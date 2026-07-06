# syntax=docker/dockerfile:1
# MarkItDown MCP (Microsoft, Python) exposto no hub server.dasg.ltd/markitdown/mcp.
# Como o markitdown-mcp serve /mcp fixo no root, sem base-path e sem auth,
# embutimos o Caddy como reverse-proxy: strip do prefixo /markitdown + camada
# de header key (X-MCP-Key). O n8n interno usa /mcp direto na porta 3000.

FROM python:3.12-slim

# Binário estático do Caddy (Go) direto da imagem oficial.
COPY --from=caddy:2 /usr/bin/caddy /usr/bin/caddy

# markitdown-mcp + conversores. bash para o entrypoint (wait -n).
RUN apt-get update \
    && apt-get install -y --no-install-recommends bash \
    && rm -rf /var/lib/apt/lists/* \
    && pip install --no-cache-dir markitdown-mcp

COPY Caddyfile /etc/caddy/Caddyfile
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Definida no EasyPanel; sem ela o Caddy nega toda requisição MCP.
ENV MARKITDOWN_KEY=""
EXPOSE 3000

# Healthcheck contra a rota /health (respondida pelo Caddy, sem auth).
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD python -c "import urllib.request,sys; sys.exit(0 if urllib.request.urlopen('http://127.0.0.1:3000/health',timeout=3).status==200 else 1)" || exit 1

ENTRYPOINT ["/entrypoint.sh"]
