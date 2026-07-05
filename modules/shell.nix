# Shell configuration: fish (default) + zsh, Tide prompt and plugins.
{ config, pkgs, ... }:

let
  # `update` wrapper: rebuild the system from the flake, then reindex the
  # walker launcher so newly installed apps appear without a re-login. Any
  # extra arguments (e.g. --show-trace) are forwarded to nixos-rebuild. The
  # reindex only runs on a successful rebuild and no-ops outside a graphical
  # session (see reindex-walker in modules/hyprland.nix).
  nixosUpdate = pkgs.writeShellScriptBin "nixos-update" ''
    sudo nixos-rebuild switch --flake /etc/nixos#nixos "$@"
    rc=$?
    if [ "$rc" -eq 0 ]; then
      reindex-walker || true
    fi
    exit "$rc"
  '';
in
{
  # Fish shell as the main interactive shell.
  programs.fish = {
    enable = true;

    shellAliases = {
      # `nixos-update` = rebuild + reindex walker (see the let block above).
      update = "nixos-update";
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
    nixosUpdate               # `update` wrapper: rebuild + reindex walker
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
