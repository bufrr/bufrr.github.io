# Skill: Breakdown

Identify missing articles by mining existing wiki content for entities and themes that deserve their own pages.

## Workflow

1. Read all wiki pages in `kb/wiki/`.
2. For each page, scan for:
   - Named entities (people, companies, projects, tools) mentioned but without their own page.
   - Concepts explained inline that are substantial enough for a standalone article.
   - Recurring themes across multiple pages that lack a unifying article.
3. For each candidate, assess:
   - How many pages mention it? (Threshold: 2+ mentions = candidate)
   - Is there enough material across existing pages to write at least 15 lines?
   - Would a dedicated page reduce duplication across existing articles?

## Output Format

```org
#+title: Breakdown Report
#+date: [YYYY-MM-DD]

* Recommended New Articles

** Topic Name
- Mentioned in: page1.org, page2.org, page3.org
- Estimated material: sufficient / borderline / insufficient
- Reason: Explained inline in 3 different pages, would reduce duplication
- Priority: high / medium / low

** Another Topic
...
```

## Rules

- Do not create articles. Only recommend.
- The user must confirm before any new pages are created.
- Append a log entry:

```org
** [YYYY-MM-DD] breakdown | Content mining
:PROPERTIES:
:CANDIDATES_FOUND: N
:END:
```
