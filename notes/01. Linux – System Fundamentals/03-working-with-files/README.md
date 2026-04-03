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

# 🐧 Working with Files & File Content

## Table of Contents
- [1. Create & Inspect Files](#1-create--inspect-files)  
- [2. Copying / Moving / Renaming Files](#2-copying--moving--renaming-files)  
- [3. Deleting Files](#3-deleting-files)  
- [4. Viewing File Contents](#4-viewing-file-contents)  
- [5. Previewing File Sections](#5-previewing-file-sections)  
- [6. Filesystem Types in Linux](#6-filesystem-types-in-linux)  
- [7. Quick Command Summary](#7-quick-command-summary)  
---

<details>
<summary><strong>1. Create & Inspect Files</strong></summary>

## Theory & Notes

- **Creating Files**  
  - `touch <filename>` will create an empty file if it doesn’t exist, or update its timestamps if it does.

- **Identifying File Types**  
  - `file <filename>` examines contents and reports type (text, executable, image, etc.).

- **Inspecting File Metadata**  
  - `stat <filename>` shows detailed metadata: size, permissions, and timestamps.

---

| Command | Description                              | Syntax             | Example           |
| ------- | ---------------------------------------- | ------------------ | ----------------- |
| `touch` | Create file or update timestamps         | `touch <filename>` | `touch file1.txt` |
| `file`  | Identify the type of a file              | `file <filename>`  | `file file1.txt`  |
| `stat`  | Display file metadata (size, timestamps) | `stat <filename>`  | `stat file1.txt`  |

</details>

---

<details>
<summary><strong>2. Copying / Moving / Renaming Files</strong></summary>

## Theory & Notes

- **Copy (`cp`)**  
  - Basic: `cp <source> <destination>` duplicates files or directories.  
  - **Interactive** (`-i`): prompts before overwrite.  
  - **Verbose** (`-v`): prints each copy action, e.g.  
    ```bash
    ‘file1.txt’ -> ‘backup/file1.txt’
    ```  
    Useful for confirmation or logging.  
  - **Recursive** (`-r`): copies directories and all contents.  
  - **Combined** (`-rv` or `-vr`): recursive with live log of every file/subdirectory.

- **Move/Rename (`mv`)**  
  - `mv <source> <dest>` moves or renames while preserving metadata.  
  - Supports `-i` and `-v` as well.
  - Use `mv` instead of `cp` + `rm` to preserve file metadata.

- **Tip**
  - `cp -iv <source> <destination>`
---

| Command  | Description                                | Syntax                          | Example                          |
| -------- | ------------------------------------------ | ------------------------------- | -------------------------------- |
| `cp`     | Copy files or directories                  | `cp <source> <dest>`            | `cp file1.txt file2.txt`         |
| `cp -i`  | Prompt before overwrite                    | `cp -i <src> <dest>`            | `cp -i file1.txt file2.txt`      |
| `cp -v`  | Show each copy action                      | `cp -v <src> <dest>`            | `cp -v file1.txt backup/`        |
| `cp -r`  | Copy directories recursively               | `cp -r <src_dir> <dest_dir>`    | `cp -r src/ backup/`             |
| `cp -rv` | Recursive copy with verbose output         | `cp -rv <src_dir> <dest_dir>`   | `cp -rv src/ backup/`            |
| `mv`     | Move or rename files or directories        | `mv <source> <dest>`            | `mv file2.txt file3.txt`         |

</details>

---

<details>
<summary><strong>3. Deleting Files</strong></summary>

## Theory & Notes

- **Remove (`rm`)**  
  - Basic: `rm <filename>` deletes a file (no trash).  
  - **Interactive** (`-i`): prompt before each deletion.  
  - **Recursive** (`-r`): remove directory trees and contents.  
  - **Force** (`-f`): ignore nonexistent files and suppress prompts.  
  - **Combine** (`-rf`): force-delete a directory tree without confirmation.

---

| Command   | Description                            | Syntax                 | Example           |
| --------- | -------------------------------------- | ---------------------- | ----------------- |
| `rm`      | Remove a file                          | `rm <filename>`        | `rm file3.txt`    |
| `rm -i`   | Prompt before deletion                 | `rm -i <filename>`     | `rm -i file3.txt` |
| `rm -r`   | Remove directories and contents        | `rm -r <directory>`    | `rm -r devops/`   |
| `rm -f`   | Force delete without prompt            | `rm -f <filename>`     | `rm -f file3.txt` |

</details>

---

<details>
<summary><strong>4. Viewing File Contents</strong></summary>

## Theory & Notes

- **Concatenate (`cat`)**  
  - `cat <file>` prints entire file.  
  - `cat -n <file>` numbers all output lines.  
  - `tac <file>` prints in reverse order. (tac does not support -n option) 
  - `nl <file>` numbers lines (alternative style cannot be commbined with cat or tac).

---

| Command  | Description                         | Syntax            | Example            |
| -------- | ----------------------------------- | ----------------- | ------------------ |
| `cat`    | Print file content                  | `cat <file>`      | `cat file1.txt`    |
| `cat -n` | Print content with line numbers     | `cat -n <file>`   | `cat -n file1.txt` |
| `tac`    | Print file content in reverse order | `tac <file>`      | `tac file1.txt`    |
| `nl`     | Number lines                        | `nl <file>`       | `nl file1.txt`     |

</details>

---


<details>
<summary><strong>5. Previewing File Sections</strong></summary>

## Theory & Notes

- **Head/Tail**  
  - `head <file>` By default it shows the first 10 lines.  
  - `head -n N <file>` shows the first **N** lines.  
  - `tail <file>` By default it shows the last 10 lines.  
  - `tail -n N <file>` shows the last **N** lines.

- **Page by page**  
  - `more <file>` paginates forward only.  
  - `less <file>` allows forward/backward navigation (preferred use `q` to exit).

---

| Command    | Description                           | Syntax               | Example               |
| ---------- | ------------------------------------- | -------------------- | --------------------- |
| `head`     | Show first 10 lines                   | `head <file>`        | `head file2.txt`      |
| `head -n`  | Show first N lines                    | `head -n 5 <file>`   | `head -n 5 file2.txt` |
| `tail`     | Show last 10 lines                    | `tail <file>`        | `tail file2.txt`      |
| `tail -n`  | Show last N lines                     | `tail -n 7 <file>`   | `tail -n 7 file2.txt` |
| `more`     | Paginate forward only                 | `more <file>`        | `more long.txt`       |
| `less`     | Paginate with navigation (forward/back)| `less <file>`       | `less journal.txt`    |

</details>

---

<details>
<summary><strong>6. Filesystem Types in Linux</strong></summary>

## Theory & Notes

- **File type indicator** (first character in `ls -l`):  
  - `d` = directory  
  - `-` = regular file  
  - `l` = symbolic link  

Use `ls -l` to view these indicators.

---

| Type      | Description          | Indicator |
| --------- | -------------------- | --------- |
| Directory | A folder             | `d`       |
| File      | Text or binary file  | `-`       |
| Symlink   | Link to another file | `l`       |

</details>

---

<details>
<summary><strong>7. Quick Command Summary</strong></summary>

### Commands Quick Recap

| Command    | Description                                | Syntax                          | Example                          |
| ---------- | ------------------------------------------ | ------------------------------- | -------------------------------- |
| `touch`    | Create file or update timestamps           | `touch <filename>`              | `touch file1.txt`                |
| `file`     | Identify the type of a file                | `file <filename>`               | `file file1.txt`                 |
| `stat`     | Display file metadata (size, timestamps)   | `stat <filename>`               | `stat file1.txt`                 |
| `cp`       | Copy files or directories                  | `cp <source> <dest>`            | `cp file1.txt file2.txt`         |
| `cp -i`    | Prompt before overwrite                    | `cp -i <src> <dest>`            | `cp -i file1.txt file2.txt`      |
| `cp -v`    | Show each copy action                      | `cp -v <src> <dest>`            | `cp -v file1.txt backup/`        |
| `cp -r`    | Copy directories recursively               | `cp -r <src_dir> <dest_dir>`    | `cp -r src/ backup/`             |
| `cp -rv`   | Recursive copy with verbose output         | `cp -rv <src_dir> <dest_dir>`   | `cp -rv src/ backup/`            |
| `mv`       | Move or rename files or directories        | `mv <source> <dest>`            | `mv file2.txt file3.txt`         |
| `rm`       | Remove a file                              | `rm <filename>`                 | `rm file3.txt`                   |
| `rm -i`    | Prompt before deletion                     | `rm -i <filename>`              | `rm -i file3.txt`                |
| `rm -r`    | Remove directories and contents            | `rm -r <directory>`             | `rm -r devops/`                  |
| `rm -f`    | Force delete without prompt                | `rm -f <filename>`              | `rm -f file3.txt`                |
| `cat`      | Print file content                         | `cat <file>`                    | `cat file1.txt`                  |
| `cat -n`   | Print content with line numbers            | `cat -n <file>`                 | `cat -n file1.txt`               |
| `tac`      | Print file content in reverse order        | `tac <file>`                    | `tac file1.txt`                  |
| `nl`       | Number lines                               | `nl <file>`                     | `nl file1.txt`                   |
| `head`     | Show first 10 lines                        | `head <file>`                   | `head file2.txt`                 |
| `head -n`  | Show first N lines                         | `head -n 5 <file>`              | `head -n 5 file2.txt`            |
| `tail`     | Show last 10 lines                         | `tail <file>`                   | `tail file2.txt`                 |
| `tail -n`  | Show last N lines                          | `tail -n 7 <file>`              | `tail -n 7 file2.txt`            |
| `more`     | Paginate forward only                      | `more <file>`                   | `more long.txt`                  |
| `less`     | Paginate with navigation (forward/backward)| `less <file>`                   | `less journal.txt`               |

### Filesystem Types in Linux

| Type      | Description          | Indicator |
| --------- | -------------------- | --------- |
| Directory | A folder             | `d`       |
| File      | Text or binary file  | `-`       |
| Symlink   | Link to another file | `l`       |


→ Ready to practice? [Go to Lab 01](../linux-labs/01-boot-basics-files-lab.md)
