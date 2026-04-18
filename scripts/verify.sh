#!/bin/bash
# verify.sh — Check wiki invariants. Run at session start or in CI.
# Exits 0 if clean, 1 if drift detected.

set -u
cd "$(dirname "$0")/.."

WIKI="wiki"
ERRORS=0
WARNINGS=0

red()    { printf '\033[0;31m%s\033[0m\n' "$*"; }
yellow() { printf '\033[0;33m%s\033[0m\n' "$*"; }
green()  { printf '\033[0;32m%s\033[0m\n' "$*"; }

if [ ! -d "$WIKI" ]; then
  yellow "No wiki/ directory found. Run setup.sh first."
  exit 0
fi

echo "Verifying wiki invariants..."
echo ""

# Check 1: every wiki/sources/*.md is referenced in index.md
echo "[1/4] Checking sources are listed in index.md..."
if [ -d "$WIKI/sources" ] && [ -f "$WIKI/index.md" ]; then
  for f in "$WIKI"/sources/*.md; do
    [ -e "$f" ] || continue
    name=$(basename "$f" .md)
    if ! grep -qF "$name" "$WIKI/index.md"; then
      red "  MISSING: sources/$name.md not in index.md"
      ERRORS=$((ERRORS + 1))
    fi
  done
fi

# Check 2: log entries match strict format
echo "[2/4] Checking log.md entry format..."
if [ -f "$WIKI/log.md" ]; then
  bad=$(grep "^## \[" "$WIKI/log.md" \
        | grep -vE "^## \[20[0-9]{2}-[0-9]{2}-[0-9]{2}\] (ingest|query|lint|update|init) \| " \
        || true)
  if [ -n "$bad" ]; then
    red "  Malformed log entries:"
    echo "$bad" | sed 's/^/    /'
    ERRORS=$((ERRORS + 1))
  fi
fi

# Check 3: every entity/concept/analysis/source page has frontmatter
echo "[3/4] Checking pages have frontmatter..."
for dir in sources entities concepts analyses; do
  [ -d "$WIKI/$dir" ] || continue
  for f in "$WIKI/$dir"/*.md; do
    [ -e "$f" ] || continue
    if ! head -1 "$f" | grep -q "^---$"; then
      red "  MISSING frontmatter: $f"
      ERRORS=$((ERRORS + 1))
    fi
  done
done

# Check 4: source pages should have source_hash
echo "[4/4] Checking source pages have source_hash..."
if [ -d "$WIKI/sources" ]; then
  for f in "$WIKI"/sources/*.md; do
    [ -e "$f" ] || continue
    if ! grep -q "^source_hash:" "$f"; then
      yellow "  WARN: $f missing source_hash (will be added on next touch)"
      WARNINGS=$((WARNINGS + 1))
    fi
  done
fi

echo ""
if [ "$ERRORS" -eq 0 ] && [ "$WARNINGS" -eq 0 ]; then
  green "OK — wiki is clean."
  exit 0
elif [ "$ERRORS" -eq 0 ]; then
  yellow "OK with $WARNINGS warning(s)."
  exit 0
else
  red "FAIL — $ERRORS error(s), $WARNINGS warning(s)."
  echo "Fix manually or run ./scripts/rebuild-index.sh to regenerate index.md."
  exit 1
fi
