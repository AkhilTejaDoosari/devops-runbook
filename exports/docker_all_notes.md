---
# SOURCE: 04. Docker – Containerization/01-history-and-motivation/README.md
---

[Home](../README.md) |
[History & Motivation](../01-history-and-motivation/README.md) |
[Technology Overview](../02-technology-overview/README.md) |
[Docker Containers](../03-docker-containers/README.md) |
[Port Binding](../04-docker-port-binding/README.md) |
[Networking](../05-docker-networking/README.md) |
[Volumes](../06-docker-volumes/README.md) |
[Layers](../07-docker-layers/README.md) |
[Build](../08-docker-build-dockerfile/README.md) |
[Registry](../09-docker-registry/README.md) |
[Compose](../10-docker-compose/README.md) |
[Interview Prep](../99-interview-prep/README.md) 

---

# History and Motivation

<!-- no toc -->
  - [Why Docker Exists](#why-docker-exists)
  - [What is a container?](#what-is-a-container)
  - [History of virtualization](#history-of-virtualization)
    - [Bare Metal](#bare-metal)
    - [Virtual Machines](#virtual-machines)
    - [Containers](#containers)
    - [Tradeoffs](#tradeoffs)
  - [What Containerizing the Webstore Gives You](#what-containerizing-the-webstore-gives-you)

---

## Why Docker Exists

Before Docker, an app worked on your laptop because your machine already had the right setup. The same app often failed on testing or production machines, not because the code was wrong, but because the environment was different. Different OS packages, different runtime versions, or missing dependencies caused the break.

Docker solves this environment problem.

Instead of moving only the code, Docker packages the app together with everything it needs to run. That package behaves the same way on any machine that supports Docker. The goal is not speed or magic. The goal is consistency.

Docker has two core parts.
- A Docker **image** is a fixed definition of the environment. It describes what should exist, but it does not run.
- A Docker **container** is a running copy of that image. Containers are created from images, run the app, and can be stopped and deleted anytime.

Because containers are meant to be replaced, rebuilding them is normal. One image can create many identical containers. This makes it easy to run different apps or different versions on the same machine without conflicts.

One important rule stays constant: containers run the application, but they should not store important data. Anything that must survive restarts or deletions should live outside the container.

Everything else in Docker exists to support this idea.

## What is a container?

A Docker container image is a lightweight, standalone, executable package of software that includes everything needed to run an application (https://www.docker.com/resources/what-container/).

## History of virtualization

### Bare Metal

**What this means?**
In a bare metal setup, applications run directly on the same operating system without strong separation. All applications share the same OS, system libraries, CPU, and memory. Because there are no clear boundaries, one application can directly affect others.

**Why this is a problem?**
If one app installs or upgrades a library, it may break another app. If one app consumes too much CPU or memory, it can slow down the entire system. If one app crashes, the impact can spread beyond just that app. Over time, this makes systems fragile and hard to manage.

**Simple analogy!**
Imagine multiple people cooking in the same kitchen with **one stove and one pantry**. Everyone uses the same ingredients and tools. If one person uses all the ingredients or burns the stove, everyone else is affected. There is no separation, so one person's mistake becomes everyone's problem.

![](./readme-assets/bare-metal.jpg)

**Why the industry moved on:**
- Apps break each other
Different apps need different versions of the same software, so installing or updating one app can break another.

- Machine resources are wasted
CPU and memory are not used well; one app may use too much while others sit idle.

- One problem affects everything
If one app crashes or misbehaves, it can impact the whole system.

- Starting and stopping is slow
Services take minutes to start or stop.

- Creating and removing systems is very slow
Setting up or removing a machine takes hours or even days.

---

### Virtual Machines

**What this means?**
In a virtual machine setup, applications do not run directly on the host OS.
Instead, a hypervisor creates multiple virtual computers on one physical machine.
Each virtual machine has its own operating system, libraries, CPU share, and memory.
Because each VM is separated, one VM cannot directly mess with another.

**Why this is better than bare metal?**
Since every VM has its own OS and environment:
- Apps don't fight over libraries
- Crashes usually stay inside one VM
- Resources are more controlled

This makes systems more stable and predictable than bare metal.

**Simple analogy!**
Imagine an apartment building.
- Each family lives in their own apartment
- Everyone has their own kitchen and bathroom
- If one family burns food, it doesn't destroy the whole building

There is separation, but the building itself is still shared.

![](./readme-assets/virtual-machine.jpg)

**What problems still exist?**

Even though VMs fix many bare-metal issues, they introduce new ones:

- Each VM runs a full operating system
- OS takes memory, CPU, and disk even if the app is small
- Starting a VM takes minutes, not seconds
- Creating or deleting VMs is still slow
- Running many VMs becomes expensive and heavy

**Why the industry moved forward again**

- Too much overhead per app (full OS every time)
- Slower startup compared to containers
- Lower density (fewer apps per machine)
- Not ideal for fast development and scaling

**Virtual machines solved isolation and stability, but they are still heavy, slow, and resource-hungry.**
That gap is exactly where containers come in next.

---

### Containers

**What this means?**
In a container setup, applications do not get their own operating system. There is one operating system on the machine, and all containers use that same OS core (kernel).
Each application runs inside its own container, which gives it:
- its own files
- its own settings
- its own view of the system
So even though apps share the same OS underneath, they cannot see or touch each other.
This separation is created using built-in Linux features, not fake hardware and not extra operating systems.

**Why this is an improvement?**
Compared to virtual machines:
- No extra OS to install
- No OS to boot for every app
- Much less memory and CPU usage
- Apps start almost instantly
You can run many containers on one machine without wasting resources.

**Simple analogy!**
Imagine an apartment building. One building, One plumbing system, One power connection

Each apartment:
- has its own door
- its own rooms
- its own locks

People inside one apartment cannot see or affect people in another apartment.
The building = host operating system
The apartments = containers
Everyone shares the same building, but lives separately.

![](./readme-assets/container.jpg)

**Why the industry moved here**

- Apps no longer break each other
- Resources are used more efficiently
- Starting and stopping apps takes seconds
- Easy to create, delete, and move apps
- Perfect for development and modern cloud systems

### VM vs Docker (Mental Model Snapshot)

![VMs vs Docker Containers](./readme-assets/vm-vs-docker.webp)

## VM vs Docker — Resource & Kernel Model

**Virtual Machines:**
- Hardware virtualization
- Guest OS per VM
- Reserved CPU/RAM
- Strong isolation
- Slower, heavier

**Docker Containers:**
- OS-level virtualization
- Shared host kernel
- No reserved CPU/GPU
- Process-level isolation
- Fast, lightweight

**Core Difference:**
VMs virtualize hardware.
Containers isolate processes.

---

### Tradeoffs

![](./readme-assets/tradeoffs.jpg)

***Note:*** There is much more nuance to "performance" than this chart can capture. A VM or container doesn't inherently sacrifice much performance relative to the bare metal it runs on, but being able to have more control over things like connected storage, physical proximity of the system relative to others it communicates with, specific hardware accelerators, etc… do enable performance tuning

---

## What Containerizing the Webstore Gives You

The webstore on a Linux server — nginx on port 80, the API on port 8080, postgres on port 5432 — works on your machine because your machine is set up correctly. The right postgres version is installed. The right nginx config is in place. The right environment variables are set.

Now you want to deploy it. The production server is a fresh Ubuntu instance. It does not have postgres. It does not have the right nginx config. You SSH in, install dependencies manually, adjust configs, and hope you did not miss anything. This is the environment problem Docker solves.

**What changes when you containerize the webstore:**

The webstore-api image contains the application code, the runtime, and every dependency it needs — packaged together. When you run that image on the production server, the same container starts. Same runtime version. Same dependencies. No manual installation. No configuration drift between environments.

```
Without Docker:
  Your laptop → "works on my machine"
  Staging server → "missing postgres version mismatch"
  Production server → "env var missing, nginx config wrong"

With Docker:
  Your laptop → docker compose up → webstore running
  Staging server → docker compose up → same webstore
  Production server → docker compose up → same webstore
```

**What each container gets:**
- `webstore-frontend` — nginx:1.24 serving static files, same image in dev and prod
- `webstore-api` — built from your Dockerfile, same image that passed CI
- `webstore-db` — postgres:15, same version everywhere, data in a volume that survives container replacement

**What you hand to Kubernetes after Docker:**
A Kubernetes cluster does not know what your app is. It pulls container images from a registry and runs them. Everything you build in Docker — images, tags, environment variables, port mappings — is exactly what Kubernetes reads. Docker is not a stepping stone to Kubernetes. It is the prerequisite.

---

## What Breaks

| Symptom | Cause | First command to run |
|---|---|---|
| `docker: command not found` | Docker not installed or not in PATH | `which docker` — if missing, reinstall |
| `permission denied while trying to connect to the Docker daemon` | Your user is not in the `docker` group | `sudo usermod -aG docker $USER` then log out and back in |
| `Cannot connect to the Docker daemon at unix:///var/run/docker.sock` | The Docker daemon is not running | `sudo systemctl start docker` |
| Container exits immediately after `docker run` | The main process inside the container finished or crashed | `docker logs CONTAINER_NAME` to see the exit reason |
| `image operating system "linux" cannot be used on this platform` | Running a Linux image on Mac/Windows without the correct backend | Ensure Docker Desktop is running and fully started |

---

## Daily Commands

| Command | What it does |
|---|---|
| `docker --version` | Confirm Docker is installed and show the version |
| `docker info` | Show system-wide info — daemon status, storage driver, running container count |
| `docker images` | List all images downloaded on this machine |
| `docker ps` | List running containers |
| `docker ps -a` | List all containers including stopped ones |
| `docker pull IMAGE:TAG` | Download an image without running it |
| `docker run --name NAME IMAGE` | Run a container with a specific name |
| `docker stop NAME` | Stop a running container gracefully |
| `docker rm NAME` | Delete a stopped container |
| `docker rmi IMAGE` | Delete an image — remove containers referencing it first |

---

→ **Interview questions for this topic:** [99-interview-prep → Image vs Container · Containers vs VMs](../99-interview-prep/README.md#image-vs-container--containers-vs-vms)

---
# SOURCE: 04. Docker – Containerization/02-technology-overview/README.md
---

[Home](../README.md) |
[History & Motivation](../01-history-and-motivation/README.md) |
[Technology Overview](../02-technology-overview/README.md) |
[Docker Containers](../03-docker-containers/README.md) |
[Port Binding](../04-docker-port-binding/README.md) |
[Networking](../05-docker-networking/README.md) |
[Volumes](../06-docker-volumes/README.md) |
[Layers](../07-docker-layers/README.md) |
[Build](../08-docker-build-dockerfile/README.md) |
[Registry](../09-docker-registry/README.md) |
[Compose](../10-docker-compose/README.md) |
[Interview Prep](../99-interview-prep/README.md)

---

# Technology Overview

<!-- no toc -->
- [Linux Building Blocks](#linux-building-blocks)
  - [Cgroups](#cgroups)
  - [Namespaces](#namespaces)
  - [Union filesystems](#union-filesystems)
- [Docker Application Architecture](#docker-application-architecture)

## Linux Building Blocks

### Process → Namespace → cgroups (Clean Flow)

A **process** is a running program.
Every application starts as a process on the system.
By default, a process can see the entire system and use as many resources as it wants.

Linux then introduced **namespaces**.
A namespace limits what a process can see.
The process is intentionally made blind to the rest of the system.
It sees only its own processes, network, files, users, and hostname.
This creates isolation.

Isolation alone is not enough.
A process could still consume all CPU or memory.

So Linux added **cgroups**.
cgroups limit how much CPU, memory, and other resources a process can use.
These limits are enforced by the kernel.

When a process is started with namespaces and cgroups applied, it becomes what we call a container.

**One-line lock:**
A container is just a process with restricted view and restricted usage.

---

### Namespaces 
This table shows the Linux resources that can be isolated using namespaces. This is for reference only.
![](./readme-assets/namespaces.jpg) 

---

### Cgroups
Cgroups are a Linux kernel feature which allow processes to be organized into hierarchical groups whose usage of various types of resources can then be limited and monitored. 

With cgroups, a container runtime is able to specify that a container should be able to use (for example):
* Use up to XX% of CPU cycles (cpu.shares)
* Use up to YY MB Memory (memory.limit_in_bytes)
* Throttle reads to ZZ MB/s (blkio.throttle.read_bps_device)

![](./readme-assets/cgroups.jpg) 

---

### Union filesystems

Applications need many files. Copying the same files for every app wastes disk space.  

A union filesystem lets Linux stack multiple directories and present them as one directory.  
The directories are not actually merged. Linux only shows a combined view.  

In Docker, an image is made of read-only directories (layers). Linux stacks these layers and presents them as a single filesystem.  

When a container runs, Docker adds one writable directory on top. All read-only layers are shared and reused, not copied.  

This design avoids duplication, saves disk space, and keeps images lightweight.

**One-line lock:**
Union filesystem exists to reuse shared read-only files instead of copying them.

![](./readme-assets/overlayfs.jpg) 

---

## Docker Application Architecture

Docker is not a single thing. It is made of a core engine, optional developer tooling, and image storage.

The core of Docker is Docker Engine. Docker Engine consists of the Docker daemon (dockerd) and the Docker CLI. The daemon does the real work: building images and running containers. The CLI is just the command you type to talk to the daemon using the Docker API. Docker Engine runs only on Linux and is what is used on servers and production systems.

Docker Desktop is a developer convenience, not Docker itself. It bundles the Docker CLI with a graphical interface, credential helpers, extensions, and a Linux virtual machine. This Linux VM runs Docker Engine inside it. Docker Desktop exists because macOS and Windows do not have the Linux kernel features Docker needs. When you use Docker Desktop, you are actually using Docker Engine running inside a Linux VM.

Container registries are not part of Docker, but they are required to store and share images. Docker can push images to registries and pull images from them. Docker Hub is the default registry, but many others exist. Registries only store images; they do not run containers.

**One-line lock:**
Docker Engine runs containers, Docker Desktop helps developers, and registries store images.

![](./readme-assets/docker-architecture.jpg) 

- You start on your machine and type a Docker command       →    That command goes to the Docker CLI.
- The Docker CLI does not do any real work                  →    It only sends your request to the Docker API.
- The Docker API is handled by the Docker daemon (dockerd)  →    This daemon is where everything actually happens.

The daemon runs inside Linux: 
- directly on a Linux server  
- inside a Linux virtual machine when using Docker Desktop on Mac or Windows  
This Linux environment is **Docker Engine.**

Docker Engine builds images and runs containers. Containers run here as Linux processes using namespaces, cgroups, and union filesystem.  
If an image is not available locally, Docker Engine pulls it from a registry. Registries only store images. They never run containers.  
Docker Desktop is just a wrapper. It provides a GUI, helpers, and a Linux VM so Docker Engine can run on non-Linux systems.  

**One-line lock:**
Command goes in → Docker Engine runs containers → registry stores images.

---

## On the Webstore

Every webstore container is a Linux process running under these exact constraints.

When `docker compose up` starts `webstore-db`:
- A **namespace** gives it its own network — it sees `webstore-db:5432`, not the host's network
- A **cgroup** caps how much RAM postgres can consume — it cannot starve `webstore-api` of memory
- The **union filesystem** stacks the postgres:15 read-only image layers and adds one writable layer on top — that writable layer is where postgres writes its data files until a volume takes over

When `webstore-api` connects to `webstore-db` using the hostname `webstore-db`, that works because Docker's embedded DNS resolver maps that hostname to the container's namespaced IP. No `/etc/hosts` edit. No manual IP. The namespace makes it automatic.

This is not Docker magic. It is Linux kernel features — namespaces, cgroups, overlayfs — wired together by the Docker daemon.

---

## What Breaks

| Symptom | Cause | First command to run |
|---|---|---|
| `docker: Error response from daemon: driver failed programming external connectivity` | Port on the host is already in use by another process | `ss -tulpn \| grep PORT` to find what is using it |
| Container is killed unexpectedly with exit code 137 | cgroup memory limit reached — OOM killer terminated the process | `docker inspect CONTAINER_NAME \| grep -i memory` to check the limit |
| `cannot allocate memory` inside a container | Host has no memory left to give new containers | `free -h` on the host to check available memory |
| Two containers cannot reach each other by hostname | They are on different Docker networks | `docker inspect CONTAINER_NAME \| grep -i network` on both — they must share a network |
| `permission denied` writing files inside a container | The process user inside the container does not own the mounted path | `docker exec -it CONTAINER_NAME ls -la /path` to check ownership |

---

## Daily Commands

| Command | What it does |
|---|---|
| `docker info` | Show storage driver, cgroup driver, and runtime details for this Docker install |
| `docker inspect CONTAINER_NAME` | Full JSON output — namespaces, cgroup limits, mounts, network settings |
| `docker stats` | Live CPU and memory usage per container — shows cgroup limits in action |
| `docker system df` | Show disk usage broken down by images, containers, and volumes |
| `docker system prune` | Remove all stopped containers, dangling images, unused networks |
| `docker network ls` | List all Docker networks on this host |
| `docker network inspect NETWORK_NAME` | Show which containers are on a network and their IPs |
| `docker exec -it CONTAINER_NAME sh` | Open a shell inside a running container |
| `docker history IMAGE` | Show layers that make up an image — union filesystem in action |
| `cat /proc/self/cgroup` | Run inside a container to see its cgroup membership |

---

→ **Interview questions for this topic:** [99-interview-prep → Namespaces · cgroups · How Docker Uses the Linux Kernel](../99-interview-prep/README.md#namespaces--cgroups--how-docker-uses-the-linux-kernel)

---
# SOURCE: 04. Docker – Containerization/03-docker-containers/README.md
---

[Home](../README.md) |
[History & Motivation](../01-history-and-motivation/README.md) |
[Technology Overview](../02-technology-overview/README.md) |
[Docker Containers](../03-docker-containers/README.md) |
[Port Binding](../04-docker-port-binding/README.md) |
[Networking](../05-docker-networking/README.md) |
[Volumes](../06-docker-volumes/README.md) |
[Layers](../07-docker-layers/README.md) |
[Build](../08-docker-build-dockerfile/README.md) |
[Registry](../09-docker-registry/README.md) |
[Compose](../10-docker-compose/README.md) |
[Interview Prep](../99-interview-prep/README.md)

# Docker Containers

## What this file is about (theory)

This file teaches how to **run and operate containers**.

If you can use everything here, you can run prebuilt software without installing it on your host, run services in the background, pass correct startup configuration, debug containers when they fail, and clean Docker safely without breaking anything. This is runtime usage only — not Dockerfile, not image building, not volumes deep dive, not networking deep dive.

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
`-it` attaches your terminal to the container's main process. If that process exits, the container stops.
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
`-d` means "run like a service." You don't enter it. You observe it and manage it.

---

## 5. Configuration at Startup (`-e`)

**Goal:** pass required configuration (passwords, modes, environment flags) at container startup.

| Step | What you do | Command format | Example you run |
|---:|---|---|---|
| 14 | Run tool with required config (`-e`) | `docker run -d --name CONT_NAME -e KEY=VALUE IMAGE:TAG` | `docker run -d --name mysql8 -e MYSQL_ROOT_PASSWORD=secret mysql:8.0` |

**Mental model:**   
Image is generic. `-e` makes it environment-specific at runtime.  
You find required env vars in the image's official docs (Docker Hub).  

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

That's all.  
No magic. No Docker internals.  

---

## 6. Observability & Debugging (Operator Level)

**Goal:** figure out what's wrong without rebuilding.

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

- Container exited or won't stay up → `docker logs`
- Container running but misbehaving → `docker logs -f`
- Unsure how the container was started → `docker inspect`
- Need to look inside a running container → `docker exec`
- Config changed or process stuck → `docker restart`

---

## Command-by-command (why it exists)

| Situation (what you see) | What it means | Command to use | Why this command |
|--------------------------|---------------|----------------|------------------|
| Container exited or won't stay up | App crashed at startup | `docker logs CONT_NAME` | See error output from the last run |
| Container running but acting strange | App is alive but misbehaving | `docker logs -f CONT_NAME` | Watch live behavior and errors |
| You forgot how the container was started | Assumptions are unreliable | `docker inspect CONT_NAME` | Docker's source of truth (env, ports, image) |
| Logs aren't enough | Need to look inside | `docker exec -it CONT_NAME /bin/sh` | Debug from inside the container |
| App stuck or config changed | Process needs reset | `docker restart CONT_NAME` | Clean restart without rebuilding |

---

## 7. Safe Delete Flow (Memorize This)

**Goal:** clean Docker without "blocked by dependency" errors.

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

---

## On the Webstore

These are the exact commands to run the webstore-db container manually — before Compose automates it. The same flags, the same env vars, the same image. Compose just wraps this.

```bash
# Pull the webstore images
docker pull nginx:1.24
docker pull postgres:15

# Run webstore-db in service mode with required config
docker run -d \
  --name webstore-db \
  -e POSTGRES_DB=webstore \
  -e POSTGRES_USER=admin \
  -e POSTGRES_PASSWORD=secret \
  postgres:15

# Run webstore-frontend in service mode
docker run -d \
  --name webstore-frontend \
  nginx:1.24

# Check both are running
docker ps

# Watch webstore-db startup logs
docker logs -f webstore-db

# Inspect webstore-db — confirm env vars were applied
docker inspect webstore-db

# Enter webstore-db to verify postgres is running
docker exec -it webstore-db /bin/sh
# Inside: psql -U admin -d webstore
# Inside: \l   (list databases)
# Inside: exit

# Safe delete when done
docker stop webstore-frontend webstore-db
docker rm webstore-frontend webstore-db
```

**What you are proving:** every flag in the `docker compose up` you run later maps directly to a `docker run` flag you already understand.

---

## What Breaks

| Symptom | Cause | First command to run |
|---|---|---|
| `docker: Error response from daemon: Conflict. The container name is already in use` | A container with that name already exists (even stopped) | `docker ps -a` to find it, then `docker rm NAME` |
| Container exits immediately with no error | The main process has no foreground task to keep it alive | `docker logs CONTAINER_NAME` — look for the exit reason |
| `docker rm` fails with `removal of container is not permitted` | Container is still running | `docker stop NAME` first, then `docker rm NAME` |
| `docker rmi` fails with `image is being used by stopped container` | A stopped container still references the image | `docker ps -a` to find it, `docker rm NAME`, then `docker rmi IMAGE` |
| `Error response from daemon: No such container` | Wrong name or the container was already deleted | `docker ps -a` to see what actually exists |

---

→ **Interview questions for this topic:** [99-interview-prep → Container Lifecycle · Image vs Container · Debugging](../99-interview-prep/README.md#container-lifecycle--debugging)

---
# SOURCE: 04. Docker – Containerization/04-docker-port-binding/README.md
---

[Home](../README.md) |
[History & Motivation](../01-history-and-motivation/README.md) |
[Technology Overview](../02-technology-overview/README.md) |
[Docker Containers](../03-docker-containers/README.md) |
[Port Binding](../04-docker-port-binding/README.md) |
[Networking](../05-docker-networking/README.md) |
[Volumes](../06-docker-volumes/README.md) |
[Layers](../07-docker-layers/README.md) |
[Build](../08-docker-build-dockerfile/README.md) |
[Registry](../09-docker-registry/README.md) |
[Compose](../10-docker-compose/README.md) |
[Interview Prep](../99-interview-prep/README.md)

# Docker Port Binding

## **1) The Problem**
* Containers are isolated.
* Apps run but are not reachable from outside.
* No port binding = no access to the application.

## **2) The Rule (Memorize)**
* **App** listens on a **container port**.
* **Host** (Your Laptop) listens on a **host port**.
* **Docker** creates a rule to map them together.

## **3) The Only Command That Matters**
```bash
docker run -p HOST_PORT:CONTAINER_PORT image
```

**Example:**

```bash
docker run -p 8080:3000 app
```

* **App** inside container is running on `3000`.
* **You** access it on your browser via `localhost:8080`.

## **4) Traffic Flow (Mental Model)**

`Browser` → `Host Port` → `Container Port` → `App`

* This is two-way traffic (request/response).
* It is simple packet forwarding managed by the host's network stack.

## **5) How to check Ground Truth**

Run:

```bash
docker ps
```

Look for the **PORTS** column. If you see:  
```
0.0.0.0:8080->3000/tcp
```
It means the mapping is active and "listening" on all your laptop's network interfaces.  

## **6) Debug in 30 Seconds**

If the app is not loading:

1. **Check Ports**: Run `docker ps`. If the port isn't listed, you forgot `-p`.
2. **Check App**: Run `docker logs <container_id>`.   
If the port mapping exists but it fails, your app inside the container crashed or isn't listening on the right internal port.

## **7) One-Line Definition**

Port binding maps a container's internal port to a host machine port so the application can be accessed by the outside world.

### **Visual Mental Model: The Gatekeeper**

```text
┌──────────────────────────── YOUR LAPTOP (HOST OS) ────────────────────────────┐
│                                                                               │
│  Browser (External World)                                                     │
│    │                                                                          │
│    │  (Request: http://localhost:8080)                                        │
│    ▼                                                                          │
│  Host NIC <──────────────────────────────────┐                                │
│    │                                         │                                │
│    │  (iptables / NAT Engine)                │                                │
│    │  RULE: If traffic hits 8080 -> Forward  │  PORT BINDING (-p)             │
│    └──────────────┬──────────────────────────┘  Bridges Host to Namespace     │
│                   │                                                           │
│                   ▼                                                           │
│      ┌────────────── docker0 (Linux BRIDGE / V-Switch) ────────┐              │
│      │                                                         │              │
│      │   veth (Virtual Cable)                                  │              │
│      │     │                                                   │              │
│      │  ┌──▼──┐                                                │              │
│      │  │ ns  │                                                │              │
│      │  │app  │                                                │              │
│      │  │:3000│                                                │              │
│      │  └─────┘                                                │              │
│      │ (Target)                                                │              │
│      └─────────────────────────────────────────────────────────┘              │
└───────────────────────────────────────────────────────────────────────────────┘
```

---

## On the Webstore

The webstore has two services that need port binding and one that deliberately does not.

```bash
# webstore-frontend — exposed so browsers can reach the UI
docker run -d --name webstore-frontend -p 80:80 nginx:1.24

# webstore-api — exposed so browsers can reach the API
docker run -d --name webstore-api -p 8080:8080 nginx:1.24

# webstore-db — NO -p flag intentionally, internal only
docker run -d \
  --name webstore-db \
  -e POSTGRES_DB=webstore \
  -e POSTGRES_USER=admin \
  -e POSTGRES_PASSWORD=secret \
  postgres:15
```

Check port bindings for all three — webstore-db column will be empty:

```bash
docker ps --format "table {{.Names}}\t{{.Ports}}"
```

Expected:
```
NAMES                PORTS
webstore-frontend    0.0.0.0:80->80/tcp
webstore-api         0.0.0.0:8080->8080/tcp
webstore-db
```

`webstore-db` has no entry — no browser, no external tool, nothing outside Docker can reach it directly. This is intentional. Databases are never exposed publicly.

---

## What Breaks

| Symptom | Cause | First command to run |
|---|---|---|
| `Bind for 0.0.0.0:8080 failed: port is already allocated` | Another container or process already owns that host port | `sudo ss -tlnp \| grep 8080` to find what is using it |
| Browser shows connection refused despite container running | The `-p` flag was omitted | `docker ps` — check the PORTS column, if empty the flag is missing |
| Port mapping shows in `docker ps` but app still unreachable | App inside the container is listening on `127.0.0.1` not `0.0.0.0` | `docker exec -it CONTAINER_NAME ss -tlnp` — check the bind address |
| `docker run -p 80:80` fails with permission denied | Ports below 1024 require elevated privileges on the host | Use a port above 1024 on the host side: `-p 8080:80` |
| Two containers both need the same host port | Host ports are unique — only one process can own a host port at a time | Map to different host ports: `-p 8080:8080` and `-p 8081:8080` |

---

## Daily Commands

| Command | What it does |
|---|---|
| `docker run -p HOST:CONTAINER IMAGE` | Run a container with a port binding |
| `docker ps` | List running containers — PORTS column shows all active bindings |
| `docker port CONTAINER_NAME` | Show all port mappings for a specific container |
| `sudo ss -tlnp \| grep PORT` | Check which process is holding a host port |
| `docker inspect CONTAINER_NAME \| grep -A 5 Ports` | Full port binding detail from Docker's source of truth |
| `sudo iptables -t nat -L DOCKER -n` | Show the DNAT rules Docker created — one per `-p` flag |

---

→ **Interview questions for this topic:** [99-interview-prep → Port Binding · NAT · Container Networking](../99-interview-prep/README.md#port-binding--nat--container-networking)

→ Ready to practice? [Go to Lab 01](../docker-labs/01-containers-portbinding-lab.md)

---
# SOURCE: 04. Docker – Containerization/05-docker-networking/README.md
---

[Home](../README.md) |
[History & Motivation](../01-history-and-motivation/README.md) |
[Technology Overview](../02-technology-overview/README.md) |
[Docker Containers](../03-docker-containers/README.md) |
[Port Binding](../04-docker-port-binding/README.md) |
[Networking](../05-docker-networking/README.md) |
[Volumes](../06-docker-volumes/README.md) |
[Layers](../07-docker-layers/README.md) |
[Build](../08-docker-build-dockerfile/README.md) |
[Registry](../09-docker-registry/README.md) |
[Compose](../10-docker-compose/README.md) |
[Interview Prep](../99-interview-prep/README.md)

# Docker Networking

## What This File Is About

Containers are isolated by design — they cannot talk to each other or the outside world unless you explicitly wire them together. This file covers how Docker networking works under the hood, why the localhost rule breaks beginners, how Docker DNS makes container name resolution automatic, and how port binding is just NAT in disguise. By the end you will understand not just the commands but exactly what happens at the network layer when containers communicate.

> **Foundation:** This file builds on networking concepts covered in the Networking notes — specifically NAT (file 07), DNS (file 08), and how bridges and routing work (file 04). Read those first if anything here feels abstract.

---

## Table of Contents

1. [The Core Problem — Isolation by Default](#1-the-core-problem--isolation-by-default)
2. [The Localhost Rule — Non-Negotiable](#2-the-localhost-rule--non-negotiable)
3. [How Docker Networking Works Under the Hood](#3-how-docker-networking-works-under-the-hood)
4. [Docker Network Modes](#4-docker-network-modes)
5. [Docker DNS — How Container Names Resolve](#5-docker-dns--how-container-names-resolve)
6. [Port Binding — NAT in Action](#6-port-binding--nat-in-action)
7. [Network Isolation — Why It Matters](#7-network-isolation--why-it-matters)
8. [The Webstore Setup — Manual Commands Line by Line](#8-the-webstore-setup--manual-commands-line-by-line)
9. [Debugging Docker Networking](#9-debugging-docker-networking)

---

## 1. The Core Problem — Isolation by Default

When you run a container without any network configuration, Docker puts it in a completely isolated environment. It has its own network namespace — its own IP stack, its own routing table, its own localhost. It cannot see any other container and nothing outside can reach it.

This isolation is a feature, not a bug. It is what makes containers safe to run side by side on the same host without interfering with each other. But it means you have to deliberately wire containers together when they need to communicate.

**The three questions every container setup must answer:**

```
1. How do containers talk to each other?
   → Put them on the same Docker network

2. How does the host machine reach a container?
   → Port binding (-p flag)

3. How does a container reach the internet?
   → Docker handles this automatically via NAT
```

---

## 2. The Localhost Rule — Non-Negotiable

**The most common Docker mistake** is using `localhost` to connect containers together. It always fails. Understanding why requires understanding what localhost actually means.

**The Rule:** `localhost` always means "the machine I am currently running inside."

| Where you are | What localhost means |
|---|---|
| Your laptop terminal | Your laptop |
| webstore-api container | webstore-api container only |
| webstore-db container | webstore-db container only |
| adminer container | adminer container only |

Each container has its own network namespace. Its own localhost. Completely separate from every other container and from the host machine.

**What breaks:**

```bash
# Inside webstore-api container — this ALWAYS fails
# Because localhost means webstore-api itself, not webstore-db
DB_HOST="localhost"
DB_PORT=5432
```

```bash
# This works — using the container name as hostname
DB_HOST="webstore-db"
DB_PORT=5432
```

**The fix:** containers talk to each other using **container names**, not localhost. Docker DNS translates the container name to its IP automatically. This is covered in Section 5.

---

## 3. How Docker Networking Works Under the Hood

**The Bridge Analogy:**
Think of Docker networking like a private office building. Each floor is a separate Docker network — a private LAN. Containers on the same floor can talk to each other directly. Containers on different floors cannot see each other at all. The building's reception desk (the host machine) handles all traffic coming in and going out to the street (the internet).

When Docker installs, it creates a virtual network bridge on your host called `docker0`. This bridge acts like a virtual ethernet switch — a Layer 2 device that connects all containers on the default network.

```
┌──────────────────────── YOUR LAPTOP (HOST OS) ─────────────────────────────┐
│                                                                            │
│  Browser                                                                   │
│    │                                                                       │
│    │  http://localhost:8080                                                │
│    ▼                                                                       │
│  Host Network Interface (en0 / eth0)                                       │
│    │                                                                       │
│    │  iptables DNAT rule:                                                  │
│    │  "Traffic hitting host:8080 → forward to container:8080"              │
│    ▼                                                                       │
│  ┌──────────────── docker0 Bridge (172.18.0.1) ───────────────────┐        │
│  │   Virtual switch — all containers on this network connect here │        │
│  │                                                                │        │
│  │   veth pair            veth pair            veth pair          │        │
│  │   (virtual cable)      (virtual cable)      (virtual cable)    │        │
│  │        │                    │                    │             │        │
│  │  ┌─────▼──────┐      ┌──────▼─────┐      ┌──────▼──────┐       │        │
│  │  │webstore-api│      │webstore-db │      │  adminer    │       │        │
│  │  │172.18.0.2  │─────▶│172.18.0.3  │◀─────│172.18.0.4   │       │        │
│  │  │  :8080     │ DNS  │  :5432     │ DNS  │   :8080     │       │        │
│  │  └────────────┘      └────────────┘      └─────────────┘       │        │
│  └────────────────────────────────────────────────────────────────┘        │
└────────────────────────────────────────────────────────────────────────────┘
```

**What is a veth pair?**
Every container gets a virtual ethernet cable. One end lives inside the container (named `eth0` from inside). The other end connects to the `docker0` bridge on the host. When a container sends a packet, it travels down its virtual cable to the bridge, which forwards it to the right destination — exactly like a physical network switch reads MAC addresses and forwards frames to the right port.

**How containers get IPs:**
Docker runs an internal DHCP-like system. When a container joins a network, Docker assigns it an IP from the network's subnet. The bridge itself gets the gateway IP (`.1`). Containers get sequential IPs from `.2` onward. These IPs are private and only reachable from within that Docker network.

---

## 4. Docker Network Modes

Docker ships with three network modes. Each solves a different problem.

| Mode | What it does | When to use it |
|---|---|---|
| **bridge** | Creates a private internal network. Containers communicate via Docker DNS. Port binding required for external access. | Default for almost everything — multi-container apps |
| **host** | Container shares the host's network stack directly. No isolation, no port binding needed. | When you need maximum performance or the app needs to bind to specific host ports |
| **none** | No network at all. Complete isolation. | Security-sensitive containers that should never communicate |

**Bridge (default — what you use 99% of the time):**

```bash
docker run --network webstore-network --name webstore-api nginx
# Container gets its own IP on webstore-network
# Reachable from other containers by name: webstore-api
# Not reachable from outside without -p flag
```

**Host:**

```bash
docker run --network host nginx
# Container binds directly to host port 80
# No NAT, no port mapping
# localhost:80 on the host reaches the container directly
# Risk: container can see and bind to any host port
```

**None:**

```bash
docker run --network none nginx
# No eth0, no IP, no internet
# Completely isolated — cannot send or receive any traffic
```

**The Rule:** Always use a named bridge network (`docker network create`) for multi-container apps. Never use the default `bridge` network (also called `bridge`) for anything beyond testing — it does not have Docker DNS, so containers cannot find each other by name.

---

## 5. Docker DNS — How Container Names Resolve

**The Phone Book Analogy:**
When you create a custom Docker network, Docker starts an embedded DNS server for that network. This DNS server maintains a live phone book — every container that joins the network gets its name registered as an entry. When webstore-api asks "who is webstore-db?", it calls Docker DNS at `127.0.0.11`, gets back the IP, and connects.

```
webstore-api container
    │
    │  "Connect to webstore-db:5432"
    │
    ▼
Docker DNS (127.0.0.11)
    │
    │  Lookup: "webstore-db"
    │  Answer:  "172.18.0.3"
    │
    ▼
webstore-api connects to 172.18.0.3:5432
    │
    ▼
webstore-db container receives the connection
```

**Verify Docker DNS is configured inside a container:**

```bash
docker exec webstore-api cat /etc/resolv.conf

# Expected output:
nameserver 127.0.0.11
options ndots:0
```

`127.0.0.11` is Docker's embedded DNS server. Every container on a custom network gets this configured automatically.

**Test name resolution from inside a container:**

```bash
docker exec webstore-api nslookup webstore-db

# Expected output:
Server:         127.0.0.11
Address:        127.0.0.11:53

Non-authoritative answer:
Name:   webstore-db
Address: 172.18.0.3
```

**Why this only works on custom networks:**
The default `bridge` network does not enable Docker DNS. Containers on it cannot resolve each other by name — only by IP. This is one of the main reasons you always create a named network for your app.

**What happens when a container restarts:**
When webstore-db restarts, it may get a different IP (e.g., `172.18.0.5` instead of `172.18.0.3`). Docker DNS updates automatically — webstore-api still connects to `webstore-db:5432` and gets the new IP without any configuration change. This is the same principle as Kubernetes labels and selectors — never hardcode IPs, always use names.

---

## 6. Port Binding — NAT in Action

**The Reception Desk Analogy:**
The host machine is a hotel reception desk. From the outside, everyone calls one number (the host IP). Reception (Docker's iptables rules) answers and routes each call to the right room (container). The guest in the room (the container) only ever sees an internal call — they never know the caller came from outside.

Port binding (`-p host_port:container_port`) creates a NAT rule on the host using iptables. When traffic arrives on the host port, iptables rewrites the destination IP and port and forwards it to the container.

```
External request:
  Destination: host_machine:8080

iptables DNAT rule (created by Docker):
  IF destination port = 8080
  THEN rewrite destination to 172.18.0.2:8080

Container receives:
  A normal incoming connection on its port 8080
  It never sees the original host IP or port
```

**Verify the iptables rule Docker created:**

```bash
sudo iptables -t nat -L DOCKER -n

# Expected output (simplified):
Chain DOCKER (2 references)
target  prot  opt  source    destination
DNAT    tcp   --   0.0.0.0/0 0.0.0.0/0   tcp dpt:8080 to:172.18.0.2:8080
DNAT    tcp   --   0.0.0.0/0 0.0.0.0/0   tcp dpt:8080 to:172.18.0.4:8080
```

**The port binding format:**

```
-p 8080:8080
   │    │
   │    └── Container port (what the app listens on inside)
   └──────── Host port (what the outside world connects to)
```

They do not have to match:

```bash
# Host port 3000 forwards to container port 8080
docker run -p 3000:8080 webstore-api
```

**What happens without port binding:**

```bash
docker run -d --name webstore-api --network webstore-network webstore-api
# No -p flag — container is running but unreachable from outside
# webstore-db can reach it (same network)
# Your browser cannot reach it
```

Containers on the same Docker network can communicate directly — no port binding needed between them. Port binding is only for traffic coming from outside the Docker network (your browser, external services).

---

## 7. Network Isolation — Why It Matters

Docker lets you create multiple networks and control exactly which containers can see each other. This is the same security principle as AWS VPC subnets — public subnet (exposed) and private subnet (internal only).

**The Webstore Security Model:**

```
┌─────────────────── webstore-network ──────────────────────┐
│                                                           │
│  webstore-frontend ──▶ webstore-api ──▶ webstore-db       │
│  (nginx:1.24)           (app)            (postgres:15)    │
│                                                           │
└───────────────────────────────────────────────────────────┘

webstore-frontend: port 80 exposed to host (-p 80:80)
webstore-api:      port 8080 exposed to host (-p 8080:8080)
webstore-db:       NO port exposed — internal only
adminer:           port 8080 exposed to host (-p 8081:8080) — dev only
```

`webstore-db` has no `-p` flag. It is unreachable from your browser, from the internet, from any other Docker network. Only containers on `webstore-network` can connect to it. This is production-safe database isolation without any firewall rules.

**Multi-network isolation:**

```bash
docker network create frontend-network
docker network create backend-network

# webstore-frontend only on frontend
docker run --network frontend-network --name webstore-frontend nginx:1.24

# webstore-api on both — the bridge between the two tiers
docker run --network frontend-network --name webstore-api webstore-api
docker network connect backend-network webstore-api

# webstore-db only on backend — invisible to frontend
docker run --network backend-network --name webstore-db postgres:15
```

```
frontend-network:   webstore-frontend ←→ webstore-api
backend-network:    webstore-api ←→ webstore-db

webstore-frontend cannot reach webstore-db — different networks
webstore-api can reach both — it is connected to both networks
```

**Verify a container's network connections:**

```bash
docker inspect webstore-api | grep -A 20 "Networks"
```

---

## 8. The Webstore Setup — Manual Commands Line by Line

This is the full webstore stack brought up manually. Every flag is explained.

**Roles and direction:**

```
webstore-api    = client  (connects TO the database)
webstore-db     = server  (waits for connections)
adminer         = client  (connects TO the database for the UI)
```

**Step 1 — Create the network**

```bash
docker network create webstore-network
```

This creates a private bridge network with Docker DNS enabled. Every container that joins this network can reach every other container by name.

**Step 2 — Start the database first**

```bash
docker run -d \
  --name webstore-db \
  --network webstore-network \
  -e POSTGRES_DB=webstore \
  -e POSTGRES_USER=admin \
  -e POSTGRES_PASSWORD=secret \
  -v webstore-db-data:/var/lib/postgresql/data \
  postgres:15
```

Start the server before the clients. webstore-api will fail to connect if the database is not ready when it starts.

**Step 3 — Start adminer (database UI)**

```bash
docker run -d \
  -p 8081:8080 \
  --name adminer \
  --network webstore-network \
  adminer
```

Adminer connects to any database using the connection form in the browser. Use `webstore-db` as the server hostname — Docker DNS resolves it automatically.

**Step 4 — Build and start the API**

```bash
docker build -t webstore-api .

docker run -d \
  -p 8080:8080 \
  --name webstore-api \
  --network webstore-network \
  -e DB_HOST=webstore-db \
  -e DB_PORT=5432 \
  -e DB_NAME=webstore \
  -e DB_USER=admin \
  -e DB_PASSWORD=secret \
  webstore-api
```

**The final data flows:**

```
App path:   Browser → localhost:8080 → webstore-api → webstore-db:5432
Debug path: Browser → localhost:8081 → adminer → webstore-db:5432
```

---

## 9. Debugging Docker Networking

**Symptom: container cannot reach another container**

```bash
# Step 1 — Are they on the same network?
docker inspect webstore-api | grep -A 5 "Networks"
docker inspect webstore-db | grep -A 5 "Networks"

# Step 2 — Can the container resolve the hostname?
docker exec webstore-api nslookup webstore-db

# Step 3 — Can the container reach the port?
docker exec webstore-api nc -zv webstore-db 5432

# Step 4 — Check what the container is actually trying to connect to
docker logs webstore-api
```

**Symptom: browser cannot reach container**

```bash
# Step 1 — Is the port binding active?
docker ps | grep webstore-api
# Look for: 0.0.0.0:8080->8080/tcp

# Step 2 — Is the container running?
docker ps

# Step 3 — Is the app inside listening on the right port?
docker exec webstore-api ss -tlnp
```

**Symptom: containers on same network cannot find each other**

Most common cause: using the default `bridge` network instead of a named network.

```bash
# Wrong — default bridge, no DNS
docker run --name webstore-api nginx
docker run --name webstore-db postgres:15

# Right — named network, DNS works
docker network create webstore-network
docker run --network webstore-network --name webstore-api nginx
docker run --network webstore-network --name webstore-db postgres:15
```

---

## What Breaks

| Symptom | Cause | First command to run |
|---|---|---|
| `ping: bad address 'webstore-db'` | Containers are on different networks or the default bridge | `docker inspect CONTAINER \| grep -A 5 Networks` on both containers |
| Connection refused when using container name | Container is on a named network but the app hardcoded `localhost` | `docker exec -it CONTAINER env \| grep DB_HOST` — check the env var |
| `docker network create` succeeds but DNS still fails | Container joined the default `bridge` not the named network — missing `--network` flag | `docker inspect CONTAINER \| grep -A 5 Networks` — check which network it actually joined |
| Container can reach the internet but not sibling containers | Missing `--network` flag on one of the containers | `docker inspect CONTAINER \| grep -A 5 Networks` — one will show `bridge`, not your network |
| Port binding works but containers talk to each other on wrong port | Confusing host port with container port | Container-to-container traffic uses container port not host port — use `webstore-db:5432` not `webstore-db:8081` |

---

## Daily Commands

| Command | What it does |
|---|---|
| `docker network create NAME` | Create a named bridge network with Docker DNS enabled |
| `docker network ls` | List all networks on this host |
| `docker network inspect NAME` | Show all containers on a network and their IPs |
| `docker network rm NAME` | Delete a network — all containers must be disconnected first |
| `docker exec CONTAINER cat /etc/resolv.conf` | Confirm Docker DNS is configured inside a container |
| `docker exec CONTAINER nslookup TARGET` | Test DNS resolution from inside a container |
| `docker exec CONTAINER nc -zv TARGET PORT` | Test TCP reachability from inside a container |
| `docker inspect CONTAINER \| grep -A 5 Networks` | Show which network a container is on and its IP |

---

→ **Interview questions for this topic:** [99-interview-prep → Docker Networking · DNS · Localhost Rule](../99-interview-prep/README.md#docker-networking--dns--localhost-rule)

→ Ready to practice? [Go to Lab 02](../docker-labs/02-networking-volumes-lab.md)

---
# SOURCE: 04. Docker – Containerization/06-docker-volumes/README.md
---

[Home](../README.md) |
[History & Motivation](../01-history-and-motivation/README.md) |
[Technology Overview](../02-technology-overview/README.md) |
[Docker Containers](../03-docker-containers/README.md) |
[Port Binding](../04-docker-port-binding/README.md) |
[Networking](../05-docker-networking/README.md) |
[Volumes](../06-docker-volumes/README.md) |
[Layers](../07-docker-layers/README.md) |
[Build](../08-docker-build-dockerfile/README.md) |
[Registry](../09-docker-registry/README.md) |
[Compose](../10-docker-compose/README.md) |
[Interview Prep](../99-interview-prep/README.md)

# Docker Volumes

## What This File Is About

Containers are ephemeral. When a container is deleted, everything written inside it is gone — including database rows, uploaded files, and logs. Volumes are Docker's answer to this problem. They store data outside the container so it survives container replacement, deletion, and rebuilds.

---

## Table of Contents

1. [The Core Problem](#1-the-core-problem)
2. [Types of Storage](#2-types-of-storage)
3. [Named Volumes — Docker Managed](#3-named-volumes--docker-managed)
4. [Bind Mounts — You Control the Path](#4-bind-mounts--you-control-the-path)
5. [Bind Mount Workflow](#5-bind-mount-workflow)
6. [Volume Management Commands](#6-volume-management-commands)
7. [When to Use What](#7-when-to-use-what)
8. [Real-World Database Example — webstore-db](#8-real-world-database-example--webstore-db)
9. [Safe Delete Flow](#9-safe-delete-flow)
[Final Compression](#final-compression-memorize)

---

## 1. The Core Problem

A container is a running process with a temporary filesystem. Everything inside that filesystem lives only as long as the container lives.

```
docker run postgres:15          → database starts, stores data inside container
docker stop webstore-db         → container stops
docker rm webstore-db           → container deleted
docker run postgres:15          → fresh container, ALL DATA IS GONE
```

This is intentional — containers are designed to be replaceable. The solution is to store data in a volume that lives independently of any container.

---

## 2. Types of Storage

| Type | Who controls the path | Where data lives | Best for |
|---|---|---|---|
| **Named Volume** | Docker | Docker-managed location on host | Database data, critical persistent state |
| **Bind Mount** | You | Exact path you specify on host | Development — edit code on host, see changes in container |
| **tmpfs** | OS | RAM only, not on disk | Sensitive data that must not touch disk |

---

## 3. Named Volumes — Docker Managed

Docker creates and manages the storage location. You give the volume a name and mount it to a path inside the container.

| Step | What you do | Command format | Example you run |
|---:|---|---|---|
| 1 | Create a named volume | `docker volume create VOLUME_NAME` | `docker volume create webstore-db-data` |
| 2 | Run container with named volume | `docker run -v VOLUME_NAME:/container/path IMAGE` | `docker run -v webstore-db-data:/var/lib/postgresql/data postgres:15` |
| 3 | List all volumes | `docker volume ls` | `docker volume ls` |
| 4 | Inspect a volume | `docker volume inspect VOLUME_NAME` | `docker volume inspect webstore-db-data` |

**What you observe:**

The volume mounts the named volume to PostgreSQL's data directory. PostgreSQL writes to `/var/lib/postgresql/data`. The data actually goes to the `webstore-db-data` volume on the host. If you delete the container and run a new one with the same volume, all data survives.

**Syntax breakdown:**
```bash
docker run -v webstore-db-data:/var/lib/postgresql/data postgres:15
           ↑                    ↑
     volume name          path inside container
```

---

## 4. Bind Mounts — You Control the Path

You specify an absolute path on your host. That host directory is mounted directly into the container at the specified container path. Changes in either location are instantly visible in the other.

| Step | What you do | Command format | Example you run |
|---:|---|---|---|
| 5 | Check your current location | `pwd` | `pwd` (note the output) |
| 6 | Create a folder on host | `mkdir host-data` | `mkdir host-data` |
| 7 | Run container with bind mount | `docker run -it --rm -v /absolute/host/path:/container/path IMAGE` | `docker run -it --rm -v $(pwd)/host-data:/data ubuntu:22.04` |

---

## 5. Bind Mount Workflow

| Step | What you do | Command | What happens |
|---:|---|---|---|
| 8 | Create folder on host | `mkdir ~/my-app-data` | Folder created on your laptop |
| 9 | Run container with bind mount | `docker run -it --rm -v ~/my-app-data:/data ubuntu:22.04` | `/data` inside container = `~/my-app-data` on host |
| 10 | Write file inside container | `echo "from container" > /data/test.txt` | File written |
| 11 | Exit container | `exit` | Container deleted |
| 12 | Check file on host | `cat ~/my-app-data/test.txt` | **Prints: `from container`** ✅ |
| 13 | Edit file on host | `echo "from host" >> ~/my-app-data/test.txt` | Modified on laptop |
| 14 | Run new container with same mount | `docker run -it --rm -v ~/my-app-data:/data ubuntu:22.04` | Fresh container |
| 15 | Read file inside container | `cat /data/test.txt` | Sees both lines (changes from host appear immediately) |

**Key insight:**
- Changes in container → visible on host immediately
- Changes on host → visible in container immediately
- It's the **same folder**, just accessed from two places

**Syntax breakdown:**
```bash
docker run -v /host/path:/container/path IMAGE
           ↑            ↑
     real folder    where it appears
     on laptop      inside container
```

---

## 6. Volume Management Commands

| Step | What you do | Command format | Example you run |
|---:|---|---|---|
| 16 | List all volumes | `docker volume ls` | `docker volume ls` |
| 17 | Inspect a volume (see location, driver, etc.) | `docker volume inspect VOLUME_NAME` | `docker volume inspect webstore-db-data` |
| 18 | Delete a specific volume | `docker volume rm VOLUME_NAME` | `docker volume rm webstore-db-data` |
| 19 | Delete all unused volumes | `docker volume prune` | `docker volume prune` |
| 20 | Force delete all unused volumes (no confirmation) | `docker volume prune -f` | `docker volume prune -f` |

**Important rule:**
- You cannot delete a volume that is currently being used by a container
- Stop and remove the container first, then delete the volume

---

## 7. When to Use What

| Situation | Use | Why |
|---|---|---|
| Database data (PostgreSQL, MySQL) | Named Volume | Data must survive container replacement |
| Application uploads (user files, images) | Named Volume | Critical data, managed by Docker |
| Production state, logs | Named Volume | Needs to persist across deployments |
| Source code during development | Bind Mount | You edit files on laptop, changes appear in container immediately |
| Configuration files | Bind Mount | Easy to edit, version control |
| Temporary testing | Bind Mount | Quick access to files |

**Decision rule:**
```
If data must survive and you don't need to touch it often → Named Volume
If you need to edit files frequently from host → Bind Mount
```

---

## 8. Real-World Database Example — webstore-db

**Problem:**
- PostgreSQL stores data in `/var/lib/postgresql/data` inside the container
- If the container is deleted, the webstore database is gone
- We need data to survive container deletion

**Solution:**
```bash
docker run -d \
  --name webstore-db \
  --network webstore-network \
  -e POSTGRES_DB=webstore \
  -e POSTGRES_USER=admin \
  -e POSTGRES_PASSWORD=secret \
  -v webstore-db-data:/var/lib/postgresql/data \
  postgres:15
```

---

### New commands introduced here

**`docker exec` with a specific program (not a shell)**

You've used `docker exec -it CONTAINER /bin/sh` before — that opens a generic shell. Here you run a specific program directly instead:

```bash
docker exec -it webstore-db psql -U admin -d webstore
                               ↑             ↑
                          the program    its own flags
```

`docker exec` doesn't require a shell. It runs **any binary installed inside the container**. `psql` is PostgreSQL's command-line client — it's already inside the `postgres:15` image.

| Part | What it is | What it does |
|---|---|---|
| `docker exec -it webstore-db` | Docker command | Enter the running container named `webstore-db` |
| `psql` | PostgreSQL binary (inside the container) | Launch the PostgreSQL client |
| `-U admin` | psql flag | Connect as user `admin` |
| `-d webstore` | psql flag | Connect to the `webstore` database |

Once inside `psql`, you are no longer in Docker — you are in a PostgreSQL shell.

---

**Commands inside `psql`**

These are SQL + psql-specific, not Docker commands:

| Command | What it does |
|---|---|
| `CREATE TABLE products (id SERIAL, name TEXT);` | Creates a table with two columns |
| `INSERT INTO products (name) VALUES ('Widget');` | Inserts one row |
| `SELECT * FROM products;` | Reads all rows |
| `\q` | Quits `psql` — returns you to the host terminal |

`\q` is the psql quit shortcut. `\` commands are psql-internal — they don't go to the database.

---

**`-c` flag — run SQL without entering the shell**

```bash
docker exec -it webstore-db psql -U admin -d webstore -c "SELECT * FROM products;"
```

`-c` belongs to `psql`, not Docker. It means: **run this one SQL statement and exit immediately**. Useful when you want a quick check from the host without dropping into an interactive session.

```
Without -c → opens interactive psql shell → you type → \q to exit
With -c    → runs the query → prints result → exits automatically
```

---

### Verification flow

| Step | Command | What happens |
|---:|---|---|
| 1 | `docker run -d --name webstore-db -v webstore-db-data:/var/lib/postgresql/data -e POSTGRES_DB=webstore -e POSTGRES_USER=admin -e POSTGRES_PASSWORD=secret postgres:15` | Container starts, volume created |
| 2 | `docker exec -it webstore-db psql -U admin -d webstore` | Opens PostgreSQL shell directly inside the container |
| 3 | `CREATE TABLE products (id SERIAL, name TEXT);` → `INSERT INTO products (name) VALUES ('Widget');` | Data written to the volume |
| 4 | `\q` | Exit psql, back to host |
| 5 | `docker stop webstore-db` → `docker rm webstore-db` | Container deleted — volume survives |
| 6 | `docker run -d --name webstore-db -v webstore-db-data:/var/lib/postgresql/data -e POSTGRES_DB=webstore -e POSTGRES_USER=admin -e POSTGRES_PASSWORD=secret postgres:15` | Fresh container, same volume attached |
| 7 | `docker exec -it webstore-db psql -U admin -d webstore -c "SELECT * FROM products;"` | Data still exists ✅ |

**What step 7 proves:** the data lives in the volume, not the container. The container was completely deleted and recreated — the data didn't move.

---

## 9. Safe Delete Flow (Volumes Edition)

**Rule:** Volumes are independent of containers. You can delete a container without deleting its volume.

### Order of operations (non-negotiable)

| Step | What you do | Command format | Example |
|---:|---|---|---|
| 21 | Stop container (if running) | `docker stop CONTAINER_NAME` | `docker stop webstore-db` |
| 22 | Remove container | `docker rm CONTAINER_NAME` | `docker rm webstore-db` |
| 23 | **Only if you want to delete data:** Remove volume | `docker volume rm VOLUME_NAME` | `docker volume rm webstore-db-data` |

**Critical safety rule:**
- Removing a container does **NOT** delete its volumes
- Volumes persist until you explicitly delete them
- This prevents accidental data loss

**When to delete volumes:**
- Testing is done and you don't need the data
- Cleaning up old projects
- Resetting state completely

**When NOT to delete volumes:**
- Production data
- Any database you still need
- Anything you might want later

---

## Final Compression (Memorize)

**Problem:**
Containers are temporary → data inside them dies

**Solution:**
Volumes are permanent → data survives container deletion

**Two types:**
1. Named volumes → Docker manages, use for critical data
2. Bind mounts → You control path, use for development

**Commands to memorize:**
```bash
# Named volume
docker volume create webstore-db-data
docker run -v webstore-db-data:/var/lib/postgresql/data postgres:15

# Bind mount
docker run -v /host/path:/container/path IMAGE

# Management
docker volume ls
docker volume rm VOLUME_NAME
docker volume prune
```

**Mental model:**
```
Container (code runs here)  ──>  Volume (data lives here)
    ↓                              ↓
  Dies when deleted            Survives forever
```

**Delete order:**
1. Stop container
2. Remove container
3. (Optional) Remove volume

**Never forget:**
Data in containers = temporary
Data in volumes = permanent

---

## What Breaks

| Symptom | Cause | First command to run |
|---|---|---|
| `docker: Error response from daemon: invalid mount config` | Bind mount path does not exist on the host | Create the host directory first: `mkdir -p /host/path` |
| Data is gone after container restart | No volume attached — data was written to the container layer | `docker inspect CONTAINER_NAME \| grep Mounts` — if empty, no volume was used |
| `docker volume rm` fails with `volume is in use` | A container (even stopped) still references the volume | `docker ps -a` to find it, `docker rm CONTAINER_NAME` first |
| Changes on host not visible inside container | Bind mount path is wrong — host and container paths don't match | `docker inspect CONTAINER_NAME \| grep -A 10 Mounts` — verify the Source and Destination paths |
| Named volume exists but data is missing | A new volume was created with the same name after the old one was deleted | `docker volume inspect VOLUME_NAME` — check `CreatedAt` to confirm it is the right volume |

---

## Daily Commands

| Command | What it does |
|---|---|
| `docker volume create NAME` | Create a named volume |
| `docker volume ls` | List all volumes on this host |
| `docker volume inspect NAME` | Show volume location, driver, and mount path |
| `docker volume rm NAME` | Delete a volume — container must be removed first |
| `docker volume prune` | Delete all volumes not currently used by any container |
| `docker run -v NAME:/container/path IMAGE` | Mount a named volume into a container |
| `docker run -v /host/path:/container/path IMAGE` | Bind mount a host directory into a container |
| `docker inspect CONTAINER \| grep -A 10 Mounts` | Show all volume and bind mount details for a container |

---
→ **Interview questions for this topic:** [99-interview-prep → Volumes · Named vs Bind · Data Persistence](../99-interview-prep/README.md#volumes--named-vs-bind--data-persistence)

→ Ready to practice? [Go to Lab 02](../docker-labs/02-networking-volumes-lab.md)

---
# SOURCE: 04. Docker – Containerization/07-docker-layers/README.md
---

[Home](../README.md) |
[History & Motivation](../01-history-and-motivation/README.md) |
[Technology Overview](../02-technology-overview/README.md) |
[Docker Containers](../03-docker-containers/README.md) |
[Port Binding](../04-docker-port-binding/README.md) |
[Networking](../05-docker-networking/README.md) |
[Volumes](../06-docker-volumes/README.md) |
[Layers](../07-docker-layers/README.md) |
[Build](../08-docker-build-dockerfile/README.md) |
[Registry](../09-docker-registry/README.md) |
[Compose](../10-docker-compose/README.md) |
[Interview Prep](../99-interview-prep/README.md)

# Docker Layers

## What this file is about

This file teaches **how Docker images are structured and optimized**. If you can use everything here, you can build faster images, understand caching behavior, optimize Dockerfiles for speed, and diagnose why builds are slow.

1. [What Are Layers (Visual First)](#1-what-are-layers-visual-first)
2. [See Layers With Your Own Eyes](#2-see-layers-with-your-own-eyes)
3. [How Layers Are Created (Dockerfile → Layers)](#3-how-layers-are-created-dockerfile--layers)
4. [Layer Caching in Action (Build Twice)](#4-layer-caching-in-action-build-twice)
5. [What Breaks the Cache](#5-what-breaks-the-cache)
6. [Optimization Pattern (Bad → Good Dockerfile)](#6-optimization-pattern-bad--good-dockerfile)
7. [Layer Reuse When Pulling Images](#7-layer-reuse-when-pulling-images)
8. [Verify Layer Sharing (Practical Check)](#8-verify-layer-sharing-practical-check)
9. [Common Mistakes That Waste Cache](#9-common-mistakes-that-waste-cache)
10. [The Container Runtime Layer](#10-the-container-runtime-layer)  
[Final Compression (Memorize)](#final-compression-memorize)

---

## 1. What Are Layers (Visual First)

**Core concept:**
A Docker image is NOT a single file.
It is a **stack of read-only layers**.

Each layer represents the filesystem changes from **one Dockerfile instruction**.

![](./readme-assets/container-filesystem.jpg)

**What this image shows:**

```
┌─────────────────────────────────────────┐
│ WRITABLE CONTAINER LAYER (Runtime only) │  ← Created when container runs
│ Temporary, deleted with container       │
├─────────────────────────────────────────┤
│ LAYER 7: CMD ["node","app.js"]          │  ← Metadata only (no files)
├─────────────────────────────────────────┤
│ LAYER 6: COPY . .                       │  ← Your application code
├─────────────────────────────────────────┤
│ LAYER 5: RUN npm install                │  ← node_modules/ (heavy)
├─────────────────────────────────────────┤
│ LAYER 4: COPY package.json .            │  ← Dependency manifest
├─────────────────────────────────────────┤
│ LAYER 3: WORKDIR /app                   │  ← Directory structure
├─────────────────────────────────────────┤
│ LAYER 2: Intermediate OS setup          │  ← Base image internals
├─────────────────────────────────────────┤
│ LAYER 1: FROM node:20                   │  ← Base filesystem
└─────────────────────────────────────────┘
   ↑
   All these layers are READ-ONLY
   Stacked on top of each other
```

**Mental model:**
- Image = stack of transparent sheets
- Each sheet = one Dockerfile instruction
- Docker combines them into one visible filesystem
- Bottom layer = base image
- Top layer = your latest changes

---

## 2. See Layers With Your Own Eyes

**Goal:** Inspect actual layers of a real image.

| Step | What you do | Command | What to observe |
|---:|---|---|---|
| 1 | Pull a small image | `docker pull alpine:3.18` | Image downloaded |
| 2 | View its layers | `docker history alpine:3.18` | See each layer's size and command |
| 3 | Pull a Node.js image | `docker pull node:20-alpine` | Larger image downloaded |
| 4 | View its layers | `docker history node:20-alpine` | Many more layers visible |

**Example output:**
```bash
docker history node:20-alpine
```

```
IMAGE          CREATED        CREATED BY                                      SIZE
a1b2c3d4e5f6   2 weeks ago    CMD ["node"]                                    0B
b2c3d4e5f6a7   2 weeks ago    ENTRYPOINT ["docker-entrypoint.sh"]            0B
c3d4e5f6a7b8   2 weeks ago    COPY docker-entrypoint.sh /usr/local/bin/      1.2kB
d4e5f6a7b8c9   2 weeks ago    RUN /bin/sh -c apk add --no-cache ...          75MB
e5f6a7b8c9d0   2 weeks ago    ENV NODE_VERSION=20.11.0                        0B
f6a7b8c9d0e1   3 weeks ago    /bin/sh -c #(nop) ADD file:abc123... in /      7.3MB
```

**What each column means:**
- `IMAGE` → Layer ID (hash)
- `CREATED` → When this layer was built
- `CREATED BY` → Which Dockerfile instruction created it
- `SIZE` → How much disk space this layer added

**Key observations:**
1. Metadata instructions (`CMD`, `ENV`) add **0B** (no files changed)
2. `RUN` and `COPY` add actual size
3. Layers stack bottom → top
4. Each layer has a unique hash (ID)

---

## 3. How Layers Are Created (Dockerfile → Layers)

**Rule:** Each Dockerfile instruction creates one layer.

### Example Dockerfile:
```dockerfile
FROM node:20-alpine          # Layer 1
WORKDIR /app                 # Layer 2
COPY package.json .          # Layer 3
RUN npm install              # Layer 4
COPY . .                     # Layer 5
CMD ["node", "server.js"]    # Layer 6 (metadata)
```

### What happens during build:

| Step | Instruction | What Docker does | Layer created? |
|---:|---|---|---|
| 1 | `FROM node:20-alpine` | Downloads base image layers | Reuses existing layers |
| 2 | `WORKDIR /app` | Creates `/app` directory | ✅ New layer |
| 3 | `COPY package.json .` | Copies one file | ✅ New layer |
| 4 | `RUN npm install` | Installs dependencies | ✅ New layer (heavy) |
| 5 | `COPY . .` | Copies all source code | ✅ New layer |
| 6 | `CMD ["node", "server.js"]` | Sets metadata | ✅ New layer (0B) |

**Result:** 6 instructions = 6 new layers (plus base image layers)

**Mental model:**
```
Dockerfile line  →  Build step  →  New layer  →  Stacked on previous
```

---

## 4. Layer Caching in Action (Build Twice)

**Goal:** See Docker reuse layers when nothing changed.

### Experiment: Build the same image twice

| Step | What you do | Command | What happens |
|---:|---|---|---|
| 5 | Create a simple Dockerfile | See below | File created |
| 6 | Build image (first time) | `docker build -t cache-test:v1 .` | All layers built from scratch |
| 7 | Build image (second time) | `docker build -t cache-test:v1 .` | All layers use cache (instant) |

**Create this Dockerfile:**
```dockerfile
FROM alpine:3.18
RUN apk add --no-cache curl
RUN echo "Layer 3"
RUN echo "Layer 4"
CMD ["sh"]
```

**First build output:**
```bash
docker build -t cache-test:v1 .
```

```
[1/4] FROM alpine:3.18                                    5.2s
[2/4] RUN apk add --no-cache curl                         3.1s
[3/4] RUN echo "Layer 3"                                  0.3s
[4/4] RUN echo "Layer 4"                                  0.2s
```
**Total time: ~9 seconds**

**Second build output:**
```bash
docker build -t cache-test:v1 .
```

```
[1/4] FROM alpine:3.18                                    CACHED
[2/4] RUN apk add --no-cache curl                         CACHED
[3/4] RUN echo "Layer 3"                                  CACHED
[4/4] RUN echo "Layer 4"                                  CACHED
```
**Total time: ~0.1 seconds**

**What happened:**
- Docker computed a hash for each instruction
- Hashes matched previous build
- Docker reused existing layers
- No work needed = instant build

**Mental model:**
```
Same instruction + same context = same hash = reuse layer
```

---

## 5. What Breaks the Cache

**Rule:** Changing a layer invalidates that layer AND all layers after it.

### Experiment: Modify one line, see what rebuilds

| Step | What you do | Command | What happens |
|---:|---|---|---|
| 8 | Modify Layer 3 in Dockerfile | Change `echo "Layer 3"` to `echo "Modified"` | File changed |
| 9 | Rebuild | `docker build -t cache-test:v2 .` | Watch which layers rebuild |

**Modified Dockerfile:**
```dockerfile
FROM alpine:3.18
RUN apk add --no-cache curl
RUN echo "Modified"          # ← Changed this line
RUN echo "Layer 4"
CMD ["sh"]
```

**Build output:**
```
[1/4] FROM alpine:3.18                                    CACHED
[2/4] RUN apk add --no-cache curl                         CACHED
[3/4] RUN echo "Modified"                                 0.3s  ← Rebuilt
[4/4] RUN echo "Layer 4"                                  0.2s  ← Rebuilt
```

**What happened:**
- Layer 1 (FROM) → cached ✅
- Layer 2 (curl install) → cached ✅
- Layer 3 (echo modified) → **rebuilt** ❌
- Layer 4 (echo layer 4) → **rebuilt** ❌ (even though it didn't change!)

**Critical rule:**
```
Change at step N → rebuild N and everything after
```

**Why Layer 4 rebuilt:**
- Each layer depends on the previous layer's filesystem state
- Layer 3 changed
- Layer 4's context is now different (even if its instruction is the same)
- Docker cannot reuse it

---

## 6. Optimization Pattern (Bad → Good Dockerfile)

**Goal:** Order instructions to maximize cache reuse.

### Bad Dockerfile (cache breaks on every code change):

```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY . .                     # ← Copies EVERYTHING (including package.json)
RUN npm install              # ← Reinstalls dependencies every time code changes
CMD ["node", "server.js"]
```

**Problem:**
- Any code change → `COPY . .` layer changes
- This breaks cache for `RUN npm install`
- Dependencies reinstall **every time** (even if package.json didn't change)

### Good Dockerfile (cache preserved for dependencies):

```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package.json .          # ← Copy ONLY dependency manifest first
RUN npm install              # ← Install dependencies (cached until package.json changes)
COPY . .                     # ← Copy source code last
CMD ["node", "server.js"]
```

**Why this is better:**
- Code changes don't affect `COPY package.json .`
- `RUN npm install` stays cached
- Only `COPY . .` rebuilds (fast)

### Side-by-side comparison:

| Scenario | Bad Dockerfile | Good Dockerfile |
|---|---|---|
| Change `server.js` | Reinstalls all dependencies (slow) | Copies new code only (fast) |
| Change `package.json` | Reinstalls dependencies | Reinstalls dependencies |
| No changes | Cached | Cached |

**Benchmark:**
```bash
# Bad pattern: Change one line of code
docker build -t app:bad .
# Time: 45 seconds (npm install runs again)

# Good pattern: Change one line of code
docker build -t app:good .
# Time: 2 seconds (only COPY . . runs)
```

**The optimization principle:**
```
Stable instructions first → Volatile instructions last
```

**Order of stability:**
1. Base image (`FROM`) - almost never changes
2. System packages (`RUN apt-get install`) - rarely changes
3. Dependencies (`COPY package.json` + `RUN npm install`) - changes occasionally
4. Source code (`COPY . .`) - changes frequently

---

## 7. Layer Reuse When Pulling Images

**Context shift:** We've been talking about **building** images. Now we talk about **pulling** images.

**Key difference:**
- Building = creating layers locally
- Pulling = downloading pre-built layers from a registry

**Rule:** When pulling, Docker downloads only missing layers.

### How it works:

| Step | What you do | Command | What happens |
|---:|---|---|---|
| 10 | Pull first image | `docker pull node:20-alpine` | Downloads all layers |
| 11 | Pull related image | `docker pull node:20` | Reuses some layers, downloads only differences |

**Example scenario:**

You already have `node:20-alpine` (200MB).
Now you pull `node:20-bullseye` (900MB).

**What Docker does:**
1. Checks which layers you already have locally
2. Both images share base Debian layers
3. Downloads only the missing layers
4. Actual download: ~700MB (not 900MB)

**Mental model:**
```
Registry holds:     Layer A, Layer B, Layer C, Layer D
You have locally:   Layer A, Layer B
Docker downloads:   Layer C, Layer D only
```

**This is NOT rebuilding:**
- The image is already built (by someone else, on the registry)
- You're just downloading the missing pieces
- Layer reuse is based on exact hash matching

---

## 8. Verify Layer Sharing (Practical Check)

**Goal:** Prove that multiple images share layers.

| Step | What you do | Command | What to observe |
|---:|---|---|---|
| 12 | Check current disk usage | `docker system df` | Note "Images" size |
| 13 | Pull Ubuntu 22.04 | `docker pull ubuntu:22.04` | ~77MB downloaded |
| 14 | Check disk usage again | `docker system df` | Size increased by ~77MB |
| 15 | Pull Ubuntu 24.04 | `docker pull ubuntu:24.04` | ~80MB downloaded |
| 16 | Check disk usage again | `docker system df` | Size increased by ~20MB (not 80MB!) |

**Why the difference:**
- Both Ubuntu images share base layers
- Only the differences are stored
- Docker deduplicates automatically

**View shared layers:**
```bash
docker history ubuntu:22.04 > ubuntu22-layers.txt
docker history ubuntu:24.04 > ubuntu24-layers.txt
diff ubuntu22-layers.txt ubuntu24-layers.txt
```

You'll see some layers have identical hashes → those are shared.

---

## 9. Common Mistakes That Waste Cache

### Mistake 1: Copying everything first

❌ **Bad:**
```dockerfile
COPY . .
RUN npm install
```

✅ **Good:**
```dockerfile
COPY package.json .
RUN npm install
COPY . .
```

### Mistake 2: Installing packages and copying code in one layer

❌ **Bad:**
```dockerfile
RUN apt-get update && apt-get install -y curl && npm install
```

✅ **Good:**
```dockerfile
RUN apt-get update && apt-get install -y curl
COPY package.json .
RUN npm install
```

### Mistake 3: Not using `.dockerignore`

Without `.dockerignore`:
- `COPY . .` includes `node_modules/`, `.git/`, `*.log`
- Layer hash changes even when real source code didn't
- Cache breaks unnecessarily

**Create `.dockerignore`:**
```
node_modules
.git
*.log
.env
dist
build
```

### Mistake 4: Updating packages in every build

❌ **Bad:**
```dockerfile
RUN apt-get update && apt-get install -y curl
```
This might change daily (package versions update).

✅ **Better:**
```dockerfile
RUN apt-get update && apt-get install -y curl=7.68.0-1
```
Pin versions when stability matters.

### Mistake 5: Combining unrelated operations

❌ **Bad:**
```dockerfile
RUN apt-get update && apt-get install -y curl && npm install && apt-get install -y git
```

✅ **Good:**
```dockerfile
RUN apt-get update && apt-get install -y curl git
COPY package.json .
RUN npm install
```

---

## 10. The Container Runtime Layer

**Critical concept:** When you run a container, Docker adds ONE writable layer on top.

![](./readme-assets/container-filesystem.jpg)

**The top layer in the diagram** = Container Layer (temporary)

### What this means:

| Layer type | Read/Write | Lifetime | Purpose |
|---|---|---|---|
| Image layers (all below) | Read-only | Permanent | Shared across containers |
| Container layer (top) | Writable | Until container deleted | Container-specific changes |

### Experiment: Write data in a container

| Step | What you do | Command | What happens |
|---:|---|---|---|
| 17 | Run container | `docker run -it --name test alpine:3.18` | Container starts |
| 18 | Create file | `echo "test" > /tmp/file.txt` | File written to container layer |
| 19 | Exit | `exit` | Container stops |
| 20 | Start same container | `docker start -i test` | File still exists |
| 21 | Delete container | `docker rm test` | Container layer deleted |
| 22 | Run new container | `docker run -it alpine:3.18` | File is gone (fresh container layer) |

**Mental model:**
```
Image layers (read-only)  →  Shared by all containers
     +
Container layer (writable)  →  Unique per container, deleted with container
```

**Why this matters:**
- Changes in containers don't affect the image
- Multiple containers from same image don't interfere
- This is why you need volumes for persistent data

---

## Final Compression (Memorize)

### What layers are:
- Image = stack of read-only layers
- Each Dockerfile instruction = one layer
- Layers stack bottom (base) → top (your code)

### How caching works:
- Docker hashes each instruction + context
- Same hash = reuse layer
- Different hash = rebuild that layer + all after it

### Optimization rule:
```
Stable first → Volatile last

1. FROM (base image)
2. RUN (system packages)
3. COPY (dependency manifest)
4. RUN (install dependencies)
5. COPY (source code)
6. CMD (startup command)
```

### Build vs Pull:
- **Build** = create layers locally, cache reused within builds
- **Pull** = download pre-built layers, reuse based on hash matching

### Container runtime:
- Image layers = read-only, shared
- Container adds one writable layer = temporary, deleted with container

### Commands to remember:
```bash
docker history IMAGE              # See all layers
docker build -t name .            # Build uses cache
docker system df                  # Check layer disk usage
```

### Critical insight:
```
Layer at position N changes
  ↓
Everything at position N+1, N+2... rebuilds
  ↓
Order matters for speed
```

**One-line truth:**
Docker images are stacks of cached, read-only layers; changing one layer invalidates everything after it, so put stable stuff first and volatile stuff last.

---

## What Breaks

| Symptom | Cause | First command to run |
|---|---|---|
| Every build is slow — nothing is cached | `COPY . .` is too early — source code changes bust the cache for everything after it | Move `COPY . .` after dependency install steps |
| `npm install` runs on every build even when dependencies didn't change | `package.json` is copied with `COPY . .` instead of separately before `RUN npm install` | Copy `package.json` first, run install, then `COPY . .` |
| Image is unexpectedly large | Build tools, test files, or `.git` folder copied into the image | Add a `.dockerignore` file excluding `node_modules`, `.git`, `*.log` |
| `docker build` fails with `COPY failed: file not found` | File path in `COPY` is wrong relative to the build context | Run `docker build` from the directory that contains the files being copied |
| Multi-stage build final image is missing files | Files were created in the builder stage but not copied to the runtime stage with `COPY --from=builder` | Check every file the runtime needs has an explicit `COPY --from=builder` line |

---

## Daily Commands

| Command | What it does |
|---|---|
| `docker build -t NAME:TAG .` | Build an image from the Dockerfile in the current directory |
| `docker build --no-cache -t NAME:TAG .` | Force rebuild all layers — bypass cache entirely |
| `docker history IMAGE` | Show all layers, their sizes, and which instruction created them |
| `docker images` | List all images and their sizes |
| `docker system df` | Show total disk usage by images, containers, and volumes |
| `docker image inspect IMAGE` | Full image metadata including layer digests |
| `docker rmi IMAGE` | Delete an image — remove containers using it first |

---
→ **Interview questions for this topic:** [99-interview-prep → Layers · Caching · Image Optimization](../99-interview-prep/README.md#layers--caching--image-optimization)

→ Ready to practice? [Go to Lab 03](../docker-labs/03-build-layers-lab.md)

---
# SOURCE: 04. Docker – Containerization/08-docker-build-dockerfile/README.md
---

[Home](../README.md) |
[History & Motivation](../01-history-and-motivation/README.md) |
[Technology Overview](../02-technology-overview/README.md) |
[Docker Containers](../03-docker-containers/README.md) |
[Port Binding](../04-docker-port-binding/README.md) |
[Networking](../05-docker-networking/README.md) |
[Volumes](../06-docker-volumes/README.md) |
[Layers](../07-docker-layers/README.md) |
[Build](../08-docker-build-dockerfile/README.md) |
[Registry](../09-docker-registry/README.md) |
[Compose](../10-docker-compose/README.md) |
[Interview Prep](../99-interview-prep/README.md)

# Docker Build (Dockerfile)

## 0) Absolute Zero (Before Docker Exists)

You have:

* a laptop
* a folder with your app code (files)

That's it.

No Linux knowledge required.
No Node knowledge required.
No Docker knowledge required.

---

## 1) The Problem (Before Docker)

Your app needs two things to run:

1. The app files (your code)
2. A way to run them (a runtime like Node, Python, Java)

Right now, both exist only on your laptop.

You want one package that contains everything needed to run the app so it runs anywhere.

That package is a Docker image.

---

## 2) Docker Cannot Guess Anything

Docker does not know:

* what language your app uses
* how to start it
* where files should live

So you must explain step by step.

That explanation is written in a text file called a **Dockerfile**.

At this point:

* nothing runs
* nothing is built

---

## 3) Two Timelines (Core Mental Model)

### Build-time (when you run `docker build`)

Build-time instructions create an **image filesystem** (layers). They permanently change what exists inside the image.

Common build-time instructions:

* `FROM`
* `WORKDIR`
* `RUN`
* `COPY` (and `ADD`, rarely)
* `ENV` (sets defaults in the image)

### Run-time (when you run `docker run`)

Run-time is when Docker creates a **container** from the image and starts the default process defined by the image.

Run-time is driven by:

* `CMD` / `ENTRYPOINT` (image metadata that defines what starts)
* runtime environment variables (`docker run -e ...` overrides image `ENV`)

**Rule**

* If it must exist before the app starts → build-time
* If it happens when the app starts → run-time

Do not mix these mentally.

---

## 4) First Question Docker Asks → `FROM`

Docker cannot start from nothing.

So the first line must answer:

> "What should I start from?"

```dockerfile
FROM node:20
```

Plain English:

* "Start from a ready-made environment that already knows how to run Node apps."

Facts:

* You are not installing Node manually here
* You are selecting a prepared filesystem
* `FROM` must be first (non-negotiable)

---

## 5) `WORKDIR` — Set the Default Folder (Recommended)

```dockerfile
WORKDIR /app
```

Plain English:

* "Inside the image, treat `/app` as the current folder."

Facts:

* `WORKDIR` creates the folder if missing
* it replaces `cd` (which does not persist across layers)
* it prevents path confusion

---

## 6) `ENV` — Store Defaults (Not Secrets)

```dockerfile
ENV NODE_ENV=production \
    PORT=8080
```

Plain English:

* "Store key=value defaults inside the image."

Facts:

* `ENV` does not run anything
* values are available at runtime (e.g., `process.env`)
* runtime env vars override image env vars
* do not store secrets in images

---

## 7) `RUN` — Build-Time Setup

`RUN` executes while building the image and saves the result into the next layer.

The command you use depends on the **base image**:

* Alpine images → `apk`
* Debian/Ubuntu images → `apt-get`

Example (Alpine base):

```dockerfile
FROM node:20-alpine
RUN apk add --no-cache curl
```

Example (Debian base):

```dockerfile
FROM node:20
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*
```

Facts:

* `RUN` executes at build-time
* each `RUN` creates a layer
* use it for OS packages, dependency installs, downloads, and setup

Rule:

* Readability > micro-optimization
* combine `RUN` steps mainly when cleanup matters

---

## 8) `COPY` — Put Your App Into the Image (Normal Path)

```dockerfile
COPY . .
```

Chronological meaning:

* first `.` → your project folder on laptop (build context)
* second `.` → current folder inside image (`/app` because of `WORKDIR`)

Plain English:

* "Copy my app files into the image."

Facts:

* In normal builds, `COPY` is how your local code enters the image
* Docker can only copy files inside the build context
* use a `.dockerignore` to avoid copying junk (`node_modules`, `.git`, build outputs)

---

## 9) `.dockerignore` — Control What Gets Copied

When Docker runs `COPY . .`, it copies everything in the build context by default.
That includes junk that slows builds and breaks layer caching.

`.dockerignore` is a file in the same folder as your Dockerfile.
It tells Docker what to exclude from the build context.

**Create `.dockerignore` in your project root:**

```
node_modules
.git
*.log
.env
dist
build
```

**Why each line matters:**

| Entry | Why exclude it |
|---|---|
| `node_modules` | Already installed by `RUN npm install` inside the image — copying from host wastes space and breaks the install layer |
| `.git` | Version control history has no place in a runtime image |
| `*.log` | Log files change constantly — they break layer caching on every build |
| `.env` | Contains secrets — never bake secrets into an image |
| `dist` / `build` | Compiled output — the image should build this itself |

**Without `.dockerignore` — what goes wrong:**

```
COPY . .     ← copies node_modules (300MB), .git, .env, logs
               layer hash changes every build even if code didn't
               cache breaks → npm install runs again every time
```

**With `.dockerignore` — what happens:**

```
COPY . .     ← copies only your source code
               layer hash stable until code actually changes
               cache works → fast builds
```

**One-line rule:**
`.dockerignore` exists so `COPY . .` only copies what the image actually needs.

---

## 10) `EXPOSE` — Documentation Only

```dockerfile
EXPOSE 8080
```

Facts:

* `EXPOSE` does not open ports
* `EXPOSE` does not publish ports
* it is metadata only

Real access happens with port binding (covered in Port Binding notes):

```bash
docker run -p 8080:8080 webstore-api:1.0
```

---

## 11) `CMD` — Default Startup Command (Run-Time)

```dockerfile
CMD ["node", "server.js"]
```

Plain English:

* "When a container starts, run this command."

Facts:

* `CMD` does nothing during build
* it runs only when a container starts
* it can be overridden at runtime

---

## 12) Build the Image (Nothing Runs Yet)

```bash
docker build -t webstore-api:1.0 .
```

Meaning:

* `-t` → tag (name) the image
* `webstore-api` → image name
* `1.0` → version tag
* `.` → build context (files Docker is allowed to `COPY`)

After this:

* image exists
* app is not running

---

## 13) Verify Image

```bash
docker images
```

---

## 14) Run the Image (First Time Anything Runs)

```bash
docker run -p 8080:8080 webstore-api:1.0
```

Now:

* Docker creates a container
* executes `CMD`
* the app runs

---

## 15) Canonical Dockerfile Shape (Reference)

```dockerfile
FROM <base-image>

WORKDIR /app

RUN <install OS deps>

COPY <dependency manifests> ./
RUN <install app deps>

COPY . .

EXPOSE <app-port>   # metadata only

CMD ["<start-command>"]
```

---

## 16) Multi-Stage Builds — Production Images

A single-stage build puts everything into one image — build tools, compiler, test dependencies, and the runtime. This produces large images that contain code that should never run in production.

Multi-stage builds solve this. You define multiple `FROM` stages in one Dockerfile. The final stage copies only what it needs from earlier stages. Build tools never make it into the production image.

**Why this matters for the webstore-api:**

```
Single-stage build:
  Base image (node:20)           ~900MB
  + npm install (all deps)       ~200MB
  + source code                  ~5MB
  Total image size: ~1.1GB

Multi-stage build:
  Builder stage:  node:20 + all deps + source code (discarded)
  Runtime stage:  node:20-alpine + production deps + compiled output only
  Total image size: ~150MB
```

The runtime image is smaller, faster to pull, has fewer installed packages meaning fewer attack vectors, and contains nothing a developer would not want running in production.

**Multi-stage Dockerfile for webstore-api:**

```dockerfile
# Stage 1 — Builder
# This stage installs all dependencies and builds the app
FROM node:20-alpine AS builder

WORKDIR /app

# Copy dependency manifest first (cache this layer)
COPY package.json package-lock.json ./

# Install ALL dependencies including dev deps needed for build
RUN npm ci

# Copy source code and build
COPY . .
RUN npm run build

# Stage 2 — Production runtime
# This stage produces the final image — only what runs in production
FROM node:20-alpine AS production

WORKDIR /app

# Copy only production dependency manifest
COPY package.json package-lock.json ./

# Install only production dependencies
RUN npm ci --only=production

# Copy built output from builder stage — not the source code
COPY --from=builder /app/dist ./dist

EXPOSE 8080

CMD ["node", "dist/server.js"]
```

**Key lines explained:**

```
FROM node:20-alpine AS builder
↑ Each FROM starts a new stage. AS builder names it.

COPY --from=builder /app/dist ./dist
↑ This is the multi-stage copy — pulling built output from the builder stage.
  Only the compiled files come through. No node_modules from dev deps.
  No source TypeScript. No test files.

FROM node:20-alpine AS production
↑ This is the final stage. When you docker build, this is what you get.
  Everything from builder exists only during the build — it is discarded.
```

**Build and verify size reduction:**

```bash
# Build the multi-stage image
docker build -t webstore-api:1.0 .

# Check the image size
docker images webstore-api

# Confirm build tools are not in the final image
docker run --rm webstore-api:1.0 which tsc
# Should print nothing — TypeScript compiler not present
```

**The rule:** if your app has a build step — TypeScript compilation, webpack bundling, Go compilation — use multi-stage builds. The builder stage does the work. The runtime stage runs the result.

---

## 17) The Ordering Law (Memorize This)

> **Stable first. Volatile last.**

Order:

1. Base OS
2. System dependencies
3. App dependencies
4. App source code
5. Runtime command

Reason:

* Docker caches layers top → bottom
* changing a layer invalidates everything after it

---

## 18) Instruction Laws (Quick Reference)

* `FROM` → starting filesystem + tools
* `WORKDIR` → default folder (creates it)
* `RUN` → build-time execution (creates a layer)
* `COPY` → bring local files from build context
* `ENV` → static defaults (not secrets)
* `EXPOSE` → metadata only
* `CMD` → default runtime command

**File sourcing rules:**
* Local files → `COPY`
* Internet files → `RUN curl` / `RUN wget`
* Secrets / dynamic data → runtime, not image

**OS rule:**
Inside Docker = Linux.
Language tools are portable.
OS package managers are Linux-specific.

---

## 19) One-Line Truth

> A Dockerfile is a cached, ordered, Linux build recipe that separates build-time from run-time to create reproducible images.

---

## What Breaks

| Symptom | Cause | First command to run |
|---|---|---|
| `failed to solve: failed to read dockerfile` | Dockerfile is not named `Dockerfile` or is in the wrong directory | `ls -la` in the directory where you ran `docker build` |
| `COPY failed: file not found in build context` | File path in `COPY` doesn't exist relative to the build context | Check the path is correct and the file exists — `ls` in the project root |
| Container starts but app crashes immediately | `CMD` is wrong — wrong file name, wrong path, or wrong syntax | `docker logs CONTAINER_NAME` to see the exact error |
| Build works but `node_modules` is missing inside container | `COPY . .` ran before `RUN npm install` — copies over the installed modules | Put `RUN npm install` before `COPY . .` |
| Image builds but secrets are baked in | `.env` file was not excluded — `COPY . .` pulled it into the image | Add `.env` to `.dockerignore` — rebuild the image |

---

## Daily Commands

| Command | What it does |
|---|---|
| `docker build -t NAME:TAG .` | Build an image — `.` sets the build context to current directory |
| `docker build --no-cache -t NAME:TAG .` | Build with no cache — forces every layer to rebuild |
| `docker build -f PATH/Dockerfile -t NAME:TAG .` | Build using a Dockerfile at a non-default location |
| `docker run -p HOST:CONTAINER NAME:TAG` | Run the built image as a container with port binding |
| `docker history NAME:TAG` | Inspect all layers the Dockerfile produced |
| `docker image inspect NAME:TAG` | Full metadata — entrypoint, CMD, env vars, layers |
| `docker run --rm NAME:TAG COMMAND` | Run a one-off command in the image and auto-delete the container |

---

→ **Interview questions for this topic:** [99-interview-prep → Dockerfile · Build-time vs Run-time · Multi-stage](../99-interview-prep/README.md#dockerfile--build-time-vs-run-time--multi-stage)

→ Ready to practice? [Go to Lab 03](../docker-labs/03-build-layers-lab.md)

---
# SOURCE: 04. Docker – Containerization/09-docker-registry/README.md
---

[Home](../README.md) |
[History & Motivation](../01-history-and-motivation/README.md) |
[Technology Overview](../02-technology-overview/README.md) |
[Docker Containers](../03-docker-containers/README.md) |
[Port Binding](../04-docker-port-binding/README.md) |
[Networking](../05-docker-networking/README.md) |
[Volumes](../06-docker-volumes/README.md) |
[Layers](../07-docker-layers/README.md) |
[Build](../08-docker-build-dockerfile/README.md) |
[Registry](../09-docker-registry/README.md) |
[Compose](../10-docker-compose/README.md) |
[Interview Prep](../99-interview-prep/README.md)

# Container Registries

## 1) What a Container Registry Is

A container registry is a **remote storage system for Docker images**.

It stores images so they can be:
- pushed by developers
- pulled by CI systems
- pulled by production servers

It does **not** run containers.

---

## 2) Why Registries Exist

Without a registry:
- images live only on your laptop
- CI cannot access them
- production cannot pull them

With a registry:
- one image
- reused everywhere
- no rebuild drift

---

## 3) Visual Mental Model (Registry as the Hub)

![](./readme-assets/container-registry.jpg)

What this image shows:

**Developer systems**
- Push → very common (after build)
- Pull → very common (base images, debugging)

**CI servers**
- Pull → always (to test, scan, deploy)
- Push → often (build pipelines, versioned images)

**Production servers**
- Pull → yes (to run images)
- Push → almost never (anti-pattern)

Key idea:
The registry is **passive storage**.
Everything else initiates communication.

**The Only Flow That Matters**
```
Developer ↔ Registry ↔ CI → Production
```
Same image. Different environments.

---

## 4) Common Container Registries (Awareness Only)

Examples you will see in real systems:
- Docker Hub
- GitHub Container Registry (ghcr.io)
- GitLab Container Registry
- Google Container Registry (gcr.io)
- Amazon Elastic Container Registry (ECR)
- Azure Container Registry (ACR)
- JFrog Artifactory
- Nexus
- Harbor

You do not need to learn each one now.
They all solve the same problem.

---

## 5) Public vs Private Images

Public images:
- anyone can pull
- no authentication required

Private images:
- authentication required
- commonly used in CI and production

This explains why login exists.

---

## 6) Authentication

To push or pull private images:
```bash
docker login
```

What happens:

* credentials are sent to the registry
* Docker stores them securely
* future pulls/pushes work automatically

Where credentials live:

* macOS Keychain
* Windows Credential Manager
* Linux credential helpers

---

## 7) Authentication Visual

![](./readme-assets/credential-helper.jpg)

What this image shows:

* Docker CLI requesting credentials
* OS credential store handling secrets
* Registry validating access

You do not manage tokens manually at this stage.

---

## 8) Tagging Strategy — How Real Teams Version Images

Tags are not just labels. They are the mechanism CI/CD pipelines use to decide what to deploy. A poorly thought-out tagging strategy causes deployments to pull stale images, makes rollbacks difficult, and makes production incidents harder to debug.

**The `latest` trap:**

`latest` is the default tag when no tag is specified. It sounds useful but causes serious problems in real pipelines:

```bash
# This is what latest actually means:
docker push myrepo/webstore-api:latest
# "latest" = whatever was pushed most recently
# NOT "the most stable version"
# NOT "the version that passed QA"
# NOT reproducible — tomorrow it may be a different image

# Three weeks later on production:
docker pull myrepo/webstore-api:latest
# What did you just pull? Impossible to know without checking the registry.
# If it breaks, what do you roll back to?
```

**The rule:** never deploy `latest` to production. Always deploy a specific, immutable tag.

**Semantic versioning tags — the standard for releases:**

```
v1.0.0    ← major.minor.patch
v1.1.0    ← new feature, backward compatible
v1.1.1    ← bug fix
v2.0.0    ← breaking change
```

```bash
# Tag and push a release
docker build -t webstore-api:v1.0.0 .
docker tag webstore-api:v1.0.0 akhiltejadoosari/webstore-api:v1.0.0
docker push akhiltejadoosari/webstore-api:v1.0.0
```

**Git SHA tags — the standard for CI/CD:**

Every commit produces an image. Tag it with the Git commit SHA so you can trace any deployed image back to the exact commit that built it.

```bash
# In a CI pipeline:
GIT_SHA=$(git rev-parse --short HEAD)
docker build -t webstore-api:${GIT_SHA} .
docker push akhiltejadoosari/webstore-api:${GIT_SHA}

# Example output:
# akhiltejadoosari/webstore-api:a3f92c1
```

When production has a bug, you check the deployed tag (`a3f92c1`), run `git show a3f92c1`, and see exactly what changed.

**Environment tags — for promotion workflows:**

Some teams tag images with the environment they are deployed to:

```bash
# Tag the same image for staging
docker tag webstore-api:v1.0.0 akhiltejadoosari/webstore-api:staging

# Promote to production after QA passes
docker tag webstore-api:v1.0.0 akhiltejadoosari/webstore-api:production
```

The underlying image is identical — only the tag changes. This makes rollback trivial: retag the previous version as `production` and redeploy.

**Tagging decision table:**

| Context | Tag to use | Example |
|---|---|---|
| Every CI build | Git SHA | `webstore-api:a3f92c1` |
| Versioned releases | Semantic version | `webstore-api:v1.0.0` |
| Current stable dev | `latest` | Only for local development |
| Production deploy | Specific SHA or semver | Never `latest` |
| Environment tracking | Environment name | `webstore-api:staging` |

**One-line rule:**
In production, every image tag must be immutable and traceable — either a Git SHA or a semantic version. `latest` is for local development only.

---

## 9) Publish webstore-api to Docker Hub (End-to-End Process)

Goal:
- Take the local image you built in section 08 (`webstore-api:1.0`)
- Publish it to Docker Hub so other machines and CI can pull it

This section includes:
- Docker Hub UI steps (create repository)
- Terminal steps (build, login, tag, push, verify)

---

### Step 0: Prerequisites (Docker Hub)

1) Sign in to Docker Hub (website).
2) Create a repository:
   - Name: `webstore-api`
   - Visibility: Public or Private (your choice)
3) After creation, your image target will look like:
   - `DOCKERHUB_USERNAME/webstore-api`

You can add your own screenshots here (recommended).

---

### Step 1: Ensure the Image Exists Locally

Check local images:

```bash
docker images
```

Look for:

* `webstore-api` under `REPOSITORY`
* a tag like `1.0`

If you do NOT see it, build it now (run this from the folder that contains your Dockerfile):

```bash
docker build -t webstore-api:1.0 .
```

Re-check:

```bash
docker images | head
```

---

### Step 2: Confirm Which Docker Account the Terminal Is Using

Docker can stay logged in from old sessions. Confirm current auth state:

```bash
docker info | grep -i username
```

If it prints a username, Docker is logged in.

---

### Step 3: Reset Login (Only When Needed)

Use this if:

* you see the wrong username
* push fails with permission errors
* you previously logged into a different account

Logout first:

```bash
docker logout
```

Now login again:

```bash
docker login
```

It will prompt for Docker Hub username and password (or token if you use one).

Verify again:

```bash
docker info | grep -i username
```

---

### Step 4: Tag the Image for Docker Hub

Docker Hub requires images to be tagged as:

```
DOCKERHUB_USERNAME/REPO_NAME:TAG
```

Tag your local image:

```bash
docker tag webstore-api:1.0 DOCKERHUB_USERNAME/webstore-api:1.0
```

Confirm the tag exists:

```bash
docker images | grep webstore-api
```

You should see both:

* `webstore-api:1.0`
* `DOCKERHUB_USERNAME/webstore-api:1.0`

---

### Step 5: Push the Image

Push to Docker Hub:

```bash
docker push DOCKERHUB_USERNAME/webstore-api:1.0
```

What happens:

* Docker checks which layers already exist in Docker Hub
* Only missing layers are uploaded
* Existing layers are reused

---

### Step 6: Verify Push Worked (Two Ways)

Terminal verification:

```bash
docker pull DOCKERHUB_USERNAME/webstore-api:1.0
```

Docker Hub verification:

* Open your repository page on Docker Hub
* Confirm the `1.0` tag exists

---

### Common Failure Modes (Fast Fix)

1. `denied: requested access to the resource is denied`
   - Cause: wrong Docker Hub username, not logged in, or repo not owned by you
   - Fix:
     ```bash
     docker logout
     docker login
     ```

2. `tag does not exist`
   - Cause: you tagged the wrong local image name or it was never built
   - Fix:
     ```bash
     docker build -t webstore-api:1.0 .
     docker tag webstore-api:1.0 DOCKERHUB_USERNAME/webstore-api:1.0
     ```

3. `unauthorized: authentication required`
   - Cause: not logged in or stale credentials
   - Fix:
     ```bash
     docker logout
     docker login
     ```

---

### Final Checkpoint

If you can do this from zero:

* build `webstore-api:1.0`
* create Docker Hub repo
* login correctly
* tag to `DOCKERHUB_USERNAME/webstore-api:1.0`
* push successfully

Then you understand container registries at the correct practical level.

**One-Line Definition**

> A container registry is a remote store for container images so the same image can be shared across development, CI, and production.

---

## What Breaks

| Symptom | Cause | First command to run |
|---|---|---|
| `denied: requested access to the resource is denied` | Wrong Docker Hub username in the tag, or not logged in | `docker logout` then `docker login` — retag with the correct username |
| `unauthorized: authentication required` | Credentials expired or never set | `docker login` — re-authenticate |
| Push succeeds but Kubernetes can't pull the image | Image is in a private registry but no pull secret is configured in the cluster | Confirm the repo visibility on Docker Hub — set to public for now |
| `tag does not exist` when pulling | Tag was never pushed, or you used the wrong tag name | `docker images` to see what tags exist locally — check Docker Hub UI for what was pushed |
| Layers upload on every push — nothing is reused | Base image tag changed (e.g., `node:20` resolved to a new digest) | Pin the base image with a specific digest or use a fixed tag like `node:20.11.0-alpine` |

---

## Daily Commands

| Command | What it does |
|---|---|
| `docker login` | Authenticate to Docker Hub — credentials stored by OS |
| `docker logout` | Remove stored credentials |
| `docker tag SOURCE TARGET` | Create a new tag pointing to the same image |
| `docker push USERNAME/IMAGE:TAG` | Upload image to registry |
| `docker pull USERNAME/IMAGE:TAG` | Download image from registry |
| `docker images` | List all local images and tags |
| `docker rmi IMAGE:TAG` | Delete a local image tag — does not affect the registry |

---

→ **Interview questions for this topic:** [99-interview-prep → Registry · Tagging · Push and Pull](../99-interview-prep/README.md#registry--tagging--push-and-pull)

→ Ready to practice? [Go to Lab 04](../docker-labs/04-registry-compose-lab.md)

---
# SOURCE: 04. Docker – Containerization/10-docker-compose/README.md
---

[Home](../README.md) |
[History & Motivation](../01-history-and-motivation/README.md) |
[Technology Overview](../02-technology-overview/README.md) |
[Docker Containers](../03-docker-containers/README.md) |
[Port Binding](../04-docker-port-binding/README.md) |
[Networking](../05-docker-networking/README.md) |
[Volumes](../06-docker-volumes/README.md) |
[Layers](../07-docker-layers/README.md) |
[Build](../08-docker-build-dockerfile/README.md) |
[Registry](../09-docker-registry/README.md) |
[Compose](../10-docker-compose/README.md) |
[Interview Prep](../99-interview-prep/README.md)

# Docker Compose — Same System, Automated

## 1) Mental Model First (What You Are About to Read)

Docker Compose replaces many manual `docker run` commands with **one file**.

Below is the **entire webstore system** in one view.

Do not analyze it yet.
Just observe the shape.

```yaml
version: "3.9"

services:
  webstore-db:
    image: postgres:15
    environment:
      POSTGRES_DB: webstore
      POSTGRES_USER: admin
      POSTGRES_PASSWORD: secret
    volumes:
      - webstore-db-data:/var/lib/postgresql/data

  adminer:
    image: adminer
    ports:
      - "8081:8080"
    depends_on:
      - webstore-db

  webstore-api:
    build: .
    ports:
      - "8080:8080"
    environment:
      DB_HOST: webstore-db
      DB_PORT: 5432
      DB_NAME: webstore
      DB_USER: admin
      DB_PASSWORD: secret
    depends_on:
      - webstore-db

volumes:
  webstore-db-data:
```

What this shows at a glance:

* Three containers
* One private Docker network (created automatically)
* Two ports exposed for human access (8080 for API, 8081 for DB UI)
* One database accessed internally by hostname
* One named volume for database persistence

Everything below explains **this file**, line by line.

---

## 2) What Docker Compose Is

Docker Compose runs a multi-container system using **one declarative file** instead of many imperative commands.

Compose does not add new concepts.
It automates:

* container creation
* Docker networking
* DNS (service names)
* port binding
* startup order
* volume creation

---

## 3) Services Block (System Definition)

```yaml
services:
```

Meaning:

* Start of all containers in this system
* Each service becomes:
  * one container
  * one DNS hostname
  * one isolated process

---

## 4) webstore-db Service (Database Server)

```yaml
  webstore-db:
```

Meaning:

* Service name
* Also becomes hostname `webstore-db`
* Used by other containers to connect

```yaml
    image: postgres:15
```

Meaning:

* Use PostgreSQL version 15 — pinned, not `latest`
* Pulled automatically if missing

```yaml
    environment:
      POSTGRES_DB: webstore
      POSTGRES_USER: admin
      POSTGRES_PASSWORD: secret
```

Meaning:

* Environment variables passed into the container
* PostgreSQL uses them on first startup to create the database and admin user

```yaml
    volumes:
      - webstore-db-data:/var/lib/postgresql/data
```

Meaning:

* Mount the named volume to PostgreSQL's data directory
* Data survives `docker compose down` — it is not deleted unless you explicitly remove the volume

Important:

* No `ports` section
* Database is internal-only
* Not reachable from your browser or the internet

---

## 5) adminer Service (Database UI)

```yaml
  adminer:
```

Meaning:

* Lightweight database management UI
* Supports PostgreSQL, MySQL, SQLite
* No configuration needed — connects using the form in the browser

```yaml
    image: adminer
```

Meaning:

* Uses the official adminer image

```yaml
    ports:
      - "8081:8080"
```

Meaning:

* adminer listens on port 8080 inside the container
* Host port `8081` forwards to container port `8080`
* Open `http://localhost:8081` in your browser to access the UI

```yaml
    depends_on:
      - webstore-db
```

Meaning:

* webstore-db container starts before adminer
* Controls start order only — does not guarantee the database is ready to accept connections

**How to use adminer:**
1. Open `http://localhost:8081`
2. System: PostgreSQL
3. Server: `webstore-db` (Docker DNS resolves this)
4. Username: `admin`
5. Password: `secret`
6. Database: `webstore`

---

## 6) webstore-api Service (Application)

```yaml
  webstore-api:
```

Meaning:

* Application container
* Hostname becomes `webstore-api`

```yaml
    build: .
```

Meaning:

* Builds image from Dockerfile in current directory
* Equivalent to `docker build .`

```yaml
    ports:
      - "8080:8080"
```

Meaning:

* Host port `8080` forwards to app port `8080`
* Required for browser access to the API

```yaml
    environment:
      DB_HOST: webstore-db
      DB_PORT: 5432
      DB_NAME: webstore
      DB_USER: admin
      DB_PASSWORD: secret
```

Meaning:

* Database connection details for the app
* Uses service name `webstore-db` — same rule as manual Docker networking
* Containers talk by name, never by IP

```yaml
    depends_on:
      - webstore-db
```

Meaning:

* Starts webstore-db before the app
* Prevents obvious startup failures
* Not a health check — the app may still need retry logic for DB connections

---

## 7) Volumes Block

```yaml
volumes:
  webstore-db-data:
```

Meaning:

* Declares the named volume at the top level
* Docker creates it if it does not exist
* Survives `docker compose down`
* Only deleted with `docker compose down -v` or `docker volume rm`

---

## 8) What Compose Creates Automatically

When you run:

```bash
docker compose up
```

Compose automatically creates:

* one bridge network named `<project>_default`
* DNS entries for each service
* containers attached to that network
* named volumes declared in the `volumes` block

You do not need to define networks explicitly for this setup.

---

## 9) Running the System

Start everything:

```bash
docker compose up
```

Start in background:

```bash
docker compose up -d
```

Stop and clean up containers and network (volumes survive):

```bash
docker compose down
```

Stop and delete everything including volumes:

```bash
docker compose down -v
```

**Warning:** `docker compose down -v` deletes the database volume. All data is gone. Use only when you want a completely clean reset.

---

## 10) About the `-f` Flag

Default behavior:

* Compose reads `docker-compose.yml`
* Also accepts `compose.yml`

`-f` selects a specific file:

```bash
docker compose -f docker-compose.prod.yml up
docker compose -f docker-compose.prod.yml down
```

Rule:
If the file is named `docker-compose.yml` and you are in that folder, do not use `-f`.

---

## 11) Manual vs Compose

![](./readme-assets/docker-run-compose.jpeg)

Use manual Docker commands when:

* learning Docker
* debugging a single container
* understanding flags

Use Docker Compose when:

* running multi-container systems
* daily development
* you want reproducible setup

**Data flows (same as manual, just automated):**

App path:
```
Browser → localhost:8080 → webstore-api → webstore-db:5432 → webstore-db
```

Debug path:
```
Browser → localhost:8081 → adminer → webstore-db:5432 → webstore-db
```

One-line truth:
> webstore-api connects to webstore-db using hostname `webstore-db` on a Docker network.
Compose only automates the same configuration you already know.

---

## What Breaks

| Symptom | Cause | First command to run |
|---|---|---|
| `Bind for 0.0.0.0:8080 failed: port is already allocated` | Another container or process already owns that host port | `docker ps` to find it — `docker stop NAME` then retry |
| Service exits immediately after `docker compose up` | App crashed on startup — often a missing env var or wrong CMD | `docker compose logs SERVICE_NAME` to see the exit reason |
| `webstore-api` cannot connect to `webstore-db` | `DB_HOST` is set to `localhost` instead of the service name | Check `environment` block — must be `DB_HOST: webstore-db` not `localhost` |
| `docker compose down -v` deleted all database data | `-v` flag removes volumes — used when you wanted to keep data | Never use `-v` unless you explicitly want to wipe the database |
| Changes to `docker-compose.yml` not taking effect | Old containers still running with old config | `docker compose down` first, then `docker compose up -d` |

---

## Daily Commands

| Command | What it does |
|---|---|
| `docker compose up -d` | Start all services in the background |
| `docker compose down` | Stop and remove containers and network — volumes survive |
| `docker compose down -v` | Stop and remove everything including volumes — data is gone |
| `docker compose logs SERVICE` | View logs for a specific service |
| `docker compose logs -f SERVICE` | Follow live logs for a specific service |
| `docker compose ps` | List all containers managed by this Compose file |
| `docker compose exec SERVICE COMMAND` | Run a command inside a running service container |
| `docker compose build` | Rebuild images for services that use `build:` |

---

→ **Interview questions for this topic:** [99-interview-prep → Compose · depends_on · Networks and Volumes](../99-interview-prep/README.md#compose--dependson--networks-and-volumes)

→ Ready to practice? [Go to Lab 04](../docker-labs/04-registry-compose-lab.md)

---
# SOURCE: 04. Docker – Containerization/99-interview-prep/README.md
---

[Home](../README.md) |
[History & Motivation](../01-history-and-motivation/README.md) |
[Technology Overview](../02-technology-overview/README.md) |
[Docker Containers](../03-docker-containers/README.md) |
[Port Binding](../04-docker-port-binding/README.md) |
[Networking](../05-docker-networking/README.md) |
[Volumes](../06-docker-volumes/README.md) |
[Layers](../07-docker-layers/README.md) |
[Build](../08-docker-build-dockerfile/README.md) |
[Registry](../09-docker-registry/README.md) |
[Compose](../10-docker-compose/README.md)

---

# Docker — Interview Prep

Answers are 30 seconds. No padding. Every question here actually comes up.

---

## Image vs Container · Containers vs VMs

**What is the difference between an image and a container?**

An image is a read-only package — app code, runtime, dependencies, config — built from a Dockerfile. A container is a running instance of that image. One image can run as many containers as you need. The image never changes when a container runs. Containers are disposable — delete one and start another from the same image.

**What is the difference between a container and a VM?**

A VM runs a full guest OS on top of a hypervisor — heavy, slow to start, gigabytes of overhead per instance. A container shares the host OS kernel and uses namespaces and cgroups to isolate processes — starts in milliseconds, uses megabytes, dozens per host. VMs virtualize hardware. Containers isolate processes. Both exist in production — Kubernetes nodes are VMs, containers run inside them.

**Why use Docker at all?**

The environment problem. Code works on your machine because your machine is set up correctly. Docker packages the app and its environment together. That package runs identically on any machine with Docker installed. No more "works on my machine."

---

## Namespaces · cgroups · How Docker Uses the Linux Kernel

**How does Docker actually create a container?**

Docker uses three Linux kernel features. Namespaces limit what a process can see — its own filesystem, network, processes, users, and hostname. cgroups limit how much CPU and memory a process can use. Union filesystems (overlayfs) stack read-only image layers and add one writable layer on top. A container is a Linux process with these three constraints applied.

**What is a namespace?**

A namespace restricts a process's view of the system. A container's network namespace gives it its own IP stack and its own localhost — completely separate from the host and every other container. This is why `localhost` inside webstore-api means webstore-api itself, not webstore-db.

**What is a cgroup?**

A cgroup (control group) limits how much CPU, memory, and I/O a process group can consume. When a container gets OOM-killed (exit code 137), it hit its cgroup memory limit. `docker stats` shows cgroup limits in real time.

---

## Container Lifecycle · Debugging

**What happens when you run `docker run`?**

Docker checks if the image exists locally. If not, it pulls from the registry. It creates a container — a new namespace set, a writable layer on top of the image layers, and a network interface. It starts the process defined by CMD or ENTRYPOINT. The container lives as long as that process runs.

**A container is running but the app isn't working. What do you do?**

Never rebuild first. `docker logs CONTAINER_NAME` to see what the app is outputting. If the app is alive but misbehaving, `docker logs -f` to follow live. If logs aren't enough, `docker exec -it CONTAINER_NAME /bin/sh` to get inside. `docker inspect` to check env vars, ports, and network. Rebuild only after you know the root cause.

**What does exit code 137 mean?**

The container was killed by OOM — the cgroup memory limit was hit. Check `docker inspect` for memory limits and `docker stats` for usage before the crash.

---

## Port Binding · NAT · Container Networking

**What does `-p 8080:8080` actually do?**

It creates an iptables DNAT rule on the host. Traffic arriving on host port 8080 gets its destination rewritten to the container's private IP on port 8080. The container never sees the original host address — it just receives a normal incoming connection. `sudo iptables -t nat -L DOCKER -n` shows the rules Docker created.

**Why can't two containers on the same host talk using `localhost`?**

Each container has its own network namespace — its own localhost. `localhost` inside webstore-api means webstore-api itself. To reach webstore-db, you use the container name as the hostname. Docker DNS on the custom network resolves it to the container's IP automatically.

**What is Docker DNS and how does it work?**

When you create a custom Docker network, Docker starts an embedded DNS server at `127.0.0.11` for that network. Every container that joins gets its name registered. When webstore-api asks for `webstore-db`, it queries `127.0.0.11`, gets back the IP, and connects. This only works on custom named networks — the default bridge network does not have Docker DNS.

**Why doesn't webstore-db have a `-p` flag?**

Databases should never be exposed publicly. webstore-db is reachable from webstore-api over the Docker network using the container name. No port binding means no external access — the container is invisible to anything outside Docker. This is the same principle as putting a database in a private subnet on AWS.

---

## Layers · Caching · Image Optimization

**What is a Docker image layer?**

Each Dockerfile instruction creates one read-only layer. Layers are stacked — each one represents the filesystem changes from that instruction. When a container runs, Docker adds one writable layer on top. All read-only layers are shared across containers from the same image.

**How does Docker layer caching work?**

Docker hashes each instruction and its context. If the hash matches a previous build, Docker reuses that layer — no work is done. If the hash changes, that layer and every layer after it rebuilds. This is why `COPY . .` must come after `RUN npm install` — changing source code should not invalidate the dependency install cache.

**What is a multi-stage build and why use it?**

A multi-stage build uses multiple `FROM` instructions in one Dockerfile. The first stage (builder) compiles or builds the app. The second stage (runtime) copies only the compiled output from the builder — no build tools, no source code, no intermediate files. The result is a small, production-safe image.

**What goes in `.dockerignore`?**

`node_modules` — already installed inside the image by `RUN npm install`, copying from host wastes space. `.git` — version history has no place in a runtime image. `.env` — secrets must never be baked into an image. `*.log` — log files change constantly and break layer caching.

---

## Volumes · Named vs Bind · Data Persistence

**What happens to data written inside a container when it is deleted?**

It is gone. A container's writable layer is deleted with the container. Anything that must survive — database rows, uploaded files, logs — must be stored in a volume outside the container.

**What is the difference between a named volume and a bind mount?**

A named volume is managed by Docker. Docker controls where it lives on the host. Use it for database data — anything critical that must persist. A bind mount maps a specific host path into the container. You control the path. Use it in development — edit code on your laptop, see changes instantly inside the container.

**Why does webstore-db use a named volume?**

`/var/lib/postgresql/data` is where postgres writes its data files. Without a volume, deleting and recreating the container means every row in the database is gone. The named volume `webstore-db-data` lives independently of the container — delete and recreate the container, the data is still there.

---

## Dockerfile · Build-time vs Run-time · Multi-stage

**What is the difference between `RUN`, `CMD`, and `ENTRYPOINT`?**

`RUN` executes during `docker build` and creates a new layer — use it to install packages or set up the environment. `CMD` is the default command when a container starts — it runs at runtime and can be overridden by passing a command to `docker run`. `ENTRYPOINT` is the fixed starting point — it always runs, and `CMD` becomes its default arguments.

**What is the correct order of instructions in a Dockerfile?**

Stable things first, volatile things last. Base image (`FROM`), system packages (`RUN apt-get`), dependency manifest (`COPY package.json`), dependency install (`RUN npm install`), source code (`COPY . .`), startup command (`CMD`). Source code changes on every commit — putting it last means the expensive install steps stay cached.

**What does `EXPOSE` do?**

Nothing at runtime. It is documentation only — it tells anyone reading the Dockerfile which port the app listens on. Actual port binding happens with `-p` when you run the container. `EXPOSE` without `-p` does not make the port reachable.

---

## Registry · Tagging · Push and Pull

**What is a container registry?**

A remote storage system for Docker images. Developers push to it after building. CI pulls from it to test. Production pulls from it to deploy. The registry is passive — it stores images, it does not run them. Docker Hub is the default public registry. ECR, GCR, and ACR are cloud-managed private registries.

**Why should you never deploy `latest` to production?**

`latest` is mutable — it points to whatever was pushed most recently. In production you need to know exactly which version is running and be able to roll back to a specific version. Use Git SHA tags (`webstore-api:a3f92c1`) for CI builds and semantic version tags (`webstore-api:v1.0.0`) for releases.

**What is the full workflow to push an image to Docker Hub?**

Build the image, tag it with your Docker Hub username and the target repo name, login with `docker login`, push with `docker push`. The tag format is `USERNAME/IMAGE:TAG`. Kubernetes later pulls this same tag — what you push here is what the cluster runs.

---

## Compose · depends_on · Networks and Volumes

**What does Docker Compose do?**

Replaces multiple `docker run` commands with one declarative file. It automates container creation, Docker networking, DNS, port binding, startup order, and volume creation. It does not add new concepts — everything Compose does, you can do manually with `docker run`. Compose just does it consistently from a single file.

**What does `depends_on` do?**

It controls startup order — the listed service starts before the dependent one. It does not guarantee the service is ready to accept connections. webstore-db starting before webstore-api means the postgres process started, not that it finished initializing. The app still needs retry logic for database connections.

**What is the difference between `docker compose down` and `docker compose down -v`?**

`docker compose down` removes containers and the network — volumes are left untouched. `docker compose down -v` removes containers, network, and all named volumes. `-v` deletes the database volume. All data is gone. Only use it when you want a completely clean reset.

---

← [Back to Docker README](../README.md)

---
# SOURCE: 04. Docker – Containerization/docker-labs/01-containers-portbinding-lab.md
---

[Home](../README.md) |
[Labs Index](./README.md) |
[Lab 01](./01-containers-portbinding-lab.md) |
[Lab 02](./02-networking-volumes-lab.md) |
[Lab 03](./03-build-layers-lab.md) |
[Lab 04](./04-registry-compose-lab.md)

---

# Lab 01 — Containers & Port Binding

## The Situation

The webstore ran on a Linux server. Now you are going to containerize it — but before you containerize your own app, you need to understand how containers work at the most basic level. What does it mean to run nginx as a container? How do you reach it from a browser? What happens when it crashes?

This lab uses prebuilt images — nginx for the webstore-frontend and postgres for webstore-db. By the end you will have run, inspected, debugged, and cleaned up containers confidently. Lab 02 picks up here to wire multiple containers together into the actual webstore stack.

## What this lab covers

You will run containers interactively and as background services, pass configuration at startup, observe and debug running containers, expose a service to your browser using port binding, and clean up safely. Every command is typed from scratch. Nothing is copy-pasted.

## Prerequisites

- [Docker Containers notes](../03-docker-containers/README.md)
- [Docker Port Binding notes](../04-docker-port-binding/README.md)
- Docker Desktop running on your machine

---

## Section 1 — Pull and Explore Images

**Goal:** download images and inspect what you have locally.

1. Check your Docker version
```bash
docker -v
```

2. Pull the ubuntu image (no tag = latest)
```bash
docker pull ubuntu
```

3. Pull a specific version
```bash
docker pull ubuntu:22.04
```

4. Pull nginx — the image that will serve the webstore-frontend
```bash
docker pull nginx:1.24
```

5. List all downloaded images
```bash
docker images
```

**What to observe:**
- Each image has a REPOSITORY, TAG, IMAGE ID, and SIZE
- `ubuntu` and `ubuntu:22.04` may share layers (size difference is small)
- Nothing is running yet

---

## Section 2 — Interactive Containers

**Goal:** enter a container like a terminal, explore it, and understand its lifecycle.

1. Run ubuntu interactively and name it
```bash
docker run --name ubuntu-test -it ubuntu:22.04
```

You are now inside the container. Your prompt changes.

2. Explore the environment from inside
```bash
whoami
hostname
ls /
cat /etc/os-release
```

3. Create a file inside the container
```bash
echo "I was here" > /tmp/test.txt
cat /tmp/test.txt
```

4. Exit the container
```bash
exit
```

5. Check container status
```bash
docker ps -a
```

**What to observe:** the container is stopped but still exists (STATUS = Exited)

6. Start the same container and re-enter it
```bash
docker start -i ubuntu-test
```

7. Check if your file survived the stop/start
```bash
cat /tmp/test.txt
```

**What to observe:** file is still there — stopping is not deleting

8. Exit again
```bash
exit
```

---

## Section 3 — Service Mode + Port Binding

**Goal:** run nginx as the webstore-frontend background service and reach it from your browser.

1. Run nginx in the background with port binding
```bash
docker run -d --name webstore-frontend -p 8080:80 nginx:1.24
```

2. Confirm it is running
```bash
docker ps
```

**What to observe in the PORTS column:**
```
0.0.0.0:8080->80/tcp
```
This means host port 8080 forwards to container port 80.

3. Open your browser and go to:
```
http://localhost:8080
```

**What to observe:** nginx welcome page loads — your container is serving traffic

4. View live logs
```bash
docker logs -f webstore-frontend
```

Refresh the browser page and watch a new log line appear.

Press `Ctrl+C` to stop following logs.

---

## Section 4 — Configuration at Startup

**Goal:** pass required environment variables to a container that needs them.

1. Try running webstore-db without any configuration
```bash
docker run -d --name webstore-db-test postgres:15
```

2. Check what happened
```bash
docker ps -a
docker logs webstore-db-test
```

**What to observe:** container exited immediately — postgres requires at minimum `POSTGRES_PASSWORD`. This is the `-e` flag in action — without it the image refuses to start.

3. Run webstore-db with the required environment variables
```bash
docker run -d \
  --name webstore-db-configured \
  -e POSTGRES_DB=webstore \
  -e POSTGRES_USER=admin \
  -e POSTGRES_PASSWORD=secret \
  postgres:15
```

4. Confirm it is running
```bash
docker ps
```

5. Check logs to confirm clean startup
```bash
docker logs webstore-db-configured
```

**What to observe:** postgres started successfully — you will see `database system is ready to accept connections` in the logs

---

## Section 5 — Observability and Debugging

**Goal:** inspect and debug containers without rebuilding anything.

1. Inspect the full container configuration
```bash
docker inspect webstore-frontend
```

Look for:
- `"Image"` — which image was used
- `"Ports"` — port mapping
- `"Env"` — environment variables

2. Enter the running nginx container
```bash
docker exec -it webstore-frontend /bin/sh
```

3. From inside, explore the nginx config
```bash
cat /etc/nginx/nginx.conf
ls /usr/share/nginx/html
exit
```

4. Restart the container
```bash
docker restart webstore-frontend
```

5. Confirm it came back up
```bash
docker ps
```

---

## Section 6 — Break It on Purpose

**Goal:** produce real failure states and learn to read them.

### Break 1 — Wrong image name

```bash
docker run -d --name broken-1 nginxxx:1.24
```

Check what happened:
```bash
docker ps -a
docker logs broken-1
```

**What to observe:** `Unable to find image` — Docker couldn't pull a non-existent image

### Break 2 — Missing required environment variable

You already did this in Section 4 with webstore-db. Go back and re-read those logs now with fresh eyes.

**What to observe:** the error message tells you exactly what is missing

### Break 3 — Port conflict

Start a second nginx on the same host port:
```bash
docker run -d --name broken-2 -p 8080:80 nginx:1.24
```

**What to observe:** `port is already allocated` — two containers cannot share the same host port

Fix it by using a different host port:
```bash
docker run -d --name webstore-frontend-2 -p 8090:80 nginx:1.24
```

Confirm both are running on different ports:
```bash
docker ps
```

Visit `http://localhost:8090` — second nginx is also accessible.

---

## Section 7 — Safe Delete Flow

**Goal:** clean everything up without errors.

1. List everything that exists
```bash
docker ps -a
```

2. Stop all running containers
```bash
docker stop webstore-frontend webstore-frontend-2 webstore-db-configured
```

3. Remove all containers (including the failed ones)
```bash
docker rm ubuntu-test webstore-frontend webstore-frontend-2 webstore-db-configured webstore-db-test broken-1 broken-2
```

4. Confirm no containers remain
```bash
docker ps -a
```

5. Remove images
```bash
docker rmi nginx:1.24 ubuntu:22.04 ubuntu postgres:15
```

6. Confirm images are gone
```bash
docker images
```

**If any delete fails:** the error message tells you what is still blocking it. Stop and remove that container first, then retry.

---

## Checklist

Do not move to Lab 02 until every box is checked.

- [ ] I pulled images and read the `docker images` output without guessing what the columns mean
- [ ] I entered an ubuntu container interactively, created a file, exited, restarted, and confirmed the file survived the stop/start cycle
- [ ] I ran nginx with `-d` and `-p` and saw the welcome page in my browser
- [ ] I watched live logs with `docker logs -f` and saw a new line appear when I refreshed the browser
- [ ] I ran webstore-db without `-e` and read the error — I know why it failed
- [ ] I ran webstore-db with the correct postgres env vars and confirmed clean startup in logs
- [ ] I used `docker inspect` and found the port mapping and image name in the output
- [ ] I used `docker exec -it` to enter a running container and looked around
- [ ] I produced a port conflict error on purpose and understood what it meant
- [ ] I deleted everything in the correct order: stop → rm → rmi — with zero errors

---
# SOURCE: 04. Docker – Containerization/docker-labs/02-networking-volumes-lab.md
---

[Home](../README.md) |
[Labs Index](./README.md) |
[Lab 01](./01-containers-portbinding-lab.md) |
[Lab 02](./02-networking-volumes-lab.md) |
[Lab 03](./03-build-layers-lab.md) |
[Lab 04](./04-registry-compose-lab.md)

---

# Lab 02 — Networking & Volumes

## The Situation

The webstore-frontend is running as a container. But the real webstore is three services: a frontend, an API, and a database. Those three services need to talk to each other. The database needs to store data that survives container restarts.

Right now containers are isolated. webstore-api cannot reach webstore-db because nothing connects them. And if webstore-db is deleted, every row in the database is gone with it. This lab fixes both problems.

By the end, webstore-api talks to webstore-db using the container name as a hostname, Docker DNS resolves it automatically, port binding is proven to be iptables NAT, and the database data survives complete container deletion. This is the foundation Lab 03 builds on — you cannot build the API image until the network and storage are wired correctly.

## What this lab covers

You will prove that containers cannot talk to each other without a network, create a Docker network, connect webstore-db and webstore-api so they communicate by name, verify Docker DNS at the resolver level, prove that port binding is iptables NAT, prove that container data dies without volumes, attach a named volume to postgres, delete and recreate the container, and confirm the data survived. Every command is typed from scratch.

## Prerequisites

- [Docker Networking notes](../05-docker-networking/README.md)
- [Docker Volumes notes](../06-docker-volumes/README.md)
- Lab 01 completed

---

## Section 1 — Prove Containers Are Isolated by Default

**Goal:** show that two containers cannot reach each other without a network.

1. Run two containers with no network flags
```bash
docker run -d --name container-a nginx:1.24
docker run -d --name container-b nginx:1.24
```

2. Enter container-a
```bash
docker exec -it container-a /bin/sh
```

3. Try to reach container-b by name
```bash
ping container-b
```

**What to observe:** `ping: bad address 'container-b'` — no DNS, no connection

4. Exit
```bash
exit
```

5. Clean up
```bash
docker stop container-a container-b
docker rm container-a container-b
```

---

## Section 2 — Create a Network and Verify Docker DNS

**Goal:** create the webstore network, prove DNS works inside it, and verify it at the resolver level.

1. Create the network
```bash
docker network create webstore-network
```

2. Confirm it exists
```bash
docker network ls
```

3. Run webstore-db on the network
```bash
docker run -d \
  --name webstore-db \
  --network webstore-network \
  -e POSTGRES_DB=webstore \
  -e POSTGRES_USER=admin \
  -e POSTGRES_PASSWORD=secret \
  postgres:15
```

4. Run adminer on the same network
```bash
docker run -d \
  --name adminer \
  --network webstore-network \
  -p 8081:8080 \
  adminer
```

5. Wait about 10 seconds then open your browser:
```
http://localhost:8081
```

Log in with:
- System: PostgreSQL
- Server: `webstore-db`
- Username: `admin`
- Password: `secret`
- Database: `webstore`

**What to observe:** adminer UI loads and connects to webstore-db — it reached the database using the hostname `webstore-db`, not an IP address

6. Enter the adminer container and ping webstore-db by name
```bash
docker exec -it adminer /bin/sh
ping webstore-db
```

**What to observe:** ping resolves and gets a response — Docker DNS is working

7. Check what DNS server the container is using
```bash
cat /etc/resolv.conf
```

**What to observe:**
```
nameserver 127.0.0.11
options ndots:0
```

`127.0.0.11` is Docker's embedded DNS server. This is automatically configured for every container on a custom network.

8. Run a proper DNS lookup to see the full resolution
```bash
nslookup webstore-db
```

**What to observe:**
```
Server:         127.0.0.11
Address:        127.0.0.11:53

Non-authoritative answer:
Name:   webstore-db
Address: 172.18.0.X
```

The container name `webstore-db` resolved to its private IP. Docker DNS answered the query at `127.0.0.11:53`.

9. Exit
```bash
exit
```

10. Check the network from the outside — see all containers and their IPs
```bash
docker network inspect webstore-network
```

**What to observe:** a `"Containers"` section showing every container on the network, their names, and their assigned IPs. The IP you saw in `nslookup` matches here.

---

## Section 2.5 — Port Binding Is NAT — Prove It

**Goal:** show that `-p host:container` creates a real iptables DNAT rule — not magic.

1. Run nginx with port binding
```bash
docker run -d --name nat-proof -p 8080:80 nginx:1.24
```

2. Confirm port 8080 is now listening on the host
```bash
sudo ss -tlnp | grep 8080
```

**What to observe:** port 8080 is now listening — Docker created this mapping.

3. Check what IP the container was assigned
```bash
docker inspect nat-proof | grep '"IPAddress"'
```

Record the container IP (something like `172.17.0.2`).

4. Access it via the port binding
```bash
curl http://localhost:8080
```

**What to observe:** nginx responds — request hit host port 8080, was translated to container port 80.

5. Look at the actual iptables rule Docker created
```bash
sudo iptables -t nat -L DOCKER -n
```

**What to observe:**
```
Chain DOCKER
target  prot  opt  source      destination
DNAT    tcp   --   0.0.0.0/0   0.0.0.0/0   tcp dpt:8080 to:172.17.0.X:80
```

This DNAT rule is what makes port binding work. Every `-p` flag you use creates an entry exactly like this.

6. Access the container directly by its IP (bypassing NAT entirely)
```bash
CONTAINER_IP=$(docker inspect nat-proof | grep '"IPAddress"' | tail -1 | awk -F'"' '{print $4}')
curl http://$CONTAINER_IP:80
```

**What to observe:** direct container access works — no NAT needed when already on the same network.

7. Clean up
```bash
docker stop nat-proof && docker rm nat-proof
```

> **The Rule:** `-p host:container` = `iptables DNAT rule`. Docker translates host traffic to the container's private IP. This is identical to how your home router does port forwarding.

---

## Section 3 — Prove Data Dies Without a Volume

**Goal:** write data into a postgres container, delete it, confirm data is gone.

1. Enter the running webstore-db container
```bash
docker exec -it webstore-db psql -U admin -d webstore
```

2. Create a table and insert a row
```sql
CREATE TABLE products (id SERIAL PRIMARY KEY, name TEXT, price INT);
INSERT INTO products (name, price) VALUES ('keyboard', 79);
SELECT * FROM products;
```

**What to observe:** row inserted and visible

3. Exit psql
```sql
\q
```

4. Stop and delete the container
```bash
docker stop webstore-db
docker rm webstore-db
```

5. Run a fresh webstore-db container (same image, no volume)
```bash
docker run -d \
  --name webstore-db \
  --network webstore-network \
  -e POSTGRES_DB=webstore \
  -e POSTGRES_USER=admin \
  -e POSTGRES_PASSWORD=secret \
  postgres:15
```

6. Wait a few seconds then check for your data
```bash
docker exec -it webstore-db psql -U admin -d webstore -c "SELECT * FROM products;"
```

**What to observe:** error — table does not exist. Data is gone. This is why volumes exist.

---

## Section 4 — Named Volume (Data Survives)

**Goal:** attach a named volume to postgres and prove data survives container deletion.

1. Stop and remove the no-volume container
```bash
docker stop webstore-db
docker rm webstore-db
```

2. Create a named volume
```bash
docker volume create webstore-db-data
```

3. Confirm it exists
```bash
docker volume ls
```

4. Run webstore-db with the volume attached
```bash
docker run -d \
  --name webstore-db \
  --network webstore-network \
  -v webstore-db-data:/var/lib/postgresql/data \
  -e POSTGRES_DB=webstore \
  -e POSTGRES_USER=admin \
  -e POSTGRES_PASSWORD=secret \
  postgres:15
```

5. Wait a few seconds then create data
```bash
docker exec -it webstore-db psql -U admin -d webstore
```

```sql
CREATE TABLE products (id SERIAL PRIMARY KEY, name TEXT, price INT);
INSERT INTO products (name, price) VALUES ('keyboard', 79);
INSERT INTO products (name, price) VALUES ('mouse', 49);
SELECT * FROM products;
\q
```

6. Stop and delete the container — deliberately
```bash
docker stop webstore-db
docker rm webstore-db
```

7. Confirm the volume still exists
```bash
docker volume ls
```

**What to observe:** `webstore-db-data` is still there — volumes are independent of containers

8. Run a new container with the same volume
```bash
docker run -d \
  --name webstore-db \
  --network webstore-network \
  -v webstore-db-data:/var/lib/postgresql/data \
  -e POSTGRES_DB=webstore \
  -e POSTGRES_USER=admin \
  -e POSTGRES_PASSWORD=secret \
  postgres:15
```

9. Check for your data
```bash
docker exec -it webstore-db psql -U admin -d webstore -c "SELECT * FROM products;"
```

**What to observe:** both rows are there — data survived full container deletion and recreation

---

## Section 5 — Bind Mount (Developer Workflow)

**Goal:** link a host folder into a container and prove changes go both ways.

1. Create a folder on your laptop
```bash
mkdir ~/webstore-config
echo "db_host=webstore-db" > ~/webstore-config/app.conf
echo "db_port=5432" >> ~/webstore-config/app.conf
```

2. Run a container with the folder bind-mounted
```bash
docker run -it --rm \
  -v ~/webstore-config:/config \
  ubuntu:22.04
```

3. From inside the container, read the file
```bash
cat /config/app.conf
```

4. Add a line from inside the container
```bash
echo "api_port=8080" >> /config/app.conf
cat /config/app.conf
exit
```

5. On your laptop, check the file
```bash
cat ~/webstore-config/app.conf
```

**What to observe:** the line you added inside the container appears on your laptop — same folder, two views

---

## Section 5.5 — Full Webstore Stack Trace

**Goal:** bring up the full webstore stack and trace every networking layer — DNS, routing, ports, NAT — exactly as covered in the networking notes complete journey.

This section fulfills the redirect from [Networking Lab 05](../../03.%20Networking%20–%20Foundations/networking-labs/05-complete-journey-lab.md).

1. Confirm webstore-db and adminer are still running
```bash
docker ps
```

If they are not running, bring them back:
```bash
docker run -d \
  --name webstore-db \
  --network webstore-network \
  -v webstore-db-data:/var/lib/postgresql/data \
  -e POSTGRES_DB=webstore \
  -e POSTGRES_USER=admin \
  -e POSTGRES_PASSWORD=secret \
  postgres:15

docker run -d \
  --name adminer \
  --network webstore-network \
  -p 8081:8080 \
  adminer
```

2. Run a webstore-api placeholder (nginx standing in for the real API)
```bash
docker run -d \
  --name webstore-api \
  --network webstore-network \
  -p 8080:80 \
  nginx:1.24
```

Now trace every layer:

**Layer 7 — DNS: can webstore-api resolve webstore-db by name?**
```bash
docker exec webstore-api nslookup webstore-db
```

Record: `webstore-db resolves to ___.___.___.___ `

**Layer 7 — DNS: what DNS server is the container using?**
```bash
docker exec webstore-api cat /etc/resolv.conf
```

Record: `nameserver ___.___.___.___ ` (should be `127.0.0.11`)

**Layer 3 — Routing: what is the container's default gateway?**
```bash
docker exec webstore-api ip route
```

**What to observe:** `default via 172.18.0.1` — the Docker bridge is the gateway for all traffic leaving the container.

**Layer 3-4 — Can the container reach the database port?**
```bash
docker exec webstore-api nc -zv webstore-db 5432
```

Record: port 5432 reachable? ___

**NAT — Port binding proof: see the iptables rules for all containers**
```bash
sudo iptables -t nat -L DOCKER -n
```

**What to observe:** DNAT rules — one for port 8080 (api), one for 8081 (adminer). Each maps a host port to a container IP. webstore-db has no entry — it is internal only.

**Network isolation — confirm webstore-db has no public port exposure**
```bash
docker inspect webstore-db | grep -A 5 '"Ports"'
```

**What to observe:** empty or no host port mapping — webstore-db is unreachable from outside Docker.

**The complete data flow:**
```
Browser → localhost:8080
    │
    ▼ iptables DNAT
host port 8080 → webstore-api container (172.18.0.X:80)
    │
    ▼ Docker DNS resolves "webstore-db"
webstore-api → webstore-db:5432 (172.18.0.Y:5432)
    │
    ▼ direct container-to-container (no NAT needed)
webstore-db receives connection
```

**Verify the full flow end to end:**
```bash
# From outside — hits port binding (NAT)
curl -s http://localhost:8080 | head -5

# From inside api — hits DNS then direct network
docker exec webstore-api nc -zv webstore-db 5432

# From inside api — confirm db is unreachable on localhost
docker exec webstore-api nc -zv localhost 5432
```

**What to observe on the last command:** connection refused — `localhost` inside webstore-api is the container itself, not webstore-db. This is the localhost rule in action.

---

## Section 6 — Break It on Purpose

### Break 1 — Connect to a container not on the network

1. Run a container with no network
```bash
docker run -d --name isolated nginx:1.24
```

2. Try to reach webstore-db from it
```bash
docker exec -it isolated /bin/sh
ping webstore-db
exit
```

**What to observe:** fails — `isolated` is on the default bridge, not `webstore-network`

3. Clean up
```bash
docker stop isolated && docker rm isolated
```

### Break 2 — Wrong hostname in connection string

Check what happens when the container name is wrong:
```bash
docker exec webstore-api nc -zv wrong-host 5432
```

**What to observe:** DNS resolution fails — `wrong-host` does not exist on the network

### Break 3 — Use localhost instead of container name

```bash
docker exec webstore-api nc -zv localhost 5432
```

**What to observe:** `Connection refused` — `localhost` inside webstore-api is the container itself. Port 5432 is not running inside webstore-api. This is why you always use container names, never localhost, in Docker connection strings.

---

## Section 7 — Safe Delete Flow

1. Stop all containers
```bash
docker stop webstore-api webstore-db adminer
```

2. Remove all containers
```bash
docker rm webstore-api webstore-db adminer
```

3. Remove the network
```bash
docker network rm webstore-network
```

4. Remove the volume (only if you don't need the data)
```bash
docker volume rm webstore-db-data
```

5. Remove images
```bash
docker rmi postgres:15 adminer nginx:1.24 ubuntu:22.04
```

6. Confirm everything is clean
```bash
docker ps -a
docker network ls
docker volume ls
docker images
```

---

## Checklist

Do not move to Lab 03 until every box is checked.

- [ ] I ran two containers with no network and confirmed they cannot reach each other by name
- [ ] I created `webstore-network` and confirmed DNS resolution works between containers on it
- [ ] I opened adminer in the browser and it connected to webstore-db using the hostname — not an IP
- [ ] I ran `cat /etc/resolv.conf` inside a container and confirmed the DNS server is `127.0.0.11`
- [ ] I ran `nslookup webstore-db` from inside a container and got back the container's IP
- [ ] I ran `docker network inspect webstore-network` and matched the IP from nslookup to the IP in the inspect output
- [ ] I ran `sudo iptables -t nat -L DOCKER -n` and saw the DNAT rule Docker created for my port binding
- [ ] I accessed the container directly by its IP (bypassing NAT) and confirmed it worked
- [ ] I inserted data into webstore-db with no volume, deleted the container, confirmed the data was gone
- [ ] I created a named volume, attached it to webstore-db, inserted data, deleted the container, recreated it with the same volume, and confirmed the data survived
- [ ] I used a bind mount, wrote a file from inside the container, and saw it appear on my laptop
- [ ] I traced the full webstore stack — DNS resolution, default gateway, port reachability, iptables rules, and data flow
- [ ] I confirmed that `localhost` inside a container does NOT reach another container — connection refused
- [ ] I deleted everything in the correct order: stop → rm containers → rm network → rm volume → rmi images

---
# SOURCE: 04. Docker – Containerization/docker-labs/03-build-layers-lab.md
---

[Home](../README.md) |
[Labs Index](./README.md) |
[Lab 01](./01-containers-portbinding-lab.md) |
[Lab 02](./02-networking-volumes-lab.md) |
[Lab 03](./03-build-layers-lab.md) |
[Lab 04](./04-registry-compose-lab.md)

---

# Lab 03 — Layers, Build & Dockerfile

## The Situation

The webstore network is wired and the database persists data. But webstore-api is still running as a placeholder nginx container. The actual API is code on your laptop — a Node.js application that needs to be packaged into a Docker image before it can run anywhere else.

This lab is where you build that image. You will understand why layer order matters before you write a single line of Dockerfile, then write the webstore-api Dockerfile correctly from scratch. By the end `webstore-api:1.0` is a real image that runs the actual API — ready to be pushed to a registry in Lab 04.

## What this lab covers

You will inspect real image layers, watch Docker caching work and break, write a Dockerfile for webstore-api from scratch, create a proper `.dockerignore`, build and run the image, then break the build on purpose in ways that teach you how the cache and ordering rules actually work. Every file is written from scratch.

## Prerequisites

- [Docker Layers notes](../07-docker-layers/README.md)
- [Docker Build notes](../08-docker-build-dockerfile/README.md)
- Lab 02 completed

---

## Section 1 — Inspect Real Layers

**Goal:** see layers with your own eyes before writing any Dockerfile.

1. Pull a small image
```bash
docker pull alpine:3.18
```

2. View its layers
```bash
docker history alpine:3.18
```

**What to observe:** very few layers, small sizes

3. Pull a Node image
```bash
docker pull node:20-alpine
```

4. View its layers
```bash
docker history node:20-alpine
```

**What to observe:** more layers — each one added something on top of alpine

5. Check how much disk both images use
```bash
docker system df
```

**What to observe:** total size is less than alpine + node added together — shared layers are not duplicated on disk

---

## Section 2 — Watch Caching Work

**Goal:** build an image twice and see layers get reused.

1. Create a working folder
```bash
mkdir ~/cache-test && cd ~/cache-test
```

2. Write this Dockerfile from scratch
```dockerfile
FROM alpine:3.18
RUN apk add --no-cache curl
RUN echo "layer three"
RUN echo "layer four"
CMD ["sh"]
```

3. Build it the first time
```bash
docker build -t cache-test:v1 .
```

**What to observe:** each step says how long it took

4. Build it again immediately
```bash
docker build -t cache-test:v1 .
```

**What to observe:** every step says `CACHED` — instant build, nothing re-ran

---

## Section 3 — Break the Cache on Purpose

**Goal:** change one layer and watch everything after it rebuild.

1. Edit your Dockerfile — change only layer three
```dockerfile
FROM alpine:3.18
RUN apk add --no-cache curl
RUN echo "layer three MODIFIED"
RUN echo "layer four"
CMD ["sh"]
```

2. Build again
```bash
docker build -t cache-test:v2 .
```

**What to observe:**
- Layer 1 (FROM) → CACHED
- Layer 2 (curl) → CACHED
- Layer 3 (echo modified) → rebuilt
- Layer 4 (echo layer four) → rebuilt even though you didn't change it

**Why:** changing layer 3 invalidates the filesystem state that layer 4 depends on. Docker cannot safely reuse it. This is why stable instructions go first — volatile code goes last.

---

## Section 4 — Bad vs Good Dockerfile Ordering

**Goal:** prove that instruction order directly affects build speed.

1. Create a new folder
```bash
mkdir ~/order-test && cd ~/order-test
```

2. Create a fake dependency file
```bash
echo '{ "name": "webstore-api", "version": "1.0.0" }' > package.json
```

3. Create some fake source files
```bash
echo "console.log('server running')" > server.js
echo "module.exports = {}" > config.js
```

4. Write the **bad** Dockerfile (copy everything first)
```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY . .
RUN npm install
CMD ["node", "server.js"]
```

5. Build it
```bash
docker build -t order-bad:v1 .
```

6. Change one source file (simulating a code change)
```bash
echo "console.log('updated')" > server.js
```

7. Build again and watch what reruns
```bash
docker build -t order-bad:v2 .
```

**What to observe:** `COPY . .` layer changed → `npm install` runs again even though `package.json` didn't change

8. Now write the **good** Dockerfile in the same folder
```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package.json .
RUN npm install
COPY . .
CMD ["node", "server.js"]
```

9. Build it
```bash
docker build -t order-good:v1 .
```

10. Change a source file again
```bash
echo "console.log('updated again')" > server.js
```

11. Build again
```bash
docker build -t order-good:v2 .
```

**What to observe:**
- `COPY package.json` → CACHED (didn't change)
- `RUN npm install` → CACHED (package.json didn't change)
- `COPY . .` → rebuilt (source code changed)
- Only the last copy reruns — npm install is skipped

**This is the difference between a 45-second build and a 2-second build.**

---

## Section 5 — Write the webstore-api Dockerfile

**Goal:** write a real Dockerfile for the webstore-api from scratch.

1. Create the project folder
```bash
mkdir ~/webstore-api && cd ~/webstore-api
```

2. Create a minimal Node app
```bash
cat > server.js << 'EOF'
const http = require('http');
const port = process.env.PORT || 8080;
const server = http.createServer((req, res) => {
  res.writeHead(200, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify({ service: 'webstore-api', status: 'running' }));
});
server.listen(port, () => console.log(`webstore-api listening on port ${port}`));
EOF
```

3. Create the package.json
```bash
cat > package.json << 'EOF'
{
  "name": "webstore-api",
  "version": "1.0.0",
  "main": "server.js",
  "scripts": { "start": "node server.js" }
}
EOF
```

4. Write the `.dockerignore` file from scratch
```
node_modules
.git
*.log
.env
dist
build
```

5. Write the Dockerfile from scratch
```dockerfile
FROM node:20-alpine

WORKDIR /app

COPY package.json .
RUN npm install

COPY . .

EXPOSE 8080

CMD ["node", "server.js"]
```

6. Build the image
```bash
docker build -t webstore-api:1.0 .
```

7. Confirm the image exists
```bash
docker images | grep webstore-api
```

8. Run it
```bash
docker run -d --name webstore-api -p 8080:8080 webstore-api:1.0
```

9. Test it
```bash
curl http://localhost:8080
```

**What to observe:**
```json
{"service":"webstore-api","status":"running"}
```

10. Check the logs
```bash
docker logs webstore-api
```

---

## Section 6 — Inspect Your Image Layers

**Goal:** verify your Dockerfile produced the layers you expect.

1. View your image layers
```bash
docker history webstore-api:1.0
```

**What to observe:** each instruction you wrote appears as a layer with a size

2. Check that `.dockerignore` is working — look at the COPY layer size and confirm `node_modules` was not copied in

---

## Section 7 — Break It on Purpose

### Break 1 — Wrong base image name

1. Edit your Dockerfile — change the FROM line
```dockerfile
FROM node:99-alpine
```

2. Try to build
```bash
docker build -t webstore-api:broken .
```

**What to observe:** `manifest unknown` — image tag does not exist on Docker Hub

3. Fix it — restore `node:20-alpine`

### Break 2 — COPY before WORKDIR

1. Edit your Dockerfile
```dockerfile
FROM node:20-alpine
COPY package.json .
WORKDIR /app
RUN npm install
COPY . .
CMD ["node", "server.js"]
```

2. Build and run
```bash
docker build -t webstore-api:broken2 .
docker run --rm webstore-api:broken2
```

**What to observe:** `package.json` was copied to `/` (root) not `/app` — WORKDIR must come before COPY

3. Fix it — restore the correct order

### Break 3 — Missing `.dockerignore` effect

1. Create a fake node_modules folder
```bash
mkdir node_modules
echo "fake dependency" > node_modules/fake.js
```

2. Remove your `.dockerignore` temporarily
```bash
mv .dockerignore .dockerignore.bak
```

3. Build and inspect the COPY layer size
```bash
docker build -t webstore-api:no-ignore .
docker history webstore-api:no-ignore
```

**What to observe:** COPY layer is larger — `node_modules` was copied in unnecessarily

4. Restore `.dockerignore`
```bash
mv .dockerignore.bak .dockerignore
```

5. Build again and compare
```bash
docker build -t webstore-api:with-ignore .
docker history webstore-api:with-ignore
```

**What to observe:** COPY layer is smaller — `.dockerignore` excluded the junk

---

## Section 8 — Safe Delete Flow

1. Stop and remove the running container
```bash
docker stop webstore-api
docker rm webstore-api
```

2. Remove all images from this lab
```bash
docker rmi webstore-api:1.0 webstore-api:broken webstore-api:broken2
docker rmi webstore-api:no-ignore webstore-api:with-ignore
docker rmi cache-test:v1 cache-test:v2
docker rmi order-bad:v1 order-bad:v2 order-good:v1 order-good:v2
```

3. Confirm clean
```bash
docker images
docker ps -a
```

---

## Checklist

Do not move to Lab 04 until every box is checked.

- [ ] I ran `docker history` on alpine and node images and understood what each layer represents
- [ ] I built the same image twice and confirmed every layer was CACHED on the second build
- [ ] I changed one layer in the middle of a Dockerfile and watched it and every layer after it rebuild — I understand why
- [ ] I built the bad ordering Dockerfile, changed a source file, and watched `npm install` run again unnecessarily
- [ ] I built the good ordering Dockerfile, changed a source file, and confirmed `npm install` was cached
- [ ] I wrote the webstore-api Dockerfile from scratch with correct layer ordering
- [ ] I wrote `.dockerignore` from scratch and know what each entry excludes and why
- [ ] I built, ran, and hit `webstore-api:1.0` with curl and got a valid JSON response
- [ ] I produced a wrong FROM tag error and read the error message
- [ ] I proved `.dockerignore` reduces the COPY layer size by comparing builds with and without it

---
# SOURCE: 04. Docker – Containerization/docker-labs/04-registry-compose-lab.md
---

[Home](../README.md) |
[Labs Index](./README.md) |
[Lab 01](./01-containers-portbinding-lab.md) |
[Lab 02](./02-networking-volumes-lab.md) |
[Lab 03](./03-build-layers-lab.md) |
[Lab 04](./04-registry-compose-lab.md)

---

# Lab 04 — Registry & Compose

## The Situation

`webstore-api:1.0` exists on your laptop. It runs correctly. But it only exists on your laptop — no CI system can pull it, no production server can run it, no teammate can use it. And bringing up the full three-tier webstore still requires running three separate `docker run` commands in the right order with all the right flags.

This lab finishes both problems. You push the image to Docker Hub so it is available everywhere. Then you write a `docker-compose.yml` that captures the entire webstore — api, database, and DB UI — in one file. From this point forward, bringing up the entire webstore is one command: `docker compose up`.

This is the state Kubernetes picks up from. K8s does not run `docker run` commands — it pulls images from a registry and runs them based on manifest files. What you do in this lab is exactly the pattern Kubernetes uses, just at the orchestration layer.

## What this lab covers

You will push the webstore-api image to Docker Hub, pull it back to confirm it works, then write a `docker-compose.yml` from scratch that brings up the full webstore system — api, postgres database, and adminer UI — with one command. You will break the compose file on purpose, fix it, and do a clean teardown. Every file is written from scratch.

## Prerequisites

- [Docker Registry notes](../09-docker-registry/README.md)
- [Docker Compose notes](../10-docker-compose/README.md)
- Lab 03 completed — `webstore-api:1.0` image must exist locally
- A Docker Hub account

---

## Section 1 — Prepare and Push to Docker Hub

**Goal:** publish your local webstore-api image to Docker Hub.

1. Confirm the image exists locally
```bash
docker images | grep webstore-api
```

If it is missing, go back and build it from Lab 03 before continuing.

2. Check which Docker account you are logged into
```bash
docker info | grep -i username
```

3. If you see the wrong account or nothing — log out and back in
```bash
docker logout
docker login
```

4. Verify again
```bash
docker info | grep -i username
```

5. Tag the image for Docker Hub
```bash
docker tag webstore-api:1.0 YOUR_DOCKERHUB_USERNAME/webstore-api:1.0
```

6. Confirm both tags exist
```bash
docker images | grep webstore-api
```

**What to observe:** two rows — your local tag and the Docker Hub tag

7. Push to Docker Hub
```bash
docker push YOUR_DOCKERHUB_USERNAME/webstore-api:1.0
```

**What to observe:** Docker uploads only missing layers. Shared base layers (node:20-alpine) may already exist and get skipped.

8. Open Docker Hub in your browser and confirm the tag `1.0` appears in your `webstore-api` repository.

---

## Section 2 — Pull and Verify

**Goal:** delete the local image and pull it back from Docker Hub to prove the registry works.

1. Remove the local images (both tags)
```bash
docker rmi webstore-api:1.0
docker rmi YOUR_DOCKERHUB_USERNAME/webstore-api:1.0
```

2. Confirm they are gone
```bash
docker images | grep webstore-api
```

3. Pull from Docker Hub
```bash
docker pull YOUR_DOCKERHUB_USERNAME/webstore-api:1.0
```

4. Run it and confirm it still works
```bash
docker run -d --name webstore-api-test -p 8080:8080 YOUR_DOCKERHUB_USERNAME/webstore-api:1.0
curl http://localhost:8080
```

**What to observe:** same JSON response as before — the image came from the registry, not your local build

5. Clean up
```bash
docker stop webstore-api-test
docker rm webstore-api-test
```

---

## Section 3 — Write docker-compose.yml from Scratch

**Goal:** define the full webstore system in one file and bring it up with one command.

1. Create a working folder
```bash
mkdir ~/webstore && cd ~/webstore
```

2. Copy your webstore-api app files here (from Lab 03)
```bash
cp ~/webstore-api/server.js .
cp ~/webstore-api/package.json .
cp ~/webstore-api/Dockerfile .
cp ~/webstore-api/.dockerignore .
```

3. Write `docker-compose.yml` from scratch
```yaml
version: "3.9"

services:

  webstore-db:
    image: postgres:15
    environment:
      POSTGRES_DB: webstore
      POSTGRES_USER: admin
      POSTGRES_PASSWORD: secret
    volumes:
      - webstore-db-data:/var/lib/postgresql/data

  adminer:
    image: adminer
    ports:
      - "8081:8080"
    depends_on:
      - webstore-db

  webstore-api:
    build: .
    ports:
      - "8080:8080"
    environment:
      DB_HOST: webstore-db
      DB_PORT: 5432
      DB_NAME: webstore
      DB_USER: admin
      DB_PASSWORD: secret
    depends_on:
      - webstore-db

volumes:
  webstore-db-data:
```

4. Start the full system
```bash
docker compose up
```

Watch the startup logs — you will see all three containers initializing.

5. Open your browser and confirm both endpoints work:
```
http://localhost:8080   ← webstore-api
http://localhost:8081   ← adminer DB UI
```

For adminer, log in with:
- System: PostgreSQL
- Server: `webstore-db`
- Username: `admin`
- Password: `secret`
- Database: `webstore`

6. Stop with `Ctrl+C`, then bring it back up in the background
```bash
docker compose up -d
```

7. Confirm all three containers are running
```bash
docker ps
```

8. Check logs for a specific service
```bash
docker compose logs webstore-api
docker compose logs webstore-db
```

---

## Section 4 — Inspect What Compose Created

**Goal:** understand what Compose built automatically.

1. List networks
```bash
docker network ls
```

**What to observe:** Compose created a new network named after your folder (e.g. `webstore_default`)

2. List containers
```bash
docker ps
```

**What to observe:** container names follow the pattern `webstore-SERVICENAME-1`

3. Inspect the network
```bash
docker network inspect webstore_default
```

**What to observe:** all three containers are attached to the same network with their service names as DNS hostnames

4. Verify adminer reaches the database using the service name
```bash
docker exec webstore-adminer-1 nslookup webstore-db 2>/dev/null || \
docker exec $(docker ps -qf name=adminer) nslookup webstore-db
```

**What to observe:** DNS resolves `webstore-db` to its container IP — same as manual networking

---

## Section 5 — Break It on Purpose

### Break 1 — Wrong service name in connection string

1. Bring the system down
```bash
docker compose down
```

2. Edit `docker-compose.yml` — change the DB_HOST in webstore-api
```yaml
      DB_HOST: wrong-db
```

3. Bring it back up
```bash
docker compose up -d
```

4. Check webstore-api logs
```bash
docker compose logs webstore-api
```

**What to observe:** connection error — `wrong-db` does not exist as a hostname on the network

5. Fix it — restore `DB_HOST: webstore-db`
```bash
docker compose down
# fix the file
docker compose up -d
```

### Break 2 — Port already in use

1. Start a standalone nginx on port 8080
```bash
docker run -d --name port-blocker -p 8080:8080 nginx:1.24
```

2. Try to bring Compose up
```bash
docker compose up -d
```

**What to observe:** `Bind for 0.0.0.0:8080 failed: port is already allocated` — Compose cannot claim a port another container owns

3. Fix it
```bash
docker stop port-blocker && docker rm port-blocker
docker compose up -d
```

### Break 3 — Remove depends_on and watch startup order fail

1. Bring the system down
```bash
docker compose down
```

2. Edit `docker-compose.yml` — remove both `depends_on` blocks

3. Bring it up and watch the logs
```bash
docker compose up
```

**What to observe:** webstore-api and adminer may start before webstore-db is ready and log connection errors

4. Fix it — restore both `depends_on` blocks
```bash
# Ctrl+C to stop
docker compose down
# fix the file
docker compose up -d
```

---

## Section 6 — Safe Delete Flow

1. Stop and remove all Compose containers and network
```bash
docker compose down
```

2. Confirm containers and network are gone
```bash
docker ps -a
docker network ls
```

3. Remove the volume (only when you want to discard all database data)
```bash
docker compose down -v
```

4. Remove images
```bash
docker rmi YOUR_DOCKERHUB_USERNAME/webstore-api:1.0
docker rmi postgres:15 adminer nginx:1.24
```

5. Final check
```bash
docker images
docker ps -a
docker network ls
docker volume ls
```

Everything should be clean.

---

## Checklist

Do not move to Kubernetes until every box is checked.

- [ ] I confirmed my local webstore-api image existed before starting
- [ ] I tagged it correctly as `YOUR_DOCKERHUB_USERNAME/webstore-api:1.0` and pushed it
- [ ] I verified the push on Docker Hub in the browser — the `1.0` tag was visible
- [ ] I deleted the local image and pulled it back from Docker Hub — it ran correctly
- [ ] I wrote `docker-compose.yml` from scratch using postgres:15 and adminer — I did not copy-paste it
- [ ] I brought the full system up with `docker compose up -d` and hit both browser endpoints
- [ ] I logged into adminer using `webstore-db` as the server hostname — Docker DNS resolved it
- [ ] I inspected the auto-created network and confirmed all three containers were on it
- [ ] I broke the DB_HOST with a wrong name and read the connection error in the logs
- [ ] I produced a port conflict error by running a container on 8080 before Compose started
- [ ] I removed `depends_on` and observed startup order problems in the logs
- [ ] I ran `docker compose down` and confirmed containers and network were removed cleanly

---
# SOURCE: 04. Docker – Containerization/docker-labs/README.md
---

[Home](../README.md) |
[Labs Index](./README.md) |
[Lab 01](./01-containers-portbinding-lab.md) |
[Lab 02](./02-networking-volumes-lab.md) |
[Lab 03](./03-build-layers-lab.md) |
[Lab 04](./04-registry-compose-lab.md)

---

# Docker Labs

Hands-on sessions for every topic in the Docker notes.

Each lab builds on the previous one. Do them in order.
Do not move to the next lab until the checklist at the bottom is fully checked.

---

## The Project Thread

These four labs containerize the webstore from scratch — the same project that ran on a Linux server and was versioned with Git. By Lab 04 you have the entire three-tier webstore running from a single `docker compose up` command, with the API image pushed to Docker Hub and ready for Kubernetes.

| Lab | Where the webstore is | What you do |
|---|---|---|
| [Lab 01](./01-containers-portbinding-lab.md) | Not yet containerized | Pull images, run nginx as webstore-frontend, bind ports, debug containers |
| [Lab 02](./02-networking-volumes-lab.md) | Frontend running | Wire webstore-api to webstore-db on a Docker network, persist postgres data in a volume |
| [Lab 03](./03-build-layers-lab.md) | Network and storage wired | Build the webstore-api image from a Dockerfile, optimize layers, use multi-stage builds |
| [Lab 04](./04-registry-compose-lab.md) | Image built | Push to Docker Hub, write docker-compose.yml, bring the full three-tier webstore up in one command |

---

## Labs

| Lab | Topics | Notes |
|---|---|---|
| [Lab 01](./01-containers-portbinding-lab.md) | Containers + Port Binding | [03](../03-docker-containers/README.md) · [04](../04-docker-port-binding/README.md) |
| [Lab 02](./02-networking-volumes-lab.md) | Networking + Volumes | [05](../05-docker-networking/README.md) · [06](../06-docker-volumes/README.md) |
| [Lab 03](./03-build-layers-lab.md) | Layers + Build + Dockerfile | [07](../07-docker-layers/README.md) · [08](../08-docker-build-dockerfile/README.md) |
| [Lab 04](./04-registry-compose-lab.md) | Registry + Compose | [09](../09-docker-registry/README.md) · [10](../10-docker-compose/README.md) |

---
# SOURCE: 04. Docker – Containerization/README.md
---

<p align="center">
  <img src="../../assets/docker-banner.svg" alt="docker" width="100%"/>
</p>

[← devops-runbook](../../README.md) |
[History & Motivation](./01-history-and-motivation/README.md) |
[Technology Overview](./02-technology-overview/README.md) |
[Containers](./03-docker-containers/README.md) |
[Port Binding](./04-docker-port-binding/README.md) |
[Networking](./05-docker-networking/README.md) |
[Volumes](./06-docker-volumes/README.md) |
[Layers](./07-docker-layers/README.md) |
[Build](./08-docker-build-dockerfile/README.md) |
[Registry](./09-docker-registry/README.md) |
[Compose](./10-docker-compose/README.md) |
[Interview](./99-interview-prep/README.md)

---

A fundamentals-first learning path for Docker — containers, networking, volumes, images, and Compose — built around one real app with no tutorial noise.

---

## Prerequisites

**Complete first:** [03. Networking – Foundations](../03.%20Networking%20–%20Foundations/README.md)

Specifically, before starting Docker you should understand:
- How bridges and routing work (file 04) — Docker bridge is a virtual switch
- NAT and port forwarding (file 07) — Docker `-p` flag creates iptables DNAT rules
- DNS resolution (file 08) — Docker has an embedded DNS server at `127.0.0.11`

Without these, Docker networking will feel like magic. Magic breaks in production.

---

## The Running Example

Every note, every lab, every command uses the same 3-tier app:

| Service | Image | Port |
|---|---|---|
| webstore-frontend | nginx:1.24 | 80 |
| webstore-api | nginx:1.24 (then custom) | 8080 |
| webstore-db | postgres:15 | 5432 |
| adminer | adminer | 8081 (dev only) |

By the end, this app is containerized, networked, persisted, built from a Dockerfile, pushed to a registry, and running with a single Compose command.

---

## Where You Take the Webstore

You arrive at Docker with the webstore running on a Linux server and version-controlled in Git. It works on your machine. It does not work anywhere else without manual setup.

You leave Docker with the webstore as three container images — webstore-frontend, webstore-api, webstore-db — running from a single `docker compose up`. The API image is pushed to Docker Hub tagged as `v1.0`. That tag is what Kubernetes pulls when you get there.

---

## Phases

| Phase | Topics | Lab |
|---|---|---|
| 0 — Foundation | [01 History & Motivation](./01-history-and-motivation/README.md) · [02 Technology Overview](./02-technology-overview/README.md) | No lab |
| 1 — Running Containers | [03 Docker Containers](./03-docker-containers/README.md) · [04 Port Binding](./04-docker-port-binding/README.md) | [Lab 01](./docker-labs/01-containers-portbinding-lab.md) |
| 2 — Data & Networks | [05 Networking](./05-docker-networking/README.md) · [06 Volumes](./06-docker-volumes/README.md) | [Lab 02](./docker-labs/02-networking-volumes-lab.md) |
| 3 — Building Images | [07 Layers](./07-docker-layers/README.md) · [08 Build & Dockerfile](./08-docker-build-dockerfile/README.md) | [Lab 03](./docker-labs/03-build-layers-lab.md) |
| 4 — Ship & Operate | [09 Registry](./09-docker-registry/README.md) · [10 Compose](./10-docker-compose/README.md) | [Lab 04](./docker-labs/04-registry-compose-lab.md) |

---

## Labs

| Lab | Covers |
|---|---|
| [Lab 01](./docker-labs/01-containers-portbinding-lab.md) | Pull images, run containers, port binding, debug, safe delete |
| [Lab 02](./docker-labs/02-networking-volumes-lab.md) | Docker networks, DNS between containers, iptables DNAT proof, named volumes, bind mounts |
| [Lab 03](./docker-labs/03-build-layers-lab.md) | Layer inspection, cache behavior, Dockerfile ordering, .dockerignore, multi-stage builds |
| [Lab 04](./docker-labs/04-registry-compose-lab.md) | Push to Docker Hub, tagging strategy, pull and verify, write and run docker-compose.yml |

---

## Interview Prep

→ [99-interview-prep](./99-interview-prep/README.md) — Image vs Container · Containers vs VMs · Namespaces · cgroups · Lifecycle · Port Binding · Networking · Layers · Caching · Volumes · Dockerfile · Registry · Compose

---

## How to Use This

Read phases in order. Each one builds on the previous.
After each phase do the lab before moving on.
The checklist at the end of every lab is not optional.

---

## What You Can Do After This

- Run any containerized service on your laptop or a server
- Wire multi-container apps together with Docker networks and DNS
- Persist data correctly with named volumes
- Write production-ready Dockerfiles with correct layer ordering
- Build multi-stage images that are small and safe
- Push images to a registry and pull them anywhere
- Bring up the full webstore stack with one command

---

## What Comes Next

→ [05. Kubernetes – Orchestration](../05.%20Kubernetes%20–%20Orchestration/README.md)

Kubernetes orchestrates containers. Everything you built here — images, tags, port mappings, environment variables — is what Kubernetes reads from your manifests. Docker is the prerequisite, not a stepping stone.
