[Setup](00-setup/README.md) | [Architecture](01-architecture/README.md) | [YAML & Pods](02-yaml-pods/README.md) | [Deployments](03-deployments/README.md) | [Networking](03.5-networking/README.md) | [State & Config](04-state/README.md) | [Troubleshooting](05-troubleshooting/README.md) | [CI-CD](06-cicd/README.md) | [Observability](07-observability/README.md) | [Cloud & EKS](08-cloud/README.md)

---

# Kubernetes — From Local Cluster to Production

A phase-by-phase learning path for Kubernetes, built for real DevOps work.
Every tool and concept here transfers directly from a Minikube laptop to a
1,000-node AWS EKS cluster — no shortcuts that disappear in production.

Focus:
- build correct mental models before touching commands
- use only job-legal, transferable tooling
- practice with a real 3-tier running example (webstore) throughout
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
| 02 | [YAML & Pods](02-yaml-pods/README.md) | YAML Syntax (apiVersion, kind, metadata, spec), Pods (the smallest unit), Labels and Selectors. | Write the webstore Pod in a `.yaml` file and run `kubectl apply -f`. |
| 03 | [Deployments](03-deployments/README.md) | ReplicaSet & Self-Healing, Deployments, Rolling Updates & Rollbacks, Scaling. | Create a Deployment with 3 replicas. Delete one Pod manually and watch it self-heal in K9s. |
| 03.5 | [Networking](03.5-networking/README.md) | Services (ClusterIP, NodePort, LoadBalancer), Sidecar Pattern, Namespaces. | Compare NodePort vs. LoadBalancer using the webstore example and `minikube service`. |
| 04 | [State & Config](04-state/README.md) | Persistent Volumes (PV), Claims (PVC), ConfigMaps, Secrets. | Deploy webstore-db using a Secret for the password and a PVC for storage. |
| 05 | [Troubleshooting](05-troubleshooting/README.md) | K8s Probes (Liveness/Readiness), Jobs & CronJobs, DaemonSets, describe & logs. | Intentionally break a Pod (wrong image name) and use `kubectl describe` to find the error. |
| 06 | [CI-CD](06-cicd/README.md) | GitHub Actions pipeline, ArgoCD GitOps, automated deploys to the cluster. | Build a GitHub Actions workflow that pushes webstore-api image and ArgoCD syncs it to the cluster. |
| 07 | [Observability](07-observability/README.md) | Prometheus metrics, Grafana dashboards, alerting rules. | Deploy Prometheus + Grafana via Helm, build a webstore dashboard, set an alert. |
| 08 | [Cloud & EKS](08-cloud/README.md) | AWS EKS, Ingress Controller, HPA, eksctl, production cluster setup. | Build your EKS cluster on AWS and deploy the full webstore stack to it. |

---

## Labs

| Lab | File |
|-----|------|
| 00 — Setup | [k8s-labs/00-setup-lab.md](k8s-labs/00-setup-lab.md) |
| 01 — Architecture | [k8s-labs/01-architecture-lab.md](k8s-labs/01-architecture-lab.md) |
| 02 — YAML & Pods | [k8s-labs/02-yaml-pods-lab.md](k8s-labs/02-yaml-pods-lab.md) |
| 03 — Deployments | [k8s-labs/03-deployments-lab.md](k8s-labs/03-deployments-lab.md) |
| 03.5 — Networking | [k8s-labs/03.5-networking-lab.md](k8s-labs/03.5-networking-lab.md) |
| 04 — State & Config | [k8s-labs/04-state-lab.md](k8s-labs/04-state-lab.md) |
| 05 — Troubleshooting | [k8s-labs/05-troubleshooting-lab.md](k8s-labs/05-troubleshooting-lab.md) |
| 06 — CI-CD | [k8s-labs/06-cicd-lab.md](k8s-labs/06-cicd-lab.md) |
| 07 — Observability | [k8s-labs/07-observability-lab.md](k8s-labs/07-observability-lab.md) |
| 08 — Cloud & EKS | [k8s-labs/08-cloud-lab.md](k8s-labs/08-cloud-lab.md) |

---

## What You Should Be Able to Do After This

By the end of this repository, you should be able to:

- explain what Kubernetes is and why Docker alone is not enough
- read and write YAML manifests without guessing
- deploy, scale, and roll back an application
- expose an app to the network using the right Service type
- store secrets and config data correctly
- debug a broken Pod using `describe`, `logs`, and `events`
- automate deployments using GitHub Actions and ArgoCD
- monitor a live cluster using Prometheus and Grafana
- build and manage a production cluster on AWS EKS

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
| `helm` | Package manager — installs Prometheus, ArgoCD with one command |
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

## Running Example — Webstore

Throughout every phase, a 3-tier e-commerce application called **webstore**
serves as the practical example — a frontend, a backend API, and a database.
Every manifest, every Service, every Secret is built around webstore — so
concepts always have a concrete anchor, not just abstract YAML.

| Service | Image | Port |
|---|---|---|
| webstore-frontend | nginx:1.24 | 80 |
| webstore-api | nginx:1.24 | 8080 |
| webstore-db | mariadb | 3306 |

---

*Start with [00 — Setup](00-setup/README.md) →*
