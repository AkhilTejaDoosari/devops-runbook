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

# vim — Terminal Text Editor

On a remote Linux server there is no GUI. No VS Code, no Sublime, no Notepad. When you need to edit a config file, fix a broken nginx config, or write a quick script, you use a terminal editor. `vim` is the one you will find on every Linux server without exception — it ships with the OS or is one package install away.

The reason vim feels hard at first is that it is **modal** — it has separate modes for navigating and for typing. Most editors have one mode: you open a file and start typing. vim separates these deliberately, because navigating and editing are different tasks that deserve different keystrokes. Once that mental model clicks, vim becomes fast.

---

## Table of Contents

- [1. The Three Modes](#1-the-three-modes)
- [2. Opening and Exiting](#2-opening-and-exiting)
- [3. Navigation](#3-navigation)
- [4. Editing](#4-editing)
- [5. Search and Replace](#5-search-and-replace)
- [6. The Webstore Workflow — Real Editing Scenarios](#6-the-webstore-workflow--real-editing-scenarios)
- [7. Quick Reference](#7-quick-reference)

---

## 1. The Three Modes

vim starts in **Normal mode** every time you open it. This is the source of most beginner confusion — you open a file, start typing, and nothing appears where you expect it to.

```
Normal mode  ←──────────── Esc ─────────────┐
     │                                       │
     │  i / a / o                            │
     ▼                                       │
Insert mode  ── type your content ───────────┘

Normal mode
     │
     │  :
     ▼
Command-line mode  ── :w  :q  :wq  :%s/old/new/g
```

| Mode | How to enter | What you do here |
|---|---|---|
| Normal | Default on open, or press `Esc` from any other mode | Navigate, delete, copy, paste — keyboard is commands not text |
| Insert | Press `i`, `a`, or `o` from Normal mode | Type text — keyboard behaves like a normal editor |
| Command-line | Press `:` from Normal mode | Save, quit, search and replace, open other files |

**The rule that prevents most frustration:** whenever vim is not behaving as expected, press `Esc` first. `Esc` always returns you to Normal mode from anywhere.

---

## 2. Opening and Exiting

```bash
# Open a file
vim ~/webstore/config/webstore.conf

# Open and jump directly to line 5
vim +5 ~/webstore/config/webstore.conf

# Open a new file (creates it on save)
vim ~/webstore/config/nginx.conf
```

**Exiting — the commands everyone needs to know first:**

| Command | What it does |
|---|---|
| `:w` | Save (write) the file — stay in vim |
| `:q` | Quit — only works if no unsaved changes |
| `:wq` | Save and quit |
| `:q!` | Quit without saving — discard all changes |
| `:x` | Save and quit — same as `:wq` but skips write if nothing changed |

`:q!` is the one you reach for when you opened the wrong file or made changes you want to throw away. It forces quit with no questions asked.

---

## 3. Navigation

In Normal mode the keyboard is for movement, not typing. These are the keys you use to move around a file without touching the mouse.

**Basic movement:**

| Key | Movement |
|---|---|
| `h` | Left one character |
| `l` | Right one character |
| `j` | Down one line |
| `k` | Up one line |
| `w` | Forward one word |
| `b` | Backward one word |
| `0` | Beginning of current line |
| `$` | End of current line |
| `gg` | First line of the file |
| `G` | Last line of the file |
| `NG` | Jump to line N — e.g. `5G` jumps to line 5 |

**Prepend a number to repeat any movement:**
`5j` moves down 5 lines. `3w` jumps forward 3 words. `10G` jumps to line 10. This is how you navigate a large config file without scrolling.

**When you reach for `NG`:**
An error message says "syntax error on line 47 of webstore.conf" — type `47G` in Normal mode and you land exactly there.

---

## 4. Editing

All editing commands run from Normal mode. You do not need to enter Insert mode to delete, copy, or paste.

**Entering Insert mode — where to start typing:**

| Key | Where insertion begins |
|---|---|
| `i` | Before the cursor |
| `a` | After the cursor |
| `o` | New line below the current line |
| `O` | New line above the current line |

After typing your content, press `Esc` to return to Normal mode.

**Editing without Insert mode:**

| Command | What it does |
|---|---|
| `x` | Delete the character under the cursor |
| `dd` | Delete (cut) the entire current line |
| `D` | Delete from cursor to end of line |
| `cw` | Delete the current word and enter Insert mode to replace it |
| `yy` | Yank (copy) the current line |
| `Nyy` | Yank N lines — `3yy` copies 3 lines |
| `p` | Paste after the cursor / below the current line |
| `u` | Undo the last change |
| `Ctrl+R` | Redo — reverse an undo |

**The most useful editing sequence in practice:**
`dd` to cut a line, navigate to where you want it, `p` to paste it. This is how you reorder lines in a config file without retyping them.

---

## 5. Search and Replace

**Search:**

```
/pattern      search forward — press n for next match, N for previous
?pattern      search backward
```

```bash
# Inside vim — find every occurrence of "webstore-db" in the config
/webstore-db
# Press n to jump to the next match
# Press N to jump backwards
```

**Replace — the command-line mode substitute:**

```
:%s/old/new/g
```

- `%` — apply to the entire file (without `%` it only applies to the current line)
- `s` — substitute
- `old` — pattern to find
- `new` — replacement
- `g` — replace all occurrences on each line (without `g` only the first per line)

```bash
# Replace every occurrence of "production" with "staging" in the entire file
:%s/production/staging/g

# Replace with confirmation for each change — vim shows each match and asks y/n
:%s/production/staging/gc

# Replace only on the current line
:s/production/staging/g

# Replace only on lines 2 through 5
:2,5s/8080/9090/g
```

**When you reach for `:%s`:**
Updating a config file to point at a new database host, changing a port number that appears multiple times, or sanitizing a file before committing it. Faster than finding every occurrence manually.

---

## 6. The Webstore Workflow — Real Editing Scenarios

**Scenario 1 — Edit the webstore config to change the API port:**

```
vim ~/webstore/config/webstore.conf   # open the file
/api_port                             # search for the line
cw                                    # delete "api_port" and enter insert mode
api_port=9090                         # type the new value
Esc                                   # back to Normal mode
:wq                                   # save and quit
```

**Scenario 2 — nginx config has a syntax error on line 12:**

```
vim ~/webstore/config/nginx.conf      # open the file
12G                                   # jump directly to line 12
```
Read the line, find the error, press `i` to enter Insert mode, fix it, press `Esc`, then `:wq`.

**Scenario 3 — Add a new config entry at the end of webstore.conf:**

```
vim ~/webstore/config/webstore.conf   # open the file
G                                     # jump to last line
o                                     # open new line below and enter Insert mode
log_level=info                        # type the new entry
Esc                                   # back to Normal mode
:wq                                   # save and quit
```

**Scenario 4 — Replace all occurrences of the old database hostname:**

```
vim ~/webstore/config/webstore.conf
:%s/webstore-db-old/webstore-db/g
:wq
```

---

## 7. Quick Reference

**Modes:**

| Key | Action |
|---|---|
| `Esc` | Return to Normal mode from anywhere |
| `i` | Enter Insert mode before cursor |
| `a` | Enter Insert mode after cursor |
| `o` | New line below, enter Insert mode |
| `:` | Enter Command-line mode |

**Navigation (Normal mode):**

| Key | Action |
|---|---|
| `h j k l` | Left, down, up, right |
| `w` / `b` | Next / previous word |
| `0` / `$` | Start / end of line |
| `gg` / `G` | First / last line |
| `NG` | Jump to line N |

**Editing (Normal mode):**

| Key | Action |
|---|---|
| `x` | Delete character under cursor |
| `dd` | Delete current line |
| `yy` | Copy current line |
| `p` | Paste after cursor |
| `u` | Undo |
| `Ctrl+R` | Redo |
| `cw` | Change word |

**Save and exit (Command-line mode):**

| Command | Action |
|---|---|
| `:w` | Save |
| `:q` | Quit (no unsaved changes) |
| `:wq` | Save and quit |
| `:q!` | Quit without saving |

**Search and replace (Command-line mode):**

| Command | Action |
|---|---|
| `/pattern` | Search forward |
| `n` / `N` | Next / previous match |
| `:%s/old/new/g` | Replace all in file |
| `:%s/old/new/gc` | Replace all with confirmation |

---

→ Ready to practice? [Go to Lab 03](../linux-labs/03-vim-users-permissions-lab.md)
