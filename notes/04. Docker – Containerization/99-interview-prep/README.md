[Home](../README.md) |
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

---

# Docker — Interview Prep

Answers are 30 seconds. No padding. Every question here actually comes up.

---

## Image vs Container · Containers vs VMs

**What is the difference between an image and a container?**

An image is a read-only package — app code, runtime, dependencies, config — built from a Dockerfile. A container is a running instance of that image. One image can run as many containers as you need. The image never changes when a container runs. Containers are disposable — delete one and start another from the same image.

**What is the difference between a container and a VM?**

A VM runs a full guest OS on top of a hypervisor — heavy, slow to start, gigabytes of overhead per instance. A container shares the host OS kernel and uses namespaces and cgroups to isolate processes — starts in milliseconds, uses megabytes, dozens per host. VMs virtualize hardware. Containers isolate processes. Both exist in production — Kubernetes nodes are VMs, containers run inside them.

**Why use Docker at all?**

The environment problem. Code works on your machine because your machine is set up correctly. Docker packages the app and its environment together. That package runs identically on any machine with Docker installed. No more "works on my machine."

---

## Namespaces · cgroups · How Docker Uses the Linux Kernel

**How does Docker actually create a container?**

Docker uses three Linux kernel features. Namespaces limit what a process can see — its own filesystem, network, processes, users, and hostname. cgroups limit how much CPU and memory a process can use. Union filesystems (overlayfs) stack read-only image layers and add one writable layer on top. A container is a Linux process with these three constraints applied.

**What is a namespace?**

A namespace restricts a process's view of the system. A container's network namespace gives it its own IP stack and its own localhost — completely separate from the host and every other container. This is why `localhost` inside webstore-api means webstore-api itself, not webstore-db.

**What is a cgroup?**

A cgroup (control group) limits how much CPU, memory, and I/O a process group can consume. When a container gets OOM-killed (exit code 137), it hit its cgroup memory limit. `docker stats` shows cgroup limits in real time.

---

## Container Lifecycle · Debugging

**What happens when you run `docker run`?**

Docker checks if the image exists locally. If not, it pulls from the registry. It creates a container — a new namespace set, a writable layer on top of the image layers, and a network interface. It starts the process defined by CMD or ENTRYPOINT. The container lives as long as that process runs.

**A container is running but the app isn't working. What do you do?**

Never rebuild first. `docker logs CONTAINER_NAME` to see what the app is outputting. If the app is alive but misbehaving, `docker logs -f` to follow live. If logs aren't enough, `docker exec -it CONTAINER_NAME /bin/sh` to get inside. `docker inspect` to check env vars, ports, and network. Rebuild only after you know the root cause.

**What does exit code 137 mean?**

The container was killed by OOM — the cgroup memory limit was hit. Check `docker inspect` for memory limits and `docker stats` for usage before the crash.

---

## Port Binding · NAT · Container Networking

**What does `-p 8080:8080` actually do?**

It creates an iptables DNAT rule on the host. Traffic arriving on host port 8080 gets its destination rewritten to the container's private IP on port 8080. The container never sees the original host address — it just receives a normal incoming connection. `sudo iptables -t nat -L DOCKER -n` shows the rules Docker created.

**Why can't two containers on the same host talk using `localhost`?**

Each container has its own network namespace — its own localhost. `localhost` inside webstore-api means webstore-api itself. To reach webstore-db, you use the container name as the hostname. Docker DNS on the custom network resolves it to the container's IP automatically.

**What is Docker DNS and how does it work?**

When you create a custom Docker network, Docker starts an embedded DNS server at `127.0.0.11` for that network. Every container that joins gets its name registered. When webstore-api asks for `webstore-db`, it queries `127.0.0.11`, gets back the IP, and connects. This only works on custom named networks — the default bridge network does not have Docker DNS.

**Why doesn't webstore-db have a `-p` flag?**

Databases should never be exposed publicly. webstore-db is reachable from webstore-api over the Docker network using the container name. No port binding means no external access — the container is invisible to anything outside Docker. This is the same principle as putting a database in a private subnet on AWS.

---

## Layers · Caching · Image Optimization

**What is a Docker image layer?**

Each Dockerfile instruction creates one read-only layer. Layers are stacked — each one represents the filesystem changes from that instruction. When a container runs, Docker adds one writable layer on top. All read-only layers are shared across containers from the same image.

**How does Docker layer caching work?**

Docker hashes each instruction and its context. If the hash matches a previous build, Docker reuses that layer — no work is done. If the hash changes, that layer and every layer after it rebuilds. This is why `COPY . .` must come after `RUN npm install` — changing source code should not invalidate the dependency install cache.

**What is a multi-stage build and why use it?**

A multi-stage build uses multiple `FROM` instructions in one Dockerfile. The first stage (builder) compiles or builds the app. The second stage (runtime) copies only the compiled output from the builder — no build tools, no source code, no intermediate files. The result is a small, production-safe image.

**What goes in `.dockerignore`?**

`node_modules` — already installed inside the image by `RUN npm install`, copying from host wastes space. `.git` — version history has no place in a runtime image. `.env` — secrets must never be baked into an image. `*.log` — log files change constantly and break layer caching.

---

## Volumes · Named vs Bind · Data Persistence

**What happens to data written inside a container when it is deleted?**

It is gone. A container's writable layer is deleted with the container. Anything that must survive — database rows, uploaded files, logs — must be stored in a volume outside the container.

**What is the difference between a named volume and a bind mount?**

A named volume is managed by Docker. Docker controls where it lives on the host. Use it for database data — anything critical that must persist. A bind mount maps a specific host path into the container. You control the path. Use it in development — edit code on your laptop, see changes instantly inside the container.

**Why does webstore-db use a named volume?**

`/var/lib/postgresql/data` is where postgres writes its data files. Without a volume, deleting and recreating the container means every row in the database is gone. The named volume `webstore-db-data` lives independently of the container — delete and recreate the container, the data is still there.

---

## Dockerfile · Build-time vs Run-time · Multi-stage

**What is the difference between `RUN`, `CMD`, and `ENTRYPOINT`?**

`RUN` executes during `docker build` and creates a new layer — use it to install packages or set up the environment. `CMD` is the default command when a container starts — it runs at runtime and can be overridden by passing a command to `docker run`. `ENTRYPOINT` is the fixed starting point — it always runs, and `CMD` becomes its default arguments.

**What is the correct order of instructions in a Dockerfile?**

Stable things first, volatile things last. Base image (`FROM`), system packages (`RUN apt-get`), dependency manifest (`COPY package.json`), dependency install (`RUN npm install`), source code (`COPY . .`), startup command (`CMD`). Source code changes on every commit — putting it last means the expensive install steps stay cached.

**What does `EXPOSE` do?**

Nothing at runtime. It is documentation only — it tells anyone reading the Dockerfile which port the app listens on. Actual port binding happens with `-p` when you run the container. `EXPOSE` without `-p` does not make the port reachable.

---

## Registry · Tagging · Push and Pull

**What is a container registry?**

A remote storage system for Docker images. Developers push to it after building. CI pulls from it to test. Production pulls from it to deploy. The registry is passive — it stores images, it does not run them. Docker Hub is the default public registry. ECR, GCR, and ACR are cloud-managed private registries.

**Why should you never deploy `latest` to production?**

`latest` is mutable — it points to whatever was pushed most recently. In production you need to know exactly which version is running and be able to roll back to a specific version. Use Git SHA tags (`webstore-api:a3f92c1`) for CI builds and semantic version tags (`webstore-api:v1.0.0`) for releases.

**What is the full workflow to push an image to Docker Hub?**

Build the image, tag it with your Docker Hub username and the target repo name, login with `docker login`, push with `docker push`. The tag format is `USERNAME/IMAGE:TAG`. Kubernetes later pulls this same tag — what you push here is what the cluster runs.

---

## Compose · depends_on · Networks and Volumes

**What does Docker Compose do?**

Replaces multiple `docker run` commands with one declarative file. It automates container creation, Docker networking, DNS, port binding, startup order, and volume creation. It does not add new concepts — everything Compose does, you can do manually with `docker run`. Compose just does it consistently from a single file.

**What does `depends_on` do?**

It controls startup order — the listed service starts before the dependent one. It does not guarantee the service is ready to accept connections. webstore-db starting before webstore-api means the postgres process started, not that it finished initializing. The app still needs retry logic for database connections.

**What is the difference between `docker compose down` and `docker compose down -v`?**

`docker compose down` removes containers and the network — volumes are left untouched. `docker compose down -v` removes containers, network, and all named volumes. `-v` deletes the database volume. All data is gone. Only use it when you want a completely clean reset.

---

← [Back to Docker README](../README.md)
