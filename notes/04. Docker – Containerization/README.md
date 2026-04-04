<p align="center">
  <img src="../../assets/docker-banner.svg" alt="docker" width="100%"/>
</p>

[← devops-runbook](../../README.md)

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
| webstore-api | nginx:1.24 (then custom) | 8080 |
| webstore-db | mongo | 27017 |
| mongo-express | mongo-express | 8081 |

By the end, this app is containerized, networked, persisted, built from a Dockerfile, pushed to a registry, and running with a single Compose command.

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
| [Lab 03](./docker-labs/03-build-layers-lab.md) | Layer inspection, cache behavior, Dockerfile ordering, .dockerignore |
| [Lab 04](./docker-labs/04-registry-compose-lab.md) | Push to Docker Hub, pull and verify, write and run docker-compose.yml |

---

## How to Use This

Read phases in order. Each one builds on the previous.  
After each phase do the lab before moving on.  
The checklist at the end of every lab is not optional.

---

## What You Can Do After This

- Explain what a container actually is and how Linux makes it work
- Run any service in a container without installing it on your host
- Connect multi-container apps over a Docker network using DNS names
- Persist data correctly so it survives container deletion
- Write a Dockerfile from scratch with correct layer ordering
- Build, tag, and push images to a registry
- Bring up a full multi-container system with one command

---

## What Comes Next

→ [05. Kubernetes – Orchestration](../05.%20Kubernetes%20–%20Orchestration/README.md)

Docker runs containers on one machine. Kubernetes manages containers across many machines — with self-healing, rolling updates, and auto-scaling. Everything you learned about containers, networking, and images applies directly.
