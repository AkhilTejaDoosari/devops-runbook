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
