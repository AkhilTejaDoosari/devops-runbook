[Home](../README.md) |
[Labs Index](./README.md) |
[Lab 01](./01-boot-basics-files-lab.md) |
[Lab 02](./02-filters-sed-awk-lab.md) |
[Lab 03](./03-vim-users-permissions-lab.md) |
[Lab 04](./04-archive-packages-services-lab.md) |
[Lab 05](./05-networking-lab.md)

---

# Lab 04 — Archive, Packages & Services

## The Situation

Today is deploy day. Before you change anything on the server you archive the current state of the webstore — if something goes wrong you can restore from the backup in minutes. Then you install nginx and configure it to serve the webstore frontend. When you are done nginx is running, serving the right content, enabled to survive a reboot, and you know how to read its logs when something goes wrong.

This is the lab where the webstore goes from being files on a disk to being a live service. Lab 05 picks up here — with nginx running — to verify and debug the network layer.

## What this lab covers

You will back up the webstore directory using tar and gzip, install nginx using the package manager, configure it to serve the webstore-frontend, manage it as a systemd service through the full lifecycle, read its logs with journalctl, and practice the break-fix cycle on a broken nginx config. Every command is typed from scratch.

## Prerequisites

- [Archiving & Compression notes](../10-archiving-and-compression/README.md)
- [Package Management notes](../11-package-management/README.md)
- [Service Management notes](../12-service-management/README.md)
- Lab 01 completed — `~/webstore/` directory must exist
- sudo access on your system

---

## Section 1 — Archive the Webstore Before the Deploy

**Goal:** create a timestamped compressed backup of the webstore project before touching anything.

1. Check what is in the webstore directory before archiving
```bash
ls -lh ~/webstore/
```

2. Create a compressed tar archive with a timestamp in the name
```bash
tar -czvf ~/webstore/backup/webstore-$(date +%Y-%m-%d).tar.gz \
    --exclude='~/webstore/backup' \
    ~/webstore/
```

3. Confirm the archive was created and note its size
```bash
ls -lh ~/webstore/backup/
```

4. View the contents of the archive without extracting — always verify before relying on a backup
```bash
tar -tvf ~/webstore/backup/webstore-$(date +%Y-%m-%d).tar.gz
```

**What to observe:** permissions, owner, size, and path of every file — all preserved in the archive.

5. Test extraction into a temp directory
```bash
mkdir /tmp/webstore-restore
tar -xzvf ~/webstore/backup/webstore-$(date +%Y-%m-%d).tar.gz -C /tmp/webstore-restore/
ls -lh /tmp/webstore-restore/
```

6. Clean up the temp restore
```bash
rm -rf /tmp/webstore-restore
```

---

## Section 2 — Compress Individual Log Files

**Goal:** compress a log file, view it without extracting, then decompress it.

1. Compress the access log — original is replaced
```bash
gzip ~/webstore/logs/access.log
ls -lh ~/webstore/logs/
```

**What to observe:** `access.log` is replaced by `access.log.gz` — the original is gone.

2. View the compressed log without extracting
```bash
zcat ~/webstore/logs/access.log.gz
```

3. Search inside the compressed log without extracting
```bash
zcat ~/webstore/logs/access.log.gz | grep '500'
```

4. Try to read it with cat
```bash
cat ~/webstore/logs/access.log.gz
```

**What to observe:** garbled output — `cat` does not understand compressed files.

5. Decompress it
```bash
gunzip ~/webstore/logs/access.log.gz
ls -lh ~/webstore/logs/
```

6. Zip multiple files into one archive
```bash
zip ~/webstore-logs.zip ~/webstore/logs/access.log ~/webstore/logs/error.log
ls -lh ~/webstore-logs.zip
```

7. View zip contents
```bash
unzip -l ~/webstore-logs.zip
```

---

## Section 3 — Package Management

**Goal:** install, verify, and understand the package manager workflow.

1. Update the package index — always before installing
```bash
sudo apt update
```

**What to observe:** apt fetches the latest package lists. This does NOT install anything — it only updates what apt knows is available.

2. Check if nginx is already installed
```bash
which nginx
nginx -v 2>/dev/null || echo "nginx not installed"
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

7. Search for a package you are not sure of the name for
```bash
apt search postgres | grep postgresql-client
```

---

## Section 4 — Manage nginx as a Service

**Goal:** control nginx using systemctl and understand the full service lifecycle.

1. Check nginx status — it may have auto-started after install
```bash
sudo systemctl status nginx
```

2. If not running, start it
```bash
sudo systemctl start nginx
```

3. Check status again — read every field in the output
```bash
sudo systemctl status nginx
```

**What to observe:** `Active: active (running)` with a PID. Note the `Loaded` line — it shows whether nginx is enabled for boot.

4. Confirm nginx is listening on port 80
```bash
sudo ss -tlnp | grep :80
```

5. Test it is serving
```bash
curl http://localhost
```

**What to observe:** nginx default welcome page HTML.

6. Check if nginx starts automatically on boot
```bash
systemctl is-enabled nginx
```

7. Enable it to start on boot
```bash
sudo systemctl enable nginx
systemctl is-enabled nginx
```

---

## Section 5 — Configure nginx for webstore-frontend

**Goal:** point nginx at the webstore-frontend directory and apply the change with reload — not restart.

1. Create the webstore-frontend directory
```bash
sudo mkdir -p /var/www/webstore-frontend
```

2. Create a simple frontend page
```bash
echo "<h1>webstore-frontend is live</h1>" | sudo tee /var/www/webstore-frontend/index.html
```

3. Create a dedicated nginx site config for the webstore
```bash
sudo tee /etc/nginx/sites-available/webstore << 'EOF'
server {
    listen 80;
    server_name localhost;
    root /var/www/webstore-frontend;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }

    access_log /var/log/nginx/webstore-access.log;
    error_log  /var/log/nginx/webstore-error.log;
}
EOF
```

4. Enable the webstore site by creating a symlink
```bash
sudo ln -s /etc/nginx/sites-available/webstore /etc/nginx/sites-enabled/webstore
```

5. Disable the default site to avoid conflict
```bash
sudo rm /etc/nginx/sites-enabled/default
```

6. Test the config — always before reload or restart
```bash
sudo nginx -t
```

**What to observe:** `syntax is ok` and `test is successful` — if not, go back and fix the config before proceeding.

7. Reload nginx — apply config without dropping connections
```bash
sudo systemctl reload nginx
```

8. Verify the change
```bash
curl http://localhost
```

**What to observe:** `<h1>webstore-frontend is live</h1>`

---

## Section 6 — Read nginx Logs with journalctl

**Goal:** use journalctl to read nginx service logs — the same way you debug any failed service.

1. View all nginx logs
```bash
journalctl -u nginx
```

2. Show only the last 20 lines
```bash
journalctl -u nginx -n 20
```

3. Follow nginx logs live — open in one terminal, make a request from another
```bash
journalctl -u nginx -f
```
In another terminal:
```bash
curl http://localhost
curl http://localhost/nonexistent
```

**What to observe:** each request appears in the journal as it happens.

4. Show only error-level messages
```bash
journalctl -u nginx -p err
```

5. Show logs since boot
```bash
journalctl -u nginx -b
```

---

## Section 7 — Service Lifecycle Practice

**Goal:** run through every systemctl operation once deliberately.

1. Restart the service completely — drops connections
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
systemctl is-enabled nginx
```

6. Re-enable it
```bash
sudo systemctl enable nginx
systemctl is-enabled nginx
```

---

## Section 8 — Break It on Purpose

### Break 1 — Bad nginx config syntax

1. Open the nginx site config and introduce a deliberate syntax error
```bash
sudo vim /etc/nginx/sites-available/webstore
```
Delete the semicolon from the end of the `root` line:
```nginx
root /var/www/webstore-frontend
```
Save: `:wq`

2. Test the config before reloading
```bash
sudo nginx -t
```

**What to observe:** `nginx: [emerg]` error — config test catches the error before it breaks the live service. This is why you always run `nginx -t` before reload.

3. Fix it — add the semicolon back and re-test
```bash
sudo vim /etc/nginx/sites-available/webstore
# restore: root /var/www/webstore-frontend;
sudo nginx -t
sudo systemctl reload nginx
```

### Break 2 — Extract archive to wrong path

```bash
tar -xzvf ~/webstore/backup/webstore-$(date +%Y-%m-%d).tar.gz -C /nonexistent/path/
```

**What to observe:** `Cannot open: No such file or directory` — the target path must exist before extraction.

### Break 3 — Install a non-existent package

```bash
sudo apt install webstore-server-pro
```

**What to observe:** `Unable to locate package` — the package does not exist in the repos. This is what happens when you forget to `apt update` first or misspell a package name.

### Break 4 — Reload nginx with a broken config

1. Break the config again
```bash
sudo vim /etc/nginx/sites-available/webstore
# delete a semicolon
```

2. Try to reload without testing first
```bash
sudo systemctl reload nginx
```

**What to observe:** the reload fails and nginx continues running with the old config — it does not crash. This is why reload is safer than restart for config changes: a bad config on reload keeps the old config running, whereas restart with a bad config stops the service entirely.

3. Read what went wrong
```bash
journalctl -u nginx -n 20
```

4. Fix and reload correctly
```bash
sudo vim /etc/nginx/sites-available/webstore
# fix the semicolon
sudo nginx -t
sudo systemctl reload nginx
```

---

## Checklist

Do not move to Lab 05 until every box is checked.

- [ ] I created a timestamped `.tar.gz` archive with `--exclude` and viewed its contents without extracting
- [ ] I extracted the archive into `/tmp` with `-C` and confirmed all files were restored
- [ ] I compressed a log file with gzip, searched it with `zcat | grep`, tried `cat` and saw garbled output, then decompressed it
- [ ] I ran `sudo apt update` before installing — I know this refreshes the index, not installs updates
- [ ] I installed nginx, confirmed with `nginx -v`, and checked the installed package with `dpkg -l`
- [ ] I created a dedicated nginx site config in `sites-available` and enabled it with a symlink in `sites-enabled`
- [ ] I ran `sudo nginx -t` before every reload and explained why
- [ ] I configured nginx to serve `/var/www/webstore-frontend` and confirmed with `curl http://localhost`
- [ ] I used `journalctl -u nginx -f` and watched log entries appear while making curl requests
- [ ] I used `systemctl status`, `start`, `stop`, `restart`, `reload`, `enable`, `disable` on nginx — I know the difference between restart and reload
- [ ] I introduced a config syntax error, tested it with `nginx -t`, and fixed it before reloading
- [ ] I confirmed that `curl http://localhost` fails with `Connection refused` when nginx is stopped
