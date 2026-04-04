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

# 🐧 User & Group Management

## Table of Contents
- [1. User Management](#1-user-management)  
- [2. Group Management](#2-group-management)  
- [3. Quick Command Summary](#3-quick-command-summary)  

<details>
<summary><strong>1. User Management</strong></summary>

#### Theory & Notes
- **UID** = Unique User ID  
- **GECOS** = User metadata field (e.g., full name, contact)  
- **Home Directory** = default `/home/<username>`  
- Adding a user with `useradd -m` creates home directory and primary group  
- Passwords & aging stored in `/etc/shadow`; account info in `/etc/passwd`

##### Key Files
| File            | Description                                      | Permissions    |
| --------------- | ------------------------------------------------ | -------------- |
| `/etc/passwd`   | User account info: username, UID, GID, home, shell | world-readable |
| `/etc/shadow`   | Hashed passwords & aging settings                | root-only      |
| `/etc/group`    | Group definitions and member lists               | world-readable |
| `/etc/gshadow`  | Encrypted group passwords & group admins         | root-only      |
| `/etc/sudoers`  | Sudo permissions (edit with `visudo`)            | root-only      |

##### UID Ranges
| Range      | Purpose                             |
| ---------- | ----------------------------------- |
| `0`        | Root (super-user)                   |
| `1–200`    | System accounts & services          |
| `201–999`  | Unprivileged system processes       |
| `1000+`    | Regular user accounts               |

##### Commands, Options & Examples
| Command   | Option         | Description                   | Example                                      |
| --------- | -------------- | ----------------------------- | -------------------------------------------- |
| `useradd` | `-m`           | create home directory         | `sudo useradd -m navya`                     |
|           | `-s <shell>`   | set default shell             | `sudo useradd -s /bin/bash navya`           |
|           | `-u <UID>`     | set user ID                   | `sudo useradd -u 1500 navya`                |
| `usermod` | `-s <shell>`   | change login shell            | `sudo usermod -s /bin/zsh navya`            |
|           | `-u <UID>`     | change user ID                | `sudo usermod -u 2001 navya`                |
|           | `-aG <group>`  | add to supplementary group    | `sudo usermod -aG engineers navya`          |
| `passwd`  | (none)         | set or change password        | `sudo passwd navya`                         |
| `userdel` | `--remove`     | delete user & remove home     | `sudo userdel --remove navya`               |
|           | (none)         | delete user but keep home     | `sudo userdel navya`                        |

##### Syntax & Examples
```bash
# Syntax: add user
sudo useradd <username>
# Example:
sudo useradd navya

# Syntax: set password
sudo passwd <username>
# Example:
sudo passwd navya

# Syntax: list users
cat /etc/passwd

# Syntax: change login name
sudo usermod -l <newname> <oldname>
# Example:
sudo usermod -l atd akhil-teja-doosari

# Syntax: change UID
sudo usermod -u <UID> <username>
# Example:
sudo usermod -u 2000 navya

# Syntax: change shell
sudo usermod -s <shell_path> <username>
# Example:
sudo usermod -s /bin/zsh navya

# Syntax: delete user (keep home)
sudo userdel <username>
# Example:
sudo userdel navya

# Syntax: delete user + home
sudo userdel <username> --remove
# Example:
sudo userdel navya --remove
````

</details>

---

<details>
<summary><strong>2. Group Management</strong></summary>

#### Theory & Notes

* **GID** = Group ID
* **Primary Group** = each user’s default group, same name as user
* **Supplementary Groups** = additional groups for access control
* Group membership listed in `/etc/group`; secure info in `/etc/gshadow`

##### Key Files

| File           | Description                        | Permissions    |
| -------------- | ---------------------------------- | -------------- |
| `/etc/group`   | Group definitions & member lists   | world-readable |
| `/etc/gshadow` | Encrypted group passwords & admins | root-only      |

##### Commands, Options & Examples

| Command    | Option      | Description            | Example                           |
| ---------- | ----------- | ---------------------- | --------------------------------- |
| `groupadd` | `-g <GID>`  | set group ID           | `sudo groupadd -g 3000 devs`      |
| `groupmod` | `-n <new>`  | rename group           | `sudo groupmod -n engineers devs` |
|            | `-g <GID>`  | change group ID        | `sudo groupmod -g 2001 engineers` |
| `gpasswd`  | `-a <user>` | add user to group      | `sudo gpasswd -a navya engineers` |
|            | `-d <user>` | remove user from group | `sudo gpasswd -d navya engineers` |
| `groupdel` | (none)      | delete a group         | `sudo groupdel devs`              |

##### Syntax & Examples

```bash
# Syntax: add group
sudo groupadd <groupname>
# Example:
sudo groupadd devs

# Syntax: add group with specific GID
sudo groupadd -g <GID> <groupname>
# Example:
sudo groupadd -g 3000 devs

# Syntax: rename group
sudo groupmod -n <newname> <oldname>
# Example:
sudo groupmod -n engineers devs

# Syntax: change group GID
sudo groupmod -g <GID> <groupname>
# Example:
sudo groupmod -g 2001 engineers

# Syntax: add user to group
sudo gpasswd -a <user> <group>
# Example:
sudo gpasswd -a navya engineers

# Syntax: remove user from group
sudo gpasswd -d <user> <group>
# Example:
sudo gpasswd -d navya engineers

# Syntax: delete group
sudo groupdel <groupname>
# Example:
sudo groupdel devs
```

</details>

---

<details>
<summary><strong>3. Quick Command Summary</strong></summary>

| Command      | Purpose                                     | Example                              |
| ------------ | ------------------------------------------- | ------------------------------------ |
| `useradd`    | Create user (with `-m` for home directory)  | `sudo useradd -m -s /bin/bash navya` |
| `usermod`    | Modify user account properties              | `sudo usermod -aG engineers navya`   |
| `passwd`     | Set or change user password                 | `sudo passwd navya`                  |
| `userdel`    | Delete user (use `--remove` to delete home) | `sudo userdel --remove navya`        |
| `groupadd`   | Create a new group                          | `sudo groupadd -g 3000 devs`         |
| `groupmod`   | Rename or change GID of a group             | `sudo groupmod -n engineers devs`    |
| `groupdel`   | Delete a group                              | `sudo groupdel devs`                 |
| `gpasswd -a` | Add user to supplementary group             | `sudo gpasswd -a navya engineers`    |
| `gpasswd -d` | Remove user from supplementary group        | `sudo gpasswd -d navya engineers`    |

</details>