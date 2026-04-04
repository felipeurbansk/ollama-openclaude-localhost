FROM ollama/ollama

ARG NODE_MAJOR=22

ENV DEBIAN_FRONTEND=noninteractive
ENV CLAUDE_CODE_USE_OPENAI=1
ENV OPENAI_BASE_URL=http://localhost:11434/v1
ENV OPENAI_API_KEY=fake-key
ENV OPENAI_MODEL=hhao/qwen2.5-coder-tools:14b

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    gnupg \
    libatomic1 \
  && curl -fsSL "https://deb.nodesource.com/setup_${NODE_MAJOR}.x" | bash - \
  && apt-get install -y --no-install-recommends nodejs \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

RUN npm i -g @gitlawb/openclaude
RUN npm i -g @nestjs/cli

WORKDIR /workspace

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 11434

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
