[Home](../README.md) |
[Labs Index](./README.md) |
[Lab 01](./01-containers-portbinding-lab.md) |
[Lab 02](./02-networking-volumes-lab.md) |
[Lab 03](./03-build-layers-lab.md) |
[Lab 04](./04-registry-compose-lab.md)

---

# Lab 02 — Networking & Volumes

## What this lab is about

You will prove that containers cannot talk to each other without a network, create a Docker network, connect the webstore-db and webstore-api containers so they communicate by name, prove that container data dies without volumes, attach a named volume to a database, delete and recreate the container, and confirm the data survived. Every command is typed from scratch.

## Prerequisites

- [Docker Networking notes](../04-docker-networking/README.md)
- [Docker Volumes notes](../06-docker-volumes/README.md)
- Lab 01 completed

---

## Section 1 — Prove Containers Are Isolated by Default

**Goal:** show that two containers cannot reach each other without a network.

1. Run two containers with no network flags
```bash
docker run -d --name container-a nginx:1.24
docker run -d --name container-b nginx:1.24
```

2. Enter container-a
```bash
docker exec -it container-a /bin/sh
```

3. Try to reach container-b by name
```bash
ping container-b
```

**What to observe:** `ping: bad address 'container-b'` — no DNS, no connection

4. Exit
```bash
exit
```

5. Clean up
```bash
docker stop container-a container-b
docker rm container-a container-b
```

---

## Section 2 — Create a Network and Connect Containers

**Goal:** create the webstore network and prove DNS works inside it.

1. Create the network
```bash
docker network create webstore-network
```

2. Confirm it exists
```bash
docker network ls
```

3. Run webstore-db on the network
```bash
docker run -d \
  --name webstore-db \
  --network webstore-network \
  -e MONGO_INITDB_ROOT_USERNAME=admin \
  -e MONGO_INITDB_ROOT_PASSWORD=secret \
  mongo
```

4. Run mongo-express on the same network
```bash
docker run -d \
  --name mongo-express \
  --network webstore-network \
  -p 8081:8081 \
  -e ME_CONFIG_MONGODB_ADMINUSERNAME=admin \
  -e ME_CONFIG_MONGODB_ADMINPASSWORD=secret \
  -e ME_CONFIG_MONGODB_URL="mongodb://admin:secret@webstore-db:27017" \
  mongo-express
```

5. Wait about 10 seconds then open your browser:
```
http://localhost:8081
```

**What to observe:** mongo-express UI loads and connects to webstore-db — it reached the database using the hostname `webstore-db`

6. Enter mongo-express container and ping webstore-db by name
```bash
docker exec -it mongo-express /bin/sh
ping webstore-db
```

**What to observe:** ping resolves and gets a response — Docker DNS is working

7. Exit
```bash
exit
```

---

## Section 3 — Prove Data Dies Without a Volume

**Goal:** write data into a container, delete it, confirm data is gone.

1. Enter the running webstore-db container
```bash
docker exec -it webstore-db mongosh \
  -u admin -p secret --authenticationDatabase admin
```

2. Create a database and insert a document
```bash
use webstore
db.products.insertOne({ name: "keyboard", price: 79 })
db.products.find()
```

**What to observe:** document inserted and visible

3. Exit mongosh
```bash
exit
```

4. Stop and delete the container
```bash
docker stop webstore-db
docker rm webstore-db
```

5. Run a fresh webstore-db container (same image, no volume)
```bash
docker run -d \
  --name webstore-db \
  --network webstore-network \
  -e MONGO_INITDB_ROOT_USERNAME=admin \
  -e MONGO_INITDB_ROOT_PASSWORD=secret \
  mongo
```

6. Enter and check for your data
```bash
docker exec -it webstore-db mongosh \
  -u admin -p secret --authenticationDatabase admin
```

```bash
use webstore
db.products.find()
```

**What to observe:** empty result — data is gone. This is why volumes exist.

7. Exit
```bash
exit
```

---

## Section 4 — Named Volume (Data Survives)

**Goal:** attach a named volume to the database and prove data survives container deletion.

1. Stop and remove the no-volume container
```bash
docker stop webstore-db
docker rm webstore-db
```

2. Create a named volume
```bash
docker volume create webstore-db-data
```

3. Confirm it exists
```bash
docker volume ls
```

4. Run webstore-db with the volume attached
```bash
docker run -d \
  --name webstore-db \
  --network webstore-network \
  -p 27017:27017 \
  -v webstore-db-data:/data/db \
  -e MONGO_INITDB_ROOT_USERNAME=admin \
  -e MONGO_INITDB_ROOT_PASSWORD=secret \
  mongo
```

5. Insert data again
```bash
docker exec -it webstore-db mongosh \
  -u admin -p secret --authenticationDatabase admin
```

```bash
use webstore
db.products.insertOne({ name: "keyboard", price: 79 })
db.products.insertOne({ name: "mouse", price: 35 })
db.products.find()
exit
```

6. Stop and delete the container
```bash
docker stop webstore-db
docker rm webstore-db
```

7. Confirm the volume still exists
```bash
docker volume ls
```

**What to observe:** volume is still there even though the container is gone

8. Run a brand new container with the same volume
```bash
docker run -d \
  --name webstore-db \
  --network webstore-network \
  -p 27017:27017 \
  -v webstore-db-data:/data/db \
  -e MONGO_INITDB_ROOT_USERNAME=admin \
  -e MONGO_INITDB_ROOT_PASSWORD=secret \
  mongo
```

9. Check for your data
```bash
docker exec -it webstore-db mongosh \
  -u admin -p secret --authenticationDatabase admin
```

```bash
use webstore
db.products.find()
exit
```

**What to observe:** both documents are there — data survived full container deletion and recreation

---

## Section 5 — Bind Mount (Developer Workflow)

**Goal:** link a host folder into a container and prove changes go both ways.

1. Create a folder on your laptop
```bash
mkdir ~/webstore-config
echo "db_host=webstore-db" > ~/webstore-config/app.conf
```

2. Run a container with the folder bind-mounted
```bash
docker run -it --rm \
  -v ~/webstore-config:/config \
  ubuntu:22.04
```

3. From inside the container, read the file
```bash
cat /config/app.conf
```

4. Add a line from inside the container
```bash
echo "db_port=27017" >> /config/app.conf
cat /config/app.conf
exit
```

5. On your laptop, check the file
```bash
cat ~/webstore-config/app.conf
```

**What to observe:** the line you added inside the container appears on your laptop — same folder, two views

---

## Section 6 — Break It on Purpose

### Break 1 — Connect to a container not on the network

1. Run a container with no network
```bash
docker run -d --name isolated nginx:1.24
```

2. Try to reach webstore-db from it
```bash
docker exec -it isolated /bin/sh
ping webstore-db
exit
```

**What to observe:** fails — `isolated` is on the default bridge, not `webstore-network`

3. Clean up
```bash
docker stop isolated && docker rm isolated
```

### Break 2 — Wrong hostname in connection string

1. Run mongo-express with a typo in the DB hostname
```bash
docker stop mongo-express && docker rm mongo-express

docker run -d \
  --name mongo-express \
  --network webstore-network \
  -p 8081:8081 \
  -e ME_CONFIG_MONGODB_ADMINUSERNAME=admin \
  -e ME_CONFIG_MONGODB_ADMINPASSWORD=secret \
  -e ME_CONFIG_MONGODB_URL="mongodb://admin:secret@wrong-host:27017" \
  mongo-express
```

2. Check logs
```bash
docker logs mongo-express
```

**What to observe:** connection refused or timeout — the hostname `wrong-host` does not exist on the network

3. Fix it — recreate with the correct hostname
```bash
docker stop mongo-express && docker rm mongo-express

docker run -d \
  --name mongo-express \
  --network webstore-network \
  -p 8081:8081 \
  -e ME_CONFIG_MONGODB_ADMINUSERNAME=admin \
  -e ME_CONFIG_MONGODB_ADMINPASSWORD=secret \
  -e ME_CONFIG_MONGODB_URL="mongodb://admin:secret@webstore-db:27017" \
  mongo-express
```

---

## Section 7 — Safe Delete Flow

1. Stop all containers
```bash
docker stop webstore-db mongo-express
```

2. Remove all containers
```bash
docker rm webstore-db mongo-express
```

3. Remove the network
```bash
docker network rm webstore-network
```

4. Remove the volume (only if you don't need the data)
```bash
docker volume rm webstore-db-data
```

5. Remove images
```bash
docker rmi mongo mongo-express nginx:1.24 ubuntu:22.04
```

6. Confirm everything is clean
```bash
docker ps -a
docker network ls
docker volume ls
docker images
```

---

## Checklist

Do not move to Lab 03 until every box is checked.

- [ ] I ran two containers with no network and confirmed they cannot reach each other by name
- [ ] I created `webstore-network` and confirmed DNS resolution works between containers on it
- [ ] I opened mongo-express in the browser and it connected to webstore-db using the hostname — not an IP
- [ ] I inserted data into webstore-db with no volume, deleted the container, confirmed the data was gone
- [ ] I created a named volume, attached it to webstore-db, inserted data, deleted the container, recreated it with the same volume, and confirmed the data survived
- [ ] I used a bind mount, wrote a file from inside the container, and saw it appear on my laptop
- [ ] I broke the connection string with a wrong hostname and read the error in the logs
- [ ] I deleted everything in the correct order: stop → rm containers → rm network → rm volume → rmi images
