# Git & GitHub – Version Control
> From Local Commits to Global Collaboration

---

[Foundations](01-foundations/README.md) | 
[Stash & Tags](02-stash-tags/README.md) | 
[History & Branching](03-history-branching/README.md) | 
[Contribute](04-contribute/README.md) | 
[Undo & Recovery](05-undo-recovery/README.md) | 

---

## Why This Series Exists

Most Git tutorials teach commands in isolation. You learn `git add`, `git commit`, `git push` — but not **why they exist** or **when to use each**.

This series is different. It teaches Git the way experienced developers think about it: as a **timeline management system** for collaborative work.

You'll learn Git from the **Inside-Out**:
- Start with local version control (your machine)
- Build outward to remote collaboration (GitHub)
- Master recovery tools (the safety net)

By the end, you won't just know Git commands — you'll understand the **mental model** behind distributed version control.

---

## What Makes This Different

**Scenario-First Learning**  
Every concept begins with a real problem Git solves, not abstract theory.

**Hands-On Verification**  
Each section includes commands to test your understanding immediately.

**Decision Tables Over Walls of Text**  
Quick-reference tables show you exactly when to use each command.

**Mental Models at Every Stage**  
Visual diagrams and analogies that stick — Git as a timeline, branches as parallel universes, stash as a shelf.

**Production Patterns**  
Best practices from day one — atomic commits, meaningful messages, safe collaboration flows.

---

## The Series

### **Foundation – Local Control**
**[01. Foundations](01-foundations/README.md)**  
Install Git, configure identity, create repositories, understand tracked vs untracked files, staging area, commits, and the basic workflow from edit to push.

**[02. Stash & Tags](02-stash-tags/README.md)**  
Pause unfinished work safely with stash, mark release milestones with tags, manage temporary vs permanent snapshots.

---

### **Collaboration – Working with Others**
**[03. History & Branching](03-history-branching/README.md)**  
Read commit history, create parallel development branches, merge strategies (fast-forward vs 3-way), resolve conflicts, manage clean timelines.

**[04. Contribute](04-contribute/README.md)**  
Fork repositories, clone to local machine, set up dual remotes (origin/upstream), push changes, create pull requests, complete the open-source contribution cycle.

---

### **Recovery – The Safety Net**
**[05. Undo & Recovery](05-undo-recovery/README.md)**  
Fix mistakes with revert, amend recent commits, reset local history, recover lost work with reflog, understand when to use each recovery tool.

---

### **Advanced – Power User Patterns**
**[06. Advanced](06-advanced/README.md)** *(Coming Soon)*  
Rebase vs merge workflows, interactive rebase, cherry-pick commits, submodules, Git hooks, advanced collaboration patterns.

---

## Critical Concepts

### **The Big Three: Working Directory → Staging → Repository**

```
┌─────────────────┐    git add    ┌─────────────┐   git commit   ┌──────────────┐
│ Working         │──────────────>│  Staging    │───────────────>│ Repository   │
│ Directory       │               │  Area       │                │ (.git/)      │
│ (Your files)    │               │ (Index)     │                │ (History)    │
└─────────────────┘               └─────────────┘                └──────────────┘
```

**Working Directory** – Where you edit files  
**Staging Area** – Where you prepare the next commit  
**Repository** – Where Git stores permanent history

This three-stage model is what makes Git powerful. You control exactly what goes into each snapshot.

---

### **DevOps Essentials**

| Concept | Why It Matters |
|---------|----------------|
| **Atomic Commits** | Each commit = one logical change. Makes debugging and rollback precise. |
| **Branching Strategy** | Feature branches keep main stable. CI/CD pipelines trigger on branch events. |
| **Merge vs Rebase** | Merge preserves full history; rebase creates linear history. Team decides. |
| **Tags for Releases** | `v1.0`, `v2.0` mark deployable states. Automation tools reference these. |
| **Pull Request Reviews** | Code quality gate. No direct pushes to main in production environments. |

---

## Learning Path

### **If You're Brand New to Git:**
1. Start with [Foundations](01-foundations/README.md) – get Git installed and make your first commit
2. Then [Stash & Tags](02-stash-tags/README.md) – learn to pause work and mark milestones
3. Move to [History & Branching](03-history-branching/README.md) – understand parallel development
4. Practice [Contribute](04-contribute/README.md) – simulate real collaboration
5. Study [Undo & Recovery](05-undo-recovery/README.md) – build confidence with safety nets

### **If You Know Git Basics:**
- Jump to [History & Branching](03-history-branching/README.md) for merge strategies
- Review [Contribute](04-contribute/README.md) for fork/PR workflows
- Master [Undo & Recovery](05-undo-recovery/README.md) for professional-grade recovery

### **If You're Debugging an Issue:**
- Wrong file committed? → [Undo & Recovery](05-undo-recovery/README.md) (amend)
- Merge conflict? → [History & Branching](03-history-branching/README.md) (conflict resolution)
- Lost commits? → [Undo & Recovery](05-undo-recovery/README.md) (reflog)
- Need to switch tasks mid-work? → [Stash & Tags](02-stash-tags/README.md) (stash)

---

## Prerequisites

**Required:**
- Command line comfort (basic navigation: `cd`, `ls`, `mkdir`)
- A text editor (VS Code, Vim, Nano — any editor works)
- Terminal access (Linux/macOS Terminal, Windows Git Bash)

**Helpful but Optional:**
- GitHub account (free) for remote collaboration practice
- Basic understanding of files and directories

**Not Required:**
- Programming experience (Git works with any file type)
- Prior version control knowledge

---

## What You'll Be Able to Do

After completing this series, you'll confidently:

✅ Initialize repositories and track file changes  
✅ Create atomic commits with meaningful messages  
✅ Use branches to develop features in parallel  
✅ Merge code and resolve conflicts manually  
✅ Fork open-source projects and contribute via pull requests  
✅ Recover from mistakes using revert, reset, and reflog  
✅ Mark releases with tags and reference them in deployments  
✅ Navigate Git history to find bugs or trace changes  
✅ Collaborate on teams using GitHub workflows  
✅ Understand when to use stash, amend, rebase, or cherry-pick

---

## How to Use This Series

**Each file follows a consistent structure:**

1. **Table of Contents** – Jump to any section
2. **Collapsible Sections** – Expand only what you need
3. **Command Tables** – Quick reference without scrolling
4. **Hands-On Examples** – Test immediately in your terminal
5. **Troubleshooting Tables** – Common issues and fixes
6. **Mentor Insight** – Connects concepts to the bigger picture

**Recommended approach:**
- Read linearly the first time (foundation → advanced)
- Use as a reference afterward (jump to specific commands)
- Practice every example in a test repository
- Bookmark tables for quick lookups during work

---

## Philosophy

**Practical Over Theoretical**  
You'll learn by doing, not by memorizing Git internals.

**Production Patterns from Day One**  
Commands are taught the way professionals use them — with context and guardrails.

**Mistakes Are Learning Opportunities**  
Every recovery tool exists because mistakes happen. We teach you to fix them confidently.

**Collaboration Is the Goal**  
Git exists to help teams work together. Solo workflows are stepping stones to collaborative ones.

---

## Navigation

All files include a **navigation bar** at the top:

```
[🏠 Home](../README.md) | 
[Foundations](01-foundations/README.md) | 
[Stash & Tags](02-stash-tags/README.md) | 
[History & Branching](03-history-branching/README.md) | 
[Contribute](04-contribute/README.md) | 
[Undo & Recovery](05-undo-recovery/README.md) | 
[Advanced](06-advanced/README.md)
```

Click any link to jump between topics instantly.

---

## Start Learning

Ready to begin? Test your setup:

```bash
# Check Git installation
git --version

# Configure your identity
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Verify settings
git config --list
```

If those commands work, you're ready for **[01. Foundations](01-foundations/README.md)**.

---

## Quick Command Reference

### **Navigation & Setup**
```bash
git --version                           # Check Git installation
git config --global user.name "Name"    # Set your name
git config --global user.email "email"  # Set your email
git config --list                       # View all settings
```

### **Repository Basics**
```bash
git init                                # Create new repository
git clone <url>                         # Clone remote repository
git status                              # Check file status
git log --oneline                       # View commit history
```

### **Staging & Committing**
```bash
git add <file>                          # Stage specific file
git add .                               # Stage all changes
git commit -m "message"                 # Commit with message
git commit --amend                      # Fix last commit
```

### **Branching & Merging**
```bash
git branch                              # List branches
git branch <name>                       # Create branch
git switch <name>                       # Switch to branch
git switch -c <name>                    # Create and switch
git merge <branch>                      # Merge branch into current
git branch -d <name>                    # Delete branch
```

### **Remote Collaboration**
```bash
git remote -v                           # List remotes
git remote add origin <url>             # Add remote
git push origin <branch>                # Push to remote
git pull                                # Fetch and merge updates
git fetch                               # Download updates (no merge)
```

### **Recovery & Undo**
```bash
git restore --staged <file>             # Unstage file
git revert <commit>                     # Undo commit (safe)
git reset --soft <commit>               # Move HEAD, keep changes staged
git reset --hard <commit>               # Move HEAD, discard changes
git reflog                              # View all HEAD movements
```

### **Stash & Tags**
```bash
git stash                               # Save work in progress
git stash list                          # View all stashes
git stash pop                           # Apply and remove stash
git tag <name>                          # Create lightweight tag
git tag -a <name> -m "msg"              # Create annotated tag
git push --tags                         # Push tags to remote
```

---

**Ready to master version control?** Start with **[01. Foundations](01-foundations/README.md)** →

---