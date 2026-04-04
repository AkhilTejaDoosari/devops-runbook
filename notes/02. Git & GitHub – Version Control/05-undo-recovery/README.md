[← devops-runbook](../../README.md) | 
[Foundations](../01-foundations/README.md) | 
[Stash & Tags](../02-stash-tags/README.md) | 
[History & Branching](../03-history-branching/README.md) | 
[Contribute](../04-contribute/README.md) | 
[Undo & Recovery](../05-undo-recovery/README.md)

# Git Undo & Recovery  
> Mastering Revert, Reflog & Amend

---

## Table of Contents
1. [When Things Go Wrong – The Need for Recovery](#1-when-things-go-wrong--the-need-for-recovery)
2. [Revert – Safely Undoing Published Commits](#2-revert--safely-undoing-published-commits)
3. [Amend – Fixing the Most Recent Commit](#3-amend--fixing-the-most-recent-commit)
4. [Reset – Moving the Pointer](#4-reset--moving-the-pointer)
5. [Reflog – Recovering Lost Work](#5-reflog--recovering-lost-work)
6. [Best Practices & Guardrails](#6-best-practices--guardrails)

---

<details>
<summary><strong>1. When Things Go Wrong – The Need for Recovery</strong></summary>

Mistakes happen — wrong commit, deleted branch, reset gone bad.
Git provides multiple safety nets to fix or roll back without losing history.

| Layer | Tool | Purpose |
|---|---|---|
| Surface | `git commit --amend` | Fix your last commit (message or files) |
| Mid-Level | `git revert` | Undo older commits safely with new commits |
| Deep Recovery | `git reflog` / `git reset` | Restore lost work or move to any past state |

</details>

---

<details>
<summary><strong>2. Revert – Safely Undoing Published Commits</strong></summary>

`git revert` creates a **new commit** that reverses the changes of an earlier commit — without deleting history.

**Analogy:** Crossing out a line in a notebook instead of tearing the page — the record remains.

### Commands

| Command | Description |
|---|---|
| `git revert HEAD` | Undo the latest commit |
| `git revert <commit-hash>` | Undo a specific commit |
| `git revert HEAD~2` | Undo a commit two steps back |
| `git revert --no-edit` | Skip editing commit message |

### Example

```bash
git log --oneline
# a91b23c add broken feature
# b78d23d fix login

git revert a91b23c --no-edit
# Creates new commit that undoes a91b23c
# History is preserved — nothing is deleted
```

### Troubleshooting

| Issue | Solution |
|---|---|
| Conflict occurs | Fix manually → `git add .` → `git revert --continue` |
| Want to cancel | `git revert --abort` |

**Use revert when:** the commit has already been pushed and others may have pulled it.

</details>

---

<details>
<summary><strong>3. Amend – Fixing the Most Recent Commit</strong></summary>

`git commit --amend` rewrites your last commit.

⚠️ Only use on **local commits** — never amend something already pushed.

### Fix a commit message

```bash
git commit --amend -m "add webstore config file"
```

### Add a forgotten file

```bash
git add missing-file.txt
git commit --amend --no-edit
```

### Remove a file from the last commit

```bash
git reset HEAD^ -- unwanted.txt
git commit --amend --no-edit
```

After amending, the commit hash changes — Git treats it as a new commit.

</details>

---

<details>
<summary><strong>4. Reset – Moving the Pointer</strong></summary>

`git reset` moves your HEAD pointer to a specific commit.

### Modes

| Command | Effect |
|---|---|
| `git reset --soft <commit>` | Move HEAD, keep changes staged |
| `git reset --mixed <commit>` | Move HEAD, unstage changes (default) |
| `git reset --hard <commit>` | Move HEAD and erase all changes |
| `git reset <file>` | Unstage a specific file only |

### Example

```bash
git log --oneline
# a91b23c bad commit
# b78d23d good state

git reset --soft b78d23d
# HEAD moves back — changes from a91b23c are now staged, ready to recommit
```

### Visual summary

```
--soft  → HEAD moves, files stay staged
--mixed → HEAD moves, files unstaged but kept
--hard  → HEAD moves, files erased completely
```

⚠️ Never use `reset` on shared branches — rewrite history causes problems for teammates.

</details>

---

<details>
<summary><strong>5. Reflog – Recovering Lost Work</strong></summary>

`git reflog` records every update to HEAD — even commits unreachable by normal history.
Your **black box recorder** — tracks every move.

### When to use

- Lost commits after a reset
- Branch deleted by mistake
- Need to go back to an exact state

### View reflog

```bash
git reflog
```

Example:
```
e56ba1f HEAD@{0}: commit: revert bad feature
52418f7 HEAD@{1}: commit: update webstore config
9a9add8 HEAD@{2}: reset: moving to HEAD~1
```

### Recover lost commits

```bash
git reset --hard HEAD@{2}
# or
git checkout 9a9add8
```

### Restore a deleted branch

```bash
git branch recovered-branch 9a9add8
```

### Key notes

- Reflog is **local only** — not synced to remote
- Expires after 90 days by default
- Always push branches you want to keep permanently

</details>

---

<details>
<summary><strong>6. Best Practices & Guardrails</strong></summary>

| Situation | Use | Avoid |
|---|---|---|
| Fix local commit before push | `git commit --amend` | After pushing to shared repo |
| Undo a pushed commit safely | `git revert` | `git reset --hard` on shared branch |
| Undo multiple local commits | `git reset --soft` | On shared branches |
| Lost commit recovery | `git reflog` + `git checkout` | Panicking before checking reflog |

**Golden rule:**
Revert for shared safety. Reset for private cleanup.

</details>

→ Ready to practice? [Go to Lab 05](../git-labs/05-undo-recovery-lab.md)
