# markitdown-mcp-server

[MarkItDown](https://github.com/microsoft/markitdown) (Microsoft) empacotado como
servidor MCP no hub `server.dasg.ltd`, seguindo a convenção de rotas por plataforma.

Converte PDF, Office (docx/xlsx/pptx), HTML, imagens, áudio e outros formatos em
Markdown limpo — útil como *tool* de ingestão para o Hermes/Claude, n8n e Antigravity.

## Arquitetura

O `markitdown-mcp` (Python, Microsoft) serve `/mcp` **fixo no root, sem base-path e
sem autenticação**. Como não patchamos código de terceiros, embutimos o **Caddy**
como reverse-proxy dentro do container:

```
cliente ─► Caddy :3000 ─► markitdown-mcp 127.0.0.1:3001
             │
             ├─ /health              → 200 (sem auth, p/ HEALTHCHECK)
             ├─ /markitdown/mcp      → strip → /mcp   (URL pública do hub; exige X-MCP-Key)
             └─ /mcp  /sse           → /mcp            (uso interno n8n; exige X-MCP-Key)
```

## Endpoints

- **Público:** `https://server.dasg.ltd/markitdown/mcp` (header `X-MCP-Key: <MARKITDOWN_KEY>`)
- **Interno (n8n, rede docker):** `http://markitdown:3000/mcp` (mesmo header)

## Segurança

O MarkItDown busca URLs e converte arquivos arbitrários — exposto sem proteção
seria vetor de SSRF/abuso. Por isso o Caddy **exige** o header `X-MCP-Key` igual à
env `MARKITDOWN_KEY` em todas as rotas MCP; `/health` fica aberto.

## Deploy

Push na `main` → GitHub Actions builda, envia ao GHCR e dispara o redeploy do
serviço `markitdown` (projeto `start`) no EasyPanel. A env `MARKITDOWN_KEY` é
definida no painel do serviço.
