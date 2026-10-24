#!/usr/bin/env bash

# Validate the built site in public/: post metadata, one page per published
# post, and every internal link (href/src, including #fragments).
# Run after ./build.sh (and ./minify.sh). Used by CI and the publish workflow.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# shellcheck source=config.sh
source ./config.sh

errors=0
fail() {
  echo "❌ $*"
  errors=$((errors + 1))
}

if [ ! -f public/index.html ]; then
  echo "❌ public/index.html not found; run ./build.sh first"
  exit 1
fi

echo "📋 Checking post metadata and published pages..."
for org in posts/*.org; do
  name=$(basename "$org" .org)
  case "$name" in
    index | index-cn | about | 404) ;;
    *)
      for key in TITLE AUTHOR DATE; do
        grep -qE "^#\+$key:[[:space:]]*[^[:space:]]" "$org" || fail "Missing $key in $org"
      done
      ;;
  esac
  if ! is_draft "$org" && [ ! -f "public/$name.html" ]; then
    fail "Expected public/$name.html for $org"
  fi
done

echo "🔗 Checking internal links..."
python3 -I - public << 'EOF' || errors=$((errors + 1))
import html.parser, os, posixpath, sys, urllib.parse

root = sys.argv[1]

class Page(html.parser.HTMLParser):
    def __init__(self):
        super().__init__()
        self.ids, self.links = set(), []

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        for key in ("id", "name"):
            if attrs.get(key):
                self.ids.add(attrs[key])
        for key in ("href", "src"):
            if attrs.get(key):
                self.links.append((tag, attrs[key]))

pages = {}
for dirpath, _, files in os.walk(root):
    for f in files:
        if f.endswith(".html"):
            path = os.path.join(dirpath, f)
            page = Page()
            page.feed(open(path, encoding="utf-8").read())
            pages["/" + os.path.relpath(path, root)] = page

def resolve(base, link):
    """Site-absolute path for an internal link, or None for external ones."""
    parts = urllib.parse.urlsplit(link)
    if parts.scheme or parts.netloc:
        return None, None
    path = urllib.parse.unquote(parts.path)
    if path:
        path = posixpath.join(posixpath.dirname(base), path) if not path.startswith("/") else path
        # Browsers clamp ".." at the site root
        path = "/" + "/".join(p for p in posixpath.normpath(path).split("/") if p not in ("", ".."))
    else:
        path = base
    return path, parts.fragment

broken = 0
for base, page in sorted(pages.items()):
    for tag, link in page.links:
        target, fragment = resolve(base, link)
        if target is None:
            continue
        fs_path = os.path.join(root, target.lstrip("/"))
        if os.path.isdir(fs_path):
            target = target.rstrip("/") + "/index.html"
            fs_path = os.path.join(fs_path, "index.html")
        if not os.path.isfile(fs_path):
            print(f"❌ Broken link in {base}: {link}")
            broken += 1
        elif fragment and target in pages and fragment not in pages[target].ids:
            print(f"❌ Missing anchor in {base}: {link}")
            broken += 1

print(f"Checked {sum(len(p.links) for p in pages.values())} links on {len(pages)} pages")
sys.exit(1 if broken else 0)
EOF

if [ "$errors" -gt 0 ]; then
  echo "❌ Site check failed ($errors problem group(s))"
  exit 1
fi
echo "✅ Site check passed"
