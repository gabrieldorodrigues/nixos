{ config, lib, pkgs, ... }:

let
  # Walker (v2.16) loads a theme's style.css verbatim — there is NO CSS
  # inheritance from the default theme (see src/theme/mod.rs `setup_css`, which
  # does `load_from_file` then returns). So a custom theme's style.css must be
  # complete. We take Walker's bundled default stylesheet, recolour its five
  # base @define-color values to match the Waybar palette (Catppuccin Mocha),
  # then append a few rules for the search box and selection.
  waybarBaseCss = builtins.replaceStrings
    [ "#1f1f28" "#54546d" "#f2ecbc" "#C34043" "#DCD7BA" ]
    [ "#1e1e2e" "#cdd6f4" "#cdd6f4" "#f38ba8" "#1e1e2e" ]
    (builtins.readFile "${pkgs.walker.src}/resources/themes/default/style.css");

  # Same colours as home/programs/waybar (base #1e1e2e, foreground #cdd6f4).
  # The bar is monochrome: hover/active states are just the foreground at a low
  # alpha, so we mirror that here instead of using a coloured accent.
  waybarExtraCss = ''
    /* --- Match the Waybar palette (Catppuccin Mocha, monochrome) --- */
    @define-color base       #1e1e2e;   /* waybar @background */
    @define-color foreground #cdd6f4;   /* waybar @foreground */

    window .search-container,
    window .search {
      background: alpha(@foreground, 0.06);
      box-shadow: 0 4px 18px rgba(0, 0, 0, 0.2);
      color: @foreground;
      border: 1px solid alpha(@foreground, 0.15);
      border-radius: 12px;
      padding: 6px 16px;
      margin-top: 1px;
    }

    /* Let the search-container's background show through (no box-in-box). */
    .input {
      background: transparent;
    }

    .box-wrapper {
      border-radius: 24px;
    }

    /* Remove the default per-item-box tint so selection is a single surface. */
    child:selected .item-box,
    row:selected .item-box {
      background: transparent;
    }

    /* Selection mirrors the Waybar hover/active language: a translucent
       foreground fill. Border via inset box-shadow so selecting an item never
       shifts the layout (a real border would add a pixel). */
    child:selected,
    row:selected {
      border-radius: 12px;
      background-color: alpha(@foreground, 0.12);
      box-shadow: inset 0 0 0 1px alpha(@foreground, 0.18);
      transition: background-color 0.2s cubic-bezier(0.22, 1, 0.36, 1);
    }

    child:selected .item-box *,
    row:selected .item-box * {
      color: @foreground;
    }
  '';
in
{
  # Walker application launcher config (replaces Rofi).
  # Walker is the GTK4 frontend; the `elephant` daemon is its data backend and
  # must be running (both are autostarted from hypr/hyprland.lua). Providers
  # (drun, calc, files, clipboard, symbols/emoji, dmenu, ...) ship with elephant.
  # Docs: https://github.com/abenz1267/walker
  xdg.configFile = {
    # Main config: pin the theme, help Walker locate it, and set placeholders.
    "walker/config.toml".text = ''
      theme = "waybar"
      additional_theme_location = "~/.config/walker/themes"

      [placeholders]
      "default" = { input = "Search...", list = "No results" }
    '';

    # Complete theme stylesheet: recoloured Walker default + Waybar-palette rules.
    "walker/themes/waybar/style.css".text =
      waybarBaseCss + "\n" + waybarExtraCss;
  };
}

