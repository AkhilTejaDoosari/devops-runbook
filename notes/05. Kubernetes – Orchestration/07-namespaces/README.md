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
