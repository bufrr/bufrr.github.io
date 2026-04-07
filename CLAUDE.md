# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Structure

This is a private repo containing blog + LLM-powered knowledge base:

```
bufrr.github.io/
├── posts/            # Blog source files (.org)
├── build-site.el     # Blog build script
├── public/           # Generated HTML (GitHub Pages serves from here)
├── static/           # CSS, JS, assets
├── templates/        # Blog post templates
├── kb/               # Knowledge base
│   ├── raw/          # Immutable source material (articles, tweets, chats)
│   ├── wiki/         # LLM-maintained wiki (you write and maintain this)
│   ├── brainstorm/   # Brainstorming drafts
│   ├── artifacts/    # Query outputs, blog drafts, reports
│   └── skills/       # Skill files that define your behavior
└── CLAUDE.md         # This file
```

Note: GTD lives separately at `~/org/gtd/` and is not part of this repo.

## Knowledge Base Commands

When the user gives one of these commands, read the corresponding skill file and follow its instructions exactly:

| Command | Skill File | What to Do |
|---------|-----------|------------|
| **ingest** | `kb/skills/ingest.md` | Import a source into kb/raw/ |
| **absorb** | `kb/skills/absorb.md` | Compile raw sources into wiki entries |
| **query** | `kb/skills/query.md` | Answer questions from the wiki |
| **lint** | `kb/skills/lint.md` | Health check the knowledge base |
| **breakdown** | `kb/skills/breakdown.md` | Find missing articles |
| **reorganize** | `kb/skills/reorganize.md` | Restructure wiki categories |
| **rebuild-index** | `kb/skills/rebuild-index.md` | Regenerate index.org |

Always read the skill file before executing. The skill files contain the rules.

## Key Files

- `kb/wiki/index.org` — Master index of all wiki pages. Read this first when navigating.
- `kb/wiki/log.org` — Chronological log of all operations. Append after every operation.
- `kb/skills/*.md` — Skill definitions. These are your instruction manuals.

## Wiki Page Format

All wiki pages use the above-the-line / below-the-line structure (defined in `kb/skills/absorb.md`):
- Above `-----`: Compiled truth. Rewrite freely with new information.
- Below `-----`: Evidence timeline. Append-only. Never rewrite.

## Blog

```bash
# Build the site (generates HTML from Org files)
./build.sh

# Or directly with Emacs
emacs -Q --script build-site.el
```

- Source: `posts/*.org`
- Build: `build-site.el` uses `ox-publish`
- Output: `public/` directory (GitHub Pages)
- Blog drafts from `kb/artifacts/` can be published to `posts/`

## Rules

- Never modify files in `kb/raw/`. Raw sources are immutable.
- Always update `kb/wiki/index.org` after creating or significantly changing wiki pages.
- Always append to `kb/wiki/log.org` after any operation.
- Use `[[id:xxx][Display Text]]` format for wiki cross-references (org-roam compatible).
- Use `#+title:`, `#+filetags:`, `#+date:` headers on all wiki pages.
