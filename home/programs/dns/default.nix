# Seletor de provedor de DNS (menu fzf), acionado por Super+Shift+G.
# Antes vivia no módulo da Waybar (como o módulo custom/dns da barra). A Waybar
# foi removida na migração para o DankMaterialShell (DMS), então o script foi
# extraído para cá — o menu/toggle continuam funcionando pelo atalho do Hyprland
# (ver home/programs/hypr). Sem a barra não há mais um ícone de status do DNS; o
# feedback vem por notificação (notify-send) ao trocar de provedor.
{ config, lib, pkgs, ... }:

let
  # Controle do provedor de DNS por TUI (menu com vários provedores).
  #  - "menu":  abre uma TUI (fzf) num kitty p/ escolher o provedor de DNS.
  #  - "toggle": alterna rápido entre DNS criptografado (padrão) e o roteador.
  #  - "status": imprime JSON (mantido por compatibilidade; sem barra não é usado).
  # O sistema resolve via systemd-resolved; o padrão Global é Cloudflare DoT (ver
  # modules/networking.nix). Como NÃO dá pra mudar a config Global em runtime sem
  # root, a troca atua NO LINK padrão via resolvectl (liberado pelo polkit p/ o
  # grupo wheel, sem senha — ver modules/hyprland.nix): define os servidores do
  # provedor + DoT e marca o link como default-route (prioridade sobre o Global).
  # "Automático" faz `resolvectl revert`, voltando a herdar o Global (Cloudflare).
  # O estado é DETECTADO do resolvectl (não de um marker), então reinícios/reboots
  # refletem certo automaticamente.
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
        # Alternância rápida entre criptografado e o roteador.
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
          printf '{"text":"󰦝","class":"on","tooltip":"DNS: %s (criptografado)"}\n' "$label"
        else
          printf '{"text":"󰦞","class":"off","tooltip":"DNS: %s (sem DoT)"}\n' "$label"
        fi
        ;;
    esac
  '';
in
{
  # Ferramentas usadas pelo dns.sh (o menu roda num kitty via atalho do Hyprland).
  #   - fzf:       TUI de seleção do provedor.
  #   - libnotify: notify-send (feedback ao trocar de provedor).
  #   - iproute2:  `ip route` p/ descobrir a interface/gateway padrão.
  # `resolvectl` vem do systemd (já no sistema); a troca no link é liberada sem
  # senha pelas regras de polkit em modules/hyprland.nix.
  home.packages = with pkgs; [
    fzf
    libnotify
    iproute2
  ];

  # Entrega o script em ~/.config/dns/dns.sh (o atalho Super+Shift+G o chama).
  xdg.configFile."dns/dns.sh" = { text = dnsScript; executable = true; };
}
