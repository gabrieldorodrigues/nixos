# Networking configuration.
{ config, pkgs, ... }:

{
  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # DNS: Cloudflare (1.1.1.1 / 1.0.0.1 + IPv6) com DNS-over-TLS (DoT), ou seja,
  # as consultas DNS saem criptografadas até a Cloudflare em vez de texto puro.
  # Quem resolve é o systemd-resolved (stub em 127.0.0.53); o NetworkManager
  # delega a ele (dns = "systemd-resolved") em vez de escrever resolv.conf com o
  # DNS do DHCP. DNSOverTLS = "true" força DoT e falha se indisponível.
  networking.nameservers = [
    "1.1.1.1"
    "1.0.0.1"
    "2606:4700:4700::1111"
    "2606:4700:4700::1001"
  ];
  networking.networkmanager.dns = "systemd-resolved";
  services.resolved = {
    enable = true;
    dnsovertls = "true";
    # Repassa os mesmos resolvers ao resolved (fallback caso um link não
    # forneça DNS próprio). Os hostnames após o '#' são usados na validação do
    # certificado TLS da Cloudflare durante o handshake DoT.
    settings.Resolve.DNS = [
      "1.1.1.1#cloudflare-dns.com"
      "1.0.0.1#cloudflare-dns.com"
      "2606:4700:4700::1111#cloudflare-dns.com"
      "2606:4700:4700::1001#cloudflare-dns.com"
    ];
  };

  # Reverse-path filtering em modo "loose" (RFC 3704 loose mode) em vez do
  # strict padrão do NixOS. Com Docker no host (interfaces docker0/veth e rotas
  # extras), o modo strict pode descartar tráfego UDP de retorno legítimo —
  # justamente o que o BitTorrent/DHT e trackers UDP do torlink usam. "loose"
  # ainda barra spoofing (o IP de origem tem de ser roteável por alguma
  # interface), mas não quebra respostas P2P/DHT.
  networking.firewall.checkReversePath = "loose";

  # Tailscale: habilita o daemon tailscaled (cria o socket em
  # /var/run/tailscale/tailscaled.sock que a CLI `tailscale` usa). Sem isto o
  # pacote `tailscale` só instala a CLI, mas não há daemon para conectar.
  services.tailscale.enable = true;

  # ProtonVPN via WireGuard: a TUI da Waybar (home/programs/waybar/vpn.sh) sobe/
  # derruba o túnel com `wg-quick`, que exige root. Instala o wireguard-tools
  # (fornece `wg` e `wg-quick`) e libera SOMENTE o `wg-quick` via sudo sem senha
  # para o grupo wheel — assim o toggle/menu da barra não pede senha. O caminho
  # no store é o mesmo referenciado pelo script (mesmo nixpkgs), então o match do
  # sudoers é exato. Os perfis .conf ficam em ~/.config/protonvpn/wg (baixados no
  # painel da Proton). Regra restrita a um único binário → superfície mínima.
  environment.systemPackages = [ pkgs.wireguard-tools ];
  security.sudo.extraRules = [
    {
      groups = [ "wheel" ];
      commands = [
        {
          command = "${pkgs.wireguard-tools}/bin/wg-quick";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];
}
