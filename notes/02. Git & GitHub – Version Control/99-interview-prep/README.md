[Home](../README.md) |
[Foundations](../01-foundations/README.md) |
[Stash & Tags](../02-stash-tags/README.md) |
[History & Branching](../03-history-branching/README.md) |
[Contribute](../04-contribute/README.md) |
[Undo & Recovery](../05-undo-recovery/README.md) |
[Interview](../99-interview-prep/README.md)

---

# Interview Prep — Git

> Read the notes files first. Come here the day before an interview.
> Each answer is 30 seconds. No more. That is what interviewers want.

---

## Table of Contents

- [Git Foundations](#git-foundations)
- [Stash and Tags](#stash-and-tags)
- [History and Branching](#history-and-branching)
- [Contribute](#contribute)
- [Undo and Recovery](#undo-and-recovery)

---

## Git Foundations

**What is Git and why does every DevOps tool depend on it?**

Git is a distributed version control system — it tracks every change to a project as a permanent snapshot. In DevOps, it is the source of truth that everything downstream reads from. GitHub Actions triggers on Git commits. Docker images are tagged with Git commit SHAs. Terraform state is version controlled. ArgoCD watches a Git repo and deploys whatever is in it. Without Git, none of those tools know what to build or deploy.

**What is the difference between the working directory, staging area, and local repo?**

The working directory is where you edit files — what you see in your editor. The staging area is where you explicitly choose what goes into the next commit — a holding area where you decide exactly what this snapshot contains. The local repo is the committed history — permanent, immutable, stored in `.git/`. The three-step flow is: edit in working dir, `git add` to staging, `git commit` to repo.

**Why does the staging area exist?**

Without a staging area, every `git commit` would include everything you touched since the last commit. The staging area lets you commit partial work — you edited five files but only three are ready, so you stage those three as one logical change and leave the other two in progress. It gives you control over exactly what each commit contains.

**What does `git init` actually do?**

It creates a hidden `.git/` folder inside the directory. That folder IS the entire repository — every commit, every branch, every tag is stored there. Before `git init`, the directory is just files. After it, the directory has version control. The `.git/` folder is what makes the difference.

**What belongs in `.gitignore` and why must it be created before the first commit?**

Secrets and credentials (`.env`, API keys), build output (`dist/`, `build/`), runtime data (`*.log`), dependencies (`node_modules/`), and infrastructure state files (`*.tfstate`). It must be created before the first `git add .` because Git history is immutable — if you commit a secret, it is in the history permanently even after you delete the file. Anyone who clones the repo can access it by looking at the history.

---

## Stash and Tags

**What is `git stash` and when do you use it?**

Stash saves your in-progress changes to a temporary shelf and gives you back a clean working directory — without creating a commit. You use it when you are mid-feature and something urgent comes in that requires a clean state to fix. After fixing, `git stash pop` restores your changes exactly where you left them. Stash is local, expires after 90 days, and is not a substitute for branches on work lasting more than a day.

**What is the difference between `git stash pop` and `git stash apply`?**

Both apply the stash to your working directory, but `pop` removes it from the stash stack after applying and `apply` leaves it on the stack. Use `pop` for the normal restore workflow. Use `apply` when you want to apply the same stash to multiple branches without losing it from the stack.

**What does `git stash -u` do and when do you need it?**

`-u` stands for `--include-untracked`. By default `git stash` only saves tracked files — files Git already knows about. New files you created but have not yet run `git add` on are untracked and left behind. `git stash -u` includes those new files in the stash.

**What is the difference between a lightweight tag and an annotated tag?**

A lightweight tag is just a pointer to a commit — a name with no metadata. An annotated tag contains a pointer plus the tagger's identity, a date, and a message. Always use annotated tags (`git tag -a`) for releases — they appear correctly on GitHub's releases page, carry your identity, and are what CI/CD pipelines expect when they trigger on a tagged push.

**Why are tags not pushed automatically with `git push`?**

By design — tags are permanent markers and pushing them to a shared remote is an intentional act. A `git push` sends your commits but not your tags. You push a tag explicitly with `git push origin v1.0` or push all tags at once with `git push --tags`. This prevents accidentally publishing tags that were meant to be local.

---

## History and Branching

**What is a branch in Git?**

A branch is a lightweight pointer to a commit. When you create a branch, Git creates a new pointer at your current commit. When you make commits on that branch, only that pointer moves forward — other branches stay exactly where they were. This is why branches are cheap to create — Git is not copying files, it is just creating a new reference.

**What is HEAD in Git?**

HEAD is a pointer that tells Git which branch — and therefore which commit — you are currently on. When you switch branches, HEAD moves. When you make a commit, HEAD's branch pointer moves forward to the new commit. When you see "detached HEAD" in the terminal, it means HEAD is pointing directly at a commit instead of a branch.

**What is the difference between a fast-forward merge and a 3-way merge?**

A fast-forward merge happens when the base branch has not moved since the feature branch was created — Git simply moves the branch pointer forward, no merge commit is created, history stays linear. A 3-way merge happens when both branches have moved since they diverged — Git creates a merge commit that combines both lines of history. The 3-way merge requires three commits to resolve: the common ancestor plus the two branch tips.

**What is the golden rule of rebase?**

Never rebase commits that have already been pushed to a shared branch. Rebase rewrites commit hashes — if someone else already pulled those commits, their local history now diverges from yours and they will have conflicts when they try to push or pull. Rebase is safe on a local feature branch you have not pushed yet, or on a personal branch nobody else has pulled.

**What is the difference between `git merge` and `git rebase`?**

Both integrate changes from one branch into another. Merge creates a merge commit that preserves the full branch history — you can see when the branch diverged and merged. Rebase replays your commits on top of another branch tip, creating new commit hashes and a linear history with no merge commit. Use merge to bring completed features into main. Use rebase to update a feature branch with the latest main before merging.

---

## Contribute

**What is the difference between `git fetch` and `git pull`?**

`git fetch` downloads new commits from the remote into your local repo but does not touch your working directory or current branch — your files are unchanged. `git pull` is `git fetch` plus `git merge` in one command — it downloads and immediately merges into your current branch. Use `git fetch` when you want to see what changed before merging. Use `git pull` in your daily workflow when you just want to be up to date.

**What is the difference between `origin` and `upstream`?**

`origin` is the remote you cloned from — your team's repo or your fork. You push to origin and open PRs against it. `upstream` is the original repo you forked from in an open-source workflow. You pull from upstream to stay in sync with what the project maintainers are doing, but you never push to it directly — you only have read access.

**What is a pull request and why does it exist?**

A pull request is a proposal to merge one branch into another, with a built-in code review step before the merge happens. Before code reaches main — the production branch — a teammate reads the diff, asks questions, catches bugs, and approves. The PR is how teams prevent mistakes from reaching production. It also creates a documented record of what changed, why, and who approved it.

**Walk me through the feature branch PR workflow.**

Start from latest main with `git pull`. Create a feature branch with `git switch -c feature/name`. Make commits on the branch. Push it to GitHub with `git push origin feature/name`. Open a pull request on GitHub — base is main, compare is the feature branch. A teammate reviews and approves. Merge happens on GitHub. Clean up locally: `git switch main`, `git pull`, `git branch -d feature/name`.

**How do you keep a fork in sync with the original repo?**

Add the original repo as a second remote called `upstream` with `git remote add upstream <url>`. Run `git fetch upstream` to pull in new commits without merging. Switch to main and `git merge upstream/main` to integrate them. Push the updated main to your fork with `git push origin main`. Then rebase your feature branch on top of the updated main.

---

## Undo and Recovery

**What is the critical question before choosing a recovery command?**

Has the commit been pushed? If not pushed — you can rewrite history with `amend` or `reset`. If already pushed — you cannot rewrite shared history because others may have pulled it. Use `revert` instead, which adds a new commit that undoes the bad one without touching history.

**What is the difference between `git revert` and `git reset`?**

`git revert` creates a new commit that exactly reverses a specific earlier commit — the original commit stays in history, a new one records the reversal. It is safe on pushed commits because it adds to history rather than rewriting it. `git reset` moves HEAD back to a previous commit, removing commits from history. It is only safe on local commits that have not been pushed.

**What are the three modes of `git reset` and when do you use each?**

`--soft` undoes the commit but keeps all changes staged and ready to recommit — use when you want to redo the commit differently. `--mixed` (the default) undoes the commit and unstages the changes — they are in your working directory for you to review and re-stage selectively. `--hard` undoes the commit and permanently erases all changes — use when you want to completely discard the work. Hard is the dangerous one.

**What is `git reflog` and why is it the last line of defense?**

`reflog` records every time HEAD moved — every commit, checkout, reset, merge, rebase. Even after a `--hard` reset or deleting a branch, the commits still exist in Git's object store for 90 days. `reflog` shows you the hash of every state HEAD was in. If you lost commits after a reset or deleted a branch, find the hash in reflog and `git reset --hard <hash>` or recreate the branch with `git branch <n> <hash>`.

**You committed a secret to a public GitHub repo. What do you do?**

First — rotate the secret immediately. Delete the API key, change the password, invalidate the token. Anyone who has already seen the repo may have the credential. Second — remove it from history using `git filter-branch` or the BFG Repo Cleaner, then force push. Third — add it to `.gitignore` so it cannot be committed again. The critical point: deleting the file and pushing a new commit is not enough. The secret is still in the commit history and anyone who clones the repo can find it.
