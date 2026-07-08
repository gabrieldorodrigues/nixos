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

  # Reverse-path filtering em modo "loose" (RFC 3704 loose mode) em vez do
  # strict padrão do NixOS. Com Docker no host (interfaces docker0/veth e rotas
  # extras), o modo strict pode descartar tráfego UDP de retorno legítimo —
  # justamente o que o BitTorrent/DHT e trackers UDP do torlink usam. "loose"
  # ainda barra spoofing (o IP de origem tem de ser roteável por alguma
  # interface), mas não quebra respostas P2P/DHT.
  networking.firewall.checkReversePath = "loose";
}
