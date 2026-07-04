{ ... }:

let
  # Real ESC byte (0x1b). Nix has no \e escape, so decode it from JSON.
  esc = builtins.fromJSON ''"\u001b"'';

  # NixOS snowflake logo with inline truecolor ANSI. We author it with "@" as a
  # stand-in for ESC (keeps the source readable) and swap it for the real byte.
  # Home Manager serialises this string to JSON as \u001b, and fastfetch prints
  # it verbatim thanks to the "data-raw" logo type.
  nixosLogo = builtins.replaceStrings [ "@" ] [ esc ] ''
    @[38;2;82;119;195m       ◢██◣@[38;2;127;183;255m   ◥███◣  ◢██◣
    @[38;2;82;119;195m       ◥███◣@[38;2;127;183;255m   ◥███◣◢███◤
    @[38;2;82;119;195m        ◥███◣@[38;2;127;183;255m   ◥██████◤
    @[38;2;82;119;195m    ◢████████████@[48;2;127;183;255m◣@[0m@[38;2;127;183;255m████◤@[38;2;82;119;195m   ◢◣
    @[38;2;82;119;195m   ◢██████████████@[48;2;127;183;255m◣@[0m@[38;2;127;183;255m███◣@[38;2;82;119;195m  ◢██◣
    @[38;2;127;183;255m        ◢███◤      ◥███◣@[38;2;82;119;195m◢███◤
    @[38;2;127;183;255m       ◢███◤        ◥██@[48;2;82;119;195m◤@[0m@[38;2;82;119;195m███◤
    @[38;2;127;183;255m◢█████████◤          ◥@[48;2;82;119;195m◤@[0m@[38;2;82;119;195m████████◣
    @[38;2;127;183;255m◥████████@[48;2;82;119;195m◤@[0m@[38;2;82;119;195m◣          ◢█████████◤
    @[38;2;127;183;255m    ◢███@[48;2;82;119;195m◤@[0m@[38;2;82;119;195m██◣        ◢███◤
    @[38;2;127;183;255m   ◢███◤@[38;2;82;119;195m◥███◣      ◢███◤
    @[38;2;127;183;255m   ◥██◤  @[38;2;82;119;195m◥███@[48;2;127;183;255m◣@[0m@[38;2;127;183;255m██████████████◤
    @[38;2;127;183;255m    ◥◤   @[38;2;82;119;195m◢████@[48;2;127;183;255m◣@[0m@[38;2;127;183;255m████████████◤
    @[38;2;82;119;195m        ◢██████◣@[38;2;127;183;255m   ◥███◣
    @[38;2;82;119;195m       ◢███◤◥███◣@[38;2;127;183;255m   ◥███◣
    @[38;2;82;119;195m       ◥██◤  ◥███◣@[38;2;127;183;255m   ◥██◤@[0m'';
in
{
  # fastfetch: system info with the custom NixOS logo above.
  programs.fastfetch = {
    enable = true;

    settings = {
      logo = {
        type = "data-raw"; # print the string as-is (keep our ANSI colours)
        source = nixosLogo;
        padding = {
          top = 1;
          left = 2;
          right = 3;
        };
      };

      display = {
        separator = "  ";
      };

      modules = [
        "title"
        "separator"
        "os"
        "host"
        "kernel"
        "uptime"
        "packages"
        "shell"
        "wm"
        "terminal"
        {
          type = "cpu";
          showPeCoreCount = true;
        }
        "gpu"
        "memory"
        "swap"
        "disk"
        "localip"
        "break"
        "colors"
      ];
    };
  };
}
