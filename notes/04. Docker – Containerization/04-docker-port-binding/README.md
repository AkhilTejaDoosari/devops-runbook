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

# 05. Docker Port Binding

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
`0.0.0.0:8080->3000/tcp`  
```
It means the mapping is active and "listening" on all your laptop's network interfaces.  

## **6) Debug in 30 Seconds**

If the app is not loading:

1. **Check Ports**: Run `docker ps`. If the port isn't listed, you forgot `-p`.
2. **Check App**: Run `docker logs <container_id>`.   
If the port mapping exists but it fails, your app inside the container crashed or isn't listening on the right internal port.

## **7) One-Line Definition**

Port binding maps a container’s internal port to a host machine port so the application can be accessed by the outside world.

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
│      │    │                                                    │              │
│      │  ┌─▼──┐                                                 │              │
│      │  │ ns │                                                 │              │
│      │  │app │                                                 │              │
│      │  │:3000                                                 │              │
│      │  └─────┘                                                │              │
│      │ (Target)                                                │              │
│      └─────────────────────────────────────────────────────────┘              │
└───────────────────────────────────────────────────────────────────────────────┘

```

→ Ready to practice? [Go to Lab 01](../docker-labs/01-containers-portbinding-lab.md)
