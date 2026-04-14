# Personal Knowledge Base — LLM Wiki Schema

The LLM writes and maintains the wiki. The user curates sources and asks questions.

## Directory Structure

```
personal-agent/
├── raw/          # Immutable source documents — NEVER modify
└── wiki/
    ├── index.md      # Single source of truth for what's been ingested
    ├── log.md        # Append-only chronological record of all operations
    ├── overview.md   # Cross-domain synthesis
    ├── sources/      # One .md summary per ingested raw file
    ├── entities/     # People, projects, tools, products
    ├── concepts/     # Ideas, methods, principles, patterns
    └── analyses/     # Substantive query results worth preserving
```

## Open-Source Boundaries

- `raw/` and `wiki/` are **gitignored** — personal/proprietary data never leaves the machine
- `CLAUDE.md.template` at root is the open-source version; `setup.sh` copies it to `.claude/CLAUDE.md`
- Anyone who clones gets scaffolding + instructions; they bring their own data

---

## Core Rule: index.md is the Only Source of Truth

Never scan `wiki/sources/` to check what's been ingested. Only read `wiki/index.md`.
The Sources section in `index.md` lists every file that has been processed.

---

## On Every Query — Execute This Flow First

### Step 1: Detect new or modified files in raw/

1. Read `wiki/index.md` → get the list of all ingested filenames
2. List all files in `raw/` recursively
3. Any file in `raw/` NOT in the index → **unprocessed, must ingest before answering**
4. Any file in `raw/` whose last-modified date is newer than `date_updated` in its wiki source page → **re-ingest before answering**

### Step 2: If unprocessed or modified files exist → Ingest first

1. Read the full source file in `raw/`
2. Create `wiki/sources/<kebab-name>.md` (source summary page)
3. Create or update relevant `wiki/entities/` and `wiki/concepts/` pages
4. Add the file to `wiki/index.md` under Sources
5. Append entry to `wiki/log.md`: `## [YYYY-MM-DD] ingest | filename`
6. Update `wiki/overview.md` if this shifts the big picture

### Step 3: Answer the query from the wiki

1. Read `wiki/index.md` to identify which pages are relevant
2. Read those specific wiki `.md` pages
3. Synthesize the answer using wiki content — never go back to raw/ to answer
4. If the answer synthesizes 2+ pages or reveals a new connection → file it as `wiki/analyses/<name>.md` and update index + log

---

## Query Decision Tree

```
User asks a question
        ↓
Read wiki/index.md
        ↓
Is the topic in the index?
        ↓
      YES                          NO
       ↓                            ↓
Check raw/ file's              Check raw/ folder
last-modified date             for relevant files
       ↓                            ↓
Newer than date_updated?      File found?
       ↓                            ↓
  YES → Re-ingest first        YES → Ingest first → answer from wiki
  NO  → Read wiki .md          NO  → Answer from existing wiki or say not found
        and answer
```

---

## Compounding Knowledge — Three Growth Channels

**1. Ingest compounds:** Every new raw file doesn't just create its own source page. It also updates existing entity and concept pages — adding cross-references, noting contradictions, strengthening the synthesis. One new source may touch 5–10 wiki pages.

**2. Query compounds:** Good answers that synthesize multiple wiki pages get filed as `analyses/` pages. The next similar question gets a pre-built answer. Knowledge doesn't disappear into chat history.

**3. Conversation compounds:** When the user states a preference, decision, or correction during conversation, update the relevant entity or concept page immediately. Log it. That context becomes permanent.

### Handling Contradictions

When new information (from a new source or conversation) contradicts existing wiki content:

- Note the contradiction explicitly on the affected page — cite both the original source and the new source
- Ask the user which is correct if genuinely ambiguous
- Update the page with the resolved information and log it
- Never silently overwrite — contradictions are knowledge too

---

## overview.md — Cross-Domain Synthesis

`wiki/overview.md` is a living summary of the entire wiki's big picture. Update it when:

- A new source significantly shifts the overall understanding of a domain
- A major new entity or concept is introduced
- A key contradiction is resolved

It should answer: _What does this knowledge base know? What are the dominant themes? What is still uncertain?_

---

## Lint — Periodic Health Check

Run when asked, or proactively every ~10 ingests. Check for:

- **Orphan pages** — wiki pages with no inbound `[[wikilinks]]` from other pages
- **Contradictions** — claims on different pages that conflict with each other
- **Stale content** — claims superseded by newer sources but not yet updated
- **Missing concept pages** — concepts mentioned in sources/ or entities/ but lacking their own concepts/ page
- **Index gaps** — pages that exist in wiki/ but are not listed in index.md

Log findings and fixes: `## [YYYY-MM-DD] lint | summary of findings`

---

## Page Conventions

**Frontmatter** (every page):

```yaml
---
title: Page Title
type: source | entity | concept | analysis
domain: auto-detected
tags: [relevant, tags]
sources: [raw-filename]
date_created: YYYY-MM-DD
date_updated: YYYY-MM-DD
---
```

**Filenames:** kebab-case, no spaces. E.g. `my-concept.md`
**Links:** Obsidian wikilinks `[[page-name]]` — use liberally, connections matter.

**Page types:**

- `sources/` — what the raw file is, key takeaways, links to entities/concepts it informed
- `entities/` — a person, tool, project, or product; attributes + relationships
- `concepts/` — an idea, method, or pattern; definition + where it appears
- `analyses/` — a synthesized answer or comparison; the question, the analysis, conclusions

---

## When to File an Analysis Page

| Situation                                | Action                                  |
| ---------------------------------------- | --------------------------------------- |
| Answer synthesizes 2+ wiki pages         | File as `analyses/` page                |
| Answer reveals a non-obvious connection  | File as `analyses/` page                |
| User says "save this" or "remember this" | File as `analyses/` page                |
| User states a preference or decision     | Update relevant entity/concept page     |
| User corrects existing wiki content      | Update page, note contradiction, log it |
| Simple factual lookup from one page      | Just answer, nothing filed              |

---

## Handling Images in raw/

- Images dropped in `raw/` are sources too
- Standalone image → create a `wiki/sources/` page describing it; embed with relative path
- Image alongside a document → include it in that document's source summary
- Embed syntax: `![description](../../raw/folder/image.jpg)` (relative from wiki/ to raw/)

---

## Handling Binary Files in raw/

- **.docx**: Extract text using `python3` with `zipfile` + `xml.etree.ElementTree` (docx files are zipped XML). Then process the extracted text as a normal source.
- **.pdf**: Readable directly by the LLM. Process as a normal source.
- **.zip**: If extracted contents already exist alongside the zip (e.g. `raw/folder.zip` + `raw/folder/`), skip the zip — it's a duplicate. If only the zip exists, extract first, then ingest the contents.
- **.xlsx/.pptx**: Same zip-of-XML approach as .docx. For .xlsx, focus on sheet data; for .pptx, focus on slide text.
- **Unsupported formats**: If a binary file can't be read by any available method, log it as skipped with the reason.

---

## Batch Ingest

When multiple unprocessed files exist in `raw/`:

- **Related files in the same folder** (e.g. 10 config files in `raw/my-project/`): Group into a single source summary if they form a coherent set. One source page with subsections beats 10 thin pages.
- **Unrelated files**: Ingest one at a time, highest-value first (relevance to existing wiki content or user's active domains).
- **Duplicates**: If a `.zip` and its extracted contents both exist, skip the `.zip`. If two files contain the same content in different formats, ingest the richer format and note the duplicate in the log.

---

## Rules

1. **Never modify files in `raw/`** — immutable source of truth
2. **Always check index.md first** — never scan wiki/sources/ to detect ingested files
3. **Ingest before answering** — if raw/ has new or modified files, ingest them first
4. **Always update index.md and log.md** after any ingest or analysis page creation
5. **Answer from the wiki, not from raw/** — wiki is the compiled, enriched layer
6. **Auto-detect domain** — never ask the user to categorize
7. **Log entry format is strict** — every log entry must start with `## [YYYY-MM-DD] operation | title` where operation is one of: `ingest`, `query`, `lint`, `update`. This makes the log grep-parseable.
8. **Log all three operation types** — not just ingests. Log substantive queries that produce analyses/ pages, and every lint pass.
9. **Never silently overwrite contradictions** — note them explicitly on the affected page, cite both sources
10. **File good answers back** — substantive query results become analyses/ pages
