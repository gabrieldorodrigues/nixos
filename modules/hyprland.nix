# Hyprland (Wayland) desktop setup.
# Login pelo greetd + dms-greeter (ver modules/desktop.nix). O Hyprland é a única sessão gráfica.
{ config, pkgs, inputs, ... }:

let
  # Hyprland vem do nixpkgs-unstable (0.56.x). O canal 26.05 trava em 0.55.4,
  # que é velho demais para o plugin hyprglass (exige a ABI de 0.56). Puxamos só
  # o compositor + portal do unstable; o resto do sistema segue no 26.05. O
  # MESMO pkgs-unstable é usado para compilar o hyprglass (ver home/programs/hypr),
  # então a ABI casa (o compositor e o plugin saem do mesmo nixpkgs).
  pkgsUnstable = import inputs.nixpkgs-unstable {
    system = pkgs.stdenv.hostPlatform.system;
    config.allowUnfree = true;
  };
  # Real, editable location of the wallpapers, versioned in this repo. We point
  # the ~/Pictures/wallpaper symlink (below) at THIS path instead of a copy in
  # the read-only nix store, so wallpapers can be added / removed / edited in
  # place (the folder is user-owned; /etc/nixos is the deploy path) and show up
  # live in the DMS wallpaper picker with no rebuild. O DankMaterialShell lê os
  # wallpapers direto desta pasta (ver home/programs/dms), então NÃO usamos mais
  # daemon próprio (awww) nem scripts de troca — o DMS renderiza e cicla sozinho.
  wallpaperSource = "/etc/nixos/home/wallpapers";
in
{
  # Enable the Hyprland compositor. This also wires up XWayland and the
  # xdg-desktop-portal-hyprland portal automatically.
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    # Compositor + portal do unstable (0.56.x), casando com o plugin hyprglass.
    package = pkgsUnstable.hyprland;
    portalPackage = pkgsUnstable.xdg-desktop-portal-hyprland;
  };

  # Helpful environment for Wayland/Hyprland sessions.
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";        # Electron/Chromium apps run on Wayland.
    MOZ_ENABLE_WAYLAND = "1";    # Firefox/Zen on Wayland.
    # NOTE: Do NOT set GTK_THEME=Adwaita-dark. "Adwaita-dark" only ships a
    # gtk-3.0 stylesheet (no gtk-4.0), so forcing it on GTK4/libadwaita apps
    # (Nautilus) loads broken CSS: misaligned sidebar without dividers and
    # dialogs (Preferences) rendered inline instead of as a floating card.
    # Dark mode for GTK4/libadwaita comes from color-scheme=prefer-dark
    # (set via gsettings in the Hyprland autostart).
    TERMINAL = "kitty";          # Default terminal for apps that honour $TERMINAL.
    # NOTE: We deliberately do NOT pin HYPRLAND_CONFIG to a Nix store path.
    # Hyprland reads its default ~/.config/hypr/hyprland.lua (the symlink
    # managed below by systemd-tmpfiles). Because that symlink is updated in
    # place on every rebuild, `hyprctl reload` picks up config changes without
    # requiring a full logout/login. The old stub hyprland.conf is removed by
    # the tmpfiles `r` rule below, so there is no risk of falling back to it.
  };

  # dconf is needed so the gsettings "prefer-dark" color-scheme sticks.
  programs.dconf.enable = true;

  # GNOME Files (Nautilus) plumbing. Under Plasma these are pulled in by KDE,
  # but the Hyprland session has no desktop environment to enable them, so
  # Nautilus was left without a virtual-filesystem backend or a search index.
  #   - gvfs:        provides trash://, recent://, network://, smb://, mtp://…
  #                  Without it there is no Trash (lixeira) and the Trash /
  #                  Network / Other Locations sidebar tabs fail to load.
  #   - tinysparql:  SPARQL metadata store used by the Recent / Starred views
  #                  (formerly services.gnome.tracker).
  services.gvfs.enable = true;
  services.gnome.tinysparql.enable = true;

  # localsearch (o indexador de arquivos, ex services.gnome.tracker-miners)
  # fica DESLIGADO de propósito. Seu unit (localsearch-3.service) tem
  # `ConditionEnvironment=XDG_SESSION_CLASS=user`, e nesta sessão Hyprland o
  # `systemd --user` NÃO recebe XDG_SESSION_CLASS (a variável existe na sessão,
  # via pam/loginctl Class=user, mas não é importada para o manager do usuário —
  # isso só aconteceria com UWSM). Então o indexador era sempre "skipped".
  # Consequência: ao abrir, o Nautilus tentava ativar o miner via D-Bus
  # (org.freedesktop.Tracker3.Miner.Files) e, no PRIMEIRO launch após o boot, a
  # ativação ficava presa no timeout até falhar (~10-20 s de atraso; nos
  # launches seguintes o cache negativo tornava tudo rápido). Como o indexador
  # nunca funcionou de fato aqui, desligá-lo não perde nenhuma função em uso e
  # remove o nome D-Bus → o Nautilus retorna na hora e abre rápido no boot.
  # (Para reativar a busca por conteúdo seria preciso importar XDG_SESSION_CLASS
  # no systemd --user e religar localsearch — aí ele passa a indexar em background.)
  services.gnome.localsearch.enable = false;

  # Agente polkit (hyprpolkitagent). A sessão Hyprland não tem um ambiente de
  # desktop que forneça um agente de autenticação polkit, então operações
  # privilegiadas pedidas por apps gráficos (ex.: o Nautilus montar um HD/SSD
  # interno, que exige a ação org.freedesktop.udisks2.filesystem-mount-system)
  # falhavam caladas com "Not authorized" — não havia quem mostrasse o diálogo
  # de senha. Este pacote traz o unit systemd de usuário hyprpolkitagent.service
  # (ConditionEnvironment=WAYLAND_DISPLAY, que já está no systemd --user); ele é
  # iniciado no autostart do Hyprland (home/programs/hypr).
  systemd.packages = [ pkgs.hyprpolkitagent ];

  # Regra polkit: permite aos membros do grupo wheel (o usuário está nele)
  # montar/desmontar/ejetar discos — inclusive os INTERNOS/fixos (…-mount-system)
  # e volumes criptografados — SEM digitar a senha toda vez. É o comportamento
  # padrão de desktops GNOME/KDE completos; aqui a sessão Hyprland não traz
  # nenhuma regra equivalente, então sem isto cada montagem pediria autenticação.
  # Máquina pessoal single-user cujo dono já tem sudo via wheel → risco aceitável.
  security.polkit.enable = true;
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if ((action.id == "org.freedesktop.udisks2.filesystem-mount-system" ||
           action.id == "org.freedesktop.udisks2.filesystem-mount" ||
           action.id == "org.freedesktop.udisks2.filesystem-mount-other-seat" ||
           action.id == "org.freedesktop.udisks2.encrypted-unlock" ||
           action.id == "org.freedesktop.udisks2.eject-media" ||
           action.id == "org.freedesktop.udisks2.power-off-drive") &&
          subject.isInGroup("wheel")) {
        return polkit.Result.YES;
      }
    });

    // Seletor de DNS (home/programs/dns/dns.sh, atalho Super+Shift+G): o `resolvectl`
    // configura DNS/DoT por-link via systemd-resolved (org.freedesktop.resolve1)
    // e revert do override. Sem esta regra, cada clique abriria um diálogo de
    // senha do polkit. Liberado para o grupo wheel (dono single-user com sudo).
    polkit.addRule(function(action, subject) {
      if (action.id.indexOf("org.freedesktop.resolve1.") == 0 &&
          subject.isInGroup("wheel")) {
        return polkit.Result.YES;
      }
    });
  '';

  # GNOME Online Accounts (GOA). Enables the goa-daemon + D-Bus service that
  # stores cloud credentials (Google, Nextcloud, Microsoft…). Combined with the
  # GOA-enabled gvfs above, adding a Google account here makes the Drive show up
  # in Nautilus as a mountable location (google-drive://). The accounts are
  # added / removed through the gnome-online-accounts-gtk GUI below (Plasma's
  # System Settings would provide this, but the Hyprland session has none).
  services.gnome.gnome-online-accounts.enable = true;

  # Secret Service (chaveiro). A sessão Hyprland não tem um ambiente de desktop
  # para fornecer o daemon org.freedesktop.secrets, então apps que guardam
  # credenciais nele falhavam com "The Secret Service daemon is neither running
  # nor activatable through D-Bus" (ex.: ProtonVPN, que nem inicializa o login
  # sem chaveiro). O gnome-keyring instala esse serviço D-Bus (ativável sob
  # demanda) e o PAM abaixo o destrava no login do greetd usando a senha da
  # conta, evitando prompts (o Hyprland não tem um prompter gráfico por padrão).
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.greetd.enableGnomeKeyring = true;

  # DankSearch (dsearch) — daemon de indexação/busca de arquivos que alimenta a
  # busca de arquivos/pastas do launcher do DMS. Módulo NixOS do nixpkgs 26.05;
  # o serviço de usuário sobe junto com a sessão (default.target).
  programs.dsearch = {
    enable = true;
    systemd.enable = true;
  };


  # Packages for the Hyprland ecosystem (utilities).
  environment.systemPackages = with pkgs; [
    # Barra, launcher, notificações, lock/idle, clipboard e wallpaper agora são
    # todos do DankMaterialShell (DMS): waybar, walker, elephant, awww, mako,
    # cliphist, hyprlock e hypridle foram removidos — o DMS os substitui.
    libnotify           # notify-send + notification client lib

    grim                # screenshot capture
    slurp               # region selection (for screenshots)
    hyprpicker          # color picker (Super+Print)
    wl-clipboard        # wl-copy / wl-paste

    brightnessctl       # backlight control
    pamixer             # PulseAudio/Pipewire volume control
    playerctl           # media keys (play/pause/next)
    pavucontrol         # graphical audio mixer

    nwg-look            # GTK theme settings
    gnome-themes-extra  # provides the Adwaita-dark GTK theme
    glib                # gsettings CLI (used to set the dark color-scheme)
    xdg-utils           # xdg-open and friends
    nautilus            # file manager
    # Previews no Nautilus (a sessão Hyprland não traz nada disso por padrão):
    #   - sushi: "Quick Look" estilo macOS. Selecione um arquivo e aperte ESPAÇO
    #     para pré-visualizar — TOCA música/vídeo, mostra foto em tamanho real,
    #     PDF, texto e fontes. Registra o serviço D-Bus
    #     org.gnome.NautilusPreviewer (achado via XDG_DATA_DIRS/dbus-1/services e
    #     ativado sob demanda pelo Nautilus) e traz seus próprios plugins
    #     GStreamer no closure, então não depende de codecs do sistema.
    #   - ffmpegthumbnailer: gera as MINIATURAS de vídeo na grade de ícones
    #     (instala share/thumbnailers/ffmpegthumbnailer.thumbnailer, encontrado
    #     via XDG_DATA_DIRS). Fotos já viram miniatura pelo gdk-pixbuf embutido.
    #   - gnome-epub-thumbnailer: capas de EPUB/MOBI (você usa foliate/readest).
    sushi
    ffmpegthumbnailer
    gnome-epub-thumbnailer
    gnome-online-accounts-gtk # GUI to add cloud accounts (Google Drive → Nautilus)
    tmux                # used by the Super+Alt+Return keybind
  ];

  # App configs (hypr/gtk) are managed by Home Manager. The wallpapers
  # are exposed at ~/Pictures/wallpaper via a symlink to the real (editable,
  # versioned) repo folder, so new wallpapers can be dropped in with no rebuild
  # and o DankMaterialShell os lista na hora. `L+` replaces any pre-existing
  # target on activation.
  systemd.user.tmpfiles.rules = [
    "L+ %h/Pictures/wallpaper          - - - - ${wallpaperSource}"
  ];

  # DDC/CI para o plugin de brilho do DMS (ddcBrightness) controlar monitores
  # EXTERNOS via ddcutil. Habilita o módulo i2c-dev + regras de udev e cria o
  # grupo "i2c" (o usuário é adicionado em modules/users.nix) para acessar os
  # barramentos /dev/i2c-* sem root. O brilho de telas internas continua pelo
  # brightnessctl (acima), que não depende disto.
  hardware.i2c.enable = true;
}
