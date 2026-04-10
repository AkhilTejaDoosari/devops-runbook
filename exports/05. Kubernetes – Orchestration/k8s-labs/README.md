[Home](../README.md) |
[Lab 00](./00-setup-lab.md) |
[Lab 01](./01-architecture-lab.md) |
[Lab 02](./02-yaml-pods-lab.md) |
[Lab 03](./03-deployments-lab.md) |
[Lab 03.5](./03.5-networking-lab.md) |
[Lab 04](./04-state-lab.md) |
[Lab 05](./05-troubleshooting-lab.md) |
[Lab 06](./06-cloud-lab.md)

---

# Kubernetes Labs

Hands-on sessions for every phase in the K8s notes.

Do them in order. Do not move to the next lab until the checklist at the bottom is fully checked.

---

## The Project Thread

These labs take the webstore from a Docker Compose stack on your laptop to a production deployment on AWS EKS. Each lab leaves the webstore in a better state than it found it.

| Lab | Where the webstore is | What you do |
|---|---|---|
| [Lab 00](./00-setup-lab.md) | Not yet on K8s | Verify every tool, run the cold start drill, build the K9s cockpit habit |
| [Lab 01](./01-architecture-lab.md) | Not yet on K8s | Find every control plane component running live — map theory to reality |
| [Lab 02](./02-yaml-pods-lab.md) | First Pod on the cluster | Write manifests from scratch, apply, inspect, run the full debug loop |
| [Lab 03](./03-deployments-lab.md) | All 3 tiers as Deployments | Prove self-healing, trigger a rolling update, perform an emergency rollback, scale |
| [Lab 03.5](./03.5-networking-lab.md) | Deployments running, not yet wired | Services connect the tiers, frontend exposed, namespace boundaries enforced |
| [Lab 04](./04-state-lab.md) | Network complete, data not persisted | Postgres gets a PVC, credentials move into a Secret, config into a ConfigMap |
| [Lab 05](./05-troubleshooting-lab.md) | Full stack running locally | Readiness probe gates traffic, CronJob backs up the DB, debug loop drilled |
| [Lab 06](./06-cloud-lab.md) | Production-ready on Minikube | Same manifests, real cloud — eksctl creates the cluster, webstore deploys to EKS |

---

## Labs

| Lab | Topics | Notes |
|---|---|---|
| [Lab 00](./00-setup-lab.md) | Setup, daily workflow, cold start, K9s, yamllint | [00-setup](../00-setup/README.md) |
| [Lab 01](./01-architecture-lab.md) | Live cluster inspection, control plane components | [01-architecture](../01-architecture/README.md) |
| [Lab 02](./02-yaml-pods-lab.md) | Write manifests, deploy pods, labels, debug loop | [02-yaml-pods](../02-yaml-pods/README.md) |
| [Lab 03](./03-deployments-lab.md) | Deployments, self-healing, rolling updates, rollbacks, scaling | [03-deployments](../03-deployments/README.md) |
| [Lab 03.5](./03.5-networking-lab.md) | Services, kube-dns, Sidecar pattern, Namespaces | [03.5-networking](../03.5-networking/README.md) |
| [Lab 04](./04-state-lab.md) | PersistentVolumes, PVCs, ConfigMaps, Secrets | [04-state](../04-state/README.md) |
| [Lab 05](./05-troubleshooting-lab.md) | Probes, Jobs, CronJobs, DaemonSets, full debug loop | [05-troubleshooting](../05-troubleshooting/README.md) |
| [Lab 06](./06-cloud-lab.md) | EKS, eksctl, EBS CSI driver, ECR, Ingress, HPA | [06-cloud](../06-cloud/README.md) |

---

## After Kubernetes

CI-CD and Observability are their own tools in this runbook — not phases of Kubernetes. They live at the same level as every other tool because they are not Kubernetes features. They are disciplines that happen to use a Kubernetes cluster.

→ [06. CI-CD – Pipelines & GitOps](../../06.%20CI-CD%20–%20Pipelines%20%26%20GitOps/README.md) — automate every `kubectl apply` you just ran manually

→ [07. Observability – Monitoring & Logs](../../07.%20Observability%20–%20Monitoring%20%26%20Logs/README.md) — instrument what CI-CD deployed so you can see inside it
