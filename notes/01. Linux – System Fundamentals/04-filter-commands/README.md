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

# Filter Commands

A production server generates thousands of log lines every hour. You will never open them in a text editor. You will never scroll through them manually. Instead you use filter commands — tools that let you search, slice, count, sort, and chain operations against any file or stream from the terminal. This is how a DevOps engineer reads a system without a GUI.

The webstore access log used throughout this file:

```
192.168.1.10 GET /api/products 200
192.168.1.11 GET /api/products 200
192.168.1.12 POST /api/orders 201
192.168.1.10 GET /api/products 200
192.168.1.13 GET /api/users 404
192.168.1.14 POST /api/orders 500
192.168.1.11 GET /api/products 200
192.168.1.15 DELETE /api/orders/7 403
192.168.1.10 GET /api/products 200
192.168.1.14 POST /api/orders 500
```

---

## Table of Contents

- [1. find — Search the Filesystem](#1-find--search-the-filesystem)
- [2. locate — Fast Name Lookup](#2-locate--fast-name-lookup)
- [3. grep — Search File Contents](#3-grep--search-file-contents)
- [4. wc — Count Lines, Words, Characters](#4-wc--count-lines-words-characters)
- [5. The Pipe — Chaining Commands](#5-the-pipe--chaining-commands)
- [6. cut — Extract Fields](#6-cut--extract-fields)
- [7. sort — Order Lines](#7-sort--order-lines)
- [8. uniq — Deduplicate Lines](#8-uniq--deduplicate-lines)
- [9. tr — Translate Characters](#9-tr--translate-characters)
- [10. tee — Split a Stream](#10-tee--split-a-stream)
- [11. Real Incident Pipelines](#11-real-incident-pipelines)

---

## 1. find — Search the Filesystem

`find` walks the directory tree in real time and returns every file that matches your criteria. Unlike `locate`, its results are always current because it reads the actual filesystem rather than a cached database. It is slower on very large trees but infinitely more flexible — you can filter by name, type, size, age, owner, permissions, and then execute a command on every match.

| Option | What it does | Example |
|---|---|---|
| `-name "*.log"` | Match files by name using wildcards | `find ~/webstore/logs -name "*.log"` |
| `-type f` | Regular files only | `find ~/webstore -type f` |
| `-type d` | Directories only | `find ~/webstore -type d` |
| `-mtime +7` | Modified more than 7 days ago | `find ~/webstore/logs -mtime +7` |
| `-mtime -1` | Modified in the last 24 hours | `find ~/webstore/logs -mtime -1` |
| `-size +1k` | Larger than 1 KB | `find ~/webstore/logs -size +1k` |
| `-size -500c` | Smaller than 500 bytes | `find ~/webstore/logs -size -500c` |
| `-exec <cmd> {} \;` | Run a command on every match | `find ~/webstore/logs -name "*.tmp" -exec rm {} \;` |

**When you reach for `find`:**
- Cleaning up old log files before a deploy: `find ~/webstore/logs -mtime +30 -exec rm {} \;`
- Confirming a config file exists somewhere in the project: `find ~/webstore -name "webstore.conf"`
- Deleting all `.tmp` files left behind by a crashed process: `find ~/webstore -name "*.tmp" -exec rm {} \;`

---

## 2. locate — Fast Name Lookup

`locate` searches a prebuilt database of filenames instead of walking the live filesystem. It returns results instantly but the database is only as fresh as the last time `updatedb` ran — usually once a day. Use it when you need to find a file quickly by name and do not need guaranteed freshness.

| Option | What it does | Example |
|---|---|---|
| `locate <name>` | Find all paths containing this name | `locate webstore.conf` |
| `-i` | Case-insensitive match | `locate -i ACCESS.LOG` |
| `-l 5` | Limit results to 5 | `locate -l 5 access.log` |
| `-c` | Count matches only | `locate -c "*.log"` |

**find vs locate — when to use which:**

| | find | locate |
|---|---|---|
| Results | Always current | Only as fresh as last `updatedb` |
| Speed | Slower on large trees | Instant |
| Filters | Name, type, size, age, owner | Name only |
| Actions | Can run `-exec` on matches | Returns list only |
| Use when | You need exact, current results | You just need to know where a file is |

If a file was created in the last few hours and `locate` cannot find it, run `sudo updatedb` first to refresh the database.

---

## 3. grep — Search File Contents

`grep` searches inside files for lines matching a pattern. It is the single most-used command for reading logs and config files on a server. Every incident investigation starts with `grep`.

```
grep [OPTIONS] <pattern> <file>
```

| Flag | What it does | Example |
|---|---|---|
| `grep <pattern> <file>` | Find lines matching pattern — case sensitive | `grep '500' ~/webstore/logs/access.log` |
| `-i` | Case-insensitive match | `grep -i 'error' access.log` |
| `-n` | Show line numbers alongside matches | `grep -n '500' access.log` |
| `-c` | Count matching lines instead of showing them | `grep -c '500' access.log` |
| `-v` | Invert — show lines that do NOT match | `grep -v '200' access.log` |
| `-w` | Match whole words only | `grep -w 'GET' access.log` |
| `-r` | Search recursively through all files in a directory | `grep -r 'db_host' ~/webstore/config/` |

**What these look like against the webstore log:**

```bash
# Find all 500 errors
grep '500' ~/webstore/logs/access.log
# 192.168.1.14 POST /api/orders 500
# 192.168.1.14 POST /api/orders 500

# Count how many 500 errors occurred
grep -c '500' ~/webstore/logs/access.log
# 2

# Find everything that is NOT a 200 OK — surface all problems at once
grep -v '200' ~/webstore/logs/access.log
# 192.168.1.12 POST /api/orders 201
# 192.168.1.13 GET /api/users 404
# 192.168.1.14 POST /api/orders 500
# 192.168.1.15 DELETE /api/orders/7 403
# 192.168.1.14 POST /api/orders 500

# Find all errors across every log file in the logs directory
grep -r '500' ~/webstore/logs/
```

**When you reach for `grep`:**
During an incident, `grep -v '200'` on the access log immediately surfaces every non-successful request. You do not scroll — you filter.

---

## 4. wc — Count Lines, Words, Characters

`wc` counts lines, words, and characters in a file or stream. On its own it tells you the size of a file in human terms. In a pipeline it tells you how many results a previous command produced.

| Command | What it counts | When you reach for it |
|---|---|---|
| `wc <file>` | Lines, words, and characters together | Quick file size check |
| `wc -l <file>` | Lines only | How many entries are in the access log |
| `wc -w <file>` | Words only | Rarely needed on log files |
| `wc -c <file>` | Characters (bytes) only | Checking exact file size |

**Most useful pattern — count grep results:**

```bash
grep '500' ~/webstore/logs/access.log | wc -l
# 2
```

This tells you exactly how many 500 errors occurred without printing every matching line. Combine with `-i` and a date pattern and you have a quick incident count.

---

## 5. The Pipe — Chaining Commands

The pipe `|` takes the output of one command and feeds it directly into the next as input. No temporary files. No intermediate steps. It is what turns single commands into powerful analysis chains.

```
command1 | command2 | command3
```

Think of it as an assembly line. Each command does one job. The pipe connects them. The final output is the result of the entire chain.

```bash
# Read the log, find 500 errors, count them
cat ~/webstore/logs/access.log | grep '500' | wc -l
# 2

# Extract just the IP addresses from every 500 error
grep '500' ~/webstore/logs/access.log | cut -d' ' -f1
# 192.168.1.14
# 192.168.1.14
```

Every section below builds on the pipe.

---

## 6. cut — Extract Fields

`cut` extracts specific columns from structured text. Log files, CSVs, `/etc/passwd` — any file where fields are separated by a consistent delimiter. You tell it the delimiter with `-d` and which field(s) to keep with `-f`.

| Option | What it does | Example |
|---|---|---|
| `-d' ' -f1` | Split on space, take field 1 | `cut -d' ' -f1 access.log` — extracts IP addresses |
| `-d' ' -f3` | Split on space, take field 3 | `cut -d' ' -f3 access.log` — extracts URL paths |
| `-d' ' -f1,4` | Take fields 1 and 4 | `cut -d' ' -f1,4 access.log` — IP and status code |
| `-d',' -f2` | Split on comma, take field 2 | `cut -d',' -f2 data.csv` |

**Against the webstore log:**

```bash
# Extract all IP addresses (field 1)
cut -d' ' -f1 ~/webstore/logs/access.log
# 192.168.1.10
# 192.168.1.11
# ...

# Extract status codes only (field 4)
cut -d' ' -f4 ~/webstore/logs/access.log
# 200
# 200
# 201
# ...
```

---

## 7. sort — Order Lines

`sort` orders lines of text. By default it sorts alphabetically. Flags let you sort numerically, in reverse, by a specific field, or by month name. `sort` almost always appears before `uniq` in a pipeline — `uniq` only deduplicates consecutive identical lines, so you must sort first.

| Flag | What it does | Example |
|---|---|---|
| `sort <file>` | Alphabetical ascending | `sort access.log` |
| `-r` | Reverse order | `sort -r access.log` |
| `-n` | Numeric sort | `sort -n sizes.txt` |
| `-k <N>` | Sort by field N | `sort -k4 access.log` — sort by status code |
| `-t <delim>` | Use this delimiter to identify fields | `sort -t',' -k3 -n data.csv` |

```bash
# Sort the access log by status code (field 4)
sort -k4 ~/webstore/logs/access.log
# 192.168.1.12 POST /api/orders 201
# 192.168.1.15 DELETE /api/orders/7 403
# 192.168.1.13 GET /api/users 404
# 192.168.1.14 POST /api/orders 500
# 192.168.1.14 POST /api/orders 500
# 192.168.1.10 GET /api/products 200
# ...
```

---

## 8. uniq — Deduplicate Lines

`uniq` removes or counts duplicate consecutive lines. Because it only works on adjacent duplicates, you almost always run `sort` first to bring identical lines together.

| Flag | What it does | Example |
|---|---|---|
| `uniq` | Remove consecutive duplicate lines | `sort access.log \| uniq` |
| `-c` | Prefix each line with how many times it appeared | `sort access.log \| uniq -c` |
| `-d` | Show only lines that appeared more than once | `sort access.log \| uniq -d` |
| `-u` | Show only lines that appeared exactly once | `sort access.log \| uniq -u` |

**The classic combination — find the most active IPs:**

```bash
cut -d' ' -f1 ~/webstore/logs/access.log | sort | uniq -c | sort -rn
#   5 192.168.1.10
#   2 192.168.1.11
#   2 192.168.1.14
#   1 192.168.1.12
#   1 192.168.1.13
#   1 192.168.1.15
```

Read this pipeline left to right: extract IP addresses → sort them so identical ones are adjacent → count and deduplicate → sort by count descending. Result: a ranked list of who is hitting the webstore API most.

---

## 9. tr — Translate Characters

`tr` replaces or deletes characters in a stream. It reads from stdin — you feed it content with a pipe or redirect.

| Option | What it does | Example |
|---|---|---|
| `tr 'a-z' 'A-Z'` | Uppercase everything | `cat access.log \| tr 'a-z' 'A-Z'` |
| `-d '0-9'` | Delete all digits | `tr -d '0-9' < access.log` |
| `-s ' '` | Squeeze repeated spaces into one | `tr -s ' ' < access.log` |

`tr` is most useful in pipelines when you need to normalize text before passing it to another command — removing characters that break field splitting, or standardizing case before comparison.

---

## 10. tee — Split a Stream

`tee` reads from stdin and writes to both stdout and a file simultaneously. It lets you see pipeline output on the terminal and save it to a file at the same time — without running the command twice.

| Flag | What it does | Example |
|---|---|---|
| `tee <file>` | Write to stdout and file | `grep '500' access.log \| tee errors.log` |
| `-a` | Append to file instead of overwrite | `grep '500' access.log \| tee -a errors.log` |

```bash
# Save all 500 errors to a file AND still see them on screen
grep '500' ~/webstore/logs/access.log | tee ~/webstore/logs/errors.log
# 192.168.1.14 POST /api/orders 500   ← printed to terminal
# 192.168.1.14 POST /api/orders 500   ← also written to errors.log
```

---

## 11. Real Incident Pipelines

These are the chains you actually build during an incident. Each one is a question you need answered fast.

**How many 500 errors hit the API in this log?**
```bash
grep '500' ~/webstore/logs/access.log | wc -l
```

**Which IP address is generating all the 500 errors?**
```bash
grep '500' ~/webstore/logs/access.log | cut -d' ' -f1 | sort | uniq -c | sort -rn
```

**Which endpoints are being hit most often?**
```bash
cut -d' ' -f3 ~/webstore/logs/access.log | sort | uniq -c | sort -rn
```

**Show me every request that is not a 200 OK, with line numbers:**
```bash
grep -vn '200' ~/webstore/logs/access.log
```

**Find all log files modified in the last 24 hours and search them all for errors:**
```bash
find ~/webstore/logs -mtime -1 -name "*.log" -exec grep -l '500' {} \;
```

**Save all non-200 requests to a separate file for further analysis:**
```bash
grep -v '200' ~/webstore/logs/access.log | tee ~/webstore/logs/non-200.log
```

---

→ Ready to practice? [Go to Lab 02](../linux-labs/02-filters-sed-awk-lab.md)
