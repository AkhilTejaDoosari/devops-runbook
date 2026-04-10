<p align="center">
  <img src="../../assets/kubernetes-banner.svg" alt="kubernetes" width="100%"/>
</p>

[← devops-runbook](../../README.md)

---

A phase-by-phase learning path for Kubernetes — from local cluster to production on AWS EKS.
Every tool and concept here transfers directly from a Minikube laptop to a 1,000-node cluster.

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

## The Running Example

Every phase, every manifest, every command is built around the webstore app.

| Service | Image | Port |
|---|---|---|
| webstore-frontend | nginx:1.24 | 80 |
| webstore-api | nginx:1.24 (placeholder → custom) | 8080 |
| webstore-db | postgres:15 | 5432 |

---

## Where You Take the Webstore

You arrive at Kubernetes with the webstore running as three Docker containers on your laptop, brought up with `docker compose up`.

You leave with the webstore running on a real cluster — self-healing Deployments for all three tiers, postgres persisted to a PersistentVolumeClaim, credentials stored in Secrets, non-sensitive config in ConfigMaps, readiness probes preventing traffic before the database is ready, and the full stack deployed to AWS EKS in the final phase.

The same manifests you write for Minikube deploy to EKS. That is the point of writing them correctly from the start.

---

## Phases

| # | Phase | Topics | Lab |
|---|---|---|---|
| 00 | [Setup](./00-setup/README.md) | Job-legal toolkit — Minikube, kubectl, K9s, Helm, kubectx | [Lab 00](./k8s-labs/00-setup-lab.md) |
| 01 | [Architecture](./01-architecture/README.md) | Control Plane, etcd, Scheduler, Controller Manager, Worker Nodes, request flow | [Lab 01](./k8s-labs/01-architecture-lab.md) |
| 02 | [YAML & Pods](./02-yaml-pods/README.md) | YAML syntax, 4 pillars of a manifest, Pods, Labels, Selectors | [Lab 02](./k8s-labs/02-yaml-pods-lab.md) |
| 03 | [Deployments](./03-deployments/README.md) | ReplicaSets, Deployments, rolling updates, rollbacks, scaling | [Lab 03](./k8s-labs/03-deployments-lab.md) |
| 03.5 | [Networking](./03.5-networking/README.md) | Services (ClusterIP, NodePort, LoadBalancer), kube-dns, Sidecar pattern, Namespaces | [Lab 03.5](./k8s-labs/03.5-networking-lab.md) |
| 04 | [State & Config](./04-state/README.md) | PersistentVolumes, PVCs, StorageClass, ConfigMaps, Secrets | [Lab 04](./k8s-labs/04-state-lab.md) |
| 05 | [Troubleshooting](./05-troubleshooting/README.md) | Liveness, Readiness, Startup probes, Jobs, CronJobs, DaemonSets, full debug loop | [Lab 05](./k8s-labs/05-troubleshooting-lab.md) |
| 06 | [Cloud & EKS](./06-cloud/README.md) | eksctl, EBS CSI driver, ECR, LoadBalancer Services on EKS, Ingress Controller, HPA | [Lab 06](./k8s-labs/06-cloud-lab.md) |

---

## Labs

| Lab | Topics Covered | What You Practice |
|---|---|---|
| [Lab 00](./k8s-labs/00-setup-lab.md) | Setup | Verify every tool, cold start drill, K9s cockpit, yamllint habit |
| [Lab 01](./k8s-labs/01-architecture-lab.md) | Architecture | Find every control plane component running live, map it to the theory |
| [Lab 02](./k8s-labs/02-yaml-pods-lab.md) | YAML & Pods | Write manifests from scratch, apply, describe, debug the full loop |
| [Lab 03](./k8s-labs/03-deployments-lab.md) | Deployments | All 3 webstore tiers as Deployments, self-healing proof, rolling update, rollback, scale |
| [Lab 03.5](./k8s-labs/03.5-networking-lab.md) | Networking | Wire the tiers with Services, expose frontend, test kube-dns, enforce namespace isolation |
| [Lab 04](./k8s-labs/04-state-lab.md) | State & Config | PVC for webstore-db, Secret for credentials, ConfigMap for non-sensitive config |
| [Lab 05](./k8s-labs/05-troubleshooting-lab.md) | Troubleshooting | Readiness probe on webstore-api, CronJob DB backup, DaemonSet log collector, full debug drill |
| [Lab 06](./k8s-labs/06-cloud-lab.md) | Cloud & EKS | Create EKS cluster with eksctl, migrate webstore manifests, LoadBalancer Service, ECR |

---

## What You Can Do After This

- Write production-quality Kubernetes manifests from scratch without documentation
- Explain what happens inside the cluster when you run `kubectl apply`
- Deploy, update, and roll back applications with zero downtime
- Wire multi-tier applications together using Services and kube-dns
- Persist database data correctly using PVCs and StorageClasses
- Store credentials safely using Secrets and config using ConfigMaps
- Gate traffic with readiness probes so broken Pods never receive requests
- Debug any cluster issue using the full get → describe → logs → exec loop
- Deploy a production workload to AWS EKS

---

## How to Use This

Read phases in order. Each one builds on the previous.
After each phase do the lab before moving on.
The checklist at the end of every lab is not optional.

---

## What Comes Next

→ [06. CI-CD – Pipelines & GitOps](../06.%20CI-CD%20–%20Pipelines%20%26%20GitOps/README.md)

Kubernetes gives you the cluster. CI-CD automates what you have been doing manually — building images, pushing them, applying manifests. Every `kubectl apply` you ran in these labs becomes a step in a pipeline that runs itself on every code push.
