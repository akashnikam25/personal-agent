# LLM Wiki — Personal Knowledge Base

A pattern for building personal knowledge bases maintained by LLMs. Drop documents into `raw/`, and your LLM agent (Claude Code, Codex, etc.) incrementally builds a structured, interlinked wiki — summarizing, cross-referencing, and maintaining it automatically.

## How It Works

```
You drop files here          LLM builds this              You browse here
─────────────────           ──────────────────           ──────────────────
raw/                   →    wiki/                   →    Obsidian / any
  article.pdf                 sources/                   markdown viewer
  project-docs/               entities/
  random-notes.md             concepts/
                              analyses/
                              index.md
                              overview.md
```

1. **Drop** any document (`.md`, `.pdf`, `.txt`) into `raw/`
2. **Start a conversation** with your LLM agent — it auto-detects new files and ingests them
3. **The wiki compounds** — every source updates entity pages, concept pages, cross-references, and the index
4. **Ask questions** — the LLM reads the wiki to answer, and good answers get filed back as analysis pages

No manual categorization needed. No folder structure required. Just drop files and chat.

## Quick Start

```bash
# Clone the repo
git clone https://github.com/YOUR_USERNAME/personal-agent.git
cd personal-agent

# Create the scaffolding (copies CLAUDE.md.template → .claude/CLAUDE.md)
./setup.sh

# Drop your first source document — anywhere in raw/, no categorization needed
cp ~/Downloads/interesting-article.pdf raw/

# Open a Claude Code session (or your preferred LLM agent)
claude

# The agent auto-detects the new file and ingests it
```

## How It Compounds

The wiki doesn't just grow from source ingestion — **conversations compound it too.**

```
Day 1:  Drop 3 articles into raw/ → LLM creates 3 source summaries,
        5 concept pages, 2 entity pages, all cross-linked

Day 3:  Ask "how does X compare to Y?" → LLM synthesizes from wiki pages
        → good answer filed as wiki/analyses/x-vs-y.md

Day 5:  Drop 2 more articles → LLM updates existing entity/concept pages,
        notes where new data contradicts old claims

Day 10: You mention "I decided to go with approach B" in conversation
        → LLM updates the relevant entity page with your decision

Day 30: Ask a question → LLM draws from 15 source summaries, 8 concept pages,
        3 prior analyses. The 30th answer is better than the 1st because
        the cross-references and synthesis already exist.
```

## Works With Any LLM Agent

The wiki schema is provided to three agents via their native instruction files:

| Agent | Instruction file | Source |
|---|---|---|
| **Claude Code** | `.claude/CLAUDE.md` | `setup.sh` copies from `CLAUDE.md.template` |
| **GitHub Copilot** | `.github/copilot-instructions.md` | Tracked in git |
| **OpenAI Codex** | `AGENTS.md` | Tracked in git |

All three files have identical content. `CLAUDE.md.template` is the source of truth — edit it and re-run `setup.sh` to sync.

On every session, the agent will:

1. Check `wiki/index.md` for what's already ingested
2. Scan `raw/` for unprocessed files — auto-ingest any new ones
3. Answer questions using the wiki, filing good answers back as analysis pages
4. Update entity/concept pages when you reveal preferences or decisions

## Using with Obsidian

Open the `wiki/` folder as an Obsidian vault. You'll get:
- Clickable `[[wikilinks]]` between all pages
- Graph view showing the full knowledge network
- Backlinks showing which pages reference each other
- Dataview queries over YAML frontmatter (if you install the Dataview plugin)

## Architecture

See [llmwiki.md](llmwiki.md) for the full pattern description. In short:

| Layer | What | Who Owns It |
|---|---|---|
| **Raw sources** (`raw/`) | Your documents — articles, PDFs, notes | You (immutable) |
| **Wiki** (`wiki/`) | Summaries, entities, concepts, analyses | LLM (generated) |
| **Schema** (`CLAUDE.md.template`) | Conventions, workflows, page types | You + LLM (co-evolved) |

The schema is distributed to each agent via its native instruction file (`.claude/CLAUDE.md`, `.github/copilot-instructions.md`, `AGENTS.md`).

## Privacy

`raw/` and `wiki/` are **gitignored** — your personal data never leaves your machine. Only the scaffolding, schema, and pattern documentation are in the repo.

## Adapting to Your Domain

The schema in `.claude/CLAUDE.md` is designed to be generic. Domains are auto-detected from content. Some examples of what you might build:

- **Research** — papers, articles, reports → evolving thesis wiki
- **Book notes** — chapters → character, theme, and plot thread pages
- **Business** — meeting notes, Slack exports, customer calls → team knowledge base
- **Health** — diet plans, lab results, workout logs → personal health wiki
- **Learning** — course materials, tutorials → structured study notes

## License

MIT
