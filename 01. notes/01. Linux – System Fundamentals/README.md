[Boot](01-boot-process/README.md) | 
[Basics](02-basics/README.md) | 
[Files](03-working-with-files/README.md) | 
[Filters](04-filter-commands/README.md) | 
[sed](05-sed-stream-editor/README.md) | 
[awk](06-awk/README.md) | 
[Editors](07-text-editor/README.md) | 
[Users](08-user-&-group-management/README.md) | 
[Permissions](09-file-ownership-&-permissions/README.md) | 
[Archive](10-archiving-and-compression/README.md) | 
[Packages](11-package-management/README.md) | 
[Services](12-service-management/README.md) | 
[Networking](13-networking/README.md)

---

# Linux Fundamentals for DevOps Engineers

A comprehensive, production-focused Linux guide built for cloud support, DevOps, and systems engineering roles. Learn Linux the way professionals actually use it: real commands, real scenarios, real troubleshooting.

## Why This Series Exists

Most Linux tutorials either:
- Teach every command flag ever created (overwhelming)
- Focus on desktop Linux (irrelevant for servers)
- Assume you already know the basics (unhelpful)
- Cover theory without practice (boring)

This series teaches Linux **the way DevOps engineers actually use it**: SSH into servers, debug production issues, write automation scripts, manage services at scale.

## What Makes This Different

**Zero to production-ready in 13 files:**
- Starts with boot process (what actually happens when a server starts)
- Builds concepts in dependency order (can't learn permissions before users)
- Uses real scenarios (web servers, database servers, actual debugging)
- Explains WHY commands exist, not just syntax
- No certification fluff, only practical knowledge
- Every file follows the same scannable structure

## The Series

### Foundation
**[01. Boot Process](01-boot-process/README.md)**  
What happens from power-on to login prompt. BIOS/UEFI, bootloader (GRUB), kernel initialization, systemd/init, runlevels. Understand why servers sometimes don't boot.

**[02. Basics](02-basics/README.md)**  
Core commands for navigation, file inspection, and system information. `ls`, `cd`, `pwd`, `cat`, `head`, `tail`, `grep`, `find`, `which`, `whereis`. The commands you'll use every single day.

**[03. Working with Files](03-working-with-files/README.md)**  
Creating, copying, moving, deleting files and directories. `touch`, `cp`, `mv`, `rm`, `mkdir`, `rmdir`. File paths (absolute vs relative), wildcards, hidden files.

### Text Processing
**[04. Filter Commands](04-filter-commands/README.md)**  
Transform and analyze text streams. `grep`, `cut`, `sort`, `uniq`, `wc`, `tr`, `head`, `tail`, `tee`. Piping commands together. Essential for log analysis.

**[05. sed (Stream Editor)](05-sed-stream-editor/README.md)**  
Find and replace at scale. Edit files in place, transform data, automate text processing. The power tool for automation scripts.

**[06. awk](06-awk/README.md)**  
Pattern matching and text processing language. Extract columns, filter rows, perform calculations. Essential for parsing logs and structured data.

**[07. Text Editors](07-text-editor/README.md)**  
`vi`/`vim` and `nano`. Edit files on remote servers without a GUI. Survival mode for vim (how to exit), efficient editing, configuration files.

### System Administration
**[08. User & Group Management](08-user-&-group-management/README.md)**  
Creating users, managing groups, sudo access. `useradd`, `usermod`, `userdel`, `groupadd`, `/etc/passwd`, `/etc/shadow`, `/etc/sudoers`. Multi-user security.

**[09. File Ownership & Permissions](09-file-ownership-&-permissions/README.md)**  
`chmod`, `chown`, `chgrp`, permission modes (rwx), octal notation (755, 644), special permissions (setuid, setgid, sticky bit). Security fundamentals.

**[10. Archiving & Compression](10-archiving-and-compression/README.md)**  
`tar`, `gzip`, `bzip2`, `zip`, `unzip`. Backup strategies, transferring files, reducing storage. The difference between archiving and compression.

### Operations
**[11. Package Management](11-package-management/README.md)**  
Installing, updating, removing software. `apt` (Ubuntu/Debian), `yum`/`dnf` (RHEL/CentOS), package repositories, dependency management. Keep systems updated and secure.

**[12. Service Management](12-service-management/README.md)**  
`systemctl`, `service`, starting/stopping/enabling services, viewing logs with `journalctl`. Managing web servers, databases, and application daemons.

**[13. Networking](13-networking/README.md)**  
Network configuration, troubleshooting connectivity. `ip`, `ifconfig`, `ping`, `traceroute`, `netstat`, `ss`, `curl`, `wget`. Firewall basics (`ufw`, `firewalld`).

## Critical Concepts You'll Master

**The Big Three:**
1. **Everything is a file** - Devices, processes, sockets—all accessible as files
2. **Pipes are power** - Chain commands to build complex operations from simple tools
3. **Permissions matter** - Understanding rwx prevents security issues and access problems

**DevOps Essentials:**
- How to SSH into a server and not panic
- Read and analyze log files efficiently
- Automate repetitive tasks with scripting
- Debug why a service won't start
- Secure systems with proper permissions
- Manage users and access control

## Learning Path

**Absolute beginner?** Read in order (01→13). Each file builds on previous concepts.

**Have some Linux knowledge?** Jump to specific files based on what you need to learn, but Files 08-09 (users/permissions) are critical even if you think you know them.

**Debugging production issue?** Jump to the relevant file (Services for daemon problems, Networking for connectivity, etc.)

## Prerequisites

**Required:** 
- Access to a Linux system (Ubuntu VM, EC2 instance, WSL, or Docker container)
- Basic computer literacy

**Helpful but not required:**
- Used command line before (any OS)
- SSH'd into a server
- Edited a text file

## What You'll Be Able to Do

After completing this series:

✅ SSH into servers confidently  
✅ Navigate filesystems efficiently  
✅ Analyze log files to debug issues  
✅ Create and manage users/groups  
✅ Set proper file permissions  
✅ Install and configure software packages  
✅ Start/stop/monitor system services  
✅ Write basic automation scripts  
✅ Troubleshoot network connectivity  
✅ Understand what happens during boot  

## How to Use This Series

**Each file contains:**
- Clear explanations (why, not just what)
- Step-by-step command tables
- Real scenarios (web servers, databases, automation)
- Common mistakes and how to avoid them
- "Final Compression" (memorize this)

**Learn actively:**
- Run every command on your own system
- Break things intentionally to see error messages
- Practice on real servers (not just reading)
- Build muscle memory for common operations

## Philosophy

**This series believes:**
- Practical > Theoretical
- Understanding > Memorization  
- Real servers > Desktop Linux
- Common tasks > Obscure features
- Production mindset > Hobbyist approach

**This series avoids:**
- Linux+ certification fluff
- Desktop environment configuration
- Rarely-used command flags
- Historical trivia without context
- "Try this weird trick" gimmicks

## Navigation

Each file has navigation links at the top. Click to jump between files. Files are in logical order—later files reference concepts from earlier ones.

## Start Learning

**Ready?** Begin with [01. Boot Process](01-boot-process/README.md)

**Want to test your setup?** Try these commands:
```bash
# Check your Linux distribution
cat /etc/os-release

# Check your shell
echo $SHELL

# See your current directory
pwd

# List files (including hidden)
ls -la

# Check system uptime
uptime
```

If these commands work, you're ready to start.

---

**Built for:** Cloud support engineers, DevOps engineers, SREs, systems administrators  
**Focus:** Server management, automation, production environments  
**Level:** Beginner to intermediate  
**Goal:** Turn Linux confusion into confident systems knowledge

---

## Quick Command Reference

**Navigation:**
```bash
pwd                  # Where am I?
ls -la               # What's here?
cd /path/to/dir      # Go somewhere
cd ..                # Go up one level
cd ~                 # Go home
```

**File Operations:**
```bash
cat file.txt         # View file
less file.txt        # View file (paginated)
cp source dest       # Copy
mv source dest       # Move/rename
rm file.txt          # Delete
mkdir dirname        # Create directory
```

**Text Processing:**
```bash
grep "pattern" file  # Search in file
grep -r "pattern" /path  # Search recursively
sed 's/old/new/g' file   # Find and replace
awk '{print $1}' file    # Print first column
```

**System:**
```bash
sudo command         # Run as superuser
systemctl status service  # Check service status
journalctl -u service     # View service logs
df -h                # Disk usage
free -h              # Memory usage
top                  # Process monitor
```

**Networking:**
```bash
ip addr              # Show IP addresses
ping host            # Test connectivity
curl http://url      # Fetch URL
ss -tulpn            # Show listening ports
```

**Permissions:**
```bash
chmod 755 file       # Change permissions
chown user:group file  # Change owner
ls -l                # View permissions
```

**This is your Linux foundation. Start at File 01 and build from there.**