#!/usr/bin/env bash
# Uploads build/ to Cloudflare R2 via awscli (S3-compatible)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD="$ROOT/build"

# ── Config via env vars ──
: "${R2_ENDPOINT:?Requer R2_ENDPOINT (ex: https://abc123.r2.cloudflarestorage.com)}"
: "${R2_BUCKET:?Requer R2_BUCKET}"
: "${R2_ACCESS_KEY:?Requer R2_ACCESS_KEY_ID}"
: "${R2_SECRET_KEY:?Requer R2_SECRET_ACCESS_KEY}"
: "${R2_PUBLIC_URL:=https://assets.seu-dominio.com}"
R2_REGION="${R2_REGION:-auto}"

log() { echo "[$(date +%H:%M:%S)] $*"; }

# Configure AWS CLI for R2
export AWS_ACCESS_KEY_ID="$R2_ACCESS_KEY"
export AWS_SECRET_ACCESS_KEY="$R2_SECRET_KEY"
export AWS_DEFAULT_REGION="$R2_REGION"

log "Iniciando upload para R2 bucket: $R2_BUCKET"

# Set CORS policy for browser access
CORS_POLICY='{
  "CORSRules": [
    {
      "AllowedOrigins": ["*"],
      "AllowedMethods": ["GET", "HEAD"],
      "AllowedHeaders": ["*"],
      "ExposeHeaders": ["Content-Type", "Content-Length"],
      "MaxAgeSeconds": 3600
    }
  ]
}
'
echo "$CORS_POLICY" | aws s3api put-bucket-cors \
  --endpoint-url "$R2_ENDPOINT" \
  --bucket "$R2_BUCKET" \
  --cors-configuration file:///dev/stdin \
  2>/dev/null || log "CORS já configurado ou bucket não existe — criando bucket..."

# Create bucket if needed (R2 auto-creates)
aws s3 mb "s3://$R2_BUCKET" \
  --endpoint-url "$R2_ENDPOINT" \
  2>/dev/null || true

# Sync build/ → R2
# --delete removes files no longer present locally
# --no-guess-mime-type uses proper MIME based on extension
# --cache-control sets CDN cache duration
log "Syncando assets..."

aws s3 sync "$BUILD" "s3://$R2_BUCKET" \
  --endpoint-url "$R2_ENDPOINT" \
  --delete \
  --no-progress \
  --exclude ".git/*" \
  --include "*" \
  --cache-control "public, max-age=31536000, immutable" \
  --content-type "image/svg+xml" --exclude "*" --include "*.svg" \
  --

# Re-run sync without the content-type override for all files
aws s3 sync "$BUILD" "s3://$R2_BUCKET" \
  --endpoint-url "$R2_ENDPOINT" \
  --delete \
  --no-progress \
  --exclude ".git/*" \
  --include "*" \
  --cache-control "public, max-age=31536000, immutable"

# Set manifest.json to short cache (agents need fresh data)
aws s3 cp "$BUILD/manifest.json" "s3://$R2_BUCKET/manifest.json" \
  --endpoint-url "$R2_ENDPOINT" \
  --cache-control "public, max-age=900" \
  --content-type "application/json"

aws s3 cp "$BUILD/tags-index.json" "s3://$R2_BUCKET/tags-index.json" \
  --endpoint-url "$R2_ENDPOINT" \
  --cache-control "public, max-age=900" \
  --content-type "application/json"

# Public URL
echo ""
log "══════════════════════════════════════════"
log "Upload concluído!"
log "URL pública base: $R2_PUBLIC_URL"
log "Manifest:        $R2_PUBLIC_URL/manifest.json"
log "Tags Index:      $R2_PUBLIC_URL/tags-index.json"
log "══════════════════════════════════════════"
