{ pkgs, inputs, ... }:

let
  # Pacote de temas/extensões do spicetify-nix para esta arquitetura.
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.system};
in
{
  # Spicetify — customiza o cliente oficial do Spotify. O módulo instala o
  # próprio Spotify (por isso `pkgs.spotify` foi removido de media.nix).
  programs.spicetify = {
    enable = true;

    # Marketplace: loja embutida na sidebar do Spotify para navegar/instalar
    # temas, extensões e snippets da comunidade direto pela interface. No
    # spicetify-nix ele é um "custom app", não uma flag booleana.
    enabledCustomApps = with spicePkgs.apps; [
      marketplace
    ];

    enabledExtensions = with spicePkgs.extensions; [
      adblockify # Bloqueia anúncios de áudio/banner.
      hidePodcasts # Remove podcasts da home.
      shuffle # Shuffle verdadeiramente aleatório (Fisher–Yates).
    ]
    ++ [
      # Spicy Lyrics — letras sincronizadas e animadas (não empacotado no
      # spicetify-nix). O build fica em builds/spicy-lyrics.mjs no repo.
      {
        src = pkgs.fetchFromGitHub {
          owner = "Spikerko";
          repo = "spicy-lyrics";
          rev = "cc45160facbebbe6c872a8796d339c0602d58928";
          hash = "sha256-jKzm8/MFOUbFzBoTFLsmIbdnmsI0zIkr/5Ugm4+ZXb4=";
        } + "/builds";
        name = "spicy-lyrics.mjs";
      }
    ];

    # Snippets: pequenos ajustes de CSS. Lista em spicePkgs.snippets (ver
    # docs/THEMES / o Marketplace). Ex.: rotatingCoverart, pointer.
    enabledSnippets = with spicePkgs.snippets; [
    ];
  };
}
