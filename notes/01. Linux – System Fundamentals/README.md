<p align="center">
  <img src="../../assets/linux-banner.svg" alt="linux" width="100%"/>
</p>

[← devops-runbook](../../README.md) |
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

## Why Linux — and Why Ubuntu

Every server you will ever SSH into in a DevOps role runs Linux. AWS EC2 instances run Linux. Docker containers run Linux. Kubernetes nodes run Linux. The CI runners that build your images run Linux. Learning Linux is not optional in this stack — it is the ground everything else stands on.

Ubuntu is the distribution this runbook uses because it is the default for AWS EC2, the most common choice in DevOps job environments, and the distribution all tooling in this series assumes. The concepts transfer directly to any other Linux distribution — the package manager and a few paths change, nothing fundamental does.

---

## The Linux Stack

Linux is not one thing. It is layers. Each layer has one job.
Every file in these notes lives on a specific layer.
When something breaks, you know exactly which layer to look at.

```
  ┌─────────────────────────────────────────────────────────────────────┐
  │  L6  YOU                                                            │
  │       ~ · /home/akhil · .bashrc · .ssh/ · .config/                  │
  │       you land here every time you SSH into a server                │
  ├─────────────────────────────────────────────────────────────────────┤
  │  L5  TOOLS & FILES                                                  │
  │       /usr/bin · /usr/local/bin · /opt                              │
  │       the commands you run · the files you edit · the scripts       │
  ├─────────────────────────────────────────────────────────────────────┤
  │  L4  CONFIG                                                         │
  │       /etc — users · passwords · groups · network · services        │
  │       you edit /etc to change how the system behaves                │
  ├─────────────────────────────────────────────────────────────────────┤
  │  L3  STATE & DEBUG                    ← start here when prod breaks │
  │       /var/log · /var/lib · /run                                    │
  │       logs of everything that happened · live state of what runs    │
  ├─────────────────────────────────────────────────────────────────────┤
  │  L2  NETWORKING                                                     │
  │       /etc/hosts · /etc/netplan · /sys/class/net                    │
  │       how this machine talks to the world                           │
  ├─────────────────────────────────────────────────────────────────────┤
  │  L1  PROCESS MANAGER                                                │
  │       systemd · PID 1 · /etc/systemd/system                         │
  │       starts and watches every service you deploy                   │
  ├─────────────────────────────────────────────────────────────────────┤
  │  L0  FOUNDATION                                                     │
  │       kernel · GRUB · /boot · hardware · cloud VM                   │
  │       everything above sits on top of this                          │
  └─────────────────────────────────────────────────────────────────────┘
```

---

## When Production Breaks

You SSH into a server. Something is wrong.
You do not panic. You ask these questions in order.
Each question maps to a layer. Each layer has a file.

```
  SYMPTOM                            LAYER   FIRST COMMAND
  ─────────────────────────────────────────────────────────────────────
  Can't find a file or command     → L5/L6   pwd · ls · which nginx
  Config change broke something    → L4      nginx -t · cat /etc/nginx/nginx.conf
  Need to know what happened       → L3      journalctl -u nginx · tail /var/log/syslog
  Can't reach the server           → L2      ip addr · ss -tulnp · curl -I localhost
  Service is down                  → L1      systemctl status nginx
  Machine is slow or unresponsive  → L0      uptime · free -h · df -h · dmesg | tail
  ─────────────────────────────────────────────────────────────────────
```

---

## The Running Example

Every file uses the same webstore project on disk.
This is the same app that gets containerized in Docker,
orchestrated in Kubernetes, and deployed to AWS.
It starts here as a directory on a Linux server.

```
~/webstore/
├── frontend/       ← static files nginx will serve
├── api/            ← application code
├── db/             ← database schemas
├── logs/           ← access.log, error.log
├── config/         ← webstore.conf
└── backup/         ← archives before deploys
```

By the end of Linux you will have built this structure from scratch,
written config files into it, searched its logs with grep and awk,
set correct ownership and permissions on every folder, archived it
with tar, installed nginx to serve the frontend, managed nginx as a
systemd service, and debugged it live over the network with curl and tcpdump.

---

## Where You Take the Webstore

You arrive at Linux with nothing — a blank server and a project idea.
You leave with the webstore running on that server, files organized,
permissions locked, nginx serving the frontend, logs being written,
and the whole project archived and ready to hand off.

That is the state Git picks up from. You do not start Git with a
blank folder — you start it with a working server setup that already
has history worth tracking.

---

## Files — Read in This Order

Each file only requires knowledge from the files before it.
Every example uses the webstore. Every file leaves something working.

| # | File | Layer | After reading this you can |
|---|---|---|---|
| 01 | [Boot Process](./01-boot-process/README.md) | L0 | Explain every step from power-on to login. Read a boot failure and know which stage broke. |
| 02 | [Basics](./02-basics/README.md) | L6 | Navigate any Linux server. Know where you are, what is running, what the disk looks like. |
| 03 | [Working with Files](./03-working-with-files/README.md) | L5 | Copy, move, rename, link files. Back up a directory safely before changing it. |
| 04 | [Filter Commands](./04-filter-commands/README.md) | L5 | Search logs, count errors, extract fields, chain commands together in a pipeline. |
| 05 | [sed](./05-sed-stream-editor/README.md) | L5 | Edit config files from the command line without opening an editor. |
| 06 | [awk](./06-awk/README.md) | L5 | Process log files, calculate totals, build reports from raw text. |
| 07 | [vim](./07-text-editor/README.md) | L5 | Edit any file on any server — even with no GUI, no nano, nothing else. |
| 08 | [Users & Groups](./08-user-and-group-management/README.md) | L4 | Create users, manage groups, set up service accounts with least privilege. |
| 09 | [Permissions](./09-file-ownership-and-permissions/README.md) | L4 | Control exactly who can read, write, and execute every file on the system. |
| 10 | [Archiving](./10-archiving-and-compression/README.md) | L5 | Back up directories, compress logs, restore from an archive. |
| 11 | [Package Management](./11-package-management/README.md) | L5 | Install, update, and remove software. Understand what apt actually does to the system. |
| 12 | [Service Management](./12-service-management/README.md) | L1 | Start, stop, enable services. Write a systemd unit file. Read service logs. |
| 13 | [Networking](./13-networking/README.md) | L2 | Debug connectivity, check open ports, trace where a request fails. |
| 14 | [Logs & Debug](./14-logs-and-debug/README.md) | L3 | Read any log, follow a live stream, run a full debug workflow end to end. |

---

## What You Can Do After This

- Navigate any Linux server confidently over SSH with no GUI
- Search and analyze log files to debug real incidents
- Create users and groups, set correct file ownership and permissions
- Install software, manage services, and configure nginx
- Use curl, dig, ss, and tcpdump to debug network issues live
- Archive and restore directories for backups and deploys
- Write and edit files directly on a server using vim
- Run a structured debug workflow from symptom to fix

---

## How to Use This

Read files in order. Each one builds on the previous.
Do the "On the webstore" section in every file before moving on.
The webstore must be in the state described at the end of each file.
If it is not — go back. Moving forward on a broken foundation means
every file after it will be harder than it should be.

---

## What Comes Next

→ [02. Git & GitHub – Version Control](../02.%20Git%20%26%20GitHub%20–%20Version%20Control/README.md)

Linux gives you the server foundation. Git gives you the workflow
foundation — version control, collaboration, and the habit of tracking
every change you make to infrastructure and code. The webstore
directory you built here becomes the first Git repository you initialize.


## 🚀 Practice Lab & Setup

We recommend **Google Cloud Shell** as your lab. It is a real Linux server in your browser.

* **Lab Portal:** [Launch Google Cloud Shell](https://shell.cloud.google.com/?hl=en_GB&theme=dark&authuser=0&fromcloudshell=true&show=terminal)
* **Specs:** 2 vCPUs, 5 GB RAM, 5 GB persistent home directory.
* **Usage:** 50 free hours per week. **Always type `exit` to save your quota!**

<details>
<summary><b>🎨 Click to expand: Customize Your Prompt (Permanent)</b></summary>
<br>

Cloud Shell defaults to a long, messy username. Follow these steps to set a clean "Production" prompt:

1. Open config: `nano ~/.bashrc`
2. Paste at the bottom: 
   ```bash
   export PS1="\[\e[1;32m\][Webstore-Prod]\[\e[m\]:\[\e[1;34m\]\w\[\e[m\]\$ "
3. **Save/Exit:** Ctrl+O, Enter, Ctrl+X
4. Apply: source ~/.bashrc

</details>
