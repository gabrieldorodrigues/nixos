{ config, ... }:

{
  # termusic (TUI music player): managed by Home Manager so o tema fica versionado.
  # termusic guarda o tema ativo embutido em `tui.toml` na seção `[theme]` e lê
  # presets `.yml` (formato Alacritty) de `~/.config/termusic/themes/`. Aqui a
  # gente:
  #   1. disponibiliza o preset Catppuccin Mocha na pasta de temas (aparece no
  #      seletor dentro do app, tecla `shift+C`);
  #   2. deixa esse mesmo tema como o ativo em `tui.toml` (seção `[theme]`).
  #
  # NOTE: como o `tui.toml` vira um symlink read-only pro Nix store, salvar
  # config pela UI do termusic vai falhar. Ajustes de tema/estilo devem ser
  # feitos aqui e reaplicados com o rebuild.

  # server.toml: config do daemon do termusic. Gerenciado aqui só pra fixar o
  # Discord Rich Presence (`set_discord_status`); o resto é o padrão do 0.13.
  # NOTE: read-only symlink pro Nix store — ajustes (ex.: music_dirs) devem ser
  # feitos aqui e reaplicados com o rebuild.
  home.file.".config/termusic/server.toml".text = ''
    version = "2"

    [com]
    protocol = "uds"
    socket_path = "/tmp/termusic.socket"
    port = 5101
    address = "::1"

    [player]
    music_dirs = ["${config.home.homeDirectory}/Music"]
    loop_mode = "playlist"
    volume = 55
    speed = 10
    gapless = false
    use_mediacontrols = true
    set_discord_status = true
    random_track_quantity = 20
    random_album_min_quantity = 5
    backend = "rusty"
    startup_state = "playing"

    [player.remember_position]
    music = "no"
    podcast = "yes"

    [player.seek_step]
    short_tracks = 5
    long_tracks = 30

    [podcast]
    concurrent_downloads_max = 3
    max_download_retries = 3
    download_dir = "${config.home.homeDirectory}/Music/podcast"

    [backends.rusty]
    soundtouch = true
    file_buffer_size = "4.0 MiB"
    decoded_buffer_size = "750.0 KiB"
    output_sample_rate = 48000

    [metadata]
    directory_scan_depth = 10
    artist_separators = [",", ";", "&", "ft.", "feat.", "/", "|", "×", " 、", " x "]
  '';

  # Preset selecionável dentro do app (mesmas cores da seção [theme] abaixo).
  home.file.".config/termusic/themes/catppuccin-mocha.yml".text = ''
    colors:
      name: Catppuccin Mocha
      author: Catppuccin Org
      primary:
        background: "#1E1E2E"
        foreground: "#CDD6F4"
      cursor:
        text: "#1E1E2E"
        cursor: "#F5E0DC"
      normal:
        black: "#45475A"
        red: "#F38BA8"
        green: "#A6E3A1"
        yellow: "#F9E2AF"
        blue: "#89B4FA"
        magenta: "#F5C2E7"
        cyan: "#94E2D5"
        white: "#BAC2DE"
      bright:
        black: "#585B70"
        red: "#F38BA8"
        green: "#A6E3A1"
        yellow: "#F9E2AF"
        blue: "#89B4FA"
        magenta: "#F5C2E7"
        cyan: "#94E2D5"
        white: "#A6ADC8"
  '';

  # tui.toml com o tema Catppuccin Mocha já ativo. O resto (keybinds/estilos)
  # é o padrão do termusic 0.13.
  home.file.".config/termusic/tui.toml".text = ''
    version = "2"
    com = "same"

    [behavior]
    quit_server_on_exit = true
    confirm_quit = true

    [coverart]
    align = "bottom right"
    size_scale = 0
    hidden = false
    protocols = ["iterm2", "kitty", "sixel", "ueberzug"]

    [style.library]
    foreground_color = "Foreground"
    background_color = "Background"
    border_color = "Blue"
    highlight_color = "LightYellow"
    highlight_symbol = "🦄"

    [style.playlist]
    foreground_color = "Foreground"
    background_color = "Background"
    border_color = "Blue"
    highlight_color = "LightYellow"
    highlight_symbol = "🚀"
    current_track_symbol = "►"
    use_loop_mode_symbol = true

    [style.lyric]
    foreground_color = "Foreground"
    background_color = "Background"
    border_color = "Blue"

    [style.progress]
    foreground_color = "LightBlack"
    background_color = "Background"
    border_color = "Blue"

    [style.important_popup]
    foreground_color = "Yellow"
    background_color = "Background"
    border_color = "Yellow"

    [style.fallback]
    foreground_color = "Foreground"
    background_color = "Background"
    border_color = "Blue"
    highlight_color = "LightYellow"

    [theme]
    name = "Catppuccin Mocha"
    author = "Catppuccin Org"

    [theme.primary]
    background = "#1E1E2E"
    foreground = "#CDD6F4"

    [theme.cursor]
    text = "#1E1E2E"
    cursor = "#F5E0DC"

    [theme.normal]
    black = "#45475A"
    red = "#F38BA8"
    green = "#A6E3A1"
    yellow = "#F9E2AF"
    blue = "#89B4FA"
    magenta = "#F5C2E7"
    cyan = "#94E2D5"
    white = "#BAC2DE"

    [theme.bright]
    black = "#585B70"
    red = "#F38BA8"
    green = "#A6E3A1"
    yellow = "#F9E2AF"
    blue = "#89B4FA"
    magenta = "#F5C2E7"
    cyan = "#94E2D5"
    white = "#A6ADC8"

    [keys]
    escape = "escape"
    quit = "q"

    [keys.view]
    view_library = "1"
    view_database = "2"
    view_podcasts = "3"
    open_config = "shift+C"
    open_help = "control+h"

    [keys.navigation]
    up = "k"
    down = "j"
    left = "h"
    right = "l"
    goto_top = "g"
    goto_bottom = "shift+G"

    [keys.global_player]
    toggle_pause = "space"
    next_track = "n"
    previous_track = "shift+N"
    volume_up = "+"
    volume_down = "-"
    seek_forward = "f"
    seek_backward = "b"
    speed_up = "control+f"
    speed_down = "control+b"
    toggle_prefetch = "control+g"
    save_playlist = "control+s"

    [keys.global_lyric]
    adjust_offset_forwards = "shift+F"
    adjust_offset_backwards = "shift+B"
    cycle_frames = "shift+T"

    [keys.library]
    load_track = "l"
    load_dir = "shift+L"
    delete = "d"
    yank = "y"
    paste = "p"
    cycle_root = "o"
    add_root = "a"
    remove_root = "shift+A"
    search = "/"
    youtube_search = "s"
    open_tag_editor = "t"

    [keys.playlist]
    delete = "d"
    delete_all = "shift+D"
    shuffle = "r"
    cycle_loop_mode = "m"
    play_selected = "l"
    search = "/"
    swap_up = "shift+K"
    swap_down = "shift+J"
    add_random_songs = "s"
    add_random_album = "shift+S"

    [keys.database]
    add_selected = "l"
    add_all = "shift+L"

    [keys.podcast]
    search = "s"
    mark_played = "m"
    mark_all_played = "shift+M"
    refresh_feed = "r"
    refresh_all_feeds = "shift+R"
    download_episode = "d"
    delete_local_episode = "shift+D"
    delete_feed = "x"
    delete_all_feeds = "shift+X"

    [keys.adjust_cover_art]
    move_left = "control+shift+arrowleft"
    move_right = "control+shift+arrowright"
    move_up = "control+shift+arrowup"
    move_down = "control+shift+arrowdown"
    increase_size = "control+shift+pageup"
    decrease_size = "control+shift+pagedown"
    toggle_hide = "control+shift+end"

    [keys.config]
    save = "control+s"

    [ytdlp]
    extra_args = ""
  '';
}
