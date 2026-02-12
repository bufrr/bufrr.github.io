# Repository Guidelines

## Project Structure & Module Organization
- `posts/` holds Org sources, including special pages (`about.org`, `404.org`, `index.org`, `index-cn.org`).
- Post files use date-first names like `YYYY-MM-DD-slug.org`; Chinese variants use `-cn.org`.
- `static/` contains site assets (`css/`, `js/`, `favicon.svg`, `robots.txt`) copied to `public/static/` during builds.
- `templates/post-template.org` is the starter template for new posts.
- `build.el` defines Org publish logic; `build.sh`, `minify.sh`, and `generate-sitemap.sh` orchestrate CLI builds.
- `public/` is generated output; do not edit it manually.

## Build, Test, and Development Commands
- `npm ci`: install Node-based tooling.
- `make build` or `npm run build`: generate HTML into `public/`.
- `make build-prod` or `npm run build:prod`: build plus asset minification.
- `make serve` or `npm run serve`: serve `public/` locally at `http://localhost:8000`.
- `make dev`: watch `posts/` and `static/` and rebuild on change (`inotifywait` required).
- `npm run format`: format JS/CSS/JSON/Markdown/YAML.
- `npm run format:check`: CI-style formatting check.

## Coding Style & Naming Conventions
- Prettier config (`.prettierrc`): 2-space indentation, single quotes, semicolons, 100-column width, LF endings.
- Shell scripts should use `bash` + `set -euo pipefail` and remain ShellCheck-clean.
- Org posts must include `#+TITLE`, `#+AUTHOR`, and `#+DATE`; use `#+DRAFT: true` for unpublished work.
- Keep filenames kebab-case and date-prefixed (example: `2026-02-12-my-post.org`).

## Testing Guidelines
- There is no unit-test suite; quality gates are lint/build checks.
- Run before push:
  - `./build.sh`
  - `shellcheck *.sh` (and any modified shell scripts)
  - `npm run format:check`
- CI additionally validates Org metadata and checks generated HTML internal links.

## Commit & Pull Request Guidelines
- Follow existing history style: short, imperative commit subjects (for example, `fix lint`, `update about`, `refactor`).
- Keep commits focused; separate content changes from tooling refactors when possible.
- PRs should include: concise change summary, linked issue (if applicable), screenshots for UI/content styling changes, and confirmation that local checks pass.

## Configuration & Security Tips
- Start from `.blogrc.example`; keep personal or deployment-specific values in `.blogrc`/environment variables.
- Do not commit secrets; CI and publish workflows already read values like `BLOG_URL`, `BLOG_AUTHOR`, and `BLOG_EMAIL` from environment/secrets.
