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

# 🐧 File Ownership & Permissions

## Table of Contents
- [1. Permission Triads & Numeric Permissions](#1-permission-triads--numeric-permissions)
- [2. Permission Syntax & Examples](#2-permission-syntax--examples)
- [3. Interpreting `ls -l`](#3-interpreting-ls--l)
- [4. Changing Ownership](#4-changing-ownership)
- [5. Special Permissions](#5-special-permissions)
- [6. Access Control Lists (ACLs)](#6-access-control-lists-acls)
- [7. umask (Default Permissions)](#7-umask-default-permissions)
- [8. Links & Inodes](#8-links--inodes)
- [9. Quick Command Summary](#9-quick-command-summary)

---

<details>
<summary><strong>1. Permission Triads & Numeric Permissions</strong></summary>

***Theory & Notes***

- **Ownership**: each file or directory has an **owner** (user) and a **group**  
- **Permissions** = three triads for user (`u`), group(`g`), other (`o`):
```
 USER    GROUP    OTHERS
 r w x   r w x   r w x
```
- **Values**: `read (r)` = 4, `write (w)` = 2, `execute (x)` = 1  
- **Numeric permissions** map bits to values:

| Octal | Symbolic | Calculation      | Meaning               |
|:-----:|:--------:|------------------|-----------------------|
| 0     | ---      | 0                | none                  |
| 1     | --x      | 2⁰ = 1           | execute only          |
| 2     | -w-      | 2¹ = 2           | write only            |
| 3     | -wx      | 2¹+2⁰ = 3        | write+execute         |
| 4     | r--      | 2² = 4           | read only             |
| 5     | r-x      | 2²+2⁰ = 5        | read+execute          |
| 6     | rw-      | 2²+2¹ = 6        | read+write            |
| 7     | rwx      | 2²+2¹+2⁰ = 7     | read+write+execute    |

```bash
chmod 400 employees.txt    # r--------
chmod 666 samplelog.txt    # rw-rw-rw-
chmod 444 samplelog.txt    # r--r--r--
chmod 777 pets.txt         # rwxrwxrwx
```

</details>

---

<details>
<summary><strong>2. Permission Syntax & Examples</strong></summary>

***Theory & Notes***

* **Symbolic Mode**: modify with user (`u`), group(`g`), other (`o`) all (`a`) plus `+`/`-`/`=`
* **Octal Mode**: three digits (0–7) for `u`/`g`/`o`

---

| Operation                  | Symbolic                  | Octal                     | Description               |
| -------------------------- | ------------------------- | ------------------------- | ------------------------- |
| Grant execute to owner     | `chmod u+x pets.txt`      | `chmod 744 pets.txt`      | add execute bit for owner |
| Grant write to group       | `chmod g+w sample.log`    | `chmod 664 sample.log`    | add write bit for group   |
| Remove execute from others | `chmod o-x employees.txt` | `chmod 750 employees.txt` | remove execute for others |
| Set owner-only read        | `chmod u=r file`          | `chmod 400 file`          | owner=read only           |
| Full access to all         | `chmod a=rwx file`        | `chmod 777 file`          | all = rwx                 |

</details>

---

<details>
<summary><strong>3. Interpreting `ls -l`</strong></summary>

**Theory & Notes**
`ls -l` breaks down into:

1. **Type + permissions** (e.g. `-rwxr-xr--`)
2. **Link count** (# of hard links)
3. **Owner & group**
4. **Size** (`-h` for human‐readable)
5. **Timestamp** (modification date/time)
6. **Filename**

```bash
ls -lh /home/navya/shared
# -rw-r--r-- 1 navya devs 1.2K Jul 05 15:52 pets.txt
```

</details>

---

<details>
<summary><strong>4. Changing Ownership</strong></summary>

**Theory & Notes**

* `chown user:group file` → sets both owner & group
* `chown user file` → changes only owner
* `chgrp group file` → changes only group
* Requires `sudo` if you’re not owner or root

```bash
sudo chown bob:devs report.pdf
sudo chown carol report.pdf
sudo chgrp devs report.pdf
```

</details>

---

<details>
<summary><strong>5. Special Permissions</strong></summary>

**Theory & Notes**
Linux adds three special bits atop the standard rwx:

* **SUID (Set-UID)**

  * Symbolic: `u+s`  | Numeric: prefix `4xxx`
  * On **executables**: runs with **file owner's** privileges (e.g. `passwd` runs as root).

* **SGID (Set-GID)**

  * Symbolic: `g+s`  | Numeric: prefix `2xxx`
  * On **executables**: runs with **file's group** privileges.
  * On **directories**: new items inherit the **directory’s group**.

* **Sticky bit**

  * Symbolic: `o+t`  | Numeric: prefix `1xxx`
  * Applies **only to directories**: only the **file owner**, **dir owner**, or **root** can delete/rename inside.
  * Display as **`t`** (if others have execute) or **`T`** (if execute is off).

---

```bash
# Add sticky bit
sudo chmod +t /shared
ls -ld /shared   # drwxrwxrwt  -> 't' at end

# Toggle execute for others to see 'T'
sudo chmod o-x /shared
ls -ld /shared   # drwxrwxr-wT -> 'T'
```

```bash
# Test deletion behavior
touch /shared/bobs.txt
rm /shared/bobs.txt   # fails if not owner
sudo chown bob /shared/bobs.txt
rm /shared/bobs.txt   # now succeeds
```

| Bit    | Numeric | Effect                                                 |
| ------ | ------- | ------------------------------------------------------ |
| SUID   | 4xxx    | exec runs as file owner                                |
| SGID   | 2xxx    | dir: new items inherit dir’s group; exec runs as group |
| Sticky | 1xxx    | dir: only owner/root can delete/rename inside          |

</details>

---

<details>
<summary><strong>6. Access Control Lists (ACLs)</strong></summary>

**Theory & Notes**  
ACLs let you grant/revoke for **multiple** users/groups:

- `user:alice:rw-` → Alice gets rw  
- `group:devs:r-x` → Devs group gets rx  
- `mask:rwx` → max effective rights  

Default ACLs apply to new items in a directory.

---

```bash
sudo apt install acl
getfacl /data/shared
setfacl -m u:bob:rwX /data/shared
setfacl -x u:alice /data/shared
setfacl -d -m g:devs:rwx /data/shared
```

</details>

---

<details>
<summary><strong>7. umask (Default Permissions)</strong></summary>

**Theory & Notes**

* Defaults: files `0666`, dirs `0777`
* `umask 022` → files `644`, dirs `755`
* `umask 077` → files `600`, dirs `700`
* Persist via `~/.bashrc`

---

```bash
umask
umask 027
echo 'umask 027' >> ~/.bashrc
source ~/.bashrc
```

</details>

---

<details>
<summary><strong>8. Links & Inodes</strong></summary>

**Theory & Notes**

* **Inode**: metadata store (perms, owner, timestamps)
* **Hard link**: same inode (no cross-fs)
* **Symlink**: points to path (cross-fs; breaks if target removed)

---

```bash
ls -li file.txt
ln file.txt hardlink.txt
ln -s file.txt symlink.txt
```

| Feature          | Hard Link  | Symlink   |
| ---------------- | ---------- | --------- |
| Points to        | same inode | file path |
| Cross-filesystem | no         | yes       |
| Broken if target | no         | yes       |

</details>

---

<details>
<summary><strong>9. Quick Command Summary</strong></summary>

| Category            | Task                       | Command                             |
|---------------------|----------------------------|-------------------------------------|
| **Listing**         | List files (long & human)  | `ls -lh`                            |
|                     | Show inode numbers         | `ls -li`                            |
| **Mode Changes**    | Add user exec              | `chmod u+x file`                    |
|                     | Revoke others exec         | `chmod o-x file`                    |
|                     | Set exact octal mode       | `chmod 750 file`                    |
| **Ownership**       | Change owner & group       | `sudo chown user:group file`        |
|                     | Change owner only          | `sudo chown user file`              |
|                     | Change group only          | `sudo chgrp group file`             |
| **ACL Management**  | View ACLs                  | `getfacl path`                      |
|                     | Add user ACL               | `setfacl -m u:user:rwX path`        |
|                     | Remove user ACL            | `setfacl -x u:user path`            |
|                     | Set default ACL            | `setfacl -d -m g:group:rwx dir`     |
| **umask**           | View mask                  | `umask`                             |
|                     | Set temporary mask         | `umask 027`                         |
|                     | Persist mask               | `echo 'umask 027' >> ~/.bashrc`     |
| **Links & Inodes**  | Create hard link           | `ln source target`                  |
|                     | Create symlink             | `ln -s source target`               |

</details>

→ Ready to practice? [Go to Lab 03](../linux-labs/03-vim-users-permissions-lab.md)
