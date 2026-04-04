[Home](../README.md) |
[Labs Index](./README.md) |
[Lab 01](./01-foundations-lab.md) |
[Lab 02](./02-stash-tags-lab.md) |
[Lab 03](./03-history-branching-lab.md) |
[Lab 04](./04-contribute-lab.md) |
[Lab 05](./05-undo-recovery-lab.md)

---

# Lab 04 — Contribute

## What this lab is about

You will practice the full collaboration workflow used in real DevOps teams — create a feature branch, push it to GitHub, open a pull request, merge it, and verify the result. You will also simulate the open-source fork workflow. Every command is typed from scratch.

## Prerequisites

- [Contribute notes](../04-contribute/README.md)
- Lab 03 completed — webstore repo pushed to GitHub
- A GitHub account

---

## Section 1 — The Company Repo Workflow (Daily DevOps)

This is what you do on every real job — no forking, just feature branches and PRs.

1. Navigate to your webstore repo
```bash
cd ~/webstore-git
git switch main
git pull
```

2. Create a feature branch following the naming convention
```bash
git switch -c feature/webstore-product-search
```

3. Make meaningful changes
```bash
cat >> src/server.js << 'EOF'

// product search endpoint
// GET /api/products?q=keyword
// returns filtered product list
EOF
```

4. Stage and commit
```bash
git add src/server.js
git commit -m "feat: add product search endpoint stub"
```

5. Add another commit on the branch
```bash
echo "search_max_results=50" >> config/webstore.conf
git add config/webstore.conf
git commit -m "chore: add search config to webstore.conf"
```

6. Push the feature branch to GitHub
```bash
git push origin feature/webstore-product-search
```

7. Open GitHub in your browser — you'll see a prompt: **"Compare & pull request"** — click it

8. Fill in the PR:
   - Title: `feat: add product search endpoint`
   - Description: `Adds a stub for the product search endpoint. Config added for max results limit.`
   - Base branch: `main`
   - Compare branch: `feature/webstore-product-search`

9. Submit the pull request

10. Review your own PR — read the diff on GitHub

11. Merge the PR on GitHub using **"Merge pull request"**

12. Pull the merged changes back to your local main
```bash
git switch main
git pull
git log --oneline
```

**What to observe:** your feature commits are now on main

13. Delete the local feature branch (it's merged)
```bash
git branch -d feature/webstore-product-search
```

---

## Section 2 — Check Your Remotes

1. View all configured remotes
```bash
git remote -v
```

**What to observe:** `origin` points to your GitHub repo

2. Rename and re-add to understand the pattern (optional exercise)
```bash
git remote rename origin backup-origin
git remote -v
git remote rename backup-origin origin
git remote -v
```

---

## Section 3 — Simulate the Open-Source Fork Workflow

For this section you'll fork a public repo and practice the full open-source flow.

1. On GitHub, find any small public repo to practice with (or create a second test repo under your account)

2. Fork it by clicking **Fork** on GitHub

3. Clone YOUR fork (not the original)
```bash
git clone https://github.com/YOUR_USERNAME/forked-repo.git
cd forked-repo
```

4. Check your remotes
```bash
git remote -v
```

**What to observe:** only `origin` — pointing to your fork

5. Add the original repo as upstream
```bash
git remote add upstream https://github.com/ORIGINAL_OWNER/forked-repo.git
git remote -v
```

**What to observe:** now you have both `origin` (your fork) and `upstream` (original)

6. Create a feature branch
```bash
git switch -c fix/typo-in-readme
```

7. Make a small change
```bash
echo "<!-- minor fix -->" >> README.md
git add README.md
git commit -m "docs: fix typo in README"
```

8. Push to YOUR fork
```bash
git push origin fix/typo-in-readme
```

9. On GitHub — open a PR from your fork to the original repo

**What to observe:** GitHub shows `base repository: original` ← `head repository: your-fork`

---

## Section 4 — Sync Fork with Upstream

1. Fetch updates from the original repo
```bash
git fetch upstream
```

2. Merge upstream changes into your local main
```bash
git switch main
git merge upstream/main
```

3. Push the synced main to your fork
```bash
git push origin main
```

**What to observe:** your fork is now in sync with the original

---

## Section 5 — Break It on Purpose

### Break 1 — Push to main directly (what teams prevent)

```bash
git switch main
echo "direct change" >> README.md
git add . && git commit -m "chore: direct commit to main"
git push origin main
```

**What to observe:** it works — but in a real team, branch protection rules on GitHub would block this. This is why teams enable **branch protection** on main.

### Break 2 — Open a PR with no differences

```bash
git switch -c feature/empty-branch
git push origin feature/empty-branch
```

Open a PR on GitHub between this branch and main.

**What to observe:** GitHub shows "This branch is up to date with main" — nothing to merge

Clean up:
```bash
git switch main
git branch -d feature/empty-branch
git push origin --delete feature/empty-branch
```

---

## Checklist

Do not move to Lab 05 until every box is checked.

- [ ] I created a feature branch, made commits, pushed it, and opened a PR on GitHub
- [ ] I reviewed the diff on GitHub before merging
- [ ] I merged the PR and pulled the changes back to local main
- [ ] I confirmed the feature branch commits appear in `git log --oneline` on main after merge
- [ ] I forked a public repo, added upstream remote, and confirmed both `origin` and `upstream` appear in `git remote -v`
- [ ] I synced my fork with upstream using `git fetch upstream` and `git merge upstream/main`
- [ ] I understood why pushing directly to main is an anti-pattern on real teams
