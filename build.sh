#!/usr/bin/env bash

# Build script for the blog
# This script runs Emacs in batch mode to generate HTML from org files

set -euo pipefail

# Configuration
BLOG_TITLE="${BLOG_TITLE:-Noob Notes}"
BLOG_AUTHOR="${BLOG_AUTHOR:-bytenoob}"
BLOG_EMAIL="${BLOG_EMAIL:-noreply@example.com}"
INCREMENTAL_BUILD="${INCREMENTAL_BUILD:-false}"

# Source configuration if available
if [ -f ".blogrc" ]; then
  # shellcheck source=/dev/null
  source .blogrc
fi

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}Building blog...${NC}"

# Show incremental build option if not enabled
if [ "$INCREMENTAL_BUILD" != "true" ]; then
  echo -e "${YELLOW}Tip:${NC} Use INCREMENTAL_BUILD=true $0 to skip unchanged files"
fi

# Get version numbers for cache busting based on file modification time
CSS_VERSION=$(stat -c %Y static/css/blog.css 2> /dev/null || stat -f %m static/css/blog.css 2> /dev/null || echo "1")
JS_VERSION=$(stat -c %Y static/js/blog.js 2> /dev/null || stat -f %m static/js/blog.js 2> /dev/null || echo "1")

# Export for use in Emacs
export CSS_VERSION
export JS_VERSION

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Run Emacs in batch mode to publish the blog
if emacs --batch \
  --load "$SCRIPT_DIR/build.el" \
  --funcall blog/publish-all; then
  echo -e "${GREEN}Build complete!${NC} HTML files generated in public/"

  # Generate sitemap
  if [ -x "./generate-sitemap.sh" ]; then
    ./generate-sitemap.sh
  fi

  # Show build statistics
  if [ -d "public" ]; then
    POST_COUNT=$(find public -name "*.html" -not -name "index.html" -not -name "index-cn.html" | wc -l)
    TOTAL_SIZE=$(du -sh public | cut -f1)
    echo -e "${GREEN}Generated:${NC} $POST_COUNT posts"
    echo -e "${GREEN}Total size:${NC} $TOTAL_SIZE"
    
    if [ "$INCREMENTAL_BUILD" = "true" ]; then
      echo -e "${GREEN}Mode:${NC} Incremental build"
    fi
  fi
else
  echo -e "${YELLOW}Build completed with warnings${NC}"
fi
