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

# 🐧 Boot Process

## Table of Contents
- [1. Theory & Notes](#1-theory--notes)
- [2. Real Examples](#2-real-examples)
- [3. Practical Use Cases](#3-practical-use-cases)
- [4. Quick Command Summary](#4-quick-command-summary)

---

<details>
<summary><strong>1. Theory & Notes</strong></summary>

### Linux Architecture Layers

Linux architecture is layered like a stack:

1. **Hardware** – CPU, RAM, disk, NIC, etc.
2. **Kernel** – The brain that talks to hardware.
3. **Shell** – CLI interface between user and kernel.
4. **Applications** – Browsers, servers, databases, tools.

Each layer builds on the one below. Example:
- Click "Save" in an app → goes to shell → kernel handles → writes to hardware.

---

### Power ON & Firmware

- System gets power → firmware starts (BIOS or UEFI).
- Runs **POST** to check hardware (RAM, CPU, storage).
- Finds a bootable disk (e.g., SSD) to hand off to bootloader.

> BIOS = Basic Input/Output System  
> UEFI = Unified Extensible Firmware Interface (modern firmware)

---

### Disk Partitioning: MBR vs GPT

- **MBR** = Master Boot Record
  - Max 4 primary partitions
  - Max 2 TB
- **GPT** = GUID Partition Table
  - Works with UEFI
  - Supports huge disks + many partitions

Both store where bootloader is.

---

### Bootloader – GRUB2

**What is it?**
- Tiny program that loads the kernel and `initramfs`.

**Tasks:**
- Show OS selection menu
- Load Linux kernel into memory
- Load initramfs (temporary root filesystem)

**Main Files:**
- `/boot/grub2/`, `/boot/efi/EFI/`
- `/etc/default/grub`, `/etc/grub.d/`
- Final config → `/boot/grub2/grub.cfg` or `/boot/efi/EFI/.../grub.cfg`

---

### Kernel – The Linux Brain

**Job:**
- Load drivers
- Mount the real root filesystem (like `/dev/sda1`)
- Start `init` (which becomes `systemd`)

**initramfs**:
- Temporary root with essential drivers
- Needed before real `/` mount

---

### systemd – First User-Space Process

- PID = 1
- Starts all services (daemons)
- Manages logs, mounts, targets
- Replaces old SysV `init`

**Main unit types:**
- `.service` → start/stop daemons
- `.target` → boot states
- `.socket`, `.mount`, `.timer`

---

### Runlevels vs Targets

| Runlevel | systemd Target    | Purpose                  |
|----------|-------------------|--------------------------|
| 0        | poweroff.target   | Shutdown                 |
| 1        | rescue.target     | Single-user mode         |
| 3        | multi-user.target | CLI, no GUI              |
| 5        | graphical.target  | Multi-user with GUI      |
| 6        | reboot.target     | Restart the system       |

---

### Login Stage

Once systemd finishes, you get:
- CLI login (for servers)
- GUI login screen (for desktops)

Then you’re ready to use the system.

</details>

---

<details>
<summary><strong>2. Real Examples</strong></summary>

```bash
# Kernel version
uname -r
````

```output
6.5.0-25-generic
```

```bash
# Boot-time logs
dmesg | less
```

```bash
# Running services
systemctl list-units --type=service
```

```bash
# View kernel + grub files
ls /boot
```

```bash
# GRUB default config
cat /etc/default/grub
```

```bash
# Regenerate GRUB (Debian/Ubuntu)
sudo update-grub
```

</details>

---

<details>
<summary><strong>3. Practical Use Cases</strong></summary>

* Debug boot failures like kernel panics, GRUB issues, and disk mounting errors.
* Manage dual boot setups between Linux and Windows.
* Automate server provisioning with cloud-init and systemd targets.
* Configure secure boot or kernel-level startup for compliance and recovery.

</details>

---

<details>
<summary><strong>4. Quick Command Summary</strong></summary>

| Command                               | Description                           |                              |
| ------------------------------------- | ------------------------------------- | ---------------------------- |
| `uname -r`                            | Show current kernel version           |                              |
| \`dmesg                               | less\`                                | View kernel/system boot logs |
| `systemctl list-units --type=service` | List all active services              |                              |
| `ls /boot`                            | Kernel + GRUB files                   |                              |
| `cat /etc/default/grub`               | GRUB user config                      |                              |
| `sudo update-grub`                    | Regenerate `grub.cfg` (Ubuntu/Debian) |                              |
| `reboot` / `shutdown -h now`          | Restart or shut down the system       |                              |

</details>