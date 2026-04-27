[Home](../README.md) | [Setup](../00-setup/README.md) | [Architecture](../01-architecture/README.md) | [YAML & Pods](../02-yaml-pods/README.md) | [Deployments](../03-deployments/README.md) | [Networking](../03.5-networking/README.md) | [State](../04-state/README.md) | [Troubleshooting](../05-troubleshooting/README.md) | [Probes](../06-probes/README.md) | [Namespaces](../07-namespaces/README.md) | [kubectl Reference](../08-kubectl-reference/README.md) | [Interview Prep](../99-interview-prep/README.md)

---

# 99 — Interview Prep

> **The rule:** Answer every question out loud in 30 seconds without looking at notes. If you cannot — the concept is not owned yet. Go back to the relevant file and read it again.

---

## How to use this file

Read a question. Cover the answer. Say it out loud. Reveal the answer. Check yourself. A concept you can write is not the same as a concept you can say under pressure in an interview room.

These 10 questions cover the concepts an interviewer asks in a junior-to-mid DevOps screen when they see Kubernetes on your resume. Every answer is written the way you say it — not the way a textbook explains it.

---

## Q1 — What is Kubernetes and why does it exist?

<details>
<summary>Answer</summary>

Kubernetes is a container orchestration platform. Docker lets you run containers, but Docker alone cannot keep them running at scale — if a container crashes at 3 AM it stays down until someone manually restarts it, and scaling means SSH-ing into machines and starting containers by hand.

Kubernetes solves this. You declare the desired state — "I want 2 copies of the ShopStack API running at all times" — and Kubernetes enforces it continuously. If a Pod crashes, it creates a replacement automatically. If you need to scale, one command changes the replica count. If you need to deploy a new version, it swaps containers one by one with zero downtime.

The core shift: you stop telling the system *how* to do things. You tell it *what* you want, and it figures out the rest.

</details>

---

## Q2 — What is a Pod?

<details>
<summary>Answer</summary>

A Pod is the smallest deployable unit in Kubernetes. Kubernetes never runs a naked container — it always wraps it in a Pod first. A Pod is a wrapper around one or more containers that share a network namespace and storage volumes. All containers in a Pod share the same IP address and communicate via localhost.

In ShopStack, the API container runs inside a Pod. That Pod gets an IP address. When the Pod dies, that IP is gone — which is why Services exist to provide a stable endpoint in front of it.

</details>

---

## Q3 — What is the difference between a Pod and a Deployment?

<details>
<summary>Answer</summary>

A bare Pod has no guardian. If you delete it or it crashes, it stays dead. Kubernetes does not recreate it automatically.

A Deployment is a declaration of desired state — "I want 2 replicas of this Pod running at all times." The Deployment creates a ReplicaSet, which watches the actual Pod count and creates or terminates Pods to match the desired number.

In production you never run bare Pods for anything that matters. You always use a Deployment. If the API Pod crashes, the Deployment detects the count dropped from 2 to 1 and creates a replacement — automatically, in seconds, without any manual intervention.

</details>

---

## Q4 — What is a Kubernetes Service and why is it needed?

<details>
<summary>Answer</summary>

A Service is a stable network endpoint for a set of Pods. Pods are ephemeral — every time one dies and gets replaced it gets a brand new IP address. If the ShopStack API Pod talked to the database Pod directly by IP, any DB restart would break the connection permanently.

A Service has a stable ClusterIP and a DNS name that never changes. The API connects to `db` — Kubernetes DNS resolves that to the db Service's stable IP. The Service routes to whichever db Pod is currently running. When the Pod restarts with a new IP, the Service updates automatically. The API never notices.

</details>

---

## Q5 — What is the difference between ClusterIP, NodePort, and LoadBalancer?

<details>
<summary>Answer</summary>

ClusterIP is the default. The Service is only reachable from inside the cluster. I use this for the ShopStack API and database — they only need to talk to each other, not to the outside world.

NodePort exposes the Service on a static port on every node — in my setup port 30080 on the EC2 instance. Anyone who can reach the EC2 IP and that port can reach the Service. I use this for the ShopStack frontend during development.

LoadBalancer provisions a cloud load balancer — on EKS this creates an AWS ALB with a public DNS name. This is how you expose a service to the internet in production. NodePort is fine for learning but you would never expose raw EC2 ports in production.

</details>

---

## Q6 — What is a liveness probe? What is a readiness probe? What is the difference?

<details>
<summary>Answer</summary>

A liveness probe asks: is this container still functioning? Kubernetes hits an endpoint on a schedule. If it fails three times in a row, Kubernetes kills the container and starts a fresh one. This handles deadlocked processes — the container is running but not doing useful work.

A readiness probe asks: is this container ready to receive traffic? If it fails, Kubernetes removes the Pod from the Service's endpoint list — traffic stops going to it — but the container is not restarted. When the probe passes again, the Pod is added back to the endpoints.

The critical difference: liveness failure causes a restart. Readiness failure causes traffic removal, no restart. A Pod can be alive but not ready — for example, still loading a database connection pool on startup.

On the ShopStack API, both probes hit `/api/health`. If the API hangs, liveness kills and restarts it. During startup, readiness holds traffic back until the DB connection is established.

</details>

---

## Q7 — What is a PersistentVolumeClaim and why does Postgres need one?

<details>
<summary>Answer</summary>

A PersistentVolumeClaim is a request for disk storage. You declare "I need 5GB" and Kubernetes finds or provisions a PersistentVolume that satisfies the claim and binds them together.

Postgres needs a PVC because container filesystems are ephemeral — when the Pod restarts, the container's filesystem is destroyed, and Postgres starts fresh with an empty database. Every row, every order, every product record is wiped.

With a PVC, the data lives on a separate volume that persists across Pod restarts. When the Postgres Pod restarts, the new Pod mounts the same volume and Postgres continues from where it left off — data intact.

</details>

---

## Q8 — What is the difference between a Secret and a ConfigMap?

<details>
<summary>Answer</summary>

Both inject configuration into Pods as environment variables. The difference is the sensitivity of the data.

A ConfigMap stores non-sensitive configuration — database hostname, port number, feature flags. Things you would be comfortable committing to a public GitHub repo.

A Secret stores sensitive data — passwords, API keys, tokens. The values are base64 encoded. Base64 is encoding, not encryption — anyone can decode it — but it keeps credentials out of plain YAML that gets committed to version control.

In ShopStack, `DB_HOST=db` and `DB_PORT=5432` live in a ConfigMap. `DB_PASSWORD=shopstack_dev` lives in a Secret.

</details>

---

## Q9 — What is CrashLoopBackOff and how do you diagnose it?

<details>
<summary>Answer</summary>

CrashLoopBackOff means a container is repeatedly crashing and Kubernetes keeps restarting it with increasing delays — 1 second, 2, 4, 8, up to 5 minutes. The Pod stays. The container inside it keeps dying and being recreated.

The two-command diagnosis:

First, `kubectl logs <pod> --previous` — this shows what the container printed to stdout before it crashed. The application error is usually right there — a missing environment variable, a failed database connection, a misconfigured path.

Second, `kubectl describe pod <pod>` — scroll to the Events section at the bottom. This shows what Kubernetes observed — exit codes, OOMKilled signals, image pull failures — things the application itself might not have logged.

In ShopStack the most common cause is a wrong `DB_HOST` value — the API cannot connect to Postgres and exits. Logs show `connection refused`. Fix the env var, restart the Deployment.

</details>

---

## Q10 — What does kubectl apply do? What is the difference between apply and create?

<details>
<summary>Answer</summary>

`kubectl apply` sends a manifest to the Kubernetes API Server. The API Server compares the manifest to what currently exists in etcd. If the object does not exist, it creates it. If it exists, it updates only the fields that changed. Apply is idempotent — you can run it multiple times and it produces the same result.

`kubectl create` only creates — if the object already exists, it returns an error.

In production you always use `kubectl apply`. It supports the declarative workflow — you store manifests in Git, make changes, and apply. Kubernetes reconciles the cluster to match. `kubectl create` is imperative and does not fit this model.

</details>

---

## Rapid fire — 30 seconds each, no notes

Answer these out loud before looking:

1. What is the control plane? One sentence.
2. What is etcd? One sentence.
3. What is a ReplicaSet? One sentence.
4. What does `kubectl rollout undo` do?
5. What is the difference between `kubectl logs` and `kubectl describe`?
6. A Pod is in `Pending` — what is the first command you run?
7. A Service shows `Endpoints: <none>` — what is wrong?
8. Why do you use `echo -n` when encoding a Secret value?
9. What is the difference between `port` and `targetPort` in a Service?
10. A rolling update is stuck — what is the first command you run?

<details>
<summary>Answers</summary>

1. The control plane is the brain of the cluster — API Server, etcd, Scheduler, Controller Manager — it stores desired state and enforces it.
2. etcd is the cluster's key-value database — the single source of truth for every object in the cluster.
3. A ReplicaSet ensures a specified number of identical Pods are always running — creates new ones when the count drops, terminates extras when it rises.
4. `kubectl rollout undo` rolls back a Deployment to its previous ReplicaSet — the old RS scales up, the new RS scales down.
5. `kubectl logs` shows what the application printed to stdout. `kubectl describe` shows what Kubernetes observed — events, probe status, resource allocation.
6. `kubectl describe pod <n>` → read Events → look for `Insufficient cpu/memory` or PVC not bound.
7. The `selector` on the Service does not match the `labels` on the Pod template — one typo makes them invisible to each other.
8. `echo -n` removes the trailing newline. Without it, the newline is encoded into the base64 value and the env var contains a hidden character that breaks the connection.
9. `port` is what other Pods use to reach the Service. `targetPort` is the port on the Pod container the Service forwards traffic to. They are independent.
10. `kubectl rollout status deployment/<n>` — if stuck, `kubectl get pods` to find the failing new Pod, then `kubectl describe pod <n>` to read the error.

</details>
