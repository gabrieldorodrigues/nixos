# torlink (torlnk) rodando em CONTAINER Docker (declarativo), no lugar da
# instalação nativa via Home Manager. A TUI é aberta com `docker exec -it`
# através de um wrapper fino chamado `torlnk` — ou seja, o comando `torlnk` e o
# atalho Super+Shift+T (kitty -e torlnk) continuam funcionando exatamente igual.
#
# Por que container: isola o torlink (e o Node que ele embute) do host — nada
# vai para o PATH do sistema além do wrapper. A imagem é construída pelo próprio
# Nix (dockerTools) a partir do MESMO pacote do flake `torlink`, com a fonte
# RARBG (rargb.to) injetada. Continua declarativo/offline: nada de `npm i -g`
# em runtime, a imagem sai do closure já pronto.
#
# torlink não tem sistema de plugins/config em runtime: as fontes de busca são
# módulos TypeScript empacotados pelo esbuild em build. Para adicionar um site
# escrevemos o módulo TS e o registramos no registry durante o postPatch,
# deixando o build do npm re-empacotar. Só arquivos de código são tocados (não
# package.json / package-lock.json), então o npmDepsHash upstream continua
# válido. `--replace-fail` quebra o build se o upstream mudar as âncoras.
#
# IMPORTANTE (string Nix indentada ''...''): todo template-literal do TypeScript
# `${"\${...}"}` é escrito como `''${"\${...}"}` (o `''` escapa a antiquotação do
# Nix); barras invertidas nas regex são literais e não precisam de escape.
{ config, pkgs, lib, inputs, ... }:

let
  system = pkgs.stdenv.hostPlatform.system;

  # Onde os downloads caem no host. É a MESMA pasta que o Jellyfin lê como
  # biblioteca (modules/jellyfin.nix monta ela em /media:ro), então tudo que o
  # torlink baixa aparece direto no Jellyfin, sem passo extra.
  downloadsDir = "/home/gabrieldorodrigues/Downloads/torlink";

  # Estado persistente do torlink (config.json, fila, histórico, seeds, .torrent
  # cache) fora do container, para sobreviver a restart/rebuild. A env
  # TORLINK_STATE_DIR relocaliza TUDO para cá (ver src/config/paths.ts upstream).
  stateDir = "/var/lib/torlink";

  # UID:GID com que o container roda, para os arquivos baixados pertencerem ao
  # usuário (e não a root, que é o padrão do Docker rootful). Primeiro usuário
  # normal do NixOS = 1000; grupo primário padrão de um isNormalUser = users(100).
  uid = "1000";
  gid = "100";

  # Portas FIXAS de escuta do BitTorrent. Por padrão o WebTorrent (engine do
  # torlink) sorteia portas aleatórias a cada start, então nenhuma regra de
  # firewall consegue liberar conexões de entrada — e sem entrada não há como
  # SEEDAR (peers precisam conseguir te conectar) nem receber peers extras no
  # download. Fixamos aqui, injetamos via env no engine (postPatch abaixo) e
  # liberamos no firewall. torrentPort = wire TCP + µTP (UDP); dhtPort = DHT (UDP).
  torrentPort = 51413;
  dhtPort = 51414;

  # ---------------------------------------------------------------------------
  # Fonte RARBG (movies / tv / games). Espelha a abordagem do source 1337x:
  # raspa a tabela de resultados e abre a página de detalhe de cada torrent para
  # pegar o magnet.
  # ---------------------------------------------------------------------------
  rargbSource = pkgs.writeText "rargb.ts" ''
    import { fetchResilient, HttpError, USER_AGENT } from "../util/net";
    import { unescapeEntities } from "./rss";
    import { parseSize } from "../util/format";
    import type { SearchOptions, Source, SourceId, TorrentResult } from "./types";

    // RARBG shut down in 2023; rargb.to is a community mirror that keeps the same
    // HTML layout. There is no public JSON API anymore, so — like the 1337x
    // source — we scrape the results table and then open each torrent's detail
    // page to read its magnet link. Mirrors are tried in order for resilience.
    const HOSTS = ["rargb.to", "rarbg.to"];

    // Cap detail-page fetches: each result needs one extra request for its magnet.
    const MAX_DETAILS = 8;

    const STOP = new Set(["the", "a", "an", "of", "and", "or", "to"]);

    // rargb top-level category slugs, matching torlink's groups.
    type Cat = "movies" | "tv" | "games";

    interface Row {
      name: string;
      path: string;
      cat: string;
      seeders: number;
      leechers: number;
      sizeBytes: number;
      added?: number;
    }

    // Parse the results table (<table class="lista2t"> ... <tr class="lista2">).
    function parseRows(html: string): Row[] {
      const start = html.indexOf("lista2t");
      if (start < 0) return [];
      const out: Row[] = [];
      for (const tr of html.slice(start).split(/<tr class="lista2"/i).slice(1)) {
        const link = tr.match(/href="(\/torrent\/[^"]+\.html)"[^>]*>([^<]+)<\/a>/i);
        if (!link) continue;

        const cat = tr.match(/width="150px" class="lista">[\s\S]*?href="\/([a-z0-9]+)\//i)?.[1] ?? "";
        const size = tr.match(/>\s*([\d.]+\s*[KMGT]i?B)\s*<\/td>/i)?.[1] ?? "";
        const nums = [...tr.matchAll(/width="50px" class="lista">(?:<font[^>]*>)?\s*(\d+)/gi)].map(
          (m) => Number(m[1]),
        );

        let added: number | undefined;
        const d = tr.match(/>\s*(\d{4})-(\d{2})-(\d{2})\s+(\d{2}):(\d{2}):(\d{2})\s*</);
        if (d) {
          const secs = Math.floor(
            Date.UTC(+d[1]!, +d[2]! - 1, +d[3]!, +d[4]!, +d[5]!, +d[6]!) / 1000,
          );
          added = Number.isNaN(secs) ? undefined : secs;
        }

        out.push({
          name: unescapeEntities(link[2]!.trim()),
          path: link[1]!,
          cat,
          seeders: nums[0] ?? 0,
          leechers: nums[1] ?? 0,
          sizeBytes: parseSize(size),
          added,
        });
      }
      return out;
    }

    async function fetchText(url: string, opts: SearchOptions, retries: number): Promise<string> {
      const res = await fetchResilient(url, {
        headers: { "User-Agent": USER_AGENT },
        signal: opts.signal,
        retries,
      });
      if (!res.ok) throw new HttpError(res.status, `RARBG returned ''${res.status}`);
      return res.text();
    }

    // Open a torrent's detail page and pull its magnet link (rargb exposes the
    // full magnet with &dn and trackers directly in the page).
    async function detailMagnet(
      base: string,
      path: string,
      opts: SearchOptions,
    ): Promise<string | null> {
      try {
        const html = await fetchText(`''${base}''${path}`, opts, 1);
        const raw = html.match(/magnet:\?xt=urn:btih:[^"'<>\s]+/i)?.[0];
        return raw ? unescapeEntities(raw) : null;
      } catch {
        return null;
      }
    }

    async function search(
      query: string,
      cat: Cat,
      source: SourceId,
      opts: SearchOptions = {},
    ): Promise<TorrentResult[]> {
      const q = query.trim();
      // Search is category-agnostic (we filter rows by slug below); an empty
      // query browses the category's landing page instead.
      const path = q ? `/search/?search=''${encodeURIComponent(q)}` : `/''${cat}/`;

      let base = "";
      let html = "";
      let lastError: unknown;
      for (const host of HOSTS) {
        try {
          const candidate = `https://''${host}`;
          html = await fetchText(`''${candidate}''${path}`, opts, 2);
          base = candidate;
          break;
        } catch (e) {
          if (opts.signal?.aborted) throw e;
          lastError = e;
        }
      }
      if (!base) throw lastError instanceof Error ? lastError : new HttpError(0, "RARBG unreachable");

      let rows = parseRows(html).filter((r) => r.cat === cat);

      const tokens = q.toLowerCase().split(/\s+/).filter(Boolean);
      const meaningful = tokens.filter((t) => !STOP.has(t));
      const need = meaningful.length ? meaningful : tokens;
      if (need.length) {
        rows = rows.filter((r) => {
          const n = r.name.toLowerCase();
          return need.every((t) => n.includes(t));
        });
      }

      rows.sort((a, b) => b.seeders - a.seeders);
      rows = rows.slice(0, MAX_DETAILS);

      const settled = await Promise.all(
        rows.map(async (row): Promise<TorrentResult | null> => {
          const magnet = await detailMagnet(base, row.path, opts);
          const infoHash = magnet?.match(/urn:btih:([a-zA-Z0-9]+)/i)?.[1]?.toLowerCase();
          if (!magnet || !infoHash) return null;
          return {
            infoHash,
            name: row.name,
            sizeBytes: row.sizeBytes,
            seeders: row.seeders,
            leechers: row.leechers,
            source,
            magnet,
            added: row.added,
          };
        }),
      );
      return settled.filter((r): r is TorrentResult => r !== null);
    }

    export const rargbMovies: Source = {
      id: "rargb-movies",
      label: "RARBG",
      group: "Movies",
      homepage: "https://rargb.to",
      search: (query, opts = {}) => search(query, "movies", "rargb-movies", opts),
    };

    export const rargbTv: Source = {
      id: "rargb-tv",
      label: "RARBG",
      group: "TV",
      homepage: "https://rargb.to",
      search: (query, opts = {}) => search(query, "tv", "rargb-tv", opts),
    };

    export const rargbGames: Source = {
      id: "rargb-games",
      label: "RARBG",
      group: "Games",
      homepage: "https://rargb.to",
      search: (query, opts = {}) => search(query, "games", "rargb-games", opts),
    };
  '';

  # Pacote upstream do flake `torlink`, com a fonte RARBG injetada e registrada
  # em build. É exatamente o mesmo pacote que rodava nativo antes.
  torlink = (inputs.torlink.packages.${system}.default).overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      # 1. Drop in the RARBG scraper (movies / tv / games).
      cp ${rargbSource} src/sources/rargb.ts

      # 2a. Import the new sources in the registry.
      substituteInPlace src/sources/registry.ts \
        --replace-fail \
          'import { yts } from "./yts";' \
          'import { yts } from "./yts";
      import { rargbMovies, rargbTv, rargbGames } from "./rargb";'

      # 2b. Append them to the SOURCES array (anchor: the last existing entry).
      substituteInPlace src/sources/registry.ts \
        --replace-fail \
          '  subsplease,' \
          '  subsplease,
        rargbMovies,
        rargbTv,
        rargbGames,'

      # 3. Extend the SourceId union so the new ids are valid (type-only; esbuild
      #    strips types, but keep it correct for the source of truth).
      substituteInPlace src/sources/types.ts \
        --replace-fail \
          '  | "x1337-tv";' \
          '  | "x1337-tv"
        | "rargb-movies"
        | "rargb-tv"
        | "rargb-games";'

      # 4. Pin the WebTorrent listen ports from env (TORLINK_TORRENT_PORT /
      #    TORLINK_DHT_PORT). Upstream lets WebTorrent pick a RANDOM port every
      #    start, so no firewall rule can ever match it — which is why inbound
      #    peers and seeding don't work. With a fixed, firewall-opened port,
      #    incoming connections (and thus seeding) work. 0/unset keeps the
      #    upstream random behaviour, so this is a no-op when the env is absent.
      substituteInPlace src/download/engine.ts \
        --replace-fail \
          'this.client = new WebTorrent();' \
          'const _tlPort = Number(process.env.TORLINK_TORRENT_PORT) || 0;
      const _tlDht = Number(process.env.TORLINK_DHT_PORT) || 0;
      const _tlOpts = _tlPort > 0 ? { torrentPort: _tlPort, dhtPort: _tlDht > 0 ? _tlDht : _tlPort + 1 } : {};
      this.client = new WebTorrent(_tlOpts);'
    '';
  });

  # ---------------------------------------------------------------------------
  # Imagem Docker construída pelo Nix a partir do pacote acima. Inclui todo o
  # closure do torlink (Node embutido + node-datachannel) mais um shell/coreutils
  # (processo âncora + `docker exec`) e os certificados TLS.
  #
  # config.User fixa o uid:gid tanto do `docker run` quanto do `docker exec`, para
  # os downloads pertencerem ao usuário. TORLINK_STATE_DIR e HOME apontam para o
  # volume /state; TMPDIR também, porque a imagem não traz um /tmp gravável.
  # ---------------------------------------------------------------------------
  torlinkImage = pkgs.dockerTools.buildLayeredImage {
    name = "torlink-local";
    tag = "latest";
    contents = [ torlink pkgs.bashInteractive pkgs.coreutils pkgs.cacert ];
    config = {
      User = "${uid}:${gid}";
      WorkingDir = "/downloads";
      Env = [
        "PATH=${lib.makeBinPath [ torlink pkgs.bashInteractive pkgs.coreutils ]}"
        "TORLINK_STATE_DIR=/state"
        "HOME=/state"
        "TMPDIR=/state/tmp"
        "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
        # Portas fixas de escuta do BitTorrent (lidas pelo engine, ver postPatch).
        "TORLINK_TORRENT_PORT=${toString torrentPort}"
        "TORLINK_DHT_PORT=${toString dhtPort}"
      ];
      # Processo âncora: mantém o container de pé para o `docker exec -it`.
      # A TUI em si é iniciada sob demanda pelo wrapper `torlnk`.
      Cmd = [ "${pkgs.coreutils}/bin/sleep" "infinity" ];
    };
  };

  # Wrapper que abre a TUI dentro do container. Mesmo nome do binário nativo
  # anterior, então o atalho Super+Shift+T (kitty -e torlnk) segue igual.
  torlnkLauncher = pkgs.writeShellScriptBin "torlnk" ''
    set -eu
    docker=${pkgs.docker}/bin/docker

    # Normalmente o container já está de pé (serviço systemd sobe no boot e o
    # processo âncora nunca sai). Se por algum motivo estiver parado, tenta subir.
    if [ -z "$("$docker" ps -q -f 'name=^/torlink$' -f status=running 2>/dev/null)" ]; then
      "$docker" start torlink >/dev/null 2>&1 || {
        echo "torlink: container não está rodando. Suba com: sudo systemctl start docker-torlink.service" >&2
        exit 1
      }
    fi

    # Instância única. O motor do torlink (WebTorrent) roda DENTRO do processo
    # da TUI, e o `docker exec` NÃO mata esse processo quando o terminal fecha —
    # ele fica órfão no container segurando a porta fixa do BitTorrent (e ainda
    # seedando). Ao abrir uma nova TUI, ela não consegue o bind da porta e morre
    # com "client is destroyed"; pior, duas engines vivas corrompem os arquivos
    # de estado (queue.json/seeds.json). Como só há download/seed enquanto uma
    # TUI está aberta, encerramos qualquer TUI remanescente antes de abrir outra.
    # Os PIDs (namespace do host) aparecem no `docker top` e pertencem ao usuário
    # (uid ${uid}), então podem ser mortos daqui mesmo, sem sudo.
    old="$("$docker" top torlink 2>/dev/null | ${pkgs.gawk}/bin/awk '/cli\.cjs/ {print $2}')"
    if [ -n "$old" ]; then
      kill $old 2>/dev/null || true
      # Espera as engines saírem (flush de estado + liberação da porta), com teto
      # de ~3s; depois força com SIGKILL o que sobrar.
      n=0
      while [ "$n" -lt 15 ]; do
        left="$("$docker" top torlink 2>/dev/null | ${pkgs.gawk}/bin/awk '/cli\.cjs/ {print $2}')"
        [ -z "$left" ] && break
        ${pkgs.coreutils}/bin/sleep 0.2
        n=$((n + 1))
      done
      kill -9 $old 2>/dev/null || true
    fi

    # -it porque a TUI (Ink) precisa de PTY; TERM/COLORTERM forçados porque a
    # imagem não tem o terminfo do kitty, mas suporta 256/truecolor.
    exec "$docker" exec -it -u ${uid}:${gid} \
      -e TERM=xterm-256color -e COLORTERM=truecolor \
      torlink torlnk "$@"
  '';
in
{
  # ---------------------------------------------------------------------------
  # Container torlink (backend Docker). O backend `docker` do oci-containers já
  # é definido em modules/jellyfin.nix (a opção é compartilhada e só pode ser
  # setada uma vez), então aqui só declaramos o container.
  # ---------------------------------------------------------------------------
  virtualisation.oci-containers.containers.torlink = {
    imageFile = torlinkImage;
    image = "torlink-local:latest";
    autoStart = true;
    volumes = [
      "${downloadsDir}:/downloads" # onde os torrents são salvos (= biblioteca do Jellyfin)
      "${stateDir}:/state"          # config/fila/histórico/seeds persistentes
    ];
    extraOptions = [
      # Rede do host: melhor conectividade P2P (NAT-PMP/UPnP e portas diretas),
      # igual ao comportamento da versão nativa.
      "--network=host"
    ];
  };

  # Libera a porta fixa de BitTorrent para conexões de ENTRADA. Sem isto o
  # firewall do NixOS (que bloqueia todo inbound por padrão) impede que peers te
  # conectem — matando o seeding e limitando os peers no download. Como o
  # container usa --network=host, abrir no host já basta (não há NAT do Docker).
  #   TCP torrentPort  → wire protocol (conexões de peer)
  #   UDP torrentPort  → µTP (transporte de peer sobre UDP)
  #   UDP dhtPort      → DHT (descoberta de peers sem tracker)
  networking.firewall.allowedTCPPorts = [ torrentPort ];
  networking.firewall.allowedUDPPorts = [ torrentPort dhtPort ];

  # Wrapper `torlnk` no PATH do sistema (substitui o binário nativo).
  environment.systemPackages = [ torlnkLauncher ];

  # ---------------------------------------------------------------------------
  # Prepara o diretório de estado e semeia o config.json antes de o container
  # subir. Roda a cada (re)start do container.
  # ---------------------------------------------------------------------------
  systemd.services.torlink-setup = {
    description = "Prepara estado do torlink (Docker)";
    wantedBy = [ "docker-torlink.service" ];
    before = [ "docker-torlink.service" ];
    path = [ pkgs.coreutils ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      set -eu
      # Estado do torlink e pasta temporária, do usuário (uid ${uid}).
      install -d -o ${uid} -g ${gid} -m 0755 \
        ${stateDir} ${stateDir}/config ${stateDir}/data ${stateDir}/tmp
      # Pasta de downloads (a mesma do Jellyfin). Cria se ainda não existir.
      install -d -o ${uid} -g ${gid} -m 0755 ${downloadsDir}

      # Semeia o config.json apontando os downloads para /downloads (o bind mount
      # acima). Só na primeira vez — depois o usuário pode mudar com a tecla `o`.
      cfg=${stateDir}/config/config.json
      if [ ! -e "$cfg" ]; then
        cat > "$cfg" <<'JSON'
{
  "downloadDir": "/downloads",
  "trackers": []
}
JSON
        chown ${uid}:${gid} "$cfg"
      fi
    '';
  };
}
