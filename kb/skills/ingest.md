# Skill: Ingest

Import raw source material into the knowledge base.

## Supported Input

- `.org` files (preferred)
- `.md` files (convert to Org on ingest)
- `.txt` files (wrap in Org structure)
- URLs (fetch content, save as `.org` in raw/)

## Workflow

1. Determine the source type (article, podcast notes, tweet, chat log)
2. Place the file in the appropriate `kb/raw/` subdirectory:
   - `kb/raw/articles/` — articles, blog posts, papers
   - `kb/raw/podcasts/` — podcast notes, transcripts
   - `kb/raw/tweets/` — tweets, threads, social media
   - `kb/raw/chats/` — AI conversations, chat logs
3. Ensure the file has an Org-mode property drawer with metadata:

```org
#+title: Source Title
#+date: [YYYY-MM-DD]
#+filetags: :tag1:tag2:
:PROPERTIES:
:SOURCE_TYPE: article
:SOURCE_URL: https://...
:INGESTED: [YYYY-MM-DD]
:END:
```

4. Append an entry to `kb/wiki/log.org`:

```org
** [YYYY-MM-DD] ingest | Source Title
:PROPERTIES:
:SOURCE: kb/raw/articles/filename.org
:END:
```

## Rules

- Never modify raw files after ingestion. Raw is immutable.
- One source per file.
- If the input is a URL, fetch the content and save it. Do not leave URLs as placeholders.
- If the input is Markdown, convert to Org-mode syntax (headings, links, emphasis).
- After ingesting, immediately run the absorb skill to compile into wiki.
