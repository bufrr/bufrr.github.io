#!/usr/bin/env bash

# Generate sitemap.xml for the blog

# Source configuration if available
if [ -f ".blogrc" ]; then
  # shellcheck source=/dev/null
  source .blogrc
fi

BLOG_URL="${BLOG_URL:-https://example.com}"
OUTPUT_FILE="public/sitemap.xml"

# Start sitemap
cat > "$OUTPUT_FILE" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
EOF

# Add homepage
cat >> "$OUTPUT_FILE" << EOF
  <url>
    <loc>$BLOG_URL/</loc>
    <lastmod>$(date -u +%Y-%m-%d)</lastmod>
    <changefreq>daily</changefreq>
    <priority>1.0</priority>
  </url>
EOF

# Add all HTML files
for file in public/*.html; do
  if [ -f "$file" ] && [ "$(basename "$file")" != "404.html" ]; then
    # Get last modified date
    LASTMOD=$(date -r "$file" -u +%Y-%m-%d 2> /dev/null || date -u +%Y-%m-%d)
    FILENAME=$(basename "$file")

    # Set priority based on page type
    if [ "$FILENAME" = "index.html" ]; then
      continue # Already added
    elif [ "$FILENAME" = "about.html" ]; then
      PRIORITY="0.8"
    else
      PRIORITY="0.6"
    fi

    cat >> "$OUTPUT_FILE" << EOF
  <url>
    <loc>$BLOG_URL/$FILENAME</loc>
    <lastmod>$LASTMOD</lastmod>
    <changefreq>weekly</changefreq>
    <priority>$PRIORITY</priority>
  </url>
EOF
  fi
done

# Close sitemap
cat >> "$OUTPUT_FILE" << EOF
</urlset>
EOF

echo "Sitemap generated at $OUTPUT_FILE"
