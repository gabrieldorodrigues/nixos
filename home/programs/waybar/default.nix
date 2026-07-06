{ config, lib, pkgs, ... }:

let
  # Catppuccin Mocha palette (replaces the Omarchy theme @import).
  colors = ''
    @define-color background #1e1e2e;
    @define-color foreground #cdd6f4;
  '';

  # Modules + commands for the dock layout.
  # Omarchy helper commands were replaced with the tools available on this host:
  #   btop / nmtui / blueman-manager / pavucontrol / walker / pamixer.
  modulesConfig = ''
    "modules-left": ["custom/launcher", "custom/active_window"],
    "modules-center": [ "group/center3", "hyprland/workspaces", "group/center2" ],
    "modules-right": [ "group/right1" ],

    "group/center2": {
      "orientation": "inherit",
      "modules": [ "clock", "custom/gamemode" ]
    },

    "group/center3": {
      "orientation": "inherit",
      "modules": [ "cpu", "memory", "custom/separator#blank", "image#cover", "custom/media" ]
    },

    "group/right1": {
      "orientation": "inherit",
      "modules": [
        "pulseaudio",
        "bluetooth",
        "tray",
        "battery"
      ]
    },

    "custom/active_window": {
      "exec": "~/.config/waybar/window.sh",
      "return-type": "json",
      "markup": true
    },

    "tray": {
      "icon-size": 16,
      "spacing": 8,
      "show-passive-items": true,
      "reverse-direction": false
    },

    "hyprland/workspaces": {
      "on-click": "activate",
      "all-outputs": true,
      "sort-by-number": true,
      "format": "{icon}",
      "format-icons": { "default": "○", "active": "●", "empty": "·" },
      "persistent-workspaces": {
        "1": [], "2": [], "3": [], "4": [], "5": [], "6": [], "7": [], "8": []
      }
    },

    "custom/launcher": {
      "format": "<span size='13000'>&#xf313;</span>",
      "on-click": "walker",
      "on-click-right": "kitty",
      "tooltip-format": "NixOS — Apps (Super+Space)"
    },

    "cpu": {
      "interval": 2,
      "format": "{icon} ",
      "format-icons": ["󰪞", "󰪟", "󰪠", "󰪡", "󰪢", "󰪣", "󰪤", "󰪥"],
      "on-click": "kitty -e btop"
    },

    "memory": {
      "interval": 2,
      "format": "{icon} ",
      "format-icons": ["󰪞", "󰪟", "󰪠", "󰪡", "󰪢", "󰪣", "󰪤", "󰪥"],
      "on-click": "kitty -e btop"
    },

    "clock": {
      "interval": 1,
      "locale": "pt_BR.UTF-8",
      "format": " {:L%H:%M:%S • %a, %d/%m}",
      "format-alt": "{:L%A, %d %B %Y}",
      "tooltip-format": "<big>{:L%Y %B}</big>\n<tt><small>{calendar}</small></tt>"
    },

    "battery": {
      "format": "{capacity}% {icon}",
      "format-discharging": "{icon}",
      "format-charging": "{icon}",
      "format-plugged": "",
      "format-icons": {
        "charging": ["󰢜", "󰂆", "󰂇", "󰂈", "󰢝", "󰂉", "󰢞", "󰂊", "󰂋", "󰂅"],
        "default": ["󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]
      },
      "format-full": "󰂅",
      "tooltip-format-discharging": "{power:>1.0f}W↓ {capacity}%",
      "tooltip-format-charging": "{power:>1.0f}W↑ {capacity}%",
      "interval": 5,
      "states": { "warning": 20, "critical": 10 }
    },

    "bluetooth": {
      "format": "<span size='11500'>󰂯</span>",
      "format-disabled": "<span size='11500'>󰂲</span>",
      "format-connected": "<span size='11500'></span>",
      "format-no-controller": "",
      "tooltip-format": "Devices connected: {num_connections}",
      "on-click": "blueman-manager"
    },

    "pulseaudio": {
      "format": "<span size='11500'>{icon}</span>",
      "on-click": "pavucontrol",
      "on-click-right": "pamixer -t",
      "tooltip-format": "Playing at {volume}%",
      "scroll-step": 5,
      "format-muted": "󰝟",
      "format-icons": { "default": ["󰕿", "󰖀", "󰕾"] }
    },

    "custom/separator#blank": { "format": " ", "interval": "once", "tooltip": false },

    "image#cover": {
      "exec": "~/.config/waybar/cover.sh",
      "size": 20,
      "interval": 2,
      "tooltip": false,
      "on-click": "playerctl play-pause"
    },

    "custom/media": {
      "exec": "~/.config/waybar/media.sh",
      "interval": 2,
      "on-click": "playerctl play-pause"
    },

    "custom/gamemode": {
      "exec": "test -f ~/.cache/hypr_gamemode && echo '{\"text\":\"\"}' || echo '{\"text\":\"\"}'",
      "on-click": "test -f ~/.cache/hypr_gamemode && (rm ~/.cache/hypr_gamemode && hyprctl keyword animations:enabled 1 && hyprctl keyword decoration:blur:enabled 1) || (touch ~/.cache/hypr_gamemode && hyprctl keyword animations:enabled 0 && hyprctl keyword decoration:blur:enabled 0)",
      "interval": 1,
      "return-type": "json",
      "tooltip": true,
      "tooltip-format": "GameMode"
    }
  '';

  dockConfig = ''
    {
      "reload_style_on_change": true,
      "layer": "top",
      "position": "top",
      "spacing": 0,
      "height": 36,
      "border-radius": 25,
      "margin-right": 300,
      "margin-left": 300,
      "margin-top": 8,
    ${modulesConfig}
    }
  '';

  baseStyle = ''
    * {
      border: none;
      border-radius: 0;
      min-height: 0;
      font-family: 'JetBrainsMono Nerd Font';
      font-size: 12px;
      /* Pin the text/glyph color so modules never inherit it from the ambient
         GTK theme. Without this, waybar reads the dconf gtk-theme at startup and
         a stray theme (e.g. a leftover adw-gtk3) renders clock/media/icons in a
         dark, near-invisible color. More specific selectors still override this. */
      color: @foreground;
    }

    .modules-left { margin-left: 8px; }
    .modules-right { margin-right: 8px; }

    /* Keep the toplevel surface fully transparent. Giving the window itself an
       opaque background makes GTK mark the whole surface opaque, so Hyprland
       renders the rounded-corner / side-gap pixels as solid BLACK (they vanish
       in screenshots because grim composites the real, transparent buffer).
       Painting the bar on an inner box keeps those gaps transparent. */
    window#waybar {
      background: transparent;
    }
    window#waybar > box {
      background-color: @background;
      transition-property: background-color;
      transition-duration: .5s;
      border-radius: 18px;
    }

    window#waybar.empty #window {
      background: transparent;
      background-color: transparent;
      border: none;
      border-radius: 0;
      color: transparent;
      padding: 0;
      margin: 0;
    }
    #waybar.empty .modules-center { opacity: 0; }

    #workspaces {
      padding: 0px 5px;
      margin: 3.5px 3.5px;
      border-radius: 11px;
      background-color: transparent;
      opacity: 0.95;
    }
    #workspaces button { color: @foreground; padding: 0 6px; margin: 0 1.5px; min-width: 9px; }
    #workspaces button.empty { color: @foreground; opacity: 0.5; }
    #workspaces button.active {
      transition: all 50ms ease-out;
      border-radius: 18px;
      color: #11111b;
      background: transparent;
      opacity: 1;
      margin-top: 4px;
      margin-bottom: 4px;
      margin-left: 5px;
      padding-right: 5px;
      padding-left: 5px;
    }
    #workspaces button.active:hover { background-color: alpha(@background, 0.5); color: @foreground; }
    #workspaces button:hover { background-color: transparent; }
    #workspaces button.empty:hover { border-radius: 18px; background: transparent; opacity: 1; }

    #battery, #pulseaudio { min-width: 12px; }

    #cover, #image {
      margin: 4px 6px 4px 0;
      padding: 0;
      min-width: 20px;
    }
    #cover.empty, #image.empty {
      margin: 0;
      padding: 0;
      min-width: 0;
    }

    #clock { font-size: 13px; font-weight: 700; padding: 0 14px; }
    #pulseaudio { margin: 0 7px; }
    #bluetooth { margin: 0 7px; }
    #battery { margin: 0 7px; }
    #custom-media { margin: 0 6px 0 0; }
    #custom-gamemode { margin-right: 8px; }

    tooltip {
      background: @background;
      border: 1px solid alpha(@foreground, 0.2);
      border-radius: 4px 4px 11px 11px;
    }
    tooltip label { color: white; }

    #custom-active_window {
      padding: 3px 6px;
      border-radius: 14px;
      background: @background;
      font-size: 12px;
    }
    .hidden { opacity: 0; }

    #tray {
      margin: 0 7px;
    }
    #tray > .passive { -gtk-icon-effect: dim; }
    #tray > .needs-attention { -gtk-icon-effect: highlight; }
    #tray menu { background: @background; color: @foreground; }

    #custom-mode { margin-right: 4px; }
    #custom-launcher {
      color: @foreground;
      background: transparent;
      margin-top: 4px;
      margin-bottom: 4px;
      margin-left: 2px;
      margin-right: 6px;
      padding-right: 4px;
      padding-left: 4px;
    }
    #cpu, #memory { font-size: 18px; padding: 2px 1px; }

    #group-right1, #group_right1, #right1 {
      font-weight: 800;
      background: transparent;
      padding: 0px 5px;
      margin: 3.5px 2px;
    }
    #group-center3, #group_center3, #center3,
    #group-center2, #group_center2, #center2 {
      font-weight: 800;
      background: transparent;
      border-radius: 12px;
      padding: 0px 5px;
      margin: 3.5px 2px;
    }
  '';

  mediaScript = ''
    #!/usr/bin/env bash
    title=$(playerctl metadata title 2>/dev/null)
    art=$(playerctl metadata mpris:artUrl 2>/dev/null)
    if [ -n "$title" ]; then
      if [ -n "$art" ]; then
        echo "''${title:0:25}"
      else
        echo "󰎈  ''${title:0:25}"
      fi
    else
      echo "󰎈  No media"
    fi
  '';

  coverScript = ''
    #!/usr/bin/env bash
    # Album-cover thumbnail for waybar's built-in image module. The image module
    # re-reads the file from disk every interval, so the cover updates with NO
    # CSS reload (SIGUSR2) => no bar flicker on track change. This script only
    # prints the cached PNG path; the heavy work (download + rounding) runs in
    # the background so the exec returns fast (the image module runs it on the
    # GTK main thread each tick). Corners are pre-rounded with rsvg-convert
    # because border-radius does not clip a GtkImage's pixbuf.
    cache="$HOME/.cache/waybar"
    src="$cache/cover-src"
    out="$cache/cover.png"
    marker="$cache/cover.url"
    svg="$cache/cover.svg"
    mkdir -p "$cache"

    art=$(playerctl metadata mpris:artUrl 2>/dev/null)

    if [ -z "$art" ]; then
      # No media -> drop the cached art so the image module hides itself.
      : > "$marker"
      rm -f "$out"
      exit 0
    fi

    last=$(cat "$marker" 2>/dev/null)
    if [ "$art" != "$last" ]; then
      echo "$art" > "$marker"
      {
        ok=1
        case "$art" in
          file://*)
            p=''${art#file://}
            printf -v p '%b' "''${p//%/\\x}"
            cp -f "$p" "$src" 2>/dev/null || ok=0
            ;;
          http://*|https://*)
            curl -sfL --max-time 8 -o "$src" "$art" 2>/dev/null || ok=0
            ;;
          *) ok=0 ;;
        esac
        if [ "$ok" = 1 ]; then
          W=40; H=40; R=8
          printf '%s\n' \
            "<svg xmlns=\"http://www.w3.org/2000/svg\" xmlns:xlink=\"http://www.w3.org/1999/xlink\" width=\"$W\" height=\"$H\">" \
            "<defs><clipPath id=\"r\"><rect width=\"$W\" height=\"$H\" rx=\"$R\" ry=\"$R\"/></clipPath></defs>" \
            "<image xlink:href=\"file://$src\" width=\"$W\" height=\"$H\" preserveAspectRatio=\"xMidYMid slice\" clip-path=\"url(#r)\"/>" \
            "</svg>" > "$svg"
          rsvg-convert -w "$W" -h "$H" -o "$out.tmp" "$svg" 2>/dev/null && mv -f "$out.tmp" "$out"
        fi
      } &
    fi

    [ -f "$out" ] && echo "$out"
  '';

  windowScript = ''
    #!/usr/bin/env bash
    MAX_TITLE_LEN=20

    print_status() {
      window=$(hyprctl activewindow -j 2>/dev/null)
      address=$(jq -r '.address // empty' <<< "$window")

      if [[ -z "$address" || "$address" == "null" ]]; then
        ws=$(hyprctl activeworkspace -j | jq -r '.id')
        top_line="Desktop"
        bottom_line="Workspace $ws"
        esc_top=$(sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g' <<< "$top_line")
        esc_bottom=$(sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g' <<< "$bottom_line")
        text="<span size='7500' foreground='#a6adc8' rise='-2000'>$esc_top</span>
    <span size='9000' weight='bold' foreground='#ffffff'>$esc_bottom</span>"
        jq -nc --arg text "$text" --arg tooltip "$bottom_line" \
          '{ text: $text, class: "custom-window", tooltip: $tooltip }'
        return
      fi

      class=$(jq -r '.class // "Unknown"' <<< "$window")
      title=$(jq -r '.title // ""' <<< "$window")
      app_class="''${class,,}"

      if [[ "$app_class" == *discord* || "$app_class" == *vesktop* ]]; then
        title=$(sed -E 's/^\([0-9]+\)[[:space:]]*//' <<< "$title")
        title=$(sed -E 's/^Discord[[:space:]]*\|[[:space:]]*//' <<< "$title")
      fi

      if (( ''${#title} > MAX_TITLE_LEN )); then
        title="''${title:0:$((MAX_TITLE_LEN-3))}..."
      fi

      esc_top=$(sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g' <<< "$class")
      esc_bottom=$(sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g' <<< "$title")
      text="<span size='7500' foreground='#a6adc8' rise='-2000'>$esc_top</span>
    <span size='9000' weight='bold' foreground='#ffffff'>$esc_bottom</span>"
      tooltip="$class: $title"
      jq -nc --arg text "$text" --arg tooltip "$tooltip" \
        '{ text: $text, class: "custom-window", tooltip: $tooltip }'
    }

    print_status
  '';
in
{
  # Tools the bar's modules/scripts call out to.
  home.packages = with pkgs; [
    jq
    playerctl
    pamixer
    pavucontrol
    blueman
    curl
    librsvg
  ];

  programs.waybar.enable = true;

  xdg.configFile = {
    "waybar/config.jsonc".text = dockConfig;
    "waybar/style.css".text = colors + baseStyle;

    "waybar/media.sh" = { text = mediaScript; executable = true; };
    "waybar/cover.sh" = { text = coverScript; executable = true; };
    "waybar/window.sh" = { text = windowScript; executable = true; };
  };
}
