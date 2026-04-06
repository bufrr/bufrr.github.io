# Repository Guidelines

## Project Structure

This is a private monorepo with three systems:

- **Blog** (`posts/`, `static/`, `templates/`, `build.el`, `build.sh`) — Org-mode static site generator → `public/` → GitHub Pages
- **GTD** (`gtd/`) — Simple 2-file GTD system (current.org + archive.org)
- **Knowledge Base** (`kb/`) — LLM-powered personal wiki compiled from raw sources

### Key Directories

- `posts/` — Org source files for blog posts and pages. Date-first naming: `YYYY-MM-DD-slug.org`
- `static/` — Site assets (css/, js/, favicon.svg, robots.txt) copied to `public/static/`
- `templates/post-template.org` — Starter template for new posts
- `public/` — Generated output. Do not edit manually.
- `gtd/current.org` — Active projects, tasks, ideas
- `gtd/archive.org` — Completed items
- `kb/raw/` — Immutable source material (articles, podcasts, tweets, chats). Never modify after ingestion.
- `kb/wiki/` — LLM-maintained wiki. Contains `index.org` (master catalog) and `log.org` (operation timeline).
- `kb/skills/` — Skill files defining Claude's behavior for each KB operation.
- `kb/artifacts/` — Query outputs, blog drafts, reports.
- `CLAUDE.md` — Project-level instructions for Claude Code, including KB command mapping.

## Build, Test, and Development Commands

- `npm ci`: install Node-based tooling
- `make build` or `npm run build`: generate HTML into `public/`
- `make build-prod` or `npm run build:prod`: build plus asset minification
- `make serve` or `npm run serve`: serve `public/` locally at `http://localhost:8000`
- `make dev`: watch `posts/` and `static/` and rebuild on change
- `npm run format`: format JS/CSS/JSON/Markdown/YAML
- `npm run format:check`: CI-style formatting check

## Coding Style & Naming Conventions

- Prettier config (`.prettierrc`): 2-space indentation, single quotes, semicolons, 100-column width, LF endings
- Shell scripts: `bash` + `set -euo pipefail`, ShellCheck-clean
- Blog posts: must include `#+TITLE`, `#+AUTHOR`, `#+DATE`; use `#+DRAFT: true` for unpublished
- Wiki pages: must include `#+title:`, `#+filetags:`, `#+date:`; use above/below-the-line structure (see `kb/skills/absorb.md`)
- Filenames: kebab-case, date-prefixed for blog posts

## Knowledge Base Operations

When working with the KB, read the corresponding skill file before executing:

| Command | Skill File | Description |
|---------|-----------|-------------|
| ingest | `kb/skills/ingest.md` | Import source material into `kb/raw/` |
| absorb | `kb/skills/absorb.md` | Compile raw sources into wiki entries |
| query | `kb/skills/query.md` | Answer questions from the wiki |
| lint | `kb/skills/lint.md` | Health check the knowledge base |
| breakdown | `kb/skills/breakdown.md` | Find missing articles |
| reorganize | `kb/skills/reorganize.md` | Restructure wiki categories |
| rebuild-index | `kb/skills/rebuild-index.md` | Regenerate index.org |

Rules:
- Never modify files in `kb/raw/`. Raw sources are immutable.
- Always update `kb/wiki/index.org` after creating or changing wiki pages.
- Always append to `kb/wiki/log.org` after any operation.

## Testing Guidelines

- No unit-test suite; quality gates are lint/build checks
- Run before push: `./build.sh`, `shellcheck *.sh`, `npm run format:check`
- CI validates Org metadata and checks generated HTML internal links

## Commit & Pull Request Guidelines

- Short, imperative commit subjects (e.g., `fix lint`, `add kb skills`, `update config`)
- Separate content changes from tooling refactors
- Do not commit secrets; use `.blogrc`/environment variables

## Configuration & Security

- Start from `.blogrc.example`; keep personal values in `.blogrc`/env vars
- Do not commit `.blogrc` with real credentials
