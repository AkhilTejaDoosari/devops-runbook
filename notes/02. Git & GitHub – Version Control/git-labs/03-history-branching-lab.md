[Home](../README.md) |
[Labs Index](./README.md) |
[Lab 01](./01-foundations-lab.md) |
[Lab 02](./02-stash-tags-lab.md) |
[Lab 03](./03-history-branching-lab.md) |
[Lab 04](./04-contribute-lab.md) |
[Lab 05](./05-undo-recovery-lab.md)

---

# Lab 03 — History & Branching

## The Situation

The webstore is at `v1.0` on GitHub. New features need to be built — a frontend, an improved API, a search endpoint. You cannot build these directly on `main`. Main is the stable version. If a feature breaks halfway through, main breaks with it.

This lab is where you learn to work in parallel. Every feature gets its own branch. Main stays stable. Features merge back when they are ready. By the end you will have built and merged multiple features, resolved a conflict by hand, and produced both a merge-commit history and a linear rebased history — and you will understand the difference.

## What this lab covers

You will read the webstore commit history, create feature branches, merge them back using both fast-forward and 3-way merge, resolve a conflict manually, rebase a branch onto main, and observe how history looks different between merge and rebase. Every command is typed from scratch.

## Prerequisites

- [History & Branching notes](../03-history-branching/README.md)
- Lab 02 completed — webstore repo with multiple commits and tags

---

## Section 1 — Read the History

1. Navigate to your webstore repo
```bash
cd ~/webstore-git
```

2. View full history
```bash
git log
```

3. View compact history
```bash
git log --oneline
```

4. View graph history
```bash
git log --graph --oneline
```

5. Inspect a specific commit — copy any hash from the log
```bash
git show <commit-hash>
```

**What to observe:** author, date, message, and the exact diff for that commit — this is your audit trail

6. Compare current state vs last commit
```bash
echo "test change" >> README.md
git diff
```

**What to observe:** `+test change` in the diff output — always use `git diff` before staging to review what you are about to commit

7. Restore README
```bash
git restore README.md
```

---

## Section 2 — Create and Work on a Feature Branch

1. Create and switch to a feature branch
```bash
git switch -c feature/webstore-frontend
```

2. Confirm you're on the new branch
```bash
git branch
```

**What to observe:** `* feature/webstore-frontend` — the `*` shows your current branch

3. Add frontend files
```bash
mkdir -p src/frontend
echo "<h1>webstore</h1>" > src/frontend/index.html
echo "body { font-family: sans-serif; }" > src/frontend/style.css
```

4. Commit on the feature branch
```bash
git add .
git commit -m "feat: add webstore frontend html and css"
```

5. Add another commit
```bash
echo "<footer>webstore © 2025</footer>" >> src/frontend/index.html
git add .
git commit -m "feat: add footer to webstore frontend"
```

6. Check branch history
```bash
git log --oneline
```

7. Switch back to main and check its history
```bash
git switch main
git log --oneline
```

**What to observe:** main does not have the frontend commits — they are isolated on the feature branch. This is the point of branching.

---

## Section 3 — Fast-Forward Merge

Main has not changed since you branched. Git can simply move the pointer forward.

1. Merge the frontend feature
```bash
git merge feature/webstore-frontend
```

**What to observe:** `Fast-forward` in the output — Git moved the pointer, no merge commit created, history stays linear

2. Check the log
```bash
git log --oneline
```

**What to observe:** all commits are now on main in a linear sequence

3. Delete the merged branch
```bash
git branch -d feature/webstore-frontend
```

---

## Section 4 — 3-Way Merge

Now both branches will have new commits — a merge commit is required.

1. Create a new feature branch
```bash
git switch -c feature/webstore-api-v2
```

2. Modify server.js on this branch
```bash
echo "// api v2: add pagination support" >> src/server.js
git add .
git commit -m "feat: add api v2 pagination"
```

3. Switch back to main and also make a commit on main
```bash
git switch main
echo "// main: add request logging" >> src/server.js
git add .
git commit -m "feat: add request logging to api"
```

4. Both branches have diverged. Merge the feature branch:
```bash
git merge feature/webstore-api-v2
```

**What to observe:** a merge commit is created — Git combines both lines of work into one commit

5. Check the graph
```bash
git log --graph --oneline
```

**What to observe:** two lines converging at the merge commit — this is what 3-way merge history looks like

---

## Section 5 — Resolve a Merge Conflict

When two branches modify the same lines, Git cannot decide automatically. You decide.

1. Set up a guaranteed conflict

```bash
# On main
echo "api_port=8080" > config/webstore.conf
git add . && git commit -m "chore: set api port to 8080"

# Create branch and change same line
git switch -c feature/port-change
echo "api_port=9090" > config/webstore.conf
git add . && git commit -m "chore: change api port to 9090"

# Back to main
git switch main

# Merge — this will conflict
git merge feature/port-change
```

2. See the conflict
```bash
git status
cat config/webstore.conf
```

**What to observe:**
```
<<<<<<< HEAD
api_port=8080
=======
api_port=9090
>>>>>>> feature/port-change
```

Above `=======` is what main has. Below is what the feature branch has. The markers are not valid content — remove them.

3. Resolve it — keep the correct value and remove all markers
```bash
echo "api_port=8080" > config/webstore.conf
```

4. Mark as resolved and complete the merge
```bash
git add config/webstore.conf
git commit -m "merge: resolve port conflict — keep 8080"
```

5. Clean up
```bash
git branch -d feature/port-change
git branch -d feature/webstore-api-v2
```

---

## Section 6 — Rebase

Rebase replays your feature commits on top of the latest main — producing a linear history with no merge commits.

1. Create a new feature branch from current main
```bash
git switch -c feature/webstore-search
echo "// search endpoint" >> src/server.js
git add . && git commit -m "feat: add search endpoint"
```

2. Meanwhile make a commit on main
```bash
git switch main
echo "// health check endpoint" >> src/server.js
git add . && git commit -m "feat: add health check endpoint"
```

3. Both branches have diverged. Rebase the feature onto latest main:
```bash
git switch feature/webstore-search
git rebase main
```

**What to observe:** Git replays your search endpoint commit on top of main's latest commit — as if you had branched after the health check was added

4. Check the graph
```bash
git log --graph --oneline
```

**What to observe:** no merge commit — the feature commits appear directly after main's commits. Clean linear history.

5. Merge into main with fast-forward — clean because of rebase
```bash
git switch main
git merge feature/webstore-search
git branch -d feature/webstore-search
```

6. Final graph
```bash
git log --graph --oneline
```

**What to observe:** perfectly linear history — no merge commits anywhere

---

## Section 7 — Break It on Purpose

### Break 1 — Delete an unmerged branch

```bash
git switch -c feature/unfinished
echo "work in progress" >> src/server.js
git add . && git commit -m "wip: unfinished feature"
git switch main
git branch -d feature/unfinished
```

**What to observe:** `error: The branch 'feature/unfinished' is not fully merged` — Git protects you from losing work

Force delete it:
```bash
git branch -D feature/unfinished
```

### Break 2 — Rebase with a conflict

```bash
git switch -c feature/conflict-test
echo "api_port=7777" > config/webstore.conf
git add . && git commit -m "change port on feature"

git switch main
echo "api_port=8888" > config/webstore.conf
git add . && git commit -m "change port on main"

git switch feature/conflict-test
git rebase main
```

**What to observe:** rebase pauses at the conflict — same resolution process as merge

Fix it:
```bash
echo "api_port=8080" > config/webstore.conf
git add config/webstore.conf
git rebase --continue
git switch main
git branch -D feature/conflict-test
```

---

## Checklist

Do not move to Lab 04 until every box is checked.

- [ ] I used `git log`, `git log --oneline`, and `git log --graph --oneline` and can explain what each shows
- [ ] I created a feature branch, made commits on it, switched to main, and confirmed main did not have those commits
- [ ] I performed a fast-forward merge and saw `Fast-forward` in the output — no merge commit
- [ ] I performed a 3-way merge and saw the merge commit in the graph — two lines converging
- [ ] I produced a merge conflict on purpose, read the conflict markers, resolved it manually, and committed
- [ ] I rebased a feature branch onto main and confirmed the history was linear with no merge commit
- [ ] I tried to delete an unmerged branch with `-d` and saw the error — then forced it with `-D`
- [ ] I resolved a rebase conflict using `git rebase --continue`
