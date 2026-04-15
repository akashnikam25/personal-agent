#!/bin/bash
# rebuild-index.sh — Regenerate wiki/index.md from the filesystem.
# Treats index.md as derived. Safe to run any time.

set -euo pipefail
cd "$(dirname "$0")/.."

WIKI="wiki"
INDEX="$WIKI/index.md"
TODAY=$(date +%Y-%m-%d)

if [ ! -d "$WIKI" ]; then
  echo "No wiki/ directory found. Run setup.sh first."
  exit 1
fi

# Extract a one-line summary: title from frontmatter, fall back to first heading
summarize() {
  local f="$1"
  local title
  title=$(awk '/^---$/{if(++c==2)exit; next} c==1 && /^title:/{sub(/^title:[[:space:]]*/,""); print; exit}' "$f")
  if [ -z "$title" ]; then
    title=$(grep -m1 "^# " "$f" | sed 's/^# //' || true)
  fi
  [ -z "$title" ] && title=$(basename "$f" .md)
  echo "$title"
}

emit_section() {
  local heading="$1"
  local dir="$2"
  echo "## $heading"
  echo ""
  if [ -d "$WIKI/$dir" ] && ls "$WIKI/$dir"/*.md >/dev/null 2>&1; then
    for f in "$WIKI/$dir"/*.md; do
      name=$(basename "$f" .md)
      summary=$(summarize "$f")
      echo "- [[$dir/$name]] — $summary"
    done
  else
    echo "_None yet._"
  fi
  echo ""
}

{
  echo "---"
  echo "title: Wiki Index"
  echo "type: index"
  echo "date_updated: $TODAY"
  echo "---"
  echo ""
  echo "# Wiki Index"
  echo ""
  echo "Master catalog of all pages. **Derived** — rebuilt from filesystem by \`scripts/rebuild-index.sh\`."
  echo ""
  emit_section "Sources" "sources"
  emit_section "Entities" "entities"
  emit_section "Concepts" "concepts"
  emit_section "Analyses" "analyses"
} > "$INDEX"

echo "Rebuilt $INDEX"

# Append to log if it exists
if [ -f "$WIKI/log.md" ]; then
  echo "" >> "$WIKI/log.md"
  echo "## [$TODAY] update | rebuilt index.md from filesystem" >> "$WIKI/log.md"
  echo "Logged to $WIKI/log.md"
fi
