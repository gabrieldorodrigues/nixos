{ ... }:

{
  # kitty terminal: managed by Home Manager so the config lives in this folder.
  # Font size is intentionally small (zoom out) and colours match the rest of
  # the Catppuccin Mocha rice (waybar/walker).
  programs.kitty = {
    enable = true;

    font = {
      name = "JetBrainsMono Nerd Font";
      size = 9.0; # zoom out (kitty default is 11.0) — bump if it feels too small
    };

    settings = {
      # --- ergonomics ---
      window_padding_width = 8;
      confirm_os_window_close = 0;
      enable_audio_bell = false;
      cursor_shape = "beam";
      scrollback_lines = 10000;

      # --- Catppuccin Mocha ---
      foreground = "#CDD6F4";
      background = "#1E1E2E";
      selection_foreground = "#1E1E2E";
      selection_background = "#F5E0DC";

      cursor = "#F5E0DC";
      cursor_text_color = "#1E1E2E";
      url_color = "#F5E0DC";

      active_border_color = "#B4BEFE";
      inactive_border_color = "#6C7086";
      bell_border_color = "#F9E2AF";

      wayland_titlebar_color = "#1E1E2E";

      active_tab_foreground = "#11111B";
      active_tab_background = "#CBA6F7";
      inactive_tab_foreground = "#CDD6F4";
      inactive_tab_background = "#181825";
      tab_bar_background = "#11111B";

      # normal
      color0 = "#45475A";
      color1 = "#F38BA8";
      color2 = "#A6E3A1";
      color3 = "#F9E2AF";
      color4 = "#89B4FA";
      color5 = "#F5C2E7";
      color6 = "#94E2D5";
      color7 = "#BAC2DE";
      # bright
      color8 = "#585B70";
      color9 = "#F38BA8";
      color10 = "#A6E3A1";
      color11 = "#F9E2AF";
      color12 = "#89B4FA";
      color13 = "#F5C2E7";
      color14 = "#94E2D5";
      color15 = "#A6ADC8";
    };
  };
}
