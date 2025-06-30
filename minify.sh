#!/usr/bin/env bash

# Minify CSS and JS files for production

set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}Minifying assets...${NC}"

# Use local node_modules if available, otherwise global
if [ -f "package.json" ] && [ -d "node_modules" ]; then
  echo -e "${YELLOW}Using local node_modules...${NC}"
  TERSER="npx terser"
  POSTCSS="npx postcss"
else
  # Check for required tools
  if ! command -v terser &> /dev/null; then
    echo -e "${YELLOW}terser not found. Run: npm install${NC}"
    exit 1
  fi
  if ! command -v postcss &> /dev/null; then
    echo -e "${YELLOW}postcss not found. Run: npm install${NC}"
    exit 1
  fi
  TERSER="terser"
  POSTCSS="postcss"
fi

# Minify CSS
if [ -f "public/static/css/blog.css" ]; then
  SIZE_BEFORE=$(stat -c%s "public/static/css/blog.css" 2> /dev/null || stat -f%z "public/static/css/blog.css")
  $POSTCSS public/static/css/blog.css -o public/static/css/blog.min.css --use cssnano --no-map
  mv public/static/css/blog.min.css public/static/css/blog.css
  SIZE_AFTER=$(stat -c%s "public/static/css/blog.css" 2> /dev/null || stat -f%z "public/static/css/blog.css")
  SAVED=$((SIZE_BEFORE - SIZE_AFTER))
  if [ "$SIZE_BEFORE" -gt 0 ]; then
    PERCENT=$((SAVED * 100 / SIZE_BEFORE))
    echo -e "${GREEN}CSS minified:${NC} $SIZE_BEFORE → $SIZE_AFTER bytes (saved ${PERCENT}%)"
  fi
fi

# Minify JavaScript
if [ -f "public/static/js/blog.js" ]; then
  SIZE_BEFORE=$(stat -c%s "public/static/js/blog.js" 2> /dev/null || stat -f%z "public/static/js/blog.js")
  $TERSER public/static/js/blog.js -o public/static/js/blog.min.js -c -m
  mv public/static/js/blog.min.js public/static/js/blog.js
  SIZE_AFTER=$(stat -c%s "public/static/js/blog.js" 2> /dev/null || stat -f%z "public/static/js/blog.js")
  SAVED=$((SIZE_BEFORE - SIZE_AFTER))
  if [ "$SIZE_BEFORE" -gt 0 ]; then
    PERCENT=$((SAVED * 100 / SIZE_BEFORE))
    echo -e "${GREEN}JavaScript minified:${NC} $SIZE_BEFORE → $SIZE_AFTER bytes (saved ${PERCENT}%)"
  fi
fi

echo -e "${GREEN}Minification complete!${NC}"
