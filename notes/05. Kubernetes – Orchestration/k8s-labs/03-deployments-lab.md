[Home](../README.md) | [Labs Index](./README.md) | [Setup Lab](./00-setup-lab.md) | [Architecture Lab](./01-architecture-lab.md) | [YAML & Pods Lab](./02-yaml-pods-lab.md) | [Deployments Lab](./03-deployments-lab.md) | [Networking Lab](./03.5-networking-lab.md) | [State & Config Lab](./04-state-lab.md) | [Troubleshooting Lab](./05-troubleshooting-lab.md) | [Cloud & EKS Lab](./06-cloud-lab.md)

---

# Lab 03 — Deployments, ReplicaSets & Pod Management

## What This Lab Is About

In [03-deployments/README.md](../03-deployments/README.md) you learned the
Deployment → ReplicaSet → Pod hierarchy, rolling updates, rollbacks, and scaling.
This lab makes every one of those concepts real.

You will deploy all 3 tiers of webstore using Deployments, watch self-healing
happen live, trigger a rolling update and watch it progress in real time, perform
an emergency rollback, and scale under simulated load.

You are done with this lab when you can operate a Deployment — update, rollback,
scale, and debug — without referring to notes.

---

## Prerequisites

- Lab 02 complete — YAML and the debug loop are muscle memory
- [03-deployments/README.md](../03-deployments/README.md) read and understood
- Cluster running, K9s open in Tab 2

---

## Section 1 — Write All 3 Webstore Deployments From Scratch

No copy-paste. Write each file yourself.

### webstore-frontend Deployment

```bash
vi webstore-frontend-deployment.yaml
```

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webstore-frontend
  labels:
    app: webstore
    tier: frontend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: webstore
      tier: frontend
  template:
    metadata:
      labels:
        app: webstore
        tier: frontend
    spec:
      containers:
        - name: frontend-container
          image: nginx:1.24
          ports:
            - containerPort: 80
```

Lint and apply:

```bash
yamllint webstore-frontend-deployment.yaml
kubectl apply -f webstore-frontend-deployment.yaml
```

### webstore-api Deployment

```bash
vi webstore-api-deployment.yaml
```

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webstore-api
  labels:
    app: webstore
    tier: backend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: webstore
      tier: backend
  template:
    metadata:
      labels:
        app: webstore
        tier: backend
    spec:
      containers:
        - name: api-container
          image: nginx:1.24
          ports:
            - containerPort: 8080
```

```bash
yamllint webstore-api-deployment.yaml
kubectl apply -f webstore-api-deployment.yaml
```

### webstore-db Deployment

```bash
vi webstore-db-deployment.yaml
```

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webstore-db
  labels:
    app: webstore
    tier: database
spec:
  replicas: 1
  selector:
    matchLabels:
      app: webstore
      tier: database
  template:
    metadata:
      labels:
        app: webstore
        tier: database
    spec:
      containers:
        - name: db-container
          image: nginx:1.24
          ports:
            - containerPort: 3306
```

> Note: Using nginx as a placeholder for the database container — the real
> MariaDB Deployment with Secrets and PVC comes in Lab 04.

```bash
yamllint webstore-db-deployment.yaml
kubectl apply -f webstore-db-deployment.yaml
```

---

## Section 2 — Verify the Full Stack

Run the full stack health check:

```bash
kubectl get deploy
```

Expected — all 3 Deployments showing READY:
```
NAME                READY   UP-TO-DATE   AVAILABLE   AGE
webstore-api        3/3     3            3           Xs
webstore-db         1/1     1            1           Xs
webstore-frontend   3/3     3            3           Xs
```

If any Deployment shows less than full READY count — wait 30 seconds and run
again. If it still does not reach full count run `kubectl describe deploy/<name>`
and read the Events section.

```bash
kubectl get pods
```

Expected — 7 Pods total (3 frontend + 3 api + 1 db):
```
NAME                                 READY   STATUS    RESTARTS   AGE
webstore-api-xxx-xxx                 1/1     Running   0          Xs
webstore-api-xxx-xxx                 1/1     Running   0          Xs
webstore-api-xxx-xxx                 1/1     Running   0          Xs
webstore-frontend-xxx-xxx            1/1     Running   0          Xs
webstore-frontend-xxx-xxx            1/1     Running   0          Xs
webstore-frontend-xxx-xxx            1/1     Running   0          Xs
webstore-db-xxx-xxx                  1/1     Running   0          Xs
```

```bash
kubectl get rs
```

Expected — one RS per Deployment:
```
NAME                          DESIRED   CURRENT   READY   AGE
webstore-api-5c6b7a8d9        3         3         3       Xs
webstore-db-7d9f8b6c4         1         1         1       Xs
webstore-frontend-6f8c9d2e1   3         3         3       Xs
```

**In K9s (Tab 2):**
Press `0` to see all namespaces. You should see all 7 Pods running in green.
Navigate through them — this is what a healthy 3-tier stack looks like.

---

## Section 3 — Self-Healing Drill

This is the most important thing to prove with your own hands.

Watch the Pod count in K9s (Tab 2). In Tab 1, copy the exact name of one
frontend Pod from `kubectl get pods` and delete it:

```bash
kubectl delete pod <webstore-frontend-pod-name>
```

Watch K9s immediately — the deleted Pod disappears and a new one appears within
seconds. The ReplicaSet detected the count dropped from 3 to 2 and created a
replacement.

Confirm it:
```bash
kubectl get pods
```

Still 7 Pods. Still 3 frontend. Different name on the replacement — new Pod,
same label, same job.

**Repeat this for the api tier.** Delete one api Pod and watch the replacement
appear. The behaviour is identical because every Deployment has its own RS doing
the same job.

---

## Section 4 — Rolling Update Drill

You will update the frontend from `nginx:1.24` to `nginx:1.25` and watch the
entire process live.

Open a third terminal tab and run the watcher:

```bash
kubectl get pods -w
```

Leave this running. In Tab 1 trigger the update:

```bash
kubectl set image deploy/webstore-frontend \
  frontend-container=nginx:1.25
```

Watch Tab 3 — you will see old Pods terminating and new Pods being created one
by one. Traffic never fully drops because Kubernetes waits for each new Pod to
be healthy before terminating the next old one.

In Tab 1 immediately run:

```bash
kubectl rollout status deploy/webstore-frontend
```

Watch it progress:
```
Waiting for deployment "webstore-frontend" rollout to finish:
1 out of 3 new replicas have been updated...
2 out of 3 new replicas have been updated...
3 out of 3 new replicas have been updated...
Waiting for 3 pods to be ready...
deployment "webstore-frontend" successfully rolled out
```

After it completes check the ReplicaSets:

```bash
kubectl get rs
```

You will now see TWO frontend ReplicaSets:
```
NAME                          DESIRED   CURRENT   READY   AGE
webstore-frontend-6f8c9d2e1   0         0         0       10m   ← old (nginx:1.24)
webstore-frontend-7d9f8b6c4   3         3         3       2m    ← new (nginx:1.25)
```

The old RS is kept at 0 — not deleted. This is your rollback parachute.

Check the rollout history:

```bash
kubectl rollout history deploy/webstore-frontend
```

```
REVISION  CHANGE-CAUSE
1         <none>
2         <none>
```

---

## Section 5 — Break a Rolling Update

You will trigger a bad update and watch it get stuck.

```bash
kubectl set image deploy/webstore-frontend \
  frontend-container=nginx:doesnotexist999
```

Immediately run:

```bash
kubectl rollout status deploy/webstore-frontend
```

It will hang:
```
Waiting for deployment "webstore-frontend" rollout to finish:
1 out of 3 new replicas have been updated...
(hangs — never progresses)
```

Press `ctrl + c` to stop watching. Check the Pods:

```bash
kubectl get pods
```

You will see a mix — some old Pods still running (good — traffic still flowing)
and one new Pod stuck in `ImagePullBackOff`.

Diagnose the stuck Pod:

```bash
kubectl describe pod <stuck-pod-name>
```

Scroll to Events — find the image pull error. This is how a bad rollout looks
in production. The old Pods keep running so the application stays up while you
investigate.

---

## Section 6 — Emergency Rollback

The bad image is deployed. Roll it back now:

```bash
kubectl rollout undo deploy/webstore-frontend
```

Watch it recover:

```bash
kubectl rollout status deploy/webstore-frontend
```

After completion check the RS:

```bash
kubectl get rs
```

The old RS (nginx:1.24) scaled back up to 3. The bad RS scaled down to 0.
Kubernetes swapped them — no new objects, no manual Pod recreation.

Verify all Pods are healthy:

```bash
kubectl get pods
kubectl get deploy
```

All 7 Pods running, all 3 Deployments at full READY count.

---

## Section 7 — Scaling Drill

Scale the frontend up to handle a traffic spike:

```bash
kubectl scale deploy/webstore-frontend --replicas=5
```

Watch it in K9s — 2 new frontend Pods appear. Check:

```bash
kubectl get deploy webstore-frontend
```

```
NAME                READY   UP-TO-DATE   AVAILABLE   AGE
webstore-frontend   5/5     5            5           Xm
```

Scale back down:

```bash
kubectl scale deploy/webstore-frontend --replicas=3
```

Watch K9s — 2 Pods terminate (the newest ones first — LIFO). Confirm:

```bash
kubectl get deploy webstore-frontend
```

Back to `3/3`.

---

## Section 8 — Clean Up

Delete all 3 Deployments. This also deletes all their ReplicaSets and Pods:

```bash
kubectl delete deploy webstore-frontend
kubectl delete deploy webstore-api
kubectl delete deploy webstore-db
```

Verify everything is gone:

```bash
kubectl get deploy
kubectl get rs
kubectl get pods
```

All three should return `No resources found in default namespace.`

---

## Lab Complete — You Are Ready For Lab 03.5 When

- [ ] You wrote all 3 Deployment manifests from scratch with no copy-paste
- [ ] You watched self-healing happen live — deleted a Pod and saw the RS replace it
- [ ] You triggered a rolling update and watched `kubectl rollout status` progress line by line
- [ ] You saw what TWO ReplicaSets look like after an update — old at 0, new at 3
- [ ] You triggered a bad update, watched it get stuck, diagnosed the error, and rolled back
- [ ] You scaled up to 5 and back down to 3 and confirmed LIFO termination order
- [ ] `kubectl get deploy`, `kubectl get rs`, `kubectl get pods` feel like one natural sequence

If any box is unchecked — repeat the relevant section.
Do not move to Lab 03.5 until all seven are checked.
