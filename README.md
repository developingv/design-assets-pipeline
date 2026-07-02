# Design Asset Library Pipeline

Pipeline automatizada que extrai assets de repositórios open-source e publica no Cloudflare R2 para consumo por agentes de IA.

## Arquitetura

```
GitHub Action (semanal)
    │
    ├─ scripts/extract.sh
    │   Clona shallow (--depth 1 --filter=tree:0)
    │   Extrai só os assets (SVG, PNG, TSX)
    │
    ├─ scripts/generate-manifest.sh
    │   Escaneia build/ e gera manifest.json
    │   + tags-index.json para busca
    │
    └─ scripts/upload.sh
        Sobe para Cloudflare R2 via S3 API
        Cache: 1 ano (assets) / 15min (manifest)
```

## Deploy

### 1. Bucket R2

Crie um bucket no [Cloudflare R2](https://dash.cloudflare.com/?to=/:account/r2).

### 2. Secrets no GitHub

| Secret | Valor |
|---|---|
| `R2_ENDPOINT` | `https://<id>.r2.cloudflarestorage.com` |
| `R2_BUCKET` | Nome do bucket |
| `R2_ACCESS_KEY_ID` | Access Key ID (R2 → Tokens de API) |
| `R2_SECRET_ACCESS_KEY` | Secret Key |
| `R2_PUBLIC_URL` | `https://assets.seu-dominio.com` (ou `https://pub-<hash>.r2.dev`) |

### 3. Ativar

Após configurar os secrets, faça um push pro repositório. O workflow roda automaticamente toda segunda ou manualmente via **Actions → Sync Asset Library → Run workflow**.

## Consumo pelo Agente

```python
import httpx, json

BASE = "https://assets.seu-dominio.com"

# 1. Pega o índice
manifest = httpx.get(f"{BASE}/manifest.json").json()

# 2. Busca por tag
tags = httpx.get(f"{BASE}/tags-index.json").json()
packs_3d = tags.get("3d", [])  # → ["icons.3dicons"]

# 3. Baixa assets específicos
icon_url = f"{BASE}/icons/lucide/star.svg"
svg = httpx.get(icon_url).text
```

## Adicionar novo repo

Edite `config/repos.json`:

```json
{
  "icons": [
    {
      "id": "meu-pack",
      "repo": "user/repo",
      "subdir": "caminho/dos/assets",
      "formats": ["svg"],
      "tags": ["novo", "estilo"],
      "license": "MIT"
    }
  ]
}
```

Próximo sync automaticamente inclui os novos assets.
