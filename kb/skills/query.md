# Skill: Query

Answer questions using the knowledge base. Read-only navigation through the wiki.

## Workflow

1. Read `kb/wiki/index.org` to find relevant pages.
2. Read the relevant wiki pages (above-the-line content is primary, below-the-line for evidence).
3. Follow cross-reference links to gather related context.
4. Synthesize an answer with citations to specific wiki pages.

## Output Formats

Choose based on the question:
- **Short answer**: Direct text response with page citations.
- **Org file**: For complex answers worth keeping. Save to `kb/artifacts/`.
- **Comparison table**: For "X vs Y" questions.
- **List**: For "what are all the..." questions.

## Output Reflow

When an answer is substantial and worth preserving:
1. Save the output as an `.org` file in `kb/artifacts/`.
2. Consider whether the answer reveals insights that should be absorbed back into relevant wiki pages.
3. Append a log entry:

```org
** [YYYY-MM-DD] query | Question summary
:PROPERTIES:
:OUTPUT: kb/artifacts/filename.org
:PAGES_READ: page1.org, page2.org
:END:
```

## Rules

- Never modify wiki pages during a query. Query is read-only.
- Always cite which wiki pages your answer draws from.
- If you cannot answer from the wiki alone, say so. Suggest what sources to ingest.
- Prefer depth over breadth — read fewer pages thoroughly rather than many superficially.
