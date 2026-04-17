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

**What this does:**
- `-v webstore-db-data:/var/lib/postgresql/data` → creates volume `webstore-db-data` and mounts it to PostgreSQL's data directory
- PostgreSQL writes to `/var/lib/postgresql/data`
- Data actually goes to the `webstore-db-data` volume
- If you delete the container and create a new one with the same volume, **all data is still there**

**Verification flow:**

| Step | Command | What happens |
|---:|---|---|
| 1 | Run webstore-db with volume | `docker run -d --name webstore-db -v webstore-db-data:/var/lib/postgresql/data -e POSTGRES_DB=webstore -e POSTGRES_USER=admin -e POSTGRES_PASSWORD=secret postgres:15` | Container starts, volume created |
| 2 | Connect and create data | `docker exec -it webstore-db psql -U admin -d webstore` | Enter PostgreSQL shell |
| 3 | Insert test data | `CREATE TABLE products (id SERIAL, name TEXT);` then `INSERT INTO products (name) VALUES ('Widget');` | Data written |
| 4 | Exit | `\q` | Back to host |
| 5 | Stop and delete container | `docker stop webstore-db` then `docker rm webstore-db` | Container gone |
| 6 | Start new container with same volume | `docker run -d --name webstore-db -v webstore-db-data:/var/lib/postgresql/data -e POSTGRES_DB=webstore -e POSTGRES_USER=admin -e POSTGRES_PASSWORD=secret postgres:15` | Fresh container, same volume |
| 7 | Check if data survived | `docker exec -it webstore-db psql -U admin -d webstore -c "SELECT * FROM products;"` | **Data still exists** ✅ |

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
