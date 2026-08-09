{ pkgs, ... }:

let
  # btop lê a GPU NVIDIA via NVML, que ele carrega em runtime com
  # dlopen("libnvidia-ml.so"). No NixOS essa lib mora em /run/opengl-driver/lib,
  # que NÃO está no runpath do binário do Nix — por isso o dlopen falha e a box
  # da GPU não aparece, mesmo com o driver proprietário ativo e o nvidia-smi
  # funcionando. Envolvemos o btop injetando esse diretório no LD_LIBRARY_PATH.
  btopWithGpu = pkgs.symlinkJoin {
    name = "btop-gpu";
    paths = [ pkgs.btop ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/btop \
        --prefix LD_LIBRARY_PATH : /run/opengl-driver/lib
    '';
  };

  # Official Catppuccin Mocha palette, matching the rest of the rice
  # (waybar / walker / kitty). Source: github.com/catppuccin/btop.
  catppuccinMocha = ''
    # Main background, empty for terminal default, need to be empty if you want transparent background
    theme[main_bg]="#1e1e2e"

    # Main text color
    theme[main_fg]="#cdd6f4"

    # Title color for boxes
    theme[title]="#cdd6f4"

    # Highlight color for keyboard shortcuts
    theme[hi_fg]="#89b4fa"

    # Background color of selected item in processes box
    theme[selected_bg]="#45475a"

    # Foreground color of selected item in processes box
    theme[selected_fg]="#89b4fa"

    # Color of inactive/disabled text
    theme[inactive_fg]="#7f849c"

    # Color of text appearing on top of graphs, i.e uptime and current network graph scaling
    theme[graph_text]="#f5e0dc"

    # Background color of the percentage meters
    theme[meter_bg]="#45475a"

    # Misc colors for processes box including mini cpu graphs, details memory graph and details status text
    theme[proc_misc]="#f5e0dc"

    # CPU, Memory, Network, Proc box outline colors
    theme[cpu_box]="#cba6f7" #Mauve
    theme[mem_box]="#a6e3a1" #Green
    theme[net_box]="#eba0ac" #Maroon
    theme[proc_box]="#89b4fa" #Blue

    # Box divider line and small boxes line color
    theme[div_line]="#6c7086"

    # Temperature graph color (Green -> Yellow -> Red)
    theme[temp_start]="#a6e3a1"
    theme[temp_mid]="#f9e2af"
    theme[temp_end]="#f38ba8"

    # CPU graph colors (Teal -> Lavender)
    theme[cpu_start]="#94e2d5"
    theme[cpu_mid]="#74c7ec"
    theme[cpu_end]="#b4befe"

    # Mem/Disk free meter (Mauve -> Lavender -> Blue)
    theme[free_start]="#cba6f7"
    theme[free_mid]="#b4befe"
    theme[free_end]="#89b4fa"

    # Mem/Disk cached meter (Sapphire -> Lavender)
    theme[cached_start]="#74c7ec"
    theme[cached_mid]="#89b4fa"
    theme[cached_end]="#b4befe"

    # Mem/Disk available meter (Peach -> Red)
    theme[available_start]="#fab387"
    theme[available_mid]="#eba0ac"
    theme[available_end]="#f38ba8"

    # Mem/Disk used meter (Green -> Sky)
    theme[used_start]="#a6e3a1"
    theme[used_mid]="#94e2d5"
    theme[used_end]="#89dceb"

    # Download graph colors (Peach -> Red)
    theme[download_start]="#fab387"
    theme[download_mid]="#eba0ac"
    theme[download_end]="#f38ba8"

    # Upload graph colors (Green -> Sky)
    theme[upload_start]="#a6e3a1"
    theme[upload_mid]="#94e2d5"
    theme[upload_end]="#89dceb"

    # Process box color gradient for threads, mem and cpu usage (Sapphire -> Mauve)
    theme[process_start]="#74c7ec"
    theme[process_mid]="#b4befe"
    theme[process_end]="#cba6f7"
  '';
in
{
  # btop system monitor, managed by Home Manager so its Catppuccin Mocha theme
  # lives in this folder (same pattern as kitty).
  programs.btop = {
    enable = true;
    package = btopWithGpu;
    settings = {
      color_theme = "catppuccin_mocha";
      # Let the (already themed) terminal background show through.
      theme_background = false;
      # --- GPU (NVIDIA RTX 2060) ---
      # btop já é compilado com suporte a GPU (BTOP_GPU=ON) e lê a NVIDIA via
      # NVML, que vem do driver proprietário (ver modules/nvidia.nix). Mostra a
      # box da GPU embutida na box da CPU e no modo de preset abaixo.
      show_gpu_info = "On";
      gpu_mirror_graph = true;
      # Presets: preset 0 mostra cpu(+gpu)/mem/net/proc; alterne com Shift+P.
      presets = "cpu:1:default,proc:0:default cpu:0:default,mem:0:default,net:0:default gpu:0:default";
    };
  };

  xdg.configFile."btop/themes/catppuccin_mocha.theme".text = catppuccinMocha;
}
