# Git configuration (declarative, system-wide).
{ config, pkgs, ... }:

{
  programs.git = {
    enable = true;
    config = {
      user = {
        name = "gabrieldorodrigues";
        email = "gabriell.dorodrigues@gmail.com";
      };
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
    };
  };
}
