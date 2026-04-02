[Home](../README.md) | [Setup](../00-setup/README.md) | [Architecture](../01-architecture/README.md) | [YAML & Pods](../02-yaml-pods/README.md) | [Deployments](../03-deployments/README.md) | [Networking](../03.5-networking/README.md) | [State & Config](../04-state/README.md) | [Troubleshooting](../05-troubleshooting/README.md) | [Cloud & EKS](../06-cloud/README.md)

# 02 — YAML Basics & The Pod

---

## What This File Is About

In Phase 1, you learned the theory **how things work under the hood**. In Phase 2, you move to the **Language**.   
This file covers YAML syntax, the anatomy of a Manifest, and how to deploy a Pod — the smallest unit of work in Kubernetes.

---

## Table of Contents

1. [The Concept — Declarative vs Imperative](#1-the-concept--declarative-vs-imperative)
2. [The 4 Pillars of a Manifest](#2-the-4-pillars-of-a-manifest)
3. [Labels and Selectors — The Glue](#3-labels-and-selectors--the-glue)
4. [The Anatomy of a Pod](#4-the-anatomy-of-a-pod)
5. [The DevOps Workflow — kubectl + vi](#5-the-devops-workflow--kubectl--vi)
6. [Action Step](#6-action-step)

---

## 1. The Concept — Declarative vs Imperative

In traditional IT, you give direct commands: *"Start this container."* That is **Imperative** — you describe the steps.

In Kubernetes, you use **Declarative Management**:

- **You:** Provide a YAML file saying, *"This is the Desired State I want."*
- **Kubernetes:** The Control Plane constantly compares your file to the cluster and acts to match it.

You stop telling Kubernetes *how* to do things. You tell it *what* you want, and it figures out the rest.

---

## 2. The 4 Pillars of a Manifest

Every Kubernetes object starts with the same skeleton. Before you write a single container name or port number, you must declare these four fields. The API Server reads them first — if any one is missing or wrong, it rejects the entire file before even looking at the rest.

A Kubernetes object is anything you can create, store, and manage in the cluster — every kind in your manifest table is an object, just a different type of record stored in etcd that the Control Plane works to keep alive.

Here is a real ChillSpot Pod manifest. Read the comments — every pillar is labelled inline:
```yaml
apiVersion: v1          # PILLAR 1 — Which version of the K8s API dictionary to use.
                        # 'v1' covers core objects: Pod, Service, ConfigMap, Secret.
                        # Newer objects like Deployment use 'apps/v1'.

kind: Pod               # PILLAR 2 — What TYPE of object you are creating.
                        # The API Server reads this first to know what rules apply.
                        # Change this one word and you get a completely different object.

metadata:
  name: chillspot-api         # PILLAR 3 — The identity card of this object. 
                              # Naming convention: projectname-role
                              # 'chillspot' = the project
                              # 'api' = this Pod's role — API stands for Application Programming Interface
                              # It is the backend service that receives requests and returns data
                              # e.g. "give me the list of movies" → API processes it → sends back the data
                              # Other real examples: payments-api, auth-api, analytics-api
  labels:
    app: chillspot            # The badge. Services and controllers find this Pod using this.
    env: dev                  # Environment tag — useful when you have dev/prod later

spec:                         # PILLAR 4 — The Blueprint. What should actually exist inside.
  containers:
    - name: api-container     # Container name inside the Pod.
                              # Convention: role-container (matches the Pod's role above)
      image: nginx:latest     # nginx = a real production web server, used here as a placeholder.
                              # It starts instantly and stays running — perfect for practice.
                              # In real ChillSpot this becomes your actual app image:
                              # e.g. starkwolf/chillspot-api:1.0
      ports:
        - containerPort: 80   # Port the container listens on inside the Pod
```

### The 4 Pillars — Explained

**`apiVersion`** is the version of the Kubernetes API you are targeting.   
Think of it as telling the API Server which rulebook to open. Core objects like Pods and Services use `v1`. More advanced objects like Deployments and ReplicaSets live in the `apps/v1` group because they were added later. If you use the wrong version for a `kind`, the API Server rejects it immediately.

**`kind`** is the single most important field.   
It tells Kubernetes *what* you are asking it to create. One word — `Pod`, `Deployment`, `Service` — completely changes what the rest of the file means. The API Server uses this to decide which controller should handle your request. `kind` is **case sensitive** — `pod` and `Pod` are not the same thing, the API Server will reject it. Always write it exactly as shown: first letter uppercase, rest lowercase.

**`metadata`** is the identity card of the object.   
The `name` field must be unique within a Namespace. The `labels` block is where you attach tags — covered fully in Section 3, but notice it lives here, inside `metadata`, not inside `spec`.

**`spec`** is the blueprint — the "what should exist" section.   
Everything from here down is specific to the `kind` you declared. A Pod's `spec` holds containers. A Service's `spec` holds ports and selectors. A Deployment's `spec` holds replicas and a template. Same pillar, completely different content depending on the `kind`.

---

## 3. Labels and Selectors — The Glue

### Why "Label"? Why "Selector"?

The names are exactly what they sound like.

A **Label** is a stamp you press onto a Kubernetes object. Like a name badge at a conference — it does not change what the object *is*, it just gives it a tag that others can read. In Kubernetes, labels are simple key-value pairs you write in the `metadata` section: `app: chillspot`, `env: production`, `tier: backend`.

A **Selector** is a search filter. It does not create anything new — it just copies the same label value and uses it to hunt for matching objects. A Service with `selector: app: chillspot` is saying *"go check etcd and bring me every Pod in the cluster that has `app: chillspot` stamped on it."*

**Same value. Two different roles:**

```yaml
# POD — this is where the label is CREATED (you are stamping this onto the Pod)
metadata:
  labels:
    app: chillspot      # ← THE LABEL. The stamp.

# SERVICE — this is where the label is USED as a search filter
spec:
  selector:
    app: chillspot      # ← SAME VALUE. "Find every Pod stamped with this."
```

The reason this system exists is because **Pods are ephemeral**. Every time a Pod dies and gets replaced, it gets a brand new name and a brand new IP address. If a Service tracked Pods by IP, it would lose them constantly. Instead, every new Pod just wears the same label as the one it replaced — and everything watching for that label picks it up instantly with zero reconfiguration.

---

### The Full Picture — Pod + Service Together

Here is the complete ChillSpot setup. Read both files as one connected system:

```yaml
# FILE 1 — chillspot-pod.yaml
# The Pod is the laborer. It wears the name badge.

apiVersion: v1
kind: Pod
metadata:
  name: chillspot-api
  labels:
    app: chillspot      # STAMP — this Pod is wearing the "chillspot" badge
spec:
  containers:
    - name: api-container
      image: nginx:latest
      ports:
        - containerPort: 80
```

```yaml
# FILE 2 — chillspot-service.yaml
# The Service is the router. It finds Pods by their badge.

apiVersion: v1
kind: Service
metadata:
  name: chillspot-service
spec:
  type: LoadBalancer    # HOW the Service is exposed to the world
                        # (LoadBalancer, NodePort, ClusterIP — covered in Phase 3.5)

  selector:             # WHO this Service sends traffic TO
    app: chillspot      # "Find every Pod wearing this badge and route traffic to them"

  ports:
    - port: 80          # WHAT port this Service listens on from the outside
      targetPort: 80    # What port to forward to inside the Pod
```

Think of it like a delivery service:

- **`type`** = the delivery method. Internal office mail only (ClusterIP)? A side door with a specific number (NodePort)? A full public address anyone on the internet can reach (LoadBalancer)?
- **`selector`** = the address label on the package. The delivery service does not care how many people live at that address — it just drops the package wherever it sees the matching label.
- **`ports`** = the door number. Knock on port 80 from outside, it gets forwarded to port 80 inside the Pod.

These three are completely independent. Change `type` without touching `selector`. Point `selector` at a different app without touching `ports`.

---

### The Real-World Example — ChillSpot Goes Viral

It is 2 AM. ChillSpot gets a traffic spike. Kubernetes scales from 1 Pod to 5. All 5 get completely random names and brand new IP addresses:

```
chillspot-api-x7k2p   →  IP: 10.0.0.4
chillspot-api-m9nq1   →  IP: 10.0.0.7
chillspot-api-p3vc8   →  IP: 10.0.0.11
chillspot-api-h6zt4   →  IP: 10.0.0.15
chillspot-api-r2bw9   →  IP: 10.0.0.19
```

The Service does not track names. Does not track IPs. It looks for `app: chillspot`. All 5 Pods are wearing that badge — so the Service finds all 5 instantly and load balances across them. When traffic drops and 4 Pods get terminated, the Service stops seeing their badges and stops routing to them. No config change. No restart.

**What breaks without labels:** Two apps in the same cluster — ChillSpot API and an admin dashboard. Both running Pods. Without labels, the Service has no way to know which Pods belong to which app. User streaming traffic goes to the admin dashboard. Admin traffic goes to the API. Everything breaks.

That one line — `app: chillspot` — is what keeps them separated.

> **The Rule:** The label on the Pod and the selector on the Service must be an **exact match**. One typo and they are completely invisible to each other. This is the most common beginner misconfiguration in Kubernetes.

---

### The 3 Superpowers Labels Unlock

**1. Networking — Services find Pods dynamically** (shown above) → Phase 3.5

**2. Scaling and Self-Healing — ReplicaSets count by label**
When you tell a ReplicaSet *"I want 3 copies running"*, it does not track Pod names — it counts how many Pods are currently wearing its label. If it counts 2, it creates a new one. If it counts 4, it terminates one. → Phase 3

**3. Node Placement — Labels on Nodes, not just Pods**
You can label Worker Nodes too. Label two nodes `storage: ssd`. Then tell a database Pod *"only schedule me on a Node with storage: ssd"*. The Scheduler reads that and guarantees the Pod only lands on the right hardware. → Phase 6

> **The architectural reality:** Labels and Selectors are not running software. They are pure text metadata stored in etcd. When a Service needs its Pods, it asks the API Server: *"Check etcd, give me the IPs of every Pod with this label."* The Control Plane does the rest.

---

## 4. The Anatomy of a Pod

A Pod is the smallest deployable unit in Kubernetes. Think of it as a **Space Shuttle** — a protective shell that carries your containers into the cluster and gives them everything they need to survive: an identity, a network, and storage.

Kubernetes never runs a naked container. It always wraps it in a Pod first. Here is why that wrapper exists and what every line inside it actually does:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: chillspot-api       # The unique name of this Pod inside the cluster.
                            # When this Pod dies, the replacement gets a new random name.
                            # You never rely on this name to find Pods — you use labels.
  labels:
    app: chillspot          # The badge. Services and controllers find this Pod using this.
    env: dev                # You can stack multiple labels on one Pod.

spec:
  containers:               # A Pod can hold MORE than one container.
                            # All containers in this list share the same IP and storage.
    - name: api-container   # The name of THIS container inside the Pod.
      image: nginx:latest   # The Docker image to pull. This is what actually runs.
                            # 'latest' means always pull the newest version.
                            # In production you pin this to a specific version e.g. nginx:1.25
      ports:
        - containerPort: 80 # The port THIS container listens on INSIDE the Pod.
                            # This is documentation — it does not actually open or block ports.
                            # The Service's targetPort is what routes traffic here.
```

**The Shared Environment** is the whole reason the Pod abstraction exists. All containers listed in the `spec` share the same network namespace — meaning they share one IP address and talk to each other via `localhost`. They also share the same storage volumes. This is how the Sidecar pattern works — one container runs the app, another runs alongside it handling logs or proxying — both living in the same Pod, sharing everything. → Sidecar covered in Phase 3.5.

**One IP per Pod** — every Pod gets its own internal cluster IP the moment it is born. That IP dies with the Pod. This is exactly why you never hardcode IPs anywhere — you use labels and selectors instead.

**Ephemeral (Temporary)** — Pods are disposable by design. If a standalone Pod dies, it stays dead. Kubernetes does not resurrect it — a Controller detects the death and creates a brand new replacement Pod with a new name and new IP. The old Pod is gone forever. Self-healing is not a Pod feature — it is a Controller feature. → Covered in Phase 3.

> **ChillSpot angle:** Every ChillSpot API request — streaming metadata, fetching content, authenticating users — is handled inside a Pod. That Pod is the isolated unit of compute that owns the job. When traffic spikes and Kubernetes needs 5 copies, it does not clone the Pod — it creates 5 fresh ones, all wearing the same `app: chillspot` badge, all picked up instantly by the Service.

---

## 5. The DevOps Workflow — kubectl + vi

The professional toolkit has no GUIs. You write manifests in the terminal, apply them, and read the cluster's response directly. Here is the full loop from writing a file to verifying it is healthy:

```bash
# Step 1 — Write the manifest
vi chillspot-pod.yaml
# Use 'i' to enter insert mode, write your YAML, then ':wq' to save and exit.

# Step 2 — Apply it (send your Desired State to the API Server)
kubectl apply -f chillspot-pod.yaml
# Expected output:
# pod/chillspot-api created

# Step 3 — Check the Pod status
kubectl get pods
# Expected output when healthy:
# NAME             READY   STATUS    RESTARTS   AGE
# chillspot-api    1/1     Running   0          10s
#
# READY 1/1   = 1 container running out of 1 total
# STATUS      = Running means Pod is alive and healthy
# RESTARTS 0  = nothing has crashed yet

# Step 4 — Read the birth certificate (when something looks wrong)
kubectl describe pod chillspot-api
# This prints the full event log of the Pod's life.
# Scroll to the EVENTS section at the bottom — this is where errors appear.
# Common things you will see here:
#   "Pulling image nginx:latest"      → K8s is downloading the image
#   "Started container api-container" → container came up clean
#   "Back-off pulling image"          → image name is wrong or does not exist
#   "CrashLoopBackOff"                → container starts then immediately dies

# Step 5 — Monitor everything in real time
k9s
# Your live cockpit. Press 0 to see all namespaces.
# Arrow keys to navigate, 'd' to describe, 'l' to see logs, 'ctrl+d' to delete.
```

| Tool | What it does | When you use it |
|---|---|---|
| `vi` | Write and edit YAML manifests in the terminal | Every time you create or change a manifest |
| `kubectl apply -f` | Send Desired State to the API Server | After every save |
| `kubectl get pods` | Quick health check — status and restart count | After applying, or when something feels off |
| `kubectl describe pod` | Full event log — the Pod's birth certificate | When status is not `Running` or restarts are climbing |
| `kubectl logs [pod]` | Print what the container printed to stdout | When the Pod is running but the app inside is broken |
| `k9s` | Real-time visual cockpit for the whole cluster | Keep this open in Tab 2 at all times |

---

## 6. Action Step

Deploy the ChillSpot API Pod and verify it is healthy. This is the full loop — write, apply, inspect:

```yaml
# chillspot-pod.yaml
# Your first real manifest. Every field here maps to a concept in this file.

apiVersion: v1                # Core object — uses v1
kind: Pod                     # Creating a Pod (the smallest unit)
metadata:
  name: chillspot-api         # The Pod's identity inside the cluster
  labels:
    app: chillspot            # The badge — Services will use this to find it
    env: dev                  # Environment tag — useful when you have dev/prod later
spec:
  containers:
    - name: api-container     # Container name inside the Pod
      image: nginx:latest     # The image to run — swap this for your actual app later
      ports:
        - containerPort: 80   # Port the container listens on inside the Pod
```

```bash
# Deploy it
kubectl apply -f chillspot-pod.yaml

# Verify it came up healthy
kubectl get pods

# What you should see:
# NAME             READY   STATUS    RESTARTS   AGE
# chillspot-api    1/1     Running   0          <10s

# Open your cockpit and watch it live
k9s
```

**What success looks like in K9s:**
- Status column shows `Running` in green
- Ready shows `1/1`
- Restarts shows `0`

**What a broken Pod looks like:**
- `ImagePullBackOff` → the image name is wrong or does not exist
- `CrashLoopBackOff` → the container starts and immediately crashes
- `Pending` → the Scheduler cannot find a Node to place it on

If you see any of these, run `kubectl describe pod chillspot-api` and scroll to the Events section at the bottom. The answer is always there. → Full troubleshooting toolkit in Phase 5.

→ Ready to practice? [Go to Lab 02](../labs/02-yaml-pods-lab.md)
