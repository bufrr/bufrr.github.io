#!/usr/bin/env bash

# Generate sitemap.xml for the blog

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# shellcheck source=config.sh
source ./config.sh

OUTPUT_FILE="public/sitemap.xml"
TODAY=$(date -u +%Y-%m-%d)

if [ ! -d public ]; then
  echo "public/ not found; run ./build.sh first" >&2
  exit 1
fi

# First YYYY-MM-DD date in an Org keyword, bare or as a timestamp
# (<2024-06-16 Sun> or [2024-06-16 Sun])
org_keyword_date() {
  grep -m1 -oiE "^#\+$1:[[:space:]]*[<[]?[0-9]{4}-[0-9]{2}-[0-9]{2}" "$2" | grep -oE '[0-9-]{10}$' || true
}

# Last-modified date for a page: #+LASTMOD, then #+DATE of its Org source,
# then the last commit touching it, then today.
page_lastmod() {
  local org="posts/${1%.html}.org" value=""
  if [ -f "$org" ]; then
    value=$(org_keyword_date LASTMOD "$org")
    if [ -z "$value" ]; then
      value=$(org_keyword_date DATE "$org")
    fi
    if [ -z "$value" ]; then
      value=$(git log -1 --format=%cs -- "$org" 2> /dev/null || true)
    fi
  fi
  echo "${value:-$TODAY}"
}

# Percent-encode spaces and escape XML special characters in a URL
xml_url() {
  printf '%s\n' "$1" | sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g' -e 's/ /%20/g'
}

url_entry() {
  cat << EOF
  <url>
    <loc>$1</loc>
    <lastmod>$2</lastmod>
    <changefreq>$3</changefreq>
    <priority>$4</priority>
  </url>
EOF
}

newest="0000-00-00"
entries=""
shopt -s nullglob
for file in public/*.html; do
  name=$(basename "$file")
  case "$name" in
    404.html | index.html) continue ;;
    index-cn.html) priority="0.9" changefreq="daily" ;;
    about.html) priority="0.8" changefreq="monthly" ;;
    *) priority="0.6" changefreq="weekly" ;;
  esac

  lastmod=$(page_lastmod "$name")
  if [[ "$lastmod" > "$newest" ]]; then
    newest="$lastmod"
  fi
  entries+=$(url_entry "$(xml_url "$BLOG_URL/$name")" "$lastmod" "$changefreq" "$priority")$'\n'
done

if [ "$newest" = "0000-00-00" ]; then
  newest="$TODAY"
fi

{
  echo '<?xml version="1.0" encoding="UTF-8"?>'
  echo '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">'
  url_entry "$(xml_url "$BLOG_URL/")" "$newest" "daily" "1.0"
  printf '%s' "$entries"
  echo '</urlset>'
} > "$OUTPUT_FILE"

echo "Sitemap generated at $OUTPUT_FILE"
