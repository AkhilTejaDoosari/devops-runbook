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
