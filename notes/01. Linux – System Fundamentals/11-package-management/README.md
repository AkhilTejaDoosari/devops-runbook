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

# 🐧 Package Management

## Table of Contents
1. [Why Packages Matter](#1-why-packages-matter)  
2. [Using APT on Debian/Ubuntu](#2-using-apt-on-debianubuntu)  
3. [Using YUM/DNF on RHEL/CentOS/Fedora](#3-using-yumdnf-on-rhelcentosfedora)  
4. [Comparing Package Managers](#4-comparing-package-managers)  
5. [Quick Command Summary](#5-quick-command-summary)

---

<details>
<summary><strong>1. Why Packages Matter</strong></summary>

**Theory & Purpose**  
- A **package** bundles all files (binaries, libraries, configs, docs) needed to install software.  
- A **package manager** automates:
  - Installation, upgrade, removal  
  - Dependency resolution  
  - Repository management  
  - Cleanup of unused files  
- **Benefits**:
  - **Consistency**: Same version everywhere (development, production)   
  - **Safety**: Verified packages signed with GNU Privacy Guard (GPG)    
  - **Simplicity**: One command instead of dozens     

> **Remember**: Manual installs risk version mismatches and missing dependencies. Always prefer your distro’s package manager for production and development.

</details>

---

<details>
<summary><strong>2. Using APT on Debian/Ubuntu</strong></summary>

**Theory & Notes**  
- APT (`Advanced Package Tool`) is the high-level front end for `.deb` packages.  
- Config lives in `/etc/apt/sources.list` and `/etc/apt/sources.list.d/`.  
- You must **update** the local index after adding repositories.

### Commands Table

| Action            | Command                          | Description                           |
|-------------------|----------------------------------|---------------------------------------|
| Update index      | `sudo apt update`                | Fetch latest package lists            |
| Install package   | `sudo apt install <pkg>`         | Download & install `<pkg>`            |
| Upgrade packages  | `sudo apt upgrade -y`            | Upgrade all installed packages        |
| Remove package    | `sudo apt remove <pkg>`          | Remove `<pkg>` but keep config files  |
| Purge package     | `sudo apt purge <pkg>`           | Remove `<pkg>` including config files |
| Cleanup deps      | `sudo apt autoremove`            | Remove orphaned dependencies          |
| Clean cache       | `sudo apt clean`                 | Delete downloaded `.deb` files        |

### Examples

```bash
# 1. Update before installing:
sudo apt update

# 2. Install nginx web server:
sudo apt install nginx

# 3. Upgrade all packages non-interactively:
sudo apt upgrade -y

# 4. Remove a package but keep its config:
sudo apt remove apache2

# 5. Purge package and configs:
sudo apt purge apache2

# 6. Clean up unused dependencies:
sudo apt autoremove

# 7. Clear local cache:
sudo apt clean
````

</details>

---

<details>
<summary><strong>3. Using YUM/DNF on RHEL/CentOS/Fedora</strong></summary>

**Theory & Notes**

* YUM and DNF are front-end interfaces for `.rpm` (Red Hat Package Manager) packages.   

  * **YUM** stands for **Yellowdog Updater, Modified**.
  * **DNF** stands for **Dandified YUM**.

* **YUM is the default package-management interface on CentOS (Community Enterprise Operating System) and Red Hat Enterprise Linux 7; DNF is the default on Fedora and Red Hat Enterprise Linux 8 and later.**

* **They handle**:

  * **Repository metadata** (information about available packages in software repositories)
  * **GNU Privacy Guard (GPG) keys** (for verifying package authenticity)
  * **Dependency resolution** (automatically determining and installing all required libraries and packages)


#### YUM (CentOS/RHEL 7)

| Action          | Command                  | Description                        |
| --------------- | ------------------------ | ---------------------------------- |
| Install package | `sudo yum install <pkg>` | Install `<pkg>` from enabled repos |
| Update packages | `sudo yum update -y`     | Update all installed packages      |
| Remove package  | `sudo yum remove <pkg>`  | Uninstall `<pkg>`                  |
| Clean cache     | `sudo yum clean all`     | Remove all cached data             |

```bash
# Install Docker:
sudo yum install docker

# Update everything:
sudo yum update -y

# Remove Docker:
sudo yum remove docker

# Clean all yum cache:
sudo yum clean all
```

#### DNF (Fedora, RHEL 8+)

| Action           | Command                  | Description                    |
| ---------------- | ------------------------ | ------------------------------ |
| Install package  | `sudo dnf install <pkg>` | Install `<pkg>`                |
| Upgrade packages | `sudo dnf upgrade -y`    | Upgrade all installed packages |
| Remove package   | `sudo dnf remove <pkg>`  | Uninstall `<pkg>`              |
| Clean cache      | `sudo dnf clean all`     | Remove all cached data         |

```bash
# Install Git:
sudo dnf install git

# Upgrade system:
sudo dnf upgrade -y

# Remove Git:
sudo dnf remove git

# Clean all dnf cache:
sudo dnf clean all
```

</details>

---

<details>
<summary><strong>4. Comparing Package Managers</strong></summary>

| Feature      | APT (`.deb`)        | YUM (`.rpm`)        | DNF (`.rpm`)        |
| ------------ | ------------------- | ------------------- | ------------------- |
| Default On   | Debian, Ubuntu      | CentOS, RHEL 7      | Fedora, RHEL 8+     |
| Install Cmd  | `apt install <pkg>` | `yum install <pkg>` | `dnf install <pkg>` |
| Update Index | `apt update`        | `yum update`        | `dnf check-update`  |
| Upgrade All  | `apt upgrade`       | `yum update`        | `dnf upgrade`       |
| Remove Cmd   | `apt remove <pkg>`  | `yum remove <pkg>`  | `dnf remove <pkg>`  |
| Cleanup      | `apt autoremove`    | `yum clean all`     | `dnf clean all`     |
| Repo Config  | `/etc/apt/`         | `/etc/yum.repos.d/` | `/etc/yum.repos.d/` |

</details>

---

<details>
<summary><strong>5. Quick Command Summary</strong></summary>

### APT

| Action          | Command                  |
| --------------- | ------------------------ |
| Update index    | `sudo apt update`        |
| Install package | `sudo apt install <pkg>` |
| Upgrade all     | `sudo apt upgrade -y`    |
| Remove package  | `sudo apt remove <pkg>`  |
| Purge package   | `sudo apt purge <pkg>`   |
| Cleanup deps    | `sudo apt autoremove`    |
| Clean cache     | `sudo apt clean`         |

---

### YUM

| Action          | Command                  |
| --------------- | ------------------------ |
| Install package | `sudo yum install <pkg>` |
| Update all      | `sudo yum update -y`     |
| Remove package  | `sudo yum remove <pkg>`  |
| Clean cache     | `sudo yum clean all`     |

---

### DNF

| Action          | Command                  |
| --------------- | ------------------------ |
| Install package | `sudo dnf install <pkg>` |
| Upgrade all     | `sudo dnf upgrade -y`    |
| Remove package  | `sudo dnf remove <pkg>`  |
| Clean cache     | `sudo dnf clean all`     |

</details>