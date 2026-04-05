[Home](../README.md) |
[Labs Index](./README.md) |
[Lab 01](./01-containers-portbinding-lab.md) |
[Lab 02](./02-networking-volumes-lab.md) |
[Lab 03](./03-build-layers-lab.md) |
[Lab 04](./04-registry-compose-lab.md)

---

# Lab 02 — Networking & Volumes

## The Situation

The webstore-frontend is running as a container. But the real webstore is three services: a frontend, an API, and a database. Those three services need to talk to each other. The database needs to store data that survives container restarts.

Right now containers are isolated. webstore-api cannot reach webstore-db because nothing connects them. And if webstore-db is deleted, every row in the database is gone with it. This lab fixes both problems.

By the end, webstore-api talks to webstore-db using the container name as a hostname, Docker DNS resolves it automatically, port binding is proven to be iptables NAT, and the database data survives complete container deletion. This is the foundation Lab 03 builds on — you cannot build the API image until the network and storage are wired correctly.

## What this lab covers

You will prove that containers cannot talk to each other without a network, create a Docker network, connect webstore-db and webstore-api so they communicate by name, verify Docker DNS at the resolver level, prove that port binding is iptables NAT, prove that container data dies without volumes, attach a named volume to postgres, delete and recreate the container, and confirm the data survived. Every command is typed from scratch.

## Prerequisites

- [Docker Networking notes](../05-docker-networking/README.md)
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

## Section 2 — Create a Network and Verify Docker DNS

**Goal:** create the webstore network, prove DNS works inside it, and verify it at the resolver level.

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
  -e POSTGRES_DB=webstore \
  -e POSTGRES_USER=admin \
  -e POSTGRES_PASSWORD=secret \
  postgres:15
```

4. Run adminer on the same network
```bash
docker run -d \
  --name adminer \
  --network webstore-network \
  -p 8081:8080 \
  adminer
```

5. Wait about 10 seconds then open your browser:
```
http://localhost:8081
```

Log in with:
- System: PostgreSQL
- Server: `webstore-db`
- Username: `admin`
- Password: `secret`
- Database: `webstore`

**What to observe:** adminer UI loads and connects to webstore-db — it reached the database using the hostname `webstore-db`, not an IP address

6. Enter the adminer container and ping webstore-db by name
```bash
docker exec -it adminer /bin/sh
ping webstore-db
```

**What to observe:** ping resolves and gets a response — Docker DNS is working

7. Check what DNS server the container is using
```bash
cat /etc/resolv.conf
```

**What to observe:**
```
nameserver 127.0.0.11
options ndots:0
```

`127.0.0.11` is Docker's embedded DNS server. This is automatically configured for every container on a custom network.

8. Run a proper DNS lookup to see the full resolution
```bash
nslookup webstore-db
```

**What to observe:**
```
Server:         127.0.0.11
Address:        127.0.0.11:53

Non-authoritative answer:
Name:   webstore-db
Address: 172.18.0.X
```

The container name `webstore-db` resolved to its private IP. Docker DNS answered the query at `127.0.0.11:53`.

9. Exit
```bash
exit
```

10. Check the network from the outside — see all containers and their IPs
```bash
docker network inspect webstore-network
```

**What to observe:** a `"Containers"` section showing every container on the network, their names, and their assigned IPs. The IP you saw in `nslookup` matches here.

---

## Section 2.5 — Port Binding Is NAT — Prove It

**Goal:** show that `-p host:container` creates a real iptables DNAT rule — not magic.

1. Run nginx with port binding
```bash
docker run -d --name nat-proof -p 8080:80 nginx:1.24
```

2. Confirm port 8080 is now listening on the host
```bash
sudo ss -tlnp | grep 8080
```

**What to observe:** port 8080 is now listening — Docker created this mapping.

3. Check what IP the container was assigned
```bash
docker inspect nat-proof | grep '"IPAddress"'
```

Record the container IP (something like `172.17.0.2`).

4. Access it via the port binding
```bash
curl http://localhost:8080
```

**What to observe:** nginx responds — request hit host port 8080, was translated to container port 80.

5. Look at the actual iptables rule Docker created
```bash
sudo iptables -t nat -L DOCKER -n
```

**What to observe:**
```
Chain DOCKER
target  prot  opt  source      destination
DNAT    tcp   --   0.0.0.0/0   0.0.0.0/0   tcp dpt:8080 to:172.17.0.X:80
```

This DNAT rule is what makes port binding work. Every `-p` flag you use creates an entry exactly like this.

6. Access the container directly by its IP (bypassing NAT entirely)
```bash
CONTAINER_IP=$(docker inspect nat-proof | grep '"IPAddress"' | tail -1 | awk -F'"' '{print $4}')
curl http://$CONTAINER_IP:80
```

**What to observe:** direct container access works — no NAT needed when already on the same network.

7. Clean up
```bash
docker stop nat-proof && docker rm nat-proof
```

> **The Rule:** `-p host:container` = `iptables DNAT rule`. Docker translates host traffic to the container's private IP. This is identical to how your home router does port forwarding.

---

## Section 3 — Prove Data Dies Without a Volume

**Goal:** write data into a postgres container, delete it, confirm data is gone.

1. Enter the running webstore-db container
```bash
docker exec -it webstore-db psql -U admin -d webstore
```

2. Create a table and insert a row
```sql
CREATE TABLE products (id SERIAL PRIMARY KEY, name TEXT, price INT);
INSERT INTO products (name, price) VALUES ('keyboard', 79);
SELECT * FROM products;
```

**What to observe:** row inserted and visible

3. Exit psql
```sql
\q
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
  -e POSTGRES_DB=webstore \
  -e POSTGRES_USER=admin \
  -e POSTGRES_PASSWORD=secret \
  postgres:15
```

6. Wait a few seconds then check for your data
```bash
docker exec -it webstore-db psql -U admin -d webstore -c "SELECT * FROM products;"
```

**What to observe:** error — table does not exist. Data is gone. This is why volumes exist.

---

## Section 4 — Named Volume (Data Survives)

**Goal:** attach a named volume to postgres and prove data survives container deletion.

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
  -v webstore-db-data:/var/lib/postgresql/data \
  -e POSTGRES_DB=webstore \
  -e POSTGRES_USER=admin \
  -e POSTGRES_PASSWORD=secret \
  postgres:15
```

5. Wait a few seconds then create data
```bash
docker exec -it webstore-db psql -U admin -d webstore
```

```sql
CREATE TABLE products (id SERIAL PRIMARY KEY, name TEXT, price INT);
INSERT INTO products (name, price) VALUES ('keyboard', 79);
INSERT INTO products (name, price) VALUES ('mouse', 49);
SELECT * FROM products;
\q
```

6. Stop and delete the container — deliberately
```bash
docker stop webstore-db
docker rm webstore-db
```

7. Confirm the volume still exists
```bash
docker volume ls
```

**What to observe:** `webstore-db-data` is still there — volumes are independent of containers

8. Run a new container with the same volume
```bash
docker run -d \
  --name webstore-db \
  --network webstore-network \
  -v webstore-db-data:/var/lib/postgresql/data \
  -e POSTGRES_DB=webstore \
  -e POSTGRES_USER=admin \
  -e POSTGRES_PASSWORD=secret \
  postgres:15
```

9. Check for your data
```bash
docker exec -it webstore-db psql -U admin -d webstore -c "SELECT * FROM products;"
```

**What to observe:** both rows are there — data survived full container deletion and recreation

---

## Section 5 — Bind Mount (Developer Workflow)

**Goal:** link a host folder into a container and prove changes go both ways.

1. Create a folder on your laptop
```bash
mkdir ~/webstore-config
echo "db_host=webstore-db" > ~/webstore-config/app.conf
echo "db_port=5432" >> ~/webstore-config/app.conf
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
echo "api_port=8080" >> /config/app.conf
cat /config/app.conf
exit
```

5. On your laptop, check the file
```bash
cat ~/webstore-config/app.conf
```

**What to observe:** the line you added inside the container appears on your laptop — same folder, two views

---

## Section 5.5 — Full Webstore Stack Trace

**Goal:** bring up the full webstore stack and trace every networking layer — DNS, routing, ports, NAT — exactly as covered in the networking notes complete journey.

This section fulfills the redirect from [Networking Lab 05](../../03.%20Networking%20–%20Foundations/networking-labs/05-complete-journey-lab.md).

1. Confirm webstore-db and adminer are still running
```bash
docker ps
```

If they are not running, bring them back:
```bash
docker run -d \
  --name webstore-db \
  --network webstore-network \
  -v webstore-db-data:/var/lib/postgresql/data \
  -e POSTGRES_DB=webstore \
  -e POSTGRES_USER=admin \
  -e POSTGRES_PASSWORD=secret \
  postgres:15

docker run -d \
  --name adminer \
  --network webstore-network \
  -p 8081:8080 \
  adminer
```

2. Run a webstore-api placeholder (nginx standing in for the real API)
```bash
docker run -d \
  --name webstore-api \
  --network webstore-network \
  -p 8080:80 \
  nginx:1.24
```

Now trace every layer:

**Layer 7 — DNS: can webstore-api resolve webstore-db by name?**
```bash
docker exec webstore-api nslookup webstore-db
```

Record: `webstore-db resolves to ___.___.___.___ `

**Layer 7 — DNS: what DNS server is the container using?**
```bash
docker exec webstore-api cat /etc/resolv.conf
```

Record: `nameserver ___.___.___.___ ` (should be `127.0.0.11`)

**Layer 3 — Routing: what is the container's default gateway?**
```bash
docker exec webstore-api ip route
```

**What to observe:** `default via 172.18.0.1` — the Docker bridge is the gateway for all traffic leaving the container.

**Layer 3-4 — Can the container reach the database port?**
```bash
docker exec webstore-api nc -zv webstore-db 5432
```

Record: port 5432 reachable? ___

**NAT — Port binding proof: see the iptables rules for all containers**
```bash
sudo iptables -t nat -L DOCKER -n
```

**What to observe:** DNAT rules — one for port 8080 (api), one for 8081 (adminer). Each maps a host port to a container IP. webstore-db has no entry — it is internal only.

**Network isolation — confirm webstore-db has no public port exposure**
```bash
docker inspect webstore-db | grep -A 5 '"Ports"'
```

**What to observe:** empty or no host port mapping — webstore-db is unreachable from outside Docker.

**The complete data flow:**
```
Browser → localhost:8080
    │
    ▼ iptables DNAT
host port 8080 → webstore-api container (172.18.0.X:80)
    │
    ▼ Docker DNS resolves "webstore-db"
webstore-api → webstore-db:5432 (172.18.0.Y:5432)
    │
    ▼ direct container-to-container (no NAT needed)
webstore-db receives connection
```

**Verify the full flow end to end:**
```bash
# From outside — hits port binding (NAT)
curl -s http://localhost:8080 | head -5

# From inside api — hits DNS then direct network
docker exec webstore-api nc -zv webstore-db 5432

# From inside api — confirm db is unreachable on localhost
docker exec webstore-api nc -zv localhost 5432
```

**What to observe on the last command:** connection refused — `localhost` inside webstore-api is the container itself, not webstore-db. This is the localhost rule in action.

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

Check what happens when the container name is wrong:
```bash
docker exec webstore-api nc -zv wrong-host 5432
```

**What to observe:** DNS resolution fails — `wrong-host` does not exist on the network

### Break 3 — Use localhost instead of container name

```bash
docker exec webstore-api nc -zv localhost 5432
```

**What to observe:** `Connection refused` — `localhost` inside webstore-api is the container itself. Port 5432 is not running inside webstore-api. This is why you always use container names, never localhost, in Docker connection strings.

---

## Section 7 — Safe Delete Flow

1. Stop all containers
```bash
docker stop webstore-api webstore-db adminer
```

2. Remove all containers
```bash
docker rm webstore-api webstore-db adminer
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
docker rmi postgres:15 adminer nginx:1.24 ubuntu:22.04
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
- [ ] I opened adminer in the browser and it connected to webstore-db using the hostname — not an IP
- [ ] I ran `cat /etc/resolv.conf` inside a container and confirmed the DNS server is `127.0.0.11`
- [ ] I ran `nslookup webstore-db` from inside a container and got back the container's IP
- [ ] I ran `docker network inspect webstore-network` and matched the IP from nslookup to the IP in the inspect output
- [ ] I ran `sudo iptables -t nat -L DOCKER -n` and saw the DNAT rule Docker created for my port binding
- [ ] I accessed the container directly by its IP (bypassing NAT) and confirmed it worked
- [ ] I inserted data into webstore-db with no volume, deleted the container, confirmed the data was gone
- [ ] I created a named volume, attached it to webstore-db, inserted data, deleted the container, recreated it with the same volume, and confirmed the data survived
- [ ] I used a bind mount, wrote a file from inside the container, and saw it appear on my laptop
- [ ] I traced the full webstore stack — DNS resolution, default gateway, port reachability, iptables rules, and data flow
- [ ] I confirmed that `localhost` inside a container does NOT reach another container — connection refused
- [ ] I deleted everything in the correct order: stop → rm containers → rm network → rm volume → rmi images
