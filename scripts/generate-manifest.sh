#!/usr/bin/env bash
# Scans build/ and generates manifest.json + tags index
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD="$ROOT/build"
CONFIG="$ROOT/config/repos.json"

cd "$BUILD"

# Build per-file manifest
manifest=$(jq -n '{}')

for category in */; do
  category="${category%/}"
  cat_array=$(jq -n '[]')

  for pack in "$category"/*/; do
    [ -d "$pack" ] || continue
    pack_id=$(basename "$pack")

    # Count files by format
    formats=$(jq -n '{}')
    while IFS= read -r -d '' f; do
      ext="${f##*.}"
      count=$(echo "$formats" | jq ".\"$ext\" // 0")
      formats=$(echo "$formats" | jq ".\"$ext\" = $((count + 1))")
    done < <(find "$pack" -type f -not -path '*/node_modules/*' -print0 2>/dev/null)

    total=$(echo "$formats" | jq '[.[]] | add // 0')

    # Get metadata from config
    config_data=$(jq --arg cat "$category" --arg id "$pack_id" '
      .[$cat][] | select(.id == $id)
    ' "$CONFIG" 2>/dev/null || echo "null")

    entry=$(jq -n \
      --arg id "$pack_id" \
      --argjson total "$total" \
      --argjson formats "$formats" \
      --argjson config "$config_data" \
      '{
        id: $id,
        count: $total,
        formats: $formats,
        base_url: ("https://assets.seu-dominio.com/" + $id + "/"),
        license: ($config.license // "unknown"),
        tags: ($config.tags // [])
      }'
    )
    cat_array=$(echo "$cat_array" | jq ". + [$entry]")
  done

  manifest=$(echo "$manifest" | jq --arg cat "$category" --argjson arr "$cat_array" '.[$cat] = $arr')
done

# Write manifest
echo "$manifest" | jq '.' > "$BUILD/manifest.json"
echo "$manifest" > "$ROOT/manifest.json"

# Generate flat tag index
tag_index=$(echo "$manifest" | jq '
  [paths(scalars) as $path |
    select($path[-1] == "tags") |
    {key: $path[:-1] | join("."), value: .[$path[]]}]
  | map(select(.value | type == "array"))
  | reduce .[] as $item ({};
    $item.value[] as $tag |
    .[$tag] += [$item.key]
  )
')
echo "$tag_index" | jq '.' > "$BUILD/tags-index.json"
echo "$tag_index" | jq '.' > "$ROOT/tags-index.json"

echo "manifest.json gerado com $(echo "$manifest" | jq '[..|objects|.id] | unique | length') packs"
echo "tags-index.json gerado com $(echo "$tag_index" | jq 'keys | length') tags"
