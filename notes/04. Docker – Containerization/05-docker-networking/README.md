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

# Docker Networking

**A) Names (locked)**
* App: webstore-api
* Database: webstore-db
* DB UI: mongo-express
* Network: webstore-network

**B) Roles + Direction (this stops confusion forever)**
* webstore-api = client (initiates DB connection)
* webstore-db = server (waits for connections)
* mongo-express = client tool (initiates DB connection)

Rule:
* Clients connect to servers
* Servers don't connect outward

**C) The rule of localhost (non-negotiable)**
localhost always means "this machine I am inside"

| Where you are          | localhost means        |
|------------------------|------------------------|
| Browser (laptop)       | Your laptop            |
| webstore-api container | webstore-api container |
| webstore-db container  | webstore-db container  |

So inside Docker:
* containers never share localhost
* containers talk using container names over a Docker network

**Developing with Docker (Manual Commands, line-by-line)**
This is the "I understand Docker" method.

## **1) Create the Docker network**
Command
```bash
docker network create webstore-network
```
Meaning
* webstore-network = private LAN
* provides DNS so container names resolve (name → IP)

To delete network
```bash
docker network rm webstore-network
```

## **2) Run webstore-db container**
```bash
docker run -d \
  -p 27017:27017 \
  --name webstore-db \
  --network webstore-network \
  -e MONGO_INITDB_ROOT_USERNAME=admin \
  -e MONGO_INITDB_ROOT_PASSWORD=secret \
  mongo
```

**Line-by-line meaning**
* `docker run` = start a container
* `-d` = run in background
* `-p 27017:27017`
  * left = laptop port
  * right = MongoDB port in container
* `--name webstore-db`
  * container name
  * also becomes hostname inside the network (`webstore-db`)
* `--network webstore-network` = attach to network
* `-e ...` = set environment variables inside container (creates admin user/password)
* `mongo` = image name (MongoDB software)

## **3) Run Mongo Express container**
```bash
docker run -d \
  -p 8081:8081 \
  --name mongo-express \
  --network webstore-network \
  -e ME_CONFIG_MONGODB_ADMINUSERNAME=admin \
  -e ME_CONFIG_MONGODB_ADMINPASSWORD=secret \
  -e ME_CONFIG_MONGODB_URL="mongodb://admin:secret@webstore-db:27017" \
  mongo-express
```

**Line-by-line meaning**
* `-p 8081:8081` = open UI on laptop at localhost:8081
* `--name mongo-express` = container name / hostname
* `--network webstore-network` = same LAN as webstore-db
* `ME_CONFIG...` = credentials + connection string
* `mongodb://admin:secret@webstore-db:27017`
  * `webstore-db` here is the database container name
* `mongo-express` = image name (software)

Check
Open: http://localhost:8081

## **4) Build webstore-api image (from your code)**
```bash
docker build -t webstore-api .
```
Meaning
* `docker build` = create image from Dockerfile
* `-t webstore-api` = name the image webstore-api
* `.` = current folder contains Dockerfile

## **5) Run webstore-api container**
```bash
docker run -d \
  -p 8080:8080 \
  --name webstore-api \
  --network webstore-network \
  -e MONGO_URL="mongodb://admin:secret@webstore-db:27017" \
  webstore-api
```

**Line-by-line meaning**
* `-p 8080:8080` = laptop localhost:8080 → api container port 8080
* `--name webstore-api` = container name / hostname
* `--network webstore-network` = same LAN
* `-e MONGO_URL=...` = DB connection string given to app
* `webstore-api` = image name you built

## **6) Final data flows**
Real app path
```
Browser → localhost:8080 → webstore-api → webstore-db:27017 → webstore-db
```
Debug path
```
Browser → localhost:8081 → mongo-express → webstore-db:27017 → webstore-db
```

## **7) Delete the Docker network**
Command
```bash
docker network rm webstore-network
```
Meaning
* Deletes the Docker network webstore-network
* Works only if no containers are currently using it

If it fails (network is in use):
```bash
docker ps
docker stop <container>
docker rm <container>
docker network rm webstore-network
```

## **Mental Picture**
```
┌──────────────────────────── YOUR LAPTOP (HOST OS) ─────────────────────────────┐
│                                                                                │
│  Browser (External World)                                                      │
│    │                                                                           │
│    │  (Request: http://localhost:8080)                                         │
│    ▼                                                                           │
│  Host NIC: eth0 / en0 <───────────────────────┐                                │
│    │                                          │                                │
│    │  (iptables / NAT Engine)                 │                                │
│    │  RULE: If traffic hits 8080 -> Forward   │  PORT MAPPING (-p)             │
│    └──────────────┬───────────────────────────┘  Bridges Host to Bridge        │
│                   │                                                            │
│                   ▼                                                            │
│      ┌────────────── docker0 (Linux BRIDGE / V-Switch) ────────┐               │
│      │   Private Subnet (IP: 172.18.0.1)                       │               │
│      │                                                         │               │
│      │   veth0 (Cable)    veth1 (Cable)    veth2 (Cable)       │               │
│      │     │                 │                    │            │               │
│      │  ┌──▼──────┐      ┌───▼────────┐    ┌─────▼──────┐      │               │
│      │  │  ns     │      │     ns     │    │     ns     │      │               │
│      │  │webstore │─DNS─▶│ webstore   │◀───│  mongo     │      │               │
│      │  │  -api   │      │   -db      │    │  -express  │      │               │
│      │  │  :8080  │      │  :27017    │    │   :8081    │      │               │
│      │  └─────────┘      └────────────┘    └────────────┘      │               │
│      │  (App Client)     (DB Server)       (UI Client)         │               │
│      └─────────────────────────────────────────────────────────┘               │
└────────────────────────────────────────────────────────────────────────────────┘
```

→ Ready to practice? [Go to Lab 02](../docker-labs/02-networking-volumes-lab.md)
