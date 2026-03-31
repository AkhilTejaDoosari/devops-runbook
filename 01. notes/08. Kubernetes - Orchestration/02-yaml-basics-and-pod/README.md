# 02 — YAML Basics & The Pod

## What This File Is About

In Phase 1, you learned the theory — the Brain. In Phase 2, you move to the **Language**. This file covers YAML syntax, the anatomy of a Manifest, and how to deploy a Pod — the smallest unit of work in Kubernetes.

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

Every Kubernetes YAML file must have these four top-level fields. If one is missing, the API Server (The Gatekeeper) rejects the request outright.

| Field | Purpose | Example |
|---|---|---|
| `apiVersion` | Which version of the K8s API dictionary to use | `v1` |
| `kind` | The type of object being created | `Pod` |
| `metadata` | Identification data — Name, Labels | `name: chillspot-api` |
| `spec` | The Blueprint — exactly what is inside | `containers`, `image`, `ports` |

---

## 3. Labels and Selectors — The Glue

Kubernetes does not connect components using IP addresses — those change constantly as Pods die and get replaced. It uses **Labels** instead.

- **Labels:** Key-value "sticky notes" attached to a Pod in the `metadata` section.
  - Example: `app: chillspot`
- **Selectors:** Used by other objects (Services, Deployments) to find and group all Pods with a matching label.

> **The Rule:** If the Label on the Pod does not match the Selector on the Service, they cannot talk to each other. This is the most common beginner misconfiguration.

---

## 4. The Anatomy of a Pod

A Pod is the smallest deployable unit in Kubernetes. Think of it as a **"Space Shuttle"** — a protective shell that carries your containers into the cluster.

**The Shared Environment:** The primary reason the Pod abstraction exists is so that multiple containers can live in the same space, sharing the same **Network IP** and **Storage volumes**. Kubernetes never runs a naked container — it always wraps it in a Pod first.

**One IP per Pod:** Every Pod gets its own internal cluster IP. All containers inside that Pod communicate with each other via `localhost`.

**Ephemeral (Temporary):** Pods are disposable. If a standalone Pod dies, it stays dead — Kubernetes does not resurrect it. Self-healing only kicks in during Phase 3, where a **Controller** detects the death and creates a brand new replacement Pod. The old Pod is gone forever; a new one takes its place.

> **ChillSpot angle:** In our project, the Pod is the "Unit of Compute" that hosts the ChillSpot API — giving it an isolated environment, its own identity, and a place to live inside the cluster.

---

## 5. The DevOps Workflow — kubectl + vi

The professional toolkit — no GUIs:

| Tool | Purpose |
|---|---|
| `vi` | Industry-standard terminal editor for writing manifests directly on the server |
| `kubectl apply -f [file]` | Sends your Desired State to the API Server |
| `kubectl describe pod [name]` | Reads the Pod's Events — the birth certificate of the Pod |
| `k9s` | Terminal-based cockpit for real-time cluster monitoring |

---

## 6. Action Step

Write and deploy the ChillSpot API Pod using `vi`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: chillspot-api
  labels:
    app: chillspot
spec:
  containers:
    - name: api-container
      image: nginx:latest
      ports:
        - containerPort: 80
```

```bash
# Deploy to your Minikube cluster
kubectl apply -f chillspot-pod.yaml

# Monitor the status in your cockpit
k9s
```