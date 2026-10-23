#!/usr/bin/env bash

# Shared configuration loader, sourced by build.sh and generate-sitemap.sh.
# Precedence: exported environment (e.g. CI secrets) > .blogrc > defaults.

CONFIG_VARS=(BLOG_TITLE BLOG_AUTHOR BLOG_EMAIL BLOG_URL BLOG_DESCRIPTION GITHUB_USERNAME INCREMENTAL_BUILD)

declare -A env_config=()
for var in "${CONFIG_VARS[@]}"; do
  if [ -n "${!var+x}" ]; then
    env_config[$var]="${!var}"
  fi
done

if [ -f ".blogrc" ]; then
  # shellcheck source=/dev/null
  source .blogrc
fi

for var in "${!env_config[@]}"; do
  printf -v "$var" '%s' "${env_config[$var]}"
done
unset env_config var

: "${BLOG_TITLE:=Noob Notes}"
: "${BLOG_AUTHOR:=bytenoob}"
: "${BLOG_EMAIL:=noreply@example.com}"
: "${BLOG_URL:=https://bytenoob.io}"
: "${BLOG_DESCRIPTION:=}"
: "${GITHUB_USERNAME:=bufrr}"
: "${INCREMENTAL_BUILD:=false}"

export "${CONFIG_VARS[@]}"
