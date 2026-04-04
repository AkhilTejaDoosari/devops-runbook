<p align="center">
  <img src="../../assets/git-banner.svg" alt="git and github" width="100%"/>
</p>

[← devops-runbook](../../README.md)

---

Version control, branching, collaboration, and recovery — built around one real project from first commit to open-source contribution workflow.

---

## Prerequisites

**Complete first:** [01. Linux – System Fundamentals](../01.%20Linux%20–%20System%20Fundamentals/README.md)

You need to be comfortable in the terminal — navigating directories, editing files with vim, and running commands — before Git will make sense as a tool.

---

## The Running Example

Every lab uses the same webstore project — the same app from Linux.  
You initialize it as a Git repo, build its history commit by commit, branch and merge features, and push to GitHub.

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
| [Lab 02](./git-labs/02-stash-tags-lab.md) | Stash & Tags | Stash mid-work, restore, tag releases, push tags |
| [Lab 03](./git-labs/03-history-branching-lab.md) | History & Branching | Read history, fast-forward merge, 3-way merge, conflict resolution, rebase |
| [Lab 04](./git-labs/04-contribute-lab.md) | Contribute | Feature branch PR workflow, fork, upstream remote, sync fork |
| [Lab 05](./git-labs/05-undo-recovery-lab.md) | Undo & Recovery | Amend commits, revert bad commits, reset, recover with reflog |

---

## How to Use This

Read phases in order. Each one builds on the previous.  
After each phase do the lab before moving on.  
The checklist at the end of every lab is not optional.

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

## What Comes Next

→ [03. Networking – Foundations](../03.%20Networking%20–%20Foundations/README.md)

Git gives you version control for code. Networking gives you the foundation that makes Docker, Kubernetes, and AWS actually make sense — bridge networks, DNS resolution, NAT, and firewalls are not magic once you understand how packets travel.
