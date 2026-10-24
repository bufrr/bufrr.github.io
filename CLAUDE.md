# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Structure

This is a public repo: the source for the blog at https://bytenoob.io plus an LLM-powered knowledge base. Everything committed, including `kb/`, is publicly readable on GitHub; the website only publishes `posts/`.

```
bufrr.github.io/
├── posts/            # Blog source files (.org)
├── build.el          # Blog build logic (org-publish)
├── public/           # Generated HTML (gitignored; CI builds and deploys it)
├── static/           # CSS, JS, assets
├── templates/        # Blog post templates
├── kb/               # Knowledge base
│   ├── raw/          # Immutable source material (articles, podcasts; private/, chats/, tweets/ are gitignored)
│   ├── wiki/         # LLM-maintained wiki (you write and maintain this)
│   ├── brainstorm/   # Brainstorming drafts
│   ├── artifacts/    # Query outputs, blog drafts, reports
│   └── skills/       # Skill files that define your behavior
└── CLAUDE.md         # This file
```

Note: GTD lives separately at `~/org/gtd/` and is not part of this repo.

## Knowledge Base Commands

When the user gives one of these commands, read the corresponding skill file and follow its instructions exactly:

| Command           | Skill File                   | What to Do                            |
| ----------------- | ---------------------------- | ------------------------------------- |
| **ingest**        | `kb/skills/ingest.md`        | Import a source into kb/raw/          |
| **absorb**        | `kb/skills/absorb.md`        | Compile raw sources into wiki entries |
| **query**         | `kb/skills/query.md`         | Answer questions from the wiki        |
| **lint**          | `kb/skills/lint.md`          | Health check the knowledge base       |
| **breakdown**     | `kb/skills/breakdown.md`     | Find missing articles                 |
| **reorganize**    | `kb/skills/reorganize.md`    | Restructure wiki categories           |
| **rebuild-index** | `kb/skills/rebuild-index.md` | Regenerate index.org                  |

Always read the skill file before executing. The skill files contain the rules.

## Key Files

- `kb/wiki/index.org` — Master index of all wiki pages. Read this first when navigating.
- `kb/wiki/log.org` — Chronological log of KB operations (see Rules for which ones).
- `kb/skills/*.md` — Skill definitions. These are your instruction manuals.

## Wiki Page Format

All wiki pages use the above-the-line / below-the-line structure (defined in `kb/skills/absorb.md`):

- Above `-----`: Compiled truth. Rewrite freely with new information.
- Below `-----`: Evidence timeline. Append-only. Never rewrite.

## Blog

```bash
# Build the site (generates HTML from Org files)
./build.sh

# Or directly with Emacs (skips .blogrc, sitemap, and robots.txt)
emacs --batch --load build.el --funcall blog/publish-all
```

- Source: `posts/*.org`
- Build: `build.el` uses `ox-publish`; `build.sh` wraps it with config, sitemap, and robots.txt
- Output: `public/` (gitignored); the Publish workflow builds it and deploys to GitHub Pages
- Blog drafts from `kb/artifacts/` can be published to `posts/`

## Rules

- This repo is public. Never commit credentials, tokens, private notes, or personal data (emails, phone numbers, addresses). Ask before ingesting private conversations or documents into `kb/`, and redact personal details.
- Never modify files in `kb/raw/`. Raw sources are immutable.
- Always update `kb/wiki/index.org` after creating or significantly changing wiki pages.
- Append to `kb/wiki/log.org` after every KB operation (ingest, absorb, lint, breakdown, rebuild-index; reorganize once the user decides; query only when it saves an artifact).
- Use `[[id:xxx][Display Text]]` for wiki cross-references, with the ID read from the target page's `:ID:` drawer. Every new page gets a fresh UUID (`uuidgen`) in a property drawer at the top of the file (see `kb/skills/absorb.md`).
- Use `#+title:`, `#+filetags:`, `#+date:` headers on all wiki pages; the first filetag is the index section (`core`, `culture`, `technical`, `narrative`, `work`).
- Wiki pages and artifacts are public: never copy personal data or verbatim quotes from private sources into them. Private raw material of any type goes in the gitignored `kb/raw/private/` (or `chats/`, `tweets/`).
