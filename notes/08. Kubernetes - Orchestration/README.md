[Setup](00-setup/README.md) | [Architecture](01-architecture/README.md) | [YAML & Pods](02-yaml-pods/README.md) | [Deployments](03-deployments/README.md) | [Networking](03.5-networking/README.md) | [State & Config](04-state/README.md) | [Troubleshooting](05-troubleshooting/README.md) | [Cloud & EKS](06-cloud/README.md)

---

# Kubernetes — From Local Cluster to Production

A phase-by-phase learning path for Kubernetes, built for real DevOps work.
Every tool and concept here transfers directly from a Minikube laptop to a
1,000-node AWS EKS cluster — no shortcuts that disappear in production.

Focus:
- build correct mental models before touching commands
- use only job-legal, transferable tooling
- practice with a real running example (ChillSpot) throughout
- develop muscle memory, not fake confidence from watching videos

---

## How to Use This Repository

Read the phases **in order**.

Each phase builds directly on the previous one.
Do not skip phases unless you have already practiced the hands-on actions.
Theory without commands is just reading. Commands without theory is just guessing.

---

## Phase Index

| # | Phase | Topics | Hands-On Action |
|---|-------|--------|-----------------|
| 00 | [Setup](00-setup/README.md) | Job-legal toolkit — Minikube, kubectl, K9s, Helm. What NOT to get attached to. | Install all tools. Run the cold start. Open the K9s cockpit in Tab 2. |
| 01 | [Architecture](01-architecture/README.md) | K8s Intro, Control Plane (API Server, etcd, Scheduler, Controller Manager), Worker Nodes (Kubelet, Kube Proxy). | Run `kubectl get nodes` and `kubectl get pods -n kube-system` to see the Control Plane alive. |
| 02 | [YAML & Pods](02-yaml-pods/README.md) | YAML Syntax (apiVersion, kind, metadata, spec), Pods (the smallest unit), Labels and Selectors. | Write the webapp Pod in a `.yaml` file and run `kubectl apply -f`. |
| 03 | [Deployments](03-deployments/README.md) | ReplicaSet & Self-Healing, Deployments, Rolling Updates & Rollbacks, Scaling, Multi-Container Pods. | Create a Deployment with 3 replicas. Delete one Pod manually and watch it self-heal in K9s. |
| 03.5 | [Networking](03.5-networking/README.md) | Services (ClusterIP, NodePort, LoadBalancer), Sidecar Pattern, Namespaces. | Compare NodePort vs. LoadBalancer using the webappsvc example and `minikube service`. |
| 04 | [State & Config](04-state/README.md) | Persistent Volumes (PV), Claims (PVC), ConfigMaps, Secrets. | Deploy a database (MariaDB) using a Secret for the password and a PVC for storage. |
| 05 | [Troubleshooting](05-troubleshooting/README.md) | K8s Probes (Liveness/Readiness), Jobs & CronJobs, DaemonSet, describe & logs. | Intentionally break a Pod (wrong image name) and use `kubectl describe` to find the error. |
| 06 | [Cloud & EKS](06-cloud/README.md) | AWS EKS, Ingress Controller, HPA, Helm, ArgoCD, Prometheus, Grafana, EFK, Blue-Green Deployment. | Build your EKS cluster on AWS and automate it using ArgoCD and Helm. |

---

## What You Should Be Able to Do After This

By the end of this repository, you should be able to:

- explain what Kubernetes is and why Docker alone is not enough
- read and write YAML manifests without guessing
- deploy, scale, and roll back an application
- expose an app to the network using the right Service type
- store secrets and config data correctly
- debug a broken Pod using `describe`, `logs`, and `events`
- build and manage a production cluster on AWS EKS

If you can do these without memorizing commands, this repository has done its job.

---

## The Non-Negotiable Daily Habit

Every session, before writing a single line of YAML:

```bash
open -a Docker && sleep 10 && docker version
minikube start
kubectl get nodes
kubectl get pods -A
# Tab 2 → k9s
```

Every session, before closing:

```bash
minikube stop
```

---

## Tools Used Throughout

| Tool | Purpose |
|------|---------|
| `kubectl` | Primary CLI for all cluster operations |
| `k9s` | Live cluster monitor — always open in Tab 2 |
| `minikube` | Local single-node cluster for all practice |
| `helm` | Package manager — installs complex apps with one command |
| `kubectx` | Switch between clusters (Minikube ↔ EKS) |
| `vi` | Write and edit YAML manifests in the terminal |
| `eksctl` | Create and manage EKS clusters on AWS |

---

## What NOT to Get Attached To

These are Minikube-only shortcuts. They do not exist in production:

| Minikube shortcut | Production replacement |
|---|---|
| `minikube dashboard` | K9s, Lens, or the AWS Console |
| `minikube service` | LoadBalancers or Ingress Controllers |
| `minikube mount` | AWS EBS or EFS |

---

## Running Example — ChillSpot

Throughout every phase, a fictional containerized streaming platform called
**ChillSpot** serves as the practical example. Every manifest, every Service,
every Secret is built around ChillSpot — so concepts always have a concrete
anchor, not just abstract YAML.

---

## Credits & Acknowledgements

This repository is a derivative learning work, rebuilt from scratch with a
fundamentals-first, mental-model-driven structure.

Reference material and inspiration:

- **TechWorld with Nana** — Kubernetes Tutorial for Beginners (YouTube)
- **Kunal Kushwaha** — Complete Kubernetes Course (YouTube)
- **Official Kubernetes Documentation** — kubernetes.io/docs

All explanations, sequencing, and notes have been rewritten and reorganized to
match my own learning style and goals.

---

*Start with [00 — Setup](00-setup/README.md) →*
