[Home](../README.md) | [Setup](../00-setup/README.md) | [Architecture](../01-architecture/README.md) | [YAML & Pods](../02-yaml-pods/README.md) | [Deployments](../03-deployments/README.md) | [Networking](../03.5-networking/README.md) | [State & Config](../04-state/README.md) | [Troubleshooting](../05-troubleshooting/README.md) | [CI-CD](../06-cicd/README.md) | [Observability](../07-observability/README.md) | [Cloud & EKS](../08-cloud/README.md)

---

# 03 — Deployments, ReplicaSets & Pod Management

## What This File Is About

In Phase 02 you deployed a naked Pod. You also proved it does not self-heal —
delete it and it stays dead. That is not production. This phase covers how
Kubernetes actually keeps applications alive, updates them without downtime,
and scales them under load.

---

## Table of Contents

1. [The Problem With Naked Pods](#1-the-problem-with-naked-pods)
2. [ReplicaSets — The Guardian](#2-replicasets--the-guardian)
3. [Deployments — The Manager](#3-deployments--the-manager)
4. [The Anatomy of a Deployment Manifest](#4-the-anatomy-of-a-deployment-manifest)
5. [Rolling Updates — Zero Downtime](#5-rolling-updates--zero-downtime)
6. [Rollbacks — The Emergency Undo](#6-rollbacks--the-emergency-undo)
7. [Scaling](#7-scaling)
8. [The Full Debug Loop for Deployments](#8-the-full-debug-loop-for-deployments)

> **Note on Sidecar Pattern:** Multi-container Pods and the Sidecar pattern are
> covered in [Phase 3.5 — Networking](../03.5-networking/README.md). They live
> there because Sidecars are fundamentally about a helper container handling
> network traffic alongside your main app.

---

## 1. The Problem With Naked Pods

In Phase 02 you ran this and watched the Pod disappear forever:

```bash
kubectl delete pod webstore-frontend
kubectl get pods
# No resources found — it is gone, nothing replaced it
```

A standalone Pod has no guardian. If it crashes at 3 AM, it stays crashed until
someone manually recreates it. In production that means downtime.

The solution is to never run naked Pods for anything that matters. Instead, you
describe the desired state to a Controller and let Kubernetes enforce it 24/7.

---

## 2. ReplicaSets — The Guardian

A **ReplicaSet (RS)** has one job: ensure that a specified number of identical
Pod replicas are running at all times.

**The Thermostat Analogy:**
Think of a ReplicaSet as a smart thermostat. You set the temperature to 3 (your
desired replica count). The thermostat watches the room constantly. If a Pod
crashes and the count drops to 2, it immediately turns on the heat and creates a
new Pod to bring it back to 3. If somehow 4 are running, it terminates one. It
never stops watching. It never sleeps.

```
Desired State: replicas = 3
Actual State:  running  = 2  (one crashed)

ReplicaSet detects drift → creates 1 new Pod → Actual = 3 ✅
```

**RC vs RS — Why RS Won:**
You may hear about Replication Controllers (RC) — the legacy version of RS.
ReplicaSets replaced them because RS uses a more powerful selector (`matchLabels`)
that allows it to adopt and manage even existing Pods that were not originally
created by the ReplicaSet itself. RC is obsolete. Always use RS (via Deployments).

**The Rule:**
You almost never create a ReplicaSet directly. You create a Deployment, which
creates and manages the ReplicaSet for you. The RS is an implementation detail
that Kubernetes handles behind the scenes.

---

## 3. Deployments — The Manager

If a ReplicaSet is the thermostat that keeps the count right, a **Deployment**
is the building manager that controls everything about the thermostat — including
how to upgrade it, roll it back, and configure it safely.

**The Hierarchy:**

```
You (kubectl apply)
        │
        ▼
┌───────────────────┐
│    Deployment     │  ← You create this. It owns everything below.
│  (The Manager)    │
└────────┬──────────┘
         │ creates and manages
         ▼
┌───────────────────┐
│    ReplicaSet     │  ← Deployment creates this. Ensures Pod count.
│  (The Guardian)   │
└────────┬──────────┘
         │ creates and manages
         ▼
┌──────────────────────────────┐
│  Pod    Pod    Pod           │  ← RS creates these. Your app runs here.
│ [C1]   [C1]   [C1]           │
└──────────────────────────────┘
```

**Why Deployments Over Naked ReplicaSets:**

| Feature | Naked Pod | ReplicaSet | Deployment |
|---------|-----------|------------|------------|
| Self-healing | ❌ | ✅ | ✅ |
| Scaling | ❌ | ✅ | ✅ |
| Rolling updates | ❌ | ❌ | ✅ |
| Rollbacks | ❌ | ❌ | ✅ |
| Update history | ❌ | ❌ | ✅ |

A Deployment is what you use for every stateless application in production.
Every time.

---

## 4. The Anatomy of a Deployment Manifest

A Deployment manifest has the same 4 pillars as a Pod manifest — but the `spec`
is more complex because it wraps a Pod template inside it.

```yaml
apiVersion: apps/v1         # PILLAR 1 — Deployments live in 'apps/v1' not 'v1'
                            # This is different from Pods which use 'v1'
                            # The API Server uses this to find the right rulebook

kind: Deployment            # PILLAR 2 — The type of object

metadata:
  name: webstore-frontend   # PILLAR 3 — The Deployment's identity
  labels:
    app: webstore
    tier: frontend

spec:                        # PILLAR 4 — The blueprint
  replicas: 3                # How many Pod copies to keep running at all times

  selector:                  # How this Deployment finds and owns its Pods
    matchLabels:             # Must match the labels in the Pod template below
      app: webstore          # ← This is the link between Deployment and its Pods
      tier: frontend         # If this does not match, the Deployment owns nothing

  template:                  # The Pod template — every Pod created uses this blueprint
    metadata:
      labels:
        app: webstore        # ← Must match selector.matchLabels above exactly
        tier: frontend       # One typo here and the Deployment cannot find its Pods
    spec:
      containers:
        - name: frontend-container
          image: nginx:1.24           # Pin to a specific version in production
                                      # Never use 'latest' in a real Deployment —
                                      # you cannot roll back 'latest' to 'latest'
          ports:
            - containerPort: 80
```

**The selector is the critical link.**
The `selector.matchLabels` on the Deployment must exactly match the `labels` on
the Pod template. This is how the Deployment knows which Pods it owns and is
responsible for. One typo and the Deployment creates Pods it cannot manage.

**`apps/v1` vs `v1`:**
Pods use `apiVersion: v1` because they are core objects. Deployments use
`apiVersion: apps/v1` because they were added later as part of the `apps` API
group. Getting this wrong is the most common first mistake with Deployments —
the API Server rejects the file immediately.

---

## 5. Rolling Updates — Zero Downtime

**The Construction Analogy:**
Imagine you need to renovate a 10-floor hotel without closing it. You cannot
kick out all the guests at once. So you renovate floor by floor — move guests
from floor 1 to a spare room, renovate floor 1, move guests back, then move to
floor 2. At no point is the hotel fully closed. Guests always have somewhere
to stay.

Kubernetes does the exact same thing with your Pods during an update.

**How it works:**

```
BEFORE UPDATE                    DURING UPDATE                   AFTER UPDATE
webstore-frontend v1.24          New RS (v1.25) starts           Old RS scales to 0
[Pod] [Pod] [Pod]                [Pod v1.25] starts healthy      [Pod v1.25]
Old RS: replicas=3               [Pod v1.24] terminated          [Pod v1.25]
New RS: replicas=0               Repeat for each Pod             [Pod v1.25]
                                                                 New RS: replicas=3
```

At no point are all Pods down. Traffic keeps flowing throughout.

**Trigger a rolling update:**
```bash
kubectl set image deploy/webstore-frontend \
  frontend-container=nginx:1.25
```

**Watch it happen live — run this immediately after:**
```bash
kubectl rollout status deploy/webstore-frontend
```

Expected output while updating:
```
Waiting for deployment "webstore-frontend" rollout to finish:
1 out of 3 new replicas have been updated...
2 out of 3 new replicas have been updated...
3 out of 3 new replicas have been updated...
Waiting for 3 pods to be ready...
deployment "webstore-frontend" successfully rolled out
```

**Check the ReplicaSet history after the update:**
```bash
kubectl get rs
```

Expected output:
```
NAME                          DESIRED   CURRENT   READY   AGE
webstore-frontend-7d9f8b6c4   3         3         3       2m    ← new RS (v1.25)
webstore-frontend-5c6b7a8d9   0         0         0       10m   ← old RS (v1.24) kept for rollback
```

**What the columns mean:**

| Column | Meaning |
|--------|---------|
| `DESIRED` | How many Pods this RS wants to run |
| `CURRENT` | How many Pods currently exist |
| `READY` | How many Pods are passing their health checks |

The old RS stays at `0` — Kubernetes keeps it so you can roll back instantly.

**A stuck rolling update — what it looks like:**
```bash
kubectl rollout status deploy/webstore-frontend
# Waiting for deployment "webstore-frontend" rollout to finish:
# 1 out of 3 new replicas have been updated...
# (hangs here — never progresses)
```

This means the new Pods are failing to start. Diagnose it:
```bash
kubectl get pods
# webstore-frontend-7d9f8b6c4-xxx   0/1   ImagePullBackOff   0   2m

kubectl describe pod webstore-frontend-7d9f8b6c4-xxx
# Scroll to Events — find the exact error
```

Fix the image name, apply again, and the rollout resumes.

---

## 6. Rollbacks — The Emergency Undo

**Check the full update history:**
```bash
kubectl rollout history deploy/webstore-frontend
```

Expected output:
```
REVISION  CHANGE-CAUSE
1         <none>
2         <none>
```

**Add a change cause to your updates (professional habit):**
```bash
kubectl set image deploy/webstore-frontend \
  frontend-container=nginx:1.25 \
  --record
```

Now history shows what changed:
```
REVISION  CHANGE-CAUSE
1         <none>
2         kubectl set image deploy/webstore-frontend frontend-container=nginx:1.25
```

**Emergency rollback to previous version:**
```bash
kubectl rollout undo deploy/webstore-frontend
```

**Rollback to a specific revision:**
```bash
kubectl rollout undo deploy/webstore-frontend --to-revision=1
```

After a rollback, check the RS again:
```bash
kubectl get rs
```

The old RS (v1.24) will scale back up to 3. The new RS (v1.25) will scale down
to 0. Kubernetes just swapped them — no new objects created.

---

## 7. Scaling

Scaling a Deployment means telling the ReplicaSet to run more or fewer Pods.
The Deployment updates the RS desired count and the RS handles the rest.

**Scale out (handle more traffic):**
```bash
kubectl scale deploy/webstore-frontend --replicas=5
```

**Scale in (reduce after traffic drops):**
```bash
kubectl scale deploy/webstore-frontend --replicas=3
```

When scaling in, Kubernetes uses LIFO (Last In, First Out) — the newest Pods
are terminated first. This is intentional: newer Pods are more likely to be
in the middle of a task than older, settled ones.

**Watch the scale happen in real time:**
```bash
kubectl get pods -w
```

The `-w` flag watches for changes. You will see Pods appear and disappear live.
Press `ctrl + c` to stop watching.

**Check the Deployment status after scaling:**
```bash
kubectl get deploy
```

Expected output:
```
NAME                READY   UP-TO-DATE   AVAILABLE   AGE
webstore-frontend   5/5     5            5           10m
```

| Column | Meaning |
|--------|---------|
| `READY` | Running Pods out of desired total |
| `UP-TO-DATE` | Pods running the latest template version |
| `AVAILABLE` | Pods passing health checks and ready for traffic |

---

## 8. The Full Debug Loop for Deployments

The same loop you built in Phase 02 — extended for Deployments.

```bash
# Step 1 — Lint before applying
yamllint webstore-frontend-deployment.yaml

# Step 2 — Apply
kubectl apply -f webstore-frontend-deployment.yaml

# Step 3 — Check Deployment health
kubectl get deploy

# Step 4 — Check the Pods it created
kubectl get pods

# Step 5 — Check the ReplicaSet
kubectl get rs

# Step 6 — Watch a rollout in progress
kubectl rollout status deploy/webstore-frontend

# Step 7 — Read the Deployment's event log
kubectl describe deploy/webstore-frontend

# Step 8 — Check rollout history
kubectl rollout history deploy/webstore-frontend
```

**Quick reference — all Deployment commands:**

| Command | When you use it |
|---------|----------------|
| `kubectl apply -f <file>` | Create or update a Deployment |
| `kubectl get deploy` | Check all Deployments and their ready count |
| `kubectl get rs` | See the ReplicaSets — old and new after updates |
| `kubectl get pods` | See the individual Pods the RS created |
| `kubectl describe deploy/<name>` | Full event log — errors appear here |
| `kubectl rollout status deploy/<name>` | Watch a rolling update in real time |
| `kubectl rollout history deploy/<name>` | See all previous revisions |
| `kubectl rollout undo deploy/<name>` | Emergency rollback to previous version |
| `kubectl set image deploy/<name> <c>=<image>` | Trigger a rolling update |
| `kubectl scale deploy/<name> --replicas=N` | Scale up or down |
| `kubectl get pods -w` | Watch Pod changes live |
| `kubectl delete deploy/<name>` | Delete the Deployment and all its Pods |

---

→ Ready to practice? [Go to Lab 03](../k8s-labs/03-deployments-lab.md)
