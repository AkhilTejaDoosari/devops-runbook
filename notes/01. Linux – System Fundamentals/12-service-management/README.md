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
* [4. Practical: Managing apache2 with systemctl](#4-practical-managing-apache2-with-systemctl)
* [5. Quick Command Summary](#5-quick-command-summary)

---

<details>
<summary><strong>1. Introduction to Services</strong></summary>

## Theory & Notes

* A **service** is a background process that performs tasks automatically and continuously.
* These are also known as **daemons**.
* Examples include:

  * Web servers (`httpd`)
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
  * `httpd`: Web server
  * `mysqld`: Database engine
  * `journald`: System logs collector
* Daemons use config files to define behavior
  (e.g., `/etc/ssh/sshd_config` for `sshd`).

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
<summary><strong>4. Practical: Managing apache2 with systemctl</strong></summary>

## Commands Used

### Install apache2

```bash
sudo apt update
sudo apt install apache2 -y
```

### Check Version

```bash
apache2 -v
```

### Check Status

```bash
sudo systemctl status apache2.service
```

If not running:

```bash
sudo systemctl start apache2.service
```

Enable on boot:

```bash
sudo systemctl enable apache2.service
```

---

### Edit Apache Config

```bash
sudo nano /etc/apache2/sites-available/000-default.conf
```

Change:

```bash
DocumentRoot /var/www/html
# to
DocumentRoot /var/www/custom_HTML
```

Create directory:

```bash
sudo mkdir /var/www/custom_HTML
```

Create index.html:

```bash
echo "Hello from custom_HTML" | sudo tee /var/www/custom_HTML/index.html
```

### Test Output

```bash
curl http://localhost
```

### Check Config

```bash
sudo apachectl configtest
# Should return: Syntax OK
```

### Apply Config Changes

```bash
sudo systemctl restart apache2.service
# or
sudo systemctl reload apache2.service
```

### Stop and Disable Apache2

```bash
sudo systemctl stop apache2.service
sudo systemctl disable apache2.service
```

Check status:

```bash
sudo systemctl status apache2.service
# Should show inactive (dead)
```

</details>

---

<details>
<summary><strong>5. Quick Command Summary</strong></summary>

| Command                                                   | Description                            |                                 |
| --------------------------------------------------------- | -------------------------------------- | ------------------------------- |
| `systemctl start <service>`                               | Start a service immediately            |                                 |
| `systemctl stop <service>`                                | Stop a running service                 |                                 |
| `systemctl restart <service>`                             | Restart a service                      |                                 |
| `systemctl reload <service>`                              | Reload config without stopping service |                                 |
| `systemctl enable <service>`                              | Enable service to auto-start on boot   |                                 |
| `systemctl disable <service>`                             | Disable service from starting on boot  |                                 |
| `systemctl status <service>`                              | Show detailed status of a service      |                                 |
| `systemctl is-active <service>`                           | Check if service is currently running  |                                 |
| `systemctl is-enabled <service>`                          | Check if service is enabled at boot    |                                 |
| `systemctl list-units`                                    | List all active units                  |                                 |
| `systemctl list-units --type=service`                     | List only services                     |                                 |
| `systemctl list-units --type=service --state=running`     | List only running services             |                                 |
| `apache2 -v`                                              | Check Apache version                   |                                 |
| `sudo apachectl configtest`                               | Validate Apache config syntax          |                                 |
| `curl http://localhost`                                   | Fetch Apache landing page              |                                 |
| `sudo nano /etc/apache2/sites-available/000-default.conf` | Edit Apache site config                |                                 |
| \`echo "..."                                              | sudo tee <file>\`                      | Create or write content as root |
| `sudo mkdir <dir>`                                        | Create directory with superuser rights |                                 |

</details>

---