[Home](../README.md) |
[Boot](../01-boot-process/README.md) |
[Basics](../02-basics/README.md) |
[Files](../03-working-with-files/README.md) |
[Filters](../04-filter-commands/README.md) |
[sed](../05-sed-stream-editor/README.md) |
[awk](../06-awk/README.md) |
[Editors](../07-text-editor/README.md) |
[Users](../08-user-&-group-management/README.md) |
[Permissions](../09-file-ownership-&-permissions/README.md) |
[Archive](../10-archiving-and-compression/README.md) |
[Packages](../11-package-management/README.md) |
[Services](../12-service-management/README.md) |
[Networking](../13-networking/README.md)

# Archiving and Compression

Before every deploy, you archive the current state of the webstore. Before rotating logs, you compress last month's access log. When you need to move the entire project to a new server, you pack it into one file and transfer it. These are not optional practices — they are the habits that let you recover when something goes wrong.

This file covers two distinct operations that are often confused:

- **Archiving** — combining multiple files and directories into one file. No size reduction. The purpose is portability and organization.
- **Compression** — reducing a file's size. The purpose is storage efficiency and faster transfer.

`tar` archives. `gzip` compresses. Used together — `tar.gz` — you get both.

---

## Table of Contents

- [1. Archiving vs Compression](#1-archiving-vs-compression)
- [2. tar — The Standard Tool](#2-tar--the-standard-tool)
- [3. gzip — Compressing Single Files](#3-gzip--compressing-single-files)
- [4. Reading Compressed Files Without Extracting](#4-reading-compressed-files-without-extracting)
- [5. zip and unzip](#5-zip-and-unzip)
- [6. The Webstore Backup Workflow](#6-the-webstore-backup-workflow)
- [7. Quick Reference](#7-quick-reference)

---

## 1. Archiving vs Compression

| Tool | What it does | Output |
|---|---|---|
| `tar` | Combines files into one archive — no compression | `.tar` |
| `gzip` | Compresses a single file | `.gz` |
| `tar + gzip` | Archives and compresses in one step — the Linux standard | `.tar.gz` or `.tgz` |
| `zip` | Archives and compresses — common on Windows, cross-platform | `.zip` |

**The rule in practice:** on Linux servers you use `tar.gz`. It preserves file permissions, ownership, symlinks, and directory structure — everything you need to restore a backup to an identical state. `zip` does not preserve Unix permissions reliably, which matters when restoring a webstore with carefully set `chmod` values.

---

## 2. tar — The Standard Tool

`tar` reads like a sentence: what to do, how to do it, what to name the result, what to include.

**The flags you use constantly:**

| Flag | Meaning |
|---|---|
| `c` | Create a new archive |
| `x` | Extract from an archive |
| `t` | List contents without extracting |
| `z` | Compress or decompress with gzip |
| `v` | Verbose — print each file as it is processed |
| `f` | The next argument is the archive filename — always required |

The order matters: `tar -czvf archive.tar.gz source/` — flags first, archive name second, source last.

**Create an archive:**

```bash
# Archive the entire webstore directory — no compression yet
tar -cvf webstore.tar ~/webstore/

# Output — verbose shows every file being added:
# webstore/
# webstore/config/
# webstore/config/webstore.conf
# webstore/logs/
# webstore/logs/access.log
# webstore/logs/error.log
# ...
```

**Create a compressed archive (the one you actually use):**

```bash
# Archive + compress the webstore in one step
tar -czvf webstore-backup.tar.gz ~/webstore/

# With a timestamp in the filename — essential for multiple backups
tar -czvf webstore-backup-$(date +%Y-%m-%d).tar.gz ~/webstore/
# Creates: webstore-backup-2025-04-05.tar.gz
```

**List contents without extracting — always do this before extracting:**

```bash
tar -tzvf webstore-backup-2025-04-05.tar.gz

# Output shows permissions, owner, size, date, path:
# drwxr-xr-x akhil/webstore-team    0  2025-04-05  webstore/
# -rw-r--r-- akhil/webstore-team  128  2025-04-05  webstore/config/webstore.conf
# -rw-rw-r-- akhil/webstore-team 2.4K  2025-04-05  webstore/logs/access.log
```

This confirms the archive contains what you expect before you extract it. Extracting blindly into the wrong directory can overwrite files.

**Extract an archive:**

```bash
# Extract into the current directory
tar -xzvf webstore-backup-2025-04-05.tar.gz

# Extract into a specific directory — safer than extracting in place
tar -xzvf webstore-backup-2025-04-05.tar.gz -C /tmp/restore/

# Extract a single file from the archive
tar -xzvf webstore-backup-2025-04-05.tar.gz webstore/config/webstore.conf
```

The `-C` flag is important. Without it, tar extracts relative to your current directory. With it, you control exactly where things land — critical when restoring to a non-default path.

---

## 3. gzip — Compressing Single Files

`gzip` compresses one file and replaces it with a `.gz` version. The original file is gone after compression — this is different from `tar` which always creates a new file.

```bash
# Compress last month's access log — original is replaced
gzip ~/webstore/logs/access.log.old
ls -lh ~/webstore/logs/
# -rw-rw-r-- akhil webstore-team 312K access.log.old.gz
# (was 1.8M before compression — typical 80% reduction for log files)

# Maximum compression — slower but smallest output
gzip -9 ~/webstore/logs/error.log.old

# Keep the original file (do not replace it)
gzip -k ~/webstore/logs/access.log.old

# Decompress — restores the original file
gunzip ~/webstore/logs/access.log.old.gz
```

**When you reach for gzip directly:**
Log rotation — compressing last month's logs before archiving them off the server. Individual config file backup before editing. Log files compress extremely well (60-85% reduction) because they contain repetitive text.

---

## 4. Reading Compressed Files Without Extracting

When a log file is compressed, you do not have to decompress it to search it. These commands work directly on `.gz` files:

```bash
# Print the entire contents of a compressed log
zcat ~/webstore/logs/access.log.gz

# Page through it
zless ~/webstore/logs/access.log.gz

# Search for 500 errors inside the compressed log — no extraction needed
zcat ~/webstore/logs/access.log.gz | grep '500'

# Count 500 errors in the compressed log
zcat ~/webstore/logs/access.log.gz | grep -c '500'
```

This is the pattern for searching historical logs. You keep old logs compressed to save space, and `zcat` lets you query them without decompressing to disk.

---

## 5. zip and unzip

`zip` is useful when you need to share files with systems that expect `.zip` — Windows, certain APIs, email attachments. On Linux servers between themselves, use `tar.gz`.

```bash
# Zip specific files
zip webstore-logs.zip ~/webstore/logs/access.log ~/webstore/logs/error.log

# Zip an entire directory recursively
zip -r webstore-config.zip ~/webstore/config/

# List contents without extracting
unzip -l webstore-config.zip

# Extract
unzip webstore-config.zip

# Extract to a specific directory
unzip webstore-config.zip -d /tmp/restore/
```

**zip vs tar.gz on Linux:**
`tar.gz` preserves Unix permissions, ownership, and symlinks. `zip` may not. If you archive the webstore with `zip` and extract it on another Linux server, the file permissions may be wrong and you will have to run `chmod` and `chown` again. Use `tar.gz` for Linux-to-Linux transfers.

---

## 6. The Webstore Backup Workflow

This is the sequence you run before every significant change to the webstore on a server — before a deploy, before editing config files, before a system update.

```bash
# Step 1 — create a timestamped backup of the entire project
tar -czvf ~/webstore/backup/webstore-$(date +%Y-%m-%d-%H%M).tar.gz \
    --exclude='~/webstore/backup' \
    ~/webstore/

# Step 2 — verify the archive is not corrupted and contains what you expect
tar -tzvf ~/webstore/backup/webstore-2025-04-05-0914.tar.gz | head -20

# Step 3 — confirm the size is reasonable
ls -lh ~/webstore/backup/

# Step 4 — if something goes wrong after your change, restore:
tar -xzvf ~/webstore/backup/webstore-2025-04-05-0914.tar.gz -C /tmp/restore/
# Then verify the restore, swap the directories, restart nginx
```

The `--exclude` flag prevents the backup directory from being included inside itself — without it, each backup would contain all previous backups.

**Log rotation backup — compress old logs monthly:**

```bash
# Compress logs older than 30 days
find ~/webstore/logs/ -name "*.log" -mtime +30 -exec gzip {} \;

# Verify compression happened
ls -lh ~/webstore/logs/
```

---

## 7. Quick Reference

| Command | What it does | Example |
|---|---|---|
| `tar -czvf <archive> <source>` | Create compressed archive | `tar -czvf backup.tar.gz ~/webstore/` |
| `tar -tzvf <archive>` | List contents without extracting | `tar -tzvf backup.tar.gz` |
| `tar -xzvf <archive>` | Extract compressed archive | `tar -xzvf backup.tar.gz` |
| `tar -xzvf <archive> -C <dir>` | Extract to specific directory | `tar -xzvf backup.tar.gz -C /tmp/restore/` |
| `tar -xzvf <archive> <file>` | Extract a single file | `tar -xzvf backup.tar.gz webstore/config/webstore.conf` |
| `gzip <file>` | Compress file — replaces original | `gzip access.log.old` |
| `gzip -k <file>` | Compress file — keep original | `gzip -k access.log` |
| `gzip -9 <file>` | Maximum compression | `gzip -9 error.log.old` |
| `gunzip <file>.gz` | Decompress | `gunzip access.log.gz` |
| `zcat <file>.gz` | Print compressed file contents | `zcat access.log.gz` |
| `zless <file>.gz` | Page through compressed file | `zless access.log.gz` |
| `zcat <file>.gz \| grep <pattern>` | Search inside compressed file | `zcat access.log.gz \| grep '500'` |
| `zip -r <archive> <dir>` | Zip a directory | `zip -r config.zip ~/webstore/config/` |
| `unzip <archive> -d <dir>` | Extract zip to directory | `unzip config.zip -d /tmp/restore/` |

---

→ Ready to practice? [Go to Lab 04](../linux-labs/04-archive-packages-services-lab.md)
