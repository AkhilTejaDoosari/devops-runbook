[Home](../README.md) | 
[Foundations](../01-foundations/README.md) | 
[Stash & Tags](../02-stash-tags/README.md) | 
[History & Branching](../03-history-branching/README.md) | 
[Contribute](../04-contribute/README.md) | 
[Undo & Recovery](../05-undo-recovery/README.md)

# Git Stash & Tags  
> Managing Work in Progress and Marking Milestones

---

## Table of Contents  
- [1. Git Stash – Pausing Unfinished Work](#1-git-stash--pausing-unfinished-work)  
- [2. Git Tags – Marking Versions and Releases](#2-git-tags--marking-versions-and-releases)

---

<details>
<summary><strong>1. Git Stash – Pausing Unfinished Work</strong></summary>

### Why Git Stash Exists  
Sometimes you need to switch tasks, fix a bug, or test something quickly, but your current work isn't ready to commit.  
**Git stash** acts like a temporary *shelf* for unfinished changes — letting you save progress, return to a clean state, and restore your work later.

---

### Key Commands for Stashing  
| Command | Description |
|---|---|
| `git stash` | Save tracked changes (staged + unstaged) |
| `git stash -u` | Include new/untracked files |
| `git stash push -m "message"` | Stash with a custom message |
| `git stash list` | Show all saved stashes |
| `git stash show [-p]` | Show summary (`-p` = full diff) |
| `git stash apply [stash@{n}]` | Re-apply stash (keeps it in list) |
| `git stash pop [stash@{n}]` | Apply + delete stash |
| `git stash drop stash@{n}` | Delete a specific stash |
| `git stash clear` | Delete all stashes (irreversible) |
| `git stash branch <branch>` | Create a new branch from a stash |

---

### How Stashing Works  
Each stash you create is added to a **stack**:  
```
stash@{0}   ← newest
stash@{1}
stash@{2}   ← oldest
```
The top of the stack (`stash@{0}`) is the most recent.

---

### Example: Save and Restore Work  
```bash
git stash push -m "WIP: webstore api changes"
# switch branch, fix urgent bug, come back
git stash pop    # apply + remove from list
```

---

### Including Untracked Files

By default, untracked (new) files are not stashed.
To include them:
```bash
git stash -u
```

---

### Viewing and Inspecting Stashes

```bash
git stash list          # list all stashes
git stash show          # summary of latest stash
git stash show -p       # full diff of latest stash
```

---

### Create a Branch from a Stash

```bash
git stash branch feature-branch stash@{0}
```

Creates a new branch, applies the stash, and removes it once done.

---

### Best Practices for Stashing

- Use clear messages: `git stash push -m "WIP: user-auth feature"`
- Don't treat stashes as long-term storage — commit soon after
- Review and clean old stashes regularly
- Remember: stashes are **local only** and expire after ~90 days

---

### Troubleshooting

| Problem | Fix |
|---|---|
| Lost changes | `git stash list` → `git stash apply` |
| Conflicts on apply | Resolve manually like merge conflicts |
| Untracked files missing | Use `git stash -u` next time |
| Accidentally cleared | `git stash clear` is permanent — cannot recover |

</details>

---

<details>
<summary><strong>2. Git Tags – Marking Versions and Releases</strong></summary>

### Why Git Tags Exist

Commits tell the full story, but tags mark the **key chapters** — the release versions and milestones that CI-CD pipelines and teams rely on.

---

### Key Commands for Tagging

| Command | Description |
|---|---|
| `git tag <tagname>` | Create a lightweight tag |
| `git tag -a <tagname> -m "message"` | Create an annotated tag (recommended) |
| `git tag <tagname> <commit-hash>` | Tag an older commit |
| `git tag` | List all tags |
| `git show <tagname>` | Show tag + commit details |
| `git push origin <tagname>` | Push one tag to remote |
| `git push --tags` | Push all tags to remote |
| `git tag -d <tagname>` | Delete local tag |
| `git push origin --delete tag <tagname>` | Delete remote tag |

---

### Lightweight vs Annotated Tags

| Type | Contains | Best For |
|---|---|---|
| **Lightweight** | Commit pointer only | Quick local bookmarks |
| **Annotated** | Author, date, message | Releases and shared milestones |

Always use annotated tags for releases:
```bash
git tag -a v1.0 -m "webstore v1.0 — initial release"
```

---

### Tag a Specific Commit

```bash
git tag -a v1.1 1a2b3c4d -m "hotfix release"
```

---

### Pushing Tags to Remote

Tags are not pushed automatically:
```bash
git push origin v1.0    # push one tag
git push --tags         # push all tags
```

---

### When to Use Tags

- **Releases:** Mark stable versions (`v1.0`, `v2.0`)
- **Milestones:** Feature completions
- **Deployments:** CI-CD pipelines reference tags to decide what to deploy
- **Hotfixes:** Return to stable versions safely

---

### Best Practices for Tagging

- Always use annotated tags (`-a -m`) for anything shared
- Tag only stable commits after tests pass
- Follow semantic versioning: `v1.0.0`, `v1.1.2`
- Avoid `--force` unless correcting an unavoidable mistake

---

### Troubleshooting

| Problem | Solution |
|---|---|
| Tag already exists | `git tag -d <tag>` → recreate |
| Wrong tag pushed | Delete local + remote, push correct one |
| Tag missing on remote | `git push origin <tag>` |

</details>

→ Ready to practice? [Go to Lab 02](../git-labs/02-stash-tags-lab.md)
