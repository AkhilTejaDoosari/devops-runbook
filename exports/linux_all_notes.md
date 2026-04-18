
---
# FILE: 01. Linux – System Fundamentals/01-boot-process/README.md
---

[Home](../README.md) |
[Boot](../01-boot-process/README.md) |
[Basics](../02-basics/README.md) |
[Files](../03-working-with-files/README.md) |
[Filters](../04-filter-commands/README.md) |
[sed](../05-sed-stream-editor/README.md) |
[awk](../06-awk/README.md) |
[vim](../07-text-editor/README.md) |
[Users](../08-user-and-group-management/README.md) |
[Permissions](../09-file-ownership-and-permissions/README.md) |
[Archive](../10-archiving-and-compression/README.md) |
[Packages](../11-package-management/README.md) |
[Services](../12-service-management/README.md) |
[Networking](../13-networking/README.md) |
[Logs](../14-logs-and-debug/README.md) |
[Interview](../99-interview-prep/README.md)

---

# Boot Process

> **Layer:** L0 — Kernel & Hardware
> **Depends on:** Nothing — this is the first file
> **Used in production when:** A server won't boot, you need to know which stage failed and where to look

---

## Table of Contents

- [What this is](#what-this-is)
- [How it fits the stack](#how-it-fits-the-stack)
- [The Boot Sequence](#the-boot-sequence)
- [1. Firmware — BIOS and UEFI](#1-firmware--bios-and-uefi)
- [2. GRUB2 — The Bootloader](#2-grub2--the-bootloader)
- [3. initramfs — Why it exists](#3-initramfs--why-it-exists)
- [4. The Kernel](#4-the-kernel)
- [5. systemd — PID 1](#5-systemd--pid-1)
- [On the webstore](#on-the-webstore)
- [What breaks](#what-breaks)
- [Daily commands](#daily-commands)

---

## What this is

The boot process is a relay race. Six stages run in a fixed order — each one does its job and hands off to the next. If any stage fails, the race stops exactly there and the error tells you which stage broke. Understanding this sequence means you never blindly stare at a blank screen — you read the error, identify the stage, and know exactly where to look. This file gives you that map.

---

## How it fits the stack

```
  L6  You
  L5  Tools & Files
  L4  Config
  L3  State & Debug
  L2  Networking
  L1  Process Manager  ← systemd starts here, at the end of boot
  L0  Kernel & Hardware  ← this file lives here
```

Everything above L0 only exists because the boot process assembled it.
BIOS wakes the hardware. GRUB loads the kernel. The kernel starts systemd.
systemd builds everything above it. If L0 fails, nothing above it can exist.

---

## The Boot Sequence

```
Power ON
   │
   ▼
┌─────────────────────────────────────────────────────────────────┐
│  BIOS / UEFI  (firmware on the motherboard chip)                │
│  job: run POST, find bootable disk, load GRUB into RAM          │
│  breaks as: blank screen · beep codes · "no bootable device"    │
│  fix: physical check — RAM seated, disk connected, BIOS order   │
└──────────────────────────────┬──────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│  GRUB2  (Grand Unified Bootloader)                              │
│  job: show boot menu, load kernel + initramfs, hand off         │
│  breaks as: grub rescue> prompt · "no such partition" error     │
│  fix: boot live USB → chroot → grub-install → update-grub       │
└──────────────────────────────┬──────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│  Kernel  (/boot/vmlinuz-*)                                      │
│  job: load drivers, mount real /, hand off to systemd           │
│  breaks as: kernel panic — text wall on screen                  │
│  fix: dmesg | less — read the last lines before the panic       │
│       boot older kernel from GRUB menu as fallback              │
└──────────────────────────────┬──────────────────────────────────┘
                               │  ← initramfs used here, then discarded
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│  systemd  (PID 1)                                               │
│  job: read unit files, start services, reach boot target        │
│  breaks as: emergency shell · failed units listed on screen     │
│  fix: journalctl -xb · systemctl list-units --state=failed      │
└──────────────────────────────┬──────────────────────────────────┘
                               │
                               ▼
                        Login prompt ✓
```

Each error message tells you exactly which stage broke.
`grub rescue>` → GRUB failed, don't look at the kernel.
`kernel panic` → GRUB worked, look at drivers or the filesystem.
`emergency shell` → kernel worked, look at systemd unit files.

---

## 1. Firmware — BIOS and UEFI

The firmware is the first thing that runs when a machine gets power.
It lives on a chip on the motherboard — not Linux, not an OS.
Its only job is to wake up the hardware and find something bootable.

**What it does:**
- Runs **POST** (Power-On Self Test) — checks CPU, RAM, and storage are present
- Finds a bootable disk based on the boot order you set in BIOS settings
- Loads the bootloader (GRUB) from that disk into RAM
- Steps aside — firmware is done

**BIOS vs UEFI — what you actually need to know:**

| | BIOS | UEFI |
|---|---|---|
| Age | Legacy — 1970s design | Modern standard — what all servers use now |
| Disk table | Works with MBR | Works with GPT |
| Max disk size | 2 TB limit | No practical limit |
| Boot speed | Slower | Faster — loads more directly |

UEFI is on every modern server. You will only see BIOS on hardware older than ~2012.
GPT is the partition table standard. MBR is legacy — 2 TB limit, max 4 partitions.

---

## 2. GRUB2 — The Bootloader

GRUB2 (Grand Unified Bootloader 2) is the first Linux-aware software that runs.
Firmware knows nothing about Linux — it just finds a disk.
GRUB knows exactly where the kernel lives and how to load it.

**What GRUB does:**
- Displays the OS selection menu (dual-boot machines)
- Loads the kernel (`/boot/vmlinuz-*`) into RAM
- Loads **initramfs** (`/boot/initrd.img-*`) alongside the kernel
- Passes control to the kernel — GRUB's job is done in seconds

**The two files rule — this is what you actually touch:**

| File | What it is | What you do |
|---|---|---|
| `/etc/default/grub` | Human-editable settings | **Edit this one** |
| `/boot/grub/grub.cfg` | Auto-generated final config | **Never touch this** |

After editing `/etc/default/grub`, regenerate the final config:
```bash
sudo update-grub
```

**Common things you change in `/etc/default/grub`:**
```bash
GRUB_TIMEOUT=5           # seconds to show the menu before auto-booting
GRUB_DEFAULT=0           # which menu entry boots by default (0 = first)
GRUB_CMDLINE_LINUX=""    # extra parameters passed to the kernel at boot
                         # example: "net.ifnames=0" forces old-style eth0 naming
```

---

## 3. initramfs — Why it exists

The kernel needs drivers to mount the real root filesystem (`/`).
But those drivers live on the real root filesystem.
Classic chicken-and-egg problem.

**initramfs** breaks the deadlock. It is a tiny filesystem loaded into RAM
by GRUB alongside the kernel. It contains just enough drivers to mount
the real disk. Once `/` is mounted, initramfs is discarded and forgotten.

You rarely touch it directly. It rebuilds automatically when you update the kernel.

```bash
# See your initramfs files
ls -lh /boot/initrd.img-*
# -rw-r--r-- 1 root root 52M Apr 5 09:12 /boot/initrd.img-6.5.0-26-generic
```

---

## 4. The Kernel

The kernel is the only software that talks directly to hardware.
Once GRUB hands control to it, the kernel takes over completely.

**What the kernel does at boot:**
1. Decompresses itself into RAM
2. Uses initramfs to access storage drivers
3. Mounts the real root filesystem (`/dev/sda1` or equivalent)
4. Discards initramfs
5. Starts systemd as PID 1 — the first user-space process

The kernel binary lives at `/boot/vmlinuz-*`.
The `vmlinuz` name is historical — "vm" for virtual memory, "linuz" for Linux, "z" for compressed.

---

## 5. systemd — PID 1

systemd is the first process the kernel starts. It always gets **PID 1** —
process ID number one. Every other process on the system is a child of systemd.
If systemd dies, the system goes down.

**What systemd manages:**
- Starting and stopping all services (nginx, sshd, cron, docker)
- Boot targets — the state the system should reach after boot
- Logging via `journald` — all service logs flow through here
- Mounts, sockets, timers

**Unit types — the files systemd reads:**

| Unit | Extension | Purpose |
|---|---|---|
| Service | `.service` | A background daemon — nginx, sshd, postgresql |
| Target | `.target` | A group of units — defines what "booted" means |
| Socket | `.socket` | Starts a service when a connection arrives on a port |
| Mount | `.mount` | A filesystem mount point managed by systemd |
| Timer | `.timer` | A scheduled job — modern replacement for cron |

**Boot targets — the two you need to know:**

| Target | Old runlevel | What it means |
|---|---|---|
| `multi-user.target` | 3 | Full system, networking up, no GUI — this is every server |
| `graphical.target` | 5 | Full system, networking up, GUI running — desktops |
| `rescue.target` | 1 | Minimal, single user, no networking — recovery mode |
| `emergency.target` | — | Bare minimum root shell — last resort |

```bash
# See what target the system boots into
systemctl get-default
# multi-user.target

# Change the default boot target
sudo systemctl set-default multi-user.target
```

---

## On the webstore

At this stage the webstore does not exist yet — there is nothing to deploy.
But the boot process is what runs every time the server starts, and knowing
it means you can answer the first question in any incident:
**is the machine actually up, and did it come up cleanly?**

```bash
# Step 1 — SSH into the server. Confirm it came up and how long it's been running
uptime
# 09:14:22 up 2:03, 1 user, load average: 0.08, 0.03, 0.01

# Step 2 — Check what kernel is running
uname -r
# 6.5.0-26-generic

# Step 3 — Check for any errors during this boot
journalctl -b --priority=err
# (should be empty on a clean boot — any output means something failed)

# Step 4 — Check what systemd brought up
systemctl list-units --type=service --state=running
# shows every service currently running

# Step 5 — Check the boot partition — kernel, initramfs, GRUB files
ls -lh /boot
# vmlinuz-6.5.0-26-generic
# initrd.img-6.5.0-26-generic
# grub/

# Step 6 — View the GRUB settings
cat /etc/default/grub
```

When you install nginx in file 11 and enable it with systemd in file 12,
it will start automatically on every boot because systemd reads the unit
file during boot and starts every enabled service. That process starts here.

---

## What breaks

| Symptom | Stage that broke | First command |
|---|---|---|
| Blank screen, beep codes | BIOS/UEFI | Physical check — RAM, cables, boot order in BIOS |
| `grub rescue>` prompt | GRUB | Boot live USB → `chroot` → `grub-install /dev/sda` → `update-grub` |
| `error: no such partition` | GRUB | Disk UUID changed — boot live USB, update `/boot/grub/grub.cfg` |
| Kernel panic text on screen | Kernel | `journalctl -b -1` — logs from previous boot. Try older kernel from GRUB menu |
| Emergency shell on boot | systemd | `journalctl -xb` — find the failed unit. Fix it then `systemctl reboot` |
| Boots but service missing | systemd | `systemctl list-units --state=failed` — find what didn't start |
| System boots slowly | systemd | `systemd-analyze blame` — shows which service took the longest |

---

## Daily commands

| Command | What it does |
|---|---|
| `uname -r` | Show the kernel version currently running |
| `systemctl get-default` | Show which target the system boots into |
| `systemctl list-units --state=failed` | Show every unit that failed during boot |
| `journalctl -b` | Show all logs from the current boot |
| `journalctl -b -1` | Show all logs from the previous boot — useful after a crash |
| `journalctl -b --priority=err` | Show only errors from current boot |
| `dmesg \| less` | Show kernel hardware messages — look here after a crash |
| `ls -lh /boot` | See kernel, initramfs, and GRUB files |
| `sudo update-grub` | Regenerate `/boot/grub/grub.cfg` after editing `/etc/default/grub` |

---

→ **Interview questions for this topic:** [99-interview-prep → Boot Process](../99-interview-prep/README.md#boot-process)

---
# FILE: 01. Linux – System Fundamentals/02-basics/README.md
---

[Home](../README.md) |
[Boot](../01-boot-process/README.md) |
[Basics](../02-basics/README.md) |
[Files](../03-working-with-files/README.md) |
[Filters](../04-filter-commands/README.md) |
[sed](../05-sed-stream-editor/README.md) |
[awk](../06-awk/README.md) |
[vim](../07-text-editor/README.md) |
[Users](../08-user-and-group-management/README.md) |
[Permissions](../09-file-ownership-and-permissions/README.md) |
[Archive](../10-archiving-and-compression/README.md) |
[Packages](../11-package-management/README.md) |
[Services](../12-service-management/README.md) |
[Networking](../13-networking/README.md) |
[Logs](../14-logs-and-debug/README.md) |
[Interview](../99-interview-prep/README.md)

---

# Linux Basics

> **Layer:** L6 — You
> **Depends on:** [01 Boot Process](../01-boot-process/README.md) — you should know what booted before you navigate it
> **Used in production when:** You SSH into any server — familiar or not — and need to know where you are, what is running, and what the machine looks like before touching anything

---

## Table of Contents

- [What this is](#what-this-is)
- [How it fits the stack](#how-it-fits-the-stack)
- [1. Directory Navigation](#1-directory-navigation)
- [2. Listing Directory Contents](#2-listing-directory-contents)
- [3. Terminal Essentials](#3-terminal-essentials)
- [4. System Information](#4-system-information)
- [5. Getting Help](#5-getting-help)
- [6. Kernel and System Info](#6-kernel-and-system-info)
- [On the webstore](#on-the-webstore)
- [What breaks](#what-breaks)
- [Daily commands](#daily-commands)

---

## What this is

Linux organises everything under one single tree starting at `/`. No C: or D: drives — every file, disk, device, and config lives somewhere beneath that root slash. The **shell** is the translator between you and the kernel — when you type a command, the shell interprets it and asks the kernel to do the work. On servers you interact with Linux through a shell over SSH with no GUI. These commands are how you see, move, and understand everything on that machine. They are the vocabulary you use in every other file in these notes.

---

## How it fits the stack

```
  L6  You  ← this file lives here
       ~ · /home/akhil · pwd · ls · whoami
  L5  Tools & Files
  L4  Config
  L3  State & Debug
  L2  Networking
  L1  Process Manager
  L0  Kernel & Hardware
```

L6 is where you land every time you SSH in. Before you can edit a config at L4, read a log at L3, or check a service at L1 — you need to be able to move around at L6. This file teaches that movement.

---

## 1. Directory Navigation

The shell always operates inside some directory — called the **current working directory (CWD)**. When you SSH into a server you have no idea where you landed. The first command you run is `pwd` — it tells you exactly where you are before you touch anything.

**Absolute vs relative paths:**
- **Absolute** — starts from root: `/home/akhil/webstore` — works from anywhere
- **Relative** — starts from your CWD: if you are in `/home/akhil`, then `cd webstore` takes you to `/home/akhil/webstore`
- `..` — means parent directory. `cd ..` moves you up one level.
- `~` — shorthand for your home directory. The shell replaces it with `/home/akhil`.

| Command | Full form | What it does | When you reach for it |
|---|---|---|---|
| `pwd` | Print Working Directory | Print the full path of your current location | First command after SSHing into any server |
| `cd <dir>` | Change Directory | Move into a directory | `cd ~/webstore/logs` — navigate to a specific folder |
| `cd ..` | Change Directory up | Move up one directory level | Going from `~/webstore/logs` back to `~/webstore` |
| `cd ~` | Change Directory home | Jump to your home directory | Getting back to a known starting point fast |
| `cd -` | Change Directory previous | Jump back to the last directory you were in | Toggling between two directories during an incident |
| `mkdir <dir>` | Make Directory | Create a new directory | `mkdir ~/webstore/logs` — creating the logs folder |
| `mkdir -p <path>` | Make Directory --parents | Create nested directories in one shot, no error if they exist | `mkdir -p ~/webstore/{frontend,api,db,logs,config,backup}` — builds the full project structure in one command |
| `rmdir <dir>` | Remove Directory | Delete an empty directory | Removing a folder you created by mistake — fails silently if the directory has contents |
| `rm -rf <dir>` | Remove --recursive --force | Delete a directory and everything inside it, no confirmation | Wiping a directory completely — always run `ls <path>` first to confirm what you are about to delete |

> **`rm -rf` has no confirmation and no undo.** A wrong path on a production server means permanent data loss. Build this habit: always run `ls <path>` first to confirm exactly what is there before deleting it.

---

## 2. Listing Directory Contents

`ls` is the command you run more than any other on a Linux server. Flags give you permissions, ownership, size, timestamps, and hidden files — all critical during incident work.

| Command | Full form | What it shows | When you reach for it |
|---|---|---|---|
| `ls` | List | Filenames only | Quick glance at what is in a directory |
| `ls -l` | List --long | Full details — permissions, owner, size, timestamp | Checking who owns the webstore config and when it was last changed |
| `ls -lh` | List --long --human-readable | Same as `-l` but sizes in KB/MB/GB | Checking whether a log file has silently grown to 2 GB overnight |
| `ls -la` | List --long --all | Full details including hidden files (`.` prefix) | Finding `.env` or `.bashrc` files invisible by default |
| `ls -lt` | List --long --time | Sorted by modification time, newest first | Spotting which file in `~/webstore/logs` changed during an incident |
| `ls -ltr` | List --long --time --reverse | Sorted by modification time, oldest first | Seeing the full chronological history of changes in a directory |
| `ls -ld <dir>` | List --long --directory | Info about the directory itself, not its contents | Checking permissions on `~/webstore/` without listing everything inside |

You can chain flags freely — `ls -lh`, `ls -ltr`, `ls -lahtr` all work. Flag order does not matter.

**Gold standard: `ls -lahtr`** — long format, all files including hidden, human-readable sizes, sorted oldest-to-newest. Full picture at a glance.

**Reading `ls -lh` output — every field explained:**

```bash
ls -lh ~/webstore/config/
# -rw-r--r-- 1 akhil www-data 1.2K Apr 5 09:14 webstore.conf
```

| Field | Value | What it means |
|---|---|---|
| File type + permissions | `-rw-r--r--` | `-` = regular file. Owner can read+write. Group and others can only read. |
| Hard links | `1` | One reference to this file in the filesystem |
| Owner | `akhil` | The user who owns this file |
| Group | `www-data` | Any process running as `www-data` — such as nginx — inherits the group's read permission |
| Size | `1.2K` | Human-readable because of `-h` — without it this shows raw bytes |
| Last modified | `Apr 5 09:14` | When the file was last written to — critical during incident triage |
| Filename | `webstore.conf` | The file |

When you see `www-data` as the group on a config file, it means nginx can read it — intentional. If the group were `root`, nginx would be locked out and the site would fail to start.

---

## 3. Terminal Essentials

The shell keeps a numbered history of every command you have run. On a server this lets you repeat long commands without retyping and audit what was run before you arrived.

| Command | What it does | When you reach for it |
|---|---|---|
| `clear` | Clear the terminal screen — history is untouched | Cleaning up visual clutter before a focused task |
| `history` | Show all commands run this session with line numbers | Auditing what was run on a server before you got there |
| `!<num>` | Re-run the command at that history number | `!42` — repeat a long command without retyping it |
| `!!` | Re-run the last command | Running the same command twice — or `sudo !!` to re-run with sudo |

**Keyboard shortcuts that save the most time:**

| Shortcut | What it does |
|---|---|
| `↑` | Scroll back through history one command at a time |
| `Ctrl + R` | Reverse-search history by typing part of a command |
| `Ctrl + C` | Kill the running command immediately |
| `Ctrl + L` | Clear the screen — same as `clear` |
| `Tab` | Autocomplete a command, filename, or path |

`Ctrl + R` is the one most people do not know but use constantly once they do. Type `Ctrl + R` then start typing `docker run` — the shell finds the last matching command. Press Enter to run it or keep typing to narrow the search.

---

## 4. System Information

These are the first commands you run when you SSH into an unfamiliar server. They tell you who you are, what the machine is, and whether anything unusual is happening.

| Command | What it tells you | When you reach for it |
|---|---|---|
| `whoami` | Your current username | Confirming you are logged in as the right user — not root when you shouldn't be |
| `id` | Your UID, GID, and all group memberships | Confirming you have the group access you need before touching files |
| `who` | Every user currently logged into this machine | Checking if someone else is on the server during an incident |
| `uptime` | How long the system has been running + load averages | A server that rebooted 3 minutes ago when it should have been up 30 days tells you something broke |
| `date` | Current system date and time | Confirming the server clock is correct before reading log timestamps |
| `hostname` | The machine's name | Confirming you are on the right server — critical when managing multiple machines |

**What `uptime` output actually means:**

```bash
uptime
# 10:32:11 up 4 days, 2:17, 1 user, load average: 0.45, 0.38, 0.31
```

The three load average numbers are CPU demand over the last 1 minute, 5 minutes, and 15 minutes. A number below your CPU core count means the system is healthy. A number above it means the system is under more load than it can handle.

```bash
# See your CPU core count to compare against load average
nproc
# 2   ← load average above 2.0 means this server is overloaded
```

---

## 5. Getting Help

Every command ships with documentation built in. Before searching the internet, check locally — it is faster and works on any server with no internet access.

| Command | What it does | When you reach for it |
|---|---|---|
| `man <command>` | Full manual page — everything the command can do | `man ls` — when you need to find an obscure flag |
| `<command> --help` | Short usage summary — faster than man | `cp --help` — quick reminder of the most common flags |
| `whatis <command>` | One-line description of what a command does | Quick reminder of what a command is for |
| `which <command>` | Shows the exact path of the executable that would run | `which python3` — confirming which Python is active when you have multiple versions installed |
| `whereis <command>` | Finds the binary, man page, and source locations | Confirming where a tool is installed on the system |

Inside `man` pages: use `/` to search, `n` to jump to the next match, `q` to quit. Most man pages are long — searching is faster than scrolling.

---

## 6. Kernel and System Info

`uname` (Unix Name) reports information about the running kernel and hardware. You reach for it when confirming the kernel version after an update, when a tool requires a specific architecture, or when a script needs to detect what OS it is running on.

| Command | Full form | What it shows | Example output |
|---|---|---|---|
| `uname -s` | uname --kernel-name | Kernel name | `Linux` |
| `uname -r` | uname --kernel-release | Kernel version | `6.5.0-26-generic` |
| `uname -n` | uname --nodename | Hostname | `webstore-prod-01` |
| `uname -m` | uname --machine | Hardware architecture | `x86_64` |
| `uname -a` | uname --all | All of the above in one line | Full system summary |

```bash
uname -a
# Linux webstore-prod-01 6.5.0-26-generic #26~22.04.1-Ubuntu SMP x86_64 GNU/Linux
```

---

## On the webstore

This is the first real work. You are on a blank server.
Before installing or deploying anything, you need to understand what you have.

```bash
# Step 1 — confirm who you are and where you landed
whoami
# akhil

pwd
# /home/akhil

# Step 2 — check the machine is healthy before touching anything
uptime
# 10:32:11 up 4 days, 2:17, 1 user, load average: 0.08, 0.03, 0.01

hostname
# webstore-prod-01

# Step 3 — check disk space — enough room to install software and store logs?
df -h
# Filesystem      Size  Used Avail Use% Mounted on
# /dev/sda1        20G  4.2G   15G  23% /

# Step 4 — check memory
free -h
#               total        used        free
# Mem:           3.8G        1.1G        2.7G

# Step 5 — build the webstore directory structure
mkdir -p ~/webstore/{frontend,api,db,logs,config,backup}

# Step 6 — verify it was created correctly
ls -la ~/webstore/
# drwxrwxr-x 8 akhil akhil 4.0K Apr  5 09:14 .
# drwxr-xr-x 5 akhil akhil 4.0K Apr  5 09:14 ..
# drwxrwxr-x 2 akhil akhil 4.0K Apr  5 09:14 api
# drwxrwxr-x 2 akhil akhil 4.0K Apr  5 09:14 backup
# drwxrwxr-x 2 akhil akhil 4.0K Apr  5 09:14 config
# drwxrwxr-x 2 akhil akhil 4.0K Apr  5 09:14 db
# drwxrwxr-x 2 akhil akhil 4.0K Apr  5 09:14 frontend
# drwxrwxr-x 2 akhil akhil 4.0K Apr  5 09:14 logs

# Step 7 — navigate into the project and confirm your location
cd ~/webstore
pwd
# /home/akhil/webstore
```

The webstore directory structure now exists on disk. Every file from here onward operates inside this structure. The `frontend/` directory is where nginx will serve files from. The `logs/` directory is where access and error logs will land. The `config/` directory is where `webstore.conf` will live.

---

## What breaks

| Symptom | Cause | Fix |
|---|---|---|
| `bash: cd: /path: No such file or directory` | The path does not exist or you have a typo | `ls` the parent directory first to confirm the exact name |
| `mkdir: cannot create directory: Permission denied` | You do not have write permission on the parent | `ls -ld <parent>` to check ownership — you may need `sudo` |
| `rm: cannot remove: Is a directory` | You used `rm` without `-r` on a directory | Use `rm -r` for directories — add `-f` only if you are sure |
| `rm -rf` deleted the wrong thing | Wrong path, no confirmation | No fix — no undo on Linux. Restore from backup. Verify paths before running. |
| `pwd` shows unexpected path | You navigated somewhere by accident | `cd ~` to get back to a known location, then navigate again |
| Load average in `uptime` is very high | System is overloaded | `top` or `htop` to find which process is consuming resources |

---

## Daily commands

| Command | What it does |
|---|---|
| `pwd` | Show where you are right now |
| `ls -lahtr` | List all files including hidden, human-readable sizes, sorted by time |
| `cd <path>` | Move into a directory |
| `cd ~` | Jump to your home directory |
| `cd -` | Jump back to the previous directory |
| `mkdir -p <path>` | Create nested directories in one command |
| `whoami` | Show your current username |
| `id` | Show your UID, GID, and all group memberships |
| `uptime` | Show how long the machine has been running and load average |

---

→ **Interview questions for this topic:** [99-interview-prep → Linux Basics](../99-interview-prep/README.md#linux-basics)

---
# FILE: 01. Linux – System Fundamentals/03-working-with-files/README.md
---

[Home](../README.md) |
[Boot](../01-boot-process/README.md) |
[Basics](../02-basics/README.md) |
[Files](../03-working-with-files/README.md) |
[Filters](../04-filter-commands/README.md) |
[sed](../05-sed-stream-editor/README.md) |
[awk](../06-awk/README.md) |
[vim](../07-text-editor/README.md) |
[Users](../08-user-and-group-management/README.md) |
[Permissions](../09-file-ownership-and-permissions/README.md) |
[Archive](../10-archiving-and-compression/README.md) |
[Packages](../11-package-management/README.md) |
[Services](../12-service-management/README.md) |
[Networking](../13-networking/README.md) |
[Logs](../14-logs-and-debug/README.md) |
[Interview](../99-interview-prep/README.md)

---

# Working with Files

> **Layer:** L5 — Tools & Files
> **Depends on:** [02 Basics](../02-basics/README.md) — you need `ls`, `cd`, and `pwd` before working with files
> **Used in production when:** Backing up a config before changing it, writing content into a file from the terminal, reading a log without opening an editor, creating the webstore directory structure

---

## Table of Contents

- [What this is](#what-this-is)
- [How it fits the stack](#how-it-fits-the-stack)
- [1. Create and Inspect Files](#1-create-and-inspect-files)
- [2. Writing Content into Files](#2-writing-content-into-files)
- [3. Copying Files — cp](#3-copying-files--cp)
- [4. Moving and Renaming Files — mv](#4-moving-and-renaming-files--mv)
- [5. Deleting Files — rm](#5-deleting-files--rm)
- [6. Viewing File Contents](#6-viewing-file-contents)
- [7. Previewing File Sections — head and tail](#7-previewing-file-sections--head-and-tail)
- [8. Symbolic Links — ln](#8-symbolic-links--ln)
- [On the webstore](#on-the-webstore)
- [What breaks](#what-breaks)
- [Daily commands](#daily-commands)

---

## What this is

On a Linux server, everything is a file. Config files, log files, scripts, sockets, devices — all of them live in the filesystem and all of them are operated on with the same small set of commands. This file covers creating files, reading their contents, copying and moving them, deleting them, and understanding symlinks. These are not beginner exercises — they are the operations you perform every single time you work on a server. Getting comfortable with `-i` and `-v` flags here will prevent data loss in production.

---

## How it fits the stack

```
  L6  You
  L5  Tools & Files  ← this file lives here
       cp · mv · rm · cat · less · head · tail · touch · ln
  L4  Config
  L3  State & Debug
  L2  Networking
  L1  Process Manager
  L0  Kernel & Hardware
```

The webstore directory from file 02 is now a skeleton of empty folders. This file fills it — writing config files into it, reading its logs, backing it up before changes. Every tool from file 04 onward operates on files you know how to handle after this.

---

## 1. Create and Inspect Files

`touch` creates an empty file if it does not exist, or updates the last-modified timestamp if it does. On a server you use it to create placeholder files or initialise log files before a service starts writing to them.

`file` examines the actual content of a file and reports what type it is — not based on the extension, but based on the bytes inside. Linux does not care about extensions. A file called `server.conf` could contain anything — `file` tells you what it actually is.

`stat` (status) shows the full metadata of a file — exact size, all three timestamps, permissions in both numeric and symbolic form, and the inode number. When a deployment goes wrong and you need to know exactly when a config file was last changed, `stat` gives you the answer down to the second.

| Command | Full form | What it does | When you reach for it |
|---|---|---|---|
| `touch <file>` | — | Create an empty file or update its timestamp | Creating `~/webstore/logs/access.log` before nginx starts writing to it |
| `file <file>` | — | Report the actual content type of a file | Confirming a downloaded binary is an ELF executable, not a corrupted file |
| `stat <file>` | Status | Show full metadata — size, all timestamps, permissions, inode | Finding the exact second `webstore.conf` was last modified during an incident |

**What `stat` output tells you:**

```bash
stat ~/webstore/config/webstore.conf
# File: webstore.conf
# Size: 128        Blocks: 8    IO Block: 4096   regular file
# Inode: 524291    Links: 1
# Access: (0644/-rw-r--r--)  Uid: (1000/akhil)  Gid: (33/www-data)
# Access: 2025-04-05 09:12:01   ← last read
# Modify: 2025-04-05 08:47:33   ← last content change
# Change: 2025-04-05 08:47:33   ← last metadata change (permissions etc)
```

Three timestamps — **Access** (last read), **Modify** (last content change), **Change** (last metadata change including permissions). If `Modify` and `Change` differ, someone changed permissions without touching the content. That is worth knowing during an incident.

---

## 2. Writing Content into Files

Two operators write content into files from the command line — `>` and `>>`.     
Knowing the difference prevents you from accidentally wiping a file you meant to append to.

| Operator | What it does | When you reach for it |
|---|---|---|
| `echo "text" > <file>` | Write text to a file — **overwrites** entirely if file exists | Creating `webstore.conf` from scratch with a single line |
| `echo "text" >> <file>` | Append text to a file — adds to the end, never overwrites | Adding a new config entry to an existing file without disturbing the rest |

```bash
# Create webstore.conf with initial content
echo "db_host=webstore-db" > ~/webstore/config/webstore.conf
echo "db_port=5432" >> ~/webstore/config/webstore.conf
echo "api_port=8080" >> ~/webstore/config/webstore.conf

# Verify what was written
cat ~/webstore/config/webstore.conf
# db_host=webstore-db
# db_port=5432
# api_port=8080
```

 Use `>>` **(append)** when you mean to add.  
Use `>` **(overwrite)** only when you mean to replace everything.   
 **`>` overwrites without warning.** `echo "new" > webstore.conf` replaces the entire file with one word.  

> **Rule of Thumb:**    
Use `echo` for quickly injecting small pieces of data or appending single lines to files via scripts.   
For creating or editing large, complex configuration files, use a text editor like `vim`.
---

## 3. Copying Files — `cp`

`cp` (copy) copies a file or directory. The original stays in place.

| Command | Full form | What it does |
|---|---|---|
| `cp <src> <dest>` | Copy | Copy a file to a new location or name |
| `cp -r <src> <dest>` | Copy --recursive | Copy a directory and everything inside it |
| `cp -i <src> <dest>` | Copy --interactive | Ask before overwriting — prompt if destination exists |
| `cp -v <src> <dest>` | Copy --verbose | Print each file as it is copied |
| `cp -riv <src> <dest>` | Copy --recursive --interactive --verbose | Gold standard for directory copies |

**`-i` prevents silent overwrites:**

```bash
# Without -i — silently overwrites webstore.conf if it already exists
cp webstore.conf /etc/webstore/webstore.conf

# With -i — pauses and asks first
cp -i webstore.conf /etc/webstore/webstore.conf
# cp: overwrite '/etc/webstore/webstore.conf'? y
```

**`-v` confirms the copy actually happened:**

```bash
# Without -v — no output, no confirmation
cp -r ~/webstore ~/webstore-backup

# With -v — prints every file as it copies
cp -rv ~/webstore ~/webstore-backup
# ~/webstore -> ~/webstore-backup
# ~/webstore/config/webstore.conf -> ~/webstore-backup/config/webstore.conf
# ~/webstore/logs/access.log -> ~/webstore-backup/logs/access.log
```

**Gold standard — use this before every production change:**

```bash
cp -riv ~/webstore ~/webstore-backup
```

`-r` handles directories, `-i` won't silently overwrite, `-v` shows every file as it copies. You get safety and visibility in one command.

---

## 4. Moving and Renaming Files — `mv`

`mv` (move) handles both moving and renaming — they are the same operation. If the destination is a different path, the file moves. If the destination is a new name in the same directory, the file is renamed. The original is gone either way.

| Command | Full form | What it does |
|---|---|---|
| `mv <src> <dest>` | Move | Move or rename a file or directory |
| `mv -i <src> <dest>` | Move --interactive | Ask before overwriting the destination |
| `mv -v <src> <dest>` | Move --verbose | Print what moved and where it landed |

```bash
# Move — relocate to a different directory
mv webstore.conf /etc/webstore/webstore.conf

# Rename — new name in the same directory
mv webstore.conf webstore.conf.bak

# With -v confirmation
mv -v webstore.conf.bak webstore.conf.backup
# 'webstore.conf.bak' -> 'webstore.conf.backup'
```

`mv` has no `-r` flag because it already handles directories natively.

> **`mv` vs `cp` + `rm`** — always use `mv` to relocate files. `mv` preserves all metadata including timestamps and ownership. `cp` + `rm` creates a new file and loses the original timestamps.

**Gold standard combinations:**

| Situation | Command |
|---|---|
| Back up a directory before changing it | `cp -riv ~/webstore ~/webstore-backup` |
| Copy a single config file safely | `cp -iv webstore.conf /etc/webstore/webstore.conf` |
| Rename a file with confirmation | `mv -iv webstore.conf webstore.conf.bak` |

---

## 5. Deleting Files — `rm`

`rm` (remove) deletes files permanently. There is no trash, no recycle bin, no undo. The habit to build now: always run `ls <path>` first to confirm exactly what you are about to delete.

| Command | Full form | What it does | When you reach for it |
|---|---|---|---|
| `rm <file>` | Remove | Delete a file permanently | Removing a stale lock file blocking a service restart |
| `rm -i <file>` | Remove --interactive | Prompt before each deletion | Deleting multiple files when you want to confirm each one |
| `rm -r <dir>` | Remove --recursive | Delete a directory and all its contents | Removing a build output directory before a fresh deploy |
| `rm -f <file>` | Remove --force | No prompt, no error if file does not exist | Deleting temp files in scripts where the file may or may not be there |
| `rm -rf <dir>` | Remove --recursive --force | Delete an entire directory tree with no confirmation | Wiping a temp directory — verify the path first, every time |

> **`rm -rf` has no confirmation and no undo.** `rm -rf /webstore` and `rm -rf ~/webstore` are completely different operations. Always run `ls <path>` first to confirm what is there before deleting it.

---

## 6. Viewing File Contents

Reading file contents from the terminal is something you do constantly on a server — checking config values, reading logs, verifying that a write operation worked.

| Command | Full form | What it does | When you reach for it |
|---|---|---|---|
| `cat <file>` | Concatenate | Print entire file to terminal | Reading `webstore.conf` to check the current db_host value |
| `cat -n <file>` | Concatenate --number | Print with line numbers | When an error references a specific line number in a config |
| `less <file>` | — | Scroll through a file page by page | Any file too long to read in one screen — logs, long configs |
| `tac <file>` | — (cat backwards) | Print file in reverse line order | Reading a log from bottom to top when newest entries matter most |

Inside `less`: `Space` scroll down, `b` scroll back, `/pattern` search, `n` next match, `q` quit. For a 2 GB log file, `less` handles it instantly — `cat` would flood your terminal.

---

## 7. Previewing File Sections — `head` and `tail`

When debugging a live service you rarely need the whole file. You need the last 50 lines where the error happened, or the first 10 lines of a config to confirm the format.

| Command | Full form | What it does | When you reach for it |
|---|---|---|---|
| `head <file>` | — | Show first 10 lines | Checking the header of a log file to confirm its format |
| `head -n <N> <file>` | head --lines | Show first N lines | `head -n 3 webstore.conf` — reading just the first three config entries |
| `tail <file>` | — | Show last 10 lines | Checking the most recent entries in `access.log` after a request |
| `tail -n <N> <file>` | tail --lines | Show last N lines | `tail -n 50 error.log` — reading the last 50 lines during an incident |
| `tail -f <file>` | tail --follow | Follow live — print new lines as they are written | Watching `access.log` in real time while testing a webstore endpoint |

`tail -f` is the command for watching a live service. Open a second terminal, run `tail -f ~/webstore/logs/access.log`, then make a request — you see the log entry appear the moment it is written.

---

## 8. Symbolic Links — `ln`

A symbolic link (symlink) is a pointer to another file or directory. The file exists in one place — the symlink makes it appear somewhere else. Deleting the symlink does not delete the file. Deleting the file leaves a broken symlink.

nginx uses symlinks to manage site configs — the actual config lives in `sites-available/`, and a symlink in `sites-enabled/` points to it. Enabling a site means creating the symlink. Disabling means removing it.

```bash
# Create a symlink
ln -s (s = symbolic) /etc/nginx/sites-available/webstore /etc/nginx/sites-enabled/webstore

# What it looks like in ls -l output
ls -la /etc/nginx/sites-enabled/
# lrwxrwxrwx 1 root root 34 Apr 5 09:00 webstore -> ../sites-available/webstore
# ^                                               ^
# l = symlink                                     -> points to the real file
```

| Command | Full form | What it does |
|---|---|---|
| `ln -s <target> <link>` | Link --symbolic | Create a symlink pointing to target |
| `ls -la` | List --long --all | See symlinks — shown with `l` prefix and `->` arrow |
| `readlink <link>` | — | Show where a symlink points |
| `unlink <link>` | — | Remove a symlink without deleting the target |

---

## On the webstore

The directory structure exists from file 02. Now you write content into it, back it up, and verify every file is correct before moving forward.

```bash
# Step 1 — write the webstore config file
echo "frontend_port=80" >> ~/webstore/config/webstore.conf
echo "api_host=webstore-api" >> ~/webstore/config/webstore.conf
echo "api_port=8080" >> ~/webstore/config/webstore.conf
echo "db_host=webstore-db" >> ~/webstore/config/webstore.conf
echo "db_port=5432" >> ~/webstore/config/webstore.conf
echo "db_name=webstore" >> ~/webstore/config/webstore.conf
echo "env=production" >> ~/webstore/config/webstore.conf

# Step 2 — verify it
cat ~/webstore/config/webstore.conf
frontend_port=80
api_host=webstore-api
api_port=8080
db_host=webstore-db
db_port=5432
db_name=webstore
env=production

# Step 3 — create a placeholder log file before nginx starts
touch ~/webstore/logs/access.log
touch ~/webstore/logs/error.log

# Step 4 — check the exact metadata on the config file
stat ~/webstore/config/webstore.conf
# Modify: 2025-04-05 09:14:22  ← you will use this during incident triage

# Step 5 — back up the entire project before making any changes
cp -riv ~/webstore ~/webstore-backup
# ~/webstore -> ~/webstore-backup
# ~/webstore/config/webstore.conf -> ~/webstore-backup/config/webstore.conf
# ~/webstore/logs/access.log -> ~/webstore-backup/logs/access.log

# Step 6 — verify the backup has the same structure
ls -la ~/webstore-backup/
# config/  logs/  frontend/  api/  db/  backup/

# Step 7 — read only the first 3 lines of the config
head -n 3 ~/webstore/config/webstore.conf
frontend_port=80
api_host=webstore-api
api_port=8080
```

The webstore now has a real config file and placeholder log files. The backup exists. From here, file 04 will search and filter this config. File 05 will edit it in-place. File 07 will let you open and edit it in vim.

---

## What breaks

| Symptom | Cause | Fix |
|---|---|---|
| `cp: cannot stat: No such file or directory` | Source path does not exist or is misspelled | `ls` the source directory to confirm the exact filename |
| `cp: omitting directory` | Used `cp` without `-r` on a directory | Add `-r` — `cp -riv <src> <dest>` |
| `mv: cannot move: Permission denied` | You do not own the destination directory | Check with `ls -ld <dest>` — you may need `sudo` |
| `>` wiped a file you meant to append to | Used `>` instead of `>>` | Restore from backup — this is why you run `cp -riv` before every change |
| `rm: cannot remove: Is a directory` | Used `rm` without `-r` on a directory | Use `rm -r <dir>` — add `-f` only if you are certain |
| `tail -f` shows nothing new | The service is not writing to that file | Check `systemctl status <service>` — the service may have stopped |
| Symlink shows `->` but target is missing | The file the symlink points to was deleted | Broken symlink — recreate the target or remove the symlink with `unlink` |

---

## Daily commands

| Command | What it does |
|---|---|
| `touch <file>` | Create an empty file or update its timestamp |
| `stat <file>` | Show full metadata — size, all timestamps, permissions |
| `cat <file>` | Print entire file contents to terminal |
| `less <file>` | Scroll through a large file page by page |
| `tail -f <file>` | Follow a file live — new lines appear as they are written |
| `head -n <N> <file>` | Show the first N lines of a file |
| `cp -riv <src> <dest>` | Copy a directory safely with confirmation and visibility |
| `mv -iv <src> <dest>` | Move or rename with confirmation and visibility |
| `ln -s <target> <link>` | Create a symbolic link |
| `rm -i <file>` | Delete a file with a confirmation prompt |

---

→ **Interview questions for this topic:** [99-interview-prep → Working with Files](../99-interview-prep/README.md#working-with-files)

---
# FILE: 01. Linux – System Fundamentals/04-filter-commands/README.md
---

[Home](../README.md) |
[Boot](../01-boot-process/README.md) |
[Basics](../02-basics/README.md) |
[Files](../03-working-with-files/README.md) |
[Filters](../04-filter-commands/README.md) |
[sed](../05-sed-stream-editor/README.md) |
[awk](../06-awk/README.md) |
[vim](../07-text-editor/README.md) |
[Users](../08-user-and-group-management/README.md) |
[Permissions](../09-file-ownership-and-permissions/README.md) |
[Archive](../10-archiving-and-compression/README.md) |
[Packages](../11-package-management/README.md) |
[Services](../12-service-management/README.md) |
[Networking](../13-networking/README.md) |
[Logs](../14-logs-and-debug/README.md) |
[Interview](../99-interview-prep/README.md)

---

# Filter Commands

> **Layer:** L5 — Tools & Files
> **Depends on:** [03 Working with Files](../03-working-with-files/README.md) — you need to be able to read and navigate files before filtering them
> **Used in production when:** Something broke and you need to search thousands of log lines to find the one that matters — without opening a text editor

---

## Table of Contents

- [What this is](#what-this-is)
- [How it fits the stack](#how-it-fits-the-stack)
- [The webstore access log](#the-webstore-access-log)
- [1. The Pipe — how everything connects](#1-the-pipe--how-everything-connects)
- [2. grep — Search File Contents](#2-grep--search-file-contents)
- [3. find — Search the Filesystem](#3-find--search-the-filesystem)
- [4. locate — Fast Name Lookup](#4-locate--fast-name-lookup)
- [5. wc — Count Lines, Words, Bytes](#5-wc--count-lines-words-bytes)
- [6. cut — Extract Fields](#6-cut--extract-fields)
- [7. sort — Order Lines](#7-sort--order-lines)
- [8. uniq — Deduplicate Lines](#8-uniq--deduplicate-lines)
- [9. tr — Translate Characters](#9-tr--translate-characters)
- [10. tee — Split a Stream](#10-tee--split-a-stream)
- [On the webstore](#on-the-webstore)
- [What breaks](#what-breaks)
- [Daily commands](#daily-commands)

---

## What this is

A production server generates thousands of log lines every hour. You will never open them in a text editor. You will never scroll through them manually. Filter commands let you search, slice, count, sort, and chain operations against any file or stream directly from the terminal. The pipe `|` connects them into analysis chains that answer real questions in seconds. This is how a DevOps engineer reads a system without a GUI.

---

## How it fits the stack

```
  L6  You
  L5  Tools & Files  ← this file lives here
       grep · find · cut · sort · uniq · wc · tee · tr · pipe
  L4  Config
  L3  State & Debug   ← /var/log — the logs you filter live here
  L2  Networking
  L1  Process Manager
  L0  Kernel & Hardware
```

The logs at L3 are the raw material. The filter commands at L5 are the tools that make sense of them. Every incident investigation you run in file 14 (Logs & Debug) uses the commands you learn here.

---

## The webstore access log

Every example in this file uses this log. Save it to `~/webstore/logs/access.log` to follow along.

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

Fields: `IP  METHOD  PATH  STATUS`

---

## 1. The Pipe — how everything connects

The pipe `|` takes the output of one command and feeds it directly as input to the next. No temporary files. No intermediate steps. It turns single commands into analysis chains.

```
command1 | command2 | command3
```

Think of it as an assembly line. Each command does one job. The pipe passes the result to the next worker. The final output is the answer to your question.

```bash
# Question: how many 500 errors are in the log?
grep '500' ~/webstore/logs/access.log | wc -l
# 2

# Question: which IPs caused the 500 errors?
grep '500' ~/webstore/logs/access.log | cut -d' ' -f1
# 192.168.1.14
# 192.168.1.14
```

Every section below is a tool you add to your pipeline vocabulary.

---

## 2. grep — Search File Contents

`grep` (Global Regular Expression Print) searches inside files for lines matching a pattern. It is the most-used command in incident investigation. Every log analysis starts here.

| Flag | Full form | What it does | Example |
|---|---|---|---|
| `grep <pat> <file>` | — | Find lines matching pattern — case sensitive | `grep '500' access.log` |
| `-i` | --ignore-case | Case-insensitive match | `grep -i 'error' access.log` |
| `-n` | --line-number | Show line numbers alongside matches | `grep -n '500' access.log` |
| `-c` | --count | Count matching lines, do not print them | `grep -c '500' access.log` |
| `-v` | --invert-match | Show lines that do NOT match | `grep -v '200' access.log` |
| `-w` | --word-regexp | Match whole words only | `grep -w 'GET' access.log` |
| `-r` | --recursive | Search all files in a directory | `grep -r 'db_host' ~/webstore/config/` |

```bash
# Find all 500 errors
grep '500' ~/webstore/logs/access.log
# 192.168.1.14 POST /api/orders 500
# 192.168.1.14 POST /api/orders 500

# Count how many 500 errors occurred
grep -c '500' ~/webstore/logs/access.log
# 2

# Surface every non-200 request — all problems at once
grep -v '200' ~/webstore/logs/access.log
# 192.168.1.12 POST /api/orders 201
# 192.168.1.13 GET /api/users 404
# 192.168.1.14 POST /api/orders 500
# 192.168.1.15 DELETE /api/orders/7 403
# 192.168.1.14 POST /api/orders 500

# Search every log file in the directory
grep -r '500' ~/webstore/logs/
# access.log:192.168.1.14 POST /api/orders 500
# access.log:192.168.1.14 POST /api/orders 500
```

`grep -v '200'` on any access log immediately surfaces every non-successful request. You do not scroll — you filter.

---

## 3. find — Search the Filesystem

`find` walks the directory tree in real time and returns every file matching your criteria. Results are always current — it reads the live filesystem, not a cache.

| Option | What it does | Example |
|---|---|---|
| `-name "*.log"` | Match by filename with wildcards | `find ~/webstore/logs -name "*.log"` |
| `-type f` | Regular files only | `find ~/webstore -type f` |
| `-type d` | Directories only | `find ~/webstore -type d` |
| `-mtime +7` | Modified more than 7 days ago | `find ~/webstore/logs -mtime +7` |
| `-mtime -1` | Modified in the last 24 hours | `find ~/webstore/logs -mtime -1` |
| `-size +1M` | Larger than 1 megabyte | `find ~/webstore/logs -size +1M` |
| `-exec <cmd> {} \;` | Run a command on every match | `find ~/webstore -name "*.tmp" -exec rm {} \;` |

```bash
# Find the webstore config wherever it is
find ~/webstore -name "webstore.conf"
# /home/akhil/webstore/config/webstore.conf

# Find log files modified in the last day
find ~/webstore/logs -mtime -1 -name "*.log"
# /home/akhil/webstore/logs/access.log

# Find and delete all temp files left by a crashed process
find ~/webstore -name "*.tmp" -exec rm {} \;

# Find large log files consuming disk space
find ~/webstore/logs -size +100M
```

---

## 4. locate — Fast Name Lookup

`locate` searches a prebuilt database of filenames. Results are instant but only as fresh as the last time `updatedb` ran — usually once a day.

| Option | Full form | What it does |
|---|---|---|
| `locate <name>` | — | Find all paths containing this name |
| `-i` | --ignore-case | Case-insensitive match |
| `-l 5` | --limit | Limit results to 5 |
| `-c` | --count | Count matches only |

```bash
locate webstore.conf
# /home/akhil/webstore/config/webstore.conf

# File created in the last hour and locate cannot find it?
sudo updatedb && locate webstore.conf
```

**find vs locate — when to use which:**

| | find | locate |
|---|---|---|
| Results | Always current | Only as fresh as last `updatedb` |
| Speed | Slower on large trees | Instant |
| Filters | Name, type, size, age, owner | Name only |
| Use when | You need exact current results | You just need to know if a file exists |

---

## 5. wc — Count Lines, Words, Bytes

`wc` (Word Count) counts lines, words, and bytes in a file or stream.

| Flag | Full form | What it counts |
|---|---|---|
| `wc -l` | --lines | Lines only — most useful |
| `wc -w` | --words | Words only |
| `wc -c` | --bytes | Bytes only |

```bash
# How many lines in the access log?
wc -l ~/webstore/logs/access.log
# 10 /home/akhil/webstore/logs/access.log

# How many 500 errors? (in a pipeline)
grep '500' ~/webstore/logs/access.log | wc -l
# 2
```

`wc -l` at the end of any pipeline tells you how many results the previous command produced.

---

## 6. cut — Extract Fields

`cut` extracts specific columns from structured text. You define the delimiter with `-d` and which field to keep with `-f`. Fields are numbered from 1.

| Option | Full form | What it does |
|---|---|---|
| `-d' ' -f1` | --delimiter --fields | Split on space, take field 1 |
| `-d',' -f2` | --delimiter --fields | Split on comma, take field 2 |
| `-d' ' -f1,4` | --delimiter --fields | Take fields 1 and 4 |

```bash
# Extract IP addresses (field 1 — space delimited)
cut -d' ' -f1 ~/webstore/logs/access.log
# 192.168.1.10
# 192.168.1.11
# 192.168.1.12
# ...

# Extract status codes (field 4)
cut -d' ' -f4 ~/webstore/logs/access.log
# 200
# 200
# 201
# ...

# Extract IP and status code together
cut -d' ' -f1,4 ~/webstore/logs/access.log
# 192.168.1.10 200
# 192.168.1.11 200
# ...
```

---

## 7. sort — Order Lines

`sort` orders lines of text. It almost always appears before `uniq` — `uniq` only removes adjacent duplicates, so you must sort first to bring identical lines together.

| Flag | Full form | What it does |
|---|---|---|
| `sort` | — | Alphabetical ascending |
| `-r` | --reverse | Reverse order |
| `-n` | --numeric-sort | Sort numerically, not alphabetically |
| `-rn` | --reverse --numeric-sort | Largest numbers first |
| `-k <N>` | --key | Sort by field N |

```bash
# Sort the log by status code (field 4)
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

`uniq` removes or counts duplicate **consecutive** lines. Always run `sort` first.

| Flag | Full form | What it does |
|---|---|---|
| `uniq` | — | Remove consecutive duplicate lines |
| `-c` | --count | Prefix each line with its occurrence count |
| `-d` | --repeated | Show only lines that appeared more than once |
| `-u` | --unique | Show only lines that appeared exactly once |

**The classic combination — ranked hit count per IP:**

```bash
cut -d' ' -f1 ~/webstore/logs/access.log | sort | uniq -c | sort -rn
#   5 192.168.1.10
#   2 192.168.1.11
#   2 192.168.1.14
#   1 192.168.1.12
#   1 192.168.1.13
#   1 192.168.1.15
```

Read left to right: extract IPs → sort so identical IPs are adjacent → count and deduplicate → sort by count descending. Result: ranked list of who is hitting the API most. This same pattern works on any field — endpoints, status codes, methods.

---

## 9. tr — Translate Characters

`tr` (Translate) replaces or deletes characters in a stream. It reads from stdin — feed it with a pipe.

| Option | Full form | What it does |
|---|---|---|
| `tr 'a-z' 'A-Z'` | — | Uppercase all lowercase letters |
| `-d '0-9'` | --delete | Delete all digits |
| `-s ' '` | --squeeze-repeats | Collapse multiple spaces into one |

```bash
# Uppercase the entire log for case-insensitive comparison
cat ~/webstore/logs/access.log | tr 'a-z' 'A-Z'

# Remove digits from a stream
echo "error404" | tr -d '0-9'
# error
```

Most useful in pipelines when you need to normalise text before passing it to another command.

---

## 10. tee — Split a Stream

`tee` reads from stdin and writes to both stdout and a file simultaneously. You see the output on screen and it gets saved — without running the command twice.

| Flag | Full form | What it does |
|---|---|---|
| `tee <file>` | — | Write to stdout and file, overwriting file |
| `tee -a <file>` | --append | Write to stdout and append to file |

```bash
# Save all 500 errors to a file AND see them on screen
grep '500' ~/webstore/logs/access.log | tee ~/webstore/logs/errors.log
# 192.168.1.14 POST /api/orders 500   ← printed to terminal
# 192.168.1.14 POST /api/orders 500   ← also written to errors.log
```

Use `tee` when you want a record of your investigation without losing the ability to keep piping.

---

## On the webstore

These are the pipelines you actually run during a webstore incident.
Each one answers a specific question you will be asked.

```bash
# Question 1 — how many errors hit the API in this log?
grep '500' ~/webstore/logs/access.log | wc -l
# 2

# Question 2 — which IP is generating all the 500 errors?
grep '500' ~/webstore/logs/access.log | cut -d' ' -f1 | sort | uniq -c | sort -rn
#   2 192.168.1.14

# Question 3 — which endpoints are getting hit most?
cut -d' ' -f3 ~/webstore/logs/access.log | sort | uniq -c | sort -rn
#   5 /api/products
#   2 /api/orders
#   1 /api/users
#   1 /api/orders/7

# Question 4 — show every non-200 request with line numbers
grep -vn '200' ~/webstore/logs/access.log
# 3:192.168.1.12 POST /api/orders 201
# 5:192.168.1.13 GET /api/users 404
# 6:192.168.1.14 POST /api/orders 500
# 8:192.168.1.15 DELETE /api/orders/7 403
# 10:192.168.1.14 POST /api/orders 500

# Question 5 — save all errors to a separate file for the team
grep -v '200' ~/webstore/logs/access.log | tee ~/webstore/logs/non-200.log
# (prints to screen and saves to file simultaneously)

# Question 6 — find all log files changed in the last 24 hours
find ~/webstore/logs -mtime -1 -name "*.log"
# /home/akhil/webstore/logs/access.log

# Question 7 — find which log files contain 500 errors
find ~/webstore/logs -name "*.log" -exec grep -l '500' {} \;
# /home/akhil/webstore/logs/access.log
```

---

## What breaks

| Symptom | Cause | Fix |
|---|---|---|
| `grep` returns nothing when you expected matches | Pattern is case-sensitive and case does not match | Add `-i` for case-insensitive matching |
| `grep '500'` also matches `5000` or `15001` | Pattern matches anywhere in the line | Use `-w` for whole-word match or anchor with `\b500\b` |
| `uniq -c` not deduplicating correctly | Identical lines are not adjacent | Run `sort` before `uniq` — always |
| `cut` returns the wrong field | Fields are numbered from 1, not 0, and the delimiter may contain multiple spaces | Check the actual delimiter with `cat -A file` to see whitespace |
| `find -exec` errors with `missing argument to -exec` | Missing `\;` at the end of the exec block | Always close `-exec <cmd> {} \;` with `\;` |
| `locate` cannot find a file you just created | Database is stale — locate uses a cache | Run `sudo updatedb` then try again |
| Pipeline produces no output | An early command in the chain matched nothing | Test each command individually before piping |

---

## Daily commands

| Command | What it does |
|---|---|
| `grep '<pat>' <file>` | Find lines matching a pattern |
| `grep -v '<pat>' <file>` | Find lines that do NOT match — surfaces all problems |
| `grep -rn '<pat>' <dir>` | Search all files in a directory, show line numbers |
| `find <dir> -name "<pat>"` | Find files by name in real time |
| `find <dir> -mtime -1` | Find files modified in the last 24 hours |
| `cut -d' ' -f<N> <file>` | Extract field N from space-delimited text |
| `sort \| uniq -c \| sort -rn` | Count and rank occurrences — the core analysis pattern |
| `wc -l` | Count lines — always useful at the end of a pipeline |
| `tee <file>` | Save pipeline output to file while still seeing it on screen |
| `cmd1 \| cmd2 \| cmd3` | Chain commands — each feeds the next |

---

→ **Interview questions for this topic:** [99-interview-prep → Filter Commands](../99-interview-prep/README.md#filter-commands)

---
# FILE: 01. Linux – System Fundamentals/05-sed-stream-editor/README.md
---

[Home](../README.md) |
[Boot](../01-boot-process/README.md) |
[Basics](../02-basics/README.md) |
[Files](../03-working-with-files/README.md) |
[Filters](../04-filter-commands/README.md) |
[sed](../05-sed-stream-editor/README.md) |
[awk](../06-awk/README.md) |
[vim](../07-text-editor/README.md) |
[Users](../08-user-and-group-management/README.md) |
[Permissions](../09-file-ownership-and-permissions/README.md) |
[Archive](../10-archiving-and-compression/README.md) |
[Packages](../11-package-management/README.md) |
[Services](../12-service-management/README.md) |
[Networking](../13-networking/README.md) |
[Logs](../14-logs-and-debug/README.md) |
[Interview](../99-interview-prep/README.md)

---

# sed — Stream Editor

> **Layer:** L5 — Tools & Files
> **Depends on:** [04 Filter Commands](../04-filter-commands/README.md) — you need grep and pipes before sed makes sense
> **Used in production when:** A deploy script needs to update a config file without opening an editor — swap `env=production` to `env=staging`, update a port, strip comment lines before parsing

---

## Table of Contents

- [What this is](#what-this-is)
- [How it fits the stack](#how-it-fits-the-stack)
- [The webstore config file](#the-webstore-config-file)
- [1. How sed works](#1-how-sed-works)
- [2. Substitution — the core operation](#2-substitution--the-core-operation)
- [3. Targeting specific lines](#3-targeting-specific-lines)
- [4. In-place editing](#4-in-place-editing)
- [5. Deleting lines](#5-deleting-lines)
- [6. Printing specific lines](#6-printing-specific-lines)
- [7. Inserting and appending lines](#7-inserting-and-appending-lines)
- [8. Running multiple commands](#8-running-multiple-commands)
- [On the webstore](#on-the-webstore)
- [What breaks](#what-breaks)
- [Daily commands](#daily-commands)

---

## What this is

`grep` finds lines. `cut` extracts fields. `sed` transforms content. It reads a file or stream one line at a time, applies your editing instruction, and outputs the result — without opening an editor, without moving a cursor, without touching the file unless you tell it to. You describe the change once and sed applies it to every matching line. This is how deploy scripts update config files, how you strip comment lines before parsing, and how you make the same change across hundreds of lines in one command.

---

## How it fits the stack

```
  L6  You
  L5  Tools & Files  ← this file lives here
       sed — transforms files and streams without opening an editor
  L4  Config  ← /etc/webstore/webstore.conf — the files sed edits
  L3  State & Debug
  L2  Networking
  L1  Process Manager
  L0  Kernel & Hardware
```

sed sits between you and the config files at L4. When a deploy script needs to switch an environment value or update a port in `/etc/nginx/nginx.conf`, sed is the tool that makes that change programmatically — no manual editing, no risk of human error, reproducible every time.

---

## The webstore config file

Every example in this file uses this config. It lives at `~/webstore/config/webstore.conf` — you created it in file 03.

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

## 1. How sed works

sed reads a file one line at a time. For each line it checks whether your pattern matches, applies the instruction if it does, then prints the result. By default it prints every line — changed or not. The original file is untouched unless you use `-i`.

```
sed 'instruction' file

instruction = [address] command
  address = which lines to act on (optional — default is all lines)
  command = what to do (substitute, delete, print, insert)
```

**Key flags:**

| Flag | Full form | What it does |
|---|---|---|
| `-n` | --quiet | Suppress automatic printing — only print lines you explicitly request with `p` |
| `-i` | --in-place | Write changes back to the original file |
| `-e` | --expression | Chain multiple instructions in one command |

---

## 2. Substitution — the core operation

The substitution command is the one you use 90% of the time:

```
s/OLD/NEW/flags
│ │   │   │
│ │   │   └── flags: g = global (all matches), p = print changed lines
│ │   └────── replacement text
│ └────────── pattern to find
└──────────── s = substitute
```

**Replace first match per line:**

```bash
sed 's/production/staging/' ~/webstore/config/webstore.conf
# db_host=webstore-db
# db_port=5432
# api_port=8080
# api_host=webstore-api
# frontend_port=80
# frontend_host=webstore-frontend
# env=staging          ← only this line changed
```

The file is not modified — output goes to terminal only.

**Replace all matches per line with `g` (global):**

```bash
sed 's/webstore/mystore/g' ~/webstore/config/webstore.conf
# db_host=mystore-db
# api_host=mystore-api
# frontend_host=mystore-frontend
# env=production
```

Without `g`, only the first match per line is replaced. With `g`, every match on every line is replaced.

**When the pattern contains `/`, use a different delimiter:**

```bash
# This breaks — forward slash conflicts with the sed delimiter
sed 's/api/v2/api/g' webstore.conf

# Use # as delimiter instead — any char not in your pattern works
sed 's#/api#/v2/api#g' webstore.conf

# Other common choices: | and @
sed 's|production|staging|g' webstore.conf
```

---

## 3. Targeting specific lines

By default sed acts on every line. You can restrict it with a line number, a range, or a pattern.

**Line number:**

```bash
# Replace only on line 1
sed '1 s/db_host/database_host/' ~/webstore/config/webstore.conf
# database_host=webstore-db   ← only line 1 changed
# db_port=5432
# ...
```

**Line range:**

```bash
# Replace on lines 1 through 3 only
sed '1,3 s/webstore/mystore/' ~/webstore/config/webstore.conf
# db_host=mystore-db
# db_port=5432
# api_port=8080
# api_host=webstore-api       ← unchanged, line 4
```

**From line N to end of file (`$` = last line):**

```bash
sed '3,$ s/webstore/mystore/' ~/webstore/config/webstore.conf
```

**Only lines matching a pattern:**

```bash
# Only replace on lines that contain "port"
sed '/port/ s/8080/9090/' ~/webstore/config/webstore.conf
# db_host=webstore-db
# db_port=5432               ← contains "port" but 5432 not matched
# api_port=9090              ← changed
# frontend_port=80           ← contains "port" but 80 not matched
```

**Print only lines where substitution happened (`-n` + `p` flag):**

```bash
sed -n 's/production/staging/p' ~/webstore/config/webstore.conf
# env=staging
```

`-n` suppresses all output. `p` prints only lines that were actually changed. Together: confirmation of exactly what sed touched.

---

## 4. In-place editing

Everything above only prints the result — the original file is not modified. `-i` writes changes back to the file.

```bash
# Change production to staging directly in the file
sed -i 's/production/staging/' ~/webstore/config/webstore.conf
```

After this, `webstore.conf` is permanently changed. No undo unless you have a backup.

**Always back up before in-place editing:**

```bash
# Step 1 — back up first
cp ~/webstore/config/webstore.conf ~/webstore/backup/webstore.conf.bak

# Step 2 — then edit in-place
sed -i 's/production/staging/' ~/webstore/config/webstore.conf

# Step 3 — verify the change landed
grep 'env' ~/webstore/config/webstore.conf
# env=staging
```

> **macOS difference:** `-i` requires an empty string argument on macOS: `sed -i '' 's/old/new/' file`. On Linux no empty string is needed. If your script runs on both, use `sed -i'' 's/old/new/' file` — works on both.

---

## 5. Deleting lines

```bash
# Delete all lines containing "frontend"
sed '/frontend/d' ~/webstore/config/webstore.conf
# db_host=webstore-db
# db_port=5432
# api_port=8080
# api_host=webstore-api
# env=production

# Delete lines starting with # (strip all comments)
sed '/^#/d' ~/webstore/config/webstore.conf

# Delete the last line ($ = last line, d = delete)
sed '$d' ~/webstore/config/webstore.conf

# Delete lines 5 through end
sed '5,$d' ~/webstore/config/webstore.conf
```

`^` matches the start of a line. `$` alone means the last line. `/pattern/d` deletes every line containing that pattern.

---

## 6. Printing specific lines

With `-n` and `p` you can extract exactly the lines you need — more targeted than `head` or `tail`.

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

## 7. Inserting and appending lines

```bash
# Insert a line BEFORE line 1 (i = insert)
sed '1i\# webstore config — do not edit manually' ~/webstore/config/webstore.conf
# # webstore config — do not edit manually   ← inserted before line 1
# db_host=webstore-db
# ...

# Append a line AFTER the last line (a = append)
sed '$a\log_level=info' ~/webstore/config/webstore.conf
# ...
# env=production
# log_level=info   ← appended after last line

# Insert in-place — write it back
sed -i '1i\# webstore config — do not edit manually' ~/webstore/config/webstore.conf
```

---

## 8. Running multiple commands

`-e` chains multiple instructions in a single sed pass. One read of the file, multiple transformations applied.

```bash
# Swap environment AND update the API port in one command
sed -e 's/production/staging/' -e 's/api_port=8080/api_port=9090/' ~/webstore/config/webstore.conf
# db_host=webstore-db
# db_port=5432
# api_port=9090              ← changed
# api_host=webstore-api
# frontend_port=80
# frontend_host=webstore-frontend
# env=staging                ← changed
```

Cleaner than running sed twice and faster on large files — the file is read only once.

---

## On the webstore

Deploy day. The webstore needs to switch from production to staging config.
You update the config file programmatically — no editor, no manual steps.

```bash
# Step 1 — confirm current state
cat ~/webstore/config/webstore.conf
# env=production
# api_port=8080

# Step 2 — back up before any change
cp ~/webstore/config/webstore.conf ~/webstore/backup/webstore.conf.bak

# Step 3 — switch to staging in one command
sed -i -e 's/production/staging/' -e 's/api_port=8080/api_port=9090/' \
  ~/webstore/config/webstore.conf

# Step 4 — verify both changes landed
grep -E 'env|api_port' ~/webstore/config/webstore.conf
# api_port=9090
# env=staging

# Step 5 — add a header comment to the config
sed -i '1i\# webstore staging config — generated by deploy script' \
  ~/webstore/config/webstore.conf

# Step 6 — verify the final file
cat ~/webstore/config/webstore.conf
# # webstore staging config — generated by deploy script
# db_host=webstore-db
# db_port=5432
# api_port=9090
# api_host=webstore-api
# frontend_port=80
# frontend_host=webstore-frontend
# env=staging

# Step 7 — to roll back, restore from backup
cp ~/webstore/backup/webstore.conf.bak ~/webstore/config/webstore.conf
grep 'env' ~/webstore/config/webstore.conf
# env=production
```

---

## What breaks

| Symptom | Cause | Fix |
|---|---|---|
| `sed: 1: "s/old/new/"`: extra characters | macOS sed requires `sed -i ''` not `sed -i` | Use `sed -i ''` on macOS, `sed -i` on Linux |
| Substitution silently does nothing | Pattern does not match — case mismatch or wrong field | Run without `-i` first to preview output, add `-i` only when confirmed |
| `s/path/to/file/replacement/` breaks | Forward slash in pattern conflicts with delimiter | Switch delimiter: `s#path/to/file#replacement#` |
| `-i` changed the file and you cannot undo | No backup was made | Restore from version control or backup — this is why you `cp` first |
| `uniq` not working after sed | Lines not adjacent after transformation | Add `sort` before `uniq` in the pipeline |
| `sed -n '/pattern/p'` prints nothing | Pattern does not match | Test the pattern with `grep 'pattern' file` first to confirm it works |
| Multi-line sed produces unexpected output | sed processes one line at a time by default | For multi-line transformations use `N` command or switch to awk |

---

## Daily commands

| Command | What it does |
|---|---|
| `sed 's/OLD/NEW/' <file>` | Replace first match per line — preview only, no file change |
| `sed 's/OLD/NEW/g' <file>` | Replace all matches per line — preview only |
| `sed -n 's/OLD/NEW/p' <file>` | Preview only the lines that would change |
| `sed -i 's/OLD/NEW/' <file>` | Replace and write back to file — always back up first |
| `sed -i -e 's/A/B/' -e 's/C/D/' <file>` | Multiple replacements in one pass |
| `sed '/^#/d' <file>` | Strip all comment lines |
| `sed -n '2,4p' <file>` | Print only lines 2 through 4 |
| `sed -n '/pattern/p' <file>` | Print only lines matching pattern |
| `sed '$a\new line' <file>` | Append a line at the end |
| `sed 's#/old/path#/new/path#g' <file>` | Replace paths — use `#` delimiter to avoid slash conflicts |

---

→ **Interview questions for this topic:** [99-interview-prep → sed](../99-interview-prep/README.md#sed)

---
# FILE: 01. Linux – System Fundamentals/06-awk/README.md
---

[Home](../README.md) |
[Boot](../01-boot-process/README.md) |
[Basics](../02-basics/README.md) |
[Files](../03-working-with-files/README.md) |
[Filters](../04-filter-commands/README.md) |
[sed](../05-sed-stream-editor/README.md) |
[awk](../06-awk/README.md) |
[vim](../07-text-editor/README.md) |
[Users](../08-user-and-group-management/README.md) |
[Permissions](../09-file-ownership-and-permissions/README.md) |
[Archive](../10-archiving-and-compression/README.md) |
[Packages](../11-package-management/README.md) |
[Services](../12-service-management/README.md) |
[Networking](../13-networking/README.md) |
[Logs](../14-logs-and-debug/README.md) |
[Interview](../99-interview-prep/README.md)

---

# awk — Text Processing

> **Layer:** L5 — Tools & Files
> **Depends on:** [05 sed](../05-sed-stream-editor/README.md) — you need pipes, grep, and field thinking before awk
> **Used in production when:** You need to calculate totals from a log, build a report from raw text, or filter rows by the exact value of a specific field — things grep and cut cannot do alone

---

## Table of Contents

- [What this is](#what-this-is)
- [How it fits the stack](#how-it-fits-the-stack)
- [The webstore access log](#the-webstore-access-log)
- [1. How awk works](#1-how-awk-works)
- [2. Built-in variables](#2-built-in-variables)
- [3. Printing fields](#3-printing-fields)
- [4. Pattern matching](#4-pattern-matching)
- [5. Custom field separator](#5-custom-field-separator)
- [6. Conditionals](#6-conditionals)
- [7. Arithmetic and aggregation](#7-arithmetic-and-aggregation)
- [8. BEGIN and END blocks](#8-begin-and-end-blocks)
- [9. awk vs cut — when to use which](#9-awk-vs-cut--when-to-use-which)
- [On the webstore](#on-the-webstore)
- [What breaks](#what-breaks)
- [Daily commands](#daily-commands)

---

## What this is

`cut` extracts columns. `grep` finds lines. `sed` transforms content. `awk` does all three at once — and adds arithmetic. It reads a file line by line, splits each line into numbered fields, and lets you filter rows, extract specific fields, compute totals, and format output in a single command. The reason awk exists separately from the other filter tools is calculation — when you need the total bytes transferred across all 200 responses, or the average response time across a thousand requests, awk does it in one line. No spreadsheet. No Python script.

---

## How it fits the stack

```
  L6  You
  L5  Tools & Files  ← this file lives here
       awk — field extraction + filtering + arithmetic in one command
  L4  Config  ← webstore.conf — awk reads this with -F '='
  L3  State & Debug  ← /var/log — the logs awk analyses
  L2  Networking
  L1  Process Manager
  L0  Kernel & Hardware
```

awk is the last tool in the text processing chain — grep narrows the lines, cut or awk extracts the fields, awk calculates the numbers. Every incident report you produce from a log file ends with awk.

---

## The webstore access log

This log adds a bytes field compared to the filter commands file. Save it to `~/webstore/logs/access.log`.

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

Fields: `$1`=IP · `$2`=method · `$3`=path · `$4`=status · `$5`=bytes

---

## 1. How awk works

awk reads a file one line at a time. Each line is a **record**. Each record is automatically split into **fields** — by whitespace by default. You write rules:

```
awk 'PATTERN { ACTION }' file
     │         │
     │         └── what to do: print fields, calculate, format
     └──────────── condition to test — if true, action runs
                   if omitted, action runs on every line
```

The simplest awk command:

```bash
awk '{ print }' ~/webstore/logs/access.log
# 192.168.1.10 GET /api/products 200 512
# 192.168.1.11 GET /api/products 200 489
# ...
```

No pattern means match everything. `print` with no arguments prints the whole line (`$0`). Identical to `cat` — but now you understand the structure everything else builds on.

---

## 2. Built-in variables

These are available in every awk program without being defined:

| Variable | What it holds | Value for line `192.168.1.10 GET /api/products 200 512` |
|---|---|---|
| `$0` | The entire current line | `192.168.1.10 GET /api/products 200 512` |
| `$1` | Field 1 | `192.168.1.10` |
| `$2` | Field 2 | `GET` |
| `$3` | Field 3 | `/api/products` |
| `$4` | Field 4 | `200` |
| `$5` | Field 5 | `512` |
| `NR` | Current line number (Number of Record) | `1` on first line, `2` on second |
| `NF` | Number of fields in current line (Number of Fields) | `5` for this log format |
| `FS` | Field separator — default whitespace | Set with `-F` flag or in BEGIN block |

---

## 3. Printing fields

```bash
# Print only the IP address (field 1)
awk '{ print $1 }' ~/webstore/logs/access.log
# 192.168.1.10
# 192.168.1.11
# 192.168.1.12
# ...

# Print IP and status code with default space separator
awk '{ print $1, $4 }' ~/webstore/logs/access.log
# 192.168.1.10 200
# 192.168.1.11 200
# 192.168.1.12 201
# ...

# Print with custom text between fields
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

**Comma vs string concatenation:**
`print $1, $4` puts a space between fields (comma = space separator).
`print $1 $4` joins them with nothing between.
`print $1 " → " $4` puts custom text between them.

---

## 4. Pattern matching

A pattern before `{ }` filters which lines trigger the action. Only matching lines run the action block.

```bash
# Print all lines containing "500" anywhere
awk '/500/ { print }' ~/webstore/logs/access.log
# 192.168.1.14 POST /api/orders 500 256
# 192.168.1.14 POST /api/orders 500 256

# Print IP and path for 500 errors only
awk '/500/ { print $1, $3 }' ~/webstore/logs/access.log
# 192.168.1.14 /api/orders
# 192.168.1.14 /api/orders

# Match on a specific field — only lines where field 4 is exactly "500"
awk '$4 == "500" { print }' ~/webstore/logs/access.log
# 192.168.1.14 POST /api/orders 500 256
# 192.168.1.14 POST /api/orders 500 256
```

**`/500/` vs `$4 == "500"` — why it matters:**
`/500/` matches any line containing `500` anywhere — a path like `/api/v500/orders` would match too.
`$4 == "500"` matches only when field 4 is exactly `500`. More precise. Use field matching when you know which column holds the value.

---

## 5. Custom field separator

When your file uses a delimiter other than whitespace, set it with `-F`.

```bash
# webstore.conf uses = as the separator
# db_host=webstore-db
# db_port=5432

# Print only the values (field 2, split on =)
awk -F '=' '{ print $2 }' ~/webstore/config/webstore.conf
# webstore-db
# 5432
# 8080
# webstore-api
# 80
# webstore-frontend
# production

# Print formatted key → value pairs
awk -F '=' '{ print "KEY: " $1 "  VALUE: " $2 }' ~/webstore/config/webstore.conf
# KEY: db_host  VALUE: webstore-db
# KEY: db_port  VALUE: 5432
# ...

# /etc/passwd uses : — print username (field 1) and shell (field 7)
awk -F ':' '{ print $1, $7 }' /etc/passwd
# root /bin/bash
# daemon /usr/sbin/nologin
# akhil /bin/bash
```

---

## 6. Conditionals

`if` inside the action block applies logic beyond simple pattern matching.

```bash
# Print lines where bytes transferred is greater than 500
awk '{ if ($5 > 500) print $1, $3, $5 }' ~/webstore/logs/access.log
# 192.168.1.12 /api/orders 1024
# 192.168.1.10 /api/products 512
# 192.168.1.10 /api/products 512
# 192.168.1.10 /api/products 512

# Print lines where status is NOT 200
awk '{ if ($4 != "200") print $0 }' ~/webstore/logs/access.log
```

The pattern form is more idiomatic awk and reads more cleanly:

```bash
# These two are equivalent — second is preferred
awk '{ if ($4 == "500") print $0 }' access.log
awk '$4 == "500" { print }' access.log
```

Use `if` when the condition is complex or when you need `else`. Use the pattern form for simple single-condition filtering.

---

## 7. Arithmetic and aggregation

This is what separates awk from every other filter tool. Variables persist across lines — you accumulate values as awk reads through the file.

```bash
# Sum total bytes transferred across all requests
awk '{ total += $5 } END { print "Total bytes:", total }' ~/webstore/logs/access.log
# Total bytes: 4242

# Count 500 errors (count++ increments by 1 each time condition matches)
awk '$4 == "500" { count++ } END { print "500 errors:", count }' ~/webstore/logs/access.log
# 500 errors: 2

# Sum bytes for successful requests only
awk '$4 == "200" { total += $5 } END { print "Bytes from 200s:", total }' ~/webstore/logs/access.log
# Bytes from 200s: 2514

# Calculate average bytes per request (NR = total line count at END)
awk '{ total += $5 } END { print "Average bytes:", total/NR }' ~/webstore/logs/access.log
# Average bytes: 424.2
```

**How accumulation works:**
`total += $5` adds field 5 of the current line to `total`. Since `total` starts at zero and this runs on every line, by the time `END` runs, `total` holds the sum of every value in field 5 across the entire file. `count++` works the same way — increments by 1 each time the condition is true.

---

## 8. BEGIN and END blocks

`BEGIN` runs once before any lines are read. `END` runs once after all lines are processed.

```bash
# Full report with header and summary
awk '
  BEGIN { print "--- Webstore Access Report ---" }
  { print $1, $4, $5 }
  END   { print "--- Total requests:", NR, "---" }
' ~/webstore/logs/access.log
# --- Webstore Access Report ---
# 192.168.1.10 200 512
# 192.168.1.11 200 489
# 192.168.1.12 201 1024
# ...
# --- Total requests: 10 ---

# Requests per IP using an associative array
awk '{ count[$1]++ } END { for (ip in count) print count[ip], ip }' \
  ~/webstore/logs/access.log | sort -rn
# 3 192.168.1.10
# 2 192.168.1.14
# 2 192.168.1.11
# 1 192.168.1.15
# 1 192.168.1.13
# 1 192.168.1.12

# Total bytes per status code
awk '{ bytes[$4] += $5 } END { for (s in bytes) print s, bytes[s] }' \
  ~/webstore/logs/access.log | sort
# 200 2514
# 201 1024
# 403 64
# 404 128
# 500 512
```

`count[$1]++` uses an associative array — `$1` (the IP address) is the key, the value increments each time that IP appears. `END` then loops over every key and prints the result.

---

## 9. awk vs cut — when to use which

| Situation | Use |
|---|---|
| Extract one field, simple delimiter | `cut` — faster syntax |
| Extract multiple fields with custom text between them | `awk` |
| Filter rows by the exact value of a field | `awk` |
| Calculate totals, averages, counts | `awk` — `cut` cannot do this |
| Process a config file with `=` or `:` delimiter | Either — `awk -F '='` or `cut -d'='` |
| Build a per-key count or report | `awk` — `cut` has no aggregation |

---

## On the webstore

The webstore has been running. Logs have accumulated.
You need to produce a full incident report from the access log.

```bash
# Step 1 — total requests and total bytes transferred
awk '{ requests++; total += $5 } END { print "Requests:", requests; print "Total bytes:", total }' \
  ~/webstore/logs/access.log
# Requests: 10
# Total bytes: 4242

# Step 2 — count requests per status code
awk '{ count[$4]++ } END { for (s in count) print s, count[s] }' \
  ~/webstore/logs/access.log | sort
# 200 5
# 201 1
# 403 1
# 404 1
# 500 2

# Step 3 — which IPs caused the 500 errors?
awk '$4 == "500" { print $1 }' ~/webstore/logs/access.log | sort | uniq -c | sort -rn
#   2 192.168.1.14

# Step 4 — which endpoints are taking the most bytes?
awk '{ bytes[$3] += $5 } END { for (p in bytes) print bytes[p], p }' \
  ~/webstore/logs/access.log | sort -rn
# 1536 /api/products
# 1024 /api/orders
# 256 /api/orders
# 128 /api/users
# 64 /api/orders/7

# Step 5 — full formatted report
awk '
  BEGIN {
    printf "%-18s %-8s %-25s %-6s %s\n", "IP", "METHOD", "PATH", "STATUS", "BYTES"
    print "----------------------------------------------------------------------"
  }
  { printf "%-18s %-8s %-25s %-6s %s\n", $1, $2, $3, $4, $5 }
  END { print "----------------------------------------------------------------------"; print "Total requests:", NR }
' ~/webstore/logs/access.log
# IP                 METHOD   PATH                      STATUS BYTES
# ----------------------------------------------------------------------
# 192.168.1.10       GET      /api/products             200    512
# ...
# ----------------------------------------------------------------------
# Total requests: 10
```

---

## What breaks

| Symptom | Cause | Fix |
|---|---|---|
| `awk: syntax error` on a pattern | Missing quotes around string comparison — `$4 == 500` vs `$4 == "500"` | String values need quotes: `$4 == "500"`. Numbers do not: `$5 > 500` |
| Field extraction returns nothing | Wrong field number — fields start at `$1` not `$0` | `$0` is the whole line. Fields start at `$1`. Check with `awk '{ print NF }' file` to see field count |
| `-F` not splitting correctly | Delimiter has special meaning in regex | Escape it: `awk -F '\.'` for dot, `awk -F '\|'` for pipe |
| `END` block shows wrong totals | Action ran on header line or blank lines | Filter them out: `NR > 1 { total += $5 }` skips line 1 |
| Associative array output is unsorted | awk arrays have no guaranteed order | Pipe to `sort` after the END block |
| `print $1 $4` joins fields with no space | Missing comma between field references | Use `print $1, $4` (comma = space) or `print $1 " " $4` |

---

## Daily commands

| Command | What it does |
|---|---|
| `awk '{ print $1 }' <file>` | Print field 1 from every line |
| `awk '{ print $1, $4 }' <file>` | Print fields 1 and 4 with space between |
| `awk '$4 == "500" { print }' <file>` | Print lines where field 4 equals exactly 500 |
| `awk -F '=' '{ print $2 }' <file>` | Use `=` as delimiter — print values from config files |
| `awk -F ':' '{ print $1, $7 }' /etc/passwd` | Print username and shell for every user |
| `awk '{ total += $5 } END { print total }' <file>` | Sum all values in field 5 |
| `awk '$4=="500"{ c++ } END{ print c }' <file>` | Count lines where field 4 is 500 |
| `awk '{ total += $5 } END { print total/NR }' <file>` | Average of field 5 across all lines |
| `awk '{ count[$1]++ } END { for (k in count) print count[k], k }' <file>` | Count occurrences per unique value in field 1 |
| `awk 'BEGIN{print "header"} { print } END{print "footer"}' <file>` | Wrap output with header and footer |

---

→ **Interview questions for this topic:** [99-interview-prep → awk](../99-interview-prep/README.md#awk)

---
# FILE: 01. Linux – System Fundamentals/07-text-editor/README.md
---

[Home](../README.md) |
[Boot](../01-boot-process/README.md) |
[Basics](../02-basics/README.md) |
[Files](../03-working-with-files/README.md) |
[Filters](../04-filter-commands/README.md) |
[sed](../05-sed-stream-editor/README.md) |
[awk](../06-awk/README.md) |
[vim](../07-text-editor/README.md) |
[Users](../08-user-and-group-management/README.md) |
[Permissions](../09-file-ownership-and-permissions/README.md) |
[Archive](../10-archiving-and-compression/README.md) |
[Packages](../11-package-management/README.md) |
[Services](../12-service-management/README.md) |
[Networking](../13-networking/README.md) |
[Logs](../14-logs-and-debug/README.md) |
[Interview](../99-interview-prep/README.md)

---

# vim — Terminal Text Editor

> **Layer:** L5 — Tools & Files
> **Depends on:** [02 Basics](../02-basics/README.md) — you need to navigate the filesystem before editing files on it
> **Used in production when:** You SSH into a server and need to edit a config file — no GUI, no VS Code, just the terminal

---

## Table of Contents

- [What this is](#what-this-is)
- [How it fits the stack](#how-it-fits-the-stack)
- [1. The three modes](#1-the-three-modes)
- [2. Opening and exiting](#2-opening-and-exiting)
- [3. Navigation](#3-navigation)
- [4. Editing](#4-editing)
- [5. Search and replace](#5-search-and-replace)
- [On the webstore](#on-the-webstore)
- [What breaks](#what-breaks)
- [Daily commands](#daily-commands)

---

## What this is

On a remote Linux server there is no GUI. No VS Code, no Sublime, no Notepad. When you need to edit a config file, fix a broken nginx config, or write a quick script, you use a terminal editor. `vim` is the one you find on every Linux server — it ships with the OS or is one package install away. The reason vim feels hard at first is that it is **modal** — it has separate modes for navigating and for typing. Once that mental model clicks, vim becomes fast. This file gives you everything you need to be productive with vim on a real server.

---

## How it fits the stack

```
  L6  You
  L5  Tools & Files  ← this file lives here
       vim — the editor you use when no GUI exists
  L4  Config  ← /etc/nginx/ /etc/systemd/ — the files you edit with vim
  L3  State & Debug
  L2  Networking
  L1  Process Manager
  L0  Kernel & Hardware
```

Every config file at L4 gets edited with vim. The nginx config from file 12, the systemd unit file, the webstore.conf — all opened and changed with the commands in this file.

---

## 1. The three modes

vim starts in **Normal mode** every time you open it. This is the source of most beginner frustration — you open a file, start typing, and nothing appears where you expect it to.

```
Normal mode  ←─────────────── Esc ───────────────┐
     │                                            │
     │  i / a / o                                 │
     ▼                                            │
Insert mode  ── type your content ────────────────┘

Normal mode
     │
     │  :
     ▼
Command-line mode  ── :w  :q  :wq  :q!  :%s/old/new/g
```

| Mode | How to enter | What you do here |
|---|---|---|
| Normal | Default on open, or `Esc` from anywhere | Navigate, delete, copy, paste — keys are commands not text |
| Insert | `i`, `a`, or `o` from Normal | Type text — keyboard behaves like a normal editor |
| Command-line | `:` from Normal | Save, quit, search and replace |

**The rule that prevents most frustration:** when vim is not behaving as expected, press `Esc` first. `Esc` always returns you to Normal mode from anywhere.

---

## 2. Opening and exiting

```bash
# Open a file
vim ~/webstore/config/webstore.conf

# Open and jump directly to line 12 (e.g. error on line 12)
vim +12 ~/webstore/config/nginx.conf

# Open a new file — created on first save
vim ~/webstore/config/new-setting.conf
```

**Exiting — the commands everyone needs first:**

| Command | What it does |
|---|---|
| `:w` | Write (save) the file — stay in vim |
| `:q` | Quit — only works if no unsaved changes |
| `:wq` | Write and quit — save then exit |
| `:q!` | Quit without saving — discard all changes, no questions asked |
| `:x` | Write and quit — same as `:wq` but skips write if nothing changed |

`:q!` is the one you reach for when you opened the wrong file or made changes you want to throw away.

---

## 3. Navigation

In Normal mode the keyboard is for movement. These are the keys you use to move around a file without a mouse.

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
| `NG` | Jump to line N — e.g. `12G` jumps to line 12 |

**Prepend a number to repeat any movement:**
`5j` moves down 5 lines. `3w` jumps forward 3 words. `12G` jumps to line 12.

**When you reach for `NG`:**
An error says "syntax error on line 47 of nginx.conf" — type `47G` in Normal mode and you land exactly there.

---

## 4. Editing

**Entering Insert mode:**

| Key | Where typing begins |
|---|---|
| `i` | Before the cursor |
| `a` | After the cursor |
| `o` | New line below the current line |
| `O` | New line above the current line |

Press `Esc` after typing to return to Normal mode.

**Editing without Insert mode:**

| Command | What it does |
|---|---|
| `x` | Delete the character under the cursor |
| `dd` | Delete (cut) the entire current line |
| `D` | Delete from cursor to end of line |
| `cw` | Delete the current word and enter Insert mode |
| `yy` | Yank (copy) the current line |
| `Nyy` | Yank N lines — `3yy` copies 3 lines |
| `p` | Paste after the cursor / below the current line |
| `u` | Undo the last change |
| `Ctrl+R` | Redo — reverse an undo |

**The most useful editing sequence:** `dd` to cut a line, navigate to where you want it, `p` to paste. Reorder config lines without retyping them.

---

## 5. Search and replace

**Search:**

```
/pattern     search forward — n = next match, N = previous
?pattern     search backward
```

```bash
# Inside vim — search for the api_port line
/api_port
# n to jump to next match, N to go back
```

**Replace — command-line substitute:**

```
:%s/OLD/NEW/g
│  │   │   │
│  │   │   └── g = global, replace all on each line
│  │   └────── replacement
│  └────────── pattern to find
└────────────── % = entire file (without % = current line only)
```

```bash
# Replace every "production" with "staging" in the entire file
:%s/production/staging/g

# Replace with confirmation for each match — vim shows y/n prompt
:%s/production/staging/gc

# Replace only on the current line
:s/8080/9090/g

# Replace only on lines 2 through 5
:2,5s/8080/9090/g
```

---

## On the webstore

```bash
# Scenario 1 — edit the webstore config to change the API port
vim ~/webstore/config/webstore.conf
# /api_port          search for the line
# cw                 delete the word and enter Insert
# api_port=9090      type the new value
# Esc                back to Normal
# :wq                save and quit

# Verify the change
grep 'api_port' ~/webstore/config/webstore.conf
# api_port=9090

# Scenario 2 — nginx config has a syntax error on line 12
vim ~/webstore/config/nginx.conf
# 12G                jump directly to line 12
# fix the error, Esc, :wq

# Scenario 3 — add a new config entry at the end
vim ~/webstore/config/webstore.conf
# G                  jump to last line
# o                  new line below, enter Insert
# log_level=info     type the new entry
# Esc
# :wq

# Scenario 4 — replace the old database hostname everywhere
vim ~/webstore/config/webstore.conf
# :%s/webstore-db-old/webstore-db/g
# :wq

# Verify
grep 'db_host' ~/webstore/config/webstore.conf
# db_host=webstore-db
```

---

## What breaks

| Symptom | Cause | Fix |
|---|---|---|
| Typed text appears as commands | You are in Normal mode, not Insert | Press `i` to enter Insert mode before typing |
| Can't quit vim | Unsaved changes blocking `:q` | `:wq` to save and quit, or `:q!` to quit without saving |
| `:wq` says "readonly file" | File is owned by root or has no write permission | Quit with `:q!`, then `sudo vim <file>` or fix permissions first |
| Typed `:wq` but text appeared in file | You were in Insert mode when you typed `:` | Press `Esc` first, then `:wq` |
| Search not finding text | Pattern is case-sensitive | Add `\c` for case-insensitive: `/\cpattern` |
| `:%s` replaced wrong text | Pattern matched more than you intended | Use `:%s/old/new/gc` to confirm each replacement before applying |
| `u` undo not working as expected | vim undo history has a limit | Use version control — commit before making large changes |

---

## Daily commands

| Command | What it does |
|---|---|
| `vim <file>` | Open a file in vim |
| `vim +<N> <file>` | Open file and jump to line N |
| `Esc` | Return to Normal mode from anywhere |
| `i` | Enter Insert mode before cursor |
| `o` | New line below, enter Insert mode |
| `:wq` | Save and quit |
| `:q!` | Quit without saving |
| `NG` | Jump to line N in Normal mode |
| `/pattern` | Search forward — `n` next, `N` previous |
| `:%s/OLD/NEW/gc` | Replace all with confirmation |

---

→ **Interview questions for this topic:** [99-interview-prep → vim](../99-interview-prep/README.md#vim)

---
# FILE: 01. Linux – System Fundamentals/08-user-and-group-management/README.md
---

[Home](../README.md) |
[Boot](../01-boot-process/README.md) |
[Basics](../02-basics/README.md) |
[Files](../03-working-with-files/README.md) |
[Filters](../04-filter-commands/README.md) |
[sed](../05-sed-stream-editor/README.md) |
[awk](../06-awk/README.md) |
[vim](../07-text-editor/README.md) |
[Users](../08-user-and-group-management/README.md) |
[Permissions](../09-file-ownership-and-permissions/README.md) |
[Archive](../10-archiving-and-compression/README.md) |
[Packages](../11-package-management/README.md) |
[Services](../12-service-management/README.md) |
[Networking](../13-networking/README.md) |
[Logs](../14-logs-and-debug/README.md) |
[Interview](../99-interview-prep/README.md)

---

# User & Group Management

> **Layer:** L4 — Config
> **Depends on:** [02 Basics](../02-basics/README.md) — you need `whoami` and `id` before managing other users
> **Used in production when:** Setting up a new server, adding a team member, creating a service account for nginx or docker, or auditing who has access to what

---

## Table of Contents

- [What this is](#what-this-is)
- [How it fits the stack](#how-it-fits-the-stack)
- [1. How Linux identifies users](#1-how-linux-identifies-users)
- [2. Key system files](#2-key-system-files)
- [3. UID ranges — who is who](#3-uid-ranges--who-is-who)
- [4. User management](#4-user-management)
- [5. Group management](#5-group-management)
- [On the webstore](#on-the-webstore)
- [What breaks](#what-breaks)
- [Daily commands](#daily-commands)

---

## What this is

Every process on a Linux server runs as a user. Every file is owned by a user and a group. This is not bureaucracy — it is the access control model that prevents a compromised web server from reading your database credentials, and prevents a developer's script from accidentally deleting system files. When nginx serves the webstore frontend, it runs as `www-data` — a system user with no shell, no home directory, and read-only access to exactly the files it needs. Understanding users and groups is understanding who is allowed to do what on the machine.

---

## How it fits the stack

```
  L6  You  ← /home/akhil  /home/charan  /home/pramod  /home/navya  /home/indhu
  L5  Tools & Files
  L4  Config  ← this file lives here
       /etc/passwd  /etc/shadow  /etc/group  /etc/gshadow
  L3  State & Debug
  L2  Networking
  L1  Process Manager  ← services run as specific users defined at L4
  L0  Kernel & Hardware
```

Users are defined at L4 (/etc). They live at L6 (/home). Services at L1 run under those users. Permissions in file 09 enforce what each user can access. All four layers are connected by this one concept.

---

## 1. How Linux identifies users

Linux does not track users by name — it tracks them by **UID** (User ID), a number. When you run `ls -l` and see `akhil` as the owner, Linux is storing UID `1000` and your terminal is resolving it to a name for readability. The same is true for groups — every group has a **GID** (Group ID).

Every process has a UID. That UID determines what files the process can read, write, or execute. A process running as root (UID 0) can access anything. This is why services should never run as root — a compromised root process means full system compromise.

---

## 2. Key system files

These four files define every user and group on the system. Read them often. Never edit them directly — use the commands in section 4 and 5 instead.

| File | What it contains | Who can read |
|---|---|---|
| `/etc/passwd` | One line per user: username, UID, GID, home dir, shell | Everyone |
| `/etc/shadow` | Hashed passwords and password aging | Root only |
| `/etc/group` | One line per group: name, GID, member list | Everyone |
| `/etc/gshadow` | Encrypted group passwords and admins | Root only |

**Reading `/etc/passwd`:**

```bash
grep www-data /etc/passwd
# www-data:x:33:33:www-data:/var/www:/usr/sbin/nologin
#          │     │  │        │         └── shell: nologin = cannot log in interactively
#          │     │  │        └── home directory
#          │     │  └── GID
#          │     └── UID
#          └── x = password is in /etc/shadow
```

`/usr/sbin/nologin` as the shell means this user cannot log in interactively. Intentional for service accounts — nginx does not need a shell.

**Reading `/etc/group`:**

```bash
grep webstore-team /etc/group
# webstore-team:x:3000:www-data,akhil,charan,pramod
#               │  │    └── comma-separated member list
#               │  └── GID
#               └── password placeholder
```

---

## 3. UID ranges — who is who

| Range | Purpose | Examples |
|---|---|---|
| `0` | Root — full system access | `root` |
| `1–999` | System accounts — services, no login shell | `www-data` (33), `postgres` (999) |
| `1000+` | Human users — login shell, home directory | `akhil` (1000), `charan` (1001) |

When you install nginx, it creates `www-data` automatically in the system range. When you create `akhil`, they get UID 1000+. This separation is intentional — services and humans should never share an identity.

---

## 4. User management

**Creating a user:**

```bash
# -m (--create-home) creates /home/akhil
# -s (--shell) sets the login shell
sudo useradd -m -s /bin/bash akhil

# Set the password
sudo passwd akhil
# New password:
# Retype new password:
# passwd: password updated successfully
```

**Modifying a user:**

```bash
# -aG (--append --groups) adds to a group — the -a is critical
sudo usermod -aG webstore-team akhil

# Without -a it REPLACES all groups — user loses all other access
# Always use -aG never -G alone

# Change login shell
sudo usermod -s /bin/bash akhil

# Change username
sudo usermod -l charan-new charan
```

**Deleting a user:**

```bash
# Delete user, keep /home/akhil — useful when preserving files
sudo userdel akhil

# Delete user AND remove /home/akhil and mail spool
sudo userdel --remove akhil
```

**Checking users:**

```bash
# Your UID, GID, and every group you belong to
id
# uid=1000(akhil) gid=1000(akhil) groups=1000(akhil),27(sudo),3000(webstore-team)

# Another user's info
id charan

# All groups a user belongs to
groups akhil
# akhil : akhil sudo webstore-team docker
```

---

## 5. Group management

Groups give multiple users the same access to a resource without duplicating permissions. Instead of giving akhil, charan, and pramod individual write access to the webstore directory, you create `webstore-team`, give the directory group write access, and add all three to the group.

```bash
# Create a group
sudo groupadd webstore-team

# Create with specific GID
sudo groupadd -g 3000 webstore-team

# Add a user to a group
sudo gpasswd -a akhil webstore-team
sudo gpasswd -a charan webstore-team
sudo gpasswd -a pramod webstore-team

# Remove a user from a group
sudo gpasswd -d akhil webstore-team

# Rename a group
sudo groupmod -n webstore-devs webstore-team

# Delete a group
sudo groupdel webstore-devs

# Confirm group membership
getent group webstore-team
# webstore-team:x:3000:akhil,charan,pramod

# Apply new group in current session without re-login
newgrp webstore-team
```

---

## On the webstore

The webstore needs specific users and groups set up before permissions can be locked down in file 09.

```bash
# Step 1 — confirm nginx is running as www-data
ps aux | grep nginx
# www-data  1234  ...  nginx: worker process

# Step 2 — create the webstore team group
sudo groupadd -g 3000 webstore-team

# Step 3 — add the developers
sudo gpasswd -a akhil webstore-team
sudo gpasswd -a charan webstore-team
sudo gpasswd -a pramod webstore-team

# Step 4 — add www-data so nginx can read webstore files
sudo gpasswd -a www-data webstore-team

# Step 5 — navya and indhu are designers, different group
sudo groupadd -g 3001 design-team
sudo gpasswd -a navya design-team
sudo gpasswd -a indhu design-team

# Step 6 — only akhil gets sudo
# (akhil was given sudo during initial user creation — verify)
groups akhil
# akhil : akhil sudo webstore-team

# Step 7 — confirm the full webstore-team membership
getent group webstore-team
# webstore-team:x:3000:akhil,charan,pramod,www-data

# Step 8 — verify nobody else has unexpected access
cat /etc/passwd | grep -v nologin | grep -v false | awk -F: '$3 >= 1000 {print $1, $3}'
# akhil 1000
# charan 1001
# pramod 1002
# navya 1003
# indhu 1004
```

File 09 (Permissions) picks up from here — now that the right users and groups exist, you can lock down which directories each one can access.

---

## What breaks

| Symptom | Cause | Fix |
|---|---|---|
| `useradd: user already exists` | Username taken | Pick a different name or `userdel` the old one first |
| `usermod -G group user` removed all other groups | Used `-G` without `-a` | Always use `-aG` — `-G` alone replaces all group memberships |
| Group change not taking effect in current session | Linux caches group membership at login | Run `newgrp <group>` or log out and back in |
| `userdel: user is currently logged in` | User has an active session | `pkill -u username` to kill their session first |
| Service still runs as wrong user after config change | systemd caches the unit — restart needed | `sudo systemctl daemon-reload && sudo systemctl restart <service>` |
| `getent group <group>` shows no members | Users were added with `usermod -aG` but didn't re-login | Check with `id <user>` — shows current session groups. Have them re-login. |

---

## Daily commands

| Command | What it does |
|---|---|
| `sudo useradd -m -s /bin/bash <user>` | Create user with home directory and bash shell |
| `sudo passwd <user>` | Set or change a user's password |
| `sudo usermod -aG <group> <user>` | Add user to group — always use `-aG` never `-G` alone |
| `sudo userdel --remove <user>` | Delete user and their home directory |
| `sudo groupadd <group>` | Create a new group |
| `sudo gpasswd -a <user> <group>` | Add user to group |
| `sudo gpasswd -d <user> <group>` | Remove user from group |
| `getent group <group>` | Show group members |
| `groups <user>` | List all groups a user belongs to |
| `newgrp <group>` | Switch active group in current session without re-login |

---

→ **Interview questions for this topic:** [99-interview-prep → Users & Groups](../99-interview-prep/README.md#users-and-groups)

---
# FILE: 01. Linux – System Fundamentals/09-file-ownership-and-permissions/README.md
---

[Home](../README.md) |
[Boot](../01-boot-process/README.md) |
[Basics](../02-basics/README.md) |
[Files](../03-working-with-files/README.md) |
[Filters](../04-filter-commands/README.md) |
[sed](../05-sed-stream-editor/README.md) |
[awk](../06-awk/README.md) |
[vim](../07-text-editor/README.md) |
[Users](../08-user-and-group-management/README.md) |
[Permissions](../09-file-ownership-and-permissions/README.md) |
[Archive](../10-archiving-and-compression/README.md) |
[Packages](../11-package-management/README.md) |
[Services](../12-service-management/README.md) |
[Networking](../13-networking/README.md) |
[Logs](../14-logs-and-debug/README.md) |
[Interview](../99-interview-prep/README.md)

---

# File Ownership & Permissions

> **Layer:** L4 — Config
> **Depends on:** [08 Users & Groups](../08-user-and-group-management/README.md) — you need users and groups before you can assign ownership
> **Used in production when:** nginx cannot read the webstore config, a deploy script cannot write to the logs directory, or you need to lock down files containing database passwords

---

## Table of Contents

- [What this is](#what-this-is)
- [How it fits the stack](#how-it-fits-the-stack)
- [1. The permission model](#1-the-permission-model)
- [2. Reading ls -l output](#2-reading-ls--l-output)
- [3. Numeric permissions — the octal system](#3-numeric-permissions--the-octal-system)
- [4. chmod — changing permissions](#4-chmod--changing-permissions)
- [5. chown and chgrp — changing ownership](#5-chown-and-chgrp--changing-ownership)
- [6. Special permissions — SUID SGID sticky](#6-special-permissions--suid-sgid-sticky)
- [7. umask — default permissions](#7-umask--default-permissions)
- [On the webstore](#on-the-webstore)
- [What breaks](#what-breaks)
- [Daily commands](#daily-commands)

---

## What this is

Every file on a Linux system has an owner, a group, and a set of permissions. These three things together answer one question: who is allowed to do what with this file. This is not abstract security theory. When nginx cannot read the webstore config file, it is a permissions problem. When a deploy script cannot write to the logs directory, it is a permissions problem. When a developer accidentally deletes a shared file, a missing sticky bit is the reason. Understanding permissions is understanding why services fail and how to fix them.

---

## How it fits the stack

```
  L6  You  ← /home/akhil owned by akhil:akhil chmod 700
  L5  Tools & Files
  L4  Config  ← this file lives here
       chmod chown chgrp — control access to every file on the system
  L3  State & Debug
  L2  Networking
  L1  Process Manager  ← nginx runs as www-data — must have read on config
  L0  Kernel & Hardware
```

Permissions connect users (file 08) to the files they can access. Without correct permissions, services fail to read their configs, processes cannot write their logs, and security is broken.

---

## 1. The permission model

Every file has three sets of permissions — owner, group, and others (everyone else).

```
-rw-r--r--  1  akhil  webstore-team  1.2K  webstore.conf
│└────────┘     │      │
│               │      └── group
│               └── owner
└── file type: - = file, d = directory, l = symlink
```

Each set has three bits:

```
OWNER   GROUP   OTHERS
r w x   r w x   r w x
│ │ │
│ │ └── execute: run file as program / enter directory
│ └──── write:   modify file / create+delete files in directory
└────── read:    read file contents / list directory contents
```

**The directory execute bit is the one people miss.** A directory with `r` but no `x` lets you see filenames with `ls` but you cannot `cd` into it or access any files inside. You need `x` to enter a directory.

---

## 2. Reading ls -l output

```bash
ls -lh ~/webstore/
# drwxr-xr-x  2  akhil  webstore-team  4.0K  config/
# drwxrwsr-x  2  akhil  webstore-team  4.0K  logs/
# -rw-r-----  1  akhil  webstore-team   128  config/webstore.conf
```

Decoding `drwxr-xr-x`:
- `d` — directory
- `rwx` — owner (akhil): read, write, enter
- `r-x` — group (webstore-team): read and enter, no write
- `r-x` — others: read and enter, no write

Decoding `-rw-r-----`:
- `-` — regular file
- `rw-` — owner: read and write
- `r--` — group: read only
- `---` — others: no access at all

---

## 3. Numeric permissions — the octal system

Each bit has a value. Add them for each set.

| Value | Bit | Meaning |
|---|---|---|
| 4 | `r` | read |
| 2 | `w` | write |
| 1 | `x` | execute |

**The permissions you use most in production:**

| Octal | Symbolic | Use case |
|---|---|---|
| `600` | `rw-------` | SSH private keys, credential files — owner only |
| `640` | `rw-r-----` | Config files with secrets — owner writes, group reads |
| `644` | `rw-r--r--` | Public config files — owner writes, everyone reads |
| `664` | `rw-rw-r--` | Shared files — owner and group write |
| `700` | `rwx------` | Private scripts and directories |
| `750` | `rwxr-x---` | Directories — owner full, group enters, others nothing |
| `755` | `rwxr-xr-x` | Public directories and executables |
| `770` | `rwxrwx---` | Shared directories — owner and group full access |
| `777` | `rwxrwxrwx` | Full access for everyone — almost never correct in production |

**Reading `640` as three digits:**
`6` = owner gets rw- (4+2=6) · `4` = group gets r-- (4) · `0` = others get --- (0)

---

## 4. chmod — changing permissions

**Octal mode — set exact permissions:**

```bash
# Config file with secrets — owner reads+writes, group reads, others nothing
chmod 640 ~/webstore/config/webstore.conf

# Logs directory — owner and group can write (nginx writes here)
chmod 770 ~/webstore/logs/

# Frontend files — nginx reads these, so others need read
chmod 644 ~/webstore/frontend/index.html
chmod 755 ~/webstore/frontend/

# Deploy script — only owner executes
chmod 700 ~/webstore/api/deploy.sh

# Recursively set entire directory tree
chmod -R 755 ~/webstore/
```

**Symbolic mode — add or remove specific bits:**

```bash
# u = user/owner, g = group, o = others, a = all three
# + adds, - removes, = sets exactly

chmod u+x deploy.sh        # add execute for owner only
chmod o-w webstore.conf    # remove write from others
chmod g+w logs/            # add write for group
chmod o= webstore.conf     # set others to no permissions
chmod a+r index.html       # add read for everyone
```

**Octal vs symbolic — when to use which:**
Octal sets the complete final state — use it when you know exactly what permissions should be.
Symbolic makes a targeted change without resetting everything else — use it when you want to add or remove one bit.

---

## 5. chown and chgrp — changing ownership

```bash
# Change both owner and group
sudo chown akhil:webstore-team ~/webstore/config/webstore.conf

# Change owner only
sudo chown akhil ~/webstore/logs/access.log

# Change group only
sudo chgrp webstore-team ~/webstore/config/

# Change recursively — entire directory tree
sudo chown -R akhil:webstore-team ~/webstore/
```

`sudo` is required — only root can change a file's owner. A regular user can change the group of files they own, but only to groups they belong to.

---

## 6. Special permissions — SUID SGID sticky

**SGID on a directory (the one you use most):**

Any new files created inside inherit the directory's group instead of the creator's primary group. Essential for shared team directories — every file created in `~/webstore/logs/` automatically belongs to `webstore-team` regardless of who created it.

```bash
# Set SGID on logs directory
sudo chmod g+s ~/webstore/logs/
ls -ld ~/webstore/logs/
# drwxrwsr-x  akhil  webstore-team  logs/
#       ^
#       s in group execute position = SGID set
```

**Sticky bit on a directory:**

Only the file's owner, the directory owner, or root can delete files inside — even if the directory is world-writable. `/tmp` always has this set.

```bash
sudo chmod +t ~/webstore/logs/
ls -ld ~/webstore/logs/
# drwxrwxrwt  logs/
#          ^
#          t = sticky bit
```

**SUID on an executable (informational — you read this, rarely set it):**

The file runs with the file owner's privileges regardless of who launches it. Classic example: `/usr/bin/passwd` runs as root so any user can update their own password in `/etc/shadow`.

```bash
ls -l /usr/bin/passwd
# -rwsr-xr-x  root  root  /usr/bin/passwd
#    ^
#    s in owner execute position = SUID set
```

---

## 7. umask — default permissions

When a new file or directory is created, Linux starts from a maximum and subtracts the umask.

- Files start at `666` (no execute) → umask `022` → result `644`
- Directories start at `777` → umask `022` → result `755`
- umask `027` → files get `640`, directories get `750`

```bash
# Check current umask
umask
# 0022

# Set more restrictive for current session
umask 027

# Make permanent
echo 'umask 027' >> ~/.bashrc
```

`027` matters for deploy scripts that create config files — default `022` makes them world-readable. Any user on the server could read your database password. `027` means only owner and group can read new files.

---

## On the webstore

This is the complete permission setup for the webstore. Every number has a reason.

```bash
# Step 1 — set ownership — akhil owns, webstore-team is the group
sudo chown -R akhil:webstore-team ~/webstore/

# Step 2 — directories — owner full, group enters and reads, others nothing
chmod 750 ~/webstore/
chmod 750 ~/webstore/config/
chmod 750 ~/webstore/api/
chmod 750 ~/webstore/db/

# Step 3 — logs directory — owner and group write (nginx writes as www-data)
chmod 770 ~/webstore/logs/

# Step 4 — config file with secrets — owner rw, group r, others nothing
chmod 640 ~/webstore/config/webstore.conf

# Step 5 — frontend — nginx needs read, so others need read too
chmod 755 ~/webstore/frontend/
chmod 644 ~/webstore/frontend/index.html

# Step 6 — deploy script — only owner executes
chmod 700 ~/webstore/api/deploy.sh

# Step 7 — SGID on logs — nginx files inherit webstore-team group automatically
sudo chmod g+s ~/webstore/logs/

# Step 8 — verify everything
ls -lah ~/webstore/
# drwxr-x--- akhil webstore-team  .          ← 750
# drwxrwx--- akhil webstore-team  logs/      ← 770
# drwxr-x--- akhil webstore-team  config/    ← 750
# -rw-r----- akhil webstore-team  config/webstore.conf  ← 640
# -rwx------ akhil webstore-team  api/deploy.sh         ← 700
```

**Why `640` on webstore.conf and not `644`:**
`644` would let any user on the server read the config — including the database password. `640` means only `akhil` and members of `webstore-team` can read it. nginx runs as `www-data` which is a member of `webstore-team`, so it can read the config. Random users cannot.

---

## What breaks

| Symptom | Cause | Fix |
|---|---|---|
| `nginx: [warn] could not open error log file: Permission denied` | nginx cannot write to the logs directory | `chmod 770 ~/webstore/logs/` and verify www-data is in webstore-team |
| `curl localhost` returns 403 Forbidden | nginx can reach the directory but cannot read the files | `chmod 644` on the HTML files and `chmod 755` on the directory |
| `Permission denied` when running a script | Script lacks execute permission | `chmod u+x script.sh` |
| `chown: changing ownership: Operation not permitted` | Only root can change file owners | `sudo chown user:group file` |
| New files in shared dir owned by wrong group | SGID not set on the directory | `sudo chmod g+s <directory>` |
| `chmod -R 777` used and now it feels wrong | World-writable files are a security risk | Set properly: `chmod -R 750` for dirs, `chmod -R 640` for files |

---

## Daily commands

| Command | What it does |
|---|---|
| `ls -lah <dir>` | See permissions, owner, group for all files including hidden |
| `chmod 640 <file>` | Set exact permissions — owner rw, group r, others nothing |
| `chmod u+x <file>` | Add execute for owner only |
| `chmod -R 755 <dir>` | Set permissions recursively on directory tree |
| `sudo chown <user>:<group> <file>` | Change owner and group |
| `sudo chown -R <user>:<group> <dir>` | Change ownership recursively |
| `sudo chmod g+s <dir>` | SGID — new files inside inherit directory's group |
| `chmod +t <dir>` | Sticky bit — only owners can delete inside |
| `umask` | Show current default permissions |
| `ls -li <dir>` | Show inode numbers alongside file details |

---

→ **Interview questions for this topic:** [99-interview-prep → Permissions](../99-interview-prep/README.md#permissions)

---
# FILE: 01. Linux – System Fundamentals/10-archiving-and-compression/README.md
---

[Home](../README.md) |
[Boot](../01-boot-process/README.md) |
[Basics](../02-basics/README.md) |
[Files](../03-working-with-files/README.md) |
[Filters](../04-filter-commands/README.md) |
[sed](../05-sed-stream-editor/README.md) |
[awk](../06-awk/README.md) |
[vim](../07-text-editor/README.md) |
[Users](../08-user-and-group-management/README.md) |
[Permissions](../09-file-ownership-and-permissions/README.md) |
[Archive](../10-archiving-and-compression/README.md) |
[Packages](../11-package-management/README.md) |
[Services](../12-service-management/README.md) |
[Networking](../13-networking/README.md) |
[Logs](../14-logs-and-debug/README.md) |
[Interview](../99-interview-prep/README.md)

---

# Archiving and Compression

> **Layer:** L5 — Tools & Files
> **Depends on:** [03 Working with Files](../03-working-with-files/README.md) — you need cp and mv before you need tar
> **Used in production when:** Backing up the webstore before a deploy, compressing old logs to free disk space, transferring the entire project to a new server in one file

---

## Table of Contents

- [What this is](#what-this-is)
- [How it fits the stack](#how-it-fits-the-stack)
- [1. Archiving vs compression](#1-archiving-vs-compression)
- [2. tar — the standard tool](#2-tar--the-standard-tool)
- [3. gzip — compressing single files](#3-gzip--compressing-single-files)
- [4. Reading compressed files without extracting](#4-reading-compressed-files-without-extracting)
- [5. zip and unzip](#5-zip-and-unzip)
- [On the webstore](#on-the-webstore)
- [What breaks](#what-breaks)
- [Daily commands](#daily-commands)

---

## What this is

Before every deploy, you archive the current state of the webstore. Before rotating logs, you compress last month's access log. When you need to move the entire project to a new server, you pack it into one file and transfer it. These are not optional practices — they are the habits that let you recover when something goes wrong. This file covers two distinct operations that are often confused: **archiving** (combining multiple files into one, no size reduction) and **compression** (reducing a file's size). `tar` archives. `gzip` compresses. Used together — `tar.gz` — you get both.

---

## How it fits the stack

```
  L6  You
  L5  Tools & Files  ← this file lives here
       tar gzip zcat zip — pack, compress, and restore
  L4  Config
  L3  State & Debug  ← /var/log — the logs you compress live here
  L2  Networking
  L1  Process Manager
  L0  Kernel & Hardware
```

Archiving is the safety net under every other layer. Before you edit a config at L4 or restart a service at L1, you tar the project. If something breaks, you restore from the archive.

---

## 1. Archiving vs compression

| Tool | What it does | Output |
|---|---|---|
| `tar` | Combines files into one archive — no compression | `.tar` |
| `gzip` | Compresses a single file — replaces original | `.gz` |
| `tar + gzip` | Archives and compresses in one step — the Linux standard | `.tar.gz` |
| `zip` | Archives and compresses — cross-platform | `.zip` |

**The rule on Linux servers:** use `tar.gz`. It preserves file permissions, ownership, symlinks, and directory structure — everything you need to restore a backup to an identical state. `zip` does not preserve Unix permissions reliably, which matters when your webstore has carefully set `chmod` values.

---

## 2. tar — the standard tool

`tar` reads like a sentence — what to do, what to name the result, what to include.

**The flags you use constantly:**

| Flag | Full form | Meaning |
|---|---|---|
| `c` | --create | Create a new archive |
| `x` | --extract | Extract from an archive |
| `t` | --list | List contents without extracting |
| `z` | --gzip | Compress or decompress with gzip |
| `v` | --verbose | Print each file as it is processed |
| `f` | --file | Next argument is the archive filename — always required |
| `-C` | --directory | Extract to a specific directory |

Flag order: `-czvf archive.tar.gz source/` — flags first, archive name second, source last.

**Create a compressed archive:**

```bash
# Archive + compress the webstore
tar -czvf webstore-backup.tar.gz ~/webstore/
# webstore/
# webstore/config/
# webstore/config/webstore.conf
# webstore/logs/access.log
# ...

# With a timestamp — essential when keeping multiple backups
tar -czvf webstore-backup-$(date +%Y-%m-%d).tar.gz ~/webstore/
# Creates: webstore-backup-2025-04-05.tar.gz
```

**List contents without extracting — always do this before extracting:**

```bash
tar -tzvf webstore-backup-2025-04-05.tar.gz
# drwxr-xr-x akhil/webstore-team    0  2025-04-05  webstore/
# -rw-r----- akhil/webstore-team  128  2025-04-05  webstore/config/webstore.conf
# -rw-rw---- akhil/webstore-team 2.4K  2025-04-05  webstore/logs/access.log
```

Note permissions and ownership are preserved. This confirms the archive contains what you expect before extracting.

**Extract:**

```bash
# Extract to current directory
tar -xzvf webstore-backup-2025-04-05.tar.gz

# Extract to a specific directory — always safer
tar -xzvf webstore-backup-2025-04-05.tar.gz -C /tmp/restore/

# Extract a single file from the archive
tar -xzvf webstore-backup-2025-04-05.tar.gz webstore/config/webstore.conf
```

`-C` is important — without it tar extracts relative to your current directory. With it you control exactly where things land.

---

## 3. gzip — compressing single files

`gzip` compresses one file and replaces it with a `.gz` version. The original file is gone after compression.

```bash
# Compress last month's log — original replaced
gzip ~/webstore/logs/access.log.old
ls -lh ~/webstore/logs/
# -rw-rw-r-- akhil webstore-team 312K access.log.old.gz
# (was 1.8M — 80% reduction typical for log files)

# Keep the original — do not replace it (-k = --keep)
gzip -k ~/webstore/logs/access.log

# Maximum compression (-9 = slowest but smallest)
gzip -9 ~/webstore/logs/error.log.old

# Decompress — restores original file
gunzip ~/webstore/logs/access.log.old.gz
```

Log files compress extremely well — 60-85% reduction — because they contain repetitive text.

---

## 4. Reading compressed files without extracting

You do not have to decompress a log to search it. These commands work directly on `.gz` files:

```bash
# Print entire compressed log to terminal
zcat ~/webstore/logs/access.log.gz

# Page through it
zless ~/webstore/logs/access.log.gz

# Search inside without extracting
zcat ~/webstore/logs/access.log.gz | grep '500'

# Count errors in compressed log
zcat ~/webstore/logs/access.log.gz | grep -c '500'
# 2
```

This is the pattern for historical log analysis. Keep old logs compressed to save disk space, use `zcat` to query them without decompressing to disk.

---

## 5. zip and unzip

Use `zip` when sharing files with Windows systems or APIs that expect `.zip`. Between Linux servers, use `tar.gz`.

```bash
# Zip specific files
zip webstore-logs.zip ~/webstore/logs/access.log ~/webstore/logs/error.log

# Zip a directory recursively (-r = --recurse-paths)
zip -r webstore-config.zip ~/webstore/config/

# List contents without extracting
unzip -l webstore-config.zip

# Extract
unzip webstore-config.zip

# Extract to specific directory (-d = destination)
unzip webstore-config.zip -d /tmp/restore/
```

---

## On the webstore

This is the backup workflow you run before every significant change.

```bash
# Step 1 — create a timestamped backup before the deploy
tar -czvf ~/webstore/backup/webstore-$(date +%Y-%m-%d-%H%M).tar.gz \
    --exclude='~/webstore/backup' \
    ~/webstore/

# Step 2 — verify the archive — list contents and check for key files
tar -tzvf ~/webstore/backup/webstore-2025-04-05-0914.tar.gz | grep 'webstore.conf'
# -rw-r----- akhil/webstore-team 128 2025-04-05 webstore/config/webstore.conf

# Step 3 — check the backup size is reasonable
ls -lh ~/webstore/backup/
# -rw-r--r-- akhil akhil 42K webstore-2025-04-05-0914.tar.gz

# Step 4 — make the change (e.g. edit nginx config)
# ...

# Step 5 — if something breaks, restore
tar -xzvf ~/webstore/backup/webstore-2025-04-05-0914.tar.gz -C /tmp/restore/
ls /tmp/restore/webstore/
# config/  logs/  frontend/  api/  db/  backup/

# Step 6 — compress old logs monthly to free disk space
find ~/webstore/logs/ -name "*.log" -mtime +30 -exec gzip {} \;
ls -lh ~/webstore/logs/
# access.log.gz  error.log.gz  access.log (current month — not compressed)
```

---

## What breaks

| Symptom | Cause | Fix |
|---|---|---|
| `tar: Removing leading / from member names` | tar strips absolute paths by default | Expected behaviour — extract to a specific dir with `-C /target/` |
| Extracted files have wrong permissions | Used `zip` instead of `tar.gz` | Use `tar.gz` for Linux backups — zip does not preserve Unix permissions |
| Archive is missing files | `--exclude` pattern too broad | Test with `-t` list before extracting to see what is inside |
| `gzip: access.log: already has .gz suffix` | Trying to compress an already compressed file | Check with `file access.log.gz` — already compressed |
| `tar -xzvf` extracts to current directory and overwrites files | Missing `-C` flag | Always use `-C /tmp/restore/` to extract to a safe location first |
| Disk fills up with old `.tar.gz` files | No backup rotation | Add `find backup/ -mtime +30 -name "*.tar.gz" -delete` after creating new backup |

---

## Daily commands

| Command | What it does |
|---|---|
| `tar -czvf <archive>.tar.gz <source>` | Create compressed archive |
| `tar -tzvf <archive>.tar.gz` | List archive contents without extracting |
| `tar -xzvf <archive>.tar.gz -C <dir>` | Extract to a specific directory |
| `tar -czvf backup-$(date +%Y-%m-%d).tar.gz <source>` | Create timestamped backup |
| `gzip <file>` | Compress a file — original replaced by .gz |
| `gzip -k <file>` | Compress keeping the original |
| `gunzip <file>.gz` | Decompress a .gz file |
| `zcat <file>.gz \| grep <pattern>` | Search inside compressed file without extracting |
| `zless <file>.gz` | Page through compressed file |
| `zip -r <archive>.zip <dir>` | Zip a directory for cross-platform sharing |

---

→ **Interview questions for this topic:** [99-interview-prep → Archiving](../99-interview-prep/README.md#archiving)

---
# FILE: 01. Linux – System Fundamentals/11-package-management/README.md
---

[Home](../README.md) |
[Boot](../01-boot-process/README.md) |
[Basics](../02-basics/README.md) |
[Files](../03-working-with-files/README.md) |
[Filters](../04-filter-commands/README.md) |
[sed](../05-sed-stream-editor/README.md) |
[awk](../06-awk/README.md) |
[vim](../07-text-editor/README.md) |
[Users](../08-user-and-group-management/README.md) |
[Permissions](../09-file-ownership-and-permissions/README.md) |
[Archive](../10-archiving-and-compression/README.md) |
[Packages](../11-package-management/README.md) |
[Services](../12-service-management/README.md) |
[Networking](../13-networking/README.md) |
[Logs](../14-logs-and-debug/README.md) |
[Interview](../99-interview-prep/README.md)

---

# Package Management

> **Layer:** L5 — Tools & Files
> **Depends on:** [02 Basics](../02-basics/README.md) — you need basic navigation before installing software
> **Used in production when:** Installing nginx, updating the server, removing a package cleanly, or auditing what is installed on an unfamiliar server

---

## Table of Contents

- [What this is](#what-this-is)
- [How it fits the stack](#how-it-fits-the-stack)
- [1. What a package manager does](#1-what-a-package-manager-does)
- [2. APT — Debian and Ubuntu](#2-apt--debian-and-ubuntu)
- [3. YUM and DNF — RHEL CentOS Fedora](#3-yum-and-dnf--rhel-centos-fedora)
- [4. Comparing package managers](#4-comparing-package-managers)
- [On the webstore](#on-the-webstore)
- [What breaks](#what-breaks)
- [Daily commands](#daily-commands)

---

## What this is

On a Linux server you never download software from a website and run an installer. You use the package manager — a tool that fetches verified software from trusted repositories, resolves all dependencies automatically, and tracks everything it installed so it can be cleanly removed later. This is how nginx gets on the webstore server. One command. No manual download. No guessing which libraries it needs. The package manager handles all of it.

---

## How it fits the stack

```
  L6  You
  L5  Tools & Files  ← this file lives here
       apt yum dnf — install and manage all software on the system
  L4  Config  ← /etc/apt/sources.list — where apt looks for packages
  L3  State & Debug  ← /var/cache/apt/ /var/lib/dpkg/ — package state lives here
  L2  Networking
  L1  Process Manager  ← systemd unit files created by packages land at L1
  L0  Kernel & Hardware
```

When you run `apt install nginx`, it downloads the package, installs the binary to `/usr/bin/`, puts the config in `/etc/nginx/`, and registers `nginx.service` with systemd at L1. One command touches four layers.

---

## 1. What a package manager does

A **package** is a bundle containing everything a piece of software needs — the binary, its libraries, default config files, and documentation. The package manager handles four things you would otherwise do manually:

- **Installation** — downloads the package and puts every file in the right place
- **Dependency resolution** — figures out what other packages this one needs and installs those too
- **Verification** — checks GPG signatures to confirm the package has not been tampered with
- **Removal** — tracks every file installed so it can cleanly remove them later

**Two ecosystems on Linux:**

| Ecosystem | Format | Manager | Used on |
|---|---|---|---|
| Debian | `.deb` | `apt` | Ubuntu, Debian — what this runbook uses |
| Red Hat | `.rpm` | `yum` / `dnf` | RHEL, CentOS, Fedora, Amazon Linux |

Ubuntu is the AWS EC2 default and what this runbook uses throughout. You will see both in real jobs.

---

## 2. APT — Debian and Ubuntu

APT (Advanced Package Tool) manages packages on Ubuntu. Package lists live in `/etc/apt/sources.list` and `/etc/apt/sources.list.d/`. The index must be updated manually before installing.

**The install sequence — always in this order:**

```bash
# Step 1 — refresh the package index
# Does NOT install anything — just updates what apt knows is available
sudo apt update

# Step 2 — install
sudo apt install nginx
# apt resolves dependencies, downloads, installs in correct order
# creates www-data user, puts config in /etc/nginx/, registers systemd service
```

Never skip `apt update` before installing. Without it you may install a stale version, or apt may fail to find a dependency that was recently renamed.

**Full APT command set:**

| Command | What it does | When you reach for it |
|---|---|---|
| `sudo apt update` | Refresh package index — fetch latest available versions | Before every install or upgrade |
| `sudo apt install <pkg>` | Install a package and its dependencies | Installing nginx, curl, vim, git |
| `sudo apt install <pkg>=<version>` | Install a specific version | Pinning nginx to match production |
| `sudo apt upgrade -y` | Upgrade all installed packages | Routine server maintenance |
| `sudo apt remove <pkg>` | Remove package, keep config files | Removing nginx while keeping `/etc/nginx/` for reinstall |
| `sudo apt purge <pkg>` | Remove package AND all config files | Complete clean uninstall |
| `sudo apt autoremove` | Remove unused dependency packages | After removing a package that pulled in many deps |
| `sudo apt clean` | Delete downloaded `.deb` files from cache | Freeing disk space |
| `apt list --installed` | List all installed packages | Auditing what is on a server |
| `apt show <pkg>` | Show details — version, size, dependencies | Before installing, check what you are getting |
| `apt search <keyword>` | Search available packages | Finding the right package name |

**`remove` vs `purge` — when it matters:**
`apt remove nginx` removes the binary but leaves `/etc/nginx/` intact — if you reinstall later your config is still there.
`apt purge nginx` removes everything including configs — nothing left behind.
Use `remove` when you plan to reinstall. Use `purge` for a complete clean uninstall.

---

## 3. YUM and DNF — RHEL CentOS Fedora

YUM is the package manager on older Red Hat systems (RHEL 7, CentOS 7). DNF replaced it on RHEL 8+, Fedora, and Amazon Linux 2023.

**YUM (CentOS / RHEL 7):**

```bash
sudo yum install nginx       # install
sudo yum update -y           # upgrade all packages
sudo yum remove nginx        # remove
sudo yum clean all           # clear cached data
sudo yum list installed      # list installed packages
```

**DNF (Fedora / RHEL 8+ / Amazon Linux 2023):**

```bash
sudo dnf install nginx       # install
sudo dnf upgrade -y          # upgrade all packages
sudo dnf remove nginx        # remove
sudo dnf clean all           # clear cached data
sudo dnf list installed      # list installed packages
```

Key difference from APT: YUM and DNF do not separate `update` (refresh index) from `upgrade` (install updates). `yum update` and `dnf upgrade` do both in one step.

---

## 4. Comparing package managers

| | APT | YUM | DNF |
|---|---|---|---|
| Used on | Ubuntu, Debian | CentOS, RHEL 7 | Fedora, RHEL 8+, Amazon Linux |
| Format | `.deb` | `.rpm` | `.rpm` |
| Refresh index | `apt update` (manual) | Automatic | Automatic |
| Install | `apt install` | `yum install` | `dnf install` |
| Upgrade all | `apt upgrade` | `yum update` | `dnf upgrade` |
| Remove | `apt remove` | `yum remove` | `dnf remove` |
| Remove + configs | `apt purge` | No equivalent | No equivalent |
| Clean cache | `apt clean` | `yum clean all` | `dnf clean all` |
| List installed | `apt list --installed` | `yum list installed` | `dnf list installed` |
| Repo config | `/etc/apt/sources.list` | `/etc/yum.repos.d/` | `/etc/yum.repos.d/` |

---

## On the webstore

Installing the full webstore stack on a fresh Ubuntu server.

```bash
# Step 1 — update index first, always
sudo apt update

# Step 2 — install nginx to serve the webstore frontend
sudo apt install -y nginx
# -y (--yes) answers confirmation prompt automatically
# use -y in scripts; skip it interactively to review dependencies first

# Step 3 — confirm nginx installed and check version
nginx -v
# nginx version: nginx/1.24.0

# Step 4 — install tools needed for the webstore
sudo apt install -y curl vim git

# Step 5 — install PostgreSQL client to connect to webstore-db
sudo apt install -y postgresql-client

# Step 6 — verify what got installed
apt list --installed | grep -E 'nginx|curl|vim|git|postgresql'

# Step 7 — check disk space — installs can be large
df -h
# Filesystem      Size  Used Avail Use%
# /dev/sda1        20G  5.1G   14G  27%

# Step 8 — clean up downloaded .deb files
sudo apt clean
sudo apt autoremove
```

---

## What breaks

| Symptom | Cause | Fix |
|---|---|---|
| `E: Unable to locate package <pkg>` | Package index is stale or package name is wrong | Run `sudo apt update` first, then `apt search <keyword>` to find correct name |
| `E: Could not get lock /var/lib/dpkg/lock` | Another apt process is running | Wait for it to finish, or `sudo kill <pid>` if it is stuck |
| `apt upgrade` broke a service | A package update changed behavior or config | Check `/var/log/dpkg.log` for what changed, restore from backup |
| `apt remove` left config files behind | Used `remove` instead of `purge` | Run `sudo apt purge <pkg>` to remove configs too |
| Disk full after install | `/var/cache/apt/archives/` filled with `.deb` files | `sudo apt clean` to clear the cache |
| Package installs old version | Index not refreshed before install | Always `sudo apt update` before `apt install` |

---

## Daily commands

| Command | What it does |
|---|---|
| `sudo apt update` | Refresh package index — run before every install |
| `sudo apt install -y <pkg>` | Install a package without confirmation prompt |
| `sudo apt upgrade -y` | Upgrade all installed packages |
| `sudo apt remove <pkg>` | Remove package, keep config files |
| `sudo apt purge <pkg>` | Remove package and all config files |
| `sudo apt autoremove` | Remove unused dependency packages |
| `sudo apt clean` | Clear downloaded .deb files from cache |
| `apt list --installed \| grep <name>` | Check if a specific package is installed |
| `apt show <pkg>` | Show package version, size, and dependencies |
| `apt search <keyword>` | Find the correct package name |

---

→ **Interview questions for this topic:** [99-interview-prep → Package Management](../99-interview-prep/README.md#package-management)

---
# FILE: 01. Linux – System Fundamentals/12-service-management/README.md
---

[Home](../README.md) |
[Boot](../01-boot-process/README.md) |
[Basics](../02-basics/README.md) |
[Files](../03-working-with-files/README.md) |
[Filters](../04-filter-commands/README.md) |
[sed](../05-sed-stream-editor/README.md) |
[awk](../06-awk/README.md) |
[vim](../07-text-editor/README.md) |
[Users](../08-user-and-group-management/README.md) |
[Permissions](../09-file-ownership-and-permissions/README.md) |
[Archive](../10-archiving-and-compression/README.md) |
[Packages](../11-package-management/README.md) |
[Services](../12-service-management/README.md) |
[Networking](../13-networking/README.md) |
[Logs](../14-logs-and-debug/README.md) |
[Interview](../99-interview-prep/README.md)

---

# Service Management

> **Layer:** L1 — Process Manager
> **Depends on:** [11 Package Management](../11-package-management/README.md) — you need to install software before you can manage it as a service
> **Used in production when:** Starting and stopping services, making a service survive reboots, applying a config change without dropping connections, or debugging why a service failed to start

---

## Table of Contents

- [What this is](#what-this-is)
- [How it fits the stack](#how-it-fits-the-stack)
- [1. Services and daemons](#1-services-and-daemons)
- [2. systemd — how it manages services](#2-systemd--how-it-manages-services)
- [3. systemctl — the control interface](#3-systemctl--the-control-interface)
- [4. restart vs reload — the critical distinction](#4-restart-vs-reload--the-critical-distinction)
- [5. journalctl — reading service logs](#5-journalctl--reading-service-logs)
- [On the webstore](#on-the-webstore)
- [What breaks](#what-breaks)
- [Daily commands](#daily-commands)

---

## What this is

A service is a process that runs in the background without user interaction — started at boot, running continuously, doing its job silently until something goes wrong. nginx serving the webstore frontend is a service. The SSH daemon that lets you log in remotely is a service. On modern Linux, all of these are managed by `systemd` — the PID 1 process from file 01. Every service you start, stop, enable, or debug goes through `systemctl`, systemd's command-line interface.

---

## How it fits the stack

```
  L6  You
  L5  Tools & Files
  L4  Config  ← /etc/systemd/system/ — your unit files live here
  L3  State & Debug  ← /var/log/ /run/ — service logs and state live here
  L2  Networking
  L1  Process Manager  ← this file lives here
       systemd PID 1 · systemctl · journalctl
  L0  Kernel & Hardware
```

Every service you install at L5 (apt install nginx) gets managed by systemd at L1. The config at L4 (/etc/nginx/) controls what the service does. The logs at L3 (/var/log/nginx/) record what it did.

---

## 1. Services and daemons

A **daemon** is a background process that keeps running until the system shuts down. Every daemon has a config file:

| Daemon | What it does | Config file |
|---|---|---|
| `nginx` | Serves web content | `/etc/nginx/nginx.conf` |
| `sshd` | Accepts SSH connections | `/etc/ssh/sshd_config` |
| `cron` | Runs scheduled tasks | `/etc/crontab`, `/etc/cron.d/` |
| `journald` | Collects all system logs | `/etc/systemd/journald.conf` |
| `postgresql` | Runs the database | `/etc/postgresql/*/main/postgresql.conf` |

When you edit a config file, nothing changes until you tell the service to reload or restart. The running process in memory uses the old config until you explicitly apply the new one.

---

## 2. systemd — how it manages services

systemd manages services through **unit files** — text files describing what binary to run, what user to run it as, what it depends on, and whether it should restart if it crashes.

**Unit file locations — priority order (1 wins):**

| Priority | Location | Purpose |
|---|---|---|
| 1 | `/etc/systemd/system/` | Your overrides and custom units — edit here |
| 2 | `/run/systemd/system/` | Runtime units — lost on reboot |
| 3 | `/usr/lib/systemd/system/` | Vendor defaults installed by packages — never edit |

**Unit types:**

| Extension | Purpose |
|---|---|
| `.service` | Background daemon — nginx, sshd, postgresql |
| `.timer` | Scheduled job — modern cron replacement |
| `.socket` | Socket-activated service |
| `.target` | Group of units — defines boot state |

---

## 3. systemctl — the control interface

**Start, stop, restart, reload:**

```bash
# Start now — does not affect boot behavior
sudo systemctl start nginx

# Stop now
sudo systemctl stop nginx

# Restart — stop then start — drops all active connections
sudo systemctl restart nginx

# Reload — apply new config without dropping connections
sudo systemctl reload nginx
```

**Enable and disable at boot:**

```bash
# Enable — will start automatically on next boot
sudo systemctl enable nginx

# Enable AND start immediately in one command
sudo systemctl enable --now nginx

# Disable — will not start on boot
sudo systemctl disable nginx

# Disable AND stop immediately
sudo systemctl disable --now nginx
```

`enable` and `start` are independent. `enable` without `start` = starts next boot but not now. `start` without `enable` = running now but not after reboot. In production you almost always want both — use `enable --now`.

**Check status:**

```bash
sudo systemctl status nginx
# ● nginx.service - A high performance web server
#      Loaded: loaded (/lib/systemd/system/nginx.service; enabled)
#      Active: active (running) since Sat 2025-04-05 09:14:22 UTC; 2h ago
#     Main PID: 1235 (nginx)
#      CGroup: /system.slice/nginx.service
#              ├─1235 nginx: master process
#              └─1236 nginx: worker process

# Quick checks
systemctl is-active nginx     # active  or  inactive
systemctl is-enabled nginx    # enabled  or  disabled
```

**Loaded** = unit file found and whether it is enabled.
**Active** = current running state and how long.
**CGroup** = every process this service spawned.

**List services:**

```bash
systemctl list-units --type=service --state=running   # all running
systemctl list-units --type=service --state=failed    # all failed — check this first
```

---

## 4. restart vs reload — the critical distinction

**`restart`** — stops the process completely, starts a fresh one. Any user currently connected loses their connection. Use when a config change requires a full restart, or when a service is misbehaving.

**`reload`** — sends a signal asking the process to re-read its config. Process stays running. Connections are not dropped. nginx supports reload — new workers start with new config while old workers finish current requests, then exit gracefully.

```bash
# Edited nginx.conf — test first, then reload
sudo nginx -t                    # always test config syntax before applying
# nginx: configuration file /etc/nginx/nginx.conf test is successful
sudo systemctl reload nginx      # apply without dropping connections

# nginx consuming memory and not responding — restart it
sudo systemctl restart nginx     # drops connections, starts fresh
```

**The rule:** for config changes on a running production server, always try `reload` first. Only use `restart` when `reload` is not supported or when the service needs to be killed.

---

## 5. journalctl — reading service logs

systemd collects all service output in a centralized journal. `journalctl` is how you read it.

```bash
# All logs for nginx
journalctl -u nginx

# Follow live — new lines appear as written
journalctl -u nginx -f

# Last 50 lines
journalctl -u nginx -n 50

# Logs since current boot
journalctl -u nginx -b

# Logs from last hour
journalctl -u nginx --since "1 hour ago"

# Error-level messages only
journalctl -u nginx -p err

# Logs from previous boot — useful after a crash
journalctl -u nginx -b -1
```

**The debug loop when a service fails:**

```bash
sudo systemctl start nginx          # attempt to start
sudo systemctl status nginx         # see if it started or shows error
journalctl -u nginx -n 50           # read exactly what went wrong
# fix the problem
sudo nginx -t                       # verify config is valid
sudo systemctl start nginx          # try again
```

---

## On the webstore

The complete nginx lifecycle — from install to serving the webstore frontend.

```bash
# Step 1 — install nginx (from file 11)
sudo apt update && sudo apt install -y nginx

# Step 2 — nginx auto-starts on Ubuntu after install — check it
sudo systemctl status nginx
# Active: active (running)

# Step 3 — create webstore frontend directory and page
sudo mkdir -p /var/www/webstore-frontend
echo "<h1>webstore is live</h1>" | sudo tee /var/www/webstore-frontend/index.html

# Step 4 — write the nginx site config using vim (from file 07)
sudo vim /etc/nginx/sites-available/webstore
# [write the server block config]

# Step 5 — enable the site
sudo ln -s /etc/nginx/sites-available/webstore /etc/nginx/sites-enabled/webstore
sudo rm /etc/nginx/sites-enabled/default

# Step 6 — ALWAYS test config before applying
sudo nginx -t
# nginx: configuration file /etc/nginx/nginx.conf test is successful

# Step 7 — reload without dropping connections
sudo systemctl reload nginx

# Step 8 — verify it is serving the webstore
curl http://localhost
# <h1>webstore is live</h1>

# Step 9 — enable nginx to survive reboots
sudo systemctl enable nginx
# Created symlink /etc/systemd/system/multi-user.target.wants/nginx.service

# Step 10 — confirm enabled
systemctl is-enabled nginx
# enabled
```

---

## What breaks

| Symptom | Cause | Fix |
|---|---|---|
| `Job for nginx.service failed` | Config syntax error or port conflict | `sudo nginx -t` to find syntax error · `ss -tlnp \| grep :80` to find port conflict |
| Service starts but stops immediately | Binary error, missing file, or permission problem | `journalctl -u nginx -n 50` — read the exact error |
| `reload` returns error | Service does not support reload | Use `restart` instead — check man page for support |
| Service running but not surviving reboot | Started with `start` but not `enable` | `sudo systemctl enable nginx` |
| `enable` but service not starting after reboot | Unit file has dependency issue | `journalctl -b -u nginx` — logs from boot |
| Config change not taking effect | Forgot to reload after editing | `sudo systemctl reload nginx` or `restart` |

---

## Daily commands

| Command | What it does |
|---|---|
| `sudo systemctl status <svc>` | Full status — state, PID, recent logs |
| `sudo systemctl start <svc>` | Start service now |
| `sudo systemctl stop <svc>` | Stop service now |
| `sudo systemctl restart <svc>` | Stop and start — drops connections |
| `sudo systemctl reload <svc>` | Apply new config — no dropped connections |
| `sudo systemctl enable --now <svc>` | Enable at boot AND start immediately |
| `systemctl list-units --state=failed` | Show every service that failed |
| `journalctl -u <svc> -f` | Follow live service logs |
| `journalctl -u <svc> -n 50` | Last 50 lines of service logs |
| `sudo nginx -t` | Test nginx config syntax before applying |

---

→ **Interview questions for this topic:** [99-interview-prep → Service Management](../99-interview-prep/README.md#service-management)

---
# FILE: 01. Linux – System Fundamentals/13-networking/README.md
---

[Home](../README.md) |
[Boot](../01-boot-process/README.md) |
[Basics](../02-basics/README.md) |
[Files](../03-working-with-files/README.md) |
[Filters](../04-filter-commands/README.md) |
[sed](../05-sed-stream-editor/README.md) |
[awk](../06-awk/README.md) |
[vim](../07-text-editor/README.md) |
[Users](../08-user-and-group-management/README.md) |
[Permissions](../09-file-ownership-and-permissions/README.md) |
[Archive](../10-archiving-and-compression/README.md) |
[Packages](../11-package-management/README.md) |
[Services](../12-service-management/README.md) |
[Networking](../13-networking/README.md) |
[Logs](../14-logs-and-debug/README.md) |
[Interview](../99-interview-prep/README.md)

---

# Linux Networking

> **Layer:** L2 — Networking
> **Depends on:** [12 Service Management](../12-service-management/README.md) — you need running services before you have network traffic to debug
> **Used in production when:** nginx is running but not responding, the API cannot reach the database, a port that should be open is not, or you need to trace where a request is failing

---

## Table of Contents

- [What this is](#what-this-is)
- [How it fits the stack](#how-it-fits-the-stack)
- [1. ip — inspect network interfaces](#1-ip--inspect-network-interfaces)
- [2. ping — confirm reachability](#2-ping--confirm-reachability)
- [3. traceroute — find where delay lives](#3-traceroute--find-where-delay-lives)
- [4. dig — query DNS](#4-dig--query-dns)
- [5. curl — test HTTP endpoints](#5-curl--test-http-endpoints)
- [6. ss — see what is listening](#6-ss--see-what-is-listening)
- [7. nc — test port connectivity](#7-nc--test-port-connectivity)
- [8. tcpdump — capture live traffic](#8-tcpdump--capture-live-traffic)
- [9. nmap — scan open ports](#9-nmap--scan-open-ports)
- [On the webstore](#on-the-webstore)
- [What breaks](#what-breaks)
- [Daily commands](#daily-commands)

---

## What this is

When something is wrong with a running service, the problem is often in the network layer. nginx is running but not responding. The API cannot reach the database. A port that should be open is not. A request arrives but takes 3 seconds and you do not know where the delay is. These tools answer those questions from the command line — no GUI, no external monitoring tool, just the terminal and the commands that show you exactly what is happening on the network right now.

---

## How it fits the stack

```
  L6  You
  L5  Tools & Files
  L4  Config  ← /etc/hosts /etc/netplan — network config lives here
  L3  State & Debug  ← /proc/net /sys/class/net — live network state
  L2  Networking  ← this file lives here
       ip ping traceroute dig curl ss nc tcpdump nmap
  L1  Process Manager
  L0  Kernel & Hardware  ← TCP/IP stack is in the kernel
```

L2 sits between the kernel's TCP/IP stack (L0) and the config that shapes it (L4). Every service at L1 that listens on a port is visible through the tools at L2.

---

## 1. ip — inspect network interfaces

`ip` shows and configures network interfaces. When you SSH into a server for the first time, `ip addr` tells you what IP addresses the machine has.

```bash
# Show all interfaces and their IP addresses
ip addr show
# 1: lo: <LOOPBACK,UP,LOWER_UP>
#     inet 127.0.0.1/8 scope host lo
# 2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP>
#     inet 10.0.1.45/24 brd 10.0.1.255 scope global eth0
```

`lo` is the loopback interface — `127.0.0.1`. `eth0` (or `enp3s0` on newer systems) is the real network interface.

```bash
# Show the routing table — how the server decides where to send traffic
ip route show
# default via 10.0.1.1 dev eth0   ← default gateway
# 10.0.1.0/24 dev eth0 proto kernel   ← local network

# Show a specific interface
ip addr show eth0
```

---

## 2. ping — confirm reachability

`ping` sends ICMP echo requests and measures whether a host responds.

```bash
# Ping the webstore API — stop after 4 packets (-c = --count)
ping -c 4 webstore-api
# 64 bytes from 172.18.0.3: icmp_seq=0 ttl=64 time=0.312 ms
# 4 packets transmitted, 4 received, 0% packet loss

# Ping the database
ping -c 3 webstore-db

# Ping localhost — confirm loopback is up
ping -c 2 localhost
```

`time=0.312 ms` is round-trip latency. Under 1ms on a local network is normal. Packet loss above 0% means something is dropping packets. A failed ping does not always mean the host is down — some servers block ICMP. Follow up with `nc` to test a specific port.

---

## 3. traceroute — find where delay lives

`traceroute` maps every router hop between you and a destination, showing latency at each step.

```bash
# Trace path to API server
traceroute webstore-api.example.com

# Skip DNS lookups — faster, IPs only (-n = numeric)
traceroute -n webstore-api.example.com
#  1  10.0.1.1     0.891 ms   ← your gateway
#  2  172.16.0.1   1.234 ms   ← ISP router
#  3  54.239.1.1   8.456 ms   ← AWS edge
#  4  54.239.2.15  10.123 ms  ← destination
```

Each line is one hop. `* * *` means a router is blocking traceroute probes — not necessarily broken. Use when API response times jumped and you need to find which hop is adding the latency.

---

## 4. dig — query DNS

`dig` (Domain Information Groper) queries DNS servers and shows the full response. Use when a hostname is not resolving or resolving to the wrong IP.

```bash
# Quick IP lookup
dig +short webstore-api.example.com
# 54.239.28.81

# Query a specific DNS server — bypass your default resolver
dig @8.8.8.8 webstore-api.example.com

# Trace full DNS resolution from root servers down
dig +trace webstore-api.example.com

# Look up the nameserver for a domain (NS record)
dig webstore-api.example.com NS

# Check TTL — how long until this record expires from cache
dig webstore-api.example.com
# webstore-api.example.com.  300  IN  A  54.239.28.81
#                            ^^^
#                            TTL in seconds — 300 = 5 minutes
```

TTL matters when you update a DNS record and it is not working yet — the old answer is cached until TTL expires.

---

## 5. curl — test HTTP endpoints

`curl` makes HTTP requests from the terminal. Essential on a server with no GUI.

```bash
# Test if the webstore API responds
curl http://localhost:8080

# Check only the response status code and headers (-I = --head)
curl -I http://localhost:8080/api/products
# HTTP/1.1 200 OK
# Content-Type: application/json

# Verbose — see full request and response headers (-v = --verbose)
curl -v http://localhost:8080/api/products

# POST request with JSON body
curl -X POST http://localhost:8080/api/orders \
  -H "Content-Type: application/json" \
  -d '{"product_id": 1, "quantity": 2}'

# Follow redirects (-L = --location)
curl -L http://webstore.example.com

# Fail fast — give up after 5 seconds (--max-time)
curl --max-time 5 http://localhost:8080/api/products

# Test virtual host routing with custom Host header (-H = --header)
curl -H "Host: webstore.example.com" http://localhost
```

**Reading status codes:** `200` = success, `301/302` = redirect, `404` = not found, `502 Bad Gateway` = nginx reached but upstream API did not respond, `503` = nginx could not reach upstream at all.

---

## 6. ss — see what is listening

`ss` (Socket Statistics) shows every active connection and every port the server is listening on. Replaced `netstat` on modern Linux.

```bash
# Show all listening TCP ports with process names
# -t = TCP, -l = listening, -n = numeric, -p = process name
sudo ss -tlnp
# LISTEN  0  511  0.0.0.0:80    users:(("nginx",pid=1235))
# LISTEN  0  128  0.0.0.0:22    users:(("sshd",pid=845))
# LISTEN  0  128  127.0.0.1:5432 users:(("postgres",pid=987))
```

Port 80 nginx on `0.0.0.0` = accessible from outside.
Port 5432 postgres on `127.0.0.1` = local only, not exposed externally. Good.

```bash
# Show all TCP and UDP connections with process names
# -u = UDP, -t = TCP, -n = numeric, -p = process
sudo ss -tunp

# Check if nginx is on port 80
sudo ss -tlnp | grep :80

# Show established connections only
sudo ss -t state established
```

---

## 7. nc — test port connectivity

`nc` (netcat) opens a raw TCP connection to a port — the fastest way to test whether a specific port is open without speaking the full protocol.

```bash
# Test if API port 8080 is accepting connections
# -z = zero I/O (just test), -v = verbose
nc -zv webstore-api 8080
# Connection to webstore-api 8080 port [tcp/*] succeeded!

# Test database port
nc -zv webstore-db 5432

# Test with a timeout — fail after 3 seconds (-w = wait)
nc -zv -w 3 webstore-api 8080
```

If `nc` fails, it is a network or firewall problem. If `nc` succeeds but the application still cannot connect, the problem is in the application layer — wrong credentials, wrong database name, wrong connection string.

---

## 8. tcpdump — capture live traffic

`tcpdump` captures raw network packets in real time. The deepest debugging tool — reach for it when everything else has failed to explain what is happening.

```bash
# Capture all traffic on eth0 — Ctrl+C to stop
sudo tcpdump -i eth0

# Capture only HTTP traffic on port 80
sudo tcpdump -i eth0 port 80

# Capture traffic to/from a specific host
sudo tcpdump -i eth0 host 10.0.1.45

# No DNS lookups — show IPs only (-n = numeric)
sudo tcpdump -i eth0 -n port 80

# Show packet contents in ASCII (-A = ASCII)
sudo tcpdump -i eth0 -A port 8080

# Save to file for analysis later (-w = write)
sudo tcpdump -i eth0 -w capture.pcap port 8080

# Read a saved capture file (-r = read)
sudo tcpdump -r capture.pcap
```

`-A port 8080` shows you the raw HTTP request and response — every header and body. Use when `curl` returns something unexpected and you need to see exactly what is on the wire.

---

## 9. nmap — scan open ports

`nmap` probes a host and reports which ports are open. On your own servers, use it to confirm your firewall is configured correctly.

```bash
# Scan the webstore server
nmap webstore.example.com

# Scan specific ports only (-p = ports)
nmap -p 22,80,443,8080 webstore.example.com

# Fast scan — top 100 ports (-F = fast)
nmap -F webstore.example.com

# Output:
# PORT     STATE   SERVICE
# 22/tcp   open    ssh
# 80/tcp   open    http
# 5432/tcp closed  postgresql   ← good — DB should not be exposed
```

Run `nmap` from an external machine to get the attacker's view of your server — what they can see.

---

## On the webstore

Users report the webstore is not loading. Work from outside in.

```bash
# Step 1 — is nginx running and bound to port 80?
sudo ss -tlnp | grep :80
# Nothing? nginx is not listening
sudo systemctl status nginx
journalctl -u nginx -n 20

# Step 2 — can the server respond to HTTP at all?
curl -I http://localhost
# 200 OK → nginx is up
# Connection refused → nginx not running or not on port 80

# Step 3 — can the API port be reached from the frontend server?
nc -zv webstore-api 8080
# succeeded → network is fine
# failed → check if API service is running, check firewall

# Step 4 — is the API responding correctly?
curl -v http://webstore-api:8080/api/products

# Step 5 — can the API reach the database?
nc -zv webstore-db 5432
# succeeded → DB port reachable
# failed → DB is down or firewall is blocking

# Step 6 — is DNS resolving to the right IP?
dig +short webstore-api.example.com
# compare to the IP you expect

# Step 7 — traffic arriving but responses wrong? capture it
sudo tcpdump -A -i eth0 port 8080 -c 20
# read the raw HTTP request and response
```

---

## What breaks

| Symptom | Cause | Fix |
|---|---|---|
| `curl: (7) Failed to connect` | Service not running or wrong port | `ss -tlnp` to check what is listening, `systemctl status` to check service |
| `curl` returns `502 Bad Gateway` | nginx is up but upstream API is not responding | `nc -zv api-host 8080` to test API port, `journalctl -u api-service` |
| `ping` succeeds but `nc` fails | ICMP allowed but the specific port is blocked by firewall | Check `ufw status` or `iptables -L` — the port may be firewalled |
| `dig +short` returns old IP after DNS update | TTL has not expired — old answer is still cached | Wait for TTL to expire, or `dig @8.8.8.8` to check what authoritative DNS has |
| `ss -tlnp` shows service on `127.0.0.1` not `0.0.0.0` | Service is bound to localhost only — not accessible from outside | Edit service config to bind to `0.0.0.0` or the correct interface |
| `tcpdump` shows packets arriving but no response | Service is receiving but not responding — likely a crash or busy | `journalctl -u service -f` while sending a request to see the error |

---

## Daily commands

| Command | What it does |
|---|---|
| `ip addr show` | Show all interfaces and IP addresses |
| `ip route show` | Show routing table and default gateway |
| `ping -c 4 <host>` | Test if a host is reachable |
| `dig +short <host>` | Quick DNS lookup — returns just the IP |
| `curl -I <url>` | Check HTTP status code and headers only |
| `curl -v <url>` | Full verbose HTTP request and response |
| `sudo ss -tlnp` | Show all listening ports with process names |
| `nc -zv <host> <port>` | Test if a specific port is open |
| `sudo tcpdump -A -i eth0 port <port>` | Capture and read raw traffic on a port |
| `nmap -p <ports> <host>` | Scan specific ports from outside |

---

→ **Interview questions for this topic:** [99-interview-prep → Networking](../99-interview-prep/README.md#networking)

---
# FILE: 01. Linux – System Fundamentals/14-logs-and-debug/README.md
---

[Home](../README.md) |
[Boot](../01-boot-process/README.md) |
[Basics](../02-basics/README.md) |
[Files](../03-working-with-files/README.md) |
[Filters](../04-filter-commands/README.md) |
[sed](../05-sed-stream-editor/README.md) |
[awk](../06-awk/README.md) |
[vim](../07-text-editor/README.md) |
[Users](../08-user-and-group-management/README.md) |
[Permissions](../09-file-ownership-and-permissions/README.md) |
[Archive](../10-archiving-and-compression/README.md) |
[Packages](../11-package-management/README.md) |
[Services](../12-service-management/README.md) |
[Networking](../13-networking/README.md) |
[Logs](../14-logs-and-debug/README.md) |
[Interview](../99-interview-prep/README.md)

---

# Logs & Debug

> **Layer:** L3 — State & Debug
> **Depends on:** [12 Service Management](../12-service-management/README.md) and [13 Networking](../13-networking/README.md) — logs only make sense once services are running and network is configured
> **Used in production when:** Something broke. You SSH in at 2am. You need to find the cause using only the terminal.

---

## Table of Contents

- [What this is](#what-this-is)
- [How it fits the stack](#how-it-fits-the-stack)
- [1. Where logs live — /var/log](#1-where-logs-live--varlog)
- [2. journalctl — the systemd journal](#2-journalctl--the-systemd-journal)
- [3. /run — live runtime state](#3-run--live-runtime-state)
- [4. /var/lib — persistent app state](#4-varlib--persistent-app-state)
- [5. The debug workflow](#5-the-debug-workflow)
- [On the webstore](#on-the-webstore)
- [What breaks](#what-breaks)
- [Daily commands](#daily-commands)

---

## What this is

L3 is where the system keeps its memory — what happened (logs), what is running now (runtime state), and what persists between reboots (app state). When something breaks in production, this is the first layer you open. Not the code. Not the config. The logs. The log tells you what actually happened, when it happened, and often exactly why. Every tool in files 01 through 13 produced information that landed here. This file teaches you how to read it.

---

## How it fits the stack

```
  L6  You
  L5  Tools & Files
  L4  Config  ← /etc controls what services do
  L3  State & Debug  ← this file lives here
       /var/log  /run  /var/lib  journalctl
  L2  Networking
  L1  Process Manager  ← systemd writes to journal at L3
  L0  Kernel & Hardware
```

Everything that happens at every other layer leaves a trace at L3. The kernel logs hardware events. systemd logs service starts and stops. nginx logs every request. When something breaks, L3 has the evidence.

---

## 1. Where logs live — /var/log

```
/var/log/
├── syslog          ← main system log — everything goes here
├── auth.log        ← all logins, sudo uses, SSH connections
├── kern.log        ← kernel messages — hardware errors, OOM kills
├── dpkg.log        ← every package install and remove
├── apt/
│   └── history.log ← apt install/upgrade/remove history
├── nginx/
│   ├── access.log  ← every HTTP request nginx received
│   └── error.log   ← nginx errors — config problems, upstream failures
└── journal/        ← systemd binary journal (read with journalctl)
```

**The log you open first depends on the symptom:**

| Symptom | First log to check |
|---|---|
| Service failed | `journalctl -u <service> -n 50` |
| Login or sudo issue | `/var/log/auth.log` |
| System slow or crashing | `/var/log/kern.log` or `dmesg` |
| nginx 502 or 503 | `/var/log/nginx/error.log` |
| Package install problem | `/var/log/dpkg.log` |
| General "something happened" | `/var/log/syslog` |

**Reading logs with the tools from file 04:**

```bash
# Watch syslog live
tail -f /var/log/syslog

# Find all errors in the last hour of syslog
grep "$(date +'%b %e %H')" /var/log/syslog | grep -i error

# Count nginx 500 errors today
grep "$(date +'%d/%b/%Y')" /var/log/nginx/access.log | grep ' 500 ' | wc -l

# Find which IPs are hitting the webstore with 500 errors
grep ' 500 ' /var/log/nginx/access.log | awk '{print $1}' | sort | uniq -c | sort -rn

# Check who has logged in recently
tail -n 50 /var/log/auth.log | grep 'Accepted'
```

---

## 2. journalctl — the systemd journal

`journalctl` reads the systemd binary journal — the central log for all services managed by systemd. More powerful than plain log files because it is structured, indexed, and searchable by time, priority, and service.

```bash
# All logs from current boot
journalctl -b

# All logs from previous boot — useful after a crash reboot
journalctl -b -1

# Logs for a specific service
journalctl -u nginx

# Follow live — new lines appear as they are written (-f = --follow)
journalctl -u nginx -f

# Last 50 lines of a service log (-n = --lines)
journalctl -u nginx -n 50

# Errors only — no info or debug noise (-p = --priority)
journalctl -u nginx -p err

# Logs from the last hour
journalctl -u nginx --since "1 hour ago"

# Logs between two timestamps
journalctl --since "2025-04-05 09:00" --until "2025-04-05 10:00"

# No pager — print all to terminal (useful in scripts)
journalctl -u nginx -n 100 --no-pager

# Show kernel messages (same as dmesg but via journal)
journalctl -k
```

**Priority levels** (lowest number = highest severity):
`0` = emerg · `1` = alert · `2` = crit · `3` = err · `4` = warning · `5` = notice · `6` = info · `7` = debug

`-p err` shows levels 0 through 3 — emergencies, alerts, critical, and errors.

---

## 3. /run — live runtime state

`/run` is a tmpfs (RAM filesystem) — it exists only while the system is running. Wiped completely on every reboot. Everything here reflects the current live state.

```
/run/
├── nginx.pid           ← PID of the running nginx master process
├── docker.sock         ← Docker API socket — CLI talks to daemon here
├── systemd/
│   └── system/         ← runtime unit files — temporary overrides
└── user/
    ├── 1000/           ← akhil's runtime session data
    ├── 1001/           ← charan's session
    ├── 1002/           ← pramod's session
    ├── 1003/           ← navya's session
    └── 1004/           ← indhu's session
```

```bash
# See what is in /run right now
ls /run/

# Find which PID nginx is running as
cat /run/nginx.pid
# 1235

# Confirm the PID is actually running
ps aux | grep 1235

# Check if docker socket exists (Docker is running)
ls -la /run/docker.sock
# srw-rw---- root docker  /run/docker.sock
```

---

## 4. /var/lib — persistent app state

`/var/lib` stores data that services write to disk and need to survive reboots — unlike `/run` which is wiped, `/var/lib` persists.

```
/var/lib/
├── docker/         ← all Docker images, containers, and volumes
├── dpkg/           ← installed package database — what apt knows is installed
├── apt/lists/      ← cached package lists from last apt update
├── mysql/          ← MySQL database files (if installed)
└── postgresql/     ← PostgreSQL database files (if installed)
```

```bash
# See disk usage of Docker data
du -sh /var/lib/docker/
# 8.2G /var/lib/docker/

# See disk usage of all /var/lib subdirectories
du -sh /var/lib/* | sort -rh | head -10

# Check the installed package database
ls /var/lib/dpkg/info/ | grep nginx
# nginx.list  nginx.md5sums  nginx.postinst  nginx.postrm  nginx.prerm
```

---

## 5. The debug workflow

This is the structured approach to any production problem. Work from symptom to cause in order.

```
SYMPTOM → LAYER → FIRST COMMAND → WHAT IT TELLS YOU
```

**Step 1 — is the machine alive?**
```bash
uptime          # is it up? how long? is load average normal?
free -h         # is RAM exhausted? (OOM killer may have struck)
df -h           # is disk full? (disk full = services fail silently)
```

**Step 2 — did anything fail at boot or recently?**
```bash
systemctl list-units --state=failed     # any failed units?
journalctl -b -p err                    # any errors since last boot?
dmesg | tail -20                        # any kernel errors?
```

**Step 3 — is the specific service running?**
```bash
systemctl status nginx
journalctl -u nginx -n 50
```

**Step 4 — is the service reachable on the network?**
```bash
sudo ss -tlnp | grep :80    # is nginx bound to the right port?
curl -I http://localhost     # does it respond to HTTP?
nc -zv localhost 80          # can you connect to the port at all?
```

**Step 5 — what do the application logs say?**
```bash
tail -f /var/log/nginx/error.log
grep ' 500 ' /var/log/nginx/access.log | tail -20
journalctl -u nginx -p err --since "1 hour ago"
```

**Step 6 — is disk or memory the problem?**
```bash
df -h                           # which filesystem is full?
du -sh /var/log/* | sort -rh    # which log is consuming the most space?
free -h                         # how much RAM is left?
dmesg | grep -i 'oom\|killed'   # has the OOM killer been running?
```

---

## On the webstore

A full incident simulation. Users report the webstore is returning 502 errors.

```bash
# Step 1 — is the machine alive?
uptime
# 14:23:11 up 12 days, load average: 0.45, 0.38, 0.31  ← machine is fine

df -h
# /dev/sda1  20G  19G  500M  98%  /   ← disk nearly full!

# Disk is nearly full — this could cause the issue
# Find what is eating space
du -sh /var/log/* | sort -rh | head -5
# 18G  /var/log/nginx/access.log   ← the culprit

# Step 2 — is nginx up?
systemctl status nginx
# Active: active (running)

# Step 3 — what does the nginx error log say?
tail -20 /var/log/nginx/error.log
# [error] 1235: open() "/var/log/nginx/access.log" failed (28: No space left)
# Confirmed — nginx cannot write logs because disk is full

# Step 4 — compress old logs to free space
gzip /var/log/nginx/access.log
# Now access.log is access.log.gz — 95% smaller

# Step 5 — tell nginx to reopen its log files
sudo systemctl reload nginx

# Step 6 — verify it is writing again
tail -f /var/log/nginx/access.log
# 192.168.1.10 GET /api/products 200 512   ← writing again

# Step 7 — verify the webstore is serving correctly
curl -I http://localhost
# HTTP/1.1 200 OK

# Step 8 — prevent this from happening again
# Compress logs older than 7 days automatically
find /var/log/nginx/ -name "*.log" -mtime +7 -exec gzip {} \;
```

---

## What breaks

| Symptom | Layer | First command |
|---|---|---|
| Service failing silently | L1/L3 | `journalctl -u <svc> -n 50` |
| Disk full — services writing logs | L3 | `df -h` then `du -sh /var/log/* \| sort -rh` |
| OOM kill — process killed silently | L0/L3 | `dmesg \| grep -i oom` |
| Cannot SSH in | L2/L4 | Check `journalctl -u sshd` from console |
| journalctl shows no logs | L1/L3 | `systemctl status systemd-journald` — journal may have stopped |
| `/var/log` filling with old logs | L3 | `find /var/log -mtime +30 -name "*.log" -exec gzip {} \;` |

---

## Daily commands

| Command | What it does |
|---|---|
| `journalctl -u <svc> -f` | Follow live logs for a service |
| `journalctl -u <svc> -n 50` | Last 50 lines of service logs |
| `journalctl -b -p err` | All errors since last boot |
| `journalctl -b -1` | All logs from previous boot — useful after a crash |
| `df -h` | Check disk space on all filesystems |
| `du -sh /var/log/* \| sort -rh \| head -10` | Find the largest log files |
| `cat /run/nginx.pid` | Read PID of a running service from its PID file |
| `ls -la /run/docker.sock` | Confirm Docker socket exists and is accessible |
| `find /var/log -mtime +30 -name "*.log" -exec gzip {} \;` | Compress logs older than 30 days |
| `grep "$(date +'%b %e')" /var/log/syslog \| grep -i error` | Find today's errors in syslog |

---

→ **Interview questions for this topic:** [99-interview-prep → Logs & Debug](../99-interview-prep/README.md#logs-and-debug)

---
# FILE: 01. Linux – System Fundamentals/99-interview-prep/README.md
---

[Home](../README.md) |
[Boot](../01-boot-process/README.md) |
[Basics](../02-basics/README.md) |
[Files](../03-working-with-files/README.md) |
[Filters](../04-filter-commands/README.md) |
[sed](../05-sed-stream-editor/README.md) |
[awk](../06-awk/README.md) |
[vim](../07-text-editor/README.md) |
[Users](../08-user-and-group-management/README.md) |
[Permissions](../09-file-ownership-and-permissions/README.md) |
[Archive](../10-archiving-and-compression/README.md) |
[Packages](../11-package-management/README.md) |
[Services](../12-service-management/README.md) |
[Networking](../13-networking/README.md) |
[Logs](../14-logs-and-debug/README.md) |
[Interview](../99-interview-prep/README.md)

---

# Interview Prep — Linux

> Read the notes files first. Come here the day before an interview.
> Each answer is 30 seconds. No more. That is what interviewers want.

---

## Table of Contents

- [Boot Process](#boot-process)
- [Linux Basics](#linux-basics)
- [Working with Files](#working-with-files)
- [Filter Commands](#filter-commands)
- [sed](#sed)
- [awk](#awk)
- [vim](#vim)
- [Users and Groups](#users-and-groups)
- [Permissions](#permissions)
- [Archiving](#archiving)
- [Package Management](#package-management)
- [Service Management](#service-management)
- [Networking](#networking)
- [Logs and Debug](#logs-and-debug)

---

## Boot Process

**What happens when you press the power button on a Linux server?**

BIOS or UEFI firmware runs a POST check on the hardware, then finds the bootable disk and loads GRUB. GRUB loads the kernel and initramfs into RAM and hands off control. The kernel initialises hardware, uses initramfs to mount the real root filesystem, then starts systemd as PID 1. systemd reads unit files and brings all services up to the configured target — on servers that is `multi-user.target`. Then you get a login prompt.

**What is initramfs and why does it exist?**

initramfs is a tiny temporary filesystem loaded into RAM alongside the kernel. The kernel needs drivers to mount the real root filesystem, but those drivers might live on the real root filesystem — a chicken-and-egg problem. initramfs contains just enough drivers to break that deadlock. Once the real filesystem is mounted, initramfs is discarded.

**A server won't boot. You see `grub rescue>`. What happened and what do you do?**

GRUB failed to find the kernel. Common causes: disk UUID changed, wrong partition in grub.cfg, or the boot partition is corrupted. Boot from a live USB, chroot into the broken system, run `grub-install /dev/sda` and `update-grub` to regenerate the config.

**What is the difference between GRUB's two config files?**

`/etc/default/grub` is human-editable settings — timeout, default kernel, boot parameters. `/boot/grub/grub.cfg` is auto-generated from those settings. You never edit `grub.cfg` directly. You edit `/etc/default/grub` and run `sudo update-grub` to regenerate it.

**What is systemd and what is PID 1?**

systemd is the init system — the first process the kernel starts, always with PID 1. It is the parent of every other process on the system. It manages services through unit files, handles logging via journald, and manages the boot target. If systemd dies, the system goes down.

---

## Linux Basics

**What is the difference between `~` and `/`?**

`/` is the root of the entire filesystem — the top of the directory tree. Everything on the system lives somewhere beneath it. `~` is shorthand for the current user's home directory — `/home/akhil` for akhil. They are completely different locations.

**What does `ls -lahtr` show?**

Long format (`-l`) with all files including hidden (`-a`), sizes in human-readable KB/MB/GB (`-h`), sorted by modification time (`-t`) in reverse order oldest-first (`-r`). It gives you the full picture of a directory — permissions, owner, size, and when each file was last changed.

**What is the difference between an absolute and relative path?**

An absolute path starts from root and works from anywhere — `/home/akhil/webstore/config/webstore.conf`. A relative path starts from your current working directory — if you are in `/home/akhil`, then `webstore/config/webstore.conf` refers to the same file. `pwd` tells you your current directory.

**What does `uptime` tell you?**

How long the system has been running and the load average over the last 1, 5, and 15 minutes. A load average above the number of CPU cores means the system is under more load than it can handle. A very short uptime when you expect days or weeks tells you the server restarted unexpectedly.

---

## Working with Files

**What is the difference between `>` and `>>`?**

`>` redirects output to a file and overwrites it completely — no warning, no undo. `>>` appends to the end of the file without touching existing content. Using `>` when you meant `>>` is one of the most common causes of data loss on a server.

**What flags do you always use with `cp` when backing up a directory?**

`cp -riv` — `-r` to copy directories recursively, `-i` to prompt before overwriting so you cannot silently destroy an existing backup, `-v` to print each file as it copies so you can confirm what moved and catch wrong paths. This is the gold standard before any production change.

**What is a symlink and how does nginx use them?**

A symlink is a pointer to another file or directory. nginx keeps all site configs in `sites-available/` and enables them by creating symlinks in `sites-enabled/`. To disable a site you remove the symlink — the actual config file is untouched. To enable a site you create the symlink. The actual config is never moved or deleted.

**What is the difference between `stat` and `ls -l`?**

`ls -l` gives a readable summary — permissions, owner, size, last modified time. `stat` gives full metadata — all three timestamps (access, modify, change), exact size in bytes, inode number, and permissions in both octal and symbolic form. During incident triage, `stat` tells you the exact second a config file was last changed.

---

## Filter Commands

**What does `grep -v '200'` do and when do you use it?**

`-v` is invert-match — it shows every line that does NOT match the pattern. `grep -v '200'` on an access log shows every non-200 request — immediately surfaces all errors, 404s, 500s, and redirects in one command. It is the fastest way to see every problem in a log without scrolling.

**Explain the pipeline: `cut -d' ' -f1 access.log | sort | uniq -c | sort -rn`**

`cut` extracts field 1 (the IP address) from each line. `sort` puts identical IPs adjacent to each other. `uniq -c` counts and deduplicates consecutive identical lines. `sort -rn` sorts numerically in descending order. Result: a ranked list of which IPs are hitting the server most — the core pattern for log analysis.

**What is the difference between `find` and `locate`?**

`find` walks the live filesystem in real time — results are always current. It can filter by name, type, size, age, owner, and execute commands on matches. `locate` searches a prebuilt database — it is instant but only as fresh as the last time `updatedb` ran, usually daily. Use `find` when you need current results, `locate` when you just need to know where a file is and freshness does not matter.

**What does `tee` do?**

`tee` reads from stdin and writes to both stdout and a file at the same time. You see the output on screen and it gets saved — without running the command twice. Useful during an incident when you want to watch grep results live and save them for the team simultaneously.

---

## sed

**What does `sed -i 's/production/staging/' webstore.conf` do?**

`s/production/staging/` is the substitution command — find `production`, replace with `staging`, on the first match per line. `-i` writes the change back to the file in-place. Without `-i`, sed only prints the result to terminal and the file is untouched. This is the command a deploy script uses to switch config environments without opening an editor.

**What is the difference between `s/old/new/` and `s/old/new/g`?**

Without `g`, sed replaces only the first match per line. With `g` (global), it replaces every match on every line. If `old` appears three times on one line and you use `s/old/new/` without `g`, only the first occurrence changes.

**How do you replace a path like `/api/v1` with `/api/v2` in sed when the pattern contains forward slashes?**

Switch the delimiter. The default is `/` but sed accepts any character. Use `#` instead: `sed 's#/api/v1#/api/v2#g' file`. Any character that does not appear in your pattern or replacement works — `|` and `@` are also common.

**How do you preview what sed would change without actually changing the file?**

Run without `-i` — sed prints to terminal, file unchanged. Add `-n` with the `p` flag to see only the lines that would be changed: `sed -n 's/old/new/p' file`. This shows exactly which lines match before you commit to in-place editing.

---

## awk

**What is the basic structure of an awk command?**

`awk 'PATTERN { ACTION }' file`. awk reads the file one line at a time. For each line it checks if the pattern matches — if it does, it runs the action. Fields are split by whitespace by default, numbered from `$1`. `$0` is the whole line. `NR` is the current line number.

**What is the difference between `/500/` and `$4 == "500"` in awk?**

`/500/` matches any line containing `500` anywhere — in a URL path, an error message, anywhere. `$4 == "500"` matches only when field 4 is exactly the string `500`. Use field matching when you know which column holds the value you care about — it prevents false matches.

**How do you sum a column in awk?**

`awk '{ total += $5 } END { print total }' file`. Variables in awk persist across lines. `total += $5` adds field 5 of every line to `total`. `END` runs once after all lines are processed, printing the accumulated sum. The same pattern works for counts (`count++`) and averages (`total/NR`).

**What is an associative array in awk and what is it used for?**

An associative array uses a string as the key instead of a number. `count[$1]++` increments the count for each unique value of field 1. After processing the entire file, `for (ip in count) print count[ip], ip` prints the count for every unique IP. This is how you count occurrences per unique value in one pass.

---

## vim

**Someone opens vim for the first time and starts typing but nothing appears correctly. What is happening?**

vim starts in Normal mode — keys are commands, not text. They need to press `i` to enter Insert mode first, then type. When done, press `Esc` to return to Normal mode. `Esc` always returns you to Normal mode from anywhere — it is the first thing to try when vim behaves unexpectedly.

**How do you save and exit vim? How do you exit without saving?**

`:wq` saves and exits — `:w` writes the file, `:q` quits. `:q!` exits without saving and without asking — the `!` forces quit even with unsaved changes. If you opened the wrong file and made no intentional changes, `:q!` is the fastest exit.

**How do you jump to line 47 in vim?**

Type `47G` in Normal mode. `G` by itself jumps to the last line. `gg` jumps to the first line. `5G` jumps to line 5. This is how you go directly to a syntax error reported on a specific line.

**How do you replace all occurrences of a word in vim?**

`:%s/old/new/g` from Command-line mode (press `:` first). `%` applies to the entire file, `s` is substitute, `g` is global (all occurrences per line). `:%s/old/new/gc` adds a confirmation prompt for each match — useful when you want to review each change before applying it.

---

## Users and Groups

**What is the difference between UID and username?**

Linux tracks users by UID — a number. The username is just a human-readable label that resolves to the UID. When you see `akhil` as file owner in `ls -l`, Linux is storing UID 1000 and your terminal is resolving it. This matters when moving files between servers — if UIDs differ, ownership mappings break.

**What is the danger of running `usermod -G webstore-team akhil` without `-a`?**

Without `-a` (append), `-G` replaces all of the user's current group memberships with only the groups you specified. Akhil loses membership in sudo, docker, and every other group instantly. They lose all access those groups granted. Always use `-aG` to add a group without touching existing memberships.

**What is the UID range for system accounts and why does it matter?**

UIDs 1-999 are reserved for system accounts — daemons and services like `www-data` (33) and `postgres` (999). They have no login shell and no home directory by design. Human users get UID 1000+. This separation ensures services and humans never share an identity, which limits blast radius if a service is compromised.

**Why should nginx not run as root?**

If nginx runs as root and is compromised, the attacker has full system access — can read any file, write anywhere, execute anything. Running nginx as `www-data` with access only to the files it needs means a compromise is contained — the attacker gets www-data's limited permissions, not root's unlimited ones. This is the principle of least privilege.

---

## Permissions

**What does `chmod 640` mean?**

Six = owner gets read+write (4+2). Four = group gets read only (4). Zero = others get nothing (0). In symbolic form: `-rw-r-----`. Used on config files containing secrets — the owner can edit them, the service group can read them, everyone else is locked out.

**What is the execute bit on a directory and why does it matter?**

Without execute (`x`) on a directory, you cannot `cd` into it or access any files inside — even if you have read permission. Read without execute lets you see filenames with `ls` but nothing else. This is a common trap — a directory with `r--` looks accessible but is effectively locked.

**What is SGID on a directory and when do you use it?**

SGID (Set Group ID) on a directory makes all new files created inside automatically inherit the directory's group instead of the creator's primary group. Essential for shared team directories — every file created in `~/webstore/logs/` belongs to `webstore-team` regardless of who created it. Set with `chmod g+s <dir>`.

**Why use `640` instead of `644` for a config file with a database password?**

`644` means others (any user on the server) can read the file — including the database password. `640` means only the owner and the group can read it. nginx runs as `www-data` which is a member of `webstore-team`, so it can read the config. Any other user on the server cannot.

---

## Archiving

**What is the difference between archiving and compression?**

Archiving combines multiple files into one file — no size reduction, the purpose is portability. `tar` archives. Compression reduces a file's size. `gzip` compresses. `tar.gz` does both — archive first with `tar`, then compress the result with `gzip`. On Linux servers you almost always use `tar.gz`.

**What does `tar -czvf backup.tar.gz ~/webstore/` do, flag by flag?**

`c` = create a new archive. `z` = compress it with gzip. `v` = verbose, print each file. `f` = the next argument is the filename. `backup.tar.gz` = the output file. `~/webstore/` = what to archive. Reading it: create a gzip-compressed verbose archive called backup.tar.gz from the webstore directory.

**Why do you always list the archive contents before extracting?**

`tar -tzvf archive.tar.gz` shows every file without extracting. It confirms the archive contains what you expect and that the paths are correct. Extracting blindly into the wrong directory can overwrite existing files — listing first costs 2 seconds and prevents that mistake.

**Why use `tar.gz` instead of `zip` on Linux servers?**

`tar.gz` preserves Unix file permissions, ownership, and symlinks exactly. `zip` does not reliably preserve Unix permissions. If you archive the webstore with `zip` and extract it on another Linux server, the file permissions will be wrong and you will have to run `chown` and `chmod` again to fix them.

---

## Package Management

**What is the difference between `apt update` and `apt upgrade`?**

`apt update` refreshes the local package index — it fetches the latest list of available versions from the repositories but installs nothing. `apt upgrade` installs newer versions of all packages already installed. You must run `update` before `upgrade` so apt knows what versions are available.

**What is the difference between `apt remove` and `apt purge`?**

`apt remove` uninstalls the package binaries but leaves config files on disk. If you reinstall later, your config is still there. `apt purge` removes everything including config files — a clean slate. Use `remove` when you plan to reinstall. Use `purge` for a complete uninstall.

**Why do you never skip `apt update` before `apt install`?**

Without updating the index, apt installs from its cached list which may be days or weeks old. You might install an outdated version with known security issues, or apt might fail entirely because a dependency was renamed and the old name no longer exists in the current repository.

**What does `apt install nginx` actually do to the system?**

Downloads the nginx package and all its dependencies. Installs the nginx binary to `/usr/sbin/nginx`. Puts the default config in `/etc/nginx/`. Creates the `www-data` system user if it does not exist. Registers `nginx.service` with systemd. On Ubuntu, nginx starts automatically after install.

---

## Service Management

**What is the difference between `systemctl start` and `systemctl enable`?**

`start` runs the service right now but has no effect on boot behavior. `enable` makes the service start automatically on the next boot but does not start it now. In production you almost always want both — `systemctl enable --now nginx` enables and starts in one command.

**What is the difference between `systemctl restart` and `systemctl reload`?**

`restart` stops the process completely and starts a fresh one — all active connections are dropped. `reload` sends a signal asking the process to re-read its config without stopping — active connections are preserved. Always use `reload` for config changes in production when the service supports it. Test config with `nginx -t` before either.

**A service fails to start. What is your debugging sequence?**

`systemctl status <service>` to see the current state and the last few log lines. `journalctl -u <service> -n 50` to read the full error. Fix what the log identifies. `nginx -t` if it is nginx to confirm the config is valid. `systemctl start <service>` again.

**What are the three unit file priority locations and which wins?**

1. `/etc/systemd/system/` — your overrides, highest priority, always wins
2. `/run/systemd/system/` — runtime units, second priority, lost on reboot
3. `/usr/lib/systemd/system/` — vendor defaults installed by packages, lowest priority, never edit these

---

## Networking

**What does `ss -tlnp` show?**

All listening TCP ports with the process name and PID that owns each one. `-t` = TCP, `-l` = listening, `-n` = numeric (no DNS resolution), `-p` = process name. After deploying a service, `ss -tlnp` confirms it is bound to the expected port. If it is not in the list, it is not running or failed to bind.

**What is the difference between a service bound to `0.0.0.0` vs `127.0.0.1`?**

`0.0.0.0` means the service accepts connections on all network interfaces — accessible from outside the server. `127.0.0.1` (loopback) means the service only accepts connections from the same machine — not accessible from outside. The database should always be on `127.0.0.1`. nginx serving the web should be on `0.0.0.0`.

**The API cannot connect to the database. How do you isolate the problem?**

`nc -zv webstore-db 5432` from the API server. If nc succeeds, the network is fine — the problem is in the application layer (wrong password, wrong database name, wrong connection string). If nc fails, it is a network problem — check if postgres is running, check firewall rules, check if postgres is listening on `127.0.0.1` instead of `0.0.0.0`.

**What does `dig +short webstore-api.example.com` return and when do you use it?**

Just the IP address the hostname resolves to. Use it after a DNS change to confirm the record has propagated, or when traffic is hitting the wrong server — `dig +short` immediately tells you if DNS is returning the old IP. `dig @8.8.8.8 hostname` queries Google's DNS directly to bypass your local cache.

**What does `502 Bad Gateway` mean?**

nginx received the request and forwarded it to the upstream service (the API), but the upstream did not respond. nginx is running. The API is not. Check `systemctl status <api-service>` and `journalctl -u <api-service> -n 50`.

---

## Logs and Debug

**A server is having issues and you SSH in. What are your first three commands?**

`uptime` — is the machine alive, how long has it been up, is load normal. `df -h` — is any filesystem full (full disk causes silent failures). `systemctl list-units --state=failed` — are there any failed services. These three commands tell you the state of the system in 10 seconds.

**Where do you look first when a service fails to start?**

`journalctl -u <service> -n 50` — the last 50 lines of the service's log since the failed start. systemd captures all service output here. The exact error message is almost always in those 50 lines. `systemctl status <service>` shows a shorter summary but `journalctl` gives more context.

**Disk is filling up on a server. How do you find what is consuming it?**

`df -h` shows which filesystem is full. `du -sh /var/log/* | sort -rh | head -10` shows the largest items in `/var/log`. `du -sh /* | sort -rh | head -10` shows the largest top-level directories. Nine times out of ten on a server, it is a log file that was not rotated.

**What is the difference between `/var/log` and `/run`?**

`/var/log` is persistent — it survives reboots and accumulates over time. It contains the historical record of what happened. `/run` is a RAM filesystem — it exists only while the system is running and is wiped completely on every reboot. It contains live state: socket files, PID files, session data. Both are at L3 but serve different purposes.

**What does `dmesg | grep -i oom` tell you?**

OOM stands for Out of Memory. When the Linux kernel runs out of RAM, it activates the OOM killer — it selects and kills processes to free memory. `dmesg | grep -i oom` shows if this happened and which processes were killed. A process that mysteriously disappeared without a trace was probably OOM killed.

---
# FILE: 01. Linux – System Fundamentals/README.md
---

<p align="center">
  <img src="../../assets/linux-banner.svg" alt="linux" width="100%"/>
</p>

[← devops-runbook](../../README.md) |
[Boot](./01-boot-process/README.md) |
[Basics](./02-basics/README.md) |
[Files](./03-working-with-files/README.md) |
[Filters](./04-filter-commands/README.md) |
[sed](./05-sed-stream-editor/README.md) |
[awk](./06-awk/README.md) |
[vim](./07-text-editor/README.md) |
[Users](./08-user-and-group-management/README.md) |
[Permissions](./09-file-ownership-and-permissions/README.md) |
[Archive](./10-archiving-and-compression/README.md) |
[Packages](./11-package-management/README.md) |
[Services](./12-service-management/README.md) |
[Networking](./13-networking/README.md) |
[Logs](./14-logs-and-debug/README.md) |
[Interview](./99-interview-prep/README.md)

---

## Why Linux — and Why Ubuntu

Every server you will ever SSH into in a DevOps role runs Linux. AWS EC2 instances run Linux. Docker containers run Linux. Kubernetes nodes run Linux. The CI runners that build your images run Linux. Learning Linux is not optional in this stack — it is the ground everything else stands on.

Ubuntu is the distribution this runbook uses because it is the default for AWS EC2, the most common choice in DevOps job environments, and the distribution all tooling in this series assumes. The concepts transfer directly to any other Linux distribution — the package manager and a few paths change, nothing fundamental does.

---

## The Linux Stack

Linux is not one thing. It is layers. Each layer has one job.
Every file in these notes lives on a specific layer.
When something breaks, you know exactly which layer to look at.

```
  ┌─────────────────────────────────────────────────────────────────────┐
  │  L6  YOU                                                            │
  │       ~ · /home/akhil · .bashrc · .ssh/ · .config/                  │
  │       you land here every time you SSH into a server                │
  ├─────────────────────────────────────────────────────────────────────┤
  │  L5  TOOLS & FILES                                                  │
  │       /usr/bin · /usr/local/bin · /opt                              │
  │       the commands you run · the files you edit · the scripts       │
  ├─────────────────────────────────────────────────────────────────────┤
  │  L4  CONFIG                                                         │
  │       /etc — users · passwords · groups · network · services        │
  │       you edit /etc to change how the system behaves                │
  ├─────────────────────────────────────────────────────────────────────┤
  │  L3  STATE & DEBUG                    ← start here when prod breaks │
  │       /var/log · /var/lib · /run                                    │
  │       logs of everything that happened · live state of what runs    │
  ├─────────────────────────────────────────────────────────────────────┤
  │  L2  NETWORKING                                                     │
  │       /etc/hosts · /etc/netplan · /sys/class/net                    │
  │       how this machine talks to the world                           │
  ├─────────────────────────────────────────────────────────────────────┤
  │  L1  PROCESS MANAGER                                                │
  │       systemd · PID 1 · /etc/systemd/system                         │
  │       starts and watches every service you deploy                   │
  ├─────────────────────────────────────────────────────────────────────┤
  │  L0  FOUNDATION                                                     │
  │       kernel · GRUB · /boot · hardware · cloud VM                   │
  │       everything above sits on top of this                          │
  └─────────────────────────────────────────────────────────────────────┘
```

---

## When Production Breaks

You SSH into a server. Something is wrong.
You do not panic. You ask these questions in order.
Each question maps to a layer. Each layer has a file.

```
  SYMPTOM                            LAYER   FIRST COMMAND
  ─────────────────────────────────────────────────────────────────────
  Can't find a file or command     → L5/L6   pwd · ls · which nginx
  Config change broke something    → L4      nginx -t · cat /etc/nginx/nginx.conf
  Need to know what happened       → L3      journalctl -u nginx · tail /var/log/syslog
  Can't reach the server           → L2      ip addr · ss -tulnp · curl -I localhost
  Service is down                  → L1      systemctl status nginx
  Machine is slow or unresponsive  → L0      uptime · free -h · df -h · dmesg | tail
  ─────────────────────────────────────────────────────────────────────
```

---

## The Running Example

Every file uses the same webstore project on disk.
This is the same app that gets containerized in Docker,
orchestrated in Kubernetes, and deployed to AWS.
It starts here as a directory on a Linux server.

```
~/webstore/
├── frontend/       ← static files nginx will serve
├── api/            ← application code
├── db/             ← database schemas
├── logs/           ← access.log, error.log
├── config/         ← webstore.conf
└── backup/         ← archives before deploys
```

By the end of Linux you will have built this structure from scratch,
written config files into it, searched its logs with grep and awk,
set correct ownership and permissions on every folder, archived it
with tar, installed nginx to serve the frontend, managed nginx as a
systemd service, and debugged it live over the network with curl and tcpdump.

---

## Where You Take the Webstore

You arrive at Linux with nothing — a blank server and a project idea.
You leave with the webstore running on that server, files organized,
permissions locked, nginx serving the frontend, logs being written,
and the whole project archived and ready to hand off.

That is the state Git picks up from. You do not start Git with a
blank folder — you start it with a working server setup that already
has history worth tracking.

---

## Files — Read in This Order

Each file only requires knowledge from the files before it.
Every example uses the webstore. Every file leaves something working.

| # | File | Layer | After reading this you can |
|---|---|---|---|
| 01 | [Boot Process](./01-boot-process/README.md) | L0 | Explain every step from power-on to login. Read a boot failure and know which stage broke. |
| 02 | [Basics](./02-basics/README.md) | L6 | Navigate any Linux server. Know where you are, what is running, what the disk looks like. |
| 03 | [Working with Files](./03-working-with-files/README.md) | L5 | Copy, move, rename, link files. Back up a directory safely before changing it. |
| 04 | [Filter Commands](./04-filter-commands/README.md) | L5 | Search logs, count errors, extract fields, chain commands together in a pipeline. |
| 05 | [sed](./05-sed-stream-editor/README.md) | L5 | Edit config files from the command line without opening an editor. |
| 06 | [awk](./06-awk/README.md) | L5 | Process log files, calculate totals, build reports from raw text. |
| 07 | [vim](./07-text-editor/README.md) | L5 | Edit any file on any server — even with no GUI, no nano, nothing else. |
| 08 | [Users & Groups](./08-user-and-group-management/README.md) | L4 | Create users, manage groups, set up service accounts with least privilege. |
| 09 | [Permissions](./09-file-ownership-and-permissions/README.md) | L4 | Control exactly who can read, write, and execute every file on the system. |
| 10 | [Archiving](./10-archiving-and-compression/README.md) | L5 | Back up directories, compress logs, restore from an archive. |
| 11 | [Package Management](./11-package-management/README.md) | L5 | Install, update, and remove software. Understand what apt actually does to the system. |
| 12 | [Service Management](./12-service-management/README.md) | L1 | Start, stop, enable services. Write a systemd unit file. Read service logs. |
| 13 | [Networking](./13-networking/README.md) | L2 | Debug connectivity, check open ports, trace where a request fails. |
| 14 | [Logs & Debug](./14-logs-and-debug/README.md) | L3 | Read any log, follow a live stream, run a full debug workflow end to end. |

---

## What You Can Do After This

- Navigate any Linux server confidently over SSH with no GUI
- Search and analyze log files to debug real incidents
- Create users and groups, set correct file ownership and permissions
- Install software, manage services, and configure nginx
- Use curl, dig, ss, and tcpdump to debug network issues live
- Archive and restore directories for backups and deploys
- Write and edit files directly on a server using vim
- Run a structured debug workflow from symptom to fix

---

## How to Use This

Read files in order. Each one builds on the previous.
Do the "On the webstore" section in every file before moving on.
The webstore must be in the state described at the end of each file.
If it is not — go back. Moving forward on a broken foundation means
every file after it will be harder than it should be.

---

## What Comes Next

→ [02. Git & GitHub – Version Control](../02.%20Git%20%26%20GitHub%20–%20Version%20Control/README.md)

Linux gives you the server foundation. Git gives you the workflow
foundation — version control, collaboration, and the habit of tracking
every change you make to infrastructure and code. The webstore
directory you built here becomes the first Git repository you initialize.


## 🚀 Practice Lab & Setup

We recommend **Google Cloud Shell** as your lab. It is a real Linux server in your browser.

* **Lab Portal:** [Launch Google Cloud Shell](https://shell.cloud.google.com/?hl=en_GB&theme=dark&authuser=0&fromcloudshell=true&show=terminal)
* **Specs:** 2 vCPUs, 5 GB RAM, 5 GB persistent home directory.
* **Usage:** 50 free hours per week. **Always type `exit` to save your quota!**

<details>
<summary><b>🎨 Click to expand: Customize Your Prompt (Permanent)</b></summary>
<br>

Cloud Shell defaults to a long, messy username. Follow these steps to set a clean "Production" prompt:

1. Open config: `nano ~/.bashrc`
2. Paste at the bottom: 
   ```bash
   export PS1="\[\e[1;32m\][Webstore-Prod]\[\e[m\]:\[\e[1;34m\]\w\[\e[m\]\$ "
3. **Save/Exit:** Ctrl+O, Enter, Ctrl+X
4. Apply: source ~/.bashrc

</details>
