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
