#!/bin/bash

# Run this from the ROOT of your devops-runbook repo
# Usage: bash fix-all-readmes.sh

echo "=== Fixing all README files ==="

# 1. Fix root README link in all tool home READMEs (one level: notes/XX. Tool/README.md)
# These currently say [Home](../README.md) — needs to go up one more level
for folder in notes/*/; do
  readme="$folder/README.md"
  if [ -f "$readme" ]; then
    # Fix Home link
    sed -i '' 's|\[Home\](../README.md)|[← devops-runbook](../../README.md)|g' "$readme"
    # Fix banner path — one level deep tool READMEs need ../../assets/
    sed -i '' 's|src="../assets/|src="../../assets/|g' "$readme"
    # Fix any remaining [Home] labels
    sed -i '' 's|\[Home\]|[← devops-runbook]|g' "$readme"
    echo "Fixed: $readme"
  fi
done

# 2. Fix all notes files inside tool subfolders (two levels: notes/XX. Tool/XX-topic/README.md)
for readme in notes/*/*/README.md; do
  if [ -f "$readme" ]; then
    # Fix Home link pointing to root
    sed -i '' 's|\[Home\](../../README.md)|[← devops-runbook](../../../README.md)|g' "$readme"
    sed -i '' 's|\[Home\](../README.md)|[← devops-runbook](../../README.md)|g' "$readme"
    # Fix any remaining [Home] labels
    sed -i '' 's|\[🏠 Home\](../README.md)|[← devops-runbook](../../README.md)|g' "$readme"
    sed -i '' 's|\[🏠 Home\]|[← devops-runbook]|g' "$readme"
    sed -i '' 's|\[Home\]|[← devops-runbook]|g' "$readme"
    echo "Fixed: $readme"
  fi
done

# 3. Fix lab files inside tool subfolders
for readme in notes/*/*/README.md notes/*/*-labs/*.md notes/*/k8s-labs/*.md notes/*/git-labs/*.md notes/*/linux-labs/*.md notes/*/docker-labs/*.md notes/*/networking-labs/*.md; do
  if [ -f "$readme" ]; then
    sed -i '' 's|\[🏠 Home\](../README.md)|[← devops-runbook](../../README.md)|g' "$readme"
    sed -i '' 's|\[Home\](../README.md)|[← devops-runbook](../../README.md)|g' "$readme"
    sed -i '' 's|\[🏠 Home\]|[← devops-runbook]|g' "$readme"
    sed -i '' 's|\[Home\]|[← devops-runbook]|g' "$readme"
  fi
done

echo ""
echo "=== Verifying — searching for leftover [Home] links ==="
grep -r '\[Home\]\|\[🏠 Home\]' notes/ --include="*.md" | grep -v "Binary"

echo ""
echo "=== Done. Now run: ==="
echo "git add ."
echo "git commit -m 'docs: fix all README links and replace Home with devops-runbook'"
echo "git push"
