# bufrr.github.io

Private monorepo: blog + GTD + LLM-powered knowledge base.

## Setup (after clone)

### 1. Prerequisites

- [Emacs](https://www.gnu.org/software/emacs/) (for blog build + GTD)
- [Doom Emacs](https://github.com/doomemacs/doomemacs) (with config from [bufrr/emacs-config](https://github.com/bufrr/emacs-config))
- [Claude Code](https://claude.ai/code) CLI (`claude` command available in PATH)
- Node.js 16+ and npm (for blog asset minification)

### 2. Clone and install

```bash
git clone git@github.com:bufrr/bufrr.github.io.git ~/bufrr.github.io
cd ~/bufrr.github.io
npm ci
cp .blogrc.example .blogrc  # edit with your values
```

### 3. Doom Emacs config

The Doom config lives in `~/.config/doom/` (separate [emacs-config](https://github.com/bufrr/emacs-config) repo). It points all paths to this repo:

```elisp
(setq org-directory "~/bufrr.github.io/")
(setq org-current-file "~/bufrr.github.io/gtd/current.org")
(setq org-archive-file "~/bufrr.github.io/gtd/archive.org")
(setq blog-directory "~/bufrr.github.io/")
```

After cloning the emacs-config, run:

```bash
doom sync    # installs org-roam, org-roam-ui, org-ql
```

### 4. Verify everything works

```bash
# Blog
./build.sh                   # should generate HTML in public/

# Knowledge base (requires Claude Code CLI)
claude -p "Read CLAUDE.md. Then read kb/wiki/index.org. Report what you see."

# Or use Makefile shortcuts
make kb-lint                 # health check
make kb-absorb               # compile new raw files
```

In Emacs:
- `SPC g w` — should open `gtd/current.org`
- `SPC k k` — should open `kb/wiki/` directory
- `SPC B n` — should create a new blog post

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

## Daily Usage

### Add knowledge

```bash
# Option A: save a file directly
cp article.org kb/raw/articles/

# Option B: use Emacs capture
# SPC k n → paste content → save

# Then compile it into wiki
claude -p "Read kb/skills/absorb.md. Absorb kb/raw/articles/article.org"
```

### Query your wiki

```bash
claude -p "Read kb/skills/query.md. Summarize everything I know about Solana."
```

### Write a blog post from wiki knowledge

```bash
claude -p "Read kb/skills/query.md. Based on my wiki, draft a blog post about Ethereum block building. Save to kb/artifacts/eth-block-building.org"

# Then publish
# SPC k p → select draft → copies to posts/
# SPC B p → publish
# git push
```

### Weekly maintenance

```bash
make kb-lint        # find issues
make kb-breakdown   # find missing articles
```

## Blog

```bash
./build.sh              # build site
make serve              # preview at localhost:8000
make build-prod         # build + minify
```

Create posts in `posts/` using `YYYY-MM-DD-slug.org` naming with `#+TITLE:`, `#+AUTHOR:`, `#+DATE:` headers. Set `#+DRAFT: true` to keep unpublished.

Push to `main` to deploy via GitHub Pages.

## GTD

Managed in Doom Emacs. Files: `gtd/current.org` (active work) and `gtd/archive.org` (completed).

## Keybindings

| Prefix | System | Keys |
|--------|--------|------|
| `SPC g` | GTD | `c` capture, `a` agenda, `w` current work, `A` archive |
| `SPC k` | KB | `n` new raw, `c` compile file, `C` compile all new, `k` browse wiki, `g` graph, `h` health check, `p` publish draft |
| `SPC B` | Blog | `n` new post, `p` publish |

## KB Commands Reference

| Command | CLI | Makefile | What it does |
|---------|-----|----------|-------------|
| Ingest | `claude -p "Read kb/skills/ingest.md. Ingest ..."` | — | Import source into raw/ |
| Absorb | `claude -p "Read kb/skills/absorb.md. Absorb ..."` | `make kb-absorb` | Compile raw → wiki |
| Query | `claude -p "Read kb/skills/query.md. ..."` | — | Answer questions from wiki |
| Lint | `claude -p "Read kb/skills/lint.md. ..."` | `make kb-lint` | Health check |
| Breakdown | `claude -p "Read kb/skills/breakdown.md. ..."` | `make kb-breakdown` | Find missing articles |
| Reorganize | `claude -p "Read kb/skills/reorganize.md. ..."` | — | Restructure categories |
| Rebuild Index | `claude -p "Read kb/skills/rebuild-index.md. ..."` | — | Regenerate index.org |
