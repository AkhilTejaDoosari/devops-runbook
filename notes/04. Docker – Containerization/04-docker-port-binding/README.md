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
