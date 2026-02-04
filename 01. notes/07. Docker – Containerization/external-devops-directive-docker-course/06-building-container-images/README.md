[Home](../README.md) | [History and Motivation](../01-history-and-motivation/README.md)
| [Technology Overview](../02-technology-overview/README.md)
| [Installation and Set Up](../03-installation-and-set-up/README.md)
| [Using 3rd Party Containers](../04-using-3rd-party-containers/README.md)
| [Example Web Application](../05-example-web-application/README.md)
| [Building Container Images](../06-building-container-images/README.md)
| [Container Registries](../07-container-registries/README.md)
| [Running Containers](../08-running-containers/README.md)
| [Container Security](../09-container-security/README.md)
| [Interacting with Docker Objects](../10-interacting-with-docker-objects/README.md)
| [Development Workflows](../11-development-workflow/README.md)
| [Deploying Containers](../12-deploying-containers/README.md)

---

# Building Container Images

## 0) Absolute Zero (Before Docker Exists)

You have:

* a laptop
* a folder with your app code (files)

That’s it.

No Linux knowledge required.
No Node knowledge required.
No Docker knowledge required.

---

## 1) The Problem (Before Docker)

Your app needs **two things** to run:

1. The app files (your code)
2. A way to run them (runtime like Node, Python, Java)

Right now:

* both exist **only on your laptop**

You want:

* **one package**
* that contains **everything needed to run the app**
* so it runs **anywhere**

That package is called a **Docker image**.

You don’t have it yet.

---

## 2) Docker Cannot Guess Anything

Docker is dumb.

It does NOT know:

* what language your app uses
* how to start it
* where files should live

So you must explain **step by step**.

That explanation is written in a file called:

**Dockerfile**

At this point:

* Dockerfile is just a text file
* nothing runs
* nothing is built

---

## 3) Two Timelines (THIS IS THE CORE)

### Build-time (docker build)

* FROM
* WORKDIR
* RUN
* COPY
* ENV

Purpose:

> create an **image**

### Run-time (docker run)

* CMD
* ENTRYPOINT
* runtime environment variables

Purpose:

> start a **container** from the image

**Rule**

* If it must exist **before the app starts** → build-time
* If it runs **when the app starts** → run-time

Never mix these mentally.

---

## 4) First Question Docker Asks → FROM

Docker cannot start from nothing.

So the first line must answer:

> “What should I start from?”

```dockerfile
FROM node
```

Plain English:

* “Start from a ready-made environment that already knows how to run Node apps.”

Important:

* You are **not installing Node**
* You are **borrowing a prepared filesystem**
* FROM **must be first** (non-negotiable)

---

## 5) WORKDIR — Set the Default Folder (Recommended)

```dockerfile
WORKDIR /app
```

Plain English:

* “Inside the image, treat `/app` as the current folder.”

Facts:

* WORKDIR **creates the folder if missing**
* replaces `cd` (which does NOT persist across layers)
* prevents path confusion

---

## 6) ENV — Store Configuration (Optional)

```dockerfile
ENV MONGO_DB_USERNAME=admin \
    MONGO_DB_PWD=qwerty
```

Plain English:

* “Store key=value pairs inside the image.”

Facts:

* ENV does **not run anything**
* values are available at runtime (e.g. `process.env`)
* runtime env vars override image env vars
* **not for secrets**

---

## 7) RUN — Build-Time Setup

```dockerfile
RUN apk add --no-cache curl
```

Plain English:

* “While building the image, run this command and save the result.”

Facts:

* RUN executes at **build-time**
* RUN can be used **multiple times**
* each RUN creates a **layer**
* use for:

  * OS packages
  * installing dependencies
  * downloading files from internet
  * system setup

**Rule**

* Readability > micro-optimization
* Combine RUNs only when cleanup matters

---

## 8) COPY — Put Your App Into the Image (Mandatory)

```dockerfile
COPY . .
```

Chronological meaning:

* first `.` → your project folder on laptop (build context)
* second `.` → current folder inside image (`/app` because of WORKDIR)

Plain English:

* “Copy my app files into the image.”

Facts:

* Without COPY, your code never enters Docker
* Docker can only COPY files **inside build context**

---

## 9) Internet Files Rule (Critical)

* Local files → `COPY`
* Internet files → `RUN curl / wget`
* Secrets / dynamic data → runtime, NOT image

Example:

```dockerfile
RUN curl -fsSL -o /app/file.dat https://example.com/file.dat
```

Never rely on ADD unless you know exactly why.

---

## 10) EXPOSE — Documentation Only

```dockerfile
EXPOSE 3000
```

Facts:

* EXPOSE does **not open ports**
* EXPOSE does **not publish ports**
* it is **metadata only**

Real access happens with:

```bash
docker run -p 3000:3000 image
```

If you forget EXPOSE, nothing breaks.

---

## 11) CMD — How the App Starts (Run-Time)

```dockerfile
CMD ["node", "server.js"]
```

Plain English:

* “When a container starts, run this command.”

Facts:

* CMD does **nothing during build**
* runs **only at docker run**
* one image → many containers → same CMD
* can be overridden at runtime

---

## 12) Build the Image (Nothing Runs Yet)

```bash
docker build -t chillspot:1.0 .
```

Meaning:

* `-t` → name the image
* `chillspot` → image name
* `1.0` → version tag
* `.` → build context (files Docker is allowed to COPY)

After this:

* image exists
* app is NOT running

---

## 13) Verify Image

```bash
docker images
```

You should see:

```
chillspot   1.0
```

---

## 14) Run the Image (FIRST Time Anything Runs)

```bash
docker run chillspot:1.0
```

Now:

* Docker creates a container
* executes CMD
* app actually runs

This is the **first moment** anything executes.

---

## 15) Canonical Dockerfile (REFERENCE SHAPE)

```dockerfile
FROM <base-image>

WORKDIR /app

RUN <install OS deps>

COPY <dependency manifests> ./
RUN <install app deps>

COPY . .

EXPOSE <app-port>   # documentation only

CMD ["<start-command>"]
```

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

1) Instruction laws
- FROM: starting filesystem + tools
- WORKDIR: default folder (creates it)
- RUN: build-time execution (can be used multiple times)
- COPY: bring files from build context
- ENV: static defaults (not secrets)
- EXPOSE: metadata only
- CMD: default runtime command

2) File sourcing rules
- Local files → COPY
- Internet files → RUN curl / wget
- Secrets / dynamic data → runtime, not image

3) OS rule
Inside Docker = Linux.
Language tools are portable.
OS package managers are Linux-specific.
---

## 17) One-Line Truth (Replace All Other Notes)

> A Dockerfile is a cached, ordered, Linux build recipe that separates build-time from run-time to create reproducible images.

---