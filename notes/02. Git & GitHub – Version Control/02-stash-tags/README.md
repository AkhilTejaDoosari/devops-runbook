[Home](../README.md) |
[Foundations](../01-foundations/README.md) |
[Stash & Tags](../02-stash-tags/README.md) |
[History & Branching](../03-history-branching/README.md) |
[Contribute](../04-contribute/README.md) |
[Undo & Recovery](../05-undo-recovery/README.md)

# Git Stash & Tags

Two tools for two different situations. Stash is for when you are in the middle of something and need to stop without committing half-finished work. Tags are for when you finish something and want to mark that moment permanently — a release, a milestone, a version that CI/CD can reference.

---

## Table of Contents

- [1. Git Stash — Pausing Without Committing](#1-git-stash--pausing-without-committing)
- [2. Git Tags — Marking the Webstore's First Release](#2-git-tags--marking-the-webstores-first-release)
- [3. Quick Reference](#3-quick-reference)

---

## 1. Git Stash — Pausing Without Committing

You are halfway through updating `webstore.conf` to point at a new database host. Your changes are not ready to commit. Then an urgent message arrives — a bug in production, needs a fix right now. You need a clean working directory to switch branches and investigate.

This is what stash is for. It saves your in-progress changes to a temporary shelf, gives you back a clean state, and lets you restore everything exactly where you left it when you are done.

**The basic stash workflow:**

```bash
# You are mid-work on webstore.conf
cat ~/webstore/config/webstore.conf
# db_host=webstore-db-new   ← work in progress, not ready to commit

# Save it to the stash — your working directory becomes clean
git stash push -m "WIP: updating db_host to new database server"

# Check status — clean
git status
# nothing to commit, working tree clean

# Switch to fix the urgent bug
git switch main
# fix the bug, commit it, push it

# Come back and restore your work
git stash pop
cat ~/webstore/config/webstore.conf
# db_host=webstore-db-new   ← your changes are back exactly as you left them
```

**The stash is a stack.** Each stash is pushed on top. The most recent is `stash@{0}`.

```
stash@{0}  ← most recent — "WIP: updating db_host"
stash@{1}  ← older
stash@{2}  ← oldest
```

**All stash commands:**

| Command | What it does | When you reach for it |
|---|---|---|
| `git stash` | Save tracked changes to the stash | Quick save before switching context |
| `git stash push -m "message"` | Save with a descriptive label | Always — anonymous stashes are hard to identify later |
| `git stash -u` | Include untracked (new) files | When you have new files not yet staged |
| `git stash list` | Show all saved stashes | Checking what is on the stack |
| `git stash show` | Summary of the most recent stash | Quick reminder of what you stashed |
| `git stash show -p` | Full diff of the most recent stash | Reading exactly what changed |
| `git stash pop` | Apply most recent stash and remove it from the stack | Normal restore — most common |
| `git stash apply stash@{1}` | Apply a specific stash but keep it on the stack | When you want to apply without removing |
| `git stash drop stash@{1}` | Delete a specific stash | Cleaning up old stashes you no longer need |
| `git stash clear` | Delete all stashes | Nuclear option — permanent, no recovery |

**Stash only saves tracked files by default.** If you created a new file and have not run `git add` on it yet, `git stash` leaves it behind. Use `git stash -u` to include untracked files:

```bash
touch ~/webstore/api/new-endpoint.js   # new file, not tracked yet
git stash -u                           # includes it
```

**Create a branch from a stash** — when you realize mid-work that what you are building should be its own feature branch:

```bash
git stash branch feature/new-db-config stash@{0}
# Creates the branch, checks it out, applies the stash, removes it
```

**What stash is not:** stash is local only — it does not push to GitHub. It expires after 90 days. It is a temporary shelf, not long-term storage. If you are working on something for more than a day, commit it to a branch instead.

---

## 2. Git Tags — Marking the Webstore's First Release

The webstore has been running, commits have been made, nginx is serving the frontend. At some point the project reaches a stable state — everything works, the foundation is solid, this is a version worth marking.

That mark is a tag. Tags are permanent pointers to specific commits. Unlike branch names which move forward as you commit, a tag never moves. `v1.0` will always point to exactly the commit you tagged.

**Why tags matter in DevOps:**
CI/CD pipelines are often configured to trigger on tags. When you push `v1.0` to GitHub, GitHub Actions can detect it, build a Docker image, tag the image as `webstore-api:1.0`, and push it to the registry. The tag in Git becomes the version in Docker becomes the version in Kubernetes. It is the chain that connects your code to your deployment.

**Two types of tags:**

| Type | What it contains | When to use |
|---|---|---|
| Lightweight | Just a pointer to a commit | Local bookmarks, private notes |
| Annotated | Pointer + author + date + message | Releases — always use this for anything shared |

Always use annotated tags for releases. They carry a message and your identity, they show up properly in GitHub's releases page, and they are what CI/CD pipelines expect.

**Tagging the webstore v1.0:**

```bash
# First confirm where you are
git log --oneline
# c8d21fa logs: add initial server startup entry
# b71e3a2 config: add nginx worker process setting
# a3f92c1 feat: initialize webstore project structure

# Tag the current commit — the stable foundation
git tag -a v1.0 -m "webstore v1.0 — Linux foundation complete

- directory structure established
- nginx configured and serving frontend
- permissions locked down
- ready for containerization"

# View the tag and its details
git show v1.0
```

**Tags are not pushed automatically** — you have to push them explicitly:

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

# Tag an older specific commit — when you forgot to tag at the right time
git tag -a v0.9 a3f92c1 -m "initial structure — pre-nginx"

# Delete a local tag — if you tagged the wrong commit
git tag -d v1.0

# Delete a remote tag — only after deleting locally
git push origin --delete tag v1.0
```

**Semantic versioning — the standard format:**

```
v1.0.0   ← major.minor.patch
v1.1.0   ← new feature, backward compatible
v1.1.1   ← bug fix
v2.0.0   ← breaking change
```

For the webstore journey:
- `v1.0` — Linux foundation complete
- `v1.1` — first Docker commit
- `v2.0` — running on Kubernetes

---

## 3. Quick Reference

**Stash:**

| Command | What it does |
|---|---|
| `git stash push -m "message"` | Save changes with a label |
| `git stash -u` | Include untracked files |
| `git stash list` | Show all stashes |
| `git stash show -p` | Full diff of most recent stash |
| `git stash pop` | Restore and remove most recent stash |
| `git stash apply stash@{n}` | Restore specific stash, keep it on stack |
| `git stash drop stash@{n}` | Delete a specific stash |
| `git stash clear` | Delete all stashes permanently |
| `git stash branch <name>` | Create branch from most recent stash |

**Tags:**

| Command | What it does |
|---|---|
| `git tag -a v1.0 -m "message"` | Create annotated tag at current commit |
| `git tag -a v1.0 <hash> -m "message"` | Tag a specific past commit |
| `git tag` | List all tags |
| `git show v1.0` | Show tag details and the commit it points to |
| `git push origin v1.0` | Push a single tag to remote |
| `git push --tags` | Push all local tags to remote |
| `git tag -d v1.0` | Delete a local tag |
| `git push origin --delete tag v1.0` | Delete a remote tag |

---

→ Ready to practice? [Go to Lab 02](../git-labs/02-stash-tags-lab.md)
