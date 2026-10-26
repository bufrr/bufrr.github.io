#!/usr/bin/env bash

# Render a 1200x630 share card per published post into public/og/<post>.png
# from templates/og-card.html, using headless Chrome. Runs before the HTML
# export so build.el can point each post's og:image at its card. Without
# Chrome it does nothing and posts fall back to static/og-default.png.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# shellcheck source=config.sh
source ./config.sh

TEMPLATE=templates/og-card.html
OUT_DIR=public/og

CHROME=""
for candidate in google-chrome google-chrome-stable chromium chromium-browser; do
  if command -v "$candidate" > /dev/null 2>&1; then
    CHROME="$candidate"
    break
  fi
done
if [ -z "$CHROME" ]; then
  echo "Share cards: Chrome not found, posts will use static/og-default.png"
  if [ "${CI:-}" = "true" ]; then
    echo "::warning::Chrome not found; per-post share cards were not generated"
  fi
  exit 0
fi

# The sandbox needs user namespaces, which CI runners may restrict; the input
# is our own local template, so running without it there is acceptable.
chrome_flags=(--headless=new --disable-gpu --hide-scrollbars --allow-file-access-from-files
  '--window-size=1200,630' --virtual-time-budget=3000)
if [ "${CI:-}" = "true" ]; then
  chrome_flags+=(--no-sandbox)
fi

html_escape() {
  printf '%s' "$1" | sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g' -e 's/"/\&quot;/g'
}

# Escape a value for use as a sed replacement (with | as the delimiter)
sed_value() {
  printf '%s' "$1" | sed -e 's/[\\&|]/\\&/g'
}

pretty_date() {
  LC_ALL=C date -d "$1" '+%b %-d, %Y' 2> /dev/null ||
    LC_ALL=C date -j -f '%Y-%m-%d' "$1" '+%b %e, %Y' 2> /dev/null || echo "$1"
}

mkdir -p "$OUT_DIR"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

host="${BLOG_URL#*://}"
rendered=0
skipped=0
shopt -s nullglob
for org in posts/[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]-*.org; do
  is_draft "$org" && continue
  name=$(basename "$org" .org)
  png="$OUT_DIR/$name.png"

  # Unchanged cards are kept on incremental builds
  if [ -f "$png" ] && [ "$png" -nt "$org" ] && [ "$png" -nt "$TEMPLATE" ]; then
    skipped=$((skipped + 1))
    continue
  fi

  title=$(grep -m1 -iE '^#\+TITLE:' "$org" | sed -E 's/^#\+[Tt][Ii][Tt][Ll][Ee]:[[:space:]]*//; s/[[:space:]]+$//')
  # Shrink long titles so they stay within three lines (CJK counts double)
  ascii_only=${title//[^[:ascii:]]/}
  length=$((${#title} * 2 - ${#ascii_only}))
  if [ "$length" -le 30 ]; then
    size=84
  elif [ "$length" -le 55 ]; then
    size=68
  else
    size=56
  fi

  sed -e "s|{{ROOT}}|$(sed_value "$SCRIPT_DIR")|g" \
    -e "s|{{TITLE}}|$(sed_value "$(html_escape "$title")")|g" \
    -e "s|{{DATE}}|$(sed_value "$(pretty_date "${name:0:10}")")|g" \
    -e "s|{{SITE}}|$(sed_value "$(html_escape "$BLOG_TITLE")")|g" \
    -e "s|{{HOST}}|$(sed_value "$(html_escape "$host")")|g" \
    -e "s|{{TITLE_SIZE}}|$size|g" \
    "$TEMPLATE" > "$work/$name.html"

  "$CHROME" "${chrome_flags[@]}" --user-data-dir="$work/profile" \
    --screenshot="$work/$name.png" "file://$work/$name.html" > /dev/null 2>&1
  if command -v pngquant > /dev/null 2>&1; then
    pngquant --quality=80-95 --strip --force --output "$png" "$work/$name.png"
  else
    cp "$work/$name.png" "$png"
  fi
  rendered=$((rendered + 1))
done

echo "Share cards: $rendered rendered, $skipped unchanged"
