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
in
{
  home.packages = [ pkgsUnstable.opencode ];

  # Config declarativa do opencode (sem segredos).
  xdg.configFile."opencode/opencode.json".text = builtins.toJSON {
    "$schema" = "https://opencode.ai/config.json";

    # Tema Catppuccin Mocha (embutido), alinhado ao resto do sistema
    # (waybar/kitty/walker/mako usam a mesma paleta).
    theme = "catppuccin";

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
  };
}
