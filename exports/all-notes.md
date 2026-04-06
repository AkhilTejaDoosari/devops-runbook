---
# TOOL: 01. Linux – System Fundamentals | FILE: 01-boot-process
---

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

# Boot Process

## What This File Is About

When a Linux server fails to boot — kernel panic, GRUB error, blank screen — you need to know exactly which stage broke and why. The boot process is a relay race. Each stage does its specific job and hands off to the next. If any stage fails, the race stops exactly there. This file gives you the mental model to read that failure and know where to look.

---

## Table of Contents

1. [Linux Architecture](#1-linux-architecture)
2. [The Boot Sequence](#2-the-boot-sequence)
3. [Firmware — BIOS and UEFI](#3-firmware--bios-and-uefi)
4. [Disk Partitioning — MBR vs GPT](#4-disk-partitioning--mbr-vs-gpt)
5. [GRUB2 — The Bootloader](#5-grub2--the-bootloader)
6. [The Kernel](#6-the-kernel)
7. [systemd — PID 1](#7-systemd--pid-1)
8. [Runlevels vs Targets](#8-runlevels-vs-targets)
9. [Login Stage](#9-login-stage)
10. [Commands](#10-commands)

---

## 1. Linux Architecture

Before the boot process makes sense, you need to understand how Linux is structured. It is built in layers — each one sitting on top of the one below, each one only talking to the layer directly beneath it.

```
┌─────────────────────────────────────┐
│            Applications             │  browsers, web servers, databases, tools
├─────────────────────────────────────┤
│               Shell                 │  bash, zsh — translates your commands
├─────────────────────────────────────┤
│               Kernel                │  the core of Linux, talks to hardware
├─────────────────────────────────────┤
│              Hardware               │  CPU, RAM, disk, NIC
└─────────────────────────────────────┘
```

When you click Save in an application, that request travels down the stack — app → shell → kernel → hardware. The kernel is the only layer that ever touches hardware directly. Everything above it goes through the kernel to get anything done.

The boot process is how this entire stack gets assembled from nothing, every time the machine starts.

---

## 2. The Boot Sequence

When you press the power button, Linux does not just appear. A fixed sequence runs — each stage hands off to the next. Miss a handoff and the system stops exactly there.

```
Power ON
   │
   ▼
┌─────────────────────────────────────┐
│         Firmware (BIOS/UEFI)        │
│  runs POST, finds bootable disk     │
│  ✗ fails → hardware error,          │
│            beep codes, blank screen │
└──────────────────┬──────────────────┘
                   │
                   ▼
┌─────────────────────────────────────┐
│           GRUB2 Bootloader          │
│  loads kernel + initramfs           │
│  ✗ fails → grub rescue prompt or    │
│            "no such partition" error│
└──────────────────┬──────────────────┘
                   │
                   ▼
┌─────────────────────────────────────┐
│               Kernel                │
│  loads drivers, mounts filesystem   │
│  ✗ fails → kernel panic on screen   │
└──────────────────┬──────────────────┘
                   │
                   ▼
┌─────────────────────────────────────┐
│           systemd (PID 1)           │
│  starts all services, hits target   │
│  ✗ fails → emergency shell or       │
│            failed units on screen   │
└──────────────────┬──────────────────┘
                   │
                   ▼
            Login Prompt ✅
```

Each failure message tells you exactly which stage broke. A grub rescue prompt means GRUB2 failed — you don't look at the kernel. A kernel panic means GRUB2 succeeded — you look at drivers or the filesystem mount.

---

## 3. Firmware — BIOS and UEFI

The firmware is the first thing that runs when a machine gets power. It lives on a chip on the motherboard — it is not Linux, not an OS, just a tiny program burned into hardware whose only job is to wake up the system and find something bootable.

**What it does:**
- Runs **POST** (Power-On Self Test) — checks that RAM, CPU, and storage are present and responding
- Finds a bootable disk
- Hands control to the bootloader on that disk

There are two firmware types:

| | BIOS | UEFI |
|---|---|---|
| Age | Legacy | Modern standard |
| Disk support | Works with MBR | Works with GPT |
| Max disk size | 2 TB | No practical limit |
| Boot speed | Slower | Faster |

UEFI is what every modern server uses. You may still see BIOS on older hardware.

---

## 4. Disk Partitioning — MBR vs GPT

Before the firmware can hand off to the bootloader, it needs to know where on disk the bootloader lives. That information is stored in the partition table.

| | MBR (Master Boot Record) | GPT (GUID Partition Table) |
|---|---|---|
| Max partitions | 4 primary | Virtually unlimited |
| Max disk size | 2 TB | No practical limit |
| Works with | BIOS | UEFI |
| Status | Legacy | Modern standard |

GPT is the standard on any server built in the last decade. You will encounter MBR only on old machines or legacy setups.

---

## 5. GRUB2 — The Bootloader

GRUB2 (Grand Unified Bootloader) is the first Linux-aware software that runs. Firmware is generic — it knows nothing about Linux. GRUB2 knows exactly where the kernel is and how to load it.

**What GRUB2 does:**
- Shows the OS selection menu (useful on dual-boot machines)
- Loads the Linux kernel into memory
- Loads **initramfs** — a tiny temporary filesystem the kernel needs to get started
- Steps aside — its job is done in seconds

**Key files:**

| File | Purpose |
|---|---|
| `/boot/grub2/` or `/boot/efi/EFI/` | GRUB2 binary and config location |
| `/etc/default/grub` | Human-editable GRUB settings |
| `/etc/grub.d/` | Scripts that generate the final config |
| `/boot/grub2/grub.cfg` | Final generated config — do not edit directly |

After changing `/etc/default/grub`, regenerate the config:
```bash
sudo update-grub
```

---

## 6. The Kernel

The kernel is the brain of Linux — the only software that talks directly to hardware. Once GRUB2 hands control to it, the kernel takes over completely.

**What the kernel does at boot:**
- Loads hardware drivers
- Uses initramfs to get access to storage
- Mounts the real root filesystem (e.g. `/dev/sda1`)
- Starts systemd — the first user-space process

**Why initramfs exists:**
The kernel needs certain drivers to mount the real root filesystem — but those drivers might live on the real root filesystem. initramfs breaks that chicken-and-egg problem. It is a tiny filesystem loaded into RAM with just enough drivers to get the real mount done. Once the real filesystem is mounted, initramfs is discarded.

---

## 7. systemd — PID 1

systemd is the first process the kernel starts after taking control. It always gets **PID 1** — process ID number one, the parent of everything else on the system. Every service, every daemon, every background process on a running Linux machine is a child of systemd.

**What systemd manages:**
- Starting and stopping all services
- Boot targets — defining what state the system should reach
- Logging via `journald`
- Mounts, sockets, timers

**Unit types:**

| Unit | Purpose |
|---|---|
| `.service` | Background daemons — nginx, sshd, mysql |
| `.target` | Groups of units — defines boot states |
| `.socket` | Socket-based service activation |
| `.mount` | Filesystem mount points |
| `.timer` | Scheduled jobs, like cron |

---

## 8. Runlevels vs Targets

Old SysV init used numbered runlevels. systemd replaced them with named targets that describe what state the system should reach after boot.

| Runlevel | systemd Target | Purpose |
|---|---|---|
| 0 | `poweroff.target` | Shutdown |
| 1 | `rescue.target` | Single-user recovery mode |
| 3 | `multi-user.target` | CLI with networking — standard for servers |
| 5 | `graphical.target` | Multi-user with GUI — standard for desktops |
| 6 | `reboot.target` | Restart |

Most Linux servers run at `multi-user.target` — full networking, no GUI. That is the target systemd reaches on a typical server boot.

---

## 9. Login Stage

Once systemd finishes bringing all services up and reaches the target, you get a login prompt:

- **Servers** → CLI login over SSH or directly on the console
- **Desktops** → graphical login screen (GDM, LightDM, etc.)

The system is fully up. The relay race is complete.

---

## 10. Commands

These are the commands you reach for when working with or debugging the boot process:

```bash
# Confirm which kernel version is currently running
uname -r

# View kernel and hardware messages from boot — look here after a crash
dmesg | less

# List all active services — see what systemd brought up
systemctl list-units --type=service

# See what lives in the boot partition — kernel, initramfs, GRUB files
ls /boot

# View the human-editable GRUB config
cat /etc/default/grub

# Regenerate grub.cfg after editing GRUB settings (Debian/Ubuntu)
sudo update-grub

# Restart or shut down
reboot
shutdown -h now
```

**When you reach for these:**
- Server won't boot → `dmesg | less` to find exactly where it failed
- Kernel updated, confirm the version → `uname -r`
- Service missing after reboot → `systemctl list-units --type=service`
- Changed GRUB timeout or default OS → `sudo update-grub` to apply it

---
# TOOL: 01. Linux – System Fundamentals | FILE: 02-basics
---

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

# Linux Basics

Linux organizes everything under one single tree starting at `/`. No C: or D: drives — every file, disk, device, and config lives somewhere beneath that root slash. In Linux a **directory is just a folder** — the two words mean the same thing, Linux documentation just prefers "directory."

The **shell** is the translator between you and the kernel. When you type a command, the shell interprets it and asks the kernel to do the work. On servers you almost always interact with Linux through a shell over SSH, with no graphical interface. These commands are how you see, move, and control everything on that machine.

---

## Table of Contents

- [1. Directory Navigation](#1-directory-navigation)
- [2. Listing Directory Contents](#2-listing-directory-contents)
- [3. Terminal Essentials](#3-terminal-essentials)
- [4. System Information](#4-system-information)
- [5. Getting Help](#5-getting-help)
- [6. System Info via uname](#6-system-info-via-uname)

---

## 1. Directory Navigation

The shell always operates inside some directory — called the **current working directory (CWD)**. You can think of it as "where you are right now" in the filesystem. When you SSH into a server for the first time, you have no idea where you landed. The first command you run is `pwd` — it tells you exactly where you are before you touch anything.

**Absolute vs relative paths:**
- Absolute starts from root: `/home/akhil/webstore` — works from anywhere on the system
- Relative starts from your CWD: if you are in `/home/akhil`, then `cd webstore` takes you to `/home/akhil/webstore`
- `..` means parent directory — `cd ..` moves you up one level

| Command | What it does | When you reach for it |
|---|---|---|
| `pwd` | Print the full path of where you currently are | First thing after SSHing into any server |
| `cd <dir>` | Move into a directory | Navigating into the webstore project folder |
| `cd ..` | Move up one directory level | Going from `~/webstore/logs` back to `~/webstore` |
| `cd ~` | Jump directly to your home directory | Getting back to a known starting point fast |
| `mkdir <dir>` | Create a new directory | Creating `~/webstore/logs` for the first time |
| `mkdir -p <path>` | Create nested directories in one shot — no error if they exist | `mkdir -p ~/webstore/{frontend,api,db,logs,config,backup}` — builds the full webstore structure in one command |
| `rmdir <dir>` | Remove an empty directory | Cleaning up a folder you created by mistake — only works if empty |
| `rm -rf <dir>` | Force delete a directory and everything inside it | Wiping a directory with no confirmation and no undo — use with full attention |

> `rm -rf` has no confirmation prompt and no undo. On a server, this means permanent. The habit to build: always run `ls` on the path first to confirm what you are about to delete.

---

## 2. Listing Directory Contents

`ls` is the command you run more than any other on a Linux server. By default it lists filenames only — clean but minimal. The flags give you everything else you need: who owns the file, how large it is, when it was last modified, and whether it is hidden. Every one of these details matters when you are debugging a live system.

| Command | What it shows | When you reach for it |
|---|---|---|
| `ls` | Filenames only | Quick glance at what is in a directory |
| `ls -l` | Full details — permissions, owner, size, timestamp | Checking who owns the webstore config file and when it was last changed |
| `ls -lh` | Same as `-l` but sizes in KB, MB, GB instead of bytes | When you need to know if a log file has grown to 2GB overnight |
| `ls -la` | Full details including hidden files (`.` prefix) | Finding `.env` files or `.git` directories that are invisible by default |
| `ls -lt` | Sorted by modification time, newest first | Finding which file in `~/webstore/logs` changed most recently during an incident |
| `ls -ltr` | Sorted by modification time, oldest first | Seeing the full history of changes in chronological order |
| `ls -ld <dir>` | Shows info about the directory itself, not its contents | Checking the permissions on `~/webstore/` without listing everything inside |

You can chain flags freely — `ls -lh`, `ls -ltr`, `ls -lath` all work. Order does not matter.

**What the output of `ls -lh` actually tells you:**

```
-rw-r--r-- 1 akhil www-data 1.2K Apr 5 09:14 webstore.conf
```

Reading left to right:  
file type and permissions (`-rw-r--r--`), number of hard links (`1`), owner (`akhil`), group (`www-data`), size (`1.2K`), last modified (`Apr 5 09:14`), filename (`webstore.conf`).     
When you see `www-data` as the group on a webstore config file, that tells you nginx has read access to it — which is exactly what you want.

---

## 3. Terminal Essentials

The shell keeps a numbered history of every command you have run in the current session. On a server this matters for two reasons: you need to repeat long commands exactly without retyping them, and when something broke you need to know what was run before you arrived.

| Command | What it does | When you reach for it |
|---|---|---|
| `clear` | Clear the terminal screen — history is untouched | Cleaning up visual clutter before a focused task |
| `history` | Show all commands run this session with line numbers | Auditing what was run on the server before you got there |
| `!<num>` | Re-run the command at that history number | `!42` — repeat a long docker run command without retyping |
| `!-1` | Re-run the last command | Running the same command twice in a row |

**The keyboard shortcuts that save the most time:**

- `↑` arrow — scroll back through history one command at a time
- `Ctrl + R` — reverse search through history by typing part of a command
- `Ctrl + C` — kill the running command immediately
- `Ctrl + L` — same as `clear`
- `Tab` — autocomplete a command, filename, or path

`Ctrl + R` is the one most people do not know but use constantly once they do.   
Type `Ctrl + R` then start typing `docker run` — the shell finds the last command that matches and shows it.   
Press Enter to run it or keep typing to narrow the search.   

---

## 4. System Information

These are the first commands you run when you SSH into an unfamiliar server. They tell you who you are, what the machine is doing, and whether anything unusual is happening before you touch anything else.

| Command | What it tells you | When you reach for it |
|---|---|---|
| `whoami` | Your current username | Confirming you are logged in as the right user — not root when you shouldn't be |
| `who` | Every user currently logged into this machine | Checking if someone else is on the server during an incident |
| `uptime` | How long the system has been running + current load averages | A machine that rebooted 3 minutes ago when it should have been up for 30 days tells you something broke |
| `date` | Current system date and time | Confirming the server clock is correct before reading log timestamps |

**What `uptime` output actually means:**

```
10:32:11 up 4 days, 2:17, 1 user, load average: 0.45, 0.38, 0.31
```

The three load average numbers are CPU demand over the last 1 minute, 5 minutes, and 15 minutes.  
A number below your CPU core count means the system is healthy.  
A number above it means the system is under more load than it can handle — worth investigating before deploying anything.  

---

## 5. Getting Help

Every command ships with documentation built in. Before searching the internet for a flag you cannot remember, check it locally — it is faster and works on any server with no internet access.

| Command | What it does | When you reach for it |
|---|---|---|
| `man <command>` | Full manual page — everything the command can do | `man ls` — when you need to find an obscure flag |
| `whatis <command>` | One-line description of what a command does | Quick reminder of what a command is for |
| `whereis <command>` | Finds the binary, source code, and man page locations | Confirming which version of a tool is installed and where |
| `which <command>` | Shows the exact path of the executable that would run | `which python3` — confirming which Python is active when you have multiple versions |

Inside `man` pages: use `/` to search, `n` to jump to the next match, `q` to exit. Most man pages are long — searching is faster than scrolling.

---

## 6. System Info via uname

`uname` reports information about the running kernel and hardware. You reach for it when you need to confirm the kernel version after an update, when a tool requires a specific architecture, or when a script needs to detect the OS it is running on.

| Option | What it shows | Example output |
|---|---|---|
| `uname -s` | Kernel name | `Linux` |
| `uname -r` | Kernel release version | `5.15.0-91-generic` |
| `uname -n` | Hostname of the machine | `webstore-prod-01` |
| `uname -m` | Machine hardware architecture | `x86_64` |
| `uname -a` | All of the above in one line | Full system summary |

**When you reach for this:**
- After a kernel update — `uname -r` confirms the new kernel is actually running
- When installing a tool that has different binaries for `x86_64` vs `arm64` — `uname -m` tells you which to download
- In a shell script that needs to behave differently on different systems — `uname -s` lets you detect the OS

---

→ Ready to practice? [Go to Lab 01](../linux-labs/01-boot-basics-files-lab.md)

---
# TOOL: 01. Linux – System Fundamentals | FILE: 03-working-with-files
---

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

`stat` shows the full metadata of a file: exact size in bytes, all three timestamps (accessed, modified, changed), permissions in both numeric and symbolic form, and the inode number. When a deployment goes wrong and you need to know exactly when a config file was last changed, `stat` gives you the answer down to the second.

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

## 2. Writing Content into Files

Before you can work with file contents you need to know how to write them from the terminal. Two operators handle this — `>` and `>>`. Getting them mixed up is one of the most common ways to accidentally destroy a config file.

`>` redirects output into a file and **overwrites** everything already there. If the file does not exist it creates it. If it does exist, everything in it is gone.

`>>` appends output to the end of a file. Existing content is untouched.

```bash
# Create webstore.conf from scratch — safe because the file is new
echo "db_host=webstore-db" > ~/webstore/config/webstore.conf
echo "db_port=5432" >> ~/webstore/config/webstore.conf
echo "api_port=8080" >> ~/webstore/config/webstore.conf
```

The first line uses `>` to create the file and write the first entry. Every line after uses `>>` to append. If you accidentally used `>` on the second line, the first entry would be gone.

To write multiple lines at once without running echo repeatedly, use a heredoc:

```bash
cat > ~/webstore/config/webstore.conf << 'EOF'
db_host=webstore-db
db_port=5432
api_port=8080
api_host=webstore-api
frontend_port=80
EOF
```

Everything between `<< 'EOF'` and `EOF` goes into the file as-is. This is how you write config files from scripts without opening an editor.

---

## 3. Copying and Moving Files

`cp` copies a file or directory. `mv` moves or renames one. They look similar but behave differently in one important way — `cp` leaves the original in place, `mv` does not.

**Copying files:**

| Command | What it does | When you reach for it |
|---|---|---|
| `cp <src> <dest>` | Copy a file | `cp webstore.conf webstore.conf.bak` — backup before editing |
| `cp -i <src> <dest>` | Prompt before overwriting an existing file | When you are not sure if the destination already exists |
| `cp -v <src> <dest>` | Show each file as it copies | Confirming the copy happened, especially useful in scripts |
| `cp -r <src> <dest>` | Copy a directory and all its contents recursively | `cp -r ~/webstore ~/webstore-backup` — full project backup |
| `cp -rv <src> <dest>` | Recursive copy with a live log of every file copied | Watching a large directory copy complete in real time |

**Moving and renaming:**

`mv` is used for both moving a file to a new location and renaming it — they are the same operation. Moving `webstore.conf` to `/etc/webstore/webstore.conf` and renaming `webstore.conf` to `webstore.conf.old` both use `mv`.

| Command | What it does | When you reach for it |
|---|---|---|
| `mv <src> <dest>` | Move or rename a file or directory | `mv webstore.conf.bak webstore.conf.backup` — rename a backup file |
| `mv -i <src> <dest>` | Prompt before overwriting | Safe default when moving config files in production |
| `mv -v <src> <dest>` | Show what was moved | Confirming the move in scripts or long sessions |

Use `mv` instead of `cp` followed by `rm` when you want to relocate a file. `mv` preserves all metadata including timestamps. `cp` + `rm` does not.

---

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

Inside `less`: `Space` to scroll down one page, `b` to scroll back up, `/pattern` to search, `n` to jump to the next match, `q` to exit.

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

---
# TOOL: 01. Linux – System Fundamentals | FILE: 04-filter-commands
---

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

# Filter Commands

A production server generates thousands of log lines every hour. You will never open them in a text editor. You will never scroll through them manually. Instead you use filter commands — tools that let you search, slice, count, sort, and chain operations against any file or stream from the terminal. This is how a DevOps engineer reads a system without a GUI.

The webstore access log used throughout this file:

```
192.168.1.10 GET /api/products 200
192.168.1.11 GET /api/products 200
192.168.1.12 POST /api/orders 201
192.168.1.10 GET /api/products 200
192.168.1.13 GET /api/users 404
192.168.1.14 POST /api/orders 500
192.168.1.11 GET /api/products 200
192.168.1.15 DELETE /api/orders/7 403
192.168.1.10 GET /api/products 200
192.168.1.14 POST /api/orders 500
```

---

## Table of Contents

- [1. find — Search the Filesystem](#1-find--search-the-filesystem)
- [2. locate — Fast Name Lookup](#2-locate--fast-name-lookup)
- [3. grep — Search File Contents](#3-grep--search-file-contents)
- [4. wc — Count Lines, Words, Characters](#4-wc--count-lines-words-characters)
- [5. The Pipe — Chaining Commands](#5-the-pipe--chaining-commands)
- [6. cut — Extract Fields](#6-cut--extract-fields)
- [7. sort — Order Lines](#7-sort--order-lines)
- [8. uniq — Deduplicate Lines](#8-uniq--deduplicate-lines)
- [9. tr — Translate Characters](#9-tr--translate-characters)
- [10. tee — Split a Stream](#10-tee--split-a-stream)
- [11. Real Incident Pipelines](#11-real-incident-pipelines)

---

## 1. find — Search the Filesystem

`find` walks the directory tree in real time and returns every file that matches your criteria. Unlike `locate`, its results are always current because it reads the actual filesystem rather than a cached database. It is slower on very large trees but infinitely more flexible — you can filter by name, type, size, age, owner, permissions, and then execute a command on every match.

| Option | What it does | Example |
|---|---|---|
| `-name "*.log"` | Match files by name using wildcards | `find ~/webstore/logs -name "*.log"` |
| `-type f` | Regular files only | `find ~/webstore -type f` |
| `-type d` | Directories only | `find ~/webstore -type d` |
| `-mtime +7` | Modified more than 7 days ago | `find ~/webstore/logs -mtime +7` |
| `-mtime -1` | Modified in the last 24 hours | `find ~/webstore/logs -mtime -1` |
| `-size +1k` | Larger than 1 KB | `find ~/webstore/logs -size +1k` |
| `-size -500c` | Smaller than 500 bytes | `find ~/webstore/logs -size -500c` |
| `-exec <cmd> {} \;` | Run a command on every match | `find ~/webstore/logs -name "*.tmp" -exec rm {} \;` |

**When you reach for `find`:**
- Cleaning up old log files before a deploy: `find ~/webstore/logs -mtime +30 -exec rm {} \;`
- Confirming a config file exists somewhere in the project: `find ~/webstore -name "webstore.conf"`
- Deleting all `.tmp` files left behind by a crashed process: `find ~/webstore -name "*.tmp" -exec rm {} \;`

---

## 2. locate — Fast Name Lookup

`locate` searches a prebuilt database of filenames instead of walking the live filesystem. It returns results instantly but the database is only as fresh as the last time `updatedb` ran — usually once a day. Use it when you need to find a file quickly by name and do not need guaranteed freshness.

| Option | What it does | Example |
|---|---|---|
| `locate <name>` | Find all paths containing this name | `locate webstore.conf` |
| `-i` | Case-insensitive match | `locate -i ACCESS.LOG` |
| `-l 5` | Limit results to 5 | `locate -l 5 access.log` |
| `-c` | Count matches only | `locate -c "*.log"` |

**find vs locate — when to use which:**

| | find | locate |
|---|---|---|
| Results | Always current | Only as fresh as last `updatedb` |
| Speed | Slower on large trees | Instant |
| Filters | Name, type, size, age, owner | Name only |
| Actions | Can run `-exec` on matches | Returns list only |
| Use when | You need exact, current results | You just need to know where a file is |

If a file was created in the last few hours and `locate` cannot find it, run `sudo updatedb` first to refresh the database.

---

## 3. grep — Search File Contents

`grep` searches inside files for lines matching a pattern. It is the single most-used command for reading logs and config files on a server. Every incident investigation starts with `grep`.

```
grep [OPTIONS] <pattern> <file>
```

| Flag | What it does | Example |
|---|---|---|
| `grep <pattern> <file>` | Find lines matching pattern — case sensitive | `grep '500' ~/webstore/logs/access.log` |
| `-i` | Case-insensitive match | `grep -i 'error' access.log` |
| `-n` | Show line numbers alongside matches | `grep -n '500' access.log` |
| `-c` | Count matching lines instead of showing them | `grep -c '500' access.log` |
| `-v` | Invert — show lines that do NOT match | `grep -v '200' access.log` |
| `-w` | Match whole words only | `grep -w 'GET' access.log` |
| `-r` | Search recursively through all files in a directory | `grep -r 'db_host' ~/webstore/config/` |

**What these look like against the webstore log:**

```bash
# Find all 500 errors
grep '500' ~/webstore/logs/access.log
# 192.168.1.14 POST /api/orders 500
# 192.168.1.14 POST /api/orders 500

# Count how many 500 errors occurred
grep -c '500' ~/webstore/logs/access.log
# 2

# Find everything that is NOT a 200 OK — surface all problems at once
grep -v '200' ~/webstore/logs/access.log
# 192.168.1.12 POST /api/orders 201
# 192.168.1.13 GET /api/users 404
# 192.168.1.14 POST /api/orders 500
# 192.168.1.15 DELETE /api/orders/7 403
# 192.168.1.14 POST /api/orders 500

# Find all errors across every log file in the logs directory
grep -r '500' ~/webstore/logs/
```

**When you reach for `grep`:**
During an incident, `grep -v '200'` on the access log immediately surfaces every non-successful request. You do not scroll — you filter.

---

## 4. wc — Count Lines, Words, Characters

`wc` counts lines, words, and characters in a file or stream. On its own it tells you the size of a file in human terms. In a pipeline it tells you how many results a previous command produced.

| Command | What it counts | When you reach for it |
|---|---|---|
| `wc <file>` | Lines, words, and characters together | Quick file size check |
| `wc -l <file>` | Lines only | How many entries are in the access log |
| `wc -w <file>` | Words only | Rarely needed on log files |
| `wc -c <file>` | Characters (bytes) only | Checking exact file size |

**Most useful pattern — count grep results:**

```bash
grep '500' ~/webstore/logs/access.log | wc -l
# 2
```

This tells you exactly how many 500 errors occurred without printing every matching line. Combine with `-i` and a date pattern and you have a quick incident count.

---

## 5. The Pipe — Chaining Commands

The pipe `|` takes the output of one command and feeds it directly into the next as input. No temporary files. No intermediate steps. It is what turns single commands into powerful analysis chains.

```
command1 | command2 | command3
```

Think of it as an assembly line. Each command does one job. The pipe connects them. The final output is the result of the entire chain.

```bash
# Read the log, find 500 errors, count them
cat ~/webstore/logs/access.log | grep '500' | wc -l
# 2

# Extract just the IP addresses from every 500 error
grep '500' ~/webstore/logs/access.log | cut -d' ' -f1
# 192.168.1.14
# 192.168.1.14
```

Every section below builds on the pipe.

---

## 6. cut — Extract Fields

`cut` extracts specific columns from structured text. Log files, CSVs, `/etc/passwd` — any file where fields are separated by a consistent delimiter. You tell it the delimiter with `-d` and which field(s) to keep with `-f`.

| Option | What it does | Example |
|---|---|---|
| `-d' ' -f1` | Split on space, take field 1 | `cut -d' ' -f1 access.log` — extracts IP addresses |
| `-d' ' -f3` | Split on space, take field 3 | `cut -d' ' -f3 access.log` — extracts URL paths |
| `-d' ' -f1,4` | Take fields 1 and 4 | `cut -d' ' -f1,4 access.log` — IP and status code |
| `-d',' -f2` | Split on comma, take field 2 | `cut -d',' -f2 data.csv` |

**Against the webstore log:**

```bash
# Extract all IP addresses (field 1)
cut -d' ' -f1 ~/webstore/logs/access.log
# 192.168.1.10
# 192.168.1.11
# ...

# Extract status codes only (field 4)
cut -d' ' -f4 ~/webstore/logs/access.log
# 200
# 200
# 201
# ...
```

---

## 7. sort — Order Lines

`sort` orders lines of text. By default it sorts alphabetically. Flags let you sort numerically, in reverse, by a specific field, or by month name. `sort` almost always appears before `uniq` in a pipeline — `uniq` only deduplicates consecutive identical lines, so you must sort first.

| Flag | What it does | Example |
|---|---|---|
| `sort <file>` | Alphabetical ascending | `sort access.log` |
| `-r` | Reverse order | `sort -r access.log` |
| `-n` | Numeric sort | `sort -n sizes.txt` |
| `-k <N>` | Sort by field N | `sort -k4 access.log` — sort by status code |
| `-t <delim>` | Use this delimiter to identify fields | `sort -t',' -k3 -n data.csv` |

```bash
# Sort the access log by status code (field 4)
sort -k4 ~/webstore/logs/access.log
# 192.168.1.12 POST /api/orders 201
# 192.168.1.15 DELETE /api/orders/7 403
# 192.168.1.13 GET /api/users 404
# 192.168.1.14 POST /api/orders 500
# 192.168.1.14 POST /api/orders 500
# 192.168.1.10 GET /api/products 200
# ...
```

---

## 8. uniq — Deduplicate Lines

`uniq` removes or counts duplicate consecutive lines. Because it only works on adjacent duplicates, you almost always run `sort` first to bring identical lines together.

| Flag | What it does | Example |
|---|---|---|
| `uniq` | Remove consecutive duplicate lines | `sort access.log \| uniq` |
| `-c` | Prefix each line with how many times it appeared | `sort access.log \| uniq -c` |
| `-d` | Show only lines that appeared more than once | `sort access.log \| uniq -d` |
| `-u` | Show only lines that appeared exactly once | `sort access.log \| uniq -u` |

**The classic combination — find the most active IPs:**

```bash
cut -d' ' -f1 ~/webstore/logs/access.log | sort | uniq -c | sort -rn
#   5 192.168.1.10
#   2 192.168.1.11
#   2 192.168.1.14
#   1 192.168.1.12
#   1 192.168.1.13
#   1 192.168.1.15
```

Read this pipeline left to right: extract IP addresses → sort them so identical ones are adjacent → count and deduplicate → sort by count descending. Result: a ranked list of who is hitting the webstore API most.

---

## 9. tr — Translate Characters

`tr` replaces or deletes characters in a stream. It reads from stdin — you feed it content with a pipe or redirect.

| Option | What it does | Example |
|---|---|---|
| `tr 'a-z' 'A-Z'` | Uppercase everything | `cat access.log \| tr 'a-z' 'A-Z'` |
| `-d '0-9'` | Delete all digits | `tr -d '0-9' < access.log` |
| `-s ' '` | Squeeze repeated spaces into one | `tr -s ' ' < access.log` |

`tr` is most useful in pipelines when you need to normalize text before passing it to another command — removing characters that break field splitting, or standardizing case before comparison.

---

## 10. tee — Split a Stream

`tee` reads from stdin and writes to both stdout and a file simultaneously. It lets you see pipeline output on the terminal and save it to a file at the same time — without running the command twice.

| Flag | What it does | Example |
|---|---|---|
| `tee <file>` | Write to stdout and file | `grep '500' access.log \| tee errors.log` |
| `-a` | Append to file instead of overwrite | `grep '500' access.log \| tee -a errors.log` |

```bash
# Save all 500 errors to a file AND still see them on screen
grep '500' ~/webstore/logs/access.log | tee ~/webstore/logs/errors.log
# 192.168.1.14 POST /api/orders 500   ← printed to terminal
# 192.168.1.14 POST /api/orders 500   ← also written to errors.log
```

---

## 11. Real Incident Pipelines

These are the chains you actually build during an incident. Each one is a question you need answered fast.

**How many 500 errors hit the API in this log?**
```bash
grep '500' ~/webstore/logs/access.log | wc -l
```

**Which IP address is generating all the 500 errors?**
```bash
grep '500' ~/webstore/logs/access.log | cut -d' ' -f1 | sort | uniq -c | sort -rn
```

**Which endpoints are being hit most often?**
```bash
cut -d' ' -f3 ~/webstore/logs/access.log | sort | uniq -c | sort -rn
```

**Show me every request that is not a 200 OK, with line numbers:**
```bash
grep -vn '200' ~/webstore/logs/access.log
```

**Find all log files modified in the last 24 hours and search them all for errors:**
```bash
find ~/webstore/logs -mtime -1 -name "*.log" -exec grep -l '500' {} \;
```

**Save all non-200 requests to a separate file for further analysis:**
```bash
grep -v '200' ~/webstore/logs/access.log | tee ~/webstore/logs/non-200.log
```

---

→ Ready to practice? [Go to Lab 02](../linux-labs/02-filters-sed-awk-lab.md)

---
# TOOL: 01. Linux – System Fundamentals | FILE: 05-sed-stream-editor
---

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

# sed — Stream Editor

`grep` finds lines. `cut` extracts fields. `sed` transforms content — it reads a stream line by line, applies your editing instructions, and outputs the result. No file is opened in an editor. No manual cursor movement. You describe the change once and sed applies it to every matching line in the file.

This is how you update config files in deploy scripts, sanitize log output before piping it elsewhere, or make the same change across hundreds of lines in seconds.

The webstore config file used throughout this file:

```
db_host=webstore-db
db_port=5432
api_port=8080
api_host=webstore-api
frontend_port=80
frontend_host=webstore-frontend
env=production
```

---

## Table of Contents

- [1. How sed Works](#1-how-sed-works)
- [2. Substitution — the Core Operation](#2-substitution--the-core-operation)
- [3. Targeting Specific Lines](#3-targeting-specific-lines)
- [4. In-Place Editing](#4-in-place-editing)
- [5. Deleting Lines](#5-deleting-lines)
- [6. Printing Specific Lines](#6-printing-specific-lines)
- [7. Inserting and Appending Lines](#7-inserting-and-appending-lines)
- [8. Running Multiple Commands](#8-running-multiple-commands)
- [9. Quick Reference](#9-quick-reference)

---

## 1. How sed Works

sed reads a file or stream one line at a time. For each line it checks whether your pattern matches, applies the instruction if it does, then prints the result. By default it prints every line — changed or not. The original file is untouched unless you use `-i`.

```
sed 'instruction' file
     │
     └── instruction = [address] command
         address = which lines to act on (optional — default is all lines)
         command = what to do (substitute, delete, print, insert)
```

**Key flags:**

| Flag | What it does |
|---|---|
| `-n` | Suppress automatic printing — only print lines you explicitly ask for with `p` |
| `-i` | Edit the file in-place — changes are written back to the original file |
| `-e` | Chain multiple instructions in one command |

---

## 2. Substitution — the Core Operation

The substitution command is the one you will use 90% of the time:

```
s/OLD/NEW/
```

- `s` — substitute
- first `/` — opens the pattern to find
- `OLD` — what to look for
- second `/` — separates pattern from replacement
- `NEW` — what to replace it with
- third `/` — closes the replacement, flags go here

**Replace the first match on each line:**

```bash
sed 's/production/staging/' ~/webstore/config/webstore.conf
```

This replaces only the first occurrence of `production` per line. The file is not changed — output goes to the terminal.

**Replace all occurrences on each line with `g` (global):**

```bash
sed 's/webstore/mystore/g' ~/webstore/config/webstore.conf
```

Without `g`, only the first match per line is replaced. With `g`, every match on every line is replaced.

**When the replacement contains `/`, use a different delimiter:**

```bash
# This would break — forward slash conflicts with the delimiter
sed 's/api_host=webstore-api/api_host=webstore-api/staging/' webstore.conf

# Use # as the delimiter instead
sed 's#webstore-api#webstore-api-staging#g' ~/webstore/config/webstore.conf
```

Any character can be the delimiter as long as it does not appear in your pattern or replacement. `#`, `|`, and `@` are common choices.

---

## 3. Targeting Specific Lines

By default sed acts on every line. You can restrict it to specific lines using a line number or a pattern.

**Act on a specific line number:**

```bash
# Replace only on line 1
sed '1 s/production/staging/' ~/webstore/config/webstore.conf
```

**Act on a range of lines:**

```bash
# Replace on lines 1 through 3 only
sed '1,3 s/webstore/mystore/' ~/webstore/config/webstore.conf
```

**Act on all lines from line 2 to the end (`$` means last line):**

```bash
sed '2,$ s/webstore/mystore/' ~/webstore/config/webstore.conf
```

**Act only on lines matching a pattern:**

```bash
# Only replace on lines that contain "port"
sed '/port/ s/8080/9090/' ~/webstore/config/webstore.conf
```

**Print only the lines where substitution occurred (`-n` + `p` flag):**

```bash
sed -n 's/production/staging/p' ~/webstore/config/webstore.conf
# env=staging
```

`-n` suppresses all output. `p` prints only the lines that were actually changed. Together they give you a confirmation of what sed touched.

---

## 4. In-Place Editing

Everything above only prints the result — the original file is not modified. To write changes back to the file, use `-i`.

```bash
# Change production to staging directly in the file
sed -i 's/production/staging/' ~/webstore/config/webstore.conf
```

After this command, `webstore.conf` is permanently changed. There is no undo unless you have a backup.

**Best practice — always back up before in-place editing:**

```bash
# Create a backup first
cp ~/webstore/config/webstore.conf ~/webstore/backup/webstore.conf.bak

# Then edit in-place
sed -i 's/production/staging/' ~/webstore/config/webstore.conf
```

On macOS, `-i` requires an empty string argument: `sed -i '' 's/old/new/' file`. On Linux it does not.

**When you reach for `-i`:**
Deploy scripts that update config files before a service restart. Instead of opening an editor manually, the script runs `sed -i` to swap the environment value, then restarts the service.

---

## 5. Deleting Lines

```bash
# Delete all lines containing "frontend"
sed '/frontend/d' ~/webstore/config/webstore.conf

# Delete the last line
sed '$d' ~/webstore/config/webstore.conf

# Delete lines 5 through the end
sed '5,$d' ~/webstore/config/webstore.conf
```

**When you reach for delete:**
Stripping comment lines from a config file before parsing it. Removing header lines from a log file before piping it to another command.

```bash
# Strip all comment lines (lines starting with #) from a config
sed '/^#/d' ~/webstore/config/webstore.conf
```

---

## 6. Printing Specific Lines

Combined with `-n`, you can use sed to extract exactly the lines you need from a large file — like `head` and `tail` but with more control.

```bash
# Print only lines 2 through 4
sed -n '2,4p' ~/webstore/config/webstore.conf
# db_port=5432
# api_port=8080
# api_host=webstore-api

# Print only lines containing "api"
sed -n '/api/p' ~/webstore/config/webstore.conf
# api_port=8080
# api_host=webstore-api
```

---

## 7. Inserting and Appending Lines

```bash
# Insert a line BEFORE line 1
sed '1i\# webstore config — do not edit manually' ~/webstore/config/webstore.conf

# Append a line AFTER the last line
sed '$a\log_level=info' ~/webstore/config/webstore.conf

# Insert in-place — write it back to the file
sed -i '1i\# webstore config — do not edit manually' ~/webstore/config/webstore.conf
```

---

## 8. Running Multiple Commands

Use `-e` to chain multiple instructions in a single sed pass. One read of the file, multiple transformations applied.

```bash
# Swap environment to staging AND update the api port in one command
sed -e 's/production/staging/' -e 's/api_port=8080/api_port=9090/' ~/webstore/config/webstore.conf
```

This is cleaner than running sed twice and is faster on large files because the file is only read once.

---

## 9. Quick Reference

| Syntax | What it does | Example |
|---|---|---|
| `s/OLD/NEW/` | Replace first match per line | `sed 's/production/staging/' webstore.conf` |
| `s/OLD/NEW/g` | Replace all matches per line | `sed 's/webstore/mystore/g' webstore.conf` |
| `s#OLD#NEW#g` | Same but using `#` as delimiter | `sed 's#/api#/v2/api#g' webstore.conf` |
| `N s/OLD/NEW/` | Replace on line N only | `sed '1 s/production/staging/' webstore.conf` |
| `N,M s/OLD/NEW/` | Replace on lines N through M | `sed '1,3 s/webstore/mystore/' webstore.conf` |
| `/PAT/ s/OLD/NEW/` | Replace only on lines matching PAT | `sed '/port/ s/8080/9090/' webstore.conf` |
| `-n 's/OLD/NEW/p'` | Print only changed lines | `sed -n 's/production/staging/p' webstore.conf` |
| `-i 's/OLD/NEW/'` | Edit the file in-place | `sed -i 's/production/staging/' webstore.conf` |
| `/PAT/d` | Delete lines matching pattern | `sed '/^#/d' webstore.conf` |
| `$d` | Delete the last line | `sed '$d' webstore.conf` |
| `-n 'N,Mp'` | Print lines N through M only | `sed -n '2,4p' webstore.conf` |
| `Ni\TEXT` | Insert TEXT before line N | `sed '1i\# header' webstore.conf` |
| `$a\TEXT` | Append TEXT after last line | `sed '$a\log_level=info' webstore.conf` |
| `-e 'cmd1' -e 'cmd2'` | Run multiple commands in one pass | `sed -e 's/a/b/' -e 's/c/d/' webstore.conf` |

---

→ Ready to practice? [Go to Lab 02](../linux-labs/02-filters-sed-awk-lab.md)

---
# TOOL: 01. Linux – System Fundamentals | FILE: 06-awk
---

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

# awk — Text Processing

`cut` extracts columns. `grep` finds lines. `sed` transforms content. `awk` does all three at once — and adds arithmetic. It reads a file line by line, splits each line into fields, and lets you filter, extract, compute, and format the output in a single command.

The reason awk exists separately from the other filter tools is its ability to calculate. When you need to know the total number of bytes transferred across all 200 responses in an access log, or the average response time across a thousand requests, awk does it in one line. No spreadsheet. No Python script.

The webstore access log used throughout this file:

```
192.168.1.10 GET /api/products 200 512
192.168.1.11 GET /api/products 200 489
192.168.1.12 POST /api/orders 201 1024
192.168.1.10 GET /api/products 200 512
192.168.1.13 GET /api/users 404 128
192.168.1.14 POST /api/orders 500 256
192.168.1.11 GET /api/products 200 489
192.168.1.15 DELETE /api/orders/7 403 64
192.168.1.10 GET /api/products 200 512
192.168.1.14 POST /api/orders 500 256
```

Fields: `$1`=IP, `$2`=method, `$3`=path, `$4`=status, `$5`=bytes

---

## Table of Contents

- [1. How awk Works](#1-how-awk-works)
- [2. Built-in Variables](#2-built-in-variables)
- [3. Printing Fields](#3-printing-fields)
- [4. Pattern Matching](#4-pattern-matching)
- [5. Custom Field Separator](#5-custom-field-separator)
- [6. Conditionals](#6-conditionals)
- [7. Arithmetic and Aggregation](#7-arithmetic-and-aggregation)
- [8. BEGIN and END Blocks](#8-begin-and-end-blocks)
- [9. Real Incident One-Liners](#9-real-incident-one-liners)
- [10. awk vs cut — When to Use Which](#10-awk-vs-cut--when-to-use-which)
- [11. Quick Reference](#11-quick-reference)

---

## 1. How awk Works

awk reads a file one line at a time. Each line is called a **record**. Each record is automatically split into **fields** — by whitespace by default. You write rules that say: if this condition is true for a record, run this action.

```
awk 'PATTERN { ACTION }' file
```

- **PATTERN** — a condition to test against each line. If it matches, the action runs. If omitted, the action runs on every line.
- **ACTION** — what to do: print fields, calculate, format output.

The simplest awk command — print every line:

```bash
awk '{ print }' ~/webstore/logs/access.log
```

This is identical to `cat`. Not useful on its own, but it shows the structure: no pattern means "match everything," `print` with no arguments prints the whole line (`$0`).

---

## 2. Built-in Variables

These variables are available in every awk program without being defined:

| Variable | What it contains | Example value for line `192.168.1.10 GET /api/products 200 512` |
|---|---|---|
| `$0` | The entire current line | `192.168.1.10 GET /api/products 200 512` |
| `$1` | Field 1 | `192.168.1.10` |
| `$2` | Field 2 | `GET` |
| `$3` | Field 3 | `/api/products` |
| `$4` | Field 4 | `200` |
| `$5` | Field 5 | `512` |
| `NR` | Current line number (record number) | `1` on first line, `2` on second, etc. |
| `NF` | Number of fields in the current line | `5` for this log format |
| `FS` | Field separator (default: whitespace) | Set with `-F` flag |

---

## 3. Printing Fields

```bash
# Print only the IP address (field 1)
awk '{ print $1 }' ~/webstore/logs/access.log
# 192.168.1.10
# 192.168.1.11
# ...

# Print IP and status code together
awk '{ print $1, $4 }' ~/webstore/logs/access.log
# 192.168.1.10 200
# 192.168.1.11 200
# 192.168.1.12 201
# ...

# Print with a custom separator between fields
awk '{ print $1 " → " $4 }' ~/webstore/logs/access.log
# 192.168.1.10 → 200
# 192.168.1.11 → 200
# ...

# Print line number alongside each line
awk '{ print NR, $0 }' ~/webstore/logs/access.log
# 1 192.168.1.10 GET /api/products 200 512
# 2 192.168.1.11 GET /api/products 200 489
# ...
```

**awk vs cut for field extraction:**
Both extract fields. Use `cut` for simple, fast extraction with a consistent single-character delimiter. Use `awk` when you need to combine fields, add custom formatting, or do anything beyond raw extraction.

---

## 4. Pattern Matching

A pattern before the action block filters which lines the action runs on. Only lines where the pattern matches trigger the action.

```bash
# Print all lines containing "500"
awk '/500/ { print }' ~/webstore/logs/access.log
# 192.168.1.14 POST /api/orders 500 256
# 192.168.1.14 POST /api/orders 500 256

# Print only the IP and path for 500 errors
awk '/500/ { print $1, $3 }' ~/webstore/logs/access.log
# 192.168.1.14 /api/orders
# 192.168.1.14 /api/orders

# Match on a specific field — only lines where field 4 is exactly "500"
awk '$4 == "500" { print }' ~/webstore/logs/access.log
```

The difference between `/500/` and `$4 == "500"` matters when `500` could appear elsewhere in the line — for example, if a URL path contained `500`. Matching on `$4` is more precise.

---

## 5. Custom Field Separator

When your file uses a delimiter other than whitespace — commas, colons, equals signs — tell awk with `-F`.

```bash
# webstore.conf uses = as separator
# db_host=webstore-db
# db_port=5432

# Print only the values (field 2 after splitting on =)
awk -F '=' '{ print $2 }' ~/webstore/config/webstore.conf
# webstore-db
# 5432
# 8080
# ...

# Print key=value pairs with formatting
awk -F '=' '{ print "KEY: " $1 "  VALUE: " $2 }' ~/webstore/config/webstore.conf
# KEY: db_host  VALUE: webstore-db
# KEY: db_port  VALUE: 5432
# ...

# /etc/passwd uses : as separator — print username (field 1) and shell (field 7)
awk -F ':' '{ print $1, $7 }' /etc/passwd
```

---

## 6. Conditionals

Use `if` inside the action block to apply logic beyond simple pattern matching.

```bash
# Print lines where the status code is 500
awk '{ if ($4 == "500") print $0 }' ~/webstore/logs/access.log

# Print lines where bytes transferred is greater than 500
awk '{ if ($5 > 500) print $1, $3, $5 }' ~/webstore/logs/access.log
# 192.168.1.12 /api/orders 1024
# 192.168.1.10 /api/products 512
# 192.168.1.10 /api/products 512
# 192.168.1.10 /api/products 512

# Print lines where status is NOT 200
awk '{ if ($4 != "200") print $0 }' ~/webstore/logs/access.log
```

You can also write the condition as a pattern directly without `if`:

```bash
# These two are equivalent
awk '{ if ($4 == "500") print $0 }' access.log
awk '$4 == "500" { print }' access.log
```

The second form is more idiomatic awk. Use whichever reads more clearly to you.

---

## 7. Arithmetic and Aggregation

This is where awk separates itself from every other filter tool. Variables persist across lines — you can accumulate values as awk reads through a file.

```bash
# Sum the total bytes transferred across all requests
awk '{ total += $5 } END { print "Total bytes:", total }' ~/webstore/logs/access.log
# Total bytes: 4242

# Count how many 500 errors occurred
awk '$4 == "500" { count++ } END { print "500 errors:", count }' ~/webstore/logs/access.log
# 500 errors: 2

# Sum bytes for successful requests only (status 200)
awk '$4 == "200" { total += $5 } END { print "Bytes from 200s:", total }' ~/webstore/logs/access.log
# Bytes from 200s: 2514

# Calculate average bytes per request
awk '{ total += $5 } END { print "Average bytes:", total/NR }' ~/webstore/logs/access.log
# Average bytes: 424.2
```

**How accumulation works:**
`total += $5` adds field 5 of the current line to the variable `total`. Since `total` starts at zero and this runs on every line, by the time `END` runs, `total` contains the sum of every value in field 5 across the entire file.

---

## 8. BEGIN and END Blocks

`BEGIN` runs once before awk reads any lines. `END` runs once after all lines are processed. Both are optional.

```bash
# Print a header before the output, and a summary after
awk '
  BEGIN { print "--- Webstore Access Report ---" }
  { print $1, $4, $5 }
  END { print "--- Total lines:", NR, "---" }
' ~/webstore/logs/access.log

# Output:
# --- Webstore Access Report ---
# 192.168.1.10 200 512
# 192.168.1.11 200 489
# ...
# --- Total lines: 10 ---
```

`BEGIN` is also where you set the field separator as an alternative to `-F`:

```bash
awk 'BEGIN { FS="=" } { print $1, $2 }' ~/webstore/config/webstore.conf
```

---

## 9. Real Incident One-Liners

**How many requests came from each IP address?**
```bash
awk '{ count[$1]++ } END { for (ip in count) print count[ip], ip }' ~/webstore/logs/access.log | sort -rn
# 3 192.168.1.10
# 2 192.168.1.11
# 2 192.168.1.14
# ...
```

**What is the total bytes transferred per status code?**
```bash
awk '{ bytes[$4] += $5 } END { for (status in bytes) print status, bytes[status] }' ~/webstore/logs/access.log
# 200 2514
# 201 1024
# 500 512
# ...
```

**Print only lines where the request path starts with /api/orders:**
```bash
awk '$3 ~ /^\/api\/orders/ { print }' ~/webstore/logs/access.log
```

**Print a formatted report of all non-200 requests:**
```bash
awk '$4 != "200" { printf "%-18s %-8s %-25s %s\n", $1, $2, $3, $4 }' ~/webstore/logs/access.log
```

---

## 10. awk vs cut — When to Use Which

| Situation | Use |
|---|---|
| Extract one or two fields, simple delimiter | `cut` — faster, simpler syntax |
| Extract fields with custom formatting between them | `awk` |
| Filter rows by field value | `awk` |
| Calculate totals, averages, counts | `awk` — `cut` cannot do this |
| Multiple conditions across different fields | `awk` |
| Quick IP extraction from access log | Either — `cut -d' ' -f1` or `awk '{print $1}'` |

---

## 11. Quick Reference

| Command | What it does |
|---|---|
| `awk '{ print }' file` | Print every line |
| `awk '{ print $1 }' file` | Print field 1 only |
| `awk '{ print $1, $4 }' file` | Print fields 1 and 4 with space between |
| `awk '{ print NR, $0 }' file` | Print line number with each line |
| `awk '/PATTERN/ { print }' file` | Print lines matching pattern |
| `awk '$4 == "500" { print }' file` | Print lines where field 4 equals 500 |
| `awk '$5 > 1000 { print }' file` | Print lines where field 5 is greater than 1000 |
| `awk -F ':' '{ print $1 }' file` | Use `:` as field separator |
| `awk -F '=' '{ print $2 }' file` | Use `=` as field separator — useful for config files |
| `awk '{ total += $5 } END { print total }' file` | Sum all values in field 5 |
| `awk '$4=="500"{ c++ } END{ print c }' file` | Count lines where field 4 is 500 |
| `awk '{ total += $5 } END { print total/NR }' file` | Average of field 5 across all lines |
| `awk 'BEGIN{print "start"} { print } END{print "end"}' file` | Header + content + footer |

---

→ Ready to practice? [Go to Lab 02](../linux-labs/02-filters-sed-awk-lab.md)

---
# TOOL: 01. Linux – System Fundamentals | FILE: 07-text-editor
---

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

# vim — Terminal Text Editor

On a remote Linux server there is no GUI. No VS Code, no Sublime, no Notepad. When you need to edit a config file, fix a broken nginx config, or write a quick script, you use a terminal editor. `vim` is the one you will find on every Linux server without exception — it ships with the OS or is one package install away.

The reason vim feels hard at first is that it is **modal** — it has separate modes for navigating and for typing. Most editors have one mode: you open a file and start typing. vim separates these deliberately, because navigating and editing are different tasks that deserve different keystrokes. Once that mental model clicks, vim becomes fast.

---

## Table of Contents

- [1. The Three Modes](#1-the-three-modes)
- [2. Opening and Exiting](#2-opening-and-exiting)
- [3. Navigation](#3-navigation)
- [4. Editing](#4-editing)
- [5. Search and Replace](#5-search-and-replace)
- [6. The Webstore Workflow — Real Editing Scenarios](#6-the-webstore-workflow--real-editing-scenarios)
- [7. Quick Reference](#7-quick-reference)

---

## 1. The Three Modes

vim starts in **Normal mode** every time you open it. This is the source of most beginner confusion — you open a file, start typing, and nothing appears where you expect it to.

```
Normal mode  ←──────────── Esc ─────────────┐
     │                                       │
     │  i / a / o                            │
     ▼                                       │
Insert mode  ── type your content ───────────┘

Normal mode
     │
     │  :
     ▼
Command-line mode  ── :w  :q  :wq  :%s/old/new/g
```

| Mode | How to enter | What you do here |
|---|---|---|
| Normal | Default on open, or press `Esc` from any other mode | Navigate, delete, copy, paste — keyboard is commands not text |
| Insert | Press `i`, `a`, or `o` from Normal mode | Type text — keyboard behaves like a normal editor |
| Command-line | Press `:` from Normal mode | Save, quit, search and replace, open other files |

**The rule that prevents most frustration:** whenever vim is not behaving as expected, press `Esc` first. `Esc` always returns you to Normal mode from anywhere.

---

## 2. Opening and Exiting

```bash
# Open a file
vim ~/webstore/config/webstore.conf

# Open and jump directly to line 5
vim +5 ~/webstore/config/webstore.conf

# Open a new file (creates it on save)
vim ~/webstore/config/nginx.conf
```

**Exiting — the commands everyone needs to know first:**

| Command | What it does |
|---|---|
| `:w` | Save (write) the file — stay in vim |
| `:q` | Quit — only works if no unsaved changes |
| `:wq` | Save and quit |
| `:q!` | Quit without saving — discard all changes |
| `:x` | Save and quit — same as `:wq` but skips write if nothing changed |

`:q!` is the one you reach for when you opened the wrong file or made changes you want to throw away. It forces quit with no questions asked.

---

## 3. Navigation

In Normal mode the keyboard is for movement, not typing. These are the keys you use to move around a file without touching the mouse.

**Basic movement:**

| Key | Movement |
|---|---|
| `h` | Left one character |
| `l` | Right one character |
| `j` | Down one line |
| `k` | Up one line |
| `w` | Forward one word |
| `b` | Backward one word |
| `0` | Beginning of current line |
| `$` | End of current line |
| `gg` | First line of the file |
| `G` | Last line of the file |
| `NG` | Jump to line N — e.g. `5G` jumps to line 5 |

**Prepend a number to repeat any movement:**
`5j` moves down 5 lines. `3w` jumps forward 3 words. `10G` jumps to line 10. This is how you navigate a large config file without scrolling.

**When you reach for `NG`:**
An error message says "syntax error on line 47 of webstore.conf" — type `47G` in Normal mode and you land exactly there.

---

## 4. Editing

All editing commands run from Normal mode. You do not need to enter Insert mode to delete, copy, or paste.

**Entering Insert mode — where to start typing:**

| Key | Where insertion begins |
|---|---|
| `i` | Before the cursor |
| `a` | After the cursor |
| `o` | New line below the current line |
| `O` | New line above the current line |

After typing your content, press `Esc` to return to Normal mode.

**Editing without Insert mode:**

| Command | What it does |
|---|---|
| `x` | Delete the character under the cursor |
| `dd` | Delete (cut) the entire current line |
| `D` | Delete from cursor to end of line |
| `cw` | Delete the current word and enter Insert mode to replace it |
| `yy` | Yank (copy) the current line |
| `Nyy` | Yank N lines — `3yy` copies 3 lines |
| `p` | Paste after the cursor / below the current line |
| `u` | Undo the last change |
| `Ctrl+R` | Redo — reverse an undo |

**The most useful editing sequence in practice:**
`dd` to cut a line, navigate to where you want it, `p` to paste it. This is how you reorder lines in a config file without retyping them.

---

## 5. Search and Replace

**Search:**

```
/pattern      search forward — press n for next match, N for previous
?pattern      search backward
```

```bash
# Inside vim — find every occurrence of "webstore-db" in the config
/webstore-db
# Press n to jump to the next match
# Press N to jump backwards
```

**Replace — the command-line mode substitute:**

```
:%s/old/new/g
```

- `%` — apply to the entire file (without `%` it only applies to the current line)
- `s` — substitute
- `old` — pattern to find
- `new` — replacement
- `g` — replace all occurrences on each line (without `g` only the first per line)

```bash
# Replace every occurrence of "production" with "staging" in the entire file
:%s/production/staging/g

# Replace with confirmation for each change — vim shows each match and asks y/n
:%s/production/staging/gc

# Replace only on the current line
:s/production/staging/g

# Replace only on lines 2 through 5
:2,5s/8080/9090/g
```

**When you reach for `:%s`:**
Updating a config file to point at a new database host, changing a port number that appears multiple times, or sanitizing a file before committing it. Faster than finding every occurrence manually.

---

## 6. The Webstore Workflow — Real Editing Scenarios

**Scenario 1 — Edit the webstore config to change the API port:**

```
vim ~/webstore/config/webstore.conf   # open the file
/api_port                             # search for the line
cw                                    # delete "api_port" and enter insert mode
api_port=9090                         # type the new value
Esc                                   # back to Normal mode
:wq                                   # save and quit
```

**Scenario 2 — nginx config has a syntax error on line 12:**

```
vim ~/webstore/config/nginx.conf      # open the file
12G                                   # jump directly to line 12
```
Read the line, find the error, press `i` to enter Insert mode, fix it, press `Esc`, then `:wq`.

**Scenario 3 — Add a new config entry at the end of webstore.conf:**

```
vim ~/webstore/config/webstore.conf   # open the file
G                                     # jump to last line
o                                     # open new line below and enter Insert mode
log_level=info                        # type the new entry
Esc                                   # back to Normal mode
:wq                                   # save and quit
```

**Scenario 4 — Replace all occurrences of the old database hostname:**

```
vim ~/webstore/config/webstore.conf
:%s/webstore-db-old/webstore-db/g
:wq
```

---

## 7. Quick Reference

**Modes:**

| Key | Action |
|---|---|
| `Esc` | Return to Normal mode from anywhere |
| `i` | Enter Insert mode before cursor |
| `a` | Enter Insert mode after cursor |
| `o` | New line below, enter Insert mode |
| `:` | Enter Command-line mode |

**Navigation (Normal mode):**

| Key | Action |
|---|---|
| `h j k l` | Left, down, up, right |
| `w` / `b` | Next / previous word |
| `0` / `$` | Start / end of line |
| `gg` / `G` | First / last line |
| `NG` | Jump to line N |

**Editing (Normal mode):**

| Key | Action |
|---|---|
| `x` | Delete character under cursor |
| `dd` | Delete current line |
| `yy` | Copy current line |
| `p` | Paste after cursor |
| `u` | Undo |
| `Ctrl+R` | Redo |
| `cw` | Change word |

**Save and exit (Command-line mode):**

| Command | Action |
|---|---|
| `:w` | Save |
| `:q` | Quit (no unsaved changes) |
| `:wq` | Save and quit |
| `:q!` | Quit without saving |

**Search and replace (Command-line mode):**

| Command | Action |
|---|---|
| `/pattern` | Search forward |
| `n` / `N` | Next / previous match |
| `:%s/old/new/g` | Replace all in file |
| `:%s/old/new/gc` | Replace all with confirmation |

---

→ Ready to practice? [Go to Lab 03](../linux-labs/03-vim-users-permissions-lab.md)

---
# TOOL: 01. Linux – System Fundamentals | FILE: 08-user-&-group-management
---

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

---
# TOOL: 01. Linux – System Fundamentals | FILE: 09-file-ownership-&-permissions
---

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

---
# TOOL: 01. Linux – System Fundamentals | FILE: 10-archiving-and-compression
---

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

# Archiving and Compression

Before every deploy, you archive the current state of the webstore. Before rotating logs, you compress last month's access log. When you need to move the entire project to a new server, you pack it into one file and transfer it. These are not optional practices — they are the habits that let you recover when something goes wrong.

This file covers two distinct operations that are often confused:

- **Archiving** — combining multiple files and directories into one file. No size reduction. The purpose is portability and organization.
- **Compression** — reducing a file's size. The purpose is storage efficiency and faster transfer.

`tar` archives. `gzip` compresses. Used together — `tar.gz` — you get both.

---

## Table of Contents

- [1. Archiving vs Compression](#1-archiving-vs-compression)
- [2. tar — The Standard Tool](#2-tar--the-standard-tool)
- [3. gzip — Compressing Single Files](#3-gzip--compressing-single-files)
- [4. Reading Compressed Files Without Extracting](#4-reading-compressed-files-without-extracting)
- [5. zip and unzip](#5-zip-and-unzip)
- [6. The Webstore Backup Workflow](#6-the-webstore-backup-workflow)
- [7. Quick Reference](#7-quick-reference)

---

## 1. Archiving vs Compression

| Tool | What it does | Output |
|---|---|---|
| `tar` | Combines files into one archive — no compression | `.tar` |
| `gzip` | Compresses a single file | `.gz` |
| `tar + gzip` | Archives and compresses in one step — the Linux standard | `.tar.gz` or `.tgz` |
| `zip` | Archives and compresses — common on Windows, cross-platform | `.zip` |

**The rule in practice:** on Linux servers you use `tar.gz`. It preserves file permissions, ownership, symlinks, and directory structure — everything you need to restore a backup to an identical state. `zip` does not preserve Unix permissions reliably, which matters when restoring a webstore with carefully set `chmod` values.

---

## 2. tar — The Standard Tool

`tar` reads like a sentence: what to do, how to do it, what to name the result, what to include.

**The flags you use constantly:**

| Flag | Meaning |
|---|---|
| `c` | Create a new archive |
| `x` | Extract from an archive |
| `t` | List contents without extracting |
| `z` | Compress or decompress with gzip |
| `v` | Verbose — print each file as it is processed |
| `f` | The next argument is the archive filename — always required |

The order matters: `tar -czvf archive.tar.gz source/` — flags first, archive name second, source last.

**Create an archive:**

```bash
# Archive the entire webstore directory — no compression yet
tar -cvf webstore.tar ~/webstore/

# Output — verbose shows every file being added:
# webstore/
# webstore/config/
# webstore/config/webstore.conf
# webstore/logs/
# webstore/logs/access.log
# webstore/logs/error.log
# ...
```

**Create a compressed archive (the one you actually use):**

```bash
# Archive + compress the webstore in one step
tar -czvf webstore-backup.tar.gz ~/webstore/

# With a timestamp in the filename — essential for multiple backups
tar -czvf webstore-backup-$(date +%Y-%m-%d).tar.gz ~/webstore/
# Creates: webstore-backup-2025-04-05.tar.gz
```

**List contents without extracting — always do this before extracting:**

```bash
tar -tzvf webstore-backup-2025-04-05.tar.gz

# Output shows permissions, owner, size, date, path:
# drwxr-xr-x akhil/webstore-team    0  2025-04-05  webstore/
# -rw-r--r-- akhil/webstore-team  128  2025-04-05  webstore/config/webstore.conf
# -rw-rw-r-- akhil/webstore-team 2.4K  2025-04-05  webstore/logs/access.log
```

This confirms the archive contains what you expect before you extract it. Extracting blindly into the wrong directory can overwrite files.

**Extract an archive:**

```bash
# Extract into the current directory
tar -xzvf webstore-backup-2025-04-05.tar.gz

# Extract into a specific directory — safer than extracting in place
tar -xzvf webstore-backup-2025-04-05.tar.gz -C /tmp/restore/

# Extract a single file from the archive
tar -xzvf webstore-backup-2025-04-05.tar.gz webstore/config/webstore.conf
```

The `-C` flag is important. Without it, tar extracts relative to your current directory. With it, you control exactly where things land — critical when restoring to a non-default path.

---

## 3. gzip — Compressing Single Files

`gzip` compresses one file and replaces it with a `.gz` version. The original file is gone after compression — this is different from `tar` which always creates a new file.

```bash
# Compress last month's access log — original is replaced
gzip ~/webstore/logs/access.log.old
ls -lh ~/webstore/logs/
# -rw-rw-r-- akhil webstore-team 312K access.log.old.gz
# (was 1.8M before compression — typical 80% reduction for log files)

# Maximum compression — slower but smallest output
gzip -9 ~/webstore/logs/error.log.old

# Keep the original file (do not replace it)
gzip -k ~/webstore/logs/access.log.old

# Decompress — restores the original file
gunzip ~/webstore/logs/access.log.old.gz
```

**When you reach for gzip directly:**
Log rotation — compressing last month's logs before archiving them off the server. Individual config file backup before editing. Log files compress extremely well (60-85% reduction) because they contain repetitive text.

---

## 4. Reading Compressed Files Without Extracting

When a log file is compressed, you do not have to decompress it to search it. These commands work directly on `.gz` files:

```bash
# Print the entire contents of a compressed log
zcat ~/webstore/logs/access.log.gz

# Page through it
zless ~/webstore/logs/access.log.gz

# Search for 500 errors inside the compressed log — no extraction needed
zcat ~/webstore/logs/access.log.gz | grep '500'

# Count 500 errors in the compressed log
zcat ~/webstore/logs/access.log.gz | grep -c '500'
```

This is the pattern for searching historical logs. You keep old logs compressed to save space, and `zcat` lets you query them without decompressing to disk.

---

## 5. zip and unzip

`zip` is useful when you need to share files with systems that expect `.zip` — Windows, certain APIs, email attachments. On Linux servers between themselves, use `tar.gz`.

```bash
# Zip specific files
zip webstore-logs.zip ~/webstore/logs/access.log ~/webstore/logs/error.log

# Zip an entire directory recursively
zip -r webstore-config.zip ~/webstore/config/

# List contents without extracting
unzip -l webstore-config.zip

# Extract
unzip webstore-config.zip

# Extract to a specific directory
unzip webstore-config.zip -d /tmp/restore/
```

**zip vs tar.gz on Linux:**
`tar.gz` preserves Unix permissions, ownership, and symlinks. `zip` may not. If you archive the webstore with `zip` and extract it on another Linux server, the file permissions may be wrong and you will have to run `chmod` and `chown` again. Use `tar.gz` for Linux-to-Linux transfers.

---

## 6. The Webstore Backup Workflow

This is the sequence you run before every significant change to the webstore on a server — before a deploy, before editing config files, before a system update.

```bash
# Step 1 — create a timestamped backup of the entire project
tar -czvf ~/webstore/backup/webstore-$(date +%Y-%m-%d-%H%M).tar.gz \
    --exclude='~/webstore/backup' \
    ~/webstore/

# Step 2 — verify the archive is not corrupted and contains what you expect
tar -tzvf ~/webstore/backup/webstore-2025-04-05-0914.tar.gz | head -20

# Step 3 — confirm the size is reasonable
ls -lh ~/webstore/backup/

# Step 4 — if something goes wrong after your change, restore:
tar -xzvf ~/webstore/backup/webstore-2025-04-05-0914.tar.gz -C /tmp/restore/
# Then verify the restore, swap the directories, restart nginx
```

The `--exclude` flag prevents the backup directory from being included inside itself — without it, each backup would contain all previous backups.

**Log rotation backup — compress old logs monthly:**

```bash
# Compress logs older than 30 days
find ~/webstore/logs/ -name "*.log" -mtime +30 -exec gzip {} \;

# Verify compression happened
ls -lh ~/webstore/logs/
```

---

## 7. Quick Reference

| Command | What it does | Example |
|---|---|---|
| `tar -czvf <archive> <source>` | Create compressed archive | `tar -czvf backup.tar.gz ~/webstore/` |
| `tar -tzvf <archive>` | List contents without extracting | `tar -tzvf backup.tar.gz` |
| `tar -xzvf <archive>` | Extract compressed archive | `tar -xzvf backup.tar.gz` |
| `tar -xzvf <archive> -C <dir>` | Extract to specific directory | `tar -xzvf backup.tar.gz -C /tmp/restore/` |
| `tar -xzvf <archive> <file>` | Extract a single file | `tar -xzvf backup.tar.gz webstore/config/webstore.conf` |
| `gzip <file>` | Compress file — replaces original | `gzip access.log.old` |
| `gzip -k <file>` | Compress file — keep original | `gzip -k access.log` |
| `gzip -9 <file>` | Maximum compression | `gzip -9 error.log.old` |
| `gunzip <file>.gz` | Decompress | `gunzip access.log.gz` |
| `zcat <file>.gz` | Print compressed file contents | `zcat access.log.gz` |
| `zless <file>.gz` | Page through compressed file | `zless access.log.gz` |
| `zcat <file>.gz \| grep <pattern>` | Search inside compressed file | `zcat access.log.gz \| grep '500'` |
| `zip -r <archive> <dir>` | Zip a directory | `zip -r config.zip ~/webstore/config/` |
| `unzip <archive> -d <dir>` | Extract zip to directory | `unzip config.zip -d /tmp/restore/` |

---

→ Ready to practice? [Go to Lab 04](../linux-labs/04-archive-packages-services-lab.md)

---
# TOOL: 01. Linux – System Fundamentals | FILE: 11-package-management
---

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

---
# TOOL: 01. Linux – System Fundamentals | FILE: 12-service-management
---

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

---
# TOOL: 01. Linux – System Fundamentals | FILE: 13-networking
---

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

# Linux Networking

When something is wrong with a running service, the problem is often in the network layer. nginx is running but not responding. The API cannot reach the database. A port that should be open is not. A request is arriving but taking 3 seconds to respond and you do not know where the delay is.

These tools are how you answer those questions from the command line. No GUI. No external monitoring tool. Just the terminal and the commands that let you see exactly what is happening on the network right now.

---

## Table of Contents

- [1. ip — Inspect Network Interfaces](#1-ip--inspect-network-interfaces)
- [2. ping — Confirm Reachability](#2-ping--confirm-reachability)
- [3. traceroute — Find Where Delay Lives](#3-traceroute--find-where-delay-lives)
- [4. dig — Query DNS](#4-dig--query-dns)
- [5. curl — Test HTTP Endpoints](#5-curl--test-http-endpoints)
- [6. ss — See What Is Listening](#6-ss--see-what-is-listening)
- [7. nc — Test Port Connectivity](#7-nc--test-port-connectivity)
- [8. tcpdump — Capture Live Traffic](#8-tcpdump--capture-live-traffic)
- [9. nmap — Scan Open Ports](#9-nmap--scan-open-ports)
- [10. iftop — Watch Bandwidth Live](#10-iftop--watch-bandwidth-live)
- [11. The Webstore Debug Workflow](#11-the-webstore-debug-workflow)
- [12. Quick Reference](#12-quick-reference)

---

## 1. ip — Inspect Network Interfaces

`ip` shows and configures network interfaces — the connections your server has to the network. When you SSH into a server for the first time, `ip addr` tells you what IP addresses the machine has and on which interfaces.

```bash
# Show all interfaces and their IP addresses
ip addr show

# Output:
# 1: lo: <LOOPBACK,UP,LOWER_UP>
#     inet 127.0.0.1/8 scope host lo
# 2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP>
#     inet 10.0.1.45/24 brd 10.0.1.255 scope global eth0
```

`lo` is the loopback interface — `127.0.0.1`, the address a service uses to talk to itself on the same machine. `eth0` (or `enp3s0` on newer systems) is the real network interface with the server's actual IP.

```bash
# Show the routing table — how the server decides where to send traffic
ip route show

# Output:
# default via 10.0.1.1 dev eth0        ← default gateway
# 10.0.1.0/24 dev eth0 proto kernel    ← local network route

# Show only a specific interface
ip addr show eth0
```

**When you reach for `ip`:**
Confirming the server's IP after provisioning. Checking which interface is active when you have multiple network cards. Verifying the default gateway when traffic is not routing correctly.

---

## 2. ping — Confirm Reachability

`ping` sends ICMP echo requests to a target and measures whether it responds and how long it takes. It answers the most basic question: can this machine reach that machine?

```bash
# Ping the webstore-api from another container or server
ping webstore-api

# Stop after 4 packets
ping -c 4 webstore-api

# Output:
# PING webstore-api (172.18.0.3): 56 data bytes
# 64 bytes from 172.18.0.3: icmp_seq=0 ttl=64 time=0.312 ms
# 64 bytes from 172.18.0.3: icmp_seq=1 ttl=64 time=0.287 ms
# --- webstore-api ping statistics ---
# 4 packets transmitted, 4 received, 0% packet loss
# round-trip min/avg/max = 0.287/0.299/0.312 ms
```

**Reading ping output:**
`time=0.312 ms` is round-trip latency — how long the packet took to go and come back. On a local network this should be under 1ms. Across the internet, 10–50ms is normal. Packet loss above 0% means something is dropping packets between the two machines.

**When `ping` fails:**
A failed ping does not always mean the host is down. Some servers block ICMP deliberately. If ping fails, follow up with `nc` or `curl` to test a specific port before concluding the host is unreachable.

```bash
# Ping the database to confirm network connectivity
ping -c 3 webstore-db

# Ping localhost to confirm the loopback interface is up
ping -c 2 localhost
```

---

## 3. traceroute — Find Where Delay Lives

`traceroute` maps every router hop between you and a destination, showing the latency at each step. When a request is slow and you do not know where the delay is, `traceroute` tells you exactly which hop is adding the time.

```bash
# Trace the path to the webstore API server
traceroute webstore-api.example.com

# Skip DNS lookups — faster, shows only IPs
traceroute -n webstore-api.example.com

# Output:
#  1  10.0.1.1      0.891 ms  0.823 ms  0.812 ms     ← your gateway
#  2  172.16.0.1    1.234 ms  1.198 ms  1.211 ms     ← ISP router
#  3  54.239.1.1    8.456 ms  8.421 ms  8.433 ms     ← AWS edge
#  4  54.239.2.15  10.123 ms 10.098 ms 10.112 ms     ← destination
```

Each line is one hop. Three time values are three probes sent to that hop. `* * *` means a router is blocking traceroute probes — not necessarily broken, just silent.

**When you reach for `traceroute`:**
API response times jumped from 50ms to 800ms. `traceroute` shows hop 3 suddenly adding 700ms — you know the delay is at the ISP level, not your server.

---

## 4. dig — Query DNS

`dig` queries DNS servers directly and shows the full response. When a hostname is not resolving, or resolving to the wrong IP, `dig` shows you exactly what the DNS server returned and which server answered.

```bash
# Look up the IP for webstore-api
dig webstore-api.example.com

# Short answer only — just the IP
dig +short webstore-api.example.com
# 54.239.28.81

# Query a specific DNS server — bypass your default resolver
dig @8.8.8.8 webstore-api.example.com

# Look up the DNS server responsible for a domain (NS record)
dig webstore-api.example.com NS

# Trace the full DNS resolution path from root servers down
dig +trace webstore-api.example.com

# Check if a domain has an MX record
dig webstore-api.example.com MX
```

**What the `dig` output tells you:**

```
;; ANSWER SECTION:
webstore-api.example.com.  300  IN  A  54.239.28.81
#                          ^^^
#                          TTL — seconds until this record expires from cache
```

TTL (Time to Live) is how long resolvers cache this answer. A TTL of 300 means DNS changes take up to 5 minutes to propagate. If you just updated a DNS record and it is not working yet, check the TTL.

**When you reach for `dig`:**
You deployed to a new server and updated the DNS record but traffic is still hitting the old server. `dig +short` shows the old IP is still being returned — the TTL has not expired yet.

---

## 5. curl — Test HTTP Endpoints

`curl` makes HTTP requests from the terminal. It is how you test whether a service is responding correctly without opening a browser — essential on a server with no GUI.

```bash
# Test the webstore-api is responding
curl http://localhost:8080

# Test with verbose output — see request headers and response headers
curl -v http://localhost:8080/api/products

# Test only the response headers — useful for checking status codes
curl -I http://localhost:8080/api/products
# HTTP/1.1 200 OK
# Content-Type: application/json
# ...

# POST request with a JSON body — testing the orders endpoint
curl -X POST http://localhost:8080/api/orders \
  -H "Content-Type: application/json" \
  -d '{"product_id": 1, "quantity": 2}'

# Follow redirects automatically
curl -L http://webstore.example.com

# Test with a specific Host header — testing virtual host routing
curl -H "Host: webstore.example.com" http://localhost

# Set a timeout — fail if no response in 5 seconds
curl --max-time 5 http://localhost:8080/api/products

# Save response to a file
curl http://localhost:8080/api/products -o products.json
```

**Reading curl -I output:**
The HTTP status code tells you immediately what happened — `200 OK` means success, `301/302` means redirect, `404` means not found, `502 Bad Gateway` means nginx received the request but the upstream API did not respond, `503 Service Unavailable` means nginx could not reach the upstream at all.

**When you reach for `curl`:**
After a deploy, before announcing the service is up. After editing nginx config, to confirm the new routing is working. When a user reports an endpoint is broken — reproduce it from the server with curl to confirm and capture the exact response.

---

## 6. ss — See What Is Listening

`ss` shows socket statistics — every active network connection and every port the server is listening on. It replaced `netstat` on modern Linux systems.

```bash
# Show all listening TCP ports with process names
sudo ss -tlnp

# Output:
# State    Recv-Q  Send-Q  Local Address:Port  Peer Address:Port  Process
# LISTEN   0       511     0.0.0.0:80         0.0.0.0:*          users:(("nginx",pid=1235,fd=6))
# LISTEN   0       128     0.0.0.0:22         0.0.0.0:*          users:(("sshd",pid=845,fd=3))
# LISTEN   0       128     127.0.0.1:5432     0.0.0.0:*          users:(("postgres",pid=987,fd=5))
```

Reading this output: port 80 is nginx listening on all interfaces (`0.0.0.0`) — accessible from outside. Port 5432 is postgres listening only on `127.0.0.1` — only accessible locally, not from outside the server. Port 22 is sshd.

```bash
# Show all TCP and UDP connections with process names — numeric only
sudo ss -tunp

# Show connections to a specific port — who is connected to port 8080
sudo ss -t dst :8080

# Show established connections only
sudo ss -t state established

# Check if nginx is listening on port 80
sudo ss -tlnp | grep :80
```

**When you reach for `ss`:**
You deployed nginx but `curl http://localhost` is not responding. `ss -tlnp` shows nginx is not in the list — it failed to start or is not bound to the expected port. Or you see port 8080 is not in the list — the API service is not running.

---

## 7. nc — Test Port Connectivity

`nc` (netcat) opens a raw TCP or UDP connection to a port. It is the fastest way to test whether a specific port is open and accepting connections — without needing to speak the full protocol of whatever service is running there.

```bash
# Test if port 8080 on the API server is accepting connections
nc -zv webstore-api 8080
# Connection to webstore-api 8080 port [tcp/*] succeeded!

# Test if the database port is reachable
nc -zv webstore-db 5432
# Connection to webstore-db 5432 port [tcp/*] succeeded!

# Test with a timeout — fail after 3 seconds
nc -zv -w 3 webstore-api 8080

# Test if port 80 is open on a remote server
nc -zv webstore.example.com 80
```

`-z` means zero I/O — just test the connection, do not send data. `-v` is verbose — shows whether the connection succeeded or failed.

**When you reach for `nc`:**
The API cannot connect to the database. Before debugging the application, use `nc -zv webstore-db 5432` from the API server. If nc fails, it is a network problem. If nc succeeds, the problem is in the application layer — wrong credentials, wrong database name, wrong connection string.

---

## 8. tcpdump — Capture Live Traffic

`tcpdump` captures raw network packets in real time. It shows you exactly what is going over the wire — every request, every response, every header. It is the deepest debugging tool in this list and the one you reach for when everything else has failed to explain what is happening.

```bash
# Capture all traffic on eth0 — stop with Ctrl+C
sudo tcpdump -i eth0

# Capture only HTTP traffic on port 80
sudo tcpdump -i eth0 port 80

# Capture traffic to or from the webstore-api IP
sudo tcpdump -i eth0 host 10.0.1.45

# Capture with no DNS lookups — shows IPs not hostnames
sudo tcpdump -i eth0 -n port 80

# Capture and show packet contents in ASCII
sudo tcpdump -i eth0 -A port 8080

# Save capture to a file for analysis
sudo tcpdump -i eth0 -w webstore-capture.pcap port 8080

# Read from a saved capture file
sudo tcpdump -r webstore-capture.pcap
```

**When you reach for `tcpdump`:**
`curl` returns a response but it looks wrong. `ss` shows connections are being established. But something in the data is not right. `tcpdump -A port 8080` shows you the raw HTTP request and response — every header, every body. You can see exactly what nginx is sending and what it is receiving.

---

## 9. nmap — Scan Open Ports

`nmap` probes a host or range of hosts and reports which ports are open. On your own servers, it confirms your firewall is configured correctly — that only the ports you intend to expose are exposed.

```bash
# Scan the webstore server — which ports are open?
nmap webstore.example.com

# Scan specific ports only
nmap -p 22,80,443,8080 webstore.example.com

# Scan with service version detection
nmap -sV webstore.example.com

# Fast scan — top 100 most common ports
nmap -F webstore.example.com

# Output:
# PORT     STATE  SERVICE
# 22/tcp   open   ssh
# 80/tcp   open   http
# 8080/tcp open   http-proxy
# 5432/tcp closed postgresql   ← good — DB should not be exposed
```

**When you reach for `nmap`:**
After configuring a firewall, confirm that port 5432 (database) is closed to the outside world and port 80 is open. `nmap` from an external machine gives you the attacker's view of your server — what they can see.

---

## 10. iftop — Watch Bandwidth Live

`iftop` shows a real-time view of network bandwidth usage per connection. When a server is saturating its network link and you need to know which connection is consuming it, `iftop` shows you immediately.

```bash
# Watch all traffic on eth0
sudo iftop -i eth0

# Show IPs only — no DNS lookups
sudo iftop -n -i eth0
```

Press `q` to quit. The display shows source and destination IPs with bandwidth rates — 2s, 10s, and 40s averages.

**When you reach for `iftop`:**
A server's network usage jumped to 90% of capacity. `iftop` shows one IP address consuming almost all of it — a likely sign of a backup job, a runaway log shipper, or a DDoS attempt.

---

## 11. The Webstore Debug Workflow

This is the sequence you follow when something is wrong with the webstore and you need to isolate where the problem is. Work from the outside in — network first, then application.

**Scenario: users report the webstore is not loading**

```bash
# Step 1 — is nginx running and listening on port 80?
sudo ss -tlnp | grep :80
# If nothing appears — nginx is not listening. Check status:
sudo systemctl status nginx
journalctl -u nginx -n 20

# Step 2 — can the server respond to HTTP at all?
curl -I http://localhost
# 200 OK → nginx is up
# Connection refused → nginx is not running or not bound to port 80

# Step 3 — can the API be reached from the frontend server?
nc -zv webstore-api 8080
# succeeded → port is open, network is fine
# failed → check if the API service is running, check firewall

# Step 4 — is the API actually responding correctly?
curl -v http://webstore-api:8080/api/products
# Check status code and response body

# Step 5 — can the API reach the database?
nc -zv webstore-db 5432
# succeeded → database port is reachable
# failed → database is down or firewall is blocking

# Step 6 — is DNS resolving correctly?
dig +short webstore-api.example.com
# Compare to the IP you expect

# Step 7 — if traffic is getting in but responses are wrong, capture it
sudo tcpdump -A -i eth0 port 8080 -c 20
# Read the raw HTTP request and response
```

Work through each step in order. Each command either confirms a layer is working or identifies where the break is.

---

## 12. Quick Reference

| Command | What it does | When you reach for it |
|---|---|---|
| `ip addr show` | Show all interfaces and IP addresses | First thing after SSHing into a new server |
| `ip route show` | Show routing table | Diagnosing routing problems |
| `ping -c 4 <host>` | Test reachability with 4 packets | Confirming two machines can reach each other |
| `traceroute -n <host>` | Trace route, show IPs only | Finding which hop is adding latency |
| `dig +short <host>` | Quick DNS lookup | Confirming a hostname resolves to the right IP |
| `dig +trace <host>` | Full DNS resolution trace | Debugging DNS propagation after a record change |
| `curl -I <url>` | Show HTTP response headers only | Checking status code without full body |
| `curl -v <url>` | Verbose HTTP request and response | Debugging headers, auth, redirects |
| `sudo ss -tlnp` | Show listening TCP ports with process names | Confirming a service is bound to the right port |
| `sudo ss -tunp` | Show all TCP and UDP connections | Full socket inventory |
| `nc -zv <host> <port>` | Test if a port is open | Isolating network vs application problems |
| `sudo tcpdump -i eth0 port <port>` | Capture traffic on a specific port | Deep packet inspection when nothing else explains it |
| `sudo tcpdump -A -i eth0 port <port>` | Capture with ASCII payload | Reading raw HTTP request and response content |
| `nmap -p <ports> <host>` | Scan specific ports | Verifying firewall rules from outside |
| `sudo iftop -n -i eth0` | Watch bandwidth per connection live | Finding which connection is saturating the link |

---

→ Ready to practice? [Go to Lab 05](../linux-labs/05-networking-lab.md)

---
# TOOL: 01. Linux – System Fundamentals | FILE: linux-labs
---

[Home](../README.md) |
[Labs Index](./README.md) |
[Lab 01](./01-boot-basics-files-lab.md) |
[Lab 02](./02-filters-sed-awk-lab.md) |
[Lab 03](./03-vim-users-permissions-lab.md) |
[Lab 04](./04-archive-packages-services-lab.md) |
[Lab 05](./05-networking-lab.md)

---

# Linux Labs

Hands-on sessions for every phase in the Linux notes.

Do them in order. Do not move to the next lab until the checklist at the bottom is fully checked.

---

## The Project Thread

These five labs are not isolated exercises. They are five stages in the life of one project — the webstore — running on a Linux server. Each lab picks up exactly where the previous one left off.

By the time you finish Lab 05 you will have built the webstore's server foundation from scratch: a structured project on disk, permissions locked down, nginx serving the frontend, and the full network stack verified and debugged. That is the state Git picks up from in the next tool.

| Lab | Where the webstore is | What you do |
|---|---|---|
| [Lab 01](./01-boot-basics-files-lab.md) | Blank server | Build the project directory, write config files, set up the file structure that every future lab depends on |
| [Lab 02](./02-filters-sed-awk-lab.md) | Running for a week, logs accumulating | Act as the on-call engineer — find errors in the logs using only the terminal |
| [Lab 03](./03-vim-users-permissions-lab.md) | About to be handed to a second developer | Lock it down — correct users, groups, and permissions so nobody reads what they should not |
| [Lab 04](./04-archive-packages-services-lab.md) | Deploy day | Archive the current state, install nginx, configure it to serve the frontend, make it survive reboots |
| [Lab 05](./05-networking-lab.md) | Something is wrong, users are reporting issues | Debug the network layer from outside in — no monitoring, no dashboard, just the terminal |

---

## Labs

| Lab | Topics | Notes |
|---|---|---|
| [Lab 01](./01-boot-basics-files-lab.md) | Boot + Basics + Files | [01](../01-boot-process/README.md) · [02](../02-basics/README.md) · [03](../03-working-with-files/README.md) |
| [Lab 02](./02-filters-sed-awk-lab.md) | Filters + sed + awk | [04](../04-filter-commands/README.md) · [05](../05-sed-stream-editor/README.md) · [06](../06-awk/README.md) |
| [Lab 03](./03-vim-users-permissions-lab.md) | Vim + Users + Permissions | [07](../07-text-editor/README.md) · [08](../08-user-&-group-management/README.md) · [09](../09-file-ownership-&-permissions/README.md) |
| [Lab 04](./04-archive-packages-services-lab.md) | Archive + Packages + Services | [10](../10-archiving-and-compression/README.md) · [11](../11-package-management/README.md) · [12](../12-service-management/README.md) |
| [Lab 05](./05-networking-lab.md) | Networking | [13](../13-networking/README.md) |

---

## How to Use These Labs

Read the notes for each phase before opening a terminal. Every lab assumes you have read the corresponding notes files first.

Write every command from scratch. Do not copy-paste. Typing forces your brain to process each flag and each decision.

Every lab has a "Break It on Purpose" section. Do not skip it. These are the failure states you will actually hit in production. Seeing the error yourself and fixing it is the point.

Do not move to the next lab until every box in the checklist is checked. If you cannot check a box honestly, go back and do it properly.

---
# TOOL: 02. Git & GitHub – Version Control | FILE: 01-foundations
---

[Home](../README.md) |
[Foundations](../01-foundations/README.md) |
[Stash & Tags](../02-stash-tags/README.md) |
[History & Branching](../03-history-branching/README.md) |
[Contribute](../04-contribute/README.md) |
[Undo & Recovery](../05-undo-recovery/README.md)

# Git Foundations

Before Git, the way people saved progress on a project was to zip the folder. `webstore_final.zip` became `webstore_final_v2.zip` became `webstore_final_REAL_final.zip`. Nobody knew which was current. Nobody knew what changed between them. If something broke, there was no reliable way back.

Git solves this by recording every change as a permanent snapshot with a timestamp, a message, and the identity of who made it. You can jump to any point in that history instantly. You can work on a new feature without touching the working version. You can collaborate with other engineers without overwriting each other's work.

In DevOps, Git is the source of truth. GitHub Actions reads from it to know when to build. Terraform reads from it to know what infrastructure to provision. ArgoCD reads from it to know what to deploy. Everything downstream depends on what is in the repo.

---

## Table of Contents

- [1. How Git Tracks History](#1-how-git-tracks-history)
- [2. Installing and Configuring Git](#2-installing-and-configuring-git)
- [3. Creating a Repository — The Project's Birth](#3-creating-a-repository--the-projects-birth)
- [4. The Three States — Working, Staged, Committed](#4-the-three-states--working-staged-committed)
- [5. Your First Commits — Building the Webstore History](#5-your-first-commits--building-the-webstore-history)
- [6. .gitignore — What Git Should Never See](#6-gitignore--what-git-should-never-see)
- [7. Connecting to GitHub — The Remote](#7-connecting-to-github--the-remote)
- [8. Commit Message Convention](#8-commit-message-convention)
- [9. Quick Reference](#9-quick-reference)

---

## 1. How Git Tracks History

Git stores history as a chain of **commits**. Each commit is a snapshot of your entire project at a point in time — not a diff, not a patch, a complete snapshot. Every commit has:

- A unique **SHA hash** — a 40-character fingerprint like `a3f92c1b...` that identifies it permanently
- A **message** — what changed and why
- The **author** — who made the change and when
- A pointer to its **parent commit** — the previous snapshot

The chain looks like this:

```
A ← B ← C ← D   (main branch)
```

Each letter is a commit. Each one points back to its parent. `D` is the most recent. `A` is the first. Every commit between them is preserved permanently.

**HEAD** is a pointer that tells Git where you currently are — which commit you are looking at right now. When you make a new commit, HEAD moves forward automatically.

---

## 2. Installing and Configuring Git

**Install:**

```bash
# Ubuntu/Debian
sudo apt install git -y

# macOS
brew install git

# Verify
git --version
```

**Configure your identity — required before your first commit:**

```bash
git config --global user.name "Akhil Teja Doosari"
git config --global user.email "doosariakhilteja@gmail.com"
```

Every commit you make carries this identity. On GitHub it links your commits to your account. On a team, it shows your teammates who made each change.

**Set your default editor:**

```bash
git config --global core.editor "vim"
```

**Check all settings:**

```bash
git config --list
```

**Config levels — where settings live:**

| Level | Flag | File | Affects |
|---|---|---|---|
| System | `--system` | `/etc/gitconfig` | Every user on this machine |
| Global | `--global` | `~/.gitconfig` | Your user account |
| Local | `--local` | `.git/config` | This repo only |

Local overrides global overrides system. Use local config when you work with a company email on one project and a personal email on others:

```bash
# Inside the work repo
git config --local user.email "akhil@company.com"
```

---

## 3. Creating a Repository — The Project's Birth

When you run `git init` in a directory, Git creates a hidden `.git/` folder inside it. That folder is the entire repository — every commit, every branch, every tag. The `.git/` folder is what makes a directory a Git repo.

```bash
# Turn the webstore directory into a Git repo
cd ~/webstore
git init
```

```
Initialized empty Git repository in /home/akhil/webstore/.git/
```

```bash
# Confirm .git exists
ls -la
# .git  frontend/  api/  db/  logs/  config/  backup/
```

The webstore project now has version control. Nothing is tracked yet — Git is watching but has not been told what to remember.

---

## 4. The Three States — Working, Staged, Committed

Every file in a Git repository is in one of three states. Understanding this is the mental model that makes every Git command make sense.

```
Working Directory → Staging Area → Repository
      edit             git add        git commit
```

**Working Directory** — where you edit files. Git sees the changes but has not been asked to do anything with them yet. Running `git status` shows what has changed.

**Staging Area** — a holding area where you explicitly choose what goes into the next commit. Think of it as preparing a package before sealing it. You decide exactly what is in this snapshot.

**Repository** — committed history. Permanent. Immutable. Every commit here is preserved indefinitely.

**Why the staging area exists:**
You edited five files but only three are ready to commit. The staging area lets you commit those three as one logical change while leaving the other two in progress. Without it, every `git commit` would include everything you touched.

```bash
# See where everything stands
git status

# Stage a specific file
git add config/webstore.conf

# Stage everything
git add .

# Unstage a file you added by mistake
git restore --staged config/webstore.conf

# See what is staged vs what is not
git diff --staged   # shows staged changes
git diff            # shows unstaged changes
```

---

## 5. Your First Commits — Building the Webstore History

This is the moment the webstore project becomes trackable. Every future deploy, every incident, every feature will be traceable back to this history.

**The first commit:**

```bash
cd ~/webstore

# Check what Git sees
git status

# Stage everything — the whole initial project
git add .

# Confirm what is staged
git status
# Changes to be committed:
#   new file: frontend/index.html
#   new file: api/server.js
#   new file: config/webstore.conf
#   ...

# Create the first commit
git commit -m "feat: initialize webstore project structure

- add frontend, api, db, logs, config, backup directories
- add webstore.conf with db and api connection settings
- add placeholder files for each service layer"
```

**View the commit:**

```bash
git log --oneline
# a3f92c1 feat: initialize webstore project structure
```

**Build more history — each commit tells the story of what the webstore became:**

```bash
# Second commit — first real config
echo "nginx_worker_processes=4" >> config/webstore.conf
git add config/webstore.conf
git commit -m "config: add nginx worker process setting"

# Third commit — add the first log entry
echo "2025-04-05 09:00 server started" >> logs/access.log
git add logs/access.log
git commit -m "logs: add initial server startup entry"

# View the growing history
git log --oneline
# c8d21fa logs: add initial server startup entry
# b71e3a2 config: add nginx worker process setting
# a3f92c1 feat: initialize webstore project structure
```

Each commit is a chapter. The message explains what changed. The hash identifies it permanently. Anyone who clones this repo can read this history and understand how the project evolved.

---

## 6. .gitignore — What Git Should Never See

`.gitignore` tells Git which files to completely ignore — never track, never show in `git status`, never accidentally commit. This is one of the most important files in any repo.

**What belongs in `.gitignore`:**

```
# Environment files — database passwords, API keys, secrets
.env
.env.local
.env.production

# Build output — generated, not source
dist/
build/
*.tar
*.gz

# Dependencies — installed, not committed
node_modules/

# OS noise
.DS_Store
Thumbs.db

# Logs — runtime data, not source
*.log

# Terraform — contains sensitive infrastructure state
*.tfstate
*.tfstate.backup
.terraform/

# IDE files
.vscode/
.idea/
```

**Create it at the root of the repo:**

```bash
vim ~/webstore/.gitignore
# add the entries above
git add .gitignore
git commit -m "chore: add .gitignore"
```

**The most important rule:** create `.gitignore` before your first `git add .`. If you accidentally commit a secret, it is in the history permanently — even if you delete the file later. The history is immutable.

**If you accidentally tracked a file that should be ignored:**

```bash
# Remove from tracking without deleting from disk
git rm --cached .env
echo ".env" >> .gitignore
git commit -m "fix: remove .env from tracking, add to gitignore"
```

**Check why a file is being ignored:**

```bash
git check-ignore -v .env
# .gitignore:1:.env  .env
```

---

## 7. Connecting to GitHub — The Remote

A remote is a Git repository hosted somewhere else — GitHub in this case. When you push, Git sends your commits to the remote. When you pull, Git fetches commits from the remote into your local repo.

**Create the repo on GitHub first** (github.com → New repository → webstore), then connect it:

```bash
# Add the remote — named "origin" by convention
git remote add origin https://github.com/AkhilTejaDoosari/webstore.git

# Verify the connection
git remote -v
# origin  https://github.com/AkhilTejaDoosari/webstore.git (fetch)
# origin  https://github.com/AkhilTejaDoosari/webstore.git (push)

# Push the local history to GitHub for the first time
git push -u origin main
```

The `-u` flag sets origin/main as the default upstream — after this, `git push` and `git pull` with no arguments work from the right place.

**The daily workflow after the first push:**

```bash
# Edit files
git status               # see what changed
git add .                # stage changes
git commit -m "message"  # commit
git push                 # push to GitHub
```

---

## 8. Commit Message Convention

Every commit you make is a permanent record. Write messages that a teammate — or you in six months — can read and immediately understand what changed and why.

**The format:**

```
type: short description (under 72 characters)

Optional longer explanation if needed.
```

**Common types:**

| Type | When to use |
|---|---|
| `feat` | A new feature or capability |
| `fix` | A bug fix |
| `config` | Configuration changes |
| `docs` | Documentation only |
| `chore` | Maintenance — dependencies, gitignore, tooling |
| `refactor` | Code restructure with no behavior change |
| `test` | Adding or fixing tests |

**Good vs bad examples:**

```
# Bad — tells you nothing
git commit -m "update"
git commit -m "fix stuff"
git commit -m "wip"

# Good — tells you what and why
git commit -m "feat: add product listing endpoint to webstore-api"
git commit -m "fix: correct db_port in webstore.conf — was 27017, should be 5432"
git commit -m "config: add nginx worker process setting for production load"
```

**The webstore history should read like documentation.** Anyone cloning the repo for the first time should be able to run `git log --oneline` and understand how the project evolved without opening a single file.

---

## 9. Quick Reference

| Command | What it does |
|---|---|
| `git init` | Initialize a repo in the current directory |
| `git config --global user.name "Name"` | Set global identity |
| `git status` | Show working directory and staging area state |
| `git add <file>` | Stage a specific file |
| `git add .` | Stage all changes |
| `git restore --staged <file>` | Unstage a file |
| `git commit -m "message"` | Commit staged changes |
| `git log --oneline` | View compact commit history |
| `git diff` | Show unstaged changes |
| `git diff --staged` | Show staged changes |
| `git rm --cached <file>` | Remove from tracking without deleting |
| `git remote add origin <url>` | Connect to a GitHub remote |
| `git push -u origin main` | Push and set upstream (first push) |
| `git push` | Push commits to remote |
| `git pull` | Fetch and merge remote changes |
| `git check-ignore -v <file>` | Show which gitignore rule matched |

---

→ Ready to practice? [Go to Lab 01](../git-labs/01-foundations-lab.md)

---
# TOOL: 02. Git & GitHub – Version Control | FILE: 02-stash-tags
---

[Home](../README.md) |
[Foundations](../01-foundations/README.md) |
[Stash & Tags](../02-stash-tags/README.md) |
[History & Branching](../03-history-branching/README.md) |
[Contribute](../04-contribute/README.md) |
[Undo & Recovery](../05-undo-recovery/README.md)

# Git Stash & Tags

Two tools for two different situations. Stash is for when you are in the middle of something and need to stop without committing half-finished work. Tags are for when you finish something and want to mark that moment permanently — a release, a milestone, a version that CI/CD can reference.

---

## Table of Contents

- [1. Git Stash — Pausing Without Committing](#1-git-stash--pausing-without-committing)
- [2. Git Tags — Marking the Webstore's First Release](#2-git-tags--marking-the-webstores-first-release)
- [3. Quick Reference](#3-quick-reference)

---

## 1. Git Stash — Pausing Without Committing

You are halfway through updating `webstore.conf` to point at a new database host. Your changes are not ready to commit. Then an urgent message arrives — a bug in production, needs a fix right now. You need a clean working directory to switch branches and investigate.

This is what stash is for. It saves your in-progress changes to a temporary shelf, gives you back a clean state, and lets you restore everything exactly where you left it when you are done.

**The basic stash workflow:**

```bash
# You are mid-work on webstore.conf
cat ~/webstore/config/webstore.conf
# db_host=webstore-db-new   ← work in progress, not ready to commit

# Save it to the stash — your working directory becomes clean
git stash push -m "WIP: updating db_host to new database server"

# Check status — clean
git status
# nothing to commit, working tree clean

# Switch to fix the urgent bug
git switch main
# fix the bug, commit it, push it

# Come back and restore your work
git stash pop
cat ~/webstore/config/webstore.conf
# db_host=webstore-db-new   ← your changes are back exactly as you left them
```

**The stash is a stack.** Each stash is pushed on top. The most recent is `stash@{0}`.

```
stash@{0}  ← most recent — "WIP: updating db_host"
stash@{1}  ← older
stash@{2}  ← oldest
```

**All stash commands:**

| Command | What it does | When you reach for it |
|---|---|---|
| `git stash` | Save tracked changes to the stash | Quick save before switching context |
| `git stash push -m "message"` | Save with a descriptive label | Always — anonymous stashes are hard to identify later |
| `git stash -u` | Include untracked (new) files | When you have new files not yet staged |
| `git stash list` | Show all saved stashes | Checking what is on the stack |
| `git stash show` | Summary of the most recent stash | Quick reminder of what you stashed |
| `git stash show -p` | Full diff of the most recent stash | Reading exactly what changed |
| `git stash pop` | Apply most recent stash and remove it from the stack | Normal restore — most common |
| `git stash apply stash@{1}` | Apply a specific stash but keep it on the stack | When you want to apply without removing |
| `git stash drop stash@{1}` | Delete a specific stash | Cleaning up old stashes you no longer need |
| `git stash clear` | Delete all stashes | Nuclear option — permanent, no recovery |

**Stash only saves tracked files by default.** If you created a new file and have not run `git add` on it yet, `git stash` leaves it behind. Use `git stash -u` to include untracked files:

```bash
touch ~/webstore/api/new-endpoint.js   # new file, not tracked yet
git stash -u                           # includes it
```

**Create a branch from a stash** — when you realize mid-work that what you are building should be its own feature branch:

```bash
git stash branch feature/new-db-config stash@{0}
# Creates the branch, checks it out, applies the stash, removes it
```

**What stash is not:** stash is local only — it does not push to GitHub. It expires after 90 days. It is a temporary shelf, not long-term storage. If you are working on something for more than a day, commit it to a branch instead.

---

## 2. Git Tags — Marking the Webstore's First Release

The webstore has been running, commits have been made, nginx is serving the frontend. At some point the project reaches a stable state — everything works, the foundation is solid, this is a version worth marking.

That mark is a tag. Tags are permanent pointers to specific commits. Unlike branch names which move forward as you commit, a tag never moves. `v1.0` will always point to exactly the commit you tagged.

**Why tags matter in DevOps:**
CI/CD pipelines are often configured to trigger on tags. When you push `v1.0` to GitHub, GitHub Actions can detect it, build a Docker image, tag the image as `webstore-api:1.0`, and push it to the registry. The tag in Git becomes the version in Docker becomes the version in Kubernetes. It is the chain that connects your code to your deployment.

**Two types of tags:**

| Type | What it contains | When to use |
|---|---|---|
| Lightweight | Just a pointer to a commit | Local bookmarks, private notes |
| Annotated | Pointer + author + date + message | Releases — always use this for anything shared |

Always use annotated tags for releases. They carry a message and your identity, they show up properly in GitHub's releases page, and they are what CI/CD pipelines expect.

**Tagging the webstore v1.0:**

```bash
# First confirm where you are
git log --oneline
# c8d21fa logs: add initial server startup entry
# b71e3a2 config: add nginx worker process setting
# a3f92c1 feat: initialize webstore project structure

# Tag the current commit — the stable foundation
git tag -a v1.0 -m "webstore v1.0 — Linux foundation complete

- directory structure established
- nginx configured and serving frontend
- permissions locked down
- ready for containerization"

# View the tag and its details
git show v1.0
```

**Tags are not pushed automatically** — you have to push them explicitly:

```bash
# Push a single tag
git push origin v1.0

# Push all local tags at once
git push --tags
```

**Other tag operations:**

```bash
# List all tags
git tag

# Tag an older specific commit — when you forgot to tag at the right time
git tag -a v0.9 a3f92c1 -m "initial structure — pre-nginx"

# Delete a local tag — if you tagged the wrong commit
git tag -d v1.0

# Delete a remote tag — only after deleting locally
git push origin --delete tag v1.0
```

**Semantic versioning — the standard format:**

```
v1.0.0   ← major.minor.patch
v1.1.0   ← new feature, backward compatible
v1.1.1   ← bug fix
v2.0.0   ← breaking change
```

For the webstore journey:
- `v1.0` — Linux foundation complete
- `v1.1` — first Docker commit
- `v2.0` — running on Kubernetes

---

## 3. Quick Reference

**Stash:**

| Command | What it does |
|---|---|
| `git stash push -m "message"` | Save changes with a label |
| `git stash -u` | Include untracked files |
| `git stash list` | Show all stashes |
| `git stash show -p` | Full diff of most recent stash |
| `git stash pop` | Restore and remove most recent stash |
| `git stash apply stash@{n}` | Restore specific stash, keep it on stack |
| `git stash drop stash@{n}` | Delete a specific stash |
| `git stash clear` | Delete all stashes permanently |
| `git stash branch <name>` | Create branch from most recent stash |

**Tags:**

| Command | What it does |
|---|---|
| `git tag -a v1.0 -m "message"` | Create annotated tag at current commit |
| `git tag -a v1.0 <hash> -m "message"` | Tag a specific past commit |
| `git tag` | List all tags |
| `git show v1.0` | Show tag details and the commit it points to |
| `git push origin v1.0` | Push a single tag to remote |
| `git push --tags` | Push all local tags to remote |
| `git tag -d v1.0` | Delete a local tag |
| `git push origin --delete tag v1.0` | Delete a remote tag |

---

→ Ready to practice? [Go to Lab 02](../git-labs/02-stash-tags-lab.md)

---
# TOOL: 02. Git & GitHub – Version Control | FILE: 03-history-branching
---

[Home](../README.md) |
[Foundations](../01-foundations/README.md) |
[Stash & Tags](../02-stash-tags/README.md) |
[History & Branching](../03-history-branching/README.md) |
[Contribute](../04-contribute/README.md) |
[Undo & Recovery](../05-undo-recovery/README.md)

# Git History & Branching

The webstore has a commit history now. Someone wants to add a product pagination feature to the API. You cannot build it directly on `main` — that is the stable, deployed version. If the feature breaks halfway through, the whole project is broken.

Branches solve this. A branch is a separate line of development — a parallel timeline where you can build, experiment, and break things without touching what is working. When the feature is done and tested, you merge it back.

---

## Table of Contents

- [1. Reading Project History](#1-reading-project-history)
- [2. Branching — What It Is and Why It Exists](#2-branching--what-it-is-and-why-it-exists)
- [3. Creating, Switching, and Merging Branches](#3-creating-switching-and-merging-branches)
- [4. Merge Types — Fast-Forward and 3-Way](#4-merge-types--fast-forward-and-3-way)
- [5. Conflict Resolution](#5-conflict-resolution)
- [6. Rebase — Keeping History Linear](#6-rebase--keeping-history-linear)
- [7. Branching Strategies](#7-branching-strategies)
- [8. Quick Reference](#8-quick-reference)

---

## 1. Reading Project History

Every commit in Git is a permanent record. Reading history is how you understand what happened — who changed what, when, and why.

```bash
# Compact one-line view — most useful for daily navigation
git log --oneline
# c8d21fa logs: add initial server startup entry
# b71e3a2 config: add nginx worker process setting
# a3f92c1 feat: initialize webstore project structure

# Full detail — author, date, message, hash
git log

# Visual branch and merge history
git log --graph --oneline
# * c8d21fa (HEAD -> main) logs: add initial server startup entry
# * b71e3a2 config: add nginx worker process setting
# * a3f92c1 feat: initialize webstore project structure

# Show exactly what changed in a specific commit
git show c8d21fa

# Compare two commits — what changed between them
git diff a3f92c1 c8d21fa

# Show unstaged changes in working directory
git diff

# Show staged changes waiting to be committed
git diff --staged
```

**When you reach for `git log`:**
A deployment broke something. You need to know what changed between yesterday's working version and today's broken one. `git log --oneline` shows you the commits in between. `git show <hash>` shows you exactly what each one changed.

| Command | What it shows |
|---|---|
| `git log --oneline` | Compact history — commit hash and message |
| `git log --graph --oneline` | Visual branch and merge diagram |
| `git show <hash>` | Full detail and file diff for one commit |
| `git diff` | Unstaged changes in working directory |
| `git diff --staged` | Staged changes waiting to commit |
| `git diff <hash1> <hash2>` | Changes between any two commits |

---

## 2. Branching — What It Is and Why It Exists

A **branch** is a lightweight pointer to a commit — a named position in the commit chain. When you create a branch, Git creates a new pointer at your current commit. When you make commits on that branch, only that pointer moves forward. `main` stays exactly where it was.

```
Before branching:
main → A → B → C   (HEAD is here)

After creating feature/products-api:
main → A → B → C
feature/products-api → C   (same starting point)

After two commits on the feature branch:
main → A → B → C
feature/products-api → C → D → E   (main untouched)
```

**HEAD** is the pointer that tells Git which branch — and therefore which commit — you are currently on. When you switch branches, HEAD moves.

---

## 3. Creating, Switching, and Merging Branches

**The feature branch workflow — what you do for every new piece of work:**

```bash
# Start from main — always branch from a known good state
git switch main
git pull   # make sure you have the latest

# Create and switch to the feature branch in one step
git switch -c feature/webstore-api-pagination

# Make changes and commit them on the feature branch
vim ~/webstore/api/server.js
git add api/server.js
git commit -m "feat: add product pagination to webstore API"

vim ~/webstore/api/server.js
git add api/server.js
git commit -m "feat: add pagination query param validation"

# Check where you are and what the history looks like
git log --graph --oneline

# Return to main
git switch main

# Merge the feature branch back
git merge feature/webstore-api-pagination

# Delete the branch — it has been merged, no longer needed
git branch -d feature/webstore-api-pagination
```

**Branch management commands:**

| Command | What it does |
|---|---|
| `git branch` | List all local branches |
| `git branch -a` | List local and remote branches |
| `git branch <name>` | Create a branch (without switching) |
| `git switch <name>` | Switch to an existing branch |
| `git switch -c <name>` | Create and switch in one step |
| `git branch -m old new` | Rename a branch |
| `git branch -d <name>` | Delete a merged branch |
| `git branch -D <name>` | Force delete — even if unmerged |

---

## 4. Merge Types — Fast-Forward and 3-Way

When you merge, Git decides how to combine the histories. The result depends on what happened to both branches since they diverged.

**Fast-Forward Merge — main has not moved:**

If no new commits were added to `main` while you worked on the feature branch, Git simply moves the `main` pointer forward to match the feature branch tip. No merge commit is created. The history stays linear.

```
Before:
main → A → B → C
feature → C → D → E

After fast-forward merge:
main → A → B → C → D → E
(feature pointer deleted)
```

```bash
git switch main
git merge feature/webstore-api-pagination
# Fast-forward — history is linear, no merge commit
```

**3-Way Merge — main has also moved:**

If new commits were added to `main` while you worked on the feature branch, Git cannot just move the pointer. It has to create a **merge commit** that combines both lines of history.

```
Before:
main → A → B → C → F → G
feature → C → D → E

After 3-way merge:
main → A → B → C → F → G → M   (M is the merge commit)
                   ↗
              D → E
```

```bash
git switch main
git merge feature/webstore-api-pagination
# Merge commit created — Git opens your editor for the merge commit message
```

**When each happens:**
Fast-forward happens when you branch, work, and merge without anyone else committing to main in between. 3-way happens when the team is active and main moved while you were working.

---

## 5. Conflict Resolution

Conflicts happen when two branches modify the same lines in the same file. Git cannot decide automatically which version to keep — it marks the conflict and asks you to resolve it.

**What a conflict looks like:**

```
<<<<<<< HEAD
db_host=webstore-db-primary
=======
db_host=webstore-db-replica
>>>>>>> feature/db-failover
```

- Everything above `=======` is from the branch you are merging into (HEAD)
- Everything below is from the incoming branch
- The `<<<<<<<` and `>>>>>>>` markers are not valid content — they must be removed

**The resolution process:**

```bash
# Git tells you there is a conflict
git merge feature/db-failover
# CONFLICT (content): Merge conflict in config/webstore.conf

# Open the file and find the conflict markers
vim config/webstore.conf

# Edit it to keep what is correct — remove all markers
# Result: db_host=webstore-db-primary

# Mark it resolved
git add config/webstore.conf

# Complete the merge
git commit
# Git opens the editor with a default merge commit message — save and close
```

**The conflict resolution mindset:** a conflict is not an error. It is Git saying "two people changed the same thing — which version should survive?" You make the decision, stage the result, and commit.

---

## 6. Rebase — Keeping History Linear

Rebase rewrites your branch's commits so they appear to start from the current tip of another branch. The result is a clean, linear history with no merge commits.

**Merge result — history shows the branching:**

```
main → A → B → C → F → G → M (merge commit)
                   ↗
              D → E
```

**Rebase result — history looks like it was always linear:**

```
main → A → B → C → F → G → D' → E'
```

Your commits (`D`, `E`) are rewritten as new commits (`D'`, `E'`) on top of the latest `main`. Same changes, different parent.

**The rebase workflow:**

```bash
# On the feature branch — update it to start from latest main
git switch feature/webstore-api-pagination
git rebase main

# If conflicts arise during rebase:
# fix the conflict
git add <file>
git rebase --continue

# If something goes badly wrong — abort and return to before
git rebase --abort

# After a successful rebase — fast-forward merge on main
git switch main
git merge feature/webstore-api-pagination
# Fast-forward — clean linear history
```

**Merge vs Rebase — the decision:**

| | Merge | Rebase |
|---|---|---|
| History | Preserves the branch structure | Creates a linear timeline |
| Use for | Merging completed features to main | Updating a feature branch with latest main |
| Safe on shared branches | Yes | No — never rebase commits that have been pushed |
| Creates merge commit | Yes | No |

**The golden rule of rebase:** never rebase commits that have already been pushed to a shared remote branch. Rebase rewrites history — if someone else pulled those commits before you rebased, their local history now diverges from yours and they will have problems.

Rebase is safe on a **local feature branch you have not pushed yet**, or on a **personal branch that nobody else has pulled**.

---

## 7. Branching Strategies

A branching strategy is a team agreement on how branches are named, when they are created, and how they flow into production. These come up in interviews.

**Git Flow — the classic approach:**

```
main        — production-ready code only, every commit is deployable
develop     — integration branch, features merge here before going to main
feature/*   — individual features, branch off develop
release/*   — stabilization before merging to main
hotfix/*    — emergency fixes directly off main
```

```
feature/x → develop → release/1.0 → main  ← tag v1.0
                                        ↘ hotfix/y → main → develop
```

Good for: versioned software with scheduled release cycles.
Bad for: fast-moving teams — too much branch overhead.

**Trunk-Based Development — the DevOps standard:**

Everyone commits to `main` directly, or via very short-lived feature branches (1–2 days maximum). No long-running branches.

```
main  ← everyone integrates here, frequently
  ↑
small feature branches, merged within 1-2 days
```

Good for: CI/CD pipelines, fast-moving teams, SaaS products.
Why DevOps teams prefer it: GitHub Actions and ArgoCD trigger on commits to main. Long-lived branches delay integration and create merge hell. Feature flags replace the need for long feature branches.

**Branch naming conventions:**

```
feature/webstore-api-pagination
fix/webstore-login-timeout
chore/update-dependencies
docs/add-api-readme
release/v1.2.0
hotfix/fix-payment-crash
```

---

## 8. Quick Reference

| Command | What it does |
|---|---|
| `git log --oneline` | Compact commit history |
| `git log --graph --oneline` | Visual branch diagram |
| `git show <hash>` | Full detail for one commit |
| `git diff` | Unstaged changes |
| `git diff --staged` | Staged changes |
| `git branch` | List branches |
| `git switch -c <name>` | Create and switch to new branch |
| `git switch <name>` | Switch to existing branch |
| `git merge <branch>` | Merge branch into current |
| `git branch -d <name>` | Delete merged branch |
| `git rebase main` | Rebase current branch onto main |
| `git rebase --continue` | Continue after resolving rebase conflict |
| `git rebase --abort` | Cancel rebase entirely |

---

→ Ready to practice? [Go to Lab 03](../git-labs/03-history-branching-lab.md)

---
# TOOL: 02. Git & GitHub – Version Control | FILE: 04-contribute
---

[Home](../README.md) |
[Foundations](../01-foundations/README.md) |
[Stash & Tags](../02-stash-tags/README.md) |
[History & Branching](../03-history-branching/README.md) |
[Contribute](../04-contribute/README.md) |
[Undo & Recovery](../05-undo-recovery/README.md)

# Git Contribute

The webstore is on GitHub. A second developer joins the team and needs to work on the products API. They cannot push directly to main — that is the production branch. They need their own copy to work from, a way to propose their changes for review, and a way to stay in sync when main moves forward while they are working.

This is the collaboration model. Understanding it is what separates someone who uses Git alone from someone who uses Git on a team.

---

## Table of Contents

- [1. Two Collaboration Contexts](#1-two-collaboration-contexts)
- [2. Cloning — Getting the Repo Locally](#2-cloning--getting-the-repo-locally)
- [3. Remotes — origin and upstream](#3-remotes--origin-and-upstream)
- [4. The Feature Branch PR Workflow](#4-the-feature-branch-pr-workflow)
- [5. Forking — Contributing to a Repo You Do Not Own](#5-forking--contributing-to-a-repo-you-do-not-own)
- [6. Keeping Your Fork in Sync](#6-keeping-your-fork-in-sync)
- [7. What Makes a Good Pull Request](#7-what-makes-a-good-pull-request)
- [8. Quick Reference](#8-quick-reference)

---

## 1. Two Collaboration Contexts

You will work in two different contexts depending on whether you own the repo.

| Context | When | What you do |
|---|---|---|
| **Company repo** | You are on the team, have access | Clone directly, work in feature branches, open PRs to main |
| **Open-source repo** | You do not have write access | Fork the repo first, clone your fork, open PR to the original |

In DevOps day-to-day work — your team's infrastructure repo, the webstore deployment manifests, Terraform configs — you use the company repo pattern. Fork is for contributing to projects you do not own.

---

## 2. Cloning — Getting the Repo Locally

Clone downloads the full repository to your machine — all commits, all branches, all history.

```bash
# Clone the webstore repo
git clone https://github.com/AkhilTejaDoosari/webstore.git

# Clone into a specific folder name
git clone https://github.com/AkhilTejaDoosari/webstore.git my-webstore

# After cloning
cd webstore
git log --oneline   # full history is here
git branch -a       # all branches, local and remote
```

After cloning, you have:
- A full local copy of the repository
- One remote called `origin` pointing back to GitHub
- A local `main` branch tracking `origin/main`

---

## 3. Remotes — origin and upstream

A remote is a named reference to a repository hosted somewhere else. Every connection to GitHub is a remote.

```bash
# Check what remotes you have
git remote -v
# origin  https://github.com/AkhilTejaDoosari/webstore.git (fetch)
# origin  https://github.com/AkhilTejaDoosari/webstore.git (push)
```

**`origin`** is the repo you cloned from — your team's repo or your fork. You push to origin and pull from origin.

**`upstream`** is the original repo when you have forked. You pull from upstream to stay in sync but never push to it directly.

```bash
# Add upstream (open-source workflow — after forking)
git remote add upstream https://github.com/original-owner/webstore.git

git remote -v
# origin    https://github.com/your-username/webstore.git (fetch)
# origin    https://github.com/your-username/webstore.git (push)
# upstream  https://github.com/original-owner/webstore.git (fetch)
# upstream  https://github.com/original-owner/webstore.git (push)
```

| Remote | Purpose | You push to it? |
|---|---|---|
| `origin` | Your fork or your team's repo | Yes |
| `upstream` | Original repo you forked from | No — read only |

---

## 4. The Feature Branch PR Workflow

This is what you do every day on a team. Every new piece of work — feature, fix, config change — gets its own branch. When done, you open a pull request on GitHub for review before it merges to main.

```bash
# Step 1 — start from latest main
git switch main
git pull

# Step 2 — create your feature branch
git switch -c feature/webstore-product-pagination

# Step 3 — do the work, make commits
vim api/server.js
git add api/server.js
git commit -m "feat: add pagination to products endpoint"

vim api/server.js
git add api/server.js
git commit -m "feat: add page size validation"

# Step 4 — push the branch to GitHub
git push origin feature/webstore-product-pagination

# Step 5 — open a pull request on GitHub
# github.com → your repo → "Compare & pull request"
# Base: main  ←  Compare: feature/webstore-product-pagination
# Write a clear title and description
# Submit for review

# Step 6 — after review and approval, merge on GitHub
# (or merge locally if you have permission)

# Step 7 — clean up locally after merge
git switch main
git pull                                           # get the merged commit
git branch -d feature/webstore-product-pagination  # delete the branch
```

**Why the PR exists:**
A pull request is a checkpoint. Before code merges to main — the production branch — a teammate reads it, asks questions, catches bugs, and approves. This is how teams catch mistakes before they reach production. Even on a solo project, opening a PR forces you to read your own diff one more time before merging.

---

## 5. Forking — Contributing to a Repo You Do Not Own

A fork is a complete copy of someone else's repository under your GitHub account. You have full write access to your fork. The original repo is unaffected by anything you do.

Forking is a GitHub feature, not a Git command. You fork on the GitHub website, then clone your fork to work locally.

**The open-source contribution workflow:**

```bash
# Step 1 — fork on GitHub
# github.com → original repo → Fork button (top right)
# GitHub creates a copy at: github.com/your-username/webstore

# Step 2 — clone your fork
git clone https://github.com/your-username/webstore.git
cd webstore

# Step 3 — add the original repo as upstream
git remote add upstream https://github.com/original-owner/webstore.git

# Step 4 — create a feature branch
git switch -c fix/webstore-api-timeout

# Step 5 — make changes and commit
git commit -m "fix: increase api timeout from 5s to 30s"

# Step 6 — push to your fork
git push origin fix/webstore-api-timeout

# Step 7 — open a PR from your fork to the original repo
# github.com → your fork → Compare & pull request
# Base repository: original-owner/webstore  base: main
# Head repository: your-username/webstore  compare: fix/webstore-api-timeout
```

---

## 6. Keeping Your Fork in Sync

While you work on your fork, the original repo keeps moving forward. Before you submit a PR — and regularly while working — you need to pull in those changes so your fork does not fall behind.

```bash
# Fetch all new commits from the original repo
git fetch upstream

# See what is new
git log --oneline main..upstream/main

# Merge upstream changes into your local main
git switch main
git merge upstream/main

# Push the updated main to your fork on GitHub
git push origin main

# Rebase your feature branch on top of the updated main
git switch fix/webstore-api-timeout
git rebase main
```

If you do not stay in sync, your PR will have merge conflicts and may be rejected until you resolve them.

---

## 7. What Makes a Good Pull Request

The PR is what your teammates read when reviewing your work. A good PR makes review fast and approval easy. A poor PR makes review painful and delays the merge.

**A good PR:**
- Has a clear title that matches the commit convention: `feat: add pagination to products endpoint`
- Explains what changed and why — not just "updated server.js"
- Is focused on one logical change — one feature, one fix, not five things at once
- Links to the related issue if one exists
- Is small enough to review in one sitting — the bigger the PR, the less thorough the review

**A poor PR:**
- Title: "changes" or "WIP" or "stuff"
- Touches ten different files with no common theme
- Has no description
- Is so large that reviewers skim it

The single biggest lever for getting PRs approved quickly: keep them small. One logical change per PR. If a feature is large, break it into multiple PRs that each stand on their own.

---

## 8. Quick Reference

| Command | What it does |
|---|---|
| `git clone <url>` | Download full repository to local machine |
| `git remote -v` | List all remotes |
| `git remote add upstream <url>` | Add the original repo as upstream |
| `git fetch upstream` | Fetch new commits from upstream without merging |
| `git merge upstream/main` | Merge upstream changes into current branch |
| `git push origin <branch>` | Push a branch to your remote |
| `git switch -c feature/<n>` | Create and switch to feature branch |
| `git pull` | Fetch and merge from current tracking remote |

---

→ Ready to practice? [Go to Lab 04](../git-labs/04-contribute-lab.md)

---
# TOOL: 02. Git & GitHub – Version Control | FILE: 05-undo-recovery
---

[Home](../README.md) |
[Foundations](../01-foundations/README.md) |
[Stash & Tags](../02-stash-tags/README.md) |
[History & Branching](../03-history-branching/README.md) |
[Contribute](../04-contribute/README.md) |
[Undo & Recovery](../05-undo-recovery/README.md)

# Git Undo & Recovery

Mistakes happen. You commit the wrong file. You write a bad commit message. You reset too far and lose commits. You delete a branch before merging it.

Git has tools for all of these situations — but the right tool depends on *what state you are in* and *whether the commit has been pushed*. Using the wrong tool creates more problems than it solves. This file explains what state each mistake puts you in and which command gets you back.

---

## Table of Contents

- [1. The Mental Model — What Can Go Wrong and Where](#1-the-mental-model--what-can-go-wrong-and-where)
- [2. amend — Fix the Last Commit Before It Leaves](#2-amend--fix-the-last-commit-before-it-leaves)
- [3. revert — Undo a Pushed Commit Safely](#3-revert--undo-a-pushed-commit-safely)
- [4. reset — Move the Pointer Back](#4-reset--move-the-pointer-back)
- [5. reflog — Recover Anything](#5-reflog--recover-anything)
- [6. The Decision Table](#6-the-decision-table)
- [7. Quick Reference](#7-quick-reference)

---

## 1. The Mental Model — What Can Go Wrong and Where

Before reaching for a recovery command, identify where in the workflow the mistake happened:

```
Working Directory → Staging Area → Local Commit → Pushed to Remote
      edit             git add        git commit      git push
```

| Where the mistake is | What happened | Tool to use |
|---|---|---|
| Working directory | Edited a file and want to discard changes | `git restore <file>` |
| Staging area | Staged a file you did not mean to | `git restore --staged <file>` |
| Last local commit — not pushed | Wrong message, wrong files, forgot a file | `git commit --amend` |
| Older local commit — not pushed | Made several bad commits | `git reset` |
| Pushed commit | Bad commit others may have pulled | `git revert` |
| Lost commit after reset | Thought it was gone | `git reflog` |
| Deleted branch | Deleted before merging | `git reflog` + `git branch` |

The critical question before every recovery: **has this commit been pushed?**
If yes — you cannot rewrite history. Use `revert`.
If no — you can rewrite history. Use `amend` or `reset`.

---

## 2. amend — Fix the Last Commit Before It Leaves

`amend` rewrites the most recent commit. It changes the commit hash — Git treats the amended commit as an entirely new commit. This is why you must only amend commits that have not been pushed.

**Fix a typo in the commit message:**

```bash
git commit -m "feat: add paginaton to products endpoint"  # typo

git commit --amend -m "feat: add pagination to products endpoint"
# The old commit is replaced — the typo never existed
```

**Add a file you forgot to include:**

```bash
git commit -m "feat: add pagination to products endpoint"
# Realize you forgot to stage tests/pagination.test.js

git add tests/pagination.test.js
git commit --amend --no-edit
# The file is added to the existing commit — no new commit created
```

**Remove a file you accidentally included:**

```bash
# You committed webstore.conf but it should not be in this commit
git reset HEAD^ -- webstore.conf    # unstage it from the commit
git commit --amend --no-edit        # recommit without it
```

**The rule:** only amend before pushing. If you amend a pushed commit and force push, you rewrite shared history and cause problems for anyone who already pulled.

---

## 3. revert — Undo a Pushed Commit Safely

`revert` creates a new commit that exactly reverses the changes of a specific earlier commit. The original bad commit stays in history — nothing is erased. A new commit records the reversal.

This is the safe undo for commits that have already been pushed. It does not rewrite history — it adds to it.

**The scenario:**
You pushed a commit that broke the webstore API. Other engineers on the team may have already pulled it. You cannot rewrite history. You revert.

```bash
# Find the bad commit hash
git log --oneline
# d4e8f21 feat: add pagination   ← broke the API
# c8d21fa config: update nginx
# b71e3a2 feat: initialize project

# Revert it — creates a new commit that undoes d4e8f21
git revert d4e8f21 --no-edit

# New history:
# a91b23c Revert "feat: add pagination"   ← new commit, undoes the bad one
# d4e8f21 feat: add pagination            ← still in history
# c8d21fa config: update nginx

# Push the revert
git push
```

**What `--no-edit` does:** skips opening the editor for the revert commit message, uses the auto-generated "Revert '<original message>'" message. Leave it out if you want to write a custom message.

**If the revert has conflicts:**

```bash
git revert d4e8f21
# CONFLICT — fix the conflict manually
git add <file>
git revert --continue
```

---

## 4. reset — Move the Pointer Back

`reset` moves HEAD and the current branch pointer to a different commit. Unlike `revert`, it does not create a new commit — it rewrites history. This is why it is only safe on commits that have not been pushed.

**Three modes — the key differences:**

```
--soft  → HEAD moves back. Changes from undone commits stay staged.
--mixed → HEAD moves back. Changes from undone commits are unstaged (in working dir). DEFAULT.
--hard  → HEAD moves back. Changes from undone commits are permanently erased.
```

```bash
git log --oneline
# d4e8f21 bad commit 2   ← HEAD is here
# c8d21fa bad commit 1
# b71e3a2 good state     ← want to go back to here

# --soft: undo 2 commits, keep all changes staged and ready to recommit
git reset --soft b71e3a2

# --mixed: undo 2 commits, keep changes in working directory but unstaged
git reset --mixed b71e3a2

# --hard: undo 2 commits and erase all changes — permanent
git reset --hard b71e3a2
```

**The relative notation — without needing a hash:**

```bash
git reset --soft HEAD~1    # undo 1 commit
git reset --soft HEAD~3    # undo 3 commits
```

**When you reach for each mode:**

`--soft` — you want to undo commits but keep the work. You are going to recommit it differently, or split it into separate commits.

`--mixed` — you want to undo commits and the staging state. Changes are in your working directory, you can review and re-stage selectively.

`--hard` — you want to completely discard the commits and everything in them. Use with care — `--hard` is the one that loses work.

**Never reset commits that have been pushed to a shared branch.** If you reset and force push, everyone else who pulled those commits will have a diverged history.

---

## 5. reflog — Recover Anything

`reflog` is Git's flight recorder. It records every time HEAD moved — every commit, every checkout, every reset, every merge. Even after a `--hard` reset, even after deleting a branch, the commits still exist in Git's object store for 90 days. `reflog` is how you find them.

```bash
git reflog

# Output:
# e56ba1f HEAD@{0}: commit: revert bad feature
# d4e8f21 HEAD@{1}: commit: add pagination
# 9a9add8 HEAD@{2}: reset: moving to HEAD~1
# c8d21fa HEAD@{3}: commit: update nginx config
# b71e3a2 HEAD@{4}: commit: initialize project
```

Each line is an action. `HEAD@{n}` is shorthand for the state HEAD was in n steps ago.

**Recover commits lost after a hard reset:**

```bash
# You ran git reset --hard and lost commits d4e8f21 and e56ba1f
git reflog
# Find the hash of the commit you want to recover — e.g. d4e8f21

# Move HEAD back to it
git reset --hard d4e8f21
# Your commits are back
```

**Recover a deleted branch:**

```bash
# You deleted feature/webstore-pagination before merging
git branch -D feature/webstore-pagination

# Find the last commit that was on that branch
git reflog
# 3f8c2a1 HEAD@{2}: commit: feat: add pagination query params

# Recreate the branch at that commit
git branch feature/webstore-pagination 3f8c2a1
git switch feature/webstore-pagination
# Branch is back with all its commits
```

**The key insight about reflog:** Git almost never truly deletes commits. When you `reset --hard` or delete a branch, the commits are still in the object store — they just have no reference pointing to them. Reflog gives you those references back. As long as you act within 90 days, recovery is almost always possible.

---

## 6. The Decision Table

| Situation | Right tool | Wrong tool |
|---|---|---|
| Typo in last commit message, not pushed | `git commit --amend` | `git revert` — creates an unnecessary new commit |
| Forgot to stage a file, last commit not pushed | `git add <file>` + `git commit --amend --no-edit` | Creating a new commit for a tiny fix |
| Bad commit already pushed, others may have pulled | `git revert <hash>` | `git reset --hard` + force push — rewrites shared history |
| Several bad local commits, not pushed, keep the changes | `git reset --soft HEAD~N` | `git reset --hard` — would erase the work |
| Several bad local commits, not pushed, discard everything | `git reset --hard HEAD~N` | `git revert` — unnecessary when history is not shared |
| Lost commits after reset | `git reflog` + `git reset --hard <hash>` | Panicking — reflog almost always has it |
| Accidentally deleted a branch | `git reflog` + `git branch <n> <hash>` | Accepting the loss |

**The golden rule:**
Revert for shared history. Reset for local cleanup. Reflog for recovery.

---

## 7. Quick Reference

| Command | What it does |
|---|---|
| `git restore <file>` | Discard changes in working directory |
| `git restore --staged <file>` | Unstage a file |
| `git commit --amend -m "new message"` | Fix last commit message (not pushed only) |
| `git commit --amend --no-edit` | Add staged changes to last commit (not pushed only) |
| `git revert <hash>` | Create new commit that undoes a specific commit — safe for pushed |
| `git revert HEAD` | Revert the most recent commit |
| `git reset --soft HEAD~N` | Undo N commits, keep changes staged |
| `git reset --mixed HEAD~N` | Undo N commits, keep changes unstaged |
| `git reset --hard HEAD~N` | Undo N commits, erase all changes |
| `git reflog` | Show full history of HEAD movements |
| `git reset --hard HEAD@{n}` | Restore HEAD to any reflog position |
| `git branch <n> <hash>` | Recreate a deleted branch from a reflog hash |

---

→ Ready to practice? [Go to Lab 05](../git-labs/05-undo-recovery-lab.md)

---
# TOOL: 02. Git & GitHub – Version Control | FILE: git-labs
---

[Home](../README.md) |
[Labs Index](./README.md) |
[Lab 01](./01-foundations-lab.md) |
[Lab 02](./02-stash-tags-lab.md) |
[Lab 03](./03-history-branching-lab.md) |
[Lab 04](./04-contribute-lab.md) |
[Lab 05](./05-undo-recovery-lab.md)

---

# Git Labs

Hands-on sessions for every phase in the Git notes.

Do them in order. Do not move to the next lab until the checklist at the bottom is fully checked.

---

## The Project Thread

These five labs are not isolated exercises. They are five stages in the life of the webstore project — the same project you built in Linux — as it gains version control, a public presence on GitHub, and the collaborative workflow a real team uses.

By the time you finish Lab 05 you will have a versioned webstore on GitHub with a clean commit history, a tagged release, feature branches, a merged pull request, and the confidence to recover from any Git mistake. That is the state Docker picks up from — a project with history worth tracking before containerization.

| Lab | Where the webstore is | What you do |
|---|---|---|
| [Lab 01](./01-foundations-lab.md) | Files on disk, no version control | Initialize the repo, make the first commits, push to GitHub — the project becomes trackable |
| [Lab 02](./02-stash-tags-lab.md) | On GitHub, active development | Interrupt yourself mid-work, stash, fix a bug, restore — then tag v1.0 as the first stable release |
| [Lab 03](./03-history-branching-lab.md) | v1.0 tagged, new features needed | Build features in isolation on branches, merge them, resolve conflicts, keep history linear with rebase |
| [Lab 04](./04-contribute-lab.md) | Active team, features being built | Practice the full PR workflow — feature branch, push, review, merge — then the open-source fork workflow |
| [Lab 05](./05-undo-recovery-lab.md) | Something went wrong | Fix every category of Git mistake — wrong message, bad commit, accidental reset, deleted branch |

---

## Labs

| Lab | Topics Covered | What You Practice |
|---|---|---|
| [Lab 01](./01-foundations-lab.md) | Foundations | Init repo, configure identity, .gitignore, first commits, push to GitHub |
| [Lab 02](./02-stash-tags-lab.md) | Stash & Tags | Stash mid-work, restore, tag the first release, push tags |
| [Lab 03](./03-history-branching-lab.md) | History & Branching | Read history, fast-forward merge, 3-way merge, conflict resolution, rebase |
| [Lab 04](./04-contribute-lab.md) | Contribute | Feature branch PR workflow, fork, upstream remote, sync fork |
| [Lab 05](./05-undo-recovery-lab.md) | Undo & Recovery | Amend commits, revert bad commits, reset, recover with reflog |

---

## How to Use These Labs

Read the notes for each phase before opening a terminal. Every lab assumes you have read the corresponding notes file first.

Write every command from scratch. Do not copy-paste. Typing forces your brain to process each flag and each decision.

Every lab has a "Break It on Purpose" section. Do not skip it. These are the failure states you will actually hit — seeing the error yourself and fixing it is the point.

Do not move to the next lab until every box in the checklist is checked. If you cannot check a box honestly, go back and do it properly.

---
# TOOL: 03. Networking – Foundations | FILE: 01-foundation-and-the-big-picture
---

# File 01: Foundation & The Big Picture

[Home](../README.md) |
[Foundation](../01-foundation-and-the-big-picture/README.md) |
[Addressing](../02-addressing-fundamentals/README.md) |
[IP Deep Dive](../03-ip-deep-dive/README.md) |
[Network Devices](../04-network-devices/README.md) |
[Subnets & CIDR](../05-subnets-cidr/README.md) |
[Ports & Transport](../06-ports-transport/README.md) |
[NAT](../07-nat/README.md) |
[DNS](../08-dns/README.md) |
[Firewalls](../09-firewalls/README.md) |
[Complete Journey](../10-complete-journey/README.md)

---

# Foundation & The Big Picture

## What this file is about

This file teaches **what networking actually is** and **why it exists**. If you understand this, you'll have the mental framework to understand everything else in this series. No prior knowledge required.

<!-- no toc -->
- [Why Networking Exists](#why-networking-exists)
- [What Is a Network?](#what-is-a-network)
- [The Internet's Physical Reality](#the-internets-physical-reality)
- [What Is Data? (Introducing Packets)](#what-is-data-introducing-packets)
- [The Secret: Everything Is Layers](#the-secret-everything-is-layers)
- [The OSI Model — Your Map](#the-osi-model--your-map)
- [The Mental Model That Makes Everything Click](#the-mental-model-that-makes-everything-click)  
[Final Compression](#final-compression)

---

## Why Networking Exists

### The Problem (Before Networks)

**Scenario: 1960s**

Researchers at MIT have data.  
Researchers at Stanford need that data.  

**How do they share it?**

Option 1: Print it, mail it (takes days)  
Option 2: Fly with magnetic tapes (expensive)  
Option 3: Type it all again (error-prone)  

**None of these work when:**
- You need the data NOW
- The data changes constantly  
- Multiple people need access simultaneously

**The question became:** Can we connect computers together so they can share data instantly?

---

### The Solution: ARPANET (The First Network)

**1969:**  
The US government's Advanced Research Projects Agency (ARPA) connected four university computers:

```
UCLA ←→ Stanford ←→ UC Santa Barbara ←→ University of Utah
```

**For the first time:**
- A researcher at UCLA could send data to Stanford instantly
- No printing, no mailing, no flying
- Just computers talking directly to each other

**This was ARPANET — the ancestor of the internet.**

---

### Why This Matters for You

When you:
- Open a website
- Send an email  
- Deploy code to AWS
- Run a Docker container that talks to a database

**You're using the same fundamental concept:**

**Computers connected together, sharing data.**

Everything else is just details about HOW that connection works.

---

## What Is a Network?

### The Simple Definition

**A network is two or more computers connected together so they can share data.**

That's it. That's networking.

---

### How Are They Connected?

**Three main ways:**

#### 1. Ethernet (Wired)

```
[Computer A] ──cable── [Computer B]
```

**Physical medium:** Copper cable (electrical signals)  
**Speed:** Fast (1 Gbps - 100 Gbps)  
**Range:** Up to 100 meters per cable  
**Use case:** Office networks, data centers, your home router

---

#### 2. WiFi (Wireless)

```
[Laptop] ~~~radio waves~~~ [Router]
```

**Physical medium:** Radio waves (electromagnetic signals)  
**Speed:** Medium (100 Mbps - 1 Gbps)  
**Range:** Up to 100 meters  
**Use case:** Homes, coffee shops, airports

---

#### 3. Fiber Optic

```
[Data Center A] ──fiber cable── [Data Center B]
```

**Physical medium:** Glass fiber (light signals)  
**Speed:** Very fast (10 Gbps - 400 Gbps)  
**Range:** Up to 100 kilometers (or across oceans!)  
**Use case:** Internet backbone, submarine cables, data centers

---

### Network Sizes (Scope)

Networks come in different sizes:

| Type | Name | Scope | Example |
|------|------|-------|---------|
| **LAN** | Local Area Network | One building/floor | Your home WiFi, office network |
| **WAN** | Wide Area Network | Multiple cities/countries | The Internet, corporate networks across offices |

**Key distinction:**
- **LAN:** All devices can talk directly (same physical location)
- **WAN:** Devices need intermediate connections (different locations)

---

## The Internet's Physical Reality

### What Is "The Internet"?

**The internet is NOT in the sky.**  
**The internet is NOT "the cloud."**  

**The internet is:**
- Millions of smaller networks connected together
- Physical cables (lots of them)
- Computers forwarding data between networks

---

### The Physical Infrastructure

#### Submarine Cables (The Backbone)

**Right now, at the bottom of the ocean:**

```
North America ←──────fiber cable──────→ Europe
                 (across Atlantic Ocean)

Asia ←──────fiber cable──────→ North America
              (across Pacific Ocean)
```

**Facts:**
- Over 400 submarine cables connect continents
- These cables are the size of a garden hose
- They carry 99% of international internet traffic
- If cut, entire regions lose connectivity

**You can see them:** [https://www.submarinecablemap.com/](https://www.submarinecablemap.com/)

---

#### Data Centers

**Where websites and cloud services actually live:**

```
Google has data centers in:
- Iowa, USA
- Finland
- Singapore
- ... and many more

When you Google something:
Your request goes to the nearest data center
```

**These are PHYSICAL buildings** with:
- Thousands of computers (servers)
- Cooling systems (computers generate heat)
- Backup power (can't go offline)
- Security (valuable data)

**"The cloud" = someone else's computer in a data center.**

---

#### Internet Service Providers (ISPs)

**Your bridge to the internet:**

```
Your home ←─cable─→ ISP ←─fiber─→ Internet backbone
```

**Examples:**
- USA: AT&T, Comcast, Verizon
- India: Airtel, Jio, BSNL  
- UK: BT, Sky, Virgin Media

**What ISPs do:**
- Connect your home to their network
- Provide a public IP address (more on this later)
- Route your traffic to the rest of the internet
- You pay them monthly for this service

---

### Mental Model: The Internet

```
┌────────────────────────────────────────────────┐
│           YOUR HOME NETWORK (LAN)              │
│                                                │
│  [Laptop] [Phone] [Smart TV]                   │
│       │      │        │                        │
│       └──────┴────────┘                        │
│              │                                 │
│         [Router]                               │
└──────────────┼─────────────────────────────────┘
               │
        (Cable/Fiber)
               │
┌──────────────▼─────────────────────────────────┐
│          ISP NETWORK                           │
│  (Connects you to backbone)                    │
└──────────────┬─────────────────────────────────┘
               │
        (Fiber optics)
               │
┌──────────────▼─────────────────────────────────┐
│        INTERNET BACKBONE                       │
│  (Submarine cables, major routers)             │
└──────────────┬─────────────────────────────────┘
               │
        ┌──────┴──────────┐
        │                 │
┌───────▼───────┐ ┌───────▼────────┐
│ Google Servers│ │ AWS Data Center│
│ (California)  │ │ (Virginia)     │
└───────────────┘ └────────────────┘
```

**The internet = all of these networks connected.**

---

## What Is Data? (Introducing Packets)

### The Fundamental Concept

**When you send data over a network, it doesn't travel as one big file.**

**It travels as small chunks called PACKETS.**

---

### Why Packets Exist

**Scenario: You want to download a 10 MB video**

**Option 1: Send as one big file**
```
[10 MB file] ────────→ [Your computer]

Problem:
- Takes a long time (blocks everything else)
- If connection breaks mid-transfer, start over
- No other data can use the network
```

**Option 2: Break into packets (what actually happens)**
```
10 MB video = 7,000 packets (each ~1,500 bytes)

Packet 1 ──→
Packet 2 ──→
Packet 3 ──→
... (thousands more)
Packet 7,000 ──→

Benefits:
- Packets can take different routes (faster)
- If one packet fails, only resend that packet
- Multiple users can share the network
- Packets arrive and reassemble at destination
```

---

### What a Packet Looks Like (Simplified)

**Every packet has two parts:**

```
┌─────────────────────────────────────────┐
│           PACKET                        │
│                                         │
│  ┌──────────────────────────────────┐   │
│  │ HEADER (Metadata)                │   │
│  │                                  │   │
│  │ - Where it's going (destination) │   │
│  │ - Where it came from (source)    │   │
│  │ - Packet number (for ordering)   │   │
│  │ - Other control info             │   │
│  └──────────────────────────────────┘   │
│                                         │
│  ┌──────────────────────────────────┐   │
│  │ PAYLOAD (Actual Data)            │   │
│  │                                  │   │
│  │ Part of your video, email, etc.  │   │
│  └──────────────────────────────────┘   │
│                                         │
└─────────────────────────────────────────┘
```

**Analogy: Packets = letters in an envelope**

```
Envelope (header):
- To: 123 Main St (destination)
- From: 456 Oak Ave (source)
- Stamp (delivery info)

Letter inside (payload):
- Your actual message
```

---

### Real Example: Sending an Email

**You send email: "Hello, how are you?"**

```
Email gets broken into packets:

Packet 1:
  Header: To: mail server, From: you, Packet 1 of 3
  Payload: "Hello, "

Packet 2:
  Header: To: mail server, From: you, Packet 2 of 3
  Payload: "how are "

Packet 3:
  Header: To: mail server, From: you, Packet 3 of 3
  Payload: "you?"

Mail server receives all 3 packets
Reassembles: "Hello, how are you?"
```

**This is how ALL data travels on networks.**

- Websites → broken into packets
- Videos → broken into packets  
- File uploads → broken into packets
- Everything → packets

---

## The Secret: Everything Is Layers

### The Core Insight That Makes Networking Make Sense

**Networking is not one thing.**  
**Networking is LAYERS working together.**

Each layer has a specific job.  
Each layer builds on the layer below it.

**This is the most important concept in networking.**

---

### The Envelope Analogy

**Imagine sending a package:**

```
Step 1: Write a letter (your data)

Step 2: Put letter in envelope (add destination address)

Step 3: Put envelope in box (add shipping label)

Step 4: Give box to delivery driver (physical transport)
```

**Each step wraps the previous step.**

**This is exactly how networking works.**

---

### How Data Actually Travels (Layer by Layer)

**You type google.com in your browser:**

```
Layer 7 (Application):
  Your browser creates HTTP request:
  "GET / HTTP/1.1
   Host: google.com"

        ↓ Wraps ↓

Layer 4 (Transport):
  Adds TCP header:
  - Source port: 54321
  - Destination port: 443 (HTTPS)
  
        ↓ Wraps ↓

Layer 3 (Network):
  Adds IP header:
  - Source IP: Your laptop's IP
  - Destination IP: Google's server IP
  
        ↓ Wraps ↓

Layer 2 (Data Link):
  Adds Ethernet header:
  - Source MAC: Your network card
  - Destination MAC: Router
  
        ↓ Wraps ↓

Layer 1 (Physical):
  Converts to electrical/radio signals
  Transmits over cable/WiFi
```

---

### The Russian Nesting Doll Visual

**Each layer wraps the previous layer like a nesting doll:**

```
┌──────────────────────────────────────────────────────┐
│ Ethernet Frame (Layer 2)                             │
│                                                      │
│  ┌────────────────────────────────────────────────┐  │
│  │ IP Packet (Layer 3)                            │  │
│  │                                                │  │
│  │  ┌──────────────────────────────────────────┐  │  │
│  │  │ TCP Segment (Layer 4)                    │  │  │
│  │  │                                          │  │  │
│  │  │  ┌────────────────────────────────────┐  │  │  │
│  │  │  │ HTTP Request (Layer 7)             │  │  │  │
│  │  │  │                                    │  │  │  │
│  │  │  │ "GET /index.html HTTP/1.1"         │  │  │  │
│  │  │  │                                    │  │  │  │
│  │  │  └────────────────────────────────────┘  │  │  │
│  │  │                                          │  │  │
│  │  └──────────────────────────────────────────┘  │  │
│  │                                                │  │
│  └────────────────────────────────────────────────┘  │
│                                                      │
└──────────────────────────────────────────────────────┘
```

**This wrapping process is called ENCAPSULATION.**

**It's the fundamental mechanism of how networking works.**

---

### Why Layers Matter

**Each layer solves a different problem:**

| Layer | Problem It Solves | Example |
|-------|------------------|---------|
| **Physical** | How do we transmit bits? | Cables, WiFi radio |
| **Data Link** | How do we deliver data locally? | Ethernet, MAC addresses |
| **Network** | How do we reach different networks? | IP addresses, routing |
| **Transport** | How do we ensure reliable delivery? | TCP (guaranteed), UDP (fast) |
| **Application** | What does the data mean? | HTTP (web), SMTP (email) |

**Without layers:**
- Every application would need to know about cables
- Every cable type would need different software
- Chaos

**With layers:**
- Applications just send data (don't care about cables)
- Physical layer just transmits bits (doesn't care about apps)
- Clean separation

---

## The OSI Model — Your Map

### What Is OSI?

**OSI = Open Systems Interconnection**

It's a framework that organizes networking into 7 layers.

**Think of it as a MAP of the networking world.**

You don't need to memorize every detail now. You just need to know the map exists.

---

### The 7 Layers

```
┌─────────────────────────────────────────────┐
│  Layer 7: Application                       │
│  What: User-facing protocols                │
│  Examples: HTTP, DNS, SSH, FTP              │
│  Your browser/apps live here                │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│  Layer 6: Presentation                      │
│  What: Data formatting, encryption          │
│  Examples: SSL/TLS, JPEG, encryption        │
│  Makes data readable/secure                 │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│  Layer 5: Session                           │
│  What: Manages connections                  │
│  Examples: Session control                  │
│  Keeps conversations organized              │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│  Layer 4: Transport                         │
│  What: Reliability, ports                   │
│  Examples: TCP (reliable), UDP (fast)       │
│  Adds port numbers to identify apps         │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│  Layer 3: Network                           │
│  What: IP addressing, routing               │
│  Examples: IP, routers, subnets             │
│  Gets packets to correct network            │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│  Layer 2: Data Link                         │
│  What: Local delivery                       │
│  Examples: Ethernet, WiFi, MAC addresses    │
│  Delivers within one network segment        │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│  Layer 1: Physical                          │
│  What: Physical transmission                │
│  Examples: Cables, WiFi radio, fiber        │
│  Actual 1s and 0s transmitted               │
└─────────────────────────────────────────────┘
```

---

### How to Remember the Layers

**Mnemonic (top to bottom):**
```
All People Seem To Need Data Processing

Application
Presentation
Session
Transport
Network
Data Link
Physical
```

**Or (bottom to top):**
```
Please Do Not Throw Sausage Pizza Away

Physical
Data Link
Network
Transport
Session
Presentation
Application
```

---

### Which Layers Matter for DevOps?

**You'll spend 90% of your time in these layers:**

- ⭐ **Layer 7 (Application):** HTTP, HTTPS, DNS, SSH — what users interact with
- ⭐ **Layer 4 (Transport):** TCP/UDP, ports — reliability and app identification  
- ⭐ **Layer 3 (Network):** IP addresses, routing, subnets — how packets get places

**Less often:**
- **Layer 2 (Data Link):** Mostly abstracted in cloud environments
- **Layers 5-6:** Handled automatically (TLS encryption, etc.)
- **Layer 1 (Physical):** Cloud provider handles this

---

### Real Example: Opening a Website

**When you visit google.com, here's what happens at each layer:**

```
Layer 7 (Application):
  Browser creates HTTP request
  
Layer 6 (Presentation):
  HTTPS encrypts the request (TLS)
  
Layer 5 (Session):
  Maintains connection to server
  
Layer 4 (Transport):
  TCP ensures data arrives correctly
  Port 443 identifies HTTPS service
  
Layer 3 (Network):
  IP routing finds Google's server
  
Layer 2 (Data Link):
  Ethernet/WiFi delivers to router locally
  
Layer 1 (Physical):
  Electrical signals travel through cable/WiFi
```

**Each layer does its job.**  
**Together, they get you the webpage.**

---

## The Mental Model That Makes Everything Click

### Three Core Questions Every Packet Answers

When data travels across a network, it needs to answer three questions:

```
1. WHERE AM I GOING?
   (Destination address)

2. WHO DO I GIVE THIS TO NEXT?
   (Next hop)

3. WHAT SERVICE AM I FOR?
   (Application identification)
```

**Different layers answer different questions:**

| Question | Layer | Technology |
|----------|-------|-----------|
| **Where am I going ultimately?** | Layer 3 | IP address (final destination) |
| **Who do I give this to next?** | Layer 2 | MAC address (next hop only) |
| **What service am I for?** | Layer 4 | Port number (HTTP, SSH, etc.) |

**This is the foundation of all networking.**

---

### The Journey of a Packet (Simple View)

**You send email from New York to London:**

```
Your laptop (New York):
  "I need to send data to email server in London"
  
Step 1: Check IP address
  Destination: 203.0.113.50 (London server)
  
Step 2: Not on my local network
  Send to router (next hop)
  
Step 3: Router checks
  "203.0.113.50 is in London"
  Forward to next router toward London
  
(Packet hops through 10-20 routers)

Step 4: Final router in London
  "203.0.113.50 is directly connected"
  Deliver to email server
  
Email server:
  "Packet is for port 25 (email service)"
  Deliver to email application
```

**At each step:**
- IP address stayed the same (final destination)
- Local delivery address changed (next hop)
- Port stayed the same (email service)

**This is networking.**

---

## Final Compression

### What You Learned

✅ **Networking = computers connected to share data**  
✅ **The internet = millions of networks connected physically**  
✅ **Data travels as packets** (small chunks, not big files)  
✅ **Layers wrap data** (encapsulation, like Russian nesting dolls)  
✅ **OSI model = the map** (7 layers, each with a job)  

---

### The One Diagram You Need

```
Application (HTTP, DNS)
    ↓
Transport (TCP/UDP, Ports)
    ↓
Network (IP, Routing)
    ↓
Data Link (MAC, Ethernet)
    ↓
Physical (Cables, WiFi)

Each layer wraps the one above it.
Each layer serves the one above it.
```

---

### Three Core Truths

```
1. Packets = How data actually travels
   (Not continuous streams, but chunks)

2. Encapsulation = How layers work together
   (Each layer wraps the previous)

3. Addressing = How packets find their way
   (IP = destination, MAC = next hop, Port = service)
```

---

### The Big Picture

```
You (typing google.com)
    ↓
Packets created (with layers wrapped)
    ↓
Travel through routers (across the world)
    ↓
Reach Google's server (layers unwrapped)
    ↓
Google responds (new packets created)
    ↓
Travel back to you (same process in reverse)
    ↓
Your browser displays webpage

Every step follows the same principles:
- Encapsulation (layers)
- Addressing (IP, MAC, Port)
- Routing (next hop decisions)
```

**This is networking.**  
**Everything else is details.**

---

## What This Means for the Webstore

The webstore is three processes on a Linux server — nginx on port 80, the API on port 8080, and postgres on port 5432. When a browser requests the webstore homepage, it sends a packet. That packet has a header at every layer: application (HTTP GET /), transport (TCP, destination port 80), network (the server's IP address), data link (MAC address of the next router hop). Each layer does exactly one job and hands off to the next. The webstore receives the request, nginx processes it, and the response travels back through the same stack in reverse. Everything in this series explains one piece of that journey.

---
# TOOL: 03. Networking – Foundations | FILE: 02-addressing-fundamentals
---

# File 02: Addressing Fundamentals

[Home](../README.md) |
[Foundation](../01-foundation-and-the-big-picture/README.md) |
[Addressing](../02-addressing-fundamentals/README.md) |
[IP Deep Dive](../03-ip-deep-dive/README.md) |
[Network Devices](../04-network-devices/README.md) |
[Subnets & CIDR](../05-subnets-cidr/README.md) |
[Ports & Transport](../06-ports-transport/README.md) |
[NAT](../07-nat/README.md) |
[DNS](../08-dns/README.md) |
[Firewalls](../09-firewalls/README.md) |
[Complete Journey](../10-complete-journey/README.md)

---

# Addressing Fundamentals

## What this file is about

This file teaches **how devices identify each other on networks**. If you understand this, you'll know why both MAC addresses and IP addresses exist, how they work together, and how a device discovers another device's physical address (ARP). This is the foundation for everything else in networking.

<!-- no toc -->
- [The Core Problem](#the-core-problem)
- [Two Types of Addresses (And Why Both Exist)](#two-types-of-addresses-and-why-both-exist)
- [MAC Addresses (Physical Identity)](#mac-addresses-physical-identity)
- [IP Addresses (Logical Identity)](#ip-addresses-logical-identity)
- [Why Both? The Critical Truth](#why-both-the-critical-truth)
- [ARP: The Missing Link](#arp-the-missing-link)
- [Private vs Public IP Addresses](#private-vs-public-ip-addresses)
- [Real Scenarios](#real-scenarios)  
[Final Compression](#final-compression)

---

## The Core Problem

### The Question

**Scenario:** Your laptop wants to send data to a printer on your home WiFi.

**Three questions your laptop must answer:**

```
1. Who am I trying to reach? (identification)
2. Where are they? (location)
3. How do I physically deliver this data to them? (delivery)
```

**This is the addressing problem.**

Without addresses, computers can't find each other.

---

### Real-World Analogy

**Sending a letter:**

```
You need:
1. Person's name ("John Smith")
2. Street address ("123 Main St, New York")
3. Physical delivery (postal service uses address to deliver)

Without the address, the postal service can't deliver the letter.
```

**Sending data on a network:**

```
You need:
1. Device identity (what it's called)
2. Network address (where it is)
3. Physical address (how to reach it on local network)

Without addresses, data can't be delivered.
```

---

## Two Types of Addresses (And Why Both Exist)

**Networking uses TWO different types of addresses:**

```
1. MAC Address (Physical, Layer 2)
   - Permanent
   - Identifies hardware
   - Works only locally

2. IP Address (Logical, Layer 3)
   - Can change
   - Identifies device on network
   - Works globally
```

**This seems redundant. Why two addresses?**

**Short answer:** They solve different problems at different layers.

Let's understand each one, then see how they work together.

---

## MAC Addresses (Physical Identity)

### What Is a MAC Address?

**MAC = Media Access Control**

**Definition:**  
A MAC address is a **permanent hardware identifier** burned into your network card by the manufacturer.

**Format:**
```
AA:BB:CC:DD:EE:FF

6 pairs of hexadecimal digits
Separated by colons (or hyphens)
```

**Real examples:**
```
Your laptop WiFi:     A4:83:E7:2F:1B:C9
Your phone:           00:1A:2B:3C:4D:5E
Your router:          F8:1A:67:B4:32:D1
```

---

### Key Characteristics

| Property | Value |
|----------|-------|
| **Length** | 48 bits (6 bytes) |
| **Format** | 12 hexadecimal digits |
| **Uniqueness** | Globally unique (in theory) |
| **Changes?** | ❌ No — permanent (burned into hardware) |
| **Scope** | Local network only |
| **Layer** | Layer 2 (Data Link) |

---

### Who Assigns MAC Addresses?

**The manufacturer.**

When a company (like Intel, Broadcom, Realtek) makes a network card:

```
Step 1: Manufacturer gets assigned a block of MAC addresses
        from IEEE (standards organization)

Step 2: Manufacturer burns a unique MAC address into each
        network card's ROM (read-only memory)

Step 3: This MAC address never changes (permanent)
```

**You never assign MAC addresses yourself.**

---

### Where MAC Addresses Live

**Every network interface has a MAC address:**

```
Your laptop might have:
├─ WiFi card:      A4:83:E7:2F:1B:C9
├─ Ethernet port:  00:1E:C9:4A:7B:2D
└─ Bluetooth:      F0:18:98:45:AB:CD

Each interface = different MAC address
```

**Check your MAC address:**

```bash
# Linux/Mac
ip link show
# or
ifconfig

# Windows
ipconfig /all

Look for: "HWaddr", "ether", or "Physical Address"
```

---

### What MAC Addresses Look Like (Breakdown)

```
A4:83:E7:2F:1B:C9
│ │ │  │  │  │
└─┴─┴──┴──┴──┴─→ 6 bytes total

First 3 bytes (A4:83:E7):
  Organizationally Unique Identifier (OUI)
  Identifies manufacturer (e.g., Intel, Apple)

Last 3 bytes (2F:1B:C9):
  Device-specific identifier
  Unique to this specific network card
```

**You can look up manufacturers:**  
Website: [https://maclookup.app/](https://maclookup.app/)

Enter `A4:83:E7` → "Intel Corporation"

---

### What MAC Addresses Are Used For

**MAC addresses work at Layer 2 (Data Link).**

**Their job:** Deliver data to the correct device **on the local network**.

**Example:**

```
Your home WiFi network:
├─ Laptop:   MAC A4:83:E7:2F:1B:C9
├─ Phone:    MAC 00:1A:2B:3C:4D:5E
├─ Printer:  MAC F8:1A:67:B4:32:D1
└─ Router:   MAC 11:22:33:44:55:66

When laptop sends data to printer:
Ethernet frame header contains:
  Source MAC:      A4:83:E7:2F:1B:C9 (laptop)
  Destination MAC: F8:1A:67:B4:32:D1 (printer)

WiFi access point sees destination MAC
Delivers frame to printer
```

---

### Critical Limitation: MAC Addresses Only Work Locally

**MAC addresses do NOT route across networks.**

**Example:**

```
Your laptop (New York):  MAC A4:83:E7:2F:1B:C9
Google server (California): MAC XY:ZW:AB:CD:EF:12

Question: Can your laptop send data directly to Google's MAC?
Answer: ❌ NO

Why not?
- MAC addresses only work on local network
- Google is on a different network (different building, different city)
- Routers do not forward based on MAC addresses
```

**This is why we need IP addresses.**

---

## IP Addresses (Logical Identity)

### What Is an IP Address?

**IP = Internet Protocol**

**Definition:**  
An IP address is a **logical network identifier** assigned to a device. Unlike MAC addresses, IP addresses can change and work across networks.

**Format (IPv4):**
```
192.168.1.45

4 numbers (0-255)
Separated by dots
```

**Real examples:**
```
Your laptop:       192.168.1.45
Your router:       192.168.1.1
Google's server:   142.250.190.46
Your office PC:    10.0.1.100
```

---

### Key Characteristics

| Property | Value |
|----------|-------|
| **Length** | 32 bits (4 bytes) |
| **Format** | 4 decimal numbers (0-255) |
| **Uniqueness** | Unique within a network |
| **Changes?** | ✅ Yes — can be reassigned |
| **Scope** | Global (routes across networks) |
| **Layer** | Layer 3 (Network) |

---

### Who Assigns IP Addresses?

**Unlike MAC addresses, IP addresses are assigned by:**

1. **DHCP server** (automatic — covered in File 03)
2. **Network administrator** (manual — static configuration)
3. **ISP** (for your router's public IP)

**You control IP addresses** (or the network does).

---

### IP Address Structure

```
192.168.1.45
│   │   │  │
Each number = 1 byte (0-255)
Total = 4 bytes = 32 bits

Example breakdown:
192 = 11000000 (binary)
168 = 10101000 (binary)
1   = 00000001 (binary)
45  = 00101101 (binary)
```

**You don't need to know binary conversion.**  
**You just need to know each number is 0-255.**

---

### What IP Addresses Are Used For

**IP addresses work at Layer 3 (Network).**

**Their job:** Route data to the correct **network** and **device** globally.

**Example:**

```
You (New York):       IP 192.168.1.45
Google (California):  IP 142.250.190.46

Packet created:
  Source IP:      192.168.1.45
  Destination IP: 142.250.190.46

Routers across the internet read this IP
Forward packet hop by hop
Eventually reaches Google's network
Delivered to 142.250.190.46
```

**IP addresses route across the world.**

---

### The Key Difference: Scope

| Address Type | Scope | Example |
|--------------|-------|---------|
| **MAC** | Local network only (one hop) | Your laptop → Your router |
| **IP** | Global (many hops) | Your laptop → Google server |

---

## Why Both? The Critical Truth

### The Biggest Beginner Mistake

**❌ WRONG thinking:**
```
"Use MAC for local network"
"Use IP for internet"
```

**This makes it sound like they're used in different scenarios.**

**✅ CORRECT reality:**
```
MAC and IP are ALWAYS used together.
Every packet has BOTH MAC and IP headers.

They serve different purposes:
- MAC = next hop (where to send it NOW)
- IP = final destination (where it's ultimately going)
```

---

### How They Work Together

**Scenario: Your laptop (New York) wants to reach Google (California)**

**The packet contains:**

```
┌──────────────────────────────────────────┐
│ Ethernet Frame (Layer 2)                 │
│                                          │
│ Source MAC:      [Your laptop MAC]       │
│ Destination MAC: [Your router MAC]  ←───┐│
│                                      │  ││
│  ┌────────────────────────────────┐  │  ││
│  │ IP Packet (Layer 3)            │  │  ││
│  │                                │  │  ││
│  │ Source IP:      192.168.1.45   │  │  ││
│  │ Destination IP: 142.250.190.46 │←─┼──┘│
│  │                                │  │   │
│  └────────────────────────────────┘  │   │
│                                      │   │
└──────────────────────────────────────┘   │
         │                                 │
    Next hop                          Final destination
  (router MAC)                         (Google IP)
```

**Key insight:**

```
Destination MAC = Your router (next hop)
Destination IP  = Google server (final destination)

These are DIFFERENT addresses for DIFFERENT purposes.
```

---

### The Journey (Step by Step)

**Hop 1: Your laptop → Your router**

```
MAC src: Laptop MAC
MAC dst: Router MAC  ← Changes at each hop
IP src:  Laptop IP
IP dst:  Google IP   ← Stays the same
```

**Hop 2: Your router → ISP router**

```
Router strips old Ethernet frame
Reads IP destination
Creates new Ethernet frame:

MAC src: Router MAC
MAC dst: ISP router MAC  ← Changed
IP src:  Laptop IP
IP dst:  Google IP       ← Still the same
```

**Hop 3-20: Through internet routers**

```
At each router:
- Old MAC addresses discarded
- New MAC addresses added (next hop)
- IP addresses never change
```

**Final hop: Last router → Google server**

```
MAC src: Last router MAC
MAC dst: Google server MAC  ← Changed again
IP src:  Laptop IP
IP dst:  Google IP          ← Still the same
```

---

### Visual: MAC Changes, IP Stays

```
Your Laptop (New York)
  MAC: AA:AA:AA:AA:AA:AA
  IP:  192.168.1.45
      │
      ├─ Packet 1 ────────────────────┐
      │  MAC src: AA:AA:AA:AA:AA:AA   │
      │  MAC dst: 11:11:11:11:11:11   │ (Router)
      │  IP src:  192.168.1.45        │
      │  IP dst:  142.250.190.46      │
      │                               │
      ▼                               │
Your Router                           │
  MAC: 11:11:11:11:11:11              │
      │                               │
      ├─ Packet 2 ────────────────────┤
      │  MAC src: 11:11:11:11:11:11   │ (Router)
      │  MAC dst: 22:22:22:22:22:22   │ (ISP router)
      │  IP src:  192.168.1.45    ←───┼─ Same!
      │  IP dst:  142.250.190.46  ←───┼─ Same!
      │                               │
      ▼                               │
ISP Router                            │
  MAC: 22:22:22:22:22:22              │
      │                               │
      ... (10 more hops) ...          │
      │                               │
      ▼                               │
Google Server (California)            │
  MAC: BB:BB:BB:BB:BB:BB              │
  IP:  142.250.190.46                 │
      │                               │
      Final packet: ──────────────────┘
        MAC src: 99:99:99:99:99:99   (Last router)
        MAC dst: BB:BB:BB:BB:BB:BB   (Google)
        IP src:  192.168.1.45    ←─── Still the same!
        IP dst:  142.250.190.46  ←─── Still the same!
```

**The rule:**

```
MAC addresses: Change at every hop (local delivery)
IP addresses:  Never change (end-to-end identifier)
```

---

### Why This Design?

**MAC addresses (Layer 2):**
- Simple, fast lookup
- Works on local network segment
- No routing needed
- Hardware-based

**IP addresses (Layer 3):**
- Hierarchical (networks and hosts)
- Routes across multiple networks
- Flexible assignment
- Software-based

**Together:**
- MAC handles local delivery (this network segment)
- IP handles global routing (across networks)

**Analogy:**

```
Sending a package from New York to Los Angeles:

IP address = Final destination address
             "123 Main St, Los Angeles, CA"
             (Stays on package the entire journey)

MAC address = Current delivery truck
              "Truck A" → "Truck B" → "Truck C"
              (Changes at each distribution center)
```

---

## ARP: The Missing Link

### The Problem

**Your laptop knows:**
- Destination IP: 192.168.1.50 (printer)

**Your laptop needs:**
- Destination MAC: ??? 

**How does your laptop discover the printer's MAC address from its IP address?**

---

### The Solution: ARP (Address Resolution Protocol)

**ARP = IP to MAC translation**

**ARP answers the question:**  
"I know the IP address. What's the MAC address?"

---

### How ARP Works (Step by Step)

**Scenario:** Your laptop (192.168.1.45) wants to send data to printer (192.168.1.50)

**Step 1: Check ARP cache**

```bash
# Your laptop checks its ARP cache first
arp -a

Output:
  192.168.1.1    at  11:22:33:44:55:66  (router)
  # Printer not in cache
```

**Step 2: Send ARP request (broadcast)**

```
Your laptop broadcasts to everyone on local network:

ARP Request:
  "Who has IP 192.168.1.50?"
  "Please tell 192.168.1.45 (MAC AA:AA:AA:AA:AA:AA)"

This is sent to broadcast MAC: FF:FF:FF:FF:FF:FF
(Everyone on network receives this)
```

**Step 3: Only printer responds**

```
Printer checks:
  "Do I have IP 192.168.1.50?" → YES

Printer sends ARP reply (unicast, only to laptop):
  "192.168.1.50 is at MAC F8:1A:67:B4:32:D1"
```

**Step 4: Laptop caches the result**

```bash
# Laptop adds to ARP cache
arp -a

Output:
  192.168.1.1    at  11:22:33:44:55:66
  192.168.1.50   at  F8:1A:67:B4:32:D1  ← New entry!
```

**Step 5: Laptop can now send data**

```
Laptop creates Ethernet frame:
  Source MAC:      AA:AA:AA:AA:AA:AA (laptop)
  Destination MAC: F8:1A:67:B4:32:D1 (printer)
  
  IP Packet inside:
    Source IP:      192.168.1.45
    Destination IP: 192.168.1.50

Sends to printer
```

---

### ARP Cache (Performance Optimization)

**Why cache?**

Doing ARP for every packet would be slow:
- Broadcast request
- Wait for response
- Then send data

**Solution: Cache the result**

```bash
# Linux/Mac
arp -a

Output:
Address           HWtype  HWaddress            Flags
192.168.1.1       ether   11:22:33:44:55:66    C
192.168.1.50      ether   F8:1A:67:B4:32:D1    C

Cached for ~5-20 minutes (timeout varies)
```

**Next time you send to 192.168.1.50:**
- Check cache → Found!
- Use cached MAC address
- No ARP request needed

---

### ARP Workflow (Visual)

```
┌──────────────────────────────────────────────────┐
│  Laptop wants to send to 192.168.1.50           │
└──────────────────┬───────────────────────────────┘
                   │
                   ▼
         ┌─────────────────────┐
         │ Check ARP cache     │
         │ "Do I know the MAC?"│
         └─────────┬───────────┘
                   │
         ┌─────────┴─────────┐
         │                   │
      Found                Not found
         │                   │
         ▼                   ▼
    ┌─────────┐      ┌──────────────────┐
    │ Use it  │      │ Send ARP request │
    │         │      │ (broadcast)      │
    └─────────┘      └────────┬─────────┘
                              │
                              ▼
                     ┌─────────────────┐
                     │ Receive ARP     │
                     │ reply           │
                     └────────┬────────┘
                              │
                              ▼
                     ┌─────────────────┐
                     │ Cache result    │
                     │ Use MAC address │
                     └─────────────────┘
```

---

### Why ARP Matters

**Without ARP:**
- You'd need to manually configure MAC addresses for every device
- Doesn't scale
- Breaks when devices change

**With ARP:**
- Automatic discovery
- Works dynamically
- Scales to any network size

**DevOps reality:**
- ARP happens automatically (you never think about it)
- But when debugging network issues, ARP failures can cause problems
- Knowing ARP exists helps debug "device unreachable" errors

---

## Private vs Public IP Addresses

### Two Categories of IP Addresses

**Not all IP addresses are created equal.**

IP addresses are divided into:

1. **Private IP addresses** — Cannot route on the internet
2. **Public IP addresses** — Can route globally

---

### Private IP Addresses

**Definition:**  
IP addresses reserved for use inside private networks (homes, offices, data centers).

**Three private IP ranges (memorize these):**

| Range | CIDR Notation | Total IPs | Typical Use |
|-------|---------------|-----------|-------------|
| 10.0.0.0 - 10.255.255.255 | 10.0.0.0/8 | 16,777,216 | Large enterprises, AWS VPCs |
| 172.16.0.0 - 172.31.255.255 | 172.16.0.0/12 | 1,048,576 | Medium networks, Docker default |
| 192.168.0.0 - 192.168.255.255 | 192.168.0.0/16 | 65,536 | Home networks, small offices |

**Key characteristics:**

```
✅ Free to use (no registration needed)
✅ Reusable (every home can use 192.168.1.X)
✅ Not unique globally
❌ Cannot route on the internet
❌ Need NAT to access internet (covered in File 07)
```

---

### Public IP Addresses

**Definition:**  
All IP addresses that are NOT in the private ranges.

**Key characteristics:**

```
✅ Globally unique (only one device has this IP worldwide)
✅ Routable on the internet (can be reached from anywhere)
✅ Assigned by ISPs and regional registries
❌ Cost money (limited supply)
❌ Must be registered
```

**Examples:**
```
Google:         142.250.190.46 (public)
Your ISP:       203.45.67.89 (public, assigned to your router)
AWS EC2:        54.123.45.67 (public, Elastic IP)
```

---

### Why Private IPs Exist

**The math problem:**

```
IPv4 total addresses:  ~4.3 billion
Devices on internet:   ~20+ billion

Problem: Not enough addresses!
```

**Solution:**

```
Most devices use private IPs (inside networks)
Only routers/gateways need public IPs (facing internet)
NAT lets many private IPs share one public IP
```

**Example:**

```
Your home:
├─ Laptop:  192.168.1.45 (private)
├─ Phone:   192.168.1.67 (private)
├─ Tablet:  192.168.1.89 (private)
└─ Router:  203.45.67.89 (public, from ISP)

All 3 devices share 1 public IP via NAT.
```

---

### How to Identify Private vs Public

**Simple rule:**

```
Is the IP in one of these ranges?
- 10.0.0.0 - 10.255.255.255
- 172.16.0.0 - 172.31.255.255
- 192.168.0.0 - 192.168.255.255

YES → Private IP
NO  → Public IP
```

**Examples:**

| IP Address | Type | Why |
|------------|------|-----|
| 192.168.1.45 | Private | In 192.168.0.0/16 range |
| 10.0.1.100 | Private | In 10.0.0.0/8 range |
| 172.16.5.25 | Private | In 172.16.0.0/12 range |
| 142.250.190.46 | Public | Not in any private range |
| 8.8.8.8 | Public | Not in any private range |
| 172.32.0.1 | Public | Outside 172.16-31 range |

---

### Special IP Addresses

**Some IPs have special meanings:**

| IP Address | Name | Meaning |
|------------|------|---------|
| 127.0.0.1 | Localhost | This device (loopback) |
| 0.0.0.0 | Default route | All addresses |
| 255.255.255.255 | Broadcast | Everyone on local network |
| 169.254.X.X | Link-local | Auto-assigned (no DHCP) |

**Localhost (127.0.0.1):**

```
Always means "this machine I'm on right now"

On your laptop:     127.0.0.1 = your laptop
In a container:     127.0.0.1 = that container (not host!)
On AWS EC2:         127.0.0.1 = that EC2 instance

Never crosses network boundaries.
```

---

## Real Scenarios

### Scenario 1: Home Network

**Your home setup:**

```
┌─────────────────────────────────────────┐
│  Your Home (Private Network)            │
│                                         │
│  Laptop:                                │
│    MAC: A4:83:E7:2F:1B:C9               │
│    IP:  192.168.1.45 (private)          │
│                                         │
│  Phone:                                 │
│    MAC: 00:1A:2B:3C:4D:5E               │
│    IP:  192.168.1.67 (private)          │
│                                         │
│  Router (LAN side):                     │
│    MAC: 11:22:33:44:55:66               │
│    IP:  192.168.1.1 (private)           │
│                                         │
└─────────────────┬───────────────────────┘
                  │
        (Cable/Fiber to ISP)
                  │
┌─────────────────▼───────────────────────┐
│  Router (WAN side):                     │
│    MAC: AA:BB:CC:DD:EE:FF               │
│    IP:  203.45.67.89 (public, from ISP) │
└─────────────────────────────────────────┘
```

**When laptop accesses google.com:**

```
Inside home network:
  Laptop uses private IP: 192.168.1.45
  Router uses private IP (LAN side): 192.168.1.1

Outside (internet):
  Router uses public IP: 203.45.67.89
  Google sees this public IP (not laptop's private IP)

NAT makes this work (covered in File 07)
```

---

### Scenario 2: AWS EC2 Instance

**AWS instance addressing:**

```
EC2 Instance:
├─ Private IP:  10.0.1.25 (inside VPC)
│    Purpose: Communication within VPC
│    Never changes (static)
│
├─ Public IP:   54.123.45.67 (optional)
│    Purpose: Internet access
│    Changes when instance stops/starts
│
└─ MAC Address: 0A:12:34:56:78:9A
     Purpose: VPC internal networking
     AWS manages this
```

**Traffic flows:**

```
Instance → Another instance in same VPC:
  Uses private IPs (10.0.1.25 → 10.0.2.30)
  Stays inside VPC, never touches internet

Instance → Internet:
  Uses public IP (54.123.45.67)
  Or uses NAT Gateway if in private subnet
```

> **Docker implementation:** The same MAC and IP addressing concepts apply inside Docker networks. Each container gets its own MAC and IP, communicating via a virtual bridge exactly like a physical LAN.
> → [Docker Networking](../../04.%20Docker%20–%20Containerization/05-docker-networking/README.md)

---

## Final Compression

### The Two Address Systems

**MAC Address (Physical, Layer 2):**
```
✅ Permanent (burned into hardware)
✅ 48 bits (6 bytes), hex format: AA:BB:CC:DD:EE:FF
✅ Manufacturer assigned
✅ Local network only (one hop)
✅ Changes at every router hop
```

**IP Address (Logical, Layer 3):**
```
✅ Configurable (can change)
✅ 32 bits (4 bytes), decimal format: 192.168.1.45
✅ Network assigned (DHCP or manual)
✅ Global routing (many hops)
✅ Never changes during packet journey
```

---

### How They Work Together

**CRITICAL: Every packet has BOTH MAC and IP headers.**

```
MAC header:
  Source MAC:      [Your device]
  Destination MAC: [Next hop] ← Changes at each router

IP header:
  Source IP:       [Your device]
  Destination IP:  [Final destination] ← Never changes
```

**The rule:**

```
IP address = Where the packet is ultimately going
MAC address = Where to send it right now (next hop)
```

---

### ARP: The Translator

**ARP translates IP → MAC (on local network only)**

```
1. You know destination IP
2. You need destination MAC
3. Send ARP request (broadcast): "Who has this IP?"
4. Device responds: "I do, here's my MAC"
5. Cache result
6. Send data using MAC address
```

---

### Private vs Public IPs

**Private IP ranges (memorize):**
```
10.0.0.0 - 10.255.255.255      (10.0.0.0/8)
172.16.0.0 - 172.31.255.255    (172.16.0.0/12)
192.168.0.0 - 192.168.255.255  (192.168.0.0/16)

- Free to use
- Not internet-routable
- Need NAT for internet access
```

**Public IPs:**
```
Everything else

- Globally unique
- Internet-routable
- Costs money
```

---

### Mental Model

```
Sending data from New York to Los Angeles:

IP Address = Delivery address on package
            "123 Main St, Los Angeles, CA"
            Never changes during journey

MAC Address = Current truck/carrier
             Truck A → Truck B → Truck C
             Changes at each distribution center

ARP = Looking up "Who's driving truck to this address?"
```

---

### What You Can Do Now

✅ Understand why both MAC and IP exist  
✅ Know how ARP works (IP → MAC translation)  
✅ Identify private vs public IP addresses  
✅ Understand addressing in home networks and AWS  
✅ Know that MAC changes at each hop, IP doesn't  

---

---

## What This Means for the Webstore

The webstore server has one IP address. Every service on that server shares it. What separates them is ports: nginx answers on port 80, the API on port 8080, postgres on port 5432. When the webstore-api connects to postgres, it connects to the server's own IP at port 5432 — not necessarily `localhost`, because postgres is configured with `listen_addresses` that controls which interfaces it binds to. When postgres is set to `127.0.0.1` only, the API can reach it from the same machine. When postgres is set to `0.0.0.0`, it is reachable from any interface including external ones. Reading an IP binding tells you immediately whether a service is reachable from outside or locked to the machine.

---
# TOOL: 03. Networking – Foundations | FILE: 03-ip-deep-dive
---

# File 03: IP Deep Dive & Assignment

[Home](../README.md) |
[Foundation](../01-foundation-and-the-big-picture/README.md) |
[Addressing](../02-addressing-fundamentals/README.md) |
[IP Deep Dive](../03-ip-deep-dive/README.md) |
[Network Devices](../04-network-devices/README.md) |
[Subnets & CIDR](../05-subnets-cidr/README.md) |
[Ports & Transport](../06-ports-transport/README.md) |
[NAT](../07-nat/README.md) |
[DNS](../08-dns/README.md) |
[Firewalls](../09-firewalls/README.md) |
[Complete Journey](../10-complete-journey/README.md)

---

# IP Deep Dive & Assignment

## What this file is about

This file teaches **how devices get IP addresses** and **why your IP keeps changing**. If you understand this, you'll know how DHCP works, the difference between static and dynamic IPs, and when to use each type. This is essential for configuring networks correctly.

<!-- no toc -->
- [The Core Problem](#the-core-problem)
- [IPv4 Address Structure](#ipv4-address-structure)
- [How Do Devices Get IP Addresses?](#how-do-devices-get-ip-addresses)
- [DHCP: Automatic IP Assignment](#dhcp-automatic-ip-assignment)
- [Why Your IP Address Keeps Changing](#why-your-ip-address-keeps-changing)
- [Static vs Dynamic IPs](#static-vs-dynamic-ips)
- [DHCP Reservation (Best of Both Worlds)](#dhcp-reservation-best-of-both-worlds)
- [IPv4 vs IPv6](#ipv4-vs-ipv6)
- [Localhost (127.0.0.1)](#localhost-127001)
- [Real Scenarios](#real-scenarios)  
[Final Compression](#final-compression)

---

## The Core Problem

### Your Original Question

**"Why is my IP address always changing even with the same network?"**

This is the question that confuses most beginners.

**The short answer:**  
Your router has limited IP addresses available and assigns them temporarily using DHCP.

**Let's understand this completely.**

---

### The Scenario

**Your home WiFi network:**

```
Router has 254 usable IP addresses:
  192.168.1.1 - 192.168.1.254

Devices that connect over time:
  Your laptop
  Your phone
  Your tablet
  Guest's laptop
  Guest's phone
  Smart TV
  IoT devices
  ... (maybe 50+ devices over a week)

Problem: More devices than available IPs if all stayed connected
```

**The question:**  
How does the router manage this?

**The answer:**  
DHCP leases IPs temporarily, then reuses them.

---

## IPv4 Address Structure

### The Format

**IPv4 = Internet Protocol version 4**

```
192.168.1.45
│   │   │  │
│   │   │  └─ Host ID (device identifier)
│   │   └──── Network ID
│   └──────── Network ID
└──────────── Network ID

Total: 4 octets (bytes)
Each octet: 0-255
Total bits: 32 bits
```

---

### Understanding the Numbers

**Each octet is 8 bits:**

```
192.168.1.45

192 = 11000000 (binary)
168 = 10101000 (binary)
1   = 00000001 (binary)
45  = 00101101 (binary)

Combined = 32 bits total
```

**You don't need to memorize binary.**  
**Just know:** Each number is 0-255, total is 32 bits.

---

### Total Possible IPv4 Addresses

**Math:**

```
4 octets × 8 bits each = 32 bits total
2^32 = 4,294,967,296 possible addresses

~4.3 billion IPv4 addresses exist
```

**The problem:**

```
World population: ~8 billion people
Devices: ~20+ billion (phones, laptops, IoT, servers)

Not enough IPv4 addresses for every device!
```

**Solutions:**
1. Private IP addresses (reusable, not unique globally)
2. NAT (many devices share one public IP)
3. IPv6 (new protocol with more addresses — covered later)

---

### IP Address Classes (Legacy Concept)

**Old system (before CIDR):**

Networks were divided into classes:

| Class | Range | Default Mask | Use |
|-------|-------|--------------|-----|
| A | 1.0.0.0 - 126.255.255.255 | 255.0.0.0 | Very large networks |
| B | 128.0.0.0 - 191.255.255.255 | 255.255.0.0 | Medium networks |
| C | 192.0.0.0 - 223.255.255.255 | 255.255.255.0 | Small networks |
| D | 224.0.0.0 - 239.255.255.255 | N/A | Multicast |
| E | 240.0.0.0 - 255.255.255.255 | N/A | Reserved |

**This system is obsolete.**  
Modern networks use CIDR (covered in File 05).

**You don't need to memorize classes.**  
Just know they existed historically.

---

## How Do Devices Get IP Addresses?

### Three Methods

**When a device needs an IP address:**

```
Method 1: DHCP (Automatic)
  - Router/server assigns IP automatically
  - Most common for end-user devices
  - IP can change

Method 2: Static (Manual)
  - Administrator configures IP manually
  - Common for servers, printers
  - IP never changes

Method 3: Link-Local (Auto-Assigned)
  - Device assigns itself 169.254.X.X
  - Fallback when DHCP fails
  - Limited functionality
```

**Let's understand each one.**

---

## DHCP: Automatic IP Assignment

### What Is DHCP?

**DHCP = Dynamic Host Configuration Protocol**

**Definition:**  
DHCP is a network service that automatically assigns IP addresses to devices.

**Why it exists:**  
Manually configuring every device doesn't scale.

---

### DHCP Components

**Three parts:**

```
1. DHCP Server
   - Runs on router (home networks)
   - Runs on dedicated server (enterprise)
   - Manages IP address pool

2. DHCP Client
   - Your laptop, phone, etc.
   - Requests IP address
   - Built into operating system

3. IP Address Pool
   - Range of available IPs
   - Example: 192.168.1.100 - 192.168.1.200
   - Server assigns from this pool
```

---

### How DHCP Works (The DORA Process)

**DHCP uses a 4-step process called DORA:**

```
D = Discover
O = Offer
R = Request
A = Acknowledge
```

**Step-by-step:**

---

#### Step 1: DHCP Discover (Broadcast)

**Your laptop boots up and connects to WiFi:**

```
Your laptop (no IP yet):
  "I need an IP address!"
  
Broadcasts DHCP Discover message:
  Source IP:      0.0.0.0 (doesn't have one yet)
  Destination IP: 255.255.255.255 (broadcast - everyone)
  MAC src:        [Your laptop MAC]
  MAC dst:        FF:FF:FF:FF:FF:FF (broadcast)
  
Message: "DHCP DISCOVER - I need an IP!"
```

**Everyone on network receives this, including router.**

---

#### Step 2: DHCP Offer (Unicast)

**Router (DHCP server) responds:**

```
Router checks:
  Available IP pool: 192.168.1.100 - 192.168.1.200
  192.168.1.145 is available
  
Router sends DHCP Offer:
  Source IP:      192.168.1.1 (router)
  Destination IP: 255.255.255.255 (still broadcast)
  MAC dst:        [Your laptop MAC] (unicast at Layer 2)
  
Message: "DHCP OFFER - You can use 192.168.1.145"
```

**Router offers an IP but hasn't assigned it yet.**

---

#### Step 3: DHCP Request (Broadcast)

**Your laptop accepts the offer:**

```
Your laptop:
  "I want to use 192.168.1.145"
  
Sends DHCP Request:
  Source IP:      0.0.0.0 (still doesn't have IP yet)
  Destination IP: 255.255.255.255 (broadcast)
  
Message: "DHCP REQUEST - I accept 192.168.1.145"
```

**Why broadcast?**  
In case multiple DHCP servers offered IPs, this tells all servers which offer was accepted.

---

#### Step 4: DHCP Acknowledge (Unicast)

**Router confirms:**

```
Router:
  Marks 192.168.1.145 as "in use"
  
Sends DHCP ACK:
  Source IP:      192.168.1.1
  Destination IP: 192.168.1.145 (now can use unicast)
  
Message: "DHCP ACK - Configuration confirmed"
  
Includes:
  - IP address:      192.168.1.145
  - Subnet mask:     255.255.255.0
  - Default gateway: 192.168.1.1 (router)
  - DNS server:      8.8.8.8 (or router's IP)
  - Lease time:      86400 seconds (24 hours)
```

**Your laptop now has a working IP configuration.**

---

### Visual: DHCP DORA Process

```
┌──────────────┐                      ┌──────────────┐
│   Laptop     │                      │    Router    │
│ (DHCP Client)│                      │(DHCP Server) │
└──────┬───────┘                      └──────┬───────┘
       │                                     │
       │  1. DISCOVER (broadcast)            │
       │  "I need an IP!"                    │
       ├────────────────────────────────────>│
       │                                     │
       │                                     │ Check pool
       │                                     │ 192.168.1.145 free
       │                                     │
       │  2. OFFER (unicast)                 │
       │  "Use 192.168.1.145"                │
       │<────────────────────────────────────┤
       │                                     │
       │                                     │
       │  3. REQUEST (broadcast)             │
       │  "I accept 192.168.1.145"           │
       ├────────────────────────────────────>│
       │                                     │
       │                                     │ Mark as assigned
       │                                     │
       │  4. ACK (unicast)                   │
       │  "Confirmed + config"               │
       │<────────────────────────────────────┤
       │                                     │
       ▼                                     ▼
  Configured                         IP Pool updated
  192.168.1.145                      145 = In use
```

---

### What DHCP Provides

**DHCP doesn't just give you an IP address.**  
**It provides complete network configuration:**

| Setting | Example | What It Does |
|---------|---------|--------------|
| **IP Address** | 192.168.1.145 | Your device's identity |
| **Subnet Mask** | 255.255.255.0 | Defines network range |
| **Default Gateway** | 192.168.1.1 | Router's IP (exit to internet) |
| **DNS Server** | 8.8.8.8 | Where to resolve domain names |
| **Lease Time** | 86400 seconds | How long IP is valid |

**Check your DHCP-assigned config:**

```bash
# Linux
ip addr show
ip route

# Mac
ipconfig getpacket en0

# Windows
ipconfig /all
```

---

## Why Your IP Address Keeps Changing

### The Lease Concept

**DHCP doesn't give you an IP permanently.**  
**It LEASES it to you for a specific time.**

**Think of it like renting a hotel room:**

```
Hotel (DHCP Server):
  "You can stay in room 145 for 24 hours"

After 24 hours:
  You check out → Room 145 available again
  
You return:
  You might get room 145 again
  Or you might get room 212 (different room)
```

**Same with IP addresses:**

```
Router:
  "Use 192.168.1.145 for 24 hours"

After 24 hours (lease expires):
  IP goes back to available pool
  
You reconnect:
  Might get 192.168.1.145 again
  Or might get 192.168.1.167 (different IP)
```

---

### Typical Lease Times

| Network Type | Typical Lease Time | Why |
|--------------|-------------------|-----|
| **Home WiFi** | 24 hours | Devices come and go daily |
| **Coffee shop** | 1 hour | High turnover of devices |
| **Office** | 8 hours | Users arrive/leave with work schedule |
| **Data center** | 7 days | More stable, fewer changes |

---

### The Complete Lifecycle

**Timeline:**

```
T=0: Connect to WiFi
  DHCP assigns: 192.168.1.145
  Lease: 24 hours

T=12 hours: Lease renewal attempt
  Device: "Can I keep 192.168.1.145?"
  Router: "Yes, renewed for 24 more hours"

T=24 hours: Disconnect
  IP returns to pool

T=26 hours: Reconnect
  DHCP process starts again
  Might get different IP: 192.168.1.178
```

---

### Why Leases Exist

**Problem without leases:**

```
Day 1: 50 devices connect, get IPs
Day 2: 40 of those devices never return
Day 3: Those 40 IPs still "reserved"
Day 4: Run out of IPs even though only 10 devices active
```

**Solution with leases:**

```
Day 1: 50 devices connect, get IPs (24-hour lease)
Day 2: 40 devices don't renew → IPs freed
Day 3: Those 40 IPs available for new devices
Result: Efficient IP usage
```

---

### Lease Renewal Process

**Before lease expires, devices try to renew:**

```
T=50% of lease (12 hours):
  Device: "DHCP REQUEST - Renew my IP?"
  Router: "DHCP ACK - Renewed for 24 hours"
  
If renewal fails:

T=87.5% of lease (21 hours):
  Device: "DHCP REQUEST - Renew my IP?"
  Router: "DHCP ACK - Renewed"
  
If still fails:

T=100% (24 hours):
  Lease expires
  Device loses IP
  Starts DORA process again (might get different IP)
```

**Most of the time, renewal succeeds and you keep the same IP.**

---

## Static vs Dynamic IPs

### Dynamic IP (DHCP-Assigned)

**How it works:**

```
Device: "I need an IP"
DHCP: "Use 192.168.1.145 for 24 hours"
Device uses IP
Lease expires
Process repeats
```

**Characteristics:**

```
✅ Automatic (no configuration needed)
✅ Scales well (reuses IPs)
✅ Easy for users
❌ IP can change
❌ Unpredictable address
```

**When to use:**

```
✅ Laptops, phones, tablets
✅ Guest devices
✅ Home networks
✅ Anything that moves between networks
```

---

### Static IP (Manually Configured)

**How it works:**

```
Administrator configures on device:
  IP:      192.168.1.100
  Mask:    255.255.255.0
  Gateway: 192.168.1.1
  DNS:     8.8.8.8
  
Device uses this IP permanently
Never changes (until manually changed)
```

**Characteristics:**

```
✅ Predictable address
✅ Never changes
✅ Good for servers
❌ Manual configuration required
❌ Risk of IP conflicts
❌ Doesn't scale well
```

**When to use:**

```
✅ Servers (web, database, file)
✅ Network printers
✅ Network infrastructure (routers, switches)
✅ IoT devices (security cameras, etc.)
✅ Production systems
```

---

### Configuration Examples

**Set static IP (Linux):**

```bash
# Ubuntu (netplan)
# Edit: /etc/netplan/01-netcfg.yaml

network:
  version: 2
  ethernets:
    eth0:
      addresses:
        - 192.168.1.100/24
      gateway4: 192.168.1.1
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]

# Apply
sudo netplan apply
```

**Set static IP (Windows):**

```
Control Panel → Network Connections
Right-click adapter → Properties
Internet Protocol Version 4 (TCP/IPv4) → Properties

○ Use the following IP address:
  IP address:         192.168.1.100
  Subnet mask:        255.255.255.0
  Default gateway:    192.168.1.1
  
○ Use the following DNS server addresses:
  Preferred DNS:      8.8.8.8
  Alternate DNS:      8.8.4.4
```

---

### The IP Conflict Problem

**What happens if two devices use the same IP?**

**Scenario:**

```
Device A: Static IP 192.168.1.100 (manually set)
Device B: DHCP assigns 192.168.1.100 (router doesn't know about static)

Result: IP conflict!
```

**Symptoms:**

```
❌ Intermittent connectivity
❌ "IP address conflict" error messages
❌ Network not working randomly
❌ Both devices fighting for same IP
```

**Prevention:**

```
Best practice:
  Split IP range:
  
  DHCP pool:    192.168.1.100 - 192.168.1.200
  Static IPs:   192.168.1.10 - 192.168.1.50
  
  Never overlap!
```

---

## DHCP Reservation (Best of Both Worlds)

### What Is DHCP Reservation?

**Definition:**  
DHCP reservation binds a specific IP address to a specific device's MAC address.

**How it works:**

```
Router configuration:
  "Always give MAC AA:BB:CC:DD:EE:FF the IP 192.168.1.100"
  
Device connects:
  DHCP process runs normally
  But router always assigns 192.168.1.100 to this device
```

**Result:**  
Device gets consistent IP but still uses DHCP.

---

### Benefits

```
✅ Consistent IP address (like static)
✅ Uses DHCP (automatic, no manual device config)
✅ Centrally managed (on router)
✅ Easy to change (update router, not device)
✅ No IP conflicts (router manages everything)
```

---

### When to Use DHCP Reservation

**Perfect for:**

```
✅ Home servers (media server, NAS)
✅ Network printers
✅ Smart home devices
✅ Game consoles (port forwarding rules)
✅ Anything needing consistent IP but benefits from DHCP
```

---

### How to Configure (Example)

**Router admin interface:**

```
1. Find device's MAC address
   - Check router's DHCP client list
   - Or: ipconfig /all (Windows), ip link (Linux)

2. Add reservation:
   MAC Address:    AA:BB:CC:DD:EE:FF
   Reserved IP:    192.168.1.100
   Description:    "Home Server"

3. Save

Device will now always get 192.168.1.100
```

---

### Comparison Table

| Feature | Dynamic (DHCP) | Static (Manual) | DHCP Reservation |
|---------|----------------|-----------------|------------------|
| **IP changes?** | ✅ Yes | ❌ No | ❌ No |
| **Manual config?** | ❌ No | ✅ Yes | ❌ No |
| **Consistent IP?** | ❌ No | ✅ Yes | ✅ Yes |
| **Risk of conflict?** | Low | High | Low |
| **Easy to manage?** | ✅ Yes | ❌ No | ✅ Yes |
| **Best for** | Laptops, phones | Critical servers | Home servers, printers |

---

## IPv4 vs IPv6

### The Address Exhaustion Problem

**IPv4:**

```
Total addresses: 4.3 billion
Problem: We ran out around 2011
```

**Why we ran out:**

```
World population: 8 billion
Devices per person: 3-5 (phone, laptop, tablet, IoT)
Total devices: 20+ billion

4.3 billion < 20 billion → Not enough!
```

---

### IPv6: The Solution

**IPv6 = Internet Protocol version 6**

**Key differences:**

| Feature | IPv4 | IPv6 |
|---------|------|------|
| **Address length** | 32 bits | 128 bits |
| **Format** | 192.168.1.45 | 2001:0db8:85a3::8a2e:0370:7334 |
| **Total addresses** | ~4.3 billion | 340 undecillion (340 × 10³⁶) |
| **Notation** | Decimal | Hexadecimal |

---

### IPv6 Address Example

```
2001:0db8:85a3:0000:0000:8a2e:0370:7334
│    │    │    │    │    │    │    │
8 groups of 4 hexadecimal digits
Separated by colons
128 bits total

Abbreviation rules:
- Leading zeros can be omitted: 0db8 → db8
- Consecutive groups of zeros can be replaced with ::
  
Abbreviated:
2001:db8:85a3::8a2e:370:7334
```

---

### Why IPv6 Matters (But Not Urgently for DevOps)

**Current reality:**

```
IPv4: Still dominant (~90% of internet traffic)
IPv6: Growing but slow adoption

Most cloud providers support both:
  AWS EC2: Gets both IPv4 and IPv6
  Most home routers: IPv4 only or dual-stack
```

**For DevOps beginners:**

```
Focus on IPv4 first (this series)
IPv6 works similarly (same concepts)
Learn IPv6 when needed (usually not immediately)
```

**You don't need to master IPv6 right now.**

---

## Localhost (127.0.0.1)

### What Is Localhost?

**Definition:**  
Localhost is a special IP address that always refers to "this device I'm currently on."

**The address:**

```
IPv4: 127.0.0.1
IPv6: ::1

Both mean: "This machine"
```

---

### How Localhost Works

**Localhost never leaves your device:**

```
Application sends to 127.0.0.1
  ↓
Operating system intercepts
  ↓
Delivers back to same device
  ↓
Never touches network card
  ↓
Never leaves computer
```

**It's a loopback — traffic circles back immediately.**

---

### Critical Understanding

**Localhost is RELATIVE, not absolute:**

| Where You Are | What 127.0.0.1 Means |
|---------------|---------------------|
| **Your laptop** | Your laptop |
| **Docker container** | That specific container |
| **AWS EC2 instance** | That EC2 instance |
| **Virtual machine** | That VM |

**The Common Docker mistake:**

```
Docker container runs web server on port 3000

❌ Wrong thinking:
  "Server runs on localhost:3000"
  "I can access it at localhost:3000 on my laptop"

✅ Correct:
  "Server runs on localhost:3000 INSIDE container"
  "Container's localhost ≠ Host's localhost"
  "Need port binding: docker run -p 3000:3000"
```

> **Docker implementation:** The localhost trap and IP assignment behavior inside containers is covered in full with hands-on examples in the Docker notes.
> → [Docker Networking](../../04.%20Docker%20–%20Containerization/05-docker-networking/README.md)

---

### The Entire Loopback Range

**Reserved range:**

```
127.0.0.0 - 127.255.255.255 (127.0.0.0/8)

All of these are loopback:
  127.0.0.1    ← Most common
  127.0.0.2
  127.1.1.1
  127.255.255.254

All mean "this device"
```

**In practice, everyone uses 127.0.0.1.**

---

### When to Use Localhost

**Common scenarios:**

```
✅ Testing web apps locally
   http://localhost:3000

✅ Database connections on same machine
   mysql://localhost:3306

✅ Development servers
   localhost:8080

✅ Localhost-only services (security)
   Bind to 127.0.0.1 → only accessible locally
```

---

## Real Scenarios

### Scenario 1: Home Network

**Setup:**

```
Router: 192.168.1.1
DHCP Pool: 192.168.1.100 - 192.168.1.200
Static range: 192.168.1.10 - 192.168.1.50
```

**Devices:**

```
Your laptop (Dynamic):
  Connects → DHCP assigns 192.168.1.145
  Disconnects → IP returns to pool
  Reconnects → Might get 192.168.1.178

Home server (DHCP Reservation):
  MAC: AA:BB:CC:DD:EE:FF
  Always gets: 192.168.1.100
  Runs Plex, accessible at: http://192.168.1.100:32400

Network printer (Static):
  Manually configured: 192.168.1.10
  Never changes
  Everyone prints to: 192.168.1.10
```

---

### Scenario 2: AWS VPC

**VPC setup:**

```
VPC CIDR: 10.0.0.0/16

Public Subnet: 10.0.1.0/24
├─ Web Server 1: 10.0.1.10 (static private IP)
├─ Web Server 2: 10.0.1.20 (static private IP)
└─ NAT Gateway:  10.0.1.100

Private Subnet: 10.0.2.0/24
├─ App Server 1: 10.0.2.10 (static private IP)
├─ App Server 2: 10.0.2.20 (static private IP)
└─ RDS Database: 10.0.2.50 (static private IP)
```

**Why static IPs in AWS?**

```
✅ Security group rules reference IPs
✅ Application config uses IPs
✅ Load balancer targets use IPs
✅ Predictable addressing
✅ No DHCP lease expiration issues
```

**How they're assigned:**

```
Not DHCP — AWS assigns when instance launches
Private IP stays same for life of instance
Can be manually specified or auto-assigned
```

---

## Final Compression

### How Devices Get IPs

**Three methods:**

```
1. DHCP (Dynamic)
   - Automatic assignment
   - IP can change
   - Best for: Laptops, phones, guests

2. Static (Manual)
   - Administrator configures
   - IP never changes
   - Best for: Servers, infrastructure

3. DHCP Reservation
   - DHCP but consistent IP
   - Best of both worlds
   - Best for: Printers, home servers
```

---

### Why IPs Change (DHCP Leases)

**The process:**

```
1. Connect → DHCP assigns IP for X hours
2. Disconnect → IP returns to pool
3. Reconnect → Might get different IP

Why?
  Limited IPs, many devices, efficient reuse
```

---

### DHCP DORA Process

```
D = Discover   (Client: "I need an IP")
O = Offer      (Server: "Use this IP")
R = Request    (Client: "I accept")
A = Acknowledge (Server: "Confirmed")

Result: Device has IP + subnet + gateway + DNS
```

---

### Static vs Dynamic Decision Tree

```
Is it a server? → Static or DHCP Reservation
Does it move between networks? → DHCP
Does it need predictable address? → Static or Reservation
Is it a temporary device? → DHCP
```

---

### Key Facts

```
✅ IPv4 = 32 bits, 4.3 billion addresses
✅ DHCP provides: IP, mask, gateway, DNS, lease time
✅ Lease = temporary assignment, then reclaimed
✅ Static = manual, never changes
✅ Reservation = DHCP + consistent IP
✅ Localhost (127.0.0.1) = this device only
✅ IPv6 exists but IPv4 still dominant
```

---

### Mental Model

```
DHCP = Hotel
  Check in:  Get room number (IP) for X days (lease)
  Check out: Room available for others
  Return:    Might get different room

Static IP = Owning a house
  Same address forever
  You manage it

DHCP Reservation = Reserved hotel room
  Same room every time
  But hotel manages it
```

---

### What You Can Do Now

✅ Understand why your IP changes (DHCP leases)  
✅ Know when to use static vs dynamic IPs  
✅ Understand DHCP DORA process  
✅ Configure static IPs when needed  
✅ Use DHCP reservations for consistent IPs  
✅ Understand localhost (127.0.0.1)  

---

---

## What This Means for the Webstore

Postgres on the webstore server is configured with `listen_addresses` in `postgresql.conf`. If it is set to `localhost`, only processes on the same machine can connect — correct for a production server where the API runs locally. If it is set to `*` or the server's IP, processes on other machines can connect — necessary when the API and database run on separate servers. This is not a code change. It is an IP binding decision. Understanding that `127.0.0.1` means this machine only and `0.0.0.0` means all interfaces is what lets you read a database config file and immediately know whether it is reachable from outside. The webstore's nginx is bound to `0.0.0.0:80` — it must be, to serve browsers. Postgres is bound to `127.0.0.1:5432` — it must be, to block direct external access.

→ Ready to practice? [Go to Lab 01](../networking-labs/01-foundation-addressing-ip-lab.md)

---
# TOOL: 03. Networking – Foundations | FILE: 04-network-devices
---

# File 04: Network Devices

[Home](../README.md) |
[Foundation](../01-foundation-and-the-big-picture/README.md) |
[Addressing](../02-addressing-fundamentals/README.md) |
[IP Deep Dive](../03-ip-deep-dive/README.md) |
[Network Devices](../04-network-devices/README.md) |
[Subnets & CIDR](../05-subnets-cidr/README.md) |
[Ports & Transport](../06-ports-transport/README.md) |
[NAT](../07-nat/README.md) |
[DNS](../08-dns/README.md) |
[Firewalls](../09-firewalls/README.md) |
[Complete Journey](../10-complete-journey/README.md)

---

# Network Devices

## What this file is about

This file teaches **how traffic moves between devices and networks**. If you understand this, you'll know when devices can talk directly (switch), when they need routing (router), and how to configure the path traffic takes (default gateway). This is essential for understanding network topology and troubleshooting connectivity.

<!-- no toc -->
- [The Core Problem](#the-core-problem)
- [LAN vs WAN (Network Scope)](#lan-vs-wan-network-scope)
- [Switch (Layer 2 - Local Delivery)](#switch-layer-2---local-delivery)
- [Router (Layer 3 - Network Connector)](#router-layer-3---network-connector)
- [Default Gateway (The Exit Door)](#default-gateway-the-exit-door)
- [Switch vs Router (The Critical Difference)](#switch-vs-router-the-critical-difference)
- [Routing Tables (How Routers Decide)](#routing-tables-how-routers-decide)
- [Hub (Legacy - Don't Use)](#hub-legacy---dont-use)
- [Real Scenarios](#real-scenarios)  
[Final Compression](#final-compression)

---

## The Core Problem

### The Question

**Scenario 1:** Your laptop wants to send a file to a printer in the same room.

**Scenario 2:** Your laptop wants to access google.com (different city, different country).

**The question:**  
How does your laptop know whether to:
- Send data directly to the destination?
- Send data to a router for forwarding?

**This is the fundamental routing decision.**

---

### The Real-World Analogy

**Sending mail:**

```
Scenario 1: Give letter to neighbor
  Action: Walk to their door directly
  No post office needed

Scenario 2: Send letter to another country
  Action: Give to post office
  Post office handles forwarding
```

**Sending data:**

```
Scenario 1: Printer in same network
  Action: Send directly via switch
  No router needed

Scenario 2: Google server in another network
  Action: Send to router (default gateway)
  Router handles forwarding
```

**The device must make this decision for every packet.**

---

## LAN vs WAN (Network Scope)

### Local Area Network (LAN)

**Definition:**  
A network where all devices can communicate directly without routing.

**Characteristics:**

```
✅ Same physical location (building, floor, room)
✅ Direct communication (no router needed)
✅ High speed (Gigabit ethernet common)
✅ Low latency (<1ms)
✅ Private ownership (you control it)
```

**Examples:**

```
Your home WiFi:        192.168.1.0/24
Office floor:          10.0.5.0/24
AWS VPC subnet:        10.0.1.0/24
```

---

### Wide Area Network (WAN)

**Definition:**  
A network spanning large geographic areas, connecting multiple LANs.

**Characteristics:**

```
✅ Large geographic scope (cities, countries, continents)
✅ Requires routing (multiple routers)
✅ Lower speed (depends on connection)
✅ Higher latency (10-100ms or more)
✅ Often uses public infrastructure
```

**Examples:**

```
The Internet:           Global WAN
Corporate WAN:          Connects office branches
ISP network:            Connects customers to internet
AWS VPC peering:        Connects VPCs in different regions
```

---

### The Key Difference

```
┌─────────────────────────────────────────┐
│  LAN (Local Area Network)               │
│                                         │
│  [Laptop] ←→ [Printer] ←→ [Desktop]     │
│      │          │            │          │
│      └──────[Switch]─────────┘          │
│                                         │
│  All devices talk directly              │
│  No router needed                       │
└─────────────────────────────────────────┘

         vs

┌─────────────────────────────────────────┐
│  WAN (Wide Area Network)                │
│                                         │
│  [Your LAN] ←→ [Router] ←→ [Router] ... │
│                   ↕                     │
│              [Internet]                 │
│                   ↕                     │
│              [Router] ←→ [Google's LAN] │
│                                         │
│  Multiple LANs connected by routers     │
└─────────────────────────────────────────┘
```

---

### How Your Device Knows (Subnet Mask)

**Your device checks:**

```
My IP:           192.168.1.45
Subnet mask:     255.255.255.0
Target IP:       192.168.1.50

Calculation:
  My network:     192.168.1.0
  Target network: 192.168.1.0
  
Match? YES → Same LAN → Send directly

Target IP:       142.250.190.46 (Google)

Calculation:
  My network:     192.168.1.0
  Target network: 142.250.190.0
  
Match? NO → Different network → Send to router
```

**The subnet mask determines local vs remote.**  
(Covered in detail in File 05)

---

## Switch (Layer 2 - Local Delivery)

### What Is a Switch?

**Definition:**  
A network device that connects multiple devices in a LAN and forwards data based on MAC addresses.

**Layer:** Layer 2 (Data Link)

**Job:** Deliver frames to the correct device on the local network.

---

### How a Switch Works

**Physical setup:**

```
         [Switch]
            ╱ │ ╲
           ╱  │  ╲
          ╱   │   ╲
    [Laptop] [Desktop] [Printer]
```

**MAC address table (learned automatically):**

| MAC Address | Port | Learned |
|-------------|------|---------|
| AA:BB:CC:DD:EE:FF | Port 1 | Laptop |
| 11:22:33:44:55:66 | Port 2 | Desktop |
| F8:1A:67:B4:32:D1 | Port 3 | Printer |

---

### Switch Operation (Step by Step)

**Scenario:** Laptop sends file to printer

**Step 1: Laptop creates frame**

```
Ethernet Frame:
  Source MAC:      AA:BB:CC:DD:EE:FF (laptop)
  Destination MAC: F8:1A:67:B4:32:D1 (printer)
  Payload:         File data
```

**Step 2: Frame arrives at switch**

```
Switch receives frame on Port 1
Reads destination MAC: F8:1A:67:B4:32:D1
```

**Step 3: Switch checks MAC table**

```
MAC table lookup:
  F8:1A:67:B4:32:D1 → Port 3

Decision: Forward to Port 3 only
```

**Step 4: Switch forwards**

```
Frame sent out Port 3 → Printer receives it
Ports 2, 4, 5, etc. see nothing (efficient!)
```

---

### MAC Address Learning

**How switch builds MAC table:**

**Initial state (switch just powered on):**

```
MAC Table: Empty
```

**Laptop sends first frame:**

```
Frame arrives on Port 1
Source MAC: AA:BB:CC:DD:EE:FF

Switch learns:
  "AA:BB:CC:DD:EE:FF is on Port 1"
  
MAC Table:
  AA:BB:CC:DD:EE:FF → Port 1
```

**Destination MAC not in table:**

```
Switch doesn't know where printer is yet

Action: Flood
  Send frame to ALL ports except incoming port
  (Ports 2, 3, 4, 5 all receive the frame)
```

**Printer responds:**

```
Response frame arrives on Port 3
Source MAC: F8:1A:67:B4:32:D1

Switch learns:
  "F8:1A:67:B4:32:D1 is on Port 3"
  
MAC Table:
  AA:BB:CC:DD:EE:FF → Port 1
  F8:1A:67:B4:32:D1 → Port 3
```

**Future communication:**

```
Switch now knows both MACs
Forwards frames directly to correct ports
No flooding needed
```

---

### Switch Characteristics

```
✅ Operates at Layer 2 (Data Link)
✅ Uses MAC addresses
✅ Learns device locations automatically
✅ Forwards only to destination port (efficient)
✅ Multiple devices can communicate simultaneously
✅ Works within one network only (no routing)
❌ Cannot connect different networks
❌ Cannot route based on IP addresses
```

---

### Types of Switches

| Type | Description | Use Case |
|------|-------------|----------|
| **Unmanaged** | Plug-and-play, no configuration | Home, small office |
| **Managed** | Configurable (VLANs, QoS, monitoring) | Enterprise, data center |
| **Layer 3 Switch** | Can also route (switch + router hybrid) | Data center core |

**For most purposes:** Switch = Layer 2 device using MAC addresses.

---

## Router (Layer 3 - Network Connector)

### What Is a Router?

**Definition:**  
A network device that forwards packets between different networks based on IP addresses.

**Layer:** Layer 3 (Network)

**Job:** Connect different networks and route packets to their destination.

---

### Key Characteristic: Multiple IP Addresses

**A router has AT LEAST 2 network interfaces:**

```
┌─────────────────────────────────────┐
│           Router                    │
│                                     │
│  Interface 1 (LAN):                 │
│    IP:  192.168.1.1                 │
│    MAC: AA:BB:CC:DD:EE:FF           │
│    Connected to: Your home network  │
│                                     │
│  Interface 2 (WAN):                 │
│    IP:  203.45.67.89                │
│    MAC: 11:22:33:44:55:66           │
│    Connected to: ISP network        │
│                                     │
└─────────────────────────────────────┘

One foot in each network
```

**This is what makes routing possible.**

---

### How a Router Works

**Scenario:** Your laptop (192.168.1.45) accesses Google (142.250.190.46)

**Step 1: Laptop checks subnet**

```
My IP:     192.168.1.45
My mask:   255.255.255.0
Target:    142.250.190.46

Same network? NO
Action: Send to default gateway (router)
```

**Step 2: Laptop sends to router**

```
Ethernet Frame:
  Source MAC:      [Laptop MAC]
  Destination MAC: [Router LAN MAC]  ← Router, not Google!
  
IP Packet inside:
  Source IP:       192.168.1.45
  Destination IP:  142.250.190.46    ← Google
```

**Step 3: Router receives packet**

```
Router LAN interface receives frame
Checks destination MAC: "This is for me"
Strips Ethernet frame (de-encapsulation)
Reads IP header
  Destination: 142.250.190.46 → "Not for me, forward it"
```

**Step 4: Router checks routing table**

```
Routing table lookup:
  142.250.190.46 → Not directly connected
  Default route: 0.0.0.0/0 → WAN interface
  
Decision: Forward via WAN interface to ISP
```

**Step 5: Router forwards packet**

```
Creates NEW Ethernet frame:
  Source MAC:      [Router WAN MAC]
  Destination MAC: [ISP Router MAC]
  
IP Packet (same):
  Source IP:       192.168.1.45
  Destination IP:  142.250.190.46

Sends via WAN interface
```

**Key insight:** Router changed MAC addresses but kept IP addresses.

---

### What Routers Do

**Core functions:**

```
1. Packet forwarding
   - Read destination IP
   - Check routing table
   - Forward to next hop

2. Network separation
   - Connects different networks
   - Each interface on different network

3. NAT (Network Address Translation)
   - Converts private IPs to public IPs
   - Covered in File 07

4. Firewall
   - Block/allow traffic based on rules
   - Covered in File 09
```

---

### Router Characteristics

```
✅ Operates at Layer 3 (Network)
✅ Uses IP addresses
✅ Connects different networks
✅ Makes routing decisions
✅ Has multiple network interfaces
✅ Maintains routing table
❌ Slower than switches (more processing)
❌ Each interface is a separate network
```

---

## Default Gateway (The Exit Door)

### What Is a Default Gateway?

**Definition:**  
The IP address of the router on your local network — the "door out" to other networks.

**Simple rule:**

```
If destination is local → send directly
If destination is remote → send to default gateway
```

---

### How Default Gateway Works

**Your network configuration:**

```
IP Address:       192.168.1.45
Subnet Mask:      255.255.255.0
Default Gateway:  192.168.1.1  ← Router's IP on your LAN
```

**Decision process:**

```
┌─────────────────────────────────────┐
│  Want to send to: X.X.X.X           │
└──────────────┬──────────────────────┘
               │
               ▼
      ┌────────────────────┐
      │ Is X.X.X.X in my   │
      │ subnet?            │
      └────────┬───────────┘
               │
       ┌───────┴────────┐
       │                │
      YES              NO
       │                │
       ▼                ▼
┌────────────┐   ┌──────────────────┐
│Send direct │   │Send to gateway   │
│via switch  │   │(192.168.1.1)     │
└────────────┘   └──────────────────┘
```

---

### Real Example

**Your laptop configuration:**

```
IP:      192.168.1.45
Mask:    255.255.255.0
Gateway: 192.168.1.1
```

**Scenario 1: Print to local printer (192.168.1.50)**

```
Check: Is 192.168.1.50 in my subnet?
  My network:     192.168.1.0/24
  Target network: 192.168.1.0/24
  Match: YES

Action: Send directly
  ARP for 192.168.1.50's MAC
  Send frame directly to printer
  No router involved
```

**Scenario 2: Access google.com (142.250.190.46)**

```
Check: Is 142.250.190.46 in my subnet?
  My network:     192.168.1.0/24
  Target network: 142.250.190.0/24
  Match: NO

Action: Send to default gateway
  ARP for 192.168.1.1's MAC (already cached)
  Send frame to router
  Router forwards to internet
```

---

### Multiple Routes vs Default Route

**Routing table on your laptop:**

```
Destination      Gateway         Interface
192.168.1.0/24   0.0.0.0         eth0        (direct - local)
0.0.0.0/0        192.168.1.1     eth0        (default - everything else)
```

**Reading this table:**

```
Rule 1: 192.168.1.0/24 → 0.0.0.0 (direct)
  "Anything in 192.168.1.X goes directly"
  
Rule 2: 0.0.0.0/0 → 192.168.1.1 (default gateway)
  "Everything else goes to router"
```

**How it's used:**

```
Target: 192.168.1.50
  Matches Rule 1 → Send direct

Target: 8.8.8.8
  Doesn't match Rule 1
  Falls through to Rule 2 → Send to 192.168.1.1
```

---

### Default Gateway in Different Environments

**Home network:**

```
Your devices:    192.168.1.45, 192.168.1.67
Default gateway: 192.168.1.1 (home router)
```

**AWS VPC:**

```
EC2 in subnet 10.0.1.0/24:
  Private IP: 10.0.1.50
  Default gateway: 10.0.1.1 (VPC router)
```

**Office network:**

```
Your laptop: 10.0.5.100
Default gateway: 10.0.5.1 (office router)
```

---

### Check Your Default Gateway

**Linux/Mac:**

```bash
ip route
# or
netstat -rn

Output:
default via 192.168.1.1 dev eth0
         ↑
    Default gateway
```

**Windows:**

```cmd
ipconfig

Output:
Default Gateway: 192.168.1.1
```

---

### Common Issue: Wrong Default Gateway

**Symptom:**

```
Can ping devices on local network ✅
Cannot reach internet ❌
```

**Diagnosis:**

```bash
# Check default gateway
ip route

# Test if gateway is reachable
ping 192.168.1.1

If gateway unreachable → Misconfigured or router down
If gateway reachable but no internet → Router or ISP issue
```

**Fix:**

```
Verify gateway IP is correct
Should be router's IP on your subnet
Usually ends in .1 (192.168.1.1, 10.0.0.1, etc.)
```

---

## Switch vs Router (The Critical Difference)

### Side-by-Side Comparison

| Feature | Switch | Router |
|---------|--------|--------|
| **Layer** | Layer 2 (Data Link) | Layer 3 (Network) |
| **Uses** | MAC addresses | IP addresses |
| **Forwards based on** | MAC table | Routing table |
| **Connects** | Devices in same network | Different networks |
| **Number of networks** | 1 | 2+ |
| **Intelligence** | Simple forwarding | Routing decisions |
| **Speed** | Very fast | Slower (more processing) |
| **Example** | Office switch connecting computers | Home router connecting to internet |

---

### When to Use What

**Use a switch when:**

```
✅ Connecting devices in same network
✅ Need more ports (router has 4, need 24)
✅ All devices on same subnet
✅ High-speed local connections
```

**Use a router when:**

```
✅ Connecting different networks
✅ Need to reach internet
✅ Connecting office branches
✅ Separating networks (security, performance)
```

**Often used together:**

```
Internet
   ↓
Router (connects to ISP)
   ↓
Switch (connects local devices)
   ├─ Computer 1
   ├─ Computer 2
   ├─ Printer
   └─ Server
```

---

## Routing Tables (How Routers Decide)

### What Is a Routing Table?

**Definition:**  
A table that tells the router where to send packets based on destination IP.

**Format:**

```
Destination Network | Next Hop | Interface | Metric
```

---

### Example Routing Table

**Home router:**

```
Destination      Next Hop      Interface   Metric
192.168.1.0/24   0.0.0.0       eth0 (LAN)  0        (directly connected)
0.0.0.0/0        203.45.67.1   eth1 (WAN)  1        (default route via ISP)
```

**Reading this:**

```
Row 1: Traffic to 192.168.1.0/24
  Next hop: 0.0.0.0 (means "deliver directly")
  Interface: eth0 (LAN port)
  
Row 2: Traffic to anywhere else (0.0.0.0/0)
  Next hop: 203.45.67.1 (ISP router)
  Interface: eth1 (WAN port)
```

---

### How Routing Decisions Are Made

**Packet arrives with destination: 192.168.1.50**

```
Step 1: Check routing table (most specific first)
  Does 192.168.1.50 match 192.168.1.0/24? YES
  
Step 2: Use that route
  Next hop: 0.0.0.0 (direct)
  Interface: eth0
  
Step 3: Forward
  Send out eth0 interface directly
```

**Packet arrives with destination: 8.8.8.8**

```
Step 1: Check routing table
  Does 8.8.8.8 match 192.168.1.0/24? NO
  
Step 2: Check default route
  Does 8.8.8.8 match 0.0.0.0/0? YES (matches everything)
  
Step 3: Use default route
  Next hop: 203.45.67.1 (ISP router)
  Interface: eth1
  
Step 4: Forward
  Send to ISP router via eth1
```

---

### View Routing Table

**Linux/Mac:**

```bash
# View routing table
ip route
# or
netstat -rn

Output:
default via 192.168.1.1 dev eth0
192.168.1.0/24 dev eth0 proto kernel scope link src 192.168.1.45
```

**Windows:**

```cmd
route print
```

---

### Static vs Dynamic Routing

**Static routing:**

```
Administrator manually configures routes
Routes don't change unless manually updated

Good for:
  Small networks
  Predictable topology
  
Example:
  ip route add 10.0.2.0/24 via 192.168.1.254
```

**Dynamic routing:**

```
Routers share routes automatically
Routes update if topology changes

Protocols: RIP, OSPF, BGP
Good for:
  Large networks
  Redundant paths
```

**For DevOps beginners:**  
Focus on understanding static routes and default routes.

---

## Hub (Legacy - Don't Use)

### What Is a Hub?

**Definition:**  
An obsolete device that broadcasts data to all connected devices.

**Why mentioning it:**  
You might see it in old documentation or legacy networks.

---

### Hub vs Switch

| Feature | Hub | Switch |
|---------|-----|--------|
| **Intelligence** | None (broadcasts everything) | Smart (learns MACs) |
| **Efficiency** | Low (wastes bandwidth) | High (targeted forwarding) |
| **Speed** | Slow (collisions) | Fast |
| **Use today** | ❌ Obsolete | ✅ Standard |

**Hubs are dead. Always use switches.**

---

## Real Scenarios

### Scenario 1: Home Network

```
┌────────────────────────────────────────────┐
│           Home Network                     │
│                                            │
│  [Laptop]  [Phone]  [Smart TV]  [Printer]  │
│     │         │         │           │      │
│     └─────────┼─────────┼───────────┘      │
│               │         │                  │
│          [WiFi Router]──┘                  │
│       (Switch + Router combo)              │
│                                            │
│  LAN side:  192.168.1.1                    │
│  Subnet:    192.168.1.0/24                 │
└──────────────┬─────────────────────────────┘
               │ (Cable to ISP)
               ▼
          [Internet]
```

---

### Scenario 2: Office Network

```
┌──────────────────────────────────────────────┐
│         Office Floor (10.0.5.0/24)           │
│                                              │
│  [PC1]  [PC2]  [PC3]  ...  [PC50]  [Printer] │
│    │      │      │            │        │     │
│    └──────┴──────┴────────────┴────────┘     │
│                   │                          │
│            [24-port Switch]                  │
│                   │                          │
└───────────────────┼──────────────────────────┘
                    │
                    ▼
               [Router]
            10.0.5.1 (LAN)
            203.10.20.30 (WAN)
                    │
                    ▼
              [Internet]
```

---

### Scenario 3: AWS VPC

```
┌──────────────────────────────────────────────┐
│  VPC: 10.0.0.0/16                            │
│                                              │
│  ┌──────────────────────────────────────┐    │
│  │ Public Subnet: 10.0.1.0/24           │    │
│  │                                      │    │
│  │  [Web1]  [Web2]  [Load Balancer]     │    │
│  │  .10     .20     .100                │    │
│  │                                      │    │
│  └──────────────┬───────────────────────┘    │
│                 │                            │
│                 │ VPC Router (implicit)      │
│                 │                            │
│  ┌──────────────┴───────────────────────┐    │
│  │ Private Subnet: 10.0.2.0/24          │    │
│  │                                      │    │
│  │  [App1]  [App2]  [Database]          │    │
│  │  .10     .20     .50                 │    │
│  │                                      │    │
│  └──────────────────────────────────────┘    │
│                                              │
└──────────────────┬───────────────────────────┘
                   │
            [Internet Gateway]
                   │
              [Internet]
```

> **Docker implementation:** Docker uses the same switching and routing concepts internally — a bridge acts as the virtual switch, containers get their own IPs, and the Docker bridge acts as the default gateway. Multiple networks work exactly like multiple VPC subnets.
> → [Docker Networking](../../04.%20Docker%20–%20Containerization/05-docker-networking/README.md)

---

## Final Compression

### Network Scope

```
LAN (Local Area Network):
  Same location, direct communication
  No routing needed

WAN (Wide Area Network):
  Large geographic area, multiple LANs
  Routing required
```

---

### The Devices

**Switch (Layer 2):**
```
✅ Connects devices in same network
✅ Uses MAC addresses
✅ Fast, efficient
✅ One network only

Job: Local delivery within LAN
```

**Router (Layer 3):**
```
✅ Connects different networks
✅ Uses IP addresses
✅ Makes routing decisions
✅ Multiple network interfaces

Job: Forward packets between networks
```

---

### Default Gateway

**Definition:** Router's IP on your local network

**Purpose:** Exit door to other networks

**Decision rule:**
```
Destination in my subnet? → Send directly (switch)
Destination outside my subnet? → Send to gateway (router)
```

---

### Switch vs Router Summary

```
Same network? → Switch
  - Uses MAC
  - Fast
  - No routing

Different networks? → Router
  - Uses IP
  - Routing decisions
  - Connects networks
```

---

### Mental Model

```
Switch = Postal worker inside building
  Delivers mail to correct apartment
  Knows everyone on this floor
  Doesn't leave building

Router = International postal service
  Connects different buildings/cities
  Makes decisions about best path
  Forwards between networks

Default Gateway = Building exit
  Where you go to leave the building
```

---

### What You Can Do Now

✅ Understand when direct communication works (same LAN)  
✅ Know when routing is needed (different networks)  
✅ Understand switch operation (MAC table, forwarding)  
✅ Understand router operation (routing table, multiple networks)  
✅ Configure default gateway correctly  
✅ Read and understand routing tables  

---

---

## What This Means for the Webstore

The webstore server sits behind a router. When a request arrives from a browser in another city, it has been forwarded by 10-20 routers on the way — each one reading only the destination IP, making a routing decision, and passing the packet to the next hop. The MAC address on the packet changed at every single one of those hops. The destination IP never changed. When you run `traceroute` to the webstore server, you are watching those router hops and their latencies in real time. A latency spike at hop 8 means that is where the delay is introduced — not at your server, not in your application code.

→ Ready to practice? [Go to Lab 02](../networking-labs/02-devices-subnets-lab.md)

---
# TOOL: 03. Networking – Foundations | FILE: 05-subnets-cidr
---

# File 05: Network Segmentation (Subnets & CIDR)

[Home](../README.md) |
[Foundation](../01-foundation-and-the-big-picture/README.md) |
[Addressing](../02-addressing-fundamentals/README.md) |
[IP Deep Dive](../03-ip-deep-dive/README.md) |
[Network Devices](../04-network-devices/README.md) |
[Subnets & CIDR](../05-subnets-cidr/README.md) |
[Ports & Transport](../06-ports-transport/README.md) |
[NAT](../07-nat/README.md) |
[DNS](../08-dns/README.md) |
[Firewalls](../09-firewalls/README.md) |
[Complete Journey](../10-complete-journey/README.md)

---

# Network Segmentation (Subnets & CIDR)

## What this file is about

This file teaches **how to divide networks into smaller segments** and **how to read CIDR notation**. If you understand this, you'll be able to calculate how many IPs are available in any block and design networks that don't conflict. This is the universal foundation — how CIDR applies specifically to AWS VPCs is covered in the AWS notes.

<!-- no toc -->
- [The Core Problem](#the-core-problem)
- [Why Subnets Exist](#why-subnets-exist)
- [Subnet Masks (The Divider)](#subnet-masks-the-divider)
- [CIDR Notation (The Shorthand)](#cidr-notation-the-shorthand)
- [Calculating Available IPs](#calculating-available-ips)
- [Common CIDR Blocks (Memorize These)](#common-cidr-blocks-memorize-these)
- [Subnet Planning Rules](#subnet-planning-rules)
- [Subnetting Practice](#subnetting-practice)
[Final Compression](#final-compression)

---

## The Core Problem

### The Question

**Scenario:** You're setting up a network for a company.

**Requirements:**
- Web servers (need 50 IPs)
- Application servers (need 100 IPs)
- Databases (need 10 IPs)
- Each group should be isolated for security

**Questions:**
1. How do you divide the network?
2. How many IPs do you need total?
3. How do you prevent IP conflicts?
4. How do you ensure room for growth?

**This is what subnetting solves.**

---

### Why You Can't Just Use One Big Network

**Without subnetting (all devices in 192.168.1.0/24):**

```
Problems:
❌ Can't isolate web servers from databases (security risk)
❌ Can't apply different firewall rules to different groups
❌ Broadcast storms (everyone sees everyone's traffic)
❌ Difficult to manage (254 devices in one flat network)
❌ No logical organization
```

**With subnetting (divided logically):**

```
Benefits:
✅ Web servers:  10.0.1.0/24 (isolated)
✅ App servers:  10.0.2.0/24 (isolated)
✅ Databases:    10.0.3.0/24 (isolated)
✅ Different firewall rules per subnet
✅ Better performance (smaller broadcast domains)
✅ Organized and manageable
```

---

## Why Subnets Exist

### The Historical Context

**You now understand routers** (from File 04).

**Key insight from that file:**
- Routers separate networks
- Each router interface is on a different network
- Devices on different networks need a router to communicate

**Subnets exist BECAUSE routers exist.**

---

### Subnets Create Network Boundaries

**One large network (no subnetting):**

```
Company network: 10.0.0.0/16 (65,534 hosts)
All departments share one network

Problems:
- No isolation
- Single broadcast domain (inefficient)
- Can't apply per-department security rules
```

**Multiple subnets (segmented):**

```
Company network: 10.0.0.0/16

Subnet 1 (Marketing):    10.0.1.0/24  (254 hosts)
Subnet 2 (Engineering):  10.0.2.0/24  (254 hosts)
Subnet 3 (Finance):      10.0.3.0/24  (254 hosts)
Subnet 4 (HR):           10.0.4.0/24  (254 hosts)

Benefits:
- Departments isolated
- Different firewall rules per department
- Better performance
- Easier troubleshooting
```

---

### The Four Reasons Subnets Exist

```
1. Security / Isolation
   Separate sensitive systems from others

2. Organization
   Logical grouping of devices

3. Performance
   Smaller broadcast domains

4. Address Management
   Efficient use of IP space
```

---

## Subnet Masks (The Divider)

### What Is a Subnet Mask?

**Definition:**  
A subnet mask defines which part of an IP address is the network portion and which part is the host portion.

**Purpose:**  
Tells your device: "These IPs are local (same network), everything else is remote (need router)."

---

### How Subnet Masks Work

**Example IP and mask:**

```
IP Address:   192.168.1.45
Subnet Mask:  255.255.255.0
```

**What this means:**

```
IP Address:     192  .  168  .  1    .  45
Subnet Mask:    255  .  255  .  255  .  0
                │       │       │       │
                Network Network Network Host
                portion portion portion portion
```

**Translation:**

```
Network portion: 192.168.1  (first 3 octets)
  This defines the network
  All devices on this network have 192.168.1.X

Host portion: 45  (last octet)
  This identifies the specific device
  Can be 0-255 (actually 1-254 usable)
```

---

### Binary View (How It Really Works)

**IP Address: 192.168.1.45**

```
Decimal:  192      .  168      .  1        .  45
Binary:   11000000 .  10101000 .  00000001 .  00101101
```

**Subnet Mask: 255.255.255.0**

```
Decimal:  255      .  255      .  255      .  0
Binary:   11111111 .  11111111 .  11111111 .  00000000
          │                                   │
          Network bits (1s)                   Host bits (0s)
```

**The rule:**

```
Where mask has 1 → Network portion (fixed for this network)
Where mask has 0 → Host portion (varies per device)
```

---

### Common Subnet Masks

| Subnet Mask | Binary | Network Bits | Host Bits | Total Hosts |
|-------------|--------|--------------|-----------|-------------|
| 255.0.0.0 | 11111111.00000000.00000000.00000000 | 8 | 24 | 16,777,214 |
| 255.255.0.0 | 11111111.11111111.00000000.00000000 | 16 | 16 | 65,534 |
| 255.255.255.0 | 11111111.11111111.11111111.00000000 | 24 | 8 | 254 |
| 255.255.255.128 | 11111111.11111111.11111111.10000000 | 25 | 7 | 126 |
| 255.255.255.192 | 11111111.11111111.11111111.11000000 | 26 | 6 | 62 |

---

### How Devices Use Subnet Masks

**Your laptop's configuration:**

```
IP:   192.168.1.45
Mask: 255.255.255.0
```

**You want to reach 192.168.1.67:**

```
Your network:   192.168.1.0
Target network: 192.168.1.0
Match → SAME NETWORK → Send direct
```

**You want to reach 192.168.2.50:**

```
Your network:   192.168.1.0
Target network: 192.168.2.0
No match → DIFFERENT NETWORK → Send to gateway
```

---

## CIDR Notation (The Shorthand)

### What Is CIDR?

**CIDR = Classless Inter-Domain Routing**

**Purpose:**  
A shorter way to write IP address + subnet mask together.

**Instead of:**

```
Network:      192.168.1.0
Subnet Mask:  255.255.255.0
```

**Write:**

```
192.168.1.0/24
```

---

### What the /Number Means

**The number after the slash = how many network bits**

```
192.168.1.0/24
            └─ 24 bits for network
               32 - 24 = 8 bits for hosts
```

**Conversion:**

```
/24 → 24 network bits → Subnet mask 255.255.255.0

Why 255.255.255.0?
  First 24 bits are 1s: 11111111.11111111.11111111.00000000
  In decimal: 255.255.255.0
```

---

### Common CIDR to Subnet Mask Conversions

| CIDR | Subnet Mask | Network Bits | Host Bits |
|------|-------------|--------------|-----------|
| /8 | 255.0.0.0 | 8 | 24 |
| /16 | 255.255.0.0 | 16 | 16 |
| /24 | 255.255.255.0 | 24 | 8 |
| /25 | 255.255.255.128 | 25 | 7 |
| /26 | 255.255.255.192 | 26 | 6 |
| /27 | 255.255.255.224 | 27 | 5 |
| /28 | 255.255.255.240 | 28 | 4 |
| /30 | 255.255.255.252 | 30 | 2 |
| /32 | 255.255.255.255 | 32 | 0 |

---

### CIDR Block Examples

**Example 1: 10.0.0.0/16**

```
Range:  10.0.0.0 - 10.0.255.255
Total:  2^16 = 65,536 IPs
Usable: 65,534
```

**Example 2: 192.168.1.0/24**

```
Range:  192.168.1.0 - 192.168.1.255
Total:  2^8 = 256 IPs
Usable: 254
```

**Example 3: 172.16.0.0/12**

```
Range:  172.16.0.0 - 172.31.255.255
Total:  2^20 = 1,048,576 IPs
Usable: 1,048,574
```

---

### Why CIDR Is Better Than Old Classes

**Old system (before 1993):**

```
Class A: /8  (16 million IPs per network)
Class B: /16 (65,536 IPs per network)
Class C: /24 (256 IPs per network)

Problem:
  Company needs 500 IPs
  Class C too small (256)
  Class B too big (65,536) — Waste!
```

**CIDR system (modern):**

```
Need 500 IPs? Use /23 (512 IPs)
Need 1000 IPs? Use /22 (1024 IPs)

Flexible! Any size you need.
```

---

## Calculating Available IPs

### The Formula

**Given CIDR notation:**

```
Total IPs = 2^(32 - CIDR)

Usable IPs = Total - 2
  -1 for network address (first IP)
  -1 for broadcast address (last IP)
```

---

### Step-by-Step Calculation

**Example: 192.168.1.0/26**

```
Step 1: Identify host bits
  CIDR: /26
  Host bits: 32 - 26 = 6 bits

Step 2: Calculate total IPs
  Total: 2^6 = 64 IPs

Step 3: Calculate usable IPs
  Usable: 64 - 2 = 62 IPs

Step 4: Determine range
  Network address:   192.168.1.0   (reserved)
  First usable:      192.168.1.1
  Last usable:       192.168.1.62
  Broadcast address: 192.168.1.63  (reserved)
```

---

### Quick Reference Table

| CIDR | Host Bits | Total IPs | Usable IPs | Use Case |
|------|-----------|-----------|------------|----------|
| /32 | 0 | 1 | 1 | Single host (security group rule) |
| /30 | 2 | 4 | 2 | Point-to-point links |
| /29 | 3 | 8 | 6 | Very small subnet |
| /28 | 4 | 16 | 14 | Small subnet |
| /27 | 5 | 32 | 30 | Small subnet |
| /26 | 6 | 64 | 62 | Medium subnet |
| /25 | 7 | 128 | 126 | Medium subnet |
| /24 | 8 | 256 | 254 | Standard subnet |
| /23 | 9 | 512 | 510 | Medium-large subnet |
| /22 | 10 | 1,024 | 1,022 | Large subnet |
| /20 | 12 | 4,096 | 4,094 | Very large subnet |
| /16 | 16 | 65,536 | 65,534 | Large network |
| /8 | 24 | 16,777,216 | 16,777,214 | Massive network |

---

### Reserved Addresses

**In every subnet, two addresses are reserved:**

```
Example: 192.168.1.0/24

Network address:   192.168.1.0    (identifies the subnet)
Broadcast address: 192.168.1.255  (send to all hosts)

Usable range:      192.168.1.1 - 192.168.1.254
```

---

## Common CIDR Blocks (Memorize These)

### The Essential Four

```
/32 = 1 IP (single host)
/24 = 256 IPs (254 usable) — standard subnet
/16 = 65,536 IPs — large network
/8  = 16.7 million IPs — entire private range
```

---

### Mental Shortcuts

**Powers of 2:**

```
/32 = 2^0  = 1
/28 = 2^4  = 16
/26 = 2^6  = 64
/24 = 2^8  = 256      ← Memorize
/22 = 2^10 = 1,024
/20 = 2^12 = 4,096
/16 = 2^16 = 65,536   ← Memorize
/8  = 2^24 = 16,777,216
```

---

## Subnet Planning Rules

### Rule 1: Avoid Overlap

**❌ BAD (subnets overlap):**

```
Subnet A: 10.0.1.0/24  (10.0.1.0 - 10.0.1.255)
Subnet B: 10.0.1.128/25 (10.0.1.128 - 10.0.1.255)
                          ↑
                    Overlap! Conflict!
```

**✅ GOOD (no overlap):**

```
Subnet A: 10.0.1.0/24   (10.0.1.0 - 10.0.1.255)
Subnet B: 10.0.2.0/24   (10.0.2.0 - 10.0.2.255)
```

---

### Rule 2: Plan for Growth

```
Need 50 IPs → Use /24 (254 usable)
  Room for growth: 254 - 50 = 204 IPs available

Rule of thumb: Allocate 2-3x what you need today.
```

---

### Rule 3: Use Consistent Sizing

**✅ Consistent (easy to manage):**

```
Web subnet:  10.0.1.0/24
App subnet:  10.0.2.0/24
DB subnet:   10.0.3.0/24

Same size, predictable, simple
```

---

### Rule 4: Smaller CIDR = Bigger Network

```
/24 = 256 IPs    (bigger subnet)
/26 = 64 IPs     (smaller subnet)
/28 = 16 IPs     (even smaller)

Lower number = MORE IPs
Higher number = FEWER IPs
```

---

### Rule 5: Leave Room Between Subnets

```
VPC: 10.0.0.0/16

Current subnets:
  Web:  10.0.1.0/24
  App:  10.0.2.0/24
  DB:   10.0.3.0/24

Reserved for future:
  10.0.4.0/24 - 10.0.255.0/24 (available)
```

---

## Subnetting Practice

### Exercise 1: Calculate Usable IPs

**Given: 192.168.10.0/27**

```
Step 1: Find host bits
  Host bits = 32 - 27 = 5 bits

Step 2: Calculate total IPs
  Total = 2^5 = 32 IPs

Step 3: Calculate usable
  Usable = 32 - 2 = 30 IPs

Step 4: Determine range
  Network:   192.168.10.0
  First:     192.168.10.1
  Last:      192.168.10.30
  Broadcast: 192.168.10.31
```

---

### Exercise 2: Choose Right CIDR

**Requirement: Need subnet for 100 hosts**

```
Options:
  /25 = 128 IPs (126 usable) ✓ Sufficient
  /26 = 64 IPs (62 usable)   ✗ Too small
  /24 = 256 IPs (254 usable) ✓ Room for growth

Best choice: /24 (room for growth)
```

---

### Exercise 3: Identify Conflicts

**Which subnets overlap?**

```
A: 10.0.1.0/24   (10.0.1.0 - 10.0.1.255)
B: 10.0.2.0/24   (10.0.2.0 - 10.0.2.255)
C: 10.0.1.128/25 (10.0.1.128 - 10.0.1.255)

Answer: A and C overlap
  A covers 10.0.1.0 - 10.0.1.255
  C covers 10.0.1.128 - 10.0.1.255
  Conflict in 10.0.1.128 - 10.0.1.255 range
```

---

> **AWS implementation:** How to apply these CIDR concepts to AWS VPC design — public vs private subnets, multi-AZ patterns, AWS reserved IPs, and a full webstore VPC subnet plan — is covered in the AWS notes.
> → [AWS VPC & Subnets](../../06.%20AWS%20–%20Cloud%20Infrastructure/03-vpc-subnet/README.md)

---

## Final Compression

### Subnet Mask Basics

```
Subnet mask = Defines network boundary

255.255.255.0 means:
  First 3 octets = network (192.168.1)
  Last octet = hosts (0-255)
```

---

### CIDR Notation

```
Format: IP/Number

192.168.1.0/24
            └─ 24 network bits
               8 host bits remain

Formula:
  Total IPs = 2^(32 - CIDR)
  Usable = Total - 2
```

---

### The Essential CIDRs (Memorize)

```
/32 = 1 IP       (single host)
/24 = 256 IPs    (standard subnet)
/16 = 65,536 IPs (large network)
/8  = 16.7M IPs  (entire private range)
```

---

### Subnet Planning Rules

```
1. No overlap (check ranges)
2. Plan for growth (use 2-3x needed)
3. Consistent sizing (all /24 is easier)
4. Smaller CIDR = bigger network (/16 > /24)
5. Leave gaps for future expansion
```

---

### Mental Model

```
Subnetting = Dividing a network into smaller pieces

Why?
  Security (isolate systems)
  Organization (logical groups)
  Performance (smaller domains)

How?
  Subnet mask defines boundary
  CIDR notation is shorthand
```

---

### What You Can Do Now

✅ Calculate IPs from CIDR (/24 = 256 IPs)  
✅ Avoid subnet overlap conflicts  
✅ Choose appropriate subnet sizes  
✅ Understand subnet masks  
✅ Plan for growth and future expansion  

---

---

## What This Means for the Webstore

When you deploy the webstore to a server environment, you decide what subnet it lives in. A single server on a `/24` subnet shares that network with 253 other possible addresses. When you need to separate webstore-api from webstore-db for security — putting the database in a private subnet with no internet route — you need two subnets: one public (`10.0.1.0/24`) for the frontend and API tier, one private (`10.0.2.0/24`) for the database. Postgres lives on `10.0.2.50`. A browser on the internet cannot reach postgres directly — not because of a firewall rule, but because there is no route to that subnet from outside. This is the network design pattern AWS VPC implements, and you will lay it out exactly this way when you get there.

→ Ready to practice? [Go to Lab 02](../networking-labs/02-devices-subnets-lab.md)

---
# TOOL: 03. Networking – Foundations | FILE: 06-ports-transport
---

# File 06: Ports & Transport Layer

[Home](../README.md) |
[Foundation](../01-foundation-and-the-big-picture/README.md) |
[Addressing](../02-addressing-fundamentals/README.md) |
[IP Deep Dive](../03-ip-deep-dive/README.md) |
[Network Devices](../04-network-devices/README.md) |
[Subnets & CIDR](../05-subnets-cidr/README.md) |
[Ports & Transport](../06-ports-transport/README.md) |
[NAT](../07-nat/README.md) |
[DNS](../08-dns/README.md) |
[Firewalls](../09-firewalls/README.md) |
[Complete Journey](../10-complete-journey/README.md)

---

# Ports & Transport Layer

## What this file is about

This file teaches **how applications are identified using port numbers** and **how data is delivered reliably**. If you understand this, you'll know why SSH uses port 22, how TCP guarantees delivery, when to use UDP, and how to configure firewall rules correctly. This is essential for deploying and troubleshooting applications.

<!-- no toc -->
- [The Core Problem](#the-core-problem)
- [What Are Ports?](#what-are-ports)
- [Common Port Numbers (Memorize These)](#common-port-numbers-memorize-these)
- [TCP vs UDP (The Two Protocols)](#tcp-vs-udp-the-two-protocols)
- [TCP: The Reliable Protocol](#tcp-the-reliable-protocol)
- [UDP: The Fast Protocol](#udp-the-fast-protocol)
- [Port Ranges and Categories](#port-ranges-and-categories)
- [The Socket Concept](#the-socket-concept)
- [Real Scenarios](#real-scenarios)  
[Final Compression](#final-compression)

---

## The Core Problem

### Your Original Question

**"Does the device have IP and the application also has IP?"**

**Short answer:** No.

**Correct model:**

```
Device has IP address    (identifies the computer)
Application has PORT     (identifies the application)

Format: IP:Port
Example: 192.168.1.45:80
         └──────────┘ └┘
         Device       Application
```

---

### The Scenario

**Your server has multiple applications running:**

```
Server IP: 192.168.1.100

Running applications:
- Web server (nginx)
- Database (PostgreSQL)
- SSH server
- Redis cache
- API application
```

**Problem:**  
A packet arrives at 192.168.1.100.  
**Which application should receive it?**

**Solution: Port numbers**

```
Web server:    192.168.1.100:80
Database:      192.168.1.100:5432
SSH:           192.168.1.100:22
Redis:         192.168.1.100:6379
API:           192.168.1.100:3000

Same IP, different ports
```

---

### Real-World Analogy

**IP address = Apartment building address**

```
123 Main Street
```

**Port number = Apartment number**

```
123 Main Street, Apartment 5
123 Main Street, Apartment 12
123 Main Street, Apartment 24

Same building (IP)
Different apartments (ports)
```

**Sending mail:**

```
Wrong: "Send to 123 Main Street"
  Which apartment? Unclear!

Right: "Send to 123 Main Street, Apartment 12"
  Specific destination
```

**Sending data:**

```
Wrong: "Send to 192.168.1.100"
  Which application? Unclear!

Right: "Send to 192.168.1.100:80"
  Specific application (web server)
```

---

## What Are Ports?

### Definition

**Port:**  
A 16-bit number (0-65535) that identifies a specific application or service on a device.

**Purpose:**  
Allow multiple applications to run on the same IP address without conflicts.

---

### How Ports Work

**Your laptop connects to a web server:**

```
Your laptop:
  IP: 192.168.1.45
  Source port: 54321 (random)

Web server:
  IP: 203.45.67.89
  Destination port: 80 (HTTP)

Connection format:
  192.168.1.45:54321 → 203.45.67.89:80
  └──────────────┘     └──────────────┘
  Source (you)         Destination (server)
```

---

### Port Number Format

**Range:**

```
0 - 65535 (16-bit number)

Total possible ports: 65,536
```

**In packet headers:**

```
TCP/UDP Header:
  Source Port:      54321
  Destination Port: 80
  ...other fields...
```

---

### Check Your Open Ports

**Linux/Mac:**

```bash
# Show all listening ports
sudo netstat -tlnp

# or
sudo ss -tlnp

Output:
Proto Local Address    State   PID/Program
tcp   0.0.0.0:22       LISTEN  1234/sshd
tcp   0.0.0.0:80       LISTEN  5678/nginx
tcp   127.0.0.1:5432   LISTEN  9012/postgres
```

**Windows:**

```cmd
netstat -ano

Output:
Proto  Local Address      Foreign Address    State       PID
TCP    0.0.0.0:80         0.0.0.0:0          LISTENING   4
TCP    0.0.0.0:443        0.0.0.0:0          LISTENING   4
TCP    127.0.0.1:5432     0.0.0.0:0          LISTENING   2508
```

---

## Common Port Numbers (Memorize These)

### Essential Ports for DevOps

**You MUST know these:**

| Port | Protocol | Service | Usage |
|------|----------|---------|-------|
| **20/21** | FTP | File Transfer Protocol | File uploads (legacy) |
| **22** | SSH | Secure Shell | Remote server access |
| **23** | Telnet | Telnet | Unsecure remote access (don't use) |
| **25** | SMTP | Email sending | Mail servers |
| **53** | DNS | Domain Name System | Name resolution |
| **80** | HTTP | Web traffic (unsecure) | Websites |
| **110** | POP3 | Email retrieval | Email clients |
| **143** | IMAP | Email retrieval | Email clients |
| **443** | HTTPS | Web traffic (secure) | Secure websites |
| **3306** | MySQL | MySQL database | Database connections |
| **5432** | PostgreSQL | PostgreSQL database | Database connections |
| **6379** | Redis | Redis cache | Cache/queue connections |
| **27017** | MongoDB | MongoDB database | NoSQL database |
| **3389** | RDP | Remote Desktop | Windows remote access |
| **8080** | HTTP Alt | Alternative HTTP | Dev servers, proxies |

---

### Application-Specific Ports

**Docker & Containers:**

```
2375 - Docker daemon (unencrypted)
2376 - Docker daemon (TLS)
```

**Kubernetes:**

```
6443 - Kubernetes API server
10250 - Kubelet API
```

**Message Queues:**

```
5672 - RabbitMQ
9092 - Kafka
```

**Monitoring:**

```
9090 - Prometheus
3000 - Grafana
9200 - Elasticsearch
5601 - Kibana
```

---

### Real Examples

**Accessing websites:**

```
http://google.com
  → Implicitly uses port 80
  → Browser connects to google.com:80

https://google.com
  → Implicitly uses port 443
  → Browser connects to google.com:443

http://localhost:3000
  → Explicitly uses port 3000
  → Browser connects to localhost:3000
```

**SSH to server:**

```bash
ssh user@192.168.1.100
  → Implicitly uses port 22
  → Connects to 192.168.1.100:22

ssh -p 2222 user@192.168.1.100
  → Explicitly uses port 2222
  → Connects to 192.168.1.100:2222
```

**Database connections:**

```
PostgreSQL:
  psql -h 192.168.1.100 -p 5432
  Connection string: postgresql://user:pass@192.168.1.100:5432/db

MySQL:
  mysql -h 192.168.1.100 -P 3306
  Connection string: mysql://user:pass@192.168.1.100:3306/db

MongoDB:
  mongo 192.168.1.100:27017
  Connection string: mongodb://192.168.1.100:27017/db
```

---

## TCP vs UDP (The Two Protocols)

### The Transport Layer

**Layer 4 (Transport) has two main protocols:**

```
1. TCP (Transmission Control Protocol)
   - Reliable, ordered, connection-oriented
   - Most common

2. UDP (User Datagram Protocol)
   - Fast, unordered, connectionless
   - Special use cases
```

---

### Side-by-Side Comparison

| Feature | TCP | UDP |
|---------|-----|-----|
| **Reliability** | Guaranteed delivery | No guarantee |
| **Ordering** | Packets arrive in order | May arrive out of order |
| **Connection** | Requires handshake | No connection setup |
| **Speed** | Slower (overhead) | Faster (minimal overhead) |
| **Error checking** | Yes (retransmits lost data) | Minimal |
| **Use cases** | Web, email, file transfer, databases | Video, gaming, DNS, VoIP |
| **Header size** | 20 bytes | 8 bytes |

---

### When to Use Which

**Use TCP when:**

```
✅ Data MUST arrive correctly
✅ Order matters
✅ Loss is unacceptable

Examples:
- Downloading files
- Loading web pages
- Database queries
- Email
- SSH connections
```

**Use UDP when:**

```
✅ Speed is critical
✅ Some data loss is acceptable
✅ Real-time is important

Examples:
- Live video streaming
- Online gaming
- VoIP (phone calls)
- DNS queries
- IoT sensor data
```

---

### Visual Comparison

**TCP (like certified mail):**

```
Sender → Post Office
  ↓
Acknowledgment: "We received it"
  ↓
Delivery to recipient
  ↓
Signature required
  ↓
Confirmation back to sender: "Delivered!"

Guarantees:
✅ Package arrives
✅ In correct order
✅ Recipient confirms receipt
```

**UDP (like shouting across the street):**

```
Sender → Yells message
  ↓
Hope recipient hears it

No guarantees:
❌ May not arrive
❌ May arrive out of order
❌ No confirmation

But: Very fast!
```

---

## TCP: The Reliable Protocol

### TCP Characteristics

```
✅ Connection-oriented (handshake required)
✅ Reliable (guarantees delivery)
✅ Ordered (packets reassembled correctly)
✅ Error-checked (detects corruption)
✅ Flow-controlled (adapts to network speed)
```

---

### TCP 3-Way Handshake

**Before data is sent, TCP establishes a connection:**

```
┌──────────┐                      ┌──────────┐
│  Client  │                      │  Server  │
└────┬─────┘                      └────┬─────┘
     │                                 │
     │  1. SYN (Synchronize)           │
     │  "I want to connect"            │
     ├────────────────────────────────>│
     │                                 │
     │                                 │ Check if port open
     │                                 │ Allocate resources
     │                                 │
     │  2. SYN-ACK (Synchronize-Ack)   │
     │  "OK, I'm ready"                │
     │<────────────────────────────────┤
     │                                 │
     │                                 │
     │  3. ACK (Acknowledge)           │
     │  "Great, let's start"           │
     ├────────────────────────────────>│
     │                                 │
     │  Connection established         │
     │  Data can now flow              │
     │<───────────────────────────────>│
```

---

### Step-by-Step Handshake

**Step 1: Client sends SYN**

```
Client → Server

TCP Header:
  Source Port:    54321
  Dest Port:      80
  Flags:          SYN
  Sequence:       1000
  
Message: "I want to connect to port 80"
```

**Step 2: Server responds with SYN-ACK**

```
Server → Client

TCP Header:
  Source Port:    80
  Dest Port:      54321
  Flags:          SYN, ACK
  Sequence:       5000
  Acknowledgment: 1001
  
Message: "I received your SYN (1000). 
          I'm ready. My sequence starts at 5000."
```

**Step 3: Client sends ACK**

```
Client → Server

TCP Header:
  Source Port:    54321
  Dest Port:      80
  Flags:          ACK
  Sequence:       1001
  Acknowledgment: 5001
  
Message: "I received your SYN-ACK (5000). Let's communicate."

Connection now ESTABLISHED
```

---

### TCP Data Transfer

**After handshake, data flows with acknowledgments:**

```
Client → Server: "Here's 100 bytes (seq 1001-1100)"
Server → Client: "Got it! (ack 1101)"

Client → Server: "Here's 100 bytes (seq 1101-1200)"
Server → Client: "Got it! (ack 1201)"

If packet lost:
Client → Server: "Here's 100 bytes (seq 1201-1300)"
Server: ... (no response)

Client waits for timeout
Client: "No ACK received, resend"
Client → Server: "Here's 100 bytes (seq 1201-1300)" (retry)
Server → Client: "Got it! (ack 1301)"
```

---

### TCP Connection Termination

**4-way termination (graceful close):**

```
┌──────────┐                      ┌──────────┐
│  Client  │                      │  Server  │
└────┬─────┘                      └────┬─────┘
     │                                 │
     │  1. FIN (Finish)                │
     │  "I'm done sending"             │
     ├────────────────────────────────>│
     │                                 │
     │  2. ACK                         │
     │  "OK, got it"                   │
     │<────────────────────────────────┤
     │                                 │
     │  3. FIN                         │
     │  "I'm also done"                │
     │<────────────────────────────────┤
     │                                 │
     │  4. ACK                         │
     │  "OK, closing"                  │
     ├────────────────────────────────>│
     │                                 │
     │  Connection closed              │
```

---

### Why TCP Matters for DevOps

**Debugging connection issues:**

```
Error: "Connection refused"
  Meaning: Server not listening on that port
  TCP reached server, but nothing on port 80

Error: "Connection timeout"
  Meaning: No response to SYN
  Firewall blocking, or server down

Error: "Connection reset"
  Meaning: Server abruptly closed connection
  Application crashed, or limit reached
```

**Check TCP connections:**

```bash
# Show established TCP connections
netstat -tn

# Show listening TCP ports
netstat -tln

# Count connections per port
netstat -tn | grep :80 | wc -l
```

---

## UDP: The Fast Protocol

### UDP Characteristics

```
✅ Connectionless (no handshake)
✅ Fast (minimal overhead)
✅ Low latency
❌ No reliability guarantee
❌ No ordering guarantee
❌ No retransmission
```

---

### How UDP Works

**No handshake, just send:**

```
┌──────────┐                      ┌──────────┐
│  Client  │                      │  Server  │
└────┬─────┘                      └────┬─────┘
     │                                 │
     │  UDP packet                     │
     │  "Here's some data"             │
     ├────────────────────────────────>│
     │                                 │
     │  (no acknowledgment)            │
     │                                 │
     │  Another UDP packet             │
     │  "Here's more data"             │
     ├────────────────────────────────>│
     │                                 │
     │  (no acknowledgment)            │
     │                                 │
     │  No connection state            │
     │  No reliability                 │
     │  Just send and hope             │
```

---

### UDP Packet Structure

**Much simpler than TCP:**

```
UDP Header (8 bytes):
  Source Port:      53
  Destination Port: 54321
  Length:           56 bytes
  Checksum:         0x1A2B

Payload:
  DNS response data
  
That's it! No sequence, no ack, no flags.
```

---

### Why Use UDP?

**DNS queries (perfect UDP use case):**

```
You: "What's google.com's IP?"
  UDP packet to 8.8.8.8:53
  Small query (< 512 bytes)
  
DNS server: "142.250.190.46"
  UDP packet back
  Small response
  
Total time: ~10ms

If UDP packet lost? Send again.
Lost rate: <1%
Speed gain: Significant (no handshake)
```

**Live video streaming:**

```
Video frames sent via UDP
  Frame 1 → (sent)
  Frame 2 → (sent)
  Frame 3 → (lost!) ❌
  Frame 4 → (sent)
  Frame 5 → (sent)

Result: Slight glitch (Frame 3 missing)
Better than: Buffering while waiting for retransmit

User experience: Smooth (acceptable glitch)
```

**Online gaming:**

```
Player position updates:
  Position at T=0ms  → (sent via UDP)
  Position at T=50ms → (sent via UDP)
  Position at T=100ms → (lost!) ❌
  Position at T=150ms → (sent via UDP)

Missing one position update? No problem.
Next update arrives with current position.
Better than TCP delay from retransmit.
```

---

### UDP vs TCP Example

**Downloading a file (use TCP):**

```
TCP:
  100% of file arrives
  Every byte verified
  Correct order
  Download time: 10 seconds
  
UDP:
  98% of file arrives (2% lost)
  File corrupted
  Unusable
  Download time: 8 seconds (but useless!)
```

**VoIP call (use UDP):**

```
UDP:
  2% packets lost
  Slight audio glitch
  Real-time conversation
  Latency: 50ms
  
TCP:
  100% packets arrive
  No glitches
  But: Stuttering from retransmits
  Latency: 200-500ms (unacceptable delay)
```

---

### Common UDP Services

| Port | Service | Why UDP? |
|------|---------|----------|
| **53** | DNS | Small queries, speed critical |
| **67/68** | DHCP | Small broadcast messages |
| **123** | NTP (time sync) | Speed, periodic updates |
| **161/162** | SNMP (monitoring) | Speed, many small queries |
| **514** | Syslog | Fire-and-forget logging |
| **Various** | Video/Audio streaming | Real-time, loss acceptable |
| **Various** | Online gaming | Low latency critical |

---

## Port Ranges and Categories

### The Three Ranges

**0-1023: Well-Known Ports**

```
Assigned by IANA
System/privileged services only
Require root/admin to bind

Examples:
  22  - SSH
  80  - HTTP
  443 - HTTPS
```

**1024-49151: Registered Ports**

```
Registered for specific services
Can be used by regular users
Companies register their software ports

Examples:
  3306  - MySQL
  5432  - PostgreSQL
  27017 - MongoDB
  3000  - Many dev servers
  8080  - Alternative HTTP
```

**49152-65535: Dynamic/Private Ports**

```
Ephemeral ports
Used for client-side connections
Randomly assigned by OS

Example:
  Your browser connects to server:
    Source port: 54321 (random from this range)
    Dest port: 443 (server's HTTPS port)
```

---

### Binding Ports (Server vs Client)

**Server behavior (binds to specific port):**

```
Web server:
  Binds to port 80
  Listens for connections
  Port doesn't change

Code:
  socket.bind(("0.0.0.0", 80))
  socket.listen()
```

**Client behavior (uses random port):**

```
Your browser:
  Connects to google.com:443
  Uses random source port: 54321
  Different for each connection

Next connection:
  Source port: 54322 (different)
```

---

### Check Port Availability

**Linux/Mac:**

```bash
# Check if port 80 is in use
sudo lsof -i :80

# Check if port available
nc -zv localhost 80

# Test TCP connection
telnet localhost 80

# Test UDP connection
nc -u localhost 53
```

**Why ports might be unavailable:**

```
1. Another application using it
   Error: "Address already in use"
   
2. Insufficient privileges
   Error: "Permission denied" (ports < 1024)
   
3. Firewall blocking
   Error: "Connection refused" or timeout
```

---

## The Socket Concept

### What Is a Socket?

**Socket:**  
A combination of IP address + port number + protocol.

**Format:**

```
Protocol://IP:Port

Examples:
  tcp://192.168.1.100:80
  udp://8.8.8.8:53
  tcp://[::1]:443 (IPv6)
```

---

### Socket as Endpoint

**Communication requires two sockets:**

```
Client socket:
  tcp://192.168.1.45:54321

Server socket:
  tcp://192.168.1.100:80

Connection:
  192.168.1.45:54321 ←→ 192.168.1.100:80
```

---

### Multiple Connections to Same Server

**Server can handle many clients on same port:**

```
Server: 192.168.1.100:80

Connection 1:
  Client A (192.168.1.45:54321) → Server (192.168.1.100:80)

Connection 2:
  Client B (192.168.1.67:54322) → Server (192.168.1.100:80)

Connection 3:
  Client C (192.168.1.89:54323) → Server (192.168.1.100:80)

Server distinguishes by:
  Different source IP + source port combinations
```

---

### Socket States (TCP)

**TCP sockets have states:**

```
LISTEN      - Server waiting for connections
SYN_SENT    - Client sent SYN, waiting for SYN-ACK
ESTABLISHED - Connection active
FIN_WAIT    - Closing connection
TIME_WAIT   - Connection closed, waiting for delayed packets
CLOSED      - Socket closed
```

**Check socket states:**

```bash
netstat -tn

Output:
Proto Recv-Q Send-Q Local Address      Foreign Address    State
tcp   0      0      192.168.1.45:54321 142.250.190.46:443 ESTABLISHED
tcp   0      0      192.168.1.45:54322 93.184.216.34:80   TIME_WAIT
tcp   0      0      0.0.0.0:22         0.0.0.0:*          LISTEN
```

---

## Real Scenarios

### Scenario 1: Web Server Configuration

**nginx configuration:**

```nginx
server {
    listen 80;                    # HTTP
    listen [::]:80;               # HTTP (IPv6)
    server_name example.com;
    
    return 301 https://$server_name$request_uri;  # Redirect to HTTPS
}

server {
    listen 443 ssl;               # HTTPS
    listen [::]:443 ssl;          # HTTPS (IPv6)
    server_name example.com;
    
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    
    location / {
        proxy_pass http://localhost:3000;  # Forward to app on port 3000
    }
}
```

**Port usage:**

```
Port 80:  Public-facing HTTP (redirects to 443)
Port 443: Public-facing HTTPS (SSL/TLS)
Port 3000: Internal application server (not exposed)
```

---

### Scenario 2: Docker Port Binding

**Expose container port to host:**

```bash
# Run nginx container
docker run -d -p 8080:80 nginx

# Breakdown:
#   -p 8080:80
#      │    │
#      │    └─ Container port (nginx listens on 80)
#      └────── Host port (accessible at localhost:8080)

# Access:
curl http://localhost:8080
  → Routes to container's port 80
```

**Multiple port mappings:**

```bash
docker run -d \
  -p 80:80 \       # HTTP
  -p 443:443 \     # HTTPS
  -p 3306:3306 \   # MySQL
  nginx
```

---

### Scenario 3: AWS Security Group Rules

**Allow web traffic:**

```
Inbound Rules:

Type     Protocol  Port Range  Source       Description
HTTP     TCP       80          0.0.0.0/0    Allow HTTP from anywhere
HTTPS    TCP       443         0.0.0.0/0    Allow HTTPS from anywhere
SSH      TCP       22          203.0.113.0/24  Allow SSH from office IP only
Custom   TCP       3000        10.0.1.0/24  Allow internal API access
```

**Common mistake:**

```
❌ Wrong: Open all ports
   Port Range: 0-65535
   Risk: Exposes unnecessary services

✅ Right: Only open needed ports
   Ports: 22, 80, 443
   Principle of least privilege
```

---

### Scenario 4: Debugging Connection Issues

**Can't connect to database:**

```bash
# Step 1: Check if database listening
sudo netstat -tlnp | grep 5432

Output:
tcp  0.0.0.0:5432  LISTEN  1234/postgres

✓ Database is listening on port 5432

# Step 2: Try to connect locally
psql -h localhost -p 5432

✓ Works locally

# Step 3: Try from remote
psql -h 192.168.1.100 -p 5432

✗ Connection timeout

# Conclusion: Firewall blocking port 5432
```

**Fix:**

```bash
# Ubuntu/Debian
sudo ufw allow 5432/tcp

# CentOS/RHEL
sudo firewall-cmd --add-port=5432/tcp --permanent
sudo firewall-cmd --reload
```

---

### Scenario 5: Multi-Service Server

**One server running multiple services:**

```
Server IP: 192.168.1.100

Services:
├─ SSH:        Port 22      (secure remote access)
├─ Web:        Port 80      (public HTTP)
├─ Web SSL:    Port 443     (public HTTPS)
├─ PostgreSQL: Port 5432    (internal database)
├─ Redis:      Port 6379    (internal cache)
└─ API:        Port 8000    (internal API)

Firewall rules:
  Port 22:   Allow from 203.0.113.0/24 (office)
  Port 80:   Allow from 0.0.0.0/0 (everyone)
  Port 443:  Allow from 0.0.0.0/0 (everyone)
  Port 5432: Allow from 192.168.1.0/24 (local network)
  Port 6379: Allow from 192.168.1.0/24 (local network)
  Port 8000: Allow from 192.168.1.0/24 (local network)
```

---

## Final Compression

### What Are Ports?

```
Port = 16-bit number (0-65535)
Purpose: Identify applications on a device

Format: IP:Port
  192.168.1.100:80  (web server)
  192.168.1.100:5432 (database)

Same IP, different applications
```

---

### Essential Ports (Memorize)

```
22   - SSH (remote access)
53   - DNS (name resolution)
80   - HTTP (web unsecure)
443  - HTTPS (web secure)
3306 - MySQL
5432 - PostgreSQL
6379 - Redis
27017 - MongoDB
```

---

### TCP vs UDP

**TCP (Reliable):**
```
✅ Guaranteed delivery
✅ Ordered packets
✅ 3-way handshake (SYN, SYN-ACK, ACK)
✅ Use for: Web, email, databases, file transfer
```

**UDP (Fast):**
```
✅ No handshake
✅ Low latency
❌ No guarantee
✅ Use for: DNS, video streaming, gaming, VoIP
```

---

### TCP 3-Way Handshake

```
Client → Server: SYN ("Let's connect")
Server → Client: SYN-ACK ("OK, ready")
Client → Server: ACK ("Great!")

Connection established
```

---

### Port Ranges

```
0-1023:       Well-known (system services)
1024-49151:   Registered (applications)
49152-65535:  Dynamic (client connections)
```

---

### Socket = IP + Port + Protocol

```
tcp://192.168.1.45:54321 → tcp://192.168.1.100:80
└────────────────────┘      └────────────────────┘
Client socket               Server socket
```

---

### Common Errors

```
"Connection refused"
  → Port not listening
  → Check: netstat -tln | grep PORT

"Connection timeout"
  → Firewall blocking or server down
  → Check: firewall rules

"Address already in use"
  → Port taken by another app
  → Check: lsof -i :PORT
```

---

### Mental Model

```
IP address = Apartment building
Port number = Apartment number

One building (192.168.1.100)
Many apartments:
  :22   (SSH)
  :80   (HTTP)
  :443  (HTTPS)
  :5432 (PostgreSQL)

Mail delivery needs both:
  Building address + Apartment number
  IP address + Port number
```

---

### What You Can Do Now

✅ Understand what ports are (application identifiers)  
✅ Know common port numbers (22, 80, 443, 3306, 5432)  
✅ Understand TCP vs UDP differences  
✅ Know TCP 3-way handshake  
✅ Configure firewall rules with correct ports  
✅ Debug port-related connection issues  
✅ Map Docker container ports  

---

---

## What This Means for the Webstore

Three services, one server, three ports. nginx on 80, webstore-api on 8080, postgres on 5432. When a connection arrives at the server's IP, the OS reads the destination port and delivers it to the right process. When you check `ss -tlnp` on the webstore server, you will see `0.0.0.0:80` for nginx (listening on all interfaces), `0.0.0.0:8080` for the API, and `127.0.0.1:5432` for postgres (loopback only). That single difference in binding address tells you everything about what is and is not reachable from outside. Reading `ss` output is how you verify a service is actually listening before you debug anything else.

→ Ready to practice? [Go to Lab 03](../networking-labs/03-ports-transport-nat-lab.md)

---
# TOOL: 03. Networking – Foundations | FILE: 07-nat
---

# File 07: NAT & Translation

[Home](../README.md) |
[Foundation](../01-foundation-and-the-big-picture/README.md) |
[Addressing](../02-addressing-fundamentals/README.md) |
[IP Deep Dive](../03-ip-deep-dive/README.md) |
[Network Devices](../04-network-devices/README.md) |
[Subnets & CIDR](../05-subnets-cidr/README.md) |
[Ports & Transport](../06-ports-transport/README.md) |
[NAT](../07-nat/README.md) |
[DNS](../08-dns/README.md) |
[Firewalls](../09-firewalls/README.md) |
[Complete Journey](../10-complete-journey/README.md)

---

# NAT & Translation

## What this file is about

This file teaches **how devices with private IPs access the internet** and **how your router manages multiple devices with one public IP**. If you understand this, you'll know why your home router can support 50+ devices with one IP, how PAT works under the hood, and how port forwarding exposes internal services. How Docker and AWS implement NAT on top of these concepts is covered in their respective notes.

<!-- no toc -->
- [The Core Problem](#the-core-problem)
- [Why NAT Exists](#why-nat-exists)
- [How NAT Works (Basic)](#how-nat-works-basic)
- [PAT: Port Address Translation](#pat-port-address-translation)
- [The NAT Table](#the-nat-table)
- [Port Forwarding (Inbound NAT)](#port-forwarding-inbound-nat)
- [NAT Types and Variations](#nat-types-and-variations)
- [Real Scenarios](#real-scenarios)  
[Final Compression](#final-compression)

---

## The Core Problem

### Your Original Question

**"Router has no public IP? Only ISP has public IP?"**

**Answer:** Your router has BOTH.

**Router's two faces:**

```
┌─────────────────────────────────────┐
│           Your Router               │
│                                     │
│  LAN Side (Internal):               │
│    IP:  192.168.1.1                 │
│    MAC: AA:BB:CC:DD:EE:FF           │
│    Private, not internet-routable   │
│                                     │
│  WAN Side (External):               │
│    IP:  203.45.67.89                │
│    MAC: 11:22:33:44:55:66           │
│    Public, internet-routable        │
│    Assigned by ISP via DHCP         │
│                                     │
└─────────────────────────────────────┘
```

---

### The Fundamental Problem NAT Solves

**Scenario:**

```
Your home network:
├─ Laptop:     192.168.1.45
├─ Phone:      192.168.1.67
├─ Tablet:     192.168.1.89
└─ Smart TV:   192.168.1.100

All have private IPs
Private IPs cannot route on the internet

Internet server: 142.250.190.46 (Google)
Cannot send responses to private IPs
```

**Without NAT:**

```
Laptop (192.168.1.45) → Google (142.250.190.46)

Google tries to respond:
  Dest IP: 192.168.1.45 ← Private IP!

Internet routers: "192.168.1.45 is not routable"
Packet dropped

❌ Communication fails
```

---

## Why NAT Exists

### Historical Context

**IPv4 address exhaustion:**

```
Total IPv4 addresses: 4.3 billion
World population: 8 billion
Devices per person: 3-5+

Math: 4.3 billion < 20 billion devices

Not enough public IPs for everyone!
```

**Solution: NAT**

```
Many devices share one public IP

Your home:
├─ 10 devices with private IPs
└─ 1 router with public IP

All 10 devices access internet via 1 public IP
```

---

### NAT's Role in Modern Networking

**NAT allows:**

```
✅ Private IP addresses to access internet
✅ Multiple devices behind one public IP
✅ Conservation of public IP space
✅ Additional security (hides internal topology)
```

**NAT prevents:**

```
❌ Direct inbound connections to private IPs
   (Unless explicitly configured via port forwarding)
```

---

## How NAT Works (Basic)

### The Translation Process

**Your laptop accesses google.com:**

**Step 1: Laptop sends packet (private IP)**

```
Inside your network:
  Source IP:   192.168.1.45 (laptop)
  Source Port: 54321
  Dest IP:     142.250.190.46 (Google)
  Dest Port:   443

Packet reaches router
```

**Step 2: Router performs NAT (translation)**

```
Router receives packet
Checks source: 192.168.1.45 (private - can't route)

Router translates:
  Old Source IP:   192.168.1.45
  New Source IP:   203.45.67.89 (router's public IP)

Router records translation in NAT table:
  192.168.1.45:54321 ↔ 203.45.67.89:54321
```

**Step 3: Router forwards (public IP)**

```
Router sends packet to internet:
  Source IP:   203.45.67.89 (router's public IP)
  Source Port: 54321
  Dest IP:     142.250.190.46
  Dest Port:   443

Google sees: 203.45.67.89 (not 192.168.1.45)
```

**Step 4: Google responds**

```
Google sends response:
  Source IP:   142.250.190.46
  Source Port: 443
  Dest IP:     203.45.67.89 (router's public IP)
  Dest Port:   54321
```

**Step 5: Router receives response**

```
Router receives packet on WAN interface
Checks NAT table:
  Dest port 54321 → belongs to 192.168.1.45:54321

Router translates back:
  Old Dest IP:   203.45.67.89
  New Dest IP:   192.168.1.45
```

**Step 6: Router forwards to laptop**

```
Router sends packet to LAN:
  Dest IP:     192.168.1.45
  Dest Port:   54321

Laptop receives response. Communication successful!
```

---

### Visual: Complete NAT Flow

```
┌──────────────────────────────────────────────────────────┐
│  Home Network (192.168.1.0/24)                           │
│                                                          │
│  [Laptop: 192.168.1.45]                                  │
│        │                                                 │
│        │ 1. Outbound request                             │
│        │    Src: 192.168.1.45:54321                      │
│        │    Dst: 142.250.190.46:443                      │
│        ▼                                                 │
│  ┌─────────────────────┐                                 │
│  │  Router / NAT       │                                 │
│  │                     │                                 │
│  │  LAN: 192.168.1.1   │                                 │
│  │  WAN: 203.45.67.89  │                                 │
│  │                     │                                 │
│  │  NAT Table:         │                                 │
│  │  192.168.1.45:54321 │                                 │
│  │    ↔ 203.45.67.89:54321                               │
│  └─────────────────────┘                                 │
│        │                                                 │
│        │ 2. Translated request                           │
│        │    Src: 203.45.67.89:54321 ← Changed            │
│        │    Dst: 142.250.190.46:443                      │
└──────────────────────────────────────────────────────────┘
         │
         │ Internet
         ▼
[Google: 142.250.190.46]
  Response: Dst: 203.45.67.89:54321
         │
         │ Internet
         ▼
Router: checks NAT table, port 54321 → 192.168.1.45
  Dst: 192.168.1.45:54321 ← Changed back
         │
[Laptop receives response ✓]
```

---

## PAT: Port Address Translation

### The Real NAT Used at Home

**Basic NAT only changes IP addresses.**  
**PAT (also called NAT Overload) changes IP AND ports.**

**This is what your home router actually uses.**

---

### Why PAT Is Needed

**Problem with basic NAT:**

```
Two devices access same server with same source port:

Laptop:  192.168.1.45:54321 → Google:443
Phone:   192.168.1.67:54321 → Google:443

Both translate to: 203.45.67.89:54321

Google responds to: 203.45.67.89:54321

Router: Which device should receive it?
  Laptop or Phone?

❌ Ambiguous! NAT table collision!
```

---

### How PAT Solves This

**PAT changes BOTH IP and port:**

```
Laptop request:
  Original: 192.168.1.45:54321 → Google:443
  After PAT: 203.45.67.89:10001 → Google:443

Phone request:
  Original: 192.168.1.67:54321 → Google:443
  After PAT: 203.45.67.89:10002 → Google:443

PAT Table:
  192.168.1.45:54321 ↔ 203.45.67.89:10001
  192.168.1.67:54321 ↔ 203.45.67.89:10002

No collision — each connection has unique translated port.
```

---

### Port Allocation in PAT

**Router allocates ports from dynamic range:**

```
Port range: 49152-65535 (dynamic ports)
Total available: 16,384 ports

Each connection gets unique port:
  Connection 1: 203.45.67.89:49152
  Connection 2: 203.45.67.89:49153
  ...

One public IP can support ~16,000 simultaneous connections
```

---

## The NAT Table

### What's in the NAT Table

**NAT table tracks all active translations:**

```
Internal IP:Port  ↔  External IP:Port  ↔  Remote IP:Port  Timeout
192.168.1.45:54321 ↔ 203.45.67.89:49152 ↔ 142.250.190.46:443  300s
192.168.1.45:54322 ↔ 203.45.67.89:49153 ↔ 93.184.216.34:80    300s
192.168.1.67:51234 ↔ 203.45.67.89:49154 ↔ 142.250.190.46:443  300s
```

---

### NAT Table Timeout

**Entries expire after inactivity:**

```
TCP connection:
  Active: Entry stays alive
  Idle for 5 minutes: Entry removed

UDP (connectionless):
  Packet sent: Entry created
  Idle for 30-60 seconds: Entry removed
```

**Why timeout matters:**

```
Long idle connection:
  Client thinks connection is alive
  NAT table entry expired (timed out)
  Client sends data — packet dropped

Solution: TCP keepalive or reconnect
```

---

### View NAT Table

**On Linux router:**

```bash
# Using conntrack
sudo conntrack -L

Output:
tcp 6 299 ESTABLISHED src=192.168.1.45 dst=142.250.190.46 \
  sport=54321 dport=443 \
  src=142.250.190.46 dst=203.45.67.89 \
  sport=443 dport=49152
```

---

## Port Forwarding (Inbound NAT)

### The Problem

**NAT blocks inbound connections:**

```
You run web server on laptop: 192.168.1.45:8080

Friend tries: http://203.45.67.89:8080

Router checks NAT table:
  No entry for port 8080 (no outbound connection created it)
  Packet dropped

❌ Friend cannot reach your web server
```

---

### Port Forwarding Solution

**Create static NAT mapping:**

```
Port forwarding rule:
  External Port: 8080
  Internal IP:   192.168.1.45
  Internal Port: 8080
  Protocol:      TCP

Effect:
  "Forward all traffic to 203.45.67.89:8080
   to 192.168.1.45:8080"
```

---

### How Port Forwarding Works

```
Friend → http://203.45.67.89:8080

1. Packet arrives at router: Dst 203.45.67.89:8080
2. Router checks port forwarding rules
3. Port 8080 → 192.168.1.45:8080
4. Router rewrites Dst → 192.168.1.45:8080
5. Forwards to laptop
6. Laptop responds
7. Router reverse NATs
8. Friend receives response
```

---

### Common Port Forwarding Use Cases

```
✅ Hosting game servers
✅ Running web servers at home
✅ Remote desktop access
✅ Security cameras (remote viewing)
✅ Home automation systems
```

---

## NAT Types and Variations

### Source NAT (SNAT)

**Outbound translation — what we've been discussing:**

```
Changes source IP going outbound
Private → Public
  Src: 192.168.1.45 → 203.45.67.89
```

---

### Destination NAT (DNAT)

**Port forwarding — inbound translation:**

```
Changes destination IP coming inbound
Public → Private
  Dst: 203.45.67.89:8080 → 192.168.1.45:8080
```

---

### Static NAT

**One-to-one mapping:**

```
192.168.1.100 ↔ 203.45.67.100 (always)

Used when: Multiple public IPs available
```

---

### NAT Overload (PAT)

**What home routers use:**

```
Many-to-one mapping using ports

Many private IPs → One public IP
Differentiated by port numbers
```

---

## Real Scenarios

### Scenario 1: Home Network NAT

**All devices browse internet simultaneously:**

```
PAT Table (simplified):

Internal              External              Remote
192.168.1.45:54321 ↔ 203.45.67.89:49152 ↔ 142.250.190.46:443
192.168.1.67:51234 ↔ 203.45.67.89:49153 ↔ 142.250.190.46:443
192.168.1.89:48901 ↔ 203.45.67.89:49154 ↔ 93.184.216.34:80

Three devices, one public IP
Differentiated by port number
```

---

### Scenario 2: Port Forwarding for Game Server

**Setup:**

```
Public IP: 203.45.67.89
Game Server: 192.168.1.100:25565 (Minecraft)
```

**Port forwarding rule:**

```
External Port: 25565
Internal IP:   192.168.1.100
Internal Port: 25565
Protocol:      TCP
```

**Connection flow:**

```
Friend connects: 203.45.67.89:25565

1. Router checks port forwarding: 25565 → 192.168.1.100
2. Router translates destination
3. Packet forwarded to game server
4. Game server responds
5. Router performs reverse NAT
6. Friend receives response
8. Connection established
```

---

> **Docker implementation:** Docker port binding (`-p 8080:80`) is NAT in action — Docker creates iptables DNAT rules that forward host ports to container ports. The full breakdown with verification commands is in the Docker notes.
> → [Docker Networking](../../04.%20Docker%20–%20Containerization/05-docker-networking/README.md)

> **AWS implementation:** AWS NAT Gateway lets private EC2 instances access the internet without a public IP — same principle as your home router but managed by AWS. The full architecture, HA patterns, and Terraform examples are in the AWS notes.
> → [AWS VPC & Subnets](../../06.%20AWS%20–%20Cloud%20Infrastructure/03-vpc-subnet/README.md)

---

## Final Compression

### Why NAT Exists

```
Problem: Not enough public IPv4 addresses
Solution: Many private IPs share one public IP

Your home: 10 devices, 1 public IP
```

---

### How NAT Works

**Outbound (Private → Public):**
```
Device sends:
  Src: 192.168.1.45:54321 (private)
  
Router translates:
  Src: 203.45.67.89:49152 (public)
  
Records in NAT table
```

**Inbound (Public → Private):**
```
Response arrives:
  Dst: 203.45.67.89:49152
  
Router checks NAT table:
  Port 49152 → 192.168.1.45:54321
  
Router translates:
  Dst: 192.168.1.45:54321
```

---

### PAT (What Routers Actually Use)

```
Changes BOTH IP and port
Allows many devices to share one IP

192.168.1.45:54321 → 203.45.67.89:49152
192.168.1.67:51234 → 203.45.67.89:49153

Same public IP, different ports
```

---

### Port Forwarding (Inbound NAT)

```
Static mapping for inbound connections

Rule: External:8080 → Internal:192.168.1.45:8080

Use cases: Game servers, web hosting, remote access
```

---

### Router's Two IPs

```
LAN (Internal):
  IP: 192.168.1.1 (private)
  Your devices connect here

WAN (External):
  IP: 203.45.67.89 (public, from ISP)
  Internet connection

One foot in each network
```

---

### NAT Limitations

```
❌ Breaks end-to-end connectivity
❌ Inbound connections blocked (unless port forwarding)
❌ Some protocols don't work well (SIP, FTP)
✅ Works for most common protocols (HTTP, HTTPS, SSH)
```

---

### Mental Model

```
NAT = Translator between two worlds

Private world (home/office):
  Many devices, private IPs

Public world (internet):
  One public IP

Router = Translator:
  Remembers conversations (NAT table)
  Changes addresses (translation)
  Ensures responses reach correct device
```

---

### What You Can Do Now

✅ Understand why private IPs need NAT  
✅ Know how PAT works (IP + port translation)  
✅ Configure port forwarding  
✅ Know router has two IPs (LAN + WAN)  
✅ Debug NAT-related connectivity issues  

---

---

## What This Means for the Webstore

The webstore server has a private IP on the network — `10.0.1.45` or similar. When it receives a request from a browser on the internet, that request arrived at the public IP of the router, which NAT-translated it inbound to `10.0.1.45`. The browser never knew the server's private IP. When the server responds, the router translates the source IP back to public before sending it out. This NAT process is invisible in both directions. When you later configure `docker run -p 8080:80`, Docker is creating a DNAT rule in iptables — the exact same mechanism described in this file, applied at the container level. The concept is identical. The scope is smaller.

→ Ready to practice? [Go to Lab 03](../networking-labs/03-ports-transport-nat-lab.md)

---
# TOOL: 03. Networking – Foundations | FILE: 08-dns
---

# File 08: DNS

[Home](../README.md) |
[Foundation](../01-foundation-and-the-big-picture/README.md) |
[Addressing](../02-addressing-fundamentals/README.md) |
[IP Deep Dive](../03-ip-deep-dive/README.md) |
[Network Devices](../04-network-devices/README.md) |
[Subnets & CIDR](../05-subnets-cidr/README.md) |
[Ports & Transport](../06-ports-transport/README.md) |
[NAT](../07-nat/README.md) |
[DNS](../08-dns/README.md) |
[Firewalls](../09-firewalls/README.md) |
[Complete Journey](../10-complete-journey/README.md)

---

# DNS (Domain Name System)

## What this file is about

This file teaches **how domain names are translated into IP addresses** and **how the DNS system works globally**. If you understand this, you'll know why websites sometimes load slowly, how caching and TTL affect changes, and how to debug DNS issues. How Docker and AWS implement DNS on top of these concepts is covered in their respective notes.

<!-- no toc -->
- [The Core Problem](#the-core-problem)
- [What Is DNS?](#what-is-dns)
- [How DNS Resolution Works](#how-dns-resolution-works)
- [DNS Record Types](#dns-record-types)
- [DNS Caching](#dns-caching)
- [DNS Servers and Hierarchy](#dns-servers-and-hierarchy)
- [Public DNS Servers](#public-dns-servers)
- [DNS Debugging](#dns-debugging)  
[Final Compression](#final-compression)

---

## The Core Problem

### The Human vs Computer Challenge

**Humans prefer names:**

```
google.com
github.com
stackoverflow.com
mycompany.internal
```

**Computers need IP addresses:**

```
142.250.190.46
140.82.121.4
151.101.1.69
10.0.1.50
```

**The problem:** How do we bridge this gap?

---

### Before DNS (The Dark Ages)

**1970s-1980s: hosts.txt file**

```
Every computer had a file: /etc/hosts

Contents:
10.1.1.5    server1
10.1.1.6    server2
10.1.1.7    database

Problem:
  - Manual updates
  - No central authority
  - Didn't scale
  - File grew huge
```

**Stanford Research Institute maintained master hosts.txt — this broke when internet grew beyond a few hundred hosts.**

---

### The DNS Solution (1983)

**Distributed, hierarchical, automated system:**

```
✅ No single file to maintain
✅ Automatic lookups
✅ Scales globally
✅ Distributed authority
✅ Caching for speed
```

---

## What Is DNS?

### Definition

**DNS = Domain Name System**

**Purpose:** Translate human-readable domain names into IP addresses.

**Analogy:** DNS is like a phone book for the internet.

```
Phone book:
  Name: "Pizza Place" → Phone: 555-1234

DNS:
  Domain: google.com → IP: 142.250.190.46
```

---

### DNS Is a Distributed Database

**Not one server, but millions:**

```
Root DNS servers:        13 worldwide
Top-level domain (TLD):  Hundreds (.com, .org, .uk, etc.)
Authoritative servers:   Millions (each domain has one)
Recursive resolvers:     Thousands (ISPs, Google, Cloudflare)
```

---

## How DNS Resolution Works

### The Complete DNS Query Process

**You type `www.google.com` in browser:**

---

### Step 1: Check Local Cache

```
Browser: "Have I looked up www.google.com recently?"

If cached and not expired:
  Use cached IP
  Done! (milliseconds)
```

---

### Step 2: Check OS Cache

```
Operating system cache check

If cached:
  Return IP to browser
  Done!
```

---

### Step 3: Check /etc/hosts File

```
/etc/hosts contains:
  127.0.0.1       localhost
  192.168.1.100   myserver.local

If www.google.com is in this file:
  Use that IP (manual override)
```

---

### Step 4: Query Recursive DNS Resolver

**Your computer asks configured DNS server:**

```
Your DNS server (configured in network settings):
  8.8.8.8 (Google DNS)
  or 1.1.1.1 (Cloudflare)
  or 192.168.1.1 (Router)

Query sent via UDP port 53:
  "What's the IP for www.google.com?"
```

---

### Step 5-8: Root → TLD → Authoritative → Answer

```
Recursive resolver → Root server
  "I don't know, but .com TLD is at 192.5.6.30"

Recursive resolver → .com TLD server
  "I don't know, but google.com's NS is ns1.google.com"

Recursive resolver → ns1.google.com
  "www.google.com = 142.250.190.46" ← Final answer

Resolver caches result (TTL: 300s)
Returns to your browser
```

---

### Visual: Complete DNS Resolution

```
┌──────────────┐
│  Your Browser│
└──────┬───────┘
       │ 1. "What's google.com?"
       ▼
┌──────────────────────────┐
│ Browser Cache → OS Cache │
│ /etc/hosts → All miss    │
└──────┬───────────────────┘
       │ 2. UDP query to DNS server
       ▼
┌─────────────────────────┐
│ Recursive Resolver      │
│ (8.8.8.8) — cache miss  │
└──────┬──────────────────┘
       │ 3. Root servers
       │ 4. .com TLD
       │ 5. google.com NS
       ▼
┌─────────────────────────┐
│ Authoritative Server    │
│ (ns1.google.com)        │
│ "142.250.190.46"        │
└──────┬──────────────────┘
       │ 6. Answer returned + cached
       ▼
┌────────────────┐
│ Your Browser   │
│ Connects to    │
│ 142.250.190.46 │
└────────────────┘
```

---

### Timing Breakdown

```
First query (cache miss):   ~70ms total
Subsequent queries (hit):   <1ms (cached)

This is why first page load feels slower.
```

---

## DNS Record Types

### Common Record Types

---

### A Record (Address)

**Maps domain to IPv4 address:**

```
google.com.        300    IN    A    142.250.190.46
```

**Use case:** Most common, points domain to server IP.

---

### AAAA Record (IPv6 Address)

**Maps domain to IPv6 address:**

```
google.com.    300    IN    AAAA    2607:f8b0:4004:c07::71
```

---

### CNAME Record (Canonical Name)

**Alias one domain to another:**

```
www.example.com.    300    IN    CNAME    example.com.
```

**Use case:** Aliases, subdomains pointing to main domain.

---

### MX Record (Mail Exchange)

**Specifies mail server:**

```
example.com.    300    IN    MX    10 mail.example.com.
```

**Priority:** Lower number = higher priority.

---

### TXT Record (Text)

**Arbitrary text data:**

```
example.com.    300    IN    TXT    "v=spf1 include:_spf.google.com ~all"
```

**Common uses:** SPF, DKIM, domain verification.

---

### NS Record (Name Server)

**Specifies authoritative DNS servers:**

```
google.com.    300    IN    NS    ns1.google.com.
```

---

### PTR Record (Pointer — Reverse DNS)

**Maps IP address to domain:**

```
46.190.250.142.in-addr.arpa.    IN    PTR    google.com.
```

**Use case:** Email servers (anti-spam), verification.

---

### Record Type Summary

| Type | Purpose | Example |
|------|---------|---------|
| **A** | IPv4 address | example.com → 93.184.216.34 |
| **AAAA** | IPv6 address | example.com → 2606:... |
| **CNAME** | Alias | www → example.com |
| **MX** | Mail server | Mail to mail.example.com |
| **TXT** | Text data | SPF, DKIM, verification |
| **NS** | Nameserver | Delegates to ns1.example.com |
| **PTR** | Reverse lookup | IP → domain |

---

## DNS Caching

### Why Caching Exists

**Without caching:**

```
Every page load = DNS query = 70ms overhead
100 queries/second = slow
```

**With caching:**

```
First query: 70ms (full lookup)
Next 299 seconds: <1ms (cached)
```

---

### Caching Layers

```
1. Browser cache          — respects TTL
2. Operating system cache — respects TTL
3. Recursive resolver     — respects TTL (all users benefit)
4. Authoritative server   — source of truth (doesn't cache)
```

---

### TTL (Time To Live)

**TTL = How long to cache the record**

```
example.com.    300    IN    A    93.184.216.34
                └─┘
                TTL (seconds)

300 seconds = 5 minutes
```

**Common TTL values:**

```
60 seconds    - Frequently changing (during migrations)
300 seconds   - Common default (5 minutes)
3600 seconds  - Standard (1 hour)
86400 seconds - Long-term stable (24 hours)
```

---

### TTL Impact

**Short TTL (60 seconds):**

```
✅ Changes propagate quickly
✅ Good for deployments/migrations
❌ More DNS queries
```

**Long TTL (86400 seconds):**

```
✅ Fewer queries, better performance
❌ Changes take 24 hours to propagate
```

**Best practice:**

```
Normal operation:  Long TTL (3600-86400s)
Before changes:    Reduce TTL (60-300s)
After changes:     Restore long TTL
```

---

### DNS Propagation

**"DNS propagation" = cache expiration worldwide**

```
Old record: example.com → 1.2.3.4 (TTL: 3600s)
Change to:  example.com → 5.6.7.8

Propagation time: up to 1 hour (old TTL)

Best practice: Reduce TTL to 60s first, wait for old TTL to expire,
then make the change. Propagates in 60 seconds.
```

---

### Flush DNS Cache

**Windows:**
```cmd
ipconfig /flushdns
```

**Mac:**
```bash
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder
```

**Linux (systemd-resolved):**
```bash
sudo systemd-resolve --flush-caches
```

---

## DNS Servers and Hierarchy

### The DNS Hierarchy

```
                    . (Root)
                    │
        ┌───────────┼───────────┐
        │           │           │
       .com        .org        .net  (TLDs)
        │
    ┌───┴───┐
 google.com  example.com
```

---

### Root DNS Servers

**13 root server clusters (labeled A-M):**

```
a.root-servers.net ... m.root-servers.net

Actually hundreds of servers worldwide
Anycast routing to nearest instance
```

**Root servers know:** All TLD servers. NOT individual domains.

---

### TLD Servers

**Top-Level Domain servers:**

```
Generic TLDs: .com, .org, .net, .info
Country code: .us, .uk, .de, .jp
New TLDs:     .io, .dev, .app, .cloud
```

**TLD servers know:** Authoritative nameservers for domains under that TLD. NOT actual IPs.

---

### Authoritative DNS Servers

**Final authority for a domain:**

```
Google's authoritative servers:
  ns1.google.com, ns2.google.com, ns3.google.com, ns4.google.com

These contain the actual DNS records.
```

---

### Recursive Resolvers

**Do the heavy lifting:**

```
Examples:
  Google Public DNS: 8.8.8.8, 8.8.4.4
  Cloudflare: 1.1.1.1, 1.0.0.1

Job:
  1. Receive query from client
  2. Query root → TLD → authoritative
  3. Cache the result
  4. Return answer to client
```

---

## Public DNS Servers

### Popular Public DNS Providers

**Google Public DNS:**

```
Primary:   8.8.8.8
Secondary: 8.8.4.4

✅ Fast and reliable
❌ Google logs queries
```

**Cloudflare DNS:**

```
Primary:   1.1.1.1
Secondary: 1.0.0.1

✅ Often fastest
✅ Privacy-focused
✅ Malware blocking available (1.1.1.2)
```

**Quad9:**

```
Primary:   9.9.9.9
Secondary: 149.112.112.112

✅ Blocks malicious domains
✅ Privacy-focused
```

---

### Configure DNS Servers

**Linux (systemd-resolved):**

```bash
# Edit /etc/systemd/resolved.conf
[Resolve]
DNS=1.1.1.1 8.8.8.8
FallbackDNS=1.0.0.1 8.8.4.4

sudo systemctl restart systemd-resolved
```

**Linux (old method):**

```bash
# Edit /etc/resolv.conf
nameserver 1.1.1.1
nameserver 8.8.8.8
```

---

### Why Use Public DNS

```
✅ Often faster
✅ More reliable
✅ Better privacy (some providers)
✅ Malware/ad blocking (some providers)
✅ Bypass ISP DNS hijacking
```

---

> **Docker implementation:** Docker runs an embedded DNS server at `127.0.0.11` on every custom network. Containers resolve each other by name automatically — no manual IP management needed. The full DNS setup with verification commands is in the Docker notes.
> → [Docker Networking](../../04.%20Docker%20–%20Containerization/05-docker-networking/README.md)

> **AWS implementation:** AWS Route 53 is a globally distributed DNS service with routing policies (latency, weighted, failover, geolocation), health checks, and tight AWS integration. The full Route 53 setup with Terraform examples is in the AWS notes.
> → [AWS Route 53](../../06.%20AWS%20–%20Cloud%20Infrastructure/13-route53/README.md)

---

## DNS Debugging

### Common DNS Tools

---

### nslookup

**Basic DNS lookup:**

```bash
nslookup google.com

Output:
Server:         8.8.8.8
Address:        8.8.8.8#53

Non-authoritative answer:
Name:   google.com
Address: 142.250.190.46
```

**Query specific DNS server:**

```bash
nslookup google.com 1.1.1.1
```

**Query specific record type:**

```bash
nslookup -type=MX google.com
```

---

### dig (More detailed)

**Basic query:**

```bash
dig google.com

;; ANSWER SECTION:
google.com.    300    IN    A    142.250.190.46

;; Query time: 23 msec
;; SERVER: 8.8.8.8#53
```

**Short format:**

```bash
dig google.com +short
```

**Trace full resolution path:**

```bash
dig +trace google.com
```

**Query specific record type:**

```bash
dig MX google.com
dig AAAA google.com
dig TXT google.com
dig NS google.com
```

---

### Debugging Workflow

**Step 1: Can you resolve the name?**

```bash
nslookup example.com

If fails:
  - DNS server unreachable
  - Domain doesn't exist
  - Network issue
```

**Step 2: What IP did it resolve to?**

```bash
dig example.com +short

If wrong IP:
  - DNS cache stale (flush cache)
  - DNS propagation in progress
  - Wrong DNS record configured
```

**Step 3: Can you reach the IP?**

```bash
ping 93.184.216.34

If fails → Firewall or network issue
If succeeds → DNS is fine, problem is application-level
```

**Step 4: Check from different DNS servers**

```bash
dig @8.8.8.8 example.com
dig @1.1.1.1 example.com

If different results → DNS propagation issue
```

**Step 5: Trace full path**

```bash
dig +trace example.com
```

---

### Common DNS Issues

**Issue 1: NXDOMAIN**
```
Causes: Typo in domain, domain not registered, record not created
Fix: Check spelling, verify domain ownership, create DNS records
```

**Issue 2: Timeout**
```
Causes: DNS server unreachable, firewall blocking port 53
Fix: Try different DNS server, check firewall rules
```

**Issue 3: Wrong IP returned**
```
Causes: Stale cache, wrong DNS record, DNS hijacking
Fix: Flush DNS cache, verify authoritative record, use public DNS
```

**Issue 4: Slow resolution**
```
Causes: Slow DNS server, network latency
Fix: Switch to faster DNS (1.1.1.1)
```

---

## Final Compression

### What Is DNS?

```
DNS = Phone book for the internet

Domain name → IP address
  google.com → 142.250.190.46
```

---

### DNS Resolution Process

```
1. Check browser cache
2. Check OS cache
3. Check /etc/hosts
4. Query recursive resolver (8.8.8.8)
5. Resolver: root → TLD → authoritative
6. Return answer
7. Cache at all levels
```

---

### DNS Record Types (Essential)

```
A      - Domain to IPv4
AAAA   - Domain to IPv6
CNAME  - Alias (www → example.com)
MX     - Mail server
TXT    - Text data (SPF, verification)
NS     - Nameserver delegation
```

---

### TTL (Time To Live)

```
60s     - Short (migrations)
300s    - Common default
3600s   - Standard (1 hour)
86400s  - Long (24 hours)

Lower TTL = Faster changes, more queries
Higher TTL = Slower changes, fewer queries
```

---

### Public DNS Servers

```
Google:     8.8.8.8, 8.8.4.4
Cloudflare: 1.1.1.1, 1.0.0.1
Quad9:      9.9.9.9
```

---

### DNS Debugging

```
nslookup google.com     - Basic lookup
dig google.com          - Detailed lookup
dig +trace google.com   - Full path trace

Flush cache:
  Windows: ipconfig /flushdns
  Mac:     sudo killall -HUP mDNSResponder
  Linux:   sudo systemd-resolve --flush-caches
```

---

### Mental Model

```
DNS = Global distributed database

Your query:
  "What's google.com?"

DNS journey:
  Your computer → Resolver → Root → TLD → Authoritative
  
Answer: "142.250.190.46"
Cached everywhere for speed
Expires after TTL
```

---

### What You Can Do Now

✅ Understand how DNS resolution works  
✅ Know common DNS record types  
✅ Configure public DNS servers  
✅ Debug DNS issues with dig/nslookup  
✅ Understand DNS caching and TTL  
✅ Plan DNS changes with TTL reduction  

---

---

## What This Means for the Webstore

When you register `webstore.example.com` and create an A record pointing to the server's public IP, every browser goes through the full DNS resolution chain before it can connect. The TTL on that A record controls how long DNS caches the answer. If you move the webstore to a new server, old DNS caches will keep sending traffic to the old IP until the TTL expires — this is why DNS changes always require a propagation wait. On the server itself, adding an entry like `10.0.1.50 webstore-db` to `/etc/hosts` lets the API connect to the database by hostname without a real DNS server. The OS resolves it locally, the query never goes to a DNS server, and the connection works.

→ Ready to practice? [Go to Lab 04](../networking-labs/04-dns-firewalls-lab.md)

---
# TOOL: 03. Networking – Foundations | FILE: 09-firewalls
---

# File 09: Firewalls & Security

[Home](../README.md) |
[Foundation](../01-foundation-and-the-big-picture/README.md) |
[Addressing](../02-addressing-fundamentals/README.md) |
[IP Deep Dive](../03-ip-deep-dive/README.md) |
[Network Devices](../04-network-devices/README.md) |
[Subnets & CIDR](../05-subnets-cidr/README.md) |
[Ports & Transport](../06-ports-transport/README.md) |
[NAT](../07-nat/README.md) |
[DNS](../08-dns/README.md) |
[Firewalls](../09-firewalls/README.md) |
[Complete Journey](../10-complete-journey/README.md)

---

# Firewalls & Security

## What this file is about

This file teaches **how to control network access using firewall rules** and **the critical difference between stateful and stateless firewalls**. If you understand this, you'll be able to reason about any firewall — Linux iptables, AWS Security Groups, AWS NACLs, Docker network rules. The universal concepts are here. How AWS implements stateful and stateless firewalls on top of these concepts is covered in the AWS notes.

<!-- no toc -->
- [The Core Problem](#the-core-problem)
- [What Is a Firewall?](#what-is-a-firewall)
- [Firewall Rules (The Basics)](#firewall-rules-the-basics)
- [Stateful vs Stateless (CRITICAL)](#stateful-vs-stateless-critical)
- [Linux Firewall — iptables](#linux-firewall--iptables)
- [Common Firewall Scenarios](#common-firewall-scenarios)
- [Production Debugging Framework](#production-debugging-framework)  
[Final Compression](#final-compression)

---

## The Core Problem

### Unrestricted Access Is Dangerous

**Scenario: Server with no firewall**

```
Your web server: 203.45.67.89

Open ports:
├─ 22   (SSH)
├─ 80   (HTTP)
├─ 443  (HTTPS)
├─ 3306 (MySQL)
├─ 5432 (PostgreSQL)
└─ 6379 (Redis)

Attacker from 123.45.67.89:
  ✅ Can try SSH brute force (port 22)
  ✅ Can access database directly (port 3306)
  ✅ Can connect to Redis (port 6379)

Result: Security nightmare
```

---

### What You Actually Need

**Principle of least privilege:**

```
✅ Allow HTTP from anyone (port 80)
✅ Allow HTTPS from anyone (port 443)
✅ Allow SSH from office only (port 22 from 203.0.113.0/24)
❌ Block database ports from internet (3306, 5432)
❌ Block Redis from internet (6379)

Only expose what's necessary
Restrict everything else
```

---

## What Is a Firewall?

### Definition

**Firewall:**  
A network security system that monitors and controls incoming and outgoing network traffic based on predetermined security rules.

---

### Firewall Placement

**Network firewall (between networks):**

```
┌──────────────┐         ┌──────────┐         ┌──────────┐
│   Internet   │ ←────→  │ Firewall │ ←────→  │ Internal │
│              │         │          │         │ Network  │
└──────────────┘         └──────────┘         └──────────┘
```

**Host-based firewall (on server):**

```
┌────────────────────────────────┐
│     Server (203.45.67.89)      │
│                                │
│  ┌──────────────────────────┐  │
│  │   Firewall (iptables)    │  │
│  │  Allow 80, 443           │  │
│  │  Allow 22 from office    │  │
│  │  Block everything else   │  │
│  └──────────────────────────┘  │
│               │                │
│       ┌───────┴────────┐       │
│       │   Application  │       │
│       └────────────────┘       │
└────────────────────────────────┘
```

---

### Firewall Types

**Packet filtering (Layer 3-4):**

```
Examines: Source IP, Destination IP, ports, protocol
Decision: Allow or deny
Examples: iptables, AWS Security Groups, NACLs
```

**Stateful inspection (Layer 3-4, connection-aware):**

```
Tracks connection state
Remembers outbound requests
Auto-allows return traffic
Examples: AWS Security Groups, modern firewalls
```

**Application layer (Layer 7):**

```
Inspects application data
Can block based on URLs, HTTP headers, content
Examples: Web Application Firewall (WAF), proxy servers
```

---

## Firewall Rules (The Basics)

### Rule Components

**Every firewall rule specifies:**

```
1. Direction (inbound or outbound)
2. Protocol (TCP, UDP, ICMP, or ALL)
3. Port range (22, 80, 443, or range)
4. Source (where traffic comes FROM)
5. Destination (where traffic goes TO)
6. Action (ALLOW or DENY)
```

---

### Rule Example (Inbound)

```
Rule: Allow SSH from office

Direction:   Inbound
Protocol:    TCP
Port:        22
Source:      203.0.113.0/24 (office network)
Action:      ALLOW
```

---

### Rule Example (Outbound)

```
Rule: Allow HTTPS to internet

Direction:   Outbound
Protocol:    TCP
Port:        443
Destination: 0.0.0.0/0 (anywhere)
Action:      ALLOW
```

---

### Default Policy

**Firewalls have a default action:**

**Default DENY (recommended — whitelist approach):**

```
Default: DENY all traffic

Explicit rules:
  ALLOW port 80 from 0.0.0.0/0
  ALLOW port 443 from 0.0.0.0/0
  ALLOW port 22 from 203.0.113.0/24

Everything else: DENIED

Secure: Only explicitly allowed traffic passes
```

**Default ALLOW (dangerous — blacklist approach):**

```
Default: ALLOW all traffic

This is insecure — easy to forget to block something
```

**Best practice: Default DENY, explicitly ALLOW what's needed.**

---

### Source/Destination Notation

```
Single IP:     203.0.113.45/32
IP range:      203.0.113.0/24
Anywhere:      0.0.0.0/0 (all IPv4)
```

---

## Stateful vs Stateless (CRITICAL)

### The Most Important Concept in This File

**This single concept is responsible for more firewall misconfiguration than anything else.**

---

### What Is State?

**State = Memory of connections**

**Stateful firewall:**

```
✅ Remembers outbound connections
✅ Automatically allows return traffic
✅ Tracks connection state
✅ Smarter, easier to configure
```

**Stateless firewall:**

```
❌ No memory of connections
❌ Evaluates each packet independently
❌ Must explicitly allow BOTH directions
❌ Harder to configure correctly
```

---

### Stateful Example (Easy)

**Stateful firewall:**

```
Inbound rules:
  ALLOW TCP port 80 from 0.0.0.0/0

What happens:
  1. User → Your server (port 80)
     Inbound rule: ALLOW ✅

  2. Your server → User (return traffic)
     Firewall: "This is return traffic from allowed inbound"
     Automatically allowed ✅ (stateful behavior)

Connection works! ✅

You only needed ONE rule (inbound)
Return traffic automatically allowed
```

---

### Stateless Example (Hard)

**Stateless firewall:**

```
Inbound rules:
  ALLOW TCP port 80 from 0.0.0.0/0

Outbound rules:
  (none)

What happens:
  1. User (123.45.67.89:54321) → Your server (port 80)
     Inbound rule: ALLOW ✅

  2. Your server (port 80) → User (123.45.67.89:54321)
     Firewall: "Is there an outbound rule for port 54321?"
     NO rule exists ❌

     Response BLOCKED ❌

Connection FAILS! ❌

You needed TWO rules:
  - Inbound: Allow port 80
  - Outbound: Allow ephemeral ports (1024-65535)
```

---

### The Ephemeral Port Problem

**Why stateless is hard:**

```
User connects to your server on port 80
User's browser picks a random ephemeral port (49152-65535) as source

Your server's response goes back to that ephemeral port
Stateless firewall has no outbound rule for port 54321

Solution:
  Allow outbound TCP ports 1024-65535 (all ephemeral ports)

This is overly permissive but necessary for stateless firewalls.
```

---

### Stateful vs Stateless Summary Table

| Feature | Stateful | Stateless |
|---------|----------|-----------|
| **Remembers connections?** | ✅ Yes | ❌ No |
| **Auto-allows return traffic?** | ✅ Yes | ❌ No |
| **Rules needed** | Fewer (easier) | More (harder) |
| **Configuration complexity** | Low | High |
| **AWS example** | Security Groups | NACLs |

---

> **AWS implementation:** AWS Security Groups are stateful — they remember connections and auto-allow return traffic. AWS NACLs are stateless — you must explicitly allow both directions including ephemeral ports. The full setup, the NACL trap, and best practices are in the AWS VPC notes.
> → [AWS VPC & Subnets](../../06.%20AWS%20–%20Cloud%20Infrastructure/03-vpc-subnet/README.md)

---

## Linux Firewall — iptables

### What Is iptables?

**iptables** is the Linux kernel's built-in packet filtering firewall. AWS Security Groups and Docker networking both use iptables under the hood.

---

### Tables and Chains

**Tables:**
```
filter  - Default. Allow/deny packets.
nat     - Modify source/destination IPs (NAT, port forwarding).
mangle  - Modify packet headers.
```

**Chains (in the filter table):**
```
INPUT   - Packets destined FOR this machine
OUTPUT  - Packets originating FROM this machine
FORWARD - Packets passing THROUGH this machine
```

---

### Basic iptables Commands

**View current rules:**

```bash
# View filter table rules
sudo iptables -L -n -v

# View with line numbers (useful for deletion)
sudo iptables -L --line-numbers -n
```

**Allow inbound HTTP:**

```bash
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
```

**Allow inbound SSH from specific IP only:**

```bash
sudo iptables -A INPUT -p tcp --dport 22 -s 203.0.113.0/24 -j ACCEPT
```

**Block all inbound by default (after allowing needed ports):**

```bash
sudo iptables -P INPUT DROP
```

**Delete a rule by line number:**

```bash
sudo iptables -D INPUT 3
```

**Flush all rules (reset):**

```bash
sudo iptables -F
```

---

### Complete Minimal Server Example

**Allow HTTP, HTTPS, SSH — block everything else:**

```bash
# Start fresh
sudo iptables -F

# Allow established connections (stateful behavior)
sudo iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allow loopback
sudo iptables -A INPUT -i lo -j ACCEPT

# Allow SSH from office
sudo iptables -A INPUT -p tcp --dport 22 -s 203.0.113.0/24 -j ACCEPT

# Allow HTTP and HTTPS from anywhere
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT

# Block everything else inbound
sudo iptables -P INPUT DROP

# Allow all outbound (default)
sudo iptables -P OUTPUT ACCEPT
```

**Key line — stateful behavior:**
```bash
sudo iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
```

This is what makes iptables stateful. Without it, you'd need explicit rules for every return packet.

---

### Verify Rules

```bash
sudo iptables -L INPUT -n -v

Output:
Chain INPUT (policy DROP)
target     prot opt source     destination
ACCEPT     all  --  0.0.0.0/0  0.0.0.0/0   state RELATED,ESTABLISHED
ACCEPT     all  --  0.0.0.0/0  0.0.0.0/0   (loopback)
ACCEPT     tcp  --  203.0.113.0/24  0.0.0.0/0  tcp dpt:22
ACCEPT     tcp  --  0.0.0.0/0  0.0.0.0/0   tcp dpt:80
ACCEPT     tcp  --  0.0.0.0/0  0.0.0.0/0   tcp dpt:443
```

---

### NAT Rules (iptables nat table)

**Docker uses iptables nat rules for port binding:**

```bash
# View NAT rules
sudo iptables -t nat -L -n -v

# See DNAT rules Docker created
sudo iptables -t nat -L DOCKER -n

Output (after docker run -p 8080:80 nginx):
  DNAT tcp dpt:8080 to:172.17.0.2:80
```

This is exactly what happens when you run `docker run -p 8080:80` — Docker writes an iptables DNAT rule.

---

### ufw (Uncomplicated Firewall)

**ufw is a simpler front-end for iptables:**

```bash
# Check status
sudo ufw status verbose

# Allow port 80
sudo ufw allow 80/tcp

# Allow SSH from specific IP
sudo ufw allow from 203.0.113.0/24 to any port 22

# Enable (careful on remote servers — ensure SSH is allowed first!)
sudo ufw enable
```

---

## Common Firewall Scenarios

### Scenario 1: Can't SSH to Server

**Symptom:**

```bash
ssh user@54.123.45.67
# Hangs, then times out
```

**Debug checklist:**

```
☐ 1. Is port 22 open?
     nc -zv 54.123.45.67 22
     # Connection refused = nothing listening or firewall blocking

☐ 2. Check iptables rules
     sudo iptables -L INPUT -n | grep 22

☐ 3. Is your source IP allowed?
     Check if your current IP is in the allowed range

☐ 4. Is sshd running?
     sudo systemctl status sshd
```

---

### Scenario 2: Website Times Out

**Symptom:**

```bash
curl http://54.123.45.67
# Hangs, times out
```

**Debug:**

```
☐ 1. Is port 80 open?
     nc -zv 54.123.45.67 80

☐ 2. Check iptables
     sudo iptables -L INPUT -n | grep 80

☐ 3. Is web server running?
     sudo systemctl status nginx
     sudo netstat -tlnp | grep :80

☐ 4. Listening on correct interface?
     0.0.0.0:80 ✅ (all interfaces)
     127.0.0.1:80 ❌ (localhost only)
```

---

### Scenario 3: Database Connection Refused

**Symptom:**

```
App can't connect to database
Error: Connection refused to 10.0.3.50:5432
```

**Debug:**

```
☐ 1. Is PostgreSQL listening?
     sudo netstat -tlnp | grep :5432

☐ 2. Is PostgreSQL listening on correct interface?
     Check postgresql.conf:
     listen_addresses = '*'  (all interfaces)
     Not: listen_addresses = 'localhost'

☐ 3. Firewall allowing the port?
     sudo iptables -L INPUT -n | grep 5432

☐ 4. App server IP allowed?
     Check pg_hba.conf for client authentication
```

---

## Production Debugging Framework

### Systematic Approach

**When connection fails, debug in this order:**

---

### Step 1: DNS Resolution

```bash
nslookup database.internal
dig api.example.com

If fails: DNS issue
```

---

### Step 2: Network Reachability

```bash
ping 10.0.3.50

# If ICMP blocked, test a port:
nc -zv 10.0.3.50 5432
```

---

### Step 3: Port Accessibility

```bash
telnet 10.0.3.50 5432

Connection refused → Port not listening
Timeout → Firewall blocking
```

---

### Step 4: Firewall Check

```bash
# Local iptables
sudo iptables -L -n -v

# Cloud firewall (see AWS notes for Security Groups / NACLs)
```

---

### Step 5: Application Layer

```bash
sudo systemctl status postgresql
sudo netstat -tlnp | grep :5432
sudo journalctl -u postgresql -n 50
```

---

### Decision Tree

```
Connection fails
    │
    ▼
Can resolve DNS? → No → DNS issue
    │ Yes
    ▼
Can ping/reach IP? → No → Routing or firewall issue
    │ Yes
    ▼
Port accessible? → No → Firewall blocking or service not running
    │ Yes
    ▼
Service running? → No → Start/restart the service
    │ Yes
    ▼
Check application logs → Application-level issue
```

---

### Error Messages Guide

| Error | Meaning | Likely Cause |
|-------|---------|--------------|
| **Connection refused** | Port not listening | Service not running, wrong port |
| **Connection timeout** | No response | Firewall blocking, server down |
| **No route to host** | Routing problem | Network misconfigured |
| **Name or service not known** | DNS failure | DNS misconfigured |
| **Network unreachable** | No network path | Missing default route |

---

## Final Compression

### What Is a Firewall?

```
Firewall = Traffic filter

Allows or denies traffic based on:
  - Source IP
  - Destination IP
  - Port
  - Protocol
  
Purpose: Security
```

---

### Stateful vs Stateless (CRITICAL)

**Stateful:**
```
✅ Remembers connections
✅ Auto-allows return traffic
✅ Easier to configure

One rule needed (inbound only)
```

**Stateless:**
```
❌ No memory
❌ Must explicitly allow both directions
❌ Harder to configure

Two rules needed (inbound + outbound including ephemeral ports)
```

---

### iptables Essentials

```bash
# View rules
sudo iptables -L -n -v

# Allow port 80
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT

# Allow established connections (stateful)
sudo iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Block all inbound (after allowlist)
sudo iptables -P INPUT DROP
```

---

### Production Debugging Order

```
1. DNS working? (nslookup)
2. Network reachable? (ping, nc)
3. Port open? (telnet, nc -zv)
4. Firewall allowing? (iptables)
5. Service running? (systemctl, netstat)
```

---

### Common Scenarios

```
"Connection refused" → Service not running or wrong port
"Connection timeout" → Firewall blocking
"DNS not found"      → DNS misconfigured
"Network unreachable" → Routing issue
```

---

### Best Practices

```
✅ Default DENY policy
✅ Principle of least privilege
✅ Use stateful firewalls (easier and safer)
✅ Document all rules
✅ Test after every change
❌ Don't open all ports (0-65535)
❌ Don't allow SSH from 0.0.0.0/0 in production
```

---

### Mental Model

```
Stateful firewall = Smart bouncer
  Remembers who came in
  Lets them out automatically

Stateless firewall = Strict gate guard
  Checks everyone, both ways
  No memory

Use stateful for most cases.
Use stateless only when you need explicit DENY rules.
```

---

### What You Can Do Now

✅ Understand stateful vs stateless firewalls  
✅ Write iptables rules for common scenarios  
✅ Debug connectivity issues systematically  
✅ Know "connection refused" vs "timeout"  
✅ Apply principle of least privilege  

---

---

## What This Means for the Webstore

The webstore server needs exactly three inbound rules: allow port 80 (nginx), allow port 8080 (API), allow port 22 (SSH). Everything else is dropped by default. Postgres on port 5432 should never be reachable directly from outside — it accepts connections only from `127.0.0.1` or the server's local interface. A missing DROP rule on port 5432 means anyone on the internet can attempt to connect to the webstore database directly. The iptables setup from Linux Lab 05 enforces this: HTTP open to the world, SSH restricted to your IP, postgres not reachable from outside at all. This same logic is what AWS Security Groups enforce at the cloud level — different syntax, identical concept.

→ Ready to practice? [Go to Lab 04](../networking-labs/04-dns-firewalls-lab.md)

---
# TOOL: 03. Networking – Foundations | FILE: 10-complete-journey
---

# File 10: Complete Journey & OSI Deep Dive

[Home](../README.md) |
[Foundation](../01-foundation-and-the-big-picture/README.md) |
[Addressing](../02-addressing-fundamentals/README.md) |
[IP Deep Dive](../03-ip-deep-dive/README.md) |
[Network Devices](../04-network-devices/README.md) |
[Subnets & CIDR](../05-subnets-cidr/README.md) |
[Ports & Transport](../06-ports-transport/README.md) |
[NAT](../07-nat/README.md) |
[DNS](../08-dns/README.md) |
[Firewalls](../09-firewalls/README.md) |
[Complete Journey](../10-complete-journey/README.md)

---

# Complete Journey & OSI Deep Dive

## What this file is about

This file shows **how all networking concepts work together** in real packet flows. If you understand this, you can trace a packet from your browser to a server anywhere in the world, debug connectivity issues systematically, and understand what's happening at every layer of the network stack.

<!-- no toc -->
- [The Real Question](#the-real-question)
- [The OSI Model — Complete Picture](#the-osi-model--complete-picture)
- [Encapsulation — The Russian Nesting Doll](#encapsulation--the-russian-nesting-doll)
- [Journey 1: You Open google.com](#journey-1-you-open-googlecom)
- [Journey 2: LAN Communication (Same Subnet)](#journey-2-lan-communication-same-subnet)
- [Journey 3: Docker Container to Container](#journey-3-docker-container-to-container)
- [Journey 4: AWS Multi-Tier Application](#journey-4-aws-multi-tier-application)
- [The Troubleshooting Mindset](#the-troubleshooting-mindset)
- [Common Failure Points](#common-failure-points)  
[Final Compression](#final-compression)

---

## The Real Question

After learning about IP addresses, routers, DNS, NAT, and firewalls separately, one question remains:

**"What actually happens when I type google.com in my browser and press Enter?"**

This file answers that question completely — step by step, layer by layer, with nothing hidden.

---

## The OSI Model — Complete Picture

### Why OSI Exists

The OSI (Open Systems Interconnection) model is a framework that breaks networking into 7 layers. Each layer has a specific job. Understanding this model lets you:

- Debug problems systematically (which layer is broken?)
- Understand where different technologies fit (is DNS Layer 7 or Layer 3?)
- Communicate with other engineers (everyone uses this model)

### The 7 Layers

| Layer | Name | What It Does | Examples | Data Unit |
|-------|------|--------------|----------|-----------|
| **7** | Application | User-facing protocols | HTTP, DNS, SSH, FTP | Data/Messages |
| **6** | Presentation | Data formatting, encryption | SSL/TLS, JPEG, ASCII | Data |
| **5** | Session | Maintains connections | NetBIOS, RPC | Data |
| **4** | Transport | End-to-end delivery, reliability | TCP, UDP | Segments |
| **3** | Network | Routing between networks | IP, ICMP | Packets |
| **2** | Data Link | Local delivery, error detection | Ethernet, WiFi, ARP | Frames |
| **1** | Physical | Physical transmission | Cables, radio waves | Bits |

### How to Remember It

**Mnemonic (top to bottom):**
```
All People Seem To Need Data Processing
Application
Presentation
Session
Transport
Network
Data Link
Physical
```

**Or reverse (bottom to top):**
```
Please Do Not Throw Sausage Pizza Away
Physical
Data Link
Network
Transport
Session
Presentation
Application
```

---

### Visual: The Stack

```
┌─────────────────────────────────────────────┐
│  Layer 7: Application                       │
│  What: User-facing protocols                │
│  Example: HTTP, DNS, SSH                    │
│  Your browser lives here                    │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│  Layer 6: Presentation                      │
│  What: Data formatting, encryption          │
│  Example: SSL/TLS, compression              │
│  Makes data readable/secure                 │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│  Layer 5: Session                           │
│  What: Maintains connections                │
│  Example: Session management                │
│  Keeps conversations organized              │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│  Layer 4: Transport                         │
│  What: Ports, reliability                   │
│  Example: TCP (reliable), UDP (fast)        │
│  Creates: Segments                          │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│  Layer 3: Network                           │
│  What: IP addressing, routing               │
│  Example: IP, routers                       │
│  Creates: Packets                           │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│  Layer 2: Data Link                         │
│  What: MAC addressing, switches             │
│  Example: Ethernet, WiFi, ARP               │
│  Creates: Frames                            │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│  Layer 1: Physical                          │
│  What: Physical transmission                │
│  Example: Cables, WiFi radio, fiber         │
│  Transmits: Bits (1s and 0s)                │
└─────────────────────────────────────────────┘
```

---

### DevOps Reality: Which Layers Matter Most

**For cloud/DevOps engineers, you spend 90% of time in:**

- **Layer 7** (Application): HTTP, HTTPS, DNS, SSH
- **Layer 4** (Transport): TCP/UDP, ports
- **Layer 3** (Network): IP addresses, routing, subnets
- **Layer 2** (Data Link): Rarely touch directly (cloud abstracts this)

**Layers 5-6:** Mostly abstracted away (TLS happens automatically)  
**Layer 1:** Never touch (cloud provider handles physical)

---

## Encapsulation — The Russian Nesting Doll

### The Core Concept

**Each layer wraps the previous layer's data.**

When you send data:
1. Application creates data
2. Transport wraps it (adds TCP/UDP header)
3. Network wraps that (adds IP header)
4. Data Link wraps that (adds Ethernet header)
5. Physical transmits the bits

**Visual:**

```
┌──────────────────────────────────────────────────────────────┐
│ Ethernet Frame (Layer 2)                                     │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐  │
│  │ IP Packet (Layer 3)                                    │  │
│  │                                                        │  │
│  │  ┌──────────────────────────────────────────────────┐  │  │
│  │  │ TCP Segment (Layer 4)                            │  │  │
│  │  │                                                  │  │  │
│  │  │  ┌────────────────────────────────────────────┐  │  │  │
│  │  │  │ Application Data (Layer 7)                 │  │  │  │
│  │  │  │                                            │  │  │  │
│  │  │  │ "GET /index.html HTTP/1.1"                 │  │  │  │
│  │  │  │                                            │  │  │  │
│  │  │  └────────────────────────────────────────────┘  │  │  │
│  │  │                                                  │  │  │
│  │  └──────────────────────────────────────────────────┘  │  │
│  │                                                        │  │
│  └────────────────────────────────────────────────────────┘  │
│                                                              │
└──────────────────────────────────────────────────────────────┘

Each layer adds its own header (metadata).
The inner data is payload for the outer layer.
```

---

### What Each Header Contains

**Application Data (Layer 7):**
```
The actual content: "GET /index.html HTTP/1.1"
```

**TCP Header (Layer 4) adds:**
- Source port: 54321 (random)
- Destination port: 443 (HTTPS)
- Sequence numbers (for ordering)
- Flags (SYN, ACK, FIN)

**IP Header (Layer 3) adds:**
- Source IP: 192.168.1.45 (your laptop)
- Destination IP: 142.250.190.46 (Google)
- TTL (time to live)
- Protocol (TCP)

**Ethernet Header (Layer 2) adds:**
- Source MAC: AA:BB:CC:DD:EE:FF (your laptop)
- Destination MAC: 11:22:33:44:55:66 (router)
- EtherType (IPv4)

---

### The Critical Truth About MAC vs IP

**CRITICAL: Every packet contains BOTH MAC and IP headers.**

**They serve different purposes:**

| Header | Purpose | Changes During Journey? |
|--------|---------|------------------------|
| **IP Header** | Final destination | ❌ No — stays same from source to destination |
| **MAC Header** | Next hop | ✅ Yes — rewritten at every router |

**Example journey:**

```
Your laptop → Router → ISP Router → Google

Hop 1 (Laptop → Router):
  MAC src: Laptop MAC
  MAC dst: Router MAC  ← Changes at router
  IP src:  Laptop IP
  IP dst:  Google IP   ← Stays same

Hop 2 (Router → ISP):
  MAC src: Router MAC
  MAC dst: ISP MAC     ← Changed
  IP src:  Laptop IP
  IP dst:  Google IP   ← Still same

Hop N (Last → Google):
  MAC src: Router MAC
  MAC dst: Google MAC  ← Changed again
  IP src:  Laptop IP
  IP dst:  Google IP   ← Still same
```

**This is why:**
- MAC = local (only survives one hop)
- IP = global (survives entire journey)

---

## Journey 1: You Open google.com

**Scenario:** You're on your laptop at home, connected to WiFi. You type `google.com` in your browser.

**Network details:**
- Your laptop: 192.168.1.45 (private IP)
- Your router: 192.168.1.1 (LAN side), 203.45.67.89 (WAN side, public IP from ISP)
- Google server: 142.250.190.46

---

### Step-by-Step Complete Flow

#### Phase 1: DNS Resolution

**Step 1: Browser checks cache**
```
Browser: "Do I know google.com's IP?"
Cache: "No, never visited before"
```

**Step 2: OS DNS query**
```
Your laptop: "What's google.com?"
DNS query sent to: 8.8.8.8 (Google DNS)
Protocol: UDP port 53
```

**Step 3: DNS response**
```
DNS server: "google.com = 142.250.190.46"
Your laptop: Caches this for 5 minutes (TTL)
```

---

#### Phase 2: TCP Connection Establishment

**Step 4: TCP 3-way handshake begins**

```
Your laptop → Google

SYN packet:
  IP src: 192.168.1.45
  IP dst: 142.250.190.46
  TCP src port: 54321 (random)
  TCP dst port: 443 (HTTPS)
  Flags: SYN
```

**Step 5: Routing decision**
```
Your laptop checks:
"Is 142.250.190.46 in my subnet (192.168.1.0/24)?"

Subnet calculation:
142.250.X.X ≠ 192.168.1.X

Decision: Not local → send to default gateway (192.168.1.1)
```

**Step 6: ARP lookup**
```
Your laptop needs: Router's MAC address

ARP request (broadcast):
"Who has 192.168.1.1? Tell 192.168.1.45"

Router responds:
"192.168.1.1 is at MAC AA:BB:CC:DD:EE:FF"

Your laptop caches this.
```

---

#### Phase 3: Packet Creation (Encapsulation)

**Step 7: Build the packet**

```
Layer 7 (Application):
  Data: "SYN" (connection request)

Layer 4 (Transport):
  Wraps with TCP header:
    Src port: 54321
    Dst port: 443
    Flags: SYN
    Sequence: 1000

Layer 3 (Network):
  Wraps with IP header:
    Src IP: 192.168.1.45
    Dst IP: 142.250.190.46
    Protocol: TCP
    TTL: 64

Layer 2 (Data Link):
  Wraps with Ethernet header:
    Src MAC: [Your laptop MAC]
    Dst MAC: [Router MAC]  ← Next hop, not Google!
    Type: IPv4

Layer 1 (Physical):
  Converts to radio waves (WiFi)
  Transmits
```

**Key insight:** Destination MAC = router (next hop), not Google (final destination).

---

#### Phase 4: Router Processing

**Step 8: Router receives packet**

```
Router WiFi interface receives bits
Converts to frame
Checks Ethernet header:
  Dst MAC: [Router MAC] → "This is for me"

Router strips Ethernet header (de-encapsulation)
Reads IP header:
  Dst IP: 142.250.190.46 → "Not for me, forward it"

Router checks routing table:
  142.250.190.46 → Send via WAN interface to ISP
```

**Step 9: NAT translation**

```
Router's NAT table:

Before (LAN side):
  Src IP: 192.168.1.45
  Src port: 54321

After (WAN side):
  Src IP: 203.45.67.89 (router's public IP)
  Src port: 54321 (or remapped)

NAT logs:
"Port 54321 belongs to 192.168.1.45"
```

**Step 10: Router forwards packet**

```
Router creates new Ethernet frame:
  Src MAC: [Router WAN MAC]
  Dst MAC: [ISP Router MAC] ← Different MAC!

IP header (unchanged):
  Src IP: 203.45.67.89 (after NAT)
  Dst IP: 142.250.190.46

Router transmits via cable to ISP
```

---

#### Phase 5: Internet Journey

**Step 11: Multiple router hops**

```
ISP Router 1:
  Receives frame
  Strips Ethernet header
  Reads IP destination: 142.250.190.46
  Checks routing table: Forward to ISP Router 2
  Creates new Ethernet frame (new MACs)
  Forwards

ISP Router 2:
  Same process
  Forwards to ISP Router 3

... (10-20 hops) ...

Last Router:
  Knows Google is directly connected
  Forwards to Google's server
```

**At each hop:**
- ✅ MAC addresses change (new src/dst MACs)
- ❌ IP addresses stay same (src/dst IPs preserved)

---

#### Phase 6: Google Receives

**Step 12: Google's server receives packet**

```
Google server checks:
  Dst MAC: [Google server MAC] → "For me"
  Dst IP: 142.250.190.46 → "For me"

Google de-encapsulates:
  Strips Ethernet header
  Strips IP header
  Reads TCP header:
    Dst port: 443 → "HTTPS service"
    Flags: SYN → "New connection request"

Google's firewall checks:
  Port 443 from internet? → Allowed
```

**Step 13: Google responds (SYN-ACK)**

```
Google creates response:
  TCP flags: SYN-ACK
  Src IP: 142.250.190.46
  Dst IP: 203.45.67.89 (your router's public IP)
  Src port: 443
  Dst port: 54321

Packet travels back through internet
Same routing process in reverse
```

---

#### Phase 7: Return Journey

**Step 14: Router receives response**

```
Router WAN interface receives packet:
  Dst IP: 203.45.67.89 → "This is me"
  Dst port: 54321

Router checks NAT table:
  "Port 54321 = 192.168.1.45"

Router reverse NAT:
  Changes Dst IP: 203.45.67.89 → 192.168.1.45
  
Router forwards to LAN:
  New Ethernet frame:
    Src MAC: [Router LAN MAC]
    Dst MAC: [Your laptop MAC]
```

**Step 15: Your laptop receives**

```
Your laptop WiFi receives:
  Dst MAC: [Laptop MAC] → "For me"
  Dst IP: 192.168.1.45 → "For me"

De-encapsulates:
  TCP sees: SYN-ACK
  Browser: "Connection established!"
```

**Step 16: Final ACK**

```
Your laptop sends ACK to complete handshake
Connection now open
Browser can send HTTP request
```

---

#### Phase 8: HTTP Request

**Step 17: Browser sends request**

```
Application layer data:
GET / HTTP/1.1
Host: google.com

Encapsulated again:
  TCP segment (port 443)
  IP packet (to 142.250.190.46)
  Ethernet frame (to router MAC)

Same journey as before
```

**Step 18: Google responds with HTML**

```
Google sends:
HTTP/1.1 200 OK
Content-Type: text/html
<html>...</html>

Travels back through internet
NAT translation at router
Delivered to browser
```

**Step 19: Browser renders page**

```
Browser receives HTML
Parses it
Makes additional requests (CSS, JS, images)
Each request = new TCP connection or reuses existing
Renders google.com homepage
```

---

### Complete Timeline Summary

| Time | Event | Layer(s) |
|------|-------|----------|
| 0ms | Type google.com | L7 |
| 5ms | DNS query (UDP) | L7, L4, L3 |
| 25ms | DNS response | All layers |
| 30ms | TCP SYN sent | L7, L4, L3, L2, L1 |
| 30ms | ARP lookup (router MAC) | L2 |
| 31ms | Packet reaches router | All layers |
| 31ms | NAT translation | L3, L4 |
| 32ms | Packet forwarded to ISP | All layers |
| 50ms | Packet reaches Google | All layers (many hops) |
| 50ms | Google firewall check | L3, L4 |
| 51ms | SYN-ACK sent back | All layers |
| 70ms | Router receives, reverse NAT | L3, L4 |
| 71ms | Your laptop receives SYN-ACK | All layers |
| 71ms | ACK sent to complete handshake | All layers |
| 90ms | Connection established (TLS happens here) | L5, L6 |
| 100ms | HTTP GET request sent | L7 |
| 120ms | Google responds with HTML | L7 |
| 121ms | Browser renders page | L7 |

**Total time:** ~120ms (0.12 seconds)

---

### What You Just Learned

By tracing this one request, you now understand:

✅ **DNS resolution** (Application layer)  
✅ **TCP 3-way handshake** (Transport layer)  
✅ **Routing decisions** (Network layer)  
✅ **ARP translation** (Data Link layer)  
✅ **NAT operation** (Network/Transport layers)  
✅ **MAC address changes** (every hop)  
✅ **IP address preservation** (end-to-end)  
✅ **Encapsulation/de-encapsulation** (at every device)  
✅ **Firewall checks** (at destination)  

**This is the complete picture of networking.**

---

## Journey 2: LAN Communication (Same Subnet)

**Scenario:** Two computers on same WiFi network, no internet involved.

**Network setup:**
```
Computer A: 192.168.1.10
Computer B: 192.168.1.20
Subnet: 192.168.1.0/24
Gateway: 192.168.1.1 (exists but not used)
Switch/Access Point: Connects both
```

---

### The Flow (Much Simpler)

**Step 1: Computer A wants to send file to Computer B**

```
Application: File transfer app
Destination: 192.168.1.20
```

**Step 2: Routing decision**

```
Computer A checks:
"Is 192.168.1.20 in my subnet?"

Calculation:
My IP:     192.168.1.10
My mask:   255.255.255.0
My subnet: 192.168.1.0/24

Target:    192.168.1.20
Masked:    192.168.1.0/24

Match? YES → Send directly (no router needed)
```

**Step 3: ARP for Computer B's MAC**

```
Computer A broadcasts ARP:
"Who has 192.168.1.20? Tell 192.168.1.10"

Computer B responds:
"192.168.1.20 is at MAC BB:BB:BB:BB:BB:BB"

Computer A caches this
```

**Step 4: Build and send packet**

```
Ethernet Frame:
  Src MAC: [Computer A MAC]
  Dst MAC: [Computer B MAC] ← Direct to destination!

IP Packet:
  Src IP: 192.168.1.10
  Dst IP: 192.168.1.20

TCP Segment:
  Src port: 5000
  Dst port: 5001
  
Data: File contents
```

**Step 5: Switch forwards**

```
Switch receives frame
Checks destination MAC: BB:BB:BB:BB:BB:BB
Checks MAC table: "This MAC is on port 3"
Forwards frame only to port 3 (Computer B)
```

**Step 6: Computer B receives**

```
Computer B:
  Checks MAC → "For me"
  Checks IP → "For me"
  Delivers to file transfer app (port 5001)
```

---

### Key Differences from Internet Journey

| Aspect | Internet (Journey 1) | LAN (Journey 2) |
|--------|---------------------|-----------------|
| **Router used?** | ✅ Yes (multiple) | ❌ No |
| **NAT used?** | ✅ Yes | ❌ No |
| **DNS needed?** | ✅ Yes (domain names) | ❌ No (direct IP) |
| **MAC changes?** | ✅ Yes (every hop) | ❌ No (one hop) |
| **Hops** | 10-20 | 1 |
| **Speed** | ~100ms | <1ms |

---

## Journey 3: Docker Container to Container

**Scenario:** Two containers on same Docker network communicating.

**Setup:**
```bash
docker network create myapp-net --subnet=172.20.0.0/16
docker run -d --name web --network myapp-net nginx
docker run -d --name api --network myapp-net node-app
```

**Container details:**
```
web container: 172.20.0.2
api container: 172.20.0.3
Docker network: 172.20.0.0/16
```

---

### The Flow

**Step 1: Web container wants to call API**

```
Inside web container code:
fetch('http://api:3000/data')
```

**Step 2: Docker DNS resolution**

```
Container queries Docker's internal DNS:
"What's 'api'?"

Docker DNS responds:
"api = 172.20.0.3"
```

**Step 3: Routing decision**

```
Web container checks:
My IP: 172.20.0.2
Subnet: 172.20.0.0/16
Target: 172.20.0.3

In same subnet? YES → Direct communication
```

**Step 4: Packet sent via Docker bridge**

```
Docker bridge network = virtual switch

Ethernet Frame:
  Src MAC: [web container veth MAC]
  Dst MAC: [api container veth MAC]

IP Packet:
  Src IP: 172.20.0.2
  Dst IP: 172.20.0.3

TCP Segment:
  Src port: Random
  Dst port: 3000

HTTP Request:
  GET /data
```

**Step 5: Docker bridge forwards**

```
Docker bridge (like a switch):
  Receives from web container
  Checks destination: 172.20.0.3
  Forwards to api container's virtual interface
```

**Step 6: API container receives**

```
API container:
  Receives packet
  Port 3000 → Node.js app
  Processes request
  Sends response back
```

---

### What's Different in Docker

**Docker-specific concepts:**

- **veth pairs:** Virtual ethernet cables (one end in container, one in bridge)
- **Bridge network:** Virtual switch connecting containers
- **Internal DNS:** Container names automatically resolve to IPs
- **Isolation:** Each container has own network namespace

**No NAT needed** (containers on same bridge)  
**No physical NICs** (all virtual)  
**Same networking principles** (IP, MAC, TCP still apply)

---

## Journey 4: AWS Multi-Tier Application

**Scenario:** User accesses web application hosted on AWS

**Architecture:**
```
Internet User
    ↓
Application Load Balancer (ALB) - Public subnet
    ↓
Web Server (EC2) - Private subnet
    ↓
Database (RDS) - Private subnet
```

**Network details:**
```
VPC: 10.0.0.0/16

Public Subnet: 10.0.1.0/24
├─ ALB: 10.0.1.100 (also has public IP: 54.123.45.67)
└─ Internet Gateway: Attached

Private Subnet (Web): 10.0.2.0/24
├─ Web Server: 10.0.2.50
└─ NAT Gateway: 10.0.1.200 (in public subnet)

Private Subnet (DB): 10.0.3.0/24
└─ RDS: 10.0.3.25
```

---

### Complete Flow

#### Phase 1: User → ALB

**Step 1: DNS resolution**

```
User browser: "What's myapp.example.com?"
Route 53 (AWS DNS): "54.123.45.67"
```

**Step 2: User sends HTTPS request**

```
User laptop (203.45.67.89) → ALB (54.123.45.67)

Internet routing (multiple hops)
Reaches AWS region
AWS Internet Gateway receives
Routes to ALB in public subnet
```

**Step 3: ALB receives request**

```
ALB checks:
  Port 443 (HTTPS) → Allowed
  Security Group: Allow 0.0.0.0/0 on port 443 ✅

ALB terminates TLS (decrypts HTTPS)
Now has HTTP request
```

---

#### Phase 2: ALB → Web Server

**Step 4: ALB health checks**

```
ALB knows about:
  Web Server 1: 10.0.2.50 (healthy)
  Web Server 2: 10.0.2.51 (healthy)

Chooses: Web Server 1 (round-robin)
```

**Step 5: ALB forwards to web server**

```
Internal VPC routing:
  Src IP: 10.0.1.100 (ALB)
  Dst IP: 10.0.2.50 (web server)

Subnet check:
  10.0.1.X ≠ 10.0.2.X → Different subnets

VPC router forwards between subnets
```

**Step 6: Web server receives**

```
Web server security group checks:
  Source: ALB security group → Allowed ✅
  Port 80 (HTTP) → Allowed ✅

EC2 instance receives request
Apache/Nginx processes it
```

---

#### Phase 3: Web Server → Database

**Step 7: Web server queries database**

```
Application code:
  Connection string: 10.0.3.25:5432 (PostgreSQL)

Packet created:
  Src IP: 10.0.2.50
  Dst IP: 10.0.3.25
  Dst port: 5432
```

**Step 8: VPC routing**

```
Different subnets:
  10.0.2.X → 10.0.3.X

VPC route table:
  10.0.0.0/16 → local (VPC router handles)

Packet forwarded to database subnet
```

**Step 9: RDS receives query**

```
RDS security group checks:
  Source: Web server security group → Allowed ✅
  Port 5432 → Allowed ✅

PostgreSQL processes query
Returns data
```

---

#### Phase 4: Response Journey

**Step 10: Database → Web Server**

```
Response packet:
  Src IP: 10.0.3.25
  Dst IP: 10.0.2.50

Routed back through VPC
Web server receives data
```

**Step 11: Web Server → ALB**

```
Web server generates HTML response

Packet:
  Src IP: 10.0.2.50
  Dst IP: 10.0.1.100

ALB receives
Encrypts with TLS (HTTPS)
```

**Step 12: ALB → User**

```
ALB sends HTTPS response:
  Src IP: 54.123.45.67 (ALB public IP)
  Dst IP: 203.45.67.89 (user's public IP)

Internet routing
Reaches user's ISP
User's router (NAT)
User's browser displays page
```

---

### What If Web Server Needs Internet?

**Scenario:** Web server needs to download OS updates

**Step 1: Web server initiates connection**

```
Web server: "I want to reach archive.ubuntu.com"
Dst IP: 91.189.88.142 (Ubuntu server)
```

**Step 2: Route table check**

```
Web server's route table:
  10.0.0.0/16 → local
  0.0.0.0/0 → NAT Gateway (10.0.1.200)

Decision: Send to NAT Gateway
```

**Step 3: NAT Gateway translation**

```
NAT Gateway receives:
  Src IP: 10.0.2.50 (private)

NAT Gateway translates:
  Src IP: 52.10.20.30 (NAT Gateway's Elastic IP)

Forwards to Internet Gateway
```

**Step 4: Internet Gateway**

```
Routes packet to internet
Ubuntu server receives
Responds
```

**Step 5: Return path**

```
Internet → Internet Gateway → NAT Gateway

NAT Gateway reverse translation:
  Dst IP: 52.10.20.30 → 10.0.2.50

Delivers to web server
```

---

### AWS Networking Summary

**Components used:**

| Component | Purpose | Layer |
|-----------|---------|-------|
| **VPC** | Isolated network | L3 |
| **Subnets** | Network segments | L3 |
| **Internet Gateway** | VPC ↔ Internet | L3 |
| **NAT Gateway** | Private ↔ Internet (outbound) | L3, L4 |
| **Route Tables** | Traffic direction | L3 |
| **Security Groups** | Stateful firewall | L3, L4 |
| **NACLs** | Stateless firewall | L3, L4 |
| **ALB** | Load balancer | L7 |

---

## The Troubleshooting Mindset

### The Systematic Approach

When something doesn't work, **debug layer by layer:**

```
┌──────────────────────────────────────┐
│ 7. Application Layer                 │
│    Is the app running?               │
│    Check: ps aux | grep app          │
└──────────────────────────────────────┘
                ↑
┌──────────────────────────────────────┐
│ 4. Transport Layer                   │
│    Is the port open?                 │
│    Check: netstat -tlnp | grep :80   │
└──────────────────────────────────────┘
                ↑
┌──────────────────────────────────────┐
│ 3. Network Layer                     │
│    Can we reach the IP?              │
│    Check: ping 192.168.1.50          │
│          traceroute google.com       │
└──────────────────────────────────────┘
                ↑
┌──────────────────────────────────────┐
│ Firewall (sits between layers)       │
│    Are firewall rules correct?       │
│    Check: Security groups, iptables  │
└──────────────────────────────────────┘
                ↑
┌──────────────────────────────────────┐
│ DNS (Application layer service)      │
│    Does name resolve?                │
│    Check: nslookup google.com        │
│          dig google.com              │
└──────────────────────────────────────┘
```

---

### The 5-Question Debug Framework

**When connection fails, ask in order:**

#### 1. DNS Working?
```bash
nslookup myapp.example.com

If fails: DNS issue
If works: Note the IP, move to step 2
```

#### 2. Network Reachable?
```bash
ping <IP_FROM_STEP_1>

If fails: Routing or firewall issue
If works: Network path exists, move to step 3
```

**Note:** Ping might be blocked (ICMP). If ping fails, try:
```bash
telnet <IP> <PORT>
# or
nc -zv <IP> <PORT>
```

#### 3. Port Open?
```bash
# Test if specific port accessible
telnet <IP> 80

If "Connection refused": Port not open or service not running
If "Connected": Port is open, move to step 4
```

#### 4. Firewall Allowing?
```bash
# Check security groups (AWS)
# Check iptables (Linux)
sudo iptables -L -n -v

Look for rules blocking your traffic
```

#### 5. Application Running?
```bash
# Check if service is running
sudo systemctl status nginx

# Check if listening on expected port
sudo netstat -tlnp | grep :80

# Check application logs
sudo journalctl -u nginx -n 50
```

---

### Common Failure Points

| Symptom | Likely Layer | Debug Step |
|---------|-------------|------------|
| "Unknown host" | DNS (L7) | `nslookup domain.com` |
| "Connection timeout" | Firewall or routing (L3) | Check security groups, ping |
| "Connection refused" | Port closed (L4) | `netstat -tlnp \| grep :PORT` |
| "404 Not Found" | Application (L7) | Check app logs, correct URL |
| "SSL certificate error" | Presentation (L6) | Check cert validity, TLS config |
| Slow but working | All layers | `traceroute`, check bandwidth |

---

## Common Failure Points

### Scenario 1: Can't SSH to EC2

**Symptom:**
```bash
ssh ec2-user@54.123.45.67
# Hangs, then times out
```

**Debug:**

```
Step 1: DNS (skip, using IP)

Step 2: Network reachable?
ping 54.123.45.67
# Timeout (ICMP might be blocked, try port test)

telnet 54.123.45.67 22
# Connection timeout

Step 3: Check security group
AWS Console → EC2 → Security Groups
Inbound rules:
  SSH (22) from 203.45.67.89/32 ← Your office IP

Problem: Your current IP is 198.51.100.45 (different!)

Fix: Update security group or use your actual current IP
```

---

### Scenario 2: Container Can't Reach Database

**Symptom:**
```
App container logs: "Connection refused to db:5432"
```

**Debug:**

```
Step 1: DNS
docker exec app-container ping db
# ping: unknown host db

Problem: Containers not on same network

Fix:
docker network create mynet
docker network connect mynet app-container
docker network connect mynet db-container

Now DNS works
```

---

### Scenario 3: Website Loads Slowly

**Symptom:**
```
Browser: Page takes 30 seconds to load
```

**Debug:**

```
Step 1: DNS resolution time
dig example.com
# Query time: 25000 msec

Problem: DNS server slow or unreachable

Check:
cat /etc/resolv.conf
# nameserver 192.168.1.1

Router's DNS might be slow

Fix: Use faster DNS
# Add to /etc/resolv.conf
nameserver 8.8.8.8
nameserver 1.1.1.1

Test again:
dig example.com
# Query time: 15 msec ← Much better
```

---

### Scenario 4: NAT Not Working

**Symptom:**
```
Private EC2 instance can't reach internet for updates
```

**Debug:**

```
Step 1: Check route table
Private subnet route table:
  10.0.0.0/16 → local
  0.0.0.0/0 → igw-xxxxx  ← WRONG!

Problem: Private subnet pointing to Internet Gateway
Should point to NAT Gateway

Fix:
  0.0.0.0/0 → nat-xxxxx

Now works
```

---

## Final Compression

### The Complete Mental Model

**Networking = Data traveling through layers**

```
Your app creates data
  ↓
TCP wraps it (adds ports, reliability)
  ↓
IP wraps it (adds source/destination IPs)
  ↓
Ethernet wraps it (adds next-hop MACs)
  ↓
Physical layer transmits bits
  ↓
(At each router: strip Ethernet, check IP, add new Ethernet)
  ↓
Destination receives
  ↓
Strips layers in reverse
  ↓
App receives data
```

---

### Critical Truths (Never Forget)

1. **MAC and IP always work together**
   - MAC = next hop (changes every router)
   - IP = final destination (never changes)

2. **Routers connect networks**
   - Check destination IP
   - If not local → use routing table
   - Strip old MAC, add new MAC

3. **NAT hides private IPs**
   - Private IP → Router → Public IP
   - Response → Router → Private IP
   - NAT table tracks connections

4. **Firewalls control access**
   - Stateful = remembers connections
   - Stateless = checks every packet
   - Security groups = stateful (AWS)
   - NACLs = stateless (AWS)

5. **DNS is just a lookup service**
   - Name → IP translation
   - Uses UDP port 53
   - Can be cached
   - Can be slow (debug point)

---

### The Three Questions Every Packet Answers

```
1. Who am I going to ultimately? (Destination IP)
2. Who do I give this to next? (Next-hop MAC)
3. How do I get there? (Routing table)
```

**Answer these three, and you understand networking.**

---

### OSI Layers — Quick Reference

```
7. Application    →  HTTP, DNS, SSH (what users see)
6. Presentation   →  TLS, encryption (data formatting)
5. Session        →  Session management (connections)
4. Transport      →  TCP, UDP, ports (reliability)
3. Network        →  IP, routing (addressing)
2. Data Link      →  MAC, switching (local delivery)
1. Physical       →  Cables, WiFi (transmission)
```

---

### Troubleshooting Checklist

```
□ DNS resolving? (nslookup)
□ IP reachable? (ping or port test)
□ Port open? (netstat)
□ Firewall allowing? (security groups, iptables)
□ App running? (systemctl status, logs)
```

---
# 00-networking-map.md 

## 1. Master Packet Journey

```text
[Computer A] (Opens google.com)
      ↓
   DNS Lookup (File 05)
      ↓
   TCP Handshake (File 07)
      ↓
   Encapsulation: Data→Port→IP→MAC (File 09)
      ↓
[Local Switch] (Layer 2)
      ↓
   ARP Resolution (File 03)
      ↓
[Home Router] (Layer 3)
      ↓
   NAT: Private IP → Public IP (File 04)
      ↓
((( INTERNET )))
      ↓
   Hop-by-Hop Routing (File 09)
   MAC changes every hop
   IP never changes
      ↓
[AWS VPC]
      ↓
   Internet Gateway (File 11)
      ↓
   NACL: Stateless Firewall (File 10)
      ↓
   Load Balancer (File 11)
      ↓
   Security Group: Stateful Firewall (File 10)
      ↓
   ARP Final Hop (File 03)
      ↓
   De-encapsulation: MAC→IP→Port→Data (File 09)
      ↓
   Port Routes to Application (File 08)
      ↓
[Destination Server]
```

---

## 2. Layer Mental Model

| Layer | Tool | Purpose | Scope | Changes During Journey? |
|---|---|---|---|---|
| **Layer 2 (Data Link)** | MAC Address | Local delivery within network | LAN only | Yes (every hop) |
| **Layer 3 (Network)** | IP Address | Global delivery across internet | Worldwide | Destination: No<br>Source: Yes (NAT) |
| **Layer 4 (Transport)** | Port Number | Deliver to correct application | Inside server OS | No |

---

## 3. Packet Lifecycle

### Local Exit (Your Network)
```
DNS    → google.com becomes 142.250.80.46
TCP    → SYN, SYN-ACK, ACK handshake
Wrap   → Data→Port 443→IP→MAC (router)
Switch → Reads MAC, forwards locally
NAT    → 192.168.1.100 becomes 203.0.113.5
```

### Internet Transit
```
Routing → Packet hops router-to-router
MAC     → Rewritten every hop
IP      → Destination never changes
```

### Cloud Entry
```
IGW            → Enters AWS VPC
NACL           → Subnet firewall (stateless)
Load Balancer  → Distributes to server
Security Group → Instance firewall (stateful)
```

### Server Delivery
```
ARP     → Resolve final MAC
Unwrap  → MAC→IP→Port→Data
Port    → 443 routes to web application
```

---

## 4. What Changes vs What Stays

| Component | Changes? | When? | Why? |
|---|---|---|---|
| **Application Data** | Never | - | The payload |
| **Destination IP** | Never | - | Global addressing |
| **Source IP** | Once | At NAT | Private→Public |
| **Port Number** | Never | - | Application identifier |
| **MAC Address** | Every hop | At each router | Local delivery only |

---

## 5. Protocol Map

| Need | Protocol | File | Command Example |
|---|---|---|---|
| Name → IP | DNS | 05 | `nslookup google.com` |
| IP → MAC (local) | ARP | 03 | `arp -a` |
| Reliable delivery | TCP | 07 | 3-way handshake |
| Fast delivery | UDP | 07 | No handshake |
| Global routing | IP | 09 | Hop-by-hop |
| Hide private IPs | NAT | 04 | Router translation |
| Auto IP assignment | DHCP | 02 | Lease process |

---

## 6. Security Layers

| Firewall Type | Scope | Memory? | Return Traffic? | File |
|---|---|---|---|---|
| **NACL** | Subnet (multiple servers) | No (stateless) | Needs explicit rule | 10 |
| **Security Group** | Instance (single server) | Yes (stateful) | Auto-allowed | 10 |

**Rule:**
- Stateless = checks every packet independently, has amnesia
- Stateful = remembers connections, auto-allows replies

---

## 7. Debugging Breakpoints

| Stage | Failure Symptom | Tool | What It Shows | File |
|---|---|---|---|---|
| **DNS** | Name not resolving | `nslookup google.com` | IP address or error | 05 |
| **TCP** | Connection refused | `telnet IP PORT` | Port open/closed | 07 |
| **Routing** | Packet lost | `traceroute google.com` | Where packet dies | 09 |
| **Firewall** | Port blocked | `nc -zv IP PORT` | Port reachable? | 10 |
| **ARP** | Local delivery fails | `arp -a` | MAC table | 03 |
| **NAT** | External access fails | `curl ifconfig.me` | Public IP | 04 |

---

## 8. File Index (Concept → Location)

| Concept | File | Key Question Answered |
|---|---|---|
| **IP Addressing** | 01 | What does 192.168.1.100/24 mean? |
| **DHCP** | 02 | How did my device get an IP? |
| **ARP** | 03 | How does IP become MAC? |
| **NAT** | 04 | Why do I have two IPs (private/public)? |
| **DNS** | 05 | How does google.com become an IP? |
| **Subnetting** | 06 | How do I calculate /24 vs /16? |
| **TCP/UDP** | 07 | Reliable vs fast - when to use which? |
| **Ports** | 08 | What is port 443 vs port 80? |
| **Routing** | 09 | How does a packet cross the internet? |
| **Firewalls** | 10 | Stateful vs stateless - what's the difference? |
| **Cloud Networking** | 11 | How do VPCs, ALBs, and Security Groups work? |

---

## 9. Interview Compression

**"Explain packet flow from browser to cloud server"**

> DNS translates google.com to an IP. TCP handshake establishes connection. Data is encapsulated: application layer → port 443 → destination IP → router MAC. 
>
> Local switch forwards via MAC. Router performs NAT (private IP → public IP). Packet hops across internet—MAC changes every hop, IP stays constant.
>
> Enters AWS via Internet Gateway into VPC. Passes stateless NACL (subnet firewall), then load balancer distributes to server. Stateful Security Group (instance firewall) allows it through.
>
> ARP resolves final MAC. De-encapsulation: strip MAC → IP → port. Port 443 routes to web application. Response follows reverse path.

---

## Webstore DevOps Scenario

**User opens webstore.com**

```
DNS       → webstore.com resolves to 54.123.45.67 (Route53)
TCP       → Handshake to port 443
NAT       → Home router: 192.168.1.50 → 203.45.67.89
Routing   → Hops to AWS us-east-1
IGW       → Enters VPC 10.0.0.0/16
NACL      → Allows port 443 inbound
ALB       → Distributes to 1 of 3 backend servers
SG        → Allows port 443 to EC2 instance
Server    → Nginx serves video stream
Response  → Reverse path to browser
```

**DevOps controls:**
- DNS (Route53 config)
- Load balancer algorithm
- Security Group rules
- NACL subnet restrictions
- VPC architecture

---

## Quick Reference Card

### Addressing
```
MAC:        00:1A:2B:3C:4D:5E  (local, changes)
Private IP: 192.168.1.100      (internal, NAT'd)
Public IP:  203.0.113.5        (internet, constant)
Port:       443                (application, constant)
```

### Common Ports
```
22  → SSH
80  → HTTP
443 → HTTPS
3306 → MySQL
5432 → PostgreSQL
27017 → MongoDB
```

### Encapsulation Order
```
Build (outbound):    Data → Port → IP → MAC
Unwrap (inbound):    MAC → IP → Port → Data
```

---

**This is your network map. Review before interviews. Everything clicks.**

**You now understand networking completely.**

From typing a URL to packets traveling the world, from Docker containers talking to AWS multi-tier applications — it's all the same fundamental concepts:

**Encapsulation → Routing → Delivery → De-encapsulation**

Everything else is just details.

---
---
# TOOL: 03. Networking – Foundations | FILE: networking-labs
---

[Home](../README.md) |
[Labs Index](./README.md) |
[Lab 01](./01-foundation-addressing-ip-lab.md) |
[Lab 02](./02-devices-subnets-lab.md) |
[Lab 03](./03-ports-transport-nat-lab.md) |
[Lab 04](./04-dns-firewalls-lab.md) |
[Lab 05](./05-complete-journey-lab.md)

---

# Networking Labs

Hands-on sessions for every topic in the Networking notes.

Do them in order. Do not move to the next lab until the checklist at the bottom is fully checked.

---

## The Project Thread

These five labs are not isolated drills. They are five stages in understanding the network layer that every request to the webstore passes through.

The webstore server is running nginx on port 80, the API on port 8080, and postgres on port 5432. A browser somewhere types `webstore.example.com` and presses Enter. By Lab 05 you can trace every single step that request takes to reach the server and come back — and you can debug it when something goes wrong.

No Docker. No AWS. Just the network underneath both of them.

| Lab | What you are learning to see | Why it matters for the webstore |
|---|---|---|
| [Lab 01](./01-foundation-addressing-ip-lab.md) | Interfaces, MAC, IP, ARP, localhost | The webstore server has an IP — this is how it gets one and what it means |
| [Lab 02](./02-devices-subnets-lab.md) | Routing table, traceroute, CIDR, subnet design | Requests are routed to the webstore server — this is how routers decide where to send them |
| [Lab 03](./03-ports-transport-nat-lab.md) | ss, TCP handshake, NAT, iptables DNAT | nginx on 80, API on 8080, postgres on 5432 — ports are what separate them |
| [Lab 04](./04-dns-firewalls-lab.md) | dig, record types, TTL, iptables rules, stateful vs stateless | webstore.example.com resolves to an IP — firewalls decide what can reach it |
| [Lab 05](./05-complete-journey-lab.md) | Full end-to-end trace, production debugging | Put every layer together — trace a request and fix it when it breaks |

---

## Labs

| Lab | Topics | Notes |
|---|---|---|
| [Lab 01](./01-foundation-addressing-ip-lab.md) | Interfaces, MAC, IP, ARP, private ranges, localhost | [01](../01-foundation-and-the-big-picture/README.md) · [02](../02-addressing-fundamentals/README.md) · [03](../03-ip-deep-dive/README.md) |
| [Lab 02](./02-devices-subnets-lab.md) | Routing table, traceroute, CIDR calculation, VPC design | [04](../04-network-devices/README.md) · [05](../05-subnets-cidr/README.md) |
| [Lab 03](./03-ports-transport-nat-lab.md) | ss, netstat, TCP handshake, UDP, iptables DNAT | [06](../06-ports-transport/README.md) · [07](../07-nat/README.md) |
| [Lab 04](./04-dns-firewalls-lab.md) | dig trace, record types, TTL, iptables, stateful vs stateless | [08](../08-dns/README.md) · [09](../09-firewalls/README.md) |
| [Lab 05](./05-complete-journey-lab.md) | Full end-to-end trace, production debugging, interview answer | [10](../10-complete-journey/README.md) |

---

## How to Use These Labs

Read the notes for each phase before opening a terminal. Every lab assumes you have read the corresponding notes files first.

Write every command from scratch. Do not copy-paste.

Every lab has a "Break It on Purpose" section. Do not skip it. These are the failure states you will actually hit in production.

Do not move to the next lab until every box in the checklist is checked.

---
# TOOL: 04. Docker – Containerization | FILE: 01-history-and-motivation
---

[Home](../README.md) |
[History & Motivation](../01-history-and-motivation/README.md) |
[Technology Overview](../02-technology-overview/README.md) |
[Docker Containers](../03-docker-containers/README.md) |
[Port Binding](../04-docker-port-binding/README.md) |
[Networking](../05-docker-networking/README.md) |
[Volumes](../06-docker-volumes/README.md) |
[Layers](../07-docker-layers/README.md) |
[Build](../08-docker-build-dockerfile/README.md) |
[Registry](../09-docker-registry/README.md) |
[Compose](../10-docker-compose/README.md)

---

# History and Motivation

<!-- no toc -->
  - [Why Docker Exists](#why-docker-exists)
  - [What is a container?](#what-is-a-container)
  - [History of virtualization](#history-of-virtualization)
    - [Bare Metal](#bare-metal)
    - [Virtual Machines](#virtual-machines)
    - [Containers](#containers)
    - [Tradeoffs](#tradeoffs)
  - [What Containerizing the Webstore Gives You](#what-containerizing-the-webstore-gives-you)

---

## Why Docker Exists

Before Docker, an app worked on your laptop because your machine already had the right setup. The same app often failed on testing or production machines, not because the code was wrong, but because the environment was different. Different OS packages, different runtime versions, or missing dependencies caused the break.

Docker solves this environment problem.

Instead of moving only the code, Docker packages the app together with everything it needs to run. That package behaves the same way on any machine that supports Docker. The goal is not speed or magic. The goal is consistency.

Docker has two core parts.
- A Docker **image** is a fixed definition of the environment. It describes what should exist, but it does not run.
- A Docker **container** is a running copy of that image. Containers are created from images, run the app, and can be stopped and deleted anytime.

Because containers are meant to be replaced, rebuilding them is normal. One image can create many identical containers. This makes it easy to run different apps or different versions on the same machine without conflicts.

One important rule stays constant: containers run the application, but they should not store important data. Anything that must survive restarts or deletions should live outside the container.

Everything else in Docker exists to support this idea.

## What is a container?

A Docker container image is a lightweight, standalone, executable package of software that includes everything needed to run an application (https://www.docker.com/resources/what-container/).

## History of virtualization

### Bare Metal

**What this means?**
In a bare metal setup, applications run directly on the same operating system without strong separation. All applications share the same OS, system libraries, CPU, and memory. Because there are no clear boundaries, one application can directly affect others.

**Why this is a problem?**
If one app installs or upgrades a library, it may break another app. If one app consumes too much CPU or memory, it can slow down the entire system. If one app crashes, the impact can spread beyond just that app. Over time, this makes systems fragile and hard to manage.

**Simple analogy!**
Imagine multiple people cooking in the same kitchen with **one stove and one pantry**. Everyone uses the same ingredients and tools. If one person uses all the ingredients or burns the stove, everyone else is affected. There is no separation, so one person's mistake becomes everyone's problem.

![](./readme-assets/bare-metal.jpg)

**Why the industry moved on:**
- Apps break each other
Different apps need different versions of the same software, so installing or updating one app can break another.

- Machine resources are wasted
CPU and memory are not used well; one app may use too much while others sit idle.

- One problem affects everything
If one app crashes or misbehaves, it can impact the whole system.

- Starting and stopping is slow
Services take minutes to start or stop.

- Creating and removing systems is very slow
Setting up or removing a machine takes hours or even days.

---

### Virtual Machines

**What this means?**
In a virtual machine setup, applications do not run directly on the host OS.
Instead, a hypervisor creates multiple virtual computers on one physical machine.
Each virtual machine has its own operating system, libraries, CPU share, and memory.
Because each VM is separated, one VM cannot directly mess with another.

**Why this is better than bare metal?**
Since every VM has its own OS and environment:
- Apps don't fight over libraries
- Crashes usually stay inside one VM
- Resources are more controlled

This makes systems more stable and predictable than bare metal.

**Simple analogy!**
Imagine an apartment building.
- Each family lives in their own apartment
- Everyone has their own kitchen and bathroom
- If one family burns food, it doesn't destroy the whole building

There is separation, but the building itself is still shared.

![](./readme-assets/virtual-machine.jpg)

**What problems still exist?**

Even though VMs fix many bare-metal issues, they introduce new ones:

- Each VM runs a full operating system
- OS takes memory, CPU, and disk even if the app is small
- Starting a VM takes minutes, not seconds
- Creating or deleting VMs is still slow
- Running many VMs becomes expensive and heavy

**Why the industry moved forward again**

- Too much overhead per app (full OS every time)
- Slower startup compared to containers
- Lower density (fewer apps per machine)
- Not ideal for fast development and scaling

**Virtual machines solved isolation and stability, but they are still heavy, slow, and resource-hungry.**
That gap is exactly where containers come in next.

---

### Containers

**What this means?**
In a container setup, applications do not get their own operating system. There is one operating system on the machine, and all containers use that same OS core (kernel).
Each application runs inside its own container, which gives it:
- its own files
- its own settings
- its own view of the system
So even though apps share the same OS underneath, they cannot see or touch each other.
This separation is created using built-in Linux features, not fake hardware and not extra operating systems.

**Why this is an improvement?**
Compared to virtual machines:
- No extra OS to install
- No OS to boot for every app
- Much less memory and CPU usage
- Apps start almost instantly
You can run many containers on one machine without wasting resources.

**Simple analogy!**
Imagine an apartment building. One building, One plumbing system, One power connection

Each apartment:
- has its own door
- its own rooms
- its own locks

People inside one apartment cannot see or affect people in another apartment.
The building = host operating system
The apartments = containers
Everyone shares the same building, but lives separately.

![](./readme-assets/container.jpg)

**Why the industry moved here**

- Apps no longer break each other
- Resources are used more efficiently
- Starting and stopping apps takes seconds
- Easy to create, delete, and move apps
- Perfect for development and modern cloud systems

### VM vs Docker (Mental Model Snapshot)

![VMs vs Docker Containers](./readme-assets/vm-vs-docker.webp)

## VM vs Docker — Resource & Kernel Model

**Virtual Machines:**
- Hardware virtualization
- Guest OS per VM
- Reserved CPU/RAM
- Strong isolation
- Slower, heavier

**Docker Containers:**
- OS-level virtualization
- Shared host kernel
- No reserved CPU/GPU
- Process-level isolation
- Fast, lightweight

**Core Difference:**
VMs virtualize hardware.
Containers isolate processes.

---

### Tradeoffs

![](./readme-assets/tradeoffs.jpg)

***Note:*** There is much more nuance to "performance" than this chart can capture. A VM or container doesn't inherently sacrifice much performance relative to the bare metal it runs on, but being able to have more control over things like connected storage, physical proximity of the system relative to others it communicates with, specific hardware accelerators, etc… do enable performance tuning

---

## What Containerizing the Webstore Gives You

The webstore on a Linux server — nginx on port 80, the API on port 8080, postgres on port 5432 — works on your machine because your machine is set up correctly. The right postgres version is installed. The right nginx config is in place. The right environment variables are set.

Now you want to deploy it. The production server is a fresh Ubuntu instance. It does not have postgres. It does not have the right nginx config. You SSH in, install dependencies manually, adjust configs, and hope you did not miss anything. This is the environment problem Docker solves.

**What changes when you containerize the webstore:**

The webstore-api image contains the application code, the runtime, and every dependency it needs — packaged together. When you run that image on the production server, the same container starts. Same runtime version. Same dependencies. No manual installation. No configuration drift between environments.

```
Without Docker:
  Your laptop → "works on my machine"
  Staging server → "missing postgres version mismatch"
  Production server → "env var missing, nginx config wrong"

With Docker:
  Your laptop → docker compose up → webstore running
  Staging server → docker compose up → same webstore
  Production server → docker compose up → same webstore
```

**What each container gets:**
- `webstore-frontend` — nginx:1.24 serving static files, same image in dev and prod
- `webstore-api` — built from your Dockerfile, same image that passed CI
- `webstore-db` — postgres:15, same version everywhere, data in a volume that survives container replacement

**What you hand to Kubernetes after Docker:**
A Kubernetes cluster does not know what your app is. It pulls container images from a registry and runs them. Everything you build in Docker — images, tags, environment variables, port mappings — is exactly what Kubernetes reads. Docker is not a stepping stone to Kubernetes. It is the prerequisite.

---
# TOOL: 04. Docker – Containerization | FILE: 02-technology-overview
---

[Home](../README.md) |
[History & Motivation](../01-history-and-motivation/README.md) |
[Technology Overview](../02-technology-overview/README.md) |
[Docker Containers](../03-docker-containers/README.md) |
[Port Binding](../04-docker-port-binding/README.md) |
[Networking](../05-docker-networking/README.md) |
[Volumes](../06-docker-volumes/README.md) |
[Layers](../07-docker-layers/README.md) |
[Build](../08-docker-build-dockerfile/README.md) |
[Registry](../09-docker-registry/README.md) |
[Compose](../10-docker-compose/README.md)


---

# Technology Overview

<!-- no toc -->
- [Linux Building Blocks](#linux-building-blocks)
  - [Cgroups](#cgroups)
  - [Namespaces](#namespaces)
  - [Union filesystems](#union-filesystems)
- [Docker Application Architecture](#docker-application-architecture)

## Linux Building Blocks

### Process → Namespace → cgroups (Clean Flow)

A **process** is a running program.
Every application starts as a process on the system.
By default, a process can see the entire system and use as many resources as it wants.

Linux then introduced **namespaces**.
A namespace limits what a process can see.
The process is intentionally made blind to the rest of the system.
It sees only its own processes, network, files, users, and hostname.
This creates isolation.

Isolation alone is not enough.
A process could still consume all CPU or memory.

So Linux added **cgroups**.
cgroups limit how much CPU, memory, and other resources a process can use.
These limits are enforced by the kernel.

When a process is started with namespaces and cgroups applied, it becomes what we call a container.

**One-line lock:**
A container is just a process with restricted view and restricted usge.

---

### Namespaces 
This table shows the Linux resources that can be isolated using namespaces. This is for reference only.
![](./readme-assets/namespaces.jpg) 

---

### Cgroups
Cgroups are a Linux kernel feature which allow processes to be organized into hierarchical groups whose usage of various types of resources can then be limited and monitored. 

With cgroups, a container runtime is able to specify that a container should be able to use (for example):
* Use up to XX% of CPU cycles (cpu.shares)
* Use up to YY MB Memory (memory.limit_in_bytes)
* Throttle reads to ZZ MB/s (blkio.throttle.read_bps_device)

![](./readme-assets/cgroups.jpg) 

---

### Union filesystems

Applications need many files. Copying the same files for every app wastes disk space.  

A union filesystem lets Linux stack multiple directories and present them as one directory.  
The directories are not actually merged. Linux only shows a combined view.  

In Docker, an image is made of read-only directories (layers). Linux stacks these layers and presents them as a single filesystem.  

When a container runs, Docker adds one writable directory on top. All read-only layers are shared and reused, not copied.  

This design avoids duplication, saves disk space, and keeps images lightweight.

**One-line lock:**
Union filesystem exists to reuse shared read-only files instead of copying them.

![](./readme-assets/overlayfs.jpg) 

---

## Docker Application Architecture

Docker is not a single thing. It is made of a core engine, optional developer tooling, and image storage.

The core of Docker is Docker Engine. Docker Engine consists of the Docker daemon (dockerd) and the Docker CLI. The daemon does the real work: building images and running containers. The CLI is just the command you type to talk to the daemon using the Docker API. Docker Engine runs only on Linux and is what is used on servers and production systems.

Docker Desktop is a developer convenience, not Docker itself. It bundles the Docker CLI with a graphical interface, credential helpers, extensions, and a Linux virtual machine. This Linux VM runs Docker Engine inside it. Docker Desktop exists because macOS and Windows do not have the Linux kernel features Docker needs. When you use Docker Desktop, you are actually using Docker Engine running inside a Linux VM.

Container registries are not part of Docker, but they are required to store and share images. Docker can push images to registries and pull images from them. Docker Hub is the default registry, but many others exist. Registries only store images; they do not run containers.

**One-line lock:**
Docker Engine runs containers, Docker Desktop helps developers, and registries store images.

![](./readme-assets/docker-architecture.jpg) 

- You start on your machine and type a Docker command       →    That command goes to the Docker CLI.
- The Docker CLI does not do any real work                  →    It only sends your request to the Docker API.
- The Docker API is handled by the Docker daemon (dockerd)  →    This daemon is where everything actually happens.

The daemon runs inside Linux: 
- directly on a Linux server  
- inside a Linux virtual machine when using Docker Desktop on Mac or Windows  
This Linux environment is **Docker Engine.**

Docker Engine builds images and runs containers. Containers run here as Linux processes using namespaces, cgroups, and union filesystem.  
If an image is not available locally, Docker Engine pulls it from a registry. Registries only store images. They never run containers.  
Docker Desktop is just a wrapper. It provides a GUI, helpers, and a Linux VM so Docker Engine can run on non-Linux systems.  

**One-line lock:**
Command goes in → Docker Engine runs containers → registry stores images.
---
# TOOL: 04. Docker – Containerization | FILE: 03-docker-containers
---

[Home](../README.md) |
[History & Motivation](../01-history-and-motivation/README.md) |
[Technology Overview](../02-technology-overview/README.md) |
[Docker Containers](../03-docker-containers/README.md) |
[Port Binding](../04-docker-port-binding/README.md) |
[Networking](../05-docker-networking/README.md) |
[Volumes](../06-docker-volumes/README.md) |
[Layers](../07-docker-layers/README.md) |
[Build](../08-docker-build-dockerfile/README.md) |
[Registry](../09-docker-registry/README.md) |
[Compose](../10-docker-compose/README.md)

# Docker Containers

## What this file is about (theory)

This file teaches how to **run and operate containers**. If you can use everything here, you can run prebuilt software without installing it on your host, run services in the background, pass correct startup configuration, debug containers when they fail, and clean Docker safely without breaking anything. This is runtime usage only — not Dockerfile, not image building, not volumes deep dive, not networking deep dive.

1. [Getting Software (Images)](#1-getting-software-images)
2. [Interactive Containers (Learning & Exploration)](#2-interactive-containers-learning--exploration)
3. [Visibility & Lifecycle Control](#3-visibility--lifecycle-control)
4. [Service Mode (Real DevOps Usage)](#4-service-mode-real-devops-usage)
5. [Configuration at Startup (-e)](#5-configuration-at-startup--e)
6. [Observability & Debugging (Operator Level)](#6-observability--debugging-operator-level)
7. [Safe Delete Flow (Memorize This)](#7-safe-delete-flow-memorize-this)  
[Final Compression (Memorize)](#final-compression-memorize)

---

## 1. Getting Software (Images)

**Goal:** download software as an image so you can run it later.

| Step | What you do | Command format | Example you run |
|---:|---|---|---|
| 1 | Pull an image (download) | `docker pull IMAGE` | `docker pull ubuntu` |
| 2 | Pull a specific version (tag) | `docker pull IMAGE:TAG` | `docker pull ubuntu:22.04` |
| 3 | Check Docker version | `docker -v` | `docker -v` |
| 4 | List downloaded images | `docker images` | `docker images` |

**Mental model:** Image = downloaded software + environment. Nothing is running yet.

---

## 2. Interactive Containers (Learning & Exploration)

**Goal:** enter a container like a terminal to explore safely.

| Step | What you do | Command format | Example you run |
|---:|---|---|---|
| 5 | Run + enter container (best for learning) | `docker run --name CONT_NAME -it IMAGE` | `docker run --name ubuntu-test -it ubuntu` |
| 6 | Exit container (from inside) | `exit` | `exit` |
| 7 | Start existing container + enter again | `docker start -i CONT_NAME` | `docker start -i ubuntu-test` |

**Name behavior (important):**  
- If you do NOT specify `--name`, Docker automatically assigns a random name (e.g., `sleepy_morse`).
- The name is just a human-friendly label; Docker also assigns an internal container ID.
- These notes **always use container names**, not container IDs, because names are easier to remember and read.
- You must use the generated name or container ID for all follow-up commands (`start`, `stop`, `logs`, `exec`).

**Mental model:**   
`-it` attaches your terminal to the container’s main process. If that process exits, the container stops.
- -it — interactive terminal

---

## 3. Visibility & Lifecycle Control

**Goal:** see what exists and control container lifecycle confidently.

| Step | What you do | Command format | Example you run |
|---:|---|---|---|
| 8 | Show running containers | `docker ps` | `docker ps` |
| 9 | Show all containers (running + stopped) | `docker ps -a` | `docker ps -a` |
| 10 | Stop a running container | `docker stop CONT_NAME` | `docker stop ubuntu-test` |
| 11 | Delete container (must be stopped) | `docker rm CONT_NAME` | `docker rm ubuntu-test` |
| 12 | Delete image (after container is deleted) | `docker rmi IMAGE` | `docker rmi ubuntu` |

**Non-negotiable rule:** Delete containers first → then delete images.

---

## 4. Service Mode (Real DevOps Usage)

**Goal:** run software in the background like a server.

| Step | What you do | Command format | Example you run |
|---:|---|---|---|
| 13 | Run in background (detach) + name it | `docker run -d --name CONT_NAME IMAGE` | `docker run -d --name web nginx` |

**Mental model:**   
`-d` means “run like a service.” You don’t enter it. You observe it and manage it.

---

## 5. Configuration at Startup (`-e`)

**Goal:** pass required configuration (passwords, modes, environment flags) at container startup.

| Step | What you do | Command format | Example you run |
|---:|---|---|---|
| 14 | Run tool with required config (`-e`) | `docker run -d --name CONT_NAME -e KEY=VALUE IMAGE:TAG` | `docker run -d --name mysql8 -e MYSQL_ROOT_PASSWORD=secret mysql:8.0` |

**Mental model:**   
Image is generic. `-e` makes it environment-specific at runtime.  
You find required env vars in the image’s official docs (Docker Hub).  

### Helper: generating secrets (host-side, not a Docker command — optional)

Some images require a password at startup. This command generates a random string you can use as that password.

```bash
openssl rand -base64 16
```
**What openssl rand -base64 16 does (piece by piece)**

- `openssl` → a tool already installed on most systems
- `rand` → generate random data
- `16` → amount of randomness
- `-base64` → convert it into readable text

**How it fits into Docker (full flow)**

Generate secret on host:
```bash
openssl rand -base64 16
```

Copy the output

Use it in Docker:
```bash
docker run -d \
  --name mysql8 \
  -e MYSQL_ROOT_PASSWORD=<PASTE_HERE> \
  mysql:8.0
```

That’s all.  
No magic. No Docker internals.  

---

## 6. Observability & Debugging (Operator Level)

**Goal:** figure out what’s wrong without rebuilding.

| Step | What you do                                           | Command                             | Example                       |
| -----|------------------------------------------------ | ----------------------------------- | ----------------------------- |
| 15   |View logs                                             | `docker logs CONT_NAME`             | `docker logs mysql8`          |
| 16   |Follow logs (live)                                    | `docker logs -f CONT_NAME`          | `docker logs -f web`          |
| 17   |Inspect container truth (state/env/image/ports, etc.) | `docker inspect CONT_NAME`          | `docker inspect mysql8`       |
| 18   |Enter a running container for debugging               | `docker exec -it CONT_NAME /bin/sh` | `docker exec -it web /bin/sh` |
| 19   |Restart a container                                   | `docker restart CONT_NAME`          | `docker restart web`          |

---
### Operator mental model (read this first)

When something is wrong, **never rebuild first**.  
You observe → inspect → intervene → restart.  
* Rebuilding too early = slow + hides root cause  
* Exec/logs first = faster + teaches system behavior  
This is the **operator mindset** difference between juniors and seniors.  
---

**When to use what:**

- Container exited or won’t stay up → `docker logs`
- Container running but misbehaving → `docker logs -f`
- Unsure how the container was started → `docker inspect`
- Need to look inside a running container → `docker exec`
- Config changed or process stuck → `docker restart`

---

## Command-by-command (why it exists)

| Situation (what you see) | What it means | Command to use | Why this command |
|--------------------------|---------------|----------------|------------------|
| Container exited or won’t stay up | App crashed at startup | `docker logs CONT_NAME` | See error output from the last run |
| Container running but acting strange | App is alive but misbehaving | `docker logs -f CONT_NAME` | Watch live behavior and errors |
| You forgot how the container was started | Assumptions are unreliable | `docker inspect CONT_NAME` | Docker’s source of truth (env, ports, image) |
| Logs aren’t enough | Need to look inside | `docker exec -it CONT_NAME /bin/sh` | Debug from inside the container |
| App stuck or config changed | Process needs reset | `docker restart CONT_NAME` | Clean restart without rebuilding |

---

## 7. Safe Delete Flow (Memorize This)

**Goal:** clean Docker without “blocked by dependency” errors.

Docker will block image deletion if any container still exists that references it (even stopped). So deletion must always follow the same order.

**Delete order rule:** Container first → Image next.

| Step | What you do                      | Command format          | Example                |
| ---: | -------------------------------- | ----------------------- | ---------------------- |
|   20 | Stop container (only if running) | `docker stop CONT_NAME` | `docker stop mysql8`   |
|   21 | Delete container                 | `docker rm CONT_NAME`   | `docker rm mysql8`     |
|   22 | Delete image                     | `docker rmi IMAGE`      | `docker rmi mysql:8.0` |

---

## Final compression (memorize)

Explore → `run -it`  
Run services → `run -d`  
Configure → `-e`  
Debug → `logs / inspect / exec`  
Clean → `stop → rm → rmi`  

→ Ready to practice? [Go to Lab 01](../docker-labs/01-containers-portbinding-lab.md)

---
# TOOL: 04. Docker – Containerization | FILE: 04-docker-port-binding
---

[Home](../README.md) |
[History & Motivation](../01-history-and-motivation/README.md) |
[Technology Overview](../02-technology-overview/README.md) |
[Docker Containers](../03-docker-containers/README.md) |
[Port Binding](../04-docker-port-binding/README.md) |
[Networking](../05-docker-networking/README.md) |
[Volumes](../06-docker-volumes/README.md) |
[Layers](../07-docker-layers/README.md) |
[Build](../08-docker-build-dockerfile/README.md) |
[Registry](../09-docker-registry/README.md) |
[Compose](../10-docker-compose/README.md)

# Docker Port Binding

## **1) The Problem**
* Containers are isolated.
* Apps run but are not reachable from outside.
* No port binding = no access to the application.

## **2) The Rule (Memorize)**
* **App** listens on a **container port**.
* **Host** (Your Laptop) listens on a **host port**.
* **Docker** creates a rule to map them together.

## **3) The Only Command That Matters**
```bash
docker run -p HOST_PORT:CONTAINER_PORT image

```

**Example:**

```bash
docker run -p 8080:3000 app

```

* **App** inside container is running on `3000`.
* **You** access it on your browser via `localhost:8080`.

## **4) Traffic Flow (Mental Model)**

`Browser` → `Host Port` → `Container Port` → `App`

* This is two-way traffic (request/response).
* It is simple packet forwarding managed by the host's network stack.

## **5) How to check Ground Truth**

Run:

```bash
docker ps

```

Look for the **PORTS** column. If you see:  
```
`0.0.0.0:8080->3000/tcp`  
```
It means the mapping is active and "listening" on all your laptop's network interfaces.  

## **6) Debug in 30 Seconds**

If the app is not loading:

1. **Check Ports**: Run `docker ps`. If the port isn't listed, you forgot `-p`.
2. **Check App**: Run `docker logs <container_id>`.   
If the port mapping exists but it fails, your app inside the container crashed or isn't listening on the right internal port.

## **7) One-Line Definition**

Port binding maps a container’s internal port to a host machine port so the application can be accessed by the outside world.

### **Visual Mental Model: The Gatekeeper**

```text
┌──────────────────────────── YOUR LAPTOP (HOST OS) ────────────────────────────┐
│                                                                               │
│  Browser (External World)                                                     │
│    │                                                                          │
│    │  (Request: http://localhost:8080)                                        │
│    ▼                                                                          │
│  Host NIC <──────────────────────────────────┐                                │
│    │                                         │                                │
│    │  (iptables / NAT Engine)                │                                │
│    │  RULE: If traffic hits 8080 -> Forward  │  PORT BINDING (-p)             │
│    └──────────────┬──────────────────────────┘  Bridges Host to Namespace     │
│                   │                                                           │
│                   ▼                                                           │
│      ┌────────────── docker0 (Linux BRIDGE / V-Switch) ────────┐              │
│      │                                                         │              │
│      │   veth (Virtual Cable)                                  │              │
│      │    │                                                    │              │
│      │  ┌─▼──┐                                                 │              │
│      │  │ ns │                                                 │              │
│      │  │app │                                                 │              │
│      │  │:3000                                                 │              │
│      │  └─────┘                                                │              │
│      │ (Target)                                                │              │
│      └─────────────────────────────────────────────────────────┘              │
└───────────────────────────────────────────────────────────────────────────────┘

```

→ Ready to practice? [Go to Lab 01](../docker-labs/01-containers-portbinding-lab.md)

---
# TOOL: 04. Docker – Containerization | FILE: 05-docker-networking
---

[Home](../README.md) |
[History & Motivation](../01-history-and-motivation/README.md) |
[Technology Overview](../02-technology-overview/README.md) |
[Docker Containers](../03-docker-containers/README.md) |
[Port Binding](../04-docker-port-binding/README.md) |
[Networking](../05-docker-networking/README.md) |
[Volumes](../06-docker-volumes/README.md) |
[Layers](../07-docker-layers/README.md) |
[Build](../08-docker-build-dockerfile/README.md) |
[Registry](../09-docker-registry/README.md) |
[Compose](../10-docker-compose/README.md)

# Docker Networking

## What This File Is About

Containers are isolated by design — they cannot talk to each other or the outside world unless you explicitly wire them together. This file covers how Docker networking works under the hood, why the localhost rule breaks beginners, how Docker DNS makes container name resolution automatic, and how port binding is just NAT in disguise. By the end you will understand not just the commands but exactly what happens at the network layer when containers communicate.

> **Foundation:** This file builds on networking concepts covered in the Networking notes — specifically NAT (file 07), DNS (file 08), and how bridges and routing work (file 04). Read those first if anything here feels abstract.

---

## Table of Contents

1. [The Core Problem — Isolation by Default](#1-the-core-problem--isolation-by-default)
2. [The Localhost Rule — Non-Negotiable](#2-the-localhost-rule--non-negotiable)
3. [How Docker Networking Works Under the Hood](#3-how-docker-networking-works-under-the-hood)
4. [Docker Network Modes](#4-docker-network-modes)
5. [Docker DNS — How Container Names Resolve](#5-docker-dns--how-container-names-resolve)
6. [Port Binding — NAT in Action](#6-port-binding--nat-in-action)
7. [Network Isolation — Why It Matters](#7-network-isolation--why-it-matters)
8. [The Webstore Setup — Manual Commands Line by Line](#8-the-webstore-setup--manual-commands-line-by-line)
9. [Debugging Docker Networking](#9-debugging-docker-networking)

---

## 1. The Core Problem — Isolation by Default

When you run a container without any network configuration, Docker puts it in a completely isolated environment. It has its own network namespace — its own IP stack, its own routing table, its own localhost. It cannot see any other container and nothing outside can reach it.

This isolation is a feature, not a bug. It is what makes containers safe to run side by side on the same host without interfering with each other. But it means you have to deliberately wire containers together when they need to communicate.

**The three questions every container setup must answer:**

```
1. How do containers talk to each other?
   → Put them on the same Docker network

2. How does the host machine reach a container?
   → Port binding (-p flag)

3. How does a container reach the internet?
   → Docker handles this automatically via NAT
```

---

## 2. The Localhost Rule — Non-Negotiable

**The most common Docker mistake** is using `localhost` to connect containers together. It always fails. Understanding why requires understanding what localhost actually means.

**The Rule:** `localhost` always means "the machine I am currently running inside."

| Where you are | What localhost means |
|---|---|
| Your laptop terminal | Your laptop |
| webstore-api container | webstore-api container only |
| webstore-db container | webstore-db container only |
| adminer container | adminer container only |

Each container has its own network namespace. Its own localhost. Completely separate from every other container and from the host machine.

**What breaks:**

```bash
# Inside webstore-api container — this ALWAYS fails
# Because localhost means webstore-api itself, not webstore-db
DB_HOST="localhost"
DB_PORT=5432
```

```bash
# This works — using the container name as hostname
DB_HOST="webstore-db"
DB_PORT=5432
```

**The fix:** containers talk to each other using **container names**, not localhost. Docker DNS translates the container name to its IP automatically. This is covered in Section 5.

---

## 3. How Docker Networking Works Under the Hood

**The Bridge Analogy:**
Think of Docker networking like a private office building. Each floor is a separate Docker network — a private LAN. Containers on the same floor can talk to each other directly. Containers on different floors cannot see each other at all. The building's reception desk (the host machine) handles all traffic coming in and going out to the street (the internet).

When Docker installs, it creates a virtual network bridge on your host called `docker0`. This bridge acts like a virtual ethernet switch — a Layer 2 device that connects all containers on the default network.

```
┌──────────────────────── YOUR LAPTOP (HOST OS) ─────────────────────────────┐
│                                                                            │
│  Browser                                                                   │
│    │                                                                       │
│    │  http://localhost:8080                                                │
│    ▼                                                                       │
│  Host Network Interface (en0 / eth0)                                       │
│    │                                                                       │
│    │  iptables DNAT rule:                                                  │
│    │  "Traffic hitting host:8080 → forward to container:8080"              │
│    ▼                                                                       │
│  ┌──────────────── docker0 Bridge (172.18.0.1) ───────────────────┐        │
│  │   Virtual switch — all containers on this network connect here │        │
│  │                                                                │        │
│  │   veth pair            veth pair            veth pair          │        │
│  │   (virtual cable)      (virtual cable)      (virtual cable)    │        │
│  │        │                    │                    │             │        │
│  │  ┌─────▼──────┐      ┌──────▼─────┐      ┌──────▼──────┐       │        │
│  │  │webstore-api│      │webstore-db │      │  adminer    │       │        │
│  │  │172.18.0.2  │─────▶│172.18.0.3  │◀─────│172.18.0.4   │       │        │
│  │  │  :8080     │ DNS  │  :5432     │ DNS  │   :8080     │       │        │
│  │  └────────────┘      └────────────┘      └─────────────┘       │        │
│  └────────────────────────────────────────────────────────────────┘        │
└────────────────────────────────────────────────────────────────────────────┘
```

**What is a veth pair?**
Every container gets a virtual ethernet cable. One end lives inside the container (named `eth0` from inside). The other end connects to the `docker0` bridge on the host. When a container sends a packet, it travels down its virtual cable to the bridge, which forwards it to the right destination — exactly like a physical network switch reads MAC addresses and forwards frames to the right port.

**How containers get IPs:**
Docker runs an internal DHCP-like system. When a container joins a network, Docker assigns it an IP from the network's subnet. The bridge itself gets the gateway IP (`.1`). Containers get sequential IPs from `.2` onward. These IPs are private and only reachable from within that Docker network.

---

## 4. Docker Network Modes

Docker ships with three network modes. Each solves a different problem.

| Mode | What it does | When to use it |
|---|---|---|
| **bridge** | Creates a private internal network. Containers communicate via Docker DNS. Port binding required for external access. | Default for almost everything — multi-container apps |
| **host** | Container shares the host's network stack directly. No isolation, no port binding needed. | When you need maximum performance or the app needs to bind to specific host ports |
| **none** | No network at all. Complete isolation. | Security-sensitive containers that should never communicate |

**Bridge (default — what you use 99% of the time):**

```bash
docker run --network webstore-network --name webstore-api nginx
# Container gets its own IP on webstore-network
# Reachable from other containers by name: webstore-api
# Not reachable from outside without -p flag
```

**Host:**

```bash
docker run --network host nginx
# Container binds directly to host port 80
# No NAT, no port mapping
# localhost:80 on the host reaches the container directly
# Risk: container can see and bind to any host port
```

**None:**

```bash
docker run --network none nginx
# No eth0, no IP, no internet
# Completely isolated — cannot send or receive any traffic
```

**The Rule:** Always use a named bridge network (`docker network create`) for multi-container apps. Never use the default `bridge` network (also called `bridge`) for anything beyond testing — it does not have Docker DNS, so containers cannot find each other by name.

---

## 5. Docker DNS — How Container Names Resolve

**The Phone Book Analogy:**
When you create a custom Docker network, Docker starts an embedded DNS server for that network. This DNS server maintains a live phone book — every container that joins the network gets its name registered as an entry. When webstore-api asks "who is webstore-db?", it calls Docker DNS at `127.0.0.11`, gets back the IP, and connects.

```
webstore-api container
    │
    │  "Connect to webstore-db:5432"
    │
    ▼
Docker DNS (127.0.0.11)
    │
    │  Lookup: "webstore-db"
    │  Answer:  "172.18.0.3"
    │
    ▼
webstore-api connects to 172.18.0.3:5432
    │
    ▼
webstore-db container receives the connection
```

**Verify Docker DNS is configured inside a container:**

```bash
docker exec webstore-api cat /etc/resolv.conf

# Expected output:
nameserver 127.0.0.11
options ndots:0
```

`127.0.0.11` is Docker's embedded DNS server. Every container on a custom network gets this configured automatically.

**Test name resolution from inside a container:**

```bash
docker exec webstore-api nslookup webstore-db

# Expected output:
Server:         127.0.0.11
Address:        127.0.0.11:53

Non-authoritative answer:
Name:   webstore-db
Address: 172.18.0.3
```

**Why this only works on custom networks:**
The default `bridge` network does not enable Docker DNS. Containers on it cannot resolve each other by name — only by IP. This is one of the main reasons you always create a named network for your app.

**What happens when a container restarts:**
When webstore-db restarts, it may get a different IP (e.g., `172.18.0.5` instead of `172.18.0.3`). Docker DNS updates automatically — webstore-api still connects to `webstore-db:5432` and gets the new IP without any configuration change. This is the same principle as Kubernetes labels and selectors — never hardcode IPs, always use names.

---

## 6. Port Binding — NAT in Action

**The Reception Desk Analogy:**
The host machine is a hotel reception desk. From the outside, everyone calls one number (the host IP). Reception (Docker's iptables rules) answers and routes each call to the right room (container). The guest in the room (the container) only ever sees an internal call — they never know the caller came from outside.

Port binding (`-p host_port:container_port`) creates a NAT rule on the host using iptables. When traffic arrives on the host port, iptables rewrites the destination IP and port and forwards it to the container.

```
External request:
  Destination: host_machine:8080

iptables DNAT rule (created by Docker):
  IF destination port = 8080
  THEN rewrite destination to 172.18.0.2:8080

Container receives:
  A normal incoming connection on its port 8080
  It never sees the original host IP or port
```

**Verify the iptables rule Docker created:**

```bash
sudo iptables -t nat -L DOCKER -n

# Expected output (simplified):
Chain DOCKER (2 references)
target  prot  opt  source    destination
DNAT    tcp   --   0.0.0.0/0 0.0.0.0/0   tcp dpt:8080 to:172.18.0.2:8080
DNAT    tcp   --   0.0.0.0/0 0.0.0.0/0   tcp dpt:8080 to:172.18.0.4:8080
```

**The port binding format:**

```
-p 8080:8080
   │    │
   │    └── Container port (what the app listens on inside)
   └──────── Host port (what the outside world connects to)
```

They do not have to match:

```bash
# Host port 3000 forwards to container port 8080
docker run -p 3000:8080 webstore-api
```

**What happens without port binding:**

```bash
docker run -d --name webstore-api --network webstore-network webstore-api
# No -p flag — container is running but unreachable from outside
# webstore-db can reach it (same network)
# Your browser cannot reach it
```

Containers on the same Docker network can communicate directly — no port binding needed between them. Port binding is only for traffic coming from outside the Docker network (your browser, external services).

---

## 7. Network Isolation — Why It Matters

Docker lets you create multiple networks and control exactly which containers can see each other. This is the same security principle as AWS VPC subnets — public subnet (exposed) and private subnet (internal only).

**The Webstore Security Model:**

```
┌─────────────────── webstore-network ──────────────────────┐
│                                                           │
│  webstore-frontend ──▶ webstore-api ──▶ webstore-db       │
│  (nginx:1.24)           (app)            (postgres:15)    │
│                                                           │
└───────────────────────────────────────────────────────────┘

webstore-frontend: port 80 exposed to host (-p 80:80)
webstore-api:      port 8080 exposed to host (-p 8080:8080)
webstore-db:       NO port exposed — internal only
adminer:           port 8080 exposed to host (-p 8081:8080) — dev only
```

`webstore-db` has no `-p` flag. It is unreachable from your browser, from the internet, from any other Docker network. Only containers on `webstore-network` can connect to it. This is production-safe database isolation without any firewall rules.

**Multi-network isolation:**

```bash
docker network create frontend-network
docker network create backend-network

# webstore-frontend only on frontend
docker run --network frontend-network --name webstore-frontend nginx:1.24

# webstore-api on both — the bridge between the two tiers
docker run --network frontend-network --name webstore-api webstore-api
docker network connect backend-network webstore-api

# webstore-db only on backend — invisible to frontend
docker run --network backend-network --name webstore-db postgres:15
```

```
frontend-network:   webstore-frontend ←→ webstore-api
backend-network:    webstore-api ←→ webstore-db

webstore-frontend cannot reach webstore-db — different networks
webstore-api can reach both — it is connected to both networks
```

**Verify a container's network connections:**

```bash
docker inspect webstore-api | grep -A 20 "Networks"
```

---

## 8. The Webstore Setup — Manual Commands Line by Line

This is the full webstore stack brought up manually. Every flag is explained.

**Roles and direction:**

```
webstore-api    = client  (connects TO the database)
webstore-db     = server  (waits for connections)
adminer         = client  (connects TO the database for the UI)
```

**Step 1 — Create the network**

```bash
docker network create webstore-network
```

This creates a private bridge network with Docker DNS enabled. Every container that joins this network can reach every other container by name.

**Step 2 — Start the database first**

```bash
docker run -d \
  --name webstore-db \
  --network webstore-network \
  -e POSTGRES_DB=webstore \
  -e POSTGRES_USER=admin \
  -e POSTGRES_PASSWORD=secret \
  -v webstore-db-data:/var/lib/postgresql/data \
  postgres:15
```

Start the server before the clients. webstore-api will fail to connect if the database is not ready when it starts.

**Step 3 — Start adminer (database UI)**

```bash
docker run -d \
  -p 8081:8080 \
  --name adminer \
  --network webstore-network \
  adminer
```

Adminer connects to any database using the connection form in the browser. Use `webstore-db` as the server hostname — Docker DNS resolves it automatically.

**Step 4 — Build and start the API**

```bash
docker build -t webstore-api .

docker run -d \
  -p 8080:8080 \
  --name webstore-api \
  --network webstore-network \
  -e DB_HOST=webstore-db \
  -e DB_PORT=5432 \
  -e DB_NAME=webstore \
  -e DB_USER=admin \
  -e DB_PASSWORD=secret \
  webstore-api
```

**The final data flows:**

```
App path:   Browser → localhost:8080 → webstore-api → webstore-db:5432
Debug path: Browser → localhost:8081 → adminer → webstore-db:5432
```

---

## 9. Debugging Docker Networking

**Symptom: container cannot reach another container**

```bash
# Step 1 — Are they on the same network?
docker inspect webstore-api | grep -A 5 "Networks"
docker inspect webstore-db | grep -A 5 "Networks"

# Step 2 — Can the container resolve the hostname?
docker exec webstore-api nslookup webstore-db

# Step 3 — Can the container reach the port?
docker exec webstore-api nc -zv webstore-db 5432

# Step 4 — Check what the container is actually trying to connect to
docker logs webstore-api
```

**Symptom: browser cannot reach container**

```bash
# Step 1 — Is the port binding active?
docker ps | grep webstore-api
# Look for: 0.0.0.0:8080->8080/tcp

# Step 2 — Is the container running?
docker ps

# Step 3 — Is the app inside listening on the right port?
docker exec webstore-api ss -tlnp
```

**Symptom: containers on same network cannot find each other**

Most common cause: using the default `bridge` network instead of a named network.

```bash
# Wrong — default bridge, no DNS
docker run --name webstore-api nginx
docker run --name webstore-db postgres:15

# Right — named network, DNS works
docker network create webstore-network
docker run --network webstore-network --name webstore-api nginx
docker run --network webstore-network --name webstore-db postgres:15
```

→ Ready to practice? [Go to Lab 02](../docker-labs/02-networking-volumes-lab.md)

---
# TOOL: 04. Docker – Containerization | FILE: 06-docker-volumes
---

[Home](../README.md) |
[History & Motivation](../01-history-and-motivation/README.md) |
[Technology Overview](../02-technology-overview/README.md) |
[Docker Containers](../03-docker-containers/README.md) |
[Port Binding](../04-docker-port-binding/README.md) |
[Networking](../05-docker-networking/README.md) |
[Volumes](../06-docker-volumes/README.md) |
[Layers](../07-docker-layers/README.md) |
[Build](../08-docker-build-dockerfile/README.md) |
[Registry](../09-docker-registry/README.md) |
[Compose](../10-docker-compose/README.md)

# Docker Volumes

## What This File Is About

Containers are ephemeral. When a container is deleted, everything written inside it is gone — including database rows, uploaded files, and logs. Volumes are Docker's answer to this problem. They store data outside the container so it survives container replacement, deletion, and rebuilds.

---

## Table of Contents

1. [The Core Problem](#1-the-core-problem)
2. [Types of Storage](#2-types-of-storage)
3. [Named Volumes — Docker Managed](#3-named-volumes--docker-managed)
4. [Bind Mounts — You Control the Path](#4-bind-mounts--you-control-the-path)
5. [Bind Mount Workflow](#5-bind-mount-workflow)
6. [Volume Management Commands](#6-volume-management-commands)
7. [When to Use What](#7-when-to-use-what)
8. [Real-World Database Example — webstore-db](#8-real-world-database-example--webstore-db)
9. [Safe Delete Flow](#9-safe-delete-flow)
[Final Compression](#final-compression-memorize)

---

## 1. The Core Problem

A container is a running process with a temporary filesystem. Everything inside that filesystem lives only as long as the container lives.

```
docker run postgres:15          → database starts, stores data inside container
docker stop webstore-db         → container stops
docker rm webstore-db           → container deleted
docker run postgres:15          → fresh container, ALL DATA IS GONE
```

This is intentional — containers are designed to be replaceable. The solution is to store data in a volume that lives independently of any container.

---

## 2. Types of Storage

| Type | Who controls the path | Where data lives | Best for |
|---|---|---|---|
| **Named Volume** | Docker | Docker-managed location on host | Database data, critical persistent state |
| **Bind Mount** | You | Exact path you specify on host | Development — edit code on host, see changes in container |
| **tmpfs** | OS | RAM only, not on disk | Sensitive data that must not touch disk |

---

## 3. Named Volumes — Docker Managed

Docker creates and manages the storage location. You give the volume a name and mount it to a path inside the container.

| Step | What you do | Command format | Example you run |
|---:|---|---|---|
| 1 | Create a named volume | `docker volume create VOLUME_NAME` | `docker volume create webstore-db-data` |
| 2 | Run container with named volume | `docker run -v VOLUME_NAME:/container/path IMAGE` | `docker run -v webstore-db-data:/var/lib/postgresql/data postgres:15` |
| 3 | List all volumes | `docker volume ls` | `docker volume ls` |
| 4 | Inspect a volume | `docker volume inspect VOLUME_NAME` | `docker volume inspect webstore-db-data` |

**What you observe:**

The volume mounts the named volume to PostgreSQL's data directory. PostgreSQL writes to `/var/lib/postgresql/data`. The data actually goes to the `webstore-db-data` volume on the host. If you delete the container and run a new one with the same volume, all data survives.

**Syntax breakdown:**
```bash
docker run -v webstore-db-data:/var/lib/postgresql/data postgres:15
           ↑                    ↑
     volume name          path inside container
```

---

## 4. Bind Mounts — You Control the Path

You specify an absolute path on your host. That host directory is mounted directly into the container at the specified container path. Changes in either location are instantly visible in the other.

| Step | What you do | Command format | Example you run |
|---:|---|---|---|
| 5 | Check your current location | `pwd` | `pwd` (note the output) |
| 6 | Create a folder on host | `mkdir host-data` | `mkdir host-data` |
| 7 | Run container with bind mount | `docker run -it --rm -v /absolute/host/path:/container/path IMAGE` | `docker run -it --rm -v $(pwd)/host-data:/data ubuntu:22.04` |

---

## 5. Bind Mount Workflow

| Step | What you do | Command | What happens |
|---:|---|---|---|
| 8 | Create folder on host | `mkdir ~/my-app-data` | Folder created on your laptop |
| 9 | Run container with bind mount | `docker run -it --rm -v ~/my-app-data:/data ubuntu:22.04` | `/data` inside container = `~/my-app-data` on host |
| 10 | Write file inside container | `echo "from container" > /data/test.txt` | File written |
| 11 | Exit container | `exit` | Container deleted |
| 12 | Check file on host | `cat ~/my-app-data/test.txt` | **Prints: `from container`** ✅ |
| 13 | Edit file on host | `echo "from host" >> ~/my-app-data/test.txt` | Modified on laptop |
| 14 | Run new container with same mount | `docker run -it --rm -v ~/my-app-data:/data ubuntu:22.04` | Fresh container |
| 15 | Read file inside container | `cat /data/test.txt` | Sees both lines (changes from host appear immediately) |

**Key insight:**
- Changes in container → visible on host immediately
- Changes on host → visible in container immediately
- It's the **same folder**, just accessed from two places

**Syntax breakdown:**
```bash
docker run -v /host/path:/container/path IMAGE
           ↑            ↑
     real folder    where it appears
     on laptop      inside container
```

---

## 6. Volume Management Commands

| Step | What you do | Command format | Example you run |
|---:|---|---|---|
| 16 | List all volumes | `docker volume ls` | `docker volume ls` |
| 17 | Inspect a volume (see location, driver, etc.) | `docker volume inspect VOLUME_NAME` | `docker volume inspect webstore-db-data` |
| 18 | Delete a specific volume | `docker volume rm VOLUME_NAME` | `docker volume rm webstore-db-data` |
| 19 | Delete all unused volumes | `docker volume prune` | `docker volume prune` |
| 20 | Force delete all unused volumes (no confirmation) | `docker volume prune -f` | `docker volume prune -f` |

**Important rule:**
- You cannot delete a volume that is currently being used by a container
- Stop and remove the container first, then delete the volume

---

## 7. When to Use What

| Situation | Use | Why |
|---|---|---|
| Database data (PostgreSQL, MySQL) | Named Volume | Data must survive container replacement |
| Application uploads (user files, images) | Named Volume | Critical data, managed by Docker |
| Production state, logs | Named Volume | Needs to persist across deployments |
| Source code during development | Bind Mount | You edit files on laptop, changes appear in container immediately |
| Configuration files | Bind Mount | Easy to edit, version control |
| Temporary testing | Bind Mount | Quick access to files |

**Decision rule:**
```
If data must survive and you don't need to touch it often → Named Volume
If you need to edit files frequently from host → Bind Mount
```

---

## 8. Real-World Database Example — webstore-db

**Problem:**
- PostgreSQL stores data in `/var/lib/postgresql/data` inside the container
- If the container is deleted, the webstore database is gone
- We need data to survive container deletion

**Solution:**
```bash
docker run -d \
  --name webstore-db \
  --network webstore-network \
  -e POSTGRES_DB=webstore \
  -e POSTGRES_USER=admin \
  -e POSTGRES_PASSWORD=secret \
  -v webstore-db-data:/var/lib/postgresql/data \
  postgres:15
```

**What this does:**
- `-v webstore-db-data:/var/lib/postgresql/data` → creates volume `webstore-db-data` and mounts it to PostgreSQL's data directory
- PostgreSQL writes to `/var/lib/postgresql/data`
- Data actually goes to the `webstore-db-data` volume
- If you delete the container and create a new one with the same volume, **all data is still there**

**Verification flow:**

| Step | Command | What happens |
|---:|---|---|
| 1 | Run webstore-db with volume | `docker run -d --name webstore-db -v webstore-db-data:/var/lib/postgresql/data -e POSTGRES_DB=webstore -e POSTGRES_USER=admin -e POSTGRES_PASSWORD=secret postgres:15` | Container starts, volume created |
| 2 | Connect and create data | `docker exec -it webstore-db psql -U admin -d webstore` | Enter PostgreSQL shell |
| 3 | Insert test data | `CREATE TABLE products (id SERIAL, name TEXT);` then `INSERT INTO products (name) VALUES ('Widget');` | Data written |
| 4 | Exit | `\q` | Back to host |
| 5 | Stop and delete container | `docker stop webstore-db` then `docker rm webstore-db` | Container gone |
| 6 | Start new container with same volume | `docker run -d --name webstore-db -v webstore-db-data:/var/lib/postgresql/data -e POSTGRES_DB=webstore -e POSTGRES_USER=admin -e POSTGRES_PASSWORD=secret postgres:15` | Fresh container, same volume |
| 7 | Check if data survived | `docker exec -it webstore-db psql -U admin -d webstore -c "SELECT * FROM products;"` | **Data still exists** ✅ |

---

## 9. Safe Delete Flow (Volumes Edition)

**Rule:** Volumes are independent of containers. You can delete a container without deleting its volume.

### Order of operations (non-negotiable)

| Step | What you do | Command format | Example |
|---:|---|---|---|
| 21 | Stop container (if running) | `docker stop CONTAINER_NAME` | `docker stop webstore-db` |
| 22 | Remove container | `docker rm CONTAINER_NAME` | `docker rm webstore-db` |
| 23 | **Only if you want to delete data:** Remove volume | `docker volume rm VOLUME_NAME` | `docker volume rm webstore-db-data` |

**Critical safety rule:**
- Removing a container does **NOT** delete its volumes
- Volumes persist until you explicitly delete them
- This prevents accidental data loss

**When to delete volumes:**
- Testing is done and you don't need the data
- Cleaning up old projects
- Resetting state completely

**When NOT to delete volumes:**
- Production data
- Any database you still need
- Anything you might want later

---

## Final Compression (Memorize)

**Problem:**
Containers are temporary → data inside them dies

**Solution:**
Volumes are permanent → data survives container deletion

**Two types:**
1. Named volumes → Docker manages, use for critical data
2. Bind mounts → You control path, use for development

**Commands to memorize:**
```bash
# Named volume
docker volume create webstore-db-data
docker run -v webstore-db-data:/var/lib/postgresql/data postgres:15

# Bind mount
docker run -v /host/path:/container/path IMAGE

# Management
docker volume ls
docker volume rm VOLUME_NAME
docker volume prune
```

**Mental model:**
```
Container (code runs here)  ──>  Volume (data lives here)
    ↓                              ↓
  Dies when deleted            Survives forever
```

**Delete order:**
1. Stop container
2. Remove container
3. (Optional) Remove volume

**Never forget:**
Data in containers = temporary
Data in volumes = permanent

→ Ready to practice? [Go to Lab 02](../docker-labs/02-networking-volumes-lab.md)

---
# TOOL: 04. Docker – Containerization | FILE: 07-docker-layers
---

[Home](../README.md) |
[History & Motivation](../01-history-and-motivation/README.md) |
[Technology Overview](../02-technology-overview/README.md) |
[Docker Containers](../03-docker-containers/README.md) |
[Port Binding](../04-docker-port-binding/README.md) |
[Networking](../05-docker-networking/README.md) |
[Volumes](../06-docker-volumes/README.md) |
[Layers](../07-docker-layers/README.md) |
[Build](../08-docker-build-dockerfile/README.md) |
[Registry](../09-docker-registry/README.md) |
[Compose](../10-docker-compose/README.md)

# Docker Layers

## What this file is about

This file teaches **how Docker images are structured and optimized**. If you can use everything here, you can build faster images, understand caching behavior, optimize Dockerfiles for speed, and diagnose why builds are slow.

1. [What Are Layers (Visual First)](#1-what-are-layers-visual-first)
2. [See Layers With Your Own Eyes](#2-see-layers-with-your-own-eyes)
3. [How Layers Are Created (Dockerfile → Layers)](#3-how-layers-are-created-dockerfile--layers)
4. [Layer Caching in Action (Build Twice)](#4-layer-caching-in-action-build-twice)
5. [What Breaks the Cache](#5-what-breaks-the-cache)
6. [Optimization Pattern (Bad → Good Dockerfile)](#6-optimization-pattern-bad--good-dockerfile)
7. [Layer Reuse When Pulling Images](#7-layer-reuse-when-pulling-images)
8. [Verify Layer Sharing (Practical Check)](#8-verify-layer-sharing-practical-check)
9. [Common Mistakes That Waste Cache](#9-common-mistakes-that-waste-cache)
10. [The Container Runtime Layer](#10-the-container-runtime-layer)  
[Final Compression (Memorize)](#final-compression-memorize)

---

## 1. What Are Layers (Visual First)

**Core concept:**
A Docker image is NOT a single file.
It is a **stack of read-only layers**.

Each layer represents the filesystem changes from **one Dockerfile instruction**.

![](./readme-assets/container-filesystem.jpg)

**What this image shows:**

```
┌─────────────────────────────────────────┐
│ WRITABLE CONTAINER LAYER (Runtime only) │  ← Created when container runs
│ Temporary, deleted with container       │
├─────────────────────────────────────────┤
│ LAYER 7: CMD ["node","app.js"]          │  ← Metadata only (no files)
├─────────────────────────────────────────┤
│ LAYER 6: COPY . .                       │  ← Your application code
├─────────────────────────────────────────┤
│ LAYER 5: RUN npm install                │  ← node_modules/ (heavy)
├─────────────────────────────────────────┤
│ LAYER 4: COPY package.json .            │  ← Dependency manifest
├─────────────────────────────────────────┤
│ LAYER 3: WORKDIR /app                   │  ← Directory structure
├─────────────────────────────────────────┤
│ LAYER 2: Intermediate OS setup          │  ← Base image internals
├─────────────────────────────────────────┤
│ LAYER 1: FROM node:20                   │  ← Base filesystem
└─────────────────────────────────────────┘
   ↑
   All these layers are READ-ONLY
   Stacked on top of each other
```

**Mental model:**
- Image = stack of transparent sheets
- Each sheet = one Dockerfile instruction
- Docker combines them into one visible filesystem
- Bottom layer = base image
- Top layer = your latest changes

---

## 2. See Layers With Your Own Eyes

**Goal:** Inspect actual layers of a real image.

| Step | What you do | Command | What to observe |
|---:|---|---|---|
| 1 | Pull a small image | `docker pull alpine:3.18` | Image downloaded |
| 2 | View its layers | `docker history alpine:3.18` | See each layer's size and command |
| 3 | Pull a Node.js image | `docker pull node:20-alpine` | Larger image downloaded |
| 4 | View its layers | `docker history node:20-alpine` | Many more layers visible |

**Example output:**
```bash
docker history node:20-alpine
```

```
IMAGE          CREATED        CREATED BY                                      SIZE
a1b2c3d4e5f6   2 weeks ago    CMD ["node"]                                    0B
b2c3d4e5f6a7   2 weeks ago    ENTRYPOINT ["docker-entrypoint.sh"]            0B
c3d4e5f6a7b8   2 weeks ago    COPY docker-entrypoint.sh /usr/local/bin/      1.2kB
d4e5f6a7b8c9   2 weeks ago    RUN /bin/sh -c apk add --no-cache ...          75MB
e5f6a7b8c9d0   2 weeks ago    ENV NODE_VERSION=20.11.0                        0B
f6a7b8c9d0e1   3 weeks ago    /bin/sh -c #(nop) ADD file:abc123... in /      7.3MB
```

**What each column means:**
- `IMAGE` → Layer ID (hash)
- `CREATED` → When this layer was built
- `CREATED BY` → Which Dockerfile instruction created it
- `SIZE` → How much disk space this layer added

**Key observations:**
1. Metadata instructions (`CMD`, `ENV`) add **0B** (no files changed)
2. `RUN` and `COPY` add actual size
3. Layers stack bottom → top
4. Each layer has a unique hash (ID)

---

## 3. How Layers Are Created (Dockerfile → Layers)

**Rule:** Each Dockerfile instruction creates one layer.

### Example Dockerfile:
```dockerfile
FROM node:20-alpine          # Layer 1
WORKDIR /app                 # Layer 2
COPY package.json .          # Layer 3
RUN npm install              # Layer 4
COPY . .                     # Layer 5
CMD ["node", "server.js"]    # Layer 6 (metadata)
```

### What happens during build:

| Step | Instruction | What Docker does | Layer created? |
|---:|---|---|---|
| 1 | `FROM node:20-alpine` | Downloads base image layers | Reuses existing layers |
| 2 | `WORKDIR /app` | Creates `/app` directory | ✅ New layer |
| 3 | `COPY package.json .` | Copies one file | ✅ New layer |
| 4 | `RUN npm install` | Installs dependencies | ✅ New layer (heavy) |
| 5 | `COPY . .` | Copies all source code | ✅ New layer |
| 6 | `CMD ["node", "server.js"]` | Sets metadata | ✅ New layer (0B) |

**Result:** 6 instructions = 6 new layers (plus base image layers)

**Mental model:**
```
Dockerfile line  →  Build step  →  New layer  →  Stacked on previous
```

---

## 4. Layer Caching in Action (Build Twice)

**Goal:** See Docker reuse layers when nothing changed.

### Experiment: Build the same image twice

| Step | What you do | Command | What happens |
|---:|---|---|---|
| 5 | Create a simple Dockerfile | See below | File created |
| 6 | Build image (first time) | `docker build -t cache-test:v1 .` | All layers built from scratch |
| 7 | Build image (second time) | `docker build -t cache-test:v1 .` | All layers use cache (instant) |

**Create this Dockerfile:**
```dockerfile
FROM alpine:3.18
RUN apk add --no-cache curl
RUN echo "Layer 3"
RUN echo "Layer 4"
CMD ["sh"]
```

**First build output:**
```bash
docker build -t cache-test:v1 .
```

```
[1/4] FROM alpine:3.18                                    5.2s
[2/4] RUN apk add --no-cache curl                         3.1s
[3/4] RUN echo "Layer 3"                                  0.3s
[4/4] RUN echo "Layer 4"                                  0.2s
```
**Total time: ~9 seconds**

**Second build output:**
```bash
docker build -t cache-test:v1 .
```

```
[1/4] FROM alpine:3.18                                    CACHED
[2/4] RUN apk add --no-cache curl                         CACHED
[3/4] RUN echo "Layer 3"                                  CACHED
[4/4] RUN echo "Layer 4"                                  CACHED
```
**Total time: ~0.1 seconds**

**What happened:**
- Docker computed a hash for each instruction
- Hashes matched previous build
- Docker reused existing layers
- No work needed = instant build

**Mental model:**
```
Same instruction + same context = same hash = reuse layer
```

---

## 5. What Breaks the Cache

**Rule:** Changing a layer invalidates that layer AND all layers after it.

### Experiment: Modify one line, see what rebuilds

| Step | What you do | Command | What happens |
|---:|---|---|---|
| 8 | Modify Layer 3 in Dockerfile | Change `echo "Layer 3"` to `echo "Modified"` | File changed |
| 9 | Rebuild | `docker build -t cache-test:v2 .` | Watch which layers rebuild |

**Modified Dockerfile:**
```dockerfile
FROM alpine:3.18
RUN apk add --no-cache curl
RUN echo "Modified"          # ← Changed this line
RUN echo "Layer 4"
CMD ["sh"]
```

**Build output:**
```
[1/4] FROM alpine:3.18                                    CACHED
[2/4] RUN apk add --no-cache curl                         CACHED
[3/4] RUN echo "Modified"                                 0.3s  ← Rebuilt
[4/4] RUN echo "Layer 4"                                  0.2s  ← Rebuilt
```

**What happened:**
- Layer 1 (FROM) → cached ✅
- Layer 2 (curl install) → cached ✅
- Layer 3 (echo modified) → **rebuilt** ❌
- Layer 4 (echo layer 4) → **rebuilt** ❌ (even though it didn't change!)

**Critical rule:**
```
Change at step N → rebuild N and everything after
```

**Why Layer 4 rebuilt:**
- Each layer depends on the previous layer's filesystem state
- Layer 3 changed
- Layer 4's context is now different (even if its instruction is the same)
- Docker cannot reuse it

---

## 6. Optimization Pattern (Bad → Good Dockerfile)

**Goal:** Order instructions to maximize cache reuse.

### Bad Dockerfile (cache breaks on every code change):

```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY . .                     # ← Copies EVERYTHING (including package.json)
RUN npm install              # ← Reinstalls dependencies every time code changes
CMD ["node", "server.js"]
```

**Problem:**
- Any code change → `COPY . .` layer changes
- This breaks cache for `RUN npm install`
- Dependencies reinstall **every time** (even if package.json didn't change)

### Good Dockerfile (cache preserved for dependencies):

```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package.json .          # ← Copy ONLY dependency manifest first
RUN npm install              # ← Install dependencies (cached until package.json changes)
COPY . .                     # ← Copy source code last
CMD ["node", "server.js"]
```

**Why this is better:**
- Code changes don't affect `COPY package.json .`
- `RUN npm install` stays cached
- Only `COPY . .` rebuilds (fast)

### Side-by-side comparison:

| Scenario | Bad Dockerfile | Good Dockerfile |
|---|---|---|
| Change `server.js` | Reinstalls all dependencies (slow) | Copies new code only (fast) |
| Change `package.json` | Reinstalls dependencies | Reinstalls dependencies |
| No changes | Cached | Cached |

**Benchmark:**
```bash
# Bad pattern: Change one line of code
docker build -t app:bad .
# Time: 45 seconds (npm install runs again)

# Good pattern: Change one line of code
docker build -t app:good .
# Time: 2 seconds (only COPY . . runs)
```

**The optimization principle:**
```
Stable instructions first → Volatile instructions last
```

**Order of stability:**
1. Base image (`FROM`) - almost never changes
2. System packages (`RUN apt-get install`) - rarely changes
3. Dependencies (`COPY package.json` + `RUN npm install`) - changes occasionally
4. Source code (`COPY . .`) - changes frequently

---

## 7. Layer Reuse When Pulling Images

**Context shift:** We've been talking about **building** images. Now we talk about **pulling** images.

**Key difference:**
- Building = creating layers locally
- Pulling = downloading pre-built layers from a registry

**Rule:** When pulling, Docker downloads only missing layers.

### How it works:

| Step | What you do | Command | What happens |
|---:|---|---|---|
| 10 | Pull first image | `docker pull node:20-alpine` | Downloads all layers |
| 11 | Pull related image | `docker pull node:20` | Reuses some layers, downloads only differences |

**Example scenario:**

You already have `node:20-alpine` (200MB).
Now you pull `node:20-bullseye` (900MB).

**What Docker does:**
1. Checks which layers you already have locally
2. Both images share base Debian layers
3. Downloads only the missing layers
4. Actual download: ~700MB (not 900MB)

**Mental model:**
```
Registry holds:     Layer A, Layer B, Layer C, Layer D
You have locally:   Layer A, Layer B
Docker downloads:   Layer C, Layer D only
```

**This is NOT rebuilding:**
- The image is already built (by someone else, on the registry)
- You're just downloading the missing pieces
- Layer reuse is based on exact hash matching

---

## 8. Verify Layer Sharing (Practical Check)

**Goal:** Prove that multiple images share layers.

| Step | What you do | Command | What to observe |
|---:|---|---|---|
| 12 | Check current disk usage | `docker system df` | Note "Images" size |
| 13 | Pull Ubuntu 22.04 | `docker pull ubuntu:22.04` | ~77MB downloaded |
| 14 | Check disk usage again | `docker system df` | Size increased by ~77MB |
| 15 | Pull Ubuntu 24.04 | `docker pull ubuntu:24.04` | ~80MB downloaded |
| 16 | Check disk usage again | `docker system df` | Size increased by ~20MB (not 80MB!) |

**Why the difference:**
- Both Ubuntu images share base layers
- Only the differences are stored
- Docker deduplicates automatically

**View shared layers:**
```bash
docker history ubuntu:22.04 > ubuntu22-layers.txt
docker history ubuntu:24.04 > ubuntu24-layers.txt
diff ubuntu22-layers.txt ubuntu24-layers.txt
```

You'll see some layers have identical hashes → those are shared.

---

## 9. Common Mistakes That Waste Cache

### Mistake 1: Copying everything first

❌ **Bad:**
```dockerfile
COPY . .
RUN npm install
```

✅ **Good:**
```dockerfile
COPY package.json .
RUN npm install
COPY . .
```

### Mistake 2: Installing packages and copying code in one layer

❌ **Bad:**
```dockerfile
RUN apt-get update && apt-get install -y curl && npm install
```

✅ **Good:**
```dockerfile
RUN apt-get update && apt-get install -y curl
COPY package.json .
RUN npm install
```

### Mistake 3: Not using `.dockerignore`

Without `.dockerignore`:
- `COPY . .` includes `node_modules/`, `.git/`, `*.log`
- Layer hash changes even when real source code didn't
- Cache breaks unnecessarily

**Create `.dockerignore`:**
```
node_modules
.git
*.log
.env
dist
build
```

### Mistake 4: Updating packages in every build

❌ **Bad:**
```dockerfile
RUN apt-get update && apt-get install -y curl
```
This might change daily (package versions update).

✅ **Better:**
```dockerfile
RUN apt-get update && apt-get install -y curl=7.68.0-1
```
Pin versions when stability matters.

### Mistake 5: Combining unrelated operations

❌ **Bad:**
```dockerfile
RUN apt-get update && apt-get install -y curl && npm install && apt-get install -y git
```

✅ **Good:**
```dockerfile
RUN apt-get update && apt-get install -y curl git
COPY package.json .
RUN npm install
```

---

## 10. The Container Runtime Layer

**Critical concept:** When you run a container, Docker adds ONE writable layer on top.

![](./readme-assets/container-filesystem.jpg)

**The top layer in the diagram** = Container Layer (temporary)

### What this means:

| Layer type | Read/Write | Lifetime | Purpose |
|---|---|---|---|
| Image layers (all below) | Read-only | Permanent | Shared across containers |
| Container layer (top) | Writable | Until container deleted | Container-specific changes |

### Experiment: Write data in a container

| Step | What you do | Command | What happens |
|---:|---|---|---|
| 17 | Run container | `docker run -it --name test alpine:3.18` | Container starts |
| 18 | Create file | `echo "test" > /tmp/file.txt` | File written to container layer |
| 19 | Exit | `exit` | Container stops |
| 20 | Start same container | `docker start -i test` | File still exists |
| 21 | Delete container | `docker rm test` | Container layer deleted |
| 22 | Run new container | `docker run -it alpine:3.18` | File is gone (fresh container layer) |

**Mental model:**
```
Image layers (read-only)  →  Shared by all containers
     +
Container layer (writable)  →  Unique per container, deleted with container
```

**Why this matters:**
- Changes in containers don't affect the image
- Multiple containers from same image don't interfere
- This is why you need volumes for persistent data

---

## Final Compression (Memorize)

### What layers are:
- Image = stack of read-only layers
- Each Dockerfile instruction = one layer
- Layers stack bottom (base) → top (your code)

### How caching works:
- Docker hashes each instruction + context
- Same hash = reuse layer
- Different hash = rebuild that layer + all after it

### Optimization rule:
```
Stable first → Volatile last

1. FROM (base image)
2. RUN (system packages)
3. COPY (dependency manifest)
4. RUN (install dependencies)
5. COPY (source code)
6. CMD (startup command)
```

### Build vs Pull:
- **Build** = create layers locally, cache reused within builds
- **Pull** = download pre-built layers, reuse based on hash matching

### Container runtime:
- Image layers = read-only, shared
- Container adds one writable layer = temporary, deleted with container

### Commands to remember:
```bash
docker history IMAGE              # See all layers
docker build -t name .            # Build uses cache
docker system df                  # Check layer disk usage
```

### Critical insight:
```
Layer at position N changes
  ↓
Everything at position N+1, N+2... rebuilds
  ↓
Order matters for speed
```

**One-line truth:**
Docker images are stacks of cached, read-only layers; changing one layer invalidates everything after it, so put stable stuff first and volatile stuff last.

→ Ready to practice? [Go to Lab 03](../docker-labs/03-build-layers-lab.md)

---
# TOOL: 04. Docker – Containerization | FILE: 08-docker-build-dockerfile
---

[Home](../README.md) |
[History & Motivation](../01-history-and-motivation/README.md) |
[Technology Overview](../02-technology-overview/README.md) |
[Docker Containers](../03-docker-containers/README.md) |
[Port Binding](../04-docker-port-binding/README.md) |
[Networking](../05-docker-networking/README.md) |
[Volumes](../06-docker-volumes/README.md) |
[Layers](../07-docker-layers/README.md) |
[Build](../08-docker-build-dockerfile/README.md) |
[Registry](../09-docker-registry/README.md) |
[Compose](../10-docker-compose/README.md)

# Docker Build (Dockerfile)

## 0) Absolute Zero (Before Docker Exists)

You have:

* a laptop
* a folder with your app code (files)

That's it.

No Linux knowledge required.
No Node knowledge required.
No Docker knowledge required.

---

## 1) The Problem (Before Docker)

Your app needs two things to run:

1. The app files (your code)
2. A way to run them (a runtime like Node, Python, Java)

Right now, both exist only on your laptop.

You want one package that contains everything needed to run the app so it runs anywhere.

That package is a Docker image.

---

## 2) Docker Cannot Guess Anything

Docker does not know:

* what language your app uses
* how to start it
* where files should live

So you must explain step by step.

That explanation is written in a text file called a **Dockerfile**.

At this point:

* nothing runs
* nothing is built

---

## 3) Two Timelines (Core Mental Model)

### Build-time (when you run `docker build`)

Build-time instructions create an **image filesystem** (layers). They permanently change what exists inside the image.

Common build-time instructions:

* `FROM`
* `WORKDIR`
* `RUN`
* `COPY` (and `ADD`, rarely)
* `ENV` (sets defaults in the image)

### Run-time (when you run `docker run`)

Run-time is when Docker creates a **container** from the image and starts the default process defined by the image.

Run-time is driven by:

* `CMD` / `ENTRYPOINT` (image metadata that defines what starts)
* runtime environment variables (`docker run -e ...` overrides image `ENV`)

**Rule**

* If it must exist before the app starts → build-time
* If it happens when the app starts → run-time

Do not mix these mentally.

---

## 4) First Question Docker Asks → `FROM`

Docker cannot start from nothing.

So the first line must answer:

> "What should I start from?"

```dockerfile
FROM node:20
```

Plain English:

* "Start from a ready-made environment that already knows how to run Node apps."

Facts:

* You are not installing Node manually here
* You are selecting a prepared filesystem
* `FROM` must be first (non-negotiable)

---

## 5) `WORKDIR` — Set the Default Folder (Recommended)

```dockerfile
WORKDIR /app
```

Plain English:

* "Inside the image, treat `/app` as the current folder."

Facts:

* `WORKDIR` creates the folder if missing
* it replaces `cd` (which does not persist across layers)
* it prevents path confusion

---

## 6) `ENV` — Store Defaults (Not Secrets)

```dockerfile
ENV NODE_ENV=production \
    PORT=8080
```

Plain English:

* "Store key=value defaults inside the image."

Facts:

* `ENV` does not run anything
* values are available at runtime (e.g., `process.env`)
* runtime env vars override image env vars
* do not store secrets in images

---

## 7) `RUN` — Build-Time Setup

`RUN` executes while building the image and saves the result into the next layer.

The command you use depends on the **base image**:

* Alpine images → `apk`
* Debian/Ubuntu images → `apt-get`

Example (Alpine base):

```dockerfile
FROM node:20-alpine
RUN apk add --no-cache curl
```

Example (Debian base):

```dockerfile
FROM node:20
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*
```

Facts:

* `RUN` executes at build-time
* each `RUN` creates a layer
* use it for OS packages, dependency installs, downloads, and setup

Rule:

* Readability > micro-optimization
* combine `RUN` steps mainly when cleanup matters

---

## 8) `COPY` — Put Your App Into the Image (Normal Path)

```dockerfile
COPY . .
```

Chronological meaning:

* first `.` → your project folder on laptop (build context)
* second `.` → current folder inside image (`/app` because of `WORKDIR`)

Plain English:

* "Copy my app files into the image."

Facts:

* In normal builds, `COPY` is how your local code enters the image
* Docker can only copy files inside the build context
* use a `.dockerignore` to avoid copying junk (`node_modules`, `.git`, build outputs)

---

## 9) `.dockerignore` — Control What Gets Copied

When Docker runs `COPY . .`, it copies everything in the build context by default.
That includes junk that slows builds and breaks layer caching.

`.dockerignore` is a file in the same folder as your Dockerfile.
It tells Docker what to exclude from the build context.

**Create `.dockerignore` in your project root:**

```
node_modules
.git
*.log
.env
dist
build
```

**Why each line matters:**

| Entry | Why exclude it |
|---|---|
| `node_modules` | Already installed by `RUN npm install` inside the image — copying from host wastes space and breaks the install layer |
| `.git` | Version control history has no place in a runtime image |
| `*.log` | Log files change constantly — they break layer caching on every build |
| `.env` | Contains secrets — never bake secrets into an image |
| `dist` / `build` | Compiled output — the image should build this itself |

**Without `.dockerignore` — what goes wrong:**

```
COPY . .     ← copies node_modules (300MB), .git, .env, logs
               layer hash changes every build even if code didn't
               cache breaks → npm install runs again every time
```

**With `.dockerignore` — what happens:**

```
COPY . .     ← copies only your source code
               layer hash stable until code actually changes
               cache works → fast builds
```

**One-line rule:**
`.dockerignore` exists so `COPY . .` only copies what the image actually needs.

---

## 10) `EXPOSE` — Documentation Only

```dockerfile
EXPOSE 8080
```

Facts:

* `EXPOSE` does not open ports
* `EXPOSE` does not publish ports
* it is metadata only

Real access happens with port binding (covered in Port Binding notes):

```bash
docker run -p 8080:8080 webstore-api:1.0
```

---

## 11) `CMD` — Default Startup Command (Run-Time)

```dockerfile
CMD ["node", "server.js"]
```

Plain English:

* "When a container starts, run this command."

Facts:

* `CMD` does nothing during build
* it runs only when a container starts
* it can be overridden at runtime

---

## 12) Build the Image (Nothing Runs Yet)

```bash
docker build -t webstore-api:1.0 .
```

Meaning:

* `-t` → tag (name) the image
* `webstore-api` → image name
* `1.0` → version tag
* `.` → build context (files Docker is allowed to `COPY`)

After this:

* image exists
* app is not running

---

## 13) Verify Image

```bash
docker images
```

---

## 14) Run the Image (First Time Anything Runs)

```bash
docker run -p 8080:8080 webstore-api:1.0
```

Now:

* Docker creates a container
* executes `CMD`
* the app runs

---

## 15) Canonical Dockerfile Shape (Reference)

```dockerfile
FROM <base-image>

WORKDIR /app

RUN <install OS deps>

COPY <dependency manifests> ./
RUN <install app deps>

COPY . .

EXPOSE <app-port>   # metadata only

CMD ["<start-command>"]
```

---

## 16) Multi-Stage Builds — Production Images

A single-stage build puts everything into one image — build tools, compiler, test dependencies, and the runtime. This produces large images that contain code that should never run in production.

Multi-stage builds solve this. You define multiple `FROM` stages in one Dockerfile. The final stage copies only what it needs from earlier stages. Build tools never make it into the production image.

**Why this matters for the webstore-api:**

```
Single-stage build:
  Base image (node:20)           ~900MB
  + npm install (all deps)       ~200MB
  + source code                  ~5MB
  Total image size: ~1.1GB

Multi-stage build:
  Builder stage:  node:20 + all deps + source code (discarded)
  Runtime stage:  node:20-alpine + production deps + compiled output only
  Total image size: ~150MB
```

The runtime image is smaller, faster to pull, has fewer installed packages meaning fewer attack vectors, and contains nothing a developer would not want running in production.

**Multi-stage Dockerfile for webstore-api:**

```dockerfile
# Stage 1 — Builder
# This stage installs all dependencies and builds the app
FROM node:20-alpine AS builder

WORKDIR /app

# Copy dependency manifest first (cache this layer)
COPY package.json package-lock.json ./

# Install ALL dependencies including dev deps needed for build
RUN npm ci

# Copy source code and build
COPY . .
RUN npm run build

# Stage 2 — Production runtime
# This stage produces the final image — only what runs in production
FROM node:20-alpine AS production

WORKDIR /app

# Copy only production dependency manifest
COPY package.json package-lock.json ./

# Install only production dependencies
RUN npm ci --only=production

# Copy built output from builder stage — not the source code
COPY --from=builder /app/dist ./dist

EXPOSE 8080

CMD ["node", "dist/server.js"]
```

**Key lines explained:**

```
FROM node:20-alpine AS builder
↑ Each FROM starts a new stage. AS builder names it.

COPY --from=builder /app/dist ./dist
↑ This is the multi-stage copy — pulling built output from the builder stage.
  Only the compiled files come through. No node_modules from dev deps.
  No source TypeScript. No test files.

FROM node:20-alpine AS production
↑ This is the final stage. When you docker build, this is what you get.
  Everything from builder exists only during the build — it is discarded.
```

**Build and verify size reduction:**

```bash
# Build the multi-stage image
docker build -t webstore-api:1.0 .

# Check the image size
docker images webstore-api

# Confirm build tools are not in the final image
docker run --rm webstore-api:1.0 which tsc
# Should print nothing — TypeScript compiler not present
```

**The rule:** if your app has a build step — TypeScript compilation, webpack bundling, Go compilation — use multi-stage builds. The builder stage does the work. The runtime stage runs the result.

---

## 17) The Ordering Law (Memorize This)

> **Stable first. Volatile last.**

Order:

1. Base OS
2. System dependencies
3. App dependencies
4. App source code
5. Runtime command

Reason:

* Docker caches layers top → bottom
* changing a layer invalidates everything after it

---

## 18) Instruction Laws (Quick Reference)

* `FROM` → starting filesystem + tools
* `WORKDIR` → default folder (creates it)
* `RUN` → build-time execution (creates a layer)
* `COPY` → bring local files from build context
* `ENV` → static defaults (not secrets)
* `EXPOSE` → metadata only
* `CMD` → default runtime command

**File sourcing rules:**
* Local files → `COPY`
* Internet files → `RUN curl` / `RUN wget`
* Secrets / dynamic data → runtime, not image

**OS rule:**
Inside Docker = Linux.
Language tools are portable.
OS package managers are Linux-specific.

---

## 19) One-Line Truth

> A Dockerfile is a cached, ordered, Linux build recipe that separates build-time from run-time to create reproducible images.

→ Ready to practice? [Go to Lab 03](../docker-labs/03-build-layers-lab.md)

---
# TOOL: 04. Docker – Containerization | FILE: 09-docker-registry
---

[Home](../README.md) |
[History & Motivation](../01-history-and-motivation/README.md) |
[Technology Overview](../02-technology-overview/README.md) |
[Docker Containers](../03-docker-containers/README.md) |
[Port Binding](../04-docker-port-binding/README.md) |
[Networking](../05-docker-networking/README.md) |
[Volumes](../06-docker-volumes/README.md) |
[Layers](../07-docker-layers/README.md) |
[Build](../08-docker-build-dockerfile/README.md) |
[Registry](../09-docker-registry/README.md) |
[Compose](../10-docker-compose/README.md)

# Container Registries

## 1) What a Container Registry Is

A container registry is a **remote storage system for Docker images**.

It stores images so they can be:
- pushed by developers
- pulled by CI systems
- pulled by production servers

It does **not** run containers.

---

## 2) Why Registries Exist

Without a registry:
- images live only on your laptop
- CI cannot access them
- production cannot pull them

With a registry:
- one image
- reused everywhere
- no rebuild drift

---

## 3) Visual Mental Model (Registry as the Hub)

![](./readme-assets/container-registry.jpg)

What this image shows:

**Developer systems**
- Push → very common (after build)
- Pull → very common (base images, debugging)

**CI servers**
- Pull → always (to test, scan, deploy)
- Push → often (build pipelines, versioned images)

**Production servers**
- Pull → yes (to run images)
- Push → almost never (anti-pattern)

Key idea:
The registry is **passive storage**.
Everything else initiates communication.

**The Only Flow That Matters**
```
Developer ↔ Registry ↔ CI → Production
```
Same image. Different environments.

---

## 4) Common Container Registries (Awareness Only)

Examples you will see in real systems:
- Docker Hub
- GitHub Container Registry (ghcr.io)
- GitLab Container Registry
- Google Container Registry (gcr.io)
- Amazon Elastic Container Registry (ECR)
- Azure Container Registry (ACR)
- JFrog Artifactory
- Nexus
- Harbor

You do not need to learn each one now.
They all solve the same problem.

---

## 5) Public vs Private Images

Public images:
- anyone can pull
- no authentication required

Private images:
- authentication required
- commonly used in CI and production

This explains why login exists.

---

## 6) Authentication

To push or pull private images:
```bash
docker login
```

What happens:

* credentials are sent to the registry
* Docker stores them securely
* future pulls/pushes work automatically

Where credentials live:

* macOS Keychain
* Windows Credential Manager
* Linux credential helpers

---

## 7) Authentication Visual

![](./readme-assets/credential-helper.jpg)

What this image shows:

* Docker CLI requesting credentials
* OS credential store handling secrets
* Registry validating access

You do not manage tokens manually at this stage.

---

## 8) Tagging Strategy — How Real Teams Version Images

Tags are not just labels. They are the mechanism CI/CD pipelines use to decide what to deploy. A poorly thought-out tagging strategy causes deployments to pull stale images, makes rollbacks difficult, and makes production incidents harder to debug.

**The `latest` trap:**

`latest` is the default tag when no tag is specified. It sounds useful but causes serious problems in real pipelines:

```bash
# This is what latest actually means:
docker push myrepo/webstore-api:latest
# "latest" = whatever was pushed most recently
# NOT "the most stable version"
# NOT "the version that passed QA"
# NOT reproducible — tomorrow it may be a different image

# Three weeks later on production:
docker pull myrepo/webstore-api:latest
# What did you just pull? Impossible to know without checking the registry.
# If it breaks, what do you roll back to?
```

**The rule:** never deploy `latest` to production. Always deploy a specific, immutable tag.

**Semantic versioning tags — the standard for releases:**

```
v1.0.0    ← major.minor.patch
v1.1.0    ← new feature, backward compatible
v1.1.1    ← bug fix
v2.0.0    ← breaking change
```

```bash
# Tag and push a release
docker build -t webstore-api:v1.0.0 .
docker tag webstore-api:v1.0.0 akhiltejadoosari/webstore-api:v1.0.0
docker push akhiltejadoosari/webstore-api:v1.0.0
```

**Git SHA tags — the standard for CI/CD:**

Every commit produces an image. Tag it with the Git commit SHA so you can trace any deployed image back to the exact commit that built it.

```bash
# In a CI pipeline:
GIT_SHA=$(git rev-parse --short HEAD)
docker build -t webstore-api:${GIT_SHA} .
docker push akhiltejadoosari/webstore-api:${GIT_SHA}

# Example output:
# akhiltejadoosari/webstore-api:a3f92c1
```

When production has a bug, you check the deployed tag (`a3f92c1`), run `git show a3f92c1`, and see exactly what changed.

**Environment tags — for promotion workflows:**

Some teams tag images with the environment they are deployed to:

```bash
# Tag the same image for staging
docker tag webstore-api:v1.0.0 akhiltejadoosari/webstore-api:staging

# Promote to production after QA passes
docker tag webstore-api:v1.0.0 akhiltejadoosari/webstore-api:production
```

The underlying image is identical — only the tag changes. This makes rollback trivial: retag the previous version as `production` and redeploy.

**Tagging decision table:**

| Context | Tag to use | Example |
|---|---|---|
| Every CI build | Git SHA | `webstore-api:a3f92c1` |
| Versioned releases | Semantic version | `webstore-api:v1.0.0` |
| Current stable dev | `latest` | Only for local development |
| Production deploy | Specific SHA or semver | Never `latest` |
| Environment tracking | Environment name | `webstore-api:staging` |

**One-line rule:**
In production, every image tag must be immutable and traceable — either a Git SHA or a semantic version. `latest` is for local development only.

---

## 9) Publish webstore-api to Docker Hub (End-to-End Process)

Goal:
- Take the local image you built in section 08 (`webstore-api:1.0`)
- Publish it to Docker Hub so other machines and CI can pull it

This section includes:
- Docker Hub UI steps (create repository)
- Terminal steps (build, login, tag, push, verify)

---

### Step 0: Prerequisites (Docker Hub)

1) Sign in to Docker Hub (website).
2) Create a repository:
   - Name: `webstore-api`
   - Visibility: Public or Private (your choice)
3) After creation, your image target will look like:
   - `DOCKERHUB_USERNAME/webstore-api`

You can add your own screenshots here (recommended).

---

### Step 1: Ensure the Image Exists Locally

Check local images:

```bash
docker images
```

Look for:

* `webstore-api` under `REPOSITORY`
* a tag like `1.0`

If you do NOT see it, build it now (run this from the folder that contains your Dockerfile):

```bash
docker build -t webstore-api:1.0 .
```

Re-check:

```bash
docker images | head
```

---

### Step 2: Confirm Which Docker Account the Terminal Is Using

Docker can stay logged in from old sessions. Confirm current auth state:

```bash
docker info | grep -i username
```

If it prints a username, Docker is logged in.

---

### Step 3: Reset Login (Only When Needed)

Use this if:

* you see the wrong username
* push fails with permission errors
* you previously logged into a different account

Logout first:

```bash
docker logout
```

Now login again:

```bash
docker login
```

It will prompt for Docker Hub username and password (or token if you use one).

Verify again:

```bash
docker info | grep -i username
```

---

### Step 4: Tag the Image for Docker Hub

Docker Hub requires images to be tagged as:

```
DOCKERHUB_USERNAME/REPO_NAME:TAG
```

Tag your local image:

```bash
docker tag webstore-api:1.0 DOCKERHUB_USERNAME/webstore-api:1.0
```

Confirm the tag exists:

```bash
docker images | grep webstore-api
```

You should see both:

* `webstore-api:1.0`
* `DOCKERHUB_USERNAME/webstore-api:1.0`

---

### Step 5: Push the Image

Push to Docker Hub:

```bash
docker push DOCKERHUB_USERNAME/webstore-api:1.0
```

What happens:

* Docker checks which layers already exist in Docker Hub
* Only missing layers are uploaded
* Existing layers are reused

---

### Step 6: Verify Push Worked (Two Ways)

Terminal verification:

```bash
docker pull DOCKERHUB_USERNAME/webstore-api:1.0
```

Docker Hub verification:

* Open your repository page on Docker Hub
* Confirm the `1.0` tag exists

---

### Common Failure Modes (Fast Fix)

1. `denied: requested access to the resource is denied`
   - Cause: wrong Docker Hub username, not logged in, or repo not owned by you
   - Fix:
     ```bash
     docker logout
     docker login
     ```

2. `tag does not exist`
   - Cause: you tagged the wrong local image name or it was never built
   - Fix:
     ```bash
     docker build -t webstore-api:1.0 .
     docker tag webstore-api:1.0 DOCKERHUB_USERNAME/webstore-api:1.0
     ```

3. `unauthorized: authentication required`
   - Cause: not logged in or stale credentials
   - Fix:
     ```bash
     docker logout
     docker login
     ```

---

### Final Checkpoint

If you can do this from zero:

* build `webstore-api:1.0`
* create Docker Hub repo
* login correctly
* tag to `DOCKERHUB_USERNAME/webstore-api:1.0`
* push successfully

Then you understand container registries at the correct practical level.

**One-Line Definition**

A container registry is a remote store for container images so the same image can be shared across development, CI, and production.

→ Ready to practice? [Go to Lab 04](../docker-labs/04-registry-compose-lab.md)

---
# TOOL: 04. Docker – Containerization | FILE: 10-docker-compose
---

[Home](../README.md) |
[History & Motivation](../01-history-and-motivation/README.md) |
[Technology Overview](../02-technology-overview/README.md) |
[Docker Containers](../03-docker-containers/README.md) |
[Port Binding](../04-docker-port-binding/README.md) |
[Networking](../05-docker-networking/README.md) |
[Volumes](../06-docker-volumes/README.md) |
[Layers](../07-docker-layers/README.md) |
[Build](../08-docker-build-dockerfile/README.md) |
[Registry](../09-docker-registry/README.md) |
[Compose](../10-docker-compose/README.md)

# Docker Compose — Same System, Automated

## 1) Mental Model First (What You Are About to Read)

Docker Compose replaces many manual `docker run` commands with **one file**.

Below is the **entire webstore system** in one view.

Do not analyze it yet.
Just observe the shape.

```yaml
version: "3.9"

services:
  webstore-db:
    image: postgres:15
    environment:
      POSTGRES_DB: webstore
      POSTGRES_USER: admin
      POSTGRES_PASSWORD: secret
    volumes:
      - webstore-db-data:/var/lib/postgresql/data

  adminer:
    image: adminer
    ports:
      - "8081:8080"
    depends_on:
      - webstore-db

  webstore-api:
    build: .
    ports:
      - "8080:8080"
    environment:
      DB_HOST: webstore-db
      DB_PORT: 5432
      DB_NAME: webstore
      DB_USER: admin
      DB_PASSWORD: secret
    depends_on:
      - webstore-db

volumes:
  webstore-db-data:
```

What this shows at a glance:

* Three containers
* One private Docker network (created automatically)
* Two ports exposed for human access (8080 for API, 8081 for DB UI)
* One database accessed internally by hostname
* One named volume for database persistence

Everything below explains **this file**, line by line.

---

## 2) What Docker Compose Is

Docker Compose runs a multi-container system using **one declarative file** instead of many imperative commands.

Compose does not add new concepts.
It automates:

* container creation
* Docker networking
* DNS (service names)
* port binding
* startup order
* volume creation

---

## 3) Services Block (System Definition)

```yaml
services:
```

Meaning:

* Start of all containers in this system
* Each service becomes:
  * one container
  * one DNS hostname
  * one isolated process

---

## 4) webstore-db Service (Database Server)

```yaml
  webstore-db:
```

Meaning:

* Service name
* Also becomes hostname `webstore-db`
* Used by other containers to connect

```yaml
    image: postgres:15
```

Meaning:

* Use PostgreSQL version 15 — pinned, not `latest`
* Pulled automatically if missing

```yaml
    environment:
      POSTGRES_DB: webstore
      POSTGRES_USER: admin
      POSTGRES_PASSWORD: secret
```

Meaning:

* Environment variables passed into the container
* PostgreSQL uses them on first startup to create the database and admin user

```yaml
    volumes:
      - webstore-db-data:/var/lib/postgresql/data
```

Meaning:

* Mount the named volume to PostgreSQL's data directory
* Data survives `docker compose down` — it is not deleted unless you explicitly remove the volume

Important:

* No `ports` section
* Database is internal-only
* Not reachable from your browser or the internet

---

## 5) adminer Service (Database UI)

```yaml
  adminer:
```

Meaning:

* Lightweight database management UI
* Supports PostgreSQL, MySQL, SQLite
* No configuration needed — connects using the form in the browser

```yaml
    image: adminer
```

Meaning:

* Uses the official adminer image

```yaml
    ports:
      - "8081:8080"
```

Meaning:

* adminer listens on port 8080 inside the container
* Host port `8081` forwards to container port `8080`
* Open `http://localhost:8081` in your browser to access the UI

```yaml
    depends_on:
      - webstore-db
```

Meaning:

* webstore-db container starts before adminer
* Controls start order only — does not guarantee the database is ready to accept connections

**How to use adminer:**
1. Open `http://localhost:8081`
2. System: PostgreSQL
3. Server: `webstore-db` (Docker DNS resolves this)
4. Username: `admin`
5. Password: `secret`
6. Database: `webstore`

---

## 6) webstore-api Service (Application)

```yaml
  webstore-api:
```

Meaning:

* Application container
* Hostname becomes `webstore-api`

```yaml
    build: .
```

Meaning:

* Builds image from Dockerfile in current directory
* Equivalent to `docker build .`

```yaml
    ports:
      - "8080:8080"
```

Meaning:

* Host port `8080` forwards to app port `8080`
* Required for browser access to the API

```yaml
    environment:
      DB_HOST: webstore-db
      DB_PORT: 5432
      DB_NAME: webstore
      DB_USER: admin
      DB_PASSWORD: secret
```

Meaning:

* Database connection details for the app
* Uses service name `webstore-db` — same rule as manual Docker networking
* Containers talk by name, never by IP

```yaml
    depends_on:
      - webstore-db
```

Meaning:

* Starts webstore-db before the app
* Prevents obvious startup failures
* Not a health check — the app may still need retry logic for DB connections

---

## 7) Volumes Block

```yaml
volumes:
  webstore-db-data:
```

Meaning:

* Declares the named volume at the top level
* Docker creates it if it does not exist
* Survives `docker compose down`
* Only deleted with `docker compose down -v` or `docker volume rm`

---

## 8) What Compose Creates Automatically

When you run:

```bash
docker compose up
```

Compose automatically creates:

* one bridge network named `<project>_default`
* DNS entries for each service
* containers attached to that network
* named volumes declared in the `volumes` block

You do not need to define networks explicitly for this setup.

---

## 9) Running the System

Start everything:

```bash
docker compose up
```

Start in background:

```bash
docker compose up -d
```

Stop and clean up containers and network (volumes survive):

```bash
docker compose down
```

Stop and delete everything including volumes:

```bash
docker compose down -v
```

**Warning:** `docker compose down -v` deletes the database volume. All data is gone. Use only when you want a completely clean reset.

---

## 10) About the `-f` Flag

Default behavior:

* Compose reads `docker-compose.yml`
* Also accepts `compose.yml`

`-f` selects a specific file:

```bash
docker compose -f docker-compose.prod.yml up
docker compose -f docker-compose.prod.yml down
```

Rule:
If the file is named `docker-compose.yml` and you are in that folder, do not use `-f`.

---

## 11) Manual vs Compose

![](./readme-assets/docker-run-compose.jpeg)

Use manual Docker commands when:

* learning Docker
* debugging a single container
* understanding flags

Use Docker Compose when:

* running multi-container systems
* daily development
* you want reproducible setup

**Data flows (same as manual, just automated):**

App path:
```
Browser → localhost:8080 → webstore-api → webstore-db:5432 → webstore-db
```

Debug path:
```
Browser → localhost:8081 → adminer → webstore-db:5432 → webstore-db
```

One-line truth:
webstore-api connects to webstore-db using hostname `webstore-db` on a Docker network.
Compose only automates the same configuration you already know.

→ Ready to practice? [Go to Lab 04](../docker-labs/04-registry-compose-lab.md)

---
# TOOL: 04. Docker – Containerization | FILE: docker-labs
---

[Home](../README.md) |
[Labs Index](./README.md) |
[Lab 01](./01-containers-portbinding-lab.md) |
[Lab 02](./02-networking-volumes-lab.md) |
[Lab 03](./03-build-layers-lab.md) |
[Lab 04](./04-registry-compose-lab.md)

---

# Docker Labs

Hands-on sessions for every topic in the Docker notes.

Each lab builds on the previous one. Do them in order.
Do not move to the next lab until the checklist at the bottom is fully checked.

---

## The Project Thread

These four labs containerize the webstore from scratch — the same project that ran on a Linux server and was versioned with Git. By Lab 04 you have the entire three-tier webstore running from a single `docker compose up` command, with the API image pushed to Docker Hub and ready for Kubernetes.

| Lab | Where the webstore is | What you do |
|---|---|---|
| [Lab 01](./01-containers-portbinding-lab.md) | Not yet containerized | Pull images, run nginx as webstore-frontend, bind ports, debug containers |
| [Lab 02](./02-networking-volumes-lab.md) | Frontend running | Wire webstore-api to webstore-db on a Docker network, persist postgres data in a volume |
| [Lab 03](./03-build-layers-lab.md) | Network and storage wired | Build the webstore-api image from a Dockerfile, optimize layers, use multi-stage builds |
| [Lab 04](./04-registry-compose-lab.md) | Image built | Push to Docker Hub, write docker-compose.yml, bring the full three-tier webstore up in one command |

---

## Labs

| Lab | Topics | Notes |
|---|---|---|
| [Lab 01](./01-containers-portbinding-lab.md) | Containers + Port Binding | [03](../03-docker-containers/README.md) · [04](../04-docker-port-binding/README.md) |
| [Lab 02](./02-networking-volumes-lab.md) | Networking + Volumes | [05](../05-docker-networking/README.md) · [06](../06-docker-volumes/README.md) |
| [Lab 03](./03-build-layers-lab.md) | Layers + Build + Dockerfile | [07](../07-docker-layers/README.md) · [08](../08-docker-build-dockerfile/README.md) |
| [Lab 04](./04-registry-compose-lab.md) | Registry + Compose | [09](../09-docker-registry/README.md) · [10](../10-docker-compose/README.md) |

---
# TOOL: 05. Kubernetes – Orchestration | FILE: 00-setup
---

[Home](../README.md) | [Setup](../00-setup/README.md) | [Architecture](../01-architecture/README.md) | [YAML & Pods](../02-yaml-pods/README.md) | [Deployments](../03-deployments/README.md) | [Networking](../03.5-networking/README.md) | [State & Config](../04-state/README.md) | [Troubleshooting](../05-troubleshooting/README.md) | [CI-CD](../06-cicd/README.md) | [Observability](../07-observability/README.md) | [Cloud & EKS](../08-cloud/README.md)

# 00 — The Professional Local Setup

## What This File Is About

This guide covers the "job-legal" toolkit required to run a Kubernetes cluster on a MacBook Air. The goal is to use tools that are transferable from a local laptop to a 1,000-node AWS EKS cluster — no Minikube-only shortcuts that disappear in production.

---

## Table of Contents

1. [The Transferable CLI Toolkit](#1-the-transferable-cli-toolkit)
2. [What NOT to Get Attached To](#2-what-not-to-get-attached-to)
3. [Installation — MacBook Air](#3-installation--macbook-air)
4. [The Daily DevOps Cockpit Workflow](#4-the-daily-devops-cockpit-workflow)
5. [Session Management — To Close or Not to Close](#5-session-management--to-close-or-not-to-close)

---

## 1. The Transferable CLI Toolkit

These tools are platform-agnostic. If `kubectl` works on Minikube, it works on EKS.

| Tool | Why it's a Win | How it helps in a real job |
|---|---|---|
| **K9s** | A terminal UI skin for `kubectl` | In an incident, you can see failing Pods and logs 10x faster than typing commands |
| **Helm** | The Package Manager for K8s | 99% of companies use Helm to install apps like databases or monitoring tools |
| **kubectx** | A script to switch between clusters | Essential for switching from Development to Production clusters safely |

---

## 2. What NOT to Get Attached To

To stay cloud-ready, recognize that Minikube-only shortcuts do not exist in the real world:

| Minikube Shortcut | What replaces it in production |
|---|---|
| `minikube dashboard` | K9s, Lens, or the Cloud Console |
| `minikube service` | LoadBalancers or Ingress Controllers |
| `minikube mount` | AWS EBS or EFS for persistent storage |

---

## 3. Installation — MacBook Air

Use Homebrew to keep all tools updatable with a single `brew upgrade`.

```bash
# The Essentials
brew install minikube
brew install kubernetes-cli
brew install derailed/k9s/k9s

# The Package Manager (used from Phase 6 onward)
brew install helm
```

---

## 4. The Daily DevOps Cockpit Workflow

In a professional environment you don't click icons — you use the terminal to verify your environment is healthy before writing a single line of YAML.

### Step A — The Cold Start (Tab 1)

```bash
# 1. Launch Docker Engine
open -a Docker

# 2. Wait ~10 seconds, then verify Engine is up
#    You should see both a Client and Server version
docker version

# 3. Wake the cluster
minikube start

# 4. Audit the state
kubectl get nodes
kubectl get pods -A
```

Verify the node status is `Ready` and there are no failing Pods before proceeding.

### Step B — The Multi-Tab Cockpit

Never work in a single terminal window. The professional layout is two tabs.

1. Press `Command + T` to open a new tab
2. In the new tab, launch your live monitor:

```bash
k9s
```

| Tab | Purpose |
|---|---|
| **Tab 1** | Your Workstation — running `vi`, `kubectl`, `helm` |
| **Tab 2** | Your Live Feed — monitoring Pods and Deployments in K9s |

---

## 5. Session Management — To Close or Not to Close

Kubernetes is a heavy system. How you end your session directly affects your Mac's battery and RAM.

**Stepping away for a short break?**
Do nothing. Leave Minikube running in the background. It will be ready when you return.

**Done for the day?**
Hibernate the cluster to reclaim memory:

```bash
# 1. Exit K9s
Ctrl + C

# 2. Stop the cluster
minikube stop

# 3. Close Docker Desktop
```

**Cluster feels glitchy or messy?**
Full reset:

```bash
minikube delete
minikube start
```

This wipes the cluster state completely and starts clean.

---

→ Ready to practice? [Go to Lab 00](../k8s-labs/00-setup-lab.md)

---
# TOOL: 05. Kubernetes – Orchestration | FILE: 01-architecture
---

[Home](../README.md) | [Setup](../00-setup/README.md) | [Architecture](../01-architecture/README.md) | [YAML & Pods](../02-yaml-pods/README.md) | [Deployments](../03-deployments/README.md) | [Networking](../03.5-networking/README.md) | [State & Config](../04-state/README.md) | [Troubleshooting](../05-troubleshooting/README.md) | [CI-CD](../06-cicd/README.md) | [Observability](../07-observability/README.md) | [Cloud & EKS](../08-cloud/README.md)

# 01 — Architecture & Theory

## What This File Is About

Before touching a single command, you need the mental model.   
This file covers **why Kubernetes exists**, **what problem it solves over Docker alone**, and **how every component in the architecture communicates** — so that when you run `kubectl apply`, you know exactly what happens under the hood.

---

## Table of Contents

1. [The Core Problem — Before and After](#1-the-core-problem--before-and-after)
2. [The Analogy — Conductor and Orchestra](#2-the-analogy--conductor-and-orchestra)
3. [Docker vs Kubernetes](#3-docker-vs-kubernetes)
4. [The Architecture](#4-the-architecture)
5. [How a Deployment Request Flows](#5-how-a-deployment-request-flows)
6. [Cluster Setup Options](#6-cluster-setup-options)
7. [Action Step](#7-action-step)

---

## 1. The Core Problem — Before and After

### The Nightmare (Before)

Companies started with **monolithic apps** on massive physical servers. Then came **VMs** — better, but wasteful (allocating 10 GB RAM when the app needed 2 GB). Then came **Docker containers** — lightweight, isolated, perfect.

But Docker created a new problem. As teams broke their monolith into hundreds of tiny **microservices**, each running in its own container, the chaos began:

- Traffic spike at 2 AM → someone manually starts 200 new containers
- Server crashes at 3 AM → someone manually restarts every dead container
- New version to deploy → system goes offline while you swap it out

### The Solution (After)

**Kubernetes is a container orchestration platform.** You hand it a *desired state*:

```
"Always keep 5 copies of my web app running."
```

Kubernetes watches the cluster 24/7 and enforces that state automatically.

| Problem | Kubernetes Solution |
|---|---|
| Container crashes at 3 AM | **Self-Healing** — detects crash, spins up replacement instantly |
| Traffic spike | **Auto-Scaling** — creates more copies to handle the load |
| Deploying new version | **Rolling Updates** — swaps containers one by one, zero downtime |
| Traffic distribution | **Load Balancing** — spreads requests across all running containers |

> **Webstore angle:** The webstore serves customers 24/7. If the frontend Pod crashes at peak hours, Kubernetes detects it and replaces it before a single user notices the blip.

---

## 2. The Analogy — Conductor and Orchestra

Think of Kubernetes as the **Conductor of a massive Symphony Orchestra.**

- The **musicians** = your application containers (each knows how to do one job perfectly)
- The **sheet music** = your YAML configuration files (the desired state)
- The **Conductor (Kubernetes)** = manages the big picture, never plays an instrument itself

| Scenario | Orchestra | Kubernetes |
|---|---|---|
| Music needs to get louder | Conductor waves in 10 more violinists | Scales up — spins up more Pods |
| Trumpet player passes out | Backup trumpet player fills the seat instantly | Self-heals — replaces the crashed container |
| New piece of music introduced | Players swap parts one at a time, no silence | Rolling update — zero downtime deployment |

The key insight: **Kubernetes doesn't run your app. It manages the things that run your app.**

---

## 3. Docker vs Kubernetes

People often ask: *"Why not just use Docker?"*

| | Docker | Kubernetes |
|---|---|---|
| **What it is** | Containerization platform | Orchestration platform |
| **What it does** | Packages your app + dependencies into a container | Manages containers at scale |
| **Scope** | Single container on one machine | Thousands of containers across many machines |
| **Self-healing** | ❌ No | ✅ Yes |
| **Auto-scaling** | ❌ No | ✅ Yes |
| **Load balancing** | ❌ No | ✅ Yes |

> **The rule:** Docker *runs* the container. Kubernetes *manages* everything that runs containers.

---

## 4. The Architecture

A Kubernetes cluster has two sides: the **Control Plane** (the manager) and the **Worker Nodes** (the laborers).

```
                    ┌─────────────────────────────────────────┐
                    │           CONTROL PLANE (Manager)       │
                    │                                         │
  kubectl (CLI) ──▶ │  ┌─────────────┐    ┌────────────────┐  │
                    │  │  API Server │    │      etcd      │  │
  UI / REST    ───▶ │  │(Entry Point)│◀─▶ │  (Source of    │  │
                    │  └──────┬──────┘    │    Truth DB)   │  │
                    │         │           └────────────────┘  │
                    │  ┌──────▼──────┐   ┌────────────────┐   │
                    │  │  Scheduler  │   │   Controller   │   │
                    │  │(Assigns Pod │   │    Manager     │   │
                    │  │  to Node)   │   │(Watches State) │   │
                    │  └─────────────┘   └────────────────┘   │
                    └──────────────┬──────────────────────────┘
                                   │ assigns work
                    ┌──────────────▼──────────────────┐
                    │                                 │
          ┌─────────▼───────┐            ┌────────────▼───────────┐
          │  Worker Node 1  │            │    Worker Node 2       │
          │                 │            │                        │
          │ ┌─────────────┐ │            │ ┌──────────────────┐   │
          │ │   kubelet   │ │            │ │     kubelet      │   │
          │ │(Node Agent) │ │            │ │  (Node Agent)    │   │
          │ └──────┬──────┘ │            │ └────────┬─────────┘   │
          │        │        │            │          │             │
          │ ┌──────▼──────┐ │            │ ┌────────▼─────────┐   │
          │ │  containerd │ │            │ │   containerd     │   │
          │ │ (Runtime) * │ │            │ │   (Runtime) *    │   │
          │ └──────┬──────┘ │            │ └────────┬─────────┘   │
          │        │        │            │          │             │
          │  ┌─────▼──────┐ │            │  ┌───────▼──────────┐  │
          │  │  Pod  Pod  │ │            │  │  Pod   Pod  Pod  │  │
          │  │ [C1]  [C2] │ │            │  │ [C1]  [C1]  [C2] │  │
          │  └────────────┘ │            │  └──────────────────┘  │
          │                 │            │                        │
          │ ┌─────────────┐ │            │ ┌──────────────────┐   │
          │ │  Kube Proxy │ │            │ │   Kube Proxy     │   │
          │ │(Networking) │ │            │ │  (Networking)    │   │
          │ └─────────────┘ │            │ └──────────────────┘   │
          └─────────────────┘            └────────────────────────┘                      
```

### Control Plane Components (The "Manager")
These components run on the Master node and manage the cluster.

*   **API Server (`kube-apiserver`):**  
       The central entry point and communication hub for the entire cluster. It handles authentication, authorization, and processes all API requests from you (via kubectl), internal controllers, and external tools.    

      **Job 1:** The Broadcaster (Communication): It provides the live event stream for the entire cluster. Instead of components trying to talk to each other, they all just tune into the API Server's broadcast to see if the desired state has changed and if there is any new work for them to do.

      **Job 2:** The Gatekeeper (Security & Storage): It is the absolute protector of the etcd database.
      Because it is the only component allowed to interact directly with etcd, it acts as the ultimate "Bouncer." It forces every single request (whether from you typing kubectl or an internal controller) to prove who they are (Authentication) and what they are allowed to do (Authorization) before it ever opens the vault to read or write data
.
.The Central Hub & Database Gatekeeper.   

*   **etcd:** 
      A distributed key-value database. It acts as the cluster's single source of truth, holding the exact state, configuration, and secrets of your entire system.
*   **Scheduler (`kube-scheduler`):**   
      Actively watches the API Server for new, unassigned "Pod requests".   
      It determines the optimal Worker Node by evaluating resource availability (CPU/memory), hardware constraints, persistent storage availability, and custom affinity rules.   
      (Note: It does NOT physically create the pod; it only assigns the node).
*   **Controller Manager (`kube-controller-manager`):**   
      Runs continuous background loops that constantly compare the cluster's actual state to your desired state and make corrections to maintain it. 
    *   *Analogy for understanding:* Think of it like a thermostat. If you set the temperature to 72 degrees (your desired state: "I want 3 Pods") and a window opens causing the temperature to drop (a Pod crashes), the thermostat detects the mismatch and turns on the heater (creates a new Pod) to fix it.
---

###  Worker Node Components (The "Laborers")
These components run on every server that executes your application code.

*   **Kubelet:**   
     The primary node agent. It continuously watches the API Server for new Pod requests assigned to its specific node, and commands the Container Runtime to physically start them.   
     It also reports node health back to the Control Plane.
*   **Container Runtime:**   
     The underlying software (such as containerd, CRI-O, or Docker Engine) that actually pulls the images and physically runs the containers.
*   **Kube Proxy:**   
     Handles the networking rules on the node, ensuring that network traffic is routed to the correct Pods.
    *   *Analogy for understanding:* Because Pods are constantly dying and being recreated with brand new IP addresses, Kube Proxy acts like a dynamic switchboard operator. It constantly updates the internal network rules so that when user traffic enters the cluster, it always gets routed to the correct, currently living Pods.
*   **Pod:**   
     The absolute smallest deployable object in Kubernetes. 
    *   *Analogy for understanding:* Kubernetes does not run naked containers. It wraps your container inside a "Pod." Think of it exactly like a pea pod: the container is the pea, and the Pod is the protective shell around it that gives it an IP address and shared storage.

---

## 5. How a Deployment Request Flows

When you run `kubectl apply -f webstore-frontend-deployment.yaml`, here is the exact sequence:
```
You  
 │  
 │  kubectl apply -f webstore-frontend-deployment.yaml 
 ▼
API Server  ──── stores request as "PENDING" ────▶ etcd
 │
 │  Scheduler detects unscheduled Pod, evaluates CPU/RAM on all nodes
 ▼
Scheduler  ──────────────────────────────────────────▶ picks Worker Node 1
 │
 │  writes assignment back to API Server ──▶ etcd updated
 ▼
kubelet (on Node 1)  ──── watching API Server, sees its assignment
 │
 │  tells containerd to pull the image
 ▼
containerd  ──── pulls image, starts container inside Pod
 │
 ▼
Kube Proxy  ──── assigns network/IP so Pod can communicate
 │
 ▼
Pod is RUNNING ✅

─────────────────── Later, if a Pod crashes ─────────────────
Controller Manager  ──── detects drift (desired=3, current=2)
 │
 │  notifies API Server to create a new Pod
 ▼
Scheduler picks a node → kubelet → containerd → Pod RUNNING ✅
```

> **The API Server is the only component that talks to etcd. Everything else talks to the API Server.**

---

## 6. Cluster Setup Options

| Option | What it is | Use Case |
|---|---|---|
| **Minikube** | Single-node cluster on your laptop | Learning and local practice ✅ |
| **Kubeadm** | Self-managed multi-node cluster | Full control, you handle everything |
| **EKS / AKS / GKE** | Provider-managed cluster | Production (AWS/Azure/GCP handle the Control Plane) |

> **Where you are now:** Minikube on your laptop. EKS comes in Phase 6.

---

## 7. Action Step

With Minikube running, open your terminal and run these two commands:

```bash
# See your running node
kubectl get nodes

# See the Control Plane components running as system Pods
kubectl get pods -n kube-system
```

The second command is the key one — you will literally see `etcd`, `kube-apiserver`, `kube-scheduler`, and `kube-controller-manager` running as Pods in the `kube-system` namespace. That is the Manager, alive.

→ Ready to practice? [Go to Lab 01](../k8s-labs/01-architecture-lab.md)

---
# TOOL: 05. Kubernetes – Orchestration | FILE: 02-yaml-pods
---

[Home](../README.md) | [Setup](../00-setup/README.md) | [Architecture](../01-architecture/README.md) | [YAML & Pods](../02-yaml-pods/README.md) | [Deployments](../03-deployments/README.md) | [Networking](../03.5-networking/README.md) | [State & Config](../04-state/README.md) | [Troubleshooting](../05-troubleshooting/README.md) | [CI-CD](../06-cicd/README.md) | [Observability](../07-observability/README.md) | [Cloud & EKS](../08-cloud/README.md)

# 02 — YAML Basics & The Pod

---

## What This File Is About

In Phase 1, you learned the theory **how things work under the hood**. In Phase 2, you move to the **Language**.   
This file covers YAML syntax, the anatomy of a Manifest, and how to deploy a Pod — the smallest unit of work in Kubernetes.

---

## Table of Contents

1. [The Concept — Declarative vs Imperative](#1-the-concept--declarative-vs-imperative)
2. [The 4 Pillars of a Manifest](#2-the-4-pillars-of-a-manifest)
3. [Labels and Selectors — The Glue](#3-labels-and-selectors--the-glue)
4. [The Anatomy of a Pod](#4-the-anatomy-of-a-pod)
5. [The DevOps Workflow — kubectl + vi](#5-the-devops-workflow--kubectl--vi)
6. [Action Step](#6-action-step)

---

## 1. The Concept — Declarative vs Imperative

In traditional IT, you give direct commands: *"Start this container."* That is **Imperative** — you describe the steps.

In Kubernetes, you use **Declarative Management**:

- **You:** Provide a YAML file saying, *"This is the Desired State I want."*
- **Kubernetes:** The Control Plane constantly compares your file to the cluster and acts to match it.

You stop telling Kubernetes *how* to do things. You tell it *what* you want, and it figures out the rest.

---

## 2. The 4 Pillars of a Manifest

Every Kubernetes object starts with the same skeleton. Before you write a single container name or port number, you must declare these four fields. The API Server reads them first — if any one is missing or wrong, it rejects the entire file before even looking at the rest.

A Kubernetes object is anything you can create, store, and manage in the cluster — every kind in your manifest table is an object, just a different type of record stored in etcd that the Control Plane works to keep alive.

Here is a real webstore Pod manifest. Read the comments — every pillar is labelled inline:
```yaml
apiVersion: v1          # PILLAR 1 — Which version of the K8s API dictionary to use.
                        # 'v1' covers core objects: Pod, Service, ConfigMap, Secret.
                        # Newer objects like Deployment use 'apps/v1'.

kind: Pod               # PILLAR 2 — What TYPE of object you are creating.
                        # The API Server reads this first to know what rules apply.
                        # Change this one word and you get a completely different object.

metadata:
  name: webstore-frontend         # PILLAR 3 — The identity card of this object. 
                              # Naming convention: projectname-role
                              # 'webstore' = the project
                              # 'api' = this Pod's role — API stands for Application Programming Interface
                              # It is the backend service that receives requests and returns data
                              # e.g. "give me the list of movies" → API processes it → sends back the data
                              # Other real examples: payments-api, auth-api, analytics-api
  labels:
    app: webstore            # The badge. Services and controllers find this Pod using this.
    env: dev                  # Environment tag — useful when you have dev/prod later

spec:                         # PILLAR 4 — The Blueprint. What should actually exist inside.
  containers:
    - name: api-container     # Container name inside the Pod.
                              # Convention: role-container (matches the Pod's role above)
      image: nginx:latest     # nginx = a real production web server, used here as a placeholder.
                              # It starts instantly and stays running — perfect for practice.
                              # In real webstore this becomes your actual app image:
                              # e.g. your-registry/webstore-frontend:1.0
      ports:
        - containerPort: 80   # Port the container listens on inside the Pod
```

### The 4 Pillars — Explained

**`apiVersion`** is the version of the Kubernetes API you are targeting.   
Think of it as telling the API Server which rulebook to open. Core objects like Pods and Services use `v1`. More advanced objects like Deployments and ReplicaSets live in the `apps/v1` group because they were added later. If you use the wrong version for a `kind`, the API Server rejects it immediately.

**`kind`** is the single most important field.   
It tells Kubernetes *what* you are asking it to create. One word — `Pod`, `Deployment`, `Service` — completely changes what the rest of the file means. The API Server uses this to decide which controller should handle your request. `kind` is **case sensitive** — `pod` and `Pod` are not the same thing, the API Server will reject it. Always write it exactly as shown: first letter uppercase, rest lowercase.

**`metadata`** is the identity card of the object.   
The `name` field must be unique within a Namespace. The `labels` block is where you attach tags — covered fully in Section 3, but notice it lives here, inside `metadata`, not inside `spec`.

**`spec`** is the blueprint — the "what should exist" section.   
Everything from here down is specific to the `kind` you declared. A Pod's `spec` holds containers. A Service's `spec` holds ports and selectors. A Deployment's `spec` holds replicas and a template. Same pillar, completely different content depending on the `kind`.

---

## 3. Labels and Selectors — The Glue

### Why "Label"? Why "Selector"?

The names are exactly what they sound like.

A **Label** is a stamp you press onto a Kubernetes object. Like a name badge at a conference — it does not change what the object *is*, it just gives it a tag that others can read. In Kubernetes, labels are simple key-value pairs you write in the `metadata` section: `app: webstore`, `env: production`, `tier: backend`.

A **Selector** is a search filter. It does not create anything new — it just copies the same label value and uses it to hunt for matching objects. A Service with `selector: app: webstore` is saying *"go check etcd and bring me every Pod in the cluster that has `app: webstore` stamped on it."*

**Same value. Two different roles:**

```yaml
# POD — this is where the label is CREATED (you are stamping this onto the Pod)
metadata:
  labels:
    app: webstore      # ← THE LABEL. The stamp.

# SERVICE — this is where the label is USED as a search filter
spec:
  selector:
    app: webstore      # ← SAME VALUE. "Find every Pod stamped with this."
```

The reason this system exists is because **Pods are ephemeral**. Every time a Pod dies and gets replaced, it gets a brand new name and a brand new IP address. If a Service tracked Pods by IP, it would lose them constantly. Instead, every new Pod just wears the same label as the one it replaced — and everything watching for that label picks it up instantly with zero reconfiguration.

---

### The Full Picture — Pod + Service Together

Here is the complete webstore setup. Read both files as one connected system:

```yaml
# FILE 1 — webstore-frontend-pod.yaml
# The Pod is the laborer. It wears the name badge.

apiVersion: v1
kind: Pod
metadata:
  name: webstore-frontend
  labels:
    app: webstore      # STAMP — this Pod is wearing the "webstore" badge
spec:
  containers:
    - name: api-container
      image: nginx:latest
      ports:
        - containerPort: 80
```

```yaml
# FILE 2 — webstore-service.yaml
# The Service is the router. It finds Pods by their badge.

apiVersion: v1
kind: Service
metadata:
  name: webstore-service
spec:
  type: LoadBalancer    # HOW the Service is exposed to the world
                        # (LoadBalancer, NodePort, ClusterIP — covered in Phase 3.5)

  selector:             # WHO this Service sends traffic TO
    app: webstore      # "Find every Pod wearing this badge and route traffic to them"

  ports:
    - port: 80          # WHAT port this Service listens on from the outside
      targetPort: 80    # What port to forward to inside the Pod
```

Think of it like a delivery service:

- **`type`** = the delivery method. Internal office mail only (ClusterIP)? A side door with a specific number (NodePort)? A full public address anyone on the internet can reach (LoadBalancer)?
- **`selector`** = the address label on the package. The delivery service does not care how many people live at that address — it just drops the package wherever it sees the matching label.
- **`ports`** = the door number. Knock on port 80 from outside, it gets forwarded to port 80 inside the Pod.

These three are completely independent. Change `type` without touching `selector`. Point `selector` at a different app without touching `ports`.

---

### The Real-World Example — webstore Goes Viral

It is 2 AM. webstore gets a traffic spike. Kubernetes scales from 1 Pod to 5. All 5 get completely random names and brand new IP addresses:

```
webstore-frontend-x7k2p   →  IP: 10.0.0.4
webstore-frontend-m9nq1   →  IP: 10.0.0.7
webstore-frontend-p3vc8   →  IP: 10.0.0.11
webstore-frontend-h6zt4   →  IP: 10.0.0.15
webstore-frontend-r2bw9   →  IP: 10.0.0.19
```

The Service does not track names. Does not track IPs. It looks for `app: webstore`. All 5 Pods are wearing that badge — so the Service finds all 5 instantly and load balances across them. When traffic drops and 4 Pods get terminated, the Service stops seeing their badges and stops routing to them. No config change. No restart.

**What breaks without labels:** Two apps in the same cluster — webstore API and an admin dashboard. Both running Pods. Without labels, the Service has no way to know which Pods belong to which app. User shopping traffic goes to the admin dashboard. Admin traffic goes to the frontend. Everything breaks.

That one line — `app: webstore` — is what keeps them separated.

> **The Rule:** The label on the Pod and the selector on the Service must be an **exact match**. One typo and they are completely invisible to each other. This is the most common beginner misconfiguration in Kubernetes.

---

### The 3 Superpowers Labels Unlock

**1. Networking — Services find Pods dynamically** (shown above) → Phase 3.5

**2. Scaling and Self-Healing — ReplicaSets count by label**
When you tell a ReplicaSet *"I want 3 copies running"*, it does not track Pod names — it counts how many Pods are currently wearing its label. If it counts 2, it creates a new one. If it counts 4, it terminates one. → Phase 3

**3. Node Placement — Labels on Nodes, not just Pods**
You can label Worker Nodes too. Label two nodes `storage: ssd`. Then tell a database Pod *"only schedule me on a Node with storage: ssd"*. The Scheduler reads that and guarantees the Pod only lands on the right hardware. → Phase 6

> **The architectural reality:** Labels and Selectors are not running software. They are pure text metadata stored in etcd. When a Service needs its Pods, it asks the API Server: *"Check etcd, give me the IPs of every Pod with this label."* The Control Plane does the rest.

---

## 4. The Anatomy of a Pod

A Pod is the smallest deployable unit in Kubernetes. Think of it as a **Space Shuttle** — a protective shell that carries your containers into the cluster and gives them everything they need to survive: an identity, a network, and storage.

Kubernetes never runs a naked container. It always wraps it in a Pod first. Here is why that wrapper exists and what every line inside it actually does:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: webstore-frontend       # The unique name of this Pod inside the cluster.
                            # When this Pod dies, the replacement gets a new random name.
                            # You never rely on this name to find Pods — you use labels.
  labels:
    app: webstore          # The badge. Services and controllers find this Pod using this.
    env: dev                # You can stack multiple labels on one Pod.

spec:
  containers:               # A Pod can hold MORE than one container.
                            # All containers in this list share the same IP and storage.
    - name: api-container   # The name of THIS container inside the Pod.
      image: nginx:latest   # The Docker image to pull. This is what actually runs.
                            # 'latest' means always pull the newest version.
                            # In production you pin this to a specific version e.g. nginx:1.25
      ports:
        - containerPort: 80 # The port THIS container listens on INSIDE the Pod.
                            # This is documentation — it does not actually open or block ports.
                            # The Service's targetPort is what routes traffic here.
```

**The Shared Environment** is the whole reason the Pod abstraction exists. All containers listed in the `spec` share the same network namespace — meaning they share one IP address and talk to each other via `localhost`. They also share the same storage volumes. This is how the Sidecar pattern works — one container runs the app, another runs alongside it handling logs or proxying — both living in the same Pod, sharing everything. → Sidecar covered in Phase 3.5.

**One IP per Pod** — every Pod gets its own internal cluster IP the moment it is born. That IP dies with the Pod. This is exactly why you never hardcode IPs anywhere — you use labels and selectors instead.

**Ephemeral (Temporary)** — Pods are disposable by design. If a standalone Pod dies, it stays dead. Kubernetes does not resurrect it — a Controller detects the death and creates a brand new replacement Pod with a new name and new IP. The old Pod is gone forever. Self-healing is not a Pod feature — it is a Controller feature. → Covered in Phase 3.

> **webstore angle:** Every webstore API request — browsing products, adding to cart, checking out — is handled inside a Pod. That Pod is the isolated unit of compute that owns the job. When traffic spikes and Kubernetes needs 5 copies, it does not clone the Pod — it creates 5 fresh ones, all wearing the same `app: webstore` badge, all picked up instantly by the Service.

---

## 5. The DevOps Workflow — kubectl + vi

The professional toolkit has no GUIs. You write manifests in the terminal, apply them, and read the cluster's response directly. Here is the full loop from writing a file to verifying it is healthy:

```bash
# Step 1 — Write the manifest
vi webstore-frontend-pod.yaml
# Use 'i' to enter insert mode, write your YAML, then ':wq' to save and exit.

# Step 2 — Apply it (send your Desired State to the API Server)
kubectl apply -f webstore-frontend-pod.yaml
# Expected output:
# pod/webstore-frontend created

# Step 3 — Check the Pod status
kubectl get pods
# Expected output when healthy:
# NAME             READY   STATUS    RESTARTS   AGE
# webstore-frontend    1/1     Running   0          10s
#
# READY 1/1   = 1 container running out of 1 total
# STATUS      = Running means Pod is alive and healthy
# RESTARTS 0  = nothing has crashed yet

# Step 4 — Read the birth certificate (when something looks wrong)
kubectl describe pod webstore-frontend
# This prints the full event log of the Pod's life.
# Scroll to the EVENTS section at the bottom — this is where errors appear.
# Common things you will see here:
#   "Pulling image nginx:latest"      → K8s is downloading the image
#   "Started container api-container" → container came up clean
#   "Back-off pulling image"          → image name is wrong or does not exist
#   "CrashLoopBackOff"                → container starts then immediately dies

# Step 5 — Monitor everything in real time
k9s
# Your live cockpit. Press 0 to see all namespaces.
# Arrow keys to navigate, 'd' to describe, 'l' to see logs, 'ctrl+d' to delete.
```

| Tool | What it does | When you use it |
|---|---|---|
| `vi` | Write and edit YAML manifests in the terminal | Every time you create or change a manifest |
| `kubectl apply -f` | Send Desired State to the API Server | After every save |
| `kubectl get pods` | Quick health check — status and restart count | After applying, or when something feels off |
| `kubectl describe pod` | Full event log — the Pod's birth certificate | When status is not `Running` or restarts are climbing |
| `kubectl logs [pod]` | Print what the container printed to stdout | When the Pod is running but the app inside is broken |
| `k9s` | Real-time visual cockpit for the whole cluster | Keep this open in Tab 2 at all times |

---

## 6. Action Step

Deploy the webstore API Pod and verify it is healthy. This is the full loop — write, apply, inspect:

```yaml
# webstore-frontend-pod.yaml
# Your first real manifest. Every field here maps to a concept in this file.

apiVersion: v1                # Core object — uses v1
kind: Pod                     # Creating a Pod (the smallest unit)
metadata:
  name: webstore-frontend         # The Pod's identity inside the cluster
  labels:
    app: webstore            # The badge — Services will use this to find it
    env: dev                  # Environment tag — useful when you have dev/prod later
spec:
  containers:
    - name: api-container     # Container name inside the Pod
      image: nginx:latest     # The image to run — swap this for your actual app later
      ports:
        - containerPort: 80   # Port the container listens on inside the Pod
```

```bash
# Deploy it
kubectl apply -f webstore-frontend-pod.yaml

# Verify it came up healthy
kubectl get pods

# What you should see:
# NAME             READY   STATUS    RESTARTS   AGE
# webstore-frontend    1/1     Running   0          <10s

# Open your cockpit and watch it live
k9s
```

**What success looks like in K9s:**
- Status column shows `Running` in green
- Ready shows `1/1`
- Restarts shows `0`

**What a broken Pod looks like:**
- `ImagePullBackOff` → the image name is wrong or does not exist
- `CrashLoopBackOff` → the container starts and immediately crashes
- `Pending` → the Scheduler cannot find a Node to place it on

If you see any of these, run `kubectl describe pod webstore-frontend` and scroll to the Events section at the bottom. The answer is always there. → Full troubleshooting toolkit in Phase 5.

→ Ready to practice? [Go to Lab 02](../k8s-labs/02-yaml-pods-lab.md)

---
# TOOL: 05. Kubernetes – Orchestration | FILE: 03-deployments
---

[Home](../README.md) | [Setup](../00-setup/README.md) | [Architecture](../01-architecture/README.md) | [YAML & Pods](../02-yaml-pods/README.md) | [Deployments](../03-deployments/README.md) | [Networking](../03.5-networking/README.md) | [State & Config](../04-state/README.md) | [Troubleshooting](../05-troubleshooting/README.md) | [CI-CD](../06-cicd/README.md) | [Observability](../07-observability/README.md) | [Cloud & EKS](../08-cloud/README.md)

---

# 03 — Deployments, ReplicaSets & Pod Management

## What This File Is About

In Phase 02 you deployed a naked Pod. You also proved it does not self-heal —
delete it and it stays dead. That is not production. This phase covers how
Kubernetes actually keeps applications alive, updates them without downtime,
and scales them under load.

---

## Table of Contents

1. [The Problem With Naked Pods](#1-the-problem-with-naked-pods)
2. [ReplicaSets — The Guardian](#2-replicasets--the-guardian)
3. [Deployments — The Manager](#3-deployments--the-manager)
4. [The Anatomy of a Deployment Manifest](#4-the-anatomy-of-a-deployment-manifest)
5. [Rolling Updates — Zero Downtime](#5-rolling-updates--zero-downtime)
6. [Rollbacks — The Emergency Undo](#6-rollbacks--the-emergency-undo)
7. [Scaling](#7-scaling)
8. [The Full Debug Loop for Deployments](#8-the-full-debug-loop-for-deployments)

> **Note on Sidecar Pattern:** Multi-container Pods and the Sidecar pattern are
> covered in [Phase 3.5 — Networking](../03.5-networking/README.md). They live
> there because Sidecars are fundamentally about a helper container handling
> network traffic alongside your main app.

---

## 1. The Problem With Naked Pods

In Phase 02 you ran this and watched the Pod disappear forever:

```bash
kubectl delete pod webstore-frontend
kubectl get pods
# No resources found — it is gone, nothing replaced it
```

A standalone Pod has no guardian. If it crashes at 3 AM, it stays crashed until
someone manually recreates it. In production that means downtime.

The solution is to never run naked Pods for anything that matters. Instead, you
describe the desired state to a Controller and let Kubernetes enforce it 24/7.

---

## 2. ReplicaSets — The Guardian

A **ReplicaSet (RS)** has one job: ensure that a specified number of identical
Pod replicas are running at all times.

**The Thermostat Analogy:**
Think of a ReplicaSet as a smart thermostat. You set the temperature to 3 (your
desired replica count). The thermostat watches the room constantly. If a Pod
crashes and the count drops to 2, it immediately turns on the heat and creates a
new Pod to bring it back to 3. If somehow 4 are running, it terminates one. It
never stops watching. It never sleeps.

```
Desired State: replicas = 3
Actual State:  running  = 2  (one crashed)

ReplicaSet detects drift → creates 1 new Pod → Actual = 3 ✅
```

**RC vs RS — Why RS Won:**
You may hear about Replication Controllers (RC) — the legacy version of RS.
ReplicaSets replaced them because RS uses a more powerful selector (`matchLabels`)
that allows it to adopt and manage even existing Pods that were not originally
created by the ReplicaSet itself. RC is obsolete. Always use RS (via Deployments).

**The Rule:**
You almost never create a ReplicaSet directly. You create a Deployment, which
creates and manages the ReplicaSet for you. The RS is an implementation detail
that Kubernetes handles behind the scenes.

---

## 3. Deployments — The Manager

If a ReplicaSet is the thermostat that keeps the count right, a **Deployment**
is the building manager that controls everything about the thermostat — including
how to upgrade it, roll it back, and configure it safely.

**The Hierarchy:**

```
You (kubectl apply)
        │
        ▼
┌───────────────────┐
│    Deployment     │  ← You create this. It owns everything below.
│  (The Manager)    │
└────────┬──────────┘
         │ creates and manages
         ▼
┌───────────────────┐
│    ReplicaSet     │  ← Deployment creates this. Ensures Pod count.
│  (The Guardian)   │
└────────┬──────────┘
         │ creates and manages
         ▼
┌──────────────────────────────┐
│  Pod    Pod    Pod           │  ← RS creates these. Your app runs here.
│ [C1]   [C1]   [C1]           │
└──────────────────────────────┘
```

**Why Deployments Over Naked ReplicaSets:**

| Feature | Naked Pod | ReplicaSet | Deployment |
|---------|-----------|------------|------------|
| Self-healing | ❌ | ✅ | ✅ |
| Scaling | ❌ | ✅ | ✅ |
| Rolling updates | ❌ | ❌ | ✅ |
| Rollbacks | ❌ | ❌ | ✅ |
| Update history | ❌ | ❌ | ✅ |

A Deployment is what you use for every stateless application in production.
Every time.

---

## 4. The Anatomy of a Deployment Manifest

A Deployment manifest has the same 4 pillars as a Pod manifest — but the `spec`
is more complex because it wraps a Pod template inside it.

```yaml
apiVersion: apps/v1         # PILLAR 1 — Deployments live in 'apps/v1' not 'v1'
                            # This is different from Pods which use 'v1'
                            # The API Server uses this to find the right rulebook

kind: Deployment            # PILLAR 2 — The type of object

metadata:
  name: webstore-frontend   # PILLAR 3 — The Deployment's identity
  labels:
    app: webstore
    tier: frontend

spec:                        # PILLAR 4 — The blueprint
  replicas: 3                # How many Pod copies to keep running at all times

  selector:                  # How this Deployment finds and owns its Pods
    matchLabels:             # Must match the labels in the Pod template below
      app: webstore          # ← This is the link between Deployment and its Pods
      tier: frontend         # If this does not match, the Deployment owns nothing

  template:                  # The Pod template — every Pod created uses this blueprint
    metadata:
      labels:
        app: webstore        # ← Must match selector.matchLabels above exactly
        tier: frontend       # One typo here and the Deployment cannot find its Pods
    spec:
      containers:
        - name: frontend-container
          image: nginx:1.24           # Pin to a specific version in production
                                      # Never use 'latest' in a real Deployment —
                                      # you cannot roll back 'latest' to 'latest'
          ports:
            - containerPort: 80
```

**The selector is the critical link.**
The `selector.matchLabels` on the Deployment must exactly match the `labels` on
the Pod template. This is how the Deployment knows which Pods it owns and is
responsible for. One typo and the Deployment creates Pods it cannot manage.

**`apps/v1` vs `v1`:**
Pods use `apiVersion: v1` because they are core objects. Deployments use
`apiVersion: apps/v1` because they were added later as part of the `apps` API
group. Getting this wrong is the most common first mistake with Deployments —
the API Server rejects the file immediately.

---

## 5. Rolling Updates — Zero Downtime

**The Construction Analogy:**
Imagine you need to renovate a 10-floor hotel without closing it. You cannot
kick out all the guests at once. So you renovate floor by floor — move guests
from floor 1 to a spare room, renovate floor 1, move guests back, then move to
floor 2. At no point is the hotel fully closed. Guests always have somewhere
to stay.

Kubernetes does the exact same thing with your Pods during an update.

**How it works:**

```
BEFORE UPDATE                    DURING UPDATE                   AFTER UPDATE
webstore-frontend v1.24          New RS (v1.25) starts           Old RS scales to 0
[Pod] [Pod] [Pod]                [Pod v1.25] starts healthy      [Pod v1.25]
Old RS: replicas=3               [Pod v1.24] terminated          [Pod v1.25]
New RS: replicas=0               Repeat for each Pod             [Pod v1.25]
                                                                 New RS: replicas=3
```

At no point are all Pods down. Traffic keeps flowing throughout.

**Trigger a rolling update:**
```bash
kubectl set image deploy/webstore-frontend \
  frontend-container=nginx:1.25
```

**Watch it happen live — run this immediately after:**
```bash
kubectl rollout status deploy/webstore-frontend
```

Expected output while updating:
```
Waiting for deployment "webstore-frontend" rollout to finish:
1 out of 3 new replicas have been updated...
2 out of 3 new replicas have been updated...
3 out of 3 new replicas have been updated...
Waiting for 3 pods to be ready...
deployment "webstore-frontend" successfully rolled out
```

**Check the ReplicaSet history after the update:**
```bash
kubectl get rs
```

Expected output:
```
NAME                          DESIRED   CURRENT   READY   AGE
webstore-frontend-7d9f8b6c4   3         3         3       2m    ← new RS (v1.25)
webstore-frontend-5c6b7a8d9   0         0         0       10m   ← old RS (v1.24) kept for rollback
```

**What the columns mean:**

| Column | Meaning |
|--------|---------|
| `DESIRED` | How many Pods this RS wants to run |
| `CURRENT` | How many Pods currently exist |
| `READY` | How many Pods are passing their health checks |

The old RS stays at `0` — Kubernetes keeps it so you can roll back instantly.

**A stuck rolling update — what it looks like:**
```bash
kubectl rollout status deploy/webstore-frontend
# Waiting for deployment "webstore-frontend" rollout to finish:
# 1 out of 3 new replicas have been updated...
# (hangs here — never progresses)
```

This means the new Pods are failing to start. Diagnose it:
```bash
kubectl get pods
# webstore-frontend-7d9f8b6c4-xxx   0/1   ImagePullBackOff   0   2m

kubectl describe pod webstore-frontend-7d9f8b6c4-xxx
# Scroll to Events — find the exact error
```

Fix the image name, apply again, and the rollout resumes.

---

## 6. Rollbacks — The Emergency Undo

**Check the full update history:**
```bash
kubectl rollout history deploy/webstore-frontend
```

Expected output:
```
REVISION  CHANGE-CAUSE
1         <none>
2         <none>
```

**Add a change cause to your updates (professional habit):**
```bash
kubectl set image deploy/webstore-frontend \
  frontend-container=nginx:1.25 \
  --record
```

Now history shows what changed:
```
REVISION  CHANGE-CAUSE
1         <none>
2         kubectl set image deploy/webstore-frontend frontend-container=nginx:1.25
```

**Emergency rollback to previous version:**
```bash
kubectl rollout undo deploy/webstore-frontend
```

**Rollback to a specific revision:**
```bash
kubectl rollout undo deploy/webstore-frontend --to-revision=1
```

After a rollback, check the RS again:
```bash
kubectl get rs
```

The old RS (v1.24) will scale back up to 3. The new RS (v1.25) will scale down
to 0. Kubernetes just swapped them — no new objects created.

---

## 7. Scaling

Scaling a Deployment means telling the ReplicaSet to run more or fewer Pods.
The Deployment updates the RS desired count and the RS handles the rest.

**Scale out (handle more traffic):**
```bash
kubectl scale deploy/webstore-frontend --replicas=5
```

**Scale in (reduce after traffic drops):**
```bash
kubectl scale deploy/webstore-frontend --replicas=3
```

When scaling in, Kubernetes uses LIFO (Last In, First Out) — the newest Pods
are terminated first. This is intentional: newer Pods are more likely to be
in the middle of a task than older, settled ones.

**Watch the scale happen in real time:**
```bash
kubectl get pods -w
```

The `-w` flag watches for changes. You will see Pods appear and disappear live.
Press `ctrl + c` to stop watching.

**Check the Deployment status after scaling:**
```bash
kubectl get deploy
```

Expected output:
```
NAME                READY   UP-TO-DATE   AVAILABLE   AGE
webstore-frontend   5/5     5            5           10m
```

| Column | Meaning |
|--------|---------|
| `READY` | Running Pods out of desired total |
| `UP-TO-DATE` | Pods running the latest template version |
| `AVAILABLE` | Pods passing health checks and ready for traffic |

---

## 8. The Full Debug Loop for Deployments

The same loop you built in Phase 02 — extended for Deployments.

```bash
# Step 1 — Lint before applying
yamllint webstore-frontend-deployment.yaml

# Step 2 — Apply
kubectl apply -f webstore-frontend-deployment.yaml

# Step 3 — Check Deployment health
kubectl get deploy

# Step 4 — Check the Pods it created
kubectl get pods

# Step 5 — Check the ReplicaSet
kubectl get rs

# Step 6 — Watch a rollout in progress
kubectl rollout status deploy/webstore-frontend

# Step 7 — Read the Deployment's event log
kubectl describe deploy/webstore-frontend

# Step 8 — Check rollout history
kubectl rollout history deploy/webstore-frontend
```

**Quick reference — all Deployment commands:**

| Command | When you use it |
|---------|----------------|
| `kubectl apply -f <file>` | Create or update a Deployment |
| `kubectl get deploy` | Check all Deployments and their ready count |
| `kubectl get rs` | See the ReplicaSets — old and new after updates |
| `kubectl get pods` | See the individual Pods the RS created |
| `kubectl describe deploy/<name>` | Full event log — errors appear here |
| `kubectl rollout status deploy/<name>` | Watch a rolling update in real time |
| `kubectl rollout history deploy/<name>` | See all previous revisions |
| `kubectl rollout undo deploy/<name>` | Emergency rollback to previous version |
| `kubectl set image deploy/<name> <c>=<image>` | Trigger a rolling update |
| `kubectl scale deploy/<name> --replicas=N` | Scale up or down |
| `kubectl get pods -w` | Watch Pod changes live |
| `kubectl delete deploy/<name>` | Delete the Deployment and all its Pods |

---

→ Ready to practice? [Go to Lab 03](../k8s-labs/03-deployments-lab.md)

---
# TOOL: 05. Kubernetes – Orchestration | FILE: 03.5-networking
---


---
# TOOL: 05. Kubernetes – Orchestration | FILE: 04-state
---


---
# TOOL: 05. Kubernetes – Orchestration | FILE: 05-troubleshooting
---


---
# TOOL: 05. Kubernetes – Orchestration | FILE: 06-cloud
---


---
# TOOL: 05. Kubernetes – Orchestration | FILE: k8s-labs
---

[Home](../README.md) |
[Lab 00](./00-setup-lab.md) |
[Lab 01](./01-architecture-lab.md) |
[Lab 02](./02-yaml-pods-lab.md) |
[Lab 03](./03-deployments-lab.md) |
[Lab 03.5](./03.5-networking-lab.md) |
[Lab 04](./04-state-lab.md) |
[Lab 05](./05-troubleshooting-lab.md) |
[Lab 06](./06-cloud-lab.md)

---

# Kubernetes Labs

Hands-on sessions for every phase in the K8s notes.

Do them in order. Do not move to the next lab until the checklist at the bottom is fully checked.

---

## The Project Thread

These labs take the webstore from a Docker Compose stack on your laptop to a production deployment on AWS EKS. Each lab leaves the webstore in a better state than it found it.

| Lab | Where the webstore is | What you do |
|---|---|---|
| [Lab 00](./00-setup-lab.md) | Not yet on K8s | Verify every tool, run the cold start drill, build the K9s cockpit habit |
| [Lab 01](./01-architecture-lab.md) | Not yet on K8s | Find every control plane component running live — map theory to reality |
| [Lab 02](./02-yaml-pods-lab.md) | First Pod on the cluster | Write manifests from scratch, apply, inspect, run the full debug loop |
| [Lab 03](./03-deployments-lab.md) | All 3 tiers as Deployments | Prove self-healing, trigger a rolling update, perform an emergency rollback, scale |
| [Lab 03.5](./03.5-networking-lab.md) | Deployments running, not yet wired | Services connect the tiers, frontend exposed, namespace boundaries enforced |
| [Lab 04](./04-state-lab.md) | Network complete, data not persisted | Postgres gets a PVC, credentials move into a Secret, config into a ConfigMap |
| [Lab 05](./05-troubleshooting-lab.md) | Full stack running locally | Readiness probe gates traffic, CronJob backs up the DB, debug loop drilled |
| [Lab 06](./06-cloud-lab.md) | Production-ready on Minikube | Same manifests, real cloud — eksctl creates the cluster, webstore deploys to EKS |

---

## Labs

| Lab | Topics | Notes |
|---|---|---|
| [Lab 00](./00-setup-lab.md) | Setup, daily workflow, cold start, K9s, yamllint | [00-setup](../00-setup/README.md) |
| [Lab 01](./01-architecture-lab.md) | Live cluster inspection, control plane components | [01-architecture](../01-architecture/README.md) |
| [Lab 02](./02-yaml-pods-lab.md) | Write manifests, deploy pods, labels, debug loop | [02-yaml-pods](../02-yaml-pods/README.md) |
| [Lab 03](./03-deployments-lab.md) | Deployments, self-healing, rolling updates, rollbacks, scaling | [03-deployments](../03-deployments/README.md) |
| [Lab 03.5](./03.5-networking-lab.md) | Services, kube-dns, Sidecar pattern, Namespaces | [03.5-networking](../03.5-networking/README.md) |
| [Lab 04](./04-state-lab.md) | PersistentVolumes, PVCs, ConfigMaps, Secrets | [04-state](../04-state/README.md) |
| [Lab 05](./05-troubleshooting-lab.md) | Probes, Jobs, CronJobs, DaemonSets, full debug loop | [05-troubleshooting](../05-troubleshooting/README.md) |
| [Lab 06](./06-cloud-lab.md) | EKS, eksctl, EBS CSI driver, ECR, Ingress, HPA | [06-cloud](../06-cloud/README.md) |

---

## After Kubernetes

CI-CD and Observability are their own tools in this runbook — not phases of Kubernetes. They live at the same level as every other tool because they are not Kubernetes features. They are disciplines that happen to use a Kubernetes cluster.

→ [06. CI-CD – Pipelines & GitOps](../../06.%20CI-CD%20–%20Pipelines%20%26%20GitOps/README.md) — automate every `kubectl apply` you just ran manually

→ [07. Observability – Monitoring & Logs](../../07.%20Observability%20–%20Monitoring%20%26%20Logs/README.md) — instrument what CI-CD deployed so you can see inside it

---
# TOOL: 08. AWS – Cloud Infrastructure | FILE: 01-intro-aws
---

[Home](../README.md) | 
[Intro to AWS](../01-intro-aws/README.md) | 
[IAM](../02-iam/README.md) | 
[VPC & Subnet](../03-vpc-subnet/README.md) | 
[EBS](../04-ebs/README.md) | 
[EFS](../05-efs/README.md) | 
[S3](../06-s3/README.md) | 
[EC2](../07-ec2/README.md) | 
[RDS](../08-rds/README.md) | 
[Load Balancing & Auto Scaling](../09-Load-balancing-auto-scaling/README.md) | 
[CloudWatch & SNS](../10-cloudwatch-sns/README.md) | 
[Lambda](../11-lambda/README.md) | 
[Elastic Beanstalk](../12-elastic-beanstalk/README.md) | 
[Route 53](../13-route53/README.md) | 
[CLI + CloudFormation](../14-cli-cloudformation/README.md)

---
# Introduction to AWS & Cloud Computing

Every system we build — from a small web app to a global streaming platform — runs on three invisible pillars: compute, storage, and networking.
AWS brings all three together as building blocks you can rent, combine, and scale instantly.
Instead of buying servers or worrying about power, racks, and backups, you build with ready-made components — like assembling Lego blocks in the cloud.

In this journey, we’ll move from the inside out — starting with the smallest unit of trust and control (IAM), then stepping outward to networks (VPC), storage (EBS, S3), compute (EC2), databases (RDS), and finally into automation, scaling, and infrastructure as code.

By the end, you won’t just “know” AWS services — you’ll think like an architect who sees how they connect and why each piece matters.

## Table of Contents

1. [Why Cloud Computing?](#1-why-cloud-computing)
2. [Why AWS?](#2-why-aws)
3. [Cloud Service Models](#3-cloud-service-models)
4. [Creating an AWS Free Tier Account](#4-creating-an-aws-free-tier-account)
5. [AWS Global Infrastructure (2025 Update)](#5-aws-global-infrastructure-2025-update)

---

<details>
<summary><strong>1. Why Cloud Computing?</strong></summary>

### The Problem Before Cloud

In the pre-cloud era, companies bought **physical servers** and ran their own data centers.
This meant:

* High capital cost for hardware and maintenance.
* Under-utilized resources (servers idling most of the time).
* Slow scaling and complex upgrades.

### The Cloud Revolution

Cloud Computing lets you **rent computing power, storage, and networks over the internet**.
You pay only for what you use and scale instantly without owning hardware.

| Concept             | Description                        | Example                           |
| ------------------- | ---------------------------------- | --------------------------------- |
| **Physical Server** | One machine per application        | HP or IBM server in a data center |
| **Virtualization**  | Many VMs on one server             | 1 physical → 10 virtual machines  |
| **Cloud Computing** | On-demand virtual resources online | Launch an EC2 instance on AWS     |

💡 **Analogy:** Owning a generator vs paying the electric bill — Cloud is on-demand power.

</details>

---

<details>
<summary><strong>2. Why AWS?</strong></summary>

### AWS at a Glance (2025)

* **Launch Year:** 2006 – first public cloud provider.
* **Market Share:** ~60% of cloud jobs worldwide.
* **Global Coverage:** 36 active Regions, 114 Availability Zones (AZs), 400+ Edge Locations.
* **Upcoming Regions:** Mexico, Taiwan, New Zealand, Saudi Arabia.

| Provider         | Core Strength                         | Market Presence |
| ---------------- | ------------------------------------- | --------------- |
| **AWS**          | Largest service portfolio & ecosystem | ⭐⭐⭐⭐⭐           |
| **Azure**        | Enterprise integration with Microsoft | ⭐⭐⭐             |
| **Google Cloud** | AI / ML excellence                    | ⭐⭐              |

### Why Start with AWS

* Standard in DevOps and Cloud roles.
* Skills transfer easily to Azure & GCP.
* Rich documentation and global community.

💡 **Analogy:** Learning AWS is like learning English first — opens every door in tech.

</details>

---

<details>
<summary><strong>3. Cloud Service Models</strong></summary>

### Theory & Notes

* **IaaS (Infrastructure as a Service)**

  * **What it is:** The provider gives you raw infrastructure — virtual machines, storage, and networks — over the internet.
  * **You manage:** Operating systems, applications, runtime, security patches.
  * **Provider manages:** Physical hardware, data centers, and virtualization.
  * **Analogy:** Renting a piece of land — you build your own house but don’t own the land.
  * **Examples:** AWS EC2, Google Compute Engine, Microsoft Azure VMs.

* **PaaS (Platform as a Service)**

  * **What it is:** The provider gives you infrastructure plus platforms/tools (like databases, runtime environments).
  * **You manage:** Only your code and data.
  * **Provider manages:** Infrastructure, OS, runtime, scaling, and security.
  * **Analogy:** Renting a fully furnished apartment — you move in and start using it.
  * **Examples:** AWS Elastic Beanstalk, Google App Engine, Heroku.

* **SaaS (Software as a Service)**

  * **What it is:** Complete software delivered over the internet.
  * **You manage:** Only usage and basic settings.
  * **Provider manages:** Everything else.
  * **Analogy:** Booking a hotel room — you enjoy the service without managing anything.
  * **Examples:** Gmail, Google Drive, Dropbox, Salesforce, Zoom.

---

| Model    | Provider Manages                     | You Manage              | Real Examples           | Best For    |
| -------- | ------------------------------------ | ----------------------- | ----------------------- | ----------- |
| **IaaS** | Hardware, Virtualization, Networking | OS, Runtime, Apps, Data | AWS EC2, Google Compute | Custom apps |
| **PaaS** | Everything above + OS, Runtime       | Apps, Data              | AWS Beanstalk, Heroku   | Developers  |
| **SaaS** | Everything                           | Only usage/config       | Gmail, Salesforce, Zoom | End users   |

---

### Cloud Market Comparison

| Cloud Provider        | Market Position  | Key Strengths                        | Job Market Share |
| --------------------- | ---------------- | ------------------------------------ | ---------------- |
| **AWS (Amazon)**      | #1 Market Leader | First-mover advantage, 200+ services | ~60%             |
| **Azure (Microsoft)** | #2 Strong Second | Deep Windows/Office integration      | ~25%             |
| **GCP (Google)**      | #3 Growing Fast  | Superior AI/ML tools                 | ~10%             |
| **Others**            | Niche Players    | Specialized industry solutions       | ~5%              |

* **High Demand:** AWS professionals are in the highest demand across industries.
* **Better Compensation:** Higher salaries and strong job security.
* **Skill Transferability:** Core AWS concepts work across clouds.
* **Ecosystem Support:** Huge community and documentation base.

<img src="images/service-control.jpg" alt="" width="600" height="375" />

</details>

---

<details>  
<summary><strong>4. Creating an AWS Free Tier Account</strong></summary>

### **Step-by-Step**

1. Visit [aws.amazon.com](https://aws.amazon.com) → click **“Create an AWS Account.”**  
2. Enter a valid email, strong password, and account name.  
3. Add a **credit or debit card** (for identity verification — Free Tier doesn’t charge if you stay within limits).  
4. Complete **SMS verification**.  
5. Choose the **Free Tier plan** when prompted.  
6. Sign in as **Root User** and open the **AWS Management Console**.

🎥 *Visual Guide:* [How to Create an AWS Free Tier Account (YouTube)](https://www.youtube.com/results?search_query=create+aws+free+tier+account)

---

### **Key Terms**

| Term | Meaning | Example |
|------|----------|----------|
| **Root User** | Full-access owner of the AWS account | Used for billing and account-level security |
| **IAM User** | Secure account for daily operations | You’ll create this next |
| **Free Tier** | Limited-usage plan or credit system for new users | 750 hrs/month of EC2 micro (for older accounts) |

---

### **⚙️ Free Tier Rules in 2025**

AWS introduced an updated Free Tier model on **July 15, 2025**.  
The eligibility depends on **when your account was created**:

| Account Created | What You Get | Duration | Notes |
|-----------------|---------------|-----------|--------|
| **Before July 15 2025** | Classic 12-month Free Tier | 12 months | Includes EC2 750 hrs/month, RDS 750 hrs/month, S3 5 GB, CloudWatch/Lambda “Always Free.” |
| **On or After July 15 2025** | New **Credit-based Free Tier** | Variable | You get ≈ $100–$200 credits + “Always Free” services (no fixed 12 months). |

---

### **🧭 2025 Free Tier Highlights (Classic Accounts)**

| Service | Free Limit | Duration |
|----------|-------------|-----------|
| **EC2** | 750 hrs/month (t2.micro or t3.micro) | 12 months |
| **RDS** | 750 hrs/month (MySQL, PostgreSQL, MariaDB, etc.) | 12 months |
| **S3** | 5 GB Standard storage | 12 months |
| **CloudWatch & Lambda** | Always Free within limits | Unlimited |
| **Credits (varies)** | ≈ $100 welcome credit for new accounts | Promo-based |

> 🔸 *If you signed up after July 15 2025, you’ll see a credit balance instead of time-based limits.  
> Always check **Billing → Free Tier Dashboard** to confirm what applies to you.*

---

### **Best Practices**

- Use the **Root User** only for **billing** and **security** tasks.  
- Enable **MFA (Multi-Factor Authentication)** on the Root User.  
- Create an **IAM Admin User** for all daily operations.  
- Regularly monitor usage in **Billing → Free Tier Dashboard** to avoid accidental charges.  

---

<details>
<summary><strong>📘 Note – AWS Free Tier Change (July 2025 Update)</strong></summary>

AWS modified its **Free Tier policy on July 15, 2025**.  
Your benefits depend on **when your account was created**:

| Account Created | Model | What You Get |
|-----------------|--------|---------------|
| **Before July 15 2025** | Classic Free Tier | 12 months of free usage for core services:<br>• EC2 750 hrs/month (t2.micro or t3.micro)<br>• RDS 750 hrs/month (MySQL/PostgreSQL/MariaDB)<br>• S3 5 GB Standard Storage<br>• CloudWatch & Lambda always free within limits |
| **On or After July 15 2025** | Credit-based Free Tier | No fixed 12-month period — instead you receive ≈ $100 to $200 in credits plus ongoing “Always Free” services. |

**Quick Reminder:**  
- The “12-month Free Tier” wording applies **only** to accounts created before July 15 2025.  
- Newer accounts follow the **credit model**, so verify your balance and limits under **Billing → Free Tier Dashboard** in the AWS Console.  
- AWS may adjust credits or service quotas by region or promotion, so always confirm your exact limits.

</details>

</details>

---

<details>
<summary><strong>5. AWS Global Infrastructure (2025 Update)</strong></summary>

### Why It Exists

AWS built a **worldwide network of data centers** so users anywhere can run apps with low latency and high reliability.
If one area goes down, others keep running — this is fault tolerance by design.

---

### Core Building Blocks

| Component                  | 2025 Count                         | Purpose                                  | Example                | Analogy                       |
| -------------------------- | ---------------------------------- | ---------------------------------------- | ---------------------- | ----------------------------- |
| **Region**                 | 36 active + 4 announced            | Geographic cluster of data centers       | `us-east-1` (Virginia) | Country                       |
| **Availability Zone (AZ)** | 114 operational                    | Independent data center within a Region  | `us-east-1a`           | City                          |
| **Edge Location**          | 400+                               | Delivers content fast via CloudFront CDN | Tokyo, Miami           | Courier hub                   |
| **Local Zone**             | 20+                                | Brings compute closer to metro areas     | Los Angeles            | Neighborhood station          |
| **Wavelength Zone**        | Telco partnerships (Verizon, KDDI) | Extends AWS to 5G networks               | AWS on Verizon 5G      | Mobile tower mini-data center |

---

### How They Work Together

* **Regions** are independent geographic areas.
* Each Region has 2–6 **AZs**, each with separate power & networking.
* **Edge Locations** serve cached data close to users for speed.
* **Local Zones** handle low-latency tasks like gaming or streaming.

📘 **Example:** An EC2 instance in `us-east-1` runs inside an AZ (e.g., `us-east-1a`).
You can replicate it to `us-east-1b` for high availability.

---

### Best Practices

| Goal                  | Recommendation                        | Why                                |
| --------------------- | ------------------------------------- | ---------------------------------- |
| **High Availability** | Use multiple AZs in the same Region   | One AZ failure won’t stop your app |
| **Low Latency**       | Choose Region closest to end-users    | Faster responses                   |
| **Data Compliance**   | Store data in legally approved Region | Meets local laws                   |
| **Cost Optimization** | Compare Region pricing                | Rates vary globally                |

---

### Real-World Analogy

Think of AWS like **Netflix’s global distribution system**:

* **Regions** = big production campuses.
* **AZs** = buildings inside those campuses.
* **Edge Locations** = servers in your city’s ISP delivering content instantly.

So when someone in India streams a movie, it’s served from the Mumbai Edge Location within the India Region — not from Virginia.

✅ **Key Takeaway:** AWS’s superpower is its **redundancy + reach** — a web of Regions, AZs, and Edge Locations ensuring speed and reliability everywhere.

</details>

---
---
# TOOL: 08. AWS – Cloud Infrastructure | FILE: 02-iam
---

[Home](../README.md) | 
[Intro to AWS](../01-intro-aws/README.md) | 
[IAM](../02-iam/README.md) | 
[VPC & Subnet](../03-vpc-subnet/README.md) | 
[EBS](../04-ebs/README.md) | 
[EFS](../05-efs/README.md) | 
[S3](../06-s3/README.md) | 
[EC2](../07-ec2/README.md) | 
[RDS](../08-rds/README.md) | 
[Load Balancing & Auto Scaling](../09-Load-balancing-auto-scaling/README.md) | 
[CloudWatch & SNS](../10-cloudwatch-sns/README.md) | 
[Lambda](../11-lambda/README.md) | 
[Elastic Beanstalk](../12-elastic-beanstalk/README.md) | 
[Route 53](../13-route53/README.md) | 
[CLI + CloudFormation](../14-cli-cloudformation/README.md)

# IAM (Identity and Access Management)

We’ve seen what AWS really is — a planet of servers, storage, and networks you can rent on demand.
But before we start building anything on it, we need to decide who gets the keys and what doors they can open.
That’s where IAM (Identity and Access Management) steps in — the service that defines people, roles, and boundaries inside this cloud world.

---

## Table of Contents
1. [IAM Concepts](#iam-concepts)
2. [IAM Hands-On (Console)](#iam-hands-on-console)

---

<details>
<summary><strong>1. IAM Concepts</strong></summary>

---

## 1. Why Do We Need IAM?

Imagine AWS as a huge company building full of resources — EC2 machines, S3 storage rooms, databases, and more.  
Without IAM, **anyone with the root account** could wander around, touch everything, and accidentally delete critical servers.  
That’s where IAM steps in — it’s your **security department**, giving each person a personalized keycard that unlocks only what they need.

---

### 2. Analogy

Think of **AWS as a company building**:  
- The **Root user** is the **company owner** — full control over everything.  
- **IAM Users** are **employees** with their own ID cards to enter the building.  
- **Groups** are **departments** like *Developers* or *Finance*, each with specific duties.  
- **Policies** are the **rules** that define what each department or user can access.  
- **Roles** are **temporary visitor passes** for people or systems that need short-term access.  
- **MFA** is like a **security guard** asking for a second proof before entry.  

> 🧠 IAM is the security department of your AWS company — it decides *who gets in*, *what doors they can open*, and *how safely they can move around.*


---

## 3. Concept Understanding

### IAM is Global
IAM isn’t tied to any AWS region — the settings apply across all regions.

### 🧍 Users
- **Users** represent individual people or specific services that need access to your AWS account.  
- Each user gets their own **credentials** — a unique username, password, and (optionally) access keys for programmatic access.  
- This separation keeps actions traceable to specific individuals, improving **security** and **accountability**.  
- Example:  
  - `alice` might use the console to manage EC2 instances.  
  - `build-server` (a service user) might use access keys to deploy applications automatically.  
- **Best practice:** *One user = One human or service.* Never share credentials between people.


### 👥 Groups
- **Groups** are collections of IAM users who share similar job roles or responsibilities.  
- Instead of assigning permissions to each user one by one, you assign them to a **group** — and all members automatically inherit those permissions.  
- This makes access control **organized**, **scalable**, and **easy to audit**.  
- Example:  
  - The `Developers` group has the **AmazonEC2FullAccess** policy.  
  - Any new developer added to the group instantly gets EC2 permissions — no extra setup needed.  
- A user can belong to **multiple groups** (e.g., `Developers` and `Audit-Team`), combining permissions from both.

<img src="images/IAM.png" alt="IAM" width="600" height="150" />

### 📜 Policies
- **Policies** are permission documents written in **JSON** that define what actions are **allowed** or **denied** in AWS.  
- They decide **who can do what** and on **which resources**.  
- Policies can be attached to **users**, **groups**, or **roles** to grant specific levels of access.  
- Each policy is made up of key fields:  
  - **Effect:** Allow or Deny  
  - **Action:** The specific AWS service operations (e.g., `ec2:StartInstances`)  
  - **Resource:** The AWS resources those actions apply to  
- Example: A “ReadOnlyAccess” policy allows viewing resources but blocks any changes.

<img src="images/IAM_Policies_inheritance.png" alt="IAM" width="600" height="300" /> 

### 🧩 Roles

- **What it is:**  
  An **IAM Role** is a **temporary identity** that carries specific permissions.  
  Unlike IAM Users, roles **don’t have long-term credentials** (no password or access keys).  
  Instead, AWS issues **short-lived security tokens** whenever a role is **assumed**, and they expire automatically.

---

- **Why we need it:**  
  Storing permanent access keys inside applications or servers is unsafe.  
  Roles solve this by letting AWS generate **temporary credentials** automatically, which are **rotated** and **expire** after a short duration.  
  This greatly reduces the risk of compromised keys.

---
- **How it works (simplified flow):**  
  1. The user, service, or application requests to **assume** a role.  
  2. **AWS STS** issues temporary credentials — `AccessKeyId`, `SecretAccessKey`, and `SessionToken`.  
  3. The entity uses these credentials to access AWS resources.  
  4. Credentials **expire automatically** (default: 1 hour), removing access safely.

---

- **Why it’s safer:**  
  - No permanent credentials stored inside applications or servers.  
  - Temporary, auto-rotating tokens limit the blast radius if compromised.  
  - Enforces **least privilege** and **session-based access control**.

---
### 🎬 Simplified Analogy

Imagine a movie set:

- **IAM User** = the **actor** (their normal self)  
- **IAM Role** = the **costume** (grants temporary powers for that scene)  
- **STS (Security Token Service)** = the **wardrobe department** that issues the costume and takes it back later  

Actors — whether humans or AWS services — can wear different **costumes (roles)** depending on what the **scene (task)** needs.  
When the scene ends, the costume is returned and access expires automatically.

---
- **Who can wear Roles:**  

  | Who Wears It | Description | Example |
  |---------------|--------------|----------|
  | 🧍 **IAM User (Human)** | A person manually switches to a different role for temporary elevated permissions. | A developer switches to `AdminRole` for maintenance, then returns to normal user access. |
  | ⚙️ **AWS Service** | A service automatically assumes a role to access other AWS resources securely. | An **EC2 instance** assumes a role to read/write data in an **S3 bucket** without storing credentials. |
  | 🔁 **Another AWS Account** | Roles can be shared between AWS accounts through a **trust policy** (cross-account access). | **Account A** allows **Account B** to assume a role to manage shared infrastructure. |
  | 🤖 **Application / Script / CLI** | Code or automation pipelines assume roles using **AWS STS (Security Token Service)**. | A **CI/CD pipeline** assumes a `DeployRole` to push new versions to production. |

---

- **Best Practice:**  
  > Humans use **Users**. AWS services use **Roles**. Always apply the **least privilege** principle.  

---

- **Coming up next:**  
  > We’ll see IAM Roles *in action* in the **EC2** and **Lambda** sections — where services automatically assume roles to access other AWS resources securely.

---

### ⚙️ In Action Example: EC2 Using a Role to Access S3

1. **Create a Role**  
   - Example permission:  
     ```json
     {
       "Effect": "Allow",
       "Action": "s3:GetObject",
       "Resource": "arn:aws:s3:::my-bucket/*"
     }
     ```
   - This policy allows reading objects from the S3 bucket.

2. **Attach the Role to an EC2 Instance**  
   - When the instance launches, it automatically **assumes** this role.

3. **Automatic Credential Retrieval**  
   - Inside the EC2 instance, your application (Python script, AWS CLI, etc.) can now access S3 **without storing access keys**.  
   - Behind the scenes, the instance retrieves **temporary credentials** through the **Instance Metadata Service (IMDS)** at:
     ```
     http://169.254.169.254/latest/meta-data/iam/security-credentials/
     ```

4. **Result:**  
   - The EC2 instance can safely download or upload to the S3 bucket.  
   - Credentials are **temporary**, **auto-rotated**, and **never hard-coded** inside your code.

> 🧠 This demonstrates the core purpose of IAM Roles — **secure, short-lived, and automatic access** between AWS services without manually handling keys.

---

### 🏁 Best Practices
1. **Never use root account** for daily tasks  
2. **Use groups** to manage permissions at scale  
3. **Regularly audit permissions** (remove unused access)  
4. **Enable MFA** for all users  
5. **Apply least privilege principle**

</details>

---

<details>
<summary><strong>2. IAM Hands-On (Console)</strong></summary>

---

### 🎯 Excerise:
Create an IAM user, add it to a group, attach policies, test access, and secure it with MFA.

---

### **Step 1: Open IAM Console**
1. Log in as the **root user** → [https://aws.amazon.com/console](https://aws.amazon.com/console)  
2. Search for **IAM** in the service bar.  
3. Observe the **IAM Dashboard** — it shows account summary, MFA status, and security recommendations.  

📸 Screenshot →   
<img src="images/IAM_Dashboard.png" />

---

### **Step 2: Create a New User**
1. In the left sidebar → click **Users → Add users**.  

📸 Screenshot →     
<img src="images/IAM_adduser.png" />   

2. Enter username: `devops-user`.  
3. Check **Provide user access to the AWS Management Console**.  
4. Choose **Custom password**, uncheck “Require password reset.”  
5. Click **Next**.  

📸 Screenshot →   
<img src="images/IAM_userdetials.png" />

---

### **Step 3: Create a Group and Assign Permissions**
1. Choose **Add user to group → Create group.**  

📸 Screenshot →     
<img src="images/IAM_creatgroup.png" />

2. Name the group: `DevOps-Admins`.  
3. From the policy list, select **AdministratorAccess.**  
   - This gives full permissions across AWS services — ideal for admin-level users.  
   - *(For learning environments, you can later replace this with a custom least-privilege policy.)*  
4. Click **Create group** → select it → click **Next** → **Create user.**

📸 Screenshot →     
<img src="images/IAM_groupcreation.png" />

5. After the user is created, you’ll see the **Retrieve password** screen.  
   It displays your **sign-in URL**, **username**, and **temporary password**.  

📸 Screenshot →  
<img src="images/IAM_Retrieve password.png" />

6. Click **“Download .csv file.”**  
   - This file contains your new user’s **username**, **password**, and **sign-in URL.**  
   - Save it somewhere **secure** (e.g., a private folder, not GitHub or shared drives).  
   - ⚠️ You will **not** be able to view this password again later.

7. *(Optional but Recommended)* — Click **“Email sign-in instructions.”**  
   - This opens an email template to send login details securely to yourself.

8. Click **“Return to users list.”**  
   - You’ll be redirected to the **IAM → Users** page.  
   - You’ll now see your new user **`Devops_Admin`** listed successfully.
---

### **Step 4: Log In as IAM User**
1. Copy the **Sign-in URL** displayed after user creation (looks like:  
   `https://<account-id>.signin.aws.amazon.com/console`).  
2. Log out from root and log in with:  
   - Username: `Devops_Admin`  
   - Password: your custom password  
3. You should now see the full AWS Console as an IAM Administrator.
  
📸 Screenshot →    
<img src="images/IAM_devopsadmin.png" />
---

### **Step 5: Test Permissions**

1. Open **EC2**, **S3**, **IAM**, and other services — your `Devops_Admin` user should have **full access** to all AWS services.  
2. To test least privilege, create another IAM user with restricted access:  
   - Go to **IAM → Users → Add users.**  
   - Enter username: `teja`  
   - Provide console access (same as before).  
   - Set a **custom password** (optional: uncheck “Require password reset”).  
   - Click **Next.**
3. Choose **Add user to group → Create group.**  
   - Name the group: `Developers`  
   - Attach the following **AWS Managed Policies:**  
     - `AmazonEC2ReadOnlyAccess`  
     - `AmazonS3ReadOnlyAccess`  
     - `IAMReadOnlyAccess`  
   - Click **Create group → Next → Create user.**

📸 Screenshot →   
<img src="images/group_dev.png">

4. Log in using the new user credentials for `teja`:  
   - **Sign-in URL:** `https://735189763643.signin.aws.amazon.com/console`  
   - **Username:** `teja`  
   - **Password:** (from your downloaded .csv file)
5. Test permissions:  
   - Open **EC2**, **S3**, and **IAM** — you should be able to **view** resources but **cannot create, edit, or delete** them.  
   - This confirms that your `Developers` group and Read-Only policies are working correctly.

📸 Screenshot →   
<img src="images/access_denied.png">

6. Switch back to your `Devops_Admin` user to regain full permissions.


✅ **Result:**  
You now have two properly configured IAM users —  
- **`Devops_Admin`** → Full administrative access  
- **`teja` (Developers group)** → Read-only access across EC2, S3, and IAM

---

### **Step 6: Enable MFA for Extra Security**
1. Back in IAM → select your `devops-admin` user.  
2. Go to **Security credentials → Assign MFA device.**  

📸 Screenshot →   
<img src="images/IAM_assign_MFA.png">

3. Choose **Virtual MFA** → scan the QR code using Google Authenticator or Authy.  
4. Enter two consecutive codes → **Assign MFA.**  

📸 Screenshot →   
<img src="images/DuoPush.png">
<img src="images/MFA_Code.png">

</details>

---
---
# TOOL: 08. AWS – Cloud Infrastructure | FILE: 03-vpc-subnet
---

[Home](../README.md) |
[Intro to AWS](../01-intro-aws/README.md) |
[IAM](../02-iam/README.md) |
[VPC & Subnet](../03-vpc-subnet/README.md) |
[EBS](../04-ebs/README.md) |
[EFS](../05-efs/README.md) |
[S3](../06-s3/README.md) |
[EC2](../07-ec2/README.md) |
[RDS](../08-rds/README.md) |
[Load Balancing & Auto Scaling](../09-Load-balancing-auto-scaling/README.md) |
[CloudWatch & SNS](../10-cloudwatch-sns/README.md) |
[Lambda](../11-lambda/README.md) |
[Elastic Beanstalk](../12-elastic-beanstalk/README.md) |
[Route 53](../13-route53/README.md) |
[CLI + CloudFormation](../14-cli-cloudformation/README.md)

# AWS VPC & Subnets

## What This File Is About

IAM decided **who** gets access. VPC decides **where** that access works — your private, isolated network inside AWS. This file covers how to design a VPC from scratch, plan subnets correctly, route traffic between tiers, and secure every layer with Security Groups and NACLs. By the end you will be able to design a production-ready multi-tier AWS network and understand exactly what happens at every hop inside it.

> **Foundation:** The networking concepts behind everything here — IP addressing, CIDR math, NAT, stateful vs stateless firewalls — are covered in depth in the [Networking Fundamentals](../../03.%20Networking%20–%20Foundations/README.md) folder. Specifically:
> - Subnets and CIDR: [05 — Subnets & CIDR](../../03.%20Networking%20–%20Foundations/05-subnets-cidr/README.md)
> - NAT concept: [07 — NAT & Translation](../../03.%20Networking%20–%20Foundations/07-nat/README.md)
> - Stateful vs Stateless firewalls: [09 — Firewalls & Security](../../03.%20Networking%20–%20Foundations/09-firewalls/README.md)

---

## Table of Contents

1. [Why VPC Exists](#1-why-vpc-exists)
2. [What Is a VPC](#2-what-is-a-vpc)
3. [CIDR and IP Address Ranges](#3-cidr-and-ip-address-ranges)
4. [Subnets and Availability Zones](#4-subnets-and-availability-zones)
5. [Routing, IGW and NAT Gateway](#5-routing-igw-and-nat-gateway)
6. [Security Groups vs NACLs](#6-security-groups-vs-nacls)
7. [The NACL Trap — The Most Common Beginner Mistake](#7-the-nacl-trap--the-most-common-beginner-mistake)
8. [IP Concepts — Private, Public, Elastic, ENI](#8-ip-concepts--private-public-elastic-eni)
9. [VPC Subnet Design — Webstore on AWS](#9-vpc-subnet-design--webstore-on-aws)
10. [Architecture Blueprint](#10-architecture-blueprint)

---

<details>
<summary><strong>1. Why VPC Exists</strong></summary>

Before the cloud, every company had a physical server room — racks, cables, routers, and switches all wired together manually. Expanding meant buying hardware, finding rack space, and rewiring everything.

AWS virtualizes that entire setup. Instead of physical cables and switches, you define your network in software. That virtual network is your **VPC**.

**The Building Analogy:**
Think of AWS as a massive city of skyscrapers — one per account. Your VPC is your private building inside that city. You control everything about it:

- Which floors face the street (public subnets)
- Which floors are internal only (private subnets)
- How the hallways connect floors (route tables)
- Who has keys to each room (security groups)
- Which entrance faces the street (internet gateway)

Without a VPC, every AWS resource would float in the open city with no walls or doors. VPC gives you **boundaries, privacy, and structure**.

```
AWS City (many accounts)
└── Your Account
    └── Your VPC = Your Private Building
        ├── Internet Gateway    = Main entrance to the street
        ├── Public Subnet       = Street-facing floors (web servers)
        ├── Private Subnet      = Internal floors (databases, app servers)
        ├── Route Tables        = Hallways connecting floors
        ├── Security Groups     = Door locks on individual rooms
        └── NACLs               = Security gates at each floor entrance
```

</details>

---

<details>
<summary><strong>2. What Is a VPC</strong></summary>

A **Virtual Private Cloud (VPC)** is an isolated network you own inside AWS. Every resource you launch — EC2, RDS, Lambda — lives inside a VPC.

**Key components:**

| Component | Purpose | Example |
|---|---|---|
| **VPC** | The network boundary | `10.0.0.0/16` |
| **Subnet** | Sub-division of the VPC | `10.0.1.0/24` |
| **Route Table** | Defines where traffic goes | Route to IGW or NAT |
| **Internet Gateway (IGW)** | Public internet access | Web tier in public subnet |
| **NAT Gateway** | Private → Internet (outbound only) | OS updates from private EC2 |
| **Security Group** | Instance-level stateful firewall | Allow HTTP, SSH |
| **NACL** | Subnet-level stateless firewall | Allow/Deny by CIDR and port |

**Default VPC vs Custom VPC:**

When you create an AWS account, AWS gives you a Default VPC in every region — pre-built with public subnets and an IGW. It works immediately but is not production-safe because everything lands in public subnets by default.

For any real workload you create a **Custom VPC** — every subnet, route, and firewall rule is intentionally designed.

```
┌────────────────────────── AWS Region ──────────────────────────────┐
│                                                                    │
│  ┌─────────────────────── VPC (10.0.0.0/16) ──────────────────┐   │
│  │                                                            │   │
│  │  Public Subnet (10.0.1.0/24)   Private Subnet (10.0.2.0/24)│   │
│  │  ┌──────────────────────┐      ┌──────────────────────┐    │   │
│  │  │  EC2 Web Server      │      │  RDS Database        │    │   │
│  │  │  Route → IGW         │      │  Route → NAT         │    │   │
│  │  └──────────────────────┘      └──────────────────────┘    │   │
│  │                                                            │   │
│  │  IGW ↔ Internet                NAT Gateway (in public)     │   │
│  └────────────────────────────────────────────────────────────┘   │
└────────────────────────────────────────────────────────────────────┘
```

</details>

---

<details>
<summary><strong>3. CIDR and IP Address Ranges</strong></summary>

Before you build subnets, you choose how much IP space your VPC owns. That range is defined using **CIDR notation**.

A CIDR block like `10.0.0.0/16` means:
- `10.0.0.0` is the starting address
- `/16` means the first 16 bits are the network portion — everything after is yours to assign

**The formula:**
```
Total IPs = 2^(32 - prefix)

10.0.0.0/16  →  2^16 = 65,536 IPs
10.0.1.0/24  →  2^8  =    256 IPs
10.0.3.0/28  →  2^4  =     16 IPs
```

**AWS reserves 5 IPs per subnet** (network address, VPC router, DNS, future use, broadcast). Always subtract 5 from your total.

**Quick reference table:**

| CIDR | Total IPs | Usable in AWS | Common use |
|---|---|---|---|
| **/16** | 65,536 | 65,531 | Entire VPC CIDR |
| **/20** | 4,096 | 4,091 | Large subnet |
| **/24** | 256 | 251 | Standard subnet (most common) |
| **/26** | 64 | 59 | Small subnet |
| **/28** | 16 | 11 | Minimum AWS size |

**The Rule:** AWS only allows VPC CIDRs between `/16` (largest) and `/28` (smallest). Anything outside that range is rejected.

**Private IP ranges** (memorize these — they cannot route on the internet):
```
10.0.0.0/8         → Large networks (standard for AWS VPCs)
172.16.0.0/12      → Medium networks
192.168.0.0/16     → Home/small office
```

Always use private ranges for VPC CIDRs. Public IP ranges in a VPC cause routing conflicts.

**Avoiding overlap:**
If you ever connect two VPCs (VPC Peering) or connect to an on-premises network, their CIDR ranges must not overlap. This is why planning matters upfront.

```
❌ Bad — overlap:
VPC A: 10.0.0.0/16  (10.0.0.0 - 10.0.255.255)
VPC B: 10.0.1.0/24  (10.0.1.0 - 10.0.1.255)  ← inside VPC A's range

✅ Good — no overlap:
VPC A: 10.0.0.0/16  (10.0.0.0 - 10.0.255.255)
VPC B: 10.1.0.0/16  (10.1.0.0 - 10.1.255.255)
```

</details>

---

<details>
<summary><strong>4. Subnets and Availability Zones</strong></summary>

A **subnet** is a slice of your VPC CIDR assigned to one Availability Zone. Every resource you launch lives in a specific subnet — and therefore in a specific AZ.

**Public vs Private:**

| Type | Has route to IGW? | Has public IP? | Use for |
|---|---|---|---|
| **Public subnet** | Yes | Yes | Web servers, load balancers, bastion hosts |
| **Private subnet** | No | No | Databases, app servers, internal services |

**The HA Rule:** For high availability, always create subnets across multiple AZs. If one AZ fails, your resources in other AZs keep running.

```
VPC: 10.0.0.0/16

AZ us-east-1a:
  Public subnet:   10.0.1.0/24
  Private subnet:  10.0.2.0/24

AZ us-east-1b:
  Public subnet:   10.0.11.0/24
  Private subnet:  10.0.12.0/24
```

**What makes a subnet public?**
A subnet becomes public when its route table has a route pointing `0.0.0.0/0` to an Internet Gateway. Without that route, even if an EC2 instance has a public IP, it cannot reach the internet — the route table is the gate, not the IP.

**What makes a subnet private?**
No route to IGW. Outbound internet access goes through a NAT Gateway instead. Inbound from the internet is impossible — by design.

**Subnet sizing guidance:**
```
Web tier (public):    /24 — room for load balancers, bastion hosts
App tier (private):   /24 — room for multiple app servers
DB tier (private):    /24 — consistent sizing keeps things simple
```

Always size larger than you think you need. You cannot resize a subnet after creation — you would have to create a new one.

</details>

---

<details>
<summary><strong>5. Routing, IGW and NAT Gateway</strong></summary>

Every subnet is associated with a **route table** — a set of rules that tell AWS where to send traffic based on destination IP.

**How routing decisions work:**
```
Packet destination: 8.8.8.8

Route table lookup (most specific match wins):
  10.0.0.0/16  →  local        (matches? No — 8.8.8.8 not in VPC range)
  0.0.0.0/0    →  igw-xxxxx    (matches everything else → send to IGW)

Decision: Forward to Internet Gateway
```

**Standard route tables:**

Public subnet route table:
```
Destination     Target
10.0.0.0/16     local         ← VPC-internal traffic stays inside
0.0.0.0/0       igw-xxxxx     ← everything else goes to internet
```

Private subnet route table:
```
Destination     Target
10.0.0.0/16     local         ← VPC-internal traffic stays inside
0.0.0.0/0       nat-xxxxx     ← outbound internet via NAT Gateway
```

---

### Internet Gateway (IGW)

An IGW connects your VPC to the internet. It handles both inbound and outbound traffic for public subnets.

| Property | Value |
|---|---|
| Scope | One per VPC |
| Direction | Bidirectional (inbound and outbound) |
| Cost | Free |
| Requirement | Must be attached to VPC and referenced in route table |

Without an IGW attached and routed, no instance in the VPC can reach the internet — regardless of what Security Group rules say.

---

### NAT Gateway

A NAT Gateway lets instances in **private subnets** make outbound internet connections (downloading packages, calling external APIs) while remaining completely unreachable from the internet inbound.

**How it works:**
```
Private EC2 (10.0.2.50) wants to reach apt.ubuntu.com

1. EC2 sends packet — source IP: 10.0.2.50
2. Route table: 0.0.0.0/0 → NAT Gateway
3. NAT Gateway translates:
     Old source: 10.0.2.50 (private)
     New source: 52.10.20.30 (NAT Gateway's Elastic IP)
4. Packet leaves via IGW to internet
5. Response returns to NAT Gateway
6. NAT translates back to 10.0.2.50
7. Private EC2 receives response

The internet only ever saw 52.10.20.30 — never the private IP
```

| Property | Value |
|---|---|
| Location | Must live in a public subnet |
| Direction | Outbound only — no inbound connections possible |
| Cost | Charged per hour + per GB processed |
| HA requirement | Create one NAT Gateway per AZ |
| Requires | An Elastic IP address |

**The HA pattern:**
```
AZ-a: Private subnet → NAT Gateway in Public subnet AZ-a
AZ-b: Private subnet → NAT Gateway in Public subnet AZ-b
```

One NAT Gateway per AZ. If you use a single NAT Gateway and that AZ goes down, all private instances in every AZ lose internet access.

**NAT Gateway vs NAT Instance:**

| Feature | NAT Gateway | NAT Instance (legacy) |
|---|---|---|
| Managed by | AWS | You |
| Availability | Highly available within AZ | You manage failover |
| Bandwidth | Up to 45 Gbps | Limited by instance type |
| Cost | Higher | Lower (EC2 cost only) |
| Recommendation | ✅ Always use this | Legacy — avoid |

</details>

---

<details>
<summary><strong>6. Security Groups vs NACLs</strong></summary>

AWS gives you two layers of network security. Understanding the difference between them is one of the most important concepts in AWS networking.

**The key difference in one line:**
Security Groups are stateful (remember connections). NACLs are stateless (evaluate every packet independently).

---

### Security Groups

A Security Group is a **stateful firewall** attached to an individual EC2 instance, RDS instance, or load balancer.

**Stateful means:** if an inbound rule allows a connection in, the return traffic is automatically allowed out — even with no outbound rule. The Security Group remembers the connection.

| Property | Value |
|---|---|
| Level | Instance (ENI) |
| Statefulness | Stateful — return traffic auto-allowed |
| Rule types | Allow only — cannot create Deny rules |
| Default inbound | Deny all |
| Default outbound | Allow all |
| Changes | Apply immediately |

**Webstore web server Security Group:**

| Direction | Protocol | Port | Source | Purpose |
|---|---|---|---|---|
| Inbound | TCP | 80 | 0.0.0.0/0 | HTTP from internet |
| Inbound | TCP | 443 | 0.0.0.0/0 | HTTPS from internet |
| Inbound | TCP | 22 | 203.0.113.0/24 | SSH from office only |
| Outbound | All | All | 0.0.0.0/0 | Allow all outbound |

**Referencing Security Groups:**
Instead of using IP ranges, you can reference another Security Group as the source. This is the production pattern for multi-tier apps:

```
Database Security Group inbound rule:
  Allow TCP 5432 from [App Server Security Group ID]

This means: only instances wearing the App Server SG badge
can reach the database — regardless of their IP address.
If you scale to 100 app servers, no rule change needed.
```

---

### Network ACLs (NACLs)

A NACL is a **stateless firewall** at the subnet boundary. Every packet — inbound and outbound — is evaluated independently against the rules. No memory of connections.

| Property | Value |
|---|---|
| Level | Subnet |
| Statefulness | Stateless — every packet evaluated independently |
| Rule types | Allow and Deny |
| Rule evaluation | Lowest rule number first — first match wins |
| Default | Allow all inbound and outbound |
| Changes | Apply immediately |

**Public subnet NACL (correct configuration):**

Inbound rules:
| Rule # | Protocol | Port | Source | Action |
|---|---|---|---|---|
| 100 | TCP | 80 | 0.0.0.0/0 | ALLOW |
| 110 | TCP | 443 | 0.0.0.0/0 | ALLOW |
| 120 | TCP | 1024-65535 | 0.0.0.0/0 | ALLOW ← critical |
| * | All | All | 0.0.0.0/0 | DENY |

Outbound rules:
| Rule # | Protocol | Port | Destination | Action |
|---|---|---|---|---|
| 100 | TCP | 80 | 0.0.0.0/0 | ALLOW |
| 110 | TCP | 443 | 0.0.0.0/0 | ALLOW |
| 120 | TCP | 1024-65535 | 0.0.0.0/0 | ALLOW ← critical |
| * | All | All | 0.0.0.0/0 | DENY |

---

### Side-by-Side Comparison

| Feature | Security Group | NACL |
|---|---|---|
| Level | Instance | Subnet |
| Stateful? | ✅ Yes | ❌ No |
| Allow rules | ✅ Yes | ✅ Yes |
| Deny rules | ❌ No | ✅ Yes |
| Default inbound | Deny all | Allow all |
| Rule evaluation | All rules checked | Lowest number first |
| Return traffic | Auto-allowed | Must be explicitly allowed |
| Best for | Primary security control | Subnet-level defense layer |

**The Recommendation:** Use Security Groups for all primary access control — they are stateful and easier to manage. Add NACLs only when you need explicit Deny rules or a subnet-level defense layer.

</details>

---

<details>
<summary><strong>7. The NACL Trap — The Most Common Beginner Mistake</strong></summary>

This single misconfiguration causes more AWS networking failures than anything else. Read this carefully.

**The Setup:**
You create a custom NACL to secure your public subnet. You add what looks like correct rules:

```
Inbound:
  100  TCP  80   0.0.0.0/0  ALLOW
  110  TCP  443  0.0.0.0/0  ALLOW
  *    All  All  0.0.0.0/0  DENY

Outbound:
  100  TCP  80   0.0.0.0/0  ALLOW
  110  TCP  443  0.0.0.0/0  ALLOW
  *    All  All  0.0.0.0/0  DENY
```

Looks complete. Allows HTTP and HTTPS both ways. But your website does not load.

**What actually happens:**

```
User (123.45.67.89:54321) → Your server (:80)

NACL Inbound check:
  Rule 100: TCP port 80 from anywhere → ALLOW ✅
  Packet enters subnet, reaches EC2

Server processes request

Server (:80) → User (123.45.67.89:54321)
  The response goes to port 54321 — the user's ephemeral port

NACL Outbound check:
  Rule 100: TCP port 80 → not a match (destination port is 54321)
  Rule 110: TCP port 443 → not a match
  Rule *: DENY ❌

Response is dropped. User sees timeout.
```

**Why this happens:**
When a user connects to your server on port 80, their browser picks a random **ephemeral port** (between 1024-65535) as the source port. The server's response goes back to that ephemeral port. Your NACL has no outbound rule allowing traffic to ports 1024-65535 — so the response is silently dropped.

Security Groups never have this problem because they are stateful — they remember the inbound connection and automatically allow the response.

**The Fix:**

```
Outbound rules (add this):
  120  TCP  1024-65535  0.0.0.0/0  ALLOW  ← allows all response traffic

Inbound rules (add this too for outbound-initiated responses):
  120  TCP  1024-65535  0.0.0.0/0  ALLOW  ← allows return traffic for outbound requests
```

**The Rule:** Every NACL that allows inbound traffic on a port must also allow outbound traffic on the ephemeral port range (1024-65535). And vice versa. Both directions. Always.

**Why this confuses people:**
Security Groups teach you to only think about inbound rules — return traffic is automatic. NACLs are the opposite. The mental model that works for Security Groups breaks completely when applied to NACLs.

**Best practice:**
Most teams leave NACLs at the default (allow all) and use Security Groups for all access control. Only add custom NACLs when you specifically need Deny rules — and when you do, always include the ephemeral port range in both directions.

</details>

---

<details>
<summary><strong>8. IP Concepts — Private, Public, Elastic, ENI</strong></summary>

Every EC2 instance in your VPC gets network addresses. Understanding which type does what prevents a lot of confusion.

---

### Private IP

Assigned automatically when an instance launches. Used for all communication within the VPC — EC2 to EC2, EC2 to RDS, EC2 to internal load balancers.

```
Properties:
  ✅ Free
  ✅ Stays the same when instance stops and starts
  ❌ Released permanently when instance is terminated
  ❌ Not reachable from the internet
  ❌ Cannot route on the public internet
```

---

### Public IP

Assigned automatically to instances in public subnets (if the subnet is configured to auto-assign). Allows direct communication with the internet via IGW.

```
Properties:
  ✅ Automatically assigned — no action needed
  ✅ Included in Free Tier (750 hrs/month)
  ❌ Changes every time the instance stops and starts
  ❌ Lost permanently when instance is terminated
```

This is the problem with Public IPs — they change. If your DNS record points to `3.120.55.23` and the instance restarts, it gets a new IP and your DNS breaks.

---

### Elastic IP

A static public IPv4 address that you allocate to your account. It stays the same forever until you release it.

```
Properties:
  ✅ Permanent — survives stop/start/restart
  ✅ Can be moved between instances (failover)
  ✅ Free while attached to a running instance
  ❌ Billed when allocated but not attached (idle charge)
```

**When to use Elastic IP:**
- Production servers that need a consistent public IP
- Failover setups where you move the IP from a failed instance to a healthy one
- When your DNS or firewall rules reference a specific IP

**The idle billing trap:** If you allocate an Elastic IP and then stop the instance or detach the IP, AWS charges you for it. Always release Elastic IPs you are not using.

---

### ENI (Elastic Network Interface)

A virtual network card. Every instance gets one primary ENI automatically. It holds the instance's private IP, public IP, MAC address, and Security Group associations.

You can create additional ENIs and attach them to instances — useful for network separation, management interfaces, or failover.

---

### Comparison

| Type | Persists on restart? | Internet reachable? | Cost |
|---|---|---|---|
| Private IP | ✅ Yes | ❌ No | Free |
| Public IP | ❌ Changes | ✅ Yes | Free (750 hrs/mo) |
| Elastic IP | ✅ Yes | ✅ Yes | Free if attached, billed if idle |
| ENI | N/A | Depends | Free |

</details>

---

<details>
<summary><strong>9. VPC Subnet Design — Webstore on AWS</strong></summary>

This is how you translate requirements into a real VPC design. Work through this before touching the console.

**Requirements:**
```
Application: webstore (frontend + api + database)
Region: us-east-1
Availability Zones: 2 (for high availability)
Tiers: web (public), api (private), database (private)
Expected growth: 3x current size
```

**Step 1 — Choose VPC CIDR**

Use `10.0.0.0/16` — 65,536 IPs. Plenty of room for all subnets across multiple AZs with room for future expansion.

**Step 2 — Calculate subnet sizes**

```
Web tier:      ~20 instances now, ~60 eventually → /24 (251 usable) ✅
API tier:      ~40 instances now, ~120 eventually → /24 (251 usable) ✅
Database tier: ~5 instances now, ~15 eventually   → /24 (251 usable) ✅

Consistent /24 sizing — simple to manage, no mental math needed
```

**Step 3 — Assign non-overlapping CIDRs**

```
VPC: 10.0.0.0/16

AZ us-east-1a:
  webstore-web-1a:  10.0.1.0/24   (public)
  webstore-api-1a:  10.0.2.0/24   (private)
  webstore-db-1a:   10.0.3.0/24   (private)

AZ us-east-1b:
  webstore-web-1b:  10.0.11.0/24  (public)
  webstore-api-1b:  10.0.12.0/24  (private)
  webstore-db-1b:   10.0.13.0/24  (private)

Reserved for future:
  10.0.20.0 - 10.0.255.0  (available)
```

**Step 4 — Define routing**

```
Public subnets (web-1a, web-1b):
  Route table: 0.0.0.0/0 → igw-xxxxx

Private subnets (api, db):
  Route table: 0.0.0.0/0 → nat-xxxxx
  (one NAT Gateway per AZ for HA)
```

**Step 5 — Define Security Groups**

```
webstore-alb-sg:
  Inbound:  443 from 0.0.0.0/0
  Inbound:  80 from 0.0.0.0/0
  Outbound: All

webstore-api-sg:
  Inbound:  8080 from webstore-alb-sg  ← reference SG, not IP
  Outbound: All

webstore-db-sg:
  Inbound:  27017 from webstore-api-sg  ← only api tier can reach db
  Outbound: All
```

**Step 6 — Verify no overlaps**

```
10.0.1.0/24   → 10.0.1.0  - 10.0.1.255
10.0.2.0/24   → 10.0.2.0  - 10.0.2.255
10.0.3.0/24   → 10.0.3.0  - 10.0.3.255
10.0.11.0/24  → 10.0.11.0 - 10.0.11.255
10.0.12.0/24  → 10.0.12.0 - 10.0.12.255
10.0.13.0/24  → 10.0.13.0 - 10.0.13.255

No overlaps ✅
```

**Terraform snippet:**

```hcl
resource "aws_vpc" "webstore" {
  cidr_block = "10.0.0.0/16"
  tags = { Name = "webstore-vpc" }
}

resource "aws_subnet" "web_1a" {
  vpc_id            = aws_vpc.webstore.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
  tags = { Name = "webstore-web-1a", Tier = "web" }
}

resource "aws_subnet" "api_1a" {
  vpc_id            = aws_vpc.webstore.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1a"
  tags = { Name = "webstore-api-1a", Tier = "api" }
}

resource "aws_subnet" "db_1a" {
  vpc_id            = aws_vpc.webstore.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1a"
  tags = { Name = "webstore-db-1a", Tier = "database" }
}
```

</details>

---

<details>
<summary><strong>10. Architecture Blueprint</strong></summary>

**Webstore production VPC — full picture:**

```
┌──────────────────────────────── AWS Region (us-east-1) ────────────────────────────────────┐
│                                                                                            │
│  ┌─────────────────────────────── VPC: 10.0.0.0/16 ──────────────────────────────────┐    │
│  │                                                                                    │    │
│  │  AZ: us-east-1a                          AZ: us-east-1b                           │    │
│  │                                                                                    │    │
│  │  ┌─── Public (10.0.1.0/24) ────┐        ┌─── Public (10.0.11.0/24) ───┐           │    │
│  │  │  ALB (webstore-alb-sg)      │        │  ALB (webstore-alb-sg)      │           │    │
│  │  │  NAT Gateway                │        │  NAT Gateway                │           │    │
│  │  │  Route: 0.0.0.0/0 → IGW     │        │  Route: 0.0.0.0/0 → IGW     │           │    │
│  │  └─────────────────────────────┘        └─────────────────────────────┘           │    │
│  │                                                                                    │    │
│  │  ┌─── Private (10.0.2.0/24) ───┐        ┌─── Private (10.0.12.0/24) ──┐           │    │
│  │  │  webstore-api EC2           │        │  webstore-api EC2            │           │    │
│  │  │  SG: allow 8080 from ALB SG │        │  SG: allow 8080 from ALB SG  │           │    │
│  │  │  Route: 0.0.0.0/0 → NAT     │        │  Route: 0.0.0.0/0 → NAT      │           │    │
│  │  └─────────────────────────────┘        └─────────────────────────────┘           │    │
│  │                                                                                    │    │
│  │  ┌─── Private (10.0.3.0/24) ───┐        ┌─── Private (10.0.13.0/24) ──┐           │    │
│  │  │  webstore-db (MongoDB)      │        │  webstore-db replica         │           │    │
│  │  │  SG: allow 27017 from       │        │  SG: allow 27017 from        │           │    │
│  │  │      api SG only            │        │      api SG only             │           │    │
│  │  │  No public IP               │        │  No public IP                │           │    │
│  │  └─────────────────────────────┘        └─────────────────────────────┘           │    │
│  │                                                                                    │    │
│  │  Internet Gateway                                                                  │    │
│  └────────────────────────────────────────────────────────────────────────────────────┘    │
│                                                                                            │
└────────────────────────────────────────────────────────────────────────────────────────────┘

Traffic flow:
  Internet → IGW → ALB (public subnet) → webstore-api (private) → webstore-db (private)
  Private EC2 → NAT Gateway → IGW → Internet (outbound only)
  webstore-db: zero inbound from internet — only reachable from api SG
```

**Security summary:**

| Layer | Tool | What it protects |
|---|---|---|
| VPC boundary | CIDR + IGW | Only traffic through IGW reaches the VPC |
| Subnet boundary | NACLs | Subnet-level allow/deny (leave at default unless specific need) |
| Instance boundary | Security Groups | Per-resource stateful firewall — primary security control |
| Database isolation | SG referencing | Only api tier SG can reach db — no IP-based rules needed |

</details>

---
# TOOL: 08. AWS – Cloud Infrastructure | FILE: 04-ebs
---

[Home](../README.md) | 
[Intro to AWS](../01-intro-aws/README.md) | 
[IAM](../02-iam/README.md) | 
[VPC & Subnet](../03-vpc-subnet/README.md) | 
[EBS](../04-ebs/README.md) | 
[EFS](../05-efs/README.md) | 
[S3](../06-s3/README.md) | 
[EC2](../07-ec2/README.md) | 
[RDS](../08-rds/README.md) | 
[Load Balancing & Auto Scaling](../09-Load-balancing-auto-scaling/README.md) | 
[CloudWatch & SNS](../10-cloudwatch-sns/README.md) | 
[Lambda](../11-lambda/README.md) | 
[Elastic Beanstalk](../12-elastic-beanstalk/README.md) | 
[Route 53](../13-route53/README.md) | 
[CLI + CloudFormation](../14-cli-cloudformation/README.md)

# Elastic Block Store (EBS)

Our network is now set — roads, gates, and rules are ready.
But a server can’t run without storage to hold its data.
That’s where EBS (Elastic Block Store) comes in.
Think of it as attaching an SSD to your EC2 instance — local, fast, and always there when you restart the machine.

## Table of Contents
1. [What Is EBS?](#1-what-is-ebs)
2. [How EBS Works with EC2](#2-how-ebs-works-with-ec2)
3. [EBS Volume Types](#3-ebs-volume-types)
4. [Snapshots & Backup Mechanism](#4-snapshots--backup-mechanism)
5. [Cross-AZ and Cross-Region Copy](#5-cross-az-and-cross-region-copy)
6. [EBS Encryption](#6-ebs-encryption)
7. [Modifying Volumes (Resize, Migrate, Tune)](#7-modifying-volumes-resize-migrate-tune)
8. [Performance Essentials (IOPS & Throughput)](#8-performance-essentials-iops--throughput)
9. [Best Practices & Cost Optimization](#9-best-practices--cost-optimization)
10. [Quick Summary](#10-quick-summary)

---

<details>
<summary><strong>1. What Is EBS?</strong></summary>

**Elastic Block Store (EBS)** is a **persistent block storage** service designed for Amazon EC2 instances.  
Each EBS volume behaves like a **virtual hard drive** — you can format it, mount it, detach it, and re-attach it to other EC2 instances within the same Availability Zone (AZ).

Even if you stop or restart your instance, **the data remains intact**, making EBS a reliable storage layer for OS files, applications, and databases.

💡 **Analogy (minimal use):**  
Think of EBS as a **detachable SSD** for your EC2 instance — you can unplug it, carry it to another machine in the same data center (AZ), and plug it back in without losing your data.

**Key properties:**
- **Persistent**: Data survives instance stop/start.
- **Block-level**: You manage it like a raw disk.
- **Flexible**: You can increase size, change performance, or migrate without downtime.
- **AZ-scoped**: Must be in the same Availability Zone as the instance.

📸 **Reference:** [Amazon EBS Volumes](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebs-volumes.html)
</details>

---

<details>
<summary><strong>2. How EBS Works with EC2</strong></summary>

EBS volumes attach to EC2 instances over the **availability zone network**.  
When you launch an EC2 instance, it can have:
- **Root Volume:** Stores OS and boot files.
- **Additional Data Volumes:** For app data, logs, or databases.

**High-level flow:**

```

EBS Volume  <──attached──>  EC2 Instance
│
└── Snapshots stored in S3 (for backup & cloning)

```

- EBS is **replicated automatically within its AZ** to prevent data loss.
- You can attach **multiple EBS volumes** to one EC2, or attach a single EBS volume to multiple EC2s (only for io1/io2 Multi-Attach use cases).

💡 **Use Case Examples:**
- Root volume for Linux/Windows OS.
- Application data storage for web servers.
- Database storage (MySQL, PostgreSQL).
- Persistent log storage or caching layer.

<summary><strong>2.1  Special Case – EBS Multi-Attach (io1 / io2 Volumes)</strong></summary>

Normally, a single EBS volume can be **attached to only one EC2 instance at a time**.  
That keeps data consistent, just like plugging a physical SSD into one machine.

However, the **Provisioned IOPS SSD (io1 and io2)** volume types introduce a feature called **Multi-Attach**.  
It lets you connect the same volume to **up to 16 EC2 instances** *simultaneously* within the **same Availability Zone**.

💡 **Why this exists:**  
Some enterprise or clustered applications (for example, Oracle RAC or shared file systems) need multiple servers to read and write to the same shared disk.  
Multi-Attach gives them a common block-level layer while keeping latency extremely low.

⚙️ **How it behaves**
- Every attached EC2 gets a unique device name (e.g., `/dev/sdf`, `/dev/sdg` …).  
- All instances see the **same data blocks** in real time.  
- There’s **no built-in locking** — your application must manage concurrent writes safely (through a clustered file system or DB engine).  
- If ordinary servers try to write at the same time without coordination, data corruption can occur.

🧭 **Architect’s Note:**  
Use Multi-Attach only when your workload is explicitly designed for shared block access.  
For general cases, treat EBS as a **one-to-one disk** between an instance and its volume — simpler, faster, safer.

</details>

---

<details>
<summary><strong>3. EBS Volume Types</strong></summary>

| Volume Type | Medium | Description | Best For |
|--------------|---------|--------------|-----------|
| **gp3** | SSD | General-purpose SSD with configurable IOPS (up to 16,000) and throughput (up to 1,000 MB/s). | Most workloads – OS, applications, boot volumes |
| **io2/io1** | SSD | Provisioned IOPS SSD with consistent latency and Multi-Attach support. | High-performance databases |
| **st1** | HDD | Throughput-optimized HDD for large sequential workloads. | Big data, logs, streaming workloads |
| **sc1** | HDD | Cold HDD with lowest cost and lowest performance. | Archival and infrequently accessed data |

💡 **Tip:**  
Use **gp3** by default unless you have a clear reason to optimize for either IOPS (io2/io1) or cost (st1/sc1).

📘 **Durability:**  
EBS volumes provide **99.999% availability** within an AZ due to internal replication.
</details>

---

<details>
<summary><strong>4. Snapshots & Backup Mechanism</strong></summary>

A **snapshot** is a **point-in-time backup** of an EBS volume stored in Amazon S3.  
Although stored in S3, snapshots are managed transparently by EBS.

```

EBS Volume → Snapshot → New Volume

```

- **First snapshot** = full copy  
- **Subsequent snapshots** = incremental (only changed blocks)
- Snapshots can be **used to create new volumes**, **copied across regions**, or **automated via Lifecycle Manager**.

💡 **Analogy:**  
It’s like taking a **photo of your disk’s current state**.  
If anything breaks later, you can rebuild an exact copy using that snapshot.

📸 **Reference:** [EBS Snapshots](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/EBSSnapshots.html)
</details>

---

<details>
<summary><strong>5. Cross-AZ and Cross-Region Copy</strong></summary>

You can use snapshots to **clone volumes** across Availability Zones or Regions.

### Cross-AZ (within same region)
1. Create a snapshot of the source volume (e.g., `us-east-1a`).
2. Use that snapshot to create a new volume in another AZ (e.g., `us-east-1b`).
3. Attach it to an EC2 instance there.

### Cross-Region
1. Copy the snapshot to another region.
2. Create a volume from that copy.
3. Attach to EC2 in the destination region.

💡 **Analogy:**  
It’s like **replicating your disk** to a different branch office — same setup, new location.

📸 **Reference:** [Copy Snapshots](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebs-copy-snapshot.html)
</details>

---

<details>
<summary><strong>6. EBS Encryption</strong></summary>

EBS provides **encryption at rest and in transit** using **AWS KMS** (Key Management Service).  
You can use **AWS-managed keys (aws/ebs)** or **customer-managed CMKs**.

**Key points:**
- Encrypted data stays encrypted during I/O operations.
- Snapshots of encrypted volumes are also encrypted.
- New volumes created from encrypted snapshots remain encrypted.
- Enable **EBS encryption by default** in your account for consistency.

📘 **Command:**
```bash
aws ec2 enable-ebs-encryption-by-default
````

📸 **Reference:** [EBS Encryption](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/EBSEncryption.html)

</details>

---

<details>
<summary><strong>7. Modifying Volumes (Resize, Migrate, Tune)</strong></summary>

You can dynamically **resize** or **change** EBS volume attributes without detaching it.

**Options you can modify:**

* Size (GB)
* IOPS
* Throughput (for gp3)

**After resizing:**

* Extend partition and filesystem inside the OS (`growpart`, `xfs_growfs`).

**Migration approach:**

* Create snapshot → New volume (different type or region) → Attach → Sync data.

📘 **Example command:**

```bash
aws ec2 modify-volume --volume-id vol-1234567890abcdef --size 200 --iops 8000 --throughput 600
```

📸 **Reference:** [Modify EBS Volumes](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebs-modify-volume.html)

</details>

---

<details>
<summary><strong>8. Performance Essentials (IOPS & Throughput)</strong></summary>

**IOPS (Input/Output Operations Per Second)** → speed for small random reads/writes.
**Throughput (MB/s)** → speed for large sequential data transfers.

| Metric     | gp3 (max)  | io2 (max)             | st1/sc1              |
| ---------- | ---------- | --------------------- | -------------------- |
| IOPS       | 16,000     | 256,000 (provisioned) | Low                  |
| Throughput | 1,000 MB/s | 4,000 MB/s            | High sequential only |
| Latency    | ~5 ms      | <1 ms                 | High (HDD latency)   |

💡 **Tip:**
Monitor performance using **CloudWatch metrics** like `VolumeReadOps`, `VolumeWriteOps`, `VolumeThroughputPercentage`, etc.

</details>

---

<details>
<summary><strong>9. Best Practices & Cost Optimization</strong></summary>

✅ Use **gp3** for most workloads (better performance per $).
✅ Set **volume and snapshot tags** for cost tracking.
✅ Enable **EBS Lifecycle Manager** to automatically delete old snapshots.
✅ For large-scale systems, **align IOPS with EC2 bandwidth** to avoid bottlenecks.
✅ Use **RAID 0** (striping) for high I/O and **RAID 1** (mirroring) for durability if needed.
✅ Always **unmount before detaching** volumes to avoid data corruption.

</details>

---

<details>
<summary><strong>10. Quick Summary</strong></summary>

| Task                      | Command                                                                                                    | Description                        |
| ------------------------- | ---------------------------------------------------------------------------------------------------------- | ---------------------------------- |
| Create new gp3 volume     | `aws ec2 create-volume --size 50 --availability-zone us-east-1a --volume-type gp3`                         | Creates 50 GB volume               |
| Attach volume             | `aws ec2 attach-volume --volume-id <id> --instance-id <id> --device /dev/xvdf`                             | Mounts volume to instance          |
| Create snapshot           | `aws ec2 create-snapshot --volume-id <id> --description "backup"`                                          | Point-in-time backup               |
| Copy snapshot             | `aws ec2 copy-snapshot --source-region us-east-1 --source-snapshot-id <id> --destination-region us-west-2` | Cross-region copy                  |
| Modify volume             | `aws ec2 modify-volume --volume-id <id> --size 200`                                                        | Resize volume                      |
| List volumes              | `aws ec2 describe-volumes`                                                                                 | View all attached/detached volumes |
| Enable encryption default | `aws ec2 enable-ebs-encryption-by-default`                                                                 | Enforces KMS encryption            |

**Linux Filesystem Resize Example:**

```bash
lsblk                                # list block devices
sudo growpart /dev/xvdf 1            # extend partition
sudo xfs_growfs /                    # expand filesystem
```

**Output:**

```output
data blocks changed from 26214400 to 52428800
Filesystem successfully expanded
```

</details>
---
# TOOL: 08. AWS – Cloud Infrastructure | FILE: 05-efs
---

[Home](../README.md) | 
[Intro to AWS](../01-intro-aws/README.md) | 
[IAM](../02-iam/README.md) | 
[VPC & Subnet](../03-vpc-subnet/README.md) | 
[EBS](../04-ebs/README.md) | 
[EFS](../05-efs/README.md) | 
[S3](../06-s3/README.md) | 
[EC2](../07-ec2/README.md) | 
[RDS](../08-rds/README.md) | 
[Load Balancing & Auto Scaling](../09-Load-balancing-auto-scaling/README.md) | 
[CloudWatch & SNS](../10-cloudwatch-sns/README.md) | 
[Lambda](../11-lambda/README.md) | 
[Elastic Beanstalk](../12-elastic-beanstalk/README.md) | 
[Route 53](../13-route53/README.md) | 
[CLI + CloudFormation](../14-cli-cloudformation/README.md)

# Day 10 – Elastic File System (EFS)

## Table of Contents

1. [Why We Need EFS](#1-why-we-need-efs)
2. [What Is Amazon EFS](#2-what-is-amazon-efs)
3. [EBS vs EFS vs S3 Comparison](#3-ebs-vs-efs-vs-s3-comparison)
4. [Simplified Real-World Scenarios](#4-simplified-real-world-scenarios)
5. [How EFS Works Internally](#5-how-efs-works-internally)
6. [Lab Task – Mounting EFS on EC2](#6-lab-task--mounting-efs-on-ec2)
7. [Architecture Diagrams](#7-architecture-diagrams)
8. [Performance & Throughput Modes](#8-performance--throughput-modes)
9. [Pricing & Best Practices](#10-pricing--best-practices)

---

<details>
<summary><strong>1. Why We Need EFS</strong></summary>

When you start with one EC2, its **EBS volume** (local SSD) works fine.
But once you add more servers—**EC2-A**, **EC2-B**, **EC2-C**—each has its own EBS disk.
Uploads on one server never appear on the others, creating inconsistent data.

You can’t attach one EBS to many EC2s, and syncing files manually is painful.
What you really need is a **shared drive** that all EC2s can mount and see the same files instantly.
That’s what **Amazon EFS** provides.

---

### 💡 Quick Analogy

| Storage | Real-World Equivalent  | Use                        |
| ------- | ---------------------- | -------------------------- |
| **EBS** | Laptop SSD             | Private, local, fast       |
| **EFS** | Office network drive   | Shared, live, auto-scaling |
| **S3**  | Google Drive / Dropbox | Cloud archive and delivery |

EFS is that shared folder in the office everyone opens together.

---

### What EFS Fixes

| Need                  | Why EBS Fails            | How EFS Solves It           |
| --------------------- | ------------------------ | --------------------------- |
| Multi-instance access | EBS = 1 EC2 only         | EFS mountable by many EC2s  |
| Elastic capacity      | EBS size is fixed        | EFS auto-grows/shrinks      |
| High availability     | EBS in 1 AZ              | EFS replicates across AZs   |
| POSIX file system     | S3 = objects, no folders | EFS = real Linux filesystem |

---

### Visual Flow

```
Without EFS:
EC2-A → EBS-A   ❌ Files not visible to EC2-B
EC2-B → EBS-B   ❌ Different copies everywhere

With EFS:
EC2-A, EC2-B, EC2-C  →  mount /efsdir →  Amazon EFS
✓ All see and edit the same files in real time
```

---

### ✅ When to Use EFS

* Web apps on multiple EC2s (WordPress, Drupal)
* Shared datasets or ML pipelines
* Developer workspaces and user home dirs
* Any situation needing simultaneous read/write access

### ❌ Not for

* Databases → use **EBS**
* Backups or global media hosting → use **S3**

</details>

---

<details>
<summary><strong>2. What Is Amazon EFS</strong></summary>

**Amazon EFS (Elastic File System)** is a fully managed, shared file system that your EC2 instances can mount and use together.
It behaves like a normal Linux directory but the files actually live in AWS’s storage layer, not inside any one EC2.

**Key Points**

* **Elastic:** Storage automatically expands or shrinks with your data.
* **Shared:** Many EC2s can mount the same path at once.
* **POSIX-compliant:** Standard Linux permissions, folders, and file locks work normally.
* **Highly Available:** Data is replicated across multiple AZs for durability.
* **Fully Managed:** No disks or capacity planning—AWS handles scaling and health.

```
EC2-A, EC2-B, EC2-C  ──►  /efsdir  ──►  Amazon EFS (Shared Storage)
```

💡 **Think of it:** one central folder in the cloud that all your servers can open at the same time.

</details>

---

<details>
<summary><strong>3. EBS vs EFS vs S3 – Storage Comparison</strong></summary>

AWS gives three main storage options, each solving a different need.

| Feature         | **EBS**                | **EFS**                    | **S3**                   |
| --------------- | ---------------------- | -------------------------- | ------------------------ |
| **Type**        | Block Storage          | File Storage               | Object Storage           |
| **Access**      | One EC2 at a time      | Many EC2s at once          | Via HTTP/API             |
| **Scalability** | Fixed size (manual)    | Auto-scales (elastic)      | Infinite                 |
| **Speed**       | Very fast (local disk) | Network fast               | Slower (API calls)       |
| **Use Case**    | OS disk, DB storage    | Shared app files / uploads | Backups, media, archives |
| **Scope**       | Single AZ              | Multi-AZ (Regional)        | Regional/Global          |
| **Analogy**     | Laptop SSD             | Office shared drive        | Google Drive / Dropbox   |

💡 **In short:**

* **EBS** → local, private, single-server speed.
* **EFS** → shared, elastic workspace for multiple servers.
* **S3** → global storage for large, static, or archived data.

</details>

---

<details>
<summary><strong>4. Simplified Real-World Scenarios</strong></summary>

| Example                    | Storage Type | Real-World Analogy             | Key Idea                 |
| -------------------------- | ------------ | ------------------------------ | ------------------------ |
| **Personal Laptop**        | EBS          | Your own SSD – only you use it | Local, fast, private     |
| **Office Shared Folder**   | EFS          | Team drive on company network  | Shared live access       |
| **Google Drive / Dropbox** | S3           | Cloud backup for everything    | Accessible from anywhere |

🎬 **Movie Studio Analogy**

| Task                      | Best AWS Storage | Why                               |
| ------------------------- | ---------------- | --------------------------------- |
| Editing raw footage       | EBS              | Local speed needed                |
| Sharing project files     | EFS              | Multiple editors collaborate live |
| Archiving finished movies | S3               | Cheap & limitless storage         |
| Streaming worldwide       | S3 + CloudFront  | Global delivery                   |

</details>

---

<details>
<summary><strong>5. How EFS Works Internally</strong></summary>

EFS isn’t a physical disk; it’s a **network file system** managed by AWS.
Your EC2s connect to it over **NFS (Network File System)** — just like mapping a shared drive in an office network.

### Step-by-Step Flow

1️⃣ **Create EFS File System** → AWS sets up an elastic backend across multiple AZs.
2️⃣ **Mount Targets in Subnets** → Each AZ gets an endpoint that EC2s use to connect.
3️⃣ **Mount from EC2** → You make a folder (`/efsdir`) and mount the EFS through NFS:

```bash
sudo mount -t efs -o tls <EFS_ID>:/ efsdir
```

4️⃣ **Shared Access** → Any EC2 mounting that same path sees identical files instantly.
5️⃣ **Elastic Scaling & Durability** → EFS automatically grows, shrinks, and replicates data across AZs.

---

### Visual Snapshot

```
┌──────────────────────── AWS Region ─────────────────────────┐
│                                                             │
│  EC2-A (AZ-A)  ─┐                                           │
│                 │   NFS Mount (tcp 2049)                    │
│  EC2-B (AZ-B)  ─┼──►  Amazon EFS File System                │
│  EC2-C (AZ-C)  ─┘      • Multi-AZ replication               │
│                       • Auto-scale storage                  │
│                       • Shared POSIX filesystem             │
└─────────────────────────────────────────────────────────────┘
```

💡 **In short:**
Your EC2s keep their own EBS disks for local speed but share one EFS folder for collaboration — all while AWS handles the scaling, replication, and reliability behind the scenes.  
📘 EFS is separate from EBS.  
Mounting EFS simply adds **another drive** to your machine (shared via network).
</details>

---

<details>
<summary><strong>6. Lab Task – Mounting EFS on EC2</strong></summary>

**Goal:** Share the same storage between two EC2 instances.
###  **EFS Mount Lab (Quick Commands)**

```bash
# 1️⃣ Launch two EC2 instances in the same VPC (different subnets for HA)

# 2️⃣ Create an EFS file system in the AWS Console
#    → Add mount targets in both subnets

# 3️⃣ Connect to the first EC2
ssh -i mykey.pem ec2-user@<EC2-PUBLIC-IP>

# 4️⃣ Install the EFS client
sudo yum install -y amazon-efs-utils

# 5️⃣ Create a directory to mount EFS
mkdir /efsdir

# 6️⃣ Mount the EFS file system
sudo mount -t efs -o tls <EFS-ID>:/ /efsdir

# 7️⃣ Test shared access
echo "Hello from EC2-A" > /efsdir/test.txt
```

### ✅ **On EC2-B**

```bash
sudo yum install -y amazon-efs-utils
mkdir /efsdir
sudo mount -t efs -o tls <EFS-ID>:/ /efsdir
cat /efsdir/test.txt
```

If you see

```
Hello from EC2-A
```

EFS is successfully shared between both EC2 instances.

✅ If both instances see the same file, EFS is working.
```
EC2-A (AZ-A) ─┐
               ├──►  Amazon EFS (File System)
EC2-B (AZ-B) ─┘
     ↳ Both read / write to /efsdir (same files, live sync)
```
</details>

---

<details>
<summary><strong>7. Architecture Diagrams</strong></summary>

### A) Mount Flow (what your EC2 actually sees)

```
EC2 Instance
├─ /           → EBS (OS, app, local files)
└─ /efsdir     → EFS (shared network filesystem via NFS)
                 ↑
                 └─ mount -t efs <EFS-ID>:/ /efsdir
```

---

### B) Multi-AZ EFS with Mount Targets (HA)

```
┌───────────────────── AWS Region ───────────────────┐
│  VPC                                               │
│                                                    │
│  AZ-A                         AZ-B                 │
│  ┌───────────────┐           ┌───────────────┐     │
│  │  EC2-A        │           │  EC2-B        │     │
│  │  (has EBS)    │           │  (has EBS)    │     │
│  │ mount /efsdir ├──┐     ┌──┤ mount /efsdir │     │
│  └───────────────┘  │     │  └───────────────┘     │
│                     ▼     ▼                        │
│          ┌─────────────┴─────────────┐             │
│          │  Amazon EFS (Regional)    │             │
│          │  • Multi-AZ replication   │             │
│          │  • Elastic capacity       │             │
│          └─────────────┬─────────────┘             │
│                  ▲     │     ▲                     │
│     Mount Target (AZ-A)│  Mount Target (AZ-B)      │
│        (one per subnet) (TCP 2049/NFS)             │
│                                                    │
│ Security Group tip:                                │
│ allow NFS (TCP 2049) EC2 ↔ EFS (both directions)   │
└────────────────────────────────────────────────────┘
```

---

### C) EFS in the App Tier (behind an ALB, optional context)

```
Internet
   │
[ ALB ]  ← (optional) balances traffic to web/app EC2s
   │
   ├── EC2-Web-1 (EBS) ┐
   ├── EC2-Web-2 (EBS) ┼── mount /efsdir → Amazon EFS (shared content)
   └── EC2-Web-3 (EBS) ┘
```

---

### Final All-in-One (EBS + EFS + S3)

```
                ┌───────────────────────────┐
                │         Amazon S3         │
                │  (Backups / Hosting / CDN)│
                └─────────────┬─────────────┘
                              │  (HTTP/API)
┌────────────────────────────────────────────────────────────────┐
│                            AWS VPC                             │
│                                                                │
│   ┌───────────────┐        NFS (TCP 2049)       ┌────────────┐ │
│   │  EC2-A        │ ──────────────────────────► │            │ │
│   │  (EBS: OS/app)│                             │            │ │
│   │  /efsdir ─────┼───────────────────────────► │  Amazon    │ │
│   └───────────────┘                             │    EFS     │ │
│                                                 │ (Regional  │ │
│   ┌───────────────┐                             │  shared FS)│ │
│   │  EC2-B        │ ──────────────────────────► │            │ │
│   │  (EBS: OS/app)│                             │            │ │
│   │  /efsdir      │                             └────────────┘ │
│   └───────────────┘                                            │     
│                                                                │
│  Flow:                                                         │
│   • EBS = local per-instance disk (fast, private)              │
│   • EFS = shared live files across EC2s                        │
│   • S3  = publish/archive/fan delivery (global)                │
└────────────────────────────────────────────────────────────────┘
```

</details>

---

<details>
<summary><strong>8. Performance & Throughput Modes</strong></summary>

| Category        | Mode            | Description                      | Use Case                   |
| --------------- | --------------- | -------------------------------- | -------------------------- |
| **Performance** | General Purpose | Low latency (default)            | Web apps, CMS, dev/test    |
|                 | Max IO          | High throughput (bigger latency) | Big data, media processing |
| **Throughput**  | Bursting        | Scales with usage                | Variable workloads         |
|                 | Provisioned     | Fixed MB/s                       | Predictable heavy loads    |

</details>

---

<details>
<summary><strong>9. Pricing & Best Practices</strong></summary>

💰 **Pricing**

* Pay per GB of data stored per month.
* Lifecycle policy to move cold data to **EFS Infrequent Access (IA)**.
* No charge for data transfer within same Region.

✅ **Best Practices**

* Allow TCP 2049 (NFS) in Security Groups.
* Enable encryption at rest and in transit.
* Create mount targets in each AZ for HA.
* Monitor EFS metrics via CloudWatch.
* Use lifecycle policies for cost optimization.

---

### 🏁 Final Summary

| **Concept** | **Acts Like** | **Main Use** |
|--------------|---------------|--------------|
| **EBS** | Laptop SSD (internal storage) | Fast, local storage for a single EC2 |
| **EFS** | Office network drive (shared external storage) | Shared, elastic multi-EC2 storage |
| **S3** | Google Drive / Dropbox | Global, limitless object storage for backups and hosting |

💡 **In one line:**  
> **EBS** is *personal and local*, **EFS** is *shared and elastic*, and **S3** is *global and endless*.

</details>
---
---
# TOOL: 08. AWS – Cloud Infrastructure | FILE: 06-s3
---

[Home](../README.md) | 
[Intro to AWS](../01-intro-aws/README.md) | 
[IAM](../02-iam/README.md) | 
[VPC & Subnet](../03-vpc-subnet/README.md) | 
[EBS](../04-ebs/README.md) | 
[EFS](../05-efs/README.md) | 
[S3](../06-s3/README.md) | 
[EC2](../07-ec2/README.md) | 
[RDS](../08-rds/README.md) | 
[Load Balancing & Auto Scaling](../09-Load-balancing-auto-scaling/README.md) | 
[CloudWatch & SNS](../10-cloudwatch-sns/README.md) | 
[Lambda](../11-lambda/README.md) | 
[Elastic Beanstalk](../12-elastic-beanstalk/README.md) | 
[Route 53](../13-route53/README.md) | 
[CLI + CloudFormation](../14-cli-cloudformation/README.md)

# AWS S3 (Simple Storage Service)

EBS works great inside one zone, but sometimes data needs to travel — backups, media, global access.
That’s where S3 (Simple Storage Service) takes over.
Instead of local disks, it’s like a giant warehouse in the cloud — infinite shelves where any app can drop a file and pick it from anywhere on the planet.

---

## Table of Contents
1. [Why Do We Need S3?](#1-why-do-we-need-s3)
2. [Analogy – The Infinite Warehouse](#2-analogy--the-infinite-warehouse)
3. [Core Concept – Buckets and Objects](#3-core-concept--buckets-and-objects)
4. [Bucket Naming Rules](#4-bucket-naming-rules)
5. [Static Website Hosting](#5-static-website-hosting)
6. [Versioning](#6-versioning)
7. [Storage Classes with Scenarios](#7-storage-classes-with-scenarios)
8. [Security & Access Control](#8-security--access-control)
9. [Lifecycle Management](#9-lifecycle-management)
10. [Encryption & Consistency](#10-encryption--consistency)
11. [Real Example – Webstore Media Flow](#11-real-example--webstore-media-flow)
12. [AWS CLI Examples](#12-aws-cli-examples)
13. [Quick Command Summary](#13-quick-command-summary)

---

<details>
<summary><strong>1. Why Do We Need S3?</strong></summary>

EBS volumes are reliable but tied to one instance in one zone.  
They’re perfect for operating systems or databases — not for global sharing.  

When applications grow, you need a place where:
- Any service can store or fetch data, anytime.
- Capacity expands automatically.
- Costs depend on how much you store.

That’s **Amazon S3** — an object-storage service that acts like a limitless data vault.  
You can store photos, backups, code, logs, or even full websites — pay only for what you use.

</details>

---

<details>
<summary><strong>2. Analogy – The Infinite Warehouse</strong></summary>

Think of S3 as an **endless warehouse** in the cloud.  
Each **bucket** is a storage room with its own label.  
Every file you drop inside becomes an **object**, tagged with a unique barcode (its URL).

You can walk in, store or retrieve any object from anywhere in the world.  
Unlike an EBS disk, this warehouse has no walls, no cables — just infinite shelves that never fill up.

</details>

---

<details>
<summary><strong>3. Core Concept – Buckets and Objects</strong></summary>

- You create **buckets** to organize data. Each bucket name must be globally unique.  
- Inside a bucket, every uploaded **object** is stored with:
  - **Key** → the file name / path  
  - **Value** → file data  
  - **Metadata** → object info  
  - **Version ID** (if versioning is on)

S3 automatically replicates data across devices in the same region for durability (11 nines).

Example URL:
```

[https://my-bucket.s3.amazonaws.com/image.png](https://my-bucket.s3.amazonaws.com/image.png)

```

💡 *Architect’s Note:*  
S3 is a **global service**, but buckets are **region-specific**.  
Pick regions closer to your users to reduce latency.

</details>

---

<details>
<summary><strong>4. Bucket Naming Rules</strong></summary>

| Rule | Description |
|------|--------------|
| Length | 3 – 63 characters |
| Characters | a-z, 0-9, period (.), hyphen (-) |
| Must start/end with | Letter or number |
| Global uniqueness | No two buckets share the same name |
| Forbidden | Uppercase, underscores, or spaces |

💡 Tip: For websites, match your bucket name to your domain (e.g., `webstore-media.com`).

</details>

---

<details>
<summary><strong>5. Static Website Hosting</strong></summary>

S3 can host **static websites** — sites made of HTML, CSS, and JS files that look identical for all users.

**Steps:**
1. Create a bucket (often named after your domain).  
2. Upload your website files (`index.html`, `error.html`).  
3. Enable **Static Website Hosting** under *Properties*.  
4. Provide the index and error documents.  
5. Make objects publicly readable.  
6. Access your site via the generated endpoint URL.

Example endpoint:  
`http://webstore-website.s3-website-us-east-1.amazonaws.com`

📘 *Modern tip:* For production, use **AWS Amplify** or **CloudFront** for performance and HTTPS.

</details>

---

<details>
<summary><strong>6. Versioning</strong></summary>

Think of versioning as an **undo button** for your bucket.  
When enabled, every new upload of the same object keeps the previous version rather than replacing it.

**Default:** Disabled (new file overwrites the old one).  
**Enabled:** S3 preserves all versions.  
**Suspended:** Keeps existing versions but stops new ones.

**Why it matters in DevOps:**  
- Recover from accidental deletes or overwrites.  
- Track configuration file history or deployment artifacts.  
- Combine with Lifecycle policies to expire old versions automatically.

</details>

---

<details>
<summary><strong>7. Storage Classes with Scenarios</strong></summary>

Different data deserves different storage costs.  
Here’s how each S3 storage class fits a real-world use case:

| Storage Class | When to Use | Real Scenario |
|----------------|-------------|---------------|
| **Standard** | Frequently accessed data | Website images, app assets, or user uploads accessed every day. |
| **Intelligent-Tiering** | Unknown or changing access patterns | Logs and reports whose popularity changes — S3 auto-moves them between hot/cold tiers. |
| **Standard-IA (Infrequent Access)** | Accessed once or twice a month | Monthly analytics exports, historical sales reports. |
| **One Zone-IA** | Rarely used and easily reproducible | Cached data or thumbnails that can be recreated anytime. |
| **Glacier Instant Retrieval** | Archives needed quarterly with instant access | Marketing footage or past project files that must be instantly restored. |
| **Glacier Flexible Retrieval** | Long-term archives, retrieved occasionally | Tax filings or compliance documents you access once a year. |
| **Glacier Deep Archive** | Long-term retention, rarely accessed | 7-year legal backups or raw sensor data for audit purposes. |
| **Reduced Redundancy** | Legacy option (not recommended) | Old, non-critical assets; replaced by Standard class today. |

🧭 *Architect’s rule:* Match **frequency of access** with **cost of storage** —  
frequent = Standard; rare = Glacier.

<summary><strong>7.1  Pricing and Bucket Design Strategy</strong></summary>

### 💰 How S3 Billing Actually Works
S3 pricing depends on **what you store and how you use it**, not on how many buckets you create.

| Charged For | Example |
|--------------|----------|
| **Storage (GB per month)** | Total size of all objects in all buckets |
| **Requests** | PUT / GET / COPY / DELETE calls made to S3 |
| **Data Transfer Out** | Data leaving S3 to the Internet or another AWS Region |
| **Optional Features** | Replication, Inventory, Analytics, Object Lock, etc. |

➡️ You **do not** pay for:  
- Number of buckets  
- Number of folders  
- How many EC2 instances access them  

If you store **1 TB** of data—whether it lives in one bucket or ten—the cost is identical.

---

### 🧩 Multiple Buckets vs One Big Bucket

| Approach | Pros | Notes |
|-----------|------|-------|
| **Single bucket with folders** | Simpler to manage, one policy to maintain | Harder to apply different lifecycle or security rules |
| **Separate buckets per data type** | Clear boundaries for policy and lifecycle; easy cost breakdown | Slightly more management overhead, but no extra charges |

💬 **Example:**  
- `webstore-media` → movies & shows (Standard → IA)  
- `webstore-logs`   → app logs (Intelligent-Tiering → Glacier)  
- `webstore-backups` → database exports (Deep Archive)

All together they cost the same as one huge bucket—only the **usage** matters.

---

### ⚙️ EC2 and S3 Interaction Costs
S3 isn’t “attached” like EBS; EC2 accesses it via the S3 API (HTTPS).

| Scenario | Cost |
|-----------|------|
| EC2 ↔ S3 in same region | Free for inbound and most outbound traffic |
| EC2 ↔ S3 cross-region | Inter-region data transfer fees apply |
| EC2 ↔ S3 via Internet (no VPC endpoint) | Charged as Internet egress per GB |

---

### 🧭 Architect’s Guideline
- Use **multiple buckets** if you need different security or retention rules.  
- Use **one bucket with folders** for simpler projects.  
- Always keep S3 and EC2 in the same region to avoid transfer charges.  
- Tag buckets to track cost by project or environment.

**Summary:**  
> S3 billing cares about bytes, requests, and transfers — not bucket count.  
> Design buckets for clarity, not for cost.

</details>

---

<details>
<summary><strong>8. Security & Access Control</strong></summary>

S3 security is multi-layered:

1. **IAM Policies** → Who can access S3 resources.  
2. **Bucket Policies** → What specific actions are allowed or denied at bucket level.  
3. **ACLs** → Object-level access (legacy, rarely used).  
4. **Block Public Access** → Global safeguard against accidental exposure.  
5. **Encryption** → Protects data both at rest (AES-256 / KMS) and in transit (HTTPS).

💡 Always use **IAM roles** for EC2 or Lambda to grant temporary, secure access instead of embedding keys.

</details>

---

<details>
<summary><strong>9. Lifecycle Management</strong></summary>

As data ages, its value often drops.  
**Lifecycle rules** let you automate storage transitions and deletions.

Example policy ideas:
- Move logs to **Glacier** after 30 days.  
- Delete old object versions after 90 days.  
- Permanently remove expired data after 1 year.

This keeps S3 lean, cost-efficient, and self-maintaining.

</details>

---

<details>
<summary><strong>10. Encryption & Consistency</strong></summary>

- **At Rest:** S3 encrypts objects with AES-256 (SSE-S3) or AWS KMS (SSE-KMS).  
- **In Transit:** Uses HTTPS/TLS for secure uploads and downloads.  
- **Data Consistency:** Offers strong read-after-write consistency for all PUT and DELETE operations.

These features make S3 safe for both personal data and enterprise-grade workloads.

</details>

---

<details>
<summary><strong>11. Real Example – Webstore Media Flow</strong></summary>

In the **webstore app**, every movie file sits inside an S3 bucket — secure, versioned, and globally accessible.  
When a user presses “Play,” the app fetches metadata (title, rating, genre) from **RDS**,  
then streams the video directly from **S3** through a pre-signed URL.  

This separation keeps:
- **RDS** focused on lightweight queries,  
- **S3** handling heavy media storage,  
- **EC2** running business logic.

That’s the trio powering most modern streaming platforms.

</details>

---

<details>
<summary><strong>12. AWS CLI Examples</strong></summary>

```bash
# Upload a file
aws s3 cp song.mp3 s3://webstore-media/audio/song.mp3

# Download a file
aws s3 cp s3://webstore-media/audio/song.mp3 ./downloads/

# Sync local folder to bucket
aws s3 sync ./media s3://webstore-media/

# Remove an object
aws s3 rm s3://webstore-media/old-promo.mp4
````

</details>

---

<details>
<summary><strong>13. Quick Command Summary</strong></summary>

| Command                           | Description                |
| --------------------------------- | -------------------------- |
| `aws s3 mb s3://bucket`           | Make a new bucket          |
| `aws s3 ls`                       | List buckets               |
| `aws s3 cp file s3://bucket`      | Upload object              |
| `aws s3 rm s3://bucket/file`      | Delete object              |
| `aws s3 sync local/ s3://bucket/` | Sync folders               |
| `aws s3 rb s3://bucket --force`   | Remove bucket and contents |

</details>

---

**In short:**
S3 is not just “cloud storage” — it’s the backbone of the Internet’s data layer.
While EC2 runs your applications, **S3 remembers everything** — safely, infinitely, and affordably.
---
# TOOL: 08. AWS – Cloud Infrastructure | FILE: 07-ec2
---

[Home](../README.md) | 
[Intro to AWS](../01-intro-aws/README.md) | 
[IAM](../02-iam/README.md) | 
[VPC & Subnet](../03-vpc-subnet/README.md) | 
[EBS](../04-ebs/README.md) | 
[EFS](../05-efs/README.md) | 
[S3](../06-s3/README.md) | 
[EC2](../07-ec2/README.md) | 
[RDS](../08-rds/README.md) | 
[Load Balancing & Auto Scaling](../09-Load-balancing-auto-scaling/README.md) | 
[CloudWatch & SNS](../10-cloudwatch-sns/README.md) | 
[Lambda](../11-lambda/README.md) | 
[Elastic Beanstalk](../12-elastic-beanstalk/README.md) | 
[Route 53](../13-route53/README.md) | 
[CLI + CloudFormation](../14-cli-cloudformation/README.md)

# AWS EC2 – Elastic Compute Cloud

We now understand storage — both local (EBS) and global (S3).
But storage by itself doesn’t process anything.
We need the engine that runs our code and powers our apps.
That engine is EC2 (Elastic Compute Cloud) — the virtual machine that ties IAM, VPC, and storage into one working system.

## Table of Contents

1. [EC2 Overview & Purpose](#1-ec2-overview--purpose)  
2. [Billing & Pricing Models](#2-billing--pricing-models)  
3. [AMI & Instance Types](#3-ami--instance-types)  
4. [EC2 Lifecycle & States](#4-ec2-lifecycle--states)  
5. [Key Pairs & Security Groups](#5-key-pairs--security-groups)  
6. [Understanding VPC & Subnets](#6-understanding-vpc--subnets)  
7. [IP Concepts (Private, Public, Elastic, ENI)](#7-ip-concepts-private-public-elastic-eni)  
8. [Storage (EBS, Snapshots, FSR, Archive, Cross-AZ/Region Patterns)](#8-storage-ebs-snapshots-fsr-archive-cross-azregion-patterns)  
9. [Web Hosting (httpd) & User Data](#9-web-hosting-httpd--user-data)  
10. [Instance Metadata & Identity (IMDSv2, Signed Docs, Role Creds)](#10-instance-metadata--identity-imdsv2-signed-docs-role-creds)  
11. [Networking Foundations](#11-networking-foundations)  
12. [Load Balancer (with Health Checks)](#12-load-balancer-with-health-checks)  
13. [Auto Scaling & Monitoring](#13-auto-scaling--monitoring)

---

<details>
<summary><strong>1. EC2 Overview & Purpose</strong></summary>

### What is EC2?

EC2 stands for **Elastic Compute Cloud**, AWS’s service for creating virtual machines in the cloud.
“Elastic” means you can increase or decrease compute capacity on demand — like stretching or shrinking a rubber band depending on workload.   
It allows you to rent compute capacity from AWS instead of owning physical servers.  
You decide how much **CPU**, **memory**, and **storage** you need — and can scale up or down anytime.

**Use Cases:**
- Hosting websites and APIs  
- Running databases or backend servers  
- Testing and development environments  
- Machine learning workloads  

**Analogy:**  
Think of AWS as a massive data center. EC2 lets you rent one computer inside it — and you can turn it on, off, or resize it anytime.

📸 **Image:** [AWS EC2 Concepts](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/concepts.html)

</details>

---

<details>
<summary><strong>2. Billing & Pricing Models</strong></summary>

### EC2 Billing Basics

You pay for the **time your instance is running**:
- **Linux:** billed **per second** (minimum 60 seconds)  
- **Windows:** billed **per hour**

**Example:**  
Run a Linux instance for 2 minutes 15 seconds → billed for **135 seconds**.  
Windows instances → billed for the full **hour** even if used for 5 minutes.

---

### Free Tier

AWS Free Tier gives:
- **750 hours/month for 12 months**  
- Enough to run one small instance continuously  

**Instance types:**  
- `t2.micro` (older, available in Asia regions)  
- `t3.micro` (newer, available in US/EU regions)  

---

### Pricing Models

| Model | Description | When to Use |
|-------|--------------|-------------|
| **On-Demand** | Pay by second/hour. No commitment. | Testing, short workloads |
| **Reserved Instances (RI)** | 1–3 year commitment for up to 72% discount. | Long-running production workloads |
| **Spot Instances** | Use spare AWS capacity, up to 90% cheaper. | Fault-tolerant workloads |
| **Savings Plans** | Commit to $/hour usage, flexible across services. | Predictable workloads |
| **Dedicated Hosts** | Physical server reserved just for you. | Compliance or licensing needs |

> 💡 **Note:**  
> - **Linux instances** are billed **per-second** (minimum 60 s).  
> - **Windows instances** are billed **per hour**.  
> - **Public IPv4 addresses** are now **billable** outside the Free Tier.  
>   The Free Tier covers **750 hours / month** of one public IPv4; additional or idle ones incur charges.  
> - **Elastic IP (EIP)** addresses are **free while attached** to a running instance, but **billed when idle** (allocated but unused).

📸 **Image:** [AWS EC2 Pricing](https://aws.amazon.com/ec2/pricing/)

</details>

---

<details>
<summary><strong>3. AMI & Instance Types</strong></summary>

### Amazon Machine Image (AMI)

An AMI is a **template** used to launch EC2 instances.  
It includes:
- Operating System (Linux, Windows, Ubuntu, etc.)
- Preinstalled software (optional)
- Configurations and permissions  

**Examples:**
- Ubuntu Server AMI → ready-to-use Linux machine  
- Windows Server AMI → preconfigured Windows environment  

---

### Instance Types

| Family | Optimized For | Example | Use Case |
|---------|----------------|----------|-----------|
| **General Purpose** | Balanced CPU/RAM | `t3.micro` | Web servers |
| **Compute Optimized** | High CPU | `c5.large` | Batch processing |
| **Memory Optimized** | High RAM | `r5.large` | Databases |
| **Storage Optimized** | High I/O | `i3.large` | Data warehousing |
| **Accelerated (GPU)** | Graphics / ML | `p3.2xlarge` | AI/ML workloads |

**Analogy:**  
Each instance type is like a car built for a purpose — a sports car for speed, a truck for heavy loads, etc.

📸 **Image:** [AWS Instance Types](https://aws.amazon.com/ec2/instance-types/)

</details>

---

<details>
<summary><strong>4. EC2 Lifecycle & States</strong></summary>

### Lifecycle Stages

| State | Description |
|--------|--------------|
| **Pending** | Preparing resources and booting |
| **Running** | Fully operational and billable |
| **Stopping** | OS shutting down gracefully |
| **Stopped** | Not running, storage billed but compute stops |
| **Terminated** | Deleted permanently |

**Analogy:**  
Think of EC2 like a laptop:  
- Booting → Pending  
- Working → Running  
- Sleep → Stopped  
- Factory reset → Terminated  

📸 **Image:**  
<img src="images/EC2_instance_lifecycle.png" alt="EC2 Lifecycle" width="550"/>

</details>

---

<details>
<summary><strong>5. Key Pairs & Security Groups</strong></summary>

### Key Pair Authentication

When you create an EC2 instance, AWS uses **public-key cryptography** to ensure secure access — just like how every home has its own unique lock and key.

**Analogy:**  
If your **EC2 instance is your home**:
- The **public key** is the **lock** installed on the home’s door (AWS automatically adds it to your instance).  
- The **private key file** (`.pem` or `.ppk`) that **you download** is the **key** that fits that lock.  

You need this private key every time you want to enter (connect via SSH or RDP).  
If the key doesn’t match the lock → you can’t get inside.

---

#### Example: Connecting to EC2 (Linux/macOS)

```bash
# Step 1: Secure your private key
chmod 400 mykey.pem

# Step 2: Connect to your EC2 instance using SSH
ssh -i mykey.pem ec2-user@<Public-IP>
````

If the **private key** matches the **public key lock** on the instance:
✅ Access granted — you’ve entered your EC2 “home.”

If not:
❌ Permission denied — wrong or missing key.

📸 **Image:** [AWS EC2 Key Pairs](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html)

---

### Security Groups (SG)

A Security Group acts as a **virtual firewall**.

* **Inbound rules** → what traffic can enter
* **Outbound rules** → what traffic can exit
* **Stateful** → return traffic automatically allowed

| Protocol | Port | Use Case           |
| -------- | ---- | ------------------ |
| SSH      | 22   | Remote login       |
| HTTP     | 80   | Web traffic        |
| HTTPS    | 443  | Secure web traffic |

📸 **Image:** [VPC Security Groups](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_SecurityGroups.html)

</details>

---

<details>
<summary><strong>6. Understanding VPC & Subnets</strong></summary>

---

## 🌍 AWS as a Planet – The Big Picture

Before learning about IPs, it’s important to understand **where** everything in AWS lives.

Think of **AWS** as a **digital planet** made up of continents (Regions) and cities (Availability Zones).  
On this planet, every user can carve out their own **private island**, completely isolated from others — that island is your **VPC (Virtual Private Cloud)**.

---

### 🏝️ 1. What is a VPC?

A **VPC (Virtual Private Cloud)** is your **own private island** on the AWS planet.  
It’s a completely secure and customizable environment where you host your AWS resources such as EC2 instances, databases, and load balancers.

Inside this island, you control:
- **Borders:** IP address range (e.g., `10.0.0.0/16`)  
- **Security:** Who can enter or leave (Security Groups, NACLs, Route Tables)  
- **Connectivity:** Whether to open your island to the ocean (Internet) or stay isolated  

**Analogy:**  
> Think of a VPC as your **private country or island** in the AWS world.  
> You make the rules, build the infrastructure, and decide who can visit or communicate.

---

### 🧱 2. What is a Subnet?

A **Subnet** is a smaller **district or region** inside your private island (VPC).  
You divide your island into multiple subnets to separate workloads based on their accessibility.

Each subnet exists within one **Availability Zone (AZ)** — meaning if you have 3 AZs in your AWS Region, your island can have 3 major districts (subnets) across them.

| Subnet Type | Analogy | Connectivity | Common Use |
|--------------|----------|--------------|-------------|
| **Public Subnet** | Coastal city with open ports | Connected to the **Internet Gateway (IGW)** | Web servers, Bastion hosts |
| **Private Subnet** | Inland city with guarded roads | No direct internet connection (internal only) | Databases, Application servers |

---

### 🧩 3. How They Work Together

1. The **VPC** provides your island (the overall network boundary).  
2. You divide it into **Subnets** — each district serving a purpose (public or private).  
3. You connect a **Public Subnet** to the **Internet Gateway** — allowing outside traffic to visit.  
4. You keep **Private Subnets** isolated — only accessible through internal connections.

---

### 💡 Planet Analogy Summary

| AWS Concept | Real-World Analogy | Description |
|--------------|--------------------|--------------|
| **AWS Cloud** | The entire planet | Global infrastructure shared by all AWS users |
| **Region** | Continent | Large geographic area (e.g., North America, Asia) |
| **Availability Zone (AZ)** | City on a continent | Data center cluster within a region |
| **VPC** | Private island or country | Your own isolated network on the AWS planet |
| **Subnet** | District or region on your island | Divides your island into zones for specific use |
| **Public Subnet** | Coastal city with ports | Internet-facing zone for public services |
| **Private Subnet** | Inland city or lab | Internal-only zone for secure data storage |

---

### 🖼️ Visual Diagram

```
                🌍 AWS Planet
                       │
          ┌────────────┴────────────┐
          │                         │
  (Other Users’ Islands)     🏝️ Your VPC (Private Island)
                                     │
          ┌──────────────────────────┴──────────────────────────┐
          │                                                     │
 🌊 Public Subnet (Coastal City)                     🏞️ Private Subnet (Inland City)
  - Connected to Internet Gateway                    - No direct internet access
  - Hosts Web Servers                                - Hosts Databases & Internal Apps
  - Has Public & Private IPs                         - Has only Private IPs
```

---

### 🧠 One-Line Takeaway

> **AWS is the Planet 🌍**  
> **VPC is your Private Island 🏝️**  
> **Subnets are the Districts or Zones on that Island 🧱**  
> **Public Subnets face the sea (Internet Gateway), while Private Subnets stay inland (internal communication).**

📸 **Reference:**  
[AWS VPC Overview – Official Documentation](https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html)

---

</details>

---

<details>
<summary><strong>7. IP Concepts (Private, Public, Elastic, ENI)</strong></summary>

## 🌐 IP Concepts – Addresses on Your Island

Every EC2 instance inside your **VPC (Private Island)** needs a way to communicate — both **within the island** and **with the outside world**.  
That’s where **IP addresses** come in.  

Each EC2 instance can have:
- **Private IP** → used within your island (local communication)
- **Public IP** → used to connect with the outside ocean (internet)
- **Elastic IP** → a permanent public address (reserved port)
- **ENI (Elastic Network Interface)** → the network card that holds these addresses

---

### 🧩 1. Private IP – The House Address Inside the Island

Whenever you build a house (launch an EC2 instance) on your island, AWS automatically assigns it a **Private IP address**.  

This address is used for **internal communication** —  
for example, your bakery (web server) talking to your storage warehouse (database) — all within your fenced island.  

A Private IP **stays the same** even if you restart the house’s power (stop/start the instance),  
but it is **released permanently** if you demolish the house (terminate the instance).  

Private IPs are **free of cost** and **not visible from the ocean (internet)** — they work only within your island’s local boundaries.

📘 **Example**
```

Instance A → Private IP: 10.0.0.5
Instance B → Private IP: 10.0.0.8

```

Both houses can exchange letters (data) freely because they live inside the same fenced island (VPC).

💡 **Analogy:**  
A **Private IP** is your **house address inside the island** — neighbors can visit you,  
but no ship sailing on the ocean can see or reach you.

📸 **Image:** [Private IP Addressing in EC2](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-ip-addressing.html)

---

### 🌊 2. Public IP – The Dock Facing the Ocean

When you build something on your island that the world should reach — like a tourist information center or a shop — you place it on the **coastline** (Public Subnet).  
AWS then assigns it a **Public IP address** connected to an **Internet Gateway (IGW)**.

This Public IP allows visitors (users on the internet) to find and access your service.

However, this dock address is **temporary (dynamic)** —  
if you close the port and reopen it (stop/start your instance), the city assigns a **new dock number** next time.  
If you shut down the port completely (terminate the instance), the old number is gone forever.

Public IPs are billed under AWS’s **Public IPv4** pricing, but the **Free Tier** covers 750 hours per month.

📘 **Example**
```

Private IP: 10.0.0.12
Public IP: 3.120.55.23

````

Connect using SSH:
```bash
ssh -i mykey.pem ec2-user@3.120.55.23
````

After restarting, AWS might give you a new address, like `13.210.40.50`.

💡 **Analogy:**
A **Public IP** is your **temporary dock number** — ships (internet users) can reach you through it,
but if you rebuild or move your dock, the number changes.

📸 **Image:** [Public IPv4 Addressing in EC2](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-ip-addressing.html)

---

### ⚓ 3. Elastic IP – The Permanent Trade Port

Sometimes, you don’t want your dock number (Public IP) to change — especially if you run a permanent business on your island, like a trading company (production server).
That’s where an **Elastic IP (EIP)** comes in.

An Elastic IP is a **static (permanent) public IPv4 address** that you reserve manually.
It stays the same even if your instance stops, restarts, or moves.
You can **detach it** from one instance and **reassign it** to another anytime.

Elastic IPs are **free while attached**, but **billed if idle** (when allocated but unused).

📘 **Example**

```
Elastic IP: 18.220.45.90
Associated Instance: EC2-Web-Server
```

Even after restart:

```
Elastic IP: 18.220.45.90 ✅ (Permanent)
```

💡 **Analogy:**
An **Elastic IP** is your **island’s registered trade port** —
a permanent harbor number used for global trade.
Even if you rebuild your warehouse or relocate offices, ships (clients) always find you through the same port number.

📸 **Image:** [Elastic IP in EC2](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-ip-addressing.html)

---

### 🛰️ 4. ENI (Elastic Network Interface) – The Island’s Communication Hub

An **ENI** is like the **communication control center** of each building on your island.
It’s a **virtual network card** that stores your Private IP, Public IP (if any), and connection rules (Security Groups).

You can **attach or detach** ENIs between instances, like swapping communication panels between buildings.
They’re essential for fault-tolerant or multi-network designs.

💡 **Analogy:**
An **ENI** is the **telecom hub** in your building —
it manages all your phone lines, radios, and ports, connecting you to other buildings or even other islands.

📸 **Image:** [Elastic Network Interface (ENI)](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-eni.html)

---

### 🧭 Comparison Summary

| IP Type        | Role on the Island      | Persistence         | Cost                             | Analogy                           |
| -------------- | ----------------------- | ------------------- | -------------------------------- | --------------------------------- |
| **Private IP** | Internal communication  | Persists on restart | Free                             | House address inside the island   |
| **Public IP**  | Internet-facing access  | Changes on restart  | Free (within 750 hrs/mo)         | Temporary dock number             |
| **Elastic IP** | Permanent global access | Fixed and reusable  | Free if attached; billed if idle | Registered trade port             |
| **ENI**        | Network connector       | N/A                 | Free                             | Communication hub in the building |

---

### 🖼️ Visual Diagram

```
🌍 AWS Planet
│
└── 🏝️ Your VPC (Private Island)
     │
     ├── 🌊 Public Subnet (Coastal City)
     │     ├── EC2 Instance with Public IP (Dock Access)
     │     └── EC2 Instance with Elastic IP (Permanent Port)
     │
     └── 🏞️ Private Subnet (Inland City)
           ├── EC2 Instance with Private IP (Internal Roads)
           └── ENI (Communication Hub connecting everything)
```


                    ┌────────────────────────────┐
                    │       Internet User        │
                    │ (e.g., You on a Laptop)    │
                    └──────────────┬─────────────┘
                                   │
                     Uses Public IP or Elastic IP
                                   │
                      (Example: 3.120.55.23 or 18.220.45.90)
                                   │
                     ┌─────────────▼──────────────┐
                     │   Internet Gateway (IGW)   │
                     │  Bridges Internet <-> VPC  │
                     └─────────────┬──────────────┘
                                   │
                           Public Subnet
                                   │
                  ┌────────────────┴────────────────┐
                  │                                 │
          ┌───────▼───────┐                 ┌───────▼───────┐
          │  EC2 Instance │                 │  EC2 Instance │
          │   Web Server  │                 │   Database    │
          │               │                 │               │
          │ Public IP: 3.120.55.23          │ No Public IP  │
          │ Elastic IP: 18.220.45.90 (opt)  │ Private Only  │
          │ Private IP: 10.0.0.12           │ Private IP: 10.0.0.8 │
          └──────────────────────────────────────────────────────┘
                                   │
                      Communicate privately via VPC
                                   │
                         (10.0.0.12 ↔ 10.0.0.8)

📸 **Reference:**
[AWS EC2 Networking – IP Addressing](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-ip-addressing.html)

</details>

---

<details>
<summary><strong>8. Storage (EBS, Snapshots, Cross-AZ/Region Copy)</strong></summary>

---

## Elastic Block Store (EBS)

EBS is the **hard disk** of your EC2 instance.  
Even if you stop or restart the machine, the data stays safe — that’s what makes it **persistent**.

Each EBS volume acts like one **virtual drive** attached to your instance.  
You can remove it, re-attach it, or copy it to another zone.

| Type        | Description        | Best For |
|-------------|--------------------|----------|
| **gp3**     | Balanced SSD       | General workloads |
| **io2/io1** | High IOPS SSD      | Databases, latency-sensitive apps |
| **st1**     | Throughput HDD     | Big sequential data like logs, analytics |
| **sc1**     | Cold HDD           | Rarely accessed, archive data |

💡 **Analogy:**  
Think of EBS as a **warehouse of shelves** on your island.  
Each shelf (volume) holds your goods (data).  
You can move shelves between shops (instances) — but only inside the **same district (Availability Zone)**.

📸 **Reference:** [Amazon EBS Volumes](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebs-volumes.html)

---

## Snapshots

A **snapshot** is a photograph of your shelf at a certain moment.  
AWS stores it in S3 internally, so you can rebuild the same shelf whenever needed.

```
EBS Volume → Snapshot → New Volume
```

- First snapshot = full copy  
- Next ones = only changed blocks (incremental)  
- You can restore, copy, or automate them with **Lifecycle Manager**

💡 **Analogy:**  
Take a **photo of your warehouse shelf** today.  
If something breaks tomorrow, you can rebuild an identical shelf using that photo.

📸 **Reference:** [EBS Snapshots](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/EBSSnapshots.html)

---

## Cross-AZ or Cross-Region Copy

**Within same Region (Cross-AZ):**

1. Take a snapshot of volume in `us-east-1a`  
2. Create a new volume from it in `us-east-1b`  
3. Attach it to an instance there  

**Between Regions:**

1. Copy snapshot to another region  
2. Create volume from that copy  
3. Attach it to an instance in that region  

💡 **Analogy:**  
You take the photo of your shelf, fly it to another **city (AZ)** or even another **continent (Region)**,  
and rebuild the same shelf there.

📸 **Reference:** [Copy Snapshots](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebs-copy-snapshot.html)

</details>

---

<details>
<summary><strong>9. Web Hosting (httpd) & User Data</strong></summary>

---

## Hosting a Simple Website on EC2

You can turn your EC2 into a small web server using **Apache HTTPD**.

**Step 1 – Install Apache**

```bash
sudo yum install -y httpd
````

**Step 2 – Start the service**

```bash
sudo systemctl start httpd
sudo systemctl enable httpd
```

**Step 3 – Allow Traffic**

In your Security Group, open:

* **HTTP (80)**
* **HTTPS (443)**

**Step 4 – Create a Web Page**

```bash
cd /var/www/html
sudo bash -c 'echo "<h1>Webstore DevOps Learning</h1>" > index.html'
```

Now visit `http://<Public-IP>` in your browser.

💡 **Analogy:**
Your EC2 is a **café**, and Apache is the **waiter** serving pages to visitors who walk in through the **front door (port 80/443)**.

📸 **Reference:** [Install LAMP on EC2](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/install-LAMP.html)

---

## User Data – Automation on First Boot

**User Data scripts** run only once when a new instance starts.
They’re used for quick setup — installing software or creating files automatically.

```bash
#!/bin/bash
yum install -y httpd
echo "<h1>Webstore App – 1</h1>" > /var/www/html/index.html
systemctl enable httpd
systemctl start httpd
```

💡 **Analogy:**
This is like your **“opening-day checklist”** pinned to the café door —
each new branch runs it automatically before serving customers.

📸 **Reference:** [EC2 User Data](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html)

</details>

---

<details>
<summary><strong>10. Instance Metadata & Identity Document</strong></summary>

---

## Instance Metadata – Facts About Your Instance

This is a local HTTP endpoint inside every EC2 that gives information about itself.
It’s only reachable **from within** the instance.

```bash
curl http://169.254.169.254/latest/meta-data/
```

Examples:

* `public-ipv4`
* `instance-id`
* `security-groups`
* `ami-id`

💡 **Analogy:**
Inside your house, there’s a **cabinet with blueprints** — it shows everything about the house,
but no outsider can open it.

---

## IMDSv2 (Security Upgrade)

Newer version of metadata service uses **session tokens** for safety.
AWS recommends **enforcing IMDSv2 only**.

```bash
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

curl -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/
```

---

## Instance Identity Document

Signed JSON document that proves which instance you are.

```bash
curl http://169.254.169.254/latest/dynamic/instance-identity/document
```

Shows:

* Region
* Instance ID
* AMI ID
* Account ID

💡 **Analogy:**
It’s your **government-issued house deed** — official proof of who you are on the island.

📸 **Reference:** [Instance Metadata Docs](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instancedata-data-retrieval.html)

</details>

---

<details>
<summary><strong>11. Networking Foundations</strong></summary>

Networking concepts — DNS, TCP/UDP, the 3-way handshake, OSI layers, stateful vs stateless firewalls — are covered in full in the Networking notes before this series.

→ [Networking Fundamentals](../../03.%20Networking%20–%20Foundations/README.md)

Key concepts used in EC2:
- Security Groups = stateful firewall → [Firewalls & Security](../../03.%20Networking%20–%20Foundations/09-firewalls/README.md)
- Subnets and CIDR → [Subnets & CIDR](../../03.%20Networking%20–%20Foundations/05-subnets-cidr/README.md)
- NAT Gateway → [NAT & Translation](../../03.%20Networking%20–%20Foundations/07-nat/README.md)
- DNS and Route 53 → [DNS](../../03.%20Networking%20–%20Foundations/08-dns/README.md)

</details>

---

<details>
<summary><strong>12. Load Balancer (with Health Checks)</strong></summary>

---

## Why do we need a Load Balancer?

One server works until traffic grows. Then it slows, crashes, or becomes a single point of failure.  
A **Load Balancer (LB)** sits in front and **spreads requests** across many servers.

**Analogy:** A traffic police officer at a busy junction, sending cars into free lanes so no lane jams.

---

## How it works (simple view)

1. Users hit the **LB** (one public endpoint).
2. LB forwards each request to **healthy** EC2 instances.
3. **Health checks** run constantly. If an instance fails, LB stops sending traffic there.

**Common algorithm:**  
- **Round Robin** = 1st request → Server A, 2nd → Server B, 3rd → Server C, then back to A…

```

```
     Internet Users
            │
            ▼
     +---------------+
     | Load Balancer |
     +---------------+
        │     │     │
        ▼     ▼     ▼
     EC2 A  EC2 B  EC2 C
```

```

---

## Health checks (must-have)

- Path/port the LB probes, e.g., `HTTP:80 /healthz` → expect **200 OK**  
- Thresholds: how many passes/fails before “healthy/unhealthy”  
- Purpose: remove bad instances automatically

---

## Types of AWS Load Balancers

| Type | OSI Layer | Best For | Highlights |
|-----|-----------|----------|------------|
| **Application (ALB)** | Layer 7 | HTTP/HTTPS web apps | Path/host routing, headers, cookies, WebSockets, TLS termination with ACM |
| **Network (NLB)** | Layer 4 | Extreme performance TCP/UDP | Very low latency, static IP/EIP per AZ, TLS pass-through/termination |
| **Gateway (GWLB)** | Layer 3 | Firewalls / inspection | Transparent appliance insertion |
| **Classic (CLB)** | 4/7 | Legacy only | Old gen—prefer ALB/NLB for new apps |

**Good defaults for web apps (ALB):**
- Redirect **HTTP → HTTPS**
- **TLS** termination at ALB (managed certs via **ACM**)
- Health check on `/healthz`
- Consider **AWS WAF** and **access logs**

📸 **Reference:**  
[AWS Elastic Load Balancing](https://docs.aws.amazon.com/elasticloadbalancing/latest/userguide/what-is-load-balancing.html)

</details>

---

<details>
<summary><strong>13. Auto Scaling & Monitoring</strong></summary>

---

## Why Auto Scaling?

Traffic changes all day.  
- If you size for peak all the time → **waste money**.  
- If you size small → **downtime** during spikes.

**Auto Scaling** grows and shrinks capacity automatically.

**Analogy:** Open extra billing counters when the line gets long; close them when the store is empty.

---

## Core building blocks

1. **Launch Template**  
   - The “recipe” for new instances (AMI, type, SGs, User Data, IAM role)
2. **Auto Scaling Group (ASG)**  
   - Controls **Min / Desired / Max** instance counts
3. **Scaling Policies**  
   - **Target tracking**: keep a metric steady (e.g., CPU ~ 60%)  
   - **Step scaling**: thresholds add/remove in steps  
   - **Scheduled**: time-based (e.g., weekdays 9 AM scale up)
4. **Health checks**  
   - Replace unhealthy instances (EC2/ELB health)
5. **Lifecycle hooks** (optional)  
   - Run scripts before instance joins/leaves (warm-up, drain, save logs)

```

```
        Internet Users
              │
              ▼
       [ Load Balancer ]
              │
  ┌───────────┴───────────┐
  ▼                       ▼
```

[ EC2 ]                 [ EC2 ]
▲                       ▲
└──────────┬────────────┘
│
Auto Scaling Group
Min=2  Desired=2  Max=6
↑ Add when metric rises (scale out)
↓ Remove when metric falls (scale in)

```

---

## Monitoring (keep an eye)

- **CloudWatch Metrics**: CPU, Network, ELB TargetResponseTime, RequestCountPerTarget, custom app metrics  
- **CloudWatch Alarms**: trigger scaling or alerts  
- **CloudWatch Logs**: ship system/app logs  
- **Dashboards**: single pane of health

---

## A simple, safe starting pattern

- Put instances in **multiple AZs** behind an **ALB**  
- ASG: **Min=2**, Desired starts at 2, **Max** sized for spikes  
- **Target tracking** on CPU (e.g., 50–60%) or ALB metrics (RequestCountPerTarget)  
- Health check grace period during warm-up  
- Use **Instance Refresh** for rolling updates (new AMI/LT)

📸 **References:**  
[Amazon EC2 Auto Scaling](https://docs.aws.amazon.com/autoscaling/ec2/userguide/what-is-amazon-ec2-auto-scaling.html)  
[Amazon CloudWatch](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/WhatIsCloudWatch.html)

</details>
---
# TOOL: 08. AWS – Cloud Infrastructure | FILE: 08-rds
---

[Home](../README.md) | 
[Intro to AWS](../01-intro-aws/README.md) | 
[IAM](../02-iam/README.md) | 
[VPC & Subnet](../03-vpc-subnet/README.md) | 
[EBS](../04-ebs/README.md) | 
[EFS](../05-efs/README.md) | 
[S3](../06-s3/README.md) | 
[EC2](../07-ec2/README.md) | 
[RDS](../08-rds/README.md) | 
[Load Balancing & Auto Scaling](../09-Load-balancing-auto-scaling/README.md) | 
[CloudWatch & SNS](../10-cloudwatch-sns/README.md) | 
[Lambda](../11-lambda/README.md) | 
[Elastic Beanstalk](../12-elastic-beanstalk/README.md) | 
[Route 53](../13-route53/README.md) | 
[CLI + CloudFormation](../14-cli-cloudformation/README.md)

# AWS RDS – Relational Database Service

EC2 gives us compute power, but most real-world apps also need a structured place to store and query data — not just flat files.
RDS (Relational Database Service) fills that role.
Think of EC2 as your kitchen where code runs, and RDS as the organized pantry where recipes and ingredients stay safe and ready to use.

## Table of Contents
1. [Why Do We Need Databases?](#1-why-do-we-need-databases)
2. [Challenges with On-Premises Databases](#2-challenges-with-on-premises-databases)
3. [What Is Amazon RDS?](#3-what-is-amazon-rds)
4. [Core Components](#4-core-components)
5. [Key Features](#5-key-features)
6. [How Backups Actually Work (Behind the Scenes)](#6-how-backups-actually-work-behind-the-scenes)
7. [RDS in DevOps](#7-rds-in-devops)

---

<details>
<summary><strong>1. Why Do We Need Databases?</strong></summary>
  
Every application — whether it’s a food delivery app or a movie streaming site — needs a place to **store and recall information safely**.  
That’s what a **database** does: it holds your data even after your system restarts.

Without a database, your app would forget everything — like a restaurant that loses all its orders the moment the power goes out.

---

### The Restaurant Analogy
  
Let’s imagine your application is a restaurant.

* The **chef** is your **database engine** (MySQL, PostgreSQL, Oracle, etc.) — cooking up the data and serving results.  
* The **manager** is **AWS RDS** — taking care of the kitchen, groceries, cleaning, and overall maintenance.  
* And you — the **owner (application)** — just focus on serving customers and taking new orders.

You don’t worry about whether the gas is filled or the ingredients are fresh — that’s RDS’s job.

| Role             | Real-World Task                          | AWS Equivalent                              |
| ---------------- | ---------------------------------------- | ------------------------------------------- |
| You (Owner/App)  | Take customer orders                     | Application sending queries                 |
| Chef (DB Engine) | Cook food                                | Process and store data                      |
| Manager (RDS)    | Keep kitchen running, handle maintenance | Manage infrastructure, backups, and scaling |

So RDS basically keeps your “data kitchen” running, while you focus on your customers.

</details>

---

<details>
<summary><strong>2. Challenges with On-Premises Databases</strong></summary>
  
Before cloud services existed, companies had to host databases on **physical servers**.  
That sounds fine until you realize what it really meant:

* You had to **buy and maintain hardware**.  
* You were responsible for **installing, patching, and updating** the database software.  
* **Scaling** was a nightmare — if your app suddenly went viral, you couldn’t just “add capacity” overnight.  
* **Backups and failovers** had to be handled manually.  
* And if a server crashed — well, good luck restoring it quickly.

So instead of building your product, you’d be stuck doing IT housekeeping.

</details>

---

<details>
<summary><strong>3. What Is Amazon RDS?</strong></summary>
  
That’s exactly where **Amazon RDS (Relational Database Service)** steps in.  

RDS is a **fully managed service** that handles all the heavy lifting — setup, maintenance, scaling, patching, and backups — while you focus on using the database, not running it.

You just choose:

* which **engine** you want (MySQL, PostgreSQL, Oracle, SQL Server, or MariaDB),  
* how big your instance should be,  
* and AWS does the rest.

So you focus on your app, and RDS quietly takes care of the kitchen.

---

### Quick Architecture View

📘 **Reference Diagram:**  
[AWS RDS Architecture](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/images/Amazon-RDS-concept.png)

```

Application (EC2 / Lambda)
↓
Security Group (Port 3306 for MySQL)
↓
RDS Instance
↓
Automated Backups + Multi-AZ Replicas

```

In short — your app connects to RDS, and AWS makes sure your data stays available, secure, and recoverable.

</details>

---

<details>
<summary><strong>4. Core Components</strong></summary>
  
When you launch an RDS instance, AWS silently builds several moving parts underneath.  
Here’s what they are and how they fit together:

---

### 1. DB Instance
This is the actual **compute environment** where your database runs — like a virtual machine with CPU, RAM, and storage.  
You can scale it vertically (change instance type) or horizontally (add replicas).

---

### 2. DB Engine
This defines which database technology is powering your instance.  
Options include MySQL, PostgreSQL, Oracle, SQL Server, and MariaDB.  
Each has its own pricing and features, but RDS handles all of them in a similar way.

---

### 3. Endpoint
Every RDS instance gets a **unique DNS endpoint**.  
That’s your connection string — your app uses it instead of an IP.

Example:
```

mydb.xxxxx.ap-south-1.rds.amazonaws.com

```

Even during a failover or maintenance, the endpoint always points to the correct active instance.

---

### 4. Storage Type
RDS storage comes from **EBS (Elastic Block Store)**.  
You can pick:

* **gp3 (General Purpose SSD)** – cost-effective and balanced performance.  
* **io2 (Provisioned IOPS SSD)** – high-speed, low-latency storage for heavy workloads.

You can increase storage size anytime — no downtime required.

---

### 5. Security Group
This acts as a **firewall** controlling who can access your database.

| Engine     | Port |
| ---------- | ---- |
| MySQL      | 3306 |
| PostgreSQL | 5432 |

Always restrict access to specific IPs or your EC2 instances only.

---

| Component          | Description                                       |
| ------------------ | ------------------------------------------------- |
| **DB Instance**    | The environment where the database runs           |
| **DB Engine**      | MySQL, PostgreSQL, Oracle, SQL Server, etc.       |
| **Endpoint**       | DNS name used by apps to connect                  |
| **Storage Type**   | SSD-backed storage (gp3 / io2)                    |
| **Security Group** | Firewall controlling inbound and outbound traffic |

</details>

---

<details>
<summary><strong>5. Key Features</strong></summary>
  
RDS is designed to make your life easier — handling everything you’d normally spend hours on.

---

### 1. Automated Backups
RDS automatically takes **daily snapshots** and transaction log backups.  
You can roll back to **any specific second** within your backup retention window.  
Perfect for accidental deletions or human errors.

---

### 2. Multi-AZ Deployment
RDS creates a **standby replica** in another Availability Zone.  
If the primary database fails, RDS automatically switches over to the standby.  
This means zero manual recovery and almost no downtime.

---

### 3. Read Replicas
For apps with lots of read requests (like dashboards or analytics), you can create **read-only copies**.  
They help distribute the load and improve performance.

---

### 4. Monitoring with CloudWatch
You can monitor CPU, memory, connections, and IOPS in real time.  
Set alarms or automation to scale when performance metrics go high.

---

### 5. Fully Managed by AWS
AWS takes care of everything — patching, scaling, failovers, and security updates.  
You only pay for what you use.

| Feature                   | What It Does                                    |
| ------------------------- | ----------------------------------------------- |
| **Automated Backups**     | Daily snapshots + point-in-time restore         |
| **Multi-AZ Deployment**   | Creates standby DB in another AZ for failover   |
| **Read Replicas**         | Distribute read traffic and improve performance |
| **CloudWatch Monitoring** | Tracks performance metrics                      |
| **Fully Managed**         | AWS handles all the maintenance tasks           |

</details>

---

<details>
<summary><strong>6. How Backups Actually Work (Behind the Scenes)</strong></summary>
  
### How RDS Backups Work in Action

Let’s say you create a **MySQL RDS instance** named `myapp-db` in the **Mumbai (ap-south-1)** region.

---

### **1. Primary Storage (EBS)**

When you launch the database:

* AWS automatically attaches **EBS (Elastic Block Store)** volumes behind the scenes to store your DB files.
* These volumes hold your actual data — tables, indexes, logs, configurations.
* You don’t see or manage them; RDS abstracts them away.

📦 **Service involved:**
**Amazon EBS** (RDS uses it internally for database storage)

---

### **2. Automated Backups Start**

When you enable automated backups (default setting):

* RDS quietly takes **EBS snapshots** of your database storage volume once every 24 hours.
* These are **incremental snapshots** — meaning only the changed data blocks are stored after the first backup.

📦 **Service involved:**
**Amazon EBS + Amazon S3**
→ Snapshots are EBS-level backups **stored inside Amazon S3** (you don’t see them directly in S3 console, but they live there).

---

### **3. Transaction Logs (Point-in-Time Recovery)**

Throughout the day, RDS continuously uploads **transaction logs** (the history of every write or change) to S3.
These logs allow **point-in-time recovery**, meaning you can restore your DB to *any exact second* before failure.

📦 **Service involved:**
**Amazon S3** (stores binary logs securely and redundantly)

---

### **4. Restore from Backup**

Imagine something goes wrong — your app accidentally drops a table.
You go to:
**AWS Console → RDS → Databases → Restore to Point in Time.**

You choose a timestamp, like:

```
12th Oct, 2025 – 14:22:05
```

AWS then:

1. Fetches the relevant **EBS snapshot** from S3.
2. Replays all **transaction logs** up to that exact second.
3. Creates a **new RDS instance** (`myapp-db-restore`) with recovered data.

Your original DB stays untouched.

📦 **Services involved:**

* **Amazon RDS** → Orchestrates the recovery process.
* **Amazon S3** → Provides the stored backups and logs.
* **Amazon EBS** → Creates new volumes for the restored DB.

---

### **5. Monitoring and Logging (Simplified View)**

Once your backups and restores are running, AWS gives you two “watchers” that keep an eye on everything — one for **performance**, and one for **activity history**.

---

#### a) CloudWatch → Performance Monitor  
- **Think of this as a health meter for your database.**  
- It constantly measures things like:
  - CPU usage  
  - Storage space used  
  - Number of connections  
  - Backup duration and progress  

You can open **CloudWatch → Metrics → RDS** in the console and actually see live graphs.  
If something goes wrong (for example, CPU > 90% for 5 minutes),  
you can set an **alarm** so AWS notifies you or even runs an action (like scaling).

**Purpose:** lets you know if your database or backups are slowing down, filling up, or overloading — before it becomes a problem.

---

#### b) CloudTrail → Activity History  
- **This keeps a diary of what actions were taken and by whom.**  
- Example: if someone runs  
  - “CreateSnapshot”  
  - “DeleteDBInstance”  
  - “RestoreDBInstanceFromBackup”  
  you’ll see exactly when and who did it.

It’s mainly for **security and auditing** — so you can trace changes if something unexpected happens.

**Purpose:** proves accountability and helps investigate any wrong action or failure later.

---

### **6. Cross-Region Backups (Optional, for Extra Safety)**

If you enable it, AWS can make **a copy of your snapshots** and send them to another region — say your main DB is in Mumbai (ap-south-1), the copy could go to N. Virginia (us-east-1).

Why this matters:
- If an entire region faces an outage or disaster, your data is still safe elsewhere.  
- You can even launch an RDS instance from that copy in the other region and keep your app running.

You can set this up once — RDS automates the rest.

---

### **7. The Big Picture (Tie Everything Together)**
  
Here’s what’s happening overall:

1. **Your RDS instance** stores live data on **EBS volumes**.  
2. **Automated backups** take **EBS snapshots** daily and save them in **S3**.  
3. **Transaction logs** continuously flow into **S3** so you can rewind to any second.  
4. **When you restore**, RDS combines the latest snapshot + those logs to rebuild your data on new EBS volumes.  
5. **CloudWatch** keeps you informed about performance and backup health.  
6. **CloudTrail** keeps an action log for auditing.  
7. Optionally, **S3** replicates your snapshots to another region for disaster recovery.  

Visually:

```

RDS Instance (EBS)
│
├──> Daily Snapshots ──> Amazon S3
├──> Transaction Logs ─> Amazon S3
│
├──> Monitoring ───────> CloudWatch
├──> Activity Logs ────> CloudTrail
└──> Optional Copies ──> S3 (Other Region)

```

---

### In Short
- **EBS** = live database storage.  
- **S3** = safe long-term backup vault.  
- **CloudWatch** = performance dashboard.  
- **CloudTrail** = security history log.  

Together, these services make RDS backups automatic, trackable, and easy to recover.

### **Realistic Example**

Your production app (say, `food-ordering-app`) uses RDS for orders.

Scenario:

* At 3:15 PM, a wrong SQL command deletes the “customers” table.
* You open RDS → click “Restore to point in time” → select 3:14:59 PM.
* AWS automatically restores from your latest backup snapshot + replay logs →
  **new DB instance appears with all data intact**.
* You reconnect your app to the new endpoint, and everything resumes normally.

---

**In short:**

* RDS uses **EBS** for live data,
* **S3** for backups and logs,
* **CloudWatch** for monitoring,
* **CloudTrail** for auditing, and
* all of it is managed by **RDS itself** — no manual coordination needed.

</details>

---

<details>
<summary><strong>7. RDS in DevOps</strong></summary>
  
In a DevOps workflow, RDS acts as your **database backbone** — reliable, monitored, and automated.

* **Infrastructure as Code (IaC):** Create and manage RDS using Terraform or CloudFormation.  
* **Automation:** Integrate snapshots and restore operations into CI/CD pipelines.  
* **Monitoring:** Push CloudWatch metrics into Grafana or custom dashboards.  
* **Security:** Use IAM roles, KMS encryption, and TLS connections.  
* **Reliability:** Multi-AZ and PITR protect against failures and human mistakes.

In short — RDS gives your application the confidence to scale, fail, recover, and still stay online.

</details>
---
# TOOL: 08. AWS – Cloud Infrastructure | FILE: 09-Load-balancing-auto-scaling
---

[Home](../README.md) | 
[Intro to AWS](../01-intro-aws/README.md) | 
[IAM](../02-iam/README.md) | 
[VPC & Subnet](../03-vpc-subnet/README.md) | 
[EBS](../04-ebs/README.md) | 
[EFS](../05-efs/README.md) | 
[S3](../06-s3/README.md) | 
[EC2](../07-ec2/README.md) | 
[RDS](../08-rds/README.md) | 
[Load Balancing & Auto Scaling](../09-Load-balancing-auto-scaling/README.md) | 
[CloudWatch & SNS](../10-cloudwatch-sns/README.md) | 
[Lambda](../11-lambda/README.md) | 
[Elastic Beanstalk](../12-elastic-beanstalk/README.md) | 
[Route 53](../13-route53/README.md) | 
[CLI + CloudFormation](../14-cli-cloudformation/README.md)

# AWS Load Balancer & Auto Scaling – Resilience and Scaling in Action

Once our app is up, we hit the next challenge — growth.
More users mean more requests, and one EC2 can’t handle them forever.
This is where Load Balancers and Auto Scaling come in: one spreads the traffic, the other adds or removes servers automatically.
Together they make your system stable, fast, and cost-smart.

## Table of Contents
1. [Why We Need Load Balancing & Auto Scaling](#1-why-we-need-load-balancing--auto-scaling)
2. [Load Balancer – The Traffic Director](#2-load-balancer--the-traffic-director)
3. [AWS Load Balancer Types (Deep Clarity + Scenarios)](#3-aws-load-balancer-types-deep-clarity--scenarios)
4. [Health Checks Explained](#4-health-checks-explained)
5. [Auto Scaling – The Self-Healing Mechanism](#5-auto-scaling--the-self-healing-mechanism)
6. [Scaling Policies](#6-scaling-policies)
7. [Monitoring with CloudWatch](#7-monitoring-with-cloudwatch)
8. [Recommended Architecture Pattern](#8-recommended-architecture-pattern)
9. [Cost Awareness](#9-cost-awareness)
10. [Benefits Recap](#10-benefits-recap)
11. [Hands-On Pointers](#11-hands-on-pointers)
12. [References](#12-references)

---

<details>
<summary><strong>1. Why We Need Load Balancing & Auto Scaling</strong></summary>

When an application runs on a single EC2 instance, it’s vulnerable — if that instance fails, users face downtime.  
As traffic grows, that single instance also becomes a bottleneck.

**Load Balancing** prevents overload by distributing requests across multiple servers.  
**Auto Scaling** ensures the number of servers adjusts automatically with demand.

Together, they create systems that are:
- **Highly available** – no single point of failure  
- **Scalable** – adapt to load changes  
- **Cost-efficient** – run only what’s needed  

**Analogy:**  
Think of a restaurant during lunch hour. The manager (Load Balancer) sends customers evenly to free tables,  
and when the rush increases, new waiters are called in (Auto Scaling).  
When it’s quiet again, the extra waiters leave — smooth, efficient, and balanced.

</details>

---

<details>
<summary><strong>2. Load Balancer – The Traffic Director</strong></summary>

### Purpose
A Load Balancer acts as a **single entry point** for all users, forwarding requests to backend EC2 instances that are healthy and available.

### How It Works
1. Users connect to the LB’s DNS name.  
2. The LB routes each request to a **Target Group** (group of EC2 instances or IPs).  
3. Constant **Health Checks** decide which targets are fit to receive traffic.  
4. The LB automatically stops sending traffic to unhealthy instances.

### Core Concepts

| Term | Description |
|------|--------------|
| **Listener** | Defines protocol and port (e.g., HTTP 80 → Target Group A) |
| **Target Group** | Pool of EC2 targets behind the LB |
| **Rule** | Conditions (path/host/header) used for routing |
| **Cross-Zone LB** | Balances traffic across AZs for fault tolerance |
| **Sticky Sessions** | Keeps a client bound to the same target |
| **TLS Termination** | LB handles HTTPS encryption via ACM certificate |
| **Access Logs** | Store detailed connection data to S3 |

### Simple Architecture

```

Internet Users
│
▼
+------------------+
|  Load Balancer   |
+------------------+
│     │     │
▼     ▼     ▼
EC2-A EC2-B EC2-C

```

</details>

---

<details>
<summary><strong>3. AWS Load Balancer Types (Deep Clarity + Scenarios)</strong></summary>

Each LB type works at a specific **OSI layer** and fits different needs.

| Type | OSI Layer | Think of It As | Ideal For | Why It Fits Best |
|------|------------|----------------|------------|------------------|
| **Application LB (ALB)** | Layer 7 | Smart receptionist who understands full sentences | Web apps (HTTP/HTTPS) | Routes by path/host, supports cookies, redirects, WebSockets, and integrates with ACM & WAF. |
| **Network LB (NLB)** | Layer 4 | Bouncer who checks connection tickets | Gaming, IoT, low-latency or fixed-IP workloads | Handles millions of TCP/UDP connections with static IPs and TLS pass-through. |
| **Gateway LB (GWLB)** | Layer 3 | Security checkpoint inspecting every packet | Firewalls, intrusion detection, network inspection | Transparently inserts appliances into traffic flow. |
| **Classic LB (CLB)** | Layer 4/7 | Old front-desk operator | Legacy EC2 stacks | Simple, but lacks advanced routing and metrics — migrate to ALB/NLB. |

---

#### Real-World Scenarios

| Scenario | Best LB | Why This Works |
|-----------|----------|----------------|
| Multi-path web app (`/`, `/api`, `/login`) | **ALB** | Path-based routing, SSL termination, WAF support. |
| Multiplayer gaming needing static IPs | **NLB** | TCP/UDP speed, minimal latency. |
| Deploying network firewalls (FortiGate, Palo Alto) | **GWLB** | Inserts inspection appliances inline transparently. |
| Legacy monolith (pre-2016) | **CLB → ALB recommended** | Backward compatible, but ALB adds performance & logs. |

---

#### OSI Layer Quick View

| Layer | Understands | Example Decision |
|--------|--------------|------------------|
| **L3 (GWLB)** | IP Packets | “Route 10.0.0.0/16 through firewall.” |
| **L4 (NLB)** | Ports & Protocols | “If TCP 443 → EC2-A.” |
| **L7 (ALB)** | Full HTTP/HTTPS requests | “If path = /api → Target Group 2.” |

---

#### Choosing Quickly

| Goal | Choose |
|------|---------|
| Smart routing (URLs, headers) | **ALB** |
| Ultra-low latency or static IP | **NLB** |
| Security inspection | **GWLB** |
| Legacy support | **CLB** |

</details>

---

<details>
<summary><strong>4. Health Checks Explained</strong></summary>

Health Checks are what keep your Load Balancer smart — it constantly asks,  
“Are you okay?” to each target before sending traffic.

**Parameters to Configure**
- **Protocol & Path** → `HTTP:80 /healthz` or `TCP:22`  
- **Healthy Threshold** → How many successes before marking healthy  
- **Unhealthy Threshold** → Failures before removing instance  
- **Interval** → Frequency of checks  
- **Timeout** → Wait time before declaring failure  

**Goal:** keep traffic flowing only to **healthy** instances automatically.

</details>

---

<details>
<summary><strong>5. Auto Scaling – The Self-Healing Mechanism</strong></summary>

When traffic rises, add servers; when it drops, remove them.  
That’s what Auto Scaling does — **scale dynamically without manual control.**

### Core Components

| Component | Description |
|------------|-------------|
| **Launch Template** | Blueprint defining AMI, instance type, SGs, IAM role, User Data |
| **Auto Scaling Group (ASG)** | Logical group controlling instance count (Min/Desired/Max) |
| **Scaling Policies** | Define how and when scaling occurs |
| **Health Checks** | Replace unhealthy instances automatically |
| **Lifecycle Hooks** | Trigger actions before join/after terminate (warm-up, drain, save logs) |

### Analogy
Like a supermarket opening more checkout counters when queues form  
and closing them when the rush ends — smooth, elastic, cost-efficient.

</details>

---

<details>
<summary><strong>6. Scaling Policies</strong></summary>

| Policy Type | Trigger | Example |
|--------------|----------|----------|
| **Target Tracking** | Maintain a steady metric | Keep CPU ≈ 60 % |
| **Step Scaling** | Adjust by threshold steps | +1 instance @ 70 %, +2 @ 90 % |
| **Simple Scaling** | One threshold → one action | Add 1 instance when CPU > 80 % |
| **Scheduled Scaling** | Time-based automation | Weekdays 9 AM scale out, 5 PM scale in |

**Behind the Scenes**
- Scaling uses **CloudWatch Alarms** to detect thresholds.  
- ASG then launches or terminates instances based on that metric.

</details>

---

<details>
<summary><strong>7. Monitoring with CloudWatch</strong></summary>

**CloudWatch** provides full observability:

| Type | Use |
|------|-----|
| **Metrics** | CPU, Network, RequestCountPerTarget, TargetResponseTime |
| **Alarms** | Trigger actions or notifications |
| **Logs** | Collect system/app logs |
| **Dashboards** | Unified view of health and scaling metrics |

Combine these with scaling policies for a closed feedback loop:  
*Monitor → Decide → Act → Repeat.*

</details>

---

<details>
<summary><strong>8. Recommended Architecture Pattern</strong></summary>

**Goal:** High availability + elastic scaling + cost efficiency.

```

```
    Internet Users
          │
          ▼
 ┌────────────────┐
 │ Application LB │  ← HTTPS 443 (ACM certs)
 └────────────────┘
          │
 ┌────────┴────────┐
 ▼                 ▼
```

EC2-A             EC2-B
▲               ▲
└──────┬────────┘
│
Auto Scaling Group
Min = 2  Desired = 2  Max = 6

```

- Instances spread across multiple AZs  
- Health Checks at ALB and EC2 level  
- Scaling based on CPU or RequestCountPerTarget  
- Instance Refresh for rolling updates  
- Logging + Alerts via CloudWatch

</details>

---

<details>
<summary><strong>9. Cost Awareness</strong></summary>

| Component | Cost Basis | Notes |
|------------|-------------|-------|
| **ALB** | per hour + per LCU (Load Balancer Capacity Unit) | Pay for time active + processed traffic |
| **NLB** | per hour + per LCU (new connections, data processed) | Slightly higher but faster |
| **ASG** | Free | Pay only for EC2 and CloudWatch usage |
| **CloudWatch** | per metric + alarms + logs | Optimize by filtering important metrics only |

**Tip:**  
Right-size instance types and schedule down-scaling windows to reduce bills.

</details>

---

<details>
<summary><strong>10. Benefits Recap</strong></summary>

| Capability | Handled By | Outcome |
|-------------|-------------|----------|
| Traffic Distribution | Load Balancer | Balanced user experience |
| Fault Tolerance | LB + ASG | Automatic recovery from failures |
| Cost Efficiency | ASG | Scales down when idle |
| Security & Monitoring | WAF + CloudWatch | Visibility and Protection |

Together they build **resilient, self-adjusting AWS architectures.**

</details>

---

<details>
<summary><strong>11. Hands-On Pointers</strong></summary>

1. Deploy **ALB** in public subnets; register EC2 targets in private subnets.  
2. Create **Launch Template** → link to ASG → attach scaling policy.  
3. Configure Health Checks (`/healthz`) and grace periods.  
4. Use **ACM** for free SSL/TLS certificates.  
5. Verify metrics in **CloudWatch Dashboard**.  
6. Test scaling by generating load (e.g., Apache Bench or stress tool).

</details>

---

<details>
<summary><strong>12. References</strong></summary>

- [AWS Elastic Load Balancing Docs](https://docs.aws.amazon.com/elasticloadbalancing/latest/userguide/what-is-load-balancing.html)  
- [Amazon EC2 Auto Scaling Docs](https://docs.aws.amazon.com/autoscaling/ec2/userguide/what-is-amazon-ec2-auto-scaling.html)  
- [Amazon CloudWatch Docs](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/WhatIsCloudWatch.html)  
- [AWS WAF Integration Guide](https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html)  
- [AWS Certificate Manager Overview](https://docs.aws.amazon.com/acm/latest/userguide/acm-overview.html)

</details>
---
# TOOL: 08. AWS – Cloud Infrastructure | FILE: 10-cloudwatch-sns
---

[Home](../README.md) | 
[Intro to AWS](../01-intro-aws/README.md) | 
[IAM](../02-iam/README.md) | 
[VPC & Subnet](../03-vpc-subnet/README.md) | 
[EBS](../04-ebs/README.md) | 
[EFS](../05-efs/README.md) | 
[S3](../06-s3/README.md) | 
[EC2](../07-ec2/README.md) | 
[RDS](../08-rds/README.md) | 
[Load Balancing & Auto Scaling](../09-Load-balancing-auto-scaling/README.md) | 
[CloudWatch & SNS](../10-cloudwatch-sns/README.md) | 
[Lambda](../11-lambda/README.md) | 
[Elastic Beanstalk](../12-elastic-beanstalk/README.md) | 
[Route 53](../13-route53/README.md) | 
[CLI + CloudFormation](../14-cli-cloudformation/README.md)

# 🛰️ AWS CloudWatch & SNS — “The Eyes and Bell of AWS”

> **CloudWatch observes. SNS alerts.**
> Together, they form the heartbeat and voice of your AWS ecosystem — detecting change and announcing it instantly.
> **Phase 5 – Automation & Monitoring**

---

## Table of Contents

1. [Why We Need Observability](#1-why-we-need-observability)
2. [What Is CloudWatch](#2-what-is-cloudwatch)
3. [What Is SNS](#3-what-is-sns)
4. [Core Concepts](#4-core-concepts)
5. [Architecture Diagram](#5-architecture-diagram)
6. [Hands-On Workflow](#6-hands-on-workflow)
7. [Best Practices & Use Cases](#7-best-practices--use-cases)
8. [Beyond Alerts – Automation & IaC](#8-beyond-alerts--automation--iac)
9. [Cost & Optimization Tips](#9-cost--optimization-tips)
10. [Quick Summary](#10-quick-summary)
11. [Self-Audit Checklist](#11-self-audit-checklist)

---

<details>
<summary><strong>1. Why We Need Observability</strong></summary>

As infrastructure grows, manual health checks don’t scale.
We need **real-time telemetry** — metrics, logs, events — that expose what’s happening under the hood.

Without observability:

* Outages go undetected until users report them.
* Bottlenecks stay hidden.
* MTTR (mean time to repair) skyrockets.

**CloudWatch + SNS** close the loop:

> Measure → Detect → Alert → Respond → Recover.

</details>

---

<details>
<summary><strong>2. What Is CloudWatch</strong></summary>

Amazon CloudWatch provides a **central nervous system** for AWS environments.

It collects and visualizes:

* **Metrics:** quantitative measures (CPU, Memory, I/O).
* **Logs:** textual data from applications & services.
* **Events:** resource state changes (e.g., EC2 stopped).
* **Alarms:** logic that evaluates metrics and triggers actions.

Advanced features:

* **Metric Math:** combine or compute metrics (e.g., `CPUUtilization / NumberOfCores`).
* **Anomaly Detection:** ML-based deviation banding.
* **Composite Alarms:** aggregate multiple alarms → one decision point.
* **Dashboards:** unified visibility across accounts and regions.

Reference: [AWS Docs – CloudWatch](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/WhatIsCloudWatch.html)

</details>

---

<details>
<summary><strong>3. What Is SNS</strong></summary>

Amazon Simple Notification Service (SNS) is a **fully-managed pub/sub messaging service**.
It decouples **publishers (alarms)** from **subscribers (email, Lambda, SQS, HTTP)**.

```
CloudWatch Alarm ──► SNS Topic ──► Subscribers (Email / SMS / Lambda)
```

Features:

* **Fan-out delivery** to multiple endpoints.
* **Durability** and delivery retries.
* **Message filtering** per subscription.
* **Cross-account topics** for centralized alerting.

Reference: [AWS Docs – SNS](https://docs.aws.amazon.com/sns/latest/dg/welcome.html)

</details>

---

<details>
<summary><strong>4. Core Concepts</strong></summary>

| Concept                | CloudWatch Role                              | SNS Role                                |
| ---------------------- | -------------------------------------------- | --------------------------------------- |
| **Metric**             | Numeric data point (e.g., CPU %, Requests)   | —                                       |
| **Log Group / Stream** | Store application or system logs             | —                                       |
| **Alarm**              | Evaluates metric vs threshold → state change | Publishes message to topic              |
| **Dashboard**          | Visualization of metrics                     | —                                       |
| **Event**              | Detects resource changes                     | May publish notifications through SNS   |
| **Topic**              | —                                            | Named channel for messages              |
| **Subscription**       | —                                            | Destination endpoint (Email/SMS/Lambda) |

**Logs vs Metrics vs Events**

| Data Type   | Example Source          | Used For                            |
| ----------- | ----------------------- | ----------------------------------- |
| **Logs**    | App stdout / EC2 syslog | Root-cause analysis                 |
| **Metrics** | CPU %, Memory, Latency  | Trend monitoring & threshold alarms |
| **Events**  | EC2 stop, Lambda invoke | Automation & reactive flows         |

</details>

---

<details>
<summary><strong>5. Architecture Diagram</strong></summary>

```
                   ┌──────────────────────────────┐
                   │         AWS Resources         │
                   │  (EC2, RDS, Lambda, ECS…)   │
                   └──────────────┬───────────────┘
                                  │  Metrics / Logs
                                  ▼
                        ┌──────────────────┐
                        │   CloudWatch     │
                        │ Metrics + Logs   │
                        └───────┬──────────┘
                                │ Alarm Trigger
                                ▼
                        ┌──────────────────┐
                        │     SNS Topic    │
                        │   (ops-alerts)   │
                        └───────┬──────────┘
              ┌────────────────┼────────────────┐
              │                │                │
       ┌────────────┐  ┌────────────┐  ┌────────────┐
       │   Email     │  │   SMS      │  │  Lambda    │
       │ Subscriber  │  │ Subscriber │  │ Automation │
       └────────────┘  └────────────┘  └────────────┘
```

**Planes of Operation**

```
Metrics Plane   →  Collect & Store  (CloudWatch)
Alarm Plane     →  Evaluate & Trigger
Notification Plane →  Publish & Deliver (SNS)
Automation Plane  →  Remediate (Lambda/Systems Manager)
```

</details>

---

<details>
<summary><strong>6. Hands-On Workflow</strong></summary>

**Step 1 – Create SNS Topic & Subscription**

```bash
aws sns create-topic --name ops-alerts
aws sns subscribe \
  --topic-arn arn:aws:sns:us-east-1:111122223333:ops-alerts \
  --protocol email --notification-endpoint admin@example.com
```

Confirm email subscription.

**Step 2 – Create CloudWatch Alarm**

```bash
aws cloudwatch put-metric-alarm \
  --alarm-name HighCPU \
  --metric-name CPUUtilization --namespace AWS/EC2 \
  --statistic Average --period 300 --threshold 80 \
  --comparison-operator GreaterThanThreshold \
  --dimensions Name=InstanceId,Value=i-0123456789abcdef \
  --evaluation-periods 1 \
  --alarm-actions arn:aws:sns:us-east-1:111122223333:ops-alerts
```

**Step 3 – Trigger Alarm**

```bash
sudo yum install stress -y
sudo stress --cpu 4 --timeout 60
```

→ Alarm state changes to `ALARM` → SNS emails team.

**Step 4 – View Alarm History**
Console → CloudWatch → Alarms → History.

</details>

---

<details>
<summary><strong>7. Best Practices & Use Cases</strong></summary>

### Operational Excellence

* Group metrics per application/environment.
* Apply consistent naming: `<env>-<service>-<metric>-<severity>`.
* Define severity levels → separate SNS topics (`critical`, `warning`, `info`).
* Use **composite alarms** to reduce noise.
* Set **log retention policies**.
* Encrypt SNS topics with KMS.
* Integrate Slack/MS Teams via Lambda webhooks.
* Enable **cross-account dashboards** for central visibility.

### Practical Use Cases

| Category             | Example                                    |
| -------------------- | ------------------------------------------ |
| **Performance**      | Alert when ALB 5xx > 1 %, CPU > 80 %       |
| **Security**         | Root login event → SNS critical topic      |
| **Automation**       | Low disk space → Lambda expands EBS volume |
| **Cost Control**     | Idle instance → SNS → Lambda terminates    |
| **DevOps Pipelines** | CI/CD failure → SNS → Slack channel        |

</details>

---

<details>
<summary><strong>8. Beyond Alerts – Automation & IaC</strong></summary>

### 8.1 Event-Driven Remediation (Example)

```
CloudWatch Alarm → SNS Topic → Lambda → EC2 API (Action)
```

**Scenario:** CPU ≥ 95 % for 5 min → auto-scale EC2.

Lambda code (abstract):

```python
import boto3
def handler(event, context):
  asg = boto3.client('autoscaling')
  asg.set_desired_capacity(AutoScalingGroupName='web-tier', DesiredCapacity=3)
```

SNS publishes → Lambda invoked → Infra self-heals.

### 8.2 Infrastructure-as-Code (CloudFormation Snippet)

```yaml
Resources:
  OpsAlertsTopic:
    Type: AWS::SNS::Topic
    Properties:
      TopicName: ops-alerts

  HighCPUAlarm:
    Type: AWS::CloudWatch::Alarm
    Properties:
      AlarmDescription: High CPU Utilization
      Namespace: AWS/EC2
      MetricName: CPUUtilization
      Statistic: Average
      Period: 300
      Threshold: 80
      ComparisonOperator: GreaterThanThreshold
      EvaluationPeriods: 1
      AlarmActions:
        - !Ref OpsAlertsTopic
```

Version-control your alerts and topics alongside application code.

</details>

---

<details>
<summary><strong>9. Cost & Optimization Tips</strong></summary>

| Area           | Tip                                                              |
| -------------- | ---------------------------------------------------------------- |
| **Metrics**    | Publish aggregated custom metrics instead of per-instance.       |
| **Logs**       | Set retention < 30 days unless required.                         |
| **Dashboards** | Delete unused widgets to cut API calls.                          |
| **Alarms**     | Combine via Composite Alarms to reduce charges.                  |
| **SNS**        | Batch non-urgent notifications or route through SQS to throttle. |

</details>

---

<details>
<summary><strong>10. Quick Summary</strong></summary>

* **CloudWatch = Observer**, **SNS = Messenger**.
* Together → real-time visibility + automated response.
* Use metric math & anomaly detection for smarter alerts.
* Codify monitoring via CloudFormation/Terraform.
* Maintain alert hygiene (severity, naming, noise control).
* Integrate Lambda for self-healing automation.

</details>

---

<details>
<summary><strong>11. Self-Audit Checklist</strong></summary>

* [ ] I can explain how CloudWatch and SNS interact.
* [ ] I can create metrics, alarms, and SNS topics via CLI/IaC.
* [ ] I understand metric math and anomaly detection.
* [ ] I can draw the Event → Metric → Alarm → SNS → Lambda flow.
* [ ] I can implement alert severity and retention policies.
* [ ] I can estimate and optimize CloudWatch costs.
* [ ] I have a cross-account dashboard for visibility.

</details>

---
---
# TOOL: 08. AWS – Cloud Infrastructure | FILE: 11-lambda
---

[Home](../README.md) | 
[Intro to AWS](../01-intro-aws/README.md) | 
[IAM](../02-iam/README.md) | 
[VPC & Subnet](../03-vpc-subnet/README.md) | 
[EBS](../04-ebs/README.md) | 
[EFS](../05-efs/README.md) | 
[S3](../06-s3/README.md) | 
[EC2](../07-ec2/README.md) | 
[RDS](../08-rds/README.md) | 
[Load Balancing & Auto Scaling](../09-Load-balancing-auto-scaling/README.md) | 
[CloudWatch & SNS](../10-cloudwatch-sns/README.md) | 
[Lambda](../11-lambda/README.md) | 
[Elastic Beanstalk](../12-elastic-beanstalk/README.md) | 
[Route 53](../13-route53/README.md) | 
[CLI + CloudFormation](../14-cli-cloudformation/README.md)

# ⚡ AWS Lambda — “The Invisible Compute Engine”

> **Run code without servers. Pay only when it runs.**
> **Phase 5 – Automation & Serverless**

---

## Table of Contents

1. [Prerequisites (Read Me First)](#1-prerequisites-read-me-first)
2. [Why Lambda Exists](#2-why-lambda-exists)
3. [What Lambda Is (and Isn’t)](#3-what-lambda-is-and-isnt)
4. [Core Building Blocks](#4-core-building-blocks)
5. [Event Sources & Triggers](#5-event-sources--triggers)
6. [Execution Model & Lifecycle](#6-execution-model--lifecycle)
7. [Permissions, Security & Networking](#7-permissions-security--networking)
8. [Concurrency, Scaling & Cold Starts](#8-concurrency-scaling--cold-starts)
9. [Observability: Logs, Metrics, DLQ & Retries](#9-observability-logs-metrics-dlq--retries)
10. [Packaging, Versions, Aliases, Layers & Container Images](#10-packaging-versions-aliases-layers--container-images)
11. [Hands-On Workflow (Console + CLI)](#11-hands-on-workflow-console--cli)
12. [IaC Snapshot (CloudFormation YAML)](#12-iac-snapshot-cloudformation-yaml)
13. [Architectures & Diagrams](#13-architectures--diagrams)
14. [Best Practices (Prod-Ready)](#14-best-practices-prod-ready)
15. [Pricing & Cost Controls](#15-pricing--cost-controls)
16. [Quick Summary](#16-quick-summary)
17. [Self-Audit Checklist](#17-self-audit-checklist)

---

<details>
<summary><strong>1. Prerequisites (Read Me First)</strong></summary>

* **CloudWatch & SNS** (for logs, alarms, notifications).
* **IAM basics** (roles, policies, least privilege).
* **VPC & subnets** (only if you run Lambda inside a VPC).
* **Optional:** AWS CLI for the hands-on; full CLI deep-dive appears later in your `15. AWS CLI.md`.

> 💡 If CLI isn’t comfortable yet, read conceptually and use the console steps. You’ll master the CLI in Phase 6 and come back to automate.

</details>

---

<details>
<summary><strong>2. Why Lambda Exists</strong></summary>

Traditional servers are wasteful for bursty, short tasks. Lambda removes server management and auto-scales to **events**.
Result: faster delivery, lower ops overhead, and pay-per-use economics.

</details>

---

<details>
<summary><strong>3. What Lambda Is (and Isn’t)</strong></summary>

**Is:** Event-driven, stateless compute that executes your function code on demand.
**Isn’t:** A long-running server, a place to keep connection state, or a fit for heavy, always-on workloads.

Good fits: API backends, file processing, scheduled jobs, lightweight ETL, async workers, event routing, glue code.

</details>

---

<details>
<summary><strong>4. Core Building Blocks</strong></summary>

| Concept            | What it means                                        |
| ------------------ | ---------------------------------------------------- |
| **Function**       | Your code + config.                                  |
| **Handler**        | Entry point Lambda calls (e.g., `app.handler`).      |
| **Runtime**        | Language env (Node, Python, Java, .NET, Go, custom). |
| **Timeout**        | Up to **15 minutes** per invocation.                 |
| **Memory**         | 128 MB – 10 GB (CPU scales with memory).             |
| **Ephemeral /tmp** | Up to 10 GB scratch space inside execution env.      |
| **Env Vars**       | Config injected at runtime (secrets via KMS).        |
| **Execution Role** | IAM role Lambda assumes to access AWS APIs.          |

</details>

---

<details>
<summary><strong>5. Event Sources & Triggers</strong></summary>

Common **synchronous** triggers: **API Gateway**, **ALB**, **Lambda Function URL**.
Common **asynchronous**/stream triggers: **S3**, **SNS**, **EventBridge (CloudWatch Events)**, **SQS**, **Kinesis**, **DynamoDB Streams**, **Step Functions**.

```
Users → API Gateway → Lambda → DynamoDB
S3 PutObject → Lambda (thumbnail)
EventBridge schedule → Lambda (nightly job)
SQS queue → Lambda (async worker)
```

</details>

---

<details>
<summary><strong>6. Execution Model & Lifecycle</strong></summary>

1. **Initialization (Init / Cold Start)**

   * Runtime boot, code load, handler init, extensions init.
2. **Invoke (Warm)**

   * Lambda reuses the environment for subsequent requests if possible.
3. **Freeze / Reuse / Evict**

   * Env frozen between invokes; eventually recycled by the service.

**Statefulness note:** Keep code **stateless**; cache clients (DB, SDK) **outside** the handler to benefit from warm reuse.

</details>

---

<details>
<summary><strong>7. Permissions, Security & Networking</strong></summary>

* **Execution Role (IAM):** Grants access to AWS services (S3 get/put, DynamoDB, etc.).
* **Resource Policies:** Allow external services (e.g., S3, EventBridge) to invoke your function.
* **KMS:** Encrypt env vars & payloads when needed.
* **VPC Config:** If your function needs private resources (RDS/ElastiCache), attach to **private subnets** with **NAT** for outbound Internet.
* **Least privilege:** Narrow policies; separate roles per function.

</details>

---

<details>
<summary><strong>8. Concurrency, Scaling & Cold Starts</strong></summary>

* **Concurrency =** how many executions run in parallel.
* **Burst scaling**: Region-dependent large bursts; then scales linearly.
* **Reserved Concurrency:** Hard cap per function (prevents noisy neighbors).
* **Provisioned Concurrency:** Keeps environments warm to reduce cold starts (extra cost).
* **Cold starts:** Longer on VPC + heavy runtimes; mitigate with provisioned concurrency, lighter runtimes, smaller packages, and connection reuse.

</details>

---

<details>
<summary><strong>9. Observability: Logs, Metrics, DLQ & Retries</strong></summary>

* **Logs** → CloudWatch Logs (one log group per function).
* **Metrics** → Invocations, Duration, Errors, Throttles, IteratorAge (streams).
* **Retries**

  * **Async** (S3/SNS/EventBridge): automatic retries + optional **DLQ** (SQS/SNS).
  * **Streams** (Kinesis/DDB): retries until success; use **on-failure destination** or **bisect** patterns.
  * **Sync** (API Gateway): caller sees error; you retry in client or upstream.
* **Destinations** (async): route **success/failure** events to SNS/SQS/Lambda/EventBridge for auditing.
* **Lambda Insights**: enhanced metrics + profiling.

</details>

---

<details>
<summary><strong>10. Packaging, Versions, Aliases, Layers & Container Images</strong></summary>

* **Zip package** (fastest start for most).
* **Container image** (up to 10 GB) when you need OS deps / custom runtimes.
* **Versions**: Immutable snapshots of code+config.
* **Aliases**: Stable pointers to versions (`dev`, `prod`) → blue/green.
* **Layers**: Share libs across functions; keep function package lean.
* **Extensions**: Observability/partner agents that run alongside.

</details>

---

<details>
<summary><strong>11. Hands-On Workflow (Console + CLI)</strong></summary>

**A) Minimal Python example (zip)**

`app.py`

```python
import json
def handler(event, context):
    return {"statusCode": 200, "body": json.dumps({"ok": True})}
```

Zip & create:

```bash
zip function.zip app.py
aws lambda create-function \
  --function-name hello-lambda \
  --runtime python3.11 \
  --handler app.handler \
  --zip-file fileb://function.zip \
  --role arn:aws:iam::<ACCOUNT_ID>:role/lambda-exec-role
```

Invoke test:

```bash
aws lambda invoke --function-name hello-lambda out.json
cat out.json
```

**B) Add an EventBridge (CloudWatch Events) schedule**

```bash
aws events put-rule --name nightly-job --schedule-expression "rate(1 day)"
aws lambda add-permission \
  --function-name hello-lambda \
  --statement-id ev-perm \
  --action lambda:InvokeFunction \
  --principal events.amazonaws.com \
  --source-arn arn:aws:events:us-east-1:<ACCOUNT_ID>:rule/nightly-job
aws events put-targets \
  --rule nightly-job \
  --targets "Id"="1","Arn"="$(aws lambda get-function --function-name hello-lambda --query 'Configuration.FunctionArn' --output text)"
```

**C) Wire to S3 (object-created)** — console: S3 → Properties → Event notifications → Add → Destination = Lambda.

</details>

---

<details>
<summary><strong>12. IaC Snapshot (CloudFormation YAML)</strong></summary>

```yaml
Resources:
  LambdaExecRole:
    Type: AWS::IAM::Role
    Properties:
      AssumeRolePolicyDocument:
        Version: "2012-10-17"
        Statement:
          - Effect: Allow
            Principal: { Service: lambda.amazonaws.com }
            Action: sts:AssumeRole
      Policies:
        - PolicyName: cw-logs
          PolicyDocument:
            Version: "2012-10-17"
            Statement:
              - Effect: Allow
                Action:
                  - logs:CreateLogGroup
                  - logs:CreateLogStream
                  - logs:PutLogEvents
                Resource: "*"

  HelloLambda:
    Type: AWS::Lambda::Function
    Properties:
      FunctionName: hello-lambda
      Handler: app.handler
      Runtime: python3.11
      Role: !GetAtt LambdaExecRole.Arn
      Code:
        ZipFile: |
          import json
          def handler(event, context):
              return {"statusCode": 200, "body": json.dumps({"ok": True})}

  NightlyRule:
    Type: AWS::Events::Rule
    Properties:
      ScheduleExpression: rate(1 day)
      Targets:
        - Arn: !GetAtt HelloLambda.Arn
          Id: t1

  PermissionForEventsToInvoke:
    Type: AWS::Lambda::Permission
    Properties:
      FunctionName: !Ref HelloLambda
      Action: lambda:InvokeFunction
      Principal: events.amazonaws.com
      SourceArn: !GetAtt NightlyRule.Arn
```

</details>

---

<details>
<summary><strong>13. Architectures & Diagrams</strong></summary>

**A) S3 Thumbnail Pipeline**

```
S3 (upload) ──event──► Lambda (resize) ──► S3 /thumbnails
                            │
                            └─ logs ► CloudWatch Logs
```

**B) Serverless API Backend**

```
Client ► API Gateway (REST/HTTP) ► Lambda ► DynamoDB
                  │
                  └─ logs/metrics ► CloudWatch
```

**C) Scheduled Ops Task**

```
EventBridge (rate/cron) ► Lambda ► (EC2/RDS/Cost Explorer APIs)
```

**D) Async Worker with DLQ**

```
Producer ► SQS Queue ► Lambda (process)
                      ├─ on-failure ► SQS DLQ
                      └─ metrics/logs ► CloudWatch
```

**E) VPC-Attached Lambda**

```
Lambda (ENI in Private Subnet) ► RDS
      │
      └─ NAT Gateway ► Internet (patching, APIs)
```

</details>

---

<details>
<summary><strong>14. Best Practices (Prod-Ready)</strong></summary>

* **Keep it stateless**; reuse SDK clients outside the handler.
* **Least-privilege IAM** per function; separate roles.
* **Timeouts** aligned with upstreams; fail fast + idempotency keys.
* **Retries & DLQ/Destinations** for async invocations.
* **Instrument** with structured logs + metrics; enable **Lambda Insights**.
* **Control concurrency** (Reserved) for backends with limits; consider **Provisioned** for low-latency APIs.
* **Small packages** (or **Layers**) to reduce cold starts.
* **VPC only when needed**; ensure NAT for egress; watch ENI limits.
* **Use Aliases** for safe deploys (blue/green, canary).
* **Test locally** (SAM/LocalStack) and deploy IaC (SAM/CDK/CFN/Terraform).

</details>

---

<details>
<summary><strong>15. Pricing & Cost Controls</strong></summary>

* **Charges:** Requests + GB-seconds (memory × duration) + optional provisioned concurrency + networking.
* **Cut cost:** Right-size memory, trim duration, batch work via SQS, aggregate metrics, avoid unnecessary VPC (ENI init time + potential egress).
* **Monitor:** `Duration`, `BilledDuration`, `Invocations`, `Errors`, `Throttles`, `IteratorAge`.

</details>

---

<details>
<summary><strong>16. Quick Summary</strong></summary>

* Lambda = **event-driven, fully-managed compute**.
* Triggers from **API Gateway, S3, SQS, EventBridge, DynamoDB Streams, SNS**.
* **Stateless**, scales automatically; watch **concurrency** and **cold starts**.
* **CloudWatch** for logs/metrics; **DLQ/Destinations** for robustness.
* **IaC** everything; deploy with **versions/aliases**; keep costs in check.

</details>

---

<details>
<summary><strong>17. Self-Audit Checklist</strong></summary>

* [ ] I can explain Lambda’s execution lifecycle and cold starts.
* [ ] I can choose the right trigger (API vs S3 vs SQS vs EventBridge).
* [ ] I configured IAM **execution role** with least privilege.
* [ ] I know when to use **Reserved** vs **Provisioned** concurrency.
* [ ] I can route async failures to **DLQ/Destinations**.
* [ ] I can deploy via **CloudFormation/SAM/CDK** with **versions** and **aliases**.
* [ ] I understand the **VPC trade-offs** and NAT requirement.
* [ ] I can estimate Lambda **cost** and reduce it.

</details>

Perfect — below is your **ready-to-paste Markdown block** containing **both gold-standard tables** (🏡 Compute Models Analogy + 💰 Cost Comparison) and a **simple ASCII cost-curve diagram** that fits beautifully into your `Lambda.md`.
You can drop it right under your “Quick Summary” section or wherever you introduce cross-compute comparisons.

---

## 🏡 Compute Models Analogy – EC2 vs Beanstalk vs Lambda

> **All three run your code — they just differ in how much of the “house” you manage.**

| Model | Analogy | Responsibility | Ideal For |
|:--|:--|:--|:--|
| **EC2** | 🏠 **Your Own House** — you buy the land, build the structure, choose every detail, and maintain it yourself. | You manage **everything**: operating system, security updates, scaling, backups, patching. | When you need full control: custom environments, legacy apps, or workloads that run 24/7. |
| **Elastic Beanstalk** | 🏢 **Serviced Apartment** — the building, power, and maintenance are handled; you furnish the rooms and live comfortably. | AWS manages servers, load balancers, scaling, and health checks. You manage your **application code and configs**. | Standard web or API apps that need scalability without infra headaches. |
| **Lambda** | 🏨 **Hotel Room on Demand** — you arrive, use it briefly, and leave. You pay only for the nights you stay. | AWS manages **everything** — servers, scaling, runtime, and cleanup. You only bring the code. | Event-driven, short-lived, stateless workloads (file processing, automation, microservices). |

---

### 🧭 One-Line Rule of Thumb

| Question | Choose |
|-----------|---------|
| “Do I need full OS control?” → | **EC2** |
| “Do I just want AWS to host my web app?” → | **Elastic Beanstalk** |
| “Do I only need code to run on events?” → | **Lambda** |

---

### ⚙️ Architectural Insight
All three live on the same AWS compute backbone:

```

EC2  →  Base Infrastructure Layer (IaaS)
│
├─ Elastic Beanstalk → Managed PaaS using EC2, ALB, Auto Scaling under the hood
│
└─ Lambda → Fully Serverless FaaS running on abstracted EC2 fleets

```

> The higher you go, the **less infrastructure you manage** and the **faster you can deliver** — but the **less customization** you have.

---

## 💰 Cost Comparison – EC2 vs Beanstalk vs Lambda  

> **All three can run the same app — but the way AWS bills you changes drastically.**

| Aspect | **EC2 (IaaS)** | **Elastic Beanstalk (PaaS)** | **Lambda (FaaS)** |
|:--|:--|:--|:--|
| **Billing Unit** | **Uptime (hours/seconds)** of running instances. | Same as EC2 + extra resources (ALB, EBS, RDS if attached). | **Per request + execution time (GB-seconds)**. |
| **Idle Cost** | Charged even when idle. | Charged while environment runs (EC2s always on). | $0 when idle – no invocations = no cost. |
| **Startup Overhead** | Instance launch time billed immediately. | Small Beanstalk setup + EC2 runtime. | None – only execution time (100 ms blocks). |
| **Included Resources** | EC2 CPU, RAM, EBS, data transfer. | EC2 instances, ALB, Auto Scaling, EBS. | Memory (128 MB–10 GB), vCPU proportionally, + invocation count. |
| **Scaling Behavior** | Pay for each instance 24×7. | Pay for the EC2 fleet Beanstalk creates. | Pay only for executions – auto-scales instantly. |
| **Free Tier** | 750 hrs t2.micro (12 mo). | Uses EC2 Free Tier if within limits. | 1 M requests + 400 k GB-seconds (always free). |
| **Cost Predictability** | Stable for steady load. | Medium – depends on autoscaling. | Variable – depends on events + duration. |
| **Optimization Levers** | Right-size, Spot, Savings Plans. | Same + turn off idle envs. | Optimize memory/duration, batch events, limit provisioned concurrency. |
| **Example Monthly Cost** | 2 × t3.medium 24×7 ≈ $60–70 | EC2 + ALB ≈ $80+ | 2 M invocations (256 MB, 200 ms) ≈ <$1 |

---

### 🧮 How AWS Bills in Practice
1. **EC2 / Beanstalk = time-based** → pay for infrastructure uptime.  
2. **Lambda = usage-based** → pay only for execution time + requests.  
3. **Crossover Point** → if code runs continuously, EC2 is cheaper; if sporadic, Lambda wins.

---

### 📉 Cost Curve – Abstraction vs Idle Cost vs Request Cost

```

Cost ↑
│        EC2 ────── fixed monthly cost (always on)
│           
│            
│             \       Elastic Beanstalk (auto-scale but still EC2-based)
│              
│               
│                __________ Lambda (pay-per-request only)
│
└──────────────────────────────────────────────► Usage / Requests

```

> The higher the abstraction, the **lower your idle cost** and the **higher your per-use precision** —  
> AWS shifts the billing model from *infrastructure ownership* → *platform usage* → *function execution*.
```
---
# TOOL: 08. AWS – Cloud Infrastructure | FILE: 12-elastic-beanstalk
---

[Home](../README.md) | 
[Intro to AWS](../01-intro-aws/README.md) | 
[IAM](../02-iam/README.md) | 
[VPC & Subnet](../03-vpc-subnet/README.md) | 
[EBS](../04-ebs/README.md) | 
[EFS](../05-efs/README.md) | 
[S3](../06-s3/README.md) | 
[EC2](../07-ec2/README.md) | 
[RDS](../08-rds/README.md) | 
[Load Balancing & Auto Scaling](../09-Load-balancing-auto-scaling/README.md) | 
[CloudWatch & SNS](../10-cloudwatch-sns/README.md) | 
[Lambda](../11-lambda/README.md) | 
[Elastic Beanstalk](../12-elastic-beanstalk/README.md) | 
[Route 53](../13-route53/README.md) | 
[CLI + CloudFormation](../14-cli-cloudformation/README.md)

# AWS Elastic Beanstalk  

## Table of Contents  
1. [Why do we need Elastic Beanstalk?](#1)  
2. [The Problem Without Beanstalk](#2)  
3. [Solution – What Beanstalk Does](#3)  
4. [Benefits](#4)  
5. [Architecture Diagram](#5)  
6. [Theory & Notes](#6)  
7. [Real Examples](#7)  
8. [Practical Use Cases](#8)  
9. [Quick Command Summary](#9)  

---

<details>
<summary><strong>1. Why do we need Elastic Beanstalk?</strong></summary>

Deploying an application manually involves:
- Launching EC2 instances  
- Setting up Load Balancer and Auto Scaling  
- Managing IAM roles, networking, and health checks  
- Configuring CloudWatch metrics  

This takes time, effort, and introduces room for error.  

**Elastic Beanstalk (EB)** automates all of this — you just upload your code, and AWS handles provisioning, deployment, scaling, and monitoring.

</details>

---

<details>
<summary><strong>2. The Problem Without Beanstalk</strong></summary>

Without Beanstalk, developers must:  
1. Launch EC2 and install web servers manually  
2. Attach and configure a Load Balancer  
3. Create Auto Scaling Groups and set policies  
4. Manually upload and update code  
5. Configure CloudWatch alarms and logging  

Each of these pieces requires coordination and monitoring.  
Maintaining consistency across environments (dev, staging, prod) becomes difficult.

</details>

---

<details>
<summary><strong>3. Solution – What Beanstalk Does</strong></summary>

Elastic Beanstalk is a **Platform-as-a-Service (PaaS)** that automates environment setup and management.

You upload your application bundle (ZIP / Git repo).  
Beanstalk automatically:  
- Provisions EC2, ALB, and Auto Scaling Groups  
- Configures networking, IAM, and security groups  
- Stores versions in S3  
- Monitors health using CloudWatch  
- Handles rolling updates and rollback on failure  

You still retain **full access** to all underlying AWS resources.   
   
**Service Type:** Platform as a Service (PaaS)      
**Comparison of Cloud Service Models**   
| Model | Full Form | Example AWS Services | Responsibility |
|--------|------------|----------------------|----------------|
| IaaS | Infrastructure as a Service | EC2, VPC, S3, RDS | You manage OS, runtime, app |
| PaaS | Platform as a Service | Elastic Beanstalk | AWS manages infra, you manage code |
| SaaS | Software as a Service | Zoom, Google Meet | AWS/vendor manages everything |

   
<img src="images/service-control.jpg" alt="Elastic Beanstalk Architecture Overview" width="600" height="375" />

</details>

---

<details>
<summary><strong>4. Benefits</strong></summary>

| Benefit | Description |
|----------|-------------|
| **Fast Deployment** | Launch production-ready environments in minutes |
| **Managed Scaling** | Auto Scaling adjusts capacity automatically |
| **Built-in Monitoring** | Health integrated with CloudWatch |
| **Multi-Language Support** | Node.js, Python, Java, Go, PHP, .NET, Docker |
| **Version Control** | Keeps multiple app versions in S3 |
| **Full Control** | Developers can modify EC2, ALB, or configs anytime |
   
**💰 Pricing:** There’s no extra cost for using Elastic Beanstalk itself. You only pay for the underlying resources (like EC2, S3, and RDS) it provisions.  

</details>

---

<details>
<summary><strong>5. Architecture Diagram</strong></summary>

```

┌──────────────────────────────────────────────┐
│              Elastic Beanstalk               │
│                                              │
│   ┌──────────────────────────────────────┐   │
│   │ Environment (e.g., Prod / Dev)       │   │
│   │ ├─ EC2 Instances (App servers)       │   │
│   │ ├─ Load Balancer (ALB)               │   │
│   │ ├─ Auto Scaling Group                │   │
│   │ ├─ CloudWatch (Monitoring)           │   │
│   │ ├─ S3 (App Versions)                 │   │
│   │ └─ Optional: RDS for DB              │   │
│   └──────────────────────────────────────┘   │
└──────────────────────────────────────────────┘

```

**Flow:**  
Upload Code → Beanstalk Creates Environment → Deploy → Monitor → Scale  

</details>

---

<details>
<summary><strong>6. Theory & Notes</strong></summary>

| Concept | Meaning | Example |
|----------|----------|----------|
| **Application** | Logical container for versions & environments | `my-web-app` |
| **Environment** | Running instance of the app | `my-web-app-prod` |
| **Application Version** | Specific build stored in S3 | `v1`, `v2` |
| **Tier** | Defines workload type | *Web Server* (HTTP) or *Worker* (SQS) |
| **Platform** | Runtime stack | `Python 3.11 on Amazon Linux 2023` |
| **Configuration Files** | `.ebextensions/*.config` customize settings | instance type = `t3.micro` |   
   

Example configuration file:

```yaml
option_settings:
  aws:autoscaling:launchconfiguration:
    InstanceType: t3.micro
  aws:elasticbeanstalk:application:environment:
    DJANGO_DEBUG: false
```

</details>

---

<details>
<summary><strong>7. Real Examples</strong></summary>
     
# Step 1: Create IAM Role
Policies to attach:
- AWSElasticBeanStalkWebTier
- AWSElasticBeanStalkWorkerTier
- AWSElasticBeanStalkMulticontainerDocker

# Step 2: Create Application
eb init my-app --platform "Python 3.11" --region us-east-1

# Step 3: Create Environment
eb create my-app-env
   
**Example 1 – Deploy a Node.js App**

```
eb init my-node-app --platform node.js --region us-east-1
eb create my-node-env
eb deploy
eb open
```

**Example 2 – Monitor and Check Logs**

```bash
eb health
eb logs
```

```
Environment health: Green
Instances running: 3
Load Balancer: Healthy
```

**Example 3 – Scale or Terminate**

```bash
eb scale 3
eb terminate
```

</details>

---

<details>
<summary><strong>8. Practical Use Cases</strong></summary>
     
| Use Case                      | Description                               |
| ----------------------------- | ----------------------------------------- |
| **Deploy Web Apps Quickly**   | Launch a full stack in minutes            |
| **Test / Stage Environments** | Separate dev, staging, prod workflows     |
| **CI/CD Integration**         | Connect to CodePipeline or GitHub Actions |
| **Auto Scaling Demo**         | Observe traffic-based scaling             |
| **Legacy App Migration**      | Host .NET / Java apps easily              |
  
</details>

---

<details>
<summary><strong>9. Quick Command Summary</strong></summary>

| Command        | Full Form                    | Purpose                   |
| -------------- | ---------------------------- | ------------------------- |
| `eb init`      | Initialize Beanstalk project | Sets up app & region      |
| `eb create`    | Create new environment       | Provisions EC2, ALB, ASG  |
| `eb deploy`    | Deploy latest version        | Uploads ZIP → S3 → deploy |
| `eb open`      | Open app URL in browser      | Quick access              |
| `eb status`    | Check environment status     | Health + version          |
| `eb health`    | View health details          | Instance status           |
| `eb logs`      | Get application logs         | Debug issues              |
| `eb terminate` | Delete environment           | Clean resource removal    |

---

**AWS Flow Connection**
`IAM → VPC → EBS → S3 → EC2 → RDS → Load Balancer → Auto Scaling → CloudWatch → Lambda → Elastic Beanstalk → Route 53 → CloudFormation`

Elastic Beanstalk is the **automation layer** that ties these services together for friction-free deployments.

---

**📘 TL;DR Summary**

**Elastic Beanstalk = “Upload Code → AWS Does the Rest.”**
It manages EC2, Load Balancer, Auto Scaling, and CloudWatch automatically —
giving you developer-speed with architect-level control.

---

<details>
<summary><strong>⚙️ Mini Comparison – Beanstalk vs Lambda vs CloudFormation</strong></summary>

| Service | Type | Purpose | When to Use | Key Benefit |
|----------|------|----------|--------------|--------------|
| **Elastic Beanstalk** | PaaS (Platform as a Service) | Deploy and manage full applications automatically (EC2 + ALB + ASG + CloudWatch) | You want to focus on *code*, not infrastructure | “One-click” deployment with control over AWS resources |
| **AWS Lambda** | FaaS (Function as a Service) | Run functions without servers — event-driven code execution | You want to run lightweight, short-lived tasks | No servers to manage, pay-per-execution |
| **CloudFormation** | IaC (Infrastructure as Code) | Define and provision AWS resources using templates | You need reproducible, automated environments | Full automation and version control for infra setup |

**In Short:**  
- **Lambda →** small code tasks (serverless logic).  
- **Beanstalk →** full-stack web apps (managed environments).  
- **CloudFormation →** infrastructure automation (templates and IaC).

</details>

---
---
# TOOL: 08. AWS – Cloud Infrastructure | FILE: 13-route53
---

[Home](../README.md) | 
[Intro to AWS](../01-intro-aws/README.md) | 
[IAM](../02-iam/README.md) | 
[VPC & Subnet](../03-vpc-subnet/README.md) | 
[EBS](../04-ebs/README.md) | 
[EFS](../05-efs/README.md) | 
[S3](../06-s3/README.md) | 
[EC2](../07-ec2/README.md) | 
[RDS](../08-rds/README.md) | 
[Load Balancing & Auto Scaling](../09-Load-balancing-auto-scaling/README.md) | 
[CloudWatch & SNS](../10-cloudwatch-sns/README.md) | 
[Lambda](../11-lambda/README.md) | 
[Elastic Beanstalk](../12-elastic-beanstalk/README.md) | 
[Route 53](../13-route53/README.md) | 
[CLI + CloudFormation](../14-cli-cloudformation/README.md)

# AWS Route 53 — The Global Gateway of Your Architecture

> **Phase 6 – Networking & DNS Gateway**
> *“If IAM decides who, and VPC decides where, Route 53 decides how the world finds you.”*

---

## Table of Contents

1. [Why We Need Route 53](#1-why-we-need-route-53)
2. [Analogy – The AWS Postal System](#2-analogy--the-aws-postal-system)
3. [The Problem Without Route 53](#3-the-problem-without-route-53)
4. [The Solution – Global DNS Network](#4-the-solution--global-dns-network)
5. [Core Concepts](#5-core-concepts)
6. [Architecture Blueprint – Instructor Diagram](#6-architecture-blueprint--instructor-diagram)
7. [Deep Theory – Records & Routing Policies](#7-deep-theory--records--routing-policies)
8. [Real-World Examples](#8-real-world-examples)
9. [Practical Use Cases](#9-practical-use-cases)
10. [Quick Summary](#10-quick-summary)
11. [Self-Audit Checklist](#11-self-audit-checklist)

---

<details>
<summary><strong>1. Why We Need Route 53</strong></summary>

Every system eventually asks: **how do users reach it?**
Humans remember names like `webstore.com`; machines only understand IPs.

**AWS Route 53** is a globally distributed **Domain Name System (DNS)** service that resolves those names to IPs and directs users to the closest, healthiest endpoint (ALB, EC2, or S3).

It’s not merely a directory — it’s an intelligent **traffic controller** ensuring every request finds the right door, fast.

</details>

---

<details>
<summary><strong>2. Analogy – The AWS Postal System</strong></summary>

| AWS Concept        | Real-World Equivalent      | Role                              |
| ------------------ | -------------------------- | --------------------------------- |
| **Route 53**       | 🌍 National Postal Network | Knows every delivery path         |
| **Hosted Zone**    | 🏣 Local Post Office       | Manages mail for one domain       |
| **DNS Record**     | ✉️ Address Label           | Tells where to deliver            |
| **Routing Policy** | 🚚 Delivery Rule           | Chooses best path                 |
| **Health Check**   | 👷 Postal Inspector        | Confirms route is open            |
| **TTL**            | 🕐 Stamp Validity          | How long others reuse the address |

When someone types your domain, Route 53:

1. Reads the label (record).
2. Chooses the best route (policy + health check).
3. Delivers the request to the correct AWS building (ALB → EC2 → RDS/EFS).

</details>

---

<details>
<summary><strong>3. The Problem Without Route 53</strong></summary>

Without Route 53:

* You manually update IPs when ALB/EC2 changes.
* No health checks → downtime for users.
* Latency rises as queries travel globally.
* IaC automation becomes fragile.

**Bottom line:** users can’t reliably find your app.

</details>

---

<details>
<summary><strong>4. The Solution – Global DNS Network</strong></summary>

AWS Route 53 operates hundreds of edge DNS servers worldwide.
Each query is answered by the nearest healthy server for low latency and automatic failover.

**Flow**

1. User enters domain.
2. Nearest edge server resolves request.
3. Looks up record in Hosted Zone.
4. Applies Routing Policy and returns target (ALB DNS).
5. Browser connects to ALB → EC2 → RDS/EFS.

**Strengths**

* High availability.
* Latency-based routing.
* Health-aware failover.
* Tight AWS integration + IaC support.

</details>

---

<details>
<summary><strong>5. Core Concepts</strong></summary>

| Concept            | Description                                       | Analogy           |
| ------------------ | ------------------------------------------------- | ----------------- |
| **Domain Name**    | Human-readable address (`webstore.com`) | Name on envelope  |
| **Hosted Zone**    | Container for records                             | Local Post Office |
| **Record Set**     | Name → target mapping                             | Address Label     |
| **Routing Policy** | Decides which target to return                    | Delivery Rule     |
| **Health Check**   | Tests availability                                | Route Inspector   |
| **TTL**            | Cache duration                                    | Stamp Validity    |

</details>

---

<details>
<summary><strong>6. Architecture Blueprint – Instructor Diagram</strong></summary>

```
                     User / Browser
                           │
                           ▼
                     AWS Route 53
                 (Global DNS Resolution)
                           │
                           ▼
                   Internet Gateway (IGW)
                           │
                           ▼
             Application Load Balancer (ALB)
                     (Public Subnet)
                           │
                           ▼
                EC2 / Beanstalk Instances
                     (Private Subnet)
                           │
                           ▼
              ┌────────────┴────────────┐
              │                         │
           Amazon RDS             Amazon EFS
           (Database)            (File Storage)
```

**Flow Summary**

1. User types domain → Route 53 resolves to ALB DNS.
2. Traffic enters via IGW → ALB (public).
3. ALB routes to EC2/Beanstalk (private).
4. Instances communicate internally with RDS/EFS.

</details>

---

<details>
<summary><strong>7. Deep Theory – Records & Routing Policies</strong></summary>

### 7.1 Record Types

| Type    | Purpose                 | Example                        |
| ------- | ----------------------- | ------------------------------ |
| A       | Name → IPv4             | `@ → 54.231.10.45`             |
| AAAA    | Name → IPv6             | `@ → 2600:1f16::45`            |
| CNAME   | Alias → another domain  | `www → example.com`            |
| MX      | Mail routing            | `10 mail.google.com`           |
| TXT     | Metadata / Verification | `google-site-verification=abc` |
| Alias A | Direct AWS target       | `@ → ALB/S3`                   |

### 7.2 Routing Policies

| Policy        | Function                 | When to Use  |
| ------------- | ------------------------ | ------------ |
| Simple        | Single IP                | Static apps  |
| Weighted      | Split traffic by percent | A/B tests    |
| Latency-Based | Closest region           | Global apps  |
| Failover      | Backup target            | DR scenarios |
| Geolocation   | By user region           | Compliance   |
| Multi-Value   | Multiple healthy IPs     | Redundancy   |

**Failover Visual**

```
User
 ├─► Primary (ALB – Healthy)
 └─► Secondary (ALB – Failover)
```

**Latency Visual**

```
EU User → EU Endpoint
US User → US Endpoint
APAC User → Asia Endpoint
```

</details>

---

<details>
<summary><strong>8. Real-World Examples</strong></summary>

**Example 1 – Domain → ALB**
Hosted Zone + Alias A record → ALB DNS → EC2/Beanstalk.

**Example 2 – Static Site on S3**
Enable hosting → Alias A record → S3 endpoint.

**Example 3 – HTTPS Validation**
ACM DNS validation adds TXT record via Route 53.

**Example 4 – Failover**
us-east-1 primary, eu-west-1 secondary → automatic switch.

**Example 5 – IaC**
Manage zones and records via CloudFormation or Terraform.

</details>

---

<details>
<summary><strong>9. Practical Use Cases</strong></summary>

| Scenario               | Route 53 Feature         |
| ---------------------- | ------------------------ |
| Blue/Green Deployments | Weighted Routing         |
| Global User Latency    | Latency-Based Routing    |
| Disaster Recovery      | Failover + Health Checks |
| Regional Compliance    | Geolocation Routing      |
| Simple Redundancy      | Multi-Value Answer       |
| Public Web Hosting     | Alias A → ALB/S3         |

</details>

---

<details>
<summary><strong>10. Quick Summary</strong></summary>

| Area             | Key Points                                                                       |
| ---------------- | -------------------------------------------------------------------------------- |
| **Purpose**      | Authoritative DNS for your domains — resolves names with policy and health logic |
| **Strengths**    | Global, automated, AWS-integrated                                                |
| **Integrations** | ALB, S3, CloudFront, ACM, Terraform                                              |
| **Cost**         | ≈ $0.50/zone + $0.40/M queries (+ health checks)                                 |
| **Defaults**     | Alias A for AWS targets; TTL ≈ 300 s                                             |

</details>

---

<details>
<summary><strong>11. Self-Audit Checklist</strong></summary>

* [ ] I can describe DNS resolution via Route 53.
* [ ] I can link a domain → ALB/S3 using Alias A.
* [ ] I understand Weighted, Latency, and Failover policies.
* [ ] I can configure Health Checks.
* [ ] I can validate ACM certificates through Route 53.
* [ ] I can create zones and records in Terraform/CloudFormation.
* [ ] I can estimate hosted-zone and query costs.

</details>

---

### 💡 Mentor Insight

Every AWS architecture needs a dependable doorway.
**Route 53 is that door — a global, fault-tolerant, policy-driven DNS layer that lets the world find your cloud infrastructure without ever getting lost.**

---
---
# TOOL: 08. AWS – Cloud Infrastructure | FILE: 14-cli-cloudformation
---

[Home](../README.md) | 
[Intro to AWS](../01-intro-aws/README.md) | 
[IAM](../02-iam/README.md) | 
[VPC & Subnet](../03-vpc-subnet/README.md) | 
[EBS](../04-ebs/README.md) | 
[EFS](../05-efs/README.md) | 
[S3](../06-s3/README.md) | 
[EC2](../07-ec2/README.md) | 
[RDS](../08-rds/README.md) | 
[Load Balancing & Auto Scaling](../09-Load-balancing-auto-scaling/README.md) | 
[CloudWatch & SNS](../10-cloudwatch-sns/README.md) | 
[Lambda](../11-lambda/README.md) | 
[Elastic Beanstalk](../12-elastic-beanstalk/README.md) | 
[Route 53](../13-route53/README.md) | 
[CLI + CloudFormation](../14-cli-cloudformation/README.md)

# **AWS CLI + CloudFormation — From Manual Commands to Code-Driven Infrastructure**

> *“If the Console is your control panel, AWS CLI is the steering wheel — and CloudFormation is the autopilot that remembers every turn.”*
> Together, they form the **automation backbone** of your AWS ecosystem — bridging manual control with Infrastructure as Code.

---

## **Table of Contents**

1. [Why Automation Matters](#1-why-automation-matters)
2. [Analogy – Driver & Autopilot](#2-analogy--driver--autopilot)
3. [The Problem Without Automation](#3-the-problem-without-automation)
4. [AWS CLI – Your Command-Line Bridge](#4-aws-cli--your-command-line-bridge)
5. [CloudFormation – Your Infrastructure Engine](#5-cloudformation--your-infrastructure-engine)
6. [Architecture Blueprint – Automation Flow](#6-architecture-blueprint--automation-flow)
7. [Template Deep Dive – Webstore EC2 Stack (YAML Example)](#7-template-deep-dive--webstore-ec2-stack-yaml-example)
8. [Real-World Use Cases & Best Practices](#8-real-world-use-cases--best-practices)
9. [Quick Summary & Self-Audit](#9-quick-summary--self-audit)
10. [💡 Mentor Insight](#10-mentor-insight)

---

<details>
<summary><strong>1. Why Automation Matters</strong></summary>

Manual provisioning through the console is fine for exploration — but it doesn’t scale.
When every instance, bucket, or network must be created consistently across environments, **automation becomes survival**.

Automation:

* Removes human error
* Enforces repeatability
* Enables disaster recovery
* Saves time in testing, labs, and CI/CD

In AWS, **CLI** gives command-level control; **CloudFormation** codifies entire infrastructures.
They’re two sides of the same efficiency coin.

</details>

---

<details>
<summary><strong>2. Analogy – Driver & Autopilot</strong></summary>

| Tool               | Analogy        | Role                                                         |
| ------------------ | -------------- | ------------------------------------------------------------ |
| **AWS Console**    | Manual driving | Visual, one-at-a-time actions                                |
| **AWS CLI**        | Steering wheel | Command-based control over services                          |
| **CloudFormation** | Autopilot      | Reads a flight plan (YAML/JSON) and provisions automatically |

You first learn to **drive manually** (CLI) — steering each service yourself —
then you let **autopilot (CloudFormation)** fly the same route flawlessly every time.

</details>

---

<details>
<summary><strong>3. The Problem Without Automation</strong></summary>

Imagine decorating a house without writing anything down.
A few months later, you move rooms around — but you forget which switch turns on which light.
That’s what happens when you **manage AWS by hand** using only the Console.

Without CLI or CloudFormation:

* You forget what settings you used before.
* Two teammates set up things differently.
* Fixing or recreating something takes hours.
* A simple mistake (like wrong region or subnet) breaks everything.

Automation is your **blueprint and memory**.
It ensures every server, bucket, and network can be rebuilt exactly the same way — anywhere, anytime, by anyone.

> “Manual setup is like cooking without a recipe.
> Automation is the cookbook that guarantees the same flavor every time.”

</details>

---

<details>
<summary><strong>4. AWS CLI – Your Command-Line Bridge</strong></summary>

**🧱 Installing AWS CLI (Mac, Windows, Linux)**

**For Mac (recommended):**

```bash
brew install awscli
```

or use the official pkg:

```bash
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
sudo installer -pkg AWSCLIV2.pkg -target /
```

**For Windows:**
Download → [AWSCLIV2.msi](https://awscli.amazonaws.com/AWSCLIV2.msi)

**For Linux:**

```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

**Verify installation:**

```bash
aws --version
```

---

### ⚙️ Configure Once

```bash
aws configure
```

You’ll be asked for:

* Access Key ID
* Secret Key
* Default region (e.g., `us-east-1`)
* Output format (`json`, `table`, `text`)

After setup, your credentials are stored safely under `~/.aws/credentials`.

---

### 🧩 Grand Table — Everyday AWS CLI Commands for DevOps Engineers

| Service                     | Task                          | Command                                                                                                                                                                                      | What It Does                               |
| --------------------------- | ----------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------ |
| **General**                 | Show current profile & region | `aws configure list`                                                                                                                                                                         | Confirms which account/region you’re using |
|                             | Switch region temporarily     | `aws ec2 describe-instances --region us-west-2`                                                                                                                                              | Overrides default                          |
| **S3 (Storage)**            | List buckets                  | `aws s3 ls`                                                                                                                                                                                  | Shows all buckets                          |
|                             | Create bucket                 | `aws s3 mb s3://webstore-demo`                                                                                                                                                              | Makes a new S3 bucket                      |
|                             | Upload file                   | `aws s3 cp index.html s3://webstore-demo/`                                                                                                                                                  | Uploads a file                             |
|                             | Sync folders                  | `aws s3 sync ./website s3://webstore-demo`                                                                                                                                                  | Mirrors local → S3                         |
|                             | Delete bucket                 | `aws s3 rb s3://webstore-demo --force`                                                                                                                                                      | Removes everything inside                  |
| **EC2 (Compute)**           | List instances                | `aws ec2 describe-instances`                                                                                                                                                                 | View running/stopped servers               |
|                             | Start instance                | `aws ec2 start-instances --instance-ids i-1234abcd`                                                                                                                                          | Boot up                                    |
|                             | Stop instance                 | `aws ec2 stop-instances --instance-ids i-1234abcd`                                                                                                                                           | Shut down                                  |
|                             | Reboot instance               | `aws ec2 reboot-instances --instance-ids i-1234abcd`                                                                                                                                         | Restart                                    |
|                             | Create key pair               | `aws ec2 create-key-pair --key-name myKey > myKey.pem`                                                                                                                                       | New SSH key                                |
| **IAM (Access)**            | List users                    | `aws iam list-users`                                                                                                                                                                         | Show all users                             |
|                             | Create user                   | `aws iam create-user --user-name devuser`                                                                                                                                                    | Adds IAM user                              |
|                             | Attach policy                 | `aws iam attach-user-policy --user-name devuser --policy-arn arn:aws:iam::aws:policy/AdministratorAccess`                                                                                    | Grants access                              |
| **CloudWatch (Monitoring)** | List metrics                  | `aws cloudwatch list-metrics`                                                                                                                                                                | Shows what’s being tracked                 |
|                             | Get CPU stats                 | `aws cloudwatch get-metric-statistics --metric-name CPUUtilization --namespace AWS/EC2 --start-time 2025-11-10T00:00:00Z --end-time 2025-11-11T00:00:00Z --period 3600 --statistics Average` | View CPU usage                             |
| **Lambda (Serverless)**     | List functions                | `aws lambda list-functions`                                                                                                                                                                  | Show deployed functions                    |
|                             | Invoke function               | `aws lambda invoke --function-name myFunction out.json`                                                                                                                                      | Run function manually                      |
| **CloudFormation (IaC)**    | List stacks                   | `aws cloudformation list-stacks`                                                                                                                                                             | View deployed stacks                       |
|                             | Validate template             | `aws cloudformation validate-template --template-body file://template.yml`                                                                                                                   | Check YAML before deploying                |
|                             | Create stack                  | `aws cloudformation create-stack --stack-name MyStack --template-body file://template.yml`                                                                                                   | Deploy infra                               |
|                             | Delete stack                  | `aws cloudformation delete-stack --stack-name MyStack`                                                                                                                                       | Tear down infra                            |
| **Misc Tools**              | Get caller identity           | `aws sts get-caller-identity`                                                                                                                                                                | Confirms which user/account is active      |
|                             | Get service help              | `aws s3 help`                                                                                                                                                                                | Shows CLI options for that service         |

> 💡 Tip: Bookmark this table — it’s a “cloud survival sheet” for everyday DevOps work.

---

### 🧠 When & Why to Use AWS CLI

Think of the **AWS CLI** as your **Swiss Army knife** for cloud work — small, fast, and available everywhere.

You use it when:

* You need to **check the health** of servers.
* You want to **move files** to or from S3 quickly.
* You must **start, stop, or reboot** EC2 instances.
* You’re writing small **scripts or cron jobs** that talk to AWS automatically.
* You want to **verify** what CloudFormation deployed.

> The Console shows you *what exists*.
> The CLI lets you *command it directly.*

</details>

---

<details>
<summary><strong>5. CloudFormation – Your Infrastructure Engine</strong></summary>

---

### 🧭 What It Does

CloudFormation turns human-readable templates (YAML/JSON) into live AWS resources — EC2, S3, VPC, IAM roles, everything.

You write **what you want**, AWS figures out **how to build it**.

---

### 🧱 Core Concepts

| Term           | Meaning                             |
| -------------- | ----------------------------------- |
| **Template**   | Blueprint file describing resources |
| **Stack**      | Deployed instance of a template     |
| **Change Set** | Preview before applying changes     |
| **Parameters** | Input values to reuse templates     |
| **Outputs**    | Key data exported to other stacks   |

---

### ⚙️ Workflow

1. **Write Template**
2. **Upload** (local or S3)
3. **Create Stack**

   ```bash
   aws cloudformation create-stack --stack-name WebstoreEC2Stack \
       --template-body file://webstore-ec2.yml
   ```
4. **Monitor** progress in Events tab
5. **Verify** resources in EC2 console
6. **Delete** cleanly:

   ```bash
   aws cloudformation delete-stack --stack-name WebstoreEC2Stack
   ```

---

### 🧠 Why Architects Love It

* Reproducible environments
* Version-controlled IaC
* Automatic dependency ordering
* Rollback on failure
* Integrates with GitHub Actions / Terraform / CI-CD

</details>

---

<details>
<summary><strong>6. Architecture Blueprint – Automation Flow</strong></summary>

```
Developer / Engineer
        │
        ▼
 ┌──────────────────────┐
 │ AWS CLI              │  ← Manual provisioning / testing
 └──────────┬───────────┘
            │
            ▼
 ┌──────────────────────┐
 │ AWS CloudFormation   │  ← IaC autopilot (templates)
 └──────────┬───────────┘
            │
            ▼
 ┌──────────────────────────────┐
 │ AWS Resources                │
 │  (EC2 | S3 | RDS | VPC | EFS)│
 └──────────────────────────────┘
            │
            ▼
   Consistent Infrastructure Ready
```

CLI = hands-on control
CloudFormation = repeatable automation
Together = full-spectrum DevOps efficiency.

</details>

---

<details>
<summary><strong>7. Template Deep Dive – Webstore EC2 Stack (YAML Example)</strong></summary>

Below is an **improved, production-ready version** of your original EC2 template — simplified for clarity but deployable.

```yaml
AWSTemplateFormatVersion: '2010-09-09'
Description: >
  Webstore EC2 Linux VM Stack – creates a secure EC2 instance with SSH access.

Parameters:
  KeyPairName:
    Type: AWS::EC2::KeyPair::KeyName
    Description: Name of an existing EC2 KeyPair to SSH into the instance

Resources:
  WebstoreSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: Allow SSH and HTTP access
      VpcId: !Ref AWS::NoValue        # auto-picks default VPC
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 22
          ToPort: 22
          CidrIp: 0.0.0.0/0
        - IpProtocol: tcp
          FromPort: 80
          ToPort: 80
          CidrIp: 0.0.0.0/0

  WebstoreEC2Instance:
    Type: AWS::EC2::Instance
    Properties:
      ImageId: ami-0c02fb55956c7d316      # Amazon Linux 2 (us-east-1)
      InstanceType: t2.micro
      KeyName: !Ref KeyPairName
      SecurityGroupIds:
        - !Ref WebstoreSecurityGroup
      Tags:
        - Key: Name
          Value: Webstore-EC2-Instance
      UserData:
        Fn::Base64: |
          #!/bin/bash
          yum update -y
          amazon-linux-extras install nginx1 -y
          systemctl enable nginx
          systemctl start nginx
          echo "<h1>Welcome to Webstore EC2!</h1>" > /usr/share/nginx/html/index.html

Outputs:
  PublicIP:
    Description: Public IP address of the instance
    Value: !GetAtt WebstoreEC2Instance.PublicIp
  WebURL:
    Description: URL of the deployed web server
    Value: !Sub "http://${WebstoreEC2Instance.PublicDnsName}"
```

**Explanation Highlights**

* **Security Group** → allows SSH + HTTP from anywhere.
* **EC2 Instance** → launches Amazon Linux 2 + auto-installs Nginx.
* **UserData** → boots with a welcome page.
* **Outputs** → instantly give you the Public IP and URL.

Deploy with:

```bash
aws cloudformation create-stack \
  --stack-name WebstoreEC2Stack \
  --template-body file://webstore-ec2.yml \
  --parameters ParameterKey=KeyPairName,ParameterValue=your-keypair
```

</details>

---

<details>
<summary><strong>8. Real-World Use Cases & Best Practices</strong></summary>

Instead of big jargon, let’s make it real.

| Situation                | Tool to Use    | Example Scenario                                                                             |
| ------------------------ | -------------- | -------------------------------------------------------------------------------------------- |
| **Morning Check**        | AWS CLI        | You start your day by checking which EC2 servers are running — `aws ec2 describe-instances`. |
| **Quick File Upload**    | AWS CLI        | You push today’s build logs to S3 — `aws s3 cp logs.zip s3://webstore-logs/`.               |
| **Recreate Environment** | CloudFormation | Need a test VPC + EC2 for a new feature? Run your template once and everything appears.      |
| **Clean Up Resources**   | AWS CLI        | Before weekend, run `aws s3 rb s3://temp-bucket --force` to clear unused data.               |
| **Disaster Recovery**    | CloudFormation | Prod broke? Redeploy your saved template and get the same architecture back instantly.       |
| **Learning / Testing**   | Both           | Try new configs using CLI, then document successful setup as a CloudFormation YAML.          |

**Best Practices**

* Keep all templates in version control (GitHub).
* Validate every template before running it.
* Use tags (`--tags Key=Owner,Value=Akhil`) for tracking cost.
* Practice deleting stacks often — it teaches clean teardown.

> “CLI gives you agility; CloudFormation gives you immortality.”
> Both make sure your cloud doesn’t depend on memory — only on mastery.

</details>

---

<details>
<summary><strong>9. Quick Summary & Self-Audit</strong></summary>

| Area                    | Key Checks                                |
| ----------------------- | ----------------------------------------- |
| **AWS CLI**             | Installed + configured correctly          |
| **Access Keys**         | Stored securely in credentials file       |
| **Common Commands**     | S3 list, EC2 describe, IAM users          |
| **CloudFormation**      | Understands Stacks, Parameters, Outputs   |
| **Template Validation** | `validate-template` passes cleanly        |
| **Stack Lifecycle**     | Create → Update → Delete works error-free |
| **Reproducibility**     | Same infra works across regions           |

✅ **I can:**

* Create and delete S3 buckets from CLI.
* Deploy the Webstore EC2 Stack via CloudFormation.
* Explain IaC benefits to a teammate in plain English.

</details>

---

<details>
<summary><strong>10. 💡 Mentor Insight</strong></summary>

Automation turns good engineers into architects.
Use **AWS CLI** to understand how AWS thinks,
then let **CloudFormation** express that understanding in code.

When you can rebuild an entire environment with one file or one command —
you’ve crossed from *manual operator* to *infrastructure designer.*

</details>

---
