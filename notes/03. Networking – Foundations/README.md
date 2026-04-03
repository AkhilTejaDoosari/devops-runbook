[Foundation](01-foundation-and-the-big-picture/README.md) |
[Addressing](02-addressing-fundamentals/README.md) |
[IP Deep Dive](03-ip-deep-dive/README.md) |
[Network Devices](04-network-devices/README.md) |
[Subnets & CIDR](05-subnets-cidr/README.md) |
[Ports & Transport](06-ports-transport/README.md) |
[NAT](07-nat/README.md) |
[DNS](08-dns/README.md) |
[Firewalls](09-firewalls/README.md) |
[Complete Journey](10-complete-journey/README.md)

---

# Networking Fundamentals for DevOps Engineers

A practical networking guide built for DevOps and cloud engineering roles.
No CCNA fluff. Only what you actually use.

---

## The Running Example

Every scenario uses the same webstore application:
- User opens webstore.com from their laptop
- Traffic flows through DNS, NAT, routing, VPC, load balancer, security groups
- By file 10 you can trace every single hop of that journey

---

## The Series

| # | File | What You Learn |
|---|---|---|
| 01 | [Foundation & Big Picture](01-foundation-and-the-big-picture/README.md) | What networking is, packets, encapsulation, OSI overview |
| 02 | [Addressing Fundamentals](02-addressing-fundamentals/README.md) | MAC vs IP, ARP, private vs public IPs |
| 03 | [IP Deep Dive](03-ip-deep-dive/README.md) | DHCP, why your IP changes, static vs dynamic, localhost |
| 04 | [Network Devices](04-network-devices/README.md) | Switch vs router, default gateway, routing tables |
| 05 | [Subnets & CIDR](05-subnets-cidr/README.md) | Subnet masks, CIDR notation, AWS VPC planning |
| 06 | [Ports & Transport](06-ports-transport/README.md) | Ports, TCP vs UDP, 3-way handshake, sockets |
| 07 | [NAT & Translation](07-nat/README.md) | PAT, port forwarding, AWS NAT Gateway, Docker port binding |
| 08 | [DNS](08-dns/README.md) | DNS resolution, record types, TTL, Route53, Docker DNS |
| 09 | [Firewalls & Security](09-firewalls/README.md) | Stateful vs stateless, Security Groups, NACLs, NACL trap |
| 10 | [Complete Journey](10-complete-journey/README.md) | Everything integrated — full packet flows end to end |

---

## Labs

| Lab | Covers |
|---|---|
| [Lab 01](./networking-labs/01-foundation-addressing-ip-lab.md) | ip addr, ARP table, MAC vs IP, private ranges, localhost |
| [Lab 02](./networking-labs/02-devices-subnets-lab.md) | Routing table, traceroute, CIDR calculation, VPC design |
| [Lab 03](./networking-labs/03-ports-transport-nat-lab.md) | ss, netstat, curl TCP handshake, Docker NAT |
| [Lab 04](./networking-labs/04-dns-firewalls-lab.md) | dig trace, nslookup, ufw rules, break and fix connectivity |
| [Lab 05](./networking-labs/05-complete-journey-lab.md) | Full end-to-end trace: DNS + routing + ports + firewalls |

---

## Reference

[Networking Map](00-networking-map/README.md) — single-page cheat sheet, use before interviews

---

## Critical Concepts

**The Big Three:**
1. **MAC vs IP** — MAC changes at every hop, IP never changes
2. **Stateful vs Stateless** — Security Groups auto-allow return traffic, NACLs don't
3. **Encapsulation** — Each layer wraps the previous (Frame → Packet → Segment → Data)

---

## What You Can Do After This
  
✅ Design AWS VPCs with proper subnetting  
✅ Debug "can't connect" issues systematically  
✅ Configure Docker networks correctly  
✅ Understand what happens when you type a URL  
✅ Set up firewalls without breaking applications  
✅ Calculate CIDR blocks  
✅ Not get trapped by AWS NACLs  
