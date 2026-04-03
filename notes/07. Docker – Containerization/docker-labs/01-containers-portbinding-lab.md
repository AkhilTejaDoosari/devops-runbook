[Home](../README.md) |
[Labs Index](./README.md) |
[Lab 01](./01-containers-portbinding-lab.md) |
[Lab 02](./02-networking-volumes-lab.md) |
[Lab 03](./03-build-layers-lab.md) |
[Lab 04](./04-registry-compose-lab.md)

---

# Lab 01 — Containers & Port Binding

## What this lab is about

You will run containers interactively and as background services, pass configuration at startup, observe and debug running containers, expose a service to your browser using port binding, and clean up safely. Every command is typed from scratch. Nothing is copy-pasted.

## Prerequisites

- [Docker Containers notes](../03-docker-containers/README.md)
- [Docker Port Binding notes](../05-docker-port-binding/README.md)
- Docker Desktop running on your machine

---

## Section 1 — Pull and Explore Images

**Goal:** download images and inspect what you have locally.

1. Check your Docker version
```bash
docker -v
```

2. Pull the ubuntu image (no tag = latest)
```bash
docker pull ubuntu
```

3. Pull a specific version
```bash
docker pull ubuntu:22.04
```

4. Pull nginx
```bash
docker pull nginx:1.24
```

5. List all downloaded images
```bash
docker images
```

**What to observe:**
- Each image has a REPOSITORY, TAG, IMAGE ID, and SIZE
- `ubuntu` and `ubuntu:22.04` may share layers (size difference is small)
- Nothing is running yet

---

## Section 2 — Interactive Containers

**Goal:** enter a container like a terminal, explore it, and understand its lifecycle.

1. Run ubuntu interactively and name it
```bash
docker run --name ubuntu-test -it ubuntu:22.04
```

You are now inside the container. Your prompt changes.

2. Explore the environment from inside
```bash
whoami
hostname
ls /
cat /etc/os-release
```

3. Create a file inside the container
```bash
echo "I was here" > /tmp/test.txt
cat /tmp/test.txt
```

4. Exit the container
```bash
exit
```

5. Check container status
```bash
docker ps -a
```

**What to observe:** the container is stopped but still exists (STATUS = Exited)

6. Start the same container and re-enter it
```bash
docker start -i ubuntu-test
```

7. Check if your file survived the stop/start
```bash
cat /tmp/test.txt
```

**What to observe:** file is still there — stopping is not deleting

8. Exit again
```bash
exit
```

---

## Section 3 — Service Mode + Port Binding

**Goal:** run nginx as a background service and reach it from your browser.

1. Run nginx in the background with port binding
```bash
docker run -d --name webstore-frontend -p 8080:80 nginx:1.24
```

2. Confirm it is running
```bash
docker ps
```

**What to observe in the PORTS column:**
```
0.0.0.0:8080->80/tcp
```
This means host port 8080 forwards to container port 80.

3. Open your browser and go to:
```
http://localhost:8080
```

**What to observe:** nginx welcome page loads — your container is serving traffic

4. View live logs
```bash
docker logs -f webstore-frontend
```

Refresh the browser page and watch a new log line appear.

Press `Ctrl+C` to stop following logs.

---

## Section 4 — Configuration at Startup

**Goal:** pass required environment variables to a container that needs them.

1. Try running MySQL without any configuration
```bash
docker run -d --name mysql-test mysql:8.0
```

2. Check what happened
```bash
docker ps -a
docker logs mysql-test
```

**What to observe:** container exited immediately — MySQL requires a root password

3. Run MySQL with the required environment variable
```bash
docker run -d \
  --name mysql-configured \
  -e MYSQL_ROOT_PASSWORD=secret \
  mysql:8.0
```

4. Confirm it is running
```bash
docker ps
```

5. Check logs to confirm clean startup
```bash
docker logs mysql-configured
```

**What to observe:** MySQL started successfully this time

---

## Section 5 — Observability and Debugging

**Goal:** inspect and debug containers without rebuilding anything.

1. Inspect the full container configuration
```bash
docker inspect webstore-frontend
```

Look for:
- `"Image"` — which image was used
- `"Ports"` — port mapping
- `"Env"` — environment variables

2. Enter the running nginx container
```bash
docker exec -it webstore-frontend /bin/sh
```

3. From inside, explore the nginx config
```bash
cat /etc/nginx/nginx.conf
ls /usr/share/nginx/html
exit
```

4. Restart the container
```bash
docker restart webstore-frontend
```

5. Confirm it came back up
```bash
docker ps
```

---

## Section 6 — Break It on Purpose

**Goal:** produce real failure states and learn to read them.

### Break 1 — Wrong image name

```bash
docker run -d --name broken-1 nginxxx:1.24
```

Check what happened:
```bash
docker ps -a
docker logs broken-1
```

**What to observe:** `Unable to find image` — Docker couldn't pull a non-existent image

### Break 2 — Missing required environment variable

You already did this in Section 4 with MySQL. Go back and re-read those logs now with fresh eyes.

**What to observe:** the error message tells you exactly what is missing

### Break 3 — Port conflict

Start a second nginx on the same host port:
```bash
docker run -d --name broken-2 -p 8080:80 nginx:1.24
```

**What to observe:** `port is already allocated` — two containers cannot share the same host port

Fix it by using a different host port:
```bash
docker run -d --name webstore-frontend-2 -p 8090:80 nginx:1.24
```

Confirm both are running on different ports:
```bash
docker ps
```

Visit `http://localhost:8090` — second nginx is also accessible.

---

## Section 7 — Safe Delete Flow

**Goal:** clean everything up without errors.

1. List everything that exists
```bash
docker ps -a
```

2. Stop all running containers
```bash
docker stop webstore-frontend webstore-frontend-2 mysql-configured
```

3. Remove all containers (including the failed ones)
```bash
docker rm ubuntu-test webstore-frontend webstore-frontend-2 mysql-configured mysql-test broken-1 broken-2
```

4. Confirm no containers remain
```bash
docker ps -a
```

5. Remove images
```bash
docker rmi nginx:1.24 ubuntu:22.04 ubuntu mysql:8.0
```

6. Confirm images are gone
```bash
docker images
```

**If any delete fails:** the error message tells you what is still blocking it. Stop and remove that container first, then retry.

---

## Checklist

Do not move to Lab 02 until every box is checked.

- [ ] I pulled images and read the `docker images` output without guessing what the columns mean
- [ ] I entered an ubuntu container interactively, created a file, exited, restarted, and confirmed the file survived the stop/start cycle
- [ ] I ran nginx with `-d` and `-p` and saw the welcome page in my browser
- [ ] I watched live logs with `docker logs -f` and saw a new line appear when I refreshed the browser
- [ ] I ran MySQL without `-e` and read the error — I know why it failed
- [ ] I ran MySQL with `-e MYSQL_ROOT_PASSWORD` and confirmed clean startup in logs
- [ ] I used `docker inspect` and found the port mapping and image name in the output
- [ ] I used `docker exec -it` to enter a running container and looked around
- [ ] I produced a port conflict error on purpose and understood what it meant
- [ ] I deleted everything in the correct order: stop → rm → rmi — with zero errors
