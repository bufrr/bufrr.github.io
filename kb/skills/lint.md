# Skill: Lint

Health check the knowledge base for data integrity issues.

## Checks

Scan all files in `kb/wiki/` and report:

1. **Missing metadata**: Pages without `#+title:`, `#+filetags:`, or `#+date:`.
2. **Orphan pages**: Wiki pages with no inbound links from other pages.
3. **Missing pages**: Concepts mentioned via `[[id:...]]` links that point to non-existent pages.
4. **Broken links**: Links to pages that have been renamed or deleted.
5. **Contradictions**: Claims in one page that conflict with claims in another (check above-the-line content).
6. **Stale content**: Pages not updated in 90+ days that reference active topics.
7. **Uncompiled raw**: Files in `kb/raw/` that have no corresponding absorb entry in `kb/wiki/log.org`.
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

- This is a read-only operation. Do not fix issues — only report them.
- Always append a log entry after running:

```org
** [YYYY-MM-DD] lint | Health check
:PROPERTIES:
:ISSUES_FOUND: N
:END:
```

- Suggest specific actions for each issue found.
- Prioritize issues: missing pages and contradictions are critical; stale content is low priority.
