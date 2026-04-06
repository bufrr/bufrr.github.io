# bufrr.github.io

Private monorepo: blog + GTD + LLM-powered knowledge base.

## Structure

```
posts/        Blog source files (.org)
static/       CSS, JS, assets
templates/    Blog post templates
public/       Generated HTML (GitHub Pages)
gtd/          GTD system (current.org + archive.org)
kb/           Knowledge base
  raw/        Immutable source material
  wiki/       LLM-maintained wiki (org-roam nodes)
  brainstorm/ Brainstorming drafts
  artifacts/  Query outputs, blog drafts, reports
  skills/     Skill files defining Claude's behavior
```

## Blog

```bash
npm ci
cp .blogrc.example .blogrc
./build.sh              # build site
make serve              # preview at localhost:8000
make build-prod         # build + minify
```

Create posts in `posts/` using `YYYY-MM-DD-slug.org` naming with `#+TITLE:`, `#+AUTHOR:`, `#+DATE:` headers. Set `#+DRAFT: true` to keep unpublished.

Push to `main` to deploy via GitHub Pages.

## Knowledge Base

The KB uses `claude -p` (Claude Code CLI) to compile raw notes into a structured wiki.

```bash
# Ingest a source
claude -p "Read kb/skills/ingest.md. Ingest this URL: https://..."

# Compile raw files into wiki
claude -p "Read kb/skills/absorb.md. Absorb kb/raw/articles/my-article.org"

# Query the wiki
claude -p "Read kb/skills/query.md. What do I know about Ethereum MEV?"

# Health check
claude -p "Read kb/skills/lint.md. Run a health check."

# Find missing articles
claude -p "Read kb/skills/breakdown.md. What articles are missing?"
```

Skill files in `kb/skills/` define all rules. See `CLAUDE.md` for the full command reference.

## GTD

Managed in Doom Emacs with `SPC g` keybindings. Files: `gtd/current.org` (active work) and `gtd/archive.org` (completed).

## Doom Emacs Keybindings

| Prefix | System | Keys |
|--------|--------|------|
| `SPC g` | GTD | `c` capture, `a` agenda, `w` current work |
| `SPC k` | KB | `n` new raw, `c` compile, `k` browse wiki, `g` graph, `h` health check |
| `SPC B` | Blog | `n` new post, `p` publish |
