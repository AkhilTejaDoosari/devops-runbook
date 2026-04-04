[Home](../README.md) | 
[Foundations](../01-foundations/README.md) | 
[Stash & Tags](../02-stash-tags/README.md) | 
[History & Branching](../03-history-branching/README.md) | 
[Contribute](../04-contribute/README.md) | 
[Undo & Recovery](../05-undo-recovery/README.md)

# Git History & Branching  
> Working in Parallel and Understanding Project History

---

## Table of Contents
1. [Reading Project History](#1-reading-project-history)
2. [Branching Fundamentals](#2-branching-fundamentals)
3. [Working with Branches – Create, Switch & Merge](#3-working-with-branches--create-switch--merge)
4. [Merging Types & Conflict Resolution](#4-merging-types--conflict-resolution)
5. [Rebase – Keeping History Linear](#5-rebase--keeping-history-linear)
6. [Branching Strategies](#6-branching-strategies)

---

<details>
<summary><strong>1. Reading Project History</strong></summary>

Every Git repository maintains a **complete timeline** — every edit, commit, and merge is recorded permanently.

---

### Key Commands

| Command | Description |
|---|---|
| `git log` | Full commit history with author, date, message |
| `git log --oneline` | Condensed summary |
| `git show <commit>` | Detailed info and file changes for one commit |
| `git diff` | Compare unstaged changes with last commit |
| `git diff --staged` | Compare staged changes with last commit |
| `git log --graph --oneline` | ASCII diagram of commit and merge history |

---

### Viewing History

```bash
git log --oneline
```

Example:
```
a91b23c add webstore api endpoint
b78d23d fix login bug
c11aa8d initial commit
```

### Inspect a Specific Commit

```bash
git show a91b23c
```

Shows author, timestamp, message, and exact diff.

### Compare File Versions

```bash
git diff              # unstaged changes
git diff --staged     # staged but uncommitted
git diff 1a2b3c4 9f8e7d6   # two specific commits
```

### Graph History

```bash
git log --graph --oneline
```

```
* 7d33e45 merge feature/api
|\
| * b24aa33 add order endpoint
| * c28ef12 add product endpoint
* | a7bc9d2 fix frontend navbar
|/
* 1a2b3c4 initial commit
```

</details>

---

<details>
<summary><strong>2. Branching Fundamentals</strong></summary>

A **branch** is a lightweight pointer to a series of commits — a parallel timeline where you can develop freely without touching the main codebase.

### Why Branches Exist

- Develop features without touching working code
- Fix bugs in isolation
- Let multiple people work simultaneously
- Experiment and discard without consequences

### The HEAD Pointer

`HEAD` tells Git where you currently are — the latest commit in your active branch.
Switching branches moves `HEAD` to another line of history.

### Key Branch Commands

| Command | Purpose |
|---|---|
| `git branch` | List all branches |
| `git branch <name>` | Create a new branch |
| `git switch <name>` | Switch to a branch |
| `git switch -c <name>` | Create and switch in one step |
| `git branch -m old new` | Rename a branch |
| `git branch -d <name>` | Delete a merged branch |
| `git branch -D <name>` | Force delete unmerged branch |

</details>

---

<details>
<summary><strong>3. Working with Branches – Create, Switch & Merge</strong></summary>

### Real workflow — feature branch

```bash
# Start from main
git switch main

# Create and switch to feature branch
git switch -c feature/webstore-api

# Make changes and commit
git add .
git commit -m "add product listing endpoint"

# Return to main
git switch main

# Merge feature back
git merge feature/webstore-api

# Clean up
git branch -d feature/webstore-api
```

---

### Fast-Forward Merge

If main hasn't changed since you branched — Git simply moves the pointer forward:

```
Before:  main → A → B
                         feature → C → D

After merge:  main → A → B → C → D
```

History stays linear, no merge commit created.

---

### 3-Way Merge

If both main and your branch have new commits since branching — Git creates a **merge commit**:

```
Before:  main → A → B → E
                         feature → C → D

After:   main → A → B → E → M  (M is the merge commit)
                         C → D ↗
```

</details>

---

<details>
<summary><strong>4. Merging Types & Conflict Resolution</strong></summary>

Conflicts happen when two branches modify the same lines in the same file.

### What a conflict looks like

```text
<<<<<<< HEAD
api_port=8080
=======
api_port=9090
>>>>>>> feature/webstore-api
```

- Everything above `=======` is your current branch (HEAD)
- Everything below is the incoming branch

### Resolve it

1. Edit the file — keep what's correct, delete the markers
2. Stage the resolved file: `git add <file>`
3. Complete the merge: `git commit`

### Best Practices

- Keep branches small and focused — smaller diffs = fewer conflicts
- Merge or rebase frequently to stay in sync with main
- Communicate with teammates about shared files

</details>

---

<details>
<summary><strong>5. Rebase – Keeping History Linear</strong></summary>

### What is rebase?

Rebase moves your branch's commits so they appear to start from the tip of another branch — creating a **linear history** with no merge commits.

**Merge result:**
```
main → A → B → E → M (merge commit)
                C → D ↗
```

**Rebase result:**
```
main → A → B → E → C' → D'
```

Your commits (C, D) are rewritten as (C', D') on top of main. Clean, linear history.

### Basic rebase workflow

```bash
git switch feature/webstore-api

# Rebase onto latest main
git rebase main

# Fix any conflicts, then:
git rebase --continue

# Switch to main and fast-forward
git switch main
git merge feature/webstore-api
```

### Merge vs Rebase — when to use which

| | Merge | Rebase |
|---|---|---|
| **History** | Preserves full branching history | Creates clean linear history |
| **Use when** | Merging completed features | Updating a feature branch with latest main |
| **Safe on shared branches** | ✅ Yes | ❌ No — never rebase pushed commits |
| **Creates merge commit** | ✅ Yes | ❌ No |

**The golden rule of rebase:**
Never rebase commits that have already been pushed to a shared remote branch. It rewrites history and causes problems for everyone else.

### Abort a rebase

```bash
git rebase --abort
```

Use this if things go wrong — returns you to the state before rebase started.

</details>

---

<details>
<summary><strong>6. Branching Strategies</strong></summary>

A **branching strategy** is a team agreement on how branches are named, when they're created, and how they flow into production. Interviewers ask about this. Teams fight about this. Know both.

---

### Git Flow

The classic strategy. Multiple long-lived branches.

```
main        — production-ready code only
develop     — integration branch for features
feature/*   — individual features branch off develop
release/*   — stabilization before merging to main
hotfix/*    — emergency fixes directly off main
```

**Flow:**
```
feature/x → develop → release/1.0 → main
                                   ↘ tag v1.0
hotfix/y → main → develop (backport)
```

**Good for:** Teams with scheduled release cycles, versioned software.
**Bad for:** Fast-moving teams — too much branch overhead.

---

### Trunk-Based Development

Everyone commits to `main` (the trunk) directly or via very short-lived feature branches (1-2 days max).

```
main  ← everyone integrates here frequently
  ↑
feature branches live < 2 days, then merged
```

**Good for:** CI-CD pipelines, fast-moving teams, SaaS products.
**Bad for:** Teams that need long stabilization periods.

---

### Which one does DevOps prefer?

**Trunk-based.** Here's why:

- GitHub Actions and ArgoCD trigger on commits to main
- Long-lived branches delay integration and create merge hell
- Feature flags replace the need for long feature branches
- Most modern DevOps teams (Google, Netflix, Amazon) use trunk-based

You will use **trunk-based** in Phase 06 when you build the CI-CD pipeline.

---

### Branch naming conventions (used in both strategies)

```
feature/webstore-api-pagination
fix/webstore-login-timeout
chore/update-dependencies
docs/add-api-readme
release/v1.2.0
hotfix/fix-payment-crash
```

</details>

→ Ready to practice? [Go to Lab 03](../git-labs/03-history-branching-lab.md)
