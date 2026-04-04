[← devops-runbook](../../README.md) |
[Labs Index](./README.md) |
[Lab 01](./01-foundations-lab.md) |
[Lab 02](./02-stash-tags-lab.md) |
[Lab 03](./03-history-branching-lab.md) |
[Lab 04](./04-contribute-lab.md) |
[Lab 05](./05-undo-recovery-lab.md)

---

# Lab 05 — Undo & Recovery

## What this lab is about

You will intentionally make mistakes on the webstore repo and fix every one of them — wrong commit message, forgotten file, bad commit that needs reverting, accidental reset, deleted branch. By the end you will trust Git's safety net and know exactly which tool to reach for in each situation. Every command is typed from scratch.

## Prerequisites

- [Undo & Recovery notes](../05-undo-recovery/README.md)
- Lab 04 completed — webstore repo with commit history

---

## Section 1 — Amend a Commit

1. Navigate to your webstore repo
```bash
cd ~/webstore-git
git switch main
```

2. Make a commit with a typo in the message
```bash
echo "// rate limiter" >> src/server.js
git add src/server.js
git commit -m "feat: addd rate limitting to api"
```

3. Check the log — see the typo
```bash
git log --oneline
```

4. Fix it with amend
```bash
git commit --amend -m "feat: add rate limiting to api"
```

5. Verify the fix
```bash
git log --oneline
```

**What to observe:** the commit hash changed — amend creates a new commit

---

## Section 2 — Amend to Add a Forgotten File

1. Make a commit but forget to include a file
```bash
echo "rate_limit=100" > config/rate-limit.conf
git add src/server.js
git commit -m "feat: add rate limit config"
```

Wait — you forgot to include `config/rate-limit.conf`.

2. Stage the missing file and amend
```bash
git add config/rate-limit.conf
git commit --amend --no-edit
```

3. Verify both files are in the commit
```bash
git show --stat HEAD
```

**What to observe:** both `src/server.js` and `config/rate-limit.conf` appear in the commit

---

## Section 3 — Revert a Bad Commit

1. Add a "bad" commit that breaks something
```bash
echo "THIS BREAKS EVERYTHING" > src/server.js
git add src/server.js
git commit -m "feat: new approach (bad)"
```

2. Check the log
```bash
git log --oneline
```

3. Revert that commit — safely creates a new undo commit
```bash
git revert HEAD --no-edit
```

4. Check the log and file
```bash
git log --oneline
cat src/server.js
```

**What to observe:**
- A new commit appears: `Revert "feat: new approach (bad)"`
- The file is restored to its previous state
- The bad commit is still in history — revert never deletes

---

## Section 4 — Reset (Local Only)

1. Make 3 experimental commits you want to undo
```bash
echo "experiment 1" >> src/server.js && git add . && git commit -m "experiment: test 1"
echo "experiment 2" >> src/server.js && git add . && git commit -m "experiment: test 2"
echo "experiment 3" >> src/server.js && git add . && git commit -m "experiment: test 3"
```

2. Check the log
```bash
git log --oneline
```

3. Reset softly to 3 commits ago — keeps changes staged
```bash
git reset --soft HEAD~3
git status
```

**What to observe:** HEAD moved back 3 commits, but all changes are staged and ready to recommit as one clean commit

4. Commit them as one
```bash
git commit -m "feat: add experimental features as single commit"
```

5. Now make more commits and try hard reset
```bash
echo "junk 1" >> src/server.js && git add . && git commit -m "junk: test a"
echo "junk 2" >> src/server.js && git add . && git commit -m "junk: test b"
```

6. Hard reset — completely wipes the commits AND the file changes
```bash
git reset --hard HEAD~2
git log --oneline
cat src/server.js
```

**What to observe:** the junk commits are gone AND the file changes are gone

---

## Section 5 — Recover with Reflog

1. You just did a hard reset and realize you need those commits back

2. Check the reflog — it records everything
```bash
git reflog
```

**What to observe:** every HEAD movement is recorded — you can see the commits you just wiped

3. Find the hash of a commit you want to recover from the reflog output

4. Recover it
```bash
git reset --hard HEAD@{2}
```

**What to observe:** your commits are back — reflog saved you

---

## Section 6 — Recover a Deleted Branch

1. Create a branch and make commits on it
```bash
git switch -c feature/webstore-payments
echo "// payments module" >> src/server.js
git add . && git commit -m "feat: add payments module stub"
echo "stripe_key=test_key" > config/payments.conf
git add . && git commit -m "chore: add payments config"
```

2. Switch to main and delete the branch (simulating accidental deletion)
```bash
git switch main
git branch -D feature/webstore-payments
```

3. The branch is gone
```bash
git branch
```

4. Find the deleted branch commits in reflog
```bash
git reflog
```

Look for the commit hash from `feature/webstore-payments`

5. Recover the branch
```bash
git branch feature/webstore-payments <commit-hash-from-reflog>
git switch feature/webstore-payments
git log --oneline
```

**What to observe:** your branch and all its commits are back

6. Clean up
```bash
git switch main
git branch -D feature/webstore-payments
```

---

## Section 7 — Break It on Purpose

### Break 1 — Amend a pushed commit

```bash
# Push current state
git push origin main

# Now amend the last commit
git commit --amend -m "amended after push"

# Try to push
git push origin main
```

**What to observe:** `rejected — non-fast-forward` — you cannot push amended commits to a shared branch without force

**Why this matters:** this is why amend is only for local commits.

### Break 2 — Hard reset with uncommitted changes

```bash
echo "important unsaved work" >> README.md
git reset --hard HEAD
cat README.md
```

**What to observe:** the uncommitted change is gone — `--hard` has no mercy on unstaged work

---

## Checklist

- [ ] I used `git commit --amend` to fix a typo in a commit message and confirmed the hash changed
- [ ] I used `git commit --amend` to add a forgotten file to a commit and verified with `git show --stat`
- [ ] I made a bad commit, reverted it with `git revert`, and confirmed the bad commit still exists in history
- [ ] I used `git reset --soft HEAD~3` to squash 3 commits into one clean commit
- [ ] I used `git reset --hard` and confirmed both commits and file changes were wiped
- [ ] I used `git reflog` to find and recover commits after a hard reset
- [ ] I deleted a branch and recovered it using a hash from `git reflog`
- [ ] I tried to push an amended commit and understood why it was rejected
