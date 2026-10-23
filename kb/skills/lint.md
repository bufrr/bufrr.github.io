# Skill: Lint

Health check the knowledge base for data integrity issues.

## Checks

Scan all wiki pages in `kb/wiki/` (excluding `index.org` and `log.org`, which are not pages) and report:

1. **Missing metadata**: Pages without a leading `:ID:` property drawer, `#+title:`, `#+filetags:`, or `#+date:`, or whose first filetag is not a section tag (see `rebuild-index.md`).
2. **Orphan pages**: Wiki pages with no inbound links from other pages.
3. **Missing pages**: `[[id:...]]` links whose ID does not appear as an `:ID:` in any wiki page.
4. **Broken links**: Links to pages that have been renamed or deleted.
5. **Contradictions**: Claims in one page that conflict with claims in another (check above-the-line content).
6. **Stale content**: Pages not updated in 90+ days that reference active topics.
7. **Uncompiled raw**: Files in `kb/raw/` (ignoring `.gitkeep`) with no `absorb` log entry whose `:SOURCE:` is that file. An `ingest` entry alone does not count.
8. **Index drift**: Pages that exist in `kb/wiki/` but are missing from `index.org`, or entries in `index.org` that point to deleted pages.

## Output Format

```org
#+title: Health Check Report
#+date: [YYYY-MM-DD]

* Missing Metadata
- [[file:page.org]] — missing #+filetags:

* Orphan Pages
- [[file:page.org]] — no inbound links

* Uncompiled Raw Files
- kb/raw/articles/unprocessed.org — not found in log.org

* Suggested New Articles
- "Topic X" — mentioned in 3 pages but has no dedicated article
```

## Rules

- Do not fix issues or edit wiki pages — only report them. The one write allowed is the log entry below.
- Always append a log entry to `kb/wiki/log.org` after running:

```org
** [YYYY-MM-DD] lint | Health check
:PROPERTIES:
:ISSUES_FOUND: N
:END:
```

- Suggest specific actions for each issue found.
- Prioritize issues: missing pages and contradictions are critical; stale content is low priority.
