[Home](../README.md) |
[Boot](../01-boot-process/README.md) |
[Basics](../02-basics/README.md) |
[Files](../03-working-with-files/README.md) |
[Filters](../04-filter-commands/README.md) |
[sed](../05-sed-stream-editor/README.md) |
[awk](../06-awk/README.md) |
[vim](../07-text-editor/README.md) |
[Users](../08-user-and-group-management/README.md) |
[Permissions](../09-file-ownership-and-permissions/README.md) |
[Archive](../10-archiving-and-compression/README.md) |
[Packages](../11-package-management/README.md) |
[Services](../12-service-management/README.md) |
[Networking](../13-networking/README.md) |
[Logs](../14-logs-and-debug/README.md) |
[Interview](../99-interview-prep/README.md)

---

# [Topic Name]

> **Layer:** L[N] — [Layer Name]
> **Depends on:** [Previous file](../previous/README.md) — one line why
> **Used in production when:** one real sentence — the moment this skill matters

---

## Table of Contents

- [What this is](#what-this-is)
- [How it fits the stack](#how-it-fits-the-stack)
- [1. Section Name](#1-section-name)
- [2. Section Name](#2-section-name)
- [N. Section Name](#n-section-name)
- [On the webstore](#on-the-webstore)
- [What breaks](#what-breaks)
- [Daily commands](#daily-commands)

---

## What this is

One paragraph. The idea behind the tool. Why it exists.
What problem it solves. No commands yet.
A reader finishing this paragraph understands the tool before touching it.

---

## How it fits the stack

```
  L6  You
  L5  Tools & Files
  L4  Config
  L3  State & Debug
  L2  Networking
  L1  Process Manager
  L0  Kernel & Hardware  ← highlight the relevant layer with this arrow
```

One or two sentences. What this tool touches above and below it in the stack.
Which files at which layer it reads or modifies.

---

## 1. [First concept]

One paragraph explaining the concept. Why it works this way. What to understand before using it.

Every command table has these columns:

| Command | Full form | What it does | When you reach for it |
|---|---|---|---|
| `command -f target` | command --flag-name | What it does in plain English | Real scenario on the webstore |

Rules for the table:
- Full form column: `cp -r` = Copy --recursive. Every flag explained, no exceptions.
- "When you reach for it" = a real webstore scenario, not "when you need this"
- If a flag has no long form (like `awk`), write `—` in that column

Every example shows the command AND the output the reader should see:

```bash
# what you are doing and why — one line comment
command -flag target
# expected output line 1
# expected output line 2
```

If output is long, show only the relevant lines with `# ...` for skipped lines.

---

## 2. [Second concept]

Same format. Concept paragraph first. Table second. Examples with output third.
Flags explained inline in the command itself when needed:
  `cp -r (r = recursive, copies directories) src/ dest/`

---

## [N. As many sections as the topic needs]

No section for things that are rarely used or out of scope for DevOps daily work.
If it takes more than one file to explain a concept — split the concept, not the file structure.

---

## On the webstore

This is where the reader does the real work.
No new concepts introduced here — only the tool applied to the webstore.

Each task is a real step that leaves something working or changed:
- Not "practice chmod" → "lock down the webstore config so only nginx can read the database password"
- Not "create a user" → "create the webstore service account that nginx will run as"

Format:

```bash
# Step 1 — what and why
command
# expected output

# Step 2 — what and why
command
# expected output

# Verify it worked
command
# what correct output looks like
```

End with one sentence connecting forward — what the next file does with what was just built.

---

## What breaks

Real failures. Real error messages. First command to run.

| Symptom | Cause | Fix |
|---|---|---|
| exact error message or behaviour | why it happens — one line | first command to diagnose or fix |
| exact error message or behaviour | why it happens — one line | first command to diagnose or fix |

Minimum 5 entries. Maximum 8. Only failures that actually happen in production or learning.

---

## Daily commands

The commands you actually use. Max 10. No padding.
Full form shown — no unexplained flags anywhere.

| Command | What it does |
|---|---|
| `command -f (f=flag meaning) target` | Plain English — what it does, not how it works |
| `command -f (f=flag meaning) target` | Plain English |

---

→ **Interview questions for this topic:** [99-interview-prep → Topic Name](../99-interview-prep/README.md#topic-anchor)
