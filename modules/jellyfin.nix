# Jellyfin em Docker (declarativo), com plugins e tema pré-instalados.
# Pasta de mídia apontando para /home/gabrieldorodrigues/Downloads/torlink.
#
# Docker já vem habilitado em modules/dev.nix (daemon rootful).
{ config, pkgs, lib, ... }:

let
  # Versão do Jellyfin fixada: precisa casar com o targetAbi dos plugins.
  # Tanto o File Transformation quanto o Media Bar têm build para 10.11.11.
  jellyfinVersion = "10.11.11";

  mediaDir  = "/home/gabrieldorodrigues/Downloads/torlink";
  stateDir  = "/var/lib/jellyfin-docker";
  configDir = "${stateDir}/config";
  cacheDir  = "${stateDir}/cache";

  # Constrói a pasta de um plugin a partir do zip oficial (hash fixado),
  # já com o meta.json que o Jellyfin escreveria ao instalar pelo catálogo —
  # assim o plugin aparece como instalado e ativo, sem passo manual.
  mkPlugin =
    { pname
    , version
    , guid
    , displayName
    , owner
    , url
    , sha256
    , targetAbi ? "10.11.11.0"
    , category ? "General"
    , imagePath ? "logo.png" # alguns releases não trazem logo
    , flatten ? false # true: move DLLs de subpastas (bin/Debug/...) p/ a raiz
    }:
    let
      src = pkgs.fetchurl { inherit url sha256; };
      meta = builtins.toJSON {
        category = category;
        changelog = "";
        description = displayName;
        guid = guid;
        name = displayName;
        overview = displayName;
        owner = owner;
        targetAbi = targetAbi;
        timestamp = "2026-01-01T00:00:00Z";
        version = version;
        status = "Active";
        autoUpdate = false;
        imagePath = imagePath;
        assemblies = [ ];
      };
    in
    pkgs.runCommand "jellyfin-plugin-${pname}-${version}"
      { nativeBuildInputs = [ pkgs.unzip ]; }
      ''
        mkdir -p "$out"
        unzip -o ${src} -d "$out"
        ${lib.optionalString flatten ''
          # Alguns releases empacotam a DLL em subpastas (ex.: bin/Debug/net9.0).
          # O Jellyfin só carrega assemblies na raiz da pasta do plugin, então
          # movemos todos os artefatos para lá e limpamos os diretórios vazios.
          find "$out" -mindepth 2 -type f \
            \( -name '*.dll' -o -name '*.json' -o -name '*.pdb' -o -name '*.png' \) \
            -exec mv -f -t "$out" {} +
          find "$out" -mindepth 1 -type d -empty -delete
        ''}
        cp ${pkgs.writeText "meta.json" meta} "$out/meta.json"
      '';

  # Plugin base: transforma o index.html do web client (usado pelo Media Bar).
  fileTransformation = mkPlugin {
    pname = "file-transformation";
    version = "2.5.11.0";
    guid = "5e87cc92-571a-4d8d-8d98-d2d4147f9f90";
    displayName = "File Transformation";
    owner = "IAmParadox27";
    url = "https://github.com/IAmParadox27/jellyfin-plugin-file-transformation/releases/download/2.5.11.0/Release-10.11.11.zip";
    sha256 = "07158sbp6a9k8csy1y9w2sknfwf6wfvybs6572376jwwmnk3kfqy";
  };

  # Barra/carrossel de destaques na home (depende do File Transformation).
  mediaBar = mkPlugin {
    pname = "media-bar";
    version = "2.4.12.0";
    guid = "08f615ea-2107-4f04-89cc-091035f54448";
    displayName = "Media Bar";
    owner = "IAmParadox27";
    url = "https://github.com/IAmParadox27/jellyfin-plugin-media-bar/releases/download/2.4.12.0/Release-10.11.11.zip";
    sha256 = "1q79gz2wf773jdp5rmxf3qvxw0vqdrbgz593ccq4raqxxvpc3740";
  };

  # Metadados de anime de múltiplas fontes (AniList, AniDB, MAL, TVDB, etc.).
  # targetAbi 10.11.3.0 → compatível com 10.11.11 (server >= abi mínimo).
  animeMultiSource = mkPlugin {
    pname = "anime-multi-source";
    version = "1.0.4.9";
    guid = "8eca6f17-71fe-4309-a670-3cae083f22bd";
    displayName = "Anime Multi Source";
    owner = "webbster64";
    category = "Anime";
    targetAbi = "10.11.3.0";
    imagePath = ""; # este release não inclui logo.png
    url = "https://github.com/webbster64/jellyfin-plugin-AnimeMultiSource/releases/download/v1.0.4.9/AnimeMultiSource_v1.0.4.9.zip";
    sha256 = "0kxds1cav7akqsb5k5zq4pq925ibmyjkzgxh31rj69ad30ychrmd";
  };

  # Cria coleções automaticamente por regras (gênero, estúdio, etc.).
  # OBS: o release empacota a DLL em bin/Debug/net9.0 → flatten = true.
  autoCollections = mkPlugin {
    pname = "auto-collections";
    version = "0.0.4.1";
    guid = "06ebf4a9-1326-4327-968d-8da00e1ea2eb";
    displayName = "Auto Collections";
    owner = "KeksBombe";
    targetAbi = "10.11.0.0";
    imagePath = "";
    flatten = true;
    url = "https://github.com/KeksBombe/jellyfin-plugin-auto-collections/releases/download/0.0.4.1/auto-collections-0.0.4.1.zip";
    sha256 = "0v35ircfbwxp8mpxdpx07z6lwg5j4q527pl2m7n5hhkfcj4qd5f7";
  };

  # Detecta e permite pular aberturas/encerramentos (usa File Transformation
  # para injetar o botão "Skip" na UI web).
  introSkipper = mkPlugin {
    pname = "intro-skipper";
    version = "1.10.11.22";
    guid = "c83d86bb-a1e0-4c35-a113-e2101cf4ee6b";
    displayName = "Intro Skipper";
    owner = "intro-skipper";
    targetAbi = "10.11.11.0";
    imagePath = "";
    url = "https://github.com/intro-skipper/intro-skipper/releases/download/10.11/v1.10.11.22/intro-skipper-v1.10.11.22.zip";
    sha256 = "0zh88p25lr1ilj8n7c6h5bgpyy86s98l88pgf57d70m4jgm1c3rp";
  };

  # Páginas/abas separadas na home (Movies, Anime, TV…). Depende do
  # File Transformation. Release específico para o ABI 10.11.11.
  pluginPages = mkPlugin {
    pname = "plugin-pages";
    version = "2.4.11.0";
    guid = "5b6550fa-a014-4f4c-8a2c-59a43680ac6d";
    displayName = "Plugin Pages";
    owner = "IAmParadox27";
    targetAbi = "10.11.11.0";
    url = "https://github.com/IAmParadox27/jellyfin-plugin-pages/releases/download/2.4.11.0/Release-10.11.11.zip";
    sha256 = "0624pl8cpzx8rxlgcg144sk1f6cnx3fhw7jsms0nksz9g7z4061v";
  };

  # Permite que usuários definam o próprio avatar por upload/URL.
  getAvatar = mkPlugin {
    pname = "get-avatar";
    version = "1.6.4.1";
    guid = "88accc81-d913-44b3-b1d3-2abfa457dd2d";
    displayName = "GetAvatar";
    owner = "cedev-1";
    category = "User Management";
    targetAbi = "10.11.5.0";
    imagePath = "";
    url = "https://github.com/cedev-1/jellyfin-plugin-GetAvatar/releases/download/v1.6.4.1/Jellyfin.Plugin.GetAvatar-v1.6.4.1.zip";
    sha256 = "146r0cj5cjh1bzngpi9fv7jhrxcy0cmcb9jk7nhbbgj8gvk278a8";
  };

  # Sincroniza avaliações/watched com uma conta Letterboxd.
  letterboxdSync = mkPlugin {
    pname = "letterboxd-sync";
    version = "1.8.6.0";
    guid = "b1fb3d98-3336-4b87-a5c9-8a948bd87233";
    displayName = "LetterboxdSync";
    owner = "Gizmo091";
    targetAbi = "10.11.0.0";
    imagePath = "";
    url = "https://github.com/Gizmo091/jellyfin-plugin-letterboxd-sync/releases/download/v1.8.6/jellyfin-plugin-letterboxd-sync-v1.8.6.zip";
    sha256 = "1pgsps97dz3ki828byibz9mfjdignq9fcvs5l4xgv2fnqi0c45c9";
  };

  # Gera legendas por IA (Whisper). ATENÇÃO: precisa de um backend Whisper
  # externo (whisper-asr-webservice) configurado nas opções do plugin;
  # sozinho ele não transcreve. Instalado aqui, backend fica a seu critério.
  whisperSubs = mkPlugin {
    pname = "whisper-subs";
    version = "3.17.0.0";
    guid = "97124bd9-c8cd-4a53-a213-e593aa3fef52";
    displayName = "WhisperSubs";
    owner = "GeiserX";
    category = "Subtitles";
    targetAbi = "10.11.0.0";
    imagePath = "";
    url = "https://github.com/GeiserX/whisper-subs/releases/download/v3.17.0.0/WhisperSubs_3.17.0.0.zip";
    sha256 = "1aylzn7aqv54xd2lrbwxhnyhdb76cyjsb1yiaqryh9hy3jjvm8qc";
  };

  # ElegantFin é um tema puramente CSS: entra via "Custom CSS" (branding.xml).
  # Também esconde o pôster (backdrop) do Media Bar quando o trailer toca,
  # deixando o trailer ocupar a largura toda em vez de dividir a tela.
  brandingXml = pkgs.writeText "branding.xml" ''
    <?xml version="1.0" encoding="utf-8"?>
    <BrandingOptions xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <CustomCss>@import url("https://cdn.jsdelivr.net/gh/lscambo13/ElegantFin@main/Theme/ElegantFin-jellyfin-theme-build-latest-minified.css");
    /* Media Bar: ao tocar o trailer, mostra só o trailer (esconde o pôster). */
    .backdrop.with-video { opacity: 0 !important; }
    .video-container {
      -webkit-mask-image: linear-gradient(to top, transparent 2%, rgba(0,0,0,.6) 10%, #000 18%) !important;
      mask-image: linear-gradient(to top, transparent 2%, rgba(0,0,0,.6) 10%, #000 18%) !important;
      -webkit-mask-composite: intersect !important;
      mask-composite: intersect !important;
    }</CustomCss>
      <SplashscreenEnabled>true</SplashscreenEnabled>
    </BrandingOptions>
  '';

  # ------------------------------------------------------------------
  # Live TV (IPTV) declarativo: um tuner M3U apontando direto para a lista
  # pública do iptv-org (canais abertos brasileiros) + um guia XMLTV (EPG)
  # do epgshare01 (BR1). A lista NÃO é versionada neste repo — o Jellyfin a
  # baixa da URL ao atualizar o guia. Schema = LiveTvOptions do Jellyfin; a
  # ordem dos campos segue a ordem das propriedades das classes (o
  # XmlSerializer do .NET é sensível a ordem). EnableAllTuners=true faz o EPG
  # casar com qualquer canal cujo id bata. (~30% dos canais de listas
  # públicas ficam offline de tempos em tempos — é esperado.)
  # ------------------------------------------------------------------
  m3uUrl = "https://iptv-org.github.io/iptv/countries/br.m3u";
  epgUrl = "https://epgshare01.online/epgshare01/epg_ripper_BR1.xml.gz";
  liveTvXml = pkgs.writeText "livetv.xml" ''
    <?xml version="1.0" encoding="utf-8"?>
    <LiveTvOptions xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <GuideDays>3</GuideDays>
      <EnableRecordingSubfolders>false</EnableRecordingSubfolders>
      <EnableOriginalAudioWithEncodedRecordings>false</EnableOriginalAudioWithEncodedRecordings>
      <TunerHosts>
        <TunerHostInfo>
          <Id>a1b2c3d4e5f647a819b2c3d4e5f6a701</Id>
          <Url>${m3uUrl}</Url>
          <Type>m3u</Type>
          <FriendlyName>IPTV Brasil</FriendlyName>
          <ImportFavoritesOnly>false</ImportFavoritesOnly>
          <AllowHWTranscoding>true</AllowHWTranscoding>
          <AllowFmp4TranscodingContainer>false</AllowFmp4TranscodingContainer>
          <AllowStreamSharing>true</AllowStreamSharing>
          <FallbackMaxStreamingBitrate>30000000</FallbackMaxStreamingBitrate>
          <EnableStreamLooping>false</EnableStreamLooping>
          <TunerCount>0</TunerCount>
          <IgnoreDts>true</IgnoreDts>
          <ReadAtNativeFramerate>false</ReadAtNativeFramerate>
        </TunerHostInfo>
      </TunerHosts>
      <ListingProviders>
        <ListingsProviderInfo>
          <Id>b2c3d4e5f6a147a819b2c3d4e5f6a702</Id>
          <Type>xmltv</Type>
          <Country>BR</Country>
          <Path>${epgUrl}</Path>
          <EnableAllTuners>true</EnableAllTuners>
        </ListingsProviderInfo>
      </ListingProviders>
      <PrePaddingSeconds>0</PrePaddingSeconds>
      <PostPaddingSeconds>0</PostPaddingSeconds>
    </LiveTvOptions>
  '';
in
{
  # ------------------------------------------------------------------
  # Container Jellyfin (backend Docker).
  # ------------------------------------------------------------------
  virtualisation.oci-containers = {
    backend = "docker";
    containers.jellyfin = {
      image = "jellyfin/jellyfin:${jellyfinVersion}";
      autoStart = true;
      ports = [ "8096:8096" ];
      volumes = [
        "${configDir}:/config"
        "${cacheDir}:/cache"
        "${mediaDir}:/media:ro" # biblioteca de mídia (somente leitura)
      ];
      environment = {
        TZ = "America/Sao_Paulo";
      };
      extraOptions = [
        # Aceleração de hardware (VAAPI): /dev/dri existe nesta máquina.
        "--device=/dev/dri:/dev/dri"
      ];
    };
  };

  # Libera a interface web na LAN (TV, celular, outros dispositivos).
  networking.firewall.allowedTCPPorts = [ 8096 ];

  # ------------------------------------------------------------------
  # Prepara diretórios, plugins e tema antes de o container subir.
  # Roda a cada (re)start do container e re-sincroniza a versão declarada.
  # ------------------------------------------------------------------
  systemd.services.jellyfin-setup = {
    description = "Prepara plugins e tema do Jellyfin (Docker)";
    wantedBy = [ "docker-jellyfin.service" ];
    before = [ "docker-jellyfin.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      set -eu
      install -d -m 0755 "${configDir}" "${cacheDir}" \
        "${configDir}/plugins" "${configDir}/config"

      # Copia a pasta do plugin (do /nix/store, somente leitura) e a torna
      # gravável, para o Jellyfin conseguir gerenciá-la normalmente.
      sync_plugin() {
        dst="${configDir}/plugins/$1"
        rm -rf "$dst"
        mkdir -p "$dst"
        cp -rL "$2/." "$dst/"
        chmod -R u+rwX "$dst"
      }
      sync_plugin "FileTransformation" "${fileTransformation}"
      sync_plugin "MediaBar" "${mediaBar}"
      sync_plugin "AnimeMultiSource" "${animeMultiSource}"
      sync_plugin "AutoCollections" "${autoCollections}"
      sync_plugin "IntroSkipper" "${introSkipper}"
      sync_plugin "PluginPages" "${pluginPages}"
      sync_plugin "GetAvatar" "${getAvatar}"
      sync_plugin "LetterboxdSync" "${letterboxdSync}"
      sync_plugin "WhisperSubs" "${whisperSubs}"

      # ElegantFin (tema CSS): semeia só em instalação nova, sem sobrescrever
      # um branding.xml já existente/editado pelo usuário na interface.
      branding="${configDir}/config/branding.xml"
      if [ ! -f "$branding" ]; then
        cp ${brandingXml} "$branding"
        chmod 0644 "$branding"
      fi

      # Semeia o livetv.xml (tuner M3U + guia XMLTV) só em instalação nova,
      # sem sobrescrever ajustes feitos pelo usuário na interface depois.
      livetv="${configDir}/config/livetv.xml"
      if [ ! -f "$livetv" ]; then
        cp ${liveTvXml} "$livetv"
        chmod 0644 "$livetv"
      else
        # Já existe: garante que o tuner aponte para a URL declarada
        # (troca qualquer <Url> do tuner pela lista pública atual).
        sed -i 's#<Url>[^<]*</Url>#<Url>${m3uUrl}</Url>#' "$livetv"
      fi

      # Remove a lista local antiga (não é mais versionada/usada).
      rm -f "${configDir}/config/iptv-br.m3u"
    '';
  };
}
