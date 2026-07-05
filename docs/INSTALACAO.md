# ❄️ Instalação

Guia passo a passo para reproduzir esta configuração numa instalação limpa do
NixOS. Se você só quer aplicar mudanças no dia a dia, pule para a seção
[Uso diário](#uso-diário).

## Pré-requisitos

- **NixOS 26.05** (ou release compatível) já instalado e com acesso à internet.
- **Flakes** habilitados. Se ainda não estiverem, adicione ao seu
  `configuration.nix` atual e faça um rebuild:

  ```nix
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  ```

- Permissão de `sudo` para escrever em `/etc/nixos` e rodar `nixos-rebuild`.

## 1. Clonar o repositório

A configuração espera viver em `/etc/nixos`. Faça um backup do que já existe lá
antes de sobrescrever:

```bash
sudo mv /etc/nixos /etc/nixos.bak
sudo git clone <url-do-repo> /etc/nixos
```

Se preferir manter o repositório em outro lugar, basta apontar o `--flake` para
o caminho escolhido nos comandos seguintes.

## 2. Gerar o arquivo de hardware

O `hardware-configuration.nix` incluído descreve o hardware da máquina original
(discos, sistemas de arquivos, microcode). Ele **precisa** ser substituído pelo
da sua máquina:

```bash
sudo nixos-generate-config --show-hardware-config \
  > /etc/nixos/hosts/nixos/hardware-configuration.nix
```

Revise o resultado e confirme que os pontos de montagem e o `boot.loader`
combinam com o seu disco.

## 3. Ajustar o usuário

Esta configuração cria o usuário `gabrieldorodrigues`. Para usar outro nome,
troque as referências em:

- [modules/users.nix](../modules/users.nix): definição do usuário do sistema.
- [flake.nix](../flake.nix): a linha `home-manager.users.gabrieldorodrigues`.
- [home/home.nix](../home/home.nix): `username` e `homeDirectory`.

Caminhos absolutos que apontam para a home também precisam mudar, por exemplo o
`mediaDir` em [modules/jellyfin.nix](../modules/jellyfin.nix).

## 4. Aplicar a configuração

Com o hardware e o usuário ajustados, construa e ative o sistema:

```bash
sudo nixos-rebuild switch --flake /etc/nixos#nixos
```

A primeira build baixa e compila bastante coisa, então leva um tempo. Ao
terminar, reinicie para entrar pelo SDDM e escolher a sessão **Hyprland** (ou
**KDE Plasma 6** como alternativa).

## 5. Definir a senha e conferir

Depois do primeiro boot, defina a senha do usuário, caso ainda não tenha feito:

```bash
sudo passwd gabrieldorodrigues
```

## Uso diário

Para aplicar qualquer mudança feita nos arquivos `.nix`, rode o atalho de shell
`update` (definido em [modules/shell.nix](../modules/shell.nix)):

```bash
update
```

Ele é um envelope para o comando abaixo e, ao final de uma build bem-sucedida,
reindexa o launcher Walker para que apps novos apareçam sem relogar:

```bash
sudo nixos-rebuild switch --flake /etc/nixos#nixos
```

Argumentos extras são repassados ao `nixos-rebuild`, por exemplo:

```bash
update --show-trace
```

## Atualizar as entradas do flake

Para atualizar `nixpkgs`, `home-manager` e as demais entradas para as versões
mais recentes, atualize o `flake.lock` e faça um rebuild:

```bash
cd /etc/nixos
sudo nix flake update
update
```

Para atualizar só uma entrada específica:

```bash
sudo nix flake update nixpkgs
```

## Reverter

Toda geração fica no menu do bootloader. Se um rebuild quebrar algo, reinicie e
escolha a geração anterior. Também dá para reverter pela linha de comando:

```bash
sudo nixos-rebuild switch --rollback
```

## Dicas de diagnóstico

- **Validar sem ativar** (não pede `sudo`):

  ```bash
  nix eval --raw '/etc/nixos#nixosConfigurations.nixos.config.system.build.toplevel.drvPath'
  ```

  O aviso `Git tree ... is dirty` é inofensivo quando há mudanças não commitadas.

- **Arquivos novos não são vistos pelo flake** enquanto não forem rastreados
  pelo git. Rode `git add` antes do rebuild.

- **Testar sem tornar padrão**: `sudo nixos-rebuild test --flake /etc/nixos#nixos`
  aplica a configuração sem gravá-la como boot padrão.
