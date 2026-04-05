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

# File Ownership & Permissions

Every file on a Linux system has an owner, a group, and a set of permissions. These three things together answer one question: who is allowed to do what with this file.

This is not abstract security theory. When nginx cannot read the webstore config file, it is a permissions problem. When a deploy script cannot write to the logs directory, it is a permissions problem. When a developer accidentally deletes a shared file, a missing sticky bit is the reason. Understanding permissions is understanding why services fail and how to fix them.

---

## Table of Contents

- [1. The Permission Model](#1-the-permission-model)
- [2. Reading ls -l Output](#2-reading-ls--l-output)
- [3. Numeric Permissions — The Octal System](#3-numeric-permissions--the-octal-system)
- [4. chmod — Changing Permissions](#4-chmod--changing-permissions)
- [5. chown and chgrp — Changing Ownership](#5-chown-and-chgrp--changing-ownership)
- [6. Special Permissions](#6-special-permissions)
- [7. umask — Default Permissions](#7-umask--default-permissions)
- [8. Links and Inodes](#8-links-and-inodes)
- [9. The Webstore Permission Setup](#9-the-webstore-permission-setup)
- [10. Quick Reference](#10-quick-reference)

---

## 1. The Permission Model

Every file has three sets of permissions — one for the owner, one for the group, and one for everyone else (others).

```
-rw-r--r--  1  akhil  webstore-team  1.2K  Apr 5 09:14  webstore.conf
│└────────┘     │      │
│  permissions  │      └── group
│               └── owner
└── file type (- = regular file, d = directory, l = symlink)
```

Each permission set has three bits — read (`r`), write (`w`), execute (`x`):

```
USER    GROUP   OTHERS
r w x   r w x   r w x
```

- **read (r)** — on a file: can read its contents. On a directory: can list its contents with `ls`
- **write (w)** — on a file: can modify its contents. On a directory: can create, delete, and rename files inside it
- **execute (x)** — on a file: can run it as a program. On a directory: can `cd` into it and access files inside

**The directory execute bit is the one people miss.** A directory with `r` but no `x` lets you see the filenames with `ls` but not access the files themselves. You need `x` to actually enter a directory and use its contents.

---

## 2. Reading ls -l Output

```bash
ls -lh ~/webstore/
```

```
drwxr-xr-x  2  akhil  webstore-team  4.0K  Apr 5 09:00  config/
drwxr-xr-x  2  akhil  webstore-team  4.0K  Apr 5 09:00  logs/
-rw-r--r--  1  akhil  webstore-team   128  Apr 5 09:14  config/webstore.conf
-rw-rw-r--  1  akhil  webstore-team  2.4K  Apr 5 09:20  logs/access.log
```

Reading each field left to right:

| Field | Example | Meaning |
|---|---|---|
| Type + permissions | `drwxr-xr-x` | `d` = directory, owner=rwx, group=r-x, others=r-x |
| Hard link count | `2` | Number of hard links pointing to this inode |
| Owner | `akhil` | The user who owns the file |
| Group | `webstore-team` | The group associated with the file |
| Size | `4.0K` | File size (human-readable with `-h`) |
| Timestamp | `Apr 5 09:00` | Last modification time |
| Name | `config/` | File or directory name |

**Decoding `drwxr-xr-x`:**
- `d` — it is a directory
- `rwx` — the owner (akhil) can read, write, and enter it
- `r-x` — the group (webstore-team) can list and enter it but not create or delete files inside
- `r-x` — everyone else can list and enter it but not create or delete files inside

---

## 3. Numeric Permissions — The Octal System

Each permission bit has a numeric value. Add them up to get the octal digit for each set.

| Value | Bit | Meaning |
|---|---|---|
| 4 | `r` | read |
| 2 | `w` | write |
| 1 | `x` | execute |

| Octal | Symbolic | Meaning |
|---|---|---|
| `0` | `---` | no permissions |
| `4` | `r--` | read only |
| `5` | `r-x` | read and execute |
| `6` | `rw-` | read and write |
| `7` | `rwx` | read, write, and execute |

**The permissions you will use most often:**

| Octal | Symbolic | Use case |
|---|---|---|
| `600` | `rw-------` | Private files — SSH keys, credential files |
| `640` | `rw-r-----` | Config files readable by the service group only |
| `644` | `rw-r--r--` | Config files readable by everyone, writable only by owner |
| `664` | `rw-rw-r--` | Shared files — owner and group can write |
| `750` | `rwxr-x---` | Directories accessible by owner and group, not others |
| `755` | `rwxr-xr-x` | Directories and executables accessible by everyone |
| `777` | `rwxrwxrwx` | Full access for everyone — almost never correct in production |

**Reading `644` as three digits:**
- `6` = owner gets rw- (4+2=6)
- `4` = group gets r-- (4)
- `4` = others get r-- (4)

---

## 4. chmod — Changing Permissions

**Octal mode — set exact permissions:**

```bash
# Config file — owner reads and writes, everyone else reads only
chmod 644 ~/webstore/config/webstore.conf

# Log file — owner and group can write, others read only
chmod 664 ~/webstore/logs/access.log

# Script — owner can execute, group and others can read only
chmod 744 ~/webstore/api/deploy.sh

# Entire webstore directory — recursively set directory permissions
chmod -R 755 ~/webstore/
```

**Symbolic mode — add or remove specific bits:**

```bash
# Add execute permission for the owner only
chmod u+x ~/webstore/api/deploy.sh

# Remove write permission from others
chmod o-w ~/webstore/config/webstore.conf

# Add write permission for the group
chmod g+w ~/webstore/logs/

# Remove all permissions for others
chmod o= ~/webstore/config/webstore.conf
```

| Symbolic syntax | Meaning |
|---|---|
| `u+x` | Add execute for owner |
| `g-w` | Remove write for group |
| `o=` | Set others to no permissions |
| `a+r` | Add read for everyone (all) |

**When to use octal vs symbolic:**
Octal sets the complete state in one command — use it when you know exactly what the final permissions should be. Symbolic adds or removes specific bits without touching the others — use it when you want to make a targeted change without resetting everything.

---

## 5. chown and chgrp — Changing Ownership

```bash
# Change both owner and group
sudo chown akhil:webstore-team ~/webstore/config/webstore.conf

# Change owner only
sudo chown akhil ~/webstore/logs/access.log

# Change group only
sudo chgrp webstore-team ~/webstore/config/

# Change ownership recursively — entire directory tree
sudo chown -R akhil:webstore-team ~/webstore/
```

**When you reach for `chown`:**
After copying files from one server to another, ownership may come across as root or a different user. A fresh deploy might create files owned by the deploy script's user rather than the service user. `chown -R` corrects the entire tree in one command.

**Why `sudo` is required:**
Only root can change a file's owner. A regular user can change the group of files they own, but only to groups they belong to. Any other ownership change requires `sudo`.

---

## 6. Special Permissions

Three additional bits sit above the standard rwx and cover edge cases that standard permissions cannot handle.

**SUID (Set User ID) — numeric prefix `4`:**

When set on an executable, it runs with the file owner's privileges regardless of who launches it. The classic example is `/usr/bin/passwd` — it needs to write to `/etc/shadow` which is root-only, but any user needs to change their own password. SUID lets it run as root even when launched by a regular user.

```bash
ls -l /usr/bin/passwd
# -rwsr-xr-x  root  root  ...  /usr/bin/passwd
#    ^
#    s in the owner execute position = SUID set
```

**SGID (Set Group ID) — numeric prefix `2`:**

On a directory: any new files created inside inherit the directory's group instead of the creator's primary group. This is useful for shared team directories — every file created in `~/webstore/logs/` automatically belongs to `webstore-team` regardless of who created it.

```bash
# Set SGID on the webstore logs directory
sudo chmod g+s ~/webstore/logs/
ls -ld ~/webstore/logs/
# drwxrwsr-x  akhil  webstore-team  ...  logs/
#       ^
#       s in the group execute position = SGID set
```

**Sticky bit — numeric prefix `1`:**

On a directory: only the file's owner, the directory's owner, or root can delete or rename files inside — even if the directory is world-writable. `/tmp` always has the sticky bit set for this reason.

```bash
sudo chmod +t ~/webstore/logs/
ls -ld ~/webstore/logs/
# drwxrwxrwt  ...  logs/
#          ^
#          t at the end = sticky bit set
```

---

## 7. umask — Default Permissions

When a new file or directory is created, Linux starts from a maximum permission value and subtracts the umask to determine the actual permissions.

- New files start at `666` (no execute by default)
- New directories start at `777`
- umask `022` subtracts: files get `644`, directories get `755`
- umask `027` subtracts: files get `640`, directories get `750`

```bash
# Check current umask
umask
# 0022

# Set a more restrictive umask for the current session
umask 027

# Make it permanent for your user
echo 'umask 027' >> ~/.bashrc
source ~/.bashrc
```

**When umask `027` matters:**
If your deploy script creates config files, the default `022` umask makes them world-readable — anyone on the server can read them. A `027` umask means only the owner and group can read new files. For config files containing database passwords, this matters.

---

## 8. Links and Inodes

Every file on disk has an **inode** — a data structure that stores the file's metadata (permissions, owner, timestamps, size, and the location of the actual data blocks). The filename you see in a directory is just a pointer to an inode number.

**Hard link:** another directory entry pointing to the same inode. Both names refer to the exact same file. Deleting one does not delete the data — the inode persists until all hard links to it are removed.

**Symlink (symbolic link):** a special file that contains a path to another file. It points to a name, not an inode. If the target file is deleted, the symlink breaks.

```bash
# See inode numbers
ls -li ~/webstore/config/
# 524291 -rw-r--r-- 1 akhil webstore-team 128 Apr 5 webstore.conf

# Create a hard link
ln ~/webstore/config/webstore.conf ~/webstore/backup/webstore.conf.hard

# Create a symlink — nginx sites-enabled uses this pattern
ln -s ~/webstore/config/nginx.conf /etc/nginx/sites-enabled/webstore
```

**The nginx symlink pattern:**
nginx keeps site configs in `sites-available/` and enables them by creating symlinks in `sites-enabled/`. To disable a site you remove the symlink — the config file in `sites-available/` is untouched and can be re-enabled by recreating the symlink.

| | Hard link | Symlink |
|---|---|---|
| Points to | Inode | File path |
| Works across filesystems | No | Yes |
| Breaks if target deleted | No | Yes |
| Shows as `l` in `ls -l` | No | Yes |

---

## 9. The Webstore Permission Setup

This is the correct permission configuration for the webstore project on a Linux server. Every number here has a reason.

```bash
# Set ownership — akhil owns, webstore-team is the group
sudo chown -R akhil:webstore-team ~/webstore/

# Directories — owner full access, group can enter and read, others nothing
chmod 750 ~/webstore/
chmod 750 ~/webstore/config/
chmod 750 ~/webstore/api/
chmod 750 ~/webstore/db/

# Logs directory — owner and group can write (nginx writes here as www-data)
chmod 770 ~/webstore/logs/

# Config files — owner reads and writes, group reads, others nothing
chmod 640 ~/webstore/config/webstore.conf

# Frontend static files — nginx needs to read these, so others need read
chmod 755 ~/webstore/frontend/
chmod 644 ~/webstore/frontend/index.html

# Deploy scripts — only owner can execute
chmod 700 ~/webstore/api/deploy.sh

# Set SGID on logs so nginx's files inherit webstore-team group
sudo chmod g+s ~/webstore/logs/

# Confirm the result
ls -lh ~/webstore/
```

**Why `640` on webstore.conf and not `644`:**
`644` would let any user on the server read the config — including the database password. `640` means only `akhil` and members of `webstore-team` can read it. nginx runs as `www-data` which is a member of `webstore-team`, so it can read the config. Random users on the server cannot.

---

## 10. Quick Reference

| Command | What it does | Example |
|---|---|---|
| `chmod 644 <file>` | Set exact permissions — owner rw, group r, others r | `chmod 644 webstore.conf` |
| `chmod u+x <file>` | Add execute for owner only | `chmod u+x deploy.sh` |
| `chmod -R 755 <dir>` | Set permissions recursively on directory | `chmod -R 755 ~/webstore/` |
| `chown user:group <file>` | Change owner and group | `sudo chown akhil:webstore-team webstore.conf` |
| `chown -R user:group <dir>` | Change ownership recursively | `sudo chown -R akhil:webstore-team ~/webstore/` |
| `chgrp group <file>` | Change group only | `sudo chgrp webstore-team webstore.conf` |
| `chmod g+s <dir>` | Set SGID — new files inherit directory group | `sudo chmod g+s ~/webstore/logs/` |
| `chmod +t <dir>` | Set sticky bit — only owners can delete inside | `sudo chmod +t ~/webstore/logs/` |
| `umask` | Show current default permissions mask | `umask` |
| `ln -s <src> <dest>` | Create a symlink | `ln -s ~/webstore/config/nginx.conf /etc/nginx/sites-enabled/webstore` |
| `ls -li` | Show inode numbers alongside file details | `ls -li ~/webstore/config/` |

---

→ Ready to practice? [Go to Lab 03](../linux-labs/03-vim-users-permissions-lab.md)
