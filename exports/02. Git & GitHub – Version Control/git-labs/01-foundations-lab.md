[Home](../README.md) |
[Labs Index](./README.md) |
[Lab 01](./01-foundations-lab.md) |
[Lab 02](./02-stash-tags-lab.md) |
[Lab 03](./03-history-branching-lab.md) |
[Lab 04](./04-contribute-lab.md) |
[Lab 05](./05-undo-recovery-lab.md)

---

# Lab 01 — Git Foundations

## The Situation

The webstore project exists as files on a Linux server — organized directories, a config file, log files, nginx configured and running. But there is no history. If something breaks, there is no rollback. If a second developer joins, there is no way to track who changed what. The project is one bad `rm -rf` away from being gone.

This lab changes that. By the end the webstore is a Git repository with a commit history that tells the story of how it was built — pushed to GitHub, visible to anyone with the link, and ready for the collaboration workflow that comes in the next labs.

This is the moment the webstore becomes trackable.

## What this lab covers

You will initialize a Git repository for the webstore project, configure your identity, track and stage files, make your first commits, build a proper `.gitignore`, and push to GitHub. By the end the full local → remote workflow will be muscle memory. Every command is typed from scratch.

## Prerequisites

- [Foundations notes](../01-foundations/README.md)
- Git installed and verified with `git --version`
- A GitHub account

---

## Section 1 — Configure Git Identity

1. Set your global name and email
```bash
git config --global user.name "Your Name"
git config --global user.email "your@email.com"
```

2. Verify the settings saved
```bash
git config --list
```

**What to observe:** your name and email appear in the output — every commit you make will carry this identity

---

## Section 2 — Initialize the Webstore Repo

1. Create the webstore project folder
```bash
mkdir ~/webstore-git
cd ~/webstore-git
```

2. Initialize Git
```bash
git init
```

3. Confirm the `.git` folder was created
```bash
ls -a
```

**What to observe:** `.git` folder exists — this is where all history is stored. Delete this folder and the entire version history is gone.

---

## Section 3 — Create Files and Observe Status

1. Create the project structure
```bash
mkdir -p src config
touch src/server.js
touch config/webstore.conf
echo "api_port=8080" > config/webstore.conf
echo "db_host=webstore-db" >> config/webstore.conf
echo "db_port=5432" >> config/webstore.conf
```

2. Check status
```bash
git status
```

**What to observe:** both files show as `Untracked` — Git sees them but is not watching them yet

3. Create a `.env` file with a fake secret
```bash
echo "DB_PASSWORD=supersecret123" > .env
```

4. Check status again
```bash
git status
```

**What to observe:** `.env` also shows as untracked — you'll fix this in Section 4

---

## Section 4 — Create .gitignore

1. Create the `.gitignore` file
```bash
touch .gitignore
```

2. Add entries — write each line manually
```bash
echo ".env" >> .gitignore
echo "*.log" >> .gitignore
echo "node_modules/" >> .gitignore
echo ".DS_Store" >> .gitignore
echo "*.tfstate" >> .gitignore
echo ".terraform/" >> .gitignore
```

3. Check status now
```bash
git status
```

**What to observe:** `.env` is no longer listed — `.gitignore` is hiding it from Git. The database password will never accidentally be committed.

4. Confirm the ignore rule works
```bash
git check-ignore -v .env
```

**What to observe:** output shows exactly which rule in `.gitignore` matched

---

## Section 5 — Stage and Commit

1. Stage everything
```bash
git add .
git status
```

**What to observe:** files move from `Untracked` to `Changes to be committed`

2. Unstage the config file — you're not ready to commit it yet
```bash
git restore --staged config/webstore.conf
git status
```

**What to observe:** `config/webstore.conf` is back to untracked, `src/server.js` and `.gitignore` remain staged

3. Re-stage the config file
```bash
git add config/webstore.conf
```

4. Make your first commit — this is the moment the webstore's history begins
```bash
git commit -m "feat: initialize webstore project structure

- add src and config directories
- add server.js entry point
- add webstore.conf with db and api settings
- add .gitignore to protect secrets"
```

5. View the commit
```bash
git log --oneline
```

**What to observe:** one commit with your message and a hash — the first permanent record of the webstore

---

## Section 6 — Make More Commits

**Goal:** build a history that tells the story of the webstore's development.

1. Add content to server.js
```bash
echo "const port = process.env.PORT || 8080" > src/server.js
echo "console.log('webstore-api starting on port ' + port)" >> src/server.js
```

2. Check what changed before staging
```bash
git diff
```

**What to observe:** the `+` lines show what was added — always review with `git diff` before committing

3. Stage and commit
```bash
git add src/server.js
git commit -m "feat: add webstore api server entry point"
```

4. Add a README
```bash
echo "# Webstore API" > README.md
echo "Backend API for the webstore application." >> README.md
git add README.md
git commit -m "docs: add project README"
```

5. View full history
```bash
git log --oneline
```

**What to observe:** 3 commits building on each other — a readable story of how the project was initialized

---

## Section 7 — Push to GitHub

1. Create a new repository on GitHub named `webstore` — empty, no README

2. Add the remote
```bash
git remote add origin https://github.com/YOUR_USERNAME/webstore.git
```

3. Verify remote was added
```bash
git remote -v
```

4. Push to GitHub
```bash
git push -u origin main
```

5. Open GitHub in your browser and confirm all 3 commits are visible

**What to observe:** the commit history on GitHub matches your local `git log --oneline` exactly

---

## Section 8 — Break It on Purpose

### Break 1 — Commit without a message

```bash
git commit
```

**What to observe:** Git opens your default editor waiting for a message — close without saving and the commit is aborted. An empty commit message is not allowed.

### Break 2 — Push without a remote set

```bash
mkdir /tmp/test-repo && cd /tmp/test-repo
git init
echo "test" > file.txt
git add . && git commit -m "test"
git push
```

**What to observe:** `fatal: No configured push destination` — you must add a remote before you can push

### Break 3 — Prove .gitignore is the only protection

```bash
cd ~/webstore-git
# Remove .env from .gitignore temporarily
sed -i '/.env/d' .gitignore
git status
```

**What to observe:** `.env` now shows up as untracked — the database password is exposed. This is what happens when `.gitignore` is missing or incomplete.

Restore `.gitignore`:
```bash
echo ".env" >> .gitignore
git add .gitignore
git commit -m "chore: restore .env protection in gitignore"
```

---

## Checklist

Do not move to Lab 02 until every box is checked.

- [ ] I configured git name and email and verified with `git config --list`
- [ ] I initialized a repo and confirmed `.git` folder exists — I know what deleting it would do
- [ ] I created `.gitignore` before the first `git add .` and confirmed `.env` was hidden from `git status`
- [ ] I used `git check-ignore -v .env` and saw which rule matched
- [ ] I used `git restore --staged` to unstage a file and re-staged it deliberately
- [ ] I made 3 commits with meaningful messages following the `type: description` format
- [ ] I used `git diff` to review changes before staging them
- [ ] I pushed to GitHub and confirmed all commits appear in the browser
- [ ] I proved that removing `.env` from `.gitignore` immediately exposes the secret in `git status`
