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

# Docker Networking

**A) Names (locked)**
* App: chillspot
* Database: mongodb
* DB UI: mongo-express
* Network: chillspot-network

**B) Roles + Direction (this stops confusion forever)**  
* chillspot = client (initiates DB connection)
* mongodb = server (waits for connections)
* mongo-express = client tool (initiates DB connection)
Rule:
* Clients connect to servers
* Servers don’t connect outward

**C) The rule of localhost (non-negotiable)**  
localhost always means “this machine I am inside”  

|Where you are	     |localhost means     |
|--------------------|--------------------|
|Browser (laptop)	 |Your laptop  
|chillspot container |Chillspot container  
|mongodb container	 |MongoDB container  
So inside Docker:
* containers never share localhost
* containers talk using container names over a Docker network

**Developing with Docker (Manual Commands, line-by-line)**   
This is the “I understand Docker” method.  

## **1) Create the Docker network**  
Command
```bash
docker network create chillspot-network
```
Meaning
* chillspot-network = private LAN
* provides DNS so container names resolve (name → IP)

To delete network
Command
```bash
docker network rm chillspot-network
 ```

## **2) Run MongoDB container**  
```bash 
docker run -d \  
  -p 27017:27017 \  
  --name mongodb \  
  --network chillspot-network \  
  -e MONGO_INITDB_ROOT_USERNAME=admin \  
  -e MONGO_INITDB_ROOT_PASSWORD=secret \  
  mongo  
 ```

**Line-by-line meaning**  
* docker run = start a container
* -d = run in background
* -p 27017:27017
    * left = laptop port
    * right = MongoDB port in container
* --name mongodb
    * container name
    * also becomes hostname inside network (mongodb)
* --network chillspot-network = attach to network
* -e ... = set environment variables inside container
    * creates admin user/password
* mongo = image name (MongoDB software)

## **3) Run Mongo Express container**  
 ```bash 
docker run -d \
  -p 8081:8081 \
  --name mongo-express \
  --network chillspot-network \
  -e ME_CONFIG_MONGODB_ADMINUSERNAME=admin \
  -e ME_CONFIG_MONGODB_ADMINPASSWORD=secret \
  -e ME_CONFIG_MONGODB_URL="mongodb://admin:secret@mongodb:27017" \
  mongo-express  
 ```

**Line-by-line meaning**  
* -p 8081:8081 = open UI on laptop at localhost:8081
* --name mongo-express = container name / hostname
* --network chillspot-network = same LAN as MongoDB
* ME_CONFIG... = credentials + connection string
* mongodb://admin:secret@mongodb:27017
    * mongodb here is the MongoDB container name
* mongo-express = image name (software)  

Check  
Open: http://localhost:8081  

## **4) Build Chillspot app image (from your code)**  
 ```bash
docker build -t chillspot .
Meaning
* docker build = create image from Dockerfile
* -t chillspot = name the image chillspot
* . = current folder contains Dockerfile
 ```

## **5) Run Chillspot app container**  
 ```bash
docker run -d \
  -p 5050:5050 \
  --name chillspot \
  --network chillspot-network \
  -e MONGO_URL="mongodb://admin:secret@mongodb:27017" \
  chillspot
 ```

**Line-by-line meaning**  
* -p 5050:5050 = laptop localhost:5050 → app container port 5050
* --name chillspot = container name / hostname
* --network chillspot-network = same LAN
* -e MONGO_URL=... = DB connection string given to app
* chillspot = image name you built

## **6) Final data flows**  
Real app path  
Browser → localhost:5050 → chillspot → mongodb:27017 → mongodb  
Debug path  
Browser → localhost:8081 → mongo-express → mongodb:27017 → mongodb  

**1.1) Delete the Docker network**  
Command
 ```bash
docker network rm chillspot-network
 ```
Meaning
* Deletes the Docker network chillspot-network
* Works only if no containers are currently using it
If it fails (network is in use)
docker ps
docker stop <container>
docker rm <container>
docker network rm chillspot-network

## **Mental Picture**    
```
┌──────────────────────────── YOUR LAPTOP (HOST OS) ─────────────────────────────┐
│                                                                                │
│  Browser (External World)                                                      │
│    │                                                                           │
│    │  (Request: http://localhost:5050)                                         │
│    ▼                                                                           │
│  Host NIC: eth0 / en0 <───────────────────────┐                                │
│    │                                          │                                │
│    │  (iptables / NAT Engine)                 │                                │
│    │  RULE: If traffic hits 5050 -> Forward   │  PORT MAPPING (-p)             │
│    └──────────────┬───────────────────────────┘  Bridges Host to Bridge        │
│                   │                                                            │
│                   ▼                                                            │
│      ┌────────────── docker0 (Linux BRIDGE / V-Switch) ────────┐               │
│      │   Private Subnet (IP: 172.18.0.1)                       │               │
│      │                                                         │               │
│      │   veth0 (Cable)    veth1 (Cable)    veth2 (Cable)       │               │
│      │     │                 │                    │            │               │
│      │  ┌──▼──┐          ┌───▼────┐          ┌────▼────┐       │               │
│      │  │ ns  │          │   ns   │          │    ns   │       │               │
│      │  │chill│ --DNS--> │mongo.db│ <──DNS-- │  xpress │       │               │
│      │  │spot │          │:27017  │          │         │       │               │
│      │  │:5050│          │        |          │  :8081  │       │               │
│      │  └─────┘          └────────┘          └─────────┘       │               │
│      │   (App)           (DB Server)         (UI Client)       │               │
│      └─────────────────────────────────────────────────────────┘               │
└────────────────────────────────────────────────────────────────────────────────┘
```