# ❄️ Estrutura do repositório

Como o repositório é organizado e por onde começar a mexer. A ideia central é
separar o que é **sistema** (NixOS, em `modules/`) do que é **usuário**
(Home Manager, em `home/`), amarrando tudo num único `flake.nix`.

## Visão geral

```
.
├── flake.nix         entradas, host e integração com Home Manager
├── flake.lock        versões fixadas de cada entrada
├── docs/             esta documentação
├── hosts/            configuração específica de cada máquina
├── modules/          módulos de sistema (NixOS)
└── home/             configuração de usuário (Home Manager)
```

## O fluxo de avaliação

A ordem em que os arquivos são carregados:

1. **`flake.nix`** define a saída `nixosConfigurations.nixos` e injeta o
   Home Manager como módulo NixOS. É aqui que as entradas externas
   (`nixpkgs`, `home-manager`, `zen-browser`, `torlink`) entram.
2. **`hosts/nixos/configuration.nix`** é o ponto de entrada do host. Ele importa
   o `hardware-configuration.nix` e a lista de módulos de `modules/`.
3. **`modules/*.nix`** descrevem o sistema: boot, rede, desktop, pacotes,
   serviços e afins.
4. **`home/home.nix`** importa `home/programs/`, que configura os aplicativos do
   usuário.

## `flake.nix`

Declara as entradas e monta o host `nixos` para `x86_64-linux`. O Home Manager
roda no modo integrado ao NixOS (`useGlobalPkgs` e `useUserPackages`), com backup
automático de arquivos sobrescritos usando a extensão `.hm-bak`.

As entradas externas:

| Entrada        | Para que serve                                                  |
| -------------- | --------------------------------------------------------------- |
| `nixpkgs`      | conjunto principal de pacotes (canal `nixos-26.05`)             |
| `home-manager` | configuração declarativa do usuário                             |
| `zen-browser`  | navegador Zen empacotado como flake                             |
| `torlink`      | fonte do container de torrents `torlnk` (`modules/torlink.nix`) |

## `hosts/`

Uma pasta por máquina. Hoje há apenas `nixos/`, com:

- **`configuration.nix`**: importa o hardware e todos os módulos do sistema.
  Define também o `system.stateVersion`.
- **`hardware-configuration.nix`**: gerado pelo `nixos-generate-config`, é
  específico do hardware. Deve ser regenerado em cada máquina nova.

## `modules/`

Módulos de sistema, cada um cuidando de uma área. Veja a referência completa em
[MODULOS.md](MODULOS.md). As listas de pacotes ficam separadas por categoria em
`modules/packages/`.

## `home/`

Configuração de usuário via Home Manager.

- **`home.nix`**: define `username`, `homeDirectory` e importa `programs/`.
- **`programs/`**: um diretório ou arquivo por aplicativo (Hyprland, Waybar,
  kitty, Walker, mako, btop, GTK, entre outros).
- **`wallpapers/`**: imagens versionadas no repositório. O Hyprland aponta um
  symlink em `~/Pictures/wallpaper` para esta pasta, então dá para adicionar ou
  trocar wallpapers sem rebuild.

## Convenções

- **Sistema em `modules/`, usuário em `home/`.** Se a mudança afeta serviços,
  drivers ou pacotes globais, é módulo. Se afeta só a sua sessão e dotfiles, é
  Home Manager.
- **Pacotes por categoria.** Novos programas de linha de comando vão em
  `modules/packages/cli.nix`, apps gráficos em `apps.nix`, e assim por diante.
- **Caminhos absolutos** que apontam para a home (mídia, wallpapers) assumem o
  usuário `gabrieldorodrigues`. Ajuste ao trocar de usuário.
- **Arquivos novos precisam de `git add`** antes do rebuild, senão o flake não
  os enxerga.
