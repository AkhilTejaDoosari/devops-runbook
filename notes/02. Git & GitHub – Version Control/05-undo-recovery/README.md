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
