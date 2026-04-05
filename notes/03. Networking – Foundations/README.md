<p align="center">
  <img src="../../assets/networking-banner.svg" alt="networking" width="100%"/>
</p>

[← devops-runbook](../../README.md)

---

A practical networking guide built for DevOps and cloud engineering roles.
No CCNA fluff. Only what you actually use — and only what Docker and AWS build on top of.

---

## Why Networking Comes Before Docker and AWS

Docker bridge networking, container DNS, and port binding are all networking concepts in a container wrapper. AWS VPC, Security Groups, NAT Gateway, and Route 53 are all networking concepts in a cloud wrapper.

If you learn Docker or AWS before networking, those tools feel like magic. Magic breaks in production without warning. This folder removes the magic — everything Docker and AWS do with networking has its foundation explained here first.

The networking notes teach the pure concepts using only what you have right now: a Linux server running nginx serving the webstore frontend. No containers. No cloud. Just a server, a network, and the tools to understand both.

---

## Prerequisites

**Complete first:** [02. Git & GitHub – Version Control](../02.%20Git%20%26%20GitHub%20–%20Version%20Control/README.md)

You need Git to version your lab work and notes as you go through this series.

---

## The Running Example

Every scenario uses the same webstore application on a Linux server:

```
Linux server (running nginx)
├── webstore-frontend  → nginx serving static files on port 80
├── webstore-api       → application process on port 8080
└── webstore-db        → postgres process on port 5432
```

The webstore server has an IP address. Its services run on ports. Its hostname resolves via DNS. Its traffic passes through NAT. Its ports are controlled by iptables. By file 10 you can trace every hop a request makes from a browser to the webstore and back.

Docker and AWS apply all of these same concepts — but in their own context. That connection is made in the Docker and AWS notes, not here.

---

## Where You Take the Webstore

You arrive at Networking with the webstore running on a Linux server — nginx serving the frontend, the API and database on their ports, everything on one machine. You leave with the ability to explain and debug every network layer that request passes through to reach that server.

That understanding is what makes Docker networking click. When Docker says "bridge network", you already know what a bridge is. When Docker says "DNS at 127.0.0.11", you already know what DNS does. When Docker says "-p 8080:80 creates a DNAT rule", you have already seen a DNAT rule. The Docker notes explain how Docker uses these concepts — not what the concepts are.

---

## Phases

| Phase | Topics | Lab |
|---|---|---|
| 1 — Foundation | [01 Foundation & Big Picture](./01-foundation-and-the-big-picture/README.md) · [02 Addressing](./02-addressing-fundamentals/README.md) · [03 IP Deep Dive](./03-ip-deep-dive/README.md) | [Lab 01](./networking-labs/01-foundation-addressing-ip-lab.md) |
| 2 — Routing | [04 Network Devices](./04-network-devices/README.md) · [05 Subnets & CIDR](./05-subnets-cidr/README.md) | [Lab 02](./networking-labs/02-devices-subnets-lab.md) |
| 3 — Transport & NAT | [06 Ports & Transport](./06-ports-transport/README.md) · [07 NAT & Translation](./07-nat/README.md) | [Lab 03](./networking-labs/03-ports-transport-nat-lab.md) |
| 4 — DNS & Firewalls | [08 DNS](./08-dns/README.md) · [09 Firewalls & Security](./09-firewalls/README.md) | [Lab 04](./networking-labs/04-dns-firewalls-lab.md) |
| 5 — Complete Journey | [10 Complete Journey](./10-complete-journey/README.md) | [Lab 05](./networking-labs/05-complete-journey-lab.md) |

---

## Labs

| Lab | Topics Covered | What You Practice |
|---|---|---|
| [Lab 01](./networking-labs/01-foundation-addressing-ip-lab.md) | Foundation · Addressing · IP | ip addr, ARP table, MAC vs IP, private ranges, localhost |
| [Lab 02](./networking-labs/02-devices-subnets-lab.md) | Network Devices · Subnets | Routing table, traceroute, CIDR calculation, subnet design |
| [Lab 03](./networking-labs/03-ports-transport-nat-lab.md) | Ports · Transport · NAT | ss, TCP handshake, iptables DNAT proof |
| [Lab 04](./networking-labs/04-dns-firewalls-lab.md) | DNS · Firewalls | dig +trace, nslookup, iptables rules, stateful vs stateless |
| [Lab 05](./networking-labs/05-complete-journey-lab.md) | Complete Journey | Full end-to-end trace: DNS + routing + ports + firewalls |

---

## Reference

[Networking Map](./00-networking-map/README.md) — single-page cheat sheet, use before interviews and when debugging

---

## Critical Concepts

**The Big Three — understand these before moving on:**

1. **MAC vs IP** — MAC changes at every router hop, IP never changes end to end
2. **Stateful vs Stateless** — stateful firewalls auto-allow return traffic, stateless don't — this causes the most common AWS NACL failures
3. **DNS TTL** — DNS changes do not propagate instantly, TTL controls the delay

---

## What You Can Do After This

- Explain what happens at every layer when a browser opens a URL
- Debug connectivity failures systematically — DNS → routing → ports → firewall → service
- Read `ss`, `dig`, `traceroute`, `iptables` output and know what it means
- Design a subnet layout for a multi-tier application
- Understand why Docker bridge networking, container DNS, and port binding work the way they do — before you ever run a container

---

## How to Use This

Read phases in order. Each one builds on the previous.
After each phase do the lab before moving on.
The checklist at the end of every lab is not optional.

---

## What Comes Next

→ [04. Docker – Containerization](../04.%20Docker%20–%20Containerization/README.md)

Docker runs every concept from this folder — bridges, routing, NAT, DNS — but in a container context. The Docker prerequisites section lists exactly which networking files you need before starting. Everything you learned here transfers directly.
