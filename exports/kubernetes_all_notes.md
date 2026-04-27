[Home](../README.md) | [Setup](../00-setup/README.md) | [Architecture](../01-architecture/README.md) | [YAML & Pods](../02-yaml-pods/README.md) | [Deployments](../03-deployments/README.md) | [Networking](../03.5-networking/README.md) | [State](../04-state/README.md) | [Troubleshooting](../05-troubleshooting/README.md) | [Probes](../06-probes/README.md) | [Namespaces](../07-namespaces/README.md) | [kubectl Reference](../08-kubectl-reference/README.md) | [Interview Prep](../99-interview-prep/README.md)

---

# 00 — Kubernetes Setup

> **Used in production when:** you are connecting to a new cluster, your kubeconfig is stale after an EC2 restart, or you are setting up a colleague's machine to talk to the same cluster.

---

## What this is

Before writing a single manifest you need a working cluster and a verified connection to it. This file covers how your Kubernetes environment is structured, how your Mac talks to k3s on EC2, and the daily opening sequence you run before any session. Everything here maps directly to ShopStack — the cluster you set up in this section is the same cluster ShopStack deploys to on Day 13.

---

## How it fits the stack

```
Your Mac (kubectl)
  │
  │  kubeconfig → ~/.kube/config
  │  points at YOUR_EC2_IP:6443
  │
  ▼
AWS EC2 t3.micro (Ubuntu 22.04)
  │
  ├── k3s control plane  ← the brain (API Server, etcd, Scheduler, Controller Manager)
  ├── k3s worker node    ← the same machine, also runs your Pods
  │
  └── ShopStack Pods will live here (Days 9–13)
```

k3s is a stripped-down Kubernetes distribution. It runs the full Kubernetes API on a single EC2 instance — control plane and worker node on the same machine. Everything you learn here transfers directly to EKS (Week 5), where the control plane is managed by AWS and workers are separate nodes.

---

## 1. The two-machine mental model

You work across two machines in Week 2. Know which one you are on at all times.

| Machine | What it does | How you access it |
|---|---|---|
| Your Mac | Where you write manifests, run kubectl, push to GitHub | Local terminal |
| EC2 t3.micro | Where k3s runs, where Pods actually live | `ssh -i your-key.pem ubuntu@YOUR_EC2_IP` |

**The rule:** You write on your Mac. You never write YAML directly on EC2. kubectl on your Mac talks to k3s on EC2 via the kubeconfig file. The EC2 instance is the cluster — not the workstation.

---

## 2. The tools — what each one does

| Tool | Where it runs | What it does |
|---|---|---|
| `kubectl` | Mac | The CLI that talks to the Kubernetes API Server. Every command you run in Week 2 goes through this. |
| `k3s` | EC2 | The Kubernetes distribution. Runs the full cluster on one machine. |
| kubeconfig | Mac (`~/.kube/config`) | The file that tells kubectl where the cluster is and how to authenticate. |
| `k9s` | Mac (optional) | Terminal UI that shows the cluster in real time. Runs on your Mac, reads from the same kubeconfig. |

---

## 3. EC2 launch and k3s installation

This is your Day 8 checklist. Run it once. The cluster persists until you terminate the EC2 instance.

### Step 1 — Launch EC2

In the AWS Console:
- Instance type: **t3.micro** (free tier)
- OS: **Ubuntu 22.04**
- Key pair: create new, download `.pem` to your Mac
- Security group inbound rules:

| Port | Protocol | Source | Why |
|---|---|---|---|
| 22 | SSH | Your IP only | Terminal access |
| 80 | HTTP | Anywhere | ShopStack frontend (NodePort) |
| 443 | HTTPS | Anywhere | Future use |
| 6443 | Custom TCP | Your IP only | kubectl access to k3s API Server |
| 30080 | Custom TCP | Anywhere | ShopStack frontend NodePort (Day 11) |

### Step 2 — Connect and install k3s

```bash
# On your Mac — fix key permissions
chmod 400 your-key.pem

# SSH into EC2
ssh -i your-key.pem ubuntu@YOUR_EC2_IP

# Inside EC2 — install k3s (one command, takes ~60 seconds)
curl -sfL https://get.k3s.io | sh -

# Confirm the node is Ready
sudo k3s kubectl get nodes
```

Expected output:
```
NAME              STATUS   ROLES                  AGE   VERSION
ip-172-xx-xx-xx   Ready    control-plane,master   30s   v1.x.x+k3s1
```

`Ready` is the only acceptable status. If it shows `NotReady` — wait 30 seconds and run again.

### Step 3 — Wire kubectl on your Mac to the cluster

k3s writes its kubeconfig to `/etc/rancher/k3s/k3s.yaml` on the EC2 instance. You need to copy this to your Mac and update the server address.

```bash
# Still inside EC2 — print the kubeconfig
sudo cat /etc/rancher/k3s/k3s.yaml
```

Copy the entire output. Then on your Mac:

```bash
# On your Mac — paste the kubeconfig
vi ~/.kube/config
# Paste the contents, save and exit (:wq)

# Replace the server address — the file says 127.0.0.1 which is EC2's localhost
# You need YOUR_EC2_IP so your Mac can reach it
sed -i '' 's/127.0.0.1/YOUR_EC2_IP/g' ~/.kube/config
```

Verify:

```bash
# On your Mac — confirm kubectl talks to the cluster
kubectl get nodes
```

Expected output — same node you saw on EC2, same `Ready` status:
```
NAME              STATUS   ROLES                  AGE   VERSION
ip-172-xx-xx-xx   Ready    control-plane,master   2m    v1.x.x+k3s1
```

If you see this — your Mac is connected to k3s on EC2. Every `kubectl` command from this point forward runs from your Mac.

---

## 4. Get the EC2 public IP

EC2 public IPs change every time the instance restarts. Run this inside the EC2 terminal at the start of every session:

```bash
curl -s http://169.254.169.254/latest/meta-data/public-ipv4
```

When the IP changes you must update two things:
1. `~/.kube/config` on your Mac — the `server:` line
2. Any NodePort URLs you are testing in a browser

---

## 5. The daily opening sequence — run this every session

This is your cold start. Do it before touching a manifest. Do it without looking at notes by Day 9.

```bash
# Step 1 — On your Mac: confirm kubectl is connected
kubectl get nodes
# Must show Ready. If it times out — EC2 rebooted, update ~/.kube/config with new IP.

# Step 2 — Full cluster health scan
kubectl get pods -A
# All pods in kube-system namespace must be Running or Completed.
# Any pod in Error or CrashLoopBackOff in kube-system = cluster is unhealthy.

# Step 3 — If ShopStack is already deployed (Day 9 onward)
kubectl get pods
# Check your ShopStack pods in the default namespace.
```

| What you see | What it means | What to do |
|---|---|---|
| Node shows `Ready` | Cluster is healthy | Continue |
| `kubectl: connection refused` | EC2 IP changed | Get new IP, update `~/.kube/config` |
| `kubectl: i/o timeout` | EC2 is stopped or unreachable | Start EC2 in AWS Console |
| kube-system pod in `CrashLoopBackOff` | Cluster is unhealthy | SSH into EC2, run `sudo systemctl restart k3s` |

---

## 6. Session management — stopping and starting EC2

k3s runs as a systemd service on EC2. You do not stop and start k3s manually — you stop and start the EC2 instance.

**Stepping away for a short break?**
Leave the EC2 instance running. k3s keeps running in the background. Your cluster state (Pods, Deployments, Services) persists.

**Done for the day?**
Stop the EC2 instance in the AWS Console to avoid charges. Your cluster state is lost when the instance stops — Pods are ephemeral. Manifests on your Mac survive. Just re-apply them next session.

**EC2 IP changed after restart?**
```bash
# Get the new public IP from inside EC2
curl -s http://169.254.169.254/latest/meta-data/public-ipv4

# Update kubeconfig on your Mac
sed -i '' 's/OLD_IP/NEW_IP/g' ~/.kube/config

# Verify connection
kubectl get nodes
```

**Cluster feels broken?**
```bash
# SSH into EC2
ssh -i your-key.pem ubuntu@YOUR_EC2_IP

# Restart k3s
sudo systemctl restart k3s

# Check status
sudo systemctl status k3s

# Verify cluster
sudo k3s kubectl get nodes
```

---

## 7. The transferable toolkit — what carries to production

Everything you use here works the same on a 1,000-node EKS cluster. The tools do not change. Only the cluster behind `~/.kube/config` changes.

| Tool | Transfers to production | Notes |
|---|---|---|
| `kubectl` | ✅ Yes | Same commands on EKS, GKE, AKS |
| kubeconfig | ✅ Yes | On EKS you run `aws eks update-kubeconfig` instead of copying manually |
| k3s | ❌ No | k3s is for learning/small clusters. Production uses EKS (Week 5). |
| k9s | ✅ Yes | Connect it to any cluster via kubeconfig |

**What does NOT transfer:**
- `minikube` commands — not used in your setup at all
- Single-node cluster assumptions — EKS has multiple worker nodes

---

## ⚠️ What Breaks

| Symptom | Cause | Fix |
|---|---|---|
| `kubectl get nodes` times out | EC2 IP changed after restart | Get new IP, update `server:` in `~/.kube/config` |
| `error: You must be logged in to the server` | kubeconfig has wrong IP or credentials | Re-copy `/etc/rancher/k3s/k3s.yaml` from EC2 |
| Node shows `NotReady` | k3s still starting, or service crashed | Wait 30 seconds, or `sudo systemctl restart k3s` on EC2 |
| `permission denied` on `.pem` file | Key file permissions too open | `chmod 400 your-key.pem` |
| Port 6443 connection refused | Security group missing port 6443 rule | Add inbound rule: port 6443, your IP, in AWS Console |
| Pod shows `Pending` immediately | Not a setup error — covered in debugging section | See `07-debugging.md` |

---

## Daily Commands

| What it does | Command | Example |
|---|---|---|
| Confirm cluster is reachable and node is Ready | `kubectl get nodes` | `kubectl get nodes` |
| Full cluster health scan — all namespaces | `kubectl get pods -A` | `kubectl get pods -A` |
| Check ShopStack pods in default namespace | `kubectl get pods` | `kubectl get pods` |
| Confirm kubectl is installed | `kubectl version --client` | `kubectl version --client` |
| Check k3s service health — run inside EC2 | `sudo systemctl status k3s` | `sudo systemctl status k3s` |
| Restart k3s if cluster is unhealthy — run inside EC2 | `sudo systemctl restart k3s` | `sudo systemctl restart k3s` |
| Get current EC2 public IP — run inside EC2 | `curl -s http://169.254.169.254/latest/meta-data/public-ipv4` | `curl -s http://169.254.169.254/latest/meta-data/public-ipv4` |
| Update kubeconfig when EC2 IP changes | `sed -i '' 's/OLD_IP/NEW_IP/g' ~/.kube/config` | `sed -i '' 's/3.91.12.4/54.210.8.9/g' ~/.kube/config` |

---

→ **Interview questions for this topic:** covered in `99-interview-prep.md` — What is a node? What is kubeconfig? What is k3s vs EKS?
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
                    │           CONTROL PLANE (Brain)         │
                    │                                         │
  kubectl (Mac) ───▶│  ┌─────────────┐   ┌────────────────┐  │
                    │  │  API Server  │   │      etcd      │  │
                    │  │ (Entry Point)│◀─▶│ (Source of     │  │
                    │  └──────┬──────┘   │  Truth DB)     │  │
                    │         │          └────────────────┘  │
                    │  ┌──────▼──────┐   ┌────────────────┐  │
                    │  │  Scheduler  │   │   Controller   │  │
                    │  │(Assigns Pod │   │    Manager     │  │
                    │  │  to Node)   │   │(Watches State) │  │
                    │  └─────────────┘   └────────────────┘  │
                    └──────────────┬──────────────────────────┘
                                   │ assigns work
                          ┌────────▼────────┐
                          │  Worker Node    │
                          │  (EC2 t3.micro) │
                          │                 │
                          │ ┌─────────────┐ │
                          │ │   kubelet   │ │
                          │ │(Node Agent) │ │
                          │ └──────┬──────┘ │
                          │        │        │
                          │ ┌──────▼──────┐ │
                          │ │  containerd │ │
                          │ │ (Runtime)   │ │
                          │ └──────┬──────┘ │
                          │        │        │
                          │  ┌─────▼──────┐ │
                          │  │  Pod  Pod  │ │
                          │  │ [API][DB]  │ │
                          │  └────────────┘ │
                          │ ┌─────────────┐ │
                          │ │  Kube Proxy │ │
                          │ │(Networking) │ │
                          │ └─────────────┘ │
                          └─────────────────┘
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
[Home](../README.md) | [Setup](../00-setup/README.md) | [Architecture](../01-architecture/README.md) | [YAML & Pods](../02-yaml-pods/README.md) | [Deployments](../03-deployments/README.md) | [Networking](../03.5-networking/README.md) | [State](../04-state/README.md) | [Troubleshooting](../05-troubleshooting/README.md) | [Probes](../06-probes/README.md) | [Namespaces](../07-namespaces/README.md) | [kubectl Reference](../08-kubectl-reference/README.md) | [Interview Prep](../99-interview-prep/README.md)

---

# 02 — YAML & Pods

> **Used in production when:** you are writing a new manifest from scratch, a Pod is stuck in a bad state and you need to read its birth certificate, or you need to understand why two objects are not connecting to each other.

---

## What this is

A Pod is the smallest thing Kubernetes can deploy. Before you can write Deployments, Services, or anything else, you need to understand the object that everything in Kubernetes ultimately runs as — and the language you use to describe it. This file covers YAML manifest anatomy, the label and selector system that connects all Kubernetes objects, and the Pod itself. Every manifest you write in Week 2 starts with these four pillars.

---

## How it fits the stack

```
Week 2 object hierarchy:

  Deployment        ← you write this (Day 10)
    └── ReplicaSet  ← Kubernetes creates this
          └── Pod   ← you understand this today (Day 9)
                └── Container  ← your actual app runs here
```

You learn Pods today specifically so you can feel what breaks when there is no Deployment watching them. The aha — deleting a bare Pod and watching it stay dead — is the reason Deployments exist.

---

## 1. Declarative vs Imperative

In traditional infrastructure you give direct commands: *"Start this container."* That is imperative — you describe the steps.

In Kubernetes you use **declarative management**:

- **You:** Write a YAML file saying "this is the desired state I want."
- **Kubernetes:** The control plane continuously compares your file to the cluster and acts to match it.

You stop telling Kubernetes *how* to do things. You tell it *what* you want, and it figures out the rest.

**The practical difference:**

```bash
# Imperative — you describe the action
kubectl run shopstack-api --image=akhiltejadoosari/shopstack-api:1.0

# Declarative — you describe the desired state
kubectl apply -f infra/k8s/api-pod.yaml
```

In production you always use declarative. Imperative commands are for quick debugging only — they leave no record in version control and cannot be re-applied consistently.

---

## 2. The four pillars of every manifest

Every Kubernetes object starts with the same skeleton. The API Server reads these four fields first — if any one is missing or wrong, it rejects the entire file before looking at anything else.

```yaml
apiVersion: v1          # PILLAR 1 — Which version of the K8s API to use.
                        # v1 covers core objects: Pod, Service, ConfigMap, Secret.
                        # Deployments use apps/v1 — added later in the apps group.
                        # Wrong version = immediate rejection by the API Server.

kind: Pod               # PILLAR 2 — What TYPE of object you are creating.
                        # One word changes everything. Pod, Deployment, Service,
                        # Secret, ConfigMap — each triggers a different controller.
                        # Case sensitive. 'pod' ≠ 'Pod'. Always capitalise.

metadata:
  name: shopstack-api   # PILLAR 3 — The identity of this object in the cluster.
                        # Must be unique within a namespace.
                        # Convention: projectname-role
                        # shopstack = project, api = this Pod's role
  labels:
    app: shopstack       # The badge. Services and controllers find this Pod using this.
    tier: api            # Stack multiple labels — each one is a searchable filter.

spec:                   # PILLAR 4 — The blueprint. What should exist inside.
  containers:           # Everything from here is specific to the kind above.
    - name: api         # Container name inside the Pod.
      image: akhiltejadoosari/shopstack-api:1.0
      ports:
        - containerPort: 8080
```

**`apiVersion`** is the rulebook. It tells the API Server which version of the spec to validate against. `v1` for Pods, Services, ConfigMaps, Secrets. `apps/v1` for Deployments and ReplicaSets. Getting this wrong is the most common first error — the API Server rejects it immediately with a clear message.

**`kind`** is the single most important field. One word completely changes what the rest of the file means and which controller handles it. It is case sensitive — `pod` is not a valid kind. Always `Pod`.

**`metadata`** is the identity card. The `name` must be unique within the namespace. The `labels` block is where you attach searchable tags — they live here, inside `metadata`, not inside `spec`.

**`spec`** is the blueprint. Everything from here down is specific to the `kind` you declared. A Pod's `spec` holds containers. A Service's `spec` holds ports and selectors. Same pillar, completely different content.

---

## 3. Labels and selectors — the glue

This is the system that connects every Kubernetes object to every other. Get this wrong and nothing finds anything.

### Why the names are exactly right

A **label** is a stamp you press onto a Kubernetes object. A simple key-value pair you write in the `metadata` section. It does not change what the object does — it just gives it a tag that other objects can search for.

A **selector** is a search filter. It does not create anything — it scans etcd for objects wearing a matching label. A Service with `selector: app: shopstack` is saying: *"find every Pod in the cluster that has `app: shopstack` stamped on it and send traffic to them."*

```yaml
# THE POD — this is where the label is CREATED
metadata:
  labels:
    app: shopstack      # ← THE LABEL. The stamp on the Pod.

# THE SERVICE — this is where the label is USED as a search filter
spec:
  selector:
    app: shopstack      # ← SAME VALUE. "Find every Pod stamped with this."
```

**Why this system exists:** Pods are ephemeral. Every time a Pod dies and gets replaced, it gets a new name and a new IP address. If a Service tracked Pods by IP it would lose them constantly. Instead, every new Pod just wears the same label as the one it replaced — and the Service finds it instantly with no reconfiguration.

### The rule

The label on the Pod and the selector on the Service must be an **exact match**. One typo and they are completely invisible to each other. This is the most common misconfiguration in Kubernetes.

### ShopStack — labels in practice

```yaml
# api Pod wears these labels
labels:
  app: shopstack
  tier: api

# api Service selects by these labels
selector:
  app: shopstack
  tier: api

# frontend Pod wears these labels
labels:
  app: shopstack
  tier: frontend

# frontend Service selects by these labels — different tier, different Pods
selector:
  app: shopstack
  tier: frontend
```

Same `app: shopstack` across all five services. Different `tier` values to keep them separated. The Services know exactly which Pods belong to which service — not by name, not by IP, by label.

### The three things labels unlock

**1. Networking** — Services find Pods dynamically by label, not IP. Covered in `03.5-networking.md`.

**2. Scaling and self-healing** — A ReplicaSet counts how many Pods are wearing its label. If the count drops below desired, it creates more. If it rises above, it terminates extras. Covered in `03-deployments.md`.

**3. Filtering** — `kubectl get pods -l tier=api` returns only the API Pods. Useful when you have 20 Pods running and want to see just one tier.

---

## 4. The anatomy of a Pod

A Pod is the smallest deployable unit in Kubernetes. Think of it as a sealed shipping container — a protective shell that carries your app into the cluster and gives it everything it needs: an identity, a network address, and access to storage.

Kubernetes never runs a naked container. It always wraps it in a Pod first.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: shopstack-api          # Unique name inside the cluster.
                               # When this Pod dies, the replacement gets a new name.
                               # Never rely on the name to find Pods — use labels.
  labels:
    app: shopstack             # The badge. Services find this Pod using this.
    tier: api

spec:
  containers:
    - name: api                # The name of this container inside the Pod.
      image: akhiltejadoosari/shopstack-api:1.0
                               # The Docker image to pull. Always pin to a specific
                               # version tag in production. Never use latest —
                               # you cannot roll back latest to latest.
      ports:
        - containerPort: 8080  # The port this container listens on INSIDE the Pod.
                               # This is documentation only — it does not open or
                               # block ports. The Service's targetPort routes here.
      env:
        - name: DB_HOST
          value: "db"          # Same service name used in Docker Compose.
                               # Kubernetes DNS resolves this to the db Service IP.
        - name: DB_NAME
          value: "shopstack"
        - name: DB_USER
          value: "shopstack"
        - name: DB_PASSWORD
          value: "shopstack_dev"
                               # In production this moves to a Secret. Covered Day 12.
```

**One IP per Pod.** Every Pod gets its own internal cluster IP when it starts. That IP is destroyed with the Pod. This is why you never hardcode Pod IPs — you use Service names and labels.

**Shared environment.** All containers listed in the `spec` share the same network namespace — they share one IP and communicate via `localhost`. They also share storage volumes. This is the foundation of the Sidecar pattern — one container runs the app, another handles logs or proxying, both in the same Pod.

**Ephemeral by design.** If a bare Pod dies it stays dead. Kubernetes does not resurrect it — a controller detects the death and creates a brand new replacement with a new name and new IP. Self-healing is not a Pod feature. It is a Deployment feature.

---

## 5. ShopStack — what each service looks like as a Pod

Before you write the real Deployment manifests on Day 10, you write bare Pods on Day 9. This is intentional — you need to feel the Pod fail to self-heal before Deployments make sense.

```
shopstack/infra/k8s/          ← all manifests live here
├── api-pod.yaml              ← Day 9 only, replaced by api-deployment.yaml on Day 10
├── frontend-pod.yaml         ← Day 9 only
└── db-pod.yaml               ← Day 9 only
```

**What each Pod needs:**

| Service | Image | Port | Key env vars |
|---|---|---|---|
| api | `akhiltejadoosari/shopstack-api:1.0` | 8080 | `DB_HOST`, `DB_NAME`, `DB_USER`, `DB_PASSWORD` |
| frontend | `akhiltejadoosari/shopstack-frontend:1.0` | 80 | none |
| db | `postgres:15-alpine` | 5432 | `POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD` |
| worker | `akhiltejadoosari/shopstack-worker:1.0` | none | `API_HOST` |
| adminer | `adminer` | 8080 | none |

> **Note on db:** Postgres crashes immediately without its required env vars (`POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD`). This is intentional on Day 9 — you will see `CrashLoopBackOff`, read the logs, understand why, and fix it. The permanent fix (Secrets) comes on Day 12.

---

## 6. The dev workflow — write, lint, apply, inspect

The professional loop. Run it every time you touch a manifest. Build it into reflex.

```bash
# Step 1 — Write the manifest
vi infra/k8s/api-pod.yaml

# Step 2 — Apply it (send desired state to the API Server)
kubectl apply -f infra/k8s/api-pod.yaml
# Expected: pod/shopstack-api created

# Step 3 — Check status
kubectl get pods
# NAME            READY   STATUS    RESTARTS   AGE
# shopstack-api   1/1     Running   0          10s
#
# READY 1/1   = 1 container running out of 1 total
# STATUS      = Running means the Pod is alive
# RESTARTS 0  = nothing has crashed yet

# Step 4 — Read the birth certificate (when something looks wrong)
kubectl describe pod shopstack-api
# Scroll to the EVENTS section at the bottom.
# This is where errors appear. Always read this before anything else.

# Step 5 — Read what the container printed
kubectl logs shopstack-api
# This is stdout from the container. Application errors appear here.
# If the Pod is in CrashLoopBackOff — logs shows what it printed before dying.
```

**What a healthy Events section looks like:**

```
Events:
  Normal  Scheduled  5s    default-scheduler  Successfully assigned default/shopstack-api
  Normal  Pulling    4s    kubelet            Pulling image "akhiltejadoosari/shopstack-api:1.0"
  Normal  Pulled     2s    kubelet            Successfully pulled image
  Normal  Created    2s    kubelet            Created container api
  Normal  Started    2s    kubelet            Started container api
```

Read this sequence until you can spot a break in it instantly. Pulling → Pulled → Created → Started is healthy. Any `Failed`, `BackOff`, or `Error` entry is where you diagnose.

---

## 7. The kubectl debug loop for Pods

| Tool | What it shows | When to use it |
|---|---|---|
| `kubectl get pods` | Status and restart count at a glance | After every apply, or when something feels off |
| `kubectl describe pod <n>` | Full event log — the Pod's birth certificate | When status is not `Running` or restarts are climbing |
| `kubectl logs <n>` | What the container printed to stdout | When Pod is running but the app inside is broken |
| `kubectl logs <n> --previous` | Logs from the previous crash | When the Pod is in CrashLoopBackOff |
| `kubectl exec -it <n> -- /bin/sh` | Enter the running container | When logs are not enough — you need to poke around inside |

---

## ⚠️ What Breaks

| Symptom | Cause | First command |
|---|---|---|
| `ImagePullBackOff` | Image name is wrong, tag does not exist, or DockerHub is unreachable | `kubectl describe pod <n>` → Events → find the exact pull error |
| `CrashLoopBackOff` | Container starts then immediately exits | `kubectl logs <n> --previous` → read what it printed before dying |
| `Pending` — never starts | Scheduler cannot find a node (usually not enough CPU/RAM on EC2) | `kubectl describe pod <n>` → Events → look for `Insufficient` |
| `Error: ImagePullBackOff` on db Pod | Postgres started without required env vars | `kubectl logs <n>` → Postgres prints exactly what is missing |
| Pod is `Running` but app returns errors | App is up but something inside is broken (wrong DB_HOST, missing table) | `kubectl logs <n>` → read application error output |
| Label typo — Service sends no traffic | `selector` on Service does not match `labels` on Pod | `kubectl describe service <n>` → check Endpoints field — should not be `<none>` |

---

## Daily Commands

| What it does | Command | Example |
|---|---|---|
| Send manifest to the API Server — create or update the object | `kubectl apply -f <file>` | `kubectl apply -f infra/k8s/api-pod.yaml` |
| Apply every manifest in the folder at once | `kubectl apply -f <folder>` | `kubectl apply -f infra/k8s/` |
| Check Pod status and restart count | `kubectl get pods` | `kubectl get pods` |
| Filter by label — show only matching Pods | `kubectl get pods -l <label>` | `kubectl get pods -l tier=api` |
| Full event log — always read Events section | `kubectl describe pod <n>` | `kubectl describe pod shopstack-api` |
| Container stdout — application errors appear here | `kubectl logs <n>` | `kubectl logs shopstack-api` |
| Logs from the last crash — for CrashLoopBackOff | `kubectl logs <n> --previous` | `kubectl logs shopstack-api --previous` |
| Follow logs live — Ctrl+C to stop | `kubectl logs -f <n>` | `kubectl logs -f shopstack-api` |
| Enter a running container | `kubectl exec -it <n> -- /bin/sh` | `kubectl exec -it shopstack-api -- /bin/sh` |
| Delete a Pod — if a Deployment owns it, it comes back | `kubectl delete pod <n>` | `kubectl delete pod shopstack-api` |
| Delete the object defined in the manifest | `kubectl delete -f <file>` | `kubectl delete -f infra/k8s/api-pod.yaml` |

---

→ **Interview questions for this topic:** `99-interview-prep.md` — What is a Pod? Why not run bare Pods in production? What is a label? What is a selector?

→ Next: [03 — Deployments](./03-deployments.md)
[Home](../README.md) | [Setup](../00-setup/README.md) | [Architecture](../01-architecture/README.md) | [YAML & Pods](../02-yaml-pods/README.md) | [Deployments](../03-deployments/README.md) | [Networking](../03.5-networking/README.md) | [State](../04-state/README.md) | [Troubleshooting](../05-troubleshooting/README.md) | [Probes](../06-probes/README.md) | [Namespaces](../07-namespaces/README.md) | [kubectl Reference](../08-kubectl-reference/README.md) | [Interview Prep](../99-interview-prep/README.md)

---

# 03 — Deployments

> **Used in production when:** you need to deploy a new image version without downtime, a Pod keeps crashing and you need to roll back, or you need to scale a service up to handle load.

---

## What this is

In `02-yaml-pods.md` you deployed a bare Pod and proved it does not self-heal — delete it and it stays dead. That is not production. This file covers how Kubernetes actually keeps applications alive, updates them without downtime, and scales them under load. A Deployment is what you create for every stateless application. Every time.

---

## How it fits the stack

```
You write:       Deployment   (desired state declaration — "I want 2 API replicas")
K8s creates:     ReplicaSet   (enforces the count — "are 2 running right now?")
RS creates:      Pods         (the actual running containers)

shopstack/infra/k8s/
├── api-deployment.yaml       ← 2 replicas, rolling update config
├── frontend-deployment.yaml  ← 2 replicas
├── db-deployment.yaml        ← 1 replica (stateful — PVC added Day 12)
└── worker-deployment.yaml    ← 1 replica
```

---

## 1. The problem with bare Pods

In `02-yaml-pods.md` you ran this and watched the Pod stay dead:

```bash
kubectl delete pod shopstack-api
kubectl get pods
# No resources found — gone, nothing replaced it
```

A bare Pod has no guardian. If it crashes at 3 AM it stays crashed until someone manually recreates it. In production that means downtime.

The solution is to never run bare Pods for anything that matters. Instead you declare desired state to a Deployment and let Kubernetes enforce it 24/7.

---

## 2. ReplicaSets — the guardian

A ReplicaSet has one job: ensure that a specified number of identical Pod replicas are running at all times.

**The thermostat analogy:** You set the temperature to 2 (your desired replica count). The thermostat watches the room constantly. If a Pod crashes and the count drops to 1, it immediately turns on the heat and creates a new Pod to bring it back to 2. If somehow 3 are running, it terminates one. It never stops watching. It never sleeps.

```
Desired state:  replicas = 2
Actual state:   running  = 1  (one crashed)

ReplicaSet detects gap → creates 1 new Pod → Actual = 2 ✅
```

**The rule:** You almost never create a ReplicaSet directly. You create a Deployment, which creates and manages the ReplicaSet for you. The RS is an implementation detail Kubernetes handles behind the scenes.

---

## 3. Deployments — the manager

If a ReplicaSet is the thermostat that keeps the count right, a Deployment is the building manager that controls everything about the thermostat — including how to upgrade it, roll it back, and configure it safely.

```
You (kubectl apply)
        │
        ▼
┌───────────────────┐
│    Deployment     │  ← You create this. It owns everything below.
└────────┬──────────┘
         │ creates and manages
         ▼
┌───────────────────┐
│    ReplicaSet     │  ← Deployment creates this. Enforces Pod count.
└────────┬──────────┘
         │ creates and manages
         ▼
┌─────────────────────────┐
│  Pod      Pod           │  ← Your app runs here.
│ [api]   [api]           │
└─────────────────────────┘
```

| Feature | Bare Pod | ReplicaSet | Deployment |
|---|---|---|---|
| Self-healing | ❌ | ✅ | ✅ |
| Scaling | ❌ | ✅ | ✅ |
| Rolling updates | ❌ | ❌ | ✅ |
| Rollbacks | ❌ | ❌ | ✅ |
| Update history | ❌ | ❌ | ✅ |

---

## 4. The anatomy of a Deployment manifest

A Deployment manifest has the same four pillars as a Pod — but the `spec` wraps a Pod template inside it.

```yaml
apiVersion: apps/v1         # Deployments live in 'apps/v1' not 'v1'
                            # Different from Pods which use 'v1'
                            # Wrong version = immediate rejection by API Server

kind: Deployment

metadata:
  name: shopstack-api
  labels:
    app: shopstack
    tier: api

spec:
  replicas: 2               # How many Pod copies to keep running at all times
                            # The ReplicaSet enforces this number 24/7

  selector:                 # How this Deployment finds and owns its Pods
    matchLabels:
      app: shopstack        # Must match the labels in the Pod template below
      tier: api             # One typo here = Deployment owns nothing

  template:                 # The Pod template — every Pod created uses this blueprint
    metadata:
      labels:
        app: shopstack      # Must match selector.matchLabels above exactly
        tier: api
    spec:
      containers:
        - name: api
          image: akhiltejadoosari/shopstack-api:1.0
                            # Always pin to a specific version in production
                            # Never use 'latest' — you cannot roll back latest to latest
          ports:
            - containerPort: 8080
          env:
            - name: DB_HOST
              value: "db"
            - name: DB_NAME
              value: "shopstack"
            - name: DB_USER
              value: "shopstack"
            - name: DB_PASSWORD
              value: "shopstack_dev"
                            # Moves to a Secret on Day 12
```

**The selector is the critical link.** The `selector.matchLabels` on the Deployment must exactly match the `labels` on the Pod template. This is how the Deployment knows which Pods it owns. One typo and the Deployment creates Pods it cannot manage.

**`apps/v1` vs `v1`:** Pods use `v1`. Deployments use `apps/v1`. Getting this wrong is the most common first mistake — the API Server rejects it immediately.

---

## 5. Rolling updates — zero downtime

**The hotel renovation analogy:** You need to renovate a 10-floor hotel without closing it. You cannot evict all guests at once. So you renovate floor by floor — move guests from floor 1 to a spare room, renovate floor 1, move them back, then floor 2. At no point is the hotel fully closed. Guests always have somewhere to stay.

Kubernetes does the exact same thing with your Pods during an update.

```
BEFORE UPDATE                 DURING UPDATE                  AFTER UPDATE
shopstack-api:1.0             New Pod (v1.1) starts          Old RS scales to 0
[Pod] [Pod]                   [Pod v1.0] [Pod v1.0]          [Pod v1.1]
Old RS: replicas=2            [Pod v1.1] starts healthy      [Pod v1.1]
New RS: replicas=0            [Pod v1.0] terminated          New RS: replicas=2
                              Repeat for second Pod
```

At no point are all Pods down. Traffic keeps flowing throughout.

**Watch the rollout in real time:**

```bash
kubectl rollout status deployment/shopstack-api
```

Expected output while updating:
```
Waiting for deployment "shopstack-api" rollout to finish:
1 out of 2 new replicas have been updated...
2 out of 2 new replicas have been updated...
Waiting for 2 pods to be ready...
deployment "shopstack-api" successfully rolled out
```

**Check ReplicaSets after the update:**

```bash
kubectl get rs
```

Expected — two ReplicaSets, old at 0, new at 2:
```
NAME                       DESIRED   CURRENT   READY   AGE
shopstack-api-7d9f8b6c4    2         2         2       2m    ← new (v1.1)
shopstack-api-5c6b7a8d9    0         0         0       10m   ← old (v1.0) kept for rollback
```

The old RS stays at 0 — not deleted. This is your rollback parachute.

**A stuck rolling update** — what it looks like:

```bash
kubectl rollout status deployment/shopstack-api
# Waiting for deployment "shopstack-api" rollout to finish:
# 1 out of 2 new replicas have been updated...
# (hangs — never progresses)
```

This means the new Pods are failing to start. Check:

```bash
kubectl get pods
# shopstack-api-7d9f8b6c4-xxx   0/1   ImagePullBackOff   0   2m

kubectl describe pod shopstack-api-7d9f8b6c4-xxx
# Scroll to Events — find the exact error
```

The old Pods keep running so the application stays up while you investigate.

---

## 6. Rollbacks — the emergency undo

**Check the full update history:**

```bash
kubectl rollout history deployment/shopstack-api
```

```
REVISION  CHANGE-CAUSE
1         <none>
2         <none>
```

**Emergency rollback to previous version:**

```bash
kubectl rollout undo deployment/shopstack-api
```

After rollback — check the ReplicaSets:

```bash
kubectl get rs
```

The old RS (v1.0) scales back up to 2. The new RS (v1.1) scales down to 0. Kubernetes swapped them — no new objects created, no manual Pod recreation.

**Rollback to a specific revision:**

```bash
kubectl rollout undo deployment/shopstack-api --to-revision=1
```

---

## 7. Scaling

Scaling a Deployment means telling the ReplicaSet to run more or fewer Pods.

```bash
# Scale up — handle more traffic
kubectl scale deployment/shopstack-api --replicas=4

# Scale back down
kubectl scale deployment/shopstack-api --replicas=2
```

When scaling in, Kubernetes terminates the newest Pods first (LIFO — Last In, First Out). Newer Pods are more likely to be in the middle of a task than older, settled ones.

**Watch the scale happen live:**

```bash
kubectl get pods -w
```

`-w` watches for changes. Pods appear and disappear live. `Ctrl+C` to stop.

---

## 8. Reading Deployment output

```bash
kubectl get deployments
```

```
NAME               READY   UP-TO-DATE   AVAILABLE   AGE
shopstack-api      2/2     2            2           10m
shopstack-frontend 2/2     2            2           10m
shopstack-db       1/1     1            1           10m
```

| Column | Meaning |
|---|---|
| `READY` | Running Pods out of desired total |
| `UP-TO-DATE` | Pods running the latest template version |
| `AVAILABLE` | Pods passing health checks and ready for traffic |

```bash
kubectl get rs
```

```
NAME                       DESIRED   CURRENT   READY   AGE
shopstack-api-7d9f8b6c4    2         2         2       10m
shopstack-api-5c6b7a8d9    0         0         0       20m   ← old RS kept for rollback
```

| Column | Meaning |
|---|---|
| `DESIRED` | How many Pods this RS wants to run |
| `CURRENT` | How many Pods currently exist |
| `READY` | How many Pods are passing health checks |

---

## 9. ShopStack — all four Deployment manifests

```
shopstack/infra/k8s/
├── api-deployment.yaml       ← 2 replicas, env vars for DB connection
├── frontend-deployment.yaml  ← 2 replicas, port 80
├── worker-deployment.yaml    ← 1 replica, env var for API_HOST
└── db-deployment.yaml        ← 1 replica (PVC added Day 12, Secret added Day 12)
```

> **Note on adminer:** Adminer is a dev tool only. It can run as a bare Pod on Day 9 or a single-replica Deployment — it does not need self-healing in a learning environment.

> **Note on db Deployment:** Postgres at 1 replica is correct — you do not run multiple Postgres replicas without a StatefulSet and replication config. Day 10 uses a Deployment as a stepping stone. PVC and Secrets are added Day 12.

---

## ⚠️ What Breaks

| Symptom | Cause | Fix |
|---|---|---|
| Deployment created but no Pods appear | `selector.matchLabels` does not match Pod template `labels` | `kubectl describe deployment shopstack-api` → check Events |
| Rolling update stuck at 1 out of 2 | New Pod failing to start — bad image or bad env vars | `kubectl get pods` → find the stuck Pod → `kubectl describe pod <n>` |
| `kubectl rollout undo` does nothing | Already at revision 1 — nothing to roll back to | Check `kubectl rollout history deployment/<n>` |
| Scale up — Pods stuck in `Pending` | EC2 t3.micro out of CPU or RAM | `kubectl describe pod <n>` → Events → `Insufficient cpu` |
| `error: unknown flag: --record` | `--record` flag deprecated in newer kubectl | Use `kubectl annotate` to add change cause manually |
| Deleted a Deployment — Pods gone too | Correct behaviour — Deployment deletion cascades to RS and Pods | Recreate with `kubectl apply -f` |

---

## Daily Commands

| What it does | Command | Example |
|---|---|---|
| Create or update a Deployment | `kubectl apply -f <file>` | `kubectl apply -f infra/k8s/api-deployment.yaml` |
| Check all Deployments and ready count | `kubectl get deployments` | `kubectl get deployments` |
| See the ReplicaSets — old and new after updates | `kubectl get rs` | `kubectl get rs` |
| See the Pods the RS created | `kubectl get pods` | `kubectl get pods` |
| Full event log — errors appear here | `kubectl describe deployment <n>` | `kubectl describe deployment shopstack-api` |
| Watch a rolling update in real time | `kubectl rollout status deployment/<n>` | `kubectl rollout status deployment/shopstack-api` |
| See all previous revisions | `kubectl rollout history deployment/<n>` | `kubectl rollout history deployment/shopstack-api` |
| Emergency rollback to previous version | `kubectl rollout undo deployment/<n>` | `kubectl rollout undo deployment/shopstack-api` |
| Rollback to a specific revision | `kubectl rollout undo deployment/<n> --to-revision=<n>` | `kubectl rollout undo deployment/shopstack-api --to-revision=1` |
| Trigger a rolling update with new image | `kubectl set image deployment/<n> <container>=<image>` | `kubectl set image deployment/shopstack-api api=akhiltejadoosari/shopstack-api:1.1` |
| Scale up or down | `kubectl scale deployment/<n> --replicas=<n>` | `kubectl scale deployment/shopstack-api --replicas=4` |
| Watch Pod changes live | `kubectl get pods -w` | `kubectl get pods -w` |
| Delete Deployment and all its Pods | `kubectl delete deployment <n>` | `kubectl delete deployment shopstack-api` |

---

→ **Interview questions for this topic:** `99-interview-prep.md` — What is a Deployment? What is a ReplicaSet? What is a rolling update? What does kubectl rollout undo do?

→ Next: [03.5 — Services & Networking](./03.5-networking.md)
[Home](../README.md) | [Setup](../00-setup/README.md) | [Architecture](../01-architecture/README.md) | [YAML & Pods](../02-yaml-pods/README.md) | [Deployments](../03-deployments/README.md) | [Networking](../03.5-networking/README.md) | [State](../04-state/README.md) | [Troubleshooting](../05-troubleshooting/README.md) | [Probes](../06-probes/README.md) | [Namespaces](../07-namespaces/README.md) | [kubectl Reference](../08-kubectl-reference/README.md) | [Interview Prep](../99-interview-prep/README.md)

---

# 03.5 — Services & Networking

> **Used in production when:** a Pod cannot reach another Pod by name, traffic is not reaching your application from the browser, or you need to expose a new service to the outside world.

---

## What this is

Pods have IP addresses that change every time they restart. A Service is the stable network endpoint that sits in front of a set of Pods and never changes. Without Services, nothing in the cluster can reliably talk to anything else. This file covers how Services work, the three types and when to use each, how Kubernetes DNS lets Pods find each other by name, and how all five ShopStack services get wired together.

---

## How it fits the stack

```
Day 9  — Pods exist but cannot talk to each other
Day 10 — Deployments manage Pods but still no stable addressing
Day 11 — Services wire the tiers together ← this file

After Day 11:
  Browser → frontend-service (NodePort :30080)
                │
                ▼ /api/* proxy
           api-service (ClusterIP :8080)
                │
                ▼
           db-service (ClusterIP :5432)

  worker-deployment → api-service :8080 (health ping every 10s)
  adminer-service   → db-service :5432
```

---

## 1. The problem Services solve

After Day 10 you have Deployments running Pods. But Pods have a fatal networking problem — their IP addresses are not stable.

Every time a Pod dies and gets replaced it gets a brand new IP address. The replacement is functionally identical but its IP is completely different. If the API Pod is talking to the DB Pod directly by IP and the DB Pod restarts overnight, the API loses its connection — and has no way to find the DB again.

This is not a Kubernetes bug. It is a deliberate design decision. Pods are ephemeral. Their IPs are ephemeral. The solution is to never talk to a Pod IP directly.

**A Service has a stable IP and a stable DNS name — both survive Pod restarts.**

The API never talks to `10.42.0.14` (the db Pod IP). It talks to `db` (the db Service name). Kubernetes DNS resolves `db` to the db Service's stable IP. The db Service routes to whichever db Pod is currently running. When the Pod restarts with a new IP, the Service updates its routing — the API never notices.

---

## 2. How a Service finds its Pods — selectors

A Service finds its Pods the same way everything in Kubernetes does — by label selector.

```yaml
# The db Pod wears this label
metadata:
  labels:
    app: shopstack
    tier: db

# The db Service selects by this label
spec:
  selector:
    app: shopstack
    tier: db        # "Find every Pod wearing this badge and route traffic to them"
```

When the db Pod restarts with a new IP, it wears the same label. The Service finds it instantly. No reconfiguration. No restart. The label is the address.

**The rule:** The `selector` on the Service must exactly match the `labels` on the Pod template in the Deployment. One typo and the Service has no Pods — `Endpoints: <none>`.

---

## 3. The three Service types

| Type | Who can reach it | ShopStack use |
|---|---|---|
| ClusterIP | Inside the cluster only | api, db, worker, adminer |
| NodePort | Outside the cluster via EC2 IP + port | frontend (browser access on Day 11) |
| LoadBalancer | Outside via cloud load balancer | frontend on EKS (Week 5 — production) |

### ClusterIP — the default

ClusterIP is what you use for every service that only needs to be reachable from inside the cluster. The Service gets a stable internal IP that is only routable within the cluster network.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: db              # This name is the DNS hostname other Pods use
spec:
  type: ClusterIP       # Default — omit the type field and you get ClusterIP
  selector:
    app: shopstack
    tier: db
  ports:
    - port: 5432        # Port the Service listens on
      targetPort: 5432  # Port on the Pod to forward traffic to
```

The API Pod connects to Postgres by writing `DB_HOST=db` in its env vars. Kubernetes DNS resolves `db` to this Service's ClusterIP. The Service forwards to the db Pod on port 5432.

### NodePort — external access for learning

NodePort exposes the Service on a static port on every node in the cluster. Traffic to `YOUR_EC2_IP:30080` reaches the frontend Service, which routes to the frontend Pods.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: frontend
spec:
  type: NodePort
  selector:
    app: shopstack
    tier: frontend
  ports:
    - port: 80          # Port the Service listens on inside the cluster
      targetPort: 80    # Port on the frontend Pod
      nodePort: 30080   # Port exposed on the EC2 instance (must be 30000–32767)
                        # http://YOUR_EC2_IP:30080 reaches the frontend
```

> **NodePort range:** Kubernetes only allows NodePort values between 30000 and 32767. You chose 30080 — it is in range, memorable, and already in your EC2 security group.

### LoadBalancer — production on EKS

LoadBalancer provisions a cloud load balancer (AWS ALB on EKS) and gives it a public DNS name. Traffic to that DNS name routes into the cluster. This replaces NodePort in production — you do not expose raw EC2 ports to the internet.

Not used in Week 2. Covered in Week 5 (AWS + EKS).

---

## 4. Kubernetes DNS — how Pods find each other by name

Kubernetes runs a DNS server inside the cluster (CoreDNS). Every Service gets a DNS entry automatically when it is created. The full DNS name for a Service is:

```
<service-name>.<namespace>.svc.cluster.local
```

For ShopStack in the default namespace:
```
db.default.svc.cluster.local       ← full DNS name for the db Service
api.default.svc.cluster.local      ← full DNS name for the api Service
```

But within the same namespace you can just use the Service name:
```
db          ← resolves to db.default.svc.cluster.local
api         ← resolves to api.default.svc.cluster.local
```

**This is why your env vars work.** In Docker Compose `DB_HOST=db` worked because Docker DNS resolved `db` to the db container. In Kubernetes `DB_HOST=db` works because Kubernetes DNS resolves `db` to the db Service ClusterIP. Same mental model, different mechanism. Your application code does not change.

**ShopStack DNS resolution in practice:**

```
API Pod env var:    DB_HOST=db
API connects to:    db:5432
DNS resolves:       db → 10.96.45.12  (db Service ClusterIP)
Service routes to:  10.42.0.14:5432   (db Pod IP — changes on restart)
App sees:           a stable Postgres connection
```

---

## 5. The port fields — what each one means

Service manifests have three port fields that confuse people. They are independent.

```yaml
ports:
  - port: 80          # The port OTHER Pods and Services use to reach this Service
                      # "knock on port 80 of the frontend Service"
    targetPort: 80    # The port on the POD that the Service forwards traffic to
                      # "forward to port 80 on the frontend container"
    nodePort: 30080   # NodePort only — the port exposed on the EC2 instance
                      # "http://YOUR_EC2_IP:30080 reaches this Service"
```

**The most common mistake:** setting `port` and `targetPort` to different values without realising. If your frontend container listens on port 80 but `targetPort` says 8080, no traffic reaches the container.

---

## 6. ShopStack — all five Service manifests

```
shopstack/infra/k8s/
├── frontend-service.yaml   ← NodePort :30080 → Pod :80
├── api-service.yaml        ← ClusterIP :8080
├── db-service.yaml         ← ClusterIP :5432
├── worker-service.yaml     ← ClusterIP (no external port — worker calls out, not in)
└── adminer-service.yaml    ← NodePort :30081 → Pod :8080 (dev only)
```

**frontend-service.yaml:**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: frontend
spec:
  type: NodePort
  selector:
    app: shopstack
    tier: frontend
  ports:
    - port: 80
      targetPort: 80
      nodePort: 30080
```

**api-service.yaml:**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: api
spec:
  type: ClusterIP
  selector:
    app: shopstack
    tier: api
  ports:
    - port: 8080
      targetPort: 8080
```

**db-service.yaml:**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: db              # This name is what DB_HOST=db resolves to
spec:
  type: ClusterIP
  selector:
    app: shopstack
    tier: db
  ports:
    - port: 5432
      targetPort: 5432
```

**worker-service.yaml:**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: worker
spec:
  type: ClusterIP
  selector:
    app: shopstack
    tier: worker
  ports:
    - port: 8080
      targetPort: 8080
```

**adminer-service.yaml:**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: adminer
spec:
  type: NodePort
  selector:
    app: shopstack
    tier: adminer
  ports:
    - port: 8080
      targetPort: 8080
      nodePort: 30081
```

---

## 7. Verifying a Service is working

After applying a Service manifest the first thing to check is Endpoints.

```bash
kubectl get endpoints
```

Expected — each Service should show at least one IP:
```
NAME       ENDPOINTS           AGE
api        10.42.0.5:8080      2m
db         10.42.0.3:5432      2m
frontend   10.42.0.4:80        2m
worker     10.42.0.6:8080      2m
```

If a Service shows `<none>` under ENDPOINTS — the selector does not match any running Pod. This is the most common Service bug.

```bash
kubectl describe service api
```

Scroll to the `Endpoints` line. If it says `<none>`:
1. Check the Service selector labels
2. Check the Pod template labels in the Deployment
3. They must match exactly — one typo makes them invisible to each other

**Test DNS resolution from inside a Pod:**

```bash
kubectl exec -it <any-running-pod> -- /bin/sh
# Inside the container:
nslookup db
# Should return the ClusterIP of the db Service

wget -qO- http://api:8080/api/health
# Should return {"status":"ok","db":"connected"...}
```

---

## 8. Nginx as Ingress — the bridge from Docker Week

In Week 1 you learned that Nginx is a reverse proxy — it sits at the front door, serves static files, and forwards `/api/*` requests to the Python API.

In Kubernetes, **Ingress** is the same concept. An Ingress controller is Nginx running inside the cluster doing the same proxying job. Same idea, different environment.

You do not use Ingress in Week 2 — you use NodePort for direct access. Ingress becomes relevant in Week 5 (EKS) when you need path-based routing and TLS termination. When you get there, it will click immediately because you already own the mental model from Week 1.

---

## ⚠️ What Breaks

| Symptom | Cause | Fix |
|---|---|---|
| `kubectl get endpoints` shows `<none>` | Service selector does not match Pod labels | Compare `selector` in Service to `labels` in Deployment Pod template |
| Browser hits `YOUR_EC2_IP:30080` — connection refused | NodePort not in EC2 security group | Add inbound rule: port 30080, anywhere, in AWS Console |
| API cannot connect to DB — `could not connect to server` | `DB_HOST` env var does not match Service name | Confirm Service is named `db` and `DB_HOST=db` in api Deployment |
| Service exists but Pod gets no traffic | Pod failing readiness probe — not in endpoints | `kubectl describe pod <n>` → check readiness probe status |
| `nslookup db` fails inside a Pod | CoreDNS not running or Service not created yet | `kubectl get pods -n kube-system` → confirm coredns pods are Running |
| NodePort not in 30000–32767 range | K8s rejects the manifest | Use a port in range — 30080 and 30081 are already set |

---

## Daily Commands

| What it does | Command | Example |
|---|---|---|
| Create or update a Service | `kubectl apply -f <file>` | `kubectl apply -f infra/k8s/api-service.yaml` |
| List all Services and their type | `kubectl get services` | `kubectl get services` |
| List all Services with ports | `kubectl get services -o wide` | `kubectl get services -o wide` |
| Check which Pods a Service is routing to | `kubectl get endpoints` | `kubectl get endpoints` |
| Full Service details — selector, endpoints, events | `kubectl describe service <n>` | `kubectl describe service api` |
| Delete a Service | `kubectl delete service <n>` | `kubectl delete service api` |
| Test DNS resolution from inside a Pod | `kubectl exec -it <pod> -- nslookup <service>` | `kubectl exec -it shopstack-api-xxx -- nslookup db` |
| Hit an internal endpoint from inside a Pod | `kubectl exec -it <pod> -- wget -qO- <url>` | `kubectl exec -it shopstack-api-xxx -- wget -qO- http://api:8080/api/health` |

---

→ **Interview questions for this topic:** `99-interview-prep.md` — What is a Kubernetes Service? What is ClusterIP vs NodePort vs LoadBalancer? How does Kubernetes DNS work?

→ Next: [04 — State](./04-state.md)
[Home](../README.md) | [Setup](../00-setup/README.md) | [Architecture](../01-architecture/README.md) | [YAML & Pods](../02-yaml-pods/README.md) | [Deployments](../03-deployments/README.md) | [Networking](../03.5-networking/README.md) | [State](../04-state/README.md) | [Troubleshooting](../05-troubleshooting/README.md) | [Probes](../06-probes/README.md) | [Namespaces](../07-namespaces/README.md) | [kubectl Reference](../08-kubectl-reference/README.md) | [Interview Prep](../99-interview-prep/README.md)

---

# 04 — State — ConfigMap, Secret, PVC

> **Used in production when:** you need to inject configuration into a Pod without hardcoding it, you need to store a password without putting it in plain YAML, or Postgres is losing data every time its Pod restarts.

---

## What this is

Containers are ephemeral — their filesystem is destroyed when they stop. Every env var hardcoded in a manifest is visible to anyone who reads the file. This file covers the three Kubernetes objects that solve state and configuration: ConfigMap for non-sensitive config, Secret for sensitive data, and PersistentVolumeClaim for disk storage that survives Pod restarts. All three are applied to ShopStack's database tier on Day 12.

---

## How it fits the stack

```
Day 10 — api Deployment has DB_PASSWORD=shopstack_dev in plain YAML ← bad
Day 12 — DB credentials move into a Secret, injected as env vars   ← correct
Day 12 — Postgres gets a PVC so data survives Pod restarts          ← correct
Day 12 — Non-sensitive config moves into a ConfigMap                ← correct

shopstack/infra/k8s/
├── db-secret.yaml       ← DB_USER, DB_PASSWORD, DB_NAME (base64 encoded)
├── db-configmap.yaml    ← DB_HOST, DB_PORT (non-sensitive)
└── db-pvc.yaml          ← 5GB for /var/lib/postgresql/data
```

---

## 1. The three problems and their solutions

| Problem | Wrong approach | Correct object |
|---|---|---|
| DB password in plain YAML committed to GitHub | `DB_PASSWORD: shopstack_dev` hardcoded in Deployment | `kind: Secret` |
| DB_HOST and DB_PORT config scattered across manifests | Repeated in every Deployment that needs it | `kind: ConfigMap` |
| Postgres data wiped every time the Pod restarts | No volume — data lives on container layer | `kind: PersistentVolumeClaim` |

---

## 2. ConfigMap — non-sensitive configuration

A ConfigMap stores non-sensitive key-value pairs and injects them into Pods as environment variables or mounted files. Think of it as a shared configuration file that multiple Pods can read from.

**When to use ConfigMap vs Secret:** If you would be comfortable committing the value to a public GitHub repo — it goes in a ConfigMap. If not — it goes in a Secret.

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: db-config
data:
  DB_HOST: "db"           # The Service name — resolves via Kubernetes DNS
  DB_PORT: "5432"         # Postgres default port
  DB_NAME: "shopstack"    # Database name — not sensitive
```

**Inject into the API Deployment:**

```yaml
spec:
  containers:
    - name: api
      image: akhiltejadoosari/shopstack-api:1.0
      envFrom:
        - configMapRef:
            name: db-config   # Inject ALL keys from the ConfigMap as env vars
```

Or inject individual keys:

```yaml
      env:
        - name: DB_HOST
          valueFrom:
            configMapKeyRef:
              name: db-config
              key: DB_HOST
```

---

## 3. Secret — sensitive data

A Secret stores sensitive data — passwords, tokens, API keys. The values are base64 encoded. Base64 is **not encryption** — anyone can decode it. The safety comes from not committing it to Git and from RBAC restricting who can read Secrets in the cluster.

**Encoding a value:**

```bash
echo -n "shopstack_dev" | base64
# → c2hvcHN0YWNrX2Rldg==

echo -n "shopstack" | base64
# → c2hvcHN0YWNr
```

The `-n` flag is critical — without it `echo` adds a newline character and the encoded value is wrong.

**db-secret.yaml:**

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-secret
type: Opaque           # Opaque = generic key-value secret (the default type)
data:
  DB_USER: c2hvcHN0YWNr           # "shopstack" base64 encoded
  DB_PASSWORD: c2hvcHN0YWNrX2Rldg==  # "shopstack_dev" base64 encoded
  POSTGRES_DB: c2hvcHN0YWNr       # "shopstack" base64 encoded
  POSTGRES_USER: c2hvcHN0YWNr     # "shopstack" base64 encoded
  POSTGRES_PASSWORD: c2hvcHN0YWNrX2Rldg==  # "shopstack_dev" base64 encoded
```

**Inject into the db Deployment:**

```yaml
spec:
  containers:
    - name: db
      image: postgres:15-alpine
      envFrom:
        - secretRef:
            name: db-secret   # Inject ALL keys from the Secret as env vars
```

**Read a Secret value (decode it):**

```bash
kubectl get secret db-secret -o jsonpath='{.data.DB_PASSWORD}' | base64 -d
# → shopstack_dev
```

**The rule:** Never commit a Secret manifest with real credentials to GitHub. Use `.gitignore` to exclude `*-secret.yaml`, or use a secrets manager (AWS Secrets Manager, Vault) in production.

---

## 4. PersistentVolumeClaim — disk storage that survives Pod restarts

Without a PVC, Postgres stores all data on the container's writable layer. When the Pod restarts — for any reason — that layer is destroyed and a fresh Postgres starts with an empty database. Every row, every order, every product record is gone.

A PVC is a request for disk storage. Your manifest says "I need 5GB." Kubernetes finds or provisions a PersistentVolume that satisfies the claim and binds them. The data on that volume survives Pod deletion, Pod restarts, and Pod rescheduling.

```
Without PVC:  Pod restarts → container layer wiped → Postgres starts empty
With PVC:     Pod restarts → new Pod mounts same volume → Postgres continues
```

**The storage stack:**

```
PersistentVolume (PV)     ← the actual disk (provisioned by k3s or AWS EBS)
        ↑
PersistentVolumeClaim (PVC) ← your request for storage (what you write)
        ↑
Pod (db Deployment)       ← mounts the PVC at /var/lib/postgresql/data
```

You write the PVC. Kubernetes finds or creates the PV automatically (in k3s it uses local storage on the EC2 disk).

**db-pvc.yaml:**

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: db-pvc
spec:
  accessModes:
    - ReadWriteOnce       # One node can read and write at a time
                          # Correct for a single Postgres instance
  resources:
    requests:
      storage: 5Gi        # Request 5 gigabytes of storage
```

**Mount the PVC in the db Deployment:**

```yaml
spec:
  containers:
    - name: db
      image: postgres:15-alpine
      volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data   # Where Postgres stores its data
  volumes:
    - name: postgres-storage
      persistentVolumeClaim:
        claimName: db-pvc   # Reference the PVC by name
```

**Check PVC status:**

```bash
kubectl get pvc
```

Expected:
```
NAME     STATUS   VOLUME         CAPACITY   ACCESS MODES   AGE
db-pvc   Bound    pvc-xxx-xxx    5Gi        RWO            30s
```

`Bound` is the only healthy status. `Pending` means Kubernetes cannot find storage to satisfy the claim — on k3s this usually means the local storage provisioner is not running.

---

## 5. ShopStack — the full Day 12 state layer

After Day 12 the db Deployment references all three objects:

```yaml
# db-deployment.yaml — after Day 12
spec:
  template:
    spec:
      containers:
        - name: db
          image: postgres:15-alpine
          envFrom:
            - secretRef:
                name: db-secret      # POSTGRES_USER, POSTGRES_PASSWORD, POSTGRES_DB
            - configMapRef:
                name: db-config      # DB_HOST, DB_PORT, DB_NAME
          volumeMounts:
            - name: postgres-storage
              mountPath: /var/lib/postgresql/data
      volumes:
        - name: postgres-storage
          persistentVolumeClaim:
            claimName: db-pvc
```

The API Deployment references the same ConfigMap and Secret for its DB connection env vars — so credentials are defined once and referenced everywhere.

---

## 6. Proving data survives Pod restart

```bash
# Step 1 — confirm PVC is Bound
kubectl get pvc

# Step 2 — connect to adminer at http://YOUR_EC2_IP:30081
# Create a test row in the products table

# Step 3 — delete the db Pod
kubectl delete pod <db-pod-name>

# Step 4 — watch the Deployment recreate it
kubectl get pods -w

# Step 5 — connect to adminer again
# The test row is still there — PVC survived the Pod deletion
```

If the row is gone — the PVC is not mounted correctly. Check `volumeMounts` and `volumes` in the Deployment manifest.

---

## ⚠️ What Breaks

| Symptom | Cause | Fix |
|---|---|---|
| `base64: invalid input` when decoding | Value was encoded with a trailing newline | Re-encode with `echo -n` (the `-n` flag removes the newline) |
| Postgres still crashes after adding Secret | Secret keys do not match what Postgres expects | Postgres needs `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB` — not `DB_USER` etc. |
| PVC stuck in `Pending` | k3s local storage provisioner not running | `kubectl get pods -n kube-system` → check local-path-provisioner is Running |
| Data lost after Pod restart | PVC not mounted — `volumeMounts` missing from Deployment | Add `volumeMounts` and `volumes` to the db Deployment spec |
| `envFrom` not working — env vars empty inside container | Secret or ConfigMap name mismatch | `kubectl describe pod <n>` → check for `InvalidEnvVarName` or missing reference events |
| Secret visible in `kubectl get secret -o yaml` | Base64 is encoding not encryption — expected | Restrict access with RBAC in production, never commit to GitHub |

---

## Daily Commands

| What it does | Command | Example |
|---|---|---|
| Create a ConfigMap | `kubectl apply -f <file>` | `kubectl apply -f infra/k8s/db-configmap.yaml` |
| Create a Secret | `kubectl apply -f <file>` | `kubectl apply -f infra/k8s/db-secret.yaml` |
| Create a PVC | `kubectl apply -f <file>` | `kubectl apply -f infra/k8s/db-pvc.yaml` |
| List all ConfigMaps | `kubectl get configmaps` | `kubectl get configmaps` |
| List all Secrets | `kubectl get secrets` | `kubectl get secrets` |
| List all PVCs and their status | `kubectl get pvc` | `kubectl get pvc` |
| Read a ConfigMap's values | `kubectl describe configmap <n>` | `kubectl describe configmap db-config` |
| Decode a Secret value | `kubectl get secret <n> -o jsonpath='{.data.<key>}' \| base64 -d` | `kubectl get secret db-secret -o jsonpath='{.data.DB_PASSWORD}' \| base64 -d` |
| Encode a value for a Secret | `echo -n "<value>" \| base64` | `echo -n "shopstack_dev" \| base64` |
| Check env vars injected into a running Pod | `kubectl exec -it <pod> -- env` | `kubectl exec -it shopstack-db-xxx -- env` |

---

→ **Interview questions for this topic:** `99-interview-prep.md` — What is a Secret? What is a ConfigMap? What is a PVC? What happens to Postgres data when its Pod restarts without a PVC?

→ Next: [05 — Troubleshooting](./05-troubleshooting.md)
[Home](../README.md) | [Setup](../00-setup/README.md) | [Architecture](../01-architecture/README.md) | [YAML & Pods](../02-yaml-pods/README.md) | [Deployments](../03-deployments/README.md) | [Networking](../03.5-networking/README.md) | [State](../04-state/README.md) | [Troubleshooting](../05-troubleshooting/README.md) | [Probes](../06-probes/README.md) | [Namespaces](../07-namespaces/README.md) | [kubectl Reference](../08-kubectl-reference/README.md) | [Interview Prep](../99-interview-prep/README.md)

---

# 05 — Troubleshooting

> **Used in production when:** a Pod is not starting, traffic is not reaching your app, a rolling update is stuck, or you need to understand what the cluster is doing right now.

---

## What this is

Four commands cover 90% of Kubernetes debugging: `kubectl get`, `kubectl describe`, `kubectl logs`, and `kubectl exec`. This file covers what each one shows, when to use it, and how to read the output. Everything is anchored to ShopStack failure scenarios — the exact errors you will see on Day 13 when you deliberately break the stack.

---

## How it fits the stack

```
Something is broken in ShopStack on K8s.
You do not guess. You follow the sequence:

1. kubectl get pods          ← what is the status?
2. kubectl describe pod <n>  ← what did the cluster observe?
3. kubectl logs <n>          ← what did the app print before dying?
4. kubectl exec -it <n>      ← what does the inside of the container look like?
5. kubectl get events        ← what is the cluster timeline?
```

Every debugging session starts at step 1 and goes deeper only if needed. Most problems are resolved at step 2 or 3.

---

## 1. CrashLoopBackOff — what it means and how to diagnose it

CrashLoopBackOff is the most common error state you will see. It means a container is repeatedly crashing and Kubernetes keeps restarting it — with increasing delays between restarts (1s, 2s, 4s, 8s... up to 5 minutes).

**What it does NOT mean:** The Pod is broken forever. It means Kubernetes is trying to fix it but the container keeps dying.

**The two-command diagnosis sequence:**

```bash
# Command 1 — what did the container print before it crashed?
kubectl logs shopstack-api-xxx --previous
# --previous shows logs from the LAST crash, not the current attempt
# This is where the application error lives

# Command 2 — what did Kubernetes observe?
kubectl describe pod shopstack-api-xxx
# Scroll to Events at the bottom
# Look for: Exit Code, OOMKilled, Back-off restarting
```

**ShopStack CrashLoopBackOff scenarios:**

| Service | Most likely cause | What logs show |
|---|---|---|
| api | DB_HOST wrong — cannot connect to Postgres | `could not connect to server: Connection refused` |
| db | Missing POSTGRES_PASSWORD env var | `Error: Database is uninitialized and superuser password is not specified` |
| worker | API_HOST wrong — cannot reach the API | `connection refused` on health ping |
| frontend | Nginx config error | `nginx: [emerg] unknown directive` |

---

## 2. kubectl describe — the birth certificate

`kubectl describe` prints everything Kubernetes knows about an object — its configuration, its current state, and the full event log of everything that happened to it.

```bash
kubectl describe pod shopstack-api-xxx
```

**The anatomy of describe output:**

```
Name:         shopstack-api-7d9f8b6c4-x2k9p
Namespace:    default
Node:         ip-172-31-14-5/172.31.14.5
Status:       Running

Containers:
  api:
    Image:    akhiltejadoosari/shopstack-api:1.0
    Port:     8080/TCP
    State:    Running
    Ready:    True
    Restart Count: 0        ← climbing restart count = CrashLoopBackOff

Conditions:
  Ready:    True            ← False here = Pod not passing readiness probe

Events:                     ← THIS IS WHERE YOU LOOK FIRST
  Normal   Scheduled   5s   Successfully assigned default/shopstack-api
  Normal   Pulling     4s   Pulling image "akhiltejadoosari/shopstack-api:1.0"
  Normal   Pulled      2s   Successfully pulled image
  Normal   Created     2s   Created container api
  Normal   Started     2s   Started container api
```

**What to look for in Events:**

| Event message | What it means |
|---|---|
| `Back-off pulling image` | Image name wrong or tag does not exist |
| `Failed to pull image` | DockerHub unreachable or image is private |
| `OOMKilled` | Container exceeded its memory limit |
| `Back-off restarting failed container` | CrashLoopBackOff — container keeps dying |
| `Insufficient cpu` | Node does not have enough CPU to schedule the Pod |
| `Unable to mount volumes` | PVC not bound or wrong claimName |

**Describe works on any object — not just Pods:**

```bash
kubectl describe deployment shopstack-api
kubectl describe service api
kubectl describe pvc db-pvc
kubectl describe node ip-172-31-14-5
```

---

## 3. kubectl logs — what the app printed

`kubectl logs` shows what the container printed to stdout and stderr. This is where application errors live — not cluster errors (those are in describe Events).

```bash
# Current logs
kubectl logs shopstack-api-xxx

# Logs from the previous crash — use this for CrashLoopBackOff
kubectl logs shopstack-api-xxx --previous

# Follow logs live — tail -f equivalent
kubectl logs -f shopstack-api-xxx

# Last 50 lines only
kubectl logs shopstack-api-xxx --tail=50

# Logs from a specific container in a multi-container Pod
kubectl logs shopstack-api-xxx -c api
```

**What logs shows vs what it does not:**

| logs shows | logs does NOT show |
|---|---|
| Application startup messages | Why Kubernetes scheduled the Pod here |
| Database connection errors | Image pull failures (those are in describe) |
| HTTP request/response logs | Node resource issues |
| Application crashes and stack traces | Network routing problems |
| Whatever the app prints to stdout | Config injection errors |

**ShopStack — what each service prints in logs:**

| Service | Healthy log output |
|---|---|
| api | `Uvicorn running on http://0.0.0.0:8080` + request logs |
| frontend | `nginx: worker process started` |
| db | `database system is ready to accept connections` |
| worker | `Starting worker... pinging api every 10s` |

If the db Pod shows `database system is ready to accept connections` — Postgres started clean. If it shows a password error — the Secret env vars are wrong.

---

## 4. kubectl exec — enter the container

`kubectl exec` opens a shell inside a running container. Use it when logs are not enough and you need to inspect the filesystem, test network connectivity, or run a command inside the container.

```bash
# Open a shell inside the api container
kubectl exec -it shopstack-api-xxx -- /bin/sh

# Run a single command without an interactive shell
kubectl exec shopstack-api-xxx -- env
kubectl exec shopstack-api-xxx -- cat /app/config.py

# Test if the api can reach the db by name
kubectl exec -it shopstack-api-xxx -- /bin/sh
# Inside the container:
wget -qO- http://db:5432       # test TCP connection to db Service
wget -qO- http://api:8080/api/health  # test api health endpoint
nslookup db                    # test DNS resolution
```

**When to use exec over logs:**

| Use logs when | Use exec when |
|---|---|
| Container crashed — you need to see what it printed | Container is running but something is wrong inside |
| Application startup error | You need to test network connectivity between services |
| Request handling errors | You need to check if a file or config exists |

**Common exec use on ShopStack Day 13:**

```bash
# Confirm env vars are injected correctly
kubectl exec shopstack-api-xxx -- env | grep DB

# Confirm the api can reach the db by name
kubectl exec shopstack-api-xxx -- wget -qO- http://db:5432

# Check if the frontend Nginx config is correct
kubectl exec shopstack-frontend-xxx -- cat /etc/nginx/conf.d/default.conf
```

---

## 5. kubectl get events — the cluster timeline

`kubectl get events` shows every event that happened in the cluster — across all objects — sorted by time. It is the cluster's audit log.

```bash
# All events in the default namespace, newest first
kubectl get events --sort-by=.lastTimestamp

# Watch events live
kubectl get events -w

# Events in a specific namespace
kubectl get events -n kube-system
```

**Sample output:**

```
LAST SEEN   TYPE      REASON              OBJECT                    MESSAGE
2m          Normal    Scheduled           Pod/shopstack-api-xxx     Successfully assigned
2m          Normal    Pulling             Pod/shopstack-api-xxx     Pulling image
1m          Normal    Started             Pod/shopstack-api-xxx     Started container
30s         Warning   BackOff             Pod/shopstack-api-xxx     Back-off restarting failed container
10s         Warning   Failed              Pod/shopstack-api-xxx     Error: secret not found
```

`Warning` events are where problems surface. `Normal` events are healthy lifecycle steps. When something is wrong and `kubectl describe` is not specific enough, `kubectl get events` gives you the full timeline across the entire cluster.

---

## 6. The ShopStack Day 13 break sequence

On Day 13 you deliberately break things and fix them. Here is the diagnosis path for each break.

**Break 1 — Delete a Service**

```bash
kubectl delete service api
# Frontend stops showing products — /api/products returns 502

kubectl get services       # api Service is missing
kubectl apply -f infra/k8s/api-service.yaml   # fix
```

**Break 2 — Wrong DB_HOST in Secret**

```bash
# Edit db-secret.yaml — change DB_HOST value to "wrong-host"
kubectl apply -f infra/k8s/db-secret.yaml
kubectl rollout restart deployment/shopstack-api

kubectl get pods           # api enters CrashLoopBackOff
kubectl logs <api-pod> --previous  # shows: could not connect to server
# Fix: correct the DB_HOST, re-apply, restart
```

**Break 3 — Delete a Pod**

```bash
kubectl delete pod <shopstack-api-pod>
kubectl get pods -w        # watch Deployment recreate it
# No action needed — self-healing
```

**Break 4 — Bad image tag in Deployment**

```bash
kubectl set image deployment/shopstack-api api=akhiltejadoosari/shopstack-api:99.99
kubectl rollout status deployment/shopstack-api   # hangs
kubectl get pods           # new Pod in ImagePullBackOff
kubectl describe pod <new-pod>  # Events: failed to pull image
kubectl rollout undo deployment/shopstack-api     # fix
```

---

## 7. Reading Pod status at a glance

```bash
kubectl get pods
```

| Status | What it means | First action |
|---|---|---|
| `Running` | Pod is alive and containers are running | Check logs if app is misbehaving |
| `Pending` | Scheduler cannot place the Pod | `kubectl describe pod` → Events → Insufficient resources or PVC not bound |
| `CrashLoopBackOff` | Container keeps crashing | `kubectl logs --previous` → read crash output |
| `ImagePullBackOff` | Cannot pull the image | `kubectl describe pod` → Events → image name or tag error |
| `OOMKilled` | Container exceeded memory limit | `kubectl describe pod` → Events → set resource limits |
| `Terminating` | Pod is being deleted | Normal — wait for it to complete |
| `Init:Error` | An init container failed | `kubectl logs <pod> -c <init-container-name>` |
| `ContainerCreating` | Image pulling or volume mounting | Normal during startup — wait 30s then check if stuck |

---

## ⚠️ What Breaks

| Symptom | Cause | Fix |
|---|---|---|
| `kubectl logs` returns nothing | Container has not printed anything yet, or just started | Wait 10 seconds and retry |
| `kubectl logs --previous` returns `previous terminated container not found` | No previous crash — Pod just started | Container is currently running or first start — use `kubectl logs` without `--previous` |
| `kubectl exec` returns `OCI runtime exec failed` | Container does not have `/bin/sh` — distroless image | Try `/bin/bash` or `kubectl exec -- ls /` to find the shell |
| Events section in describe is empty | Event TTL expired — events are only kept for 1 hour by default | Use `kubectl get events` to see broader timeline |
| `kubectl get pods` shows correct status but app is broken | App is running but service is misconfigured | Check Service endpoints: `kubectl get endpoints` |

---

## Daily Commands

| What it does | Command | Example |
|---|---|---|
| Check Pod status and restart count | `kubectl get pods` | `kubectl get pods` |
| Full event log for a Pod | `kubectl describe pod <n>` | `kubectl describe pod shopstack-api-xxx` |
| Container logs — current | `kubectl logs <n>` | `kubectl logs shopstack-api-xxx` |
| Container logs — previous crash | `kubectl logs <n> --previous` | `kubectl logs shopstack-api-xxx --previous` |
| Follow logs live | `kubectl logs -f <n>` | `kubectl logs -f shopstack-api-xxx` |
| Enter a running container | `kubectl exec -it <n> -- /bin/sh` | `kubectl exec -it shopstack-api-xxx -- /bin/sh` |
| Run a single command in a container | `kubectl exec <n> -- <cmd>` | `kubectl exec shopstack-api-xxx -- env` |
| Cluster event timeline | `kubectl get events --sort-by=.lastTimestamp` | `kubectl get events --sort-by=.lastTimestamp` |
| Watch events live | `kubectl get events -w` | `kubectl get events -w` |
| Restart all Pods in a Deployment | `kubectl rollout restart deployment/<n>` | `kubectl rollout restart deployment/shopstack-api` |

---

→ **Interview questions for this topic:** `99-interview-prep.md` — What is CrashLoopBackOff? What is the difference between kubectl logs and kubectl describe? When do you use kubectl exec?

→ Next: [06 — Probes](./06-probes.md)
[Home](../README.md) | [Setup](../00-setup/README.md) | [Architecture](../01-architecture/README.md) | [YAML & Pods](../02-yaml-pods/README.md) | [Deployments](../03-deployments/README.md) | [Networking](../03.5-networking/README.md) | [State](../04-state/README.md) | [Troubleshooting](../05-troubleshooting/README.md) | [Probes](../06-probes/README.md) | [Namespaces](../07-namespaces/README.md) | [kubectl Reference](../08-kubectl-reference/README.md) | [Interview Prep](../99-interview-prep/README.md)

---

# 06 — Probes

> **Used in production when:** you want Kubernetes to automatically restart a hung container, or you want to prevent traffic from reaching a Pod that is still starting up.

---

## What this is

A probe is a health check Kubernetes runs against your container on a schedule. There are two kinds: liveness (is the container alive?) and readiness (is the container ready to receive traffic?). They sound similar but fail in completely different ways. This file covers both, what happens when each one fails, and how to configure them on the ShopStack API container.

---

## How it fits the stack

```
Without probes:
  API container hangs — process is running but returns 500 on every request
  Kubernetes sees the process is alive — does nothing
  Users get 500 errors indefinitely

With liveness probe:
  API container hangs — probe hits /api/health — gets 500
  Kubernetes kills the container and starts a fresh one
  Users get a brief blip, then a healthy API

Without readiness probe:
  API starts — Kubernetes immediately sends traffic
  API is still loading DB connection pool — first requests fail
  Users see errors during startup

With readiness probe:
  API starts — probe hits /api/health — not ready yet
  Kubernetes holds traffic back — Pod not in Service endpoints
  DB connection pool loads — probe passes — traffic flows
  Users never see startup errors
```

---

## 1. Liveness probe — restart if dead

A liveness probe asks: **is this container still functioning?**

If the liveness probe fails — Kubernetes kills the container and starts a new one. The Pod stays. Only the container inside it is restarted.

**When to use:** Any container that can get into a deadlocked or hung state where the process is still running but not doing useful work. A web server that stops responding to HTTP but has not crashed is the classic case.

**ShopStack — liveness probe on the API container:**

```yaml
livenessProbe:
  httpGet:
    path: /api/health    # The endpoint Kubernetes hits
    port: 8080           # The container port
  initialDelaySeconds: 15  # Wait 15s before first check — let the app start
  periodSeconds: 10        # Check every 10 seconds
  failureThreshold: 3      # Fail 3 times in a row before restarting
  timeoutSeconds: 5        # Each check must respond within 5 seconds
```

**What `/api/health` returns on ShopStack:**

```json
{"status": "ok", "db": "connected", "timestamp": "..."}
```

If the API returns anything other than HTTP 200 — the probe fails. After 3 consecutive failures — Kubernetes kills the container and starts a fresh one.

---

## 2. Readiness probe — hold traffic until ready

A readiness probe asks: **is this container ready to receive traffic?**

If the readiness probe fails — Kubernetes removes the Pod from the Service's endpoint list. Traffic stops going to it. The container is NOT restarted. When the probe passes again — the Pod is added back to the endpoints and traffic resumes.

**When to use:** Any container that needs time to warm up before it can handle requests — loading config, establishing DB connections, populating a cache.

**ShopStack — readiness probe on the API container:**

```yaml
readinessProbe:
  httpGet:
    path: /api/health
    port: 8080
  initialDelaySeconds: 5   # Start checking after 5s — sooner than liveness
  periodSeconds: 5          # Check every 5 seconds
  failureThreshold: 3       # Remove from endpoints after 3 failures
  successThreshold: 1       # One success = back in rotation
```

---

## 3. Liveness vs readiness — the critical difference

| | Liveness | Readiness |
|---|---|---|
| Question asked | Is the container alive? | Is the container ready for traffic? |
| Fails → | Container is killed and restarted | Pod removed from Service endpoints — no restart |
| Use case | Hung process, deadlock, infinite loop | App warming up, DB connecting, cache loading |
| `initialDelaySeconds` | Longer — let the app fully start | Shorter — check as soon as possible |

**The Pod can be alive but not ready.** This is the key insight. A liveness probe passing means the container is running. A readiness probe failing means the container is up but should not receive traffic yet. Both can be true at the same time.

```
Container state:  Running ✅  (liveness passes — not restarted)
Traffic state:    Blocked ⛔  (readiness fails — not in endpoints)

→ Pod is alive but holding traffic back until it is ready
```

---

## 4. The three probe types

You have seen `httpGet` — it is the most common. Two others exist.

| Type | How it works | When to use |
|---|---|---|
| `httpGet` | Makes an HTTP GET request — 200-399 = pass | Web servers, REST APIs — ShopStack API |
| `tcpSocket` | Opens a TCP connection — success = pass | Databases, message queues — ShopStack DB |
| `exec` | Runs a command inside the container — exit 0 = pass | Custom checks, scripts |

**tcpSocket probe for the db container:**

```yaml
livenessProbe:
  tcpSocket:
    port: 5432           # Kubernetes opens a TCP connection to Postgres port
  initialDelaySeconds: 30  # Postgres takes longer to start
  periodSeconds: 10
```

**exec probe example:**

```yaml
livenessProbe:
  exec:
    command:
    - pg_isready           # Postgres utility — exits 0 if DB is accepting connections
    - -U
    - shopstack
  initialDelaySeconds: 30
  periodSeconds: 10
```

---

## 5. ShopStack — full API Deployment with both probes

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: shopstack-api
spec:
  replicas: 2
  selector:
    matchLabels:
      app: shopstack
      tier: api
  template:
    metadata:
      labels:
        app: shopstack
        tier: api
    spec:
      containers:
        - name: api
          image: akhiltejadoosari/shopstack-api:1.0
          ports:
            - containerPort: 8080
          envFrom:
            - secretRef:
                name: db-secret
            - configMapRef:
                name: db-config
          livenessProbe:
            httpGet:
              path: /api/health
              port: 8080
            initialDelaySeconds: 15
            periodSeconds: 10
            failureThreshold: 3
            timeoutSeconds: 5
          readinessProbe:
            httpGet:
              path: /api/health
              port: 8080
            initialDelaySeconds: 5
            periodSeconds: 5
            failureThreshold: 3
            successThreshold: 1
```

---

## 6. Reading probe status

```bash
kubectl describe pod shopstack-api-xxx
```

Look for:

```
Liveness:   http-get http://:8080/api/health delay=15s timeout=5s period=10s #success=1 #failure=3
Readiness:  http-get http://:8080/api/health delay=5s timeout=5s period=5s #success=1 #failure=3
```

If a probe is failing — the Events section shows it:

```
Warning  Unhealthy  10s  kubelet  Liveness probe failed: HTTP probe failed with statuscode: 500
Warning  Unhealthy  10s  kubelet  Readiness probe failed: HTTP probe failed with statuscode: 500
```

Check `kubectl get endpoints api` — if readiness is failing the Pod IP will be missing from the endpoints list.

---

## ⚠️ What Breaks

| Symptom | Cause | Fix |
|---|---|---|
| Pod keeps restarting every few minutes | Liveness probe failing — app is hanging or returning non-200 | `kubectl logs --previous` → find what `/api/health` is returning |
| Pod is `Running` but gets no traffic | Readiness probe failing — Pod not in endpoints | `kubectl get endpoints` → Pod IP missing → `kubectl describe pod` → probe errors |
| Pod stuck in `0/1 Running` forever | Readiness probe never passes — `initialDelaySeconds` too short | Increase `initialDelaySeconds` to give the app more startup time |
| Liveness probe kills the Pod during startup | `initialDelaySeconds` too short — probe fires before app is ready | Increase `initialDelaySeconds` to be longer than app startup time |
| `Readiness probe failed: connection refused` | App not yet listening on the probe port | Increase `initialDelaySeconds` or check the app is binding to the correct port |

---

## Daily Commands

| What it does | Command | Example |
|---|---|---|
| Check probe configuration on a Pod | `kubectl describe pod <n>` | `kubectl describe pod shopstack-api-xxx` |
| Check if Pod is in Service endpoints | `kubectl get endpoints <service>` | `kubectl get endpoints api` |
| Watch probe failures in real time | `kubectl get events -w` | `kubectl get events -w` |
| Check READY column — readiness state | `kubectl get pods` | `kubectl get pods` |
| Read logs from a probe-killed container | `kubectl logs <n> --previous` | `kubectl logs shopstack-api-xxx --previous` |

---

→ **Interview questions for this topic:** `99-interview-prep.md` — What is a liveness probe? What is a readiness probe? What is the difference between them?

→ Next: [08 — kubectl Reference](./08-kubectl-reference.md)
[Home](../README.md) | [Setup](../00-setup/README.md) | [Architecture](../01-architecture/README.md) | [YAML & Pods](../02-yaml-pods/README.md) | [Deployments](../03-deployments/README.md) | [Networking](../03.5-networking/README.md) | [State](../04-state/README.md) | [Troubleshooting](../05-troubleshooting/README.md) | [Probes](../06-probes/README.md) | [Namespaces](../07-namespaces/README.md) | [kubectl Reference](../08-kubectl-reference/README.md) | [Interview Prep](../99-interview-prep/README.md)

---

# 07 — Namespaces

> **Used in production when:** you need to isolate environments (dev vs staging vs prod) on the same cluster, you are debugging why `kubectl get pods` returns nothing even though you know Pods are running, or you see `-n kube-system` in a command and want to understand what it means.

---

## What this is

A namespace is a virtual partition inside a Kubernetes cluster. One physical cluster, multiple isolated sections. Every object you have created so far — Pods, Deployments, Services, Secrets, PVCs — lives in a namespace. You have been working in the `default` namespace without knowing it. This file covers what namespaces are, the four that exist in every cluster, when to use them, and how they affect every `kubectl` command you run.

---

## How it fits the stack

```
Every kubectl command you have run so far targets the default namespace.

kubectl get pods              ← same as: kubectl get pods -n default
kubectl get services          ← same as: kubectl get services -n default
kubectl get pods -n kube-system  ← this is why you see different Pods here

Your cluster right now:

  default namespace      ← ShopStack lives here
  kube-system namespace  ← control plane components live here
  kube-public namespace  ← cluster info, rarely touched
  kube-node-lease namespace ← node heartbeats, never touched directly
```

---

## 1. The mental model — floors in a building

Think of a Kubernetes cluster as an office building. A namespace is a floor. Each floor has its own set of rooms (Pods), its own reception desk (Services), its own filing cabinet (ConfigMaps and Secrets). Two floors can have a room with the same name — they do not conflict because they are on different floors.

```
Cluster = the building
  default namespace    = floor 1  ← your ShopStack
  kube-system          = floor 2  ← Kubernetes' own infrastructure
  staging              = floor 3  ← a staging copy of ShopStack (future)
  production           = floor 4  ← the live copy of ShopStack (future)
```

Two Pods on different floors can have the same name without conflict. A Service on floor 1 cannot accidentally route to a Pod on floor 3. The floors are isolated.

---

## 2. The four built-in namespaces

Every Kubernetes cluster — k3s, EKS, Minikube — starts with these four:

| Namespace | What lives here | Do you touch it? |
|---|---|---|
| `default` | Your workloads — ShopStack Pods, Deployments, Services | Yes — this is your workspace |
| `kube-system` | Kubernetes' own components — API Server, etcd, CoreDNS, kube-proxy | Never modify — only observe |
| `kube-public` | Cluster info readable by all users without auth | No |
| `kube-node-lease` | Node heartbeat objects — tells control plane nodes are alive | No |

**Why `kubectl get pods -n kube-system` shows different Pods:**

```bash
kubectl get pods -n kube-system
```

```
NAME                                     READY   STATUS    AGE
coredns-xxx                              1/1     Running   2d   ← internal DNS
local-path-provisioner-xxx               1/1     Running   2d   ← PVC storage (k3s)
metrics-server-xxx                       1/1     Running   2d
svclb-traefik-xxx                        1/1     Running   2d   ← k3s ingress
traefik-xxx                              1/1     Running   2d   ← k3s ingress controller
```

These are Kubernetes' own infrastructure Pods. They are not your app. They live in `kube-system` so they are separated from everything you deploy in `default`.

---

## 3. How namespaces affect kubectl commands

Without `-n`, every `kubectl` command targets the `default` namespace. This is why `kubectl get pods` only shows your ShopStack Pods — not the kube-system Pods.

```bash
# These are equivalent
kubectl get pods
kubectl get pods -n default

# See kube-system Pods
kubectl get pods -n kube-system

# See ALL Pods across ALL namespaces
kubectl get pods -A
kubectl get pods --all-namespaces   # same thing, longer form

# Apply a manifest to a specific namespace
kubectl apply -f infra/k8s/api-deployment.yaml -n staging

# Create a namespace
kubectl create namespace staging
```

**The `-A` flag is your full cluster health scan.** When something is wrong and you do not know where, `kubectl get pods -A` shows every Pod in every namespace at once.

---

## 4. DNS across namespaces

In `03.5-networking.md` you learned that `DB_HOST=db` resolves to the db Service via Kubernetes DNS. This works because both the API and db are in the same namespace (`default`).

When services are in different namespaces, the short name does not resolve. You need the full DNS name:

```
Same namespace:       db
                      → resolves to db.default.svc.cluster.local ✅

Different namespace:  db
                      → does not resolve ❌

Different namespace:  db.default.svc.cluster.local
                      → resolves correctly ✅
```

**ShopStack implication:** All five ShopStack services are in `default`. Short names work. If you ever move staging to its own namespace, the env vars need the full DNS names.

---

## 5. When to use namespaces in production

In a real company, namespaces are used to isolate environments and teams on one cluster:

| Use case | Namespace strategy |
|---|---|
| Dev / staging / prod on one cluster | `default` (dev), `staging`, `production` |
| Multiple teams sharing a cluster | `team-payments`, `team-frontend`, `team-data` |
| Isolating monitoring tools | `monitoring` (Prometheus + Grafana live here) |
| Isolating CI/CD tools | `argocd` (ArgoCD lives here — Week 3) |

**For ShopStack in Week 2:** Everything in `default`. Namespaces become relevant in Week 3 when ArgoCD goes into its own namespace and Week 5 when EKS gets dev and prod environments.

---

## 6. Namespaces in a manifest

You can specify a namespace directly in the manifest so you never have to remember the `-n` flag:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: shopstack-api
  namespace: default      # explicit — works the same as omitting it for default
  labels:
    app: shopstack
    tier: api
```

In production manifests you always set `namespace` explicitly — it prevents accidentally deploying to the wrong namespace.

---

## ⚠️ What Breaks

| Symptom | Cause | Fix |
|---|---|---|
| `kubectl get pods` returns nothing — but Pods are running | Pods are in a different namespace | `kubectl get pods -A` to find them, then use `-n <namespace>` |
| `kubectl apply` succeeds but object does not appear | Applied to wrong namespace — check `-n` flag | `kubectl get <object> -A` to find where it landed |
| DNS name `db` not resolving from a Pod | Pod and Service are in different namespaces | Use full DNS name: `db.default.svc.cluster.local` |
| `kubectl delete pod <n>` returns `not found` | Pod is in a different namespace | Add `-n <namespace>` to the command |
| ArgoCD Pods not visible in `kubectl get pods` | ArgoCD installs into `argocd` namespace | `kubectl get pods -n argocd` |

---

## Daily Commands

| What it does | Command | Example |
|---|---|---|
| List all namespaces | `kubectl get namespaces` | `kubectl get namespaces` |
| Create a namespace | `kubectl create namespace <n>` | `kubectl create namespace staging` |
| Get Pods in a specific namespace | `kubectl get pods -n <n>` | `kubectl get pods -n kube-system` |
| Get Pods across ALL namespaces | `kubectl get pods -A` | `kubectl get pods -A` |
| Apply a manifest to a specific namespace | `kubectl apply -f <file> -n <n>` | `kubectl apply -f api-deployment.yaml -n staging` |
| Delete a namespace and everything in it | `kubectl delete namespace <n>` | `kubectl delete namespace staging` |
| Set default namespace for current session | `kubectl config set-context --current --namespace=<n>` | `kubectl config set-context --current --namespace=staging` |

---

→ **Interview questions for this topic:** `99-interview-prep.md` — What is a Kubernetes namespace? What is kube-system? How does DNS work across namespaces?

→ Next: [08 — kubectl Reference](./08-kubectl-reference.md)
[Home](../README.md) | [Setup](../00-setup/README.md) | [Architecture](../01-architecture/README.md) | [YAML & Pods](../02-yaml-pods/README.md) | [Deployments](../03-deployments/README.md) | [Networking](../03.5-networking/README.md) | [State](../04-state/README.md) | [Troubleshooting](../05-troubleshooting/README.md) | [Probes](../06-probes/README.md) | [Namespaces](../07-namespaces/README.md) | [kubectl Reference](../08-kubectl-reference/README.md) | [Interview Prep](../99-interview-prep/README.md)

---

# 08 — kubectl Reference

> **This is your combat sheet.** Open this when you know what you want to do but cannot recall the exact flag or syntax. Every command is anchored to ShopStack.

---

## Cluster & Node

| What it does | Command | Example |
|---|---|---|
| Confirm cluster is reachable and node is Ready | `kubectl get nodes` | `kubectl get nodes` |
| Full node details — CPU, RAM, conditions | `kubectl get nodes -o wide` | `kubectl get nodes -o wide` |
| Full node description — events, capacity | `kubectl describe node <n>` | `kubectl describe node ip-172-31-14-5` |
| Confirm API Server address | `kubectl cluster-info` | `kubectl cluster-info` |
| Full cluster health scan — all namespaces | `kubectl get pods -A` | `kubectl get pods -A` |
| See control plane components | `kubectl get pods -n kube-system` | `kubectl get pods -n kube-system` |

---

## Pods

| What it does | Command | Example |
|---|---|---|
| List all Pods and their status | `kubectl get pods` | `kubectl get pods` |
| List Pods with node and IP info | `kubectl get pods -o wide` | `kubectl get pods -o wide` |
| Filter Pods by label | `kubectl get pods -l <label>` | `kubectl get pods -l tier=api` |
| Watch Pod changes live | `kubectl get pods -w` | `kubectl get pods -w` |
| Full Pod details — events, probes, volumes | `kubectl describe pod <n>` | `kubectl describe pod shopstack-api-xxx` |
| Container logs — current | `kubectl logs <n>` | `kubectl logs shopstack-api-xxx` |
| Container logs — previous crash | `kubectl logs <n> --previous` | `kubectl logs shopstack-api-xxx --previous` |
| Follow logs live | `kubectl logs -f <n>` | `kubectl logs -f shopstack-api-xxx` |
| Last N lines of logs | `kubectl logs <n> --tail=<n>` | `kubectl logs shopstack-api-xxx --tail=50` |
| Logs from specific container in multi-container Pod | `kubectl logs <pod> -c <container>` | `kubectl logs shopstack-api-xxx -c api` |
| Enter a running container | `kubectl exec -it <n> -- /bin/sh` | `kubectl exec -it shopstack-api-xxx -- /bin/sh` |
| Run a single command in a container | `kubectl exec <n> -- <cmd>` | `kubectl exec shopstack-api-xxx -- env` |
| Delete a Pod — Deployment will recreate it | `kubectl delete pod <n>` | `kubectl delete pod shopstack-api-xxx` |

---

## Deployments

| What it does | Command | Example |
|---|---|---|
| Create or update a Deployment | `kubectl apply -f <file>` | `kubectl apply -f infra/k8s/api-deployment.yaml` |
| Apply all manifests in a folder | `kubectl apply -f <folder>` | `kubectl apply -f infra/k8s/` |
| List all Deployments and ready count | `kubectl get deployments` | `kubectl get deployments` |
| Full Deployment details — events, selector | `kubectl describe deployment <n>` | `kubectl describe deployment shopstack-api` |
| Watch a rolling update in real time | `kubectl rollout status deployment/<n>` | `kubectl rollout status deployment/shopstack-api` |
| See rollout history | `kubectl rollout history deployment/<n>` | `kubectl rollout history deployment/shopstack-api` |
| Trigger a rolling update with new image | `kubectl set image deployment/<n> <container>=<image>` | `kubectl set image deployment/shopstack-api api=akhiltejadoosari/shopstack-api:1.1` |
| Emergency rollback to previous version | `kubectl rollout undo deployment/<n>` | `kubectl rollout undo deployment/shopstack-api` |
| Rollback to specific revision | `kubectl rollout undo deployment/<n> --to-revision=<n>` | `kubectl rollout undo deployment/shopstack-api --to-revision=1` |
| Restart all Pods in a Deployment | `kubectl rollout restart deployment/<n>` | `kubectl rollout restart deployment/shopstack-api` |
| Scale up or down | `kubectl scale deployment/<n> --replicas=<n>` | `kubectl scale deployment/shopstack-api --replicas=4` |
| Delete Deployment and all its Pods | `kubectl delete deployment <n>` | `kubectl delete deployment shopstack-api` |

---

## ReplicaSets

| What it does | Command | Example |
|---|---|---|
| List all ReplicaSets | `kubectl get rs` | `kubectl get rs` |
| Full RS details | `kubectl describe rs <n>` | `kubectl describe rs shopstack-api-7d9f8b6c4` |

---

## Services

| What it does | Command | Example |
|---|---|---|
| List all Services | `kubectl get services` | `kubectl get services` |
| List Services with ports and selectors | `kubectl get services -o wide` | `kubectl get services -o wide` |
| Full Service details — selector, endpoints | `kubectl describe service <n>` | `kubectl describe service api` |
| Check which Pods a Service routes to | `kubectl get endpoints` | `kubectl get endpoints` |
| Check endpoints for a specific Service | `kubectl get endpoints <n>` | `kubectl get endpoints api` |
| Delete a Service | `kubectl delete service <n>` | `kubectl delete service api` |

---

## ConfigMaps & Secrets

| What it does | Command | Example |
|---|---|---|
| Create or update a ConfigMap | `kubectl apply -f <file>` | `kubectl apply -f infra/k8s/db-configmap.yaml` |
| List all ConfigMaps | `kubectl get configmaps` | `kubectl get configmaps` |
| Read a ConfigMap's values | `kubectl describe configmap <n>` | `kubectl describe configmap db-config` |
| Create or update a Secret | `kubectl apply -f <file>` | `kubectl apply -f infra/k8s/db-secret.yaml` |
| List all Secrets | `kubectl get secrets` | `kubectl get secrets` |
| Decode a Secret value | `kubectl get secret <n> -o jsonpath='{.data.<key>}' \| base64 -d` | `kubectl get secret db-secret -o jsonpath='{.data.DB_PASSWORD}' \| base64 -d` |
| Encode a value for a Secret | `echo -n "<value>" \| base64` | `echo -n "shopstack_dev" \| base64` |
| Check env vars injected into a running Pod | `kubectl exec <pod> -- env` | `kubectl exec shopstack-api-xxx -- env` |

---

## Persistent Storage

| What it does | Command | Example |
|---|---|---|
| Create a PVC | `kubectl apply -f <file>` | `kubectl apply -f infra/k8s/db-pvc.yaml` |
| List all PVCs and their status | `kubectl get pvc` | `kubectl get pvc` |
| Full PVC details | `kubectl describe pvc <n>` | `kubectl describe pvc db-pvc` |
| List PersistentVolumes | `kubectl get pv` | `kubectl get pv` |

---

## Debugging

| What it does | Command | Example |
|---|---|---|
| Cluster event timeline — newest first | `kubectl get events --sort-by=.lastTimestamp` | `kubectl get events --sort-by=.lastTimestamp` |
| Watch events live | `kubectl get events -w` | `kubectl get events -w` |
| Test DNS from inside a Pod | `kubectl exec -it <pod> -- nslookup <service>` | `kubectl exec -it shopstack-api-xxx -- nslookup db` |
| Test HTTP from inside a Pod | `kubectl exec -it <pod> -- wget -qO- <url>` | `kubectl exec -it shopstack-api-xxx -- wget -qO- http://api:8080/api/health` |
| Check all resources at once | `kubectl get all` | `kubectl get all` |

---

## ShopStack Quick Reference

```bash
# Full stack health check — run this every session
kubectl get nodes
kubectl get pods
kubectl get deployments
kubectl get services
kubectl get pvc
kubectl get endpoints

# The five ShopStack services should all show Running
kubectl get pods -l app=shopstack

# Hit the frontend from your Mac
curl http://YOUR_EC2_IP:30080

# Hit the API health endpoint
curl http://YOUR_EC2_IP:30080/api/health

# Hit products
curl http://YOUR_EC2_IP:30080/api/products
```

---

## Flag Quick Reference

| Flag | What it does | Used with |
|---|---|---|
| `-f <file>` | Specify manifest file | `apply`, `delete` |
| `-l <label>` | Filter by label | `get pods`, `get services` |
| `-n <namespace>` | Specify namespace | any `get` or `describe` |
| `-A` | All namespaces | `get pods` |
| `-o wide` | Extra columns — IPs, node, ports | any `get` |
| `-o yaml` | Full object as YAML | any `get` |
| `-w` | Watch for changes live | any `get` |
| `--previous` | Logs from previous crash | `logs` |
| `-f` | Follow logs live | `logs` |
| `--tail=<n>` | Last N lines of logs | `logs` |
| `-it` | Interactive terminal | `exec` |
| `--replicas=<n>` | Set replica count | `scale` |
| `--to-revision=<n>` | Rollback to specific revision | `rollout undo` |
| `--sort-by=<field>` | Sort output by field | `get events` |

---

→ **Interview questions:** `99-interview-prep.md`

→ Next: [99 — Interview Prep](./99-interview-prep.md)
[Home](../README.md) | [Setup](../00-setup/README.md) | [Architecture](../01-architecture/README.md) | [YAML & Pods](../02-yaml-pods/README.md) | [Deployments](../03-deployments/README.md) | [Networking](../03.5-networking/README.md) | [State](../04-state/README.md) | [Troubleshooting](../05-troubleshooting/README.md) | [Probes](../06-probes/README.md) | [Namespaces](../07-namespaces/README.md) | [kubectl Reference](../08-kubectl-reference/README.md) | [Interview Prep](../99-interview-prep/README.md)

---

# 99 — Interview Prep

> **The rule:** Answer every question out loud in 30 seconds without looking at notes. If you cannot — the concept is not owned yet. Go back to the relevant file and read it again.

---

## How to use this file

Read a question. Cover the answer. Say it out loud. Reveal the answer. Check yourself. A concept you can write is not the same as a concept you can say under pressure in an interview room.

These 10 questions cover the concepts an interviewer asks in a junior-to-mid DevOps screen when they see Kubernetes on your resume. Every answer is written the way you say it — not the way a textbook explains it.

---

## Q1 — What is Kubernetes and why does it exist?

<details>
<summary>Answer</summary>

Kubernetes is a container orchestration platform. Docker lets you run containers, but Docker alone cannot keep them running at scale — if a container crashes at 3 AM it stays down until someone manually restarts it, and scaling means SSH-ing into machines and starting containers by hand.

Kubernetes solves this. You declare the desired state — "I want 2 copies of the ShopStack API running at all times" — and Kubernetes enforces it continuously. If a Pod crashes, it creates a replacement automatically. If you need to scale, one command changes the replica count. If you need to deploy a new version, it swaps containers one by one with zero downtime.

The core shift: you stop telling the system *how* to do things. You tell it *what* you want, and it figures out the rest.

</details>

---

## Q2 — What is a Pod?

<details>
<summary>Answer</summary>

A Pod is the smallest deployable unit in Kubernetes. Kubernetes never runs a naked container — it always wraps it in a Pod first. A Pod is a wrapper around one or more containers that share a network namespace and storage volumes. All containers in a Pod share the same IP address and communicate via localhost.

In ShopStack, the API container runs inside a Pod. That Pod gets an IP address. When the Pod dies, that IP is gone — which is why Services exist to provide a stable endpoint in front of it.

</details>

---

## Q3 — What is the difference between a Pod and a Deployment?

<details>
<summary>Answer</summary>

A bare Pod has no guardian. If you delete it or it crashes, it stays dead. Kubernetes does not recreate it automatically.

A Deployment is a declaration of desired state — "I want 2 replicas of this Pod running at all times." The Deployment creates a ReplicaSet, which watches the actual Pod count and creates or terminates Pods to match the desired number.

In production you never run bare Pods for anything that matters. You always use a Deployment. If the API Pod crashes, the Deployment detects the count dropped from 2 to 1 and creates a replacement — automatically, in seconds, without any manual intervention.

</details>

---

## Q4 — What is a Kubernetes Service and why is it needed?

<details>
<summary>Answer</summary>

A Service is a stable network endpoint for a set of Pods. Pods are ephemeral — every time one dies and gets replaced it gets a brand new IP address. If the ShopStack API Pod talked to the database Pod directly by IP, any DB restart would break the connection permanently.

A Service has a stable ClusterIP and a DNS name that never changes. The API connects to `db` — Kubernetes DNS resolves that to the db Service's stable IP. The Service routes to whichever db Pod is currently running. When the Pod restarts with a new IP, the Service updates automatically. The API never notices.

</details>

---

## Q5 — What is the difference between ClusterIP, NodePort, and LoadBalancer?

<details>
<summary>Answer</summary>

ClusterIP is the default. The Service is only reachable from inside the cluster. I use this for the ShopStack API and database — they only need to talk to each other, not to the outside world.

NodePort exposes the Service on a static port on every node — in my setup port 30080 on the EC2 instance. Anyone who can reach the EC2 IP and that port can reach the Service. I use this for the ShopStack frontend during development.

LoadBalancer provisions a cloud load balancer — on EKS this creates an AWS ALB with a public DNS name. This is how you expose a service to the internet in production. NodePort is fine for learning but you would never expose raw EC2 ports in production.

</details>

---

## Q6 — What is a liveness probe? What is a readiness probe? What is the difference?

<details>
<summary>Answer</summary>

A liveness probe asks: is this container still functioning? Kubernetes hits an endpoint on a schedule. If it fails three times in a row, Kubernetes kills the container and starts a fresh one. This handles deadlocked processes — the container is running but not doing useful work.

A readiness probe asks: is this container ready to receive traffic? If it fails, Kubernetes removes the Pod from the Service's endpoint list — traffic stops going to it — but the container is not restarted. When the probe passes again, the Pod is added back to the endpoints.

The critical difference: liveness failure causes a restart. Readiness failure causes traffic removal, no restart. A Pod can be alive but not ready — for example, still loading a database connection pool on startup.

On the ShopStack API, both probes hit `/api/health`. If the API hangs, liveness kills and restarts it. During startup, readiness holds traffic back until the DB connection is established.

</details>

---

## Q7 — What is a PersistentVolumeClaim and why does Postgres need one?

<details>
<summary>Answer</summary>

A PersistentVolumeClaim is a request for disk storage. You declare "I need 5GB" and Kubernetes finds or provisions a PersistentVolume that satisfies the claim and binds them together.

Postgres needs a PVC because container filesystems are ephemeral — when the Pod restarts, the container's filesystem is destroyed, and Postgres starts fresh with an empty database. Every row, every order, every product record is wiped.

With a PVC, the data lives on a separate volume that persists across Pod restarts. When the Postgres Pod restarts, the new Pod mounts the same volume and Postgres continues from where it left off — data intact.

</details>

---

## Q8 — What is the difference between a Secret and a ConfigMap?

<details>
<summary>Answer</summary>

Both inject configuration into Pods as environment variables. The difference is the sensitivity of the data.

A ConfigMap stores non-sensitive configuration — database hostname, port number, feature flags. Things you would be comfortable committing to a public GitHub repo.

A Secret stores sensitive data — passwords, API keys, tokens. The values are base64 encoded. Base64 is encoding, not encryption — anyone can decode it — but it keeps credentials out of plain YAML that gets committed to version control.

In ShopStack, `DB_HOST=db` and `DB_PORT=5432` live in a ConfigMap. `DB_PASSWORD=shopstack_dev` lives in a Secret.

</details>

---

## Q9 — What is CrashLoopBackOff and how do you diagnose it?

<details>
<summary>Answer</summary>

CrashLoopBackOff means a container is repeatedly crashing and Kubernetes keeps restarting it with increasing delays — 1 second, 2, 4, 8, up to 5 minutes. The Pod stays. The container inside it keeps dying and being recreated.

The two-command diagnosis:

First, `kubectl logs <pod> --previous` — this shows what the container printed to stdout before it crashed. The application error is usually right there — a missing environment variable, a failed database connection, a misconfigured path.

Second, `kubectl describe pod <pod>` — scroll to the Events section at the bottom. This shows what Kubernetes observed — exit codes, OOMKilled signals, image pull failures — things the application itself might not have logged.

In ShopStack the most common cause is a wrong `DB_HOST` value — the API cannot connect to Postgres and exits. Logs show `connection refused`. Fix the env var, restart the Deployment.

</details>

---

## Q10 — What does kubectl apply do? What is the difference between apply and create?

<details>
<summary>Answer</summary>

`kubectl apply` sends a manifest to the Kubernetes API Server. The API Server compares the manifest to what currently exists in etcd. If the object does not exist, it creates it. If it exists, it updates only the fields that changed. Apply is idempotent — you can run it multiple times and it produces the same result.

`kubectl create` only creates — if the object already exists, it returns an error.

In production you always use `kubectl apply`. It supports the declarative workflow — you store manifests in Git, make changes, and apply. Kubernetes reconciles the cluster to match. `kubectl create` is imperative and does not fit this model.

</details>

---

## Rapid fire — 30 seconds each, no notes

Answer these out loud before looking:

1. What is the control plane? One sentence.
2. What is etcd? One sentence.
3. What is a ReplicaSet? One sentence.
4. What does `kubectl rollout undo` do?
5. What is the difference between `kubectl logs` and `kubectl describe`?
6. A Pod is in `Pending` — what is the first command you run?
7. A Service shows `Endpoints: <none>` — what is wrong?
8. Why do you use `echo -n` when encoding a Secret value?
9. What is the difference between `port` and `targetPort` in a Service?
10. A rolling update is stuck — what is the first command you run?

<details>
<summary>Answers</summary>

1. The control plane is the brain of the cluster — API Server, etcd, Scheduler, Controller Manager — it stores desired state and enforces it.
2. etcd is the cluster's key-value database — the single source of truth for every object in the cluster.
3. A ReplicaSet ensures a specified number of identical Pods are always running — creates new ones when the count drops, terminates extras when it rises.
4. `kubectl rollout undo` rolls back a Deployment to its previous ReplicaSet — the old RS scales up, the new RS scales down.
5. `kubectl logs` shows what the application printed to stdout. `kubectl describe` shows what Kubernetes observed — events, probe status, resource allocation.
6. `kubectl describe pod <n>` → read Events → look for `Insufficient cpu/memory` or PVC not bound.
7. The `selector` on the Service does not match the `labels` on the Pod template — one typo makes them invisible to each other.
8. `echo -n` removes the trailing newline. Without it, the newline is encoded into the base64 value and the env var contains a hidden character that breaks the connection.
9. `port` is what other Pods use to reach the Service. `targetPort` is the port on the Pod container the Service forwards traffic to. They are independent.
10. `kubectl rollout status deployment/<n>` — if stuck, `kubectl get pods` to find the failing new Pod, then `kubectl describe pod <n>` to read the error.

</details>
