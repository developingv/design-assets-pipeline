# Design Asset Library Pipeline

Pipeline automatizada que extrai assets de repositórios open-source e publica via **jsDelivr CDN** para consumo por agentes de IA.

## Arquitetura

```
GitHub Action (semanal)
    │
    ├─ scripts/extract.sh
    │   Clona shallow (--depth 1 --filter=tree:0)
    │   Extrai só os assets (SVG, PNG, TSX, etc)
    │
    ├─ scripts/generate-manifest.sh
    │   Escaneia build/ e gera manifest.json
    │   + tags-index.json para busca por tag
    │
    └─ scripts/deploy.sh
        Cria/atualiza branch 'assets' com os arquivos
        Servido via jsDelivr CDN (cache global)
```

**Custo: ZERO.** Sem Cloudflare, sem R2, sem cartão de crédito.

## URLs do CDN

| Recurso | URL |
|---|---|
| Base | `https://cdn.jsdelivr.net/gh/developingv/design-assets-pipeline@assets/` |
| Manifest | `https://cdn.jsdelivr.net/gh/developingv/design-assets-pipeline@assets/manifest.json` |
| Tags Index | `https://cdn.jsdelivr.net/gh/developingv/design-assets-pipeline@assets/tags-index.json` |
| Ícone específico | `https://cdn.jsdelivr.net/gh/developingv/design-assets-pipeline@assets/icons/lucide/star.svg` |

## Consumo pelo Agente

```python
import httpx

BASE = "https://cdn.jsdelivr.net/gh/developingv/design-assets-pipeline@assets"

# 1. Descobrir todos os packs
manifest = httpx.get(f"{BASE}/manifest.json").json()

# 2. Buscar por tag
tags = httpx.get(f"{BASE}/tags-index.json").json()
packs_3d = tags.get("3d", [])  # → ["icons.3dicons"]

# 3. Baixar asset específico
svg = httpx.get(f"{BASE}/icons/lucide/star.svg").text
```

## Adicionar novo repo

Edite `config/repos.json` seguindo o schema dos entries existentes.
