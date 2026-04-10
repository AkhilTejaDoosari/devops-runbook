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

# Service Management

A service is a process that runs in the background without any user interaction — started at boot, running continuously, doing its job silently until something goes wrong. nginx serving the webstore frontend is a service. The SSH daemon that lets you log into the server remotely is a service. The process collecting logs is a service.

On modern Linux systems, all of these are managed by `systemd` — the same process that took control after the kernel booted (PID 1). Every service you start, stop, enable, or debug goes through `systemctl`, systemd's command-line interface.

---

## Table of Contents

- [1. Services and Daemons](#1-services-and-daemons)
- [2. systemd — How It Manages Services](#2-systemd--how-it-manages-services)
- [3. systemctl — The Control Interface](#3-systemctl--the-control-interface)
- [4. restart vs reload — The Critical Distinction](#4-restart-vs-reload--the-critical-distinction)
- [5. journalctl — Reading Service Logs](#5-journalctl--reading-service-logs)
- [6. The Webstore nginx Lifecycle](#6-the-webstore-nginx-lifecycle)
- [7. Quick Reference](#7-quick-reference)

---

## 1. Services and Daemons

A **daemon** is a background process that was started at boot and keeps running until the system shuts down. The name comes from Unix tradition — daemons run silently in the background, invisible unless you look for them.

Every daemon has a config file that defines its behavior:

| Daemon | What it does | Config file |
|---|---|---|
| `nginx` | Serves web content — the webstore frontend | `/etc/nginx/nginx.conf` |
| `sshd` | Accepts incoming SSH connections | `/etc/ssh/sshd_config` |
| `cron` | Runs scheduled tasks | `/etc/crontab`, `/etc/cron.d/` |
| `journald` | Collects and stores all system logs | `/etc/systemd/journald.conf` |
| `postgresql` | Runs the webstore database | `/etc/postgresql/*/main/postgresql.conf` |

When you edit a config file, nothing changes until you tell the service to reload or restart. The running process in memory is using the old config until you explicitly apply the new one.

---

## 2. systemd — How It Manages Services

systemd manages services through **unit files** — text files that describe a service: what binary to run, what user to run it as, what other services it depends on, and whether it should restart automatically if it crashes.

Unit files live in `/lib/systemd/system/` (package-installed) and `/etc/systemd/system/` (custom overrides). You never edit these directly in normal operations — you use `systemctl` commands which call systemd on your behalf.

**Unit types you will encounter:**

| Unit type | File extension | Purpose |
|---|---|---|
| Service | `.service` | Background daemons — nginx, sshd, postgresql |
| Timer | `.timer` | Scheduled jobs — replacement for cron |
| Socket | `.socket` | Socket-activated services |
| Target | `.target` | Groups of units — defines boot states |

**System targets — what state the system boots into:**

| Target | Old runlevel | Purpose |
|---|---|---|
| `poweroff.target` | 0 | Shutdown |
| `rescue.target` | 1 | Single-user recovery mode |
| `multi-user.target` | 3 | Full CLI with networking — standard for servers |
| `graphical.target` | 5 | Multi-user with GUI — standard for desktops |
| `reboot.target` | 6 | Restart |

Servers run at `multi-user.target`. When you SSH into a cloud server, this is the target that brought up networking and SSH before you connected.

---

## 3. systemctl — The Control Interface

**Starting and stopping:**

```bash
# Start a service immediately — does not affect boot behavior
sudo systemctl start nginx

# Stop a running service
sudo systemctl stop nginx

# Restart — stop then start — drops all active connections
sudo systemctl restart nginx

# Reload — apply new config without dropping connections
sudo systemctl reload nginx
```

**Enabling and disabling at boot:**

```bash
# Enable — service will start automatically on next boot
sudo systemctl enable nginx

# Enable AND start immediately in one command
sudo systemctl enable --now nginx

# Disable — service will not start on boot
sudo systemctl disable nginx

# Disable AND stop immediately
sudo systemctl disable --now nginx
```

`enable` and `start` are independent. `enable` without `start` means it will start next boot but is not running now. `start` without `enable` means it is running now but will not start after a reboot. In production you almost always want both.

**Checking status:**

```bash
# Full status — active state, enabled state, recent log lines, PID
sudo systemctl status nginx

# Is it running right now?
systemctl is-active nginx
# active  or  inactive

# Will it start on boot?
systemctl is-enabled nginx
# enabled  or  disabled
```

**What `systemctl status` output tells you:**

```
● nginx.service - A high performance web server and a reverse proxy server
     Loaded: loaded (/lib/systemd/system/nginx.service; enabled; vendor preset: enabled)
     Active: active (running) since Sat 2025-04-05 09:14:22 UTC; 2h 3min ago
    Process: 1234 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
   Main PID: 1235 (nginx)
      Tasks: 2 (limit: 1136)
     CGroup: /system.slice/nginx.service
             ├─1235 nginx: master process /usr/sbin/nginx -g daemon on; master_process on;
             └─1236 nginx: worker process
```

Reading this output: `Loaded` tells you the unit file path and whether it is enabled. `Active` tells you current state and how long it has been running. `Main PID` is the process ID — you can use this with `kill` if needed. The `CGroup` section shows every process the service spawned.

**Listing services:**

```bash
# All active units
systemctl list-units

# Only services
systemctl list-units --type=service

# Only running services
systemctl list-units --type=service --state=running

# Services that failed
systemctl list-units --type=service --state=failed
```

`--state=failed` is the first thing you check when something stopped working and you are not sure which service died.

---

## 4. restart vs reload — The Critical Distinction

This distinction matters in production. Getting it wrong drops active connections.

**`restart`** — stops the process completely, then starts a fresh one. Any user currently connected to the service loses their connection. Use this when a config change requires a full process restart, or when a service is misbehaving and needs to be killed and restarted clean.

**`reload`** — sends a signal to the running process asking it to re-read its config file. The process stays running. Active connections are not dropped. nginx supports reload — it spins up new worker processes with the new config while old workers finish serving their current requests, then exits gracefully.

```bash
# You edited nginx.conf — test it first, then reload
sudo nginx -t                    # test syntax — always do this first
sudo systemctl reload nginx      # apply without dropping connections

# nginx is consuming too much memory and not responding — restart it
sudo systemctl restart nginx     # drops connections, starts fresh
```

**The rule:** for config changes on a running production server, always try `reload` first. Only use `restart` when `reload` is not supported or when the service needs to be killed.

---

## 5. journalctl — Reading Service Logs

systemd collects all service output in a centralized journal. `journalctl` is how you read it. This is where you look when a service fails to start or behaves unexpectedly.

```bash
# View all logs for nginx — most recent at bottom
journalctl -u nginx

# Follow live — new lines appear as they are written
journalctl -u nginx -f

# Show only the last 50 lines
journalctl -u nginx -n 50

# Show logs since boot
journalctl -u nginx -b

# Show logs from the last hour
journalctl -u nginx --since "1 hour ago"

# Show logs between two timestamps
journalctl -u nginx --since "2025-04-05 09:00" --until "2025-04-05 10:00"

# Show only error-level messages
journalctl -u nginx -p err

# View logs for a failed service immediately after it dies
journalctl -u nginx -n 100 --no-pager
```

**The debug loop when a service fails to start:**

```bash
sudo systemctl start nginx          # attempt to start
sudo systemctl status nginx         # see if it started or failed
journalctl -u nginx -n 50          # read what went wrong
# fix the problem
sudo nginx -t                       # verify the config is valid
sudo systemctl start nginx          # try again
```

`journalctl -u nginx -n 50` after a failed start shows you the exact error message that caused the failure. This is faster than grepping log files.

---

## 6. The Webstore nginx Lifecycle

This is the complete sequence from installation to serving the webstore frontend — every step in order.

```bash
# Step 1 — install nginx
sudo apt update && sudo apt install -y nginx

# Step 2 — confirm it installed and check version
nginx -v
# nginx version: nginx/1.24.0

# Step 3 — check status — nginx auto-starts after install on Ubuntu
sudo systemctl status nginx
# Active: active (running)

# Step 4 — test the default page
curl http://localhost
# Returns the nginx welcome page HTML

# Step 5 — create the webstore frontend directory
sudo mkdir -p /var/www/webstore-frontend
echo "<h1>webstore-frontend is live</h1>" | sudo tee /var/www/webstore-frontend/index.html

# Step 6 — create an nginx site config for webstore
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

# Step 7 — enable the site by creating a symlink
sudo ln -s /etc/nginx/sites-available/webstore /etc/nginx/sites-enabled/webstore

# Step 8 — disable the default site to avoid conflict
sudo rm /etc/nginx/sites-enabled/default

# Step 9 — test the config — always before reload or restart
sudo nginx -t
# nginx: configuration file /etc/nginx/nginx.conf test is successful

# Step 10 — reload nginx to apply the new config without dropping connections
sudo systemctl reload nginx

# Step 11 — verify it is serving the webstore
curl http://localhost
# <h1>webstore-frontend is live</h1>

# Step 12 — enable nginx to survive reboots
sudo systemctl enable nginx
# Created symlink /etc/systemd/system/multi-user.target.wants/nginx.service

# Step 13 — confirm enabled
systemctl is-enabled nginx
# enabled
```

**The sites-available / sites-enabled pattern:**
nginx config files live in `sites-available/` — all of them, enabled or not. `sites-enabled/` contains only symlinks to the configs that are active. To disable a site you remove the symlink. To enable a site you create one. The actual config file is never touched. This is the same symlink pattern from the permissions file.

---

## 7. Quick Reference

| Command | What it does |
|---|---|
| `sudo systemctl start <svc>` | Start service now |
| `sudo systemctl stop <svc>` | Stop service now |
| `sudo systemctl restart <svc>` | Stop and start — drops connections |
| `sudo systemctl reload <svc>` | Reload config — no dropped connections |
| `sudo systemctl enable <svc>` | Start on boot |
| `sudo systemctl enable --now <svc>` | Enable AND start now |
| `sudo systemctl disable <svc>` | Do not start on boot |
| `sudo systemctl status <svc>` | Full status — state, PID, recent logs |
| `systemctl is-active <svc>` | active or inactive |
| `systemctl is-enabled <svc>` | enabled or disabled |
| `systemctl list-units --type=service --state=running` | All running services |
| `systemctl list-units --type=service --state=failed` | All failed services |
| `journalctl -u <svc> -f` | Follow live logs |
| `journalctl -u <svc> -n 50` | Last 50 log lines |
| `journalctl -u <svc> -p err` | Error-level messages only |
| `sudo nginx -t` | Test nginx config syntax before applying |

---

→ Ready to practice? [Go to Lab 04](../linux-labs/04-archive-packages-services-lab.md)
