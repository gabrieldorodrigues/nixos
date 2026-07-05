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

  # ElegantFin é um tema puramente CSS: entra via "Custom CSS" (branding.xml).
  brandingXml = pkgs.writeText "branding.xml" ''
    <?xml version="1.0" encoding="utf-8"?>
    <BrandingOptions xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <CustomCss>@import url("https://cdn.jsdelivr.net/gh/lscambo13/ElegantFin@main/Theme/ElegantFin-jellyfin-theme-build-latest-minified.css");</CustomCss>
      <SplashscreenEnabled>true</SplashscreenEnabled>
    </BrandingOptions>
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

      # ElegantFin (tema CSS): semeia só em instalação nova, sem sobrescrever
      # um branding.xml já existente/editado pelo usuário na interface.
      branding="${configDir}/config/branding.xml"
      if [ ! -f "$branding" ]; then
        cp ${brandingXml} "$branding"
        chmod 0644 "$branding"
      fi
    '';
  };
}
