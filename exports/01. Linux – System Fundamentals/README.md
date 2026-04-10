<p align="center">
  <img src="../../assets/linux-banner.svg" alt="linux" width="100%"/>
</p>

[← devops-runbook](../../README.md)

---

A production-focused Linux guide built around one running example.
No certification fluff. No desktop Linux. Only what you actually use on servers.

---

## Why Linux — and Why Ubuntu

Every server you will ever SSH into in a DevOps role runs Linux. AWS EC2 instances run Linux. Docker containers run Linux. Kubernetes nodes run Linux. The CI runners that build your images run Linux. Learning Linux is not optional in this stack — it is the ground everything else stands on.

Ubuntu is the distribution this runbook uses because it is the default for AWS EC2, the most common choice in DevOps job environments, and the distribution all tooling in this series assumes. The concepts transfer directly to any other Linux distribution — the package manager and a few paths change, nothing fundamental does.

---

## Prerequisites

None. This is the first folder in the series.
All you need is a Linux terminal — a VM, WSL, or an EC2 instance works fine.

---

## The Running Example

Every note and every lab uses the same webstore project on disk. This is the same app that gets containerized in Docker, orchestrated in Kubernetes, and deployed to AWS. It starts here as a directory on a Linux server.

```
~/webstore/
├── frontend/       ← static files nginx will serve
├── api/            ← application code
├── db/             ← database schemas
├── logs/           ← access.log, error.log
├── config/         ← webstore.conf
└── backup/         ← archives before deploys
```

By the end of Linux you will have built this structure from scratch, written config files into it, searched its logs with grep and awk, set correct ownership and permissions on every folder, archived it with tar, installed nginx to serve the frontend, managed nginx as a systemd service, and debugged it live over the network with curl and tcpdump.

---

## Where You Take the Webstore

You arrive at Linux with nothing — a blank server and a project idea. You leave with the webstore running on that server, files organized, permissions locked, nginx serving the frontend, logs being written, and the whole project archived and ready to hand off.

That is the state Git picks up from. You do not start Git with a blank folder — you start it with a working server setup that already has history worth tracking.

---

## Phases

| Phase | Topics | Lab |
|---|---|---|
| 0 — Foundation | [01 Boot Process](./01-boot-process/README.md) · [02 Basics](./02-basics/README.md) · [03 Files](./03-working-with-files/README.md) | [Lab 01](./linux-labs/01-boot-basics-files-lab.md) |
| 1 — Text Processing | [04 Filters](./04-filter-commands/README.md) · [05 sed](./05-sed-stream-editor/README.md) · [06 awk](./06-awk/README.md) | [Lab 02](./linux-labs/02-filters-sed-awk-lab.md) |
| 2 — System Admin | [07 Vim](./07-text-editor/README.md) · [08 Users](./08-user-&-group-management/README.md) · [09 Permissions](./09-file-ownership-&-permissions/README.md) | [Lab 03](./linux-labs/03-vim-users-permissions-lab.md) |
| 3 — Operations | [10 Archive](./10-archiving-and-compression/README.md) · [11 Packages](./11-package-management/README.md) · [12 Services](./12-service-management/README.md) | [Lab 04](./linux-labs/04-archive-packages-services-lab.md) |
| 4 — Networking | [13 Networking](./13-networking/README.md) | [Lab 05](./linux-labs/05-networking-lab.md) |

---

## Labs

| Lab | Covers |
|---|---|
| [Lab 01](./linux-labs/01-boot-basics-files-lab.md) | Boot inspection, filesystem navigation, webstore directory setup, file operations |
| [Lab 02](./linux-labs/02-filters-sed-awk-lab.md) | grep, find, cut, sort, uniq, sed, awk — all on webstore logs |
| [Lab 03](./linux-labs/03-vim-users-permissions-lab.md) | vim editing, user/group creation, ownership and permission control |
| [Lab 04](./linux-labs/04-archive-packages-services-lab.md) | tar/gzip backup, nginx install, systemctl full lifecycle, config management |
| [Lab 05](./linux-labs/05-networking-lab.md) | ip, ping, traceroute, dig, curl, ss, tcpdump — all against the running nginx |

---

## What You Can Do After This

- Navigate any Linux server confidently over SSH with no GUI
- Search and analyze log files to debug real incidents
- Create users and groups, set correct file ownership and permissions
- Install software, manage services, and configure nginx
- Use curl, dig, ss, and tcpdump to debug network issues live
- Archive and restore directories for backups and deploys

---

## How to Use This

Read phases in order. Each one builds on the previous.
After each phase do the lab before moving on.
The checklist at the end of every lab is not optional.

---

## What Comes Next

→ [02. Git & GitHub – Version Control](../02.%20Git%20%26%20GitHub%20–%20Version%20Control/README.md)

Linux gives you the server foundation. Git gives you the workflow foundation — version control, collaboration, and the habit of tracking every change you make to infrastructure and code. The webstore directory you built here becomes the first Git repository you initialize.
