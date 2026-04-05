[Home](../README.md) |
[Foundations](../01-foundations/README.md) |
[Stash & Tags](../02-stash-tags/README.md) |
[History & Branching](../03-history-branching/README.md) |
[Contribute](../04-contribute/README.md) |
[Undo & Recovery](../05-undo-recovery/README.md)

# Git History & Branching

The webstore has a commit history now. Someone wants to add a product pagination feature to the API. You cannot build it directly on `main` — that is the stable, deployed version. If the feature breaks halfway through, the whole project is broken.

Branches solve this. A branch is a separate line of development — a parallel timeline where you can build, experiment, and break things without touching what is working. When the feature is done and tested, you merge it back.

---

## Table of Contents

- [1. Reading Project History](#1-reading-project-history)
- [2. Branching — What It Is and Why It Exists](#2-branching--what-it-is-and-why-it-exists)
- [3. Creating, Switching, and Merging Branches](#3-creating-switching-and-merging-branches)
- [4. Merge Types — Fast-Forward and 3-Way](#4-merge-types--fast-forward-and-3-way)
- [5. Conflict Resolution](#5-conflict-resolution)
- [6. Rebase — Keeping History Linear](#6-rebase--keeping-history-linear)
- [7. Branching Strategies](#7-branching-strategies)
- [8. Quick Reference](#8-quick-reference)

---

## 1. Reading Project History

Every commit in Git is a permanent record. Reading history is how you understand what happened — who changed what, when, and why.

```bash
# Compact one-line view — most useful for daily navigation
git log --oneline
# c8d21fa logs: add initial server startup entry
# b71e3a2 config: add nginx worker process setting
# a3f92c1 feat: initialize webstore project structure

# Full detail — author, date, message, hash
git log

# Visual branch and merge history
git log --graph --oneline
# * c8d21fa (HEAD -> main) logs: add initial server startup entry
# * b71e3a2 config: add nginx worker process setting
# * a3f92c1 feat: initialize webstore project structure

# Show exactly what changed in a specific commit
git show c8d21fa

# Compare two commits — what changed between them
git diff a3f92c1 c8d21fa

# Show unstaged changes in working directory
git diff

# Show staged changes waiting to be committed
git diff --staged
```

**When you reach for `git log`:**
A deployment broke something. You need to know what changed between yesterday's working version and today's broken one. `git log --oneline` shows you the commits in between. `git show <hash>` shows you exactly what each one changed.

| Command | What it shows |
|---|---|
| `git log --oneline` | Compact history — commit hash and message |
| `git log --graph --oneline` | Visual branch and merge diagram |
| `git show <hash>` | Full detail and file diff for one commit |
| `git diff` | Unstaged changes in working directory |
| `git diff --staged` | Staged changes waiting to commit |
| `git diff <hash1> <hash2>` | Changes between any two commits |

---

## 2. Branching — What It Is and Why It Exists

A **branch** is a lightweight pointer to a commit — a named position in the commit chain. When you create a branch, Git creates a new pointer at your current commit. When you make commits on that branch, only that pointer moves forward. `main` stays exactly where it was.

```
Before branching:
main → A → B → C   (HEAD is here)

After creating feature/products-api:
main → A → B → C
feature/products-api → C   (same starting point)

After two commits on the feature branch:
main → A → B → C
feature/products-api → C → D → E   (main untouched)
```

**HEAD** is the pointer that tells Git which branch — and therefore which commit — you are currently on. When you switch branches, HEAD moves.

---

## 3. Creating, Switching, and Merging Branches

**The feature branch workflow — what you do for every new piece of work:**

```bash
# Start from main — always branch from a known good state
git switch main
git pull   # make sure you have the latest

# Create and switch to the feature branch in one step
git switch -c feature/webstore-api-pagination

# Make changes and commit them on the feature branch
vim ~/webstore/api/server.js
git add api/server.js
git commit -m "feat: add product pagination to webstore API"

vim ~/webstore/api/server.js
git add api/server.js
git commit -m "feat: add pagination query param validation"

# Check where you are and what the history looks like
git log --graph --oneline

# Return to main
git switch main

# Merge the feature branch back
git merge feature/webstore-api-pagination

# Delete the branch — it has been merged, no longer needed
git branch -d feature/webstore-api-pagination
```

**Branch management commands:**

| Command | What it does |
|---|---|
| `git branch` | List all local branches |
| `git branch -a` | List local and remote branches |
| `git branch <name>` | Create a branch (without switching) |
| `git switch <name>` | Switch to an existing branch |
| `git switch -c <name>` | Create and switch in one step |
| `git branch -m old new` | Rename a branch |
| `git branch -d <name>` | Delete a merged branch |
| `git branch -D <name>` | Force delete — even if unmerged |

---

## 4. Merge Types — Fast-Forward and 3-Way

When you merge, Git decides how to combine the histories. The result depends on what happened to both branches since they diverged.

**Fast-Forward Merge — main has not moved:**

If no new commits were added to `main` while you worked on the feature branch, Git simply moves the `main` pointer forward to match the feature branch tip. No merge commit is created. The history stays linear.

```
Before:
main → A → B → C
feature → C → D → E

After fast-forward merge:
main → A → B → C → D → E
(feature pointer deleted)
```

```bash
git switch main
git merge feature/webstore-api-pagination
# Fast-forward — history is linear, no merge commit
```

**3-Way Merge — main has also moved:**

If new commits were added to `main` while you worked on the feature branch, Git cannot just move the pointer. It has to create a **merge commit** that combines both lines of history.

```
Before:
main → A → B → C → F → G
feature → C → D → E

After 3-way merge:
main → A → B → C → F → G → M   (M is the merge commit)
                   ↗
              D → E
```

```bash
git switch main
git merge feature/webstore-api-pagination
# Merge commit created — Git opens your editor for the merge commit message
```

**When each happens:**
Fast-forward happens when you branch, work, and merge without anyone else committing to main in between. 3-way happens when the team is active and main moved while you were working.

---

## 5. Conflict Resolution

Conflicts happen when two branches modify the same lines in the same file. Git cannot decide automatically which version to keep — it marks the conflict and asks you to resolve it.

**What a conflict looks like:**

```
<<<<<<< HEAD
db_host=webstore-db-primary
=======
db_host=webstore-db-replica
>>>>>>> feature/db-failover
```

- Everything above `=======` is from the branch you are merging into (HEAD)
- Everything below is from the incoming branch
- The `<<<<<<<` and `>>>>>>>` markers are not valid content — they must be removed

**The resolution process:**

```bash
# Git tells you there is a conflict
git merge feature/db-failover
# CONFLICT (content): Merge conflict in config/webstore.conf

# Open the file and find the conflict markers
vim config/webstore.conf

# Edit it to keep what is correct — remove all markers
# Result: db_host=webstore-db-primary

# Mark it resolved
git add config/webstore.conf

# Complete the merge
git commit
# Git opens the editor with a default merge commit message — save and close
```

**The conflict resolution mindset:** a conflict is not an error. It is Git saying "two people changed the same thing — which version should survive?" You make the decision, stage the result, and commit.

---

## 6. Rebase — Keeping History Linear

Rebase rewrites your branch's commits so they appear to start from the current tip of another branch. The result is a clean, linear history with no merge commits.

**Merge result — history shows the branching:**

```
main → A → B → C → F → G → M (merge commit)
                   ↗
              D → E
```

**Rebase result — history looks like it was always linear:**

```
main → A → B → C → F → G → D' → E'
```

Your commits (`D`, `E`) are rewritten as new commits (`D'`, `E'`) on top of the latest `main`. Same changes, different parent.

**The rebase workflow:**

```bash
# On the feature branch — update it to start from latest main
git switch feature/webstore-api-pagination
git rebase main

# If conflicts arise during rebase:
# fix the conflict
git add <file>
git rebase --continue

# If something goes badly wrong — abort and return to before
git rebase --abort

# After a successful rebase — fast-forward merge on main
git switch main
git merge feature/webstore-api-pagination
# Fast-forward — clean linear history
```

**Merge vs Rebase — the decision:**

| | Merge | Rebase |
|---|---|---|
| History | Preserves the branch structure | Creates a linear timeline |
| Use for | Merging completed features to main | Updating a feature branch with latest main |
| Safe on shared branches | Yes | No — never rebase commits that have been pushed |
| Creates merge commit | Yes | No |

**The golden rule of rebase:** never rebase commits that have already been pushed to a shared remote branch. Rebase rewrites history — if someone else pulled those commits before you rebased, their local history now diverges from yours and they will have problems.

Rebase is safe on a **local feature branch you have not pushed yet**, or on a **personal branch that nobody else has pulled**.

---

## 7. Branching Strategies

A branching strategy is a team agreement on how branches are named, when they are created, and how they flow into production. These come up in interviews.

**Git Flow — the classic approach:**

```
main        — production-ready code only, every commit is deployable
develop     — integration branch, features merge here before going to main
feature/*   — individual features, branch off develop
release/*   — stabilization before merging to main
hotfix/*    — emergency fixes directly off main
```

```
feature/x → develop → release/1.0 → main  ← tag v1.0
                                        ↘ hotfix/y → main → develop
```

Good for: versioned software with scheduled release cycles.
Bad for: fast-moving teams — too much branch overhead.

**Trunk-Based Development — the DevOps standard:**

Everyone commits to `main` directly, or via very short-lived feature branches (1–2 days maximum). No long-running branches.

```
main  ← everyone integrates here, frequently
  ↑
small feature branches, merged within 1-2 days
```

Good for: CI/CD pipelines, fast-moving teams, SaaS products.
Why DevOps teams prefer it: GitHub Actions and ArgoCD trigger on commits to main. Long-lived branches delay integration and create merge hell. Feature flags replace the need for long feature branches.

**Branch naming conventions:**

```
feature/webstore-api-pagination
fix/webstore-login-timeout
chore/update-dependencies
docs/add-api-readme
release/v1.2.0
hotfix/fix-payment-crash
```

---

## 8. Quick Reference

| Command | What it does |
|---|---|
| `git log --oneline` | Compact commit history |
| `git log --graph --oneline` | Visual branch diagram |
| `git show <hash>` | Full detail for one commit |
| `git diff` | Unstaged changes |
| `git diff --staged` | Staged changes |
| `git branch` | List branches |
| `git switch -c <name>` | Create and switch to new branch |
| `git switch <name>` | Switch to existing branch |
| `git merge <branch>` | Merge branch into current |
| `git branch -d <name>` | Delete merged branch |
| `git rebase main` | Rebase current branch onto main |
| `git rebase --continue` | Continue after resolving rebase conflict |
| `git rebase --abort` | Cancel rebase entirely |

---

→ Ready to practice? [Go to Lab 03](../git-labs/03-history-branching-lab.md)
