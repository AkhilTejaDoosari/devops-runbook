#!/bin/bash
# Run from the ROOT of your devops-runbook repo
# Restores correct 3-level navigation structure

echo "=== Restoring correct nav structure ==="

# Individual notes files inside tool subfolders
# These should link back to their TOOL README (../README.md)
# Currently broken — the script changed them to [← devops-runbook]
for readme in notes/*/*/README.md; do
  if [ -f "$readme" ]; then
    # Restore: [← devops-runbook](../../README.md) → [Home](../README.md)
    # This makes individual notes link back to tool home
    sed -i '' 's|\[← devops-runbook\](../../README.md)|[Home](../README.md)|g' "$readme"
    echo "Restored: $readme"
  fi
done

# Lab files inside tool subfolders
for readme in notes/*/networking-labs/*.md notes/*/linux-labs/*.md notes/*/docker-labs/*.md notes/*/git-labs/*.md notes/*/k8s-labs/*.md; do
  if [ -f "$readme" ]; then
    sed -i '' 's|\[← devops-runbook\](../../README.md)|[Home](../README.md)|g' "$readme"
    sed -i '' 's|\[← devops-runbook\](../README.md)|[Home](../README.md)|g' "$readme"
    echo "Restored lab: $readme"
  fi
done

# Networking map file (one level deeper)
if [ -f "notes/03. Networking – Foundations/00-networking-map/00-networking-map.md" ]; then
  sed -i '' 's|\[← devops-runbook\](../../README.md)|[Home](../README.md)|g' \
    "notes/03. Networking – Foundations/00-networking-map/00-networking-map.md"
  echo "Restored: networking map"
fi

# Tool home READMEs (notes/XX. Tool/README.md)
# These KEEP the [← devops-runbook] link pointing to root
# Already correct from previous fix — no change needed here

echo ""
echo "=== Verifying tool home READMEs still have devops-runbook link ==="
grep -l 'devops-runbook' notes/*/README.md

echo ""
echo "=== Verifying individual notes have Home link ==="
grep -l '\[Home\]' notes/01.\ Linux*/0*/README.md | head -5

echo ""
echo "=== Done. Now run: ==="
echo "git add ."
echo "git commit -m 'docs: restore correct 3-level nav structure'"
echo "git push"
