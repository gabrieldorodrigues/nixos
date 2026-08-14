{ config, lib, pkgs, ... }:

let
  # Waybar 0.15.0 envia o dispatch legado "dispatch workspace N" ao clicar numa
  # workspace, o que quebra no IPC Lua do Hyprland >= 0.54 (aqui e 0.55): o
  # Hyprland interpreta o comando como Lua e da erro de sintaxe, entao o clique
  # nao troca de desktop. Reescrevemos o handler de clique (workspace.cpp) para
  # o formato Lua "/dispatch hl.dsp.focus({ workspace = \"N\" })" que o Hyprland
  # Lua aceita. Feito via substituteInPlace (nao um .patch externo) para o build
  # nao depender de um arquivo git-trackeado (/etc/nixos/.git e' root-owned).
  waybarPkg = pkgs.waybar.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      substituteInPlace src/modules/hyprland/workspace.cpp \
        --replace-fail 'm_ipc.getSocket1Reply("dispatch focusworkspaceoncurrentmonitor " + std::to_string(id()));' 'm_ipc.getSocket1Reply("/dispatch hl.dsp.focus({ workspace = \"" + std::to_string(id()) + "\", on_current_monitor = true })");' \
        --replace-fail 'm_ipc.getSocket1Reply("dispatch workspace " + std::to_string(id()));' 'm_ipc.getSocket1Reply("/dispatch hl.dsp.focus({ workspace = \"" + std::to_string(id()) + "\" })");' \
        --replace-fail 'm_ipc.getSocket1Reply("dispatch focusworkspaceoncurrentmonitor name:" + name());' 'm_ipc.getSocket1Reply("/dispatch hl.dsp.focus({ workspace = \"name:" + name() + "\", on_current_monitor = true })");' \
        --replace-fail 'm_ipc.getSocket1Reply("dispatch workspace name:" + name());' 'm_ipc.getSocket1Reply("/dispatch hl.dsp.focus({ workspace = \"name:" + name() + "\" })");' \
        --replace-fail 'm_ipc.getSocket1Reply("dispatch togglespecialworkspace " + name());' 'm_ipc.getSocket1Reply("/dispatch hl.dsp.workspace.toggle_special(\"" + name() + "\")");' \
        --replace-fail 'm_ipc.getSocket1Reply("dispatch togglespecialworkspace");' 'm_ipc.getSocket1Reply("/dispatch hl.dsp.workspace.toggle_special()");'
    '';
  });

  # Catppuccin Mocha palette (replaces the Omarchy theme @import).
  colors = ''
    @define-color background #1e1e2e;
    @define-color foreground #cdd6f4;
  '';

  # Modules + commands for the dock layout.
  # Omarchy helper commands were replaced with the tools available on this host:
  #   btop / nmtui / blueman-manager / pavucontrol / walker / pamixer.
  modulesConfig = ''
    "modules-left": ["custom/launcher", "custom/active_window"],
    "modules-center": [ "group/center3", "hyprland/workspaces", "group/center2" ],
    "modules-right": [ "group/right1" ],

    "group/center2": {
      "orientation": "inherit",
      "modules": [ "clock", "custom/gamemode" ]
    },

    "group/center3": {
      "orientation": "inherit",
      "modules": [ "cpu", "memory", "custom/separator#blank", "image#cover", "custom/media" ]
    },

    "group/right1": {
      "orientation": "inherit",
      "modules": [
        "custom/vpn",
        "custom/dns",
        "pulseaudio",
        "bluetooth",
        "tray",
        "battery"
      ]
    },

    "custom/vpn": {
      "exec": "~/.config/waybar/vpn.sh status",
      "on-click": "kitty --title waybar-vpn-menu -e ~/.config/waybar/vpn.sh menu",
      "on-click-right": "~/.config/waybar/vpn.sh toggle",
      "return-type": "json",
      "interval": 5,
      "signal": 10,
      "tooltip": true
    },

    "custom/dns": {
      "exec": "~/.config/waybar/dns.sh status",
      "on-click": "kitty --title waybar-dns-menu -e ~/.config/waybar/dns.sh menu",
      "on-click-right": "~/.config/waybar/dns.sh toggle",
      "return-type": "json",
      "interval": 5,
      "signal": 9,
      "tooltip": true
    },

    "custom/active_window": {
      "exec": "~/.config/waybar/window.sh",
      "return-type": "json",
      "markup": true
    },

    "tray": {
      "icon-size": 16,
      "spacing": 8,
      "show-passive-items": true,
      "reverse-direction": false
    },

    "hyprland/workspaces": {
      "on-click": "activate",
      "all-outputs": true,
      "sort-by-number": true,
      "format": "{icon}",
      "format-icons": { "default": "○", "active": "●", "empty": "·" },
      "persistent-workspaces": {
        "1": [], "2": [], "3": [], "4": [], "5": [], "6": [], "7": [], "8": []
      }
    },

    "custom/launcher": {
      "format": "<span size='13000'>&#xf313;</span>",
      "on-click": "walker",
      "on-click-right": "kitty",
      "tooltip-format": "NixOS — Apps (Super+Space)"
    },

    "cpu": {
      "interval": 2,
      "format": "{icon} ",
      "format-icons": ["󰪞", "󰪟", "󰪠", "󰪡", "󰪢", "󰪣", "󰪤", "󰪥"],
      "on-click": "kitty -e btop"
    },

    "memory": {
      "interval": 2,
      "format": "{icon} ",
      "format-icons": ["󰪞", "󰪟", "󰪠", "󰪡", "󰪢", "󰪣", "󰪤", "󰪥"],
      "on-click": "kitty -e btop"
    },

    "clock": {
      "interval": 1,
      "locale": "pt_BR.UTF-8",
      "format": " {:L%H:%M:%S • %a, %d/%m}",
      "format-alt": "{:L%A, %d %B %Y}",
      "tooltip-format": "<big>{:L%Y %B}</big>\n<tt><small>{calendar}</small></tt>"
    },

    "battery": {
      "format": "{capacity}% {icon}",
      "format-discharging": "{icon}",
      "format-charging": "{icon}",
      "format-plugged": "",
      "format-icons": {
        "charging": ["󰢜", "󰂆", "󰂇", "󰂈", "󰢝", "󰂉", "󰢞", "󰂊", "󰂋", "󰂅"],
        "default": ["󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]
      },
      "format-full": "󰂅",
      "tooltip-format-discharging": "{power:>1.0f}W↓ {capacity}%",
      "tooltip-format-charging": "{power:>1.0f}W↑ {capacity}%",
      "interval": 5,
      "states": { "warning": 20, "critical": 10 }
    },

    "bluetooth": {
      "format": "<span size='11500'>󰂯</span>",
      "format-disabled": "<span size='11500'>󰂲</span>",
      "format-connected": "<span size='11500'></span>",
      "format-no-controller": "",
      "tooltip-format": "Devices connected: {num_connections}",
      "on-click": "blueman-manager"
    },

    "pulseaudio": {
      "format": "<span size='11500'>{icon}</span>",
      "on-click": "pavucontrol",
      "on-click-right": "pamixer -t",
      "tooltip-format": "Playing at {volume}%",
      "scroll-step": 5,
      "format-muted": "󰝟",
      "format-icons": { "default": ["󰕿", "󰖀", "󰕾"] }
    },

    "custom/separator#blank": { "format": " ", "interval": "once", "tooltip": false },

    "image#cover": {
      "exec": "~/.config/waybar/cover.sh",
      "size": 20,
      "interval": 2,
      "tooltip": false,
      "on-click": "playerctl play-pause"
    },

    "custom/media": {
      "exec": "~/.config/waybar/media.sh",
      "interval": 2,
      "on-click": "playerctl play-pause"
    },

    "custom/gamemode": {
      "exec": "test -f ~/.cache/hypr_gamemode && echo '{\"text\":\"\"}' || echo '{\"text\":\"\"}'",
      "on-click": "test -f ~/.cache/hypr_gamemode && (rm ~/.cache/hypr_gamemode && hyprctl keyword animations:enabled 1 && hyprctl keyword decoration:blur:enabled 1) || (touch ~/.cache/hypr_gamemode && hyprctl keyword animations:enabled 0 && hyprctl keyword decoration:blur:enabled 0)",
      "interval": 1,
      "return-type": "json",
      "tooltip": true,
      "tooltip-format": "GameMode"
    }
  '';

  dockConfig = ''
    {
      "reload_style_on_change": true,
      "layer": "top",
      "position": "top",
      "spacing": 0,
      "height": 36,
      "border-radius": 25,
      "margin-right": 300,
      "margin-left": 300,
      "margin-top": 8,
    ${modulesConfig}
    }
  '';

  baseStyle = ''
    * {
      border: none;
      border-radius: 0;
      min-height: 0;
      font-family: 'JetBrainsMono Nerd Font';
      font-size: 12px;
      /* Pin the text/glyph color so modules never inherit it from the ambient
         GTK theme. Without this, waybar reads the dconf gtk-theme at startup and
         a stray theme (e.g. a leftover adw-gtk3) renders clock/media/icons in a
         dark, near-invisible color. More specific selectors still override this. */
      color: @foreground;
    }

    .modules-left { margin-left: 8px; }
    .modules-right { margin-right: 8px; }

    /* Keep the toplevel surface fully transparent. Giving the window itself an
       opaque background makes GTK mark the whole surface opaque, so Hyprland
       renders the rounded-corner / side-gap pixels as solid BLACK (they vanish
       in screenshots because grim composites the real, transparent buffer).
       Painting the bar on an inner box keeps those gaps transparent. */
    window#waybar {
      background: transparent;
    }
    window#waybar > box {
      background-color: @background;
      transition-property: background-color;
      transition-duration: .5s;
      border-radius: 18px;
    }

    window#waybar.empty #window {
      background: transparent;
      background-color: transparent;
      border: none;
      border-radius: 0;
      color: transparent;
      padding: 0;
      margin: 0;
    }
    #waybar.empty .modules-center { opacity: 0; }

    #workspaces {
      padding: 0px 5px;
      margin: 3.5px 3.5px;
      border-radius: 11px;
      background-color: transparent;
      opacity: 0.95;
    }
    #workspaces button { color: @foreground; padding: 0 6px; margin: 0 1.5px; min-width: 9px; }
    #workspaces button.empty { color: @foreground; opacity: 0.5; }
    #workspaces button.active {
      transition: all 50ms ease-out;
      border-radius: 18px;
      color: #11111b;
      background: transparent;
      opacity: 1;
      margin-top: 4px;
      margin-bottom: 4px;
      margin-left: 5px;
      padding-right: 5px;
      padding-left: 5px;
    }
    #workspaces button.active:hover { background-color: transparent; color: #11111b; }
    #workspaces button:hover { background-color: transparent; }
    #workspaces button.empty:hover { border-radius: 18px; background: transparent; opacity: 1; }

    #battery, #pulseaudio { min-width: 12px; }

    #cover, #image {
      margin: 4px 6px 4px 0;
      padding: 0;
      min-width: 20px;
    }
    #cover.empty, #image.empty {
      margin: 0;
      padding: 0;
      min-width: 0;
    }

    #clock { font-size: 13px; font-weight: 700; padding: 0 14px; }
    #pulseaudio { margin: 0 7px; }
    #custom-dns { margin: 0 7px; }
    /* DNS Cloudflare desligado (usando o resolver do roteador) fica em vermelho. */
    #custom-dns.off { color: #f38ba8; }
    #custom-vpn { margin: 0 7px; }
    /* ProtonVPN conectado fica verde; desconectado, cinza discreto. */
    #custom-vpn.connected { color: #a6e3a1; }
    #custom-vpn.disconnected { color: #6c7086; }
    #custom-gamemode { margin-right: 8px; }

    tooltip {
      background: @background;
      border: 1px solid alpha(@foreground, 0.2);
      border-radius: 4px 4px 11px 11px;
    }
    tooltip label { color: white; }

    #custom-active_window {
      padding: 3px 6px;
      border-radius: 14px;
      background: @background;
      font-size: 12px;
    }
    .hidden { opacity: 0; }

    #tray {
      margin: 0 7px;
    }
    #tray > .passive { -gtk-icon-effect: dim; }
    #tray > .needs-attention { -gtk-icon-effect: highlight; }
    #tray menu { background: @background; color: @foreground; }

    #custom-mode { margin-right: 4px; }
    #custom-launcher {
      color: @foreground;
      background: transparent;
      margin-top: 4px;
      margin-bottom: 4px;
      margin-left: 2px;
      margin-right: 6px;
      padding-right: 4px;
      padding-left: 4px;
    }
    #cpu, #memory { font-size: 18px; padding: 2px 1px; }

    #group-right1, #group_right1, #right1 {
      font-weight: 800;
      background: transparent;
      padding: 0px 5px;
      margin: 3.5px 2px;
    }
    #group-center3, #group_center3, #center3,
    #group-center2, #group_center2, #center2 {
      font-weight: 800;
      background: transparent;
      border-radius: 12px;
      padding: 0px 5px;
      margin: 3.5px 2px;
    }
  '';

  mediaScript = ''
    #!/usr/bin/env bash
    title=$(playerctl metadata title 2>/dev/null)
    art=$(playerctl metadata mpris:artUrl 2>/dev/null)
    if [ -n "$title" ]; then
      if [ -n "$art" ]; then
        echo "''${title:0:25}"
      else
        echo "󰎈  ''${title:0:25}"
      fi
    else
      echo "󰎈  No media"
    fi
  '';

  coverScript = ''
    #!/usr/bin/env bash
    # Album-cover thumbnail for waybar's built-in image module. The image module
    # re-reads the file from disk every interval, so the cover updates with NO
    # CSS reload (SIGUSR2) => no bar flicker on track change. This script only
    # prints the cached PNG path; the heavy work (download + rounding) runs in
    # the background so the exec returns fast (the image module runs it on the
    # GTK main thread each tick). Corners are pre-rounded with rsvg-convert
    # because border-radius does not clip a GtkImage's pixbuf.
    cache="$HOME/.cache/waybar"
    src="$cache/cover-src"
    out="$cache/cover.png"
    marker="$cache/cover.url"
    svg="$cache/cover.svg"
    mkdir -p "$cache"

    art=$(playerctl metadata mpris:artUrl 2>/dev/null)

    if [ -z "$art" ]; then
      # No media -> drop the cached art so the image module hides itself.
      : > "$marker"
      rm -f "$out"
      exit 0
    fi

    last=$(cat "$marker" 2>/dev/null)
    if [ "$art" != "$last" ]; then
      echo "$art" > "$marker"
      {
        ok=1
        case "$art" in
          file://*)
            p=''${art#file://}
            printf -v p '%b' "''${p//%/\\x}"
            cp -f "$p" "$src" 2>/dev/null || ok=0
            ;;
          http://*|https://*)
            curl -sfL --max-time 8 -o "$src" "$art" 2>/dev/null || ok=0
            ;;
          *) ok=0 ;;
        esac
        if [ "$ok" = 1 ]; then
          W=40; H=40; R=8
          printf '%s\n' \
            "<svg xmlns=\"http://www.w3.org/2000/svg\" xmlns:xlink=\"http://www.w3.org/1999/xlink\" width=\"$W\" height=\"$H\">" \
            "<defs><clipPath id=\"r\"><rect width=\"$W\" height=\"$H\" rx=\"$R\" ry=\"$R\"/></clipPath></defs>" \
            "<image xlink:href=\"file://$src\" width=\"$W\" height=\"$H\" preserveAspectRatio=\"xMidYMid slice\" clip-path=\"url(#r)\"/>" \
            "</svg>" > "$svg"
          rsvg-convert -w "$W" -h "$H" -o "$out.tmp" "$svg" 2>/dev/null && mv -f "$out.tmp" "$out"
        fi
      } &
    fi

    [ -f "$out" ] && echo "$out"
  '';

  windowScript = ''
    #!/usr/bin/env bash
    MAX_TITLE_LEN=20

    print_status() {
      window=$(hyprctl activewindow -j 2>/dev/null)
      address=$(jq -r '.address // empty' <<< "$window")

      if [[ -z "$address" || "$address" == "null" ]]; then
        ws=$(hyprctl activeworkspace -j | jq -r '.id')
        top_line="Desktop"
        bottom_line="Workspace $ws"
        esc_top=$(sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g' <<< "$top_line")
        esc_bottom=$(sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g' <<< "$bottom_line")
        text="<span size='7500' foreground='#a6adc8' rise='-2000'>$esc_top</span>
    <span size='9000' weight='bold' foreground='#ffffff'>$esc_bottom</span>"
        jq -nc --arg text "$text" --arg tooltip "$bottom_line" \
          '{ text: $text, class: "custom-window", tooltip: $tooltip }'
        return
      fi

      class=$(jq -r '.class // "Unknown"' <<< "$window")
      title=$(jq -r '.title // ""' <<< "$window")
      app_class="''${class,,}"

      if [[ "$app_class" == *discord* || "$app_class" == *vesktop* ]]; then
        title=$(sed -E 's/^\([0-9]+\)[[:space:]]*//' <<< "$title")
        title=$(sed -E 's/^Discord[[:space:]]*\|[[:space:]]*//' <<< "$title")
      fi

      if (( ''${#title} > MAX_TITLE_LEN )); then
        title="''${title:0:$((MAX_TITLE_LEN-3))}..."
      fi

      esc_top=$(sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g' <<< "$class")
      esc_bottom=$(sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g' <<< "$title")
      text="<span size='7500' foreground='#a6adc8' rise='-2000'>$esc_top</span>
    <span size='9000' weight='bold' foreground='#ffffff'>$esc_bottom</span>"
      tooltip="$class: $title"
      jq -nc --arg text "$text" --arg tooltip "$tooltip" \
        '{ text: $text, class: "custom-window", tooltip: $tooltip }'
    }

    print_status
  '';

  # Controle do provedor de DNS pela Waybar/TUI (menu com vários provedores).
  #  - "status": imprime JSON p/ o módulo custom/dns (ícone + classe + tooltip).
  #  - "toggle": alterna rápido entre DNS criptografado (padrão) e o roteador.
  #  - "menu":  abre uma TUI (fzf) num kitty p/ escolher o provedor de DNS.
  # O sistema resolve via systemd-resolved; o padrão Global é Cloudflare DoT (ver
  # modules/networking.nix). Como NÃO dá pra mudar a config Global em runtime sem
  # root, a troca atua NO LINK padrão via resolvectl (liberado pelo polkit p/ o
  # grupo wheel, sem senha — ver modules/hyprland.nix): define os servidores do
  # provedor + DoT e marca o link como default-route (prioridade sobre o Global).
  # "Automático" faz `resolvectl revert`, voltando a herdar o Global (Cloudflare).
  # O estado é DETECTADO do resolvectl (não de um marker), então reinícios/reboots
  # refletem certo no ícone automaticamente.
  dnsScript = ''
    #!/usr/bin/env bash
    set -euo pipefail

    # NB: não usar `exit` dentro do awk aqui. Com `set -o pipefail`, o awk
    # fechando o pipe cedo faz o produtor (ip/resolvectl) receber SIGPIPE e o
    # pipeline retornar 141, o que — com `set -e` — matava o script de forma
    # intermitente (o menu abria e fechava o kitty na hora). Ler toda a entrada
    # e imprimir a 1ª/última ocorrência evita o SIGPIPE.
    dev=$(ip route show default 2>/dev/null | awk 'NR==1{print $5}')
    gw=$(ip route show default 2>/dev/null | awk 'NR==1{print $3}')

    refresh_waybar() {
      pkill -RTMIN+9 waybar 2>/dev/null || true
    }

    notify_dns() {
      notify-send "DNS" "$1" 2>/dev/null || true
    }

    # Servidores de cada provedor (IPv4 + IPv6). O sufixo `#hostname` é o nome
    # usado na validação do certificado TLS durante o handshake DoT.
    provider_servers() {
      case "$1" in
        cloudflare) echo "1.1.1.1#cloudflare-dns.com 1.0.0.1#cloudflare-dns.com 2606:4700:4700::1111#cloudflare-dns.com 2606:4700:4700::1001#cloudflare-dns.com" ;;
        google)     echo "8.8.8.8#dns.google 8.8.4.4#dns.google 2001:4860:4860::8888#dns.google 2001:4860:4860::8844#dns.google" ;;
        quad9)      echo "9.9.9.9#dns.quad9.net 149.112.112.112#dns.quad9.net 2620:fe::fe#dns.quad9.net 2620:fe::9#dns.quad9.net" ;;
        adguard)    echo "94.140.14.14#dns.adguard-dns.com 94.140.15.15#dns.adguard-dns.com 2a10:50c0::ad1:ff#dns.adguard-dns.com 2a10:50c0::ad2:ff#dns.adguard-dns.com" ;;
        opendns)    echo "208.67.222.222 208.67.220.220 2620:119:35::35 2620:119:53::53" ;;
        gateway)    echo "$gw" ;;
        *)          echo "" ;;
      esac
    }

    provider_label() {
      case "$1" in
        cloudflare) echo "Cloudflare (DoT)" ;;
        google)     echo "Google (DoT)" ;;
        quad9)      echo "Quad9 (DoT)" ;;
        adguard)    echo "AdGuard (DoT)" ;;
        opendns)    echo "OpenDNS" ;;
        gateway)    echo "Roteador (DHCP)" ;;
        auto)       echo "Automático (Cloudflare DoT)" ;;
        *)          echo "Personalizado" ;;
      esac
    }

    # Provedores com DNS-over-TLS (tráfego DNS criptografado).
    provider_is_encrypted() {
      case "$1" in
        cloudflare|google|quad9|adguard|auto) return 0 ;;
        *) return 1 ;;
      esac
    }

    # DNS "atual" DO LINK padrão apenas (1ª ocorrência). NÃO usar o `resolvectl
    # status` global aqui: ele lista Global + TODOS os links, cada um podendo ter
    # sua própria linha "Current DNS Server", e pegar a última confundia a
    # detecção (retornava o gateway de outro link e reportava provedor errado).
    link_dns() {
      resolvectl status "$dev" 2>/dev/null \
        | awk -F': ' '/Current DNS Server/{if(!f){v=$2; f=1}} END{print v}'
    }

    # DNS efetivo p/ exibir no menu: o do link se houver override; senão o Global.
    current_dns() {
      local cur
      cur=$(link_dns)
      if [ -z "$cur" ]; then
        cur=$(resolvectl status 2>/dev/null \
          | awk -F': ' '/Current DNS Server/{if(!f){v=$2; f=1}} END{print v}')
      fi
      printf '%s' "$cur"
    }

    # Identifica o provedor atual a partir do DNS do link. Sem override no link
    # (link_dns vazio) => herda o Global (Cloudflare) => "auto".
    current_provider() {
      local cur
      cur=$(link_dns)
      if [ -z "$cur" ]; then echo auto; return; fi
      case "$cur" in
        1.1.1.1*|1.0.0.1*|*2606:4700*)            echo cloudflare ;;
        8.8.8.8*|8.8.4.4*|*2001:4860:4860*)       echo google ;;
        9.9.9.9*|149.112.112.112*|*2620:fe*)      echo quad9 ;;
        94.140.1*|*adguard*|*2a10:50c0*)          echo adguard ;;
        208.67.2*|*2620:119*)                     echo opendns ;;
        *)
          if [ -n "$gw" ] && [ "$cur" = "$gw" ]; then echo gateway; else echo custom; fi ;;
      esac
    }

    # Aplica um provedor no link padrão. "auto" limpa o override (revert).
    apply_provider() {
      local key="$1"
      [ -n "$dev" ] || return 0
      if [ "$key" = auto ]; then
        resolvectl revert "$dev" || true
        notify_dns "DNS: $(provider_label auto)"
        refresh_waybar
        return 0
      fi
      local servers dot
      servers=$(provider_servers "$key")
      if provider_is_encrypted "$key"; then dot=yes; else dot=no; fi
      # shellcheck disable=SC2086
      resolvectl dns "$dev" $servers || true
      resolvectl dnsovertls "$dev" "$dot" || true
      resolvectl default-route "$dev" yes || true
      notify_dns "DNS: $(provider_label "$key")"
      refresh_waybar
    }

    open_menu() {
      if ! command -v fzf >/dev/null 2>&1; then
        printf 'fzf não encontrado no PATH.\n' >&2
        exit 1
      fi

      local cur_key cur_label current header choice key
      cur_key=$(current_provider)
      cur_label=$(provider_label "$cur_key")
      current=$(current_dns)
      header="Atual: $cur_label | Interface: ''${dev:-sem rota padrão} | DNS: ''${current:-indisponível}"

      # Rótulos exibidos no fzf; o atual ganha um marcador ●.
      mark() { if [ "$1" = "$cur_key" ]; then printf '● '; else printf '  '; fi; }

      choice=$(
        {
          printf '%sCloudflare (DoT)\n'   "$(mark cloudflare)"
          printf '%sGoogle (DoT)\n'       "$(mark google)"
          printf '%sQuad9 (DoT)\n'        "$(mark quad9)"
          printf '%sAdGuard (DoT)\n'      "$(mark adguard)"
          printf '%sOpenDNS\n'            "$(mark opendns)"
          printf '%sRoteador (DHCP, sem DoT)\n' "$(mark gateway)"
          printf '%sAutomático (padrão do sistema)\n' "$(mark auto)"
          printf '  Fechar\n'
        } |
        fzf \
          --layout=reverse \
          --height=100% \
          --border=rounded \
          --prompt='DNS > ' \
          --pointer='▶' \
          --marker='•' \
          --header="$header"
      ) || exit 0

      # Remove o marcador (●/espaços) do início antes de casar.
      choice=$(printf '%s' "$choice" | sed 's/^[● ]*//')
      case "$choice" in
        'Cloudflare (DoT)')                 key=cloudflare ;;
        'Google (DoT)')                     key=google ;;
        'Quad9 (DoT)')                      key=quad9 ;;
        'AdGuard (DoT)')                    key=adguard ;;
        'OpenDNS')                          key=opendns ;;
        'Roteador (DHCP, sem DoT)')         key=gateway ;;
        'Automático (padrão do sistema)')   key=auto ;;
        *)                                  exit 0 ;;
      esac
      apply_provider "$key"
    }

    case "''${1:-status}" in
      toggle)
        if [ -z "$dev" ]; then exit 0; fi
        # Clique direito = alternância rápida entre criptografado e o roteador.
        if provider_is_encrypted "$(current_provider)"; then
          apply_provider gateway
        else
          apply_provider auto
        fi
        ;;
      menu)
        open_menu
        ;;
      status|*)
        key=$(current_provider)
        label=$(provider_label "$key")
        if provider_is_encrypted "$key"; then
          printf '{"text":"󰦝","class":"on","tooltip":"DNS: %s (criptografado) — clique abre menu, botão direito alterna"}\n' "$label"
        else
          printf '{"text":"󰦞","class":"off","tooltip":"DNS: %s (sem DoT) — clique abre menu, botão direito alterna"}\n' "$label"
        fi
        ;;
    esac
  '';

  # Controle do ProtonVPN (WireGuard via wg-quick) pela Waybar/TUI, no mesmo
  # padrão do módulo de DNS.
  #  - "status": imprime JSON p/ o módulo custom/vpn (ícone + classe + tooltip).
  #  - "toggle": conecta ao último servidor usado (ou o 1º da lista) / desconecta.
  #  - "menu":  abre uma TUI (fzf) num kitty p/ escolher o servidor (perfil .conf).
  # Os perfis são os arquivos WireGuard baixados no painel da Proton
  # (account.protonvpn.com → Downloads → WireGuard) salvos em ~/.config/protonvpn/wg.
  # O wg-quick precisa de root; liberamos SÓ ele via sudo NOPASSWD (ver
  # modules/networking.nix), então a TUI não pede senha. Como o wg-quick deriva o
  # nome da interface do basename do arquivo (e exige <=15 chars válidos), usamos
  # um symlink curto "pvpn.conf" no runtime dir apontando pro perfil escolhido.
  vpnScript = ''
    #!/usr/bin/env bash
    set -euo pipefail

    CONF_DIR="$HOME/.config/protonvpn/wg"
    IFACE="pvpn"
    STATE_DIR="''${XDG_RUNTIME_DIR:-/tmp}/protonvpn"
    LINK="$STATE_DIR/$IFACE.conf"
    CUR="$STATE_DIR/current"                       # servidor atual/último conectado
    KS_NFT="$STATE_DIR/ks.nft"                      # ruleset nftables do kill-switch
    KS_FLAG="$HOME/.config/protonvpn/killswitch"    # preferência: kill-switch ligado?
    WG_QUICK="${pkgs.wireguard-tools}/bin/wg-quick"
    NFT="${pkgs.nftables}/bin/nft"

    refresh_waybar() { pkill -RTMIN+10 waybar 2>/dev/null || true; }
    notify_vpn()     { notify-send "ProtonVPN" "$1" 2>/dev/null || true; }

    is_up() { ip link show "$IFACE" >/dev/null 2>&1; }

    # Nome do servidor atual/último (marker gravado ao conectar).
    current_name() {
      [ -f "$CUR" ] && cat "$CUR" || true
    }

    killswitch_enabled() { [ -f "$KS_FLAG" ]; }

    # Gera o ruleset do kill-switch: DERRUBA toda saída que não vá pelo túnel
    # (oif pvpn), exceto loopback, LAN e o endpoint do servidor Proton (mantém o
    # handshake WireGuard). É instalado no PostUp e removido no PostDown do
    # wg-quick, então SÓ existe enquanto a VPN está conectada — sem VPN ativa não
    # há kill-switch e a internet funciona normal.
    write_ks_nft() {
      local ip="$1"
      {
        printf 'table inet pvpnks {\n'
        printf '  chain output {\n'
        printf '    type filter hook output priority 0; policy drop;\n'
        printf '    oifname "lo" accept\n'
        printf '    oifname "%s" accept\n' "$IFACE"
        printf '    ct state established,related accept\n'
        printf '    ip daddr { 127.0.0.0/8, 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16 } accept\n'
        printf '    ip6 daddr { ::1, fe80::/10, fc00::/7 } accept\n'
        [ -n "$ip" ] && printf '    ip daddr %s accept\n' "$ip"
        printf '  }\n'
        printf '}\n'
      } > "$KS_NFT"
    }

    # Lista os perfis (.conf) disponíveis, sem a extensão, ordenados.
    list_profiles() {
      [ -d "$CONF_DIR" ] || return 0
      find "$CONF_DIR" -maxdepth 1 -type f -name '*.conf' -printf '%f\n' 2>/dev/null \
        | sed 's/\.conf$//' | sort
    }

    connect_profile() {
      local name="$1" src="$CONF_DIR/$1.conf"
      [ -f "$src" ] || { notify_vpn "Perfil não encontrado: $name"; return 1; }
      mkdir -p "$STATE_DIR"; chmod 700 "$STATE_DIR"
      # Derruba a conexão anterior (se houver) antes de subir a nova.
      if is_up; then
        sudo "$WG_QUICK" down "$LINK" >/dev/null 2>&1 \
          || sudo "$WG_QUICK" down "$IFACE" >/dev/null 2>&1 || true
      fi
      # Monta a conf de runtime a partir do perfil. Com kill-switch ligado, injeta
      # PostUp/PostDown que instalam/removem o nftables (wg-quick roda esses hooks
      # como root, então não exige sudo extra).
      cp "$src" "$LINK"; chmod 600 "$LINK"
      if killswitch_enabled; then
        local ip; ip="$(endpoint_ip "$name")"
        write_ks_nft "$ip"
        printf 'PostUp = %s -f %s\n' "$NFT" "$KS_NFT" >> "$LINK"
        printf 'PostDown = %s delete table inet pvpnks 2>/dev/null || true\n' "$NFT" >> "$LINK"
      fi
      if sudo "$WG_QUICK" up "$LINK" >/dev/null 2>&1; then
        printf '%s' "$name" > "$CUR"
        if killswitch_enabled; then notify_vpn "Conectado: $name (kill-switch ativo)"; else notify_vpn "Conectado: $name"; fi
      else
        notify_vpn "Falha ao conectar: $name"
      fi
      refresh_waybar
    }

    disconnect_vpn() {
      if is_up; then
        sudo "$WG_QUICK" down "$LINK" >/dev/null 2>&1 \
          || sudo "$WG_QUICK" down "$IFACE" >/dev/null 2>&1 || true
        notify_vpn "Desconectado"
      fi
      refresh_waybar
    }

    # --- País / latência (para "conectar ao mais rápido") -----------------------
    # Código de país = 2 primeiras letras do nome do perfil (padrão dos .conf da
    # Proton, ex.: "US-NY-1", "BR#7", "NL-FREE#2").
    country_of() { printf '%s' "$1" | grep -oiE '^[a-z]{2}' | head -1 | tr '[:lower:]' '[:upper:]'; }

    list_countries() {
      list_profiles | while IFS= read -r p; do country_of "$p"; done | sort -u | sed '/^$/d'
    }

    endpoint_ip() {
      awk -F'=' '/^[[:space:]]*Endpoint/{gsub(/[[:space:]]/,"",$2); sub(/:[0-9]+$/,"",$2); print $2; exit}' \
        "$CONF_DIR/$1.conf" 2>/dev/null
    }

    # Latência (ms) do endpoint via 1 ping ICMP; vazio se não responder.
    ping_ms() {
      ping -n -c1 -W1 "$1" 2>/dev/null \
        | awk -F'= ' '/rtt|round-trip/{split($2,a,"/"); print a[2]}'
    }

    # Melhor (menor latência) perfil de um país. Endpoints que bloqueiam ICMP
    # entram como 9999 (só escolhidos se não houver melhores).
    fastest_in_country() {
      local cc="$1"
      list_profiles | while IFS= read -r p; do
        [ "$(country_of "$p")" = "$cc" ] || continue
        local ip ms; ip="$(endpoint_ip "$p")"; [ -z "$ip" ] && continue
        ms="$(ping_ms "$ip")"; [ -z "$ms" ] && ms=9999
        printf '%s %s\n' "$ms" "$p"
      done | sort -n | head -1
    }

    connect_fastest() {
      local cc="$1" best profile ms
      notify_vpn "Medindo latência em $cc…"
      best="$(fastest_in_country "$cc")"
      if [ -z "$best" ]; then notify_vpn "Nenhum servidor mediável em $cc"; return 1; fi
      ms="''${best%% *}"; profile="''${best#* }"
      connect_profile "$profile"
      notify_vpn "Mais rápido em $cc: $profile (~''${ms} ms)"
    }

    toggle_killswitch() {
      if killswitch_enabled; then
        rm -f "$KS_FLAG"
        notify_vpn "Kill-switch desativado"
      else
        mkdir -p "$(dirname "$KS_FLAG")"; : > "$KS_FLAG"
        notify_vpn "Kill-switch ativado — efetivo só enquanto a VPN estiver conectada"
      fi
      # Reaplica na conexão atual (regenera a conf com/sem os hooks nftables).
      if is_up; then local n; n="$(current_name)"; [ -n "$n" ] && connect_profile "$n"; fi
      refresh_waybar
    }

    open_menu() {
      command -v fzf >/dev/null 2>&1 || { printf 'fzf ausente\n' >&2; exit 1; }

      local up name header profiles choice
      if is_up; then up="conectado"; name="$(current_name)"; else up="desconectado"; name=""; fi
      profiles="$(list_profiles)"

      # Sem perfis: oferece abrir a pasta / ajuda p/ baixar os .conf.
      if [ -z "$profiles" ]; then
        choice=$(
          printf '%s\n' 'Abrir pasta de configs' 'Como baixar (ajuda)' 'Fechar' |
          fzf --layout=reverse --height=100% --border=rounded \
              --prompt='ProtonVPN > ' \
              --header="Nenhum .conf em $CONF_DIR"
        ) || exit 0
        case "$choice" in
          'Abrir pasta de configs') mkdir -p "$CONF_DIR"; xdg-open "$CONF_DIR" >/dev/null 2>&1 || true ;;
          'Como baixar (ajuda)') notify_vpn "account.protonvpn.com → Downloads → WireGuard. Salve os .conf em $CONF_DIR" ;;
        esac
        exit 0
      fi

      local ks; if killswitch_enabled; then ks="ativado"; else ks="desativado"; fi
      header="Estado: $up | Servidor: ''${name:--} | Kill-switch: $ks"
      choice=$(
        {
          if is_up; then printf '⏹  Desconectar\n'; fi
          printf '🚀 Conectar ao mais rápido (por país)…\n'
          if killswitch_enabled; then printf '🛡  Kill-switch: desativar\n'; else printf '🛡  Kill-switch: ativar\n'; fi
          printf '──────────\n'
          while IFS= read -r p; do
            if [ "$p" = "$name" ]; then printf '● %s\n' "$p"; else printf '  %s\n' "$p"; fi
          done <<< "$profiles"
          printf '  Fechar\n'
        } |
        fzf --layout=reverse --height=100% --border=rounded \
            --prompt='ProtonVPN > ' --pointer='▶' --marker='•' \
            --header="$header"
      ) || exit 0

      # Remove marcadores (●/⏹/🛡/🚀/espaços) do início antes de casar.
      choice=$(printf '%s' "$choice" | sed 's/^[●⏹🛡🚀 ]*//')
      case "$choice" in
        'Desconectar')                 disconnect_vpn ;;
        'Conectar ao mais rápido (por país)…')
          cc=$(list_countries | fzf --layout=reverse --height=100% --border=rounded \
                 --prompt='País > ' --header='Escolha o país (menor latência)') || exit 0
          [ -n "$cc" ] && connect_fastest "$cc" ;;
        'Kill-switch: ativar'|'Kill-switch: desativar') toggle_killswitch ;;
        '──────────'|'Fechar'|''') exit 0 ;;
        *)                             connect_profile "$choice" ;;
      esac
    }

    case "''${1:-status}" in
      toggle)
        if is_up; then
          disconnect_vpn
        else
          last="$(current_name)"
          [ -z "$last" ] && last="$(list_profiles | head -1)"
          if [ -n "$last" ]; then connect_profile "$last"; else notify_vpn "Sem perfis em $CONF_DIR"; fi
        fi
        ;;
      menu)
        open_menu
        ;;
      status|*)
        if is_up; then
          name="$(current_name)"
          if killswitch_enabled; then kstip=", kill-switch ativo"; else kstip=""; fi
          printf '{"text":"󰖂 %s","class":"connected","tooltip":"ProtonVPN: conectado (%s)%s — clique abre menu, botão direito desconecta"}\n' "''${name:-on}" "''${name:-?}" "$kstip"
        else
          printf '{"text":"󰖂","class":"disconnected","tooltip":"ProtonVPN: desconectado — clique abre menu para conectar"}\n'
        fi
        ;;
    esac
  '';
in
{
  # Tools the bar's modules/scripts call out to.
  home.packages = with pkgs; [
    jq
    playerctl
    pamixer
    pavucontrol
    blueman
    curl
    librsvg
    libnotify
  ];

  programs.waybar.enable = true;
  programs.waybar.package = waybarPkg;

  xdg.configFile = {
    "waybar/config.jsonc".text = dockConfig;
    "waybar/style.css".text = colors + baseStyle;

    "waybar/media.sh" = { text = mediaScript; executable = true; };
    "waybar/cover.sh" = { text = coverScript; executable = true; };
    "waybar/window.sh" = { text = windowScript; executable = true; };
    "waybar/dns.sh" = { text = dnsScript; executable = true; };
    "waybar/vpn.sh" = { text = vpnScript; executable = true; };
  };
}
