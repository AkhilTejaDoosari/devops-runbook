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
