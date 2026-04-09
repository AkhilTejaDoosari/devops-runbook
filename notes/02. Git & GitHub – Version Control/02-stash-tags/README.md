[Home](../README.md) |
[Foundations](../01-foundations/README.md) |
[Stash & Tags](../02-stash-tags/README.md) |
[History & Branching](../03-history-branching/README.md) |
[Contribute](../04-contribute/README.md) |
[Undo & Recovery](../05-undo-recovery/README.md) |
[Interview](../99-interview-prep/README.md)

---

# Git Stash & Tags

> **Depends on:** [01 Foundations](./01-foundations/README.md) — you need commits and a remote before stashing and tagging make sense
> **Used in production when:** An urgent bug lands while you are mid-feature (stash), or a stable version ships and CI/CD needs a permanent reference point (tags)

---

## Table of Contents

- [What this is](#what-this-is)
- [1. Git stash — pausing without committing](#1-git-stash--pausing-without-committing)
- [2. Git tags — marking the webstore's first release](#2-git-tags--marking-the-webstores-first-release)
- [On the webstore](#on-the-webstore)
- [What breaks](#what-breaks)
- [Daily commands](#daily-commands)

---

## What this is

Two tools for two different situations. Stash is for when you are in the middle of something and need to stop without committing half-finished work — a clean shelf to park changes temporarily. Tags are for when you finish something and want to mark that moment permanently. Unlike a branch name that moves forward with every commit, a tag never moves. `v1.0` will always point to exactly the commit you tagged — which is why CI/CD pipelines use tags to trigger builds and Docker images are tagged with the same version string.

---

## 1. Git stash — pausing without committing

Stash saves your in-progress changes to a temporary shelf, gives you back a clean working directory, and lets you restore everything exactly where you left it when you are done. The stash is a stack — each save goes on top, most recent is `stash@{0}`.

```
stash@{0}  ← most recent
stash@{1}  ← older
stash@{2}  ← oldest
```

**The basic workflow:**

```bash
# Mid-work on webstore.conf — not ready to commit
cat ~/webstore/config/webstore.conf
# db_host=webstore-db-new   ← work in progress

# Save to stash with a label — anonymous stashes are hard to identify later
git stash push -m "WIP: updating db_host to new database server"

# Working directory is now clean
git status
# nothing to commit, working tree clean

# Switch context, fix the urgent thing, come back
git switch main
# fix bug, commit, push

# Restore your work exactly where you left it
git stash pop
cat ~/webstore/config/webstore.conf
# db_host=webstore-db-new   ← back exactly as you left it
```

**Stash only saves tracked files by default.** New files not yet staged are left behind. Use `-u` to include them:

```bash
touch ~/webstore/api/new-endpoint.js   # new untracked file
# -u (--include-untracked) includes new files
git stash push -u -m "WIP: new endpoint plus config change"
```

**All stash commands:**

| Command | Full form | What it does |
|---|---|---|
| `git stash push -m "msg"` | — | Save tracked changes with a label |
| `git stash -u` | --include-untracked | Include new untracked files |
| `git stash list` | — | Show all stashes on the stack |
| `git stash show -p` | --patch | Full diff of the most recent stash |
| `git stash pop` | — | Apply most recent stash and remove it from stack |
| `git stash apply stash@{1}` | — | Apply a specific stash but keep it on the stack |
| `git stash drop stash@{1}` | — | Delete a specific stash permanently |
| `git stash clear` | — | Delete all stashes — no recovery |
| `git stash branch <name>` | — | Create a branch from the most recent stash |

**Create a branch from a stash** — when you realize mid-work that what you are building should be its own feature branch:

```bash
git stash branch feature/new-db-config stash@{0}
# Creates the branch, checks it out, applies the stash, removes it from the stack
```

**What stash is not:** stash is local only — it does not push to GitHub. It expires after 90 days. It is a temporary shelf, not a substitute for branches. If you are working on something for more than a day, commit it to a branch.

---

## 2. Git tags — marking the webstore's first release

Tags are permanent pointers to specific commits. They never move forward. This is what CI/CD pipelines expect — push `v1.0` to GitHub, GitHub Actions detects it, builds the Docker image as `webstore-api:1.0`, pushes it to the registry. The tag in Git becomes the version in Docker becomes the version in Kubernetes.

**Two types:**

| Type | What it contains | When to use |
|---|---|---|
| Lightweight | Just a pointer to a commit | Local bookmarks only |
| Annotated (`-a`) | Pointer + author + date + message | Releases — always use this for anything shared |

Always use annotated tags for releases. They carry a message and your identity, show up on GitHub's releases page, and are what CI/CD pipelines expect.

**Tagging the webstore v1.0:**

```bash
# Confirm you are on the right commit
git log --oneline
# c8d21fa logs: add initial server startup entry   ← tag this one
# b71e3a2 config: add nginx worker process setting
# a3f92c1 feat: initialize webstore project structure

# -a = annotated, -m = message
git tag -a v1.0 -m "webstore v1.0 — Linux foundation complete

- directory structure established
- nginx configured and serving frontend
- permissions locked down
- ready for containerization"

# View the tag details
git show v1.0
# tag v1.0
# Tagger: Akhil Teja Doosari
# ...message...
# commit c8d21fa...
```

**Tags are not pushed automatically** — push them explicitly:

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

# Tag a specific past commit — when you forgot to tag at the right time
git tag -a v0.9 a3f92c1 -m "initial structure — pre-nginx"

# Delete a local tag
git tag -d v1.0

# Delete from remote — must delete locally first
git push origin --delete tag v1.0
```

**Semantic versioning — the standard:**

```
v1.0.0   ← major.minor.patch
v1.1.0   ← new feature, backward compatible
v1.1.1   ← bug fix
v2.0.0   ← breaking change
```

The webstore journey: `v1.0` after Linux, `v1.1` after first Docker commit, `v2.0` when running on Kubernetes.

---

## On the webstore

The webstore has three commits from file 01. An urgent bug report arrives mid-feature. You stash, fix, restore, then tag the stable foundation.

```bash
# Step 1 — you are mid-work updating the config
echo "cache_ttl=300" >> ~/webstore/config/webstore.conf
git status
# modified: config/webstore.conf

# Step 2 — urgent bug — stash and switch
git stash push -m "WIP: adding cache TTL setting"
git status
# nothing to commit, working tree clean

# Step 3 — fix the bug on main
git switch main
echo "# fixed" >> ~/webstore/api/server.js
git add api/server.js
git commit -m "fix: resolve api timeout on product listing"
git push

# Step 4 — restore your work
git stash pop
cat ~/webstore/config/webstore.conf
# cache_ttl=300   ← back

# Step 5 — finish and commit the feature
git add config/webstore.conf
git commit -m "config: add cache TTL setting"

# Step 6 — tag this stable state as v1.0
git tag -a v1.0 -m "webstore v1.0 — Linux foundation complete, ready for containerization"

# Step 7 — push everything including the tag
git push
git push origin v1.0

# Verify
git tag
# v1.0
git show v1.0
```

File 03 picks up from here — building features in branches on top of this tagged foundation.

---

## What breaks

| Symptom | Cause | Fix |
|---|---|---|
| `git stash pop` has conflicts | Stashed changes conflict with commits made while stashed | Resolve the conflict in the file, `git add <file>`, `git stash drop` to clean up |
| Stash is empty after `git stash pop` fails | Pop failed partway — stash may still be on stack | `git stash list` to check — if still there, `git stash pop` again after fixing conflicts |
| New file missing after `git stash pop` | Stashed with `git stash` not `git stash -u` — untracked files not included | Use `git stash -u` to include untracked files next time |
| Tag pushed to wrong commit | Tagged HEAD but HEAD was not the right commit | `git tag -d v1.0` locally, `git push origin --delete tag v1.0`, then tag the correct commit |
| `git push` did not push the tag | Tags require explicit push — `git push` does not include them | `git push origin v1.0` or `git push --tags` |
| `git tag -d` says tag not found | Tag name is wrong | `git tag` to list all existing tags |

---

## Daily commands

| Command | What it does |
|---|---|
| `git stash push -m "message"` | Save in-progress changes with a descriptive label |
| `git stash -u` | Save including new untracked files |
| `git stash list` | Show everything on the stash stack |
| `git stash pop` | Restore most recent stash and remove it from stack |
| `git stash show -p` | Show full diff of most recent stash |
| `git tag -a v1.0 -m "message"` | Create annotated tag at current commit |
| `git tag` | List all tags |
| `git show v1.0` | Show tag details and the commit it points to |
| `git push origin v1.0` | Push a specific tag to remote |
| `git push --tags` | Push all local tags to remote at once |

---

→ **Interview questions for this topic:** [99-interview-prep → Stash & Tags](../99-interview-prep/README.md#stash-and-tags)
