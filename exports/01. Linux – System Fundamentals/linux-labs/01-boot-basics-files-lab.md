[Home](../README.md) |
[Labs Index](./README.md) |
[Lab 01](./01-boot-basics-files-lab.md) |
[Lab 02](./02-filters-sed-awk-lab.md) |
[Lab 03](./03-vim-users-permissions-lab.md) |
[Lab 04](./04-archive-packages-services-lab.md) |
[Lab 05](./05-networking-lab.md)

---

# Lab 01 — Boot, Basics & Files

## The Situation

This is day one. You have a blank Linux server and a project idea — a three-tier webstore application. Before any code is written, before Docker is involved, before Git tracks a single file, you need to build the foundation on disk.

By the end of this lab the webstore project exists as an organized directory structure on the server. Config files are written. Log files are seeded. The project is ready to be handed to every tool that follows. This is what Lab 02 picks up from — a real project with real files to search and transform.

## What this lab covers

You will inspect the boot process to understand the system that just started, navigate the Linux filesystem with confidence, build the webstore directory structure from scratch, write config and log files, and practice every file operation you will use on servers from this point forward. Every command is typed from scratch.

## Prerequisites

- [Boot Process notes](../01-boot-process/README.md)
- [Basics notes](../02-basics/README.md)
- [Working with Files notes](../03-working-with-files/README.md)
- A Linux system (Ubuntu VM, WSL, or EC2 instance)

---

## Section 1 — Boot Process Inspection

**Goal:** see evidence of the boot process on your running system before you do anything else.

1. Check your kernel version
```bash
uname -r
```

2. Check all system info at once
```bash
uname -a
```

3. View boot-time kernel messages
```bash
dmesg | less
```
Scroll through — press `q` to exit. Look for lines mentioning hardware detection.

**What to observe:** the kernel detected and initialized hardware in sequence. Every line is the kernel reporting what it found.

4. Check what systemd target you booted into
```bash
systemctl get-default
```

**What to observe:** `multi-user.target` — the standard server boot target. No GUI.

5. List all currently active services
```bash
systemctl list-units --type=service --state=running
```

**What to observe:** identify at least 3 services systemd started automatically. These were all started by PID 1 before you logged in.

6. View GRUB config
```bash
cat /etc/default/grub
```

---

## Section 2 — Navigation and System Info

**Goal:** orient yourself on the server before touching anything.

1. Print your current directory
```bash
pwd
```

2. List files with full details including hidden files, human-readable sizes, sorted oldest-to-newest
```bash
ls -lahtr
```

**What to observe:** files starting with `.` are hidden — `.bashrc`, `.profile`, `.ssh/`. These are real config files that affect your environment. The output shows you owner, group, size, and timestamp for every file at once.

3. Show who is logged in
```bash
whoami
who
```

4. Check system uptime and load
```bash
uptime
```

**What to observe:** three load average numbers — 1 minute, 5 minute, 15 minute CPU demand. Numbers below your core count mean the system is healthy.

5. Navigate to the root of the filesystem and explore
```bash
cd /
ls -lahtr
```

**What to observe:** every directory under `/` serves a specific purpose — `/etc` for config, `/var` for variable data, `/home` for user directories, `/boot` for the kernel.

6. Navigate to /var/log and list what is there
```bash
cd /var/log
ls -lahtr
```

**What to observe:** this is where system services write their logs. Your webstore will write here too once nginx is running.

7. Go home
```bash
cd ~
pwd
```

---

## Section 3 — Create the Webstore Directory Structure

**Goal:** build the project's home on disk. Every future lab depends on this structure existing.

1. Create the full webstore structure in one command
```bash
mkdir -p ~/webstore/{frontend,api,db,logs,config,backup}
```

2. Confirm the structure
```bash
ls -lahtr ~/webstore/
```

3. Navigate into it and confirm your location
```bash
cd ~/webstore
pwd
```

4. Create placeholder files in each folder
```bash
touch frontend/index.html
touch api/server.js
touch db/schema.sql
touch logs/access.log
touch logs/error.log
touch config/webstore.conf
```

**Why each folder exists:**
- `frontend/` — static files nginx will serve
- `api/` — application code
- `db/` — database schemas
- `logs/` — access and error logs the running service writes
- `config/` — the config file the service reads at startup
- `backup/` — snapshots before deploys

5. List the full structure
```bash
ls -lahtr ~/webstore/
ls -lahtr ~/webstore/logs/
```

---

## Section 4 — Working with Files

**Goal:** write content into the webstore files, copy, move, rename, and inspect them.

1. Write the webstore config — note the difference between `>` and `>>`
```bash
echo "db_host=webstore-db" > ~/webstore/config/webstore.conf
echo "db_port=5432" >> ~/webstore/config/webstore.conf
echo "api_port=8080" >> ~/webstore/config/webstore.conf
echo "api_host=webstore-api" >> ~/webstore/config/webstore.conf
echo "frontend_port=80" >> ~/webstore/config/webstore.conf
echo "env=production" >> ~/webstore/config/webstore.conf
```

2. View the file
```bash
cat ~/webstore/config/webstore.conf
```

3. View with line numbers
```bash
cat -n ~/webstore/config/webstore.conf
```

4. Write realistic log entries
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

5. Preview the first 3 lines of the access log
```bash
head -n 3 ~/webstore/logs/access.log
```

6. Preview the last 3 lines
```bash
tail -n 3 ~/webstore/logs/access.log
```

7. Watch for new log entries in real time
```bash
tail -f ~/webstore/logs/access.log
```
Press `Ctrl+C` to stop. In a real incident you keep this running while triggering requests.

8. Page through the access log
```bash
less ~/webstore/logs/access.log
```
Press `q` to exit. Press `/500` to search for error entries.

9. Inspect the file metadata
```bash
file ~/webstore/config/webstore.conf
stat ~/webstore/config/webstore.conf
```

**What to observe in `stat` output:** three timestamps — Access, Modify, Change. Modify tells you when the content last changed. Change tells you when permissions or ownership last changed. These are different things.

10. Copy the config to backup before any changes — always use `-iv` for files
```bash
cp -iv ~/webstore/config/webstore.conf ~/webstore/backup/webstore.conf.bak
```

**What to observe:** `-v` confirms the copy happened and shows you exactly where it landed. `-i` would have prompted you if a backup already existed — protecting you from silently overwriting a previous snapshot.
```bash
ls -lahtr ~/webstore/backup/
```

11. Rename the backup to include a date marker — always use `-iv` for moves
```bash
mv -iv ~/webstore/backup/webstore.conf.bak ~/webstore/backup/webstore.conf.backup
ls -lahtr ~/webstore/backup/
```

**What to observe:** the terminal confirms `'webstore.conf.bak' -> 'webstore.conf.backup'` — you can see exactly what moved and where it landed.

---

## Section 5 — Break It on Purpose

### Break 1 — Delete a non-empty directory without -r
```bash
rm ~/webstore/backup
```

**What to observe:** `cannot remove: Is a directory` — `rm` alone cannot delete directories.

Fix it:
```bash
rm -r ~/webstore/backup
mkdir ~/webstore/backup
```

### Break 2 — Navigate to a path that does not exist
```bash
cd ~/webstore/nonexistent
```

**What to observe:** `No such file or directory`

### Break 3 — Overwrite a file accidentally with >
```bash
echo "overwritten" > ~/webstore/config/webstore.conf
cat ~/webstore/config/webstore.conf
```

**What to observe:** the entire config is gone — replaced with one word. `>` overwrites. `>>` appends. This is one of the most common accidental data losses on Linux servers.

Fix it — restore from backup using the gold standard so `-v` confirms the file landed correctly:
```bash
cp -iv ~/webstore/backup/webstore.conf.backup ~/webstore/config/webstore.conf
cat ~/webstore/config/webstore.conf
```

**What to observe:** `-i` prompts you before overwriting the damaged file — you confirm with `y`. `-v` then shows you the copy completed. You just did what a real restore looks like on a server.

### Break 4 — tail -f the wrong file
```bash
tail -f ~/webstore/logs/error.log
```

Add a line from another terminal while this is running:
```bash
echo "ERROR 2025-04-05 DB connection timeout" >> ~/webstore/logs/error.log
```

**What to observe:** the new line appears in the first terminal immediately — `tail -f` follows the file live. Press `Ctrl+C` to stop.

---

## Section 6 — Getting Help

1. Read the manual for ls
```bash
man ls
```
Press `/` to search, `n` for next match, `q` to exit.

2. One-line description of a command
```bash
whatis ls
whatis find
whatis grep
```

3. Find where a command lives
```bash
which nginx
which docker
which git
```

---

## Checklist

Do not move to Lab 02 until every box is checked.

- [ ] I ran `uname -r` and `dmesg | less` and saw real kernel boot output
- [ ] I used `systemctl list-units --type=service --state=running` and identified at least 3 running services
- [ ] I navigated to `/`, `/var/log`, and back to `~` without using the GUI
- [ ] I used `ls -lahtr` as my default listing command throughout the entire lab
- [ ] I created the full `~/webstore/` directory structure with one `mkdir -p` command and explained why each folder exists
- [ ] I wrote the webstore config using `>` for the first line and `>>` for every line after — and understand why
- [ ] I used `head`, `tail`, `cat -n`, and `less` on the same file
- [ ] I used `tail -f` to watch a file update in real time
- [ ] I read `stat` output and identified all three timestamps — Access, Modify, Change
- [ ] I used `cp -iv` to back up the config and `mv -iv` to rename it — not the bare versions
- [ ] I accidentally overwrote the config with `>` and restored it from backup using `cp -iv`
- [ ] I tried to `rm` a directory without `-r` and read the error
