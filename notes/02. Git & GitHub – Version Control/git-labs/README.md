[Home](../README.md) |
[Labs Index](./README.md) |
[Lab 01](./01-foundations-lab.md) |
[Lab 02](./02-stash-tags-lab.md) |
[Lab 03](./03-history-branching-lab.md) |
[Lab 04](./04-contribute-lab.md) |
[Lab 05](./05-undo-recovery-lab.md)

---

# Git Labs

Hands-on sessions for every phase in the Git notes.

Do them in order. Do not move to the next lab until the checklist at the bottom is fully checked.

---

## The Project Thread

These five labs are not isolated exercises. They are five stages in the life of the webstore project — the same project you built in Linux — as it gains version control, a public presence on GitHub, and the collaborative workflow a real team uses.

By the time you finish Lab 05 you will have a versioned webstore on GitHub with a clean commit history, a tagged release, feature branches, a merged pull request, and the confidence to recover from any Git mistake. That is the state Docker picks up from — a project with history worth tracking before containerization.

| Lab | Where the webstore is | What you do |
|---|---|---|
| [Lab 01](./01-foundations-lab.md) | Files on disk, no version control | Initialize the repo, make the first commits, push to GitHub — the project becomes trackable |
| [Lab 02](./02-stash-tags-lab.md) | On GitHub, active development | Interrupt yourself mid-work, stash, fix a bug, restore — then tag v1.0 as the first stable release |
| [Lab 03](./03-history-branching-lab.md) | v1.0 tagged, new features needed | Build features in isolation on branches, merge them, resolve conflicts, keep history linear with rebase |
| [Lab 04](./04-contribute-lab.md) | Active team, features being built | Practice the full PR workflow — feature branch, push, review, merge — then the open-source fork workflow |
| [Lab 05](./05-undo-recovery-lab.md) | Something went wrong | Fix every category of Git mistake — wrong message, bad commit, accidental reset, deleted branch |

---

## Labs

| Lab | Topics Covered | What You Practice |
|---|---|---|
| [Lab 01](./01-foundations-lab.md) | Foundations | Init repo, configure identity, .gitignore, first commits, push to GitHub |
| [Lab 02](./02-stash-tags-lab.md) | Stash & Tags | Stash mid-work, restore, tag the first release, push tags |
| [Lab 03](./03-history-branching-lab.md) | History & Branching | Read history, fast-forward merge, 3-way merge, conflict resolution, rebase |
| [Lab 04](./04-contribute-lab.md) | Contribute | Feature branch PR workflow, fork, upstream remote, sync fork |
| [Lab 05](./05-undo-recovery-lab.md) | Undo & Recovery | Amend commits, revert bad commits, reset, recover with reflog |

---

## How to Use These Labs

Read the notes for each phase before opening a terminal. Every lab assumes you have read the corresponding notes file first.

Write every command from scratch. Do not copy-paste. Typing forces your brain to process each flag and each decision.

Every lab has a "Break It on Purpose" section. Do not skip it. These are the failure states you will actually hit — seeing the error yourself and fixing it is the point.

Do not move to the next lab until every box in the checklist is checked. If you cannot check a box honestly, go back and do it properly.
