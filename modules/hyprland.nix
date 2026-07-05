# Hyprland (Wayland) + Waybar + Walker desktop setup.
# KDE Plasma is kept as an alternative session (see modules/desktop.nix);
# pick the session on the SDDM login screen.
{ config, pkgs, ... }:

let
  # Real, editable location of the wallpapers, versioned in this repo. We point
  # the ~/Pictures/wallpaper symlink (below) at THIS path instead of a copy in
  # the read-only nix store, so wallpapers can be added / removed / edited in
  # place (the folder is user-owned; /etc/nixos is the deploy path) and show up
  # live in the picker with no rebuild.
  wallpaperSource = "/etc/nixos/home/wallpapers";

  # Runtime path apps read wallpapers from (the symlink created below).
  wallpaperDir = "$HOME/Pictures/wallpaper";

  # Default wallpaper applied at session start.
  defaultWallpaper = "${wallpaperDir}/tyumap.webp";

  # Start the wallpaper daemon and apply the default wallpaper. Run on session
  # start (see hyprland.lua autostart). The `swww` package in this nixpkgs
  # ships the `awww` fork, whose binaries are `awww` / `awww-daemon`.
  wallpaperInit = pkgs.writeShellScriptBin "wallpaper-init" ''
    export PATH=${pkgs.awww}/bin:$PATH
    # Start the daemon if it isn't already running.
    if ! awww query >/dev/null 2>&1; then
      awww-daemon &
      # Wait for the daemon to come up before setting an image.
      for _ in $(seq 1 50); do
        awww query >/dev/null 2>&1 && break
        sleep 0.1
      done
    fi
    awww img "${defaultWallpaper}" >/dev/null 2>&1 || true
  '';

  # Cycle to the next wallpaper in ${wallpaperDir} (sorted alphabetically),
  # wrapping back to the first one. Bound to a key in hyprland.lua.
  wallpaperCycle = pkgs.writeShellScriptBin "wallpaper-cycle" ''
    export PATH=${pkgs.awww}/bin:${pkgs.coreutils}/bin:${pkgs.findutils}/bin:$PATH
    dir="${wallpaperDir}"

    # Make sure the daemon is up (e.g. first run after login).
    if ! awww query >/dev/null 2>&1; then
      awww-daemon &
      for _ in $(seq 1 50); do
        awww query >/dev/null 2>&1 && break
        sleep 0.1
      done
    fi

    # Collect supported image files, sorted for a stable order.
    mapfile -t walls < <(find -L "$dir" -maxdepth 1 -type f \
      \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \
         -o -iname '*.webp' -o -iname '*.gif' \) | sort)
    [ "''${#walls[@]}" -eq 0 ] && exit 0

    # Find the wallpaper currently displayed (if any) to compute the next one.
    # awww reports the canonical (symlink-resolved) path because
    # ~/Pictures/wallpaper is a symlink, so canonicalize each candidate first.
    current=$(awww query 2>/dev/null | sed -n 's/.*image: //p' | head -n1)
    next=0
    for i in "''${!walls[@]}"; do
      if [ "$(readlink -f "''${walls[$i]}")" = "$current" ]; then
        next=$(( (i + 1) % ''${#walls[@]} ))
        break
      fi
    done

    awww img "''${walls[$next]}" \
      --transition-type fade --transition-fps 60 --transition-duration 1
  '';

  # Open the walker wallpaper picker: a thumbnail-only menu of the images in
  # ${wallpaperDir}. The menu (entries + cached PNG thumbnails) is defined in
  # ~/.config/elephant/menus/wallpapers.lua (see home/programs/walker) and
  # applies the chosen wallpaper via awww. We activate walker directly on the
  # menus:wallpapers provider so it works even on the first use after login
  # (walker only subscribes to elephant's menu channel once it's activated).
  wallpaperMenu = pkgs.writeShellScriptBin "wallpaper-menu" ''
    export PATH=${pkgs.awww}/bin:${pkgs.walker}/bin:${pkgs.coreutils}/bin:$PATH

    # Make sure the daemon is up (e.g. first run after login) so applying the
    # selected wallpaper works immediately.
    if ! awww query >/dev/null 2>&1; then
      awww-daemon &
      for _ in $(seq 1 50); do
        awww query >/dev/null 2>&1 && break
        sleep 0.1
      done
    fi

    # Grid picker: --hideqa hides the quick-activation number hints; the
    # --maxwidth/--maxheight widen this launch only (not the main launcher) so
    # the three landscape thumbnails per row are large.
    exec walker --provider menus:wallpapers --hideqa --maxwidth 900 --maxheight 700
  '';

  # Restart elephant (walker's data backend) so the launcher re-scans the XDG
  # desktop dirs. elephant only indexes applications at startup, so after a
  # `nixos-rebuild` that adds or removes apps it keeps serving the PREVIOUS
  # generation's list until restarted — this is why newly installed apps do
  # not show up in walker until the next login. The `update` alias runs this
  # automatically after a successful rebuild (see modules/shell.nix).
  reindexWalker = pkgs.writeShellScriptBin "reindex-walker" ''
    export PATH=${pkgs.elephant}/bin:${pkgs.walker}/bin:${pkgs.procps}/bin:${pkgs.coreutils}/bin:${pkgs.util-linux}/bin:$PATH

    # Only meaningful inside a running graphical session. When elephant is not
    # running (e.g. an update over SSH or from a TTY) there is nothing stale to
    # fix: the Hyprland autostart indexes the new generation at the next login.
    if ! pgrep -f 'bin/elephant' >/dev/null 2>&1; then
      echo "reindex-walker: elephant not running, nothing to do."
      exit 0
    fi

    echo "reindex-walker: restarting elephant so the launcher sees new apps..."

    # elephant/walker are wrapped by NixOS as .<name>-wrapped, whose kernel
    # comm is truncated past 15 chars, so also match on the executable path.
    pkill -9 -f 'bin/elephant' 2>/dev/null || true
    pkill -9 -x elephant       2>/dev/null || true
    pkill -9 -f 'bin/walker'   2>/dev/null || true
    pkill -9 -x walker         2>/dev/null || true

    # Drop the stale control socket so walker reconnects to the fresh one.
    rm -f "''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/elephant/elephant.sock"

    sleep 0.3

    # Relaunch both from $HOME, fully detached from this shell. The working
    # directory matters: apps launched from walker inherit its CWD, so starting
    # it in a directory that later disappears (e.g. running `update` from a temp
    # dir) would break sandboxed apps like Steam. $HOME is always valid.
    cd "$HOME" || cd /
    setsid -f elephant >/dev/null 2>&1
    setsid -f walker --gapplication-service >/dev/null 2>&1

    echo "reindex-walker: done."
  '';
in
{
  # Enable the Hyprland compositor. This also wires up XWayland and the
  # xdg-desktop-portal-hyprland portal automatically.
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
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
  #   - tinysparql:  SPARQL metadata store used by the Recent / Starred / Search
  #                  views (formerly services.gnome.tracker).
  #   - localsearch: the file indexer that feeds tinysparql (formerly
  #                  services.gnome.tracker-miners).
  services.gvfs.enable = true;
  services.gnome.tinysparql.enable = true;
  services.gnome.localsearch.enable = true;

  # GNOME Online Accounts (GOA). Enables the goa-daemon + D-Bus service that
  # stores cloud credentials (Google, Nextcloud, Microsoft…). Combined with the
  # GOA-enabled gvfs above, adding a Google account here makes the Drive show up
  # in Nautilus as a mountable location (google-drive://). The accounts are
  # added / removed through the gnome-online-accounts-gtk GUI below (Plasma's
  # System Settings would provide this, but the Hyprland session has none).
  services.gnome.gnome-online-accounts.enable = true;

  # Packages for the Hyprland ecosystem (bar, launcher, utilities).
  environment.systemPackages = with pkgs; [
    walker              # application launcher / menus (Wayland/GTK4)
    elephant            # data backend for walker (providers: drun, calc, dmenu, symbols…)
    awww                # wallpaper daemon (live switching, used for cycling)
    wallpaperInit       # starts awww + applies the default wallpaper
    wallpaperCycle      # cycles through ~/Pictures/wallpaper (Super+Shift+W)
    wallpaperMenu       # walker wallpaper picker (Super+Ctrl+Space)
    reindexWalker       # restart elephant so walker sees newly installed apps
    hyprlock            # screen locker
    hypridle            # idle daemon (auto-lock)
    mako                # notification daemon
    libnotify           # notify-send + notification client lib

    grim                # screenshot capture
    slurp               # region selection (for screenshots)
    hyprpicker          # color picker (Super+Print)
    wl-clipboard        # wl-copy / wl-paste
    cliphist            # clipboard history

    brightnessctl       # backlight control
    pamixer             # PulseAudio/Pipewire volume control
    playerctl           # media keys (play/pause/next)
    pavucontrol         # graphical audio mixer
    networkmanagerapplet # nm-applet tray icon

    nwg-look            # GTK theme settings
    gnome-themes-extra  # provides the Adwaita-dark GTK theme
    glib                # gsettings CLI (used to set the dark color-scheme)
    xdg-utils           # xdg-open and friends
    nautilus            # file manager
    gnome-online-accounts-gtk # GUI to add cloud accounts (Google Drive → Nautilus)
    tmux                # used by the Super+Alt+Return keybind
  ];

  # App configs (hypr/walker/gtk/waybar) are managed by Home Manager. The
  # wallpapers are exposed at ~/Pictures/wallpaper via a symlink to the real
  # (editable, versioned) repo folder, so new wallpapers can be dropped in with
  # no rebuild. `L+` replaces any pre-existing target on activation.
  systemd.user.tmpfiles.rules = [
    "L+ %h/Pictures/wallpaper          - - - - ${wallpaperSource}"
  ];
}
