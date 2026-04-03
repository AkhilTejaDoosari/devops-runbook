[Home](../README.md) | [Labs Index](./README.md) | [Setup Lab](./00-setup-lab.md) | [Architecture Lab](./01-architecture-lab.md) | [YAML & Pods Lab](./02-yaml-pods-lab.md) | [Deployments Lab](./03-deployments-lab.md) | [Networking Lab](./03.5-networking-lab.md) | [State & Config Lab](./04-state-lab.md) | [Troubleshooting Lab](./05-troubleshooting-lab.md) | [Cloud & EKS Lab](./06-cloud-lab.md)

---

# Kubernetes Labs — Hands-On Practice Index

Theory lives in the phase folders. This folder is where you prove it.

Each lab maps directly to its notes file. Read the notes first, then open
the lab and run every section. Do not move to the next lab until the
checklist at the bottom is fully checked.

---

## Lab Index

| Lab | Notes File | Status |
|-----|-----------|--------|
| [00 — Setup](./00-setup-lab.md) | [00-setup/README.md](../00-setup/README.md) | ✅ Ready |
| [01 — Architecture](./01-architecture-lab.md) | [01-architecture/README.md](../01-architecture/README.md) | ✅ Ready |
| [02 — YAML & Pods](./02-yaml-pods-lab.md) | [02-yaml-pods/README.md](../02-yaml-pods/README.md) | ✅ Ready |
| [03 — Deployments](./03-deployments-lab.md) | [03-deployments/README.md](../03-deployments/README.md) | ✅ Ready |
| [03.5 — Networking](./03.5-networking-lab.md) | [03.5-networking/README.md](../03.5-networking/README.md) | 🔒 Not yet |
| [04 — State & Config](./04-state-lab.md) | [04-state/README.md](../04-state/README.md) | 🔒 Not yet |
| [05 — Troubleshooting](./05-troubleshooting-lab.md) | [05-troubleshooting/README.md](../05-troubleshooting/README.md) | 🔒 Not yet |
| [06 — Cloud & EKS](./06-cloud-lab.md) | [06-cloud/README.md](../06-cloud/README.md) | 🔒 Not yet |

---

## Rules

- Read the notes file before opening the lab
- Write every manifest from scratch — no copy paste
- Run `yamllint` before every `kubectl apply` — no exceptions
- Complete every section before checking the box
- Do not move to the next lab until all boxes are checked

---

## Running Example

Every lab uses the same 3-tier webstore application:

| Service | Name | Image | Port |
|---------|------|-------|------|
| Frontend | `webstore-frontend` | `nginx:1.24` | 80 |
| Backend API | `webstore-api` | `nginx:1.24` | 8080 |
| Database | `webstore-db` | `mariadb:latest` | 3306 |

The same app grows more complex with every lab — by Lab 06 it is running
on AWS EKS with a full CI/CD pipeline, monitoring, and auto-scaling.
