[← devops-runbook](../../README.md) |
[History & Motivation](../01-history-and-motivation/README.md) |
[Technology Overview](../02-technology-overview/README.md) |
[Docker Containers](../03-docker-containers/README.md) |
[Port Binding](../04-docker-port-binding/README.md) |
[Networking](../05-docker-networking/README.md) |
[Volumes](../06-docker-volumes/README.md) |
[Layers](../07-docker-layers/README.md) |
[Build](../08-docker-build-dockerfile/README.md) |
[Registry](../09-docker-registry/README.md) |
[Compose](../10-docker-compose/README.md)

# Docker Build (Dockerfile)

## 0) Absolute Zero (Before Docker Exists)

You have:

* a laptop
* a folder with your app code (files)

That's it.

No Linux knowledge required.
No Node knowledge required.
No Docker knowledge required.

---

## 1) The Problem (Before Docker)

Your app needs two things to run:

1. The app files (your code)
2. A way to run them (a runtime like Node, Python, Java)

Right now, both exist only on your laptop.

You want one package that contains everything needed to run the app so it runs anywhere.

That package is a Docker image.

---

## 2) Docker Cannot Guess Anything

Docker does not know:

* what language your app uses
* how to start it
* where files should live

So you must explain step by step.

That explanation is written in a text file called a **Dockerfile**.

At this point:

* nothing runs
* nothing is built

---

## 3) Two Timelines (Core Mental Model)

### Build-time (when you run `docker build`)

Build-time instructions create an **image filesystem** (layers). They permanently change what exists inside the image.

Common build-time instructions:

* `FROM`
* `WORKDIR`
* `RUN`
* `COPY` (and `ADD`, rarely)
* `ENV` (sets defaults in the image)

### Run-time (when you run `docker run`)

Run-time is when Docker creates a **container** from the image and starts the default process defined by the image.

Run-time is driven by:

* `CMD` / `ENTRYPOINT` (image metadata that defines what starts)
* runtime environment variables (`docker run -e ...` overrides image `ENV`)

**Rule**

* If it must exist before the app starts → build-time
* If it happens when the app starts → run-time

Do not mix these mentally.

---

## 4) First Question Docker Asks → `FROM`

Docker cannot start from nothing.

So the first line must answer:

> "What should I start from?"

```dockerfile
FROM node:20
```

Plain English:

* "Start from a ready-made environment that already knows how to run Node apps."

Facts:

* You are not installing Node manually here
* You are selecting a prepared filesystem
* `FROM` must be first (non-negotiable)

---

## 5) `WORKDIR` — Set the Default Folder (Recommended)

```dockerfile
WORKDIR /app
```

Plain English:

* "Inside the image, treat `/app` as the current folder."

Facts:

* `WORKDIR` creates the folder if missing
* it replaces `cd` (which does not persist across layers)
* it prevents path confusion

---

## 6) `ENV` — Store Defaults (Not Secrets)

```dockerfile
ENV NODE_ENV=production \
    PORT=8080
```

Plain English:

* "Store key=value defaults inside the image."

Facts:

* `ENV` does not run anything
* values are available at runtime (e.g., `process.env`)
* runtime env vars override image env vars
* do not store secrets in images

---

## 7) `RUN` — Build-Time Setup

`RUN` executes while building the image and saves the result into the next layer.

The command you use depends on the **base image**:

* Alpine images → `apk`
* Debian/Ubuntu images → `apt-get`

Example (Alpine base):

```dockerfile
FROM node:20-alpine
RUN apk add --no-cache curl
```

Example (Debian base):

```dockerfile
FROM node:20
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*
```

Facts:

* `RUN` executes at build-time
* each `RUN` creates a layer
* use it for OS packages, dependency installs, downloads, and setup

Rule:

* Readability > micro-optimization
* combine `RUN` steps mainly when cleanup matters

---

## 8) `COPY` — Put Your App Into the Image (Normal Path)

```dockerfile
COPY . .
```

Chronological meaning:

* first `.` → your project folder on laptop (build context)
* second `.` → current folder inside image (`/app` because of `WORKDIR`)

Plain English:

* "Copy my app files into the image."

Facts:

* In normal builds, `COPY` is how your local code enters the image
* Docker can only copy files inside the build context
* use a `.dockerignore` to avoid copying junk (`node_modules`, `.git`, build outputs)

---

## 9) `.dockerignore` — Control What Gets Copied

When Docker runs `COPY . .`, it copies everything in the build context by default.
That includes junk that slows builds and breaks layer caching.

`.dockerignore` is a file in the same folder as your Dockerfile.
It tells Docker what to exclude from the build context.

**Create `.dockerignore` in your project root:**

```
node_modules
.git
*.log
.env
dist
build
```

**Why each line matters:**

| Entry | Why exclude it |
|---|---|
| `node_modules` | Already installed by `RUN npm install` inside the image — copying from host wastes space and breaks the install layer |
| `.git` | Version control history has no place in a runtime image |
| `*.log` | Log files change constantly — they break layer caching on every build |
| `.env` | Contains secrets — never bake secrets into an image |
| `dist` / `build` | Compiled output — the image should build this itself |

**Without `.dockerignore` — what goes wrong:**

```
COPY . .     ← copies node_modules (300MB), .git, .env, logs
               layer hash changes every build even if code didn't
               cache breaks → npm install runs again every time
```

**With `.dockerignore` — what happens:**

```
COPY . .     ← copies only your source code
               layer hash stable until code actually changes
               cache works → fast builds
```

**One-line rule:**
`.dockerignore` exists so `COPY . .` only copies what the image actually needs.

---

## 10) `EXPOSE` — Documentation Only

```dockerfile
EXPOSE 8080
```

Facts:

* `EXPOSE` does not open ports
* `EXPOSE` does not publish ports
* it is metadata only

Real access happens with port binding (covered in Port Binding notes):

```bash
docker run -p 8080:8080 webstore-api:1.0
```

---

## 11) `CMD` — Default Startup Command (Run-Time)

```dockerfile
CMD ["node", "server.js"]
```

Plain English:

* "When a container starts, run this command."

Facts:

* `CMD` does nothing during build
* it runs only when a container starts
* it can be overridden at runtime

---

## 12) Build the Image (Nothing Runs Yet)

```bash
docker build -t webstore-api:1.0 .
```

Meaning:

* `-t` → tag (name) the image
* `webstore-api` → image name
* `1.0` → version tag
* `.` → build context (files Docker is allowed to `COPY`)

After this:

* image exists
* app is not running

---

## 13) Verify Image

```bash
docker images
```

---

## 14) Run the Image (First Time Anything Runs)

```bash
docker run -p 8080:8080 webstore-api:1.0
```

Now:

* Docker creates a container
* executes `CMD`
* the app runs

---

## 15) Canonical Dockerfile Shape (Reference)

```dockerfile
FROM <base-image>

WORKDIR /app

RUN <install OS deps>

COPY <dependency manifests> ./
RUN <install app deps>

COPY . .

EXPOSE <app-port>   # metadata only

CMD ["<start-command>"]
```

Later we use multi-stage builds to keep runtime images small (covered separately).

---

## 16) The Ordering Law (Memorize This)

> **Stable first. Volatile last.**

Order:

1. Base OS
2. System dependencies
3. App dependencies
4. App source code
5. Runtime command

Reason:

* Docker caches layers top → bottom
* changing a layer invalidates everything after it

---

## 17) Instruction Laws (Quick Reference)

* `FROM` → starting filesystem + tools
* `WORKDIR` → default folder (creates it)
* `RUN` → build-time execution (creates a layer)
* `COPY` → bring local files from build context
* `ENV` → static defaults (not secrets)
* `EXPOSE` → metadata only
* `CMD` → default runtime command

**File sourcing rules:**
* Local files → `COPY`
* Internet files → `RUN curl` / `RUN wget`
* Secrets / dynamic data → runtime, not image

**OS rule:**
Inside Docker = Linux.
Language tools are portable.
OS package managers are Linux-specific.

---

## 18) One-Line Truth

> A Dockerfile is a cached, ordered, Linux build recipe that separates build-time from run-time to create reproducible images.

→ Ready to practice? [Go to Lab 03](../docker-labs/03-build-layers-lab.md)
