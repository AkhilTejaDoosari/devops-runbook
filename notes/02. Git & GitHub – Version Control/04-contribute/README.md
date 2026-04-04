[← devops-runbook](../../README.md) | 
[Foundations](../01-foundations/README.md) | 
[Stash & Tags](../02-stash-tags/README.md) | 
[History & Branching](../03-history-branching/README.md) | 
[Contribute](../04-contribute/README.md) | 
[Undo & Recovery](../05-undo-recovery/README.md)

# Git Contribute  
> Fork, Clone & Pull Requests – Working with Others

---

## Table of Contents
1. [Understanding Collaboration](#1-understanding-collaboration)
2. [Forking a Repository](#2-forking-a-repository)
3. [Cloning – Bringing It to Your Local Machine](#3-cloning--bringing-it-to-your-local-machine)
4. [Remotes – origin and upstream](#4-remotes--origin-and-upstream)
5. [Pushing Changes](#5-pushing-changes)
6. [Pull Requests – Suggesting Changes](#6-pull-requests--suggesting-changes)
7. [Collaboration Flow Recap](#7-collaboration-flow-recap)

---

<details>
<summary><strong>1. Understanding Collaboration</strong></summary>

In teams or open-source projects, you rarely push directly to someone else's repository — you **propose** your changes instead.

The collaboration cycle:
```
Fork → Clone → Branch → Edit → Push → Pull Request → Review → Merge
```

**Two contexts you'll encounter:**

| Context | What you do |
|---|---|
| **Company repo** | Clone directly, work in feature branches, open PRs to main |
| **Open-source repo** | Fork first, clone your fork, open PR to original |

In DevOps day-to-day work, you'll mostly use the company repo pattern — clone, branch, PR.

</details>

---

<details>
<summary><strong>2. Forking a Repository</strong></summary>

A **fork** is a complete copy of another repository under your GitHub account.
Used mainly for open-source contributions where you don't have write access to the original.

Forking is a **GitHub feature**, not a Git command.

### Steps on GitHub
1. Navigate to the repository
2. Click **Fork** (top-right)
3. GitHub creates a copy under your account

You now have full write access to your fork.

</details>

---

<details>
<summary><strong>3. Cloning – Bringing It to Your Local Machine</strong></summary>

Clone downloads the full repository to your machine.

```bash
# Clone a repo
git clone https://github.com/username/webstore.git

# Clone into a specific folder name
git clone https://github.com/username/webstore.git my-webstore
```

After cloning:
```bash
cd webstore
git status
# On branch main — nothing to commit, working tree clean
```

</details>

---

<details>
<summary><strong>4. Remotes – origin and upstream</strong></summary>

A **remote** is a named reference to a repository hosted somewhere (GitHub, GitLab, etc).

### Check your remotes

```bash
git remote -v
```

After cloning, you have one remote named **origin** — the repo you cloned from:
```
origin  https://github.com/username/webstore.git (fetch)
origin  https://github.com/username/webstore.git (push)
```

### When you need upstream (open-source workflow)

If you forked a repo and want to stay in sync with the original:

```bash
# Add the original repo as upstream
git remote add upstream https://github.com/original-owner/webstore.git

git remote -v
# origin    https://github.com/your-username/webstore.git
# upstream  https://github.com/original-owner/webstore.git
```

Then pull updates from the original:
```bash
git fetch upstream
git merge upstream/main
```

| Remote | Purpose | Access |
|---|---|---|
| `origin` | Your fork or your team's repo | Read + Write |
| `upstream` | Original repo you forked from | Read only |

</details>

---

<details>
<summary><strong>5. Pushing Changes</strong></summary>

After making commits locally, push them to the remote:

```bash
git add .
git commit -m "add webstore product endpoint"
git push origin main
```

Or if working on a feature branch:
```bash
git push origin feature/webstore-api
```

</details>

---

<details>
<summary><strong>6. Pull Requests – Suggesting Changes</strong></summary>

A **pull request (PR)** is a proposal to merge your branch or fork into another branch.

### Company repo workflow (most common in DevOps)

```bash
git switch -c feature/webstore-api
# make changes
git push origin feature/webstore-api
```

Then on GitHub:
1. Click **Compare & Pull Request**
2. Set base branch → `main`, compare branch → `feature/webstore-api`
3. Add title and description explaining what changed and why
4. Submit — teammates review, comment, approve
5. Merge when approved

### Open-source workflow

Same steps — but you're pushing to your fork and opening a PR from your fork to the original repo.

### What makes a good PR

- One logical change per PR — easier to review and rollback
- Clear title: `feat: add webstore product pagination`
- Description explains the why, not just the what
- Link to any related issue

</details>

---

<details>
<summary><strong>7. Collaboration Flow Recap</strong></summary>

**Company repo (DevOps day-to-day):**
```
Clone → Branch → Commit → Push → Pull Request → Review → Merge
```

**Open-source contribution:**
```
Fork → Clone → Branch → Commit → Push → Pull Request → Review → Merge
```

**Essential commands:**
```bash
git clone <url>                    # get the repo locally
git switch -c feature/name         # create feature branch
git push origin feature/name       # push branch to remote
git remote -v                      # check your remotes
git fetch upstream                 # sync with original (open-source)
```

</details>

→ Ready to practice? [Go to Lab 04](../git-labs/04-contribute-lab.md)
