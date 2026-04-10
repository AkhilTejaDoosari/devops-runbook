[Home](../README.md) |
[Foundations](../01-foundations/README.md) |
[Stash & Tags](../02-stash-tags/README.md) |
[History & Branching](../03-history-branching/README.md) |
[Contribute](../04-contribute/README.md) |
[Undo & Recovery](../05-undo-recovery/README.md)

# Git Contribute

The webstore is on GitHub. A second developer joins the team and needs to work on the products API. They cannot push directly to main — that is the production branch. They need their own copy to work from, a way to propose their changes for review, and a way to stay in sync when main moves forward while they are working.

This is the collaboration model. Understanding it is what separates someone who uses Git alone from someone who uses Git on a team.

---

## Table of Contents

- [1. Two Collaboration Contexts](#1-two-collaboration-contexts)
- [2. Cloning — Getting the Repo Locally](#2-cloning--getting-the-repo-locally)
- [3. Remotes — origin and upstream](#3-remotes--origin-and-upstream)
- [4. The Feature Branch PR Workflow](#4-the-feature-branch-pr-workflow)
- [5. Forking — Contributing to a Repo You Do Not Own](#5-forking--contributing-to-a-repo-you-do-not-own)
- [6. Keeping Your Fork in Sync](#6-keeping-your-fork-in-sync)
- [7. What Makes a Good Pull Request](#7-what-makes-a-good-pull-request)
- [8. Quick Reference](#8-quick-reference)

---

## 1. Two Collaboration Contexts

You will work in two different contexts depending on whether you own the repo.

| Context | When | What you do |
|---|---|---|
| **Company repo** | You are on the team, have access | Clone directly, work in feature branches, open PRs to main |
| **Open-source repo** | You do not have write access | Fork the repo first, clone your fork, open PR to the original |

In DevOps day-to-day work — your team's infrastructure repo, the webstore deployment manifests, Terraform configs — you use the company repo pattern. Fork is for contributing to projects you do not own.

---

## 2. Cloning — Getting the Repo Locally

Clone downloads the full repository to your machine — all commits, all branches, all history.

```bash
# Clone the webstore repo
git clone https://github.com/AkhilTejaDoosari/webstore.git

# Clone into a specific folder name
git clone https://github.com/AkhilTejaDoosari/webstore.git my-webstore

# After cloning
cd webstore
git log --oneline   # full history is here
git branch -a       # all branches, local and remote
```

After cloning, you have:
- A full local copy of the repository
- One remote called `origin` pointing back to GitHub
- A local `main` branch tracking `origin/main`

---

## 3. Remotes — origin and upstream

A remote is a named reference to a repository hosted somewhere else. Every connection to GitHub is a remote.

```bash
# Check what remotes you have
git remote -v
# origin  https://github.com/AkhilTejaDoosari/webstore.git (fetch)
# origin  https://github.com/AkhilTejaDoosari/webstore.git (push)
```

**`origin`** is the repo you cloned from — your team's repo or your fork. You push to origin and pull from origin.

**`upstream`** is the original repo when you have forked. You pull from upstream to stay in sync but never push to it directly.

```bash
# Add upstream (open-source workflow — after forking)
git remote add upstream https://github.com/original-owner/webstore.git

git remote -v
# origin    https://github.com/your-username/webstore.git (fetch)
# origin    https://github.com/your-username/webstore.git (push)
# upstream  https://github.com/original-owner/webstore.git (fetch)
# upstream  https://github.com/original-owner/webstore.git (push)
```

| Remote | Purpose | You push to it? |
|---|---|---|
| `origin` | Your fork or your team's repo | Yes |
| `upstream` | Original repo you forked from | No — read only |

---

## 4. The Feature Branch PR Workflow

This is what you do every day on a team. Every new piece of work — feature, fix, config change — gets its own branch. When done, you open a pull request on GitHub for review before it merges to main.

```bash
# Step 1 — start from latest main
git switch main
git pull

# Step 2 — create your feature branch
git switch -c feature/webstore-product-pagination

# Step 3 — do the work, make commits
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
# Write a clear title and description
# Submit for review

# Step 6 — after review and approval, merge on GitHub
# (or merge locally if you have permission)

# Step 7 — clean up locally after merge
git switch main
git pull                                           # get the merged commit
git branch -d feature/webstore-product-pagination  # delete the branch
```

**Why the PR exists:**
A pull request is a checkpoint. Before code merges to main — the production branch — a teammate reads it, asks questions, catches bugs, and approves. This is how teams catch mistakes before they reach production. Even on a solo project, opening a PR forces you to read your own diff one more time before merging.

---

## 5. Forking — Contributing to a Repo You Do Not Own

A fork is a complete copy of someone else's repository under your GitHub account. You have full write access to your fork. The original repo is unaffected by anything you do.

Forking is a GitHub feature, not a Git command. You fork on the GitHub website, then clone your fork to work locally.

**The open-source contribution workflow:**

```bash
# Step 1 — fork on GitHub
# github.com → original repo → Fork button (top right)
# GitHub creates a copy at: github.com/your-username/webstore

# Step 2 — clone your fork
git clone https://github.com/your-username/webstore.git
cd webstore

# Step 3 — add the original repo as upstream
git remote add upstream https://github.com/original-owner/webstore.git

# Step 4 — create a feature branch
git switch -c fix/webstore-api-timeout

# Step 5 — make changes and commit
git commit -m "fix: increase api timeout from 5s to 30s"

# Step 6 — push to your fork
git push origin fix/webstore-api-timeout

# Step 7 — open a PR from your fork to the original repo
# github.com → your fork → Compare & pull request
# Base repository: original-owner/webstore  base: main
# Head repository: your-username/webstore  compare: fix/webstore-api-timeout
```

---

## 6. Keeping Your Fork in Sync

While you work on your fork, the original repo keeps moving forward. Before you submit a PR — and regularly while working — you need to pull in those changes so your fork does not fall behind.

```bash
# Fetch all new commits from the original repo
git fetch upstream

# See what is new
git log --oneline main..upstream/main

# Merge upstream changes into your local main
git switch main
git merge upstream/main

# Push the updated main to your fork on GitHub
git push origin main

# Rebase your feature branch on top of the updated main
git switch fix/webstore-api-timeout
git rebase main
```

If you do not stay in sync, your PR will have merge conflicts and may be rejected until you resolve them.

---

## 7. What Makes a Good Pull Request

The PR is what your teammates read when reviewing your work. A good PR makes review fast and approval easy. A poor PR makes review painful and delays the merge.

**A good PR:**
- Has a clear title that matches the commit convention: `feat: add pagination to products endpoint`
- Explains what changed and why — not just "updated server.js"
- Is focused on one logical change — one feature, one fix, not five things at once
- Links to the related issue if one exists
- Is small enough to review in one sitting — the bigger the PR, the less thorough the review

**A poor PR:**
- Title: "changes" or "WIP" or "stuff"
- Touches ten different files with no common theme
- Has no description
- Is so large that reviewers skim it

The single biggest lever for getting PRs approved quickly: keep them small. One logical change per PR. If a feature is large, break it into multiple PRs that each stand on their own.

---

## 8. Quick Reference

| Command | What it does |
|---|---|
| `git clone <url>` | Download full repository to local machine |
| `git remote -v` | List all remotes |
| `git remote add upstream <url>` | Add the original repo as upstream |
| `git fetch upstream` | Fetch new commits from upstream without merging |
| `git merge upstream/main` | Merge upstream changes into current branch |
| `git push origin <branch>` | Push a branch to your remote |
| `git switch -c feature/<n>` | Create and switch to feature branch |
| `git pull` | Fetch and merge from current tracking remote |

---

→ Ready to practice? [Go to Lab 04](../git-labs/04-contribute-lab.md)
