# ❄️ Jellyfin em Docker

O [modules/jellyfin.nix](../modules/jellyfin.nix) sobe um servidor **Jellyfin**
em container Docker, de forma declarativa, já com plugins, tema e Live TV
configurados. Nada precisa ser instalado pela interface na primeira execução.

## Visão geral

| Item       | Valor                                                       |
| ---------- | ----------------------------------------------------------- |
| Imagem     | `jellyfin/jellyfin:10.11.11`                                |
| Porta      | `8096` (liberada no firewall para a LAN)                    |
| Estado     | `/var/lib/jellyfin-docker/config` montado em `/config`      |
| Cache      | `/var/lib/jellyfin-docker/cache` montado em `/cache`        |
| Biblioteca | `~/Downloads/torlink` montada em `/media` (somente leitura) |
| Aceleração | `/dev/dri` repassado ao container (VAAPI)                   |
| Fuso       | `America/Sao_Paulo`                                         |

A versão do Jellyfin é fixada porque precisa casar com o `targetAbi` dos plugins.
Atualizar o Jellyfin exige atualizar juntos a versão, o hash e o `targetAbi` de
cada plugin.

## Acesso

Depois do primeiro rebuild, abra `http://localhost:8096` (ou o IP da máquina na
rede) e crie o usuário administrador. A biblioteca de mídia aponta para
`~/Downloads/torlink` em modo somente leitura.

## Plugins e tema

O serviço `jellyfin-setup` roda antes do container subir e sincroniza a versão
declarada de cada plugin, além de semear o tema. Os plugins incluídos:

| Plugin              | Para que serve                                       |
| ------------------- | ---------------------------------------------------- |
| File Transformation | base que injeta scripts no cliente web (dependência) |
| Media Bar           | carrossel de destaques na home                       |
| Anime Multi Source  | metadados de anime de várias fontes                  |
| Auto Collections    | cria coleções automaticamente por regras             |
| Intro Skipper       | botão para pular aberturas e encerramentos           |
| Plugin Pages        | abas separadas na home (Filmes, Anime, TV)           |
| GetAvatar           | avatar de usuário por upload ou URL                  |
| LetterboxdSync      | sincroniza avaliações com o Letterboxd               |
| WhisperSubs         | legendas por IA (precisa de backend Whisper externo) |

O tema é o **ElegantFin**, aplicado via Custom CSS no `branding.xml`. O mesmo CSS
esconde o pôster do Media Bar quando o trailer começa, deixando o trailer ocupar
a largura toda.

## Como o setup funciona

O `jellyfin-setup` (systemd, `oneshot`) roda a cada start do container e:

1. Copia a pasta de cada plugin do nix store para `config/plugins`, tornando-a
   gravável.
2. Semeia o `branding.xml` (tema) apenas se ainda não existir, para não
   sobrescrever ajustes feitos na interface.
3. Semeia o `livetv.xml` (Live TV) na primeira vez. Se já existir, apenas
   reaponta a URL do tuner para o valor declarado.

Detalhe importante: adicionar ou mudar um plugin, o CSS ou a configuração de
Live TV altera só o `jellyfin-setup`. O serviço do container em si não muda,
então o `nixos-rebuild` **não reinicia o Jellyfin sozinho**. Depois do rebuild,
reinicie o container para recarregar:

```bash
sudo systemctl restart docker-jellyfin.service
```

## Live TV (IPTV)

A configuração de Live TV combina duas peças:

- **Tuner M3U**: a lista pública de canais abertos brasileiros do iptv-org
  (`https://iptv-org.github.io/iptv/countries/br.m3u`). É o que fornece os
  streams. O Jellyfin baixa a lista da URL, ela não fica versionada no repositório.
- **Guia XMLTV (EPG)**: a grade de programação do epgshare01
  (`epg_ripper_BR1.xml.gz`). É só o guia de horários, não os canais.

O `EnableAllTuners` faz o EPG casar com qualquer canal cujo id de guia bata com o
`tvg-id` da lista M3U.

### Popular os canais

Semear o `livetv.xml` deixa o Jellyfin **ciente** do tuner, mas não escaneia os
canais sozinho. Isso só acontece na tarefa agendada **Atualizar Guia** (Refresh
Guide), que não roda automaticamente após semear e reiniciar. Depois do primeiro
rebuild e restart, rode a tarefa uma vez:

1. Abra o Painel (Dashboard).
2. Vá em **Tarefas Agendadas**.
3. Na seção **Live TV**, execute **Atualizar Guia**.

Os canais aparecem em seguida em **TV ao Vivo → Canais**.

### Trocar a lista ou o guia

As URLs ficam nas variáveis `m3uUrl` e `epgUrl` no topo do bloco de Live TV em
[modules/jellyfin.nix](../modules/jellyfin.nix). Depois de mudar, faça o rebuild,
reinicie o container e rode **Atualizar Guia** de novo.

Listas privadas com URLs de streams não devem ser versionadas neste repositório
(ele é público). O `.gitignore` já ignora `*.m3u` e `*.m3u8` para evitar commit
acidental. Para usar uma lista local, deixe o arquivo fora do git e aponte o
tuner pela interface do Jellyfin.

## Solução de problemas

### "Playback failed" ao abrir um canal

Quase sempre é o stream de origem que caiu, não o Jellyfin. Listas públicas
gratuitas têm muitos canais offline, com bloqueio geográfico ou 403. No log do
container aparece algo como `HTTP error 403 Forbidden` seguido de
`FFmpeg exited with code 251`. O que fazer:

- Escolha outro canal. Evite os marcados com `[Geo-blocked]` ou `[Not 24/7]`.
- Para checar o log:

  ```bash
  sudo docker logs jellyfin 2>&1 | grep -iE 'error|ffmpeg|403' | tail -n 20
  ```

- Para testar um stream específico com o ffprobe do próprio Jellyfin:

  ```bash
  sudo docker exec jellyfin /usr/lib/jellyfin-ffmpeg/ffprobe -v error \
    -user_agent "Mozilla/5.0" \
    -show_entries stream=codec_name,codec_type,width,height \
    -of default=noprint_wrappers=1 "<url-do-stream>"
  ```

### A lista de canais está vazia

Rode a tarefa **Atualizar Guia** (veja [Popular os canais](#popular-os-canais)).
Só semear o `livetv.xml` não popula os canais.

### O guia (horários) não carrega

O download do EPG do epgshare01 às vezes falha de forma temporária
(`Resource temporarily unavailable`). O Jellyfin tenta de novo sozinho. Os canais
tocam normalmente mesmo sem o guia.

### O CSS do tema não muda

O `branding.xml` não é sobrescrito quando já existe, então editar só o template
no `.nix` não afeta uma instalação que já rodou. É preciso editar também o
arquivo em disco (`/var/lib/jellyfin-docker/config/config/branding.xml`) e
reiniciar o container, que mantém o branding em memória.

### Muitos canais travando

Boa parte dos canais brasileiros é HEVC (H.265), que o navegador não reproduz
direto, então o Jellyfin transcodifica por software (uso alto de CPU). O
`/dev/dri` já está repassado ao container para aceleração por hardware; ajuste a
transcodificação nas configurações de reprodução do Jellyfin se precisar.

### WhisperSubs não gera legendas

O plugin depende de um backend Whisper externo (por exemplo
`whisper-asr-webservice`) configurado nas opções dele. Sozinho, ele não
transcreve.
