#!/usr/bin/env bash
# Extracts assets from all repos in config/repos.json
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG="$ROOT/config/repos.json"
OUTDIR="${1:-$ROOT/build}"
WORKDIR="$ROOT/.cache/repos"

mkdir -p "$OUTDIR" "$WORKDIR"

log()  { echo "[$(date +%H:%M:%S)] $*"; }
skip() { echo "  └─ SKIP: $*"; }

clone_shallow() {
  local repo="$1" dest="$2"
  if [ ! -d "$dest/.git" ]; then
    log "Cloning $repo → $dest"
    git clone --depth 1 --filter=tree:0 "https://github.com/$repo.git" "$dest" 2>/dev/null
  else
    log "Updating $repo"
    git -C "$dest" pull --depth 1 --ff-only 2>/dev/null || true
  fi
}

extract_assets() {
  local category="$1" id="$2" repo="$3" subdir="$4" formats="$5"

  local src="$WORKDIR/$category/$id/$subdir"
  local dst="$OUTDIR/$category/$id"

  if [ ! -d "$src" ]; then
    skip "Source not found: $src"
    return
  fi

  mkdir -p "$dst"

  # Build find pattern
  local patterns=()
  IFS=',' read -ra exts <<< "$formats"
  for ext in "${exts[@]}"; do
    patterns+=(-o -name "*.$ext")
  done
  unset IFS

  local count=0
  while IFS= read -r -d '' file; do
    local rel="${file#$src/}"
    local target="$dst/$rel"
    mkdir -p "$(dirname "$target")"
    cp "$file" "$target"
    ((count++)) || true
  done < <(find "$src" -type f \( "${patterns[@]:1}" \) -print0 2>/dev/null)

  log "  → $count assets extraídos para $category/$id"
}

# Read config and process each entry
for category in $(jq -r 'keys[]' "$CONFIG"); do
  log "═══ Categoria: $category ═══"

  for row in $(jq -c ".\"$category\"[]" "$CONFIG"); do
    id=$(echo "$row" | jq -r '.id')
    repo=$(echo "$row" | jq -r '.repo')
    subdir=$(echo "$row" | jq -r '.subdir')
    formats=$(echo "$row" | jq -r '.formats | join(",")')

    log "Processando $id ($repo)"

    # Clone/fetch repo
    repo_dir="$WORKDIR/$category/$id"
    clone_shallow "$repo" "$repo_dir"

    # Extract assets
    extract_assets "$category" "$id" "$repo" "$subdir" "$formats"
  done
done

# Show summary
echo ""
log "═══ RESUMO ═══"
total=$(find "$OUTDIR" -type f | wc -l)
echo "Total de assets extraídos: $total"
du -sh "$OUTDIR"
