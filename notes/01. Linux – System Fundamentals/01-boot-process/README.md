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
