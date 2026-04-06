# Skill: Absorb

Compile raw source material into structured wiki entries. This is the core skill.

## Page Structure: Above the Line / Below the Line

Every wiki page uses a two-part structure separated by a horizontal rule:

```org
#+title: Topic Name
#+date: [YYYY-MM-DD]
#+filetags: :category:tag1:tag2:
:PROPERTIES:
:ID: (org-id, auto-generated)
:END:

* Summary
One paragraph overview of this topic.

* Details
Thematic sections. Organize by concept, not chronology.
Use [[id:xxx][Link Text]] for cross-references to other wiki pages.

-----

* Evidence Timeline
Append-only. Never rewrite entries below this line.

** [2026-04-06] From: source-filename.org
Key facts extracted from this source.
#+begin_quote
Direct quote if valuable. Max 1-2 per source.
#+end_quote
```

**Above the line**: The compiled truth. LLM rewrites and updates this freely as new information arrives.

**Below the line**: Evidence base. Append-only. Never rewrite. Each entry cites its source file. This prevents error compounding — you can always trace back to the original evidence.

## Writing Standards

- **Wikipedia tone**: Factual, neutral, plain language. No rhetorical flourish.
- **Organize by theme, not chronology**: "What does this mean?" not "What happened when?"
- **Synthesize, don't summarize**: Every entry must be woven into understanding, not mechanically filed.
- **Length**: Minimum 15 lines for any article. 60-100 lines for major topics.
- **Quotes**: Maximum 1-2 direct quotes per article. Quotes carry emotional weight; the article stays neutral.
- **Links**: Use `[[id:xxx][Display Text]]` format for org-roam compatibility.

## Anti-Patterns

- **Anti-cramming**: Do not keep appending to an existing article when a subtopic deserves its own page. Create a new page and link to it.
- **Anti-thinning**: Do not create a page before you have enough material. A stub with two sentences is a failure.
- **Anti-diary**: Do not use dates as headings. Use thematic concepts. Dates belong in the evidence timeline below the line.

## Workflow

1. Read the raw source file completely.
2. Identify which existing wiki pages this source is relevant to. Read `kb/wiki/index.org` first.
3. For each relevant wiki page:
   - Read the existing page
   - Update the above-the-line content with new information
   - Append a new entry below the line citing this source
4. If the source introduces a new topic not covered by existing pages:
   - Create a new wiki page following the page structure above
   - Add cross-references from related existing pages
5. Update `kb/wiki/index.org` with any new or significantly changed pages.
6. Append a log entry to `kb/wiki/log.org`:

```org
** [YYYY-MM-DD] absorb | Source Title
:PROPERTIES:
:SOURCE: kb/raw/articles/filename.org
:PAGES_TOUCHED: page1.org, page2.org, new-page.org
:END:
```

## Rules

- A single absorb can touch 10-15 wiki pages. This is normal and expected.
- Always update the index after absorbing.
- Always append to the log after absorbing.
- Never delete content from above the line — rewrite it to incorporate new information.
- Never modify content below the line — only append.
