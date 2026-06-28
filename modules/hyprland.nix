# Hyprland (Wayland) + Waybar + Rofi desktop setup.
# KDE Plasma is kept as an alternative session (see modules/desktop.nix);
# pick the session on the SDDM login screen.
{ config, pkgs, ... }:

let
  # Config files live in this repo (nix/dotfiles/...) and are symlinked into
  # the user's ~/.config at login. Editing the files here updates the system
  # after the next `nixos-rebuild switch` + relogin.
  dotfiles = ../home/dotfiles;

  # Folder (symlinked to ~/Pictures/wallpaper) that holds the wallpapers
  # versioned in this repo (nix/dotfiles/wallpaper).
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

  # Show a rofi menu listing the wallpapers in ${wallpaperDir} (with thumbnail
  # icons) and apply the selected one. Bound to a key in hyprland.lua.
  wallpaperMenu = pkgs.writeShellScriptBin "wallpaper-menu" ''
    export PATH=${pkgs.awww}/bin:${pkgs.rofi}/bin:${pkgs.coreutils}/bin:${pkgs.findutils}/bin:${pkgs.gnused}/bin:$PATH
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

    # Build the rofi list: each row shows the file name with its image as icon.
    menu=""
    for w in "''${walls[@]}"; do
      menu+="$(basename "$w")"$'\x00'"icon"$'\x1f'"$w"$'\n'
    done

    choice=$(printf '%b' "$menu" \
      | rofi -dmenu -i -p "Wallpaper" -show-icons \
          -theme-str 'window { width: 900px; } listview { columns: 3; lines: 2; } element-icon { size: 8em; } element-text { vertical-align: 1.0; horizontal-align: 0.5; }')
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
    GTK_THEME = "Adwaita-dark";  # Force a dark GTK theme system-wide.
    # NOTE: We deliberately do NOT pin HYPRLAND_CONFIG to a Nix store path.
    # Hyprland reads its default ~/.config/hypr/hyprland.lua (the symlink
    # managed below by systemd-tmpfiles). Because that symlink is updated in
    # place on every rebuild, `hyprctl reload` picks up config changes without
    # requiring a full logout/login. The old stub hyprland.conf is removed by
    # the tmpfiles `r` rule below, so there is no risk of falling back to it.
  };

  # dconf is needed so the gsettings "prefer-dark" color-scheme sticks.
  programs.dconf.enable = true;

  # Packages for the Hyprland ecosystem (bar, launcher, utilities).
  environment.systemPackages = with pkgs; [
    rofi                # application launcher / menus (Wayland support built in)
    awww                # wallpaper daemon (live switching, used for cycling)
    wallpaperInit       # starts awww + applies the default wallpaper
    wallpaperCycle      # cycles through ~/Pictures/wallpaper (Super+Shift+W)
    wallpaperMenu       # rofi wallpaper picker (Super+Ctrl+Space)
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
    rofimoji            # emoji/symbol picker (Super+Ctrl+E)
    xdg-utils           # xdg-open and friends
    nautilus            # file manager
    tmux                # used by the Super+Alt+Return keybind
  ];

  # Symlink the versioned dotfiles into the user's home at login.
  # `L+` forces the symlink, replacing anything already there.
  systemd.user.tmpfiles.rules = [
    # Hyprland 0.55+ uses a Lua config (hyprland.lua). Remove the stale
    # hyprlang symlink so the compositor doesn't pick up the old file.
    "r %h/.config/hypr/hyprland.conf  - - - - -"
    "L+ %h/.config/hypr/hyprland.lua   - - - - ${dotfiles}/hypr/hyprland.lua"
    "L+ %h/.config/hypr/hypridle.conf  - - - - ${dotfiles}/hypr/hypridle.conf"
    "L+ %h/.config/hypr/hyprlock.conf  - - - - ${dotfiles}/hypr/hyprlock.conf"
    "L+ %h/.config/rofi/config.rasi    - - - - ${dotfiles}/rofi/config.rasi"
    # GTK dark theme (applies to both GTK3 and GTK4 apps).
    "L+ %h/.config/gtk-3.0/settings.ini - - - - ${dotfiles}/gtk/settings.ini"
    "L+ %h/.config/gtk-4.0/settings.ini - - - - ${dotfiles}/gtk/settings.ini"
    # Versioned wallpapers, exposed under ~/Pictures/wallpaper.
    "L+ %h/Pictures/wallpaper          - - - - ${dotfiles}/wallpaper"
  ];
}
