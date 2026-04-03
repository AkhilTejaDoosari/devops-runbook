[🏠 Home](../README.md) | 
[Foundations](../01-foundations/README.md) | 
[Stash & Tags](../02-stash-tags/README.md) | 
[History & Branching](../03-history-branching/README.md) | 
[Contribute](../04-contribute/README.md) | 
[Undo & Recovery](../05-undo-recovery/README.md)

# Git Foundations  
> From Local Control to Remote Collaboration

---

## Table of Contents
- [0. Introduction – Why Version Control Matters](#0-introduction--why-version-control-matters)  
- [1. Installing Git – Setting Up Your Environment](#1-installing-git--setting-up-your-environment)  
- [2. Git Config – Defining Your Identity](#2-git-config--defining-your-identity)  
- [3. Creating a Repository – The Project's Birth](#3-creating-a-repository--the-projects-birth)  
- [4. Understanding Tracked vs Untracked Files](#4-understanding-tracked-vs-untracked-files)  
- [5. The Staging Environment – The Waiting Room](#5-the-staging-environment--the-waiting-room)  
- [6. Commit – Capturing Your Project's Timeline](#6-commit--capturing-your-projects-timeline)  
- [7. .gitignore – Telling Git What to Ignore](#7-gitignore--telling-git-what-to-ignore)
- [8. Git Workflow – From Edit to Push](#8-git-workflow--from-edit-to-push)  
- [9. Best Practices & Troubleshooting](#9-best-practices--troubleshooting)

---

<details>
<summary><strong>0. Introduction – Why Version Control Matters</strong></summary>

Before Git, developers kept zipping folders as  
`project_final.zip → project_final_v2.zip → final_realfinal.zip`.  
Collaboration was chaos, and history was fragile.

**Git** changed that — it became a *time machine* for code.  
It tracks *what changed, when, and by whom* — and lets teams roll back or branch without fear.

In DevOps, Git is the **source of truth**.  
Tools like GitHub Actions, Docker, and Terraform rely on it to detect, version, and automate infrastructure.

```
Edit → Stage → Commit → Push → Collaborate
```

Git works locally on your machine, but can sync with **remote repositories** on GitHub, GitLab, or Bitbucket.

</details>

---

<details>
<summary><strong>1. Installing Git – Setting Up Your Environment</strong></summary>

### macOS
```bash
brew install git
```

### Linux (Ubuntu)
```bash
sudo apt-get install git
```

### Windows
Download from [git-scm.com](https://git-scm.com) and run the installer.
This also installs **Git Bash** — a terminal that supports Unix-style commands.

### Verify installation
```bash
git --version
```

### Set your default editor
```bash
git config --global core.editor "code --wait"   # VS Code
git config --global core.editor "vim"           # Vim
```

---

**Common Installation Issues**

| Problem | Fix |
|---|---|
| `git: command not found` | Add Git to PATH and reopen terminal |
| Permission denied | Run as Administrator or use `sudo` |
| Wrong version | Update using package manager or reinstall |

</details>

---

<details>
<summary><strong>2. Git Config – Defining Your Identity</strong></summary>

Before committing, Git must know who you are.
Each commit carries your name and email — your *digital signature.*

### Set Global Identity

```bash
git config --global user.name "Your Name"
git config --global user.email "your@email.com"
```

### Check Your Settings

```bash
git config --list
```

---

### Understanding Config Levels

| Level | Flag | Location | Affects |
|---|---|---|---|
| **System** | `--system` | `/etc/gitconfig` | All users |
| **Global** | `--global` | `~/.gitconfig` | Your user |
| **Local** | `--local` | `.git/config` | Current repo only |

**Priority:** `Local → Global → System`

Use local config to override identity for a specific project:
```bash
git config --local user.email "work@company.com"
```

</details>

---

<details>
<summary><strong>3. Creating a Repository – The Project's Birth</strong></summary>

A **repository (repo)** is a folder Git watches for changes.

```bash
mkdir webstore
cd webstore
git init
```

This creates a hidden `.git/` folder containing all version history.

```bash
ls -a
# .  ..  .git
```

You now have an empty repository ready to track files.

</details>

---

<details>
<summary><strong>4. Understanding Tracked vs Untracked Files</strong></summary>

A new file you create is **untracked** until you tell Git to monitor it.

```bash
echo "db_host=webstore-db" > webstore.conf
git status
```

Output:
```
Untracked files:
  webstore.conf
```

- **Untracked** — exists in your folder but Git is ignoring it
- **Tracked** — Git is monitoring it for changes

To begin tracking:
```bash
git add webstore.conf
```

</details>

---

<details>
<summary><strong>5. The Staging Environment – The Waiting Room</strong></summary>

The **staging area** is a buffer between your edits and permanent history.
Think of it as a checklist before committing — you decide exactly what goes into each snapshot.

| Command | Meaning |
|---|---|
| `git add <file>` | Stage a specific file |
| `git add .` | Stage all changes |
| `git status` | Check what's staged or not |
| `git restore --staged <file>` | Unstage a file |

Example:
```bash
git add webstore.conf
git status
```

Output:
```
Changes to be committed:
  new file: webstore.conf
```

If you added the wrong file:
```bash
git restore --staged webstore.conf
```

</details>

---

<details>
<summary><strong>6. Commit – Capturing Your Project's Timeline</strong></summary>

A **commit** is a snapshot of your staged files — a permanent save point in history.

```bash
git commit -m "add webstore config"
```

Each commit includes your name, email, date, message, and a unique **commit hash**.

### What's a Commit Hash?

Every commit is identified by a SHA-1 hash:
```
1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b
```

Short form (first 7 chars) is enough for most operations:
```
1a2b3c4
```

### View History

```bash
git log --oneline
```

Example:
```
a12f45c add webstore config
b78d23d add dockerfile
c91e7ef initial commit
```

### Amend Last Commit (before pushing)

```bash
git commit --amend -m "add webstore config file"
```

</details>

---

<details>
<summary><strong>7. .gitignore – Telling Git What to Ignore</strong></summary>

`.gitignore` is a file in your repo root that tells Git which files and folders to never track.

**Why it matters:**
- Keeps secrets (`.env`, credentials) out of your repo
- Avoids committing build artifacts and dependencies
- Keeps `git status` clean so you only see files that actually matter
- Prevents breaking layer caching in Docker builds (covered in Docker notes)

### Create a .gitignore

```bash
touch .gitignore
```

### Common entries for a DevOps project

```
# Dependencies
node_modules/

# Environment files — never commit secrets
.env
.env.local

# Build output
dist/
build/

# OS files
.DS_Store
Thumbs.db

# Logs
*.log

# Terraform state — contains sensitive data
*.tfstate
*.tfstate.backup
.terraform/

# Docker
*.tar
```

### How it works

```bash
echo "SECRET_KEY=abc123" > .env
git status
```

Without `.gitignore`:
```
Untracked files:
  .env           ← dangerous — would be committed
```

After adding `.env` to `.gitignore`:
```bash
echo ".env" >> .gitignore
git status
```

```
Untracked files:
  .gitignore     ← only the ignore file shows, not the secret
```

### Ignore a file that's already tracked

If you accidentally committed a file and now want to ignore it:
```bash
git rm --cached .env
echo ".env" >> .gitignore
git commit -m "remove .env from tracking"
```

`git rm --cached` removes it from Git's tracking without deleting the file from disk.

### Check why a file is ignored

```bash
git check-ignore -v .env
```

Output tells you exactly which `.gitignore` rule matched.

**One-line rule:**
`.gitignore` exists so you never accidentally push secrets, build junk, or OS noise into your repo.

</details>

---

<details>
<summary><strong>8. Git Workflow – From Edit to Push</strong></summary>

The natural rhythm of every Git project:

```bash
git init
git add .
git commit -m "initial commit"
git remote add origin https://github.com/username/repo.git
git push -u origin main
```

**Typical daily flow:**
```
Edit → git status → git add → git commit → git push
```

**Pulling updates from remote:**
```bash
git pull
```

Fetches and merges new changes from the remote repository.

</details>

---

<details>
<summary><strong>9. Best Practices & Troubleshooting</strong></summary>

### Best Practices

- Commit **frequently** with short, meaningful messages
- Always check status before staging: `git status`
- Stage only what's intentional — never `git add .` blindly
- Push regularly to back up work
- Review before committing: `git diff`
- Keep commits atomic — one logical change per commit
- Always have a `.gitignore` before your first commit

### Commit Message Convention

```
type: short description

feat: add webstore login endpoint
fix: correct port binding in docker-compose
docs: update README with setup instructions
chore: add .gitignore
```

### Common Issues

| Issue | Fix |
|---|---|
| Accidentally staged wrong file | `git restore --staged <file>` |
| Commit message typo | `git commit --amend` |
| Merge conflicts | Resolve manually → `git add` → `git commit` |
| Permission denied on push | Check GitHub credentials or SSH setup |
| Detached HEAD | `git switch <branch>` to return to a branch |

</details>

→ Ready to practice? [Go to Lab 01](../git-labs/01-foundations-lab.md)
