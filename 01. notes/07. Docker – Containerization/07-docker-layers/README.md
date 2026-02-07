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

# 07. Docker Layers — Notes (Structured + Chronological)

## 1) What are Docker Layers?
A Docker image is not a single file.  
It is built as a **stack of immutable layers**.

Each layer represents the result of **one Dockerfile instruction**.  
The final image is the combination of all these layers.

Key idea:
- Instructions are executed **top → bottom**
- Layers are stacked **base → top**

---

## 2) Visual Mental Model (Runtime vs Image)

![](./readme-assets/container-filesystem.jpg)

```

## [ RUNTIME ] -> Writable Container Layer    (DISPOSABLE/Temporary)

[ LAYER 7 ] -> CMD ["node","app.js"]          (IMMUTABLE)           #Read-only
[ LAYER 6 ] -> COPY . .                       (CHANGE-SENSITIVE)    #Read-only
[ LAYER 5 ] -> RUN npm install                (HEAVY / CACHED)      #Read-only
[ LAYER 4 ] -> COPY package.json .            (CACHE KEY)           #Read-only
[ LAYER 3 ] -> WORKDIR /app                   (STRUCTURAL)          #Read-only
[ LAYER 2 ] -> Intermediate OS setup          (BASE)                #Read-only
[ LAYER 1 ] -> FROM node:20                   (BASE)                #Read-only

````

Notes:
- Image layers are **immutable**
- Container runtime adds **one writable layer on top**
- When the container is deleted, the writable layer is lost

---

## 3) How Layers Are Created (Build Order)

Docker reads the Dockerfile **line-by-line from top to bottom**.

Example:
```dockerfile
FROM node:20
WORKDIR /app
COPY package.json .
RUN npm install
COPY . .
CMD ["node","server.js"]
````

Rules:

* Each instruction creates **one image layer**
* Order of instructions matters
* Later layers depend on earlier layers

---

## 4) Why Layers Exist (Core Benefits)

### Faster Builds (Build Cache)

* Docker caches layers during `docker build`
* If a layer did not change, Docker reuses it
* This dramatically reduces build time

### Faster Pulls (Layer Reuse)

* Images are pulled layer-by-layer
* Existing layers are reused
* Only missing layers are downloaded

### Disk Space Efficiency

* Identical layers are stored only once
* Multiple images can share the same layers

---

## 5) Build Cache Behavior (docker build)

Question:
If one layer changes, will Docker rebuild the layers after it?

Answer:
Yes.

Why:
Each layer depends on the filesystem output of the previous layer.

Example:

```dockerfile
COPY package.json .
RUN npm install
COPY . .
```

If `package.json` changes:

* COPY package.json . changes
* RUN npm install must run again
* COPY . . must run again

Rule:
Build = change at step N → rebuild step N and everything after it

---

## 6) Pull Reuse Behavior (docker pull)

When you run:

```bash
docker pull mysql:latest
```

Docker is **not rebuilding anything** locally.

What happens:

* Docker checks layer hashes
* Matching hashes are reused
* Missing hashes are downloaded

Example:

* Layer 1 changed → download
* Layer 2 same → reuse
* Layer 3 changed → download

Final image is a mix of old and new layers, as long as hashes match exactly.

Rule:
Pull = reuse identical layers, download only missing layers

---

## 7) One-Line Difference (Memorize)

Build:
I am creating layers now → change breaks everything after it

Pull:
Image already built → I only download missing layers

---

## 8) Exact Matching Only (Important Rule)

Docker does **not** reuse similar files.

Rules:

* Same hash → reuse
* Different hash → rebuild or download

There is no partial match or file-level comparison.

---

## 9) Command to View Layers

To inspect image layers:

```bash
docker history IMAGE
```

Example:

```bash
docker history node:20
```

This shows:

* Instruction that created each layer
* Size of each layer
* Order of layers

---

## Quick Recap

* Images are built from immutable layers
* Dockerfile instructions create layers in order
* Build cache: change at step N → rebuild N and after
* Pull reuse: download only missing layers
* Layers are reused only when hashes match exactly
* Containers add a single writable runtime layer

---