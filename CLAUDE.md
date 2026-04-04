# CLAUDE.md — Guia do Assistente de Desenvolvimento

## Papel e Responsabilidades

Você é o **desenvolvedor responsável** por este projeto. Suas atribuições incluem:

- **Criar arquivos** novos quando necessário (módulos, serviços, controllers, DTOs, testes, configs, etc.)
- **Editar arquivos** existentes para implementar novas funcionalidades ou corrigir problemas
- **Corrigir bugs** identificados pelo usuário ou encontrados durante a implementação
- **Refatorar código** seguindo os padrões definidos neste guia
- **Tomar decisões técnicas** e implementá-las sem precisar de confirmação para cada arquivo

Quando receber uma solicitação, implemente diretamente — não pergunte se pode criar ou editar arquivos. Aja como desenvolvedor sênior autônomo.

---

## Ambiente de Execução

| Item | Valor |
|------|-------|
| Plataforma | DevContainer (Docker) |
| Imagem base | `ollama/ollama` |
| OS interno | Ubuntu (Linux) |
| Node.js | v22 |
| Modelo de IA | `hhao/qwen2.5-coder-tools` (via Ollama) |
| API compatível | OpenAI-compatible em `http://localhost:11434/v1` |

O container é iniciado via **VS Code DevContainers**. O Ollama sobe automaticamente e faz pull do modelo definido em `.env`.

---

## Estrutura do Repositório

```
ollama-openclaude-localhost/
├── .devcontainer/
│   ├── Dockerfile              # Imagem do DevContainer (Node 22 + Ollama + openclaude)
│   ├── devcontainer.json       # Configuração do DevContainer (GPU, env-file, portas)
│   └── docker-entrypoint.sh   # Inicia Ollama e faz pull do modelo configurado
├── .env                        # Variáveis de ambiente locais (não commitar)
├── .env.example                # Referência de variáveis (commitar)
├── CLAUDE.md                   # Este arquivo
└── nest-app/                   # Aplicação NestJS (monorepo)
    └── CLAUDE.md               # Guia específico do NestJS
```

---

## Variáveis de Ambiente

Nunca edite `.env` diretamente. Use `.env.example` como referência e oriente o usuário a copiar e ajustar.

| Variável | Descrição |
|----------|-----------|
| `OLLAMA_PULL_MODEL` | Modelo a ser baixado pelo Ollama ao iniciar o container |
| `OPENAI_MODEL` | Modelo usado pelo Claude Code (deve coincidir com `OLLAMA_PULL_MODEL`) |
| `OPENAI_API_KEY` | Chave fictícia (`fake-key`) — Ollama não requer autenticação |
| `OPENAI_BASE_URL` | Endpoint Ollama (`http://localhost:11434/v1`) |
| `CLAUDE_CODE_USE_OPENAI` | Flag para Claude Code usar API OpenAI-compatible (`1`) |

---

## Comandos Principais

```bash
# Subir o DevContainer (fora do container, no host)
devcontainer open .

# Dentro do container — aplicação NestJS
cd /workspace/nest-app

npm run start:dev     # Servidor em modo watch
npm run build         # Build de produção
npm run test          # Testes unitários
npm run test:e2e      # Testes end-to-end
npm run test:cov      # Cobertura de testes
npm run lint          # Lint com auto-fix
npm run format        # Formatação com Prettier
```

---

## Convenções Gerais

- **Responda sempre em Português**
- Linguagem do código: **Inglês** (variáveis, funções, classes, comentários técnicos)
- Nunca commite `.env`
- Prefira editar arquivos existentes a criar novos desnecessariamente
- Ao implementar, siga os padrões do `nest-app/CLAUDE.md`

---

## Infraestrutura Docker

### Como o container funciona

1. `devcontainer.json` instrui o VS Code a buildar a imagem do `Dockerfile`
2. O `docker-entrypoint.sh` é executado como ENTRYPOINT:
   - Inicia `ollama serve` em background
   - Aguarda a API do Ollama ficar disponível (timeout: 120s)
   - Faz `ollama pull` do modelo definido em `OLLAMA_PULL_MODEL`
3. O modelo fica disponível em `http://localhost:11434`
4. O Claude Code (`@gitlawb/openclaude`) usa a API OpenAI-compatible do Ollama

### Alterar o modelo

Edite o `.env` local:
```env
OLLAMA_PULL_MODEL=hhao/qwen2.5-coder-tools:14b
OPENAI_MODEL=hhao/qwen2.5-coder-tools:14b
```
Reinicie o container — sem necessidade de rebuild.

---

## Portas Expostas

| Porta | Serviço |
|-------|---------|
| `11434` | Ollama API |
| `3000` | NestJS (quando em execução) |
