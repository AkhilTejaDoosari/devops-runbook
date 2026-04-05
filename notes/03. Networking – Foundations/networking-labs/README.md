[Home](../README.md) |
[Labs Index](./README.md) |
[Lab 01](./01-foundation-addressing-ip-lab.md) |
[Lab 02](./02-devices-subnets-lab.md) |
[Lab 03](./03-ports-transport-nat-lab.md) |
[Lab 04](./04-dns-firewalls-lab.md) |
[Lab 05](./05-complete-journey-lab.md)

---

# Networking Labs

Hands-on sessions for every topic in the Networking notes.

Do them in order. Do not move to the next lab until the checklist at the bottom is fully checked.

---

## The Project Thread

These five labs are not isolated drills. They are five stages in understanding the network layer that every request to the webstore passes through.

The webstore server is running nginx on port 80, the API on port 8080, and postgres on port 5432. A browser somewhere types `webstore.example.com` and presses Enter. By Lab 05 you can trace every single step that request takes to reach the server and come back — and you can debug it when something goes wrong.

No Docker. No AWS. Just the network underneath both of them.

| Lab | What you are learning to see | Why it matters for the webstore |
|---|---|---|
| [Lab 01](./01-foundation-addressing-ip-lab.md) | Interfaces, MAC, IP, ARP, localhost | The webstore server has an IP — this is how it gets one and what it means |
| [Lab 02](./02-devices-subnets-lab.md) | Routing table, traceroute, CIDR, subnet design | Requests are routed to the webstore server — this is how routers decide where to send them |
| [Lab 03](./03-ports-transport-nat-lab.md) | ss, TCP handshake, NAT, iptables DNAT | nginx on 80, API on 8080, postgres on 5432 — ports are what separate them |
| [Lab 04](./04-dns-firewalls-lab.md) | dig, record types, TTL, iptables rules, stateful vs stateless | webstore.example.com resolves to an IP — firewalls decide what can reach it |
| [Lab 05](./05-complete-journey-lab.md) | Full end-to-end trace, production debugging | Put every layer together — trace a request and fix it when it breaks |

---

## Labs

| Lab | Topics | Notes |
|---|---|---|
| [Lab 01](./01-foundation-addressing-ip-lab.md) | Interfaces, MAC, IP, ARP, private ranges, localhost | [01](../01-foundation-and-the-big-picture/README.md) · [02](../02-addressing-fundamentals/README.md) · [03](../03-ip-deep-dive/README.md) |
| [Lab 02](./02-devices-subnets-lab.md) | Routing table, traceroute, CIDR calculation, VPC design | [04](../04-network-devices/README.md) · [05](../05-subnets-cidr/README.md) |
| [Lab 03](./03-ports-transport-nat-lab.md) | ss, netstat, TCP handshake, UDP, iptables DNAT | [06](../06-ports-transport/README.md) · [07](../07-nat/README.md) |
| [Lab 04](./04-dns-firewalls-lab.md) | dig trace, record types, TTL, iptables, stateful vs stateless | [08](../08-dns/README.md) · [09](../09-firewalls/README.md) |
| [Lab 05](./05-complete-journey-lab.md) | Full end-to-end trace, production debugging, interview answer | [10](../10-complete-journey/README.md) |

---

## How to Use These Labs

Read the notes for each phase before opening a terminal. Every lab assumes you have read the corresponding notes files first.

Write every command from scratch. Do not copy-paste.

Every lab has a "Break It on Purpose" section. Do not skip it. These are the failure states you will actually hit in production.

Do not move to the next lab until every box in the checklist is checked.
