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

# 06. Docker Volumes

## 1) The Problem (Why Volumes Exist)

Containers are **disposable**.

- Containers can stop
- Containers can be deleted
- Containers can be recreated anytime

Anything written **inside a container filesystem** exists only as long as that container exists.

This is a problem for:
- databases
- user uploads
- logs
- application state

Docker solves this by separating **compute** from **data**.

That separation is called **Volumes**.

---

## 2) The Core Rule (Lock This)

- Containers are temporary
- Data must be permanent

If data matters, it **must not live inside the container**.

---

## 3) What a Volume Is (Mental Model)

A volume is **storage outside the container**, mounted into it at runtime.

- The container can read/write data
- The container does **not own** the data
- The data survives container deletion

---

## 4) Visual Mental Model (Full Picture)

![](./readme-assets/volumes.jpg)

Interpretation:
- Containers sit in the middle
- Data lives outside
- Containers come and go
- Volumes persist

This image is the entire idea of volumes.

---

## 5) Proof: Container Data Dies With the Container

### Step 1: Create a container and write data

```bash
docker run -it --name test-container ubuntu:22.04
mkdir /my-data
echo "hello" > /my-data/file.txt
exit
````

The container is now **stopped**, not deleted.

---

### Step 2: Restart the same container

```bash
docker start -ai test-container
cat /my-data/file.txt
```

Result:

* file exists

Stopping a container does **not** delete data.

---

### Step 3: Remove the container

```bash
docker rm test-container
docker run -it ubuntu:22.04
cat /my-data/file.txt
```

Result:

* file does not exist

Conclusion:

* data lived inside the container
* deleting the container destroyed it

This is why volumes exist.

---

## 6) Volume Types (Only Two That Matter)

### 1) Named Volumes (Default, Recommended)

* Managed by Docker
* Independent of host filesystem
* Best for databases and production data

### 2) Bind Mounts

* Direct link to a host directory
* Best for development and config files
* Tied to your machine layout

That’s it. No third type needed right now.

---

## 7) Named Volume (Correct, Minimal Example)

```bash
docker run -it --rm \
  -v my-volume:/my-data \
  ubuntu:22.04
```

What this means:

* `my-volume` → persistent storage managed by Docker
* `/my-data` → folder inside the container
* data written here survives container deletion

Write data:

```bash
echo "hello from volume" > /my-data/file.txt
exit
```

Run again with the same volume:

```bash
docker run -it --rm \
  -v my-volume:/my-data \
  ubuntu:22.04
cat /my-data/file.txt
```

Result:

* file exists

Mental model:

```text
Container A ─┐
             ├── Volume (my-volume) ── persists
Container B ─┘
```

---

## 8) Bind Mount (Host-Visible Data, Clear Version)

### Step 1: See where you are on the host

```bash
pwd
```

Example output:

```text
/Users/akhil/projects/chillspot
```

This is your **host path**.

---

### Step 2: Mount a host folder into the container

```bash
docker run -it --rm \
  -v /Users/akhil/projects/chillspot/my-data:/my-data \
  ubuntu:22.04
```

What this means:

* left side → real folder on your laptop
* right side → folder inside the container
* changes appear immediately on the host

Write data:

```bash
echo "hello from bind mount" > /my-data/file.txt
exit
```

Check on host:

```bash
cat my-data/file.txt
```

Result:

* file exists on your laptop

Mental model:

```text
Host Folder  <───►  Container Folder
```

---

## 9) When to Use What (Decision Table)

| Situation        | Use          |
| ---------------- | ------------ |
| Database data    | Named Volume |
| Production state | Named Volume |
| App source code  | Bind Mount   |
| Config files     | Bind Mount   |

Rule:

* important data → volume
* editable files → bind mount

---

## 10) Real-World Example (Database)

Databases write data to known paths.

Example: MongoDB

```bash
docker run -d \
  -v mongodata:/data/db \
  -p 27017:27017 \
  mongo:6
```

* `/data/db` is Mongo’s data directory
* volume ensures data survives container deletion

Same pattern applies to all databases.

**One-Line Definition** A Docker volume is external storage mounted into a container so data survives container deletion.