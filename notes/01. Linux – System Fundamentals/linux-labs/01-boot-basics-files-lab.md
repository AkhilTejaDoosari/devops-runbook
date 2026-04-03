[🏠 Home](../README.md) |
[Labs Index](./README.md) |
[Lab 01](./01-boot-basics-files-lab.md) |
[Lab 02](./02-filters-sed-awk-lab.md) |
[Lab 03](./03-vim-users-permissions-lab.md) |
[Lab 04](./04-archive-packages-services-lab.md) |
[Lab 05](./05-networking-lab.md)

---

# Lab 01 — Boot, Basics & Files

## What this lab is about

You will explore what happened during your system's boot process, navigate the Linux filesystem confidently, inspect system information, create and manipulate files and directories, and view file contents in multiple ways. Every command is typed from scratch.

## Prerequisites

- [Boot Process notes](../01-boot-process/README.md)
- [Basics notes](../02-basics/README.md)
- [Working with Files notes](../03-working-with-files/README.md)
- A Linux system (Ubuntu VM, WSL, or EC2 instance)

---

## Section 1 — Boot Process Inspection

**Goal:** see evidence of the boot process on your running system.

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

4. Check what systemd target you booted into
```bash
systemctl get-default
```

5. List all currently active services
```bash
systemctl list-units --type=service --state=running
```

6. View GRUB config
```bash
cat /etc/default/grub
```

**What to observe:** the kernel version, active target, and which services systemd started automatically.

---

## Section 2 — Navigation and System Info

**Goal:** move around the filesystem and read system state.

1. Print your current directory
```bash
pwd
```

2. List files with full details
```bash
ls -lh
```

3. List including hidden files
```bash
ls -la
```

4. Show who is logged in
```bash
whoami
who
```

5. Check system uptime
```bash
uptime
```

6. Navigate to the root of the filesystem and explore
```bash
cd /
ls -lh
```

7. Navigate to /var/log and list what is there
```bash
cd /var/log
ls -lh
```

8. Go home
```bash
cd ~
pwd
```

---

## Section 3 — Create the Webstore Directory Structure

**Goal:** build a working directory that all future labs will use.

1. Create the webstore project structure in one command
```bash
mkdir -p ~/webstore/{frontend,api,db,logs,config,backup}
```

2. Confirm the structure
```bash
ls -lh ~/webstore/
```

3. Navigate into it and check your location
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

5. List the full structure
```bash
ls -lh ~/webstore/
ls -lh ~/webstore/logs/
```

---

## Section 4 — Working with Files

**Goal:** copy, move, rename, delete files and inspect them.

1. Write content into the config file
```bash
echo "db_host=webstore-db" > ~/webstore/config/webstore.conf
echo "db_port=27017" >> ~/webstore/config/webstore.conf
echo "api_port=8080" >> ~/webstore/config/webstore.conf
```

2. View the file
```bash
cat ~/webstore/config/webstore.conf
```

3. View with line numbers
```bash
cat -n ~/webstore/config/webstore.conf
```

4. Write some fake log entries
```bash
echo "192.168.1.10 GET /api/products 200" >> ~/webstore/logs/access.log
echo "192.168.1.11 POST /api/orders 201" >> ~/webstore/logs/access.log
echo "192.168.1.12 GET /api/products 200" >> ~/webstore/logs/access.log
echo "192.168.1.13 POST /api/orders 500" >> ~/webstore/logs/error.log
echo "192.168.1.14 DELETE /api/orders/7 403" >> ~/webstore/logs/error.log
```

5. Preview the first 2 lines of the access log
```bash
head -n 2 ~/webstore/logs/access.log
```

6. Preview the last 2 lines
```bash
tail -n 2 ~/webstore/logs/access.log
```

7. Page through the access log
```bash
less ~/webstore/logs/access.log
```
Press `q` to exit.

8. Copy the config file to backup
```bash
cp ~/webstore/config/webstore.conf ~/webstore/backup/webstore.conf.bak
```

9. Confirm the copy exists
```bash
ls -lh ~/webstore/backup/
```

10. Rename the backup file
```bash
mv ~/webstore/backup/webstore.conf.bak ~/webstore/backup/webstore.conf.backup
ls -lh ~/webstore/backup/
```

11. Inspect the file type and metadata
```bash
file ~/webstore/config/webstore.conf
stat ~/webstore/config/webstore.conf
```

---

## Section 5 — Break It on Purpose

### Break 1 — Delete a non-empty directory without -r

```bash
rm ~/webstore/backup
```

**What to observe:** `cannot remove: Is a directory` — `rm` alone cannot delete directories

Fix it:
```bash
rm -r ~/webstore/backup
mkdir ~/webstore/backup
```

### Break 2 — Navigate to a path that doesn't exist

```bash
cd ~/webstore/nonexistent
```

**What to observe:** `No such file or directory`

### Break 3 — Overwrite a file accidentally

```bash
echo "overwritten" > ~/webstore/config/webstore.conf
cat ~/webstore/config/webstore.conf
```

**What to observe:** the original content is gone — `>` overwrites, `>>` appends

Fix it — recreate the config:
```bash
echo "db_host=webstore-db" > ~/webstore/config/webstore.conf
echo "db_port=27017" >> ~/webstore/config/webstore.conf
echo "api_port=8080" >> ~/webstore/config/webstore.conf
```

---

## Section 6 — Getting Help

1. Read the manual for ls
```bash
man ls
```
Press `q` to exit.

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
- [ ] I created the full `~/webstore/` directory structure with one `mkdir -p` command
- [ ] I wrote to a file with `>` and appended with `>>` and understand the difference
- [ ] I used `head`, `tail`, `cat -n`, and `less` on the same file
- [ ] I copied, renamed, and deleted a file using `cp`, `mv`, and `rm`
- [ ] I tried to `rm` a directory without `-r` and read the error
- [ ] I used `stat` and `file` on a real file and read the output
