# Shell configuration: fish (default) + zsh, Tide prompt and plugins.
{ config, pkgs, ... }:

let
  # `update` wrapper: rebuild the system from the flake. Any extra arguments
  # (e.g. --show-trace) are forwarded to nixos-rebuild. Since the DMS migration
  # there are no desktop helpers left to refresh (walker/elephant/waybar removed).
  nixosUpdate = pkgs.writeShellScriptBin "nixos-update" ''
    sudo nixos-rebuild switch --flake /etc/nixos#nixos "$@"
  '';

  # `update-packages` = atualiza o flake.lock de todos os inputs, MENOS o
  # nixpkgs-unstable, que fica fixado de propósito (ABI do hyprglass; ver o
  # comentário no flake.nix). Rodar `nix flake update` puro bumpa o unstable e
  # quebra o plugin ("GLIBCXX_... not found"). Depois disso, use `update`.
  nixosUpdatePackages = pkgs.writeShellScriptBin "nixos-update-packages" ''
    set -e
    unstable_rev="f13ff45afd1bb73e640eaa08a7066dbed07e3238"
    echo "Atualizando inputs (nixpkgs-unstable permanece fixado)..."
    nix flake update --flake /etc/nixos \
      --override-input nixpkgs-unstable "github:NixOS/nixpkgs/$unstable_rev"
    echo "flake.lock atualizado. Rode 'update' para aplicar ao sistema."
  '';
in
{
  # Fish shell as the main interactive shell.
  programs.fish = {
    enable = true;

    shellAliases = {
      # `nixos-update` = rebuild do sistema a partir do flake (ver o let acima).
      update = "nixos-update";
      # `nixos-update-packages` = bump dos inputs sem tocar no unstable fixado.
      update-packages = "nixos-update-packages";
      ll = "ls -lah";
    };

    # Abbreviations expand inline as you type (nicer than aliases in fish).
    shellAbbrs = {
      ".." = "cd ..";
      gs = "git status";
      ga = "git add";
      gc = "git commit";
      gp = "git push";
      gl = "git pull";
    };

    interactiveShellInit = ''
      # Disable the default fish greeting.
      set -g fish_greeting

      # Configure the Tide prompt once with a nice preset.
      if not set -q tide_left_prompt_items
        tide configure --auto \
          --style=Lean \
          --prompt_colors='True color' \
          --show_time='24-hour format' \
          --lean_prompt_height='Two lines' \
          --prompt_connection=Disconnected \
          --prompt_spacing=Sparse \
          --icons='Many icons' \
          --transient=Yes
      end

      # zoxide (smart cd) integration.
      zoxide init fish | source

      # Chave da API NVIDIA NIM (usada pelo opencode). Lida de um arquivo fora
      # do repositório para não versionar segredos.
      if test -r "$HOME/.config/secrets/nvidia-api-key"
          set -gx NVIDIA_API_KEY (string trim <"$HOME/.config/secrets/nvidia-api-key")
      end
    '';
  };

  # Fish plugins (auto-loaded from vendor dirs by fish on NixOS).
  environment.systemPackages = with pkgs; [
    nixosUpdate               # `update` wrapper: rebuild do sistema a partir do flake
    nixosUpdatePackages       # `update-packages`: bump dos inputs (unstable fixado)
    fishPlugins.tide          # prompt
    fishPlugins.fzf-fish      # fzf key bindings (Ctrl+R, Ctrl+T, etc.)
    fishPlugins.autopair      # auto-close brackets/quotes
    fishPlugins.sponge        # remove failed commands from history
    fishPlugins.colored-man-pages
  ];

  # Keep zsh available as a fallback shell.
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    shellAliases = {
      update = "nixos-update";
      update-packages = "nixos-update-packages";
      ll = "ls -lah";
      ".." = "cd ..";
    };
    histSize = 10000;
    ohMyZsh = {
      enable = true;
      plugins = [ "git" "sudo" "history" ];
    };
  };

  # Force fish as $SHELL for graphical terminals (kitty, VS Code).
  environment.sessionVariables.SHELL = "/run/current-system/sw/bin/fish";
}
