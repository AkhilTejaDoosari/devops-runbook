[Home](../README.md) |
[Foundations](../01-foundations/README.md) |
[Stash & Tags](../02-stash-tags/README.md) |
[History & Branching](../03-history-branching/README.md) |
[Contribute](../04-contribute/README.md) |
[Undo & Recovery](../05-undo-recovery/README.md)

# Git Undo & Recovery

Mistakes happen. You commit the wrong file. You write a bad commit message. You reset too far and lose commits. You delete a branch before merging it.

Git has tools for all of these situations — but the right tool depends on *what state you are in* and *whether the commit has been pushed*. Using the wrong tool creates more problems than it solves. This file explains what state each mistake puts you in and which command gets you back.

---

## Table of Contents

- [1. The Mental Model — What Can Go Wrong and Where](#1-the-mental-model--what-can-go-wrong-and-where)
- [2. amend — Fix the Last Commit Before It Leaves](#2-amend--fix-the-last-commit-before-it-leaves)
- [3. revert — Undo a Pushed Commit Safely](#3-revert--undo-a-pushed-commit-safely)
- [4. reset — Move the Pointer Back](#4-reset--move-the-pointer-back)
- [5. reflog — Recover Anything](#5-reflog--recover-anything)
- [6. The Decision Table](#6-the-decision-table)
- [7. Quick Reference](#7-quick-reference)

---

## 1. The Mental Model — What Can Go Wrong and Where

Before reaching for a recovery command, identify where in the workflow the mistake happened:

```
Working Directory → Staging Area → Local Commit → Pushed to Remote
      edit             git add        git commit      git push
```

| Where the mistake is | What happened | Tool to use |
|---|---|---|
| Working directory | Edited a file and want to discard changes | `git restore <file>` |
| Staging area | Staged a file you did not mean to | `git restore --staged <file>` |
| Last local commit — not pushed | Wrong message, wrong files, forgot a file | `git commit --amend` |
| Older local commit — not pushed | Made several bad commits | `git reset` |
| Pushed commit | Bad commit others may have pulled | `git revert` |
| Lost commit after reset | Thought it was gone | `git reflog` |
| Deleted branch | Deleted before merging | `git reflog` + `git branch` |

The critical question before every recovery: **has this commit been pushed?**
If yes — you cannot rewrite history. Use `revert`.
If no — you can rewrite history. Use `amend` or `reset`.

---

## 2. amend — Fix the Last Commit Before It Leaves

`amend` rewrites the most recent commit. It changes the commit hash — Git treats the amended commit as an entirely new commit. This is why you must only amend commits that have not been pushed.

**Fix a typo in the commit message:**

```bash
git commit -m "feat: add paginaton to products endpoint"  # typo

git commit --amend -m "feat: add pagination to products endpoint"
# The old commit is replaced — the typo never existed
```

**Add a file you forgot to include:**

```bash
git commit -m "feat: add pagination to products endpoint"
# Realize you forgot to stage tests/pagination.test.js

git add tests/pagination.test.js
git commit --amend --no-edit
# The file is added to the existing commit — no new commit created
```

**Remove a file you accidentally included:**

```bash
# You committed webstore.conf but it should not be in this commit
git reset HEAD^ -- webstore.conf    # unstage it from the commit
git commit --amend --no-edit        # recommit without it
```

**The rule:** only amend before pushing. If you amend a pushed commit and force push, you rewrite shared history and cause problems for anyone who already pulled.

---

## 3. revert — Undo a Pushed Commit Safely

`revert` creates a new commit that exactly reverses the changes of a specific earlier commit. The original bad commit stays in history — nothing is erased. A new commit records the reversal.

This is the safe undo for commits that have already been pushed. It does not rewrite history — it adds to it.

**The scenario:**
You pushed a commit that broke the webstore API. Other engineers on the team may have already pulled it. You cannot rewrite history. You revert.

```bash
# Find the bad commit hash
git log --oneline
# d4e8f21 feat: add pagination   ← broke the API
# c8d21fa config: update nginx
# b71e3a2 feat: initialize project

# Revert it — creates a new commit that undoes d4e8f21
git revert d4e8f21 --no-edit

# New history:
# a91b23c Revert "feat: add pagination"   ← new commit, undoes the bad one
# d4e8f21 feat: add pagination            ← still in history
# c8d21fa config: update nginx

# Push the revert
git push
```

**What `--no-edit` does:** skips opening the editor for the revert commit message, uses the auto-generated "Revert '<original message>'" message. Leave it out if you want to write a custom message.

**If the revert has conflicts:**

```bash
git revert d4e8f21
# CONFLICT — fix the conflict manually
git add <file>
git revert --continue
```

---

## 4. reset — Move the Pointer Back

`reset` moves HEAD and the current branch pointer to a different commit. Unlike `revert`, it does not create a new commit — it rewrites history. This is why it is only safe on commits that have not been pushed.

**Three modes — the key differences:**

```
--soft  → HEAD moves back. Changes from undone commits stay staged.
--mixed → HEAD moves back. Changes from undone commits are unstaged (in working dir). DEFAULT.
--hard  → HEAD moves back. Changes from undone commits are permanently erased.
```

```bash
git log --oneline
# d4e8f21 bad commit 2   ← HEAD is here
# c8d21fa bad commit 1
# b71e3a2 good state     ← want to go back to here

# --soft: undo 2 commits, keep all changes staged and ready to recommit
git reset --soft b71e3a2

# --mixed: undo 2 commits, keep changes in working directory but unstaged
git reset --mixed b71e3a2

# --hard: undo 2 commits and erase all changes — permanent
git reset --hard b71e3a2
```

**The relative notation — without needing a hash:**

```bash
git reset --soft HEAD~1    # undo 1 commit
git reset --soft HEAD~3    # undo 3 commits
```

**When you reach for each mode:**

`--soft` — you want to undo commits but keep the work. You are going to recommit it differently, or split it into separate commits.

`--mixed` — you want to undo commits and the staging state. Changes are in your working directory, you can review and re-stage selectively.

`--hard` — you want to completely discard the commits and everything in them. Use with care — `--hard` is the one that loses work.

**Never reset commits that have been pushed to a shared branch.** If you reset and force push, everyone else who pulled those commits will have a diverged history.

---

## 5. reflog — Recover Anything

`reflog` is Git's flight recorder. It records every time HEAD moved — every commit, every checkout, every reset, every merge. Even after a `--hard` reset, even after deleting a branch, the commits still exist in Git's object store for 90 days. `reflog` is how you find them.

```bash
git reflog

# Output:
# e56ba1f HEAD@{0}: commit: revert bad feature
# d4e8f21 HEAD@{1}: commit: add pagination
# 9a9add8 HEAD@{2}: reset: moving to HEAD~1
# c8d21fa HEAD@{3}: commit: update nginx config
# b71e3a2 HEAD@{4}: commit: initialize project
```

Each line is an action. `HEAD@{n}` is shorthand for the state HEAD was in n steps ago.

**Recover commits lost after a hard reset:**

```bash
# You ran git reset --hard and lost commits d4e8f21 and e56ba1f
git reflog
# Find the hash of the commit you want to recover — e.g. d4e8f21

# Move HEAD back to it
git reset --hard d4e8f21
# Your commits are back
```

**Recover a deleted branch:**

```bash
# You deleted feature/webstore-pagination before merging
git branch -D feature/webstore-pagination

# Find the last commit that was on that branch
git reflog
# 3f8c2a1 HEAD@{2}: commit: feat: add pagination query params

# Recreate the branch at that commit
git branch feature/webstore-pagination 3f8c2a1
git switch feature/webstore-pagination
# Branch is back with all its commits
```

**The key insight about reflog:** Git almost never truly deletes commits. When you `reset --hard` or delete a branch, the commits are still in the object store — they just have no reference pointing to them. Reflog gives you those references back. As long as you act within 90 days, recovery is almost always possible.

---

## 6. The Decision Table

| Situation | Right tool | Wrong tool |
|---|---|---|
| Typo in last commit message, not pushed | `git commit --amend` | `git revert` — creates an unnecessary new commit |
| Forgot to stage a file, last commit not pushed | `git add <file>` + `git commit --amend --no-edit` | Creating a new commit for a tiny fix |
| Bad commit already pushed, others may have pulled | `git revert <hash>` | `git reset --hard` + force push — rewrites shared history |
| Several bad local commits, not pushed, keep the changes | `git reset --soft HEAD~N` | `git reset --hard` — would erase the work |
| Several bad local commits, not pushed, discard everything | `git reset --hard HEAD~N` | `git revert` — unnecessary when history is not shared |
| Lost commits after reset | `git reflog` + `git reset --hard <hash>` | Panicking — reflog almost always has it |
| Accidentally deleted a branch | `git reflog` + `git branch <n> <hash>` | Accepting the loss |

**The golden rule:**
Revert for shared history. Reset for local cleanup. Reflog for recovery.

---

## 7. Quick Reference

| Command | What it does |
|---|---|
| `git restore <file>` | Discard changes in working directory |
| `git restore --staged <file>` | Unstage a file |
| `git commit --amend -m "new message"` | Fix last commit message (not pushed only) |
| `git commit --amend --no-edit` | Add staged changes to last commit (not pushed only) |
| `git revert <hash>` | Create new commit that undoes a specific commit — safe for pushed |
| `git revert HEAD` | Revert the most recent commit |
| `git reset --soft HEAD~N` | Undo N commits, keep changes staged |
| `git reset --mixed HEAD~N` | Undo N commits, keep changes unstaged |
| `git reset --hard HEAD~N` | Undo N commits, erase all changes |
| `git reflog` | Show full history of HEAD movements |
| `git reset --hard HEAD@{n}` | Restore HEAD to any reflog position |
| `git branch <n> <hash>` | Recreate a deleted branch from a reflog hash |

---

→ Ready to practice? [Go to Lab 05](../git-labs/05-undo-recovery-lab.md)
