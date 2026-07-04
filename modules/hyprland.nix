# Hyprland (Wayland) + Waybar + Walker desktop setup.
# KDE Plasma is kept as an alternative session (see modules/desktop.nix);
# pick the session on the SDDM login screen.
{ config, pkgs, ... }:

let
  # Versioned wallpapers folder, symlinked to ~/Pictures/wallpaper.
  wallpapers = ../home/wallpapers;

  # Folder (symlinked to ~/Pictures/wallpaper) that holds the wallpapers
  # versioned in this repo (home/wallpapers).
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
    # awww reports the canonical (nix store) path because ~/Pictures/wallpaper
    # is a symlink, so canonicalize each candidate before comparing.
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

  # Show a walker menu listing the wallpapers in ${wallpaperDir} and apply the
  # selected one. Bound to a key in hyprland.lua.
  wallpaperMenu = pkgs.writeShellScriptBin "wallpaper-menu" ''
    export PATH=${pkgs.awww}/bin:${pkgs.walker}/bin:${pkgs.coreutils}/bin:${pkgs.findutils}/bin:$PATH
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

    # Build a newline-separated list of wallpaper file names for walker --dmenu.
    menu=""
    for w in "''${walls[@]}"; do
      menu+="$(basename "$w")"$'\n'
    done

    choice=$(printf '%b' "$menu" | walker --dmenu -p "Wallpaper")
    [ -z "$choice" ] && exit 0

    awww img "$dir/$choice" \
      --transition-type fade --transition-fps 60 --transition-duration 1
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

  # Packages for the Hyprland ecosystem (bar, launcher, utilities).
  environment.systemPackages = with pkgs; [
    walker              # application launcher / menus (Wayland/GTK4)
    elephant            # data backend for walker (providers: drun, calc, dmenu, symbols…)
    awww                # wallpaper daemon (live switching, used for cycling)
    wallpaperInit       # starts awww + applies the default wallpaper
    wallpaperCycle      # cycles through ~/Pictures/wallpaper (Super+Shift+W)
    wallpaperMenu       # walker wallpaper picker (Super+Ctrl+Space)
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
    tmux                # used by the Super+Alt+Return keybind
  ];

  # App configs (hypr/walker/gtk/waybar) are managed by Home Manager. Only the
  # versioned wallpapers are symlinked into ~/Pictures/wallpaper here.
  systemd.user.tmpfiles.rules = [
    "L+ %h/Pictures/wallpaper          - - - - ${wallpapers}"
  ];
}
