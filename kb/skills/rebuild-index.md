# Skill: Rebuild Index

Regenerate `kb/wiki/index.org` from scratch by scanning all wiki pages.

## Workflow

1. Scan all `.org` files in `kb/wiki/` (excluding `index.org` and `log.org`).
2. For each file, extract:
   - `#+title:`
   - `#+filetags:`
   - `#+date:`
   - First paragraph of the Summary section (one-line description)
3. Group pages by their first filetag, which names the index section:

| First tag     | Section   | Covers                                          |
| ------------- | --------- | ----------------------------------------------- |
| `:core:`      | Core      | People, projects, places, events, companies     |
| `:culture:`   | Culture   | Books, films, music, games, tools, platforms    |
| `:technical:` | Technical | Languages, frameworks, protocols, architectures |
| `:narrative:` | Narrative | Eras, transitions, decisions, experiments       |
| `:work:`      | Work      | Strategies, techniques, skills, ideas           |

4. Write `index.org`. Keep all five sections and their one-line descriptions, even when a section is empty. Each entry is a `file:` link (the index is a plain catalog; pages link to each other by `id:`), followed by the summary and the remaining tags:

```org
#+title: Wiki Index
#+date: [YYYY-MM-DD]
#+filetags: :index:

* Core
/People, projects, places, events, companies/
- [[file:project-name.org][Project Name]] — one-line summary :projects:

* Culture
/Books, films, music, games, tools, platforms/

* Technical
/Languages, frameworks, protocols, architectures/
- [[file:ethereum-block-building.org][Ethereum Block Building]] — one-line summary :ethereum:mev:

* Narrative
/Eras, transitions, decisions, experiments/

* Work
/Strategies, techniques, skills, ideas/
```

5. Validate all links point to existing files.
6. Report any orphan files not reachable from the index.

## Rules

- This completely replaces the existing `index.org`. Back up is via git.
- Sections are fixed (table above). A page whose first tag is not a section tag is a lint issue: report it instead of inventing a section.
- Append a log entry:

```org
** [YYYY-MM-DD] rebuild-index | Index regenerated
:PROPERTIES:
:TOTAL_PAGES: N
:CATEGORIES: N
:END:
```
