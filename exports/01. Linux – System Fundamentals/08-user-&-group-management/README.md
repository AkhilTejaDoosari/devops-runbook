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

# User & Group Management

Every process on a Linux server runs as a user. Every file is owned by a user and a group. This is not bureaucracy — it is the access control model that prevents a compromised web server from reading your database credentials, and prevents a developer's script from accidentally deleting system files.

When nginx serves the webstore frontend, it does not run as root. It runs as `www-data` — a system user with no shell, no home directory, and read-only access to the files it needs. When your API process writes to the logs directory, it writes as the user the service was started under. Understanding users and groups is understanding who is allowed to do what on the machine.

---

## Table of Contents

- [1. How Linux Identifies Users](#1-how-linux-identifies-users)
- [2. Key System Files](#2-key-system-files)
- [3. UID Ranges — Who Is Who](#3-uid-ranges--who-is-who)
- [4. User Management](#4-user-management)
- [5. Group Management](#5-group-management)
- [6. The Webstore User Setup](#6-the-webstore-user-setup)
- [7. Quick Reference](#7-quick-reference)

---

## 1. How Linux Identifies Users

Linux does not track users by name — it tracks them by **UID** (User ID), a number. When you run `ls -l` and see `akhil` as the owner, Linux is actually storing the UID `1000` and your terminal is resolving it to a name for readability. The same is true for groups — every group has a **GID** (Group ID).

Every process running on the system has a UID attached to it. That UID determines what files the process can read, write, or execute. This is why running services as root is dangerous — a process running as root (UID 0) can read and modify any file on the system. A compromised root process means full system compromise.

---

## 2. Key System Files

These four files define every user and group on the system. You will read them often — never edit them directly with a text editor. Use the commands in this file instead.

| File | What it contains | Who can read it |
|---|---|---|
| `/etc/passwd` | One line per user: username, UID, GID, home directory, shell | Everyone |
| `/etc/shadow` | Hashed passwords and password aging settings | Root only |
| `/etc/group` | One line per group: group name, GID, member list | Everyone |
| `/etc/gshadow` | Encrypted group passwords and group admins | Root only |

**Reading `/etc/passwd`:**

```bash
cat /etc/passwd | grep www-data
# www-data:x:33:33:www-data:/var/www:/usr/sbin/nologin
```

Fields separated by `:` — username, password placeholder (`x` means it's in shadow), UID, GID, description, home directory, shell. The shell `/usr/sbin/nologin` means this user cannot log in interactively. That is intentional for service accounts.

**Reading `/etc/group`:**

```bash
cat /etc/group | grep www-data
# www-data:x:33:
```

Fields: group name, password placeholder, GID, comma-separated member list.

---

## 3. UID Ranges — Who Is Who

| Range | Purpose | Examples |
|---|---|---|
| `0` | Root — full system access | `root` |
| `1–999` | System accounts — services, daemons, no login shell | `www-data` (33), `postgres` (999) |
| `1000+` | Regular human users — login shell, home directory | `akhil` (1000) |

When you install nginx, it creates a `www-data` system user automatically with a UID in the system range. When you create your own user account, it gets UID 1000 or higher. This separation is intentional — system services and human operators should never share the same identity.

---

## 4. User Management

**Creating a user:**

```bash
# Create a user with home directory and bash shell
sudo useradd -m -s /bin/bash akhil

# Set the password
sudo passwd akhil
```

`-m` creates the home directory at `/home/akhil`. Without `-m`, the user exists but has no home directory. `-s /bin/bash` gives them a usable shell. Without `-s`, the default shell may be `/bin/sh`.

**Modifying a user:**

```bash
# Add user to a supplementary group — -a means append, never omit it
sudo usermod -aG webstore-team akhil

# Change the user's shell
sudo usermod -s /bin/zsh akhil

# Change the username
sudo usermod -l new-name old-name
```

The `-aG` flag is critical. If you run `usermod -G groupname user` without `-a`, it **replaces** all existing group memberships with just the one you specified. The user loses access to everything else. Always use `-aG` to add a group.

**Deleting a user:**

```bash
# Delete user but keep their home directory — useful when preserving files
sudo userdel akhil

# Delete user and remove their home directory and mail spool
sudo userdel --remove akhil
```

**Checking who you are and what groups you belong to:**

```bash
whoami          # your username
id              # your UID, GID, and all group memberships
id akhil        # same info for another user
groups akhil    # list groups a user belongs to
```

---

## 5. Group Management

Groups are how you give multiple users the same access to a resource without duplicating permissions. Instead of giving three developers individual write access to the webstore config directory, you create a `webstore-team` group, give the directory group write access, and add the developers to the group.

**Creating and managing groups:**

```bash
# Create a group
sudo groupadd webstore-team

# Create a group with a specific GID
sudo groupadd -g 3000 webstore-team

# Rename a group
sudo groupmod -n webstore-devs webstore-team

# Add a user to a group
sudo gpasswd -a akhil webstore-devs

# Remove a user from a group
sudo gpasswd -d akhil webstore-devs

# Delete a group
sudo groupdel webstore-devs
```

**Verify group membership took effect:**

```bash
# The change takes effect on next login — to apply immediately in current session:
newgrp webstore-devs
```

---

## 6. The Webstore User Setup

This is the pattern you apply when setting up the webstore on a Linux server. It reflects how real services are configured — minimum access, dedicated service account, no unnecessary privileges.

**The setup:**

```bash
# nginx is already running as www-data (created during package install)
# Confirm:
ps aux | grep nginx
# www-data  1234  ...  nginx: worker process

# Create a webstore-team group for developers who need access to the project
sudo groupadd webstore-team

# Add nginx's user (www-data) to the webstore-team group
# so nginx can read webstore files owned by that group
sudo usermod -aG webstore-team www-data

# Add your developer account to the group
sudo usermod -aG webstore-team akhil

# Confirm the group membership
getent group webstore-team
# webstore-team:x:3000:www-data,akhil
```

**Why this matters:**
The webstore config file contains the database password. If nginx runs as root, any vulnerability in nginx gives an attacker full system access. If nginx runs as `www-data` with access only to the files it needs, the blast radius of a compromise is contained. This is the principle of least privilege — give each process exactly the access it needs, nothing more.

---

## 7. Quick Reference

**Users:**

| Command | What it does | Example |
|---|---|---|
| `useradd -m -s /bin/bash <user>` | Create user with home dir and bash shell | `sudo useradd -m -s /bin/bash akhil` |
| `passwd <user>` | Set or change password | `sudo passwd akhil` |
| `usermod -aG <group> <user>` | Add user to group (always use `-a`) | `sudo usermod -aG webstore-team akhil` |
| `usermod -s <shell> <user>` | Change login shell | `sudo usermod -s /bin/zsh akhil` |
| `usermod -l <new> <old>` | Rename a user | `sudo usermod -l atd akhil` |
| `userdel <user>` | Delete user, keep home directory | `sudo userdel akhil` |
| `userdel --remove <user>` | Delete user and home directory | `sudo userdel --remove akhil` |
| `id <user>` | Show UID, GID, all group memberships | `id akhil` |

**Groups:**

| Command | What it does | Example |
|---|---|---|
| `groupadd <group>` | Create a group | `sudo groupadd webstore-team` |
| `groupmod -n <new> <old>` | Rename a group | `sudo groupmod -n webstore-devs webstore-team` |
| `gpasswd -a <user> <group>` | Add user to group | `sudo gpasswd -a akhil webstore-team` |
| `gpasswd -d <user> <group>` | Remove user from group | `sudo gpasswd -d akhil webstore-team` |
| `groupdel <group>` | Delete a group | `sudo groupdel webstore-team` |
| `groups <user>` | List all groups a user belongs to | `groups akhil` |
| `getent group <group>` | Show group details and members | `getent group webstore-team` |

---

→ Ready to practice? [Go to Lab 03](../linux-labs/03-vim-users-permissions-lab.md)
