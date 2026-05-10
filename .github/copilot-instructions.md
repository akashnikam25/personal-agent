# Personal Knowledge Base — LLM Wiki Schema

The LLM writes and maintains the wiki. The user curates sources and asks questions.

## Directory Structure

```
personal-agent/
├── raw/          # Immutable source documents — NEVER modify
└── wiki/
    ├── index.md       # Catalog of pages (DERIVED — can be rebuilt from filesystem)
    ├── log.md         # Append-only chronological record of all operations
    ├── overview.md    # Cross-domain synthesis
    ├── state.md       # Current operational context (decisions, focus, preferences)
    ├── sources/       # One .md summary per ingested raw file
    ├── entities/      # People, projects, tools, products
    │   └── .raw/      # Per-entity enrichment data (API responses, fetched pages)
    ├── concepts/      # Ideas, methods, principles, patterns
    └── analyses/      # Substantive query results worth preserving
        └── assets/    # PNG charts, diagrams referenced from analyses
```

## Open-Source Boundaries

- `raw/` and `wiki/` are **gitignored** — personal/proprietary data never leaves the machine
- `CLAUDE.md.template` at root is the open-source version; `setup.sh` copies it to `.claude/CLAUDE.md`
- Anyone who clones gets scaffolding + instructions; they bring their own data

---

## Core Rule: index.md is Fast Lookup, Filesystem is Truth

Use `wiki/index.md` for fast lookup of what's been ingested. But index.md is
**derived** — it can always be rebuilt by scanning the filesystem. If it's ever
out of sync, merge-conflicted, or suspicious, rebuild it (see "Rebuilding
index.md" below). Never hand-curate index.md as if it were authoritative.

The Sources section in `index.md` lists every file that has been processed.

---

## On First Query of the Day — Execute This Flow First

The sync flow below runs **once per day** (on the first user query of the day),
not on every message. This avoids redundant filesystem checks for a single-user
wiki where `raw/` only changes when the user explicitly drops files in.

### When to run the sync flow

Run Steps 0–2 below if **any** of these are true:

1. **First query of the day** — the most recent entry in `wiki/log.md` has a
   date that is not today's date (or the log is empty).
2. **User explicitly requests it** — phrases like "sync", "check raw",
   "re-ingest", "rescan", "what's new", or "did you see the new file".
3. **User mentions adding a file** — e.g. "I just dropped X in raw/" or
   "ingest the new doc."

Otherwise, skip straight to Step 3 (answer from the wiki). Do **not** run the
sync flow on every message.

Quick check for today's date vs. last log entry:

```bash
TODAY=$(date +%Y-%m-%d)
LAST=$(grep -oE "^## \[[0-9]{4}-[0-9]{2}-[0-9]{2}\]" wiki/log.md | tail -1 | tr -d '[]## ')
[[ "$LAST" != "$TODAY" ]] && echo "sync needed"
```

### Step 0: Check if lint is due

Before doing anything else:

```bash
INGESTS=$(grep -c "^## \[.*\] ingest" wiki/log.md 2>/dev/null || echo 0)
LAST_LINT_LINE=$(grep -n "^## \[.*\] lint" wiki/log.md | tail -1 | cut -d: -f1)
LAST_LINT_INGESTS=$(head -n "${LAST_LINT_LINE:-0}" wiki/log.md | grep -c "^## \[.*\] ingest")
SINCE=$((INGESTS - LAST_LINT_INGESTS))
```

If `SINCE >= 10`, schedule a lint pass to run after answering the current query.
Don't block the user's question — answer first, then run lint, then log it.

### Step 1: Detect new or modified files in raw/

1. Read `wiki/index.md` → get the list of all ingested filenames
2. List all files in `raw/` recursively
3. Any file in `raw/` NOT in the index → **unprocessed, must ingest before answering**
4. For each ingested file, compute `sha256sum raw/<filename>` and compare to
   `source_hash` in the wiki source page frontmatter:
   - If different → **re-ingest before answering**
   - If same → skip
   - If `source_hash` is missing (legacy page) → compute and add it on next touch

Hash comparison replaces mtime comparison because git checkouts, cloud sync, and
`cp -p` all mangle mtimes silently.

### Step 2: If unprocessed or modified files exist → Ingest first

#### Step 2a: Surface takeaways before writing (interactive mode)

Before creating any wiki pages, post to the user:

- 3–5 key takeaways from the source
- Proposed new pages: e.g. "I'll create `entities/alice-chen.md` and `concepts/rag-vs-wiki.md`"
- Proposed updates: e.g. "I'll add a cross-ref to `entities/openai.md`"

Wait for confirmation, redirection, or "go ahead." Skip this step only if:

- The user said "batch ingest" or "just process everything"
- More than 3 unprocessed files exist (default to batch mode with a summary at the end)

This restores the human-in-the-loop curation moment that makes the wiki yours,
not the LLM's.

#### Step 2b: Write the pages

1. Read the full source file in `raw/`
2. Compute `sha256sum raw/<filename>` and capture the hash
3. Create `wiki/sources/<kebab-name>.md` (source summary page) with `source_hash` in frontmatter
4. Create or update relevant `wiki/entities/` and `wiki/concepts/` pages
5. Add the file to `wiki/index.md` under Sources
6. Append entry to `wiki/log.md`: `## [YYYY-MM-DD] ingest | filename`
7. Update `wiki/overview.md` if this shifts the big picture

### Step 3: Answer the query from the wiki

1. Read `wiki/index.md` to identify which pages are relevant
2. Read those specific wiki `.md` pages
3. Synthesize the answer using wiki content — never go back to raw/ to answer
4. If the answer synthesizes 2+ pages or reveals a new connection → file it as `wiki/analyses/<n>.md` and update index + log

---

## Query Decision Tree

```
User asks a question
        ↓
Check if lint is due (Step 0)
        ↓
Read wiki/index.md
        ↓
Is the topic in the index?
        ↓
      YES                          NO
       ↓                            ↓
Hash matches raw/ file?        Check raw/ folder
       ↓                       for relevant files
  YES → Read wiki .md               ↓
        and answer             File found?
  NO  → Re-ingest first             ↓
        (with Step 2a)        YES → Ingest first → answer from wiki
                              NO  → Answer from existing wiki or say not found
```

---

## Compounding Knowledge — Three Growth Channels

**1. Ingest compounds:** Every new raw file doesn't just create its own source page. It also updates existing entity and concept pages — adding cross-references, noting contradictions, strengthening the synthesis. One new source may touch 5–10 wiki pages.

**2. Query compounds:** Good answers that synthesize multiple wiki pages get filed as `analyses/` pages. The next similar question gets a pre-built answer. Knowledge doesn't disappear into chat history.

**3. Conversation compounds:** When the user states a preference, decision, or correction during conversation, update the relevant entity or concept page immediately AND append to `state.md`. Log it. That context becomes permanent.

### Handling Contradictions

When new information (from a new source or conversation) contradicts existing wiki content:

- Note the contradiction explicitly on the affected page — cite both the original source and the new source
- Ask the user which is correct if genuinely ambiguous
- Update the page with the resolved information and log it
- Never silently overwrite — contradictions are knowledge too

---

## state.md — Current Operational Context

`wiki/state.md` separates "where I am right now" from "what I know about the world."
Entity and concept pages hold durable facts. `state.md` holds the moving target:
what the user is currently working on, recent decisions, open questions, preferences.

Update `state.md` whenever the user:

- States a current focus ("I'm working on X this week")
- Makes a decision ("I'm going with approach B")
- Expresses a preference ("I prefer markdown tables over bullet lists")
- Flags an open question ("Still figuring out whether to Y")

Structure:

```markdown
---
title: Current State
type: state
date_updated: YYYY-MM-DD
---

# Active Context

## Currently working on

- ...

## Active decisions

- YYYY-MM-DD: <decision> (see [[entities/relevant-page]])

## Open questions

- ...

## Preferences

- ...
```

Always cross-link from state.md to the relevant entity/concept page so the
connection survives even if state.md gets pruned.

---

## overview.md — Cross-Domain Synthesis

`wiki/overview.md` is a living summary of the entire wiki's big picture. Update it when:

- A new source significantly shifts the overall understanding of a domain
- A major new entity or concept is introduced
- A key contradiction is resolved

It should answer: _What does this knowledge base know? What are the dominant themes? What is still uncertain?_

---

## Lint — Periodic Health Check

Run when asked, when Step 0 flags it as due (≥10 ingests since last lint), or
proactively. Check for:

- **Orphan pages** — wiki pages with no inbound `[[wikilinks]]` from other pages
- **Contradictions** — claims on different pages that conflict with each other
- **Stale content** — claims superseded by newer sources but not yet updated
- **Missing concept pages** — concepts mentioned in sources/ or entities/ but lacking their own concepts/ page
- **Index gaps** — pages that exist in wiki/ but are not listed in index.md
- **Data gaps** — claims that are thin, uncertain, or marked TODO; suggest specific web searches or sources the user could drop into raw/ to fill them
- **Missing source_hash** — source pages without a `source_hash` field; compute and add

Log findings and fixes: `## [YYYY-MM-DD] lint | summary of findings`

---

## Rebuilding index.md

If index.md is out of sync, merge-conflicted, or suspicious, regenerate it from
the filesystem. There's a script for this:

```bash
./scripts/rebuild-index.sh
```

Or do it manually:

1. List every `.md` file under `wiki/sources/`, `wiki/entities/`, `wiki/concepts/`, `wiki/analyses/`
2. Read each file's frontmatter (title, date_updated) and the first non-frontmatter paragraph for a one-line summary
3. Rewrite index.md from scratch with all entries grouped by type

This is safe to run any time. Treat index.md as a cache, not a hand-maintained ledger.

---

## Page Conventions

**Frontmatter** (every page):

```yaml
---
title: Page Title
type: source | entity | concept | analysis | state
domain: auto-detected
tags: [relevant, tags]
sources: [raw-filename] # for source pages
source_hash: sha256:abc123… # for source pages — content hash of the raw file
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
- `state.md` — singleton page; current operational context

---

## Per-Entity Enrichment Data (.raw/ sidecars)

When the LLM fetches enrichment data for an entity (e.g., a LinkedIn profile, a
Crunchbase API response, a fetched webpage), save the raw response next to the
entity page:

```
wiki/entities/alice-chen.md
wiki/entities/.raw/alice-chen/
  ├── linkedin-2026-04-15.json
  └── personal-site-2026-04-15.html
```

The entity page synthesizes; the `.raw/` sidecar preserves provenance. Cite the
sidecar file in the entity page's "Sources" section.

`wiki/entities/.raw/` is gitignored alongside `raw/` and `wiki/`.

---

## When to File an Analysis Page

| Situation                                | Action                                         |
| ---------------------------------------- | ---------------------------------------------- |
| Answer synthesizes 2+ wiki pages         | File as `analyses/` page                       |
| Answer reveals a non-obvious connection  | File as `analyses/` page                       |
| User says "save this" or "remember this" | File as `analyses/` page                       |
| User states a preference or decision     | Update relevant entity/concept page + state.md |
| User corrects existing wiki content      | Update page, note contradiction, log it        |
| Simple factual lookup from one page      | Just answer, nothing filed                     |

---

## Answer Formats

Analyses don't have to be markdown prose. Pick the format that fits the question:

- **Comparison** → markdown table inside the analysis page
- **Trend / quantitative** → matplotlib chart, save PNG to `wiki/analyses/assets/`, embed in the .md
- **Walkthrough / pitch** → Marp slide deck (.md with Marp frontmatter)
- **Relationship map** → mermaid diagram inside the analysis page
- **Default** → markdown prose

The analysis `.md` page is always the canonical artifact; other files are embedded
or referenced from it.

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
- **Skip Step 2a (interactive takeaways)** — in batch mode, surface a single summary at the end instead of confirming each file.

---

## Evolving This Schema

CLAUDE.md.template is co-evolved between you and the LLM. Two triggers:

**Proactive (every ~50 ingests):** The LLM should propose schema improvements
based on patterns it has seen — page types that recur, conventions that aren't
captured, friction in the workflow. Surface these as a numbered list; user picks
which to adopt.

**Reactive (when something feels off):** If the user says "this isn't working"
or "let's change how X works," the LLM:

1. Proposes the specific edit to `CLAUDE.md.template`
2. After approval, edits the template
3. Reminds the user to re-run `setup.sh` to propagate to `.claude/CLAUDE.md`,
   `AGENTS.md`, and `.github/copilot-instructions.md`
4. Logs the change: `## [YYYY-MM-DD] update | schema: <what changed and why>`

The schema is part of the wiki's evolution — treat schema edits as first-class
operations, not one-time setup.

---

## Verification

Run `./scripts/verify.sh` at the start of every session and fix any drift before
doing other work. The script checks:

- Every `wiki/sources/*.md` is listed in `index.md`
- Every log entry matches the strict format: `## [YYYY-MM-DD] (ingest|query|lint|update) | …`
- Every entity/concept/analysis/source page has frontmatter
- Every source page has a `source_hash` (warns if missing)

If verify reports drift, fix it manually or rebuild index.md before trusting the
wiki for queries.

---

## Rules

1. **Never modify files in `raw/`** — immutable source of truth
2. **Use index.md for fast lookup, but rebuild it from filesystem when in doubt** — it's derived
3. **Ingest before answering** — if raw/ has new or modified files, ingest them first
4. **Always update index.md and log.md** after any ingest or analysis page creation
5. **Answer from the wiki, not from raw/** — wiki is the compiled, enriched layer
6. **Auto-detect domain** — never ask the user to categorize
7. **Log entry format is strict** — every log entry must start with `## [YYYY-MM-DD] operation | title` where operation is one of: `ingest`, `query`, `lint`, `update`. This makes the log grep-parseable.
8. **Log all four operation types** — not just ingests. Log substantive queries that produce analyses/ pages, every lint pass, and every schema update.
9. **Never silently overwrite contradictions** — note them explicitly on the affected page, cite both sources
10. **File good answers back** — substantive query results become analyses/ pages
11. **Discuss before writing** (interactive mode) — surface takeaways and proposed pages before touching the wiki
12. **Hash, don't trust mtime** — use `sha256sum` to detect re-ingest needs
13. **Update state.md on decisions and preferences** — it's the operational layer separate from world knowledge
14. **Run verify.sh at session start** — catch drift early
15. **Sync files one at a time when there are many** — if there are multiple unprocessed files, ingest them sequentially (one file fully completed before starting the next) to avoid getting stuck mid-way through a large batch
