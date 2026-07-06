{ pkgs, inputs, ... }:

# opencode — agente de IA no terminal (edição de código, tool use).
#
# Usa o endpoint GRATUITO da NVIDIA NIM (compatível com a API da OpenAI) com o
# modelo GLM-5.2. O opencode aceita qualquer provedor OpenAI-compatible via o
# pacote "@ai-sdk/openai-compatible" (baixado por ele mesmo no primeiro uso).
#
# O pacote vem do nixpkgs-unstable: o opencode evolui rápido e a versão do
# canal 26.05 fica velha (o auto-updater embutido NÃO funciona no NixOS, pois
# o binário fica no /nix/store somente-leitura). Assim recebemos versões novas
# via rebuild, sem afetar o resto do sistema.
#
# A CHAVE DA API NÃO fica aqui (o repositório é público). Ela é lida da variável
# de ambiente NVIDIA_API_KEY, que o fish exporta a partir de um arquivo fora do
# repo (~/.config/secrets/nvidia-api-key) — ver modules/shell.nix.
#
# >>> PASSO MANUAL (só uma vez) <<<
#   printf '%s' 'nvapi-suaChaveAqui' > ~/.config/secrets/nvidia-api-key
#   chmod 600 ~/.config/secrets/nvidia-api-key
#   (gere a chave em https://build.nvidia.com — NÃO reutilize chaves expostas)
# Depois abra um novo terminal e rode:  opencode
let
  pkgsUnstable = import inputs.nixpkgs-unstable {
    system = pkgs.stdenv.hostPlatform.system;
    config.allowUnfree = true;
  };

  # Servidor MCP de inteligência de código (codebase-memory-mcp). Indexa o
  # repositório num grafo e expõe ~14 ferramentas (busca estrutural, trace de
  # chamadas, arquitetura, impacto de diff…) que gastam MUITO menos tokens que
  # ler arquivo por arquivo. Vem do nixpkgs-unstable (0.8.1), binário estático.
  cbm = pkgsUnstable.codebase-memory-mcp;

  # 154 subagentes especializados da coleção VoltAgent (formato Claude Code, que
  # o opencode lê de ~/.config/opencode/agent). Adaptados na hora da build:
  #   • injeta `mode: subagent` (só são chamados por delegação, não poluem o
  #     seletor de agente principal);
  #   • remove a linha `model:` (os originais fixam modelos da Anthropic, ex.
  #     `sonnet`, que não existem aqui) → cada um herda o modelo padrão (GLM);
  #   • remove a linha `tools:` (no formato Claude é uma string separada por
  #     vírgulas, ex. `Read, Write, Edit`; o opencode espera um objeto e rejeita
  #     a string) → cada um herda o conjunto de ferramentas padrão.
  # Pinado por commit (fetchFromGitHub) para ser reprodutível sem tocar no
  # flake.lock. Atualizar = trocar rev + hash.
  subagentsSrc = pkgs.fetchFromGitHub {
    owner = "VoltAgent";
    repo = "awesome-claude-code-subagents";
    rev = "c193ad45419c13ceb49a43740186f680ad5ea264";
    hash = "sha256-qG9VLe6HdjcJ5EhHYByh5Vy+2mpd8i7K7fwdyHL8L8k=";
  };
  subagents = pkgs.runCommandLocal "opencode-subagents" { } ''
    mkdir -p "$out"
    find ${subagentsSrc}/categories -type f -name '*.md' ! -name 'README.md' | while read -r f; do
      awk '
        NR==1 && $0 ~ /^---[[:space:]]*$/ { print; print "mode: subagent"; infm=1; next }
        infm && $0 ~ /^(model|mode|tools):[[:space:]]/ { next }
        infm && $0 ~ /^---[[:space:]]*$/ { print; infm=0; next }
        { print }
      ' "$f" > "$out/$(basename "$f")"
    done
  '';
in
{
  home.packages = [ pkgsUnstable.opencode cbm ];

  # Subagentes (veja o let acima) instalados em ~/.config/opencode/agent.
  xdg.configFile."opencode/agent".source = subagents;

  # Config declarativa do opencode (sem segredos).
  xdg.configFile."opencode/opencode.json".text = builtins.toJSON {
    "$schema" = "https://opencode.ai/config.json";

    # Tema Catppuccin Mocha (embutido), alinhado ao resto do sistema
    # (waybar/kitty/walker/mako usam a mesma paleta).
    theme = "catppuccin";

    # Plugin de skills (Anthropic Agent Skills). Baixado do npm pelo próprio
    # opencode no primeiro start (cache em ~/.cache/opencode). Pinado na 0.7.0.
    # Obs.: o opencode já tem suporte NATIVO a skills; este plugin adiciona
    # extras (matching semântico, reinjeção de skills após compactação).
    plugin = [ "opencode-agent-skills@0.7.0" ];

    # Provedor customizado apontando para o endpoint gratuito da NVIDIA.
    provider.nvidia = {
      npm = "@ai-sdk/openai-compatible";
      name = "NVIDIA NIM (free)";
      options = {
        baseURL = "https://integrate.api.nvidia.com/v1";
        apiKey = "{env:NVIDIA_API_KEY}";
      };
      models = {
        "z-ai/glm-5.2".name = "GLM-5.2";
        # Qwen 3.5 (400B MoE, VLM) — visão + agentic.
        "qwen/qwen3.5-397b-a17b".name = "Qwen3.5 397B";
      };
    };

    # Modelo padrão ao abrir o opencode.
    model = "nvidia/z-ai/glm-5.2";

    # Servidores MCP (ferramentas externas expostas ao agente).
    mcp = {
      # Inteligência de código local (binário do let acima). Roda sob demanda
      # via stdio; indexe um projeto pedindo "index this repository".
      "codebase-memory" = {
        type = "local";
        command = [ "${cbm}/bin/codebase-memory-mcp" ];
        enabled = true;
      };
      # TypeUI (MCP remoto de design/UI) REMOVIDO: é um produto PAGO (Pro, ~US$30/
      # mês com trial de 7 dias) cujo endpoint hospedado exige login OAuth via
      # conta (servidor de auth Supabase). Sem token ele responde 401
      # "Missing Authorization header", quebrando toda mensagem no opencode.
      # Para reativar (após criar conta + iniciar o trial em typeui.sh):
      #   typeui = {
      #     type = "remote";
      #     url = "https://mcp.typeui.sh";
      #     enabled = true;
      #     headers.Authorization = "Bearer {env:TYPEUI_TOKEN}";
      #   };
      # exportando TYPEUI_TOKEN a partir de ~/.config/secrets/ (como a chave da
      # NVIDIA), OU deixando o opencode conduzir o fluxo OAuth no primeiro uso.
    };
  };
}
