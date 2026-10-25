#!/usr/bin/env bash

# Shared configuration loader, sourced by build.sh and generate-sitemap.sh.
# Precedence: non-empty exported environment (e.g. CI secrets) > .blogrc > defaults.
# Uses only indexed arrays so it also runs on macOS's bash 3.2.

CONFIG_VARS=(BLOG_TITLE BLOG_AUTHOR BLOG_EMAIL BLOG_URL BLOG_DESCRIPTION GITHUB_USERNAME TWITTER_USERNAME INCREMENTAL_BUILD)

env_config=()
for var in "${CONFIG_VARS[@]}"; do
  if [ -n "${!var:-}" ]; then
    env_config+=("$var=${!var}")
  fi
done

if [ -f ".blogrc" ]; then
  # shellcheck source=/dev/null
  source .blogrc
fi

for kv in ${env_config[@]+"${env_config[@]}"}; do
  printf -v "${kv%%=*}" '%s' "${kv#*=}"
done
unset env_config var kv

: "${BLOG_TITLE:=bytenoob}"
: "${BLOG_AUTHOR:=bytenoob}"
: "${BLOG_EMAIL:=noreply@example.com}"
: "${BLOG_URL:=https://bytenoob.io}"
: "${BLOG_DESCRIPTION:=}"
: "${GITHUB_USERNAME:=bufrr}"
: "${TWITTER_USERNAME:=winddyseed}"
: "${INCREMENTAL_BUILD:=false}"
BLOG_URL="${BLOG_URL%/}"

export "${CONFIG_VARS[@]}"

# True if an Org file is a draft: #+DRAFT: true/t/yes in its header, before
# the first heading (same rule as blog/is-draft-p in build.el)
is_draft() {
  awk '/^\*+ /{exit} tolower($0) ~ /^#\+draft:[[:space:]]*(true|t|yes)[[:space:]]*$/{found=1; exit} END{exit !found}' "$1"
}
