[← devops-runbook](../../README.md) | [Labs Index](./README.md) | [Lab 00](./00-setup-lab.md) | [Lab 01](./01-architecture-lab.md) | [Lab 02](./02-yaml-pods-lab.md) | [Lab 03](./03-deployments-lab.md) | [Lab 03.5](./03.5-networking-lab.md) | [Lab 04](./04-state-lab.md) | [Lab 05](./05-troubleshooting-lab.md) | [Lab 06](./06-cicd-lab.md) | [Lab 07](./07-observability-lab.md) | [Lab 08](./08-cloud-lab.md)

---

# Lab 02 — YAML & Pods

## What This Lab Is About

In [02-yaml-pods/README.md](../02-yaml-pods/README.md) you learned the 4 pillars
of a manifest, Labels and Selectors, and the debug loop. This lab puts all of it
into practice using the webstore application — a 3-tier app you will build on
through every lab from here forward.

By the end of this lab you will have written real manifests from scratch, deployed
them, broken them intentionally, and debugged them using the professional workflow.

You are done with this lab when the full debug loop — write, lint, apply, inspect,
fix — is reflex with no hesitation.

---

## Prerequisites

- Lab 01 complete — you can read a live cluster confidently
- [02-yaml-pods/README.md](../02-yaml-pods/README.md) read and understood
- Cluster running, K9s open in Tab 2

---

## Section 1 — Write Your First Real Manifest

You will write the webstore frontend Pod from scratch. No copy-paste.
Open Tab 1 and create the file:

```bash
vi webstore-frontend-pod.yaml
```

Press `i` to enter insert mode and type this out:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: webstore-frontend
  labels:
    app: webstore
    tier: frontend
    env: dev
spec:
  containers:
    - name: frontend-container
      image: nginx:latest
      ports:
        - containerPort: 80
```

Save and exit: `Esc` then `:wq`

Before applying — lint it:

```bash
yamllint webstore-frontend-pod.yaml
```

Clean output only. If yamllint returns errors, fix them before continuing.

Apply it:

```bash
kubectl apply -f webstore-frontend-pod.yaml
```

Expected: `pod/webstore-frontend created`

---

## Section 2 — The Health Check Loop

Run these three commands in sequence. This is your standard check after every
apply — build it into reflex:

```bash
kubectl get pods
```

Expected:
```
NAME                 READY   STATUS    RESTARTS   AGE
webstore-frontend    1/1     Running   0          Xs
```

`1/1` means 1 container running out of 1 total. `Running` with `0` restarts
is the only healthy state. Anything else — stop and investigate before continuing.

```bash
kubectl describe pod webstore-frontend
```

Scroll to the `Events` section at the bottom. A healthy Pod looks like this:

```
Events:
  Normal  Scheduled  Xs    default-scheduler  Successfully assigned default/webstore-frontend
  Normal  Pulling    Xs    kubelet            Pulling image "nginx:latest"
  Normal  Pulled     Xs    kubelet            Successfully pulled image
  Normal  Created    Xs    kubelet            Created container frontend-container
  Normal  Started    Xs    kubelet            Started container frontend-container
```

Read every event line. This sequence is what a healthy Pod birth looks like.
Memorise it — so when something goes wrong you immediately spot where it broke.

```bash
kubectl logs webstore-frontend
```

You will see nginx startup logs. This is what the container printed to stdout.
In a real app this is where your application errors appear.

**In K9s (Tab 2):**
- Navigate to `webstore-frontend`
- Press `d` — confirm the same events you saw in describe
- Press `l` — confirm the same logs
- Press `esc` to go back

---

## Section 3 — Labels and Selectors in Practice

Labels are not decoration. Prove they work:

```bash
kubectl get pods -l app=webstore
```

Expected: returns `webstore-frontend` — the label filter found your Pod.

```bash
kubectl get pods -l tier=frontend
```

Expected: same result — different label, same Pod.

```bash
kubectl get pods -l tier=backend
```

Expected: `No resources found` — nothing is wearing that badge yet.

Now write the webstore backend Pod. Open a new file:

```bash
vi webstore-api-pod.yaml
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: webstore-api
  labels:
    app: webstore
    tier: backend
    env: dev
spec:
  containers:
    - name: api-container
      image: nginx:latest
      ports:
        - containerPort: 8080
```

Lint, apply, verify:

```bash
yamllint webstore-api-pod.yaml
kubectl apply -f webstore-api-pod.yaml
kubectl get pods
```

Now run the label filters again:

```bash
kubectl get pods -l app=webstore
```

Expected: both `webstore-frontend` and `webstore-api` — same app label.

```bash
kubectl get pods -l tier=backend
```

Expected: only `webstore-api` — tier label separates them.

This is exactly how Services find Pods in production. Not by name. Not by IP.
By label.

---

## Section 4 — Break It On Purpose

This section trains your eye for error states. You need to recognise them
instantly under pressure.

### Break 1 — Bad Image Name

```bash
vi webstore-broken-pod.yaml
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: webstore-broken
  labels:
    app: webstore
    tier: broken
spec:
  containers:
    - name: broken-container
      image: nginx:doesnotexist999
      ports:
        - containerPort: 80
```

```bash
yamllint webstore-broken-pod.yaml
kubectl apply -f webstore-broken-pod.yaml
kubectl get pods
```

Watch in K9s — the Pod will cycle through states and land on `ImagePullBackOff`.

Now diagnose it:

```bash
kubectl describe pod webstore-broken
```

Scroll to `Events`. Find this line:
```
Failed to pull image "nginx:doesnotexist999": rpc error: ... not found
```

This is the `ImagePullBackOff` error signature. Every time you see this status
you know exactly where to look and what it means.

Clean it up:
```bash
kubectl delete pod webstore-broken
```

### Break 2 — Bad YAML Syntax

```bash
vi webstore-badsyntax-pod.yaml
```

Type this with the deliberate indentation error on `name`:

```yaml
apiVersion: v1
kind: Pod
metadata:
name: webstore-badsyntax
  labels:
    app: webstore
spec:
  containers:
    - name: syntax-container
      image: nginx:latest
```

Run yamllint before applying:

```bash
yamllint webstore-badsyntax-pod.yaml
```

yamllint catches it immediately — the API Server never even sees this file.
This is exactly why you lint before every apply.

Fix the indentation, lint again, confirm it is clean, then delete the file:

```bash
rm webstore-badsyntax-pod.yaml
```

---

## Section 5 — The Full Debug Loop Drill

This is the complete professional workflow. Run it until the sequence is reflex.

```bash
# 1. Write
vi webstore-db-pod.yaml
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: webstore-db
  labels:
    app: webstore
    tier: database
    env: dev
spec:
  containers:
    - name: db-container
      image: mariadb:latest
      ports:
        - containerPort: 3306
```

```bash
# 2. Lint
yamllint webstore-db-pod.yaml

# 3. Apply
kubectl apply -f webstore-db-pod.yaml

# 4. Health check
kubectl get pods

# 5. Read the birth certificate
kubectl describe pod webstore-db

# 6. Read the logs
kubectl logs webstore-db
```

Note: `webstore-db` will likely show `CrashLoopBackOff` — MariaDB requires
environment variables like `MYSQL_ROOT_PASSWORD` to start. It crashes without them.

This is intentional. Read the logs:

```bash
kubectl logs webstore-db
```

You will see MariaDB print exactly why it crashed. The logs always tell you
what is wrong — you just need to know to look there.

This is a preview of Phase 04 — State & Config — where you will fix this using
Secrets and ConfigMaps. For now, clean up:

```bash
kubectl delete pod webstore-db
```

---

## Section 6 — Clean Up

Delete all pods from this lab:

```bash
kubectl delete pod webstore-frontend
kubectl delete pod webstore-api
```

Verify the cluster is clean:

```bash
kubectl get pods
```

Expected: `No resources found in default namespace.`

---

## Lab Complete — You Are Ready For Lab 03 When

- [ ] You wrote all 3 webstore manifests from scratch with no copy-paste
- [ ] `yamllint` before every apply is automatic — you did not skip it once
- [ ] You can read the Events section of `kubectl describe` and know what healthy looks like
- [ ] You saw `ImagePullBackOff` live and found the exact error in the Events section
- [ ] You understand why `webstore-db` crashed and what Phase 04 will fix
- [ ] Label filters with `-l` make sense — you used them to find Pods by tier

If any box is unchecked — repeat the relevant section.
Do not move to Lab 03 until all six are checked.
