[Home](../README.md) |
[Foundations](../01-foundations/README.md) |
[Stash & Tags](../02-stash-tags/README.md) |
[History & Branching](../03-history-branching/README.md) |
[Contribute](../04-contribute/README.md) |
[Undo & Recovery](../05-undo-recovery/README.md) |
[Interview](../99-interview-prep/README.md)

---

# Git Foundations

> **Depends on:** [01 Linux](../../01.%20Linux%20–%20System%20Fundamentals/README.md) — you need terminal confidence and the webstore directory before initializing a repo
> **Used in production when:** Starting any new project, making daily commits, pushing code to GitHub, or onboarding to a repo for the first time

---

## Table of Contents

- [What this is](#what-this-is)
- [How Git works — the architecture](#how-git-works--the-architecture)
- [1. How Git tracks history](#1-how-git-tracks-history)
- [2. Installing and configuring Git](#2-installing-and-configuring-git)
- [3. Creating a repository](#3-creating-a-repository)
- [4. The three states — working, staged, committed](#4-the-three-states--working-staged-committed)
- [5. Your first commits](#5-your-first-commits)
- [6. .gitignore — what Git should never see](#6-gitignore--what-git-should-never-see)
- [7. Connecting to GitHub — the remote](#7-connecting-to-github--the-remote)
- [8. Commit message convention](#8-commit-message-convention)
- [On the webstore](#on-the-webstore)
- [What breaks](#what-breaks)
- [Daily commands](#daily-commands)

---

## What this is

Before Git, saving progress meant zipping folders. `webstore_final.zip` → `webstore_final_v2.zip` → `webstore_final_REAL_final.zip`. Nobody knew which was current. If something broke, there was no reliable way back. Git solves this by recording every change as a permanent snapshot with a timestamp, a message, and the identity of who made it. In DevOps, Git is the source of truth. GitHub Actions reads from it to know when to build. Terraform reads from it to know what to provision. ArgoCD reads from it to know what to deploy. Everything downstream depends on what is in the repo.

---

## How Git works — the architecture

```
  Working dir   →   Staging area   →   Local repo   →   Remote (GitHub)
     edit            git add            git commit        git push

  ◄── git restore --staged    ◄── git reset       ◄────── git fetch / pull
```

Three zones on your machine. One zone on GitHub. Every Git command moves data between zones. Know where data is — every command makes sense. Full diagram in the [Git README](../README.md).

---

## 1. How Git tracks history

Git stores history as a chain of commits. Each commit is a complete snapshot — not a diff, a full snapshot of the project at that point in time. Every commit has:

- A **SHA hash** — a unique 40-character fingerprint like `a3f92c1b` that identifies it permanently
- A **message** — what changed and why
- The **author** — who made it and when
- A pointer to its **parent** — the previous snapshot

```
a3f92c1 ◄── b71e3a2 ◄── c8d21fa   ←  main  ←  HEAD
```

**HEAD** is a pointer to where you currently are. When you make a new commit, HEAD moves forward automatically.

---

## 2. Installing and configuring Git

```bash
# Install — Ubuntu/Debian
sudo apt install git -y

# Verify
git --version
# git version 2.43.0
```

**Configure identity — required before your first commit:**

```bash
# --global applies to every repo on this machine
git config --global user.name "Akhil Teja Doosari"
git config --global user.email "doosariakhilteja@gmail.com"
git config --global core.editor "vim"

# Verify everything is set
git config --list
# user.name=Akhil Teja Doosari
# user.email=doosariakhilteja@gmail.com
# core.editor=vim
```

Every commit carries this identity. On GitHub it links your commits to your account.

**Config levels — which file wins:**

| Level | Flag | File | Affects |
|---|---|---|---|
| System | `--system` | `/etc/gitconfig` | Every user on this machine |
| Global | `--global` | `~/.gitconfig` | Your user account |
| Local | `--local` | `.git/config` | This repo only — overrides global |

```bash
# Different email for a work repo — override global inside that repo
git config --local user.email "akhil@company.com"
```

---

## 3. Creating a repository

`git init` creates a `.git/` folder inside the directory. That folder IS the entire repository — every commit, every branch, every tag. Nothing is tracked yet — Git is watching but has not been asked to remember anything.

```bash
cd ~/webstore
git init
# Initialized empty Git repository in /home/akhil/webstore/.git/

# Confirm .git exists
ls -la
# .git  frontend/  api/  db/  logs/  config/  backup/
```

---

## 4. The three states — working, staged, committed

Every file is always in one of three states:

```
Working Directory → Staging Area → Repository
      edit             git add        git commit
```

**Working Directory** — where you edit files. Git sees changes but has not been asked to do anything with them.

**Staging Area** — you explicitly choose what goes into the next commit. Think of it as preparing a package before sealing it.

**Repository** — committed history. Permanent. Immutable.

**Why the staging area exists:** You edited five files but only three are ready to commit. Stage those three as one logical change, leave the other two in progress. Without staging, every commit would include everything you touched.

```bash
# See where everything stands
git status

# Stage a specific file
git add config/webstore.conf

# Stage everything
git add .

# Unstage a file added by mistake
# --staged = move it back from staging to working dir
git restore --staged config/webstore.conf

# See what is staged vs what is not
git diff           # working dir vs staging area
git diff --staged  # staging area vs last commit
```

---

## 5. Your first commits

```bash
cd ~/webstore

# Check what Git sees
git status
# Untracked files: frontend/ api/ db/ logs/ config/ backup/

# Stage the whole project
git add .

# Confirm what is staged
git status
# Changes to be committed:
#   new file: frontend/index.html
#   new file: api/server.js
#   new file: config/webstore.conf
#   ...

# First commit — type: short description
git commit -m "feat: initialize webstore project structure

- add frontend, api, db, logs, config, backup directories
- add webstore.conf with db and api connection settings"

# View it
git log --oneline
# a3f92c1 feat: initialize webstore project structure
```

**Build more history:**

```bash
# Second commit
echo "nginx_worker_processes=4" >> config/webstore.conf
git add config/webstore.conf
git commit -m "config: add nginx worker process setting"

# Third commit
echo "2025-04-05 09:00 server started" >> logs/access.log
git add logs/access.log
git commit -m "logs: add initial server startup entry"

git log --oneline
# c8d21fa logs: add initial server startup entry
# b71e3a2 config: add nginx worker process setting
# a3f92c1 feat: initialize webstore project structure
```

Each commit is a chapter. Anyone cloning this repo can run `git log --oneline` and understand how the project evolved.

---

## 6. .gitignore — what Git should never see

`.gitignore` tells Git which files to completely ignore — never track, never show in `git status`, never accidentally commit. Create it before your first `git add .` — if you commit a secret, it is in the history permanently even if you delete the file later.

```bash
vim ~/webstore/.gitignore
```

```
# Secrets — never commit these
.env
.env.local
.env.production

# Build output — generated, not source
dist/
build/
*.tar
*.gz

# Dependencies — installed, not committed
node_modules/

# Logs — runtime data, not source
*.log

# Terraform state — contains sensitive infrastructure data
*.tfstate
*.tfstate.backup
.terraform/

# OS noise
.DS_Store
Thumbs.db

# IDE files
.vscode/
.idea/
```

```bash
git add .gitignore
git commit -m "chore: add .gitignore"
```

**If you accidentally tracked a file that should be ignored:**

```bash
# --cached = remove from Git tracking only, keep the file on disk
git rm --cached .env
echo ".env" >> .gitignore
git commit -m "fix: remove .env from tracking, add to gitignore"

# Check why a file is being ignored
git check-ignore -v .env
# .gitignore:1:.env  .env
```

---

## 7. Connecting to GitHub — the remote

A remote is a Git repository hosted somewhere else. When you push, Git sends your commits there. When you pull, Git fetches commits from there.

```bash
# Create the repo on GitHub first — then connect it
git remote add origin https://github.com/AkhilTejaDoosari/webstore.git

# Verify
git remote -v
# origin  https://github.com/AkhilTejaDoosari/webstore.git (fetch)
# origin  https://github.com/AkhilTejaDoosari/webstore.git (push)

# First push — -u sets origin/main as default upstream
# After this, git push and git pull work with no arguments
git push -u origin main
```

**The daily workflow after the first push:**

```bash
git status               # see what changed
git add .                # stage changes
git commit -m "message"  # commit
git push                 # push to GitHub
```

---

## 8. Commit message convention

Every commit is a permanent record. Write messages a teammate — or you in six months — can read and immediately understand.

```
type: short description (under 72 characters)

Optional longer explanation if the change needs context.
```

| Type | When to use |
|---|---|
| `feat` | A new feature or capability |
| `fix` | A bug fix |
| `config` | Configuration changes |
| `docs` | Documentation only |
| `chore` | Maintenance — dependencies, gitignore, tooling |
| `refactor` | Code restructure with no behavior change |

```bash
# Bad — tells you nothing
git commit -m "update"
git commit -m "fix stuff"
git commit -m "wip"

# Good — tells you what and why
git commit -m "feat: add product listing endpoint to webstore-api"
git commit -m "fix: correct db_port in webstore.conf — was 27017, should be 5432"
git commit -m "config: add nginx worker process setting for production load"
```

The webstore history should read like documentation. Anyone cloning the repo should understand how it evolved from `git log --oneline` alone.

---

## On the webstore

The webstore directory from Linux exists on disk. No version control yet. This is where it gets one.

```bash
# Step 1 — initialize the repo
cd ~/webstore
git init
# Initialized empty Git repository in /home/akhil/webstore/.git/

# Step 2 — create .gitignore before staging anything
vim .gitignore
# add .env, *.log, node_modules/, dist/, .terraform/

# Step 3 — stage and commit the initial structure
git add .
git status
# new file: frontend/index.html, api/server.js, config/webstore.conf ...
git commit -m "feat: initialize webstore project structure"

# Step 4 — connect to GitHub
git remote add origin https://github.com/AkhilTejaDoosari/webstore.git
git push -u origin main

# Step 5 — verify it is on GitHub
git remote -v
# origin  https://github.com/AkhilTejaDoosari/webstore.git (fetch)
# origin  https://github.com/AkhilTejaDoosari/webstore.git (push)

git log --oneline
# a3f92c1 feat: initialize webstore project structure
```

The webstore now has version control. Every change from here is tracked. File 02 picks up from here — stashing work in progress and tagging the first release.

---

## What breaks

| Symptom | Cause | Fix |
|---|---|---|
| `git commit` fails with "no identity" | user.name and user.email not configured | `git config --global user.name "Name"` and email |
| Committed a secret (.env, password) | Staged it before adding to .gitignore | `git rm --cached .env` + add to .gitignore + new commit. If pushed — rotate the secret immediately |
| `git push` rejected — "non-fast-forward" | Someone else pushed to the same branch | `git pull` first to get their changes, resolve conflicts if any, then push |
| File shows in `git status` after adding to .gitignore | File was already tracked before .gitignore was added | `git rm --cached <file>` to stop tracking it |
| Committed to wrong branch | Forgot to create a feature branch | `git reset --soft HEAD~1` moves the commit back to staging — then switch to correct branch and recommit |
| `fatal: not a git repository` | Ran git command outside a repo | `cd` to the repo root where `.git/` lives |

---

## Daily commands

| Command | What it does |
|---|---|
| `git init` | Initialize a new repository in current directory |
| `git config --global user.name "Name"` | Set global identity — name and email required before first commit |
| `git status` | Show working directory and staging area state |
| `git add .` | Stage all changes in current directory |
| `git add <file>` | Stage a specific file only |
| `git restore --staged <file>` | Unstage a file — moves it back to working directory |
| `git commit -m "type: message"` | Commit staged changes with a message |
| `git log --oneline` | Compact one-line view of commit history |
| `git remote add origin <url>` | Connect local repo to GitHub remote |
| `git push -u origin main` | Push to GitHub and set default upstream |

---

→ **Interview questions for this topic:** [99-interview-prep → Git Foundations](../99-interview-prep/README.md#git-foundations)
