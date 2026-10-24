#!/usr/bin/env bash

# Build script for the blog
# This script runs Emacs in batch mode to generate HTML from org files

set -euo pipefail

# Run from the repository root so relative paths work from any directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Configuration (environment > .blogrc > defaults)
# shellcheck source=config.sh
source ./config.sh

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}Building blog...${NC}"

# Show incremental build option if not enabled
if [ "$INCREMENTAL_BUILD" != "true" ]; then
  echo -e "${YELLOW}Tip:${NC} Use INCREMENTAL_BUILD=true $0 to skip unchanged files"
fi

# Emacs is required to publish Org files.
if ! command -v emacs > /dev/null 2>&1; then
  echo -e "${YELLOW}Error:${NC} emacs is required but was not found in PATH."
  exit 1
fi

# Cache-busting versions from file contents, so URLs change only when the
# file does (mtimes differ on every CI checkout)
file_version() {
  { sha256sum "$1" 2> /dev/null || shasum -a 256 "$1"; } | cut -c1-10
}
CSS_VERSION=$(file_version static/css/blog.css)
JS_VERSION=$(file_version static/js/blog.js)

# Export for use in Emacs
export CSS_VERSION
export JS_VERSION

# Incremental builds only re-export posts whose own Org file changed, so any
# change to shared inputs (templates, config, assets) forces a full build
INPUTS_STAMP=public/.build-inputs
inputs_hash=$({
  cat build.el config.sh static/css/blog.css static/js/blog.js
  [ -f .blogrc ] && cat .blogrc
  env | grep -E '^(BLOG_|GITHUB_USERNAME=)' | sort
} | { sha256sum 2> /dev/null || shasum -a 256; } | cut -c1-16)
if [ "$INCREMENTAL_BUILD" = "true" ] && [ "$(cat "$INPUTS_STAMP" 2> /dev/null)" != "$inputs_hash" ]; then
  echo -e "${YELLOW}Shared build inputs changed:${NC} doing a full build"
  INCREMENTAL_BUILD=false
  export INCREMENTAL_BUILD
fi

# Full builds start from an empty public/ so removed posts and assets don't
# linger (incremental builds keep existing output and prune it below)
if [ "$INCREMENTAL_BUILD" != "true" ]; then
  rm -rf public
fi

if ! emacs --batch \
  --load "$SCRIPT_DIR/build.el" \
  --funcall blog/publish-all; then
  echo -e "${YELLOW}Error:${NC} build failed."
  exit 1
fi

# Remove pages whose Org source was deleted or turned back into a draft
shopt -s nullglob
for html in public/*.html; do
  org="posts/$(basename "$html" .html).org"
  if [ ! -f "$org" ] || is_draft "$org"; then
    echo "Removing stale page: $html"
    rm -f "$html"
  fi
done
shopt -u nullglob

# robots.txt must live at the site root, pointing at this site's sitemap
sed "s#^Sitemap:.*#Sitemap: $BLOG_URL/sitemap.xml#" static/robots.txt > public/robots.txt
echo "$inputs_hash" > "$INPUTS_STAMP"

echo -e "${GREEN}Build complete!${NC} HTML files generated in public/"

# Generate sitemap
if [ -x "./generate-sitemap.sh" ]; then
  ./generate-sitemap.sh
fi

# Show build statistics
if [ -d "public" ]; then
  POST_COUNT=$(find public -maxdepth 1 -name "[0-9][0-9][0-9][0-9]-*.html" -not -name "*-cn.html" | wc -l)
  TOTAL_SIZE=$(du -sh public | cut -f1)
  echo -e "${GREEN}Generated:${NC} $POST_COUNT posts"
  echo -e "${GREEN}Total size:${NC} $TOTAL_SIZE"

  if [ "$INCREMENTAL_BUILD" = "true" ]; then
    echo -e "${GREEN}Mode:${NC} Incremental build"
  fi
fi
