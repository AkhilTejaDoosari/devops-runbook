[Home](../../README.md) | [Labs Index](./README.md) | [Setup Lab](./00-setup-lab.md) | [Architecture Lab](./01-architecture-lab.md) | [YAML & Pods Lab](./02-yaml-pods-lab.md)

---

# Lab 00 — Environment Setup & Verification

## What This Lab Is About

Before writing a single line of YAML you need a verified, healthy environment.
This lab walks you through confirming every tool is installed, wiring up your
daily workflow, and building the cold start into reflex.

You are done with this lab when you can open a terminal, have a running cluster,
and a live K9s cockpit — in under 2 minutes, without thinking.

---

## Prerequisites

- macOS with Homebrew installed
- Docker Desktop installed and running
- All tools from [00-setup/README.md](../00-setup/README.md) installed

---

## Section 1 — Verify Every Tool

Run each command. Every one must return a clean version — no errors.

```bash
kubectl version --client
```
Expected: `Client Version: v1.35.3`

```bash
minikube version
```
Expected: `minikube version: v1.38.1`

```bash
helm version --short
```
Expected: `v4.1.3+...`

```bash
k9s version
```
Expected: `Version: v0.50.18`

```bash
kubectx --version
```
Expected: `v0.11.0`

```bash
yamllint --version
```
Expected: `yamllint 1.38.0`

```bash
docker --version
```
Expected: `Docker version 29.1.5`

```bash
aws --version
```
Expected: `aws-cli/2.33.12...`

```bash
terraform --version
```
Expected: `Terraform v1.14.4`

**If any command fails** — stop. Go back to [00-setup/README.md](../00-setup/README.md) and fix it before continuing. A broken tool discovered mid-session wastes more time than
fixing it now.

---

## Section 2 — Cold Start Drill

This is your daily opening sequence. Run it every single session.
The goal is to do this in under 2 minutes without referring to notes.

**Step 1 — Start Docker Engine**
```bash
open -a Docker
```
Wait ~10 seconds for Docker Desktop to fully start.

**Step 2 — Verify Docker is up**
```bash
docker version
```
You must see both a `Client` and `Server` section.
If you only see `Client` — Docker Desktop is still starting. Wait and retry.

**Step 3 — Start the cluster**
```bash
minikube start
```
Expected final line: `Done! kubectl is now configured to use "minikube"`

**Step 4 — Verify the node is healthy**
```bash
kubectl get nodes
```
Expected output:
```
NAME       STATUS   ROLES           AGE   VERSION
minikube   Ready    control-plane   Xs    v1.x.x
```
`Ready` is the only acceptable status. If it says `NotReady` — wait 30 seconds
and run it again. If it stays `NotReady` run `minikube delete && minikube start`.

**Step 5 — Full cluster health scan**
```bash
kubectl get pods -A
```
Scan the `STATUS` column. Every pod should be `Running` or `Completed`.
Any pod in `Error` or `CrashLoopBackOff` in the `kube-system` namespace means
your cluster is unhealthy. Full reset: `minikube delete && minikube start`.

**Step 6 — Open your cockpit**

Open a second terminal tab (`Command + T`) and run:
```bash
k9s
```

Leave K9s open for the entire session. Never close it while working.

| Tab | Role |
|-----|------|
| Tab 1 | Workstation — `kubectl`, `helm`, `vi`, `yamllint` |
| Tab 2 | Live feed — K9s watching everything in real time |

---

## Section 3 — K9s Navigation Drill

K9s is only useful if navigation is reflex. Practice these until they are instant.

| Key | Action |
|-----|--------|
| `0` | Show all namespaces |
| `↑ ↓` | Navigate between Pods |
| `d` | Describe the selected Pod |
| `l` | View logs of the selected Pod |
| `ctrl + d` | Delete the selected Pod |
| `esc` | Go back |
| `ctrl + c` | Exit K9s |

**Drill:** In K9s press `0` to see all namespaces. Find the `kube-system`
namespace pods. Navigate to `kube-apiserver-minikube` and press `d` to describe
it. Press `esc` to go back. Do this until it takes under 10 seconds.

---

## Section 4 — yamllint Drill

Create a test file with a deliberate error:

```bash
vi test.yaml
```

Type this exactly — the indentation on line 4 is intentionally wrong:

```yaml
apiVersion: v1
kind: Pod
metadata:
name: test-pod
  labels:
    app: test
```

Save and exit (`:wq`), then lint it:

```bash
yamllint test.yaml
```

You should see an error pointing at the wrong indentation. This is yamllint
doing its job — catching the error before it wastes your time at the API Server.

Now fix the indentation:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: test-pod
  labels:
    app: test
```

Lint it again:
```bash
yamllint test.yaml
```

Clean output means valid YAML. Delete the test file:
```bash
rm test.yaml
```

**Rule from this point forward:** `yamllint <file>` before every `kubectl apply`.
No exceptions.

---

## Section 5 — End of Session Drill

This is your daily closing sequence. Run it every time you finish a session.

```bash
# Step 1 — Exit K9s in Tab 2
ctrl + c

# Step 2 — Stop the cluster
minikube stop

# Step 3 — Close Docker Desktop
```

**Cluster feels broken or messy at any point?**
```bash
minikube delete && minikube start
```
This wipes everything and starts clean. Use it without hesitation.

---

## Lab Complete — You Are Ready For Lab 01 When

- [ ] Every tool returns a clean version with no errors
- [ ] You can complete the cold start in under 2 minutes without notes
- [ ] K9s navigation feels natural — describe and logs without thinking
- [ ] yamllint habit is wired — you lint before you apply
- [ ] You know the end of session sequence without looking

If any box is unchecked — repeat the relevant section.
Do not move to Lab 01 until all five are checked.
