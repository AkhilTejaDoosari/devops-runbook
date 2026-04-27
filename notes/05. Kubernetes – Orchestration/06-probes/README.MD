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
