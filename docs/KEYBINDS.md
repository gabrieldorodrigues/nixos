# Keybinds — Hyprland

Atalhos definidos em [`home/programs/hypr/default.nix`](../home/programs/hypr/default.nix).
Modificador principal (`mainMod`): **Super** (tecla Windows).

**Apps padrão:** terminal = `kitty` · gerenciador de arquivos = `nautilus` · menu = `walker` · navegador = `firefox`

---

## Gerenciamento de janelas

| Atalho           | Ação                             |
| ---------------- | -------------------------------- |
| `Super + W`      | Fechar janela em foco            |
| `Super + F`      | Alternar tela cheia              |
| `Super + T`      | Alternar flutuante/tiling        |
| `Super + P`      | Pseudo-tile (dwindle)            |
| `Super + L`      | Bloquear tela (hyprlock)         |
| `Super + Delete` | Sair da sessão Hyprland (logout) |

## Foco e movimento

| Atalho                    | Ação                              |
| ------------------------- | --------------------------------- |
| `Super + ←/→/↑/↓`         | Mover foco na direção             |
| `Super + Shift + ←/→/↑/↓` | Mover janela na direção           |
| `Alt + Tab`               | Alternar entre janelas (próxima)  |
| `Alt + Shift + Tab`       | Alternar entre janelas (anterior) |

## Mouse

| Atalho                              | Ação                 |
| ----------------------------------- | -------------------- |
| `Super + Botão esquerdo` (arrastar) | Mover janela         |
| `Super + Botão direito` (arrastar)  | Redimensionar janela |

## Workspaces

| Atalho                       | Ação                                    |
| ---------------------------- | --------------------------------------- |
| `Super + 1`…`9`, `0`         | Ir para workspace 1–10                  |
| `Super + Shift + 1`…`9`, `0` | Mover janela para workspace 1–10        |
| `Super + Tab`                | Próximo workspace                       |
| `Super + Q`                  | Workspace anterior                      |
| `Super + S`                  | Mostrar scratchpad (workspace especial) |
| `Super + Alt + S`            | Mover janela para o scratchpad          |
| Swipe 3 dedos (horizontal)   | Trocar de workspace (touchpad)          |

## Aplicativos

| Atalho                    | Ação                                             |
| ------------------------- | ------------------------------------------------ |
| `Super + Space`           | Lançador de apps (walker)                        |
| `Super + Return`          | Terminal (kitty)                                 |
| `Super + Shift + F`       | Gerenciador de arquivos — nova janela (nautilus) |
| `Super + Shift + B`       | Navegador (firefox)                              |
| `Super + Shift + Alt + B` | Navegador — janela privada                       |
| `Super + Shift + M`       | Música (spotify)                                 |
| `Super + Shift + N`       | Editor (VS Code)                                 |
| `Super + Shift + D`       | Docker (kitty + lazydocker)                      |
| `Super + Shift + T`       | Torrents (kitty + torlnk)                        |
| `Super + Shift + O`       | Obsidian                                         |
| `Super + Shift + P`       | Leitor (readest)                                 |

## Clipboard e símbolos

| Atalho             | Ação                                         |
| ------------------ | -------------------------------------------- |
| `Super + C`        | Histórico de clipboard (cliphist via walker) |
| `Super + Ctrl + E` | Seletor de emoji/símbolos (walker)           |

## Wallpaper

| Atalho                 | Ação                               |
| ---------------------- | ---------------------------------- |
| `Super + Ctrl + Space` | Seletor de wallpaper (menu walker) |
| `Super + Shift + W`    | Próximo wallpaper (ciclar)         |

## Screenshots e cores

| Atalho                  | Ação                        |
| ----------------------- | --------------------------- |
| `Super + Shift + S`     | Screenshot de região        |
| `Super + Shift + Print` | Screenshot de região        |
| `Print`                 | Screenshot da tela inteira  |
| `Super + Print`         | Seletor de cor (hyprpicker) |

> Screenshots são salvos em `~/Pictures/Screenshots/`, copiados para o clipboard e notificados.

## Mídia e hardware

> Funcionam mesmo com a tela bloqueada.

| Atalho                              | Ação                       |
| ----------------------------------- | -------------------------- |
| `Volume +` / `Volume −`             | Volume ±5%                 |
| `Alt + Volume +` / `Alt + Volume −` | Volume ±1% (ajuste fino)   |
| `Mute`                              | Alternar mudo              |
| `Mic Mute`                          | Alternar mudo do microfone |
| `Brilho +` / `Brilho −`             | Brilho ±5%                 |
| `Alt + Brilho +` / `Alt + Brilho −` | Brilho ±1% (ajuste fino)   |
| `Shift + Brilho +`                  | Brilho 100%                |
| `Shift + Brilho −`                  | Brilho mínimo (1%)         |
| `Play` / `Pause`                    | Play/pause (playerctl)     |
| `Próxima` / `Anterior`              | Próxima / faixa anterior   |

---

## Regras de janela

- Suprime o evento de maximizar em todas as janelas.
- Flutuam: `pavucontrol`, `nm-connection-editor`, diálogos "Open File".
