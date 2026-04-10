[Home](../README.md) |
[Labs Index](./README.md) |
[Lab 01](./01-foundations-lab.md) |
[Lab 02](./02-stash-tags-lab.md) |
[Lab 03](./03-history-branching-lab.md) |
[Lab 04](./04-contribute-lab.md) |
[Lab 05](./05-undo-recovery-lab.md)

---

# Lab 02 — Stash & Tags

## The Situation

The webstore is on GitHub. You are mid-way through adding an orders endpoint to the API — server.js has changes, a new config file is half written, none of it is ready to commit. Then a message arrives: a bug in the products endpoint is causing 500 errors in production. You need a clean working directory right now to investigate.

After fixing the bug you need to mark this moment. The webstore has a stable foundation — Linux configured, Git tracking everything, the first version of the API started. This is `v1.0`. You want to tag it so CI/CD pipelines can reference it, so you can always return to this exact state, and so the release is documented on GitHub.

## What this lab covers

You will simulate real mid-work interruptions on the webstore repo — stash unfinished changes, switch context, restore work, and verify nothing was lost. Then you will tag a stable release, push the tag to GitHub, and verify it appears. Every command is typed from scratch.

## Prerequisites

- [Stash & Tags notes](../02-stash-tags/README.md)
- Lab 01 completed — webstore repo must exist and be pushed to GitHub

---

## Section 1 — Set Up Work in Progress

1. Navigate to your webstore repo
```bash
cd ~/webstore-git
```

2. Start working on a new feature — add an orders endpoint
```bash
echo "// orders endpoint - work in progress" >> src/server.js
echo "app.get('/api/orders', (req, res) => {})" >> src/server.js
```

3. Also create a new file you haven't staged yet
```bash
echo "order_timeout=30" > config/orders.conf
```

4. Check what's changed
```bash
git status
git diff
```

**What to observe:** one modified file and one untracked file — not ready to commit

---

## Section 2 — Stash the Work in Progress

1. Stash with a clear message — tracked files only first
```bash
git stash push -m "WIP: webstore orders endpoint"
```

2. Check status
```bash
git status
```

**What to observe:** working tree is clean — your changes are shelved

3. Check the stash list
```bash
git stash list
```

**What to observe:** `stash@{0}: WIP: webstore orders endpoint`

4. Notice the untracked file is still there
```bash
ls config/
```

**What to observe:** `orders.conf` is still present — regular stash does not include untracked files

5. Stash properly this time — restore and stash with `-u`
```bash
git stash pop                          # restore previous stash
git stash push -u -m "WIP: webstore orders endpoint + config"
git status
```

**What to observe:** now both the modified file and untracked file are stashed — working tree completely clean

---

## Section 3 — Switch Context and Fix a Bug

1. Simulate an urgent bug fix on main
```bash
echo "// hotfix: fix null check on product id" >> src/server.js
git add src/server.js
git commit -m "fix: add null check on product id"
```

2. Check your log
```bash
git log --oneline
```

**What to observe:** the hotfix commit is there — your WIP is nowhere in the history, safely stashed

---

## Section 4 — Restore the Stashed Work

1. View what's in the stash before restoring
```bash
git stash show -p
```

**What to observe:** exact diff of what was stashed — confirm it is what you expect before applying

2. Apply and remove the stash
```bash
git stash pop
git status
```

**What to observe:** your orders endpoint changes and config file are back exactly as you left them

3. Verify the content is correct
```bash
cat src/server.js
cat config/orders.conf
```

4. Finish the work and commit it
```bash
git add .
git commit -m "feat: add webstore orders endpoint"
```

---

## Section 5 — Create a Release Tag

The webstore now has a stable foundation — initialized, committed, pushed, active development happening. This is the right moment for `v1.0`.

1. Check your current log
```bash
git log --oneline
```

2. Tag this state as version 1.0
```bash
git tag -a v1.0 -m "webstore v1.0 — initial stable release

- Linux foundation complete
- Git version control active
- API entry point and orders endpoint added
- Ready for containerization"
```

3. Verify the tag was created
```bash
git tag
```

4. View the full tag details
```bash
git show v1.0
```

**What to observe:** tag shows your name, date, message, and the commit it points to — this is an annotated tag, not just a pointer

---

## Section 6 — Tag an Older Commit

1. Find the hash of your very first commit
```bash
git log --oneline
```

2. Tag that older commit as a pre-release
```bash
git tag -a v0.1 <first-commit-hash> -m "webstore v0.1 — project skeleton"
```

3. List all tags
```bash
git tag
```

**What to observe:** both `v0.1` and `v1.0` exist — tags can point to any commit in history

---

## Section 7 — Push Tags to GitHub

1. Tags are not pushed automatically — push them explicitly
```bash
git push --tags
```

2. Open GitHub in your browser, go to your webstore repo, click **Tags**

**What to observe:** both `v0.1` and `v1.0` appear on GitHub with their messages — this is what CI/CD pipelines reference when they trigger on a release tag

---

## Section 8 — Break It on Purpose

### Break 1 — Apply a stash when there's a conflict

```bash
echo "// conflicting change" >> src/server.js
git stash push -m "WIP: test conflict"
echo "// another change to same area" >> src/server.js
git stash pop
```

**What to observe:** Git reports a merge conflict — the stash cannot apply cleanly because the same area was modified after stashing

Fix it:
```bash
git checkout -- src/server.js
git stash drop stash@{0}
```

### Break 2 — Create a duplicate tag

```bash
git tag v1.0
```

**What to observe:** `fatal: tag 'v1.0' already exists` — tag names are unique. You must delete the old tag before creating a new one at the same name.

---

## Checklist

Do not move to Lab 03 until every box is checked.

- [ ] I stashed work in progress with a meaningful message and confirmed `git status` showed a clean working tree
- [ ] I proved that `git stash` without `-u` leaves untracked files behind
- [ ] I used `git stash -u` and confirmed both modified and untracked files were stashed
- [ ] I made a commit while work was stashed and confirmed the stash was unaffected in `git log`
- [ ] I used `git stash show -p` to preview the stash before applying it
- [ ] I used `git stash pop` to restore work and verified the content was exactly correct
- [ ] I created an annotated tag with `-a` and `-m` and used `git show` to see its full details
- [ ] I tagged an older commit by its hash
- [ ] I pushed tags with `git push --tags` and confirmed both tags appear on GitHub
- [ ] I produced a stash conflict and understood why it happened
