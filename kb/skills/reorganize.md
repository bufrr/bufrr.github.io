# Skill: Reorganize

Review and restructure the wiki's category organization.

## Workflow

1. Read `kb/wiki/index.org` and all wiki pages.
2. Analyze the current category structure (based on `#+filetags:`).
3. Identify issues:
   - **Overcrowded categories**: A tag with 15+ pages that should be split into subcategories.
   - **Sparse categories**: Tags with only 1-2 pages that could merge into a parent category.
   - **Miscategorized pages**: Pages whose content doesn't match their tags.
   - **Missing categories**: Clusters of related pages that share no common tag.
4. Propose a reorganization plan.

## Output Format

```org
#+title: Reorganization Plan
#+date: [YYYY-MM-DD]

* Proposed Changes

** Split :blockchain: into :ethereum: and :solana:
- Affected pages: page1.org, page2.org, ...
- Reason: 20 pages under one tag, two clear subclusters

** Merge :vim: into :tools:
- Affected pages: vim-tips.org
- Reason: Only 1 page, fits naturally under tools

** Recategorize page.org
- Current: :people:
- Proposed: :projects:
- Reason: Content is about a project, not a person
```

## Rules

- Do not execute changes. Only propose.
- The user must confirm the plan before execution.
- When confirmed, update `#+filetags:` on affected pages and rebuild the index.
- Append a log entry:

```org
** [YYYY-MM-DD] reorganize | Wiki restructure
:PROPERTIES:
:CHANGES_PROPOSED: N
:CHANGES_APPLIED: N
:END:
```
