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
