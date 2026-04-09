[Home](../README.md) |
[Foundations](../01-foundations/README.md) |
[Stash & Tags](../02-stash-tags/README.md) |
[History & Branching](../03-history-branching/README.md) |
[Contribute](../04-contribute/README.md) |
[Undo & Recovery](../05-undo-recovery/README.md) |
[Interview](../99-interview-prep/README.md)

---

# Git Contribute

> **Depends on:** [03 History & Branching](./03-history-branching/README.md) — you need branches and merges before the PR workflow makes sense
> **Used in production when:** A second developer joins the team, you need to propose code for review before it reaches main, or you are contributing to a repo you do not own

---

## Table of Contents

- [What this is](#what-this-is)
- [1. Two collaboration contexts](#1-two-collaboration-contexts)
- [2. Cloning — getting the repo locally](#2-cloning--getting-the-repo-locally)
- [3. Remotes — origin and upstream](#3-remotes--origin-and-upstream)
- [4. git fetch vs git pull — the distinction](#4-git-fetch-vs-git-pull--the-distinction)
- [5. The feature branch PR workflow](#5-the-feature-branch-pr-workflow)
- [6. Forking — contributing to a repo you do not own](#6-forking--contributing-to-a-repo-you-do-not-own)
- [7. Keeping your fork in sync](#7-keeping-your-fork-in-sync)
- [8. What makes a good pull request](#8-what-makes-a-good-pull-request)
- [On the webstore](#on-the-webstore)
- [What breaks](#what-breaks)
- [Daily commands](#daily-commands)

---

## What this is

The webstore is on GitHub. A second developer joins and needs to work on the products API. They cannot push directly to main — that is the production branch. They need their own copy to work from, a way to propose changes for review, and a way to stay in sync when main moves forward while they are working. This is the collaboration model. It is what separates someone who uses Git alone from someone who uses Git on a team.

---

## 1. Two collaboration contexts

| Context | When | What you do |
|---|---|---|
| Company repo | You are on the team, have write access | Clone directly, work in feature branches, open PRs to main |
| Open-source repo | You do not have write access | Fork first, clone your fork, open PR to the original |

In DevOps day-to-day work — your team's infrastructure repo, webstore deployment manifests, Terraform configs — you use the company repo pattern. Fork is for contributing to projects you do not own.

---

## 2. Cloning — getting the repo locally

Clone downloads the full repository — all commits, all branches, all history. Not just the latest files. Everything.

```bash
# Clone the webstore repo
git clone https://github.com/AkhilTejaDoosari/webstore.git

# Clone into a specific folder name
git clone https://github.com/AkhilTejaDoosari/webstore.git my-webstore

cd webstore
git log --oneline    # full history is here
git branch -a        # all branches — local and remote
# * main
#   remotes/origin/main
#   remotes/origin/feature/db-failover-config
```

After cloning you have a full local copy, one remote called `origin` pointing to GitHub, and a local `main` tracking `origin/main`.

---

## 3. Remotes — origin and upstream

A remote is a named reference to a repo hosted somewhere else.

```bash
# See all remotes
git remote -v
# origin  https://github.com/AkhilTejaDoosari/webstore.git (fetch)
# origin  https://github.com/AkhilTejaDoosari/webstore.git (push)
```

**`origin`** — the repo you cloned from. Your team's repo or your fork. You push here and pull from here.

**`upstream`** — the original repo when you have forked. You pull from upstream to stay in sync. You never push to it.

```bash
# Add upstream after forking
git remote add upstream https://github.com/original-owner/webstore.git

git remote -v
# origin    https://github.com/AkhilTejaDoosari/webstore.git (fetch)
# origin    https://github.com/AkhilTejaDoosari/webstore.git (push)
# upstream  https://github.com/original-owner/webstore.git (fetch)
# upstream  https://github.com/original-owner/webstore.git (push)
```

| Remote | Purpose | Push to it? |
|---|---|---|
| `origin` | Your fork or your team's repo | Yes |
| `upstream` | The original repo you forked from | No — read only |

---

## 4. git fetch vs git pull — the distinction

This is one of the most common interview questions and a real source of mistakes in production.

```
git fetch   → downloads new commits from remote into local repo
              does NOT touch your working directory or current branch
              your files are unchanged — you just have the remote data locally

git pull    → git fetch + git merge in one command
              downloads AND immediately merges into your current branch
              your working directory changes
```

```bash
# fetch — safe, no changes to your work
git fetch origin
# Now you can see what changed without your files moving
git log --oneline main..origin/main
# a1b2c3d feat: add payment gateway   ← these are on remote, not in your main yet

# Look before you merge
git diff main origin/main

# Merge when ready
git merge origin/main

# pull — does both in one step
git pull
# equivalent to: git fetch origin + git merge origin/main
```

**When to use which:**
Use `git fetch` when you want to see what changed on the remote before merging — safe on production branches. Use `git pull` in your normal daily workflow when you are confident and just want to be up to date.

---

## 5. The feature branch PR workflow

This is what you do every day on a team. Every piece of work — feature, fix, config change — gets its own branch. When done, you open a pull request for review before it merges to main.

```bash
# Step 1 — start from latest main
git switch main
git pull

# Step 2 — create your feature branch
git switch -c feature/webstore-product-pagination

# Step 3 — do the work, commit as you go
vim api/server.js
git add api/server.js
git commit -m "feat: add pagination to products endpoint"

vim api/server.js
git add api/server.js
git commit -m "feat: add page size validation"

# Step 4 — push the branch to GitHub
git push origin feature/webstore-product-pagination

# Step 5 — open a pull request on GitHub
# github.com → your repo → "Compare & pull request"
# Base: main  ←  Compare: feature/webstore-product-pagination
# Write a clear title and description, submit for review

# Step 6 — teammate reviews, approves, merges on GitHub

# Step 7 — clean up locally after merge
git switch main
git pull                                            # get the merged commit
git branch -d feature/webstore-product-pagination   # delete local branch
```

**Why the PR exists:** a pull request is a checkpoint. Before code reaches main — the production branch — a teammate reads it, catches bugs, asks questions, and approves. Even on a solo project, opening a PR forces you to read your own diff one more time before merging.

---

## 6. Forking — contributing to a repo you do not own

A fork is a complete copy of someone else's repository under your GitHub account. You have full write access to your fork. The original repo is unaffected by anything you do in your fork.

Fork is a GitHub feature, not a Git command. You fork on the GitHub website, then clone your fork locally.

```bash
# Step 1 — fork on GitHub
# github.com → original repo → Fork button (top right)
# GitHub creates: github.com/AkhilTejaDoosari/webstore

# Step 2 — clone your fork
git clone https://github.com/AkhilTejaDoosari/webstore.git
cd webstore

# Step 3 — add the original as upstream
git remote add upstream https://github.com/original-owner/webstore.git

# Step 4 — create a feature branch
git switch -c fix/webstore-api-timeout

# Step 5 — make changes and commit
git commit -m "fix: increase api timeout from 5s to 30s"

# Step 6 — push to your fork
git push origin fix/webstore-api-timeout

# Step 7 — open a PR from your fork to the original
# github.com → your fork → Compare & pull request
# Base repository: original-owner/webstore  base: main
# Head repository: AkhilTejaDoosari/webstore  compare: fix/webstore-api-timeout
```

---

## 7. Keeping your fork in sync

While you work, the original repo keeps moving forward. Before submitting a PR — and regularly while working — pull in those changes so your fork does not fall behind.

```bash
# Fetch new commits from the original repo (not your fork)
git fetch upstream

# See what is new on upstream that you do not have
git log --oneline main..upstream/main

# Merge upstream into your local main
git switch main
git merge upstream/main

# Push the updated main to your fork on GitHub
git push origin main

# Rebase your feature branch on top of the updated main
git switch fix/webstore-api-timeout
git rebase main
```

If you do not stay in sync, your PR will have merge conflicts and reviewers will ask you to fix them before approving.

---

## 8. What makes a good pull request

The PR is what your teammates read when reviewing your work. A good PR makes review fast and approval easy.

**Good PR:**
- Title matches commit convention: `feat: add pagination to products endpoint`
- Description explains what changed and why — not just "updated server.js"
- Focused on one logical change — one feature, one fix, not five things
- Links to the related issue if one exists
- Small enough to review in one sitting

**Poor PR:**
- Title: "changes" or "WIP" or "stuff"
- Touches ten files with no common theme
- No description
- So large that reviewers skim it

The single biggest lever for fast approvals: keep PRs small. One logical change per PR. If a feature is large, break it into multiple PRs that each stand on their own.

---

## On the webstore

A second developer — charan — joins the team and needs to add a product search endpoint. They clone the repo, build in a branch, and open a PR.

```bash
# Charan clones the webstore
git clone https://github.com/AkhilTejaDoosari/webstore.git
cd webstore

# Confirm the full history came down
git log --oneline
# a1b2c3d feat: add database failover config
# c8d21fa logs: add initial server startup entry
# ...

# Create a feature branch
git switch -c feature/product-search

# Build the feature
vim api/server.js
git add api/server.js
git commit -m "feat: add product search endpoint with query param"

# Before pushing, fetch to check if main moved
git fetch origin
git log --oneline main..origin/main
# (empty — main has not moved, safe to push)

# Push the feature branch
git push origin feature/product-search

# Open PR on GitHub
# Base: main  ←  Compare: feature/product-search

# After PR is merged, clean up
git switch main
git pull
git branch -d feature/product-search
```

File 05 picks up from here — what happens when a commit needs to be undone after it has already been pushed.

---

## What breaks

| Symptom | Cause | Fix |
|---|---|---|
| `git push` rejected — "no upstream branch" | Feature branch not yet on remote | `git push origin <branch-name>` to push it for the first time |
| PR shows merge conflicts | Your branch is behind main — both changed same files | `git fetch origin`, `git rebase origin/main` on your branch, fix conflicts, push |
| `git pull` has unexpected merges | Used pull when you should have fetched first | Use `git fetch` + inspect + `git merge` separately in sensitive situations |
| Fork is behind original by many commits | Did not sync upstream regularly | `git fetch upstream`, `git merge upstream/main`, `git push origin main` |
| Branch deleted on GitHub after merge, still local | Normal — GitHub deletes remote branch after merge | `git branch -d <branch>` locally to match |
| `git remote add upstream` fails "remote already exists" | Already added it before | `git remote -v` to confirm it is correct, no action needed |

---

## Daily commands

| Command | What it does |
|---|---|
| `git clone <url>` | Download full repository to local machine |
| `git remote -v` | List all remotes with their URLs |
| `git remote add upstream <url>` | Add the original repo as upstream remote |
| `git fetch origin` | Download remote changes without merging |
| `git diff main origin/main` | See what is on remote that is not in local main |
| `git push origin <branch>` | Push a branch to remote |
| `git pull` | Fetch and merge from current tracking remote |
| `git fetch upstream` | Fetch new commits from the original repo |
| `git merge upstream/main` | Merge upstream changes into current branch |
| `git branch -d <branch>` | Delete a local branch after it is merged |

---

→ **Interview questions for this topic:** [99-interview-prep → Contribute](../99-interview-prep/README.md#contribute)
