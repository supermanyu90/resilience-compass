# Resilience Compass web app — zero-dependency Node static server + model proxy.
# Build from the project root:  docker build -f deploy/Dockerfile -t resilience-compass-web:0.1 .
FROM node:20-alpine
WORKDIR /app
COPY demo_preview ./demo_preview
# Defaults target the in-cluster Ollama Service; override via the ConfigMap to use NVIDIA NIM.
ENV PORT=8422 \
    MODEL_BACKEND=ollama \
    OLLAMA_URL=http://ollama:11434
EXPOSE 8422
USER node
CMD ["node", "demo_preview/serve.js"]
