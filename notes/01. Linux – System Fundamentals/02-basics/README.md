[← devops-runbook](../../README.md) | 
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

# 🐧 Basics

---

## Table of Contents

- [1. Directory Navigation](#1-directory-navigation)  
- [2. Listing Directory Contents](#2-listing-directory-contents)  
- [3. Terminal Essentials](#3-terminal-essentials)  
- [4. System Information](#4-system-information)  
- [5. Getting Help](#5-getting-help)  
- [6. System Info via `uname`](#6-system-info-via-uname)  
- [7. Quick Command Summary](#7-quick-command-summary) 

---

<details>
<summary><strong>1. Directory Navigation</strong></summary>

## Theory & Notes

- **Filesystem Hierarchy**  
  Linux organizes files and directories in a single inverted tree, starting at the root directory (`/`). Every file and directory lives somewhere under `/`, with no “drives” like in Windows.

- **Current Working Directory (CWD)**  
  The shell always operates in some directory the CWD. You can think of it as “where you are right now” in the filesystem.  
  - `pwd` (“print working directory”) tells you the CWD.  
  - `cd` (“change directory”) moves you to a different directory, either by name or by path.

- **Absolute vs. Relative Paths**  
  - **Absolute path** starts from root: `/home/akhil/projects`  
  - **Relative path** starts from your CWD: if you’re in `/home/akhil`, then `cd linux` takes you to `/home/akhil/linux`.  
  - `..` means “parent directory,” so `cd ..` moves you up one level.

- **Creating Directories**  
  - `mkdir <dir>` makes one new directory.  
  - `mkdir -p a/b/c` will create nested directories in one shot: if `a` or `a/b` don’t exist, they’ll be created automatically.

- **Removing Directories**  
  - `rmdir <dir>` only removes an empty directory.  
  - `rm -rf <dir>` force-deletes a directory and _all_ of its contents (files and subdirectories). **Use with caution!**


---

| Command    | Description                | Syntax            | Example                              |
| ---------- | -------------------------- | ----------------- | ------------------------------------ |
| `pwd`      | Show current directory     | `pwd`             | `pwd`                                 |
| `cd`       | Change directory           | `cd <dir>`        | `cd linux`                            |
| `cd ..`    | Go up one directory level  | `cd ..`           | `cd ..`                               |
| `mkdir`    | Create a new directory     | `mkdir <dir>`     | `mkdir devops`                        |
| `mkdir -p` | Create nested directory    | `mkdir -p a/b/c`  | `mkdir -p akhil/linux/backup`    |
| `rmdir`    | Remove empty directory     | `rmdir <dir>`     | `rmdir devops`                        |
| `rm -rf`   | Delete non-empty directory | `rm -rf <dir>`    | `rm -rf akhil`                       |

</details>

---

<details>
<summary><strong>2. Listing Directory Contents</strong></summary>

## Theory & Notes

- **Listing Files & Directories**  
  The `ls` command shows you what’s in the current directory (or a specified directory). By default, it lists filenames only.

- **Common Options**  
  - `-l` (long format) adds details: permissions, owner, size, and timestamp. (alphabetical order) 
  - `-a` (all) includes hidden files (those beginning with `.`).  
  - `-h` (human-readable) prints file sizes in KB/MB/GB units when used with `-l`.  
  - `-t` (time) sorts by modification time, newest first.  
  - `-r` (reverse) swaps the sort order (oldest first when combined with `-t`).  
  - `-d` (directory) shows information about the directory itself rather than its contents.

- **Combining Options**  
  You can chain multiple flags after a single `-`, for example `ls -lh` or `ls -ltr`. Order doesn’t matter: `ls -lt -r` is equivalent to `ls -lrt`.

---

| Command   | Description                            | Syntax / Example           |
| --------- | -------------------------------------- | -------------------------- |
| `ls`      | List files and directories             | `ls`                       |
| `ls -l`   | Detailed list (permissions, size, etc) in alphabetical order  | `ls -l` |
| `ls -lr`  | Detailed list (permissions, size, etc) in reverse alphabetical order  | `ls -l` |
| `ls -a`   | Include hidden files                     | `ls -a`                     |
| `ls -lh`  | Long format with human-readable sizes    | `ls -lh`                    |
| `ls -lt`  | Sort by modification time (newest first) | `ls -lt`                    |
| `ls -ltr` | Sort by modification time (oldest first) | `ls -ltr`                   |
| `ls -ld`  | Show directory info instead of contents | `ls -ld <dir>` (e.g., `ls -ld devops/`) |

</details>

---

<details>
<summary><strong>3. Terminal Essentials</strong></summary>

## Theory & Notes

- **Clearing the Screen**  
  The `clear` command wipes the terminal display, giving you a fresh view without closing the session or affecting your command history.

- **Command History**  
  The shell keeps a list of commands you’ve executed in the current session (and often across sessions).  
  - `history` prints this list with numbered entries.  
  - You can re-run any past command by referencing its number.

- **Re-running Commands**  
  - `!<num>` retrieves and executes the command with that history number (e.g., `!42`).  
  - `!-1` repeats the very last command you ran. You can also use `!-2`, `!-3`, etc., to go further back.

---

| Command   | Description                   | Syntax / Example  |
| --------- | ----------------------------- | ----------------- |
| `clear`   | Clear the terminal screen     | `clear`           |
| `history` | Show command history          | `history`         |
| `!<num>`  | Re-run command by number      | `!42`             |
| `!-1`     | Re-run last command           | `!-1`             |

</details>

---



<details>
<summary><strong>4. System Information</strong></summary>

## Theory & Notes

- **Current User & Sessions**  
  - `whoami` prints the username of the user running the shell.  
  - `who` shows all users currently logged into the system, their terminals, and login times.

- **System Uptime**  
  - `uptime` reports how long the system has been running, along with load averages for the past 1, 5, and 15 minutes.

- **Date & Time**  
  - `date` displays the current system date and time. You can also format its output (e.g., `date +"%Y-%m-%d %H:%M:%S"`).

---

| Command   | Description               | Syntax / Example                      |
| --------- | ------------------------- | ------------------------------------- |
| `whoami`  | Show current user         | `whoami`                              |
| `who`     | List logged-in users      | `who`                                 |
| `uptime`  | Show system uptime        | `uptime`                              |
| `date`    | Display date and time     | `date`                                |

</details>


---




<details>
<summary><strong>5. Getting Help</strong></summary>

## Theory & Notes

- **Manual Pages (`man`)**  
  Every command usually comes with its own “man page” containing detailed documentation. Use `man <cmd>` to read it in the pager.
  cmd = command
  
- **One-Line Summaries (`whatis`)**  
  Quickly view a brief description of a command without paging through the full manual.

- **Locating Binaries & Documentation (`whereis`)**  
  Finds the locations of the executable, source, and man pages for a given command.

- **Which Executable (`which`)**  
  Shows the exact path of the command that would be executed in your current PATH.

---

| Command   | Description                   | Syntax           | Example        |
| --------- | ----------------------------- | ---------------- | -------------- |
| `man`     | View manual page              | `man <cmd>`      | `man ls`       |
| `whatis`  | One-line description          | `whatis <cmd>`   | `whatis clear` |
| `whereis` | Locate binary and docs        | `whereis <cmd>`  | `whereis uname`|
| `which`   | Show command path             | `which <cmd>`    | `which ls`     |

</details>

---




<details>
<summary><strong>6. System Info via <code>uname</code></strong></summary>

## Theory & Notes

- **`uname` Command**  
  Reports information about the system and kernel. By default, it prints the kernel name.

- **Common Options**  
  - `-s` (kernel name)  
  - `-r` (kernel release version)  
  - `-n` (network node hostname)  
  - `-m` (machine hardware name/type)  
  - `-a` (all) prints all available information in one go

- **Usage**  
  Combine `uname` with these flags to quickly inspect your OS and hardware details, useful for scripting or troubleshooting.

---

| Option | Description         | Syntax / Example |
| ------ | ------------------- | ---------------- |
| `-s`   | Kernel name         | `uname -s`       |
| `-r`   | Kernel release      | `uname -r`       |
| `-n`   | Hostname            | `uname -n`       |
| `-m`   | Machine type        | `uname -m`       |
| `-a`   | All system info     | `uname -a`       |

</details>

---

<details>
<summary><strong>7. Quick Command Summary<code>uname</code></strong></summary>
### Commands Quick Recap

| Command     | Description                                 | Syntax                          | Example                             |
| ----------- | ------------------------------------------- | ------------------------------- | ----------------------------------- |
| `pwd`       | Show current directory                      | `pwd`                           | `pwd`                               |
| `cd`        | Change directory                            | `cd <dir>`                      | `cd linux`                          |
| `cd ..`     | Go up one directory level                   | `cd ..`                         | `cd ..`                             |
| `mkdir`     | Create a new directory                      | `mkdir <dir>`                   | `mkdir devops`                      |
| `mkdir -p`  | Create nested directories                   | `mkdir -p a/b/c`                | `mkdir -p akhil/linux/backup`       |
| `rmdir`     | Remove empty directory                      | `rmdir <dir>`                   | `rmdir devops`                      |
| `rm -rf`    | Delete non-empty directory                  | `rm -rf <dir>`                  | `rm -rf akhil`                      |
| `ls`        | List files and directories                  | `ls`                            | `ls`                                |
| `ls -l`     | Detailed list (permissions, size, etc.)     | `ls -l`                         | `ls -l`                             |
| `ls -lr`    | Detailed list in reverse alphabetical order | `ls -lr`                        | `ls -lr`                            |
| `ls -a`     | Include hidden files                        | `ls -a`                         | `ls -a`                             |
| `ls -lh`    | Long format with human-readable sizes        | `ls -lh`                        | `ls -lh`                            |
| `ls -lt`    | Sort by modification time (newest first)    | `ls -lt`                        | `ls -lt`                            |
| `ls -ltr`   | Sort by modification time (oldest first)    | `ls -ltr`                       | `ls -ltr`                           |
| `ls -ld`    | Show directory info instead of contents     | `ls -ld <dir>`                  | `ls -ld devops/`                    |
| `clear`     | Clear the terminal screen                   | `clear`                         | `clear`                             |
| `history`   | Show command history                        | `history`                       | `history`                           |
| `!<num>`    | Re-run command by history number            | `!<num>`                        | `!42`                               |
| `!-1`       | Re-run last command                         | `!-1`                           | `!-1`                               |
| `whoami`    | Show current user                           | `whoami`                        | `whoami`                            |
| `who`       | List logged-in users                        | `who`                           | `who`                               |
| `uptime`    | Show system uptime and load averages        | `uptime`                        | `uptime`                            |
| `date`      | Display date and time                       | `date`                          | `date`                              |
| `man`       | View manual page                            | `man <cmd>`                     | `man ls`                            |
| `whatis`    | One-line description of a command           | `whatis <cmd>`                  | `whatis clear`                      |
| `whereis`   | Locate binary, source, and man pages        | `whereis <cmd>`                 | `whereis uname`                     |
| `which`     | Show full path of the executable            | `which <cmd>`                   | `which ls`                          |
| `uname -s`  | Show kernel name                            | `uname -s`                      | `uname -s`                          |
| `uname -r`  | Show kernel release version                 | `uname -r`                      | `uname -r`                          |
| `uname -n`  | Show network node hostname                  | `uname -n`                      | `uname -n`                          |
| `uname -m`  | Show machine hardware name/type             | `uname -m`                      | `uname -m`                          |
| `uname -a`  | Show all system information                 | `uname -a`                      | `uname -a`                          |
