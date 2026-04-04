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

# 🐧 `sed` Stream Editor

- [1. sed Overview](#1-sed-overview)  
- [2. Basic Substitutions](#2-basic-substitutions)  
- [3. Targeted Substitutions in a File](#3-targeted-substitutions-in-a-file)  
- [4. Deletions & Printing Ranges](#4-deletions--printing-ranges)  
- [5. Insertion & Appending](#5-insertion--appending)  
- [6. Multiple Commands in One Pass](#6-multiple-commands-in-one-pass)  
- [7. Quick Command Summary](#7-quick-command-summary)

---
<details>
<summary><strong>1. sed Overview</strong></summary>

**Notes:**  
- `s` → substitute  
- `/` → delimiter separating pattern, replacement, and flags  
- `g` → global‐flag (replace all matches on a line)  
- `-n` → suppress automatic printing (used with `p`)  
- `-i` → edit file in-place (make changes directly to the file)  
- `$` → represents the last line in address/range expressions  
- `d` → delete matching lines (when used as `/PATTERN/d` or `$d`)  
- Address specific lines via `N` (e.g. `3`) or ranges `M,N` (e.g. `3,7`)   

- Following file is used in examples    

**employees.txt**

```

Alice, January, 55000
Alice, January, 55000
Bob, February, 75000
Bob, February, 75000
David, March, 60000
Alice, January, 55000
David, March, 60000
Alice, January, 55000
Eve, April, 65000
Alice, January, 55000

```

</details>

---

<details>
<summary><strong>2 Basic Substitutions</strong></summary>

- **TASK:** Turn “Hello World!” to “Hello Linux!”  
  ```bash
  echo "Hello World" | sed 's/World/Linux/'
* `s` → substitute

* `/` → delimiter separating pattern, replacement, and flags

* **If the replacement contains `/`**, choose a non-conflicting delimiter:

  ```bash
  echo "/home/user/docs" | sed 's#/home/user#/mnt/data/backup#g'
  ```

  * Here `#` is the delimiter, so you don’t need to escape `/`

* **Replace only first vs. all occurrences**

  * First occurrence only:

    ```bash
    echo "Hello World World!" | sed 's/World/Linux/'
    ```
  * All occurrences (`g` → global):

    ```bash
    echo "Hello World World!" | sed 's/World/Linux/g'
    ```

</details>

---

<details>
<summary><strong>3. Targeted Substitutions in a File</strong></summary>

* **Delete all lines containing “Alice”**

  ```bash
  sed '/Alice/d' employees.txt
  ```

* **Replace 2nd occurrence of “Alice” on line 2**

  ```bash
  sed '2 s/Alice/Akhil/' employees.txt
  ```

* **Replace on lines 1–2 only**

  ```bash
  sed '1,2 s/Alice/Akhil/' employees.txt
  ```

* **Replace throughout entire file (lines 1–\$)**

  ```bash
  sed '1,$ s/Alice/Akhil/' employees.txt
  ```

* **Print only lines where substitution occurred**

  ```bash
  sed -n '1,$ s/Alice/Akhil/p' employees.txt
  ```

  * `-n` → suppress default printing
  * `p`  → print only substituted lines

</details>

---

<details>
<summary><strong>4. Deletions & Printing Ranges</strong></summary>

* **Print only lines 3–7**

  ```bash
  sed -n '3,7p' employees.txt
  ```

* **Delete any line containing “Eve”**

  ```bash
  sed '/Eve/d' employees.txt
  ```

* **Delete the last line**

  ```bash
  sed '$d' employees.txt
  ```

* **Delete lines 5 through end**

  ```bash
  sed '5,$d' employees.txt
  ```

</details>

---

<details>
<summary><strong>5. Insertion & Appending</strong></summary>

* **Insert before line 10 (no save)**

  ```bash
  sed '10i\Nikhil, August, 95000' employees.txt
  ```

* **Insert before line 10 (in-place)**

  ```bash
  sed -i '10i\Nikhil, August, 95000' employees.txt
  ```

* **Append after the last line**

  ```bash
  sed '$a\Navya, October, 100000' employees.txt
  ```

</details>

---


<details>
<summary><strong>6. Multiple Commands in One Pass</strong></summary>

* **Run two edits at once**

  ```bash
  sed -e 's/Alice/Akhil/' -e 's/February/Feb/' employees.txt
  ```

</details>

---

<details>
<summary><strong>7. Quick Command Summary</strong></summary>

| Syntax                | Description                                     | Example                                                      |
| --------------------- | ----------------------------------------------- | ------------------------------------------------------------ |
| `s/OLD/NEW/`          | Substitute first match on each line             | `sed 's/World/Linux/'`                                       |
| `s/OLD/NEW/g`         | Substitute all matches on each line             | `sed 's/World/Linux/g'`                                      |
| `2 s/OLD/NEW/`        | Substitute only the 2nd occurrence on a line    | `sed '2 s/Alice/Akhil/' employees.txt`                       |
| `1,2 s/OLD/NEW/`      | Substitute on lines 1 through 2                 | `sed '1,2 s/Alice/Akhil/' employees.txt`                     |
| `1,$ s/OLD/NEW/`      | Substitute throughout entire file               | `sed '1,$ s/Alice/Akhil/' employees.txt`                     |
| `-n 's/.../.../p'`    | Print only lines where substitution occurred    | `sed -n '1,$ s/Alice/Akhil/p' employees.txt`                 |
| `/PATTERN/d`          | Delete lines matching a pattern                 | `sed '/Alice/d' employees.txt`                               |
| `-n 'X,Yp'`           | Print only lines X to Y                         | `sed -n '3,7p' employees.txt`                                |
| `$d`                  | Delete the last line of the file                | `sed '$d' employees.txt`                                     |
| `5,$d`                | Delete from line 5 to end                       | `sed '5,$d' employees.txt`                                   |
| `10i\…`               | Insert text before line 10                      | `sed '10i\Nikhil, August, 95000' employees.txt`              |
| `-i '10i\…'`          | Insert before line 10 and save in-place         | `sed -i '10i\Nikhil, August, 95000' employees.txt`           |
| `$a\…`                | Append text after the last line                 | `sed '$a\Navya, October, 100000' employees.txt`              |
| `-e 'cmd1' -e 'cmd2'` | Run multiple editing commands in one invocation | `sed -e 's/Alice/Akhil/' -e 's/February/Feb/' employees.txt` |

</details>