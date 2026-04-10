<p align="center">
  <img src="../../assets/git-banner.svg" alt="git and github" width="100%"/>
</p>

[← devops-runbook](../../README.md) |
[Foundations](./01-foundations/README.md) |
[Stash & Tags](./02-stash-tags/README.md) |
[History & Branching](./03-history-branching/README.md) |
[Contribute](./04-contribute/README.md) |
[Undo & Recovery](./05-undo-recovery/README.md) |
[Interview](./99-interview-prep/README.md)

---

Version control, branching, collaboration, and recovery — built around one real project from first commit to open-source contribution workflow.

---

## Why Git — and Why GitHub

Git is not optional in this stack. Every other tool in this runbook depends on it. GitHub Actions triggers on Git commits. Docker images are tagged with Git commit SHAs. Terraform state is version controlled. ArgoCD watches a Git repo and deploys whatever is in it. Git is the source of truth that everything else reads from.

GitHub is the platform because it is where the jobs are. GitHub Actions, pull requests, branch protection rules, and the open-source ecosystem all live here. GitLab and Bitbucket use the same Git — different UI, smaller footprint in DevOps hiring.

---

## Prerequisites

**Complete first:** [01. Linux – System Fundamentals](../01.%20Linux%20–%20System%20Fundamentals/README.md)

You need to be comfortable in the terminal — navigating directories, editing files with vim, and running commands — before Git will make sense as a tool. The webstore directory you built in Linux becomes the first Git repository you initialize here.

---

## The Architecture

Every Git command is a movement between zones. Know the zones — every command makes sense.

```
  YOUR MACHINE
  ───────────────────────────────────────────────────────────────────────────────

  ┌─────────────────┐      ┌─────────────────┐      ┌──────────────────────────┐
  │                 │      │                 │      │                          │
  │  Working        │      │  Staging area   │      │  Local repo  (.git/)     │
  │  directory      │      │  (.git/index)   │      │                          │
  │                 │      │                 │      │  • full commit history   │
  │  your files     │      │  files chosen   │      │  • all branches          │
  │  what you edit  │      │  for the next   │      │  • all tags              │
  │                 │      │  commit         │      │  • works fully offline   │
  └─────────────────┘      └─────────────────┘      └──────────────────────────┘
          │                        │                            │
          │  ── git add ────────►  │                            │
          │  ◄─ git restore──────  │                            │
          │  ────staged ──────────►  (unstage back)             │
          │                        │  ── git commit ──────────► │
          │                        │  ◄─ git reset ──────────── │
          │                        │     (soft/mixed/hard)      │
          │                                                     │
          │  ◄─────────────── git checkout / git switch ─────── │
          │  ◄─────────────── git restore <file> ────────────── │


  WHAT EACH COMMAND SEES
  ─────────────────────────────────────────────────────────────────────────────
  git status        working dir + staging area   never sees the remote
  git log           local repo commits           stale until git fetch
  git diff          working dir  vs  staging
  git diff --staged staging      vs  last commit
  git diff HEAD     working dir  vs  last commit


  BRANCHES AND HEAD  (inside the local repo)
  ─────────────────────────────────────────────────────────────────────────────

  a3f92c1 ◄── b71e3a2 ◄── c8d21fa   ←  main  ←  HEAD
                                ↑
               every commit points back to its parent

  main branch: a3f92c1 ◄── b71e3a2 ◄── c8d21fa  ←  HEAD
                                              ↘
  feature branch:                               d1a3c22 ◄── e8f90ab  ←  HEAD


  GITHUB  (the remote)
  ───────────────────────────────────────────────────────────────────────────────

  ┌──────────────────────────────────────────────────────────────────────────────┐
  │  origin   →  github.com/AkhilTejaDoosari/webstore                            │
  │                                                                              │
  │  your fork or your team repo — you push here, PRs open here                  │
  │  GitHub Actions triggers on every push to main                               │
  │  ArgoCD watches main — deploys to cluster when it changes                    │
  └──────────────────────────────────────────────────────────────────────────────┘
  ┌──────────────────────────────────────────────────────────────────────────────┐
  │  upstream →  github.com/original-owner/webstore                              │
  │                                                                              │
  │  the repo you forked from — pull to stay in sync, never push to it           │
  └──────────────────────────────────────────────────────────────────────────────┘

  local repo  ──── git push ────────────────────────────────────► origin
  local repo  ◄─── git fetch ───────────────────────────────────  origin / upstream
  working dir ◄─── git pull  (fetch + merge) ───────────────────  origin
  all zones   ◄─── git clone (first time only) ─────────────────  origin


  THE DAILY WORKFLOW
  ─────────────────────────────────────────────────────────────────────────────
  git status  →  git add .  →  git commit -m ""  →  git push
```

---

## Where You Take the Webstore

You arrive at Git with the webstore living as files on a Linux server — organized, configured, permissions set. No history. No version control. If something breaks, there is no rollback.

You leave Git with the webstore as a fully version-controlled project on GitHub — every change tracked, every decision recorded, the first release tagged as `v1.0`, and a contribution workflow in place so a second developer can work on it without stepping on your changes.

That is the state Docker picks up from. You do not containerize an unversioned project — you containerize a project with a clean commit history and a tagged release.

---

## Why Git, Not Something Else

There is no real alternative at this level. SVN is legacy. Mercurial is niche. Git won and the entire DevOps ecosystem is built around it. The question is not git vs something else — it is GitHub vs GitLab vs Bitbucket, and GitHub has the largest ecosystem, the most integrations, and the most job postings.

---

## Files — Read in This Order

| # | File | What it covers | After reading this you can |
|---|---|---|---|
| 01 | [Foundations](./01-foundations/README.md) | init, config, three states, commit, .gitignore, remote, push | Start a repo from scratch, make commits, push to GitHub |
| 02 | [Stash & Tags](./02-stash-tags/README.md) | stash workflow, annotated tags, releases | Pause mid-work cleanly, tag v1.0, mark stable releases |
| 03 | [History & Branching](./03-history-branching/README.md) | git log, branches, merge types, conflicts, rebase | Read project history, build features in isolation, merge without breaking things |
| 04 | [Contribute](./04-contribute/README.md) | clone, remotes, PR workflow, fork, upstream sync | Work on a team repo, open PRs, contribute to open source |
| 05 | [Undo & Recovery](./05-undo-recovery/README.md) | amend, revert, reset, reflog | Fix any mistake — wrong commit, bad push, deleted branch |

---

## What You Can Do After This

- Track and version any project with confidence
- Write clean commit history that teammates can read
- Create and merge branches without breaking anything
- Resolve merge conflicts without panicking
- Rebase feature branches to keep history linear
- Recover from any mistake using reflog
- Contribute to team repos and open-source projects via PRs
- Tag releases that CI/CD pipelines can reference

---

## How to Use This

Read files in order. Each one builds on the previous.
Do the "On the webstore" section in every file before moving on.
The webstore must be in the state described at the end of each file.

---

## What Comes Next

→ [03. Networking – Foundations](../03.%20Networking%20–%20Foundations/README.md)

Git gives you version control. Networking gives you the foundation to understand how Docker, Kubernetes, and AWS move data — before those tools make any of it look like magic.
