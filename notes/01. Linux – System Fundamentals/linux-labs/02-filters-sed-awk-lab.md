[Home](../README.md) |
[Labs Index](./README.md) |
[Lab 01](./01-boot-basics-files-lab.md) |
[Lab 02](./02-filters-sed-awk-lab.md) |
[Lab 03](./03-vim-users-permissions-lab.md) |
[Lab 04](./04-archive-packages-services-lab.md) |
[Lab 05](./05-networking-lab.md)

---

# Lab 02 — Filters, sed & awk

## What this lab is about

You will search the webstore logs using grep, find files by size and age, extract and sort data with cut, sort, and uniq, transform log content with sed, and analyze structured data with awk. By the end you will be able to debug a log file the way a real DevOps engineer does — without opening it in an editor. Every command is typed from scratch.

## Prerequisites

- [Filter Commands notes](../04-filter-commands/README.md)
- [sed notes](../05-sed-stream-editor/README.md)
- [awk notes](../06-awk/README.md)
- Lab 01 completed — `~/webstore/` directory must exist

---

## Section 1 — Set Up the Lab Files

**Goal:** create realistic webstore log and config files to work with.

1. Write a proper access log
```bash
cat > ~/webstore/logs/access.log << 'EOF'
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

3. Write a webstore config file
```bash
cat > ~/webstore/config/webstore.conf << 'EOF'
db_host=webstore-db
db_port=27017
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

3. Show line numbers with matches
```bash
grep -n 'ERROR' ~/webstore/logs/error.log
```

4. Count how many 500 errors occurred
```bash
grep -c '500' ~/webstore/logs/access.log
```

5. Show all lines that are NOT 200 responses
```bash
grep -v '200' ~/webstore/logs/access.log
```

6. Search recursively across all webstore logs
```bash
grep -r 'ERROR' ~/webstore/logs/
```

7. Match only the word ERROR (not ERRORCODE etc.)
```bash
grep -w 'ERROR' ~/webstore/logs/error.log
```

---

## Section 3 — find and locate

**Goal:** locate files by type, size, and age.

1. Find all log files under webstore
```bash
find ~/webstore -name "*.log"
```

2. Find only regular files (not directories)
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

## Section 4 — cut, sort, uniq: Analyze the Access Log

**Goal:** extract columns, sort, and find duplicate patterns.

1. Extract only the IP addresses (field 1)
```bash
cut -d' ' -f1 ~/webstore/logs/access.log
```

2. Extract IP and status code (fields 1 and 4)
```bash
cut -d' ' -f1,4 ~/webstore/logs/access.log
```

3. Sort the IP addresses alphabetically
```bash
cut -d' ' -f1 ~/webstore/logs/access.log | sort
```

4. Sort and count how many requests each IP made
```bash
cut -d' ' -f1 ~/webstore/logs/access.log | sort | uniq -c
```

5. Sort by most requests first (numeric reverse)
```bash
cut -d' ' -f1 ~/webstore/logs/access.log | sort | uniq -c | sort -nr
```

6. Find duplicate status codes
```bash
cut -d' ' -f4 ~/webstore/logs/access.log | sort | uniq -c | sort -nr
```

**What to observe:** which IP made the most requests, which status codes appeared most often.

---

## Section 5 — sed: Transform the Config and Logs

**Goal:** edit files and transform streams without opening an editor.

1. Replace `production` with `staging` in the config (preview only)
```bash
sed 's/production/staging/' ~/webstore/config/webstore.conf
```

2. Replace it in-place (actually save the change)
```bash
sed -i 's/production/staging/' ~/webstore/config/webstore.conf
cat ~/webstore/config/webstore.conf
```

3. Change it back
```bash
sed -i 's/staging/production/' ~/webstore/config/webstore.conf
```

4. Print only lines containing 'ERROR' from the error log
```bash
sed -n '/ERROR/p' ~/webstore/logs/error.log
```

5. Delete all INFO lines from the error log (preview only)
```bash
sed '/INFO/d' ~/webstore/logs/error.log
```

6. Replace the port number on a specific line only
```bash
sed '2 s/27017/27018/' ~/webstore/config/webstore.conf
```

7. Append a new config line at the end of the file
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

**Goal:** extract and filter log data using awk's field-based model.

1. Print every line of the access log (like cat)
```bash
awk '{ print }' ~/webstore/logs/access.log
```

2. Print only the IP address (field 1)
```bash
awk '{ print $1 }' ~/webstore/logs/access.log
```

3. Print IP, method, and status code (fields 1, 2, 4)
```bash
awk '{ print $1, $2, $4 }' ~/webstore/logs/access.log
```

4. Print only lines with status 500
```bash
awk '$4 == "500" { print }' ~/webstore/logs/access.log
```

5. Print only lines with status 500 — show IP and endpoint
```bash
awk '$4 == "500" { print $1, $3 }' ~/webstore/logs/access.log
```

6. Print line numbers with each log entry
```bash
awk '{ print NR, $0 }' ~/webstore/logs/access.log
```

7. Print the number of fields per line
```bash
awk '{ print NF }' ~/webstore/logs/access.log
```

8. Print only ERROR lines from the error log
```bash
awk '/ERROR/ { print }' ~/webstore/logs/error.log
```

9. Print only lines longer than 40 characters
```bash
awk 'length($0) > 40' ~/webstore/logs/access.log
```

---

## Section 7 — Piping It All Together

**Goal:** combine commands to answer real questions about the logs.

1. How many unique IPs hit the API?
```bash
cut -d' ' -f1 ~/webstore/logs/access.log | sort -u | wc -l
```

2. Which endpoint had the most 500 errors?
```bash
awk '$4 == "500" { print $3 }' ~/webstore/logs/access.log | sort | uniq -c | sort -nr
```

3. Save all error lines to a separate file
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

---

## Section 8 — Break It on Purpose

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

**What to observe:** blank output — field 10 doesn't exist, awk prints empty string silently

---

## Checklist

Do not move to Lab 03 until every box is checked.

- [ ] I used `grep -c` to count 500 errors and `grep -v` to exclude 200s — I know the difference
- [ ] I used `find` to locate files by type, size, and modification time
- [ ] I piped `cut | sort | uniq -c | sort -nr` and read which IP made the most requests
- [ ] I used `sed -i` to edit a file in-place and confirmed the change with `cat`
- [ ] I used `sed -n '/PATTERN/p'` to print only matching lines
- [ ] I used `awk '$4 == "500"'` to filter log entries by field value
- [ ] I used `awk '{ print NR, $0 }'` and understood what NR means
- [ ] I combined grep, awk, and tee in a single pipeline and saved output to a file
- [ ] I produced all 3 break-it errors and read what each one means
