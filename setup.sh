#!/bin/bash
# Setup script for LLM Wiki
# Creates the directory scaffolding for a new knowledge base

set -e

echo "Setting up LLM Wiki scaffolding..."

# Create directories
mkdir -p raw
mkdir -p wiki/sources
mkdir -p wiki/entities
mkdir -p wiki/concepts
mkdir -p wiki/analyses
mkdir -p .claude
mkdir -p .github

# Copy schema template to all agent instruction locations
if [ -f CLAUDE.md.template ]; then
  if [ ! -f .claude/CLAUDE.md ]; then
    cp CLAUDE.md.template .claude/CLAUDE.md
    echo "  Created .claude/CLAUDE.md (Claude Code)"
  else
    echo "  .claude/CLAUDE.md already exists, skipping"
  fi

  # AGENTS.md and copilot-instructions.md are tracked by git,
  # so they should already exist. Only create if missing.
  if [ ! -f AGENTS.md ]; then
    cp CLAUDE.md.template AGENTS.md
    echo "  Created AGENTS.md (OpenAI Codex)"
  fi

  if [ ! -f .github/copilot-instructions.md ]; then
    cp CLAUDE.md.template .github/copilot-instructions.md
    echo "  Created .github/copilot-instructions.md (GitHub Copilot)"
  fi
else
  echo "  WARNING: CLAUDE.md.template not found — create agent instructions manually"
fi

# Create index.md if it doesn't exist
if [ ! -f wiki/index.md ]; then
cat > wiki/index.md << EOF
---
title: Wiki Index
type: index
date_updated: $(date +%Y-%m-%d)
---

# Wiki Index

Master catalog of all pages in this knowledge base. Updated on every ingest.

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

echo ""
echo "Done! Next steps:"
echo "  1. Drop documents into raw/"
echo "  2. Start a Claude Code session: claude"
echo "  3. The agent will auto-detect and ingest new files"
echo ""
echo "  Optional: Open wiki/ in Obsidian for graph view"
