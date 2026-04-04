# Meu Projeto

## Ambiente
- Rodando em **DevContainer** com Docker
- Modelo: `qwen2.5-coder` (via LiteLLM / Ollama / OpenRouter — especifique o seu)
- OS interno: Linux (Ubuntu)

## Estrutura
- `.devcontainer/` — configuração do container de desenvolvimento
- `Dockerfile` — imagem do projeto
- `.env` — variáveis de ambiente (nunca commitar)

## Comandos principais
- Subir container: `docker compose up`
- Entrar no container: `devcontainer open`
- Build: `<seu comando aqui>`
- Testes: `<seu comando aqui>`

## Convenções
- Linguagem de resposta: **Português**
- Não alterar `.env` diretamente, usar `.env.example` como referência
- Sempre verificar se o container está rodando antes de executar comandos

## IMPORTANTE
- Este projeto usa o modelo `qwen2.5-coder`, não o Claude padrão
- Responda sempre em português
- Não tente usar ferramentas externas ou skills não disponíveis neste ambiente
- Seja direto e conciso
- Prefira exemplos práticos a explicações longas