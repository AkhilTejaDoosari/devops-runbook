[← devops-runbook](../../README.md) | [Setup](../00-setup/README.md) | [Architecture](../01-architecture/README.md) | [YAML & Pods](../02-yaml-pods/README.md) | [Deployments](../03-deployments/README.md) | [Networking](../03.5-networking/README.md) | [State & Config](../04-state/README.md) | [Troubleshooting](../05-troubleshooting/README.md) | [CI-CD](../06-cicd/README.md) | [Observability](../07-observability/README.md) | [Cloud & EKS](../08-cloud/README.md)

# 00 — The Professional Local Setup

## What This File Is About

This guide covers the "job-legal" toolkit required to run a Kubernetes cluster on a MacBook Air. The goal is to use tools that are transferable from a local laptop to a 1,000-node AWS EKS cluster — no Minikube-only shortcuts that disappear in production.

---

## Table of Contents

1. [The Transferable CLI Toolkit](#1-the-transferable-cli-toolkit)
2. [What NOT to Get Attached To](#2-what-not-to-get-attached-to)
3. [Installation — MacBook Air](#3-installation--macbook-air)
4. [The Daily DevOps Cockpit Workflow](#4-the-daily-devops-cockpit-workflow)
5. [Session Management — To Close or Not to Close](#5-session-management--to-close-or-not-to-close)

---

## 1. The Transferable CLI Toolkit

These tools are platform-agnostic. If `kubectl` works on Minikube, it works on EKS.

| Tool | Why it's a Win | How it helps in a real job |
|---|---|---|
| **K9s** | A terminal UI skin for `kubectl` | In an incident, you can see failing Pods and logs 10x faster than typing commands |
| **Helm** | The Package Manager for K8s | 99% of companies use Helm to install apps like databases or monitoring tools |
| **kubectx** | A script to switch between clusters | Essential for switching from Development to Production clusters safely |

---

## 2. What NOT to Get Attached To

To stay cloud-ready, recognize that Minikube-only shortcuts do not exist in the real world:

| Minikube Shortcut | What replaces it in production |
|---|---|
| `minikube dashboard` | K9s, Lens, or the Cloud Console |
| `minikube service` | LoadBalancers or Ingress Controllers |
| `minikube mount` | AWS EBS or EFS for persistent storage |

---

## 3. Installation — MacBook Air

Use Homebrew to keep all tools updatable with a single `brew upgrade`.

```bash
# The Essentials
brew install minikube
brew install kubernetes-cli
brew install derailed/k9s/k9s

# The Package Manager (used from Phase 6 onward)
brew install helm
```

---

## 4. The Daily DevOps Cockpit Workflow

In a professional environment you don't click icons — you use the terminal to verify your environment is healthy before writing a single line of YAML.

### Step A — The Cold Start (Tab 1)

```bash
# 1. Launch Docker Engine
open -a Docker

# 2. Wait ~10 seconds, then verify Engine is up
#    You should see both a Client and Server version
docker version

# 3. Wake the cluster
minikube start

# 4. Audit the state
kubectl get nodes
kubectl get pods -A
```

Verify the node status is `Ready` and there are no failing Pods before proceeding.

### Step B — The Multi-Tab Cockpit

Never work in a single terminal window. The professional layout is two tabs.

1. Press `Command + T` to open a new tab
2. In the new tab, launch your live monitor:

```bash
k9s
```

| Tab | Purpose |
|---|---|
| **Tab 1** | Your Workstation — running `vi`, `kubectl`, `helm` |
| **Tab 2** | Your Live Feed — monitoring Pods and Deployments in K9s |

---

## 5. Session Management — To Close or Not to Close

Kubernetes is a heavy system. How you end your session directly affects your Mac's battery and RAM.

**Stepping away for a short break?**
Do nothing. Leave Minikube running in the background. It will be ready when you return.

**Done for the day?**
Hibernate the cluster to reclaim memory:

```bash
# 1. Exit K9s
Ctrl + C

# 2. Stop the cluster
minikube stop

# 3. Close Docker Desktop
```

**Cluster feels glitchy or messy?**
Full reset:

```bash
minikube delete
minikube start
```

This wipes the cluster state completely and starts clean.

---

→ Ready to practice? [Go to Lab 00](../k8s-labs/00-setup-lab.md)
