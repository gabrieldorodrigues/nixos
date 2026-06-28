{ config, lib, pkgs, ... }:

{
  xdg.configFile."rofi/config.rasi".source = ./config.rasi;
}
