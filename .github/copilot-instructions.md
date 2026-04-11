# Personal Knowledge Base — LLM Wiki Schema

A personal knowledge base maintained by LLMs using the LLM Wiki pattern. The LLM writes and maintains the wiki; the user curates sources and directs exploration.

## Directory Structure

```
personal-agent/
├── .claude/CLAUDE.md      # This file — wiki schema and conventions
├── llmwiki.md             # Pattern documentation (reference, open-source)
├── raw/                   # Immutable source documents (gitignored, never push)
├── wiki/                  # LLM-maintained wiki (gitignored, never push)
│   ├── index.md           # Single source of truth for what's been ingested
│   ├── log.md             # Chronological record of all operations
│   ├── overview.md        # Cross-domain synthesis
│   ├── sources/           # One summary per ingested source
│   ├── entities/          # People, projects, tools, products
│   ├── concepts/          # Ideas, methods, principles, patterns
│   └── analyses/          # Comparisons, syntheses, query results filed from conversations
```

## Open-Source Boundaries

- `raw/` and `wiki/` are **gitignored** — personal/proprietary data never leaves the machine
- `CLAUDE.md.template` at root is the open-source version; `setup.sh` copies it to `.claude/CLAUDE.md`
- Anyone who clones gets scaffolding + instructions; they bring their own data

---

## Auto-Ingest: Detecting New Files

**On every new conversation, check for unprocessed sources before doing anything else.**

### How to detect: index.md is the single source of truth

1. Read `wiki/index.md` — the Sources section lists every ingested file with its `[[page-name]]`
2. List all files in `raw/` recursively (any depth, any subfolder)
3. Any file in `raw/` whose name does NOT appear in the index Sources section → unprocessed
4. If a file was modified after its source summary's `date_updated` → flag for re-ingestion

Do NOT scan `wiki/sources/` directory separately. The index is the only place to check.

### Ingesting uncategorized files

Files can be dropped anywhere in `raw/` — root, existing subfolder, new subfolder. No categorization required.

- `raw/some-article.md` → ingest, auto-detect domain from content
- `raw/new-project/design-doc.md` → ingest, use folder name as domain hint
- `raw/random-notes.pdf` → ingest, classify from content

For each unprocessed file, follow the Ingest workflow below.

### Handling images

Images (`.png`, `.jpg`, `.jpeg`, `.gif`, `.svg`, `.webp`) dropped in `raw/` are treated as sources too.

**Standalone images** (e.g. `raw/progress-photo.jpg`, `raw/whiteboard-sketch.png`):
1. View the image to understand its content
2. Create a source summary in `wiki/sources/` describing what the image shows
3. Embed the image in the source summary and any relevant entity/concept pages using relative path: `![description](../../raw/path/to/image.jpg)`
4. Auto-detect domain from the image content
5. Update index and log as usual

**Images alongside documents** (e.g. `raw/my-project/diagram.png` next to `raw/my-project/notes.md`):
1. When ingesting the document, also view related images in the same folder
2. Embed relevant images in the source summary and wiki pages
3. Images don't need their own separate source summary — they're part of the document's ingest

**Image embedding syntax** (Obsidian-compatible):
```markdown
![Description of image](../../raw/folder/image-name.jpg)
```

Use relative paths from `wiki/` to `raw/` so images render in Obsidian when both folders are in the same vault root.

---

## Compounding: How Conversations Build the Wiki

The wiki doesn't just grow from source ingestion — **conversations compound knowledge too.** This is the key insight from the LLM Wiki pattern.

### Query → Analysis page (filing good answers back)

When a user asks a question and the answer is substantive, the LLM files it as an analysis page:

**Example flow:**
```
User: "How does the calorie surplus in my diet plan compare to standard lean bulk recommendations?"

LLM: [reads wiki pages, synthesizes answer]

→ Answer is substantial and reusable
→ Create: wiki/analyses/surplus-vs-standard-lean-bulk.md
→ Update index.md under Analyses
→ Log: "## [2026-04-15] query | Calorie surplus vs standard lean bulk"
→ Future questions about diet or bulking now find this page
```

**When to file an analysis page:**
- The answer synthesizes information from 2+ wiki pages
- The answer reveals a connection not explicitly stated in any source
- The answer would be useful if someone asked a similar question later
- The user explicitly says "save this" or "remember this"

**When NOT to file:**
- Simple factual lookups ("what's my daily calorie target?")
- The answer just quotes a single source page
- Ephemeral/debugging questions

### User preferences and context (compounding from conversation)

When the user reveals preferences, decisions, or context during conversation, update the relevant entity/concept pages:

**Example flow:**
```
User: "I'm now targeting 80kg by end of the 100 days"

→ Update relevant entity page with the new target
→ Log: "## [2026-04-15] update | Target weight set to 80kg"
```

### Contradictions from conversation

When new information from conversation contradicts existing wiki content:
- Note the contradiction explicitly on the affected page
- Cite both the original source and the conversation date
- Ask the user which is correct if ambiguous
- Update the page with the resolved information

### What conversations produce

| Conversation type | Wiki output |
|---|---|
| Question spanning multiple pages | Analysis page filed |
| User states a preference/decision | Entity or concept page updated |
| User provides new information | Relevant pages updated + logged |
| User says "save/remember this" | Analysis page or entity update |
| Comparison or synthesis request | Analysis page filed |
| Simple lookup | Nothing filed (just answered) |

---

## Page Conventions

### Frontmatter (YAML)
Every wiki page starts with:
```yaml
---
title: Page Title
type: source | entity | concept | analysis
domain: auto-detected-from-content
tags: [relevant, tags]
sources: [original-filename-in-raw]
date_created: YYYY-MM-DD
date_updated: YYYY-MM-DD
---
```

### Naming
- Filenames: kebab-case, e.g. `my-concept-name.md`
- Links: Obsidian-style wikilinks `[[page-name]]` for cross-references
- No spaces in filenames

### Page Types

**Source summary** (`wiki/sources/`) — one per raw source ingested. Contains: what the source is, key takeaways, important data points, and links to entity/concept pages it informed.

**Entity page** (`wiki/entities/`) — a person, project, tool, product, or organization. Contains: what it is, key attributes, relationships to other entities, and references to sources.

**Concept page** (`wiki/concepts/`) — an idea, methodology, principle, or pattern. Contains: definition, how it works, where it appears, connections to other concepts, and sources.

**Analysis page** (`wiki/analyses/`) — a comparison, synthesis, or answer to a query worth preserving. Contains: the question or purpose, the analysis, conclusions, and sources used. **This is where conversations compound.**

## Workflows

### Ingest (processing a new source)

1. Read the full source document in `raw/`
2. Auto-detect domain from content (or ask user if truly ambiguous)
3. Create a source summary page in `wiki/sources/`
4. Create or update entity pages for any people, projects, tools mentioned
5. Create or update concept pages for key ideas, methods, patterns
6. Update `wiki/index.md` with new/updated pages
7. Append entry to `wiki/log.md`
8. Update `wiki/overview.md` if the source shifts the big picture

### Query (answering a question)

1. Read `wiki/index.md` to identify relevant pages
2. Read the relevant wiki pages
3. Synthesize an answer with `[[wikilinks]]` to sources
4. If the answer is substantial and reusable → file as analysis page in `wiki/analyses/`
5. If the user revealed new info/preferences → update relevant entity/concept pages
6. Update index and log for any changes

### Lint (health check)

Run periodically or when user asks. Check for:
- Unprocessed files in `raw/` (compare against index Sources section)
- Orphan pages (no inbound links)
- Broken wikilinks
- Stale information
- Missing pages (concepts mentioned but lacking their own page)
- Index completeness
- Cross-reference gaps

Log findings and fixes in `wiki/log.md`.

## Domains

Auto-detected from content. Never ask the user to categorize manually.

Domains are created automatically when the first source for a topic is ingested. Examples: `fitness`, `research`, `business`, `learning`.

## Rules

- Never modify files in `raw/` — they are immutable source documents
- `index.md` is the single source of truth for what's been ingested — always check there
- Always update `index.md` and `log.md` when creating or updating wiki pages
- Use wikilinks liberally — connections are as valuable as pages
- When new info contradicts existing wiki content, note the contradiction and cite both sources
- Keep source summaries factual; save opinions and synthesis for analysis pages
- Date all log entries with ISO format: `[YYYY-MM-DD]`
- Auto-detect domain — never require manual categorization
- Files can live anywhere in `raw/` — subfolders are optional hints, not requirements
- File good answers back as analysis pages — this is how conversations compound
