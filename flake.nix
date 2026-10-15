{
  description = "NixOS configuration (classica + Zen browser via flake)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    # Canal unstable — usado pontualmente para pacotes que precisam de uma
    # versão mais nova que a do 26.05 (ex.: opencode) e para compilar o
    # compositor Hyprland + o plugin hyprglass (ver home/programs/hypr).
    #
    # FIXADO num rev específico DE PROPÓSITO: o hyprglass é compilado contra
    # ESTE nixpkgs-unstable e precisa casar o ABI (libstdc++/GLIBCXX) com o
    # Hyprland em uso. Bumpar o unstable recompila o plugin contra um gcc mais
    # novo e o Hyprland da sessão deixa de conseguir carregá-lo
    # ("GLIBCXX_3.4.36 not found"). Só suba este rev junto com uma versão do
    # hyprglass compatível, e testando com logout/login depois.
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/f13ff45afd1bb73e640eaa08a7066dbed07e3238";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # DankMaterialShell (DMS) — shell/desktop completo p/ Wayland (Quickshell +
    # Go). Substitui waybar/mako/walker. Canal stable casa com o nixos-26.05.
    dms = {
      url = "github:AvengeMedia/DankMaterialShell/stable";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # dank-greeter (dms-greeter) — tela de login greetd com a estética do DMS.
    # O greeter saiu do repo do DMS e virou pacote/flake próprio. Substitui o
    # SDDM: o greetd sobe o dms-greeter, que sincroniza tema/wallpaper do DMS.
    dank-greeter = {
      url = "github:AvengeMedia/dank-greeter";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # torlink (torlnk) — buscador de torrents no terminal.
    # O pacote é feito no unstable; como o default aqui é 26.05, seguimos nixpkgs.
    torlink = {
      url = "github:baairon/torlink";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Millennium — loader de temas/plugins para o cliente Steam. Fornece o
    # pacote `millennium-steam` (Steam com o Millennium embutido) e um overlay.
    # Ainda não está no nixpkgs, então vem deste flake (subdir packages/nix).
    # `follows nixpkgs` faz reusar a MESMA árvore de pacotes do sistema (26.05),
    # em vez de baixar/compilar um segundo nixpkgs inteiro (~28 GB a menos).
    millennium = {
      url = "github:SteamClientHomebrew/Millennium?dir=packages/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # spicetify-nix — customização declarativa do cliente Spotify (temas,
    # extensões, adblock). O módulo INSTALA o Spotify por conta própria, então
    # NÃO usamos `pkgs.spotify` em paralelo (ver modules/packages/media.nix).
    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Fastpotify — cliente Spotify nativo em Rust, sem navegador embutido.
    # Instalado em paralelo ao cliente oficial customizado pelo Spicetify.
    #
    # FIXADO num rev específico DE PROPÓSITO: a derivation em
    # home/programs/fastpotify.nix é acoplada a ESTE commit — ela fixa o rev do
    # fork `projectm-rs`, o hash do `projectmSrc`, o outputHash do
    # `librespot-audio` e um `sed` que remove a linha do projectm-sys por rev
    # exato. Bumpar o fastpotify muda o Cargo.lock (novos forks git como
    # winit/dpi, egui, fastframe…) e a build quebra ("No hash was found while
    # vendoring the git dependency dpi-0.1.1"). Só suba este rev revisando a
    # derivation junto (revs/hashes dos forks + sed do projectm).
    fastpotify = {
      url = "github:crmne/fastpotify/ebdc625389104cf997f3a36a13d46a67f35941c1";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # fetch (areofyl/fetch) — neofetch-like com um "cubo" 3D animado em ASCII.
    # Fornece um home-manager module (programs.fetch).
    areofyl-fetch = {
      url = "github:areofyl/fetch";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nix-craftapps — empacota os "ArtCraft Crafting Apps" (storytold): 12 apps
    # criativos em Rust (photocraft, vectorcraft, filmcraft…). Fornece módulo
    # NixOS (programs.craftapps); a seleção de apps fica em
    # modules/packages/media.nix. São binários pré-compilados upstream.
    nix-craftapps = {
      url = "github:olafkfreund/nix-craftapps";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs: {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        ./hosts/nixos/configuration.nix

        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "hm-bak";
          home-manager.extraSpecialArgs = { inherit inputs; };
          home-manager.users.gabrieldorodrigues = import ./home/home.nix;
        }
      ];
    };
  };
}
