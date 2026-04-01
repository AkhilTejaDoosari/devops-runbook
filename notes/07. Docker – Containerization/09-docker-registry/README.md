[Home](../README.md) |
[History & Motivation](../01-history-and-motivation/README.md) |
[Technology Overview](../02-technology-overview/README.md) |
[Docker Containers](../03-docker-containers/README.md) |
[Networking](../04-docker-networking/README.md) |
[Port Binding](../05-docker-port-binding/README.md) |
[Volumes](../06-docker-volumes/README.md) |
[Layers](../07-docker-layers/README.md) |
[Build](../08-docker-build-dockerfile/README.md) |
[Registry](../09-docker-registry/README.md) |
[Compose](../10-docker-compose/README.md)

# 09. Container Registries

## 1) What a Container Registry Is

A container registry is a **remote storage system for Docker images**.

It stores images so they can be:
- pushed by developers
- pulled by CI systems
- pulled by production servers

It does **not** run containers.

---

## 2) Why Registries Exist

Without a registry:
- images live only on your laptop
- CI cannot access them
- production cannot pull them

With a registry:
- one image
- reused everywhere
- no rebuild drift

---

## 3) Visual Mental Model (Registry as the Hub)

![](./readme-assets/container-registry.jpg)

What this image shows:  
**Developer systems**
- Push → very common (after build)
- Pull → very common (base images, debugging)  

**CI servers**
- Pull → always (to test, scan, deploy)
- Push → often (build pipelines, versioned images)

**Production servers**
- Pull → yes (to run images)
- Push → almost never (anti-pattern)

Key idea:
The registry is **passive storage**.
Everything else initiates communication.

**The Only Flow That Matters**

```

Developer ↔ Registry ↔ CI → Production

```

Same image.
Different environments.

---

## 4) Common Container Registries (Awareness Only)

Examples you will see in real systems:
- Docker Hub
- GitHub Container Registry (ghcr.io)
- GitLab Container Registry
- Google Container Registry (gcr.io)
- Amazon Elastic Container Registry (ECR)
- Azure Container Registry (ACR)
- JFrog Artifactory
- Nexus
- Harbor

You do not need to learn each one now.
They all solve the same problem.

---

## 5) Public vs Private Images

Public images:
- anyone can pull
- no authentication required

Private images:
- authentication required
- commonly used in CI and production

This explains why login exists.

---

## 6) Authentication

To push or pull private images:
```bash
docker login
```

What happens:

* credentials are sent to the registry
* Docker stores them securely
* future pulls/pushes work automatically

Where credentials live:

* macOS Keychain
* Windows Credential Manager
* Linux credential helpers

---

## 7) Authentication Visual

![](./readme-assets/credential-helper.jpg)

What this image shows:

* Docker CLI requesting credentials
* OS credential store handling secrets
* Registry validating access

You do not manage tokens manually at this stage.

---

You’re right to demand an end-to-end “do this, then this” sequence. Your current Section 8 is missing the **Docker Hub UI prerequisites** and a **clean, deterministic terminal flow**.

Below is **Section 8 only** (drop it after Section 7). It includes:

* Docker Hub login + repo creation (UI)
* Build verification + build if missing
* Terminal login (with a clean “reset credentials” option)
* Tag + push
* Verification

No fluff. All required commands included.

## 8) Publish Chillspot to Docker Hub (End-to-End Process)

Goal:
- Take a local image you built (Section 08)
- Publish it to Docker Hub so other machines/CI can pull it

This section includes:
- Docker Hub UI steps (create repository)
- Terminal steps (build, login, tag, push, verify)

---

### Step 0: Prerequisites (Docker Hub)

1) Sign in to Docker Hub (website).
2) Create a repository:
   - Name: `chillspot`
   - Visibility: Public or Private (your choice)
3) After creation, your image target will look like:
   - `DOCKERHUB_USERNAME/chillspot`

You can add your own screenshots here (recommended).

---

### Step 1: Ensure the Image Exists Locally

Check local images:

```bash
docker images
```

Look for:

* `chillspot` under `REPOSITORY`
* a tag like `latest`

If you do NOT see it, build it now (run this from the folder that contains your Dockerfile):

```bash
docker build -t chillspot:latest .
```

Re-check:

```bash
docker images | head
```

---

### Step 2: Confirm Which Docker Account the Terminal Is Using

Docker can stay logged in from old sessions. Confirm current auth state:

```bash
docker info | grep -i username
```

If it prints a username, Docker is logged in.

---

### Step 3: Reset Login (Only When Needed)

Use this if:

* you see the wrong username
* push fails with permission errors
* you previously logged into a different account

Logout first:

```bash
docker logout
```

Why logout/login helps:

* it clears stale credentials in the credential store
* avoids “pushing to the wrong account” mistakes
* fixes “denied: requested access to the resource is denied” when the wrong user is cached

Now login again:

```bash
docker login
```

It will prompt for Docker Hub username and password (or token if you use one).

Verify again:

```bash
docker info | grep -i username
```

---

### Step 4: Tag the Image for Docker Hub

Docker Hub requires images to be tagged as:

```
DOCKERHUB_USERNAME/REPO_NAME:TAG
```

Tag your local image:

```bash
docker tag chillspot:latest DOCKERHUB_USERNAME/chillspot:1.0
```

Confirm the tag exists:

```bash
docker images | grep chillspot
```

You should see both:

* `chillspot:latest`
* `DOCKERHUB_USERNAME/chillspot:1.0`

---

### Step 5: Push the Image

Push to Docker Hub:

```bash
docker push DOCKERHUB_USERNAME/chillspot:1.0
```

What happens:

* Docker checks which layers already exist in Docker Hub
* Only missing layers are uploaded
* Existing layers are reused

---

### Step 6: Verify Push Worked (Two Ways)

Terminal verification:

```bash
docker pull DOCKERHUB_USERNAME/chillspot:1.0
```

Docker Hub verification:

* Open your repository page on Docker Hub
* Confirm the `1.0` tag exists

---

### Common Failure Modes (Fast Fix)

1. `denied: requested access to the resource is denied`

* Cause: wrong Docker Hub username, not logged in, or repo not owned by you
* Fix:

  ```bash
  docker logout
  docker login
  ```

2. `tag does not exist`

* Cause: you tagged the wrong local image name or it was never built
* Fix:

  ```bash
  docker build -t chillspot:latest .
  docker tag chillspot:latest DOCKERHUB_USERNAME/chillspot:1.0
  ```

3. `unauthorized: authentication required`

* Cause: not logged in or stale credentials
* Fix:

  ```bash
  docker logout
  docker login
  ```

---

### Final Checkpoint

If you can do this from zero:

* build `chillspot:latest`
* create Docker Hub repo
* login correctly
* tag to `DOCKERHUB_USERNAME/chillspot:TAG`
* push successfully

Then you understand container registries at the correct practical level.

**One-Line Definition**

- A container registry is a remote store for container images so the same image can be shared across development, CI, and production.

---