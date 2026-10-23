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

# Get version numbers for cache busting based on file modification time
CSS_VERSION=$(stat -c %Y static/css/blog.css 2> /dev/null || stat -f %m static/css/blog.css 2> /dev/null || echo "1")
JS_VERSION=$(stat -c %Y static/js/blog.js 2> /dev/null || stat -f %m static/js/blog.js 2> /dev/null || echo "1")

# Export for use in Emacs
export CSS_VERSION
export JS_VERSION

# Run Emacs in batch mode to publish the blog
# Full builds start from a clean slate so deleted or re-drafted posts don't
# linger in public/ (incremental builds keep existing output)
if [ "$INCREMENTAL_BUILD" != "true" ] && [ -d public ]; then
  rm -f public/*.html public/sitemap.xml
fi

if ! emacs --batch \
  --load "$SCRIPT_DIR/build.el" \
  --funcall blog/publish-all; then
  echo -e "${YELLOW}Error:${NC} build failed."
  exit 1
fi

# robots.txt must live at the site root, not under static/
cp static/robots.txt public/robots.txt

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
