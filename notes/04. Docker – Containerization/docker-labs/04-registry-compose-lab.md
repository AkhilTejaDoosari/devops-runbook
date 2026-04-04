[← devops-runbook](../../README.md) |
[Labs Index](./README.md) |
[Lab 01](./01-containers-portbinding-lab.md) |
[Lab 02](./02-networking-volumes-lab.md) |
[Lab 03](./03-build-layers-lab.md) |
[Lab 04](./04-registry-compose-lab.md)

---

# Lab 04 — Registry & Compose

## What this lab is about

You will push the webstore-api image you built in Lab 03 to Docker Hub, pull it back to confirm it works, then write a `docker-compose.yml` from scratch that brings up the full webstore system — api, database, and DB UI — with one command. You will break the compose file on purpose, fix it, and do a clean teardown. Every file is written from scratch.

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

4. Start the full system
```bash
docker compose up
```

Watch the startup logs — you will see all three containers initializing.

5. Open your browser and confirm both endpoints work:
```
http://localhost:8080   ← webstore-api
http://localhost:8081   ← mongo-express DB UI
```

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

---

## Section 5 — Break It on Purpose

### Break 1 — Wrong service name in connection string

1. Bring the system down
```bash
docker compose down
```

2. Edit `docker-compose.yml` — change the DB hostname in the mongo-express URL
```yaml
ME_CONFIG_MONGODB_URL: mongodb://admin:secret@wrong-db:27017
```

3. Bring it back up
```bash
docker compose up -d
```

4. Check mongo-express logs
```bash
docker compose logs mongo-express
```

**What to observe:** connection error — `wrong-db` does not exist as a hostname on the network

5. Fix it — restore the correct hostname `webstore-db`
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

**What to observe:** webstore-api and mongo-express may start before webstore-db is ready and log connection errors

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

2. Confirm everything is gone
```bash
docker ps -a
docker network ls
```

3. Remove images built by Compose
```bash
docker rmi webstore-api:1.0 YOUR_DOCKERHUB_USERNAME/webstore-api:1.0
docker rmi mongo mongo-express nginx:1.24
```

4. Final check
```bash
docker images
docker ps -a
docker network ls
docker volume ls
```

Everything should be clean.

---

## Checklist

Do not move on until every box is checked.

- [ ] I confirmed my local webstore-api image existed before starting
- [ ] I tagged it correctly as `YOUR_DOCKERHUB_USERNAME/webstore-api:1.0` and pushed it
- [ ] I verified the push on Docker Hub in the browser — the `1.0` tag was visible
- [ ] I deleted the local image and pulled it back from Docker Hub — it ran correctly
- [ ] I wrote `docker-compose.yml` from scratch — I did not copy-paste it
- [ ] I brought the full system up with `docker compose up -d` and hit both browser endpoints
- [ ] I inspected the auto-created network and confirmed all three containers were on it
- [ ] I broke the connection string with a wrong hostname and read the error in the logs
- [ ] I produced a port conflict error by running a container on 8080 before Compose started
- [ ] I removed `depends_on` and observed startup order problems in the logs
- [ ] I ran `docker compose down` and confirmed containers and network were removed cleanly
