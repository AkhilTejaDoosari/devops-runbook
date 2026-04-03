[🏠 Home](../README.md) | 
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

# 🐧 Service Management

## Table of Contents

* [1. Introduction to Services](#1-introduction-to-services)
* [2. Role of systemd](#2-role-of-systemd)
* [3. Managing Services with `systemctl`](#3-managing-services-with-systemctl)
* [4. Practical: Managing nginx with systemctl](#4-practical-managing-nginx-with-systemctl)
* [5. Quick Command Summary](#5-quick-command-summary)

---

<details>
<summary><strong>1. Introduction to Services</strong></summary>

## Theory & Notes

* A **service** is a background process that performs tasks automatically and continuously.
* These are also known as **daemons**.
* Examples include:

  * Web servers (`nginx`)
  * Databases (`mysqld`)
  * Schedulers (`cron`)
  * Loggers (`journald`)

### Legacy Approach – SysVinit

* Used in older Linux systems to start services during boot.
* Struggled with service dependency management.
* Example: A web server might start before MySQL is ready, causing errors.

### Modern Replacement – systemd

* Handles boot process and manages all services.
* Provides:

  * Parallel service startup
  * Dependency resolution
  * Centralized logging

### What are daemons?

* Specialized background processes started at boot.
* Examples:

  * `sshd`: Secure remote login
  * `crond`: Scheduled tasks
  * `nginx`: Web server
  * `mysqld`: Database engine
  * `journald`: System logs collector
* Daemons use config files to define behavior
  (e.g., `/etc/ssh/sshd_config` for `sshd`, `/etc/nginx/nginx.conf` for `nginx`).

</details>

---

<details>
<summary><strong>2. Role of systemd</strong></summary>

## Theory & Notes

* **systemd** is the first process started by the kernel (PID 1).
* It manages:

  * Boot process
  * All services (start, stop, restart)
  * User sessions and power
  * Resource control with cgroups
  * Logging with `journalctl`

### Key Features

* **Units**: systemd uses unit files to manage resources.

  * `.service` – background daemons
  * `.socket` – IPC sockets that can auto-start services
  * `.path` – watches paths and triggers services
  * `.timer` – schedules jobs like cron

### System Targets (Replacing Runlevels)

| Runlevel | systemd Target    | Purpose             |
| -------- | ----------------- | ------------------- |
| 0        | poweroff.target   | Shutdown            |
| 1        | rescue.target     | Single-user mode    |
| 3        | multi-user.target | CLI with networking |
| 5        | graphical.target  | GUI login           |
| 6        | reboot.target     | Reboot              |

</details>

---

<details>
<summary><strong>3. Managing Services with <code>systemctl</code></strong></summary>

## Theory & Notes

### Start/Stop/Restart/Reload

| Command                   | Description                        |
| ------------------------- | ---------------------------------- |
| `systemctl start <svc>`   | Start service immediately          |
| `systemctl stop <svc>`    | Stop a running service             |
| `systemctl restart <svc>` | Restart (stop + start)             |
| `systemctl reload <svc>`  | Reload config without full restart |

### Enable/Disable at Boot

| Command                   | Description                           |
| ------------------------- | ------------------------------------- |
| `systemctl enable <svc>`  | Auto-start service on boot            |
| `systemctl disable <svc>` | Prevent service from starting on boot |

### Check Status

| Command                      | Description             |
| ---------------------------- | ----------------------- |
| `systemctl status <svc>`     | Detailed service status |
| `systemctl is-active <svc>`  | Is the service running? |
| `systemctl is-enabled <svc>` | Will it start on boot?  |

### List Services

| Command                                               | Description           |
| ----------------------------------------------------- | --------------------- |
| `systemctl list-units`                                | All active units      |
| `systemctl list-units --type=service`                 | Only services         |
| `systemctl list-units --type=service --state=running` | Only running services |

</details>

---

<details>
<summary><strong>4. Practical: Managing nginx with systemctl</strong></summary>

## Theory & Notes

nginx is the web server that will serve webstore-frontend in production.
This section teaches you to manage it as a systemd service — the same skill
you will use when deploying webstore to a real server.

---

### Install nginx

```bash
sudo apt update
sudo apt install nginx -y
```

### Check Version

```bash
nginx -v
```

### Check Status

```bash
sudo systemctl status nginx
```

If not running:

```bash
sudo systemctl start nginx
```

Enable on boot:

```bash
sudo systemctl enable nginx
```

Test it is serving:

```bash
curl http://localhost
```

**What to observe:** nginx default welcome page returned

---

### Configure nginx to Serve webstore-frontend

Create the webstore-frontend directory:

```bash
sudo mkdir -p /var/www/webstore-frontend
```

Create a simple index page:

```bash
echo "<h1>webstore-frontend</h1>" | sudo tee /var/www/webstore-frontend/index.html
```

Edit the default nginx site config:

```bash
sudo nano /etc/nginx/sites-available/default
```

Change the `root` directive:

```nginx
# Change this:
root /var/www/html;

# To this:
root /var/www/webstore-frontend;
```

### Test the Config

```bash
sudo nginx -t
```

**What to observe:** `syntax is ok` and `test is successful`

### Apply Config Changes

```bash
sudo systemctl reload nginx
```

### Verify the Change

```bash
curl http://localhost
```

**What to observe:** `<h1>webstore-frontend</h1>` — nginx is now serving the webstore frontend directory

---

### Stop and Disable nginx

```bash
sudo systemctl stop nginx
sudo systemctl disable nginx
```

Check status:

```bash
sudo systemctl status nginx
# Should show: inactive (dead)
```

</details>

---

<details>
<summary><strong>5. Quick Command Summary</strong></summary>

| Command                                               | Description                            |
| ----------------------------------------------------- | -------------------------------------- |
| `systemctl start <service>`                           | Start a service immediately            |
| `systemctl stop <service>`                            | Stop a running service                 |
| `systemctl restart <service>`                         | Restart a service                      |
| `systemctl reload <service>`                          | Reload config without stopping service |
| `systemctl enable <service>`                          | Enable service to auto-start on boot   |
| `systemctl disable <service>`                         | Disable service from starting on boot  |
| `systemctl status <service>`                          | Show detailed status of a service      |
| `systemctl is-active <service>`                       | Check if service is currently running  |
| `systemctl is-enabled <service>`                      | Check if service is enabled at boot    |
| `systemctl list-units`                                | List all active units                  |
| `systemctl list-units --type=service`                 | List only services                     |
| `systemctl list-units --type=service --state=running` | List only running services             |
| `nginx -v`                                            | Check nginx version                    |
| `sudo nginx -t`                                       | Validate nginx config syntax           |
| `curl http://localhost`                               | Fetch nginx landing page               |
| `sudo nano /etc/nginx/sites-available/default`        | Edit nginx site config                 |

</details>

→ Ready to practice? [Go to Lab 04](../linux-labs/04-archive-packages-services-lab.md)
