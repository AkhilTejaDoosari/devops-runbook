[Home](../README.md) | [Setup](../00-setup/README.md) | [Architecture](../01-architecture/README.md) | [YAML & Pods](../02-yaml-pods/README.md) | [Deployments](../03-deployments/README.MD) | [Networking](../03.5-networking/README.MD) | [State](../04-state/README.MD) | [Troubleshooting](../05-troubleshooting/README.MD) | [Probes](../06-probes/README.MD) | [Namespaces](../07-namespaces/README.md) | [kubectl Reference](../08-kubectl-reference/README.md) | [Interview Prep](../99-interview-prep/README.md)

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
