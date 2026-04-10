[Home](../README.md) |
[Labs Index](./README.md) |
[Lab 01](./01-containers-portbinding-lab.md) |
[Lab 02](./02-networking-volumes-lab.md) |
[Lab 03](./03-build-layers-lab.md) |
[Lab 04](./04-registry-compose-lab.md)

---

# Lab 04 — Registry & Compose

## The Situation

`webstore-api:1.0` exists on your laptop. It runs correctly. But it only exists on your laptop — no CI system can pull it, no production server can run it, no teammate can use it. And bringing up the full three-tier webstore still requires running three separate `docker run` commands in the right order with all the right flags.

This lab finishes both problems. You push the image to Docker Hub so it is available everywhere. Then you write a `docker-compose.yml` that captures the entire webstore — api, database, and DB UI — in one file. From this point forward, bringing up the entire webstore is one command: `docker compose up`.

This is the state Kubernetes picks up from. K8s does not run `docker run` commands — it pulls images from a registry and runs them based on manifest files. What you do in this lab is exactly the pattern Kubernetes uses, just at the orchestration layer.

## What this lab covers

You will push the webstore-api image to Docker Hub, pull it back to confirm it works, then write a `docker-compose.yml` from scratch that brings up the full webstore system — api, postgres database, and adminer UI — with one command. You will break the compose file on purpose, fix it, and do a clean teardown. Every file is written from scratch.

## Prerequisites

- [Docker Registry notes](../09-docker-registry/README.md)
- [Docker Compose notes](../10-docker-compose/README.md)
- Lab 03 completed — `webstore-api:1.0` image must exist locally
- A Docker Hub account

---

## Section 1 — Prepare and Push to Docker Hub

**Goal:** publish your local webstore-api image to Docker Hub.

1. Confirm the image exists locally
```bash
docker images | grep webstore-api
```

If it is missing, go back and build it from Lab 03 before continuing.

2. Check which Docker account you are logged into
```bash
docker info | grep -i username
```

3. If you see the wrong account or nothing — log out and back in
```bash
docker logout
docker login
```

4. Verify again
```bash
docker info | grep -i username
```

5. Tag the image for Docker Hub
```bash
docker tag webstore-api:1.0 YOUR_DOCKERHUB_USERNAME/webstore-api:1.0
```

6. Confirm both tags exist
```bash
docker images | grep webstore-api
```

**What to observe:** two rows — your local tag and the Docker Hub tag

7. Push to Docker Hub
```bash
docker push YOUR_DOCKERHUB_USERNAME/webstore-api:1.0
```

**What to observe:** Docker uploads only missing layers. Shared base layers (node:20-alpine) may already exist and get skipped.

8. Open Docker Hub in your browser and confirm the tag `1.0` appears in your `webstore-api` repository.

---

## Section 2 — Pull and Verify

**Goal:** delete the local image and pull it back from Docker Hub to prove the registry works.

1. Remove the local images (both tags)
```bash
docker rmi webstore-api:1.0
docker rmi YOUR_DOCKERHUB_USERNAME/webstore-api:1.0
```

2. Confirm they are gone
```bash
docker images | grep webstore-api
```

3. Pull from Docker Hub
```bash
docker pull YOUR_DOCKERHUB_USERNAME/webstore-api:1.0
```

4. Run it and confirm it still works
```bash
docker run -d --name webstore-api-test -p 8080:8080 YOUR_DOCKERHUB_USERNAME/webstore-api:1.0
curl http://localhost:8080
```

**What to observe:** same JSON response as before — the image came from the registry, not your local build

5. Clean up
```bash
docker stop webstore-api-test
docker rm webstore-api-test
```

---

## Section 3 — Write docker-compose.yml from Scratch

**Goal:** define the full webstore system in one file and bring it up with one command.

1. Create a working folder
```bash
mkdir ~/webstore && cd ~/webstore
```

2. Copy your webstore-api app files here (from Lab 03)
```bash
cp ~/webstore-api/server.js .
cp ~/webstore-api/package.json .
cp ~/webstore-api/Dockerfile .
cp ~/webstore-api/.dockerignore .
```

3. Write `docker-compose.yml` from scratch
```yaml
version: "3.9"

services:

  webstore-db:
    image: postgres:15
    environment:
      POSTGRES_DB: webstore
      POSTGRES_USER: admin
      POSTGRES_PASSWORD: secret
    volumes:
      - webstore-db-data:/var/lib/postgresql/data

  adminer:
    image: adminer
    ports:
      - "8081:8080"
    depends_on:
      - webstore-db

  webstore-api:
    build: .
    ports:
      - "8080:8080"
    environment:
      DB_HOST: webstore-db
      DB_PORT: 5432
      DB_NAME: webstore
      DB_USER: admin
      DB_PASSWORD: secret
    depends_on:
      - webstore-db

volumes:
  webstore-db-data:
```

4. Start the full system
```bash
docker compose up
```

Watch the startup logs — you will see all three containers initializing.

5. Open your browser and confirm both endpoints work:
```
http://localhost:8080   ← webstore-api
http://localhost:8081   ← adminer DB UI
```

For adminer, log in with:
- System: PostgreSQL
- Server: `webstore-db`
- Username: `admin`
- Password: `secret`
- Database: `webstore`

6. Stop with `Ctrl+C`, then bring it back up in the background
```bash
docker compose up -d
```

7. Confirm all three containers are running
```bash
docker ps
```

8. Check logs for a specific service
```bash
docker compose logs webstore-api
docker compose logs webstore-db
```

---

## Section 4 — Inspect What Compose Created

**Goal:** understand what Compose built automatically.

1. List networks
```bash
docker network ls
```

**What to observe:** Compose created a new network named after your folder (e.g. `webstore_default`)

2. List containers
```bash
docker ps
```

**What to observe:** container names follow the pattern `webstore-SERVICENAME-1`

3. Inspect the network
```bash
docker network inspect webstore_default
```

**What to observe:** all three containers are attached to the same network with their service names as DNS hostnames

4. Verify adminer reaches the database using the service name
```bash
docker exec webstore-adminer-1 nslookup webstore-db 2>/dev/null || \
docker exec $(docker ps -qf name=adminer) nslookup webstore-db
```

**What to observe:** DNS resolves `webstore-db` to its container IP — same as manual networking

---

## Section 5 — Break It on Purpose

### Break 1 — Wrong service name in connection string

1. Bring the system down
```bash
docker compose down
```

2. Edit `docker-compose.yml` — change the DB_HOST in webstore-api
```yaml
      DB_HOST: wrong-db
```

3. Bring it back up
```bash
docker compose up -d
```

4. Check webstore-api logs
```bash
docker compose logs webstore-api
```

**What to observe:** connection error — `wrong-db` does not exist as a hostname on the network

5. Fix it — restore `DB_HOST: webstore-db`
```bash
docker compose down
# fix the file
docker compose up -d
```

### Break 2 — Port already in use

1. Start a standalone nginx on port 8080
```bash
docker run -d --name port-blocker -p 8080:8080 nginx:1.24
```

2. Try to bring Compose up
```bash
docker compose up -d
```

**What to observe:** `Bind for 0.0.0.0:8080 failed: port is already allocated` — Compose cannot claim a port another container owns

3. Fix it
```bash
docker stop port-blocker && docker rm port-blocker
docker compose up -d
```

### Break 3 — Remove depends_on and watch startup order fail

1. Bring the system down
```bash
docker compose down
```

2. Edit `docker-compose.yml` — remove both `depends_on` blocks

3. Bring it up and watch the logs
```bash
docker compose up
```

**What to observe:** webstore-api and adminer may start before webstore-db is ready and log connection errors

4. Fix it — restore both `depends_on` blocks
```bash
# Ctrl+C to stop
docker compose down
# fix the file
docker compose up -d
```

---

## Section 6 — Safe Delete Flow

1. Stop and remove all Compose containers and network
```bash
docker compose down
```

2. Confirm containers and network are gone
```bash
docker ps -a
docker network ls
```

3. Remove the volume (only when you want to discard all database data)
```bash
docker compose down -v
```

4. Remove images
```bash
docker rmi YOUR_DOCKERHUB_USERNAME/webstore-api:1.0
docker rmi postgres:15 adminer nginx:1.24
```

5. Final check
```bash
docker images
docker ps -a
docker network ls
docker volume ls
```

Everything should be clean.

---

## Checklist

Do not move to Kubernetes until every box is checked.

- [ ] I confirmed my local webstore-api image existed before starting
- [ ] I tagged it correctly as `YOUR_DOCKERHUB_USERNAME/webstore-api:1.0` and pushed it
- [ ] I verified the push on Docker Hub in the browser — the `1.0` tag was visible
- [ ] I deleted the local image and pulled it back from Docker Hub — it ran correctly
- [ ] I wrote `docker-compose.yml` from scratch using postgres:15 and adminer — I did not copy-paste it
- [ ] I brought the full system up with `docker compose up -d` and hit both browser endpoints
- [ ] I logged into adminer using `webstore-db` as the server hostname — Docker DNS resolved it
- [ ] I inspected the auto-created network and confirmed all three containers were on it
- [ ] I broke the DB_HOST with a wrong name and read the connection error in the logs
- [ ] I produced a port conflict error by running a container on 8080 before Compose started
- [ ] I removed `depends_on` and observed startup order problems in the logs
- [ ] I ran `docker compose down` and confirmed containers and network were removed cleanly
