# ❄️ NixOS + Hyprland

Configuração pessoal e reprodutível do meu sistema, escrita como um **flake NixOS**
com **Home Manager**. Todo o ambiente, do bootloader ao tema do terminal, vive
neste repositório e é aplicado com um único comando.

![NixOS](https://img.shields.io/badge/NixOS-26.05-5277C3?logo=nixos&logoColor=white)
![Home Manager](https://img.shields.io/badge/Home_Manager-26.05-4C6EF5)
![Hyprland](https://img.shields.io/badge/Hyprland-Wayland-58E1FF)
![Shell](https://img.shields.io/badge/shell-fish-89DCEB)

## Sobre

Este é o `flake.nix` que descreve a máquina `nixos` (x86_64): pacotes, serviços,
usuário e toda a configuração da área de trabalho. A ideia é simples: o sistema
inteiro é declarativo, versionado e recriável em qualquer instalação limpa do
NixOS.

O ambiente principal é o **Hyprland**, um compositor Wayland com tiling. O
**KDE Plasma 6** fica disponível como sessão alternativa na tela de login.

## Destaques

- **Declarativo de ponta a ponta.** Sistema (`modules/`) e usuário (`home/`) num
  só flake, com entradas fixadas em `flake.lock`.
- **Rice do Hyprland** configurado em Lua, com Waybar, launcher Walker e um
  seletor de wallpapers em grade.
- **Dois ambientes.** Hyprland (Wayland) como principal e KDE Plasma 6 como
  reserva, escolhidos no SDDM.
- **Terminal e shell caprichados.** kitty com tema Catppuccin e fish com prompt
  Tide.
- **Jellyfin declarativo** em Docker, com plugins, tema e Live TV já configurados.
- **Wallpapers versionados** no próprio repositório, aplicados por daemon.

## O ambiente

| Camada        | Ferramenta                                           |
| ------------- | ---------------------------------------------------- |
| Compositor    | Hyprland (Wayland)                                   |
| Barra         | Waybar                                               |
| Launcher      | Walker + elephant                                    |
| Notificações  | mako                                                 |
| Bloqueio/idle | hyprlock + hypridle                                  |
| Wallpaper     | awww (daemon) + seletor em grade no Walker           |
| Clipboard     | cliphist                                             |
| Terminal      | kitty (principal) e alacritty                        |
| Shell         | fish (padrão, prompt Tide) e zsh                     |
| Tema          | Catppuccin Mocha, ícones Papirus, GTK em modo escuro |
| Login         | SDDM (sessões Hyprland e KDE Plasma 6)               |
| Mídia         | Jellyfin em Docker (plugins, tema e Live TV)         |

## Estrutura do repositório

```
.
├── flake.nix              # entradas, host e integração com Home Manager
├── flake.lock
├── docs/
│   ├── INSTALACAO.md      # guia de instalação passo a passo
│   ├── ESTRUTURA.md       # como o repositório é organizado
│   ├── MODULOS.md         # referência de cada módulo e programa
│   ├── JELLYFIN.md        # Jellyfin em Docker, plugins e Live TV
│   └── KEYBINDS.md        # todos os atalhos do Hyprland
├── hosts/
│   └── nixos/             # configuração e hardware desta máquina
├── modules/               # módulos de sistema (NixOS)
│   ├── boot.nix           # bootloader
│   ├── desktop.nix        # X11, SDDM, KDE Plasma
│   ├── hyprland.nix       # compositor, wallpaper, launcher
│   ├── packages.nix       # importa packages/ e define apps padrão
│   ├── packages/          # listas de pacotes por categoria
│   │   ├── cli.nix
│   │   ├── apps.nix
│   │   ├── gaming.nix
│   │   └── media.nix
│   ├── shell.nix          # fish, zsh e prompt
│   ├── dev.nix            # Docker e toolchains de desenvolvimento
│   ├── jellyfin.nix       # Jellyfin em Docker (plugins, tema, Live TV)
│   ├── networking.nix
│   ├── sound.nix
│   ├── users.nix
│   ├── git.nix
│   ├── locale.nix
│   └── nix-settings.nix
└── home/                  # configuração de usuário (Home Manager)
    ├── home.nix
    ├── programs/          # btop, gtk, hypr, kitty, mako, walker, waybar, etc.
    └── wallpapers/        # wallpapers versionados
```

Para uma visão detalhada de cada arquivo, veja [docs/ESTRUTURA.md](docs/ESTRUTURA.md)
e [docs/MODULOS.md](docs/MODULOS.md).

## Pré-requisitos

- Uma instalação do **NixOS 26.05** (ou compatível).
- **Flakes** habilitados (`experimental-features = nix-command flakes`).
- Um `hardware-configuration.nix` gerado para a sua máquina. O incluído em
  [hosts/nixos](hosts/nixos) é específico deste hardware.

## Como usar

O guia completo fica em [docs/INSTALACAO.md](docs/INSTALACAO.md). Em resumo:

Clone o repositório para `/etc/nixos` (ou aponte o `--flake` para onde ele estiver):

```bash
sudo git clone <url-do-repo> /etc/nixos
```

Gere o arquivo de hardware da sua máquina, se ainda não existir:

```bash
sudo nixos-generate-config --show-hardware-config > /etc/nixos/hosts/nixos/hardware-configuration.nix
```

Aplique a configuração:

```bash
sudo nixos-rebuild switch --flake /etc/nixos#nixos
```

O shell já traz o atalho `update` para o mesmo comando:

```bash
update
```

## Atalhos

Todos os atalhos de teclado do Hyprland estão documentados em
[docs/KEYBINDS.md](docs/KEYBINDS.md). O modificador principal é a tecla **Super**.

Alguns dos mais usados:

| Atalho                 | Ação                    |
| ---------------------- | ----------------------- |
| `Super + Space`        | Launcher de aplicativos |
| `Super + Return`       | Terminal                |
| `Super + Ctrl + Space` | Seletor de wallpaper    |
| `Super + W`            | Fechar janela           |
| `Super + L`            | Bloquear a tela         |

## Personalização

- **Pacotes**: [modules/packages.nix](modules/packages.nix) e a pasta
  [modules/packages](modules/packages).
- **Compositor e wallpaper**: [modules/hyprland.nix](modules/hyprland.nix) e
  [home/programs/hypr](home/programs/hypr).
- **Barra**: [home/programs/waybar](home/programs/waybar).
- **Launcher e seletor de wallpaper**: [home/programs/walker](home/programs/walker).
- **Terminal**: [home/programs/kitty](home/programs/kitty).
- **Shell e prompt**: [modules/shell.nix](modules/shell.nix).
- **Jellyfin e Live TV**: [modules/jellyfin.nix](modules/jellyfin.nix), detalhado
  em [docs/JELLYFIN.md](docs/JELLYFIN.md).

## Entradas do flake

| Entrada        | Origem                                      |
| -------------- | ------------------------------------------- |
| `nixpkgs`      | `github:NixOS/nixpkgs/nixos-26.05`          |
| `home-manager` | `github:nix-community/home-manager` (26.05) |
| `zen-browser`  | `github:youwen5/zen-browser-flake`          |
| `torlink`      | `github:baairon/torlink`                    |

## Licença

Configuração pessoal, compartilhada como referência. Sinta-se à vontade para se
inspirar e reaproveitar o que for útil.
