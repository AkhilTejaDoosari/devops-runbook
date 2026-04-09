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
