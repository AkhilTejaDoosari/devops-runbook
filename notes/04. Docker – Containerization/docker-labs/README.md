[Home](../README.md) |
[Labs Index](./README.md) |
[Lab 01](./01-containers-portbinding-lab.md) |
[Lab 02](./02-networking-volumes-lab.md) |
[Lab 03](./03-build-layers-lab.md) |
[Lab 04](./04-registry-compose-lab.md)

---

# Docker Labs

Hands-on sessions for every topic in the Docker notes.

Each lab builds on the previous one. Do them in order.
Do not move to the next lab until the checklist at the bottom is fully checked.

---

## The Project Thread

These four labs containerize the webstore from scratch — the same project that ran on a Linux server and was versioned with Git. By Lab 04 you have the entire three-tier webstore running from a single `docker compose up` command, with the API image pushed to Docker Hub and ready for Kubernetes.

| Lab | Where the webstore is | What you do |
|---|---|---|
| [Lab 01](./01-containers-portbinding-lab.md) | Not yet containerized | Pull images, run nginx as webstore-frontend, bind ports, debug containers |
| [Lab 02](./02-networking-volumes-lab.md) | Frontend running | Wire webstore-api to webstore-db on a Docker network, persist postgres data in a volume |
| [Lab 03](./03-build-layers-lab.md) | Network and storage wired | Build the webstore-api image from a Dockerfile, optimize layers, use multi-stage builds |
| [Lab 04](./04-registry-compose-lab.md) | Image built | Push to Docker Hub, write docker-compose.yml, bring the full three-tier webstore up in one command |

---

## Labs

| Lab | Topics | Notes |
|---|---|---|
| [Lab 01](./01-containers-portbinding-lab.md) | Containers + Port Binding | [03](../03-docker-containers/README.md) · [04](../04-docker-port-binding/README.md) |
| [Lab 02](./02-networking-volumes-lab.md) | Networking + Volumes | [05](../05-docker-networking/README.md) · [06](../06-docker-volumes/README.md) |
| [Lab 03](./03-build-layers-lab.md) | Layers + Build + Dockerfile | [07](../07-docker-layers/README.md) · [08](../08-docker-build-dockerfile/README.md) |
| [Lab 04](./04-registry-compose-lab.md) | Registry + Compose | [09](../09-docker-registry/README.md) · [10](../10-docker-compose/README.md) |
