# ❄️ Módulos e programas

Referência do que cada módulo de sistema (`modules/`) e cada configuração de
usuário (`home/programs/`) faz. Para o Jellyfin, veja o guia dedicado em
[JELLYFIN.md](JELLYFIN.md).

## Módulos de sistema

Todos são importados por [hosts/nixos/configuration.nix](../hosts/nixos/configuration.nix).

### `boot.nix`

Bootloader GRUB com suporte a EFI. O `os-prober` fica ligado para detectar o
Windows em dual boot, e o `systemd-boot` fica desligado. Partição EFI em `/boot`.

### `networking.nix`

Define o hostname `nixos` e habilita o NetworkManager para gerenciar as conexões.

### `locale.nix`

Fuso horário `America/Sao_Paulo`. Locale padrão `en_US.UTF-8` com as categorias
regionais (`LC_*`) em `pt_BR.UTF-8`, ou seja, sistema em inglês com formatos
brasileiros de data, moeda e números.

### `desktop.nix`

Camada X11 e ambiente alternativo. Habilita o servidor X, o **SDDM** como tela de
login e o **KDE Plasma 6** como sessão reserva. Teclado no layout `br` (console
`br-abnt2`) e impressão via CUPS.

### `hyprland.nix`

O ambiente principal. Configura o compositor **Hyprland** (Wayland), a barra
**Waybar**, o launcher **Walker** com o backend `elephant` e o daemon de
wallpaper `awww`. Inclui o utilitário `reindex-walker`, usado pelo atalho
`update` para atualizar o índice de apps do launcher após um rebuild. Os
wallpapers ficam versionados em [home/wallpapers](../home/wallpapers) e são
expostos por um symlink em `~/Pictures/wallpaper`.

### `sound.nix`

Áudio com **PipeWire** (ALSA, suporte a 32 bits e compatibilidade PulseAudio),
com `rtkit` para prioridade de tempo real. O PulseAudio nativo fica desligado.

### `users.nix`

Cria o usuário `gabrieldorodrigues` nos grupos `networkmanager`, `wheel` (sudo) e
`docker` (usar o Docker sem sudo). Shell padrão: fish.

### `shell.nix`

Configura o **fish** como shell interativo principal e o **zsh** como alternativa,
com o prompt **Tide**. Define o wrapper `update`, que roda
`nixos-rebuild switch --flake /etc/nixos#nixos` e, no sucesso, reindexa o Walker.
Argumentos extras são repassados ao `nixos-rebuild`.

### `packages.nix`

Ponto central de pacotes. Importa as listas por categoria de
[modules/packages/](../modules/packages), habilita o Firefox, libera pacotes
unfree e define os aplicativos padrão por tipo de arquivo (`xdg.mime`). Também
permite explicitamente o `electron-39` exigido pelo Obsidian.

As listas por categoria:

| Arquivo      | Conteúdo                         |
| ------------ | -------------------------------- |
| `cli.nix`    | utilitários de linha de comando  |
| `apps.nix`   | aplicativos gráficos             |
| `gaming.nix` | jogos e ferramentas relacionadas |
| `media.nix`  | áudio, vídeo e mídia             |

### `dev.nix`

Ambiente de desenvolvimento. Habilita o **Docker** (daemon rootful, com
`autoPrune`) e instala ferramentas de linha de comando agnósticas de linguagem
(`ripgrep`, `fd`, `jq`, `yq`, `tree`, `wget`, `httpie`, `gh`, `lazygit`, `delta`,
`neovim`, `just`), além dos build essentials e toolchains de Node.js/TypeScript e
Python. O `lazydocker` já vem instalado.

### `jellyfin.nix`

Servidor **Jellyfin** em container Docker, declarativo, com plugins, tema
ElegantFin e Live TV (IPTV) pré-configurados. Detalhado em [JELLYFIN.md](JELLYFIN.md).

### `git.nix`

Configuração de git no nível do sistema: nome e email do usuário, branch padrão
`main`, `pull.rebase` ligado e `push.autoSetupRemote` ligado.

### `nix-settings.nix`

Habilita os recursos experimentais `nix-command` e `flakes` no daemon Nix.

## Programas do usuário

Ficam em [home/programs/](../home/programs) e são importados por
[home/home.nix](../home/home.nix).

| Programa     | Papel                                                   |
| ------------ | ------------------------------------------------------- |
| `hypr/`      | regras, atalhos e autostart do Hyprland (config em Lua) |
| `waybar/`    | barra de status                                         |
| `walker/`    | launcher de apps e seletor de wallpaper em grade        |
| `kitty/`     | terminal principal, com tema Catppuccin                 |
| `mako/`      | daemon de notificações (timeout de 10s)                 |
| `btop/`      | monitor de recursos no terminal                         |
| `gtk/`       | tema GTK escuro, ícones Papirus                         |
| `fastfetch/` | resumo do sistema no terminal                           |
| `direnv.nix` | ambientes por diretório (`direnv` + `nix-direnv`)       |
| `rclone/`    | sincronização com armazenamento remoto                  |
| `torlink/`   | buscador de torrents no terminal (`torlnk`)             |

## Onde mexer para tarefas comuns

| Quero...                        | Vá para                                                                      |
| ------------------------------- | ---------------------------------------------------------------------------- |
| Adicionar um pacote de terminal | [modules/packages/cli.nix](../modules/packages/cli.nix)                      |
| Adicionar um app gráfico        | [modules/packages/apps.nix](../modules/packages/apps.nix)                    |
| Mudar atalhos do Hyprland       | [home/programs/hypr](../home/programs/hypr)                                  |
| Ajustar a barra                 | [home/programs/waybar](../home/programs/waybar)                              |
| Trocar o tema do terminal       | [home/programs/kitty](../home/programs/kitty)                                |
| Configurar o shell/prompt       | [modules/shell.nix](../modules/shell.nix)                                    |
| Mexer no Jellyfin/Live TV       | [modules/jellyfin.nix](../modules/jellyfin.nix) e [JELLYFIN.md](JELLYFIN.md) |
