{ config, lib, pkgs, ... }:

{
  # Hyprland configs are deployed to ~/.config/hypr by Home Manager.
  # The compositor itself is enabled at system level (modules/hyprland.nix).
  xdg.configFile = {
    "hypr/hyprland.lua".text = ''
      -- #######################################################################
      --  Hyprland configuration (Lua, Hyprland 0.55+)
      --  Docs: https://wiki.hypr.land/Configuring/
      --  This file is symlinked from the NixOS repo (managed by modules/hyprland.nix)
      -- #######################################################################

      ------------------
      ---- MONITORS ----
      ------------------
      -- Primary monitor at 1080p @ 144Hz; other monitors auto-detected.
      hl.monitor({ output = "DP-3", mode = "1920x1080@144", position = "0x0", scale = 1 })
      hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

      --------------------
      ---- MY PROGRAMS ---
      --------------------
      local terminal    = "kitty"
      local fileManager = "nautilus"
      local menu        = "walker"
      local browser     = "firefox"

      -------------------
      ---- AUTOSTART ----
      -------------------
      hl.on("hyprland.start", function()
          hl.exec_cmd("waybar")
          hl.exec_cmd("wallpaper-init")
          hl.exec_cmd("mako")
          hl.exec_cmd("hypridle")
          hl.exec_cmd("nm-applet --indicator")
          -- Walker launcher backend + service (started before it's ever invoked)
          hl.exec_cmd("elephant")
          hl.exec_cmd("walker --gapplication-service")
          hl.exec_cmd("wl-paste --type text  --watch cliphist store")
          hl.exec_cmd("wl-paste --type image --watch cliphist store")
          -- Apply the dark color-scheme so GTK/libadwaita apps render in dark mode.
          -- Use the real "Adwaita" theme (there is no GTK4 "Adwaita-dark"); dark
          -- comes from color-scheme=prefer-dark. Naming Adwaita-dark breaks the
          -- Nautilus sidebar/dialogs under GTK4/libadwaita.
          hl.exec_cmd("gsettings set org.gnome.desktop.interface color-scheme prefer-dark")
          hl.exec_cmd("gsettings set org.gnome.desktop.interface gtk-theme Adwaita")
          -- Pin the UI fonts to the GNOME defaults. A leftover config had bumped
          -- these to "Source Sans Pro 13" / "Maple Mono NF 13", which enlarged the
          -- GTK chrome of apps like Firefox (bigger toolbar/buttons; web content
          -- unaffected). Neither font is installed here, so the size-13 just
          -- applied to fallback fonts.
          hl.exec_cmd("gsettings set org.gnome.desktop.interface font-name 'Adwaita Sans 11'")
          hl.exec_cmd("gsettings set org.gnome.desktop.interface document-font-name 'Adwaita Sans 12'")
          hl.exec_cmd("gsettings set org.gnome.desktop.interface monospace-font-name 'Adwaita Mono 11'")
          -- Pin the cursor to Rose Pine (BreezeX-RosePine-Linux) size 24 for
          -- GTK4/libadwaita apps (they read gsettings). Matches gtk settings.ini
          -- and the XCURSOR_THEME below; package comes from home/programs/gtk.
          hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-theme BreezeX-RosePine-Linux")
          hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-size 24")
      end)

      -------------------------------
      ---- ENVIRONMENT VARIABLES ----
      -------------------------------
      -- Set the cursor theme explicitly so Hyprland uses Rose Pine consistently
      -- (and doesn't fall back to whatever is left in the gsettings/dconf value).
      hl.env("XCURSOR_THEME", "BreezeX-RosePine-Linux")
      hl.env("XCURSOR_SIZE", "24")
      hl.env("HYPRCURSOR_SIZE", "24")

      -----------------------
      ---- LOOK AND FEEL ----
      -----------------------
      hl.config({
          general = {
              gaps_in     = 5,
              gaps_out    = 10,
              border_size = 2,
              col = {
                  active_border   = { colors = { "rgba(89b4faee)", "rgba(cba6f7ee)" }, angle = 45 },
                  inactive_border = "rgba(45475aaa)",
              },
              resize_on_border = true,
              allow_tearing    = false,
              layout           = "dwindle",
          },

          decoration = {
              rounding         = 10,
              active_opacity   = 1.0,
              inactive_opacity = 1.0,
              -- Dim the rest of the screen while the scratchpad (Super+S) is open.
              dim_special      = 0.3,
              shadow = {
                  enabled      = true,
                  range        = 4,
                  render_power = 3,
                  color        = 0xee1a1a1a,
              },
              blur = {
                  enabled  = true,
                  size     = 3,
                  passes   = 1,
                  vibrancy = 0.1696,
                  -- Frosted-glass look behind the scratchpad/special workspace,
                  -- with film-grain noise ("granulado") when it's active.
                  special  = true,
                  noise    = 0.08,
              },
          },

          animations = { enabled = true },

          dwindle = { preserve_split = true },
          master  = { new_status = "master" },

          misc = {
              force_default_wallpaper = 0,
              disable_hyprland_logo   = true,
          },

          -- Cursor: keep it visible (fixes the pointer disappearing when idle).
          cursor = {
              no_hardware_cursors = true,
              inactive_timeout    = 0,
              hide_on_key_press   = false,
              hide_on_touch       = false,
          },
      })

      -- Animation curves and leaves.
      hl.curve("easeOutQuint",   { type = "bezier", points = { { 0.23, 1 },    { 0.32, 1 } } })
      hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
      hl.curve("linear",         { type = "bezier", points = { { 0, 0 },       { 1, 1 } } })

      hl.animation({ leaf = "windows",    enabled = true, speed = 4.79, bezier = "easeOutQuint" })
      hl.animation({ leaf = "windowsIn",  enabled = true, speed = 4.1,  bezier = "easeOutQuint", style = "popin 87%" })
      hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.49, bezier = "linear",       style = "popin 87%" })
      hl.animation({ leaf = "fade",       enabled = true, speed = 3.03, bezier = "easeOutQuint" })
      hl.animation({ leaf = "workspaces", enabled = true, speed = 1.94, bezier = "easeOutQuint", style = "slide" })
      hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 2.0, bezier = "easeOutQuint", style = "slidevert" })
      hl.animation({ leaf = "border",     enabled = true, speed = 5.39, bezier = "easeOutQuint" })

      ---------------
      ---- INPUT ----
      ---------------
      hl.config({
          input = {
              kb_layout   = "br",
              kb_variant  = "",
              follow_mouse = 1,
              sensitivity = 0.5,
              touchpad = {
                  natural_scroll       = true,
                  disable_while_typing = true,
                  tap_to_click         = true,
              },
          },
      })

      -- Touchpad 3-finger horizontal swipe to switch workspaces.
      hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

      ---------------------
      ---- KEYBINDINGS ----
      ---------------------
      local mainMod = "SUPER"

      -- Window management
      hl.bind(mainMod .. " + W", hl.dsp.window.close(), { description = "Close focused window" })
      -- Log out. hl.dsp.exit() only tells the compositor to quit; without a
      -- session manager (UWSM) that does NOT reliably drop back to the SDDM
      -- greeter. Terminating the systemd login session directly does, and is
      -- independent of Hyprland's exit path. $XDG_SESSION_ID is inherited from
      -- the session Hyprland was started in; the command runs via /bin/sh.
      hl.bind(mainMod .. " + Delete", hl.dsp.exec_cmd("loginctl terminate-session $XDG_SESSION_ID"), { description = "Log out of the Hyprland session" })
      hl.bind(mainMod .. " + T", hl.dsp.window.float({ action = "toggle" }), { description = "Toggle tiling/floating" })
      -- Walker runs as a single persistent service, so the wallpaper picker's
      -- larger window size (it launches with --maxheight/--maxwidth) would carry
      -- over to this launcher. Re-assert the default size here so the app
      -- launcher always opens compact.
      hl.bind(mainMod .. " + space", hl.dsp.exec_cmd(menu .. " --maxheight 400 --maxwidth 500"))
      hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
      hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ action = "toggle" }))
      hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("hyprlock"))

      -- Cycle through the wallpapers in ~/Pictures/wallpaper
      hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd("wallpaper-cycle"), { description = "Next wallpaper" })

      -- Pick a wallpaper from a walker menu
      hl.bind(mainMod .. " + CTRL + space", hl.dsp.exec_cmd("wallpaper-menu"), { description = "Wallpaper picker" })

      -- Main use cases
      hl.bind(mainMod .. " + Q", hl.dsp.focus({ workspace = "previous" }), { description = "Previous workspace" })
      hl.bind(mainMod .. " + Tab", hl.dsp.focus({ workspace = "e+1" }), { description = "Next workspace" })
      hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal), { description = "Terminal" })

      -- Application bindings
      -- Nautilus is single-instance: plain "nautilus" just raises the existing
      -- window, so pass --new-window to always open a fresh one.
      hl.bind(mainMod .. " + SHIFT + F", hl.dsp.exec_cmd(fileManager .. " --new-window"), { description = "File manager (new window)" })
      hl.bind(mainMod .. " + SHIFT + B", hl.dsp.exec_cmd(browser), { description = "Browser" })
      hl.bind(mainMod .. " + SHIFT + ALT + B", hl.dsp.exec_cmd(browser .. " --private-window"), { description = "Browser (private)" })
      hl.bind(mainMod .. " + SHIFT + M", hl.dsp.exec_cmd("spotify"), { description = "Music" })
      hl.bind(mainMod .. " + SHIFT + N", hl.dsp.exec_cmd("code"), { description = "Editor" })
      hl.bind(mainMod .. " + SHIFT + D", hl.dsp.exec_cmd(terminal .. " -e lazydocker"), { description = "Docker" })
      hl.bind(mainMod .. " + SHIFT + E", hl.dsp.exec_cmd(terminal .. " -e btop"), { description = "System monitor (btop)" })
      hl.bind(mainMod .. " + SHIFT + T", hl.dsp.exec_cmd(terminal .. " -e torlnk"), { description = "Torlink (torrents)" })
      hl.bind(mainMod .. " + SHIFT + O", hl.dsp.exec_cmd("obsidian"), { description = "Obsidian" })
      hl.bind(mainMod .. " + SHIFT + P", hl.dsp.exec_cmd("readest"), { description = "Reader" })

      -- Clipboard history (via walker dmenu)
      hl.bind(mainMod .. " + C", hl.dsp.exec_cmd([[cliphist list | walker --dmenu | cliphist decode | wl-copy]]))

      -- Cycle through windows with Alt + Tab
      hl.bind("ALT + Tab", function()
          hl.dispatch(hl.dsp.window.cycle_next())
          hl.dispatch(hl.dsp.window.bring_to_top())
      end)
      hl.bind("ALT + SHIFT + Tab", function()
          hl.dispatch(hl.dsp.window.cycle_next({ prev = true }))
          hl.dispatch(hl.dsp.window.bring_to_top())
      end)

      -- Move focus with mainMod + arrow keys
      hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
      hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
      hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
      hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

      -- Move windows with mainMod + SHIFT + arrow keys
      hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.window.move({ direction = "left" }))
      hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" }))
      hl.bind(mainMod .. " + SHIFT + up",    hl.dsp.window.move({ direction = "up" }))
      hl.bind(mainMod .. " + SHIFT + down",  hl.dsp.window.move({ direction = "down" }))

      -- Switch workspaces with mainMod + [0-9], move with mainMod + SHIFT + [0-9]
      for i = 1, 10 do
          local key = i % 10 -- 10 maps to key 0
          hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
          hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
      end

      -- Scratchpad (special) workspace
      hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"), { description = "Show scratchpad" })
      hl.bind(mainMod .. " + ALT + S", hl.dsp.window.move({ workspace = "special:magic" }), { description = "Move window to scratchpad" })

      -- Move/resize windows with mainMod + LMB/RMB and dragging
      hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
      hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

      -- Screenshots (save to ~/Pictures/Screenshots + copy to clipboard + notify)
      -- Super+Shift+S = region | Super+Shift+P = full screen | Print also works if your keyboard has it
      hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd([[mkdir -p ~/Pictures/Screenshots && f=~/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).png && grim -g "$(slurp)" "$f" && wl-copy < "$f" && notify-send "Screenshot" "Região salva em $f"]]))
      hl.bind("Print", hl.dsp.exec_cmd([[mkdir -p ~/Pictures/Screenshots && f=~/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).png && grim "$f" && wl-copy < "$f" && notify-send "Screenshot" "Tela salva em $f"]]))
      hl.bind(mainMod .. " + SHIFT + Print", hl.dsp.exec_cmd([[mkdir -p ~/Pictures/Screenshots && f=~/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).png && grim -g "$(slurp)" "$f" && wl-copy < "$f" && notify-send "Screenshot" "Região salva em $f"]]))
      hl.bind(mainMod .. " + Print", hl.dsp.exec_cmd("hyprpicker -a"), { description = "Color picker" })

      -- Emoji / symbol picker (walker symbols provider)
      hl.bind(mainMod .. " + CTRL + E", hl.dsp.exec_cmd("walker -m symbols"))

      -- Media & hardware keys (work even when locked)
      hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("pamixer -i 5"), { locked = true, repeating = true })
      hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("pamixer -d 5"), { locked = true, repeating = true })
      hl.bind("ALT + XF86AudioRaiseVolume", hl.dsp.exec_cmd("pamixer -i 1"), { locked = true, repeating = true })
      hl.bind("ALT + XF86AudioLowerVolume", hl.dsp.exec_cmd("pamixer -d 1"), { locked = true, repeating = true })
      hl.bind("XF86AudioMute", hl.dsp.exec_cmd("pamixer -t"), { locked = true })
      hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("pamixer --default-source -t"), { locked = true })
      hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl s 5%+"), { locked = true, repeating = true })
      hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl s 5%-"), { locked = true, repeating = true })
      hl.bind("ALT + XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl s 1%+"), { locked = true, repeating = true })
      hl.bind("ALT + XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl s 1%-"), { locked = true, repeating = true })
      hl.bind("SHIFT + XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl s 100%"), { locked = true })
      hl.bind("SHIFT + XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl s 1%"), { locked = true })

      hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
      hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
      hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
      hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

      --------------------------------
      ---- WINDOWS AND WORKSPACES ----
      --------------------------------
      hl.window_rule({
          name           = "suppress-maximize",
          match          = { class = ".*" },
          suppress_event = "maximize",
      })
      hl.window_rule({ match = { class = "^(pavucontrol)$" }, float = true })
      hl.window_rule({ match = { class = "^(nm-connection-editor)$" }, float = true })
      hl.window_rule({ match = { title = "^(Open File)$" }, float = true })
    '';
    "hypr/hyprlock.conf".text = ''
      # Hyprlock - screen locker (https://wiki.hyprland.org/Hypr-Ecosystem/hyprlock/)
      background {
          monitor =
          color = rgba(1e1e2eff)
          blur_passes = 2
          blur_size = 7
      }

      input-field {
          monitor =
          size = 280, 50
          outline_thickness = 2
          dots_size = 0.2
          dots_spacing = 0.3
          outer_color = rgba(89b4faff)
          inner_color = rgba(313244ff)
          font_color = rgba(cdd6f4ff)
          placeholder_text = <i>Password...</i>
          fade_on_empty = false
          position = 0, -40
          halign = center
          valign = center
      }

      # Clock
      label {
          monitor =
          text = cmd[update:1000] echo "$(date +'%H:%M')"
          color = rgba(cdd6f4ff)
          font_size = 90
          font_family = JetBrainsMono Nerd Font
          position = 0, 120
          halign = center
          valign = center
      }

      # Date
      label {
          monitor =
          text = cmd[update:60000] echo "$(date +'%A, %d %B')"
          color = rgba(a6adc8ff)
          font_size = 22
          font_family = JetBrainsMono Nerd Font
          position = 0, 40
          halign = center
          valign = center
      }
    '';
    "hypr/hypridle.conf".text = ''
      # Hypridle - idle daemon (https://wiki.hyprland.org/Hypr-Ecosystem/hypridle/)
      general {
          lock_cmd = pidof hyprlock || hyprlock       # avoid starting multiple locks
          before_sleep_cmd = loginctl lock-session     # lock before suspend
          after_sleep_cmd = hyprctl dispatch dpms on   # turn screen back on after wake
      }

      listener {
          timeout = 300                                # 5 min -> dim
          on-timeout = brightnessctl -s set 10%
          on-resume = brightnessctl -r
      }

      listener {
          timeout = 360                                # 6 min -> lock
          on-timeout = loginctl lock-session
      }

      listener {
          timeout = 600                                # 10 min -> screen off
          on-timeout = hyprctl dispatch dpms off
          on-resume = hyprctl dispatch dpms on
      }
    '';
  };
}
