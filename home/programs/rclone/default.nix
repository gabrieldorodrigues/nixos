{ pkgs, lib, ... }:

# rclone — monta o Google Drive como uma pasta normal em ~/GoogleDrive.
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
# O serviço tenta montar automaticamente no login; enquanto o remote "gdrive"
# não existir ele apenas fica reiniciando a cada 10s (inofensivo).

let
  mountDir = "%h/GoogleDrive";
  remote = "gdrive:";
  # rclone precisa do fusermount3 *setuid* para (des)montar; no NixOS ele fica
  # no wrapper estável abaixo, não no binário puro do store.
  fusermount3 = "/run/wrappers/bin/fusermount3";

  rcloneMount = lib.concatStringsSep " " [
    "${pkgs.rclone}/bin/rclone mount ${remote} ${mountDir}"
    "--config %h/.config/rclone/rclone.conf"
    "--vfs-cache-mode writes" # permite editar/enviar arquivos corretamente
    "--dir-cache-time 24h" # cache de listagem de pastas
    "--poll-interval 15s" # propaga mudanças feitas na web em ~15s
    "--umask 077" # arquivos montados ficam privados ao usuário
  ];
in
{
  home.packages = [ pkgs.rclone ];

  systemd.user.services.rclone-gdrive = {
    Unit = {
      Description = "rclone: monta o Google Drive (gdrive:) em ~/GoogleDrive";
      Documentation = [ "man:rclone(1)" ];
    };

    Service = {
      Type = "notify"; # rclone avisa o systemd quando o mount está pronto
      # Garante que rclone ache o fusermount3 setuid ao montar.
      Environment = [ "PATH=/run/wrappers/bin:/run/current-system/sw/bin" ];
      # Limpa um mountpoint "zumbi" de um crash anterior e cria a pasta.
      ExecStartPre = [
        "-${fusermount3} -uz ${mountDir}"
        "${pkgs.coreutils}/bin/mkdir -p ${mountDir}"
      ];
      ExecStart = rcloneMount;
      ExecStop = "${fusermount3} -u ${mountDir}";
      # Se a rede ainda não subiu no login, tenta de novo até conseguir.
      Restart = "on-failure";
      RestartSec = "10";
    };

    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
