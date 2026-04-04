#!/bin/sh
set -e
readonly defaultModel="qwen2.5-coder:7b"
readonly model="${OLLAMA_PULL_MODEL:-$defaultModel}"
ollama serve &
ollamaPid=$!
seconds=0
until curl -sf "http://127.0.0.1:11434/api/tags" >/dev/null 2>&1; do
  seconds=$((seconds + 1))
  if [ "$seconds" -gt 120 ]; then
    echo "docker-entrypoint: timeout waiting for Ollama API"
    exit 1
  fi
  sleep 1
done
if ! ollama list 2>/dev/null | grep -qF "$model"; then
  echo "docker-entrypoint: pulling model $model"
  ollama pull "$model"
else
  echo "docker-entrypoint: model $model already present"
fi
wait "$ollamaPid"
