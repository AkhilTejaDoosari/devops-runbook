#!/bin/bash
REPO="$HOME/Repositories/devops-runbook"
OUTPUT="$REPO/exports/all-notes.md"
mkdir -p "$REPO/exports"
rm -f "$OUTPUT"
for dir in "$REPO/notes"/*/*/; do
  folder=$(basename "$dir")
  tool=$(basename "$(dirname "$dir")")
  src="$dir/README.md"
  if [ -f "$src" ]; then
    echo "---" >> "$OUTPUT"
    echo "# TOOL: $tool | FILE: $folder" >> "$OUTPUT"
    echo "---" >> "$OUTPUT"
    echo "" >> "$OUTPUT"
    cat "$src" >> "$OUTPUT"
    echo "" >> "$OUTPUT"
  fi
done
echo "✅ All notes merged into exports/all-notes.md"
echo "📄 Size: $(wc -l < "$OUTPUT") lines"
