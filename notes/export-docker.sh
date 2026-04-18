#!/bin/bash

# Target file
TARGET="exports/docker_all_notes.md"

# Clear or create file
> "$TARGET"

# Docker notes path
DOCKER_DIR="notes/04. Docker - Containerization"

echo "Finding Docker notes..."

# Find all README.md files in Docker subdirs, sort them, and append
find "$DOCKER_DIR" -name "README.md" | sort | while read -r file; do
    echo "Adding: $file"
    echo -e "\n---" >> "$TARGET"
    echo "# File: $file" >> "$TARGET"
    echo -e "---\n" >> "$TARGET"
    cat "$file" >> "$TARGET"
done

echo "Done. Exported to $TARGET"
