[Home](../README.md) |
[Foundations](../01-foundations/README.md) |
[Stash & Tags](../02-stash-tags/README.md) |
[History & Branching](../03-history-branching/README.md) |
[Contribute](../04-contribute/README.md) |
[Undo & Recovery](../05-undo-recovery/README.md)

# Git Foundations

Before Git, the way people saved progress on a project was to zip the folder. `webstore_final.zip` became `webstore_final_v2.zip` became `webstore_final_REAL_final.zip`. Nobody knew which was current. Nobody knew what changed between them. If something broke, there was no reliable way back.

Git solves this by recording every change as a permanent snapshot with a timestamp, a message, and the identity of who made it. You can jump to any point in that history instantly. You can work on a new feature without touching the working version. You can collaborate with other engineers without overwriting each other's work.

In DevOps, Git is the source of truth. GitHub Actions reads from it to know when to build. Terraform reads from it to know what infrastructure to provision. ArgoCD reads from it to know what to deploy. Everything downstream depends on what is in the repo.

---

## Table of Contents

- [1. How Git Tracks History](#1-how-git-tracks-history)
- [2. Installing and Configuring Git](#2-installing-and-configuring-git)
- [3. Creating a Repository — The Project's Birth](#3-creating-a-repository--the-projects-birth)
- [4. The Three States — Working, Staged, Committed](#4-the-three-states--working-staged-committed)
- [5. Your First Commits — Building the Webstore History](#5-your-first-commits--building-the-webstore-history)
- [6. .gitignore — What Git Should Never See](#6-gitignore--what-git-should-never-see)
- [7. Connecting to GitHub — The Remote](#7-connecting-to-github--the-remote)
- [8. Commit Message Convention](#8-commit-message-convention)
- [9. Quick Reference](#9-quick-reference)

---

## 1. How Git Tracks History

Git stores history as a chain of **commits**. Each commit is a snapshot of your entire project at a point in time — not a diff, not a patch, a complete snapshot. Every commit has:

- A unique **SHA hash** — a 40-character fingerprint like `a3f92c1b...` that identifies it permanently
- A **message** — what changed and why
- The **author** — who made the change and when
- A pointer to its **parent commit** — the previous snapshot

The chain looks like this:

```
A ← B ← C ← D   (main branch)
```

Each letter is a commit. Each one points back to its parent. `D` is the most recent. `A` is the first. Every commit between them is preserved permanently.

**HEAD** is a pointer that tells Git where you currently are — which commit you are looking at right now. When you make a new commit, HEAD moves forward automatically.

---

## 2. Installing and Configuring Git

**Install:**

```bash
# Ubuntu/Debian
sudo apt install git -y

# macOS
brew install git

# Verify
git --version
```

**Configure your identity — required before your first commit:**

```bash
git config --global user.name "Akhil Teja Doosari"
git config --global user.email "doosariakhilteja@gmail.com"
```

Every commit you make carries this identity. On GitHub it links your commits to your account. On a team, it shows your teammates who made each change.

**Set your default editor:**

```bash
git config --global core.editor "vim"
```

**Check all settings:**

```bash
git config --list
```

**Config levels — where settings live:**

| Level | Flag | File | Affects |
|---|---|---|---|
| System | `--system` | `/etc/gitconfig` | Every user on this machine |
| Global | `--global` | `~/.gitconfig` | Your user account |
| Local | `--local` | `.git/config` | This repo only |

Local overrides global overrides system. Use local config when you work with a company email on one project and a personal email on others:

```bash
# Inside the work repo
git config --local user.email "akhil@company.com"
```

---

## 3. Creating a Repository — The Project's Birth

When you run `git init` in a directory, Git creates a hidden `.git/` folder inside it. That folder is the entire repository — every commit, every branch, every tag. The `.git/` folder is what makes a directory a Git repo.

```bash
# Turn the webstore directory into a Git repo
cd ~/webstore
git init
```

```
Initialized empty Git repository in /home/akhil/webstore/.git/
```

```bash
# Confirm .git exists
ls -la
# .git  frontend/  api/  db/  logs/  config/  backup/
```

The webstore project now has version control. Nothing is tracked yet — Git is watching but has not been told what to remember.

---

## 4. The Three States — Working, Staged, Committed

Every file in a Git repository is in one of three states. Understanding this is the mental model that makes every Git command make sense.

```
Working Directory → Staging Area → Repository
      edit             git add        git commit
```

**Working Directory** — where you edit files. Git sees the changes but has not been asked to do anything with them yet. Running `git status` shows what has changed.

**Staging Area** — a holding area where you explicitly choose what goes into the next commit. Think of it as preparing a package before sealing it. You decide exactly what is in this snapshot.

**Repository** — committed history. Permanent. Immutable. Every commit here is preserved indefinitely.

**Why the staging area exists:**
You edited five files but only three are ready to commit. The staging area lets you commit those three as one logical change while leaving the other two in progress. Without it, every `git commit` would include everything you touched.

```bash
# See where everything stands
git status

# Stage a specific file
git add config/webstore.conf

# Stage everything
git add .

# Unstage a file you added by mistake
git restore --staged config/webstore.conf

# See what is staged vs what is not
git diff --staged   # shows staged changes
git diff            # shows unstaged changes
```

---

## 5. Your First Commits — Building the Webstore History

This is the moment the webstore project becomes trackable. Every future deploy, every incident, every feature will be traceable back to this history.

**The first commit:**

```bash
cd ~/webstore

# Check what Git sees
git status

# Stage everything — the whole initial project
git add .

# Confirm what is staged
git status
# Changes to be committed:
#   new file: frontend/index.html
#   new file: api/server.js
#   new file: config/webstore.conf
#   ...

# Create the first commit
git commit -m "feat: initialize webstore project structure

- add frontend, api, db, logs, config, backup directories
- add webstore.conf with db and api connection settings
- add placeholder files for each service layer"
```

**View the commit:**

```bash
git log --oneline
# a3f92c1 feat: initialize webstore project structure
```

**Build more history — each commit tells the story of what the webstore became:**

```bash
# Second commit — first real config
echo "nginx_worker_processes=4" >> config/webstore.conf
git add config/webstore.conf
git commit -m "config: add nginx worker process setting"

# Third commit — add the first log entry
echo "2025-04-05 09:00 server started" >> logs/access.log
git add logs/access.log
git commit -m "logs: add initial server startup entry"

# View the growing history
git log --oneline
# c8d21fa logs: add initial server startup entry
# b71e3a2 config: add nginx worker process setting
# a3f92c1 feat: initialize webstore project structure
```

Each commit is a chapter. The message explains what changed. The hash identifies it permanently. Anyone who clones this repo can read this history and understand how the project evolved.

---

## 6. .gitignore — What Git Should Never See

`.gitignore` tells Git which files to completely ignore — never track, never show in `git status`, never accidentally commit. This is one of the most important files in any repo.

**What belongs in `.gitignore`:**

```
# Environment files — database passwords, API keys, secrets
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

# OS noise
.DS_Store
Thumbs.db

# Logs — runtime data, not source
*.log

# Terraform — contains sensitive infrastructure state
*.tfstate
*.tfstate.backup
.terraform/

# IDE files
.vscode/
.idea/
```

**Create it at the root of the repo:**

```bash
vim ~/webstore/.gitignore
# add the entries above
git add .gitignore
git commit -m "chore: add .gitignore"
```

**The most important rule:** create `.gitignore` before your first `git add .`. If you accidentally commit a secret, it is in the history permanently — even if you delete the file later. The history is immutable.

**If you accidentally tracked a file that should be ignored:**

```bash
# Remove from tracking without deleting from disk
git rm --cached .env
echo ".env" >> .gitignore
git commit -m "fix: remove .env from tracking, add to gitignore"
```

**Check why a file is being ignored:**

```bash
git check-ignore -v .env
# .gitignore:1:.env  .env
```

---

## 7. Connecting to GitHub — The Remote

A remote is a Git repository hosted somewhere else — GitHub in this case. When you push, Git sends your commits to the remote. When you pull, Git fetches commits from the remote into your local repo.

**Create the repo on GitHub first** (github.com → New repository → webstore), then connect it:

```bash
# Add the remote — named "origin" by convention
git remote add origin https://github.com/AkhilTejaDoosari/webstore.git

# Verify the connection
git remote -v
# origin  https://github.com/AkhilTejaDoosari/webstore.git (fetch)
# origin  https://github.com/AkhilTejaDoosari/webstore.git (push)

# Push the local history to GitHub for the first time
git push -u origin main
```

The `-u` flag sets origin/main as the default upstream — after this, `git push` and `git pull` with no arguments work from the right place.

**The daily workflow after the first push:**

```bash
# Edit files
git status               # see what changed
git add .                # stage changes
git commit -m "message"  # commit
git push                 # push to GitHub
```

---

## 8. Commit Message Convention

Every commit you make is a permanent record. Write messages that a teammate — or you in six months — can read and immediately understand what changed and why.

**The format:**

```
type: short description (under 72 characters)

Optional longer explanation if needed.
```

**Common types:**

| Type | When to use |
|---|---|
| `feat` | A new feature or capability |
| `fix` | A bug fix |
| `config` | Configuration changes |
| `docs` | Documentation only |
| `chore` | Maintenance — dependencies, gitignore, tooling |
| `refactor` | Code restructure with no behavior change |
| `test` | Adding or fixing tests |

**Good vs bad examples:**

```
# Bad — tells you nothing
git commit -m "update"
git commit -m "fix stuff"
git commit -m "wip"

# Good — tells you what and why
git commit -m "feat: add product listing endpoint to webstore-api"
git commit -m "fix: correct db_port in webstore.conf — was 27017, should be 5432"
git commit -m "config: add nginx worker process setting for production load"
```

**The webstore history should read like documentation.** Anyone cloning the repo for the first time should be able to run `git log --oneline` and understand how the project evolved without opening a single file.

---

## 9. Quick Reference

| Command | What it does |
|---|---|
| `git init` | Initialize a repo in the current directory |
| `git config --global user.name "Name"` | Set global identity |
| `git status` | Show working directory and staging area state |
| `git add <file>` | Stage a specific file |
| `git add .` | Stage all changes |
| `git restore --staged <file>` | Unstage a file |
| `git commit -m "message"` | Commit staged changes |
| `git log --oneline` | View compact commit history |
| `git diff` | Show unstaged changes |
| `git diff --staged` | Show staged changes |
| `git rm --cached <file>` | Remove from tracking without deleting |
| `git remote add origin <url>` | Connect to a GitHub remote |
| `git push -u origin main` | Push and set upstream (first push) |
| `git push` | Push commits to remote |
| `git pull` | Fetch and merge remote changes |
| `git check-ignore -v <file>` | Show which gitignore rule matched |

---

→ Ready to practice? [Go to Lab 01](../git-labs/01-foundations-lab.md)
