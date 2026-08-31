{ pkgs, lib, ... }:

# rclone — monta Google Drive e Proton Drive como pastas normais na Home.
#
# POR QUE rclone (e não GNOME Online Accounts)?
#   O gvfs 1.60 REMOVEU o backend de Google Drive (o antigo `gvfsd-google`
#   dependia da libgdata, que foi abandonada e retirada do nixpkgs). Por isso
#   a conta Google adicionada no GNOME Online Accounts só oferece Mail/Agenda/
#   Contatos — o toggle "Arquivos" não existe mais e não há `google-drive://`.
#   O rclone é o substituto padrão atual: monta o Drive via FUSE e ele aparece
#   no Nautilus como uma pasta comum dentro da Home.
#
# >>> PASSO MANUAL (só uma vez, depois do primeiro rebuild) <<<
#   1. Rode:  rclone config
#   2. n) New remote  →  name> gdrive   (o nome PRECISA ser exatamente "gdrive")
#   3. Storage> drive        (Google Drive)
#   4. client_id / client_secret: deixe em branco (Enter)
#   5. scope> 1              (acesso total)
#   6. Enter até "Use web browser to authenticate?" → y → faça o login no navegador
#   7. "Configure this as a Shared Drive (Team Drive)?" → n
#   8. y) Yes this is OK  →  q) Quit config
#   Depois:  systemctl --user restart rclone-gdrive
#
# Proton Drive:
#   1. Rode: rclone config
#   2. n) New remote → name> protondrive (o nome PRECISA ser esse)
#   3. Storage> protondrive → informe a conta Proton e conclua o 2FA, se pedido
#   4. y) Yes this is OK → q) Quit config
#   Depois: systemctl --user restart rclone-protondrive
#
# O serviço tenta montar automaticamente no login; enquanto o remote "gdrive"
# ou "protondrive" não existir, o respectivo serviço tenta novamente a cada 10s.

let
  # rclone precisa do fusermount3 *setuid* para (des)montar; no NixOS ele fica
  # no wrapper estável abaixo, não no binário puro do store.
  fusermount3 = "/run/wrappers/bin/fusermount3";

  mkRcloneMount = {
    description,
    remote,
    mountDir,
    extraOptions ? [ ],
    restart ? "on-failure",
  }: {
    Unit = {
      Description = description;
      Documentation = [ "man:rclone(1)" ];
    };

    Service = {
      Type = "notify";
      Environment = [ "PATH=/run/wrappers/bin:/run/current-system/sw/bin" ];
      ExecStartPre = [
        "-${fusermount3} -uz ${mountDir}"
        "${pkgs.coreutils}/bin/mkdir -p ${mountDir}"
      ];
      ExecStart = lib.concatStringsSep " " ([
        "${pkgs.rclone}/bin/rclone mount ${remote} ${mountDir}"
        "--config %h/.config/rclone/rclone.conf"
        "--vfs-cache-mode writes"
        "--dir-cache-time 24h"
        "--umask 077"
      ] ++ extraOptions);
      ExecStop = "${fusermount3} -u ${mountDir}";
      Restart = restart;
      RestartSec = "10";
    };

    Install.WantedBy = [ "default.target" ];
  };
in
{
  home.packages = [ pkgs.rclone ];

  # Mantém os favoritos existentes e adiciona o mount à sidebar do Nautilus.
  home.activation.protonDriveBookmark =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      bookmarks="$HOME/.config/gtk-3.0/bookmarks"
      entry="file://$HOME/ProtonDrive Proton Drive"
      run ${pkgs.coreutils}/bin/mkdir -p "$HOME/.config/gtk-3.0"
      if [ ! -f "$bookmarks" ] || ! ${pkgs.gnugrep}/bin/grep -Fxq "$entry" "$bookmarks"; then
        if [ -n "''${DRY_RUN_CMD:-}" ]; then
          echo "Would add Proton Drive to $bookmarks"
        else
          printf '%s\n' "$entry" >> "$bookmarks"
        fi
      fi
    '';

  systemd.user.services.rclone-gdrive = mkRcloneMount {
    description = "rclone: monta o Google Drive (gdrive:) em ~/GoogleDrive";
    remote = "gdrive:";
    mountDir = "%h/GoogleDrive";
    extraOptions = [ "--poll-interval 15s" ];
  };

  systemd.user.services.rclone-protondrive = mkRcloneMount {
    description = "rclone: monta o Proton Drive (protondrive:) em ~/ProtonDrive";
    remote = "protondrive:";
    mountDir = "%h/ProtonDrive";
    # O backend Proton é experimental e a API aplica rate limit agressivo;
    # não entre em loop quando ela responder 500/503.
    restart = "no";
  };
}
