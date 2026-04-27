[Home](../README.md) | [Setup](../00-setup/README.md) | [Architecture](../01-architecture/README.md) | [YAML & Pods](../02-yaml-pods/README.md) | [Deployments](../03-deployments/README.md) | [Networking](../03.5-networking/README.md) | [State](../04-state/README.md) | [Troubleshooting](../05-troubleshooting/README.md) | [Probes](../06-probes/README.md) | [Namespaces](../07-namespaces/README.md) | [kubectl Reference](../08-kubectl-reference/README.md) | [Interview Prep](../99-interview-prep/README.md)

---

# 08 — kubectl Reference

> **This is your combat sheet.** Open this when you know what you want to do but cannot recall the exact flag or syntax. Every command is anchored to ShopStack.

---

## Cluster & Node

| What it does | Command | Example |
|---|---|---|
| Confirm cluster is reachable and node is Ready | `kubectl get nodes` | `kubectl get nodes` |
| Full node details — CPU, RAM, conditions | `kubectl get nodes -o wide` | `kubectl get nodes -o wide` |
| Full node description — events, capacity | `kubectl describe node <n>` | `kubectl describe node ip-172-31-14-5` |
| Confirm API Server address | `kubectl cluster-info` | `kubectl cluster-info` |
| Full cluster health scan — all namespaces | `kubectl get pods -A` | `kubectl get pods -A` |
| See control plane components | `kubectl get pods -n kube-system` | `kubectl get pods -n kube-system` |

---

## Pods

| What it does | Command | Example |
|---|---|---|
| List all Pods and their status | `kubectl get pods` | `kubectl get pods` |
| List Pods with node and IP info | `kubectl get pods -o wide` | `kubectl get pods -o wide` |
| Filter Pods by label | `kubectl get pods -l <label>` | `kubectl get pods -l tier=api` |
| Watch Pod changes live | `kubectl get pods -w` | `kubectl get pods -w` |
| Full Pod details — events, probes, volumes | `kubectl describe pod <n>` | `kubectl describe pod shopstack-api-xxx` |
| Container logs — current | `kubectl logs <n>` | `kubectl logs shopstack-api-xxx` |
| Container logs — previous crash | `kubectl logs <n> --previous` | `kubectl logs shopstack-api-xxx --previous` |
| Follow logs live | `kubectl logs -f <n>` | `kubectl logs -f shopstack-api-xxx` |
| Last N lines of logs | `kubectl logs <n> --tail=<n>` | `kubectl logs shopstack-api-xxx --tail=50` |
| Logs from specific container in multi-container Pod | `kubectl logs <pod> -c <container>` | `kubectl logs shopstack-api-xxx -c api` |
| Enter a running container | `kubectl exec -it <n> -- /bin/sh` | `kubectl exec -it shopstack-api-xxx -- /bin/sh` |
| Run a single command in a container | `kubectl exec <n> -- <cmd>` | `kubectl exec shopstack-api-xxx -- env` |
| Delete a Pod — Deployment will recreate it | `kubectl delete pod <n>` | `kubectl delete pod shopstack-api-xxx` |

---

## Deployments

| What it does | Command | Example |
|---|---|---|
| Create or update a Deployment | `kubectl apply -f <file>` | `kubectl apply -f infra/k8s/api-deployment.yaml` |
| Apply all manifests in a folder | `kubectl apply -f <folder>` | `kubectl apply -f infra/k8s/` |
| List all Deployments and ready count | `kubectl get deployments` | `kubectl get deployments` |
| Full Deployment details — events, selector | `kubectl describe deployment <n>` | `kubectl describe deployment shopstack-api` |
| Watch a rolling update in real time | `kubectl rollout status deployment/<n>` | `kubectl rollout status deployment/shopstack-api` |
| See rollout history | `kubectl rollout history deployment/<n>` | `kubectl rollout history deployment/shopstack-api` |
| Trigger a rolling update with new image | `kubectl set image deployment/<n> <container>=<image>` | `kubectl set image deployment/shopstack-api api=akhiltejadoosari/shopstack-api:1.1` |
| Emergency rollback to previous version | `kubectl rollout undo deployment/<n>` | `kubectl rollout undo deployment/shopstack-api` |
| Rollback to specific revision | `kubectl rollout undo deployment/<n> --to-revision=<n>` | `kubectl rollout undo deployment/shopstack-api --to-revision=1` |
| Restart all Pods in a Deployment | `kubectl rollout restart deployment/<n>` | `kubectl rollout restart deployment/shopstack-api` |
| Scale up or down | `kubectl scale deployment/<n> --replicas=<n>` | `kubectl scale deployment/shopstack-api --replicas=4` |
| Delete Deployment and all its Pods | `kubectl delete deployment <n>` | `kubectl delete deployment shopstack-api` |

---

## ReplicaSets

| What it does | Command | Example |
|---|---|---|
| List all ReplicaSets | `kubectl get rs` | `kubectl get rs` |
| Full RS details | `kubectl describe rs <n>` | `kubectl describe rs shopstack-api-7d9f8b6c4` |

---

## Services

| What it does | Command | Example |
|---|---|---|
| List all Services | `kubectl get services` | `kubectl get services` |
| List Services with ports and selectors | `kubectl get services -o wide` | `kubectl get services -o wide` |
| Full Service details — selector, endpoints | `kubectl describe service <n>` | `kubectl describe service api` |
| Check which Pods a Service routes to | `kubectl get endpoints` | `kubectl get endpoints` |
| Check endpoints for a specific Service | `kubectl get endpoints <n>` | `kubectl get endpoints api` |
| Delete a Service | `kubectl delete service <n>` | `kubectl delete service api` |

---

## ConfigMaps & Secrets

| What it does | Command | Example |
|---|---|---|
| Create or update a ConfigMap | `kubectl apply -f <file>` | `kubectl apply -f infra/k8s/db-configmap.yaml` |
| List all ConfigMaps | `kubectl get configmaps` | `kubectl get configmaps` |
| Read a ConfigMap's values | `kubectl describe configmap <n>` | `kubectl describe configmap db-config` |
| Create or update a Secret | `kubectl apply -f <file>` | `kubectl apply -f infra/k8s/db-secret.yaml` |
| List all Secrets | `kubectl get secrets` | `kubectl get secrets` |
| Decode a Secret value | `kubectl get secret <n> -o jsonpath='{.data.<key>}' \| base64 -d` | `kubectl get secret db-secret -o jsonpath='{.data.DB_PASSWORD}' \| base64 -d` |
| Encode a value for a Secret | `echo -n "<value>" \| base64` | `echo -n "shopstack_dev" \| base64` |
| Check env vars injected into a running Pod | `kubectl exec <pod> -- env` | `kubectl exec shopstack-api-xxx -- env` |

---

## Persistent Storage

| What it does | Command | Example |
|---|---|---|
| Create a PVC | `kubectl apply -f <file>` | `kubectl apply -f infra/k8s/db-pvc.yaml` |
| List all PVCs and their status | `kubectl get pvc` | `kubectl get pvc` |
| Full PVC details | `kubectl describe pvc <n>` | `kubectl describe pvc db-pvc` |
| List PersistentVolumes | `kubectl get pv` | `kubectl get pv` |

---

## Debugging

| What it does | Command | Example |
|---|---|---|
| Cluster event timeline — newest first | `kubectl get events --sort-by=.lastTimestamp` | `kubectl get events --sort-by=.lastTimestamp` |
| Watch events live | `kubectl get events -w` | `kubectl get events -w` |
| Test DNS from inside a Pod | `kubectl exec -it <pod> -- nslookup <service>` | `kubectl exec -it shopstack-api-xxx -- nslookup db` |
| Test HTTP from inside a Pod | `kubectl exec -it <pod> -- wget -qO- <url>` | `kubectl exec -it shopstack-api-xxx -- wget -qO- http://api:8080/api/health` |
| Check all resources at once | `kubectl get all` | `kubectl get all` |

---

## ShopStack Quick Reference

```bash
# Full stack health check — run this every session
kubectl get nodes
kubectl get pods
kubectl get deployments
kubectl get services
kubectl get pvc
kubectl get endpoints

# The five ShopStack services should all show Running
kubectl get pods -l app=shopstack

# Hit the frontend from your Mac
curl http://YOUR_EC2_IP:30080

# Hit the API health endpoint
curl http://YOUR_EC2_IP:30080/api/health

# Hit products
curl http://YOUR_EC2_IP:30080/api/products
```

---

## Flag Quick Reference

| Flag | What it does | Used with |
|---|---|---|
| `-f <file>` | Specify manifest file | `apply`, `delete` |
| `-l <label>` | Filter by label | `get pods`, `get services` |
| `-n <namespace>` | Specify namespace | any `get` or `describe` |
| `-A` | All namespaces | `get pods` |
| `-o wide` | Extra columns — IPs, node, ports | any `get` |
| `-o yaml` | Full object as YAML | any `get` |
| `-w` | Watch for changes live | any `get` |
| `--previous` | Logs from previous crash | `logs` |
| `-f` | Follow logs live | `logs` |
| `--tail=<n>` | Last N lines of logs | `logs` |
| `-it` | Interactive terminal | `exec` |
| `--replicas=<n>` | Set replica count | `scale` |
| `--to-revision=<n>` | Rollback to specific revision | `rollout undo` |
| `--sort-by=<field>` | Sort output by field | `get events` |

---

→ **Interview questions:** `99-interview-prep.md`

→ Next: [99 — Interview Prep](./99-interview-prep.md)
