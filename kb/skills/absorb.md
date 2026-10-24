# Skill: Absorb

Compile raw source material into structured wiki entries. This is the core skill.

## Page Structure: Above the Line / Below the Line

Every wiki page uses a two-part structure separated by a horizontal rule:

```org
:PROPERTIES:
:ID: <new UUID from uuidgen>
:END:
#+title: Topic Name
#+date: [YYYY-MM-DD]
#+filetags: :technical:tag1:tag2:

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

**File-level metadata** (org-roam reads the drawer only when it is the first thing in the file):

- `:ID:` — a new UUID for every new page, generated with `uuidgen` (or `python3 -c 'import uuid; print(uuid.uuid4())'`). Never invent, reuse, or change an ID.
- `#+date:` — the last time the above-the-line content changed. Update it whenever you rewrite the page.
- `#+filetags:` — the first tag is the page's index section, one of `:core:`, `:culture:`, `:technical:`, `:narrative:`, `:work:` (see `rebuild-index.md`). Further tags are free-form topics.
- File name — `kb/wiki/<slug>.org`, where the slug is the title in lowercase kebab-case ASCII (e.g. `ethereum-block-building.org`).

**Linking**: To link to a page, read its `:ID:` from the target file and write `[[id:<that ID>][Display Text]]`. Never link to a page that does not exist yet; create it first or leave plain text.

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
5. Update `kb/wiki/index.org`: add an entry for each new page under the section named by its first filetag, using the entry format in `rebuild-index.md`; refresh the summary of significantly changed pages.
6. Append a log entry to `kb/wiki/log.org`:

```org
** [YYYY-MM-DD] absorb | Source Title
:PROPERTIES:
:SOURCE: kb/raw/articles/filename.org
:PAGES_TOUCHED: page1.org, page2.org, new-page.org
:END:
```

## Rules

- Touch every page the source is genuinely relevant to — sometimes one, often several. Do not pad pages or create thin ones to reach a number.
- Always update the index after absorbing.
- Always append to the log after absorbing.
- Above the line may be rewritten, merged, or moved: when a subtopic moves to its own page (anti-cramming), leave a one-line summary linking to it. Never drop a claim that is still supported by evidence below the line.
- Never modify content below the line — only append.
- Wiki pages are public. Never copy personal data (private individuals' names, emails, phone numbers, addresses) or verbatim quotes from private sources such as chats and emails into the wiki; paraphrase the knowledge instead. In non-interactive runs, skip private sources that have not been redacted. Do not write an `absorb` entry for a skipped source; append a separate `** [YYYY-MM-DD] skip | Source Title` entry with `:SOURCE:` and `:REASON:` properties. Only `absorb` entries count as compiled, so skipped sources stay on the uncompiled list until they are absorbed.
