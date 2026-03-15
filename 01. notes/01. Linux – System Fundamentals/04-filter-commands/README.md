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

# Filter Commands

## Table of Contents
- [1. Find](#1-find)
- [2. Locate](#2-locate)
- [3. Pattern Searching with grep](#3-pattern-searching-with-grep)
- [4. Most-Used grep Flags](#4-most-used-grep-flags)  
- [5. Comparing & Counting](#5-comparing--counting)  
- [6. Piping & Filtering](#6-piping--filtering)   
- [7. Quick Command Summary](#7-quick-command-summary)   

---

<details>
<summary><strong>1. Find</strong></summary>

**Theory & Notes**

- **What it does**  
  Walks the filesystem tree in real time, filtering by name, type, size, time, ownership, permissions—and can even run commands on each match.  
- **Why use it**  
  When you need the absolute latest results or complex queries (e.g. “all `.log` files older than 7 days in my backup folder”).  
- **Trade-off**  
  Slower on very large trees, but infinitely flexible.

---

| Option               | Description                                      | Syntax                                          | Example                                                       |
| -------------------- | ------------------------------------------------ | ----------------------------------------------- | ------------------------------------------------------------- |
| `-name <pattern>`    | Match filename using shell wildcards (`*`)       | `find <path> -name "*.txt"`                    | `find . -name "*.log"`                                        |
| `-type f`            | Filter for **regular files**                     | `find <path> -type f`                          | `find ~/akhil/linux/backup -type f`                           |
| `-type d`            | Filter for **directories**                       | `find <path> -type d`                          | `find ~/akhil/linux/backup -type d`                           |
| `-mtime N`           | Modified **exactly** N days ago                  | `find <path> -mtime 1`                         | `find ~/akhil/linux/backup -mtime 1`                          |
| `-mtime +N`          | Modified **more than** N days ago                | `find <path> -mtime +7`                        | `find ~/akhil/linux/backup -mtime +30`                        |
| `-mtime -N`          | Modified **less than** N days ago                | `find <path> -mtime -2`                        | `find ~/akhil/linux/backup -mtime -7`                         |
| `-size Nc`           | Size **exactly** N bytes                         | `find <path> -size 441c`                       | `find ~/akhil/linux/backup -size 269c`                        |
| `-size +Nk`          | Size **greater than** N KiB                      | `find <path> -size +1k`                        | `find ~/akhil/linux/backup -size +1k`                         |
| `-size -Nc`          | Size **less than** N bytes                       | `find <path> -size -500c`                      | `find ~/akhil/linux/backup -size -500c`                       |
| `-exec … {} \;`      | Execute a command on each match                  | `find <path> -name "*.tmp" -exec rm {} \;`     | `find ~/akhil/linux/backup -type f -name "*.tmp" -exec rm {} \;` |
</details>

---

<details>
<summary><strong>2. Locate</strong></summary>

**Theory & Notes**

- **What it does**  
  Instantly searches a prebuilt database (`mlocate.db`) of all filenames on disk.  
- **Why use it**  
  For lightning-fast lookups by name when you don’t need the absolute newest filesystem changes.  
- **Trade-off**  
  Results are only as fresh as the last `updatedb` run (often daily).

---

| Option                      | Description                                    | Syntax                             | Example                                              |
| --------------------------- | ---------------------------------------------- | ---------------------------------- | ---------------------------------------------------- |
| `<pattern>`                 | Substring or glob match on full path           | `locate report.pdf`                | `locate pets.txt`                                    |
| `-i`, `--ignore-case`       | Case-insensitive matching                      | `locate -i SAMPLELOG.TXT`          |                                                      |
| `-l N`, `--limit=N`         | Show only the first N results                  | `locate -l 5 pets.txt`             |                                                      |
| `-c`, `--count`             | Print the number of matches only               | `locate -c "/akhil/linux/backup/.*\.txt"` |                                               |


---

## Comparison

| Aspect           | find                                               | locate                                     |
| ---------------- | -------------------------------------------------- | ------------------------------------------ |
| **Speed**        | Slower (walks directory structure)                 | Instant (database lookup)                  |
| **Freshness**    | Always current                                     | Depends on last `updatedb`                 |
| **Flexibility**  | Match by name, type, size, time, ownership, etc.   | Match by path/name only                    |
| **Actions**      | Can run commands on each result (`-exec`)          | Returns list only                          |
| **Use case**     | Complex, precise searches                          | Quick “where is…” queries                  |

---

## Real-World Examples (using `~/akhil/linux/backup`)

Your backup folder lives at `/home/atd/akhil/linux/backup`, referenced as `~/akhil/linux/backup`.

1. **Find small files (< 500 B):**  
   ```bash
   find ~/akhil/linux/backup -type f -size -500c


Matches: `fruits.txt`, `movies.txt`, `students.txt`

2. **Find medium files (500 B – 2 KiB):**

   ```bash
   find ~/akhil/linux/backup -type f -size +500c -size -2k
   ```

   Matches: `samplelog.txt`

3. **Find large files (> 1 KiB):**

   ```bash
   find ~/akhil/linux/backup -type f -size +1k
   ```

   Matches: `pets.txt`, `samplelog.txt`

4. **Delete all `.tmp` files:**

   ```bash
   find ~/akhil/linux/backup -type f -name "*.tmp" -exec rm {} \;
   ```

5. **Locate any `pets.txt` instantly:**

   ```bash
   sudo updatedb
   locate -i pets.txt
   ```

   Returns: `/home/atd/akhil/linux/backup/pets.txt`

6. **Count backup `.txt` files with locate:**

   ```bash
   sudo updatedb
   locate -c "/akhil/linux/backup/.*\.txt"
   ```

   Returns: `5`

</details>

---

<details>
<summary><strong>3. Pattern Searching with grep</strong></summary>

**Theory & Notes**

- **Command structure**  
  `grep [OPTIONS] <pattern> <file(s)>`  
- **Pattern**  
  A regular expression (or literal string) that `grep` will search for.  
- **Files**  
  One or more filenames, wildcards, or directories (with `-r`).  
- **Output**  
  By default, prints matching lines; options adjust colorization, context, counts, etc.

---


grep [OPTIONS] <pattern> <file(s)>


| Action                       | Command & Description                                               |
| ---------------------------- | ------------------------------------------------------------------- |
| Basic, case-sensitive search | `grep 'cat' pets.txt` – finds “cat” exactly as typed                |
| Ignore case-sensitive search | `grep -i 'dog' pets.txt` – matches “Dog”, “DOG”, etc.               |
| Show line numbers            | `grep -n 'rabbit' pets.txt` – prefixes lines with their line number |
| Invert match                 | `grep -v 'snake' pets.txt` – shows lines **without** “snake”        |
| Search in all files of cwd   | `grep -i 'dog' *` – searches every file in current directory        |

</details>

---

<details>
<summary><strong>4. Most-Used grep Flags</strong></summary>

**Theory & Notes**

* Flags modify how `grep` interprets input and outputs results.
* Common flags often combined for powerful searches.

---

| Flag / Pattern     | Description                             | Syntax                     | Example Usage               |
| ------------------ | --------------------------------------- | -------------------------- | --------------------------- |
| **`-i`**           | Case-insensitive search                 | `grep -i <pattern> <file>` | `grep -i "cat" pets.txt`    |
| **`-w`**           | Match whole words only                  | `grep -w <pattern> <file>` | `grep -w "dog" pets.txt`    |
| **`-n`**           | Prefix matches with line numbers        | `grep -n <pattern> <file>` | `grep -n "rabbit" pets.txt` |
| **`-c`**           | Count matching lines                    | `grep -c <pattern> <file>` | `grep -c "snake" pets.txt`  |
| **`-v`**           | Invert match (show non-matching lines)  | `grep -v <pattern> <file>` | `grep -v "cat" pets.txt`    |
| **Search all**     | All files in current directory          | `grep <pattern> ./*`       | `grep -i "dog" *`           |
| **Search `*.txt`** | All `.txt` files in current directory   | `grep <pattern> *.txt`     | `grep -i "cat" *.txt`       |
| **`-r`**           | Recursive search through subdirectories | `grep -r "<pattern>" .`    | `grep -r "rabbit" .`        |

</details>

---

<details>
<summary><strong>5. Comparing & Counting</strong></summary>

**Theory & Notes**

* **`wc` (“word count”)** reports counts for lines, words, and bytes.
* By default, `wc <file>` prints all three counts.
* Combine flags to focus on one metric.

---

| Task                  | Command          |
| --------------------- | ---------------- |
| Line/word/char count  | `wc pets.txt`    |
| Count only lines      | `wc -l pets.txt` |
| Count only words      | `wc -w pets.txt` |
| Count only characters | `wc -c pets.txt` |

</details>

---

<details>
<summary><strong>6. Piping & Filtering</strong></summary>

**Theory & Notes**

- **Pipe (`|`)**  
  Connects the stdout of one command directly into the stdin of the next. Enables building complex, modular one-liners without temporary files.

- **cut**  
  Extracts specific fields (columns) from structured text files. It's fast and ideal for quick slicing of log files, CSVs, or tabular data.  
  Use `-d` to define the delimiter (like a comma), and `-f` to pick field positions.

- **sort**  
  Organizes lines of text from input or a file in ascending or descending order, based on specific criteria. By default follows ASCII ordering; use `-f` to ignore case, `-r` to reverse, `-n` for numeric sort, `-M` for month-name sort, and `-k`/`-t` to sort by a specific field.

- **uniq**  
  Removes consecutive duplicate lines from sorted input, leaving only unique ones for clarity. With `-c` prefixes each line with its occurrence count; `-d` shows one instance of each duplicate; `-D` prints all duplicate lines.

- **column**  
  Arranges input into neatly aligned columns, making data more readable. With `-t` auto-determines column widths; `-s` lets you specify a custom delimiter.

- **tr**  
  Translates or deletes characters in the input stream—useful for quick text substitutions. Specify two sets: characters in the first set are replaced by corresponding ones in the second; use `-d` to delete characters.

- **tee**  
  Reads from stdin and writes to both stdout and one or more files. Use `-a` to append rather than overwrite. Ideal for logging or capturing intermediate pipeline output.


Here are the files used in the following examples:

# Fruits.txt
Mango, Summer, 1.99   
Apple, Autumn, 1.49   
Kiwi, Winter, 2.50   
Strawberry, Spring, 2.99   
Banana, Year-round, 0.59   
Cherry, Summer, 3.99   
Pear, Autumn, 1.29   
Grapes, Autumn, 2.25   
Pineapple, Year-round, 1.75   
Blueberry, Summer, 4.50   
Watermelon, Summer, 0.39   
Peach, Summer, 1.89   
Lemon, Winter, 0.79   
Plum, Autumn, 1.99   
Apricot, Spring, 3.25   
Orange, Winter, 0.89   
Raspberry, Summer, 5.00   
Papaya, Year-round, 1.59   
Fig, Autumn, 2.75   
Blackberry, Summer, 4.75   


# employees.txt
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

# pets.txt
Zion Johnson, DOG, BEAGLE  
Quinn Phillips, Parrot, African Grey  
Payton Young, Dog, Labrador  
Taylor Brown, Snake, Corn  
Marley Gonzales, Cat, Siamese  
Chandler Lewis, DOG, Bulldog  
Remy Collins, Rabbit, Dutch  
Addison Stewart, cat, Persian  
Jamie Mitchell, Dog, Golden Retriever  
Bailey Wright, Goldfish, Comet  
Kennedy Hall, Cat, Bengal  
Sawyer Evans, dog, Poodle  
Reese Turner, GUINEA PIG, Abyssinian  
Harper Allen, Lizard, Bearded Dragon  
Alex Johnson, dog, Beagle  

### `|` (Pipe)

| Option | Description                     | Syntax               | Example                        |
|--------|---------------------------------|----------------------|--------------------------------|
| N/A    | Connect stdout of one command to stdin of the next | `<cmd1> \| <cmd2>`   | `cat Fruits.txt \| grep Summer`  |

---

### `cut`

| Option         | Description                             | Syntax                       | Example                            |
|----------------|-----------------------------------------|------------------------------|------------------------------------|
| `-d <delim>`   | Set delimiter (default is TAB)          | `cut -d',' -f1 file.txt`     | `cut -d',' -f1 Fruits.txt`         |
| `-f <fields>`  | Choose specific fields (columns)        | `cut -d',' -f1,3 file.txt`   | `cut -d',' -f1,3 Fruits.txt`       |

> `cut` is a fast and simple way to extract columns from structured text like CSV, TSV, logs, or `/etc/passwd` files.

---

### `sort`

| Option           | Description                                                      | Syntax                       | Example                                    |
|------------------|------------------------------------------------------------------|------------------------------|--------------------------------------------|
| `-t <delim>`     | Use `<delim>` as the field separator instead of whitespace       | `sort -t':' -k3 file.log`    | `sort -t',' -k3 Fruits.txt`                |
| `-k start[,end]` | Sort by a specific field (start to end positions)                | `sort -t',' -k2,2 file`      | `sort -t',' -k2,2 Fruits.txt`              |
| `-n`             | Interpret and sort by numeric value                              | `sort -n [file]`             | `sort -t',' -k3 -n Fruits.txt`             |
| `-M`             | Compare by month name                                            | `sort -M [file]`             | `sort -M Fruits.txt`                       |
| `-r`             | Reverse the sort order                                           | `sort -r [file]`             | `sort -r employees.txt`                    |
| `-f`             | Fold lower-case to upper-case (ignore case)                      | `sort -f [file]`             | `sort -f employees.txt`                    |


---

### `uniq`

| Option | Description                                                  | Syntax               | Example                                     |
|--------|--------------------------------------------------------------|----------------------|---------------------------------------------|
| `-c`   | Prefix each line with the count of occurrences               | `uniq -c [file]`     | `sort employees.txt \| uniq -c`             |
| `-d`   | Only print one instance of each group of duplicate lines     | `uniq -d [file]`     | `sort employees.txt \| uniq -d`             |
| `-D`   | Print all duplicate lines (every repeated occurrence)        | `uniq -D [file]`     | `sort employees.txt \| uniq -D`             |
| `-u`   | Only print lines that are not repeated (unique only)         | `uniq -u [file]`     | `sort employees.txt \| uniq -u`             |

---

### `column`

| Option              | Description                                      | Syntax                               | Example                                            |
|---------------------|--------------------------------------------------|--------------------------------------|----------------------------------------------------|
| `-t`                | Determine column widths and create a table       | `column -t [file]`                   | `cat Fruits.txt \| column -t -s ','`               |
| `-s <delim>`        | Specify input delimiter                          | `column -s ',' -t [file]`            | `column -s ',' -t employees.txt`                   |
| `-n`                | Do not reflow long lines                         | `column -n [file]`                   | `column -n Fruits.txt`                             |
| `-R <rowsep>`       | Specify output row separator between rows        | `column -t -R ' | ' [file]`          | `column -t -s ',' -R ' | ' Fruits.txt`             |
| `-c <columns>`      | Assume fixed output width of `<columns>` chars   | `column -c 80 [file]`                | `column -c 50 Fruits.txt`                          |

---

### `tee`

| Option | Description                                       | Syntax                  | Example                                       |
|--------|---------------------------------------------------|-------------------------|-----------------------------------------------|
| `-a`   | Append to the given file instead of overwriting   | `… \| tee -a file.log`  | `grep ERROR sample_log.txt \| tee -a errors.log` |
| `-i`   | Ignore SIGINT (Ctrl-C) while writing to files     | `… \| tee -i file.txt`  | `cat Fruits.txt \| tee -i fruits_backup.txt`     |

</details>

---

<details>
<summary><strong>7. Quick Command Summary</strong></summary>

### 1. Find

| Option               | Description                                      | Syntax                                          | Example                                                       |
| -------------------- | ------------------------------------------------ | ----------------------------------------------- | ------------------------------------------------------------- |
| `-name <pattern>`    | Match filename using shell wildcards (`*`)       | `find <path> -name "*.txt"`                    | `find . -name "*.log"`                                        |
| `-type f`            | Filter for **regular files**                     | `find <path> -type f`                          | `find ~/akhil/linux/backup -type f`                           |
| `-type d`            | Filter for **directories**                       | `find <path> -type d`                          | `find ~/akhil/linux/backup -type d`                           |
| `-mtime N`           | Modified **exactly** N days ago                  | `find <path> -mtime 1`                         | `find ~/akhil/linux/backup -mtime 1`                          |
| `-mtime +N`          | Modified **more than** N days ago                | `find <path> -mtime +7`                        | `find ~/akhil/linux/backup -mtime +30`                        |
| `-mtime -N`          | Modified **less than** N days ago                | `find <path> -mtime -2`                        | `find ~/akhil/linux/backup -mtime -7`                         |
| `-size Nc`           | Size **exactly** N bytes                         | `find <path> -size 441c`                       | `find ~/akhil/linux/backup -size 269c`                        |
| `-size +Nk`          | Size **greater than** N KiB                      | `find <path> -size +1k`                        | `find ~/akhil/linux/backup -size +1k`                         |
| `-size -Nc`          | Size **less than** N bytes                       | `find <path> -size -500c`                      | `find ~/akhil/linux/backup -size -500c`                       |
| `-exec … {} \;`      | Execute a command on each match                  | `find <path> -name "*.tmp" -exec rm {} \;`     | `find ~/akhil/linux/backup -type f -name "*.tmp" -exec rm {} \;` |

---

### 2. Locate

| Option                      | Description                                    | Syntax                             | Example                                              |
| --------------------------- | ---------------------------------------------- | ---------------------------------- | ---------------------------------------------------- |
| `<pattern>`                 | Substring or glob match on full path           | `locate report.pdf`                | `locate pets.txt`                                    |
| `-i, --ignore-case`         | Case-insensitive matching                      | `locate -i SAMPLELOG.TXT`          |                                                      |
| `-l N, --limit=N`           | Show only the first N results                  | `locate -l 5 pets.txt`             |                                                      |
| `-c, --count`               | Print the number of matches only               | `locate -c "/akhil/linux/backup/.*\.txt"` |                                               |

---

### Comparison: find vs. locate

| Aspect           | find                                               | locate                                     |
| ---------------- | -------------------------------------------------- | ------------------------------------------ |
| **Speed**        | Slower (walks directory structure)                 | Instant (database lookup)                  |
| **Freshness**    | Always current                                     | Depends on last `updatedb`                 |
| **Flexibility**  | Match by name, type, size, time, ownership, etc.   | Match by path/name only                    |
| **Actions**      | Can run commands on each result (`-exec`)          | Returns list only                          |
| **Use case**     | Complex, precise searches                          | Quick “where is…” queries                  |

---

### 3. Pattern Searching with grep

| Action                       | Command & Description                                               |
| ---------------------------- | ------------------------------------------------------------------- |
| Basic, case-sensitive search | `grep 'cat' pets.txt` – finds “cat” exactly as typed                |
| Ignore case-sensitive search | `grep -i 'dog' pets.txt` – matches “Dog”, “DOG”, etc.               |
| Show line numbers            | `grep -n 'rabbit' pets.txt` – prefixes lines with their line number |
| Invert match                 | `grep -v 'snake' pets.txt` – shows lines **without** “snake”        |
| Search in all files of cwd   | `grep -i 'dog' *` – searches every file in current directory        |

---

### 4. Most-Used grep Flags

| Flag / Pattern     | Description                             | Syntax                     | Example Usage               |
| ------------------ | --------------------------------------- | -------------------------- | --------------------------- |
| **`-i`**           | Case-insensitive search                 | `grep -i <pattern> <file>` | `grep -i "cat" pets.txt`    |
| **`-w`**           | Match whole words only                  | `grep -w <pattern> <file>` | `grep -w "dog" pets.txt`    |
| **`-n`**           | Prefix matches with line numbers        | `grep -n <pattern> <file>` | `grep -n "rabbit" pets.txt` |
| **`-c`**           | Count matching lines                    | `grep -c <pattern> <file>` | `grep -c "snake" pets.txt`  |
| **`-v`**           | Invert match (show non-matching lines)  | `grep -v <pattern> <file>` | `grep -v "cat" pets.txt`    |
| **Search all**     | All files in current directory          | `grep <pattern> ./*`       | `grep -i "dog" *`           |
| **Search `*.txt`** | All `.txt` files in current directory   | `grep <pattern> *.txt`     | `grep -i "cat" *.txt`       |
| **`-r`**           | Recursive search through subdirectories | `grep -r "<pattern>" .`    | `grep -r "rabbit" .`        |

---

### 5. Comparing & Counting (wc)

| Task                  | Command          |
| --------------------- | ---------------- |
| Line/word/char count  | `wc pets.txt`    |
| Count only lines      | `wc -l pets.txt` |
| Count only words      | `wc -w pets.txt` |
| Count only characters | `wc -c pets.txt` |

---

### 6. Piping & Filtering

| Command    | Description                                                                                         | Syntax                            | Key Options                                                                                                    |
|------------|-----------------------------------------------------------------------------------------------------|-----------------------------------|----------------------------------------------------------------------------------------------------------------|
| **\|**     | Chain commands by piping one’s output into another’s input                                          | `<cmd1> \| <cmd2>`                | N/A      
| `-d <delim>`   | Set delimiter (default is TAB)          | `cut -d',' -f1 file.txt`     | `cut -d',' -f1 Fruits.txt`         |
| `-f <fields>`  | Choose specific fields (columns)        | `cut -d',' -f1,3 file.txt`   | `cut -d',' -f1,3 Fruits.txt`       |                                                                                                   |
| **sort**   | Order lines: ASCII, numeric (`-n`), month (`-M`), case-insensitive (`-f`), reverse (`-r`), or field | `sort [options] [file]`           | `-n`, `-r`, `-f`, `-M`, `-k start[,end]`, `-t <delim>`                                                         |
| **uniq**   | Filter or count adjacent duplicate lines                                                           | `uniq [options] [file]`           | `-c`, `-d`, `-D`, `-u`                                                                                         |
| **column** | Align fields into columns based on a delimiter                                                     | `column [options] [file]`         | `-t`, `-s <delim>`, `-n`, `-R <rowsep>`, `-c <columns>`                                                        |
| **tr**     | Translate or delete characters                                                                     | `tr [options] <set1> <set2> < file` | `-d`, `-s`, `-c`                                                                                                |
| **tee**    | Write stream to **stdout** and file                                                                | `… \| tee [options] <file>`       | `-a`, `-i`                                                                                                     |
