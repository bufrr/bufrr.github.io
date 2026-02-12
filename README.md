# Org-Mode Blog

Static blog generator powered by Emacs Org publish, with shell-based build scripts and GitHub Pages deployment.

## Prerequisites

- Emacs
- Node.js 16+ and npm
- Python 3 (for local preview server)

## Quick Start

```bash
npm ci
cp .blogrc.example .blogrc
./build.sh
make serve
```

Open `http://localhost:8000`.

## Common Commands

- `make build` or `npm run build`: Build site into `public/`
- `make build-prod` or `npm run build:prod`: Build and minify assets
- `make serve` or `npm run serve`: Build and preview locally
- `make dev`: Watch `posts/` and `static/`, then rebuild on change
- `npm run format`: Format JS/CSS/JSON/MD/YAML
- `npm run format:check`: Check formatting

## Project Layout

- `posts/`: Org source files for posts and pages
- `static/`: CSS, JS, images, favicon, robots
- `templates/`: Post template(s)
- `build.el`: Org publish configuration
- `build.sh`, `minify.sh`, `generate-sitemap.sh`: Build pipeline scripts
- `public/`: Generated output (do not edit directly)

## Writing Posts

Create posts in `posts/` using `YYYY-MM-DD-slug.org` naming. Include:

- `#+TITLE:`
- `#+AUTHOR:`
- `#+DATE:`

Set `#+DRAFT: true` to keep a post unpublished.

## Deployment

Push to `main` to trigger `.github/workflows/publish.yml` and deploy to GitHub Pages.

For configuration, use `.blogrc` and/or repository secrets (`BLOG_URL`, `BLOG_AUTHOR`, `BLOG_EMAIL`).

## CI Checks

PRs run `.github/workflows/ci.yml`, including:

- Org metadata validation
- Shell script linting
- Build verification
- Internal HTML link checks
