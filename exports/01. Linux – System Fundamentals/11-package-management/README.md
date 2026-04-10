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

# Package Management

On a Linux server you never download software from a website and run an installer. You use the package manager — a tool that fetches verified software from trusted repositories, resolves all dependencies automatically, and tracks everything it installed so it can be cleanly removed later.

This is how nginx gets on the webstore server. One command. No manual download. No guessing which libraries it needs. The package manager handles all of it.

---

## Table of Contents

- [1. What a Package Manager Does](#1-what-a-package-manager-does)
- [2. APT — Debian and Ubuntu](#2-apt--debian-and-ubuntu)
- [3. YUM and DNF — RHEL CentOS Fedora](#3-yum-and-dnf--rhel-centos-fedora)
- [4. Comparing Package Managers](#4-comparing-package-managers)
- [5. The Webstore Install Workflow](#5-the-webstore-install-workflow)
- [6. Quick Reference](#6-quick-reference)

---

## 1. What a Package Manager Does

A **package** is a bundle containing everything a piece of software needs — the binary, its libraries, default config files, and documentation. The package manager handles four things you would otherwise do manually:

- **Installation** — downloads the package and puts every file in the right place
- **Dependency resolution** — figures out what other packages this one needs and installs those too
- **Verification** — checks GPG signatures to confirm the package has not been tampered with
- **Removal** — tracks every file that was installed so it can cleanly remove them later

Without a package manager you would download a tarball, manually install it, manually install its 12 dependencies, then discover you installed the wrong version of one of them. Package managers exist because that process does not scale.

**Two package ecosystems on Linux:**

| Ecosystem | Package format | Package manager | Used on |
|---|---|---|---|
| Debian | `.deb` | `apt` | Ubuntu, Debian — what this runbook uses |
| Red Hat | `.rpm` | `yum` / `dnf` | RHEL, CentOS, Fedora, Amazon Linux |

Ubuntu is what AWS EC2 defaults to and what this runbook uses throughout. You will see both ecosystems in real jobs — know both at the command level.

---

## 2. APT — Debian and Ubuntu

APT (Advanced Package Tool) is the package manager on Ubuntu. Its package lists live in `/etc/apt/sources.list` and `/etc/apt/sources.list.d/`. Before installing anything, you update the local index — this tells apt what versions are currently available in the repositories. The index is not updated automatically.

**The standard install sequence — always in this order:**

```bash
# Step 1 — refresh the package index
# This does NOT install anything — it just updates what apt knows is available
sudo apt update

# Step 2 — install the package
sudo apt install nginx

# What happens:
# apt resolves all nginx dependencies
# downloads nginx and every dependency
# installs them in the correct order
# creates the www-data user if it doesn't exist
# puts the default config in /etc/nginx/
# registers nginx as a systemd service
```

Never skip `apt update` before installing. Without it you might install a stale version, or apt might fail to find a dependency that was recently renamed.

**Full APT command set:**

| Command | What it does | When you reach for it |
|---|---|---|
| `sudo apt update` | Refresh package index — fetch latest available versions | Before every install or upgrade |
| `sudo apt install <pkg>` | Download and install a package and its dependencies | Installing nginx, curl, vim, git |
| `sudo apt install <pkg>=<version>` | Install a specific version | Pinning nginx to a version that matches production |
| `sudo apt upgrade -y` | Upgrade all installed packages to latest versions | Routine server maintenance |
| `sudo apt remove <pkg>` | Remove a package but keep its config files | Removing nginx while keeping `/etc/nginx/` for reinstall |
| `sudo apt purge <pkg>` | Remove a package and all its config files | Clean uninstall — nothing left behind |
| `sudo apt autoremove` | Remove packages that were installed as dependencies but are no longer needed | After removing a package that pulled in many deps |
| `sudo apt clean` | Delete downloaded `.deb` files from the local cache | Freeing disk space on a server with limited storage |
| `apt list --installed` | List all installed packages | Auditing what is on a server |
| `apt show <pkg>` | Show package details — version, size, dependencies | Checking what version is available before installing |
| `apt search <keyword>` | Search available packages by keyword | Finding the right package name when you are not sure |

**remove vs purge — when it matters:**
`apt remove nginx` removes the binary but leaves `/etc/nginx/` intact. If you reinstall nginx later, your config is still there. `apt purge nginx` removes everything including configs. Use `remove` when you plan to reinstall. Use `purge` for a complete clean uninstall.

---

## 3. YUM and DNF — RHEL CentOS Fedora

YUM is the package manager on older Red Hat systems (RHEL 7, CentOS 7). DNF replaced it on RHEL 8+, Fedora, and Amazon Linux 2023. The commands are nearly identical — DNF is faster and has better dependency resolution.

**YUM (CentOS / RHEL 7):**

```bash
sudo yum install nginx        # install
sudo yum update -y            # upgrade all packages
sudo yum remove nginx         # remove
sudo yum clean all            # clear all cached data
sudo yum list installed       # list installed packages
```

**DNF (Fedora / RHEL 8+ / Amazon Linux 2023):**

```bash
sudo dnf install nginx        # install
sudo dnf upgrade -y           # upgrade all packages
sudo dnf remove nginx         # remove
sudo dnf clean all            # clear all cached data
sudo dnf list installed       # list installed packages
```

The key difference from APT: YUM and DNF do not separate `update` (refresh index) from `upgrade` (install updates). `yum update` and `dnf upgrade` do both in one step.

---

## 4. Comparing Package Managers

| | APT | YUM | DNF |
|---|---|---|---|
| Used on | Ubuntu, Debian | CentOS, RHEL 7 | Fedora, RHEL 8+, Amazon Linux |
| Package format | `.deb` | `.rpm` | `.rpm` |
| Refresh index | `apt update` | Automatic with install | Automatic with install |
| Install | `apt install <pkg>` | `yum install <pkg>` | `dnf install <pkg>` |
| Upgrade all | `apt upgrade` | `yum update` | `dnf upgrade` |
| Remove | `apt remove <pkg>` | `yum remove <pkg>` | `dnf remove <pkg>` |
| Remove + configs | `apt purge <pkg>` | No direct equivalent | No direct equivalent |
| Clean cache | `apt clean` | `yum clean all` | `dnf clean all` |
| List installed | `apt list --installed` | `yum list installed` | `dnf list installed` |
| Repo config | `/etc/apt/sources.list` | `/etc/yum.repos.d/` | `/etc/yum.repos.d/` |

---

## 5. The Webstore Install Workflow

This is the sequence you run on a fresh Ubuntu server to get the webstore stack installed and ready.

```bash
# Start with a clean, updated index
sudo apt update

# Install nginx to serve the webstore frontend
sudo apt install -y nginx

# Confirm nginx installed and check its version
nginx -v
# nginx version: nginx/1.24.0

# Install useful tools for working with the webstore
sudo apt install -y curl vim git

# Install the postgresql client to connect to webstore-db
sudo apt install -y postgresql-client

# Verify what got installed
apt list --installed | grep -E 'nginx|curl|vim|git|postgresql'

# Check disk space after installs
df -h

# Clean up downloaded package files — good habit after large installs
sudo apt clean
sudo apt autoremove
```

**Why `-y` on some installs:**
`-y` answers "yes" automatically to the confirmation prompt. Use it in scripts or when you know exactly what you are installing. Skip it when installing interactively so you can review what dependencies will be pulled in before confirming.

---

## 6. Quick Reference

**APT (Ubuntu/Debian):**

| Command | What it does |
|---|---|
| `sudo apt update` | Refresh package index |
| `sudo apt install <pkg>` | Install a package |
| `sudo apt install <pkg>=<version>` | Install specific version |
| `sudo apt upgrade -y` | Upgrade all packages |
| `sudo apt remove <pkg>` | Remove package, keep configs |
| `sudo apt purge <pkg>` | Remove package and configs |
| `sudo apt autoremove` | Remove unused dependencies |
| `sudo apt clean` | Clear downloaded package cache |
| `apt list --installed` | List installed packages |
| `apt show <pkg>` | Show package details |
| `apt search <keyword>` | Search available packages |

**YUM (CentOS/RHEL 7):**

| Command | What it does |
|---|---|
| `sudo yum install <pkg>` | Install a package |
| `sudo yum update -y` | Upgrade all packages |
| `sudo yum remove <pkg>` | Remove a package |
| `sudo yum clean all` | Clear all cached data |
| `sudo yum list installed` | List installed packages |

**DNF (Fedora/RHEL 8+):**

| Command | What it does |
|---|---|
| `sudo dnf install <pkg>` | Install a package |
| `sudo dnf upgrade -y` | Upgrade all packages |
| `sudo dnf remove <pkg>` | Remove a package |
| `sudo dnf clean all` | Clear all cached data |
| `sudo dnf list installed` | List installed packages |

---

→ Ready to practice? [Go to Lab 04](../linux-labs/04-archive-packages-services-lab.md)
