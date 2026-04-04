[Home](../README.md) |
[Labs Index](./README.md) |
[Lab 01](./01-boot-basics-files-lab.md) |
[Lab 02](./02-filters-sed-awk-lab.md) |
[Lab 03](./03-vim-users-permissions-lab.md) |
[Lab 04](./04-archive-packages-services-lab.md) |
[Lab 05](./05-networking-lab.md)

---

# Lab 04 — Archive, Packages & Services

## What this lab is about

You will back up the webstore directory using tar and gzip, install nginx using the package manager, configure it to serve the webstore-frontend, manage it as a systemd service, and practice the full start/stop/enable/reload workflow. Every command is typed from scratch.

## Prerequisites

- [Archiving & Compression notes](../10-archiving-and-compression/README.md)
- [Package Management notes](../11-package-management/README.md)
- [Service Management notes](../12-service-management/README.md)
- Lab 01 completed — `~/webstore/` directory must exist
- sudo access on your system

---

## Section 1 — Archive the Webstore Directory

**Goal:** create a compressed backup of the webstore project.

1. Check what is in the webstore directory before archiving
```bash
ls -lh ~/webstore/
```

2. Create a compressed tar archive of the entire webstore directory
```bash
tar -czvf ~/webstore-backup.tar.gz ~/webstore/
```

3. Confirm the archive was created
```bash
ls -lh ~/webstore-backup.tar.gz
```

4. View the contents of the archive without extracting
```bash
tar -tvf ~/webstore-backup.tar.gz
```

5. Test extraction into a temp directory
```bash
mkdir /tmp/webstore-restore
tar -xzvf ~/webstore-backup.tar.gz -C /tmp/webstore-restore/
ls -lh /tmp/webstore-restore/
```

6. Clean up the temp restore
```bash
rm -rf /tmp/webstore-restore
```

---

## Section 2 — Compress Individual Log Files

**Goal:** compress a log file, view it without extracting, then decompress it.

1. Compress the access log with gzip
```bash
gzip ~/webstore/logs/access.log
ls -lh ~/webstore/logs/
```

**What to observe:** `access.log` is replaced by `access.log.gz` — original is gone

2. View the compressed log without extracting
```bash
zcat ~/webstore/logs/access.log.gz
```

3. Try to read it with cat
```bash
cat ~/webstore/logs/access.log.gz
```

**What to observe:** garbled output — `cat` does not understand compressed files

4. Decompress it
```bash
gunzip ~/webstore/logs/access.log.gz
ls -lh ~/webstore/logs/
```

5. Zip multiple files into one archive
```bash
zip ~/webstore-logs.zip ~/webstore/logs/access.log ~/webstore/logs/error.log
ls -lh ~/webstore-logs.zip
```

6. View zip contents
```bash
unzip -l ~/webstore-logs.zip
```

---

## Section 3 — Package Management

**Goal:** install, verify, and remove packages cleanly.

1. Update the package index
```bash
sudo apt update
```

2. Check if nginx is already installed
```bash
which nginx
nginx -v
```

3. Install nginx
```bash
sudo apt install nginx -y
```

4. Confirm installation
```bash
nginx -v
which nginx
```

5. Check what was installed
```bash
dpkg -l | grep nginx
```

6. Install curl if not already present
```bash
sudo apt install curl -y
curl --version
```

---

## Section 4 — Manage nginx as a Service

**Goal:** control nginx using systemctl and understand the full service lifecycle.

1. Check nginx status (may not be running yet)
```bash
sudo systemctl status nginx
```

2. Start nginx
```bash
sudo systemctl start nginx
```

3. Check status again
```bash
sudo systemctl status nginx
```

**What to observe:** `active (running)` with a PID

4. Test it is serving
```bash
curl http://localhost
```

**What to observe:** nginx default welcome page HTML

5. Check if nginx starts automatically on boot
```bash
sudo systemctl is-enabled nginx
```

6. Enable it to start on boot
```bash
sudo systemctl enable nginx
sudo systemctl is-enabled nginx
```

---

## Section 5 — Configure nginx for webstore-frontend

**Goal:** point nginx at the webstore-frontend directory and reload the service.

1. Create the webstore-frontend directory
```bash
sudo mkdir -p /var/www/webstore-frontend
```

2. Create a simple frontend page
```bash
echo "<h1>webstore-frontend is live</h1>" | sudo tee /var/www/webstore-frontend/index.html
```

3. Edit the nginx default site config
```bash
sudo vim /etc/nginx/sites-available/default
```

Find the `root` directive and change it:
```nginx
# Change from:
root /var/www/html;

# To:
root /var/www/webstore-frontend;
```
Save and quit: `:wq`

4. Test the nginx config for syntax errors
```bash
sudo nginx -t
```

**What to observe:** `syntax is ok` and `test is successful` — if not, go back and fix the config

5. Reload nginx (apply config without downtime)
```bash
sudo systemctl reload nginx
```

6. Verify the change
```bash
curl http://localhost
```

**What to observe:** `<h1>webstore-frontend is live</h1>`

---

## Section 6 — Service Lifecycle Practice

**Goal:** run through every systemctl operation once deliberately.

1. Restart the service completely
```bash
sudo systemctl restart nginx
sudo systemctl status nginx
```

2. Stop the service
```bash
sudo systemctl stop nginx
sudo systemctl status nginx
```

**What to observe:** `inactive (dead)`

3. Confirm it is no longer serving
```bash
curl http://localhost
```

**What to observe:** `Connection refused`

4. Start it again
```bash
sudo systemctl start nginx
curl http://localhost
```

5. Disable it from starting on boot
```bash
sudo systemctl disable nginx
sudo systemctl is-enabled nginx
```

6. Re-enable it
```bash
sudo systemctl enable nginx
```

---

## Section 7 — Break It on Purpose

### Break 1 — Bad nginx config syntax

1. Open the nginx config and introduce a deliberate syntax error
```bash
sudo vim /etc/nginx/sites-available/default
```
Delete the semicolon from the end of the `root` line:
```nginx
root /var/www/webstore-frontend
```
Save: `:wq`

2. Test the config
```bash
sudo nginx -t
```

**What to observe:** `nginx: [emerg] invalid number of arguments` — config test catches errors before reload

3. Fix it — add the semicolon back and re-test
```bash
sudo vim /etc/nginx/sites-available/default
# restore: root /var/www/webstore-frontend;
sudo nginx -t
sudo systemctl reload nginx
```

### Break 2 — Extract archive to wrong path

```bash
tar -xzvf ~/webstore-backup.tar.gz -C /nonexistent/path/
```

**What to observe:** `Cannot open: No such file or directory` — target path must exist before extraction

### Break 3 — Install a non-existent package

```bash
sudo apt install webstore-server-pro
```

**What to observe:** `Unable to locate package` — package does not exist in the repos

---

## Checklist

Do not move to Lab 05 until every box is checked.

- [ ] I created a `.tar.gz` archive of the entire webstore directory and viewed its contents without extracting
- [ ] I extracted the archive into `/tmp` and confirmed all files were restored correctly
- [ ] I compressed a log file with gzip, viewed it with `zcat`, tried `cat` and saw garbled output, then decompressed it
- [ ] I ran `sudo apt update` before installing anything — I know why this matters
- [ ] I installed nginx and confirmed with `nginx -v` and `which nginx`
- [ ] I used `systemctl status`, `start`, `stop`, `restart`, `reload`, `enable`, `disable` on nginx
- [ ] I configured nginx to serve `/var/www/webstore-frontend` and confirmed with `curl http://localhost`
- [ ] I ran `sudo nginx -t` after every config change before reloading
- [ ] I introduced a config syntax error on purpose, caught it with `nginx -t`, and fixed it before reloading
- [ ] I confirmed `curl http://localhost` fails with connection refused when nginx is stopped
