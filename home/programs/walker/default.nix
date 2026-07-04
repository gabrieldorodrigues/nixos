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

    /* --- Wallpaper picker (Super+Ctrl+Space, provider menus:wallpapers) --- */
    /* Shown as a 3-column grid (see config.toml [columns]). In grid mode Walker
       uses its built-in item layout, whose thumbnail is a GtkImage. The entries
       carry no Text/Subtext and the picker is launched with --hideqa, so only
       the landscape thumbnail shows. The picker window is widened per-launch
       (--maxwidth, in the wallpaper-menu script) so the three previews are big. */
    .menus-wallpapers {
      padding: 6px;
    }
    .menus-wallpapers .item-image {
      -gtk-icon-size: 260px;
      border-radius: 10px;
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

      # Render the wallpaper picker (provider menus:wallpapers) as a 3-wide grid
      # instead of one-per-row. Walker switches a provider to grid mode whenever
      # its configured column count is greater than 1.
      [columns]
      "menus:wallpapers" = 3

      [placeholders]
      "default" = { input = "Search...", list = "No results" }
    '';

    # Complete theme stylesheet: recoloured Walker default + Waybar-palette rules.
    "walker/themes/waybar/style.css".text =
      waybarBaseCss + "\n" + waybarExtraCss;

    # Item layout for the wallpaper menu (provider "menus:wallpapers"). Walker
    # renders each entry's Icon (an absolute image path) as a thumbnail; this
    # layout intentionally has ONLY the image (no ItemText/ItemSubtext labels),
    # so the picker shows just the wallpaper thumbnails.
    "walker/themes/waybar/item_menus-wallpapers.xml".text = ''
      <?xml version="1.0" encoding="UTF-8"?>
      <interface>
        <object class="GtkBox" id="ItemBox">
          <property name="halign">center</property>
          <property name="hexpand">true</property>
          <child>
            <object class="GtkPicture" id="ItemImage">
              <property name="width-request">320</property>
              <property name="height-request">180</property>
              <property name="content-fit">cover</property>
              <property name="can-shrink">true</property>
            </object>
          </child>
        </object>
      </interface>
    '';

    # Elephant "wallpapers" menu, opened with `walker --provider menus:wallpapers`
    # (via the wallpaper-menu script, bound to Super+Ctrl+Space). Lists the
    # images in ~/Pictures/wallpaper; selecting one applies it with awww.
    #
    # Icons are cached PNG thumbnails, NOT the originals: walker decodes icons
    # with gdk-pixbuf, which has no webp loader here and PANICS (aborting the
    # whole launcher) on any format it can't read. Thumbnailing every entry to
    # PNG makes the picker crash-proof and fast regardless of source format.
    "elephant/menus/wallpapers.lua".text = ''
      Name = "wallpapers"
      NamePretty = "Wallpapers"
      Icon = "preferences-desktop-wallpaper"
      Description = "Pick a wallpaper"
      -- Default action: apply the chosen wallpaper via awww. %VALUE% is the
      -- entry's Value (the ORIGINAL image path), substituted by elephant.
      Action = "${pkgs.awww}/bin/awww img '%VALUE%' --transition-type fade --transition-fps 60 --transition-duration 1"

      local function q(s)
          return "'" .. s .. "'"
      end

      function GetEntries()
          local entries = {}
          local home = os.getenv("HOME")
          local cache = os.getenv("XDG_CACHE_HOME")
          if cache == nil or cache == "" then
              cache = home .. "/.cache"
          end
          local thumbdir = cache .. "/wallpaper-thumbs"
          os.execute("mkdir -p " .. q(thumbdir))

          local dir = home .. "/Pictures/wallpaper"
          local handle = io.popen("find -L " .. q(dir) .. " -maxdepth 1 -type f | sort")
          if handle then
              for line in handle:lines() do
                  local name = line:match("([^/]+)$")
                  -- Landscape thumbnails (16:9) so the previews look like the
                  -- wallpapers themselves. Walker's grid draws each one in a
                  -- GtkImage; the geometry is part of the filename so changing
                  -- it regenerates the cache.
                  local thumb = thumbdir .. "/" .. name .. "-640x360.png"

                  -- Generate the thumbnail once; nix-store sources never change.
                  local existing = io.open(thumb, "r")
                  if existing then
                      existing:close()
                  else
                      local tmp = thumb .. ".tmp.png"
                      os.execute("${pkgs.imagemagick}/bin/magick " .. q(line) ..
                          " -auto-orient -thumbnail 640x360^ -gravity center -extent 640x360 " ..
                          q(tmp) .. " 2>/dev/null && mv " .. q(tmp) .. " " .. q(thumb) ..
                          " || rm -f " .. q(tmp))
                      local made = io.open(thumb, "r")
                      if made then made:close() else thumb = "" end
                  end

                  -- Text is empty so the grid's built-in layout shows no label
                  -- (only the thumbnail); Keywords keeps search-by-filename.
                  table.insert(entries, {
                      Text = "",
                      Keywords = { name },
                      Value = line,
                      Icon = thumb,
                  })
              end
              handle:close()
          end
          return entries
      end
    '';
  };
}

