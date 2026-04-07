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

# Working with Files

On a Linux server, everything is a file. Config files, log files, scripts, sockets, devices — all of them live in the filesystem and all of them are operated on with the same small set of commands. This file covers creating files, copying and moving them, deleting them, and reading their contents. These are not beginner exercises — these are the operations you perform every single time you work on a server.

---

## Table of Contents

- [1. Create and Inspect Files](#1-create-and-inspect-files)
- [2. Writing Content into Files](#2-writing-content-into-files)
- [3. Copying and Moving Files](#3-copying-and-moving-files)
- [4. Deleting Files](#4-deleting-files)
- [5. Viewing File Contents](#5-viewing-file-contents)
- [6. Previewing File Sections](#6-previewing-file-sections)
- [7. File Types in Linux](#7-file-types-in-linux)

---

## 1. Create and Inspect Files

`touch` creates an empty file if it does not exist, or updates the last-modified timestamp if it does. On a server you use it to create placeholder files, initialize log files before a service starts, or bump a file's timestamp to trigger a watching process.

`file` examines the actual contents of a file and reports what type it is — not based on the extension, but based on the bytes inside. Linux does not care about extensions. A file called `server.conf` could contain anything — `file` tells you what it actually is.

`stat` shows the full metadata **(status)** of a file: exact size in bytes, all three timestamps (accessed, modified, changed), permissions in both numeric and symbolic form, and the inode number. When a deployment goes wrong and you need to know exactly when a config file was last changed, `stat` gives you the answer down to the second.

| Command | What it does | When you reach for it |
|---|---|---|
| `touch <file>` | Create empty file or update its timestamp | Creating `~/webstore/logs/access.log` before nginx starts writing to it |
| `file <file>` | Report what type of content the file actually contains | Confirming `webstore-api` binary is an ELF executable, not a corrupted download |
| `stat <file>` | Show full metadata — size, all timestamps, permissions, inode | Finding the exact second `webstore.conf` was last modified during an incident |

**What `stat` output tells you:**

```
File: webstore.conf
Size: 128        Blocks: 8    IO Block: 4096   regular file
Inode: 524291    Links: 1
Access: (0644/-rw-r--r--)  Uid: (1000/akhil)  Gid: (33/www-data)
Access: 2025-04-05 09:12:01
Modify: 2025-04-05 08:47:33
Change: 2025-04-05 08:47:33
```

Three timestamps — Access (last read), Modify (last content change), Change (last metadata change including permissions). If `Modify` and `Change` differ, someone changed permissions without touching the content. That is worth knowing.

---

 ## 3. Copying and Moving Files

`cp` copies a file or directory. `mv` moves or renames one. They look similar but behave differently in one important way — `cp` leaves the original in place, `mv` does not.

---

### Copying Files — `cp`

| Command | What it does |
|---|---|
| `cp <src> <dest>` | Copy a file to a new location or name |
| `cp -r <src> <dest>` | Copy a directory and everything inside it (recursive) |
| `cp -i <src> <dest>` | Ask before overwriting — prints a prompt if the destination already exists |
| `cp -v <src> <dest>` | Print each file name as it is copied — confirms the operation happened |
| `cp -rv <src> <dest>` | Recursive copy with a live log of every file being copied |

**`-i` — Interactive (overwrite protection)**

Without `-i`, `cp` silently overwrites the destination if it already exists. You get no warning and no undo.
```bash
# Without -i — silently overwrites webstore.conf if it already exists
cp webstore.conf /etc/webstore/webstore.conf

# With -i — pauses and asks you first
cp -i webstore.conf /etc/webstore/webstore.conf
# cp: overwrite '/etc/webstore/webstore.conf'?
# Type y to confirm, n to cancel
```

Use `-i` any time you are copying into a directory where a file of the same name might already exist — especially config files in `/etc/`.

**`-v` — Verbose (confirm it actually ran)**

Without `-v`, a successful `cp` prints nothing. You run it and get your prompt back with no feedback. With `-v`, you see every file that was copied.
```bash
# Without -v — no output, no confirmation
cp -r ~/webstore ~/webstore-backup

# With -v — prints each file as it copies
cp -rv ~/webstore ~/webstore-backup
# ~/webstore -> ~/webstore-backup
# ~/webstore/config/webstore.conf -> ~/webstore-backup/config/webstore.conf
# ~/webstore/logs/access.log -> ~/webstore-backup/logs/access.log
```

Use `-v` in scripts or when copying large directories so you can see exactly what moved and catch anything unexpected.

**Gold standard:**
- Directories — `cp -riv <src> <dest>`
- Files — `cp -iv <src> <dest>`
```bash
# Full project backup before a deployment
cp -riv ~/webstore ~/webstore-backup
```

- `-r` — handles directories
- `-i` — won't silently overwrite
- `-v` — shows every file as it copies

This is your default for any directory backup or config copy in production. You get safety and visibility in one command.

---

### Moving and Renaming Files — `mv`

`mv` handles both moving and renaming — they are the same operation under the hood. If the destination is a different path, the file moves. If the destination is just a new name in the same directory, the file is renamed.
```bash
# Move — relocate the file to a new directory
mv webstore.conf /etc/webstore/webstore.conf

# Rename — same directory, new name
mv webstore.conf webstore.conf.old
```

| Command | What it does |
|---|---|
| `mv <src> <dest>` | Move or rename a file or directory |
| `mv -i <src> <dest>` | Ask before overwriting the destination |
| `mv -v <src> <dest>` | Print what was moved and where it landed |

**`-i` and `-v` work the same way as in `cp`:**
```bash
# -i — prompts before overwriting
mv -i webstore.conf /etc/webstore/webstore.conf
# mv: overwrite '/etc/webstore/webstore.conf'?

# -v — confirms the move happened
mv -v webstore.conf.bak webstore.conf.backup
# 'webstore.conf.bak' -> 'webstore.conf.backup'
```

**Gold standard: `mv -iv <src> <dest>`**
```bash
# Safely rename a config before replacing it
mv -iv webstore.conf.bak webstore.conf.backup
# 'webstore.conf.bak' -> 'webstore.conf.backup'
```

- `-i` — prompts before overwriting
- `-v` — confirms exactly what moved and where

`mv` has no `-r` because it already handles directories natively — no flag needed.

---

> **`mv` vs `cp` + `rm`**    
* When relocating a file, always use `mv` instead of copying then deleting.    
  `mv` preserves all metadata including timestamps and ownership.   
* `cp` + `rm` creates a new file and loses the original metadata.   

---

**Gold standard combinations at a glance:**

| Situation | Command |
|---|---|
| Backing up a directory | `cp -riv <src> <dest>` |
| Copying a single file safely | `cp -iv <src> <dest>` |
| Moving or renaming anything | `mv -iv <src> <dest>` |

`-i` and `-v` together are always worth it on a server. The prompt from `-i` has saved config files. The output from `-v` has caught wrong paths. Neither adds meaningful time to the command.

## 4. Deleting Files

`rm` deletes files permanently. There is no trash, no recycle bin, no undo. On a production server, a wrong `rm` command deletes things that may take hours to recover. The habit to build is: always run `ls` on the path first to confirm exactly what you are about to delete.

| Command | What it does | When you reach for it |
|---|---|---|
| `rm <file>` | Delete a file permanently | Removing a stale lock file blocking a service restart |
| `rm -i <file>` | Prompt before each deletion | When deleting multiple files and you want to confirm each one |
| `rm -r <dir>` | Delete a directory and all its contents | Removing a build output directory before a fresh deploy |
| `rm -f <file>` | Force delete — no prompt, no error if file does not exist | Deleting temp files in scripts where the file may or may not exist |
| `rm -rf <dir>` | Force delete a directory tree with no confirmation | Wiping a temp directory in a deploy script — use with full attention |

**The rule with `rm -rf`:** always verify the path with `ls` or `pwd` before running it. `rm -rf /webstore` and `rm -rf ~/webstore` are completely different operations — one deletes a system path, one deletes your project. On a server, confirm before you execute.

---

## 5. Viewing File Contents

Reading file contents from the terminal is something you do constantly — checking config values, reading logs, verifying a script did what you expected.

`cat` prints the entire file to the terminal at once. It is fast and simple for short files. For anything longer than a screen, use `less`.

| Command | What it does | When you reach for it |
|---|---|---|
| `cat <file>` | Print entire file contents | Reading `webstore.conf` to check the current db_host value |
| `cat -n <file>` | Print with line numbers | When an error message references a specific line number in a config file |
| `tac <file>` | Print file in reverse line order | Reading a log file from bottom to top when the newest entries matter most |
| `nl <file>` | Number lines with more formatting control than `cat -n` | Rarely needed — `cat -n` covers most cases |

`less` is what you use for files too long to read in one screen. It lets you scroll forward and backward, search for patterns, and navigate without loading the entire file into memory. On a server with a 2GB log file, `cat` would flood your terminal — `less` handles it instantly.

```bash
less ~/webstore/logs/access.log
```

Inside `less`:    
`Space` to scroll down one page  
`b` to scroll back up   
`/pattern` to search   
`n` to jump to the next match   
`q` to exit.

---

## 6. Previewing File Sections

When you are debugging a live service, you rarely need to read an entire log file. You need the last 50 lines where the error happened, or the first 10 lines of a config to confirm the format. `head` and `tail` give you exactly the section you need without loading everything.

| Command | What it does | When you reach for it |
|---|---|---|
| `head <file>` | Show first 10 lines | Checking the header of a log file to confirm its format |
| `head -n <N> <file>` | Show first N lines | `head -n 3 webstore.conf` — reading just the first three config entries |
| `tail <file>` | Show last 10 lines | Checking the most recent entries in `access.log` after a request |
| `tail -n <N> <file>` | Show last N lines | `tail -n 50 error.log` — reading the last 50 lines during an incident |
| `tail -f <file>` | Follow the file live — print new lines as they are written | Watching `access.log` in real time while testing a webstore endpoint |

`tail -f` is the command you reach for when a service is running and you want to watch what it is doing right now. Open a second terminal, run `tail -f ~/webstore/logs/access.log`, then make a request — you see the log entry appear the moment it is written.

---

## 7. File Types in Linux

Linux does not use file extensions to determine what a file is. The type is determined by the content. The first character in the output of `ls -l` tells you the type of every file at a glance.

| First character | Type | Example |
|---|---|---|
| `-` | Regular file — text, binary, script, image | `webstore.conf`, `server.js`, `nginx` |
| `d` | Directory | `~/webstore/logs/` |
| `l` | Symbolic link — a pointer to another file or directory | `/etc/nginx/sites-enabled/webstore -> ../sites-available/webstore` |

**Symbolic links** are worth understanding because nginx and many other services use them. When you enable an nginx site, you are creating a symlink from `sites-enabled/` pointing to the actual config in `sites-available/`. The file exists in one place, the link makes it appear in another. Deleting the link does not delete the file — it just removes the pointer.

```bash
# What a symlink looks like in ls -l output
lrwxrwxrwx 1 root root 34 Apr 5 09:00 webstore -> ../sites-available/webstore
```

The `l` at the start and the `->` at the end both tell you this is a symlink, not a real file.

---

→ Ready to practice? [Go to Lab 01](../linux-labs/01-boot-basics-files-lab.md)
