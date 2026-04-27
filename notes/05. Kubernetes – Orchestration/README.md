<p align="center">
  <img src="../../assets/kubernetes-banner.svg" alt="kubernetes" width="100%"/>
</p>

[← devops-runbook](../../README.md) | [Setup](./00-setup/README.md) | [Architecture](./01-architecture/README.md) | [YAML & Pods](./02-yaml-pods/README.md) | [Deployments](./03-deployments/README.md) | [Networking](./03.5-networking/README.md) | [State](./04-state/README.md) | [Troubleshooting](./05-troubleshooting/README.md) | [Probes](./06-probes/README.md) | [Namespaces](./07-namespaces/README.md) | [kubectl Reference](./08-kubectl-reference/README.md) | [Interview Prep](./99-interview-prep/README.md)

---

A phase-by-phase learning path for Kubernetes — from k3s on EC2 to production on AWS EKS.
Every tool and concept here transfers directly from a single EC2 instance to a 1,000-node cluster.

---

## Why Kubernetes — and Why Not Docker Swarm or Nomad

Docker Compose runs multi-container apps on one machine. That is its ceiling. When the machine goes down, every container goes down with it. When traffic spikes, you scale manually. When you deploy a new version, there is downtime.

Kubernetes solves all of this. It runs your containers across multiple machines, restarts them when they crash, rolls out new versions without dropping traffic, and scales up or down based on load — automatically, without intervention.

Docker Swarm ships with Docker and is simpler to learn, but it is not what the industry uses. Nomad is flexible, but its adoption is a fraction of Kubernetes. EKS, GKE, and AKS are all managed Kubernetes. Every DevOps job posting that mentions container orchestration means Kubernetes. Learning Swarm or Nomad first is a detour.

---

## Prerequisites

**Complete first:** [04. Docker – Containerization](../04.%20Docker%20–%20Containerization/README.md)

Kubernetes orchestrates containers. If you do not understand what a container is, how images work, how Docker networking functions, and how a Dockerfile builds an image — Kubernetes will be confusing from the first YAML file. The concepts do not repeat here, they are assumed.

---

## The Running Example — ShopStack

Every phase, every manifest, every command is built around ShopStack — the same 5-service app you ran on Docker Compose in Week 1.

| Service | Image | Port |
|---|---|---|
| frontend | `akhiltejadoosari/shopstack-frontend:1.0` | 80 |
| api | `akhiltejadoosari/shopstack-api:1.0` | 8080 |
| worker | `akhiltejadoosari/shopstack-worker:1.0` | — |
| db | `postgres:15-alpine` | 5432 |
| adminer | `adminer` | 8080 |

---

## Where You Take ShopStack

You arrive at Kubernetes with ShopStack running as 5 containers on one EC2 instance, brought up with `docker compose up`.

You leave with ShopStack running on a real k3s cluster — self-healing Deployments for all tiers, Postgres persisted to a PersistentVolumeClaim, credentials stored in Secrets, non-sensitive config in ConfigMaps, readiness probes preventing traffic before the database is ready, and the full stack accessible from a browser at `http://YOUR_EC2_IP:30080`.

The same manifests you write for k3s deploy to EKS in Week 5. That is the point of writing them correctly from the start.

---

## Phases

| # | Phase | Topics |
|---|---|---|
| 00 | [Setup](./00-setup/README.md) | k3s on EC2, kubeconfig on Mac, kubectl connection, daily opening sequence |
| 01 | [Architecture](./01-architecture/README.md) | Control Plane, etcd, Scheduler, Controller Manager, Worker Nodes, request flow, desired state |
| 02 | [YAML & Pods](./02-yaml-pods/README.md) | YAML syntax, 4 pillars of a manifest, Pods, Labels, Selectors, debug loop |
| 03 | [Deployments](./03-deployments/README.md) | ReplicaSets, Deployments, rolling updates, rollbacks, scaling |
| 03.5 | [Networking](./03.5-networking/README.md) | Services (ClusterIP, NodePort, LoadBalancer), Kubernetes DNS, port fields |
| 04 | [State & Config](./04-state/README.md) | PersistentVolumeClaims, ConfigMaps, Secrets, base64 encoding |
| 05 | [Troubleshooting](./05-troubleshooting/README.md) | CrashLoopBackOff, kubectl describe, logs, exec, get events, ShopStack break sequence |
| 06 | [Probes](./06-probes/README.md) | Liveness probe, readiness probe, the difference, httpGet vs tcpSocket |
| 07 | [Namespaces](./07-namespaces/README.md) | What namespaces are, the four built-in namespaces, DNS across namespaces |
| 08 | [kubectl Reference](./08-kubectl-reference/README.md) | Full command combat sheet — every command with ShopStack example |
| 99 | [Interview Prep](./99-interview-prep/README.md) | 10 questions, toggle answers, rapid-fire round |

---

## What You Can Do After This

- Write production-quality Kubernetes manifests from scratch without documentation
- Explain what happens inside the cluster when you run `kubectl apply`
- Deploy, update, and roll back applications with zero downtime
- Wire multi-tier applications together using Services and Kubernetes DNS
- Persist database data correctly using PVCs
- Store credentials safely using Secrets and config using ConfigMaps
- Gate traffic with readiness probes so broken Pods never receive requests
- Debug any cluster issue using the full get → describe → logs → exec loop
- Deploy a production workload to AWS EKS (Week 5)

---

## How to Use This

Read phases in order. Each one builds on the previous.
The daily checklist in `devops-journey/` is your hands-on work — these notes are the depth-on-demand layer you open when a concept does not click during a session.

---

## What Comes Next

→ [06. CI-CD – Pipelines & GitOps](../06.%20CI-CD%20–%20Pipelines%20%26%20GitOps/README.md)

Kubernetes gives you the cluster. CI-CD automates what you have been doing manually — building images, pushing them, applying manifests. Every `kubectl apply` you ran in these phases becomes a step in a pipeline that runs itself on every code push.
