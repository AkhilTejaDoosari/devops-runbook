[Home](../README.md) |
[Labs Index](./README.md) |
[Lab 01](./01-foundations-lab.md) |
[Lab 02](./02-stash-tags-lab.md) |
[Lab 03](./03-history-branching-lab.md) |
[Lab 04](./04-contribute-lab.md) |
[Lab 05](./05-undo-recovery-lab.md)

---

# Lab 05 — Undo & Recovery

## The Situation

Things have gone wrong on the webstore repo. A commit has a typo in the message. A file was forgotten from a commit. A "test" commit accidentally made it to main and has already been pushed — others may have pulled it. Three experimental commits need to be squashed into one. The wrong commits were wiped with a hard reset. A branch was deleted before being merged.

None of these are unusual. They happen on real projects. The difference between a junior engineer and a confident one is not that the confident one makes fewer mistakes — it is that they know exactly how to fix each one. This lab makes you that engineer.

## What this lab covers

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

4. Fix it with amend — rewrite the last commit
```bash
git commit --amend -m "feat: add rate limiting to api"
```

5. Verify the fix
```bash
git log --oneline
```

**What to observe:** the commit hash changed — amend creates a new commit. The old one no longer exists locally.

---

## Section 2 — Amend to Add a Forgotten File

1. Make a commit but forget to include a file
```bash
echo "rate_limit=100" > config/rate-limit.conf
git add src/server.js
git commit -m "feat: add rate limit config"
```

You forgot to stage `config/rate-limit.conf`.

2. Stage the missing file and amend
```bash
git add config/rate-limit.conf
git commit --amend --no-edit
```

3. Verify both files are in the commit
```bash
git show --stat HEAD
```

**What to observe:** both `src/server.js` and `config/rate-limit.conf` appear in the commit — fixed without creating an extra commit

---

## Section 3 — Revert a Bad Commit

This is the scenario where the commit has already been pushed. Others may have pulled it. You cannot rewrite history. You add a new commit that reverses the damage.

1. Add a "bad" commit that breaks the API
```bash
echo "THIS BREAKS EVERYTHING" > src/server.js
git add src/server.js
git commit -m "feat: new approach (bad)"
```

2. Push it — simulating a commit that has reached the remote
```bash
git push origin main
```

3. Check the log
```bash
git log --oneline
```

4. Revert that commit safely — creates a new undo commit
```bash
git revert HEAD --no-edit
```

5. Check the log and file
```bash
git log --oneline
cat src/server.js
```

**What to observe:**
- A new commit appears: `Revert "feat: new approach (bad)"`
- The file is restored to its previous state
- The bad commit is still in history — revert never deletes, it only adds

6. Push the revert
```bash
git push origin main
```

---

## Section 4 — Reset (Local Only)

**Never run `reset` on commits that have been pushed to a shared branch.**

1. Make 3 experimental commits you want to clean up
```bash
echo "experiment 1" >> src/server.js && git add . && git commit -m "experiment: test 1"
echo "experiment 2" >> src/server.js && git add . && git commit -m "experiment: test 2"
echo "experiment 3" >> src/server.js && git add . && git commit -m "experiment: test 3"
```

2. Check the log
```bash
git log --oneline
```

3. Reset softly — undo 3 commits but keep changes staged
```bash
git reset --soft HEAD~3
git status
```

**What to observe:** HEAD moved back 3 commits. All changes from those 3 commits are now staged — ready to recommit as one clean commit.

4. Commit them as one clean commit
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

**What to observe:** the junk commits are gone AND the file changes are gone — `--hard` has no mercy

---

## Section 5 — Recover with Reflog

You just did a hard reset and realized you needed those commits. Reflog has them.

1. Check the reflog — it records every HEAD movement
```bash
git reflog
```

**What to observe:** every single action is recorded — the commits you wiped are visible here with their hashes

2. Find the hash of a commit you want to recover from the reflog output

3. Recover it
```bash
git reset --hard HEAD@{2}
```

**What to observe:** your commits are back — reflog saved you

4. Check the log to confirm
```bash
git log --oneline
```

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

2. Switch to main and delete the branch — simulating accidental deletion
```bash
git switch main
git branch -D feature/webstore-payments
```

3. Confirm the branch is gone
```bash
git branch
```

4. Find the deleted branch commits in reflog
```bash
git reflog
```

Look for entries mentioning `feature/webstore-payments`

5. Recover the branch
```bash
git branch feature/webstore-payments <commit-hash-from-reflog>
git switch feature/webstore-payments
git log --oneline
```

**What to observe:** your branch and all its commits are back — Git did not delete the commits, it only removed the pointer. Reflog gave you the pointer back.

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

**What to observe:** `rejected — non-fast-forward` — the remote has the original commit, you have a rewritten one with a different hash. Git refuses to overwrite shared history without force. This is why amend is only for local commits.

### Break 2 — Hard reset with uncommitted changes

```bash
echo "important unsaved work" >> README.md
git reset --hard HEAD
cat README.md
```

**What to observe:** the uncommitted change is completely gone — `--hard` erases everything in the working directory that does not have a commit. There is no reflog for uncommitted work.

---

## Checklist

Do not move to Networking until every box is checked.

- [ ] I used `git commit --amend` to fix a typo in a commit message and confirmed the hash changed
- [ ] I used `git commit --amend --no-edit` to add a forgotten file to a commit and verified with `git show --stat`
- [ ] I made a bad commit, pushed it, reverted it with `git revert`, pushed the revert, and confirmed the bad commit still exists in history
- [ ] I used `git reset --soft HEAD~3` to squash 3 commits into one clean commit
- [ ] I used `git reset --hard` and confirmed both commits and file changes were wiped
- [ ] I used `git reflog` to find commits after a hard reset and recovered them
- [ ] I deleted a branch and recovered it using a hash from `git reflog`
- [ ] I tried to push an amended commit and understood why it was rejected
- [ ] I ran `git reset --hard HEAD` with uncommitted changes and confirmed they were permanently gone
