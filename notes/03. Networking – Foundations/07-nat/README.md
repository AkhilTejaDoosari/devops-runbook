# File 07: NAT & Translation

[Home](../README.md) |
[Foundation](../01-foundation-and-the-big-picture/README.md) |
[Addressing](../02-addressing-fundamentals/README.md) |
[IP Deep Dive](../03-ip-deep-dive/README.md) |
[Network Devices](../04-network-devices/README.md) |
[Subnets & CIDR](../05-subnets-cidr/README.md) |
[Ports & Transport](../06-ports-transport/README.md) |
[NAT](../07-nat/README.md) |
[DNS](../08-dns/README.md) |
[Firewalls](../09-firewalls/README.md) |
[Complete Journey](../10-complete-journey/README.md) |
[Interview](../99-interview-prep/README.md)

---

# NAT & Translation

## What this file is about

This file teaches **how devices with private IPs access the internet** and **how your router manages multiple devices with one public IP**. If you understand this, you'll know why your home router can support 50+ devices with one IP, how PAT works under the hood, and how port forwarding exposes internal services. How Docker and AWS implement NAT on top of these concepts is covered in their respective notes.

<!-- no toc -->
- [The Core Problem](#the-core-problem)
- [Why NAT Exists](#why-nat-exists)
- [How NAT Works (Basic)](#how-nat-works-basic)
- [PAT: Port Address Translation](#pat-port-address-translation)
- [The NAT Table](#the-nat-table)
- [Port Forwarding (Inbound NAT)](#port-forwarding-inbound-nat)
- [NAT Types and Variations](#nat-types-and-variations)
- [Real Scenarios](#real-scenarios)  
[Final Compression](#final-compression)

---

## The Core Problem

### Your Original Question

**"Router has no public IP? Only ISP has public IP?"**

**Answer:** Your router has BOTH.

**Router's two faces:**

```
┌─────────────────────────────────────────────────────────────┐
│                       YOUR ROUTER                           │
│           (The Bridge Between Two Networks)                 │
│                                                             │
│   [ ROUTER HAS 2 IP ADDRESSES ]                             │
│                                                             │
│  1. LAN SIDE (Internal Interface)                           │
│     ─────────────────────────────                           │
│     IP:  192.168.1.1                                        │
│     TYPE: Private (Local)                                   │
│     MAC: AA:BB:CC:DD:EE:FF                                  │
│     ROLE: Default Gateway for your home devices             │
│     SCOPE: Not internet-routable                            │
│                                                             │
│                ||                                           │
│                || <─── NAT (Network Address Translation)    │
│                ||                                           │
│                                                             │
│  2. WAN SIDE (External Interface)                           │
│     ─────────────────────────────                           │
│     IP:  203.45.67.89                                       │
│     TYPE: Public (Global)                                   │
│     MAC: 11:22:33:44:55:66                                  │
│     ROLE: Your "Face" on the internet                       │
│     SCOPE: Internet-routable (Assigned by ISP)              │
│                                                             │
└─────────────────────────────────────────────────────────────┘

```

---

### The Fundamental Problem NAT Solves

**Scenario:**

```
Your home network:
├─ Laptop:     192.168.1.45
├─ Phone:      192.168.1.67
├─ Tablet:     192.168.1.89
└─ Smart TV:   192.168.1.100

All have private IPs
Private IPs cannot route on the internet

Internet server: 142.250.190.46 (Google)
Cannot send responses to private IPs
```

**Without NAT:**

```
Laptop (192.168.1.45) → Google (142.250.190.46)

Google tries to respond:
  Dest IP: 192.168.1.45 ← Private IP!

Internet routers: "192.168.1.45 is not routable"
Packet dropped

❌ Communication fails
```

---

## Why NAT Exists

### Historical Context

**IPv4 address exhaustion:**

```
Total IPv4 addresses: 4.3 billion
World population: 8 billion
Devices per person: 3-5+

Math: 4.3 billion < 20 billion devices

Not enough public IPs for everyone!
```

**Solution: NAT**

```
Many devices share one public IP

Your home:
├─ 10 devices with private IPs
└─ 1 router with public IP

All 10 devices access internet via 1 public IP
```

---

### NAT's Role in Modern Networking

**NAT allows:**

```
✅ Private IP addresses to access internet
✅ Multiple devices behind one public IP
✅ Conservation of public IP space
✅ Additional security (hides internal topology)
```

**NAT prevents:**

```
❌ Direct inbound connections to private IPs
   (Unless explicitly configured via port forwarding)
```

---

## How NAT Works (Basic)

### The Translation Process

**Your laptop accesses google.com:**

**Step 1: Laptop sends packet (private IP)**

```
Inside your network:
  Source IP:   192.168.1.45 (laptop)
  Source Port: 54321
  Dest IP:     142.250.190.46 (Google)
  Dest Port:   443

Packet reaches router
```

**Step 2: Router performs NAT (translation)**

```
Router receives packet
Checks source: 192.168.1.45 (private - can't route)

Router translates:
  Old Source IP:   192.168.1.45
  New Source IP:   203.45.67.89 (router's public IP)

Router records translation in NAT table:
  192.168.1.45:54321 ↔ 203.45.67.89:54321
```

**Step 3: Router forwards (public IP)**

```
Router sends packet to internet:
  Source IP:   203.45.67.89 (router's public IP)
  Source Port: 54321
  Dest IP:     142.250.190.46
  Dest Port:   443

Google sees: 203.45.67.89 (not 192.168.1.45)
```

**Step 4: Google responds**

```
Google sends response:
  Source IP:   142.250.190.46
  Source Port: 443
  Dest IP:     203.45.67.89 (router's public IP)
  Dest Port:   54321
```

**Step 5: Router receives response**

```
Router receives packet on WAN interface
Checks NAT table:
  Dest port 54321 → belongs to 192.168.1.45:54321

Router translates back:
  Old Dest IP:   203.45.67.89
  New Dest IP:   192.168.1.45
```

**Step 6: Router forwards to laptop**

```
Router sends packet to LAN:
  Dest IP:     192.168.1.45
  Dest Port:   54321

Laptop receives response. Communication successful!
```

---

### Visual: Complete NAT Flow

```
┌──────────────────────────────────────────────────────────┐
│  Home Network (192.168.1.0/24)                           │
│                                                          │
│  [Laptop: 192.168.1.45]                                  │
│        │                                                 │
│        │ 1. Outbound request                             │
│        │    Src: 192.168.1.45:54321                      │
│        │    Dst: 142.250.190.46:443                      │
│        ▼                                                 │
│  ┌─────────────────────────────────────────┐             │                   
│  │  Router / NAT                           │             │                 
│  │                                         │             │               
│  │  LAN: 192.168.1.1   (Private-IP)        │             │             
│  │  WAN: 203.45.67.89  (Public-IP)         │             │
│  │                                         │             │
│  │  NAT Table:                             │             │
│  │ 192.168.1.45:54321 ↔ 203.45.67.89:54321 │             │
│  └─────────────────────────────────────────┘             │
│        │                                                 │
│        │                                                 │
│        │ 2. Translated request                           │
│        │    Src: 203.45.67.89:54321 ← Changed            │
│        │    Dst: 142.250.190.46:443                      │
└──────────────────────────────────────────────────────────┘
         │
         │ Internet
         ▼
[Google: 142.250.190.46]
  Response: Dst: 203.45.67.89:54321
         │
         │ Internet
         ▼
Router: checks NAT table, port 54321 → 192.168.1.45
  Dst: 192.168.1.45:54321 ← Changed back
         │
[Laptop receives response ✓]
```

---

## PAT: Port Address Translation

### The Real NAT Used at Home

**Basic NAT only changes IP addresses.**  
**PAT (also called NAT Overload) changes IP AND ports.**

**This is what your home router actually uses.**

---

### Why PAT Is Needed

**Problem with basic NAT:**

```
Two devices access same server with same source port:

Laptop:  192.168.1.45:54321 → Google:443
Phone:   192.168.1.67:54321 → Google:443

Both translate to: 203.45.67.89:54321

Google responds to: 203.45.67.89:54321

Router: Which device should receive it?
  Laptop or Phone?

❌ Ambiguous! NAT table collision!
```

---

### How PAT Solves This

**PAT changes BOTH IP and port:**

```
Laptop request:
  Original: 192.168.1.45:54321 → Google:443
  After PAT: 203.45.67.89:10001 → Google:443

Phone request:
  Original: 192.168.1.67:54321 → Google:443
  After PAT: 203.45.67.89:10002 → Google:443

PAT Table:
  192.168.1.45:54321 ↔ 203.45.67.89:10001
  192.168.1.67:54321 ↔ 203.45.67.89:10002

No collision — each connection has unique translated port.
```

---

### Port Allocation in PAT

**Router allocates ports from dynamic range:**

```
Port range: 49152-65535 (dynamic ports)
Total available: 16,384 ports

Each connection gets unique port:
  Connection 1: 203.45.67.89:49152
  Connection 2: 203.45.67.89:49153
  ...

One public IP can support ~16,000 simultaneous connections
```

---

## The NAT Table

### What's in the NAT Table

**NAT table tracks all active translations:**

```
Internal IP:Port  ↔  External IP:Port  ↔  Remote IP:Port  Timeout
192.168.1.45:54321 ↔ 203.45.67.89:49152 ↔ 142.250.190.46:443  300s
192.168.1.45:54322 ↔ 203.45.67.89:49153 ↔ 93.184.216.34:80    300s
192.168.1.67:51234 ↔ 203.45.67.89:49154 ↔ 142.250.190.46:443  300s
```

---

### NAT Table Timeout

**Entries expire after inactivity:**

```
TCP connection:
  Active: Entry stays alive
  Idle for 5 minutes: Entry removed

UDP (connectionless):
  Packet sent: Entry created
  Idle for 30-60 seconds: Entry removed
```

**Why timeout matters:**

```
Long idle connection:
  Client thinks connection is alive
  NAT table entry expired (timed out)
  Client sends data — packet dropped

Solution: TCP keepalive or reconnect
```

---

### View NAT Table

**On Linux router:**

```bash
# Using conntrack
sudo conntrack -L

Output:
tcp 6 299 ESTABLISHED src=192.168.1.45 dst=142.250.190.46 \
  sport=54321 dport=443 \
  src=142.250.190.46 dst=203.45.67.89 \
  sport=443 dport=49152
```

---

## Port Forwarding (Inbound NAT)

### The Problem

**NAT blocks inbound connections:**

```
You run web server on laptop: 192.168.1.45:8080

Friend tries: http://203.45.67.89:8080

Router checks NAT table:
  No entry for port 8080 (no outbound connection created it)
  Packet dropped

❌ Friend cannot reach your web server
```

---

### Port Forwarding Solution

**Create static NAT mapping:**

```
Port forwarding rule:
  External Port: 8080
  Internal IP:   192.168.1.45
  Internal Port: 8080
  Protocol:      TCP

Effect:
  "Forward all traffic to 203.45.67.89:8080
   to 192.168.1.45:8080"
```

---

### How Port Forwarding Works

```
Friend → http://203.45.67.89:8080

1. Packet arrives at router: Dst 203.45.67.89:8080
2. Router checks port forwarding rules
3. Port 8080 → 192.168.1.45:8080
4. Router rewrites Dst → 192.168.1.45:8080
5. Forwards to laptop
6. Laptop responds
7. Router reverse NATs
8. Friend receives response
```

---

### Common Port Forwarding Use Cases

```
✅ Hosting game servers
✅ Running web servers at home
✅ Remote desktop access
✅ Security cameras (remote viewing)
✅ Home automation systems
```

---

## NAT Types and Variations

### Source NAT (SNAT)

**Outbound translation — what we've been discussing:**

```
Changes source IP going outbound
Private → Public
  Src: 192.168.1.45 → 203.45.67.89
```

---

### Destination NAT (DNAT)

**Port forwarding — inbound translation:**

```
Changes destination IP coming inbound
Public → Private
  Dst: 203.45.67.89:8080 → 192.168.1.45:8080
```

---

### Static NAT

**One-to-one mapping:**

```
192.168.1.100 ↔ 203.45.67.100 (always)

Used when: Multiple public IPs available
```

---

### NAT Overload (PAT)

**What home routers use:**

```
Many-to-one mapping using ports

Many private IPs → One public IP
Differentiated by port numbers
```

---

## Real Scenarios

### Scenario 1: Home Network NAT

**All devices browse internet simultaneously:**

```
PAT Table (simplified):

Internal              External              Remote
192.168.1.45:54321 ↔ 203.45.67.89:49152 ↔ 142.250.190.46:443
192.168.1.67:51234 ↔ 203.45.67.89:49153 ↔ 142.250.190.46:443
192.168.1.89:48901 ↔ 203.45.67.89:49154 ↔ 93.184.216.34:80

Three devices, one public IP
Differentiated by port number
```

---

### Scenario 2: Port Forwarding for Game Server

**Setup:**

```
Public IP: 203.45.67.89
Game Server: 192.168.1.100:25565 (Minecraft)
```

**Port forwarding rule:**

```
External Port: 25565
Internal IP:   192.168.1.100
Internal Port: 25565
Protocol:      TCP
```

**Connection flow:**

```
Friend connects: 203.45.67.89:25565

1. Router checks port forwarding: 25565 → 192.168.1.100
2. Router translates destination
3. Packet forwarded to game server
4. Game server responds
5. Router performs reverse NAT
6. Friend receives response
8. Connection established
```

---

> **Docker implementation:** Docker port binding (`-p 8080:80`) is NAT in action — Docker creates iptables DNAT rules that forward host ports to container ports. The full breakdown with verification commands is in the Docker notes.
> → [Docker Networking](../../04.%20Docker%20–%20Containerization/05-docker-networking/README.md)

> **AWS implementation:** AWS NAT Gateway lets private EC2 instances access the internet without a public IP — same principle as your home router but managed by AWS. The full architecture, HA patterns, and Terraform examples are in the AWS notes.
> → [AWS VPC & Subnets](../../06.%20AWS%20–%20Cloud%20Infrastructure/03-vpc-subnet/README.md)

---

## Final Compression

### Why NAT Exists

```
Problem: Not enough public IPv4 addresses
Solution: Many private IPs share one public IP

Your home: 10 devices, 1 public IP
```

---

### How NAT Works

**Outbound (Private → Public):**
```
Device sends:
  Src: 192.168.1.45:54321 (private)
  
Router translates:
  Src: 203.45.67.89:49152 (public)
  
Records in NAT table
```

**Inbound (Public → Private):**
```
Response arrives:
  Dst: 203.45.67.89:49152
  
Router checks NAT table:
  Port 49152 → 192.168.1.45:54321
  
Router translates:
  Dst: 192.168.1.45:54321
```

---

### PAT (What Routers Actually Use)

```
Changes BOTH IP and port
Allows many devices to share one IP

192.168.1.45:54321 → 203.45.67.89:49152
192.168.1.67:54321 → 203.45.67.89:49153

Same public IP, different ports
```

---

### Port Forwarding (Inbound NAT)

```
Static mapping for inbound connections

Rule: External:8080 → Internal:192.168.1.45:8080

Use cases: Game servers, web hosting, remote access
```

---

### Router's Two IPs

```
LAN (Internal):
  IP: 192.168.1.1 (private)
  Your devices connect here

WAN (External):
  IP: 203.45.67.89 (public, from ISP)
  Internet connection

One foot in each network
```

---

### NAT Limitations

```
❌ Breaks end-to-end connectivity
❌ Inbound connections blocked (unless port forwarding)
❌ Some protocols don't work well (SIP, FTP)
✅ Works for most common protocols (HTTP, HTTPS, SSH)
```

---

### Mental Model

```
NAT = Translator between two worlds

Private world (home/office):
  Many devices, private IPs

Public world (internet):
  One public IP

Router = Translator:
  Remembers conversations (NAT table)
  Changes addresses (translation)
  Ensures responses reach correct device
```

---

### What You Can Do Now

✅ Understand why private IPs need NAT  
✅ Know how PAT works (IP + port translation)  
✅ Configure port forwarding  
✅ Know router has two IPs (LAN + WAN)  
✅ Debug NAT-related connectivity issues  

---

## What This Means for the Webstore

The webstore server has a private IP on the network — `10.0.1.45` or similar. When it receives a request from a browser on the internet, that request arrived at the public IP of the router, which NAT-translated it inbound to `10.0.1.45`. The browser never knew the server's private IP. When the server responds, the router translates the source IP back to public before sending it out. This NAT process is invisible in both directions. When you later configure `docker run -p 8080:80`, Docker is creating a DNAT rule in iptables — the exact same mechanism described in this file, applied at the container level. The concept is identical. The scope is smaller.

---

→ **Interview questions for this topic:** [99-interview-prep → NAT · Port Forwarding · Translation](../99-interview-prep/README.md#nat--port-forwarding--translation)

→ Ready to practice? [Go to Lab 03](../networking-labs/03-ports-transport-nat-lab.md)
