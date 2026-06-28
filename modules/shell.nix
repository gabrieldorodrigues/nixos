# Shell configuration: fish (default) + zsh, Tide prompt and plugins.
{ config, pkgs, ... }:

{
  # Fish shell as the main interactive shell.
  programs.fish = {
    enable = true;

    shellAliases = {
      update = "sudo nixos-rebuild switch --flake /etc/nixos#nixos";
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
    '';
  };

  # Fish plugins (auto-loaded from vendor dirs by fish on NixOS).
  environment.systemPackages = with pkgs; [
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
      update = "sudo nixos-rebuild switch --flake /etc/nixos#nixos";
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
