#!/bin/bash
# Sobe o markitdown-mcp (backend interno) e o Caddy (front público) juntos.
# Se qualquer um dos dois morrer, o container encerra e o EasyPanel reinicia.
set -euo pipefail

# Backend MCP: só localhost, sem auth (o Caddy é a fronteira de segurança).
markitdown-mcp --http --host 127.0.0.1 --port 3001 &

# Front: TLS/roteamento/auth por header.
caddy run --config /etc/caddy/Caddyfile --adapter caddyfile &

# Encerra assim que o primeiro processo sair (com o respectivo código).
wait -n
exit $?
