{ config, lib, pkgs, ... }:

let
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
}
