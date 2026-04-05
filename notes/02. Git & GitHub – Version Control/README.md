<p align="center">
  <img src="../../assets/git-banner.svg" alt="git and github" width="100%"/>
</p>

[← devops-runbook](../../README.md)

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

## The Running Example

Every lab uses the same webstore project — the same app from Linux. You initialize it as a Git repository, build its commit history file by file, create feature branches, resolve conflicts, tag the first release, and push to GitHub. By the end the webstore has a complete, readable history that any engineer can clone and understand.

---

## Where You Take the Webstore

You arrive at Git with the webstore living as files on a Linux server — organized, configured, permissions set. No history. No version control. If something breaks, there is no rollback.

You leave Git with the webstore as a fully version-controlled project on GitHub — every change tracked, every decision recorded, the first release tagged as `v1.0`, and a contribution workflow in place so a second developer can work on it without stepping on your changes.

That is the state Docker picks up from. You do not containerize an unversioned project — you containerize a project with a clean commit history and a tagged release.

---

## Why Git, Not Something Else

There is no real alternative at this level. SVN is legacy. Mercurial is niche. Git won and the entire DevOps ecosystem is built around it. The question is not git vs something else — it is GitHub vs GitLab vs Bitbucket, and GitHub has the largest ecosystem, the most integrations, and the most job postings.

---

## Phases

| Phase | Topics | Lab |
|---|---|---|
| 1 — Foundations | [01 Foundations](./01-foundations/README.md) | [Lab 01](./git-labs/01-foundations-lab.md) |
| 2 — Stash & Tags | [02 Stash & Tags](./02-stash-tags/README.md) | [Lab 02](./git-labs/02-stash-tags-lab.md) |
| 3 — History & Branching | [03 History & Branching](./03-history-branching/README.md) | [Lab 03](./git-labs/03-history-branching-lab.md) |
| 4 — Contribute | [04 Contribute](./04-contribute/README.md) | [Lab 04](./git-labs/04-contribute-lab.md) |
| 5 — Undo & Recovery | [05 Undo & Recovery](./05-undo-recovery/README.md) | [Lab 05](./git-labs/05-undo-recovery-lab.md) |

---

## Labs

| Lab | Topics Covered | What You Practice |
|---|---|---|
| [Lab 01](./git-labs/01-foundations-lab.md) | Foundations | Init repo, configure identity, .gitignore, first commits, push to GitHub |
| [Lab 02](./git-labs/02-stash-tags-lab.md) | Stash & Tags | Stash mid-work, restore, tag the first release, push tags |
| [Lab 03](./git-labs/03-history-branching-lab.md) | History & Branching | Read history, fast-forward merge, 3-way merge, conflict resolution, rebase |
| [Lab 04](./git-labs/04-contribute-lab.md) | Contribute | Feature branch PR workflow, fork, upstream remote, sync fork |
| [Lab 05](./git-labs/05-undo-recovery-lab.md) | Undo & Recovery | Amend commits, revert bad commits, reset, recover with reflog |

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

Read phases in order. Each one builds on the previous.
After each phase do the lab before moving on.
The checklist at the end of every lab is not optional.

---

## What Comes Next

→ [03. Networking – Foundations](../03.%20Networking%20–%20Foundations/README.md)

Git gives you version control. Networking gives you the foundation to understand how Docker, Kubernetes, and AWS move data — before those tools make any of it look like magic.
