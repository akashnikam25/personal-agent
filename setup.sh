#!/bin/bash
# Setup script for LLM Wiki
# Creates the directory scaffolding for a new knowledge base.

set -e

echo "Setting up LLM Wiki scaffolding..."

# Create directories
mkdir -p raw
mkdir -p wiki/sources
mkdir -p wiki/entities/.raw
mkdir -p wiki/concepts
mkdir -p wiki/analyses/assets
mkdir -p .claude
mkdir -p .github
mkdir -p scripts

# Copy schema template to all agent instruction locations
if [ -f CLAUDE.md.template ]; then
  if [ ! -f .claude/CLAUDE.md ]; then
    cp CLAUDE.md.template .claude/CLAUDE.md
    echo "  Created .claude/CLAUDE.md (Claude Code)"
  else
    cp CLAUDE.md.template .claude/CLAUDE.md
    echo "  Updated .claude/CLAUDE.md (Claude Code)"
  fi

  cp CLAUDE.md.template AGENTS.md
  echo "  Synced AGENTS.md (OpenAI Codex)"

  cp CLAUDE.md.template .github/copilot-instructions.md
  echo "  Synced .github/copilot-instructions.md (GitHub Copilot)"
else
  echo "  WARNING: CLAUDE.md.template not found — create agent instructions manually"
fi

# Make scripts executable if present
for s in scripts/verify.sh scripts/rebuild-index.sh; do
  if [ -f "$s" ]; then
    chmod +x "$s"
    echo "  Made $s executable"
  fi
done

# Create index.md if it doesn't exist
if [ ! -f wiki/index.md ]; then
cat > wiki/index.md << EOF
---
title: Wiki Index
type: index
date_updated: $(date +%Y-%m-%d)
---

# Wiki Index

Master catalog of all pages. **Derived** — rebuilt from filesystem by \`scripts/rebuild-index.sh\`.

## Sources

_No sources ingested yet._

## Entities

_No entity pages yet._

## Concepts

_No concept pages yet._

## Analyses

_No analyses yet._
EOF
echo "  Created wiki/index.md"
fi

# Create log.md if it doesn't exist
if [ ! -f wiki/log.md ]; then
cat > wiki/log.md << EOF
---
title: Wiki Log
type: log
date_updated: $(date +%Y-%m-%d)
---

# Wiki Log

Chronological record of all wiki operations.

---

## [$(date +%Y-%m-%d)] init | Wiki initialized

Scaffolding created via setup.sh. Ready for first ingest.
EOF
echo "  Created wiki/log.md"
fi

# Create overview.md if it doesn't exist
if [ ! -f wiki/overview.md ]; then
cat > wiki/overview.md << EOF
---
title: Knowledge Base Overview
type: overview
date_created: $(date +%Y-%m-%d)
date_updated: $(date +%Y-%m-%d)
---

# Knowledge Base Overview

_This overview will be populated as sources are ingested._
EOF
echo "  Created wiki/overview.md"
fi

# Create state.md if it doesn't exist
if [ ! -f wiki/state.md ]; then
cat > wiki/state.md << EOF
---
title: Current State
type: state
date_updated: $(date +%Y-%m-%d)
---

# Active Context

Operational state — separate from world knowledge in entities/ and concepts/.
The LLM updates this when you state decisions, focus, or preferences.

## Currently working on

_Nothing logged yet._

## Active decisions

_None yet._

## Open questions

_None yet._

## Preferences

_None yet._
EOF
echo "  Created wiki/state.md"
fi

# Update .gitignore
GITIGNORE=".gitignore"
touch "$GITIGNORE"
for pattern in "raw/" "wiki/" "wiki/entities/.raw/" ".claude/CLAUDE.md"; do
  if ! grep -qxF "$pattern" "$GITIGNORE"; then
    echo "$pattern" >> "$GITIGNORE"
    echo "  Added $pattern to .gitignore"
  fi
done

echo ""
echo "Done! Next steps:"
echo "  1. Drop documents into raw/"
echo "  2. Start a Claude Code session: claude"
echo "  3. The agent will auto-detect and ingest new files"
echo ""
echo "  Run ./scripts/verify.sh anytime to check wiki invariants."
echo "  Run ./scripts/rebuild-index.sh if index.md ever gets out of sync."
echo ""
echo "  Optional: Open wiki/ in Obsidian for graph view"
