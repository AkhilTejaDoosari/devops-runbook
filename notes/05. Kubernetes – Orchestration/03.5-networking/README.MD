[Home](../README.md) | [Setup](../00-setup/README.md) | [Architecture](../01-architecture/README.md) | [YAML & Pods](../02-yaml-pods/README.md) | [Deployments](../03-deployments/README.MD) | [Networking](../03.5-networking/README.MD) | [State](../04-state/README.MD) | [Troubleshooting](../05-troubleshooting/README.MD) | [Probes](../06-probes/README.MD) | [Namespaces](../07-namespaces/README.md) | [kubectl Reference](../08-kubectl-reference/README.md) | [Interview Prep](../99-interview-prep/README.md)

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
