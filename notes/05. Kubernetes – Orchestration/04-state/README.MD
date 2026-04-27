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
