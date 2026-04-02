[Home](../../README.md) | [Labs Index](./README.md) | [Setup Lab](./00-setup-lab.md) | [Architecture Lab](./01-architecture-lab.md) | [YAML & Pods Lab](./02-yaml-pods-lab.md)

---

# Lab 01 — Architecture & The Live Cluster

## What This Lab Is About

In [01-architecture/README.md](../01-architecture/README.md) you learned the
theory — Control Plane, Worker Nodes, how requests flow. This lab makes it real.
You will find every component running live in your cluster, read their configs,
and prove to yourself that the "brain" you read about actually exists.

You are done with this lab when you can look at a live cluster and immediately
identify every component, what it does, and whether it is healthy — without
referring to notes.

---

## Prerequisites

- Lab 00 complete — cluster is running, K9s is open in Tab 2
- [01-architecture/README.md](../01-architecture/README.md) read and understood

---

## Section 1 — Find the Control Plane Alive

The Control Plane components run as Pods inside the `kube-system` namespace.
Run this and read every line of output:

```bash
kubectl get pods -n kube-system
```

Expected output (your versions may differ slightly):
```
NAME                               READY   STATUS    RESTARTS   AGE
coredns-xxx                        1/1     Running   0          Xm
etcd-minikube                      1/1     Running   0          Xm
kube-apiserver-minikube            1/1     Running   0          Xm
kube-controller-manager-minikube   1/1     Running   0          Xm
kube-proxy-xxx                     1/1     Running   0          Xm
kube-scheduler-minikube            1/1     Running   0          Xm
storage-provisioner                1/1     Running   0          Xm
```

Every pod must be `Running`. If anything is not `Running` — your cluster is
unhealthy. Run `minikube delete && minikube start` and try again.

**Map what you see to the theory:**

| Pod you see | Component it is | What it does |
|-------------|----------------|--------------|
| `etcd-minikube` | etcd | The database — stores all cluster state |
| `kube-apiserver-minikube` | API Server | The only entry point — everything talks through this |
| `kube-controller-manager-minikube` | Controller Manager | Watches state, fixes drift — the thermostat |
| `kube-scheduler-minikube` | Scheduler | Assigns Pods to nodes |
| `kube-proxy-xxx` | Kube Proxy | Handles networking rules on the node |
| `coredns-xxx` | CoreDNS | Internal DNS — how Pods find each other by name |

---

## Section 2 — Inspect the API Server

The API Server is the single most important component. Everything passes through it.

```bash
kubectl describe pod kube-apiserver-minikube -n kube-system
```

Scroll through the output and find these three things:

1. **Image** — what container image is the API Server running
2. **Node** — which node it is running on
3. **Events** — scroll to the bottom, confirm no errors

**In K9s (Tab 2):**
- Press `0` to see all namespaces
- Navigate to `kube-apiserver-minikube`
- Press `d` to describe it
- Press `l` to view its logs
- Press `esc` to go back

---

## Section 3 — Inspect etcd

etcd is the source of truth. Every object you ever create in Kubernetes lives here.

```bash
kubectl describe pod etcd-minikube -n kube-system
```

Find and note:
1. The port etcd listens on
2. The data directory where it stores cluster state
3. Confirm status is `Running` with 0 restarts

---

## Section 4 — Read the Worker Node

In Minikube your laptop is both the Control Plane and the Worker Node.
Run this to see the full node profile:

```bash
kubectl get nodes -o wide
```

Expected output adds these extra columns:
```
NAME       STATUS   ROLES           AGE   VERSION   INTERNAL-IP   OS-IMAGE   KERNEL-VERSION   CONTAINER-RUNTIME
minikube   Ready    control-plane   Xm    v1.x.x    192.168.x.x   ...        ...              containerd://x.x.x
```

Note the `CONTAINER-RUNTIME` column — it shows `containerd`. This is the
component that actually pulls images and runs containers. kubectl and K8s
never touch containers directly — containerd does.

Now describe the node in full:

```bash
kubectl describe node minikube
```

Scroll through and find:
1. **Capacity** — how much CPU and RAM this node has
2. **Allocatable** — how much is actually available for Pods
3. **Conditions** — all should show `True` for Ready, `False` for everything else
4. **System Info** — confirm the container runtime is containerd

---

## Section 5 — Trace a Request Flow

This section makes the architecture flow concrete. You will simulate what happens
when you run `kubectl apply` by watching the components respond in real time.

Open Tab 2 with K9s showing `kube-system` pods (`0` for all namespaces).

In Tab 1 run:
```bash
kubectl run test-pod --image=nginx:latest
```

Watch K9s in Tab 2 — you will see `test-pod` appear, go through `Pending`,
then `ContainerCreating`, then `Running`.

What just happened in sequence:
1. `kubectl` sent your request to the **API Server**
2. **API Server** stored it in **etcd** as `PENDING`
3. **Scheduler** detected an unscheduled Pod and picked the minikube node
4. **kubelet** on the node saw its assignment and told **containerd** to pull nginx
5. **containerd** pulled the image and started the container
6. **Kube Proxy** assigned network rules so the Pod can communicate
7. Pod status became `Running`

Now confirm it is running:
```bash
kubectl get pods
```

Now clean it up:
```bash
kubectl delete pod test-pod
```

Watch it disappear in K9s.

---

## Section 6 — Understand What Self-Healing Is NOT Here

A standalone Pod has no self-healing. Prove it:

```bash
kubectl run test-pod --image=nginx:latest
kubectl get pods
```

Wait until status is `Running`, then delete it:
```bash
kubectl delete pod test-pod
kubectl get pods
```

It is gone. Kubernetes did not replace it. There is no Controller watching it.

**This is exactly why Deployments exist** — covered in Lab 03. A Deployment
wraps a Pod in a ReplicaSet that watches and replaces it. A naked Pod is
disposable with no recovery.

---

## Lab Complete — You Are Ready For Lab 02 When

- [ ] You can name every `kube-system` pod and explain what it does without notes
- [ ] You know the difference between the API Server and etcd in one sentence each
- [ ] You ran `kubectl describe node minikube` and found CPU, RAM, and container runtime
- [ ] You watched a Pod go through `Pending → ContainerCreating → Running` in K9s
- [ ] You proved that a standalone Pod does not self-heal when deleted

If any box is unchecked — repeat the relevant section.
Do not move to Lab 02 until all five are checked.
