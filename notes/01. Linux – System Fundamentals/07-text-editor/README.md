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

# 🐧 Text Editor

## Table of Contents
- [1. Understanding vi/vim](#1-understanding-vivim)
- [2. Widely Used Workflows](#2-widely-used-workflows)
- [3. File Manipulation Shortcuts](#3-file-manipulation-shortcuts)
- [4. Quick Command Summary](#4-quick-command-summary)

<details>
<summary><strong>1. Understanding vi/vim</strong></summary>

### Editor Overview
- **vi** = original UNIX editor (always available)
- **vim** = “vi IMproved” (extra features, backward compatible)
- **Modal Editing:** separate modes for navigation vs insertion

#### Core Modes
| Mode               | Activation            | Purpose                         |
| ------------------ | --------------------- | ------------------------------- |
| Normal (Command)   | default               | navigate, delete, yank, etc.    |
| Insert             | `i`, `a`, `o`         | insert text                     |
| Command-line       | `:`                   | save, quit, search & replace    |

#### Navigation Keys
| Keys | Action                    |
| ---- | ------------------------- |
| `h`  | move left                 |
| `j`  | move down                 |
| `k`  | move up                   |
| `l`  | move right                |
| `w`  | jump to next word         |
| `b`  | jump to previous word     |
| `0`  | go to beginning of line   |
| `$`  | go to end of line         |
> Repeat count: prepend a number (e.g., 5j moves down 5 lines)
#### Editing Commands
| Command  | Description                        |
| -------- | ---------------------------------- |
| `x`      | delete character under cursor      |
| `dd`     | delete (cut) current line          |
| `cw`     | change word (enters insert mode)   |
| `u`      | undo last change                   |
| `Ctrl+R` | redo                               |

### Save & Exit
- :w → save   
- :q → quit (fails if unsaved changes)   
- :wq or :x → save + quit (:x skips if no edits)   
- :q! → quit without saving   

### Searching & Replacing   
| Command           | Description                                           |   
|-------------------|-------------------------------------------------------|   
| `/pattern`        | Search forward for pattern                            |   
| `?pattern`        | Search backward for pattern                           |   
| `n` / `N`         | Repeat search forward / backward                      |   
| `:%s/old/new/g`   | Replace all occurrences of old with new in file       |   
| `:%s/old/new/gc`  | Replace with confirmation for each change             |   

</details>

---

<details>
<summary><strong>2. Widely Used Workflows</strong></summary>

- **Quick Edit & Save:**  
  ```bash
  vim file.txt      # open file
  20G                # jump to line 20
  iYour text<Esc>    # insert text and exit insert mode
  :wq                # save and quit


* **Global Replace:**

  ```vim
  vim file.txt
  :%s/is/will be/gc     # replace all 'is' → 'will be' with confirmation
  ```

* **Copy & Paste Between Files:**

  ```bash
  vim file1.txt
  y10y               # yank 10 lines
  :e file2.txt       # open target file
  p                  # paste
  :w                 # save
  ```

* **Undo & Redo:**

  ```vim
  u                  # undo
  Ctrl+R             # redo
  ```

</details>

---

<details>
<summary><strong>3. File Manipulation Shortcuts</strong></summary>

```bash
# Append a line to file
echo "New line" >> notes.txt
tail -n1 notes.txt
```

```bash
# Append multiple lines via here-doc
cat <<EOF >> pets.txt
Akhil Teja, Cat, Persian
Navya, Cat, British Shorthair
EOF
```

```bash
# Insert header row with sed
sed -i '1i Name,Category,Value' data.csv
head -n3 data.csv
```

</details>

---

<details>
<summary><strong>4. Quick Command Summary</strong></summary>

| Command          | Syntax           | Example            | Description                                   |
| ---------------- | ---------------- | ------------------ | --------------------------------------------- |
| `h`              | `h`              | `h`                | Move cursor left                              |
| `j`              | `j`              | `j`                | Move cursor down                              |
| `k`              | `k`              | `k`                | Move cursor up                                |
| `l`              | `l`              | `l`                | Move cursor right                             |
| `w`              | `w`              | `w`                | Jump to next word                             |
| `b`              | `b`              | `b`                | Jump to previous word                         |
| `0`              | `0`              | `0`                | Go to beginning of line                       |
| `$`              | `$`              | `$`                | Go to end of line                             |
| `i`              | `i`              | `iNew text<Esc>`   | Enter Insert mode before cursor               |
| `a`              | `a`              | `aMore text<Esc>`  | Enter Insert mode after cursor                |
| `o`              | `o`              | `oLine below<Esc>` | Open new line below and enter Insert          |
| `x`              | `x`              | `x`                | Delete character under cursor                 |
| `dd`             | `dd`             | `dd`               | Delete (cut) current line                     |
| `yy`             | `yy`             | `yy`               | Yank (copy) current line                      |
| `p`              | `p`              | `p`                | Put (paste) after cursor or below line        |
| `u`              | `u`              | `u`                | Undo last change                              |
| `Ctrl+R`         | `Ctrl+R`         | *press*            | Redo change                                   |
| `:w`             | `:w`             | `:w`               | Write (save) file                             |
| `:q`             | `:q`             | `:q`               | Quit editor (fails if unsaved changes)        |
| `:wq` / `:x`     | `:wq` / `:x`     | `:wq`              | Write file and quit                           |
| `:%s/old/new/g`  | `:%s/old/new/g`  | `:%s/is/are/g`     | Replace all occurrences                       |
| `:%s/old/new/gc` | `:%s/old/new/gc` | `:%s/is/are/gc`    | Replace with confirmation for each occurrence |

</details>