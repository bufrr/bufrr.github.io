# Skill: Rebuild Index

Regenerate `kb/wiki/index.org` from scratch by scanning all wiki pages.

## Workflow

1. Scan all `.org` files in `kb/wiki/` (excluding `index.org` and `log.org`).
2. For each file, extract:
   - `#+title:`
   - `#+filetags:`
   - `#+date:`
   - First paragraph of the Summary section (one-line description)
3. Group pages by their primary filetag (first tag).
4. Write `index.org`:

```org
#+title: Wiki Index
#+date: [YYYY-MM-DD]
#+filetags: :index:

* Core
- [[file:person-name.org][Person Name]] — one-line summary :people:
- [[file:project-name.org][Project Name]] — one-line summary :projects:

* Technical
- [[file:topic.org][Topic]] — one-line summary :ethereum:

* Culture
- [[file:book.org][Book Title]] — one-line summary :books:
```

5. Validate all links point to existing files.
6. Report any orphan files not reachable from the index.

## Rules

- This completely replaces the existing `index.org`. Back up is via git.
- Categories in the index should match the actual `#+filetags:` found in wiki pages. Do not invent categories that no page uses.
- Append a log entry:

```org
** [YYYY-MM-DD] rebuild-index | Index regenerated
:PROPERTIES:
:TOTAL_PAGES: N
:CATEGORIES: N
:END:
```
