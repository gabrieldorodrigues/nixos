# torlink (torlnk) — terminal torrent finder — installed per-user via Home
# Manager, with a custom RARBG (rargb.to) search source added on top of the
# upstream flake package. It lives here (not in modules/) because it's a
# personal CLI tool whose launcher keybind is in home/programs/hypr; installing
# it in the user profile keeps it grouped with the other programs.
#
# torlink has NO runtime plugin or config system — its search sources are
# TypeScript modules bundled into the binary by esbuild/tsup at build time
# ("zero setup, nothing to configure"). So to add a site we write a new source
# module and register it in the source registry during postPatch, then let the
# normal npm build re-bundle it.
#
# The scraper is embedded inline below (instead of a separate .ts file) via
# writeText, so the whole customization lives in one file. IMPORTANT: this is a
# Nix indented string, so every TypeScript template-literal `${"\${...}"}` is
# written as `''${"\${...}"}` (the `''` escapes Nix's own antiquotation);
# backslashes in the regexes are literal and need no escaping.
#
# Only source files are touched (not package.json / package-lock.json), so the
# upstream npmDepsHash stays valid. `--replace-fail` errors the build out if
# upstream ever drops an anchor, instead of silently building without RARBG.
{ pkgs, inputs, ... }:

let
  # RARBG scraper (movies / tv / games). Mirrors the 1337x source's approach:
  # scrape the results table, then open each torrent's detail page for its
  # magnet link.
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

  # Upstream torlink from the flake input, with the RARBG source injected and
  # registered at build time.
  torlink = (inputs.torlink.packages.${pkgs.stdenv.hostPlatform.system}.default).overrideAttrs (old: {
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
    '';
  });
in
{
  home.packages = [ torlink ];
}
