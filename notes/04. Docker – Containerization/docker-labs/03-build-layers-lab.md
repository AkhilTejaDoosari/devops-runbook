[← devops-runbook](../../README.md) |
[Labs Index](./README.md) |
[Lab 01](./01-containers-portbinding-lab.md) |
[Lab 02](./02-networking-volumes-lab.md) |
[Lab 03](./03-build-layers-lab.md) |
[Lab 04](./04-registry-compose-lab.md)

---

# Lab 03 — Layers, Build & Dockerfile

## What this lab is about

You will inspect real image layers, watch Docker caching work and break, write a Dockerfile for webstore-api from scratch, create a proper `.dockerignore`, build and run the image, then break the build on purpose in ways that teach you how the cache and ordering rules actually work. Every file is written from scratch.

## Prerequisites

- [Docker Layers notes](../07-docker-layers/README.md)
- [Docker Build notes](../08-docker-build-dockerfile/README.md)
- Lab 02 completed

---

## Section 1 — Inspect Real Layers

**Goal:** see layers with your own eyes before writing any Dockerfile.

1. Pull a small image
```bash
docker pull alpine:3.18
```

2. View its layers
```bash
docker history alpine:3.18
```

**What to observe:** very few layers, small sizes

3. Pull a Node image
```bash
docker pull node:20-alpine
```

4. View its layers
```bash
docker history node:20-alpine
```

**What to observe:** more layers — each one added something on top of alpine

5. Check how much disk both images use
```bash
docker system df
```

**What to observe:** total size is less than alpine + node added together — shared layers are not duplicated

---

## Section 2 — Watch Caching Work

**Goal:** build an image twice and see layers get reused.

1. Create a working folder
```bash
mkdir ~/cache-test && cd ~/cache-test
```

2. Write this Dockerfile from scratch
```dockerfile
FROM alpine:3.18
RUN apk add --no-cache curl
RUN echo "layer three"
RUN echo "layer four"
CMD ["sh"]
```

3. Build it the first time
```bash
docker build -t cache-test:v1 .
```

**What to observe:** each step says how long it took

4. Build it again immediately
```bash
docker build -t cache-test:v1 .
```

**What to observe:** every step says `CACHED` — instant build, nothing re-ran

---

## Section 3 — Break the Cache on Purpose

**Goal:** change one layer and watch everything after it rebuild.

1. Edit your Dockerfile — change only layer three
```dockerfile
FROM alpine:3.18
RUN apk add --no-cache curl
RUN echo "layer three MODIFIED"
RUN echo "layer four"
CMD ["sh"]
```

2. Build again
```bash
docker build -t cache-test:v2 .
```

**What to observe:**
- Layer 1 (FROM) → CACHED
- Layer 2 (curl) → CACHED
- Layer 3 (echo modified) → rebuilt
- Layer 4 (echo layer four) → rebuilt even though you didn't change it

**Why:** changing layer 3 invalidates the filesystem state that layer 4 depends on. Docker cannot safely reuse it.

---

## Section 4 — Bad vs Good Dockerfile Ordering

**Goal:** prove that instruction order directly affects build speed.

1. Create a new folder
```bash
mkdir ~/order-test && cd ~/order-test
```

2. Create a fake dependency file
```bash
echo '{ "name": "webstore-api", "version": "1.0.0" }' > package.json
```

3. Create some fake source files
```bash
echo "console.log('server running')" > server.js
echo "module.exports = {}" > config.js
```

4. Write the **bad** Dockerfile (copy everything first)
```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY . .
RUN npm install
CMD ["node", "server.js"]
```

5. Build it
```bash
docker build -t order-bad:v1 .
```

6. Change one source file (simulating a code change)
```bash
echo "console.log('updated')" > server.js
```

7. Build again and watch what reruns
```bash
docker build -t order-bad:v2 .
```

**What to observe:** `COPY . .` layer changed → `npm install` runs again even though `package.json` didn't change

8. Now write the **good** Dockerfile in the same folder
```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package.json .
RUN npm install
COPY . .
CMD ["node", "server.js"]
```

9. Build it
```bash
docker build -t order-good:v1 .
```

10. Change a source file again
```bash
echo "console.log('updated again')" > server.js
```

11. Build again
```bash
docker build -t order-good:v2 .
```

**What to observe:**
- `COPY package.json` → CACHED (didn't change)
- `RUN npm install` → CACHED (package.json didn't change)
- `COPY . .` → rebuilt (source code changed)
- Only the last copy reruns — npm install is skipped

**This is the difference between a 45-second build and a 2-second build.**

---

## Section 5 — Write the webstore-api Dockerfile

**Goal:** write a real Dockerfile for the webstore-api from scratch.

1. Create the project folder
```bash
mkdir ~/webstore-api && cd ~/webstore-api
```

2. Create a minimal Node app
```bash
cat > server.js << 'EOF'
const http = require('http');
const port = process.env.PORT || 8080;
const server = http.createServer((req, res) => {
  res.writeHead(200, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify({ service: 'webstore-api', status: 'running' }));
});
server.listen(port, () => console.log(`webstore-api listening on port ${port}`));
EOF
```

3. Create the package.json
```bash
cat > package.json << 'EOF'
{
  "name": "webstore-api",
  "version": "1.0.0",
  "main": "server.js",
  "scripts": { "start": "node server.js" }
}
EOF
```

4. Write the `.dockerignore` file from scratch
```
node_modules
.git
*.log
.env
dist
build
```

5. Write the Dockerfile from scratch
```dockerfile
FROM node:20-alpine

WORKDIR /app

COPY package.json .
RUN npm install

COPY . .

EXPOSE 8080

CMD ["node", "server.js"]
```

6. Build the image
```bash
docker build -t webstore-api:1.0 .
```

7. Confirm the image exists
```bash
docker images | grep webstore-api
```

8. Run it
```bash
docker run -d --name webstore-api -p 8080:8080 webstore-api:1.0
```

9. Test it
```bash
curl http://localhost:8080
```

**What to observe:**
```json
{"service":"webstore-api","status":"running"}
```

10. Check the logs
```bash
docker logs webstore-api
```

---

## Section 6 — Inspect Your Image Layers

**Goal:** verify your Dockerfile produced the layers you expect.

1. View your image layers
```bash
docker history webstore-api:1.0
```

**What to observe:** each instruction you wrote appears as a layer with a size

2. Check that `.dockerignore` is working — look at the COPY layer size and confirm `node_modules` was not copied in

---

## Section 7 — Break It on Purpose

### Break 1 — Wrong base image name

1. Edit your Dockerfile — change the FROM line
```dockerfile
FROM node:99-alpine
```

2. Try to build
```bash
docker build -t webstore-api:broken .
```

**What to observe:** `manifest unknown` — image tag does not exist on Docker Hub

3. Fix it — restore `node:20-alpine`

### Break 2 — COPY before WORKDIR

1. Edit your Dockerfile
```dockerfile
FROM node:20-alpine
COPY package.json .
WORKDIR /app
RUN npm install
COPY . .
CMD ["node", "server.js"]
```

2. Build and run
```bash
docker build -t webstore-api:broken2 .
docker run --rm webstore-api:broken2
```

**What to observe:** `package.json` was copied to `/` (root) not `/app` — WORKDIR must come before COPY

3. Fix it — restore the correct order

### Break 3 — Missing `.dockerignore` effect

1. Create a fake node_modules folder
```bash
mkdir node_modules
echo "fake dependency" > node_modules/fake.js
```

2. Remove your `.dockerignore` temporarily
```bash
mv .dockerignore .dockerignore.bak
```

3. Build and inspect the COPY layer size
```bash
docker build -t webstore-api:no-ignore .
docker history webstore-api:no-ignore
```

**What to observe:** COPY layer is larger — `node_modules` was copied in unnecessarily

4. Restore `.dockerignore`
```bash
mv .dockerignore.bak .dockerignore
```

5. Build again and compare
```bash
docker build -t webstore-api:with-ignore .
docker history webstore-api:with-ignore
```

**What to observe:** COPY layer is smaller — `.dockerignore` excluded the junk

---

## Section 8 — Safe Delete Flow

1. Stop and remove the running container
```bash
docker stop webstore-api
docker rm webstore-api
```

2. Remove all images from this lab
```bash
docker rmi webstore-api:1.0 webstore-api:broken webstore-api:broken2
docker rmi webstore-api:no-ignore webstore-api:with-ignore
docker rmi cache-test:v1 cache-test:v2
docker rmi order-bad:v1 order-bad:v2 order-good:v1 order-good:v2
```

3. Confirm clean
```bash
docker images
docker ps -a
```

---

## Checklist

Do not move to Lab 04 until every box is checked.

- [ ] I ran `docker history` on alpine and node images and understood what each layer represents
- [ ] I built the same image twice and confirmed every layer was CACHED on the second build
- [ ] I changed one layer in the middle of a Dockerfile and watched it and every layer after it rebuild — I understand why
- [ ] I built the bad ordering Dockerfile, changed a source file, and watched `npm install` run again unnecessarily
- [ ] I built the good ordering Dockerfile, changed a source file, and confirmed `npm install` was cached
- [ ] I wrote the webstore-api Dockerfile from scratch with correct layer ordering
- [ ] I wrote `.dockerignore` from scratch and know what each entry excludes and why
- [ ] I built, ran, and hit `webstore-api:1.0` with curl and got a valid JSON response
- [ ] I produced a wrong FROM tag error and read the error message
- [ ] I proved `.dockerignore` reduces the COPY layer size by comparing builds with and without it
