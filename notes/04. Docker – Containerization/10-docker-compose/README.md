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

# 10. Docker Compose — Same System, Automated

## 1) Mental Model First (What You Are About to Read)

Docker Compose replaces many manual `docker run` commands with **one file**.

Below is the **entire webstore system** in one view.

Do not analyze it yet.
Just observe the shape.

```yaml
version: "3.9"

services:
  webstore-db:
    image: mongo
    environment:
      MONGO_INITDB_ROOT_USERNAME: admin
      MONGO_INITDB_ROOT_PASSWORD: secret

  mongo-express:
    image: mongo-express
    ports:
      - "8081:8081"
    environment:
      ME_CONFIG_MONGODB_ADMINUSERNAME: admin
      ME_CONFIG_MONGODB_ADMINPASSWORD: secret
      ME_CONFIG_MONGODB_URL: mongodb://admin:secret@webstore-db:27017
    depends_on:
      - webstore-db

  webstore-api:
    build: .
    ports:
      - "8080:8080"
    environment:
      MONGO_URL: mongodb://admin:secret@webstore-db:27017
    depends_on:
      - webstore-db
```

What this shows at a glance:

* Three containers
* One private Docker network (created automatically)
* Two ports exposed for human access (8080 for app, 8081 for DB UI)
* One database accessed internally by hostname

Everything below explains **this file**, line by line.

---

## 2) What Docker Compose Is

Docker Compose runs a multi-container system using **one declarative file** instead of many imperative commands.

Compose does not add new concepts.
It automates:

* container creation
* Docker networking
* DNS (service names)
* port binding
* startup order

---

## 3) Services Block (System Definition)

```yaml
services:
```

Meaning:

* Start of all containers in this system
* Each service becomes:
  * one container
  * one DNS hostname
  * one isolated process

---

## 4) webstore-db Service (Database Server)

```yaml
  webstore-db:
```

Meaning:

* Service name
* Also becomes hostname `webstore-db`
* Used by other containers to connect

```yaml
    image: mongo
```

Meaning:

* Use the official MongoDB image
* Pulled automatically if missing

```yaml
    environment:
      MONGO_INITDB_ROOT_USERNAME: admin
      MONGO_INITDB_ROOT_PASSWORD: secret
```

Meaning:

* Environment variables passed into the container
* MongoDB uses them on first startup
* Creates the initial admin user

Important:

* No `ports` section
* Database is internal-only
* Not exposed to the host

---

## 5) mongo-express Service (UI Client)

```yaml
  mongo-express:
```

Meaning:

* UI tool container
* Hostname becomes `mongo-express`

```yaml
    image: mongo-express
```

Meaning:

* Uses the Mongo Express image
* Provides a web interface for the database

```yaml
    ports:
      - "8081:8081"
```

Meaning:

* Host port `8081` forwards to container port `8081`
* Required so the browser can access the DB UI

```yaml
    environment:
      ME_CONFIG_MONGODB_ADMINUSERNAME: admin
      ME_CONFIG_MONGODB_ADMINPASSWORD: secret
      ME_CONFIG_MONGODB_URL: mongodb://admin:secret@webstore-db:27017
```

Meaning:

* Credentials for the database
* Connection uses hostname `webstore-db`
* DNS is provided automatically by Compose

```yaml
    depends_on:
      - webstore-db
```

Meaning:

* webstore-db container starts first
* Controls start order only
* Does not guarantee readiness

---

## 6) webstore-api Service (Application)

```yaml
  webstore-api:
```

Meaning:

* Application container
* Hostname becomes `webstore-api`

```yaml
    build: .
```

Meaning:

* Builds image from Dockerfile in current directory
* Equivalent to `docker build .`

```yaml
    ports:
      - "8080:8080"
```

Meaning:

* Host port `8080` forwards to app port `8080`
* Required for browser access to the API

```yaml
    environment:
      MONGO_URL: mongodb://admin:secret@webstore-db:27017
```

Meaning:

* Database connection string for the app
* Uses service name `webstore-db`
* Same rule as manual Docker networking — containers talk by name

```yaml
    depends_on:
      - webstore-db
```

Meaning:

* Starts webstore-db before the app
* Prevents obvious startup failures
* Not a health check

---

## 7) What Compose Creates Automatically

When you run:

```bash
docker compose up
```

Compose automatically creates:

* one bridge network
* DNS entries for each service
* containers attached to that network

You do not need to define networks explicitly for this setup.

---

## 8) Running the System

Start everything:

```bash
docker compose up
```

Start in background:

```bash
docker compose up -d
```

Stop and clean up:

```bash
docker compose down
```

This removes:

* containers
* Compose-created network

Images and volumes remain unchanged.

---

## 9) About the `-f` Flag

Default behavior:

* Compose reads `docker-compose.yml`
* Also accepts `compose.yml`

`-f` selects a specific file:

```bash
docker compose -f docker-compose.prod.yml up
docker compose -f docker-compose.prod.yml down
```

Rule:
If the file is named `docker-compose.yml` and you are in that folder, do not use `-f`.

---

## 10) Manual vs Compose

![](./readme-assets/docker-run-compose.jpeg)

Use manual Docker commands when:

* learning Docker
* debugging a single container
* understanding flags

Use Docker Compose when:

* running multi-container systems
* daily development
* you want reproducible setup

**Data flows (same as manual, just automated):**

App path:
```
Browser → localhost:8080 → webstore-api → webstore-db:27017 → webstore-db
```

Debug path:
```
Browser → localhost:8081 → mongo-express → webstore-db:27017 → webstore-db
```

One-line truth:
webstore-api connects to webstore-db using hostname `webstore-db` on a Docker network.
Compose only automates the same configuration you already know.

→ Ready to practice? [Go to Lab 04](../docker-labs/04-registry-compose-lab.md)
