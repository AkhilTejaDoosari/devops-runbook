[Home](../README.md) |
[History & Motivation](../01-history-and-motivation/README.md) |
[Technology Overview](../02-technology-overview/README.md) |
[Docker Containers](../03-docker-containers/README.md) |
[Networking](../04-docker-networking/README.md) |
[Port Binding](../05-docker-port-binding/README.md) |
[Volumes](../06-docker-volumes/README.md) |
[Layers](../07-docker-layers/README.md) |
[Build](../08-docker-build-dockerfile/README.md) |
[Registry](../09-docker-registry/README.md) |
[Compose](../10-docker-compose/README.md)

# Docker Containers

## What this file is about (theory)

This file teaches how to **run and operate containers**. If you can use everything here, you can run prebuilt software without installing it on your host, run services in the background, pass correct startup configuration, debug containers when they fail, and clean Docker safely without breaking anything. This is runtime usage only — not Dockerfile, not image building, not volumes deep dive, not networking deep dive.

1. [Getting Software (Images)](#1-getting-software-images)
2. [Interactive Containers (Learning & Exploration)](#2-interactive-containers-learning--exploration)
3. [Visibility & Lifecycle Control](#3-visibility--lifecycle-control)
4. [Service Mode (Real DevOps Usage)](#4-service-mode-real-devops-usage)
5. [Configuration at Startup (-e)](#5-configuration-at-startup--e)
6. [Observability & Debugging (Operator Level)](#6-observability--debugging-operator-level)
7. [Safe Delete Flow (Memorize This)](#7-safe-delete-flow-memorize-this)  
[Final Compression (Memorize)](#final-compression-memorize)

---

## 1. Getting Software (Images)

**Goal:** download software as an image so you can run it later.

| Step | What you do | Command format | Example you run |
|---:|---|---|---|
| 1 | Pull an image (download) | `docker pull IMAGE` | `docker pull ubuntu` |
| 2 | Pull a specific version (tag) | `docker pull IMAGE:TAG` | `docker pull ubuntu:22.04` |
| 3 | Check Docker version | `docker -v` | `docker -v` |
| 4 | List downloaded images | `docker images` | `docker images` |

**Mental model:** Image = downloaded software + environment. Nothing is running yet.

---

## 2. Interactive Containers (Learning & Exploration)

**Goal:** enter a container like a terminal to explore safely.

| Step | What you do | Command format | Example you run |
|---:|---|---|---|
| 5 | Run + enter container (best for learning) | `docker run --name CONT_NAME -it IMAGE` | `docker run --name ubuntu-test -it ubuntu` |
| 6 | Exit container (from inside) | `exit` | `exit` |
| 7 | Start existing container + enter again | `docker start -i CONT_NAME` | `docker start -i ubuntu-test` |

**Name behavior (important):**  
- If you do NOT specify `--name`, Docker automatically assigns a random name (e.g., `sleepy_morse`).
- The name is just a human-friendly label; Docker also assigns an internal container ID.
- These notes **always use container names**, not container IDs, because names are easier to remember and read.
- You must use the generated name or container ID for all follow-up commands (`start`, `stop`, `logs`, `exec`).

**Mental model:**   
`-it` attaches your terminal to the container’s main process. If that process exits, the container stops.
- -it — interactive terminal

---

## 3. Visibility & Lifecycle Control

**Goal:** see what exists and control container lifecycle confidently.

| Step | What you do | Command format | Example you run |
|---:|---|---|---|
| 8 | Show running containers | `docker ps` | `docker ps` |
| 9 | Show all containers (running + stopped) | `docker ps -a` | `docker ps -a` |
| 10 | Stop a running container | `docker stop CONT_NAME` | `docker stop ubuntu-test` |
| 11 | Delete container (must be stopped) | `docker rm CONT_NAME` | `docker rm ubuntu-test` |
| 12 | Delete image (after container is deleted) | `docker rmi IMAGE` | `docker rmi ubuntu` |

**Non-negotiable rule:** Delete containers first → then delete images.

---

## 4. Service Mode (Real DevOps Usage)

**Goal:** run software in the background like a server.

| Step | What you do | Command format | Example you run |
|---:|---|---|---|
| 13 | Run in background (detach) + name it | `docker run -d --name CONT_NAME IMAGE` | `docker run -d --name web nginx` |

**Mental model:**   
`-d` means “run like a service.” You don’t enter it. You observe it and manage it.

---

## 5. Configuration at Startup (`-e`)

**Goal:** pass required configuration (passwords, modes, environment flags) at container startup.

| Step | What you do | Command format | Example you run |
|---:|---|---|---|
| 14 | Run tool with required config (`-e`) | `docker run -d --name CONT_NAME -e KEY=VALUE IMAGE:TAG` | `docker run -d --name mysql8 -e MYSQL_ROOT_PASSWORD=secret mysql:8.0` |

**Mental model:**   
Image is generic. `-e` makes it environment-specific at runtime.  
You find required env vars in the image’s official docs (Docker Hub).  

### Helper: generating secrets (host-side, not a Docker command — optional)

Some images require a password at startup. This command generates a random string you can use as that password.

```bash
openssl rand -base64 16
```
**What openssl rand -base64 16 does (piece by piece)**

- `openssl` → a tool already installed on most systems
- `rand` → generate random data
- `16` → amount of randomness
- `-base64` → convert it into readable text

**How it fits into Docker (full flow)**

Generate secret on host:
```bash
openssl rand -base64 16
```

Copy the output

Use it in Docker:
```bash
docker run -d \
  --name mysql8 \
  -e MYSQL_ROOT_PASSWORD=<PASTE_HERE> \
  mysql:8.0
```

That’s all.  
No magic. No Docker internals.  

---

## 6. Observability & Debugging (Operator Level)

**Goal:** figure out what’s wrong without rebuilding.

| Step | What you do                                           | Command                             | Example                       |
| -----|------------------------------------------------ | ----------------------------------- | ----------------------------- |
| 15   |View logs                                             | `docker logs CONT_NAME`             | `docker logs mysql8`          |
| 16   |Follow logs (live)                                    | `docker logs -f CONT_NAME`          | `docker logs -f web`          |
| 17   |Inspect container truth (state/env/image/ports, etc.) | `docker inspect CONT_NAME`          | `docker inspect mysql8`       |
| 18   |Enter a running container for debugging               | `docker exec -it CONT_NAME /bin/sh` | `docker exec -it web /bin/sh` |
| 19   |Restart a container                                   | `docker restart CONT_NAME`          | `docker restart web`          |

---
### Operator mental model (read this first)

When something is wrong, **never rebuild first**.  
You observe → inspect → intervene → restart.  
* Rebuilding too early = slow + hides root cause  
* Exec/logs first = faster + teaches system behavior  
This is the **operator mindset** difference between juniors and seniors.  
---

**When to use what:**

- Container exited or won’t stay up → `docker logs`
- Container running but misbehaving → `docker logs -f`
- Unsure how the container was started → `docker inspect`
- Need to look inside a running container → `docker exec`
- Config changed or process stuck → `docker restart`

---

## Command-by-command (why it exists)

| Situation (what you see) | What it means | Command to use | Why this command |
|--------------------------|---------------|----------------|------------------|
| Container exited or won’t stay up | App crashed at startup | `docker logs CONT_NAME` | See error output from the last run |
| Container running but acting strange | App is alive but misbehaving | `docker logs -f CONT_NAME` | Watch live behavior and errors |
| You forgot how the container was started | Assumptions are unreliable | `docker inspect CONT_NAME` | Docker’s source of truth (env, ports, image) |
| Logs aren’t enough | Need to look inside | `docker exec -it CONT_NAME /bin/sh` | Debug from inside the container |
| App stuck or config changed | Process needs reset | `docker restart CONT_NAME` | Clean restart without rebuilding |

---

## 7. Safe Delete Flow (Memorize This)

**Goal:** clean Docker without “blocked by dependency” errors.

Docker will block image deletion if any container still exists that references it (even stopped). So deletion must always follow the same order.

**Delete order rule:** Container first → Image next.

| Step | What you do                      | Command format          | Example                |
| ---: | -------------------------------- | ----------------------- | ---------------------- |
|   20 | Stop container (only if running) | `docker stop CONT_NAME` | `docker stop mysql8`   |
|   21 | Delete container                 | `docker rm CONT_NAME`   | `docker rm mysql8`     |
|   22 | Delete image                     | `docker rmi IMAGE`      | `docker rmi mysql:8.0` |

---

## Final compression (memorize)

Explore → `run -it`  
Run services → `run -d`  
Configure → `-e`  
Debug → `logs / inspect / exec`  
Clean → `stop → rm → rmi`  