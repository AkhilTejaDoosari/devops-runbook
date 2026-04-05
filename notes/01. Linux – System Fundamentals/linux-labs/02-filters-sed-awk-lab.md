[Home](../README.md) |
[Labs Index](./README.md) |
[Lab 01](./01-boot-basics-files-lab.md) |
[Lab 02](./02-filters-sed-awk-lab.md) |
[Lab 03](./03-vim-users-permissions-lab.md) |
[Lab 04](./04-archive-packages-services-lab.md) |
[Lab 05](./05-networking-lab.md)

---

# Lab 02 — Filters, sed & awk

## The Situation

The webstore has been running for a week. Users are reporting slow responses and occasional errors. You are the engineer on call. You have no monitoring dashboard, no Grafana, no Datadog. You have a terminal, the webstore logs, and the filter commands you are about to practice.

Your job is to find out what is wrong — which IPs are generating errors, which endpoints are failing, how many requests are hitting the API per hour, and whether the database connection is stable. You do all of this without opening a text editor. You pipe commands together and let the terminal answer your questions.

By the end of this lab you will be able to investigate any log file the way a working DevOps engineer does. That skill transfers directly to Docker logs, Kubernetes pod logs, and AWS CloudWatch — the data format changes but the technique does not.

## What this lab covers

You will search logs with grep, locate files by age and size with find, extract and rank data with cut, sort, and uniq, transform config files with sed, analyze structured log data with awk including arithmetic, and build multi-command pipelines that answer real incident questions. Every command is typed from scratch.

## Prerequisites

- [Filter Commands notes](../04-filter-commands/README.md)
- [sed notes](../05-sed-stream-editor/README.md)
- [awk notes](../06-awk/README.md)
- Lab 01 completed — `~/webstore/` directory must exist

---

## Section 1 — Set Up the Lab Files

**Goal:** create realistic webstore log and config files to work with throughout this lab.

1. Write a realistic access log — note the fifth field is bytes transferred
```bash
cat > ~/webstore/logs/access.log << 'EOF'
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
EOF
```

2. Write an error log
```bash
cat > ~/webstore/logs/error.log << 'EOF'
ERROR 2025-01-01 DB connection timeout
INFO  2025-01-01 Retry attempt 1
ERROR 2025-01-01 DB connection timeout
INFO  2025-01-01 Retry attempt 2
ERROR 2025-01-02 Out of memory
INFO  2025-01-02 Service restarted
ERROR 2025-01-02 DB connection timeout
EOF
```

3. Write the webstore config file
```bash
cat > ~/webstore/config/webstore.conf << 'EOF'
db_host=webstore-db
db_port=5432
api_port=8080
api_host=webstore-api
frontend_port=80
frontend_host=webstore-frontend
env=production
EOF
```

---

## Section 2 — grep: Search the Logs

**Goal:** find specific patterns in log files the way you would in a real incident.

1. Find all 500 errors in the access log
```bash
grep '500' ~/webstore/logs/access.log
```

2. Find all errors case-insensitively in the error log
```bash
grep -i 'error' ~/webstore/logs/error.log
```

3. Show line numbers with matches — useful when error messages reference line numbers
```bash
grep -n 'ERROR' ~/webstore/logs/error.log
```

4. Count how many 500 errors occurred
```bash
grep -c '500' ~/webstore/logs/access.log
```

5. Show all lines that are NOT 200 responses — surface every problem at once
```bash
grep -v '200' ~/webstore/logs/access.log
```

**What to observe:** this one command shows every non-successful request. 201, 404, 403, 500 — all visible immediately.

6. Search recursively across all webstore logs
```bash
grep -r 'ERROR' ~/webstore/logs/
```

7. Match only the whole word ERROR — not ERRORCODE or ERRORS
```bash
grep -w 'ERROR' ~/webstore/logs/error.log
```

---

## Section 3 — find and locate

**Goal:** locate files by type, size, and age the way you would when cleaning up a server.

1. Find all log files under webstore
```bash
find ~/webstore -name "*.log"
```

2. Find only regular files — not directories
```bash
find ~/webstore -type f
```

3. Find only directories
```bash
find ~/webstore -type d
```

4. Find files smaller than 1KB
```bash
find ~/webstore -type f -size -1k
```

5. Find files modified in the last 1 day
```bash
find ~/webstore -type f -mtime -1
```

6. Update the locate database and search
```bash
sudo updatedb
locate access.log
```

---

## Section 4 — cut, sort, uniq: Rank the Logs

**Goal:** extract columns, sort, and find patterns — answer who is hitting the API and how often.

1. Extract only the IP addresses — field 1
```bash
cut -d' ' -f1 ~/webstore/logs/access.log
```

2. Extract IP and status code together — fields 1 and 4
```bash
cut -d' ' -f1,4 ~/webstore/logs/access.log
```

3. Sort the IP addresses alphabetically
```bash
cut -d' ' -f1 ~/webstore/logs/access.log | sort
```

4. Count how many requests each IP made — ranked highest first
```bash
cut -d' ' -f1 ~/webstore/logs/access.log | sort | uniq -c | sort -nr
```

**What to observe:** `192.168.1.10` made 3 requests — the most active IP. This is the pipeline interviewers ask about.

5. Rank status codes by frequency
```bash
cut -d' ' -f4 ~/webstore/logs/access.log | sort | uniq -c | sort -nr
```

**What to observe:** 200 appears 5 times, 500 appears twice. At a glance you know 20% of requests are failing.

6. Find the most requested endpoints
```bash
cut -d' ' -f3 ~/webstore/logs/access.log | sort | uniq -c | sort -nr
```

---

## Section 5 — sed: Transform the Config and Logs

**Goal:** edit files and transform streams without opening an editor.

1. Replace `production` with `staging` — preview only, file unchanged
```bash
sed 's/production/staging/' ~/webstore/config/webstore.conf
```

2. Replace it in-place — actually save the change
```bash
sed -i 's/production/staging/' ~/webstore/config/webstore.conf
cat ~/webstore/config/webstore.conf
```

3. Change it back
```bash
sed -i 's/staging/production/' ~/webstore/config/webstore.conf
```

4. Print only lines containing ERROR from the error log
```bash
sed -n '/ERROR/p' ~/webstore/logs/error.log
```

5. Delete all INFO lines — preview only
```bash
sed '/INFO/d' ~/webstore/logs/error.log
```

6. Replace the port number on a specific line only
```bash
sed '2 s/5432/5433/' ~/webstore/config/webstore.conf
```

7. Append a new config entry at the end of the file
```bash
sed -i '$a\log_level=debug' ~/webstore/config/webstore.conf
cat ~/webstore/config/webstore.conf
```

8. Run two substitutions in one pass
```bash
sed -e 's/webstore-db/db-primary/' -e 's/webstore-api/api-v2/' ~/webstore/config/webstore.conf
```

---

## Section 6 — awk: Structured Log Analysis

**Goal:** extract fields, filter rows, and compute values from the access log.

1. Print only the IP address — field 1
```bash
awk '{ print $1 }' ~/webstore/logs/access.log
```

2. Print IP, method, and status code — fields 1, 2, 4
```bash
awk '{ print $1, $2, $4 }' ~/webstore/logs/access.log
```

3. Print only lines where status code is exactly 500
```bash
awk '$4 == "500" { print }' ~/webstore/logs/access.log
```

**What to observe:** this matches only on field 4 — more precise than `grep '500'` which would also match if 500 appeared in a URL.

4. Print IP and endpoint for 500 errors only
```bash
awk '$4 == "500" { print $1, $3 }' ~/webstore/logs/access.log
```

5. Print line numbers with each entry
```bash
awk '{ print NR, $0 }' ~/webstore/logs/access.log
```

6. Print only ERROR lines from the error log
```bash
awk '/ERROR/ { print }' ~/webstore/logs/error.log
```

7. Use awk with a custom field separator on the config file
```bash
awk -F '=' '{ print "KEY:", $1, "VALUE:", $2 }' ~/webstore/config/webstore.conf
```

---

## Section 7 — awk Arithmetic: Answer the Real Questions

**Goal:** use awk's arithmetic to compute totals and averages from the access log — the thing grep and cut cannot do.

1. Count how many 500 errors occurred
```bash
awk '$4 == "500" { count++ } END { print "500 errors:", count }' ~/webstore/logs/access.log
```

2. Sum total bytes transferred across all requests
```bash
awk '{ total += $5 } END { print "Total bytes:", total }' ~/webstore/logs/access.log
```

3. Calculate average bytes per request
```bash
awk '{ total += $5 } END { print "Average bytes:", total/NR }' ~/webstore/logs/access.log
```

4. Sum bytes for successful requests only
```bash
awk '$4 == "200" { total += $5 } END { print "Bytes from 200s:", total }' ~/webstore/logs/access.log
```

5. Count requests per IP using an associative array
```bash
awk '{ count[$1]++ } END { for (ip in count) print count[ip], ip }' ~/webstore/logs/access.log | sort -nr
```

**What to observe:** this is the awk pattern that replaces `cut | sort | uniq -c`. It works even when the data is not sorted.

6. Print a formatted incident summary
```bash
awk '
  BEGIN { print "--- Webstore Incident Report ---" }
  $4 == "500" { errors++; print "ERROR:", $1, $3 }
  END { print "Total 500 errors:", errors }
' ~/webstore/logs/access.log
```

---

## Section 8 — Piping It All Together

**Goal:** combine everything to answer real incident questions in one command.

1. How many unique IPs hit the API?
```bash
cut -d' ' -f1 ~/webstore/logs/access.log | sort -u | wc -l
```

2. Which endpoint had the most 500 errors?
```bash
awk '$4 == "500" { print $3 }' ~/webstore/logs/access.log | sort | uniq -c | sort -nr
```

3. Save all error lines to a separate file and still see them on screen
```bash
grep 'ERROR' ~/webstore/logs/error.log | tee ~/webstore/logs/errors-only.log
cat ~/webstore/logs/errors-only.log
```

4. Count total requests vs errors
```bash
echo "Total requests:"
wc -l < ~/webstore/logs/access.log
echo "500 errors:"
grep -c '500' ~/webstore/logs/access.log
```

5. Full incident summary — most active IPs, top failing endpoints, total bytes
```bash
echo "=== Top IPs ==="
cut -d' ' -f1 ~/webstore/logs/access.log | sort | uniq -c | sort -nr

echo "=== Failing Endpoints ==="
awk '$4 != "200" && $4 != "201" { print $3, $4 }' ~/webstore/logs/access.log | sort | uniq -c | sort -nr

echo "=== Total Bytes Transferred ==="
awk '{ total += $5 } END { print total, "bytes" }' ~/webstore/logs/access.log
```

---

## Section 9 — Break It on Purpose

### Break 1 — grep with no pattern

```bash
grep ~/webstore/logs/access.log
```

**What to observe:** error — grep requires a pattern before the file

### Break 2 — sed with unmatched delimiter

```bash
sed 's/production/staging ~/webstore/config/webstore.conf
```

**What to observe:** `unterminated s command` — the closing `/` is missing

### Break 3 — awk wrong field number

```bash
awk '{ print $10 }' ~/webstore/logs/access.log
```

**What to observe:** blank output — field 10 does not exist. awk prints an empty string silently instead of an error. This is a common source of confusion when awk pipelines produce no output.

### Break 4 — sed -i without backup on macOS

On macOS, `sed -i` requires an empty string argument:
```bash
sed -i '' 's/production/staging/' ~/webstore/config/webstore.conf
```

Without the `''` on macOS it fails. On Linux it works without it. This is a real cross-platform gotcha in deploy scripts.

---

## Checklist

Do not move to Lab 03 until every box is checked.

- [ ] I used `grep -c` to count 500 errors and `grep -v` to exclude 200s — I know the difference
- [ ] I used `find` to locate files by type, size, and modification time
- [ ] I piped `cut | sort | uniq -c | sort -nr` and read which IP made the most requests
- [ ] I used `sed -i` to edit a file in-place and confirmed the change with `cat`
- [ ] I used `sed -n '/PATTERN/p'` to print only matching lines
- [ ] I used `awk '$4 == "500"'` to filter by field value — not `grep '500'` — and explained why they are different
- [ ] I used `awk '{ total += $5 } END { print total }'` to sum bytes across all log lines
- [ ] I used awk's associative array `count[$1]++` to count requests per IP
- [ ] I built the full incident summary pipeline in Section 8 step 5 and read its output
- [ ] I produced all 4 break-it errors and read what each one means
