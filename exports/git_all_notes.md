
---
# FILE: 02. Git & GitHub – Version Control/01-foundations/README.md
---

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

---
# FILE: 02. Git & GitHub – Version Control/02-stash-tags/README.md
---

[Home](../README.md) |
[Foundations](../01-foundations/README.md) |
[Stash & Tags](../02-stash-tags/README.md) |
[History & Branching](../03-history-branching/README.md) |
[Contribute](../04-contribute/README.md) |
[Undo & Recovery](../05-undo-recovery/README.md) |
[Interview](../99-interview-prep/README.md)

---

# Git Stash & Tags

> **Depends on:** [01 Foundations](./01-foundations/README.md) — you need commits and a remote before stashing and tagging make sense
> **Used in production when:** An urgent bug lands while you are mid-feature (stash), or a stable version ships and CI/CD needs a permanent reference point (tags)

---

## Table of Contents

- [What this is](#what-this-is)
- [1. Git stash — pausing without committing](#1-git-stash--pausing-without-committing)
- [2. Git tags — marking the webstore's first release](#2-git-tags--marking-the-webstores-first-release)
- [On the webstore](#on-the-webstore)
- [What breaks](#what-breaks)
- [Daily commands](#daily-commands)

---

## What this is

Two tools for two different situations. Stash is for when you are in the middle of something and need to stop without committing half-finished work — a clean shelf to park changes temporarily. Tags are for when you finish something and want to mark that moment permanently. Unlike a branch name that moves forward with every commit, a tag never moves. `v1.0` will always point to exactly the commit you tagged — which is why CI/CD pipelines use tags to trigger builds and Docker images are tagged with the same version string.

---

## 1. Git stash — pausing without committing

Stash saves your in-progress changes to a temporary shelf, gives you back a clean working directory, and lets you restore everything exactly where you left it when you are done. The stash is a stack — each save goes on top, most recent is `stash@{0}`.

```
stash@{0}  ← most recent
stash@{1}  ← older
stash@{2}  ← oldest
```

**The basic workflow:**

```bash
# Mid-work on webstore.conf — not ready to commit
cat ~/webstore/config/webstore.conf
# db_host=webstore-db-new   ← work in progress

# Save to stash with a label — anonymous stashes are hard to identify later
git stash push -m "WIP: updating db_host to new database server"

# Working directory is now clean
git status
# nothing to commit, working tree clean

# Switch context, fix the urgent thing, come back
git switch main
# fix bug, commit, push

# Restore your work exactly where you left it
git stash pop
cat ~/webstore/config/webstore.conf
# db_host=webstore-db-new   ← back exactly as you left it
```

**Stash only saves tracked files by default.** New files not yet staged are left behind. Use `-u` to include them:

```bash
touch ~/webstore/api/new-endpoint.js   # new untracked file
# -u (--include-untracked) includes new files
git stash push -u -m "WIP: new endpoint plus config change"
```

**All stash commands:**

| Command | Full form | What it does |
|---|---|---|
| `git stash push -m "msg"` | — | Save tracked changes with a label |
| `git stash -u` | --include-untracked | Include new untracked files |
| `git stash list` | — | Show all stashes on the stack |
| `git stash show -p` | --patch | Full diff of the most recent stash |
| `git stash pop` | — | Apply most recent stash and remove it from stack |
| `git stash apply stash@{1}` | — | Apply a specific stash but keep it on the stack |
| `git stash drop stash@{1}` | — | Delete a specific stash permanently |
| `git stash clear` | — | Delete all stashes — no recovery |
| `git stash branch <name>` | — | Create a branch from the most recent stash |

**Create a branch from a stash** — when you realize mid-work that what you are building should be its own feature branch:

```bash
git stash branch feature/new-db-config stash@{0}
# Creates the branch, checks it out, applies the stash, removes it from the stack
```

**What stash is not:** stash is local only — it does not push to GitHub. It expires after 90 days. It is a temporary shelf, not a substitute for branches. If you are working on something for more than a day, commit it to a branch.

---

## 2. Git tags — marking the webstore's first release

Tags are permanent pointers to specific commits. They never move forward. This is what CI/CD pipelines expect — push `v1.0` to GitHub, GitHub Actions detects it, builds the Docker image as `webstore-api:1.0`, pushes it to the registry. The tag in Git becomes the version in Docker becomes the version in Kubernetes.

**Two types:**

| Type | What it contains | When to use |
|---|---|---|
| Lightweight | Just a pointer to a commit | Local bookmarks only |
| Annotated (`-a`) | Pointer + author + date + message | Releases — always use this for anything shared |

Always use annotated tags for releases. They carry a message and your identity, show up on GitHub's releases page, and are what CI/CD pipelines expect.

**Tagging the webstore v1.0:**

```bash
# Confirm you are on the right commit
git log --oneline
# c8d21fa logs: add initial server startup entry   ← tag this one
# b71e3a2 config: add nginx worker process setting
# a3f92c1 feat: initialize webstore project structure

# -a = annotated, -m = message
git tag -a v1.0 -m "webstore v1.0 — Linux foundation complete

- directory structure established
- nginx configured and serving frontend
- permissions locked down
- ready for containerization"

# View the tag details
git show v1.0
# tag v1.0
# Tagger: Akhil Teja Doosari
# ...message...
# commit c8d21fa...
```

**Tags are not pushed automatically** — push them explicitly:

```bash
# Push a single tag
git push origin v1.0

# Push all local tags at once
git push --tags
```

**Other tag operations:**

```bash
# List all tags
git tag

# Tag a specific past commit — when you forgot to tag at the right time
git tag -a v0.9 a3f92c1 -m "initial structure — pre-nginx"

# Delete a local tag
git tag -d v1.0

# Delete from remote — must delete locally first
git push origin --delete tag v1.0
```

**Semantic versioning — the standard:**

```
v1.0.0   ← major.minor.patch
v1.1.0   ← new feature, backward compatible
v1.1.1   ← bug fix
v2.0.0   ← breaking change
```

The webstore journey: `v1.0` after Linux, `v1.1` after first Docker commit, `v2.0` when running on Kubernetes.

---

## On the webstore

The webstore has three commits from file 01. An urgent bug report arrives mid-feature. You stash, fix, restore, then tag the stable foundation.

```bash
# Step 1 — you are mid-work updating the config
echo "cache_ttl=300" >> ~/webstore/config/webstore.conf
git status
# modified: config/webstore.conf

# Step 2 — urgent bug — stash and switch
git stash push -m "WIP: adding cache TTL setting"
git status
# nothing to commit, working tree clean

# Step 3 — fix the bug on main
git switch main
echo "# fixed" >> ~/webstore/api/server.js
git add api/server.js
git commit -m "fix: resolve api timeout on product listing"
git push

# Step 4 — restore your work
git stash pop
cat ~/webstore/config/webstore.conf
# cache_ttl=300   ← back

# Step 5 — finish and commit the feature
git add config/webstore.conf
git commit -m "config: add cache TTL setting"

# Step 6 — tag this stable state as v1.0
git tag -a v1.0 -m "webstore v1.0 — Linux foundation complete, ready for containerization"

# Step 7 — push everything including the tag
git push
git push origin v1.0

# Verify
git tag
# v1.0
git show v1.0
```

File 03 picks up from here — building features in branches on top of this tagged foundation.

---

## What breaks

| Symptom | Cause | Fix |
|---|---|---|
| `git stash pop` has conflicts | Stashed changes conflict with commits made while stashed | Resolve the conflict in the file, `git add <file>`, `git stash drop` to clean up |
| Stash is empty after `git stash pop` fails | Pop failed partway — stash may still be on stack | `git stash list` to check — if still there, `git stash pop` again after fixing conflicts |
| New file missing after `git stash pop` | Stashed with `git stash` not `git stash -u` — untracked files not included | Use `git stash -u` to include untracked files next time |
| Tag pushed to wrong commit | Tagged HEAD but HEAD was not the right commit | `git tag -d v1.0` locally, `git push origin --delete tag v1.0`, then tag the correct commit |
| `git push` did not push the tag | Tags require explicit push — `git push` does not include them | `git push origin v1.0` or `git push --tags` |
| `git tag -d` says tag not found | Tag name is wrong | `git tag` to list all existing tags |

---

## Daily commands

| Command | What it does |
|---|---|
| `git stash push -m "message"` | Save in-progress changes with a descriptive label |
| `git stash -u` | Save including new untracked files |
| `git stash list` | Show everything on the stash stack |
| `git stash pop` | Restore most recent stash and remove it from stack |
| `git stash show -p` | Show full diff of most recent stash |
| `git tag -a v1.0 -m "message"` | Create annotated tag at current commit |
| `git tag` | List all tags |
| `git show v1.0` | Show tag details and the commit it points to |
| `git push origin v1.0` | Push a specific tag to remote |
| `git push --tags` | Push all local tags to remote at once |

---

→ **Interview questions for this topic:** [99-interview-prep → Stash & Tags](../99-interview-prep/README.md#stash-and-tags)

---
# FILE: 02. Git & GitHub – Version Control/03-history-branching/README.md
---

[Home](../README.md) |
[Foundations](../01-foundations/README.md) |
[Stash & Tags](../02-stash-tags/README.md) |
[History & Branching](../03-history-branching/README.md) |
[Contribute](../04-contribute/README.md) |
[Undo & Recovery](../05-undo-recovery/README.md) |
[Interview](../99-interview-prep/README.md)

---

# Git History & Branching

> **Depends on:** [02 Stash & Tags](./02-stash-tags/README.md) — you need commits and a tagged release before building features in branches
> **Used in production when:** Building a new feature without touching the deployed version, reading history to find what broke a deployment, resolving a merge conflict, keeping a feature branch up to date with main

---

## Table of Contents

- [What this is](#what-this-is)
- [1. Reading project history](#1-reading-project-history)
- [2. Branching — what it is and why it exists](#2-branching--what-it-is-and-why-it-exists)
- [3. Creating, switching, and merging branches](#3-creating-switching-and-merging-branches)
- [4. Merge types — fast-forward and 3-way](#4-merge-types--fast-forward-and-3-way)
- [5. Conflict resolution](#5-conflict-resolution)
- [6. Rebase — keeping history linear](#6-rebase--keeping-history-linear)
- [7. Branching strategies](#7-branching-strategies)
- [On the webstore](#on-the-webstore)
- [What breaks](#what-breaks)
- [Daily commands](#daily-commands)

---

## What this is

The webstore has a commit history now. Someone wants to add a product pagination feature to the API. You cannot build it directly on `main` — that is the stable deployed version. If the feature breaks halfway through, the whole project is broken. Branches solve this. A branch is a separate line of development — a parallel timeline where you can build, break, and experiment without touching what is working. When the feature is done and tested, you merge it back.

---

## 1. Reading project history

Every commit is a permanent record. Reading history is how you understand what happened — who changed what, when, and why.

```bash
# Compact one-line view — most useful daily
git log --oneline
# c8d21fa (HEAD -> main) logs: add initial server startup entry
# b71e3a2 config: add nginx worker process setting
# a3f92c1 feat: initialize webstore project structure

# Full detail — author, date, full message
git log

# Visual branch and merge diagram
# --graph = ASCII tree, --oneline = compact, --all = all branches
git log --graph --oneline --all
# * c8d21fa (HEAD -> main, origin/main) logs: add initial server startup entry
# * b71e3a2 config: add nginx worker process setting
# * a3f92c1 feat: initialize webstore project structure

# Show exactly what changed in one commit
git show c8d21fa
# commit c8d21fa...
# Author: Akhil Teja Doosari
# +2025-04-05 09:00 server started   ← the actual diff

# Filter by author
git log --oneline --author="Akhil"

# Filter by date
git log --oneline --since="2 days ago"

# Search commit messages
git log --oneline --grep="nginx"
```

**git diff — comparing zones:**

```bash
git diff              # working dir vs staging area (unstaged changes)
git diff --staged     # staging area vs last commit (what will be committed)
git diff HEAD         # working dir vs last commit (all uncommitted changes)
git diff a3f92c1 c8d21fa   # changes between two specific commits
```

---

## 2. Branching — what it is and why it exists

A branch is a lightweight pointer to a commit. When you create a branch, Git creates a new pointer at your current commit. When you make commits on that branch, only that pointer moves. `main` stays where it was.

```
Before branching:
main → A → B → C   ← HEAD

After creating feature/products-api:
main             → A → B → C
feature/products-api → C        ← same starting point, both point at C

After two commits on the feature branch:
main             → A → B → C
feature/products-api → C → D → E   ← main untouched
```

**HEAD** tells Git which branch you are on. When you switch branches, HEAD moves. When you commit, HEAD's branch pointer moves forward.

---

## 3. Creating, switching, and merging branches

```bash
# Start from main — always branch from a known good state
git switch main
git pull   # get the latest before branching

# Create and switch in one step
# -c (--create) creates the branch and immediately switches to it
git switch -c feature/webstore-api-pagination

# Make commits on the feature branch
vim ~/webstore/api/server.js
git add api/server.js
git commit -m "feat: add product pagination to webstore API"

vim ~/webstore/api/server.js
git add api/server.js
git commit -m "feat: add pagination query param validation"

# See the branch divergence
git log --graph --oneline --all

# Return to main
git switch main

# Merge the feature branch in
git merge feature/webstore-api-pagination

# Delete the branch — merged, no longer needed
# -d (--delete) only works if the branch is already merged
git branch -d feature/webstore-api-pagination
```

**Branch commands:**

| Command | Full form | What it does |
|---|---|---|
| `git branch` | — | List all local branches |
| `git branch -a` | --all | List local and remote branches |
| `git switch -c <n>` | --create | Create and switch to new branch |
| `git switch <n>` | — | Switch to existing branch |
| `git branch -m old new` | --move | Rename a branch |
| `git branch -d <n>` | --delete | Delete a merged branch |
| `git branch -D <n>` | --delete --force | Force delete even if unmerged |

---

## 4. Merge types — fast-forward and 3-way

**Fast-forward — main has not moved:**

If no new commits were added to `main` while you worked on the feature branch, Git moves the `main` pointer forward to the feature branch tip. No merge commit. History stays linear.

```
Before:
main             → A → B → C
feature/products → C → D → E

After fast-forward:
main → A → B → C → D → E
```

```bash
git switch main
git merge feature/webstore-api-pagination
# Fast-forward — no merge commit created
```

**3-way merge — main has also moved:**

If new commits were added to `main` while you worked, Git creates a merge commit that combines both lines of history.

```
Before:
main             → A → B → C → F → G
feature/products → C → D → E

After 3-way merge:
main → A → B → C → F → G → M   ← M is the merge commit
                   ↗
              D → E
```

```bash
git switch main
git merge feature/webstore-api-pagination
# Merge made by the 'ort' strategy — merge commit created
```

---

## 5. Conflict resolution

Conflicts happen when two branches modify the same lines in the same file. Git marks the conflict and asks you to decide.

**What a conflict looks like in the file:**

```
<<<<<<< HEAD
db_host=webstore-db-primary
=======
db_host=webstore-db-replica
>>>>>>> feature/db-failover
```

- Above `=======` — the branch you are on (HEAD)
- Below `=======` — the incoming branch
- The markers `<<<<<<<`, `=======`, `>>>>>>>` must all be removed

**Resolution process:**

```bash
git merge feature/db-failover
# CONFLICT (content): Merge conflict in config/webstore.conf
# Automatic merge failed; fix conflicts and then commit the result.

# Open and fix the file
vim config/webstore.conf
# Edit to keep the correct value, remove all conflict markers
# Result: db_host=webstore-db-primary

# Mark as resolved
git add config/webstore.conf

# Complete the merge
git commit
# Git opens editor with auto-generated merge commit message — save and close
```

A conflict is not an error. It is Git saying "two people changed the same thing — you decide which version survives."

---

## 6. Rebase — keeping history linear

Rebase rewrites your branch's commits so they appear to start from the current tip of another branch. The result is a clean linear history with no merge commits.

```
Merge result — shows the branch:
main → A → B → C → F → G → M (merge commit)
                   ↗
              D → E

Rebase result — looks linear:
main → A → B → C → F → G → D' → E'
```

Your commits (D, E) are rewritten as new commits (D', E') on top of the latest main.

```bash
# On the feature branch — rebase onto latest main
git switch feature/webstore-api-pagination
# --rebase replays your commits on top of main
git rebase main

# If conflicts arise during rebase
vim <conflicted-file>      # fix the conflict
git add <file>
git rebase --continue      # continue to next commit

# If something goes wrong — abort entirely
git rebase --abort         # returns to before the rebase started

# After successful rebase — merge on main is a fast-forward
git switch main
git merge feature/webstore-api-pagination
# Fast-forward — perfectly linear history
```

**Merge vs Rebase:**

| | Merge | Rebase |
|---|---|---|
| History | Preserves branch structure | Creates linear timeline |
| Use for | Merging completed features to main | Updating a feature branch with latest main |
| Safe on pushed branches | Yes | No — never rebase pushed commits |
| Creates merge commit | Yes | No |

**The golden rule:** never rebase commits that have already been pushed to a shared branch. Rebase rewrites history — if others pulled those commits, their local history diverges and they have problems.

---

## 7. Branching strategies

**Git Flow — the classic:**

```
main        — production only, every commit is deployable
develop     — integration, features merge here before main
feature/*   — individual features, branch from develop
hotfix/*    — emergency fixes off main

feature/x → develop → release/1.0 → main  ← tag v1.0
```

Good for versioned software with scheduled releases. Too much overhead for fast-moving teams.

**Trunk-Based Development — the DevOps standard:**

```
main  ← everyone integrates here, frequently
  ↑
small feature branches, merged within 1–2 days max
```

Good for CI/CD pipelines. GitHub Actions and ArgoCD trigger on commits to main. Long-lived branches delay integration and create merge hell. Feature flags replace long-running branches.

**Branch naming conventions:**

```
feature/webstore-api-pagination
fix/webstore-login-timeout
chore/update-dependencies
docs/add-api-readme
hotfix/fix-payment-crash
```

---

## On the webstore

The webstore is tagged `v1.0`. A second feature is needed — database failover config. Build it in isolation without touching the stable foundation.

```bash
# Step 1 — branch from the stable state
git switch main
git pull
git switch -c feature/db-failover-config

# Step 2 — make the changes
echo "db_replica=webstore-db-replica" >> ~/webstore/config/webstore.conf
echo "db_failover=true" >> ~/webstore/config/webstore.conf
git add config/webstore.conf
git commit -m "feat: add database failover config"

# Step 3 — check history on this branch vs main
git log --graph --oneline --all
# * a1b2c3d (HEAD -> feature/db-failover-config) feat: add database failover config
# * c8d21fa (main) logs: add initial server startup entry
# ...

# Step 4 — merge back to main
git switch main
git merge feature/db-failover-config
# Fast-forward (main did not move while you were on the feature branch)

# Step 5 — clean up
git branch -d feature/db-failover-config

# Verify linear history
git log --oneline
# a1b2c3d feat: add database failover config
# c8d21fa logs: add initial server startup entry
# b71e3a2 config: add nginx worker process setting
# a3f92c1 feat: initialize webstore project structure
```

File 04 picks up from here — pushing this feature branch to GitHub and opening a pull request for review.

---

## What breaks

| Symptom | Cause | Fix |
|---|---|---|
| `git branch -d` refuses to delete | Branch has unmerged commits | Merge it first, or use `-D` if you are sure you want to discard it |
| Merge conflict — don't know what to keep | Both branches changed the same lines | Read both versions, understand what each does, keep the correct one, remove all markers |
| `git rebase` produced unexpected commits | Rebased onto wrong branch or wrong starting point | `git rebase --abort` immediately to return to before the rebase |
| Pushed a rebase and teammates have problems | Rebased commits that were already on remote | Rebase is safe only on local unshared branches — use merge for shared branches |
| `git log --graph` shows detached HEAD | You checked out a commit directly, not a branch | `git switch main` to get back onto a branch |
| Fast-forward expected but got merge commit | Someone committed to main while you were on the feature branch | Normal — 3-way merge is correct in this situation |

---

## Daily commands

| Command | What it does |
|---|---|
| `git log --oneline` | Compact commit history |
| `git log --graph --oneline --all` | Visual branch and merge diagram for all branches |
| `git show <hash>` | Full detail and diff for one specific commit |
| `git diff --staged` | Show staged changes waiting to be committed |
| `git switch -c <branch>` | Create and immediately switch to new branch |
| `git switch <branch>` | Switch to an existing branch |
| `git merge <branch>` | Merge a branch into the current branch |
| `git branch -d <branch>` | Delete a merged branch |
| `git rebase main` | Replay current branch commits on top of latest main |
| `git rebase --abort` | Cancel a rebase in progress and return to before |

---

→ **Interview questions for this topic:** [99-interview-prep → History & Branching](../99-interview-prep/README.md#history-and-branching)

---
# FILE: 02. Git & GitHub – Version Control/04-contribute/README.md
---

[Home](../README.md) |
[Foundations](../01-foundations/README.md) |
[Stash & Tags](../02-stash-tags/README.md) |
[History & Branching](../03-history-branching/README.md) |
[Contribute](../04-contribute/README.md) |
[Undo & Recovery](../05-undo-recovery/README.md) |
[Interview](../99-interview-prep/README.md)

---

# Git Contribute

> **Depends on:** [03 History & Branching](./03-history-branching/README.md) — you need branches and merges before the PR workflow makes sense
> **Used in production when:** A second developer joins the team, you need to propose code for review before it reaches main, or you are contributing to a repo you do not own

---

## Table of Contents

- [What this is](#what-this-is)
- [1. Two collaboration contexts](#1-two-collaboration-contexts)
- [2. Cloning — getting the repo locally](#2-cloning--getting-the-repo-locally)
- [3. Remotes — origin and upstream](#3-remotes--origin-and-upstream)
- [4. git fetch vs git pull — the distinction](#4-git-fetch-vs-git-pull--the-distinction)
- [5. The feature branch PR workflow](#5-the-feature-branch-pr-workflow)
- [6. Forking — contributing to a repo you do not own](#6-forking--contributing-to-a-repo-you-do-not-own)
- [7. Keeping your fork in sync](#7-keeping-your-fork-in-sync)
- [8. What makes a good pull request](#8-what-makes-a-good-pull-request)
- [On the webstore](#on-the-webstore)
- [What breaks](#what-breaks)
- [Daily commands](#daily-commands)

---

## What this is

The webstore is on GitHub. A second developer joins and needs to work on the products API. They cannot push directly to main — that is the production branch. They need their own copy to work from, a way to propose changes for review, and a way to stay in sync when main moves forward while they are working. This is the collaboration model. It is what separates someone who uses Git alone from someone who uses Git on a team.

---

## 1. Two collaboration contexts

| Context | When | What you do |
|---|---|---|
| Company repo | You are on the team, have write access | Clone directly, work in feature branches, open PRs to main |
| Open-source repo | You do not have write access | Fork first, clone your fork, open PR to the original |

In DevOps day-to-day work — your team's infrastructure repo, webstore deployment manifests, Terraform configs — you use the company repo pattern. Fork is for contributing to projects you do not own.

---

## 2. Cloning — getting the repo locally

Clone downloads the full repository — all commits, all branches, all history. Not just the latest files. Everything.

```bash
# Clone the webstore repo
git clone https://github.com/AkhilTejaDoosari/webstore.git

# Clone into a specific folder name
git clone https://github.com/AkhilTejaDoosari/webstore.git my-webstore

cd webstore
git log --oneline    # full history is here
git branch -a        # all branches — local and remote
# * main
#   remotes/origin/main
#   remotes/origin/feature/db-failover-config
```

After cloning you have a full local copy, one remote called `origin` pointing to GitHub, and a local `main` tracking `origin/main`.

---

## 3. Remotes — origin and upstream

A remote is a named reference to a repo hosted somewhere else.

```bash
# See all remotes
git remote -v
# origin  https://github.com/AkhilTejaDoosari/webstore.git (fetch)
# origin  https://github.com/AkhilTejaDoosari/webstore.git (push)
```

**`origin`** — the repo you cloned from. Your team's repo or your fork. You push here and pull from here.

**`upstream`** — the original repo when you have forked. You pull from upstream to stay in sync. You never push to it.

```bash
# Add upstream after forking
git remote add upstream https://github.com/original-owner/webstore.git

git remote -v
# origin    https://github.com/AkhilTejaDoosari/webstore.git (fetch)
# origin    https://github.com/AkhilTejaDoosari/webstore.git (push)
# upstream  https://github.com/original-owner/webstore.git (fetch)
# upstream  https://github.com/original-owner/webstore.git (push)
```

| Remote | Purpose | Push to it? |
|---|---|---|
| `origin` | Your fork or your team's repo | Yes |
| `upstream` | The original repo you forked from | No — read only |

---

## 4. git fetch vs git pull — the distinction

This is one of the most common interview questions and a real source of mistakes in production.

```
git fetch   → downloads new commits from remote into local repo
              does NOT touch your working directory or current branch
              your files are unchanged — you just have the remote data locally

git pull    → git fetch + git merge in one command
              downloads AND immediately merges into your current branch
              your working directory changes
```

```bash
# fetch — safe, no changes to your work
git fetch origin
# Now you can see what changed without your files moving
git log --oneline main..origin/main
# a1b2c3d feat: add payment gateway   ← these are on remote, not in your main yet

# Look before you merge
git diff main origin/main

# Merge when ready
git merge origin/main

# pull — does both in one step
git pull
# equivalent to: git fetch origin + git merge origin/main
```

**When to use which:**
Use `git fetch` when you want to see what changed on the remote before merging — safe on production branches. Use `git pull` in your normal daily workflow when you are confident and just want to be up to date.

---

## 5. The feature branch PR workflow

This is what you do every day on a team. Every piece of work — feature, fix, config change — gets its own branch. When done, you open a pull request for review before it merges to main.

```bash
# Step 1 — start from latest main
git switch main
git pull

# Step 2 — create your feature branch
git switch -c feature/webstore-product-pagination

# Step 3 — do the work, commit as you go
vim api/server.js
git add api/server.js
git commit -m "feat: add pagination to products endpoint"

vim api/server.js
git add api/server.js
git commit -m "feat: add page size validation"

# Step 4 — push the branch to GitHub
git push origin feature/webstore-product-pagination

# Step 5 — open a pull request on GitHub
# github.com → your repo → "Compare & pull request"
# Base: main  ←  Compare: feature/webstore-product-pagination
# Write a clear title and description, submit for review

# Step 6 — teammate reviews, approves, merges on GitHub

# Step 7 — clean up locally after merge
git switch main
git pull                                            # get the merged commit
git branch -d feature/webstore-product-pagination   # delete local branch
```

**Why the PR exists:** a pull request is a checkpoint. Before code reaches main — the production branch — a teammate reads it, catches bugs, asks questions, and approves. Even on a solo project, opening a PR forces you to read your own diff one more time before merging.

---

## 6. Forking — contributing to a repo you do not own

A fork is a complete copy of someone else's repository under your GitHub account. You have full write access to your fork. The original repo is unaffected by anything you do in your fork.

Fork is a GitHub feature, not a Git command. You fork on the GitHub website, then clone your fork locally.

```bash
# Step 1 — fork on GitHub
# github.com → original repo → Fork button (top right)
# GitHub creates: github.com/AkhilTejaDoosari/webstore

# Step 2 — clone your fork
git clone https://github.com/AkhilTejaDoosari/webstore.git
cd webstore

# Step 3 — add the original as upstream
git remote add upstream https://github.com/original-owner/webstore.git

# Step 4 — create a feature branch
git switch -c fix/webstore-api-timeout

# Step 5 — make changes and commit
git commit -m "fix: increase api timeout from 5s to 30s"

# Step 6 — push to your fork
git push origin fix/webstore-api-timeout

# Step 7 — open a PR from your fork to the original
# github.com → your fork → Compare & pull request
# Base repository: original-owner/webstore  base: main
# Head repository: AkhilTejaDoosari/webstore  compare: fix/webstore-api-timeout
```

---

## 7. Keeping your fork in sync

While you work, the original repo keeps moving forward. Before submitting a PR — and regularly while working — pull in those changes so your fork does not fall behind.

```bash
# Fetch new commits from the original repo (not your fork)
git fetch upstream

# See what is new on upstream that you do not have
git log --oneline main..upstream/main

# Merge upstream into your local main
git switch main
git merge upstream/main

# Push the updated main to your fork on GitHub
git push origin main

# Rebase your feature branch on top of the updated main
git switch fix/webstore-api-timeout
git rebase main
```

If you do not stay in sync, your PR will have merge conflicts and reviewers will ask you to fix them before approving.

---

## 8. What makes a good pull request

The PR is what your teammates read when reviewing your work. A good PR makes review fast and approval easy.

**Good PR:**
- Title matches commit convention: `feat: add pagination to products endpoint`
- Description explains what changed and why — not just "updated server.js"
- Focused on one logical change — one feature, one fix, not five things
- Links to the related issue if one exists
- Small enough to review in one sitting

**Poor PR:**
- Title: "changes" or "WIP" or "stuff"
- Touches ten files with no common theme
- No description
- So large that reviewers skim it

The single biggest lever for fast approvals: keep PRs small. One logical change per PR. If a feature is large, break it into multiple PRs that each stand on their own.

---

## On the webstore

A second developer — charan — joins the team and needs to add a product search endpoint. They clone the repo, build in a branch, and open a PR.

```bash
# Charan clones the webstore
git clone https://github.com/AkhilTejaDoosari/webstore.git
cd webstore

# Confirm the full history came down
git log --oneline
# a1b2c3d feat: add database failover config
# c8d21fa logs: add initial server startup entry
# ...

# Create a feature branch
git switch -c feature/product-search

# Build the feature
vim api/server.js
git add api/server.js
git commit -m "feat: add product search endpoint with query param"

# Before pushing, fetch to check if main moved
git fetch origin
git log --oneline main..origin/main
# (empty — main has not moved, safe to push)

# Push the feature branch
git push origin feature/product-search

# Open PR on GitHub
# Base: main  ←  Compare: feature/product-search

# After PR is merged, clean up
git switch main
git pull
git branch -d feature/product-search
```

File 05 picks up from here — what happens when a commit needs to be undone after it has already been pushed.

---

## What breaks

| Symptom | Cause | Fix |
|---|---|---|
| `git push` rejected — "no upstream branch" | Feature branch not yet on remote | `git push origin <branch-name>` to push it for the first time |
| PR shows merge conflicts | Your branch is behind main — both changed same files | `git fetch origin`, `git rebase origin/main` on your branch, fix conflicts, push |
| `git pull` has unexpected merges | Used pull when you should have fetched first | Use `git fetch` + inspect + `git merge` separately in sensitive situations |
| Fork is behind original by many commits | Did not sync upstream regularly | `git fetch upstream`, `git merge upstream/main`, `git push origin main` |
| Branch deleted on GitHub after merge, still local | Normal — GitHub deletes remote branch after merge | `git branch -d <branch>` locally to match |
| `git remote add upstream` fails "remote already exists" | Already added it before | `git remote -v` to confirm it is correct, no action needed |

---

## Daily commands

| Command | What it does |
|---|---|
| `git clone <url>` | Download full repository to local machine |
| `git remote -v` | List all remotes with their URLs |
| `git remote add upstream <url>` | Add the original repo as upstream remote |
| `git fetch origin` | Download remote changes without merging |
| `git diff main origin/main` | See what is on remote that is not in local main |
| `git push origin <branch>` | Push a branch to remote |
| `git pull` | Fetch and merge from current tracking remote |
| `git fetch upstream` | Fetch new commits from the original repo |
| `git merge upstream/main` | Merge upstream changes into current branch |
| `git branch -d <branch>` | Delete a local branch after it is merged |

---

→ **Interview questions for this topic:** [99-interview-prep → Contribute](../99-interview-prep/README.md#contribute)

---
# FILE: 02. Git & GitHub – Version Control/05-undo-recovery/README.md
---

[Home](../README.md) |
[Foundations](../01-foundations/README.md) |
[Stash & Tags](../02-stash-tags/README.md) |
[History & Branching](../03-history-branching/README.md) |
[Contribute](../04-contribute/README.md) |
[Undo & Recovery](../05-undo-recovery/README.md) |
[Interview](../99-interview-prep/README.md)

---

# Git Undo & Recovery

> **Depends on:** [04 Contribute](./04-contribute/README.md) — you need to understand pushed vs unpushed commits before choosing a recovery tool
> **Used in production when:** Wrong commit message, forgot to stage a file, committed a secret, bad commit already pushed and others may have pulled it, hard reset went too far

---

## Table of Contents

- [What this is](#what-this-is)
- [1. The mental model — where did the mistake happen](#1-the-mental-model--where-did-the-mistake-happen)
- [2. amend — fix the last commit before it leaves](#2-amend--fix-the-last-commit-before-it-leaves)
- [3. revert — undo a pushed commit safely](#3-revert--undo-a-pushed-commit-safely)
- [4. reset — move the pointer back](#4-reset--move-the-pointer-back)
- [5. reflog — recover anything](#5-reflog--recover-anything)
- [6. The decision table](#6-the-decision-table)
- [On the webstore](#on-the-webstore)
- [What breaks](#what-breaks)
- [Daily commands](#daily-commands)

---

## What this is

Mistakes happen. You commit the wrong file. You write a bad commit message. You reset too far and lose commits. You delete a branch before merging it. Git has tools for all of these — but the right tool depends on two things: where in the workflow the mistake happened, and whether the commit has been pushed. Using the wrong tool creates more problems than it solves.

---

## 1. The mental model — where did the mistake happen

Before reaching for any recovery command, identify where the mistake is:

```
Working dir  →  Staging area  →  Local commit  →  Pushed to remote
   edit           git add          git commit         git push
```

| Where the mistake is | What happened | Tool |
|---|---|---|
| Working directory | Edited a file, want to discard changes | `git restore <file>` |
| Staging area | Staged a file you did not mean to | `git restore --staged <file>` |
| Last local commit — not pushed | Wrong message, wrong files, forgot a file | `git commit --amend` |
| Older local commits — not pushed | Several bad commits | `git reset` |
| Pushed commit — others may have pulled | Bad commit in shared history | `git revert` |
| Lost commits after reset | Thought they were gone | `git reflog` |
| Deleted a branch | Before it was merged | `git reflog` + `git branch` |

**The critical question before every recovery:** has this commit been pushed?
- Not pushed — you can rewrite history. Use `amend` or `reset`.
- Already pushed — you cannot rewrite shared history. Use `revert`.

---

## 2. amend — fix the last commit before it leaves

`amend` rewrites the most recent commit. It changes the commit hash — Git treats it as an entirely new commit. Only safe on commits that have not been pushed.

**Fix a typo in the commit message:**

```bash
git commit -m "feat: add paginaton to products endpoint"  # typo

# -m replaces the old message entirely
git commit --amend -m "feat: add pagination to products endpoint"
# old commit replaced — the typo never existed in history
```

**Add a file you forgot to include:**

```bash
git commit -m "feat: add pagination to products endpoint"
# realise tests/pagination.test.js was not staged

git add tests/pagination.test.js
# --no-edit keeps the existing commit message unchanged
git commit --amend --no-edit
# file added to existing commit — no new commit created
```

**Remove a file you accidentally included:**

```bash
# you committed webstore.conf but it should not be in this commit
git reset HEAD^ -- config/webstore.conf   # unstage it from the commit
git commit --amend --no-edit              # recommit without it
```

**The rule:** only amend before pushing. If you amend a pushed commit and force push, you rewrite shared history and cause problems for anyone who already pulled.

---

## 3. revert — undo a pushed commit safely

`revert` creates a new commit that exactly reverses the changes of a specific earlier commit. The original bad commit stays in history — nothing is erased. This is the safe undo for anything already pushed.

```bash
# Find the bad commit
git log --oneline
# d4e8f21 feat: add pagination   ← broke the API
# c8d21fa config: update nginx
# b71e3a2 feat: initialize project

# Revert it — creates a new commit that undoes d4e8f21
# --no-edit uses the auto-generated "Revert 'feat: add pagination'" message
git revert d4e8f21 --no-edit

git log --oneline
# a91b23c Revert "feat: add pagination"   ← new commit, undoes the bad one
# d4e8f21 feat: add pagination            ← still in history, untouched
# c8d21fa config: update nginx

# Push the revert — safe, adds to history rather than rewriting it
git push
```

**If the revert produces conflicts:**

```bash
git revert d4e8f21
# CONFLICT — fix it manually
git add <file>
git revert --continue
```

**Revert the most recent commit:**

```bash
git revert HEAD --no-edit
```

---

## 4. reset — move the pointer back

`reset` moves HEAD and the current branch pointer to a different commit. Unlike `revert` it does not create a new commit — it rewrites history. Only safe on commits that have not been pushed.

**Three modes:**

```
--soft   HEAD moves back. Changes from undone commits stay staged.
--mixed  HEAD moves back. Changes are unstaged (in working dir). DEFAULT.
--hard   HEAD moves back. Changes are permanently erased. No recovery without reflog.
```

```bash
git log --oneline
# d4e8f21 bad commit 2   ← HEAD is here
# c8d21fa bad commit 1
# b71e3a2 good state     ← want to return here

# --soft: undo commits, keep all changes staged and ready to recommit
git reset --soft b71e3a2

# --mixed: undo commits, changes are in working dir but unstaged
git reset --mixed b71e3a2

# --hard: undo commits and permanently erase all changes
git reset --hard b71e3a2
```

**Relative notation — no hash needed:**

```bash
# ~1 = go back 1 commit, ~3 = go back 3 commits
git reset --soft HEAD~1
git reset --hard HEAD~3
```

**When to use each:**

`--soft` — you want to undo the commit but keep the work staged. You are going to recommit it differently or split it into separate commits.

`--mixed` — you want to undo the commit and the staging. Work stays in your files so you can review and re-stage selectively.

`--hard` — you want to completely discard the commits and everything in them. Use with care — this is the one that loses work. Reflog can recover it within 90 days.

**Never reset commits that have been pushed to a shared branch.** If you reset and force push, everyone who pulled those commits will have a diverged history.

---

## 5. reflog — recover anything

`reflog` is Git's flight recorder. It records every time HEAD moved — every commit, checkout, reset, merge, rebase. Even after a `--hard` reset or a deleted branch, commits still exist in Git's object store for 90 days. Reflog is how you find them.

```bash
git reflog
# e56ba1f HEAD@{0}: commit: fix api timeout
# d4e8f21 HEAD@{1}: commit: add pagination
# 9a9add8 HEAD@{2}: reset: moving to HEAD~1
# c8d21fa HEAD@{3}: commit: update nginx config
# b71e3a2 HEAD@{4}: commit: initialize project
```

Each line is one HEAD movement. `HEAD@{n}` is shorthand for the state HEAD was in n steps ago.

**Recover commits lost after a hard reset:**

```bash
# You ran git reset --hard and lost d4e8f21
git reflog
# find d4e8f21 in the list

git reset --hard d4e8f21
# commits are back
```

**Recover a deleted branch:**

```bash
# You deleted feature/webstore-pagination before merging
git branch -D feature/webstore-pagination

git reflog
# 3f8c2a1 HEAD@{2}: commit: feat: add pagination query params  ← last commit on that branch

# Recreate the branch at that commit
git branch feature/webstore-pagination 3f8c2a1
git switch feature/webstore-pagination
# branch is back with all its commits
```

**The key insight:** Git almost never truly deletes commits. When you `reset --hard` or delete a branch, commits lose their reference but still exist in the object store. Reflog gives you those references back. As long as you act within 90 days, recovery is almost always possible.

---

## 6. The decision table

| Situation | Right tool | Wrong tool |
|---|---|---|
| Typo in last commit message, not pushed | `git commit --amend` | `git revert` — unnecessary new commit |
| Forgot to stage a file, last commit not pushed | `git add <file>` + `git commit --amend --no-edit` | New commit just for a tiny fix |
| Bad commit already pushed, others may have pulled | `git revert <hash>` | `git reset --hard` + force push — rewrites shared history |
| Several bad local commits, not pushed, keep the work | `git reset --soft HEAD~N` | `git reset --hard` — erases the work |
| Several bad local commits, not pushed, discard everything | `git reset --hard HEAD~N` | `git revert` — unnecessary when history is not shared |
| Lost commits after hard reset | `git reflog` + `git reset --hard <hash>` | Panicking — reflog almost always has it |
| Deleted a branch before merging | `git reflog` + `git branch <n> <hash>` | Accepting the loss |

**The golden rule: Revert for shared history. Reset for local cleanup. Reflog for recovery.**

---

## On the webstore

Three real mistakes — one for each recovery tool.

```bash
# ── Scenario 1: amend ───────────────────────────────────────────────
# Bad commit message, not pushed yet
git commit -m "fix webstore thing"

git commit --amend -m "fix: correct db_port in webstore.conf — was 27017, should be 5432"

git log --oneline
# b3c4d5e fix: correct db_port in webstore.conf — was 27017, should be 5432


# ── Scenario 2: revert ──────────────────────────────────────────────
# Pushed a commit that broke the API — charan already pulled it
git log --oneline
# d4e8f21 feat: add pagination   ← broke things, already pushed

git revert d4e8f21 --no-edit
git push

git log --oneline
# a91b23c Revert "feat: add pagination"
# d4e8f21 feat: add pagination
# c8d21fa config: update nginx


# ── Scenario 3: reflog ──────────────────────────────────────────────
# Ran hard reset by mistake, lost two commits
git reset --hard HEAD~2
# oh no — lost the last two commits

git reflog
# b71e3a2 HEAD@{0}: reset: moving to HEAD~2
# d4e8f21 HEAD@{1}: commit: feat: add pagination
# c8d21fa HEAD@{2}: commit: config: update nginx   ← this is where we want to be

git reset --hard d4e8f21
git log --oneline
# d4e8f21 feat: add pagination   ← commits are back
# c8d21fa config: update nginx
```

---

## What breaks

| Symptom | Cause | Fix |
|---|---|---|
| `git commit --amend` on a pushed commit causes problems for teammates | Amend rewrites the hash — their local history diverges | Never amend pushed commits. If already done, communicate with the team and they need to `git pull --rebase` |
| `git revert` produces a conflict | The commit being reverted touched a file that was later changed by another commit | Fix the conflict manually, `git add <file>`, `git revert --continue` |
| `git reset --hard` lost work that was not in a commit | Hard reset erases uncommitted changes permanently | Use `git stash` before hard resets when you have work in progress |
| `git reflog` shows nothing after a long time | Reflog entries expire after 90 days | Commit work regularly — reflog is not a permanent backup |
| Force push rejected — "protected branch" | Main branch is protected on GitHub | You should not be force pushing to main — use revert instead |

---

## Daily commands

| Command | What it does |
|---|---|
| `git restore <file>` | Discard working directory changes to a file |
| `git restore --staged <file>` | Unstage a file back to working directory |
| `git commit --amend -m "message"` | Fix the last commit message — not pushed only |
| `git commit --amend --no-edit` | Add staged changes to last commit — not pushed only |
| `git revert <hash>` | Create new commit that undoes a specific commit — safe for pushed |
| `git revert HEAD --no-edit` | Revert the most recent commit |
| `git reset --soft HEAD~1` | Undo last commit, keep changes staged |
| `git reset --hard HEAD~1` | Undo last commit and erase all changes |
| `git reflog` | Show full history of every HEAD movement |
| `git branch <name> <hash>` | Recreate a deleted branch from a reflog hash |

---

→ **Interview questions for this topic:** [99-interview-prep → Undo & Recovery](../99-interview-prep/README.md#undo-and-recovery)

---
# FILE: 02. Git & GitHub – Version Control/99-interview-prep/README.md
---

[Home](../README.md) |
[Foundations](../01-foundations/README.md) |
[Stash & Tags](../02-stash-tags/README.md) |
[History & Branching](../03-history-branching/README.md) |
[Contribute](../04-contribute/README.md) |
[Undo & Recovery](../05-undo-recovery/README.md) |
[Interview](../99-interview-prep/README.md)

---

# Interview Prep — Git

> Read the notes files first. Come here the day before an interview.
> Each answer is 30 seconds. No more. That is what interviewers want.

---

## Table of Contents

- [Git Foundations](#git-foundations)
- [Stash and Tags](#stash-and-tags)
- [History and Branching](#history-and-branching)
- [Contribute](#contribute)
- [Undo and Recovery](#undo-and-recovery)

---

## Git Foundations

**What is Git and why does every DevOps tool depend on it?**

Git is a distributed version control system — it tracks every change to a project as a permanent snapshot. In DevOps, it is the source of truth that everything downstream reads from. GitHub Actions triggers on Git commits. Docker images are tagged with Git commit SHAs. Terraform state is version controlled. ArgoCD watches a Git repo and deploys whatever is in it. Without Git, none of those tools know what to build or deploy.

**What is the difference between the working directory, staging area, and local repo?**

The working directory is where you edit files — what you see in your editor. The staging area is where you explicitly choose what goes into the next commit — a holding area where you decide exactly what this snapshot contains. The local repo is the committed history — permanent, immutable, stored in `.git/`. The three-step flow is: edit in working dir, `git add` to staging, `git commit` to repo.

**Why does the staging area exist?**

Without a staging area, every `git commit` would include everything you touched since the last commit. The staging area lets you commit partial work — you edited five files but only three are ready, so you stage those three as one logical change and leave the other two in progress. It gives you control over exactly what each commit contains.

**What does `git init` actually do?**

It creates a hidden `.git/` folder inside the directory. That folder IS the entire repository — every commit, every branch, every tag is stored there. Before `git init`, the directory is just files. After it, the directory has version control. The `.git/` folder is what makes the difference.

**What belongs in `.gitignore` and why must it be created before the first commit?**

Secrets and credentials (`.env`, API keys), build output (`dist/`, `build/`), runtime data (`*.log`), dependencies (`node_modules/`), and infrastructure state files (`*.tfstate`). It must be created before the first `git add .` because Git history is immutable — if you commit a secret, it is in the history permanently even after you delete the file. Anyone who clones the repo can access it by looking at the history.

---

## Stash and Tags

**What is `git stash` and when do you use it?**

Stash saves your in-progress changes to a temporary shelf and gives you back a clean working directory — without creating a commit. You use it when you are mid-feature and something urgent comes in that requires a clean state to fix. After fixing, `git stash pop` restores your changes exactly where you left them. Stash is local, expires after 90 days, and is not a substitute for branches on work lasting more than a day.

**What is the difference between `git stash pop` and `git stash apply`?**

Both apply the stash to your working directory, but `pop` removes it from the stash stack after applying and `apply` leaves it on the stack. Use `pop` for the normal restore workflow. Use `apply` when you want to apply the same stash to multiple branches without losing it from the stack.

**What does `git stash -u` do and when do you need it?**

`-u` stands for `--include-untracked`. By default `git stash` only saves tracked files — files Git already knows about. New files you created but have not yet run `git add` on are untracked and left behind. `git stash -u` includes those new files in the stash.

**What is the difference between a lightweight tag and an annotated tag?**

A lightweight tag is just a pointer to a commit — a name with no metadata. An annotated tag contains a pointer plus the tagger's identity, a date, and a message. Always use annotated tags (`git tag -a`) for releases — they appear correctly on GitHub's releases page, carry your identity, and are what CI/CD pipelines expect when they trigger on a tagged push.

**Why are tags not pushed automatically with `git push`?**

By design — tags are permanent markers and pushing them to a shared remote is an intentional act. A `git push` sends your commits but not your tags. You push a tag explicitly with `git push origin v1.0` or push all tags at once with `git push --tags`. This prevents accidentally publishing tags that were meant to be local.

---

## History and Branching

**What is a branch in Git?**

A branch is a lightweight pointer to a commit. When you create a branch, Git creates a new pointer at your current commit. When you make commits on that branch, only that pointer moves forward — other branches stay exactly where they were. This is why branches are cheap to create — Git is not copying files, it is just creating a new reference.

**What is HEAD in Git?**

HEAD is a pointer that tells Git which branch — and therefore which commit — you are currently on. When you switch branches, HEAD moves. When you make a commit, HEAD's branch pointer moves forward to the new commit. When you see "detached HEAD" in the terminal, it means HEAD is pointing directly at a commit instead of a branch.

**What is the difference between a fast-forward merge and a 3-way merge?**

A fast-forward merge happens when the base branch has not moved since the feature branch was created — Git simply moves the branch pointer forward, no merge commit is created, history stays linear. A 3-way merge happens when both branches have moved since they diverged — Git creates a merge commit that combines both lines of history. The 3-way merge requires three commits to resolve: the common ancestor plus the two branch tips.

**What is the golden rule of rebase?**

Never rebase commits that have already been pushed to a shared branch. Rebase rewrites commit hashes — if someone else already pulled those commits, their local history now diverges from yours and they will have conflicts when they try to push or pull. Rebase is safe on a local feature branch you have not pushed yet, or on a personal branch nobody else has pulled.

**What is the difference between `git merge` and `git rebase`?**

Both integrate changes from one branch into another. Merge creates a merge commit that preserves the full branch history — you can see when the branch diverged and merged. Rebase replays your commits on top of another branch tip, creating new commit hashes and a linear history with no merge commit. Use merge to bring completed features into main. Use rebase to update a feature branch with the latest main before merging.

---

## Contribute

**What is the difference between `git fetch` and `git pull`?**

`git fetch` downloads new commits from the remote into your local repo but does not touch your working directory or current branch — your files are unchanged. `git pull` is `git fetch` plus `git merge` in one command — it downloads and immediately merges into your current branch. Use `git fetch` when you want to see what changed before merging. Use `git pull` in your daily workflow when you just want to be up to date.

**What is the difference between `origin` and `upstream`?**

`origin` is the remote you cloned from — your team's repo or your fork. You push to origin and open PRs against it. `upstream` is the original repo you forked from in an open-source workflow. You pull from upstream to stay in sync with what the project maintainers are doing, but you never push to it directly — you only have read access.

**What is a pull request and why does it exist?**

A pull request is a proposal to merge one branch into another, with a built-in code review step before the merge happens. Before code reaches main — the production branch — a teammate reads the diff, asks questions, catches bugs, and approves. The PR is how teams prevent mistakes from reaching production. It also creates a documented record of what changed, why, and who approved it.

**Walk me through the feature branch PR workflow.**

Start from latest main with `git pull`. Create a feature branch with `git switch -c feature/name`. Make commits on the branch. Push it to GitHub with `git push origin feature/name`. Open a pull request on GitHub — base is main, compare is the feature branch. A teammate reviews and approves. Merge happens on GitHub. Clean up locally: `git switch main`, `git pull`, `git branch -d feature/name`.

**How do you keep a fork in sync with the original repo?**

Add the original repo as a second remote called `upstream` with `git remote add upstream <url>`. Run `git fetch upstream` to pull in new commits without merging. Switch to main and `git merge upstream/main` to integrate them. Push the updated main to your fork with `git push origin main`. Then rebase your feature branch on top of the updated main.

---

## Undo and Recovery

**What is the critical question before choosing a recovery command?**

Has the commit been pushed? If not pushed — you can rewrite history with `amend` or `reset`. If already pushed — you cannot rewrite shared history because others may have pulled it. Use `revert` instead, which adds a new commit that undoes the bad one without touching history.

**What is the difference between `git revert` and `git reset`?**

`git revert` creates a new commit that exactly reverses a specific earlier commit — the original commit stays in history, a new one records the reversal. It is safe on pushed commits because it adds to history rather than rewriting it. `git reset` moves HEAD back to a previous commit, removing commits from history. It is only safe on local commits that have not been pushed.

**What are the three modes of `git reset` and when do you use each?**

`--soft` undoes the commit but keeps all changes staged and ready to recommit — use when you want to redo the commit differently. `--mixed` (the default) undoes the commit and unstages the changes — they are in your working directory for you to review and re-stage selectively. `--hard` undoes the commit and permanently erases all changes — use when you want to completely discard the work. Hard is the dangerous one.

**What is `git reflog` and why is it the last line of defense?**

`reflog` records every time HEAD moved — every commit, checkout, reset, merge, rebase. Even after a `--hard` reset or deleting a branch, the commits still exist in Git's object store for 90 days. `reflog` shows you the hash of every state HEAD was in. If you lost commits after a reset or deleted a branch, find the hash in reflog and `git reset --hard <hash>` or recreate the branch with `git branch <n> <hash>`.

**You committed a secret to a public GitHub repo. What do you do?**

First — rotate the secret immediately. Delete the API key, change the password, invalidate the token. Anyone who has already seen the repo may have the credential. Second — remove it from history using `git filter-branch` or the BFG Repo Cleaner, then force push. Third — add it to `.gitignore` so it cannot be committed again. The critical point: deleting the file and pushing a new commit is not enough. The secret is still in the commit history and anyone who clones the repo can find it.

---
# FILE: 02. Git & GitHub – Version Control/README.md
---

<p align="center">
  <img src="../../assets/git-banner.svg" alt="git and github" width="100%"/>
</p>

[← devops-runbook](../../README.md) |
[Foundations](./01-foundations/README.md) |
[Stash & Tags](./02-stash-tags/README.md) |
[History & Branching](./03-history-branching/README.md) |
[Contribute](./04-contribute/README.md) |
[Undo & Recovery](./05-undo-recovery/README.md) |
[Interview](./99-interview-prep/README.md)

---

Version control, branching, collaboration, and recovery — built around one real project from first commit to open-source contribution workflow.

---

## Why Git — and Why GitHub

Git is not optional in this stack. Every other tool in this runbook depends on it. GitHub Actions triggers on Git commits. Docker images are tagged with Git commit SHAs. Terraform state is version controlled. ArgoCD watches a Git repo and deploys whatever is in it. Git is the source of truth that everything else reads from.

GitHub is the platform because it is where the jobs are. GitHub Actions, pull requests, branch protection rules, and the open-source ecosystem all live here. GitLab and Bitbucket use the same Git — different UI, smaller footprint in DevOps hiring.

---

## Prerequisites

**Complete first:** [01. Linux – System Fundamentals](../01.%20Linux%20–%20System%20Fundamentals/README.md)

You need to be comfortable in the terminal — navigating directories, editing files with vim, and running commands — before Git will make sense as a tool. The webstore directory you built in Linux becomes the first Git repository you initialize here.

---

## The Architecture

Every Git command is a movement between zones. Know the zones — every command makes sense.

```
  YOUR MACHINE
  ───────────────────────────────────────────────────────────────────────────────

  ┌─────────────────┐      ┌─────────────────┐      ┌──────────────────────────┐
  │                 │      │                 │      │                          │
  │  Working        │      │  Staging area   │      │  Local repo  (.git/)     │
  │  directory      │      │  (.git/index)   │      │                          │
  │                 │      │                 │      │  • full commit history   │
  │  your files     │      │  files chosen   │      │  • all branches          │
  │  what you edit  │      │  for the next   │      │  • all tags              │
  │                 │      │  commit         │      │  • works fully offline   │
  └─────────────────┘      └─────────────────┘      └──────────────────────────┘
          │                        │                            │
          │  ── git add ────────►  │                            │
          │  ◄─ git restore──────  │                            │
          │  ────staged ──────────►  (unstage back)             │
          │                        │  ── git commit ──────────► │
          │                        │  ◄─ git reset ──────────── │
          │                        │     (soft/mixed/hard)      │
          │                                                     │
          │  ◄─────────────── git checkout / git switch ─────── │
          │  ◄─────────────── git restore <file> ────────────── │


  WHAT EACH COMMAND SEES
  ─────────────────────────────────────────────────────────────────────────────
  git status        working dir + staging area   never sees the remote
  git log           local repo commits           stale until git fetch
  git diff          working dir  vs  staging
  git diff --staged staging      vs  last commit
  git diff HEAD     working dir  vs  last commit


  BRANCHES AND HEAD  (inside the local repo)
  ─────────────────────────────────────────────────────────────────────────────

  a3f92c1 ◄── b71e3a2 ◄── c8d21fa   ←  main  ←  HEAD
                                ↑
               every commit points back to its parent

  main branch: a3f92c1 ◄── b71e3a2 ◄── c8d21fa  ←  HEAD
                                              ↘
  feature branch:                               d1a3c22 ◄── e8f90ab  ←  HEAD


  GITHUB  (the remote)
  ───────────────────────────────────────────────────────────────────────────────

  ┌──────────────────────────────────────────────────────────────────────────────┐
  │  origin   →  github.com/AkhilTejaDoosari/webstore                            │
  │                                                                              │
  │  your fork or your team repo — you push here, PRs open here                  │
  │  GitHub Actions triggers on every push to main                               │
  │  ArgoCD watches main — deploys to cluster when it changes                    │
  └──────────────────────────────────────────────────────────────────────────────┘
  ┌──────────────────────────────────────────────────────────────────────────────┐
  │  upstream →  github.com/original-owner/webstore                              │
  │                                                                              │
  │  the repo you forked from — pull to stay in sync, never push to it           │
  └──────────────────────────────────────────────────────────────────────────────┘

  local repo  ──── git push ────────────────────────────────────► origin
  local repo  ◄─── git fetch ───────────────────────────────────  origin / upstream
  working dir ◄─── git pull  (fetch + merge) ───────────────────  origin
  all zones   ◄─── git clone (first time only) ─────────────────  origin


  THE DAILY WORKFLOW
  ─────────────────────────────────────────────────────────────────────────────
  git status  →  git add .  →  git commit -m ""  →  git push
```

---

## Where You Take the Webstore

You arrive at Git with the webstore living as files on a Linux server — organized, configured, permissions set. No history. No version control. If something breaks, there is no rollback.

You leave Git with the webstore as a fully version-controlled project on GitHub — every change tracked, every decision recorded, the first release tagged as `v1.0`, and a contribution workflow in place so a second developer can work on it without stepping on your changes.

That is the state Docker picks up from. You do not containerize an unversioned project — you containerize a project with a clean commit history and a tagged release.

---

## Why Git, Not Something Else

There is no real alternative at this level. SVN is legacy. Mercurial is niche. Git won and the entire DevOps ecosystem is built around it. The question is not git vs something else — it is GitHub vs GitLab vs Bitbucket, and GitHub has the largest ecosystem, the most integrations, and the most job postings.

---

## Files — Read in This Order

| # | File | What it covers | After reading this you can |
|---|---|---|---|
| 01 | [Foundations](./01-foundations/README.md) | init, config, three states, commit, .gitignore, remote, push | Start a repo from scratch, make commits, push to GitHub |
| 02 | [Stash & Tags](./02-stash-tags/README.md) | stash workflow, annotated tags, releases | Pause mid-work cleanly, tag v1.0, mark stable releases |
| 03 | [History & Branching](./03-history-branching/README.md) | git log, branches, merge types, conflicts, rebase | Read project history, build features in isolation, merge without breaking things |
| 04 | [Contribute](./04-contribute/README.md) | clone, remotes, PR workflow, fork, upstream sync | Work on a team repo, open PRs, contribute to open source |
| 05 | [Undo & Recovery](./05-undo-recovery/README.md) | amend, revert, reset, reflog | Fix any mistake — wrong commit, bad push, deleted branch |

---

## What You Can Do After This

- Track and version any project with confidence
- Write clean commit history that teammates can read
- Create and merge branches without breaking anything
- Resolve merge conflicts without panicking
- Rebase feature branches to keep history linear
- Recover from any mistake using reflog
- Contribute to team repos and open-source projects via PRs
- Tag releases that CI/CD pipelines can reference

---

## How to Use This

Read files in order. Each one builds on the previous.
Do the "On the webstore" section in every file before moving on.
The webstore must be in the state described at the end of each file.

---

## What Comes Next

→ [03. Networking – Foundations](../03.%20Networking%20–%20Foundations/README.md)

Git gives you version control. Networking gives you the foundation to understand how Docker, Kubernetes, and AWS move data — before those tools make any of it look like magic.
