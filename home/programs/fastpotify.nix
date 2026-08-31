{ inputs, pkgs, ... }:

let
  fastpotifyPkgs = import inputs.nixpkgs {
    inherit (pkgs.stdenv.hostPlatform) system;
    overlays = [ (import inputs.fastpotify.inputs.rust-overlay) ];
  };
  toolchain = fastpotifyPkgs.rust-bin.fromRustupToolchainFile
    "${inputs.fastpotify}/rust-toolchain.toml";
  rustPlatform = fastpotifyPkgs.makeRustPlatform {
    cargo = toolchain;
    rustc = toolchain;
  };
  runtimeLibs = with fastpotifyPkgs; [
    libxkbcommon
    wayland
    libGL
    libx11
    libxcursor
    libxi
    libxrandr
  ];
  projectmSrc = fastpotifyPkgs.fetchFromGitHub {
    owner = "crmne";
    repo = "projectm-rs";
    rev = "a2c01c3bd743700b8dd288238a6fe57f7e717ef8";
    fetchSubmodules = true;
    hash = "sha256-nzX+7ytMPscfP9uGRaCxN8GTXDdEtK82YFbw5Lapn5E=";
  };
  patchedCargoLock = fastpotifyPkgs.runCommand "fastpotify-Cargo.lock" { } ''
    sed \
      '\|source = "git+https://github.com/crmne/projectm-rs?branch=respect-cmake-generator#a2c01c3bd743700b8dd288238a6fe57f7e717ef8"|d' \
      ${inputs.fastpotify}/Cargo.lock > $out
  '';
  fastpotify = rustPlatform.buildRustPackage {
    pname = "fastpotify";
    version = (fastpotifyPkgs.lib.importTOML
      "${inputs.fastpotify}/Cargo.toml").package.version;
    src = inputs.fastpotify;
    cargoLock = {
      lockFile = patchedCargoLock;
      # Upstream omitted this required hash for its pinned librespot fork.
      outputHashes."librespot-audio-0.8.0" =
        "sha256-TkHdN/dugdmK5iWmcvxGhz+0Cynki4/nNpp85F/qF/0=";
    };

    nativeBuildInputs = with fastpotifyPkgs; [
      pkg-config
      cmake
      rustPlatform.bindgenHook
      makeWrapper
    ];
    postPatch = ''
      mkdir -p vendor
      cp -R ${projectmSrc}/projectm-sys vendor/projectm-sys
      chmod -R u+w vendor/projectm-sys
      substituteInPlace Cargo.toml \
        --replace-fail \
          'projectm-sys = { git = "https://github.com/crmne/projectm-rs", branch = "respect-cmake-generator" }' \
          'projectm-sys = { path = "vendor/projectm-sys" }'
      sed -i \
        '\|source = "git+https://github.com/crmne/projectm-rs?branch=respect-cmake-generator#a2c01c3bd743700b8dd288238a6fe57f7e717ef8"|d' \
        Cargo.lock
      substituteInPlace vendor/projectm-sys/build.rs \
        --replace-fail \
          '.define("BUILD_SHARED_LIBS", build_shared_libs)' \
          '.define("CMAKE_INSTALL_LIBDIR", "lib").define("BUILD_SHARED_LIBS", build_shared_libs)'
    '';
    buildInputs = runtimeLibs ++ (with fastpotifyPkgs; [
      alsa-lib
      libpulseaudio
    ]);

    postFixup = ''
      wrapProgram $out/bin/fastpotify \
        --prefix LD_LIBRARY_PATH : ${fastpotifyPkgs.lib.makeLibraryPath runtimeLibs}
    '';
    postInstall = ''
      install -Dm644 packaging/applications/fastpotify.desktop \
        $out/share/applications/fastpotify.desktop
      install -Dm644 packaging/icons/fastpotify.svg \
        $out/share/icons/hicolor/scalable/apps/fastpotify.svg
    '';

    meta = {
      description = "Fast native Spotify client with local playback and Spotify Connect";
      homepage = "https://fastpotify.rocks";
      license = fastpotifyPkgs.lib.licenses.mit;
      mainProgram = "fastpotify";
    };
  };
in
{
  # Cliente Spotify nativo em Rust. Mantido separado do Spicetify porque ambos
  # podem coexistir: este instala `fastpotify`; o outro, o cliente oficial.
  home.packages = [ fastpotify ];
}