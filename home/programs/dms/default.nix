{ config, lib, pkgs, inputs, ... }:

let
  # Tema custom Catppuccin Mocha (fixo). O arquivo é versionado neste módulo e
  # entregue em ~/.config/DankMaterialShell/themes/catppuccin-mocha.json pelo
  # Home Manager. O DMS lê o JSON de forma reativa (editar = recarrega).
  themeFile = "${config.xdg.configHome}/DankMaterialShell/themes/catppuccin-mocha.json";

  # Wallpaper inicial (o DMS renderiza e cicla os wallpapers por conta própria).
  # Apontar para um arquivo dentro de ~/Pictures/wallpaper faz o DMS reconhecer
  # ESSA pasta como a pasta de wallpapers: o seletor em grade (dankdash) abre o
  # diretório do wallpaper atual, e o "próximo/anterior" cicla os arquivos dela.
  defaultWallpaper = "${config.home.homeDirectory}/Pictures/wallpaper/tyumap.webp";

  # Semente do estado de sessão do DMS. Só é aplicada UMA vez (ver a activation
  # abaixo): grava o wallpaper inicial se ainda não houver session.json. Depois
  # o próprio DMS é dono do arquivo (escrita normal), então trocar de wallpaper
  # pela interface persiste entre reinícios — por isso NÃO usamos
  # `programs.dank-material-shell.session`, que deixaria o session.json como um
  # symlink read-only para o nix store e travaria a troca de wallpaper.
  sessionSeed = pkgs.writeText "dms-session-seed.json" (builtins.toJSON {
    wallpaperPath = defaultWallpaper;
  });
in
{
  # ---------------------------------------------------------------------------
  # DankMaterialShell (DMS)
  # ---------------------------------------------------------------------------
  # Barra + notificações + launcher + lock/idle + clipboard num só shell,
  # substituindo waybar/mako/walker/hypridle/cliphist. O módulo home vem do
  # input `dms` (importado em home/home.nix).
  programs.dank-material-shell = {
    enable = true;

    # Autostart via serviço de usuário. O serviço é amarrado ao alvo
    # hyprland-session.target (ver home/programs/hypr) para o DMS só subir dentro
    # do Hyprland, e não em outras sessões (KDE/SDDM).
    systemd = {
      enable = true;
      restartIfChanged = true;
    };

    # Paleta fixa Catppuccin Mocha — sem theming dinâmico por wallpaper (matugen).
    enableDynamicTheming = false;

    # Métricas de sistema (CPU/RAM/GPU). O módulo instala o dgop por conta
    # própria (default do flake); não sobrescrevemos o pacote.
    enableSystemMonitoring = true;

    # Visualizador de áudio (cava) e feedback sonoro.
    enableAudioWavelength = true;

    # Configuração completa do DMS (barra, cores, lock, dock, animações, etc.),
    # versionada em ./settings.json — um snapshot do settings.json do DMS. O
    # módulo grava esse conteúdo em ~/.config/DankMaterialShell/settings.json
    # (symlink read-only para o nix store), deixando a config declarativa e
    # reprodutível. `customThemeFile` é sobrescrito para apontar sempre para o
    # tema entregue por este módulo (independe do caminho salvo no snapshot).
    settings = (lib.importJSON ./settings.json) // {
      customThemeFile = themeFile;
    };
  };

  # Entrega o JSON do tema no diretório de temas do DMS.
  xdg.configFile."DankMaterialShell/themes/catppuccin-mocha.json".source =
    ./catppuccin-mocha.json;

  # Semeia o session.json do DMS com o wallpaper inicial APENAS se ele ainda não
  # existir. Assim o DMS já abre mostrando um wallpaper de ~/Pictures/wallpaper
  # (e o seletor reconhece a pasta), mas o arquivo continua sendo escrito pelo
  # próprio DMS — trocar de wallpaper/tema pela interface persiste normalmente.
  home.activation.dmsSeedWallpaper = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    dmsStateDir="${config.xdg.stateHome}/DankMaterialShell"
    dmsSession="$dmsStateDir/session.json"
    if [ ! -e "$dmsSession" ]; then
      run mkdir -p "$dmsStateDir"
      run install -m 0644 ${sessionSeed} "$dmsSession"
    fi
  '';

  # Alvo de sessão do Hyprland. Esta sessão não usa UWSM, então o
  # graphical-session.target do systemd --user nunca é ativado; sem um alvo
  # próprio o dms.service (WantedBy=graphical-session.target por padrão) não
  # subiria. O autostart do Hyprland (home/programs/hypr) faz
  # `systemctl --user start hyprland-session.target`, e este alvo puxa o
  # dms.service via Wants — então o DMS só roda dentro do Hyprland (não no
  # KDE/SDDM).
  systemd.user.targets.hyprland-session = {
    Unit = {
      Description = "Hyprland session target";
      BindsTo = [ "graphical-session.target" ];
      Wants = [ "graphical-session-pre.target" "dms.service" ];
      After = [ "graphical-session-pre.target" ];
    };
  };
}
