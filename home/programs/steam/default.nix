{ config, lib, pkgs, ... }:

let
  cursorTheme = "BreezeX-RosePine-Linux";

  # Steam's nested runtime needs the Xcursor theme explicitly selected and a
  # path that remains visible inside pressure-vessel.
  steamWithCursorFix = pkgs.symlinkJoin {
    name = "steam-with-cursor-fix";
    paths = [ pkgs.millennium-steam ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/steam \
        --set XCURSOR_THEME ${cursorTheme} \
        --set XCURSOR_SIZE 24 \
        --set HYPRCURSOR_SIZE 24 \
        --set XCURSOR_PATH ${config.home.homeDirectory}/.icons
    '';
  };

  # Escala da interface do cliente Steam (Configurações → Interface →
  # "Dimensionar tamanho do texto e dos ícones" / Acessibilidade). Valor entre
  # ~0.71 e ~3.41 no seu monitor; 0.8 = interface um pouco menor que o padrão.
  # A Steam grava como float longo; mantemos o mesmo formato que ela escreve.
  desktopUIScale = "0.800000011920928955";

  # config.vdf é dono da Steam (ela reescreve o arquivo a cada download, login,
  # etc.), então NÃO dá para entregá-lo como symlink read-only do nix store sem
  # travar a Steam. Em vez disso, um script de activation injeta apenas a chave
  # Accessibility/DesktopUIScale, e só quando a Steam está fechada — assim a
  # config fica reprodutível sem brigar com as escritas normais do cliente.
  patchScript = pkgs.writeShellScript "steam-ui-scale" ''
    set -eu
    cfg="${config.xdg.dataHome}/Steam/config/config.vdf"

    # Steam aberta? Não mexe — ela sobrescreveria e poderia corromper o arquivo.
    if ${pkgs.procps}/bin/pgrep -x steam >/dev/null 2>&1; then
      exit 0
    fi

    [ -f "$cfg" ] || exit 0

    # Já está no valor desejado? Nada a fazer.
    if ${pkgs.gnugrep}/bin/grep -qE '"DesktopUIScale"[[:space:]]+"${desktopUIScale}"' "$cfg"; then
      exit 0
    fi

    if ${pkgs.gnugrep}/bin/grep -qE '"DesktopUIScale"' "$cfg"; then
      # Chave existe: troca só o valor.
      ${pkgs.gnused}/bin/sed -i -E \
        's|("DesktopUIScale"[[:space:]]+")[^"]*(")|\1${desktopUIScale}\2|' "$cfg"
    elif ${pkgs.gnugrep}/bin/grep -qE '"Accessibility"' "$cfg"; then
      # Bloco Accessibility existe mas sem a chave: insere logo após a "{".
      ${pkgs.gnused}/bin/sed -i -E \
        '/"Accessibility"/{n;/\{/a\\t\t"DesktopUIScale"\t\t"${desktopUIScale}"
        }' "$cfg"
    fi
    # Se nem o bloco Accessibility existe, a Steam ainda não criou essa seção;
    # ela nasce no primeiro ajuste/execução e o próximo switch aplica o valor.
  '';
in
{
  # Aplica a escala da UI da Steam de forma declarativa (ver comentários acima).
  home.activation.steamUIScale =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run ${patchScript}
    '';

  # pressure-vessel cannot reliably follow a symlink from ~/.icons into the
  # Nix store, so install a real copy of the same theme used by Hyprland.
  home.activation.steamCursorTheme =
    lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      theme="$HOME/.icons/${cursorTheme}"
      source="${pkgs.rose-pine-cursor}/share/icons/${cursorTheme}"
      tmp="$HOME/.icons/.${cursorTheme}.tmp"

      run ${pkgs.coreutils}/bin/mkdir -p "$HOME/.icons"
      if [ -e "$theme" ]; then
        run ${pkgs.coreutils}/bin/chmod -R u+w "$theme"
      fi
      if [ -e "$tmp" ]; then
        run ${pkgs.coreutils}/bin/chmod -R u+w "$tmp"
      fi
      run ${pkgs.coreutils}/bin/rm -rf "$theme" "$tmp"
      run ${pkgs.coreutils}/bin/mkdir -p "$tmp"
      run ${pkgs.coreutils}/bin/cp -RL "$source/." "$tmp/"
      run ${pkgs.coreutils}/bin/chmod -R u+w "$tmp"
      run ${pkgs.coreutils}/bin/mv "$tmp" "$theme"
    '';

  home.file.".local/share/applications/steam.desktop".text = ''
    [Desktop Entry]
    Name=Steam
    Comment=Application for managing and launching games on Steam
    Exec=env XCURSOR_THEME=${cursorTheme} XCURSOR_SIZE=24 HYPRCURSOR_SIZE=24 XCURSOR_PATH=${config.home.homeDirectory}/.icons ${steamWithCursorFix}/bin/steam %U
    Icon=steam
    Terminal=false
    Type=Application
    Categories=Network;FileTransfer;Game;
    StartupNotify=true
    StartupWMClass=steam
  '';
}
