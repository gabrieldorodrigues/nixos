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
local terminal    = "alacritty"
local fileManager = "nautilus"
local menu        = "rofi -show drun"
local browser     = "zen"

-------------------
---- AUTOSTART ----
-------------------
hl.on("hyprland.start", function()
    hl.exec_cmd("waybar")
    hl.exec_cmd("wallpaper-init")
    hl.exec_cmd("mako")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("nm-applet --indicator")
    hl.exec_cmd("wl-paste --type text  --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
    -- Apply the dark color-scheme so GTK/libadwaita apps render in dark mode.
    hl.exec_cmd("gsettings set org.gnome.desktop.interface color-scheme prefer-dark")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface gtk-theme Adwaita-dark")
end)

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------
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
hl.animation({ leaf = "border",     enabled = true, speed = 5.39, bezier = "easeOutQuint" })

---------------
---- INPUT ----
---------------
hl.config({
    input = {
        kb_layout   = "br",
        kb_variant  = "",
        follow_mouse = 1,
        sensitivity = 0,
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
hl.bind(mainMod .. " + Delete", hl.dsp.exit(), { description = "Log out of the Hyprland session" })
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + T", hl.dsp.window.float({ action = "toggle" }), { description = "Toggle tiling/floating" })
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + space", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ action = "toggle" }))
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("hyprlock"))

-- Cycle through the wallpapers in ~/Pictures/wallpaper
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd("wallpaper-cycle"), { description = "Next wallpaper" })

-- Pick a wallpaper from a rofi menu
hl.bind(mainMod .. " + CTRL + space", hl.dsp.exec_cmd("wallpaper-menu"), { description = "Wallpaper picker" })

-- Main use cases
hl.bind(mainMod .. " + Q", hl.dsp.focus({ workspace = "previous" }), { description = "Previous workspace" })
hl.bind(mainMod .. " + Tab", hl.dsp.focus({ workspace = "e+1" }), { description = "Next workspace" })
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal), { description = "Terminal" })
hl.bind(mainMod .. " + ALT + Return", hl.dsp.exec_cmd(terminal .. [[ -e bash -c "tmux attach || tmux new -s Work"]]), { description = "Tmux" })

-- Application bindings
hl.bind(mainMod .. " + SHIFT + Return", hl.dsp.exec_cmd(browser), { description = "Browser" })
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.exec_cmd(fileManager), { description = "File manager" })
hl.bind(mainMod .. " + SHIFT + B", hl.dsp.exec_cmd(browser), { description = "Browser" })
hl.bind(mainMod .. " + SHIFT + ALT + B", hl.dsp.exec_cmd(browser .. " --private-window"), { description = "Browser (private)" })
hl.bind(mainMod .. " + SHIFT + M", hl.dsp.exec_cmd("spotify"), { description = "Music" })
hl.bind(mainMod .. " + SHIFT + N", hl.dsp.exec_cmd("code"), { description = "Editor" })
hl.bind(mainMod .. " + SHIFT + D", hl.dsp.exec_cmd(terminal .. " -e lazydocker"), { description = "Docker" })
hl.bind(mainMod .. " + SHIFT + O", hl.dsp.exec_cmd("obsidian"), { description = "Obsidian" })
hl.bind(mainMod .. " + SHIFT + P", hl.dsp.exec_cmd("readest"), { description = "Reader" })

-- Clipboard history (via rofi)
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd([[cliphist list | rofi -dmenu | cliphist decode | wl-copy]]))

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

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Screenshots (save to ~/Pictures/Screenshots + copy to clipboard + notify)
-- Super+Shift+S = region | Super+Shift+P = full screen | Print also works if your keyboard has it
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd([[mkdir -p ~/Pictures/Screenshots && f=~/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).png && grim -g "$(slurp)" "$f" && wl-copy < "$f" && notify-send "Screenshot" "Região salva em $f"]]))
hl.bind("Print", hl.dsp.exec_cmd([[mkdir -p ~/Pictures/Screenshots && f=~/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).png && grim "$f" && wl-copy < "$f" && notify-send "Screenshot" "Tela salva em $f"]]))
hl.bind(mainMod .. " + SHIFT + Print", hl.dsp.exec_cmd([[mkdir -p ~/Pictures/Screenshots && f=~/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).png && grim -g "$(slurp)" "$f" && wl-copy < "$f" && notify-send "Screenshot" "Região salva em $f"]]))
hl.bind(mainMod .. " + Print", hl.dsp.exec_cmd("hyprpicker -a"), { description = "Color picker" })

-- Emoji / symbol picker
hl.bind(mainMod .. " + CTRL + E", hl.dsp.exec_cmd("rofimoji"))

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
