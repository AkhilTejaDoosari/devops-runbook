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

````
╔══════════════════════════════════════════════════════════════════════════════╗
║                                                                              ║
║            L I N U X   —   C O M P L E T E   S Y S T E M   M A P             ║
║                                                                              ║
║   Read: BOTTOM → UP   (hardware is the foundation, you live at the top)      ║
║   Each layer cannot exist without everything below it.                       ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝

  NAVIGATION
  ──────────
  [ENTRY]      ← where YOU land when you open a terminal
  [YOU ARE]    ← your current position in the map
  [WARNING]    ← do not touch without knowing what you are doing
  [VIRTUAL]    ← not real files on disk, kernel generates them live
  [RAM]        ← lives in memory, wiped on every reboot
  [PRIORITY]   ← order matters, higher number = lower priority
  ───────────────────────────────────────────────────────────────────────────


███████████████████████████████████████████████████████████████████████████████
  PART 5 — USER SPACE     (where humans work)
███████████████████████████████████████████████████████████████████████████████

  [ENTRY] ─── when you open a terminal you land here ──────────────────────────
  │
  │   ~ (tilde)  =  shorthand for YOUR home directory
  │                 shell replaces ~ with /home/<your-username>
  │                 $HOME variable holds the same value
  │
  └── /home/                          one folder per user account
      │
      ├── akhil/           [YOU ARE]  regular user
      ├── charan/                     regular user
      ├── pramod/                     regular user
      │
      ├── navya/                      regular user
      └── indhu/                      regular user

  ─────────────────────────────────────────────────────────────────────────────
  INSIDE /home/akhil/   (same structure for every user)
  ─────────────────────────────────────────────────────────────────────────────

  /home/akhil/
  │
  ├── Desktop/
  ├── Downloads/
  ├── Documents/
  ├── Pictures/
  ├── Videos/
  ├── Music/
  │
  ├── .bashrc                  your shell config, aliases, custom prompt
  ├── .bash_profile            runs once at login  (sets PATH, env vars)
  ├── .bash_history            every command you have typed
  │
  ├── .ssh/                    SSH keys  [WARNING — private keys never share]
  │   ├── id_ed25519           private key
  │   ├── id_ed25519.pub       public key
  │   ├── known_hosts          servers you connected to before
  │   └── config               per-host SSH shortcuts
  │
  ├── .config/                 per-app config (modern standard)
  │   ├── nvim/
  │   ├── htop/
  │   └── Code/
  │
  ├── .local/
  │   ├── bin/                 your personal commands  (add to PATH)
  │   └── share/               your app data
  │
  └── .gnupg/                  GPG encryption keys

  ─────────────────────────────────────────────────────────────────────────────
  USERS & GROUPS    ← managed in /etc, shown here for context
  ─────────────────────────────────────────────────────────────────────────────

  USERS:
  akhil   uid=1000   /home/akhil    primary user (first created = 1000)
  charan  uid=1001   /home/charan
  pramod  uid=1002   /home/pramod
  navya   uid=1003   /home/navya
  indhu   uid=1004   /home/indhu

  GROUPS (example setup):
  developers    akhil  charan  pramod     can write to project files
  designers     navya  indhu              can write to design assets
  docker        akhil  charan  pramod     can run Docker without sudo
  sudo          akhil                     only akhil can sudo on this machine

  How groups work:
  /etc/passwd   ← list of users
  /etc/shadow   ← their hashed passwords  (root only)
  /etc/group    ← list of groups and members

  /home/akhil/    owned by akhil:akhil     chmod 700   (only akhil sees inside)
  /home/charan/   owned by charan:charan   chmod 700
  shared project folder example:
  /srv/project/   owned by root:developers  chmod 775  (developers can write)


███████████████████████████████████████████████████████████████████████████████
  PART 4 — FILESYSTEM TREE     (the full / hierarchy)
███████████████████████████████████████████████████████████████████████████████

  /                               root directory  [WARNING — never delete anything here]
  │                               NOT the root user. The top of ALL paths.
  │
  ├── home/                       ↑ covered in Part 5 above
  │
  ├── root/                       home for the ROOT USER  (not same as /)
  │                               root user = superuser, uid=0
  │                               separate from /home on purpose
  │
  ├── etc/                        system-wide config  [WARNING — text files only, no binaries]
  │   │
  │   ├── ── USERS & SECURITY ──
  │   ├── passwd                  all user accounts  (not passwords despite name)
  │   ├── shadow                  hashed passwords    [WARNING — root eyes only]
  │   ├── group                   groups and members
  │   ├── sudoers                 who can sudo  [WARNING — edit only with: visudo]
  │   │
  │   ├── ── NETWORK ──
  │   ├── hostname                this machine's name
  │   ├── hosts                   IP → name map, checked BEFORE dns
  │   ├── resolv.conf             which DNS servers to use
  │   ├── netplan/                network config  (Ubuntu 18.04+)
  │   ├── network/interfaces      network config  (older Debian)
  │   ├── NetworkManager/         network config  (most desktops)
  │   │
  │   ├── ── FILESYSTEM & BOOT ──
  │   ├── fstab                   which disks mount at boot and where  [WARNING — wrong entry = no boot]
  │   ├── crypttab                encrypted volumes to unlock at boot
  │   ├── default/grub            GRUB settings  ← edit this, then: update-grub
  │   │
  │   ├── ── SERVICES ──
  │   ├── systemd/                systemd config  [PRIORITY 1 — your overrides win]
  │   │   ├── system/             your unit files  *.service  *.timer  *.socket
  │   │   ├── journald.conf       log settings
  │   │   ├── logind.conf         login & session settings
  │   │   ├── resolved.conf       DNS resolver settings
  │   │   └── timesyncd.conf      time sync settings
  │   ├── crontab                 system scheduled tasks
  │   ├── cron.d/                 per-package scheduled tasks
  │   ├── ssh/                    SSH server config & host keys
  │   ├── nginx/                  nginx web server config
  │   ├── apt/                    package manager config & sources
  │   │
  │   └── ── SHELL & ENV ──
  │       ├── profile             login shell env for ALL users
  │       ├── profile.d/          drop-in scripts sourced by profile
  │       ├── bash.bashrc         interactive shell config for ALL users
  │       ├── environment         system-wide environment variables
  │       └── shells              list of valid login shells
  │
  ├── usr/                        installed software  (read-only at runtime)
  │   ├── bin/                    user programs  ls git python3 curl vim ssh…
  │   ├── sbin/                   admin programs  useradd iptables sshd fdisk…
  │   ├── lib/                    shared libraries
  │   │   ├── systemd/
  │   │   │   ├── systemd         ← the systemd BINARY lives here
  │   │   │   └── system/         vendor unit files  [PRIORITY 3 — never edit]
  │   │   │       ├── nginx.service
  │   │   │       ├── ssh.service
  │   │   │       └── cron.service  …and hundreds more
  │   │   ├── libc.so             C standard library
  │   │   └── libssl.so           OpenSSL
  │   ├── include/                C/C++ headers for compiling
  │   ├── share/                  docs, fonts, icons, man pages, timezones
  │   │   ├── man/                man page source  (man ls reads from here)
  │   │   ├── doc/                package documentation
  │   │   ├── fonts/
  │   │   ├── icons/
  │   │   └── zoneinfo/           timezone data
  │   └── local/                  your manually compiled software  (apt never touches)
  │       ├── bin/
  │       ├── lib/
  │       ├── etc/
  │       └── share/
  │
  ├── opt/                        self-contained third-party apps
  │   ├── google/chrome/          Chrome lives here
  │   └── discord/                Discord lives here
  │
  ├── var/                        variable data — grows while system runs
  │   ├── log/                    ALL system logs   ← check here when things break
  │   │   ├── syslog              main system messages
  │   │   ├── auth.log            logins  sudo  SSH  [WARNING — contains real access data]
  │   │   ├── kern.log            kernel messages
  │   │   ├── dpkg.log            package install history
  │   │   ├── apt/
  │   │   ├── nginx/
  │   │   └── journal/            systemd binary journal  (read: journalctl)
  │   ├── lib/                    persistent app state
  │   │   ├── apt/lists/          cached package lists
  │   │   ├── dpkg/               installed package database
  │   │   ├── docker/             Docker images and volumes
  │   │   └── mysql/              database files
  │   ├── cache/                  safe-to-delete computed data
  │   │   └── apt/archives/       downloaded .deb files  (clear: apt clean)
  │   ├── spool/                  queues
  │   │   ├── mail/               local user mail
  │   │   ├── cron/               per-user crontab files
  │   │   └── cups/               print jobs
  │   └── tmp/                    temp files that survive reboot
  │
  ├── tmp/                        temp files  [RAM] wiped on reboot
  │
  ├── run/                        [RAM] runtime data since last boot
  │   ├── *.pid                   process ID files
  │   ├── *.sock                  unix sockets — inter-process comms
  │   ├── systemd/system/         runtime unit files  [PRIORITY 2]
  │   └── user/
  │       ├── 1000/               akhil's runtime session dir
  │       ├── 1001/               charan's runtime session dir
  │       ├── 1002/               pramod's runtime session dir
  │       ├── 1003/               navya's runtime session dir
  │       └── 1004/               indhu's runtime session dir
  │
  ├── dev/                        [VIRTUAL] every device is a file
  │   ├── sda  sda1  sda2         SATA disks and partitions
  │   ├── nvme0n1                 NVMe SSD
  │   ├── null                    the void  (discard anything written here)
  │   ├── zero                    infinite zeros
  │   ├── urandom                 random data
  │   ├── tty                     current terminal
  │   └── loop0                   loop device for mounting .iso files
  │
  ├── proc/                       [VIRTUAL] live window into kernel and processes
  │   ├── 1/                      PID 1 = systemd
  │   ├── <PID>/                  every running process has a folder here
  │   │   ├── cmdline             what command started it
  │   │   ├── status              memory, state, uid
  │   │   └── fd/                 open files
  │   ├── cpuinfo                 CPU model, cores, speed
  │   ├── meminfo                 RAM total / used / free
  │   ├── uptime                  seconds since boot
  │   └── net/                    network stats
  │
  ├── sys/                        [VIRTUAL] live hardware and kernel tunables
  │   ├── class/net/              network interfaces  (eth0, wlan0, lo)
  │   ├── block/                  block devices  (sda, nvme0n1)
  │   ├── bus/                    hardware buses  (PCI, USB)
  │   └── power/                  suspend, hibernate controls
  │
  ├── boot/                       needed BEFORE / is mounted  [WARNING — do not delete]
  │   ├── vmlinuz-*               the kernel image  ← this IS linux
  │   ├── initrd.img-*            initial RAM disk for early boot
  │   └── grub/
  │       ├── grub.cfg            auto-generated  [WARNING — do not edit directly]
  │       └── grub.d/             scripts that generate grub.cfg
  │
  ├── bin/   → /usr/bin           [SYMLINK] same thing on modern distros
  ├── sbin/  → /usr/sbin          [SYMLINK]
  ├── lib/   → /usr/lib           [SYMLINK]
  ├── lib64/ → /usr/lib64         [SYMLINK]
  │
  ├── mnt/                        manual temporary mount point
  ├── media/                      auto-mounted USB, DVD, external drives
  ├── srv/                        data served by this host  (web, ftp roots)
  └── lost+found/                 recovered file fragments after disk check


███████████████████████████████████████████████████████████████████████████████
  PART 3 — systemd    (the process manager)
███████████████████████████████████████████████████████████████████████████████

  systemd  (PID 1)
  │   first process the kernel starts after boot
  │   parent of EVERY other process on the system
  │   manages services, mounts, timers, sockets, logging
  │
  │   BINARY:    /usr/lib/systemd/systemd
  │
  │   UNIT FILE LOCATIONS  (priority order — 1 wins over 3)
  │
  │   [PRIORITY 1]  /etc/systemd/system/          YOUR overrides  ← edit here
  │   [PRIORITY 2]  /run/systemd/system/          runtime  (lost on reboot)
  │   [PRIORITY 3]  /usr/lib/systemd/system/      vendor defaults  ← never edit
  │
  │   UNIT TYPES:
  │   *.service    a program or daemon  (nginx, ssh, cron)
  │   *.timer      scheduled task  (modern cron alternative)
  │   *.socket     socket-activated service
  │   *.mount      filesystem mount point
  │   *.target     group of units  (like a runlevel)
  │
  └── PROCESSES it spawns:
      akhil   (uid 1000)   session started when akhil logs in
      charan  (uid 1001)   session started when charan logs in
      pramod  (uid 1002)   session started when pramod logs in
      navya   (uid 1003)   session started when navya logs in
      indhu   (uid 1004)   session started when indhu logs in
      nginx   (uid www-data)  web server service
      sshd    (uid root)      SSH daemon
      cron    (uid root)      task scheduler


███████████████████████████████████████████████████████████████████████████████
  PART 2 — LINUX KERNEL
███████████████████████████████████████████████████████████████████████████████

  Linux Kernel
  │   the real boss — talks directly to hardware
  │   everything above it is built on what it provides
  │
  │   BINARY:   /boot/vmlinuz-*
  │
  ├── process manager        decides which process runs on which CPU core
  ├── memory manager         controls who gets RAM and how much
  ├── VFS                    virtual filesystem — unifies all storage as files
  ├── device drivers         speaks to disks, GPU, NIC, USB, audio…
  ├── networking stack       TCP/IP built into the kernel
  └── scheduler              keeps everything running fairly and fast


███████████████████████████████████████████████████████████████████████████████
  PART 1 — BOOT LAYER     (before the OS exists)
███████████████████████████████████████████████████████████████████████████████

  GRUB  (bootloader)
  │   first software with a purpose that runs after BIOS hands over
  │   reads the disk, finds the kernel, loads it into RAM, passes control
  │
  │   BINARY:   /boot/grub/
  │   CONFIG:   /boot/grub/grub.cfg     auto-generated  [WARNING — do not edit]
  │   SETTINGS: /etc/default/grub       ← edit this, then run: sudo update-grub
  │
  └── loads → kernel + initrd.img into RAM then hands over control


███████████████████████████████████████████████████████████████████████████████
  PART 0 — HARDWARE + FIRMWARE     (the physical foundation)
███████████████████████████████████████████████████████████████████████████████

  ┌──────────────────────────────────────────────────────────────────────────┐
  │                        BIOS / UEFI                                       │
  │                motherboard firmware — always there                       │
  │   powers on hardware → runs POST → finds bootable disk → hands to GRUB   │
  └──────────────────────────────────────────────────────────────────────────┘
                                   │
  ┌──────────────────────────────────────────────────────────────────────────┐
  │                      YOUR PC HARDWARE                                    │
  │                                                                          │
  │     CPU          executes instructions                                   │
  │     RAM          temporary fast memory  (everything running lives here)  │
  │     DISK         permanent storage  (everything in / lives here)         │
  │     NIC          network interface card                                  │
  │     GPU          graphics                                                │
  └──────────────────────────────────────────────────────────────────────────┘


╔══════════════════════════════════════════════════════════════════════════════╗
║   QUICK REFERENCE                                                            ║
╠══════════════════════════════════════════════════════════════════════════════╣
║                                                                              ║
║   where am i?              pwd                                               ║
║   go home                  cd ~   or just   cd                               ║
║   see hidden files         ls -la                                            ║
║   see who i am             whoami                                            ║
║   see all users            cat /etc/passwd                                   ║
║   see all groups           cat /etc/group                                    ║
║   see running processes    ps aux   or   top   or   htop                     ║
║   see open ports           ss -tulnp                                         ║
║   see network interfaces   ip addr                                           ║
║   watch live logs          journalctl -f                                     ║
║   see disk usage           df -h                                             ║
║   see folder sizes         du -sh /*                                         ║
║   see RAM usage            free -h                                           ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝
````
