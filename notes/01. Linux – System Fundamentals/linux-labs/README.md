[Home](../README.md) |
[Labs Index](./README.md) |
[Lab 01](./01-boot-basics-files-lab.md) |
[Lab 02](./02-filters-sed-awk-lab.md) |
[Lab 03](./03-vim-users-permissions-lab.md) |
[Lab 04](./04-archive-packages-services-lab.md) |
[Lab 05](./05-networking-lab.md)

---

# Linux Labs

Hands-on sessions for every phase in the Linux notes.

Do them in order. Do not move to the next lab until the checklist at the bottom is fully checked.

---

## The Project Thread

These five labs are not isolated exercises. They are five stages in the life of one project — the webstore — running on a Linux server. Each lab picks up exactly where the previous one left off.

By the time you finish Lab 05 you will have built the webstore's server foundation from scratch: a structured project on disk, permissions locked down, nginx serving the frontend, and the full network stack verified and debugged. That is the state Git picks up from in the next tool.

| Lab | Where the webstore is | What you do |
|---|---|---|
| [Lab 01](./01-boot-basics-files-lab.md) | Blank server | Build the project directory, write config files, set up the file structure that every future lab depends on |
| [Lab 02](./02-filters-sed-awk-lab.md) | Running for a week, logs accumulating | Act as the on-call engineer — find errors in the logs using only the terminal |
| [Lab 03](./03-vim-users-permissions-lab.md) | About to be handed to a second developer | Lock it down — correct users, groups, and permissions so nobody reads what they should not |
| [Lab 04](./04-archive-packages-services-lab.md) | Deploy day | Archive the current state, install nginx, configure it to serve the frontend, make it survive reboots |
| [Lab 05](./05-networking-lab.md) | Something is wrong, users are reporting issues | Debug the network layer from outside in — no monitoring, no dashboard, just the terminal |

---

## Labs

| Lab | Topics | Notes |
|---|---|---|
| [Lab 01](./01-boot-basics-files-lab.md) | Boot + Basics + Files | [01](../01-boot-process/README.md) · [02](../02-basics/README.md) · [03](../03-working-with-files/README.md) |
| [Lab 02](./02-filters-sed-awk-lab.md) | Filters + sed + awk | [04](../04-filter-commands/README.md) · [05](../05-sed-stream-editor/README.md) · [06](../06-awk/README.md) |
| [Lab 03](./03-vim-users-permissions-lab.md) | Vim + Users + Permissions | [07](../07-text-editor/README.md) · [08](../08-user-&-group-management/README.md) · [09](../09-file-ownership-&-permissions/README.md) |
| [Lab 04](./04-archive-packages-services-lab.md) | Archive + Packages + Services | [10](../10-archiving-and-compression/README.md) · [11](../11-package-management/README.md) · [12](../12-service-management/README.md) |
| [Lab 05](./05-networking-lab.md) | Networking | [13](../13-networking/README.md) |

---

## How to Use These Labs

Read the notes for each phase before opening a terminal. Every lab assumes you have read the corresponding notes files first.

Write every command from scratch. Do not copy-paste. Typing forces your brain to process each flag and each decision.

Every lab has a "Break It on Purpose" section. Do not skip it. These are the failure states you will actually hit in production. Seeing the error yourself and fixing it is the point.

Do not move to the next lab until every box in the checklist is checked. If you cannot check a box honestly, go back and do it properly.
