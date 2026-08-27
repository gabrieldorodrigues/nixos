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

  # Plugins do DMS, fixados por commit (nenhum tem tag/release). Cada um é um
  # repositório de QML (mais scripts em shell/python quando precisa de backend);
  # o DMS lê os arquivos direto do diretório de plugins. Entregamos cada árvore
  # como symlink read-only (ver xdg.configFile abaixo) — declarativo e
  # reprodutível, sem `dms plugins install` imperativo. A chave do atributo é o
  # `id` do plugin (definido no plugin.json de cada repo) e vira o nome da pasta
  # em ~/.config/DankMaterialShell/plugins/<id>.
  dmsPlugins = {
    # Screenshot + anotação. Backend padrão usa grim/slurp via `dms screenshot`.
    quickCapture = pkgs.fetchFromGitHub {
      owner = "hthienloc";
      repo = "dms-quick-capture";
      rev = "v5.1.4";
      hash = "sha256-AKSiIjZWFhjou2ikk36ymC6GJ8OAloiGiIxmeDakYos=";
    };
    # Launcher: busca pacotes do nixpkgs e roda via `nix shell` (gatilho "nix").
    nixPackageRunner = pkgs.fetchFromGitHub {
      owner = "iahccc";
      repo = "NixPackageRunner";
      rev = "829ad93c15b7c0ec82a6d7483728029037442601";
      hash = "sha256-ur+1oN+QmTu7p5ZMpL3rCd4JGYbkerko4twa+tH6uvg=";
    };
    # Widget da barra: brilho de monitores interno (brightnessctl) e externos
    # (ddcutil via I2C — ver hardware.i2c em modules/hyprland.nix).
    ddcBrightness = pkgs.fetchFromGitHub {
      owner = "YoungJurry";
      repo = "dms-brightness-plugin";
      rev = "d3221bb267e99f02dd7793b505ece2cbae118623";
      hash = "sha256-3J+GSoKOLwWl6mpGgT1l0skvPtx8nvUg/Z1MLiFy8nM=";
    };
    # Widget da barra: CPU/memória/swap em anéis de progresso.
    resourceMonitor = pkgs.fetchFromGitHub {
      owner = "YoungJurry";
      repo = "dms-resource-monitor";
      rev = "5e5f9d60f00a0f6fe2b9b515d729c27edeb510c5";
      hash = "sha256-JX9livc8l78lFA4spGaEoYXRcAgClYsnIITc6kYrhTs=";
    };
    # Daemon: seletor de emoji (busca/copia/cola via clipboard).
    emojiPicker = pkgs.fetchFromGitHub {
      owner = "hthienloc";
      repo = "dms-emoji-picker";
      rev = "53fb27442c5b48ab2ab0ea37e7c2bcf72da0902a";
      hash = "sha256-FdkAZh2xv8zngqwseoTSXdKV+VXA0US+HTsGdziCDnY=";
    };
    # Launcher: busca na web com engines customizáveis (gatilho "@").
    webSearch = pkgs.fetchFromGitHub {
      owner = "devnullvoid";
      repo = "dms-web-search";
      rev = "821f5b437ea96739ce1cbc85ce324fb55e8884bb";
      hash = "sha256-UqFgAjW2A75dtlvOZkq4Vv/v/DROoc/ouCXBaVlksPI=";
    };
    # Widget + daemon: participantes de canal de voz do Discord na barra. O
    # bridge é um script Python (só stdlib), então basta python3.
    discordVoice = pkgs.fetchFromGitHub {
      owner = "PandorasFox";
      repo = "dms-discord-widget";
      rev = "937e33a6c362546fa0a0e8546ff565b3f0945e0b";
      hash = "sha256-AMAIIAaeeoEqd6AKjdoDo8z9pYlohGmKy5OhbjllxYc=";
    };
    # Launcher: arquivos XDG abertos recentemente (gatilho "rf").
    recentFiles = pkgs.fetchFromGitHub {
      owner = "gouwazi";
      repo = "dms-recent-files";
      rev = "15010449df58ffec4f85acd48f8ee1145de31a1a";
      hash = "sha256-zAzkM1oO50Opja8OskXyCQ7ma3eT+1fikb7bmguG8eM=";
    };
  };

  # Defaults do gerenciador de plugins: habilita todos os plugins acima. É só uma
  # semente — a activation abaixo faz merge que preserva o que o usuário mudar na
  # GUI (ex.: desabilitar um plugin) e só adiciona chaves ausentes.
  pluginDefaults = lib.genAttrs (lib.attrNames dmsPlugins) (_: { enabled = true; });
  pluginSettingsSeed =
    pkgs.writeText "dms-plugin-settings-seed.json" (builtins.toJSON pluginDefaults);
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

  # Entrega o JSON do tema no diretório de temas do DMS, e cada plugin como um
  # symlink read-only em plugins/<id>. O DMS lê os QML/scripts direto daí.
  xdg.configFile = {
    "DankMaterialShell/themes/catppuccin-mocha.json".source = ./catppuccin-mocha.json;
  } // lib.mapAttrs'
    (name: src:
      lib.nameValuePair "DankMaterialShell/plugins/${name}" { source = src; })
    dmsPlugins;

  # Dependências de runtime dos plugins. grim/slurp/wl-clipboard/brightnessctl
  # já vêm do módulo do Hyprland; python3 e jq vêm de modules/dev.nix. Estas
  # cobrem o resto:
  #   - quickCapture: export WebP/JPEG (imagemagick), PDF (img2pdf), OCR
  #     (tesseract), QR (zbar);
  #   - ddcBrightness: brilho de monitores externos via DDC/CI (ddcutil).
  home.packages = with pkgs; [
    imagemagick
    img2pdf
    tesseract
    zbar
    ddcutil
  ];

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

  # Plugins instalados antes manualmente (git clone) ficam como diretórios reais
  # que o Home Manager se recusa a sobrescrever com o symlink. Removemos qualquer
  # clone real ANTES do linking para o symlink declarativo assumir. (Symlinks já
  # gerenciados são ignorados.)
  home.activation.dmsRemoveStalePlugins =
    lib.hm.dag.entryBefore [ "linkGeneration" ] ''
      for name in ${lib.concatStringsSep " " (lib.attrNames dmsPlugins)}; do
        pluginDir="${config.xdg.configHome}/DankMaterialShell/plugins/$name"
        if [ -e "$pluginDir" ] && [ ! -L "$pluginDir" ]; then
          run rm -rf "$pluginDir"
        fi
      done
    '';

  # Semeia/atualiza plugin_settings.json habilitando os plugins entregues aqui.
  # Faz merge preservando o que o usuário mudou na GUI (os valores existentes
  # vencem), só adicionando as chaves ausentes — assim novos plugins já entram
  # habilitados sem sobrescrever toggles manuais. Usa jq (de modules/dev.nix).
  home.activation.dmsSeedPluginSettings =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      pluginSettings="${config.xdg.configHome}/DankMaterialShell/plugin_settings.json"
      run mkdir -p "$(dirname "$pluginSettings")"
      [ -e "$pluginSettings" ] || echo '{}' > "$pluginSettings"
      tmp="$(mktemp)"
      if ${pkgs.jq}/bin/jq --slurpfile defs ${pluginSettingsSeed} \
           '$defs[0] * .' "$pluginSettings" > "$tmp" 2>/dev/null; then
        run install -m 0644 "$tmp" "$pluginSettings"
      fi
      rm -f "$tmp"
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
