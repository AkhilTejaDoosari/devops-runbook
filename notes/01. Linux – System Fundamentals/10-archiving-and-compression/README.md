[🏠 Home](../README.md) | 
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

# Archiving and Compression

## Table of Contents

- [1. Compression vs Archiving](#1-compression-vs-archiving)
- [2. ZIP – Compress & Archive Multiple Files](#2-zip--compress--archive-multiple-files)
- [3. unzip – Extract ZIP Files](#3-unzip--extract-zip-files)
- [4. zip -r – Archive a Directory](#4-zip--r--archive-a-directory)
- [5. gzip – Compress a Single File](#5-gzip--compress-a-single-file)
- [6. zcat / zmore / zless – View Compressed Content](#6-zcat--zmore--zless--view-compressed-content)
- [7. gunzip – Decompress `.gz` Files](#7-gunzip--decompress-gz-files)
- [8. tar -cvf – Archive Files](#8-tar--cvf--archive-files)
- [9. tar -xzvf – Extract from `.tar.gz`](#9-tar--xzvf--extract-from-targz)
- [10. tar -tvf – View Contents of `.tar.gz`](#10-tar--tvf--view-contents-of-targz)
- [11. tar -czvf – Archive + Compress Files](#11-tar--czvf--archive--compress-files)
- [12. Backup a Directory](#12-backup-a-directory)

---

<details>
<summary><strong>1. Compression vs Archiving</strong></summary>

## Theory

- **Compression** = reduce file size (faster transfer, less storage)
- **Archiving** = combine multiple files into one (no size reduction)

| Tool         | Function                        |
|--------------|----------------------------------|
| `zip`        | Compress + Archive               |
| `gzip`       | Compress only (single file)      |
| `tar`        | Archive only                     |
| `tar + gzip` | Archive + Compress (Linux std)   |

</details>

---

<details>
<summary><strong>2. ZIP – Compress & Archive Multiple Files</strong></summary>

## Theory

`zip` compresses and archives multiple files into a `.zip` file.

---

### Syntax:
```bash
zip [options] <archive_name.zip> <file1> <file2> ...
```

### Example:

```bash
zip logs.zip access.log error.log
```

### Output:

```text
  adding: access.log (deflated 60%)
  adding: error.log (deflated 55%)
```

Result:

```bash
ls -lh
# -rw-r--r-- 1 user group 4.1K Jul 01 18:00 logs.zip
```

</details>

---

<details>
<summary><strong>3. unzip – Extract ZIP Files</strong></summary>

## Theory

The `unzip` command extracts contents from a `.zip` file.

---

### Syntax:

```bash
unzip <archive_name.zip>
```

### Example:

```bash
unzip logs.zip
```

### Output:

```text
Archive:  logs.zip
  inflating: access.log
  inflating: error.log
```

</details>

---

<details>
<summary><strong>4. zip -r – Archive a Directory</strong></summary>

## Theory

`zip -r` archives an entire directory including its subfolders.

---

### Syntax:

```bash
zip -r <archive_name.zip> <directory_path>
```

### Example:

```bash
zip -r webstore-logs.zip /var/log/webstore
```

### Output:

```text
  adding: /var/log/webstore/ (stored 0%)
  adding: /var/log/webstore/access.log (deflated 40%)
  adding: /var/log/webstore/error.log (deflated 42%)
```

</details>

---

<details>
<summary><strong>5. gzip – Compress a Single File</strong></summary>

## Theory

`gzip` compresses one file and replaces it with a `.gz` version.

---

### Syntax:

```bash
gzip [options] <filename>
```

### Example:

```bash
gzip access.log
```

### Output:

```bash
ls -lh
# -rw-r--r-- 1 user group 2.1K Jul 01 18:10 access.log.gz
```

Maximum compression:

```bash
gzip -9 error.log
```

</details>

---

<details>
<summary><strong>6. zcat / zmore / zless – View Compressed Content</strong></summary>

## Theory

These commands let you view compressed `.gz` files without extracting.

---

### Syntax:

```bash
zcat <file.gz>
zmore <file.gz>
zless <file.gz>
```

### Example:

```bash
zcat access.log.gz
```

### Output:

```text
192.168.1.10 GET /api/products 200
192.168.1.14 POST /api/orders 500
...
```

</details>

---

<details>
<summary><strong>7. gunzip – Decompress `.gz` Files</strong></summary>

## Theory

`gunzip` restores the original file by removing the `.gz` compression.

---

### Syntax:

```bash
gunzip <file.gz>
```

### Example:

```bash
gunzip access.log.gz
```

### Output:

```bash
ls -lh
# -rw-r--r-- 1 user group 4.8K Jul 01 18:11 access.log
```

</details>

---

<details>
<summary><strong>8. tar -cvf – Archive Files</strong></summary>

## Theory

`tar -cvf` creates an archive file from multiple files, without compression.

---

### Syntax:

```bash
tar -cvf <archive_name.tar> <file1> <file2> ...
```

### Example:

```bash
tar -cvf webstore-configs.tar nginx.conf webstore.conf
```

### Output:

```text
nginx.conf
webstore.conf
```

```bash
ls -lh
# -rw-r--r-- 1 user group 6.0K Jul 01 18:12 webstore-configs.tar
```

</details>

---

<details>
<summary><strong>9. tar -xzvf – Extract from `.tar.gz`</strong></summary>

## Theory

`tar -xzvf` extracts and decompresses a `.tar.gz` file.

---

### Syntax:

```bash
tar -xzvf <archive.tar.gz>
```

### Example:

```bash
tar -xzvf webstore-configs.tar.gz
```

### Output:

```text
nginx.conf
webstore.conf
```

</details>

---

<details>
<summary><strong>10. tar -tvf – View Contents of `.tar.gz`</strong></summary>

## Theory

Lists the contents of a compressed `.tar.gz` archive without extracting.

---

### Syntax:

```bash
tar -tvf <archive.tar.gz>
```

### Example:

```bash
tar -tvf webstore-configs.tar.gz
```

### Output:

```text
-rw-r--r-- user/group  2096 2025-07-01 17:59 nginx.conf
-rw-r--r-- user/group  1800 2025-07-01 17:59 webstore.conf
```

</details>

---

<details>
<summary><strong>11. tar -czvf – Archive + Compress Files</strong></summary>

## Theory

Combines archiving + compression. Produces a `.tar.gz` file from files/folders.

---

### Syntax:

```bash
tar -czvf <archive.tar.gz> <file1> <file2> ...
```

### Example:

```bash
tar -czvf webstore-configs.tar.gz nginx.conf webstore.conf
```

### Output:

```text
nginx.conf
webstore.conf
```

```bash
ls -lh
# -rw-r--r-- 1 user group 3.5K Jul 01 18:15 webstore-configs.tar.gz
```

</details>

---

<details>
<summary><strong>12. Backup a Directory</strong></summary>

## Theory

`tar -czvf` can compress and archive full directories (with subfolders and metadata).

---

### Syntax:

```bash
tar -czvf <backup_name.tar.gz> <directory_path>
```

### Example:

```bash
tar -czvf webstore-backup.tar.gz /var/log/webstore
```

### Output:

```text
/var/log/webstore/
/var/log/webstore/access.log
/var/log/webstore/error.log
```

To extract:

```bash
tar -xzvf webstore-backup.tar.gz
```

</details>

→ Ready to practice? [Go to Lab 04](../linux-labs/04-archive-packages-services-lab.md)
