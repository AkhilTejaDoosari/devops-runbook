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

# sed — Stream Editor

`grep` finds lines. `cut` extracts fields. `sed` transforms content — it reads a stream line by line, applies your editing instructions, and outputs the result. No file is opened in an editor. No manual cursor movement. You describe the change once and sed applies it to every matching line in the file.

This is how you update config files in deploy scripts, sanitize log output before piping it elsewhere, or make the same change across hundreds of lines in seconds.

The webstore config file used throughout this file:

```
db_host=webstore-db
db_port=5432
api_port=8080
api_host=webstore-api
frontend_port=80
frontend_host=webstore-frontend
env=production
```

---

## Table of Contents

- [1. How sed Works](#1-how-sed-works)
- [2. Substitution — the Core Operation](#2-substitution--the-core-operation)
- [3. Targeting Specific Lines](#3-targeting-specific-lines)
- [4. In-Place Editing](#4-in-place-editing)
- [5. Deleting Lines](#5-deleting-lines)
- [6. Printing Specific Lines](#6-printing-specific-lines)
- [7. Inserting and Appending Lines](#7-inserting-and-appending-lines)
- [8. Running Multiple Commands](#8-running-multiple-commands)
- [9. Quick Reference](#9-quick-reference)

---

## 1. How sed Works

sed reads a file or stream one line at a time. For each line it checks whether your pattern matches, applies the instruction if it does, then prints the result. By default it prints every line — changed or not. The original file is untouched unless you use `-i`.

```
sed 'instruction' file
     │
     └── instruction = [address] command
         address = which lines to act on (optional — default is all lines)
         command = what to do (substitute, delete, print, insert)
```

**Key flags:**

| Flag | What it does |
|---|---|
| `-n` | Suppress automatic printing — only print lines you explicitly ask for with `p` |
| `-i` | Edit the file in-place — changes are written back to the original file |
| `-e` | Chain multiple instructions in one command |

---

## 2. Substitution — the Core Operation

The substitution command is the one you will use 90% of the time:

```
s/OLD/NEW/
```

- `s` — substitute
- first `/` — opens the pattern to find
- `OLD` — what to look for
- second `/` — separates pattern from replacement
- `NEW` — what to replace it with
- third `/` — closes the replacement, flags go here

**Replace the first match on each line:**

```bash
sed 's/production/staging/' ~/webstore/config/webstore.conf
```

This replaces only the first occurrence of `production` per line. The file is not changed — output goes to the terminal.

**Replace all occurrences on each line with `g` (global):**

```bash
sed 's/webstore/mystore/g' ~/webstore/config/webstore.conf
```

Without `g`, only the first match per line is replaced. With `g`, every match on every line is replaced.

**When the replacement contains `/`, use a different delimiter:**

```bash
# This would break — forward slash conflicts with the delimiter
sed 's/api_host=webstore-api/api_host=webstore-api/staging/' webstore.conf

# Use # as the delimiter instead
sed 's#webstore-api#webstore-api-staging#g' ~/webstore/config/webstore.conf
```

Any character can be the delimiter as long as it does not appear in your pattern or replacement. `#`, `|`, and `@` are common choices.

---

## 3. Targeting Specific Lines

By default sed acts on every line. You can restrict it to specific lines using a line number or a pattern.

**Act on a specific line number:**

```bash
# Replace only on line 1
sed '1 s/production/staging/' ~/webstore/config/webstore.conf
```

**Act on a range of lines:**

```bash
# Replace on lines 1 through 3 only
sed '1,3 s/webstore/mystore/' ~/webstore/config/webstore.conf
```

**Act on all lines from line 2 to the end (`$` means last line):**

```bash
sed '2,$ s/webstore/mystore/' ~/webstore/config/webstore.conf
```

**Act only on lines matching a pattern:**

```bash
# Only replace on lines that contain "port"
sed '/port/ s/8080/9090/' ~/webstore/config/webstore.conf
```

**Print only the lines where substitution occurred (`-n` + `p` flag):**

```bash
sed -n 's/production/staging/p' ~/webstore/config/webstore.conf
# env=staging
```

`-n` suppresses all output. `p` prints only the lines that were actually changed. Together they give you a confirmation of what sed touched.

---

## 4. In-Place Editing

Everything above only prints the result — the original file is not modified. To write changes back to the file, use `-i`.

```bash
# Change production to staging directly in the file
sed -i 's/production/staging/' ~/webstore/config/webstore.conf
```

After this command, `webstore.conf` is permanently changed. There is no undo unless you have a backup.

**Best practice — always back up before in-place editing:**

```bash
# Create a backup first
cp ~/webstore/config/webstore.conf ~/webstore/backup/webstore.conf.bak

# Then edit in-place
sed -i 's/production/staging/' ~/webstore/config/webstore.conf
```

On macOS, `-i` requires an empty string argument: `sed -i '' 's/old/new/' file`. On Linux it does not.

**When you reach for `-i`:**
Deploy scripts that update config files before a service restart. Instead of opening an editor manually, the script runs `sed -i` to swap the environment value, then restarts the service.

---

## 5. Deleting Lines

```bash
# Delete all lines containing "frontend"
sed '/frontend/d' ~/webstore/config/webstore.conf

# Delete the last line
sed '$d' ~/webstore/config/webstore.conf

# Delete lines 5 through the end
sed '5,$d' ~/webstore/config/webstore.conf
```

**When you reach for delete:**
Stripping comment lines from a config file before parsing it. Removing header lines from a log file before piping it to another command.

```bash
# Strip all comment lines (lines starting with #) from a config
sed '/^#/d' ~/webstore/config/webstore.conf
```

---

## 6. Printing Specific Lines

Combined with `-n`, you can use sed to extract exactly the lines you need from a large file — like `head` and `tail` but with more control.

```bash
# Print only lines 2 through 4
sed -n '2,4p' ~/webstore/config/webstore.conf
# db_port=5432
# api_port=8080
# api_host=webstore-api

# Print only lines containing "api"
sed -n '/api/p' ~/webstore/config/webstore.conf
# api_port=8080
# api_host=webstore-api
```

---

## 7. Inserting and Appending Lines

```bash
# Insert a line BEFORE line 1
sed '1i\# webstore config — do not edit manually' ~/webstore/config/webstore.conf

# Append a line AFTER the last line
sed '$a\log_level=info' ~/webstore/config/webstore.conf

# Insert in-place — write it back to the file
sed -i '1i\# webstore config — do not edit manually' ~/webstore/config/webstore.conf
```

---

## 8. Running Multiple Commands

Use `-e` to chain multiple instructions in a single sed pass. One read of the file, multiple transformations applied.

```bash
# Swap environment to staging AND update the api port in one command
sed -e 's/production/staging/' -e 's/api_port=8080/api_port=9090/' ~/webstore/config/webstore.conf
```

This is cleaner than running sed twice and is faster on large files because the file is only read once.

---

## 9. Quick Reference

| Syntax | What it does | Example |
|---|---|---|
| `s/OLD/NEW/` | Replace first match per line | `sed 's/production/staging/' webstore.conf` |
| `s/OLD/NEW/g` | Replace all matches per line | `sed 's/webstore/mystore/g' webstore.conf` |
| `s#OLD#NEW#g` | Same but using `#` as delimiter | `sed 's#/api#/v2/api#g' webstore.conf` |
| `N s/OLD/NEW/` | Replace on line N only | `sed '1 s/production/staging/' webstore.conf` |
| `N,M s/OLD/NEW/` | Replace on lines N through M | `sed '1,3 s/webstore/mystore/' webstore.conf` |
| `/PAT/ s/OLD/NEW/` | Replace only on lines matching PAT | `sed '/port/ s/8080/9090/' webstore.conf` |
| `-n 's/OLD/NEW/p'` | Print only changed lines | `sed -n 's/production/staging/p' webstore.conf` |
| `-i 's/OLD/NEW/'` | Edit the file in-place | `sed -i 's/production/staging/' webstore.conf` |
| `/PAT/d` | Delete lines matching pattern | `sed '/^#/d' webstore.conf` |
| `$d` | Delete the last line | `sed '$d' webstore.conf` |
| `-n 'N,Mp'` | Print lines N through M only | `sed -n '2,4p' webstore.conf` |
| `Ni\TEXT` | Insert TEXT before line N | `sed '1i\# header' webstore.conf` |
| `$a\TEXT` | Append TEXT after last line | `sed '$a\log_level=info' webstore.conf` |
| `-e 'cmd1' -e 'cmd2'` | Run multiple commands in one pass | `sed -e 's/a/b/' -e 's/c/d/' webstore.conf` |

---

→ Ready to practice? [Go to Lab 02](../linux-labs/02-filters-sed-awk-lab.md)
