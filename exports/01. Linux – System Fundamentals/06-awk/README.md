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

# awk — Text Processing

`cut` extracts columns. `grep` finds lines. `sed` transforms content. `awk` does all three at once — and adds arithmetic. It reads a file line by line, splits each line into fields, and lets you filter, extract, compute, and format the output in a single command.

The reason awk exists separately from the other filter tools is its ability to calculate. When you need to know the total number of bytes transferred across all 200 responses in an access log, or the average response time across a thousand requests, awk does it in one line. No spreadsheet. No Python script.

The webstore access log used throughout this file:

```
192.168.1.10 GET /api/products 200 512
192.168.1.11 GET /api/products 200 489
192.168.1.12 POST /api/orders 201 1024
192.168.1.10 GET /api/products 200 512
192.168.1.13 GET /api/users 404 128
192.168.1.14 POST /api/orders 500 256
192.168.1.11 GET /api/products 200 489
192.168.1.15 DELETE /api/orders/7 403 64
192.168.1.10 GET /api/products 200 512
192.168.1.14 POST /api/orders 500 256
```

Fields: `$1`=IP, `$2`=method, `$3`=path, `$4`=status, `$5`=bytes

---

## Table of Contents

- [1. How awk Works](#1-how-awk-works)
- [2. Built-in Variables](#2-built-in-variables)
- [3. Printing Fields](#3-printing-fields)
- [4. Pattern Matching](#4-pattern-matching)
- [5. Custom Field Separator](#5-custom-field-separator)
- [6. Conditionals](#6-conditionals)
- [7. Arithmetic and Aggregation](#7-arithmetic-and-aggregation)
- [8. BEGIN and END Blocks](#8-begin-and-end-blocks)
- [9. Real Incident One-Liners](#9-real-incident-one-liners)
- [10. awk vs cut — When to Use Which](#10-awk-vs-cut--when-to-use-which)
- [11. Quick Reference](#11-quick-reference)

---

## 1. How awk Works

awk reads a file one line at a time. Each line is called a **record**. Each record is automatically split into **fields** — by whitespace by default. You write rules that say: if this condition is true for a record, run this action.

```
awk 'PATTERN { ACTION }' file
```

- **PATTERN** — a condition to test against each line. If it matches, the action runs. If omitted, the action runs on every line.
- **ACTION** — what to do: print fields, calculate, format output.

The simplest awk command — print every line:

```bash
awk '{ print }' ~/webstore/logs/access.log
```

This is identical to `cat`. Not useful on its own, but it shows the structure: no pattern means "match everything," `print` with no arguments prints the whole line (`$0`).

---

## 2. Built-in Variables

These variables are available in every awk program without being defined:

| Variable | What it contains | Example value for line `192.168.1.10 GET /api/products 200 512` |
|---|---|---|
| `$0` | The entire current line | `192.168.1.10 GET /api/products 200 512` |
| `$1` | Field 1 | `192.168.1.10` |
| `$2` | Field 2 | `GET` |
| `$3` | Field 3 | `/api/products` |
| `$4` | Field 4 | `200` |
| `$5` | Field 5 | `512` |
| `NR` | Current line number (record number) | `1` on first line, `2` on second, etc. |
| `NF` | Number of fields in the current line | `5` for this log format |
| `FS` | Field separator (default: whitespace) | Set with `-F` flag |

---

## 3. Printing Fields

```bash
# Print only the IP address (field 1)
awk '{ print $1 }' ~/webstore/logs/access.log
# 192.168.1.10
# 192.168.1.11
# ...

# Print IP and status code together
awk '{ print $1, $4 }' ~/webstore/logs/access.log
# 192.168.1.10 200
# 192.168.1.11 200
# 192.168.1.12 201
# ...

# Print with a custom separator between fields
awk '{ print $1 " → " $4 }' ~/webstore/logs/access.log
# 192.168.1.10 → 200
# 192.168.1.11 → 200
# ...

# Print line number alongside each line
awk '{ print NR, $0 }' ~/webstore/logs/access.log
# 1 192.168.1.10 GET /api/products 200 512
# 2 192.168.1.11 GET /api/products 200 489
# ...
```

**awk vs cut for field extraction:**
Both extract fields. Use `cut` for simple, fast extraction with a consistent single-character delimiter. Use `awk` when you need to combine fields, add custom formatting, or do anything beyond raw extraction.

---

## 4. Pattern Matching

A pattern before the action block filters which lines the action runs on. Only lines where the pattern matches trigger the action.

```bash
# Print all lines containing "500"
awk '/500/ { print }' ~/webstore/logs/access.log
# 192.168.1.14 POST /api/orders 500 256
# 192.168.1.14 POST /api/orders 500 256

# Print only the IP and path for 500 errors
awk '/500/ { print $1, $3 }' ~/webstore/logs/access.log
# 192.168.1.14 /api/orders
# 192.168.1.14 /api/orders

# Match on a specific field — only lines where field 4 is exactly "500"
awk '$4 == "500" { print }' ~/webstore/logs/access.log
```

The difference between `/500/` and `$4 == "500"` matters when `500` could appear elsewhere in the line — for example, if a URL path contained `500`. Matching on `$4` is more precise.

---

## 5. Custom Field Separator

When your file uses a delimiter other than whitespace — commas, colons, equals signs — tell awk with `-F`.

```bash
# webstore.conf uses = as separator
# db_host=webstore-db
# db_port=5432

# Print only the values (field 2 after splitting on =)
awk -F '=' '{ print $2 }' ~/webstore/config/webstore.conf
# webstore-db
# 5432
# 8080
# ...

# Print key=value pairs with formatting
awk -F '=' '{ print "KEY: " $1 "  VALUE: " $2 }' ~/webstore/config/webstore.conf
# KEY: db_host  VALUE: webstore-db
# KEY: db_port  VALUE: 5432
# ...

# /etc/passwd uses : as separator — print username (field 1) and shell (field 7)
awk -F ':' '{ print $1, $7 }' /etc/passwd
```

---

## 6. Conditionals

Use `if` inside the action block to apply logic beyond simple pattern matching.

```bash
# Print lines where the status code is 500
awk '{ if ($4 == "500") print $0 }' ~/webstore/logs/access.log

# Print lines where bytes transferred is greater than 500
awk '{ if ($5 > 500) print $1, $3, $5 }' ~/webstore/logs/access.log
# 192.168.1.12 /api/orders 1024
# 192.168.1.10 /api/products 512
# 192.168.1.10 /api/products 512
# 192.168.1.10 /api/products 512

# Print lines where status is NOT 200
awk '{ if ($4 != "200") print $0 }' ~/webstore/logs/access.log
```

You can also write the condition as a pattern directly without `if`:

```bash
# These two are equivalent
awk '{ if ($4 == "500") print $0 }' access.log
awk '$4 == "500" { print }' access.log
```

The second form is more idiomatic awk. Use whichever reads more clearly to you.

---

## 7. Arithmetic and Aggregation

This is where awk separates itself from every other filter tool. Variables persist across lines — you can accumulate values as awk reads through a file.

```bash
# Sum the total bytes transferred across all requests
awk '{ total += $5 } END { print "Total bytes:", total }' ~/webstore/logs/access.log
# Total bytes: 4242

# Count how many 500 errors occurred
awk '$4 == "500" { count++ } END { print "500 errors:", count }' ~/webstore/logs/access.log
# 500 errors: 2

# Sum bytes for successful requests only (status 200)
awk '$4 == "200" { total += $5 } END { print "Bytes from 200s:", total }' ~/webstore/logs/access.log
# Bytes from 200s: 2514

# Calculate average bytes per request
awk '{ total += $5 } END { print "Average bytes:", total/NR }' ~/webstore/logs/access.log
# Average bytes: 424.2
```

**How accumulation works:**
`total += $5` adds field 5 of the current line to the variable `total`. Since `total` starts at zero and this runs on every line, by the time `END` runs, `total` contains the sum of every value in field 5 across the entire file.

---

## 8. BEGIN and END Blocks

`BEGIN` runs once before awk reads any lines. `END` runs once after all lines are processed. Both are optional.

```bash
# Print a header before the output, and a summary after
awk '
  BEGIN { print "--- Webstore Access Report ---" }
  { print $1, $4, $5 }
  END { print "--- Total lines:", NR, "---" }
' ~/webstore/logs/access.log

# Output:
# --- Webstore Access Report ---
# 192.168.1.10 200 512
# 192.168.1.11 200 489
# ...
# --- Total lines: 10 ---
```

`BEGIN` is also where you set the field separator as an alternative to `-F`:

```bash
awk 'BEGIN { FS="=" } { print $1, $2 }' ~/webstore/config/webstore.conf
```

---

## 9. Real Incident One-Liners

**How many requests came from each IP address?**
```bash
awk '{ count[$1]++ } END { for (ip in count) print count[ip], ip }' ~/webstore/logs/access.log | sort -rn
# 3 192.168.1.10
# 2 192.168.1.11
# 2 192.168.1.14
# ...
```

**What is the total bytes transferred per status code?**
```bash
awk '{ bytes[$4] += $5 } END { for (status in bytes) print status, bytes[status] }' ~/webstore/logs/access.log
# 200 2514
# 201 1024
# 500 512
# ...
```

**Print only lines where the request path starts with /api/orders:**
```bash
awk '$3 ~ /^\/api\/orders/ { print }' ~/webstore/logs/access.log
```

**Print a formatted report of all non-200 requests:**
```bash
awk '$4 != "200" { printf "%-18s %-8s %-25s %s\n", $1, $2, $3, $4 }' ~/webstore/logs/access.log
```

---

## 10. awk vs cut — When to Use Which

| Situation | Use |
|---|---|
| Extract one or two fields, simple delimiter | `cut` — faster, simpler syntax |
| Extract fields with custom formatting between them | `awk` |
| Filter rows by field value | `awk` |
| Calculate totals, averages, counts | `awk` — `cut` cannot do this |
| Multiple conditions across different fields | `awk` |
| Quick IP extraction from access log | Either — `cut -d' ' -f1` or `awk '{print $1}'` |

---

## 11. Quick Reference

| Command | What it does |
|---|---|
| `awk '{ print }' file` | Print every line |
| `awk '{ print $1 }' file` | Print field 1 only |
| `awk '{ print $1, $4 }' file` | Print fields 1 and 4 with space between |
| `awk '{ print NR, $0 }' file` | Print line number with each line |
| `awk '/PATTERN/ { print }' file` | Print lines matching pattern |
| `awk '$4 == "500" { print }' file` | Print lines where field 4 equals 500 |
| `awk '$5 > 1000 { print }' file` | Print lines where field 5 is greater than 1000 |
| `awk -F ':' '{ print $1 }' file` | Use `:` as field separator |
| `awk -F '=' '{ print $2 }' file` | Use `=` as field separator — useful for config files |
| `awk '{ total += $5 } END { print total }' file` | Sum all values in field 5 |
| `awk '$4=="500"{ c++ } END{ print c }' file` | Count lines where field 4 is 500 |
| `awk '{ total += $5 } END { print total/NR }' file` | Average of field 5 across all lines |
| `awk 'BEGIN{print "start"} { print } END{print "end"}' file` | Header + content + footer |

---

→ Ready to practice? [Go to Lab 02](../linux-labs/02-filters-sed-awk-lab.md)
