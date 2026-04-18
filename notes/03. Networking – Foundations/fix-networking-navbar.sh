#!/bin/bash

# macOS-compatible — uses python3
# Run from inside: notes/03. Networking – Foundations/
# bash fix-navbar.sh

FILES=(
  "01-foundation-and-the-big-picture/README.md"
  "02-addressing-fundamentals/README.md"
  "03-ip-deep-dive/README.md"
  "04-network-devices/README.md"
  "05-subnets-cidr/README.md"
  "06-ports-transport/README.md"
  "07-nat/README.md"
  "08-dns/README.md"
  "09-firewalls/README.md"
  "10-complete-journey/README.md"
)

for file in "${FILES[@]}"; do
  if [ -f "$file" ]; then
    python3 - "$file" << 'EOF'
import sys

filepath = sys.argv[1]

with open(filepath, 'r') as f:
    content = f.read()

if '[Interview]' in content:
    print('already done — skipped')
    sys.exit(0)

# Find the last nav link line and append Interview after it
# Networking files end their nav bar with the last link before a blank line + ---
# Strategy: find the first --- after the nav bar and insert before it

lines = content.split('\n')
nav_end_idx = None

for i, line in enumerate(lines):
    if line.strip() == '---' and i > 0:
        # Check that previous non-empty line looks like a nav link
        for j in range(i-1, -1, -1):
            if lines[j].strip():
                if lines[j].strip().endswith(')') or lines[j].strip().endswith('README.md)'):
                    nav_end_idx = j
                break
        break

if nav_end_idx is None:
    print('nav bar end not found — check manually')
    sys.exit(1)

# Append interview link to the last nav line
lines[nav_end_idx] = lines[nav_end_idx] + ' |\n[Interview](../99-interview-prep/README.md)'

with open(filepath, 'w') as f:
    f.write('\n'.join(lines))

print('updated')
EOF
    echo "✅ $file"
  else
    echo "❌ not found: $file"
  fi
done

echo ""
echo "verify with: head -15 01-foundation-and-the-big-picture/README.md"
