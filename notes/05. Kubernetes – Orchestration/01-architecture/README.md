[Home](../README.md) | [Setup](../00-setup/README.md) | [Architecture](../01-architecture/README.md) | [YAML & Pods](../02-yaml-pods/README.md) | [Deployments](../03-deployments/README.md) | [Networking](../03.5-networking/README.md) | [State](../04-state/README.md) | [Troubleshooting](../05-troubleshooting/README.md) | [Probes](../06-probes/README.md) | [Namespaces](../07-namespaces/README.md) | [kubectl Reference](../08-kubectl-reference/README.md) | [Interview Prep](../99-interview-prep/README.md)

---

# 01 — Architecture & Why Kubernetes Exists

> **Used in production when:** someone asks why the company uses Kubernetes instead of just Docker Compose, or you need to explain what the control plane is doing when a Pod mysteriously comes back after you deleted it.

---

## What this is

Before touching a single command, you need the mental model. This file covers why Kubernetes exists, what problem it solves that Docker Compose cannot, and how every component in the architecture communicates — so that when you run `kubectl apply`, you know exactly what happens under the hood.

---

## How it fits the stack

```
Week 1 — Docker Compose
  ShopStack ran as 5 containers on one EC2.
  You typed docker compose up. You got a stack.
  One machine. One command. Simple.

Week 2 — Kubernetes
  ShopStack runs as Pods managed by Deployments,
  wired by Services, with state in PVCs and Secrets.
  One cluster. Manifests declare desired state.
  Kubernetes enforces it 24/7 without your involvement.
```

The app is identical. The infrastructure layer underneath it changed.

---

## 1. The core problem — what Docker Compose cannot solve

Docker Compose is excellent for running a stack on one machine. ShopStack on Compose works perfectly for development. But Compose has hard limits that appear the moment real traffic hits.

**The nightmare scenario:**

ShopStack goes live. Traffic spikes at 2 AM. The single API container cannot handle the load — requests slow down, some time out. You need more copies of the API running.

With Docker Compose:
- SSH into EC2
- Manually start a second EC2 instance
- Clone the repo
- Start another container
- Put a load balancer in front
- Do this for every service that needs scaling
- Every container crash requires manual restart
- Every deployment requires manual steps on every machine

This is not sustainable. At 5 services it is painful. At 50 it is impossible.

**What Kubernetes solves:**

| Problem | Kubernetes solution |
|---|---|
| Container crashes at 3 AM | Self-healing — detects crash, creates replacement instantly |
| Traffic spike on the API | Scaling — create more Pod replicas to handle the load |
| Deploying a new image | Rolling update — swaps containers one by one, zero downtime |
| Traffic distribution across replicas | Load balancing — Service spreads requests across all healthy Pods |

**ShopStack angle:** The API container is the bottleneck under load — it handles every product query, every order, every health check from the worker. With Kubernetes you declare `replicas: 3` and Kubernetes runs 3 API Pods, load balances across all three, and replaces any that crash — automatically, continuously, without SSH.

---

## 2. The desired state mental model — the aha that makes everything click

This is the single most important concept in Kubernetes. Everything else is an implementation detail.

Kubernetes is not a system that runs commands. It is a system that continuously reconciles reality with your declared intention.

You write a manifest — a YAML file — that says:

```
"I want 3 replicas of the ShopStack API running at all times."
```

Kubernetes stores this as the **desired state**. It then watches **actual state** — what is really running. Every few seconds a control loop runs:

```
Desired state:  3 API replicas
Actual state:   2 API replicas  (one crashed)

Gap detected:   1
Action taken:   create 1 new Pod

Desired state:  3 API replicas
Actual state:   3 API replicas

Gap:            0
Action taken:   nothing
```

This loop never stops. That is why a crashed Pod comes back — not because Kubernetes ran a restart command, but because the controller detected a gap between desired and actual and closed it.

**The rule:** The manifest is not a command. It is a declaration. "This is the world I want." Kubernetes reads it, compares it to what exists, and works to close any gap.

Once this lands, every Kubernetes behaviour makes sense:

| Behaviour | Why it happens |
|---|---|
| Deleted Pod comes back | Deployment detects gap, closes it |
| CrashLoopBackOff | Gap keeps reopening, Kubernetes keeps closing it |
| Rolling update | Kubernetes transitions actual state toward new desired state, Pod by Pod |
| Pod stuck Pending | No node has enough resources to close the gap |

---

## 3. The architecture — control plane and worker nodes

A Kubernetes cluster has two sides: the **control plane** (the brain) and the **worker nodes** (the laborers).

```
                    ┌─────────────────────────────────────────┐
                    │           CONTROL PLANE (Manager)       │
                    │                                         │
  kubectl (CLI) ──▶ │  ┌─────────────┐    ┌────────────────┐  │
                    │  │  API Server │    │      etcd      │  │
  UI / REST    ───▶ │  │(Entry Point)│◀─▶ │  (Source of    │  │
                    │  └──────┬──────┘    │    Truth DB)   │  │
                    │         │           └────────────────┘  │
                    │  ┌──────▼──────┐   ┌────────────────┐   │
                    │  │  Scheduler  │   │   Controller   │   │
                    │  │(Assigns Pod │   │    Manager     │   │
                    │  │  to Node)   │   │(Watches State) │   │
                    │  └─────────────┘   └────────────────┘   │
                    └──────────────┬──────────────────────────┘
                                   │ assigns work
                    ┌──────────────▼──────────────────┐
                    │                                 │
          ┌─────────▼───────┐            ┌────────────▼───────────┐
          │  Worker Node 1  │            │    Worker Node 2       │
          │                 │            │                        │
          │ ┌─────────────┐ │            │ ┌──────────────────┐   │
          │ │   kubelet   │ │            │ │     kubelet      │   │
          │ │(Node Agent) │ │            │ │  (Node Agent)    │   │
          │ └──────┬──────┘ │            │ └────────┬─────────┘   │
          │        │        │            │          │             │
          │ ┌──────▼──────┐ │            │ ┌────────▼─────────┐   │
          │ │  containerd │ │            │ │   containerd     │   │
          │ │ (Runtime) * │ │            │ │   (Runtime) *    │   │
          │ └──────┬──────┘ │            │ └────────┬─────────┘   │
          │        │        │            │          │             │
          │  ┌─────▼──────┐ │            │  ┌───────▼──────────┐  │
          │  │  Pod  Pod  │ │            │  │  Pod   Pod  Pod  │  │
          │  │ [C1]  [C2] │ │            │  │ [C1]  [C1]  [C2] │  │
          │  └────────────┘ │            │  └──────────────────┘  │
          │                 │            │                        │
          │ ┌─────────────┐ │            │ ┌──────────────────┐   │
          │ │  Kube Proxy │ │            │ │   Kube Proxy     │   │
          │ │(Networking) │ │            │ │  (Networking)    │   │
          │ └─────────────┘ │            │ └──────────────────┘   │
          └─────────────────┘            └────────────────────────┘                      
```

> **Your k3s setup:** On your EC2 t3.micro, the control plane and worker node run on the same machine. k3s combines them. On EKS (Week 5), AWS manages the control plane separately and you only see the worker nodes.

---

## 4. Control plane components — the brain

### API Server

The single entry point for everything. Every `kubectl` command you run on your Mac hits the API Server on EC2 first. Every internal component (Scheduler, Controller Manager, kubelet) communicates through the API Server — never directly to each other.

**The gatekeeper rule:** The API Server is the only component that reads from and writes to etcd. Everything else talks to the API Server.

### etcd

A distributed key-value database. The cluster's single source of truth. Every object you create — every Pod, every Deployment, every Service, every Secret — is a record stored in etcd. If etcd is lost, the cluster state is lost.

You never interact with etcd directly. The API Server owns it.

### Scheduler

Watches the API Server for new Pods that have no node assigned yet. Evaluates every worker node's available CPU and RAM. Picks the best fit and writes the assignment back to the API Server.

**The scheduler does not start Pods.** It only decides which node gets them. The kubelet on that node does the actual work.

### Controller Manager

Runs a set of continuous control loops — one per object type. The Deployment controller, the ReplicaSet controller, the Node controller. Each loop watches the API Server for its object type and acts when desired state diverges from actual state.

**The thermostat analogy:** You set the temperature to 3 replicas. The thermostat (Controller Manager) watches the room. A Pod crashes — temperature drops to 2. The thermostat detects the gap and turns on the heat — creates a new Pod. It never stops watching.

---

## 5. Worker node components — the laborers

### kubelet

The node agent. Runs on every worker node. Watches the API Server for Pods assigned to its node. When it sees one, it tells containerd to pull the image and start the container. Reports back to the API Server: Pod is running, Pod crashed, node is healthy.

### containerd

The container runtime. The actual software that pulls images from Docker Hub and starts containers. kubectl and Kubernetes never touch containers directly — containerd does.

> **Note:** You may see Docker mentioned as a Kubernetes runtime in older materials. Docker was deprecated as a Kubernetes runtime in v1.24 (2022). containerd is what Docker itself used under the hood all along. k3s uses containerd directly.

### Kube Proxy

Handles networking rules on the node. Pods are constantly dying and being recreated with new IP addresses. Kube Proxy acts like a dynamic switchboard — it continuously updates the internal routing rules so traffic always reaches the correct, currently-running Pods.

### Pod

The smallest deployable unit in Kubernetes. A wrapper around one or more containers. Kubernetes never runs a naked container — it always wraps it in a Pod first. Every Pod gets its own IP address. That IP dies with the Pod — which is exactly why Services exist (covered in `03.5-networking.md`).

---

## 6. How a request flows — kubectl apply to Pod running

When you run `kubectl apply -f infra/k8s/api-deployment.yaml` from your Mac:

```
Your Mac
 │
 │  kubectl apply -f api-deployment.yaml
 ▼
API Server (EC2)  ──── stores Deployment as "PENDING" ────▶ etcd
 │
 │  Controller Manager detects: desired=2 API pods, current=0
 ▼
Scheduler  ──── evaluates CPU/RAM on EC2 node ────▶ picks the node
 │
 │  writes assignment back to API Server ──▶ etcd updated
 ▼
kubelet (on EC2)  ──── watching API Server, sees its assignment
 │
 │  tells containerd: pull akhiltejadoosari/shopstack-api:1.0
 ▼
containerd  ──── pulls image from Docker Hub, starts container inside Pod
 │
 ▼
Kube Proxy  ──── assigns network rules so Pod can be reached by Services
 │
 ▼
Pod is RUNNING ✅

─────────────── Later, if a Pod crashes ───────────────
Controller Manager  ──── detects drift (desired=2, actual=1)
 │
 │  notifies API Server to create a new Pod
 ▼
Scheduler → kubelet → containerd → Pod RUNNING ✅
```

**The rule that ties it together:** The API Server is the only component that talks to etcd. Everything else talks to the API Server. Every action in the cluster is ultimately a read from or write to etcd via the API Server.

---

## 7. ShopStack — Compose vs Kubernetes side by side

Same app. Different layer underneath.

| ShopStack concept | Docker Compose | Kubernetes |
|---|---|---|
| Run the API | `services: api:` in compose file | `kind: Deployment` with `replicas: 2` |
| API crashes | Stays down until manual restart | Deployment detects gap, creates new Pod |
| Scale the API | Manual: edit compose, restart | `kubectl scale deploy/shopstack-api --replicas=5` |
| API talks to DB | `DB_HOST=db` resolves via Docker DNS | `DB_HOST=db` resolves via Kubernetes DNS (Service name) |
| Expose frontend to browser | `ports: "80:80"` | Service with `type: NodePort` on port 30080 |
| Postgres data persists | `volumes: db-data` in compose | `kind: PersistentVolumeClaim` bound to the db Pod |
| DB password | `POSTGRES_PASSWORD=shopstack_dev` in env | `kind: Secret` injected as env var |

The environment variables your app reads (`DB_HOST`, `DB_PASSWORD`, `DB_NAME`) do not change between Compose and Kubernetes. Only how Kubernetes delivers them changes.

---

## 8. Cluster setup options — where you are now

| Option | What it is | Use case |
|---|---|---|
| **k3s on EC2** | Lightweight K8s on a single VM | Learning — your setup in Week 2 |
| **Kubeadm** | Self-managed multi-node cluster | Full control, you handle everything |
| **EKS** | AWS-managed cluster | Production — your setup in Week 5 |
| **Minikube** | Single-node cluster on your laptop | Learning on a Mac without EC2 — not your setup |

> **Where you are:** k3s on EC2 t3.micro. The control plane and worker node are the same machine. EKS comes in Week 5 — same manifests, different cluster behind `~/.kube/config`.

---

## Final compression

| Concept | Remember it as |
|---|---|
| Why K8s exists | Docker runs containers. K8s manages them at scale so you don't have to |
| Desired state | You declare what you want. K8s watches reality and closes any gap. Always. |
| Control plane | The brain — API Server, etcd, Scheduler, Controller Manager |
| Worker node | The laborer — kubelet, containerd, Kube Proxy, Pods |
| API Server | The single entry point. All components talk through it. Only one that touches etcd. |
| etcd | The database. Cluster's source of truth. API Server owns it. |
| Scheduler | Picks which node gets the Pod. Does not start Pods. |
| Controller Manager | The watchdog. Compares desired to actual. Fixes every gap. |
| kubelet | The node's ears. Receives orders from API Server. Tells containerd what to run. |
| containerd | What actually pulls the image and runs the container. Not Docker. |
| Pod | The smallest thing K8s knows about. Containers live inside Pods. IP dies with the Pod. |
| k3s | Lightweight K8s for learning. Control plane + worker on one machine. Replaced by EKS in production. |

---

## ⚠️ What Breaks

| Symptom | Cause | Fix |
|---|---|---|
| `kubectl apply` succeeds but Pod never appears | Scheduler cannot find a node with enough CPU/RAM | `kubectl describe pod <name>` → read Events → look for `Insufficient cpu` |
| Pod appears then immediately disappears | CrashLoopBackOff — container crashes on start | `kubectl logs <pod>` → read what the container printed before dying |
| Pod stuck in `Pending` forever | No node available, or PVC not bound | `kubectl describe pod <name>` → Events section |
| Deleted a Pod, it came back | A Deployment is managing it — this is correct behaviour | If you want it gone, delete the Deployment, not the Pod |
| Deleted a Pod, it did NOT come back | It was a bare Pod with no Deployment — also correct | Create a Deployment if you want self-healing |

---

## Daily Commands

| What it does | Command | Example |
|---|---|---|
| Confirm node is Ready | `kubectl get nodes` | `kubectl get nodes` |
| Full cluster health scan — all namespaces | `kubectl get pods -A` | `kubectl get pods -A` |
| See control plane components running as Pods | `kubectl get pods -n kube-system` | `kubectl get pods -n kube-system` |
| Full node profile — CPU, RAM, conditions | `kubectl describe node <n>` | `kubectl describe node ip-172-31-14-5` |
| Confirm API Server address and status | `kubectl cluster-info` | `kubectl cluster-info` |
---

→ **Interview questions for this topic:** `99-interview-prep.md` — What is Kubernetes? What is a Pod? What is the control plane? What does kubectl apply do?

→ Next: [02 — YAML & Pods](./02-yaml-pods.md)
