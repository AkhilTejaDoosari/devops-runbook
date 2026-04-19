
---
# SOURCE: 03. Networking – Foundations/00-networking-map/00-networking-map.md
---

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

# Networking Reference Map

A single-page cheat sheet covering the entire series.
Use this before interviews and when debugging production issues.

---

## 1. Master Packet Journey

```
[Your Computer]
      ↓
   DNS Lookup → name becomes IP
      ↓
   TCP Handshake → SYN, SYN-ACK, ACK
      ↓
   Encapsulation → Data → Port → IP → MAC
      ↓
[Local Switch] → reads MAC, forwards locally
      ↓
   ARP Resolution → IP becomes MAC
      ↓
[Home Router]
      ↓
   NAT → Private IP becomes Public IP
      ↓
((( INTERNET )))
      ↓
   Hop-by-Hop Routing
   MAC changes every hop
   IP never changes
      ↓
[AWS VPC]
      ↓
   Internet Gateway → enters VPC
      ↓
   NACL → subnet firewall (stateless)
      ↓
   Load Balancer → distributes to server
      ↓
   Security Group → instance firewall (stateful)
      ↓
   ARP Final Hop → resolve final MAC
      ↓
   De-encapsulation → MAC → IP → Port → Data
      ↓
   Port routes to application
      ↓
[Destination Server]
```

---

## 2. Layer Mental Model

| Layer | Tool | Purpose | Changes During Journey? |
|---|---|---|---|
| **Layer 2 (Data Link)** | MAC Address | Local delivery within network | Yes — every hop |
| **Layer 3 (Network)** | IP Address | Global delivery across internet | Destination: No / Source: Yes (NAT) |
| **Layer 4 (Transport)** | Port Number | Deliver to correct application | No |

---

## 3. What Changes vs What Stays

| Component | Changes? | When | Why |
|---|---|---|---|
| **Application Data** | Never | — | The payload |
| **Destination IP** | Never | — | Global addressing |
| **Source IP** | Once | At NAT | Private → Public |
| **Port Number** | Never | — | Application identifier |
| **MAC Address** | Every hop | At each router | Local delivery only |

---

## 4. Protocol Map

| Need | Protocol | Command |
|---|---|---|
| Name → IP | DNS | `nslookup google.com` |
| IP → MAC (local) | ARP | `arp -a` |
| Reliable delivery | TCP | 3-way handshake |
| Fast delivery | UDP | No handshake |
| Global routing | IP | Hop-by-hop |
| Hide private IPs | NAT | Router translation |
| Auto IP assignment | DHCP | Lease process |

---

## 5. Security Layers

| Firewall Type | Scope | Memory? | Return Traffic? |
|---|---|---|---|
| **NACL** | Subnet | No (stateless) | Needs explicit rule |
| **Security Group** | Instance | Yes (stateful) | Auto-allowed |

**Rule:**
- Stateless = checks every packet independently, has amnesia
- Stateful = remembers connections, auto-allows replies

---

## 6. Debugging Breakpoints

| Stage | Failure Symptom | Tool | What It Shows |
|---|---|---|---|
| **DNS** | Name not resolving | `nslookup google.com` | IP or error |
| **TCP** | Connection refused | `nc -zv IP PORT` | Port open/closed |
| **Routing** | Packet lost | `traceroute google.com` | Where packet dies |
| **Firewall** | Port blocked | `ss -tlnp` | Listening ports |
| **ARP** | Local delivery fails | `arp -a` | MAC table |
| **NAT** | External access fails | `curl ifconfig.me` | Public IP |

---

## 7. Common Ports

```
22    → SSH
53    → DNS
80    → HTTP
443   → HTTPS
3306  → MySQL
5432  → PostgreSQL
6379  → Redis
27017 → MongoDB
```

---

## 8. CIDR Quick Reference

| CIDR | Total IPs | Usable | Use Case |
|---|---|---|---|
| /32 | 1 | 1 | Single host (SG rule) |
| /28 | 16 | 14 | Small subnet |
| /24 | 256 | 254 | Standard subnet |
| /16 | 65,536 | 65,534 | VPC CIDR |

---

## 9. Private IP Ranges

```
10.0.0.0/8         → Large networks (AWS VPC)
172.16.0.0/12      → Medium networks (Docker default)
192.168.0.0/16     → Home/small office
```

---

## 10. Interview Answer: Browser to Server

> DNS translates the domain to an IP. TCP handshake establishes connection. Data is encapsulated: application layer → port → destination IP → router MAC.
>
> Local switch forwards via MAC. Router performs NAT (private IP → public IP). Packet hops across internet — MAC changes every hop, IP stays constant.
>
> Enters AWS via Internet Gateway. Passes stateless NACL (subnet firewall), then load balancer distributes to server. Stateful Security Group allows it through.
>
> De-encapsulation: strip MAC → IP → port. Port routes to web application. Response follows reverse path.

---

## 11. Webstore Scenario

**User opens webstore.com**

```
DNS       → webstore.com resolves to 54.123.45.67 (Route53)
TCP       → Handshake to port 443
NAT       → Home router: 192.168.1.50 → 203.45.67.89
Routing   → Hops to AWS us-east-1
IGW       → Enters VPC 10.0.0.0/16
NACL      → Allows port 443 inbound
ALB       → Distributes to webstore-api instance
SG        → Allows port 443 to EC2
Server    → nginx serves webstore-frontend
Response  → Reverse path to browser
```

---
# SOURCE: 03. Networking – Foundations/01-foundation-and-the-big-picture/README.md
---

# File 01: Foundation & The Big Picture

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

# Foundation & The Big Picture

## What this file is about

This file teaches **what networking actually is** and **why it exists**. If you understand this, you'll have the mental framework to understand everything else in this series. No prior knowledge required.

<!-- no toc -->
- [Why Networking Exists](#why-networking-exists)
- [What Is a Network?](#what-is-a-network)
- [The Internet's Physical Reality](#the-internets-physical-reality)
- [What Is Data? (Introducing Packets)](#what-is-data-introducing-packets)
- [The Secret: Everything Is Layers](#the-secret-everything-is-layers)
- [The OSI Model — Your Map](#the-osi-model--your-map)
- [The Mental Model That Makes Everything Click](#the-mental-model-that-makes-everything-click)  
[Final Compression](#final-compression)

---

## Why Networking Exists

### The Problem (Before Networks)

**Scenario: 1960s**

Researchers at MIT have data.  
Researchers at Stanford need that data.  

**How do they share it?**

Option 1: Print it, mail it (takes days)  
Option 2: Fly with magnetic tapes (expensive)  
Option 3: Type it all again (error-prone)  

**None of these work when:**
- You need the data NOW
- The data changes constantly  
- Multiple people need access simultaneously

**The question became:** Can we connect computers together so they can share data instantly?

---

### The Solution: ARPANET (The First Network)

**1969:**  
The US government's Advanced Research Projects Agency (ARPA) connected four university computers:

```
UCLA ←→ Stanford ←→ UC Santa Barbara ←→ University of Utah
```

**For the first time:**
- A researcher at UCLA could send data to Stanford instantly
- No printing, no mailing, no flying
- Just computers talking directly to each other

**This was ARPANET — the ancestor of the internet.**

---

### Why This Matters for You

When you:
- Open a website
- Send an email  
- Deploy code to AWS
- Run a Docker container that talks to a database

**You're using the same fundamental concept:**

**Computers connected together, sharing data.**

Everything else is just details about HOW that connection works.

---

## What Is a Network?

### The Simple Definition

**A network is two or more computers connected together so they can share data.**

That's it. That's networking.

---

### How Are They Connected?

**Three main ways:**

#### 1. Ethernet (Wired)

```
[Computer A] ──cable── [Computer B]
```

**Physical medium:** Copper cable (electrical signals)  
**Speed:** Fast (1 Gbps - 100 Gbps)  
**Range:** Up to 100 meters per cable  
**Use case:** Office networks, data centers, your home router

---

#### 2. WiFi (Wireless)

```
[Laptop] ~~~radio waves~~~ [Router]
```

**Physical medium:** Radio waves (electromagnetic signals)  
**Speed:** Medium (100 Mbps - 1 Gbps)  
**Range:** Up to 100 meters  
**Use case:** Homes, coffee shops, airports

---

#### 3. Fiber Optic

```
[Data Center A] ──fiber cable── [Data Center B]
```

**Physical medium:** Glass fiber (light signals)  
**Speed:** Very fast (10 Gbps - 400 Gbps)  
**Range:** Up to 100 kilometers (or across oceans!)  
**Use case:** Internet backbone, submarine cables, data centers

---

### Network Sizes (Scope)

Networks come in different sizes:

| Type | Name | Scope | Example |
|------|------|-------|---------|
| **LAN** | Local Area Network | One building/floor | Your home WiFi, office network |
| **WAN** | Wide Area Network | Multiple cities/countries | The Internet, corporate networks across offices |

**Key distinction:**
- **LAN:** All devices can talk directly (same physical location)
- **WAN:** Devices need intermediate connections (different locations)

---

## The Internet's Physical Reality

### What Is "The Internet"?

**The internet is NOT in the sky.**  
**The internet is NOT "the cloud."**  

**The internet is:**
- Millions of smaller networks connected together
- Physical cables (lots of them)
- Computers forwarding data between networks

---

### The Physical Infrastructure

#### Submarine Cables (The Backbone)

**Right now, at the bottom of the ocean:**

```
North America ←──────fiber cable──────→ Europe
                 (across Atlantic Ocean)

Asia ←──────fiber cable──────→ North America
              (across Pacific Ocean)
```

**Facts:**
- Over 400 submarine cables connect continents
- These cables are the size of a garden hose
- They carry 99% of international internet traffic
- If cut, entire regions lose connectivity

**You can see them:** [https://www.submarinecablemap.com/](https://www.submarinecablemap.com/)

---

#### Data Centers

**Where websites and cloud services actually live:**

```
Google has data centers in:
- Iowa, USA
- Finland
- Singapore
- ... and many more

When you Google something:
Your request goes to the nearest data center
```

**These are PHYSICAL buildings** with:
- Thousands of computers (servers)
- Cooling systems (computers generate heat)
- Backup power (can't go offline)
- Security (valuable data)

**"The cloud" = someone else's computer in a data center.**

---

#### Internet Service Providers (ISPs)

**Your bridge to the internet:**

```
Your home ←─cable─→ ISP ←─fiber─→ Internet backbone
```

**Examples:**
- USA: AT&T, Comcast, Verizon
- India: Airtel, Jio, BSNL  
- UK: BT, Sky, Virgin Media

**What ISPs do:**
- Connect your home to their network
- Provide a public IP address (more on this later)
- Route your traffic to the rest of the internet
- You pay them monthly for this service

---

### Mental Model: The Internet

```
┌────────────────────────────────────────────────┐
│           YOUR HOME NETWORK (LAN)              │
│                                                │
│  [Laptop] [Phone] [Smart TV]                   │
│       │      │        │                        │
│       └──────┴────────┘                        │
│              │                                 │
│         [Router]                               │
└──────────────┼─────────────────────────────────┘
               │
        (Cable/Fiber)
               │
┌──────────────▼─────────────────────────────────┐
│          ISP NETWORK                           │
│  (Connects you to backbone)                    │
└──────────────┬─────────────────────────────────┘
               │
        (Fiber optics)
               │
┌──────────────▼─────────────────────────────────┐
│        INTERNET BACKBONE                       │
│  (Submarine cables, major routers)             │
└──────────────┬─────────────────────────────────┘
               │
        ┌──────┴──────────┐
        │                 │
┌───────▼───────┐ ┌───────▼────────┐
│ Google Servers│ │ AWS Data Center│
│ (California)  │ │ (Virginia)     │
└───────────────┘ └────────────────┘
```

**The internet = all of these networks connected.**

---

## What Is Data? (Introducing Packets)

### The Fundamental Concept

**When you send data over a network, it doesn't travel as one big file.**

**It travels as small chunks called PACKETS.**

---

### Why Packets Exist

**Scenario: You want to download a 10 MB video**

**Option 1: Send as one big file**
```
[10 MB file] ────────→ [Your computer]

Problem:
- Takes a long time (blocks everything else)
- If connection breaks mid-transfer, start over
- No other data can use the network
```

**Option 2: Break into packets (what actually happens)**
```
10 MB video = 7,000 packets (each ~1,500 bytes)

Packet 1 ──→
Packet 2 ──→
Packet 3 ──→
... (thousands more)
Packet 7,000 ──→

Benefits:
- Packets can take different routes (faster)
- If one packet fails, only resend that packet
- Multiple users can share the network
- Packets arrive and reassemble at destination
```

---

### What a Packet Looks Like (Simplified)

**Every packet has two parts:**

```
┌─────────────────────────────────────────┐
│           PACKET                        │
│                                         │
│  ┌──────────────────────────────────┐   │
│  │ HEADER (Metadata)                │   │
│  │                                  │   │
│  │ - Where it's going (destination) │   │
│  │ - Where it came from (source)    │   │
│  │ - Packet number (for ordering)   │   │
│  │ - Other control info             │   │
│  └──────────────────────────────────┘   │
│                                         │
│  ┌──────────────────────────────────┐   │
│  │ PAYLOAD (Actual Data)            │   │
│  │                                  │   │
│  │ Part of your video, email, etc.  │   │
│  └──────────────────────────────────┘   │
│                                         │
└─────────────────────────────────────────┘
```

**Analogy: Packets = letters in an envelope**

```
Envelope (header):
- To: 123 Main St (destination)
- From: 456 Oak Ave (source)
- Stamp (delivery info)

Letter inside (payload):
- Your actual message
```

---

### Real Example: Sending an Email

**You send email: "Hello, how are you?"**

```
Email gets broken into packets:

Packet 1:
  Header: To: mail server, From: you, Packet 1 of 3
  Payload: "Hello, "

Packet 2:
  Header: To: mail server, From: you, Packet 2 of 3
  Payload: "how are "

Packet 3:
  Header: To: mail server, From: you, Packet 3 of 3
  Payload: "you?"

Mail server receives all 3 packets
Reassembles: "Hello, how are you?"
```

**This is how ALL data travels on networks.**

- Websites → broken into packets
- Videos → broken into packets  
- File uploads → broken into packets
- Everything → packets

---

## The Secret: Everything Is Layers

### The Core Insight That Makes Networking Make Sense

**Networking is not one thing.**  
**Networking is LAYERS working together.**

Each layer has a specific job.  
Each layer builds on the layer below it.

**This is the most important concept in networking.**

---

### The Envelope Analogy

**Imagine sending a package:**

```
Step 1: Write a letter (your data)

Step 2: Put letter in envelope (add destination address)

Step 3: Put envelope in box (add shipping label)

Step 4: Give box to delivery driver (physical transport)
```

**Each step wraps the previous step.**

**This is exactly how networking works.**

---

### How Data Actually Travels (Layer by Layer)

**You type google.com in your browser:**

```
Layer 7 (Application):
  Your browser creates HTTP request:
  "GET / HTTP/1.1
   Host: google.com"

        ↓ Wraps ↓

Layer 4 (Transport):
  Adds TCP header:
  - Source port: 54321
  - Destination port: 443 (HTTPS)
  
        ↓ Wraps ↓

Layer 3 (Network):
  Adds IP header:
  - Source IP: Your laptop's IP
  - Destination IP: Google's server IP
  
        ↓ Wraps ↓

Layer 2 (Data Link):
  Adds Ethernet header:
  - Source MAC: Your network card
  - Destination MAC: Router
  
        ↓ Wraps ↓

Layer 1 (Physical):
  Converts to electrical/radio signals
  Transmits over cable/WiFi
```

---

### The Russian Nesting Doll Visual

**Each layer wraps the previous layer like a nesting doll:**

```
┌──────────────────────────────────────────────────────┐
│ Ethernet Frame (Layer 2)                             │
│                                                      │
│  ┌────────────────────────────────────────────────┐  │
│  │ IP Packet (Layer 3)                            │  │
│  │                                                │  │
│  │  ┌──────────────────────────────────────────┐  │  │
│  │  │ TCP Segment (Layer 4)                    │  │  │
│  │  │                                          │  │  │
│  │  │  ┌────────────────────────────────────┐  │  │  │
│  │  │  │ HTTP Request (Layer 7)             │  │  │  │
│  │  │  │                                    │  │  │  │
│  │  │  │ "GET /index.html HTTP/1.1"         │  │  │  │
│  │  │  │                                    │  │  │  │
│  │  │  └────────────────────────────────────┘  │  │  │
│  │  │                                          │  │  │
│  │  └──────────────────────────────────────────┘  │  │
│  │                                                │  │
│  └────────────────────────────────────────────────┘  │
│                                                      │
└──────────────────────────────────────────────────────┘
```

**This wrapping process is called ENCAPSULATION.**

**It's the fundamental mechanism of how networking works.**

---

### Why Layers Matter

**Each layer solves a different problem:**

| Layer | Problem It Solves | Example |
|-------|------------------|---------|
| **Physical** | How do we transmit bits? | Cables, WiFi radio |
| **Data Link** | How do we deliver data locally? | Ethernet, MAC addresses |
| **Network** | How do we reach different networks? | IP addresses, routing |
| **Transport** | How do we ensure reliable delivery? | TCP (guaranteed), UDP (fast) |
| **Application** | What does the data mean? | HTTP (web), SMTP (email) |

**Without layers:**
- Every application would need to know about cables
- Every cable type would need different software
- Chaos

**With layers:**
- Applications just send data (don't care about cables)
- Physical layer just transmits bits (doesn't care about apps)
- Clean separation

---

## The OSI Model — Your Map

### What Is OSI?

**OSI = Open Systems Interconnection**

It's a framework that organizes networking into 7 layers.

**Think of it as a MAP of the networking world.**

You don't need to memorize every detail now. You just need to know the map exists.

---

### The 7 Layers

```
┌─────────────────────────────────────────────┐
│  Layer 7: Application                       │
│  What: User-facing protocols                │
│  Examples: HTTP, DNS, SSH, FTP              │
│  Your browser/apps live here                │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│  Layer 6: Presentation                      │
│  What: Data formatting, encryption          │
│  Examples: SSL/TLS, JPEG, encryption        │
│  Makes data readable/secure                 │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│  Layer 5: Session                           │
│  What: Manages connections                  │
│  Examples: Session control                  │
│  Keeps conversations organized              │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│  Layer 4: Transport                         │
│  What: Reliability, ports                   │
│  Examples: TCP (reliable), UDP (fast)       │
│  Adds port numbers to identify apps         │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│  Layer 3: Network                           │
│  What: IP addressing, routing               │
│  Examples: IP, routers, subnets             │
│  Gets packets to correct network            │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│  Layer 2: Data Link                         │
│  What: Local delivery                       │
│  Examples: Ethernet, WiFi, MAC addresses    │
│  Delivers within one network segment        │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│  Layer 1: Physical                          │
│  What: Physical transmission                │
│  Examples: Cables, WiFi radio, fiber        │
│  Actual 1s and 0s transmitted               │
└─────────────────────────────────────────────┘
```

---

### How to Remember the Layers

**Mnemonic (top to bottom):**
```
All People Seem To Need Data Processing

Application
Presentation
Session
Transport
Network
Data Link
Physical
```

**Or (bottom to top):**
```
Please Do Not Throw Sausage Pizza Away

Physical
Data Link
Network
Transport
Session
Presentation
Application
```

---

### Which Layers Matter for DevOps?

**You'll spend 90% of your time in these layers:**

- ⭐ **Layer 7 (Application):** HTTP, HTTPS, DNS, SSH — what users interact with
- ⭐ **Layer 4 (Transport):** TCP/UDP, ports — reliability and app identification  
- ⭐ **Layer 3 (Network):** IP addresses, routing, subnets — how packets get places

**Less often:**
- **Layer 2 (Data Link):** Mostly abstracted in cloud environments
- **Layers 5-6:** Handled automatically (TLS encryption, etc.)
- **Layer 1 (Physical):** Cloud provider handles this

---

### Real Example: Opening a Website

**When you visit google.com, here's what happens at each layer:**

```
Layer 7 (Application):
  Browser creates HTTP request
  
Layer 6 (Presentation):
  HTTPS encrypts the request (TLS)
  
Layer 5 (Session):
  Maintains connection to server
  
Layer 4 (Transport):
  TCP ensures data arrives correctly
  Port 443 identifies HTTPS service
  
Layer 3 (Network):
  IP routing finds Google's server
  
Layer 2 (Data Link):
  Ethernet/WiFi delivers to router locally
  
Layer 1 (Physical):
  Electrical signals travel through cable/WiFi
```

**Each layer does its job.**  
**Together, they get you the webpage.**

---

## The Mental Model That Makes Everything Click

### Three Core Questions Every Packet Answers

When data travels across a network, it needs to answer three questions:

```
1. WHERE AM I GOING?
   (Destination address)

2. WHO DO I GIVE THIS TO NEXT?
   (Next hop)

3. WHAT SERVICE AM I FOR?
   (Application identification)
```

**Different layers answer different questions:**

| Question | Layer | Technology |
|----------|-------|-----------|
| **Where am I going ultimately?** | Layer 3 | IP address (final destination) |
| **Who do I give this to next?** | Layer 2 | MAC address (next hop only) |
| **What service am I for?** | Layer 4 | Port number (HTTP, SSH, etc.) |

**This is the foundation of all networking.**

---

### The Journey of a Packet (Simple View)

**You send email from New York to London:**

```
Your laptop (New York):
  "I need to send data to email server in London"
  
Step 1: Check IP address
  Destination: 203.0.113.50 (London server)
  
Step 2: Not on my local network
  Send to router (next hop)
  
Step 3: Router checks
  "203.0.113.50 is in London"
  Forward to next router toward London
  
(Packet hops through 10-20 routers)

Step 4: Final router in London
  "203.0.113.50 is directly connected"
  Deliver to email server
  
Email server:
  "Packet is for port 25 (email service)"
  Deliver to email application
```

**At each step:**
- IP address stayed the same (final destination)
- Local delivery address changed (next hop)
- Port stayed the same (email service)

**This is networking.**

---

## Final Compression

### What You Learned

✅ **Networking = computers connected to share data**  
✅ **The internet = millions of networks connected physically**  
✅ **Data travels as packets** (small chunks, not big files)  
✅ **Layers wrap data** (encapsulation, like Russian nesting dolls)  
✅ **OSI model = the map** (7 layers, each with a job)  

---

### The One Diagram You Need

```
Application (HTTP, DNS)
    ↓
Transport (TCP/UDP, Ports)
    ↓
Network (IP, Routing)
    ↓
Data Link (MAC, Ethernet)
    ↓
Physical (Cables, WiFi)

Each layer wraps the one above it.
Each layer serves the one above it.
```

---

### Three Core Truths

```
1. Packets = How data actually travels
   (Not continuous streams, but chunks)

2. Encapsulation = How layers work together
   (Each layer wraps the previous)

3. Addressing = How packets find their way
   (IP = destination, MAC = next hop, Port = service)
```

---

### The Big Picture

```
You (typing google.com)
    ↓
Packets created (with layers wrapped)
    ↓
Travel through routers (across the world)
    ↓
Reach Google's server (layers unwrapped)
    ↓
Google responds (new packets created)
    ↓
Travel back to you (same process in reverse)
    ↓
Your browser displays webpage

Every step follows the same principles:
- Encapsulation (layers)
- Addressing (IP, MAC, Port)
- Routing (next hop decisions)
```

**This is networking.**  
**Everything else is details.**

---

## What This Means for the Webstore

The webstore is three processes on a Linux server — nginx on port 80, the API on port 8080, and postgres on port 5432. When a browser requests the webstore homepage, it sends a packet. That packet has a header at every layer: application (HTTP GET /), transport (TCP, destination port 80), network (the server's IP address), data link (MAC address of the next router hop). Each layer does exactly one job and hands off to the next. The webstore receives the request, nginx processes it, and the response travels back through the same stack in reverse. Everything in this series explains one piece of that journey.

---

→ **Interview questions for this topic:** [99-interview-prep → OSI Model · Layers · Encapsulation](../99-interview-prep/README.md#osi-model--layers--encapsulation)

→ Ready to practice? [Go to Lab 01](../networking-labs/01-foundation-addressing-ip-lab.md)

---
# SOURCE: 03. Networking – Foundations/02-addressing-fundamentals/README.md
---

# File 02: Addressing Fundamentals

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

# Addressing Fundamentals

## What this file is about

This file teaches **how devices identify each other on networks**. If you understand this, you'll know why both MAC addresses and IP addresses exist, how they work together, and how a device discovers another device's physical address (ARP). This is the foundation for everything else in networking.

<!-- no toc -->
- [The Core Problem](#the-core-problem)
- [Two Types of Addresses (And Why Both Exist)](#two-types-of-addresses-and-why-both-exist)
- [MAC Addresses (Physical Identity)](#mac-addresses-physical-identity)
- [IP Addresses (Logical Identity)](#ip-addresses-logical-identity)
- [Why Both? The Critical Truth](#why-both-the-critical-truth)
- [ARP: The Missing Link](#arp-the-missing-link)
- [Private vs Public IP Addresses](#private-vs-public-ip-addresses)
- [Real Scenarios](#real-scenarios)  
[Final Compression](#final-compression)

---

## The Core Problem

### The Question

**Scenario:** Your laptop wants to send data to a printer on your home WiFi.

**Three questions your laptop must answer:**

```
1. Who am I trying to reach? (identification)
2. Where are they? (location)
3. How do I physically deliver this data to them? (delivery)
```

**This is the addressing problem.**

Without addresses, computers can't find each other.

---

### Real-World Analogy

**Sending a letter:**

```
You need:
1. Person's name ("John Smith")
2. Street address ("123 Main St, New York")
3. Physical delivery (postal service uses address to deliver)

Without the address, the postal service can't deliver the letter.
```

**Sending data on a network:**

```
You need:
1. Device identity (what it's called)
2. Network address (where it is)
3. Physical address (how to reach it on local network)

Without addresses, data can't be delivered.
```

---

## Two Types of Addresses (And Why Both Exist)

**Networking uses TWO different types of addresses:**

```
1. MAC Address (Physical, Layer 2)
   - Permanent
   - Identifies hardware
   - Works only locally

2. IP Address (Logical, Layer 3)
   - Can change
   - Identifies device on network
   - Works globally
```

**This seems redundant. Why two addresses?**

**Short answer:** They solve different problems at different layers.

Let's understand each one, then see how they work together.

---

## MAC Addresses (Physical Identity)

### What Is a MAC Address?

**MAC = Media Access Control**

**Definition:**  
A MAC address is a **permanent hardware identifier** burned into your network card by the manufacturer.

**Format:**
```
AA:BB:CC:DD:EE:FF

6 pairs of hexadecimal digits
Separated by colons (or hyphens)
```

**Real examples:**
```
Your laptop WiFi:     A4:83:E7:2F:1B:C9
Your phone:           00:1A:2B:3C:4D:5E
Your router:          F8:1A:67:B4:32:D1
```

---

### Key Characteristics

| Property | Value |
|----------|-------|
| **Length** | 48 bits (6 bytes) |
| **Format** | 12 hexadecimal digits |
| **Uniqueness** | Globally unique (in theory) |
| **Changes?** | ❌ No — permanent (burned into hardware) |
| **Scope** | Local network only |
| **Layer** | Layer 2 (Data Link) |

---

### Who Assigns MAC Addresses?

**The manufacturer.**

When a company (like Intel, Broadcom, Realtek) makes a network card:

```
Step 1: Manufacturer gets assigned a block of MAC addresses
        from IEEE (standards organization)

Step 2: Manufacturer burns a unique MAC address into each
        network card's ROM (read-only memory)

Step 3: This MAC address never changes (permanent)
```

**You never assign MAC addresses yourself.**

---

### Where MAC Addresses Live

**Every network interface has a MAC address:**

```
Your laptop might have:
├─ WiFi card:      A4:83:E7:2F:1B:C9
├─ Ethernet port:  00:1E:C9:4A:7B:2D
└─ Bluetooth:      F0:18:98:45:AB:CD

Each interface = different MAC address
```

**Check your MAC address:**

```bash
# Linux/Mac
ip link show
# or
ifconfig

# Windows
ipconfig /all

Look for: "HWaddr", "ether", or "Physical Address"
```

---

### What MAC Addresses Look Like (Breakdown)

```
A4:83:E7:2F:1B:C9
│ │ │  │  │  │
└─┴─┴──┴──┴──┴─→ 6 bytes total

First 3 bytes (A4:83:E7):
  Organizationally Unique Identifier (OUI)
  Identifies manufacturer (e.g., Intel, Apple)

Last 3 bytes (2F:1B:C9):
  Device-specific identifier
  Unique to this specific network card
```

**You can look up manufacturers:**  
Website: [https://maclookup.app/](https://maclookup.app/)

Enter `A4:83:E7` → "Intel Corporation"

---

### What MAC Addresses Are Used For

**MAC addresses work at Layer 2 (Data Link).**

**Their job:** Deliver data to the correct device **on the local network**.

**Example:**

```
Your home WiFi network:
├─ Laptop:   MAC A4:83:E7:2F:1B:C9
├─ Phone:    MAC 00:1A:2B:3C:4D:5E
├─ Printer:  MAC F8:1A:67:B4:32:D1
└─ Router:   MAC 11:22:33:44:55:66

When laptop sends data to printer:
Ethernet frame header contains:
  Source MAC:      A4:83:E7:2F:1B:C9 (laptop)
  Destination MAC: F8:1A:67:B4:32:D1 (printer)

WiFi access point sees destination MAC
Delivers frame to printer
```

---

### Critical Limitation: MAC Addresses Only Work Locally

**MAC addresses do NOT route across networks.**

**Example:**

```
Your laptop (New York):  MAC A4:83:E7:2F:1B:C9
Google server (California): MAC XY:ZW:AB:CD:EF:12

Question: Can your laptop send data directly to Google's MAC?
Answer: ❌ NO

Why not?
- MAC addresses only work on local network
- Google is on a different network (different building, different city)
- Routers do not forward based on MAC addresses
```

**This is why we need IP addresses.**

---

## IP Addresses (Logical Identity)

### What Is an IP Address?

**IP = Internet Protocol**

**Definition:**  
An IP address is a **logical network identifier** assigned to a device. Unlike MAC addresses, IP addresses can change and work across networks.

**Format (IPv4):**
```
192.168.1.45

4 numbers (0-255)
Separated by dots
```

**Real examples:**
```
Your laptop:       192.168.1.45
Your router:       192.168.1.1
Google's server:   142.250.190.46
Your office PC:    10.0.1.100
```

---

### Key Characteristics

| Property | Value |
|----------|-------|
| **Length** | 32 bits (4 bytes) |
| **Format** | 4 decimal numbers (0-255) |
| **Uniqueness** | Unique within a network |
| **Changes?** | ✅ Yes — can be reassigned |
| **Scope** | Global (routes across networks) |
| **Layer** | Layer 3 (Network) |

---

### Who Assigns IP Addresses?

**Unlike MAC addresses, IP addresses are assigned by:**

1. **DHCP server** (automatic — covered in File 03)
2. **Network administrator** (manual — static configuration)
3. **ISP** (for your router's public IP)

**You control IP addresses** (or the network does).

---

### IP Address Structure

```
192.168.1.45
│   │   │  │
Each number = 1 byte (0-255)
Total = 4 bytes = 32 bits

Example breakdown:
192 = 11000000 (binary)
168 = 10101000 (binary)
1   = 00000001 (binary)
45  = 00101101 (binary)
```

**You don't need to know binary conversion.**  
**You just need to know each number is 0-255.**

---

### What IP Addresses Are Used For

**IP addresses work at Layer 3 (Network).**

**Their job:** Route data to the correct **network** and **device** globally.

**Example:**

```
You (New York):       IP 192.168.1.45
Google (California):  IP 142.250.190.46

Packet created:
  Source IP:      192.168.1.45
  Destination IP: 142.250.190.46

Routers across the internet read this IP
Forward packet hop by hop
Eventually reaches Google's network
Delivered to 142.250.190.46
```

**IP addresses route across the world.**

---

### The Key Difference: Scope

| Address Type | Scope | Example |
|--------------|-------|---------|
| **MAC** | Local network only (one hop) | Your laptop → Your router |
| **IP** | Global (many hops) | Your laptop → Google server |

---

## Why Both? The Critical Truth

### The Biggest Beginner Mistake

**❌ WRONG thinking:**
```
"Use MAC for local network"
"Use IP for internet"
```

**This makes it sound like they're used in different scenarios.**

**✅ CORRECT reality:**
```
MAC and IP are ALWAYS used together.
Every packet has BOTH MAC and IP headers.

They serve different purposes:
- MAC = next hop (where to send it NOW)
- IP = final destination (where it's ultimately going)
```

---

### How They Work Together

**Scenario: Your laptop (New York) wants to reach Google (California)**

**The packet contains:**

```
┌──────────────────────────────────────────┐
│ Ethernet Frame (Layer 2)                 │
│                                          │
│ Source MAC:      [Your laptop MAC]       │
│ Destination MAC: [Your router MAC]  ←───┐│
│                                      │  ││
│  ┌────────────────────────────────┐  │  ││
│  │ IP Packet (Layer 3)            │  │  ││
│  │                                │  │  ││
│  │ Source IP:      192.168.1.45   │  │  ││
│  │ Destination IP: 142.250.190.46 │←─┼──┘│
│  │                                │  │   │
│  └────────────────────────────────┘  │   │
│                                      │   │
└──────────────────────────────────────┘   │
         │                                 │
    Next hop                          Final destination
  (router MAC)                         (Google IP)
```

**Key insight:**

```
Destination MAC = Your router (next hop)
Destination IP  = Google server (final destination)

These are DIFFERENT addresses for DIFFERENT purposes.
```

---

### The Journey (Step by Step)

**Hop 1: Your laptop → Your router**

```
MAC src: Laptop MAC
MAC dst: Router MAC  ← Changes at each hop
IP src:  Laptop IP
IP dst:  Google IP   ← Stays the same
```

**Hop 2: Your router → ISP router**

```
Router strips old Ethernet frame
Reads IP destination
Creates new Ethernet frame:

MAC src: Router MAC
MAC dst: ISP router MAC  ← Changed
IP src:  Laptop IP
IP dst:  Google IP       ← Still the same
```

**Hop 3-20: Through internet routers**

```
At each router:
- Old MAC addresses discarded
- New MAC addresses added (next hop)
- IP addresses never change
```

**Final hop: Last router → Google server**

```
MAC src: Last router MAC
MAC dst: Google server MAC  ← Changed again
IP src:  Laptop IP
IP dst:  Google IP          ← Still the same
```

---

### Visual: MAC Changes, IP Stays

```
Your Laptop (New York)
  MAC: AA:AA:AA:AA:AA:AA
  IP:  192.168.1.45
      │
      ├─ Packet 1 ────────────────────┐
      │  MAC src: AA:AA:AA:AA:AA:AA   │
      │  MAC dst: 11:11:11:11:11:11   │ (Router)
      │  IP src:  192.168.1.45        │
      │  IP dst:  142.250.190.46      │
      │                               │
      ▼                               │
Your Router                           │
  MAC: 11:11:11:11:11:11              │
      │                               │
      ├─ Packet 2 ────────────────────┤
      │  MAC src: 11:11:11:11:11:11   │ (Router)
      │  MAC dst: 22:22:22:22:22:22   │ (ISP router)
      │  IP src:  192.168.1.45    ←───┼─ Same!
      │  IP dst:  142.250.190.46  ←───┼─ Same!
      │                               │
      ▼                               │
ISP Router                            │
  MAC: 22:22:22:22:22:22              │
      │                               │
      ... (10 more hops) ...          │
      │                               │
      ▼                               │
Google Server (California)            │
  MAC: BB:BB:BB:BB:BB:BB              │
  IP:  142.250.190.46                 │
      │                               │
      Final packet: ──────────────────┘
        MAC src: 99:99:99:99:99:99   (Last router)
        MAC dst: BB:BB:BB:BB:BB:BB   (Google)
        IP src:  192.168.1.45    ←─── Still the same!
        IP dst:  142.250.190.46  ←─── Still the same!
```

**The rule:**

```
MAC addresses: Change at every hop (local delivery)
IP addresses:  Never change (end-to-end identifier)
```

---

### Why This Design?

**MAC addresses (Layer 2):**
- Simple, fast lookup
- Works on local network segment
- No routing needed
- Hardware-based

**IP addresses (Layer 3):**
- Hierarchical (networks and hosts)
- Routes across multiple networks
- Flexible assignment
- Software-based

**Together:**
- MAC handles local delivery (this network segment)
- IP handles global routing (across networks)

**Analogy:**

```
Sending a package from New York to Los Angeles:

IP address = Final destination address
             "123 Main St, Los Angeles, CA"
             (Stays on package the entire journey)

MAC address = Current delivery truck
              "Truck A" → "Truck B" → "Truck C"
              (Changes at each distribution center)
```

---

## ARP: The Missing Link

### The Problem

**Your laptop knows:**
- Destination IP: 192.168.1.50 (printer)

**Your laptop needs:**
- Destination MAC: ??? 

**How does your laptop discover the printer's MAC address from its IP address?**

---

### The Solution: ARP (Address Resolution Protocol)

**ARP = IP to MAC translation**

**ARP answers the question:**  
"I know the IP address. What's the MAC address?"

---

### How ARP Works (Step by Step)

**Scenario:** Your laptop (192.168.1.45) wants to send data to printer (192.168.1.50)

**Step 1: Check ARP cache**

```bash
# Your laptop checks its ARP cache first
arp -a

Output:
  192.168.1.1    at  11:22:33:44:55:66  (router)
  # Printer not in cache
```

**Step 2: Send ARP request (broadcast)**

```
Your laptop broadcasts to everyone on local network:

ARP Request:
  "Who has IP 192.168.1.50?"
  "Please tell 192.168.1.45 (MAC AA:AA:AA:AA:AA:AA)"

This is sent to broadcast MAC: FF:FF:FF:FF:FF:FF
(Everyone on network receives this)
```

**Step 3: Only printer responds**

```
Printer checks:
  "Do I have IP 192.168.1.50?" → YES

Printer sends ARP reply (unicast, only to laptop):
  "192.168.1.50 is at MAC F8:1A:67:B4:32:D1"
```

**Step 4: Laptop caches the result**

```bash
# Laptop adds to ARP cache
arp -a

Output:
  192.168.1.1    at  11:22:33:44:55:66
  192.168.1.50   at  F8:1A:67:B4:32:D1  ← New entry!
```

**Step 5: Laptop can now send data**

```
Laptop creates Ethernet frame:
  Source MAC:      AA:AA:AA:AA:AA:AA (laptop)
  Destination MAC: F8:1A:67:B4:32:D1 (printer)
  
  IP Packet inside:
    Source IP:      192.168.1.45
    Destination IP: 192.168.1.50

Sends to printer
```

---

### ARP Cache (Performance Optimization)

**Why cache?**

Doing ARP for every packet would be slow:
- Broadcast request
- Wait for response
- Then send data

**Solution: Cache the result**

```bash
# Linux/Mac
arp -a

Output:
Address           HWtype  HWaddress            Flags
192.168.1.1       ether   11:22:33:44:55:66    C
192.168.1.50      ether   F8:1A:67:B4:32:D1    C

Cached for ~5-20 minutes (timeout varies)
```

**Next time you send to 192.168.1.50:**
- Check cache → Found!
- Use cached MAC address
- No ARP request needed

---

### ARP Workflow (Visual)

```
┌──────────────────────────────────────────────────┐
│  Laptop wants to send to 192.168.1.50           │
└──────────────────┬───────────────────────────────┘
                   │
                   ▼
         ┌─────────────────────┐
         │ Check ARP cache     │
         │ "Do I know the MAC?"│
         └─────────┬───────────┘
                   │
         ┌─────────┴─────────┐
         │                   │
      Found                Not found
         │                   │
         ▼                   ▼
    ┌─────────┐      ┌──────────────────┐
    │ Use it  │      │ Send ARP request │
    │         │      │ (broadcast)      │
    └─────────┘      └────────┬─────────┘
                              │
                              ▼
                     ┌─────────────────┐
                     │ Receive ARP     │
                     │ reply           │
                     └────────┬────────┘
                              │
                              ▼
                     ┌─────────────────┐
                     │ Cache result    │
                     │ Use MAC address │
                     └─────────────────┘
```

---

### Why ARP Matters

**Without ARP:**
- You'd need to manually configure MAC addresses for every device
- Doesn't scale
- Breaks when devices change

**With ARP:**
- Automatic discovery
- Works dynamically
- Scales to any network size

**DevOps reality:**
- ARP happens automatically (you never think about it)
- But when debugging network issues, ARP failures can cause problems
- Knowing ARP exists helps debug "device unreachable" errors

---

## Private vs Public IP Addresses

### Two Categories of IP Addresses

**Not all IP addresses are created equal.**

IP addresses are divided into:

1. **Private IP addresses** — Cannot route on the internet
2. **Public IP addresses** — Can route globally

---

### Private IP Addresses

**Definition:**  
IP addresses reserved for use inside private networks (homes, offices, data centers).

**Three private IP ranges (memorize these):**

| Range | CIDR Notation | Total IPs | Typical Use |
|-------|---------------|-----------|-------------|
| 10.0.0.0 - 10.255.255.255 | 10.0.0.0/8 | 16,777,216 | Large enterprises, AWS VPCs |
| 172.16.0.0 - 172.31.255.255 | 172.16.0.0/12 | 1,048,576 | Medium networks, Docker default |
| 192.168.0.0 - 192.168.255.255 | 192.168.0.0/16 | 65,536 | Home networks, small offices |

**Key characteristics:**

```
✅ Free to use (no registration needed)
✅ Reusable (every home can use 192.168.1.X)
✅ Not unique globally
❌ Cannot route on the internet
❌ Need NAT to access internet (covered in File 07)
```

---

### Public IP Addresses

**Definition:**  
All IP addresses that are NOT in the private ranges.

**Key characteristics:**

```
✅ Globally unique (only one device has this IP worldwide)
✅ Routable on the internet (can be reached from anywhere)
✅ Assigned by ISPs and regional registries
❌ Cost money (limited supply)
❌ Must be registered
```

**Examples:**
```
Google:         142.250.190.46 (public)
Your ISP:       203.45.67.89 (public, assigned to your router)
AWS EC2:        54.123.45.67 (public, Elastic IP)
```

---

### Why Private IPs Exist

**The math problem:**

```
IPv4 total addresses:  ~4.3 billion
Devices on internet:   ~20+ billion

Problem: Not enough addresses!
```

**Solution:**

```
Most devices use private IPs (inside networks)
Only routers/gateways need public IPs (facing internet)
NAT lets many private IPs share one public IP
```

**Example:**

```
Your home:
├─ Laptop:  192.168.1.45 (private)
├─ Phone:   192.168.1.67 (private)
├─ Tablet:  192.168.1.89 (private)
└─ Router:  203.45.67.89 (public, from ISP)

All 3 devices share 1 public IP via NAT.
```

---

### How to Identify Private vs Public

**Simple rule:**

```
Is the IP in one of these ranges?
- 10.0.0.0 - 10.255.255.255
- 172.16.0.0 - 172.31.255.255
- 192.168.0.0 - 192.168.255.255

YES → Private IP
NO  → Public IP
```

**Examples:**

| IP Address | Type | Why |
|------------|------|-----|
| 192.168.1.45 | Private | In 192.168.0.0/16 range |
| 10.0.1.100 | Private | In 10.0.0.0/8 range |
| 172.16.5.25 | Private | In 172.16.0.0/12 range |
| 142.250.190.46 | Public | Not in any private range |
| 8.8.8.8 | Public | Not in any private range |
| 172.32.0.1 | Public | Outside 172.16-31 range |

---

### Special IP Addresses

**Some IPs have special meanings:**

| IP Address | Name | Meaning |
|------------|------|---------|
| 127.0.0.1 | Localhost | This device (loopback) |
| 0.0.0.0 | Default route | All addresses |
| 255.255.255.255 | Broadcast | Everyone on local network |
| 169.254.X.X | Link-local | Auto-assigned (no DHCP) |

**Localhost (127.0.0.1):**

```
Always means "this machine I'm on right now"

On your laptop:     127.0.0.1 = your laptop
In a container:     127.0.0.1 = that container (not host!)
On AWS EC2:         127.0.0.1 = that EC2 instance

Never crosses network boundaries.
```

---

## Real Scenarios

### Scenario 1: Home Network

**Your home setup:**

```
┌─────────────────────────────────────────┐
│  Your Home (Private Network)            │
│                                         │
│  Laptop:                                │
│    MAC: A4:83:E7:2F:1B:C9               │
│    IP:  192.168.1.45 (private)          │
│                                         │
│  Phone:                                 │
│    MAC: 00:1A:2B:3C:4D:5E               │
│    IP:  192.168.1.67 (private)          │
│                                         │
│  Router (LAN side):                     │
│    MAC: 11:22:33:44:55:66               │
│    IP:  192.168.1.1 (private)           │
│                                         │
└─────────────────┬───────────────────────┘
                  │
        (Cable/Fiber to ISP)
                  │
┌─────────────────▼───────────────────────┐
│  Router (WAN side):                     │
│    MAC: AA:BB:CC:DD:EE:FF               │
│    IP:  203.45.67.89 (public, from ISP) │
└─────────────────────────────────────────┘
```

**When laptop accesses google.com:**

```
Inside home network:
  Laptop uses private IP: 192.168.1.45
  Router uses private IP (LAN side): 192.168.1.1

Outside (internet):
  Router uses public IP: 203.45.67.89
  Google sees this public IP (not laptop's private IP)

NAT makes this work (covered in File 07)
```

---

### Scenario 2: AWS EC2 Instance

**AWS instance addressing:**

```
EC2 Instance:
├─ Private IP:  10.0.1.25 (inside VPC)
│    Purpose: Communication within VPC
│    Never changes (static)
│
├─ Public IP:   54.123.45.67 (optional)
│    Purpose: Internet access
│    Changes when instance stops/starts
│
└─ MAC Address: 0A:12:34:56:78:9A
     Purpose: VPC internal networking
     AWS manages this
```

**Traffic flows:**

```
Instance → Another instance in same VPC:
  Uses private IPs (10.0.1.25 → 10.0.2.30)
  Stays inside VPC, never touches internet

Instance → Internet:
  Uses public IP (54.123.45.67)
  Or uses NAT Gateway if in private subnet
```

> **Docker implementation:** The same MAC and IP addressing concepts apply inside Docker networks. Each container gets its own MAC and IP, communicating via a virtual bridge exactly like a physical LAN.
> → [Docker Networking](../../04.%20Docker%20–%20Containerization/05-docker-networking/README.md)

---

## Final Compression

### The Two Address Systems

**MAC Address (Physical, Layer 2):**
```
✅ Permanent (burned into hardware)
✅ 48 bits (6 bytes), hex format: AA:BB:CC:DD:EE:FF
✅ Manufacturer assigned
✅ Local network only (one hop)
✅ Changes at every router hop
```

**IP Address (Logical, Layer 3):**
```
✅ Configurable (can change)
✅ 32 bits (4 bytes), decimal format: 192.168.1.45
✅ Network assigned (DHCP or manual)
✅ Global routing (many hops)
✅ Never changes during packet journey
```

---

### How They Work Together

**CRITICAL: Every packet has BOTH MAC and IP headers.**

```
MAC header:
  Source MAC:      [Your device]
  Destination MAC: [Next hop] ← Changes at each router

IP header:
  Source IP:       [Your device]
  Destination IP:  [Final destination] ← Never changes
```

**The rule:**

```
IP address = Where the packet is ultimately going
MAC address = Where to send it right now (next hop)
```

---

### ARP: The Translator

**ARP translates IP → MAC (on local network only)**

```
1. You know destination IP
2. You need destination MAC
3. Send ARP request (broadcast): "Who has this IP?"
4. Device responds: "I do, here's my MAC"
5. Cache result
6. Send data using MAC address
```

---

### Private vs Public IPs

**Private IP ranges (memorize):**
```
10.0.0.0 - 10.255.255.255      (10.0.0.0/8)
172.16.0.0 - 172.31.255.255    (172.16.0.0/12)
192.168.0.0 - 192.168.255.255  (192.168.0.0/16)

- Free to use
- Not internet-routable
- Need NAT for internet access
```

**Public IPs:**
```
Everything else

- Globally unique
- Internet-routable
- Costs money
```

---

### Mental Model

```
Sending data from New York to Los Angeles:

IP Address = Delivery address on package
            "123 Main St, Los Angeles, CA"
            Never changes during journey

MAC Address = Current truck/carrier
             Truck A → Truck B → Truck C
             Changes at each distribution center

ARP = Looking up "Who's driving truck to this address?"
```

---

### What You Can Do Now

✅ Understand why both MAC and IP exist  
✅ Know how ARP works (IP → MAC translation)  
✅ Identify private vs public IP addresses  
✅ Understand addressing in home networks and AWS  
✅ Know that MAC changes at each hop, IP doesn't  

---

---

## What This Means for the Webstore

The webstore server has one IP address. Every service on that server shares it. What separates them is ports: nginx answers on port 80, the API on port 8080, postgres on port 5432. When the webstore-api connects to postgres, it connects to the server's own IP at port 5432 — not necessarily `localhost`, because postgres is configured with `listen_addresses` that controls which interfaces it binds to. When postgres is set to `127.0.0.1` only, the API can reach it from the same machine. When postgres is set to `0.0.0.0`, it is reachable from any interface including external ones. Reading an IP binding tells you immediately whether a service is reachable from outside or locked to the machine.

---

→ **Interview questions for this topic:** [99-interview-prep → MAC vs IP · ARP · Addressing](../99-interview-prep/README.md#mac-vs-ip--arp--addressing)

→ Ready to practice? [Go to Lab 01](../networking-labs/01-foundation-addressing-ip-lab.md)

---
# SOURCE: 03. Networking – Foundations/03-ip-deep-dive/README.md
---

# File 03: IP Deep Dive & Assignment

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

# IP Deep Dive & Assignment

## What this file is about

This file teaches **how devices get IP addresses** and **why your IP keeps changing**. If you understand this, you'll know how DHCP works, the difference between static and dynamic IPs, and when to use each type. This is essential for configuring networks correctly.

<!-- no toc -->
- [The Core Problem](#the-core-problem)
- [IPv4 Address Structure](#ipv4-address-structure)
- [How Do Devices Get IP Addresses?](#how-do-devices-get-ip-addresses)
- [DHCP: Automatic IP Assignment](#dhcp-automatic-ip-assignment)
- [Why Your IP Address Keeps Changing](#why-your-ip-address-keeps-changing)
- [Static vs Dynamic IPs](#static-vs-dynamic-ips)
- [DHCP Reservation (Best of Both Worlds)](#dhcp-reservation-best-of-both-worlds)
- [IPv4 vs IPv6](#ipv4-vs-ipv6)
- [Localhost (127.0.0.1)](#localhost-127001)
- [Real Scenarios](#real-scenarios)  
[Final Compression](#final-compression)

---

## The Core Problem

### Your Original Question

**"Why is my IP address always changing even with the same network?"**

This is the question that confuses most beginners.

**The short answer:**  
Your router has limited IP addresses available and assigns them temporarily using DHCP.

**Let's understand this completely.**

---

### The Scenario

**Your home WiFi network:**

```
Router has 254 usable IP addresses:
  192.168.1.1 - 192.168.1.254

Devices that connect over time:
  Your laptop
  Your phone
  Your tablet
  Guest's laptop
  Guest's phone
  Smart TV
  IoT devices
  ... (maybe 50+ devices over a week)

Problem: More devices than available IPs if all stayed connected
```

**The question:**  
How does the router manage this?

**The answer:**  
DHCP leases IPs temporarily, then reuses them.

---

## IPv4 Address Structure

### The Format

**IPv4 = Internet Protocol version 4**

```
192.168.1.45
│   │   │  │
│   │   │  └─ Host ID (device identifier)
│   │   └──── Network ID
│   └──────── Network ID
└──────────── Network ID

Total: 4 octets (bytes)
Each octet: 0-255
Total bits: 32 bits
```

---

### Understanding the Numbers

**Each octet is 8 bits:**

```
192.168.1.45

192 = 11000000 (binary)
168 = 10101000 (binary)
1   = 00000001 (binary)
45  = 00101101 (binary)

Combined = 32 bits total
```

**You don't need to memorize binary.**  
**Just know:** Each number is 0-255, total is 32 bits.

---

### Total Possible IPv4 Addresses

**Math:**

```
4 octets × 8 bits each = 32 bits total
2^32 = 4,294,967,296 possible addresses

~4.3 billion IPv4 addresses exist
```

**The problem:**

```
World population: ~8 billion people
Devices: ~20+ billion (phones, laptops, IoT, servers)

Not enough IPv4 addresses for every device!
```

**Solutions:**
1. Private IP addresses (reusable, not unique globally)
2. NAT (many devices share one public IP)
3. IPv6 (new protocol with more addresses — covered later)

---

### IP Address Classes (Legacy Concept)

**Old system (before CIDR):**

Networks were divided into classes:

| Class | Range | Default Mask | Use |
|-------|-------|--------------|-----|
| A | 1.0.0.0 - 126.255.255.255 | 255.0.0.0 | Very large networks |
| B | 128.0.0.0 - 191.255.255.255 | 255.255.0.0 | Medium networks |
| C | 192.0.0.0 - 223.255.255.255 | 255.255.255.0 | Small networks |
| D | 224.0.0.0 - 239.255.255.255 | N/A | Multicast |
| E | 240.0.0.0 - 255.255.255.255 | N/A | Reserved |

**This system is obsolete.**  
Modern networks use CIDR (covered in File 05).

**You don't need to memorize classes.**  
Just know they existed historically.

---

## How Do Devices Get IP Addresses?

### Three Methods

**When a device needs an IP address:**

```
Method 1: DHCP (Automatic)
  - Router/server assigns IP automatically
  - Most common for end-user devices
  - IP can change

Method 2: Static (Manual)
  - Administrator configures IP manually
  - Common for servers, printers
  - IP never changes

Method 3: Link-Local (Auto-Assigned)
  - Device assigns itself 169.254.X.X
  - Fallback when DHCP fails
  - Limited functionality
```

**Let's understand each one.**

---

## DHCP: Automatic IP Assignment

### What Is DHCP?

**DHCP = Dynamic Host Configuration Protocol**

**Definition:**  
DHCP is a network service that automatically assigns IP addresses to devices.

**Why it exists:**  
Manually configuring every device doesn't scale.

---

### DHCP Components

**Three parts:**

```
1. DHCP Server
   - Runs on router (home networks)
   - Runs on dedicated server (enterprise)
   - Manages IP address pool

2. DHCP Client
   - Your laptop, phone, etc.
   - Requests IP address
   - Built into operating system

3. IP Address Pool
   - Range of available IPs
   - Example: 192.168.1.100 - 192.168.1.200
   - Server assigns from this pool
```

---

### How DHCP Works (The DORA Process)

**DHCP uses a 4-step process called DORA:**

```
D = Discover
O = Offer
R = Request
A = Acknowledge
```

**Step-by-step:**

---

#### Step 1: DHCP Discover (Broadcast)

**Your laptop boots up and connects to WiFi:**

```
Your laptop (no IP yet):
  "I need an IP address!"
  
Broadcasts DHCP Discover message:
  Source IP:      0.0.0.0 (doesn't have one yet)
  Destination IP: 255.255.255.255 (broadcast - everyone)
  MAC src:        [Your laptop MAC]
  MAC dst:        FF:FF:FF:FF:FF:FF (broadcast)
  
Message: "DHCP DISCOVER - I need an IP!"
```

**Everyone on network receives this, including router.**

---

#### Step 2: DHCP Offer (Unicast)

**Router (DHCP server) responds:**

```
Router checks:
  Available IP pool: 192.168.1.100 - 192.168.1.200
  192.168.1.145 is available
  
Router sends DHCP Offer:
  Source IP:      192.168.1.1 (router)
  Destination IP: 255.255.255.255 (still broadcast)
  MAC dst:        [Your laptop MAC] (unicast at Layer 2)
  
Message: "DHCP OFFER - You can use 192.168.1.145"
```

**Router offers an IP but hasn't assigned it yet.**

---

#### Step 3: DHCP Request (Broadcast)

**Your laptop accepts the offer:**

```
Your laptop:
  "I want to use 192.168.1.145"
  
Sends DHCP Request:
  Source IP:      0.0.0.0 (still doesn't have IP yet)
  Destination IP: 255.255.255.255 (broadcast)
  
Message: "DHCP REQUEST - I accept 192.168.1.145"
```

**Why broadcast?**  
In case multiple DHCP servers offered IPs, this tells all servers which offer was accepted.

---

#### Step 4: DHCP Acknowledge (Unicast)

**Router confirms:**

```
Router:
  Marks 192.168.1.145 as "in use"
  
Sends DHCP ACK:
  Source IP:      192.168.1.1
  Destination IP: 192.168.1.145 (now can use unicast)
  
Message: "DHCP ACK - Configuration confirmed"
  
Includes:
  - IP address:      192.168.1.145
  - Subnet mask:     255.255.255.0
  - Default gateway: 192.168.1.1 (router)
  - DNS server:      8.8.8.8 (or router's IP)
  - Lease time:      86400 seconds (24 hours)
```

**Your laptop now has a working IP configuration.**

---

### Visual: DHCP DORA Process

```
┌──────────────┐                      ┌──────────────┐
│   Laptop     │                      │    Router    │
│ (DHCP Client)│                      │(DHCP Server) │
└──────┬───────┘                      └──────┬───────┘
       │                                     │
       │  1. DISCOVER (broadcast)            │
       │  "I need an IP!"                    │
       ├────────────────────────────────────>│
       │                                     │
       │                                     │ Check pool
       │                                     │ 192.168.1.145 free
       │                                     │
       │  2. OFFER (unicast)                 │
       │  "Use 192.168.1.145"                │
       │<────────────────────────────────────┤
       │                                     │
       │                                     │
       │  3. REQUEST (broadcast)             │
       │  "I accept 192.168.1.145"           │
       ├────────────────────────────────────>│
       │                                     │
       │                                     │ Mark as assigned
       │                                     │
       │  4. ACK (unicast)                   │
       │  "Confirmed + config"               │
       │<────────────────────────────────────┤
       │                                     │
       ▼                                     ▼
  Configured                         IP Pool updated
  192.168.1.145                      145 = In use
```

---

### What DHCP Provides

**DHCP doesn't just give you an IP address.**  
**It provides complete network configuration:**

| Setting | Example | What It Does |
|---------|---------|--------------|
| **IP Address** | 192.168.1.145 | Your device's identity |
| **Subnet Mask** | 255.255.255.0 | Defines network range |
| **Default Gateway** | 192.168.1.1 | Router's IP (exit to internet) |
| **DNS Server** | 8.8.8.8 | Where to resolve domain names |
| **Lease Time** | 86400 seconds | How long IP is valid |

**Check your DHCP-assigned config:**

```bash
# Linux
ip addr show
ip route

# Mac
ipconfig getpacket en0

# Windows
ipconfig /all
```

---

## Why Your IP Address Keeps Changing

### The Lease Concept

**DHCP doesn't give you an IP permanently.**  
**It LEASES it to you for a specific time.**

**Think of it like renting a hotel room:**

```
Hotel (DHCP Server):
  "You can stay in room 145 for 24 hours"

After 24 hours:
  You check out → Room 145 available again
  
You return:
  You might get room 145 again
  Or you might get room 212 (different room)
```

**Same with IP addresses:**

```
Router:
  "Use 192.168.1.145 for 24 hours"

After 24 hours (lease expires):
  IP goes back to available pool
  
You reconnect:
  Might get 192.168.1.145 again
  Or might get 192.168.1.167 (different IP)
```

---

### Typical Lease Times

| Network Type | Typical Lease Time | Why |
|--------------|-------------------|-----|
| **Home WiFi** | 24 hours | Devices come and go daily |
| **Coffee shop** | 1 hour | High turnover of devices |
| **Office** | 8 hours | Users arrive/leave with work schedule |
| **Data center** | 7 days | More stable, fewer changes |

---

### The Complete Lifecycle

**Timeline:**

```
T=0: Connect to WiFi
  DHCP assigns: 192.168.1.145
  Lease: 24 hours

T=12 hours: Lease renewal attempt
  Device: "Can I keep 192.168.1.145?"
  Router: "Yes, renewed for 24 more hours"

T=24 hours: Disconnect
  IP returns to pool

T=26 hours: Reconnect
  DHCP process starts again
  Might get different IP: 192.168.1.178
```

---

### Why Leases Exist

**Problem without leases:**

```
Day 1: 50 devices connect, get IPs
Day 2: 40 of those devices never return
Day 3: Those 40 IPs still "reserved"
Day 4: Run out of IPs even though only 10 devices active
```

**Solution with leases:**

```
Day 1: 50 devices connect, get IPs (24-hour lease)
Day 2: 40 devices don't renew → IPs freed
Day 3: Those 40 IPs available for new devices
Result: Efficient IP usage
```

---

### Lease Renewal Process

**Before lease expires, devices try to renew:**

```
T=50% of lease (12 hours):
  Device: "DHCP REQUEST - Renew my IP?"
  Router: "DHCP ACK - Renewed for 24 hours"
  
If renewal fails:

T=87.5% of lease (21 hours):
  Device: "DHCP REQUEST - Renew my IP?"
  Router: "DHCP ACK - Renewed"
  
If still fails:

T=100% (24 hours):
  Lease expires
  Device loses IP
  Starts DORA process again (might get different IP)
```

**Most of the time, renewal succeeds and you keep the same IP.**

---

## Static vs Dynamic IPs

### Dynamic IP (DHCP-Assigned)

**How it works:**

```
Device: "I need an IP"
DHCP: "Use 192.168.1.145 for 24 hours"
Device uses IP
Lease expires
Process repeats
```

**Characteristics:**

```
✅ Automatic (no configuration needed)
✅ Scales well (reuses IPs)
✅ Easy for users
❌ IP can change
❌ Unpredictable address
```

**When to use:**

```
✅ Laptops, phones, tablets
✅ Guest devices
✅ Home networks
✅ Anything that moves between networks
```

---

### Static IP (Manually Configured)

**How it works:**

```
Administrator configures on device:
  IP:      192.168.1.100
  Mask:    255.255.255.0
  Gateway: 192.168.1.1
  DNS:     8.8.8.8
  
Device uses this IP permanently
Never changes (until manually changed)
```

**Characteristics:**

```
✅ Predictable address
✅ Never changes
✅ Good for servers
❌ Manual configuration required
❌ Risk of IP conflicts
❌ Doesn't scale well
```

**When to use:**

```
✅ Servers (web, database, file)
✅ Network printers
✅ Network infrastructure (routers, switches)
✅ IoT devices (security cameras, etc.)
✅ Production systems
```

---

### Configuration Examples

**Set static IP (Linux):**

```bash
# Ubuntu (netplan)
# Edit: /etc/netplan/01-netcfg.yaml

network:
  version: 2
  ethernets:
    eth0:
      addresses:
        - 192.168.1.100/24
      gateway4: 192.168.1.1
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]

# Apply
sudo netplan apply
```

**Set static IP (Windows):**

```
Control Panel → Network Connections
Right-click adapter → Properties
Internet Protocol Version 4 (TCP/IPv4) → Properties

○ Use the following IP address:
  IP address:         192.168.1.100
  Subnet mask:        255.255.255.0
  Default gateway:    192.168.1.1
  
○ Use the following DNS server addresses:
  Preferred DNS:      8.8.8.8
  Alternate DNS:      8.8.4.4
```

---

### The IP Conflict Problem

**What happens if two devices use the same IP?**

**Scenario:**

```
Device A: Static IP 192.168.1.100 (manually set)
Device B: DHCP assigns 192.168.1.100 (router doesn't know about static)

Result: IP conflict!
```

**Symptoms:**

```
❌ Intermittent connectivity
❌ "IP address conflict" error messages
❌ Network not working randomly
❌ Both devices fighting for same IP
```

**Prevention:**

```
Best practice:
  Split IP range:
  
  DHCP pool:    192.168.1.100 - 192.168.1.200
  Static IPs:   192.168.1.10 - 192.168.1.50
  
  Never overlap!
```

---

## DHCP Reservation (Best of Both Worlds)

### What Is DHCP Reservation?

**Definition:**  
DHCP reservation binds a specific IP address to a specific device's MAC address.

**How it works:**

```
Router configuration:
  "Always give MAC AA:BB:CC:DD:EE:FF the IP 192.168.1.100"
  
Device connects:
  DHCP process runs normally
  But router always assigns 192.168.1.100 to this device
```

**Result:**  
Device gets consistent IP but still uses DHCP.

---

### Benefits

```
✅ Consistent IP address (like static)
✅ Uses DHCP (automatic, no manual device config)
✅ Centrally managed (on router)
✅ Easy to change (update router, not device)
✅ No IP conflicts (router manages everything)
```

---

### When to Use DHCP Reservation

**Perfect for:**

```
✅ Home servers (media server, NAS)
✅ Network printers
✅ Smart home devices
✅ Game consoles (port forwarding rules)
✅ Anything needing consistent IP but benefits from DHCP
```

---

### How to Configure (Example)

**Router admin interface:**

```
1. Find device's MAC address
   - Check router's DHCP client list
   - Or: ipconfig /all (Windows), ip link (Linux)

2. Add reservation:
   MAC Address:    AA:BB:CC:DD:EE:FF
   Reserved IP:    192.168.1.100
   Description:    "Home Server"

3. Save

Device will now always get 192.168.1.100
```

---

### Comparison Table

| Feature | Dynamic (DHCP) | Static (Manual) | DHCP Reservation |
|---------|----------------|-----------------|------------------|
| **IP changes?** | ✅ Yes | ❌ No | ❌ No |
| **Manual config?** | ❌ No | ✅ Yes | ❌ No |
| **Consistent IP?** | ❌ No | ✅ Yes | ✅ Yes |
| **Risk of conflict?** | Low | High | Low |
| **Easy to manage?** | ✅ Yes | ❌ No | ✅ Yes |
| **Best for** | Laptops, phones | Critical servers | Home servers, printers |

---

## IPv4 vs IPv6

### The Address Exhaustion Problem

**IPv4:**

```
Total addresses: 4.3 billion
Problem: We ran out around 2011
```

**Why we ran out:**

```
World population: 8 billion
Devices per person: 3-5 (phone, laptop, tablet, IoT)
Total devices: 20+ billion

4.3 billion < 20 billion → Not enough!
```

---

### IPv6: The Solution

**IPv6 = Internet Protocol version 6**

**Key differences:**

| Feature | IPv4 | IPv6 |
|---------|------|------|
| **Address length** | 32 bits | 128 bits |
| **Format** | 192.168.1.45 | 2001:0db8:85a3::8a2e:0370:7334 |
| **Total addresses** | ~4.3 billion | 340 undecillion (340 × 10³⁶) |
| **Notation** | Decimal | Hexadecimal |

---

### IPv6 Address Example

```
2001:0db8:85a3:0000:0000:8a2e:0370:7334
│    │    │    │    │    │    │    │
8 groups of 4 hexadecimal digits
Separated by colons
128 bits total

Abbreviation rules:
- Leading zeros can be omitted: 0db8 → db8
- Consecutive groups of zeros can be replaced with ::
  
Abbreviated:
2001:db8:85a3::8a2e:370:7334
```

---

### Why IPv6 Matters (But Not Urgently for DevOps)

**Current reality:**

```
IPv4: Still dominant (~90% of internet traffic)
IPv6: Growing but slow adoption

Most cloud providers support both:
  AWS EC2: Gets both IPv4 and IPv6
  Most home routers: IPv4 only or dual-stack
```

**For DevOps beginners:**

```
Focus on IPv4 first (this series)
IPv6 works similarly (same concepts)
Learn IPv6 when needed (usually not immediately)
```

**You don't need to master IPv6 right now.**

---

## Localhost (127.0.0.1)

### What Is Localhost?

**Definition:**  
Localhost is a special IP address that always refers to "this device I'm currently on."

**The address:**

```
IPv4: 127.0.0.1
IPv6: ::1

Both mean: "This machine"
```

---

### How Localhost Works

**Localhost never leaves your device:**

```
Application sends to 127.0.0.1
  ↓
Operating system intercepts
  ↓
Delivers back to same device
  ↓
Never touches network card
  ↓
Never leaves computer
```

**It's a loopback — traffic circles back immediately.**

---

### Critical Understanding

**Localhost is RELATIVE, not absolute:**

| Where You Are | What 127.0.0.1 Means |
|---------------|---------------------|
| **Your laptop** | Your laptop |
| **Docker container** | That specific container |
| **AWS EC2 instance** | That EC2 instance |
| **Virtual machine** | That VM |

**The Common Docker mistake:**

```
Docker container runs web server on port 3000

❌ Wrong thinking:
  "Server runs on localhost:3000"
  "I can access it at localhost:3000 on my laptop"

✅ Correct:
  "Server runs on localhost:3000 INSIDE container"
  "Container's localhost ≠ Host's localhost"
  "Need port binding: docker run -p 3000:3000"
```

> **Docker implementation:** The localhost trap and IP assignment behavior inside containers is covered in full with hands-on examples in the Docker notes.
> → [Docker Networking](../../04.%20Docker%20–%20Containerization/05-docker-networking/README.md)

---

### The Entire Loopback Range

**Reserved range:**

```
127.0.0.0 - 127.255.255.255 (127.0.0.0/8)

All of these are loopback:
  127.0.0.1    ← Most common
  127.0.0.2
  127.1.1.1
  127.255.255.254

All mean "this device"
```

**In practice, everyone uses 127.0.0.1.**

---

### When to Use Localhost

**Common scenarios:**

```
✅ Testing web apps locally
   http://localhost:3000

✅ Database connections on same machine
   mysql://localhost:3306

✅ Development servers
   localhost:8080

✅ Localhost-only services (security)
   Bind to 127.0.0.1 → only accessible locally
```

---

## Real Scenarios

### Scenario 1: Home Network

**Setup:**

```
Router: 192.168.1.1
DHCP Pool: 192.168.1.100 - 192.168.1.200
Static range: 192.168.1.10 - 192.168.1.50
```

**Devices:**

```
Your laptop (Dynamic):
  Connects → DHCP assigns 192.168.1.145
  Disconnects → IP returns to pool
  Reconnects → Might get 192.168.1.178

Home server (DHCP Reservation):
  MAC: AA:BB:CC:DD:EE:FF
  Always gets: 192.168.1.100
  Runs Plex, accessible at: http://192.168.1.100:32400

Network printer (Static):
  Manually configured: 192.168.1.10
  Never changes
  Everyone prints to: 192.168.1.10
```

---

### Scenario 2: AWS VPC

**VPC setup:**

```
VPC CIDR: 10.0.0.0/16

Public Subnet: 10.0.1.0/24
├─ Web Server 1: 10.0.1.10 (static private IP)
├─ Web Server 2: 10.0.1.20 (static private IP)
└─ NAT Gateway:  10.0.1.100

Private Subnet: 10.0.2.0/24
├─ App Server 1: 10.0.2.10 (static private IP)
├─ App Server 2: 10.0.2.20 (static private IP)
└─ RDS Database: 10.0.2.50 (static private IP)
```

**Why static IPs in AWS?**

```
✅ Security group rules reference IPs
✅ Application config uses IPs
✅ Load balancer targets use IPs
✅ Predictable addressing
✅ No DHCP lease expiration issues
```

**How they're assigned:**

```
Not DHCP — AWS assigns when instance launches
Private IP stays same for life of instance
Can be manually specified or auto-assigned
```

---

## Final Compression

### How Devices Get IPs

**Three methods:**

```
1. DHCP (Dynamic)
   - Automatic assignment
   - IP can change
   - Best for: Laptops, phones, guests

2. Static (Manual)
   - Administrator configures
   - IP never changes
   - Best for: Servers, infrastructure

3. DHCP Reservation
   - DHCP but consistent IP
   - Best of both worlds
   - Best for: Printers, home servers
```

---

### Why IPs Change (DHCP Leases)

**The process:**

```
1. Connect → DHCP assigns IP for X hours
2. Disconnect → IP returns to pool
3. Reconnect → Might get different IP

Why?
  Limited IPs, many devices, efficient reuse
```

---

### DHCP DORA Process

```
D = Discover   (Client: "I need an IP")
O = Offer      (Server: "Use this IP")
R = Request    (Client: "I accept")
A = Acknowledge (Server: "Confirmed")

Result: Device has IP + subnet + gateway + DNS
```

---

### Static vs Dynamic Decision Tree

```
Is it a server? → Static or DHCP Reservation
Does it move between networks? → DHCP
Does it need predictable address? → Static or Reservation
Is it a temporary device? → DHCP
```

---

### Key Facts

```
✅ IPv4 = 32 bits, 4.3 billion addresses
✅ DHCP provides: IP, mask, gateway, DNS, lease time
✅ Lease = temporary assignment, then reclaimed
✅ Static = manual, never changes
✅ Reservation = DHCP + consistent IP
✅ Localhost (127.0.0.1) = this device only
✅ IPv6 exists but IPv4 still dominant
```

---

### Mental Model

```
DHCP = Hotel
  Check in:  Get room number (IP) for X days (lease)
  Check out: Room available for others
  Return:    Might get different room

Static IP = Owning a house
  Same address forever
  You manage it

DHCP Reservation = Reserved hotel room
  Same room every time
  But hotel manages it
```

---

### What You Can Do Now

✅ Understand why your IP changes (DHCP leases)  
✅ Know when to use static vs dynamic IPs  
✅ Understand DHCP DORA process  
✅ Configure static IPs when needed  
✅ Use DHCP reservations for consistent IPs  
✅ Understand localhost (127.0.0.1)  

---

---

## What This Means for the Webstore

Postgres on the webstore server is configured with `listen_addresses` in `postgresql.conf`. If it is set to `localhost`, only processes on the same machine can connect — correct for a production server where the API runs locally. If it is set to `*` or the server's IP, processes on other machines can connect — necessary when the API and database run on separate servers. This is not a code change. It is an IP binding decision. Understanding that `127.0.0.1` means this machine only and `0.0.0.0` means all interfaces is what lets you read a database config file and immediately know whether it is reachable from outside. The webstore's nginx is bound to `0.0.0.0:80` — it must be, to serve browsers. Postgres is bound to `127.0.0.1:5432` — it must be, to block direct external access.

---

## On the Webstore

The webstore server has one IP address — everything below maps IP concepts directly to it.

```bash
# Step 1 — confirm the server has a private IP (DHCP or static)
ip addr show
# Look for: inet 10.x.x.x or 192.168.x.x — this is your private IP
# The /24 or /16 after the IP is your subnet mask

# Step 2 — confirm your public IP is different (NAT in action)
curl -s ifconfig.me
# This is what webstore.example.com's A record will point to
# Your private IP and public IP will not match — that's expected

# Step 3 — confirm the three webstore services are bound to the right addresses
ss -tlnp | grep -E '(:80|:8080|:5432)'
# Expected:
# 0.0.0.0:80     → nginx — listening on all interfaces, reachable from outside
# 0.0.0.0:8080   → webstore-api — listening on all interfaces
# 127.0.0.1:5432 → webstore-db — loopback only, NOT reachable from outside

# Step 4 — confirm localhost means this machine only
curl http://localhost:80
# nginx responds — traffic never left the machine

# Step 5 — confirm the server's interface and gateway
ip route
# Look for: default via X.X.X.X dev eth0
# That gateway IP is where all non-local traffic exits

# Step 6 — check the server's ARP table — who is on the same subnet
arp -a
# Your gateway's MAC will be here — every packet to the internet
# goes to this MAC at Layer 2, even though the destination IP is far away

# Step 7 — confirm webstore-db is NOT reachable from an external IP
# From a different machine or using your public IP:
nc -zv YOUR_PUBLIC_IP 5432
# Expected: Connection refused or timed out — postgres is loopback-only

# Step 8 — check DHCP lease details (what the server was assigned)
cat /var/lib/dhcp/dhclient.leases 2>/dev/null | grep -E '(fixed-address|routers|domain-name-server)'
# Shows: IP assigned, gateway, DNS server — the full DHCP assignment
```

The postgres `127.0.0.1` binding in step 3 is intentional security. It means postgres is only reachable from inside the same machine. When you containerize the webstore in Docker, this changes — postgres gets a container IP and webstore-api reaches it by container name across the Docker network, not via localhost.

---

## What Breaks

| Symptom | Cause | First command to run |
|---|---|---|
| Service is running but unreachable from outside | Service is bound to `127.0.0.1` instead of `0.0.0.0` | `ss -tlnp \| grep PORT` — check the bind address column |
| `curl ifconfig.me` returns the same IP as `ip addr show` | No NAT — machine has a public IP directly (common on cloud VMs) | This is normal on EC2 — the instance has a public IP, no router NAT |
| DHCP assigned a new IP after reboot — configs broke | Dynamic IP changed | Set a static IP or DHCP reservation for server services |
| `ping` works but service is unreachable | Firewall is blocking the port, not the host | `nc -zv HOST PORT` — if it times out, the firewall is the problem |
| `nc -zv HOST PORT` says `Connection refused` not timeout | Host is reachable but nothing is listening on that port | `ss -tlnp \| grep PORT` on the server — is the service actually running? |

---

→ **Interview questions for this topic:** [99-interview-prep → MAC vs IP · ARP · Addressing](../99-interview-prep/README.md#mac-vs-ip--arp--addressing)

→ Ready to practice? [Go to Lab 01](../networking-labs/01-foundation-addressing-ip-lab.md)

---
# SOURCE: 03. Networking – Foundations/04-network-devices/README.md
---

# File 04: Network Devices

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

# Network Devices

## What this file is about

This file teaches **how traffic moves between devices and networks**. If you understand this, you'll know when devices can talk directly (switch), when they need routing (router), and how to configure the path traffic takes (default gateway). This is essential for understanding network topology and troubleshooting connectivity.

<!-- no toc -->
- [The Core Problem](#the-core-problem)
- [LAN vs WAN (Network Scope)](#lan-vs-wan-network-scope)
- [Switch (Layer 2 - Local Delivery)](#switch-layer-2---local-delivery)
- [Router (Layer 3 - Network Connector)](#router-layer-3---network-connector)
- [Default Gateway (The Exit Door)](#default-gateway-the-exit-door)
- [Switch vs Router (The Critical Difference)](#switch-vs-router-the-critical-difference)
- [Routing Tables (How Routers Decide)](#routing-tables-how-routers-decide)
- [Hub (Legacy - Don't Use)](#hub-legacy---dont-use)
- [Real Scenarios](#real-scenarios)  
[Final Compression](#final-compression)

---

## The Core Problem

### The Question

**Scenario 1:** Your laptop wants to send a file to a printer in the same room.

**Scenario 2:** Your laptop wants to access google.com (different city, different country).

**The question:**  
How does your laptop know whether to:
- Send data directly to the destination?
- Send data to a router for forwarding?

**This is the fundamental routing decision.**

---

### The Real-World Analogy

**Sending mail:**

```
Scenario 1: Give letter to neighbor
  Action: Walk to their door directly
  No post office needed

Scenario 2: Send letter to another country
  Action: Give to post office
  Post office handles forwarding
```

**Sending data:**

```
Scenario 1: Printer in same network
  Action: Send directly via switch
  No router needed

Scenario 2: Google server in another network
  Action: Send to router (default gateway)
  Router handles forwarding
```

**The device must make this decision for every packet.**

---

## LAN vs WAN (Network Scope)

### Local Area Network (LAN)

**Definition:**  
A network where all devices can communicate directly without routing.

**Characteristics:**

```
✅ Same physical location (building, floor, room)
✅ Direct communication (no router needed)
✅ High speed (Gigabit ethernet common)
✅ Low latency (<1ms)
✅ Private ownership (you control it)
```

**Examples:**

```
Your home WiFi:        192.168.1.0/24
Office floor:          10.0.5.0/24
AWS VPC subnet:        10.0.1.0/24
```

---

### Wide Area Network (WAN)

**Definition:**  
A network spanning large geographic areas, connecting multiple LANs.

**Characteristics:**

```
✅ Large geographic scope (cities, countries, continents)
✅ Requires routing (multiple routers)
✅ Lower speed (depends on connection)
✅ Higher latency (10-100ms or more)
✅ Often uses public infrastructure
```

**Examples:**

```
The Internet:           Global WAN
Corporate WAN:          Connects office branches
ISP network:            Connects customers to internet
AWS VPC peering:        Connects VPCs in different regions
```

---

### The Key Difference

```
┌─────────────────────────────────────────┐
│  LAN (Local Area Network)               │
│                                         │
│  [Laptop] ←→ [Printer] ←→ [Desktop]     │
│      │          │            │          │
│      └──────[Switch]─────────┘          │
│                                         │
│  All devices talk directly              │
│  No router needed                       │
└─────────────────────────────────────────┘

         vs

┌─────────────────────────────────────────┐
│  WAN (Wide Area Network)                │
│                                         │
│  [Your LAN] ←→ [Router] ←→ [Router] ... │
│                   ↕                     │
│              [Internet]                 │
│                   ↕                     │
│              [Router] ←→ [Google's LAN] │
│                                         │
│  Multiple LANs connected by routers     │
└─────────────────────────────────────────┘
```

---

### How Your Device Knows (Subnet Mask)

**Your device checks:**

```
My IP:           192.168.1.45
Subnet mask:     255.255.255.0
Target IP:       192.168.1.50

Calculation:
  My network:     192.168.1.0
  Target network: 192.168.1.0
  
Match? YES → Same LAN → Send directly

Target IP:       142.250.190.46 (Google)

Calculation:
  My network:     192.168.1.0
  Target network: 142.250.190.0
  
Match? NO → Different network → Send to router
```

**The subnet mask determines local vs remote.**  
(Covered in detail in File 05)

---

## Switch (Layer 2 - Local Delivery)

### What Is a Switch?

**Definition:**  
A network device that connects multiple devices in a LAN and forwards data based on MAC addresses.

**Layer:** Layer 2 (Data Link)

**Job:** Deliver frames to the correct device on the local network.

---

### How a Switch Works

**Physical setup:**

```
         [Switch]
            ╱ │ ╲
           ╱  │  ╲
          ╱   │   ╲
    [Laptop] [Desktop] [Printer]
```

**MAC address table (learned automatically):**

| MAC Address | Port | Learned |
|-------------|------|---------|
| AA:BB:CC:DD:EE:FF | Port 1 | Laptop |
| 11:22:33:44:55:66 | Port 2 | Desktop |
| F8:1A:67:B4:32:D1 | Port 3 | Printer |

---

### Switch Operation (Step by Step)

**Scenario:** Laptop sends file to printer

**Step 1: Laptop creates frame**

```
Ethernet Frame:
  Source MAC:      AA:BB:CC:DD:EE:FF (laptop)
  Destination MAC: F8:1A:67:B4:32:D1 (printer)
  Payload:         File data
```

**Step 2: Frame arrives at switch**

```
Switch receives frame on Port 1
Reads destination MAC: F8:1A:67:B4:32:D1
```

**Step 3: Switch checks MAC table**

```
MAC table lookup:
  F8:1A:67:B4:32:D1 → Port 3

Decision: Forward to Port 3 only
```

**Step 4: Switch forwards**

```
Frame sent out Port 3 → Printer receives it
Ports 2, 4, 5, etc. see nothing (efficient!)
```

---

### MAC Address Learning

**How switch builds MAC table:**

**Initial state (switch just powered on):**

```
MAC Table: Empty
```

**Laptop sends first frame:**

```
Frame arrives on Port 1
Source MAC: AA:BB:CC:DD:EE:FF

Switch learns:
  "AA:BB:CC:DD:EE:FF is on Port 1"
  
MAC Table:
  AA:BB:CC:DD:EE:FF → Port 1
```

**Destination MAC not in table:**

```
Switch doesn't know where printer is yet

Action: Flood
  Send frame to ALL ports except incoming port
  (Ports 2, 3, 4, 5 all receive the frame)
```

**Printer responds:**

```
Response frame arrives on Port 3
Source MAC: F8:1A:67:B4:32:D1

Switch learns:
  "F8:1A:67:B4:32:D1 is on Port 3"
  
MAC Table:
  AA:BB:CC:DD:EE:FF → Port 1
  F8:1A:67:B4:32:D1 → Port 3
```

**Future communication:**

```
Switch now knows both MACs
Forwards frames directly to correct ports
No flooding needed
```

---

### Switch Characteristics

```
✅ Operates at Layer 2 (Data Link)
✅ Uses MAC addresses
✅ Learns device locations automatically
✅ Forwards only to destination port (efficient)
✅ Multiple devices can communicate simultaneously
✅ Works within one network only (no routing)
❌ Cannot connect different networks
❌ Cannot route based on IP addresses
```

---

### Types of Switches

| Type | Description | Use Case |
|------|-------------|----------|
| **Unmanaged** | Plug-and-play, no configuration | Home, small office |
| **Managed** | Configurable (VLANs, QoS, monitoring) | Enterprise, data center |
| **Layer 3 Switch** | Can also route (switch + router hybrid) | Data center core |

**For most purposes:** Switch = Layer 2 device using MAC addresses.

---

## Router (Layer 3 - Network Connector)

### What Is a Router?

**Definition:**  
A network device that forwards packets between different networks based on IP addresses.

**Layer:** Layer 3 (Network)

**Job:** Connect different networks and route packets to their destination.

---

### Key Characteristic: Multiple IP Addresses

**A router has AT LEAST 2 network interfaces:**

```
┌─────────────────────────────────────┐
│           Router                    │
│                                     │
│  Interface 1 (LAN):                 │
│    IP:  192.168.1.1                 │
│    MAC: AA:BB:CC:DD:EE:FF           │
│    Connected to: Your home network  │
│                                     │
│  Interface 2 (WAN):                 │
│    IP:  203.45.67.89                │
│    MAC: 11:22:33:44:55:66           │
│    Connected to: ISP network        │
│                                     │
└─────────────────────────────────────┘

One foot in each network
```

**This is what makes routing possible.**

---

### How a Router Works

**Scenario:** Your laptop (192.168.1.45) accesses Google (142.250.190.46)

**Step 1: Laptop checks subnet**

```
My IP:     192.168.1.45
My mask:   255.255.255.0
Target:    142.250.190.46

Same network? NO
Action: Send to default gateway (router)
```

**Step 2: Laptop sends to router**

```
Ethernet Frame:
  Source MAC:      [Laptop MAC]
  Destination MAC: [Router LAN MAC]  ← Router, not Google!
  
IP Packet inside:
  Source IP:       192.168.1.45
  Destination IP:  142.250.190.46    ← Google
```

**Step 3: Router receives packet**

```
Router LAN interface receives frame
Checks destination MAC: "This is for me"
Strips Ethernet frame (de-encapsulation)
Reads IP header
  Destination: 142.250.190.46 → "Not for me, forward it"
```

**Step 4: Router checks routing table**

```
Routing table lookup:
  142.250.190.46 → Not directly connected
  Default route: 0.0.0.0/0 → WAN interface
  
Decision: Forward via WAN interface to ISP
```

**Step 5: Router forwards packet**

```
Creates NEW Ethernet frame:
  Source MAC:      [Router WAN MAC]
  Destination MAC: [ISP Router MAC]
  
IP Packet (same):
  Source IP:       192.168.1.45
  Destination IP:  142.250.190.46

Sends via WAN interface
```

**Key insight:** Router changed MAC addresses but kept IP addresses.

---

### What Routers Do

**Core functions:**

```
1. Packet forwarding
   - Read destination IP
   - Check routing table
   - Forward to next hop

2. Network separation
   - Connects different networks
   - Each interface on different network

3. NAT (Network Address Translation)
   - Converts private IPs to public IPs
   - Covered in File 07

4. Firewall
   - Block/allow traffic based on rules
   - Covered in File 09
```

---

### Router Characteristics

```
✅ Operates at Layer 3 (Network)
✅ Uses IP addresses
✅ Connects different networks
✅ Makes routing decisions
✅ Has multiple network interfaces
✅ Maintains routing table
❌ Slower than switches (more processing)
❌ Each interface is a separate network
```

---

## Default Gateway (The Exit Door)

### What Is a Default Gateway?

**Definition:**  
The IP address of the router on your local network — the "door out" to other networks.

**Simple rule:**

```
If destination is local → send directly
If destination is remote → send to default gateway
```

---

### How Default Gateway Works

**Your network configuration:**

```
IP Address:       192.168.1.45
Subnet Mask:      255.255.255.0
Default Gateway:  192.168.1.1  ← Router's IP on your LAN
```

**Decision process:**

```
┌─────────────────────────────────────┐
│  Want to send to: X.X.X.X           │
└──────────────┬──────────────────────┘
               │
               ▼
      ┌────────────────────┐
      │ Is X.X.X.X in my   │
      │ subnet?            │
      └────────┬───────────┘
               │
       ┌───────┴────────┐
       │                │
      YES              NO
       │                │
       ▼                ▼
┌────────────┐   ┌──────────────────┐
│Send direct │   │Send to gateway   │
│via switch  │   │(192.168.1.1)     │
└────────────┘   └──────────────────┘
```

---

### Real Example

**Your laptop configuration:**

```
IP:      192.168.1.45
Mask:    255.255.255.0
Gateway: 192.168.1.1
```

**Scenario 1: Print to local printer (192.168.1.50)**

```
Check: Is 192.168.1.50 in my subnet?
  My network:     192.168.1.0/24
  Target network: 192.168.1.0/24
  Match: YES

Action: Send directly
  ARP for 192.168.1.50's MAC
  Send frame directly to printer
  No router involved
```

**Scenario 2: Access google.com (142.250.190.46)**

```
Check: Is 142.250.190.46 in my subnet?
  My network:     192.168.1.0/24
  Target network: 142.250.190.0/24
  Match: NO

Action: Send to default gateway
  ARP for 192.168.1.1's MAC (already cached)
  Send frame to router
  Router forwards to internet
```

---

### Multiple Routes vs Default Route

**Routing table on your laptop:**

```
Destination      Gateway         Interface
192.168.1.0/24   0.0.0.0         eth0        (direct - local)
0.0.0.0/0        192.168.1.1     eth0        (default - everything else)
```

**Reading this table:**

```
Rule 1: 192.168.1.0/24 → 0.0.0.0 (direct)
  "Anything in 192.168.1.X goes directly"
  
Rule 2: 0.0.0.0/0 → 192.168.1.1 (default gateway)
  "Everything else goes to router"
```

**How it's used:**

```
Target: 192.168.1.50
  Matches Rule 1 → Send direct

Target: 8.8.8.8
  Doesn't match Rule 1
  Falls through to Rule 2 → Send to 192.168.1.1
```

---

### Default Gateway in Different Environments

**Home network:**

```
Your devices:    192.168.1.45, 192.168.1.67
Default gateway: 192.168.1.1 (home router)
```

**AWS VPC:**

```
EC2 in subnet 10.0.1.0/24:
  Private IP: 10.0.1.50
  Default gateway: 10.0.1.1 (VPC router)
```

**Office network:**

```
Your laptop: 10.0.5.100
Default gateway: 10.0.5.1 (office router)
```

---

### Check Your Default Gateway

**Linux/Mac:**

```bash
ip route
# or
netstat -rn

Output:
default via 192.168.1.1 dev eth0
         ↑
    Default gateway
```

**Windows:**

```cmd
ipconfig

Output:
Default Gateway: 192.168.1.1
```

---

### Common Issue: Wrong Default Gateway

**Symptom:**

```
Can ping devices on local network ✅
Cannot reach internet ❌
```

**Diagnosis:**

```bash
# Check default gateway
ip route

# Test if gateway is reachable
ping 192.168.1.1

If gateway unreachable → Misconfigured or router down
If gateway reachable but no internet → Router or ISP issue
```

**Fix:**

```
Verify gateway IP is correct
Should be router's IP on your subnet
Usually ends in .1 (192.168.1.1, 10.0.0.1, etc.)
```

---

## Switch vs Router (The Critical Difference)

### Side-by-Side Comparison

| Feature | Switch | Router |
|---------|--------|--------|
| **Layer** | Layer 2 (Data Link) | Layer 3 (Network) |
| **Uses** | MAC addresses | IP addresses |
| **Forwards based on** | MAC table | Routing table |
| **Connects** | Devices in same network | Different networks |
| **Number of networks** | 1 | 2+ |
| **Intelligence** | Simple forwarding | Routing decisions |
| **Speed** | Very fast | Slower (more processing) |
| **Example** | Office switch connecting computers | Home router connecting to internet |

---

### When to Use What

**Use a switch when:**

```
✅ Connecting devices in same network
✅ Need more ports (router has 4, need 24)
✅ All devices on same subnet
✅ High-speed local connections
```

**Use a router when:**

```
✅ Connecting different networks
✅ Need to reach internet
✅ Connecting office branches
✅ Separating networks (security, performance)
```

**Often used together:**

```
Internet
   ↓
Router (connects to ISP)
   ↓
Switch (connects local devices)
   ├─ Computer 1
   ├─ Computer 2
   ├─ Printer
   └─ Server
```

---

## Routing Tables (How Routers Decide)

### What Is a Routing Table?

**Definition:**  
A table that tells the router where to send packets based on destination IP.

**Format:**

```
Destination Network | Next Hop | Interface | Metric
```

---

### Example Routing Table

**Home router:**

```
Destination      Next Hop      Interface   Metric
192.168.1.0/24   0.0.0.0       eth0 (LAN)  0        (directly connected)
0.0.0.0/0        203.45.67.1   eth1 (WAN)  1        (default route via ISP)
```

**Reading this:**

```
Row 1: Traffic to 192.168.1.0/24
  Next hop: 0.0.0.0 (means "deliver directly")
  Interface: eth0 (LAN port)
  
Row 2: Traffic to anywhere else (0.0.0.0/0)
  Next hop: 203.45.67.1 (ISP router)
  Interface: eth1 (WAN port)
```

---

### How Routing Decisions Are Made

**Packet arrives with destination: 192.168.1.50**

```
Step 1: Check routing table (most specific first)
  Does 192.168.1.50 match 192.168.1.0/24? YES
  
Step 2: Use that route
  Next hop: 0.0.0.0 (direct)
  Interface: eth0
  
Step 3: Forward
  Send out eth0 interface directly
```

**Packet arrives with destination: 8.8.8.8**

```
Step 1: Check routing table
  Does 8.8.8.8 match 192.168.1.0/24? NO
  
Step 2: Check default route
  Does 8.8.8.8 match 0.0.0.0/0? YES (matches everything)
  
Step 3: Use default route
  Next hop: 203.45.67.1 (ISP router)
  Interface: eth1
  
Step 4: Forward
  Send to ISP router via eth1
```

---

### View Routing Table

**Linux/Mac:**

```bash
# View routing table
ip route
# or
netstat -rn

Output:
default via 192.168.1.1 dev eth0
192.168.1.0/24 dev eth0 proto kernel scope link src 192.168.1.45
```

**Windows:**

```cmd
route print
```

---

### Static vs Dynamic Routing

**Static routing:**

```
Administrator manually configures routes
Routes don't change unless manually updated

Good for:
  Small networks
  Predictable topology
  
Example:
  ip route add 10.0.2.0/24 via 192.168.1.254
```

**Dynamic routing:**

```
Routers share routes automatically
Routes update if topology changes

Protocols: RIP, OSPF, BGP
Good for:
  Large networks
  Redundant paths
```

**For DevOps beginners:**  
Focus on understanding static routes and default routes.

---

## Hub (Legacy - Don't Use)

### What Is a Hub?

**Definition:**  
An obsolete device that broadcasts data to all connected devices.

**Why mentioning it:**  
You might see it in old documentation or legacy networks.

---

### Hub vs Switch

| Feature | Hub | Switch |
|---------|-----|--------|
| **Intelligence** | None (broadcasts everything) | Smart (learns MACs) |
| **Efficiency** | Low (wastes bandwidth) | High (targeted forwarding) |
| **Speed** | Slow (collisions) | Fast |
| **Use today** | ❌ Obsolete | ✅ Standard |

**Hubs are dead. Always use switches.**

---

## Real Scenarios

### Scenario 1: Home Network

```
┌────────────────────────────────────────────┐
│           Home Network                     │
│                                            │
│  [Laptop]  [Phone]  [Smart TV]  [Printer]  │
│     │         │         │           │      │
│     └─────────┼─────────┼───────────┘      │
│               │         │                  │
│          [WiFi Router]──┘                  │
│       (Switch + Router combo)              │
│                                            │
│  LAN side:  192.168.1.1                    │
│  Subnet:    192.168.1.0/24                 │
└──────────────┬─────────────────────────────┘
               │ (Cable to ISP)
               ▼
          [Internet]
```

---

### Scenario 2: Office Network

```
┌──────────────────────────────────────────────┐
│         Office Floor (10.0.5.0/24)           │
│                                              │
│  [PC1]  [PC2]  [PC3]  ...  [PC50]  [Printer] │
│    │      │      │            │        │     │
│    └──────┴──────┴────────────┴────────┘     │
│                   │                          │
│            [24-port Switch]                  │
│                   │                          │
└───────────────────┼──────────────────────────┘
                    │
                    ▼
               [Router]
            10.0.5.1 (LAN)
            203.10.20.30 (WAN)
                    │
                    ▼
              [Internet]
```

---

### Scenario 3: AWS VPC

```
┌──────────────────────────────────────────────┐
│  VPC: 10.0.0.0/16                            │
│                                              │
│  ┌──────────────────────────────────────┐    │
│  │ Public Subnet: 10.0.1.0/24           │    │
│  │                                      │    │
│  │  [Web1]  [Web2]  [Load Balancer]     │    │
│  │  .10     .20     .100                │    │
│  │                                      │    │
│  └──────────────┬───────────────────────┘    │
│                 │                            │
│                 │ VPC Router (implicit)      │
│                 │                            │
│  ┌──────────────┴───────────────────────┐    │
│  │ Private Subnet: 10.0.2.0/24          │    │
│  │                                      │    │
│  │  [App1]  [App2]  [Database]          │    │
│  │  .10     .20     .50                 │    │
│  │                                      │    │
│  └──────────────────────────────────────┘    │
│                                              │
└──────────────────┬───────────────────────────┘
                   │
            [Internet Gateway]
                   │
              [Internet]
```

> **Docker implementation:** Docker uses the same switching and routing concepts internally — a bridge acts as the virtual switch, containers get their own IPs, and the Docker bridge acts as the default gateway. Multiple networks work exactly like multiple VPC subnets.
> → [Docker Networking](../../04.%20Docker%20–%20Containerization/05-docker-networking/README.md)

---

## Final Compression

### Network Scope

```
LAN (Local Area Network):
  Same location, direct communication
  No routing needed

WAN (Wide Area Network):
  Large geographic area, multiple LANs
  Routing required
```

---

### The Devices

**Switch (Layer 2):**
```
✅ Connects devices in same network
✅ Uses MAC addresses
✅ Fast, efficient
✅ One network only

Job: Local delivery within LAN
```

**Router (Layer 3):**
```
✅ Connects different networks
✅ Uses IP addresses
✅ Makes routing decisions
✅ Multiple network interfaces

Job: Forward packets between networks
```

---

### Default Gateway

**Definition:** Router's IP on your local network

**Purpose:** Exit door to other networks

**Decision rule:**
```
Destination in my subnet? → Send directly (switch)
Destination outside my subnet? → Send to gateway (router)
```

---

### Switch vs Router Summary

```
Same network? → Switch
  - Uses MAC
  - Fast
  - No routing

Different networks? → Router
  - Uses IP
  - Routing decisions
  - Connects networks
```

---

### Mental Model

```
Switch = Postal worker inside building
  Delivers mail to correct apartment
  Knows everyone on this floor
  Doesn't leave building

Router = International postal service
  Connects different buildings/cities
  Makes decisions about best path
  Forwards between networks

Default Gateway = Building exit
  Where you go to leave the building
```

---

### What You Can Do Now

✅ Understand when direct communication works (same LAN)  
✅ Know when routing is needed (different networks)  
✅ Understand switch operation (MAC table, forwarding)  
✅ Understand router operation (routing table, multiple networks)  
✅ Configure default gateway correctly  
✅ Read and understand routing tables  

---

---

## What This Means for the Webstore

The webstore server sits behind a router. When a request arrives from a browser in another city, it has been forwarded by 10-20 routers on the way — each one reading only the destination IP, making a routing decision, and passing the packet to the next hop. The MAC address on the packet changed at every single one of those hops. The destination IP never changed. When you run `traceroute` to the webstore server, you are watching those router hops and their latencies in real time. A latency spike at hop 8 means that is where the delay is introduced — not at your server, not in your application code.

---

→ **Interview questions for this topic:** [99-interview-prep → MAC vs IP · ARP · Addressing](../99-interview-prep/README.md#mac-vs-ip--arp--addressing)

→ Ready to practice? [Go to Lab 02](../networking-labs/02-devices-subnets-lab.md)

---
# SOURCE: 03. Networking – Foundations/05-subnets-cidr/README.md
---

# File 05: Network Segmentation (Subnets & CIDR)

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

# Network Segmentation (Subnets & CIDR)

## What this file is about

This file teaches **how to divide networks into smaller segments** and **how to read CIDR notation**. If you understand this, you'll be able to calculate how many IPs are available in any block and design networks that don't conflict. This is the universal foundation — how CIDR applies specifically to AWS VPCs is covered in the AWS notes.

<!-- no toc -->
- [The Core Problem](#the-core-problem)
- [Why Subnets Exist](#why-subnets-exist)
- [Subnet Masks (The Divider)](#subnet-masks-the-divider)
- [CIDR Notation (The Shorthand)](#cidr-notation-the-shorthand)
- [Calculating Available IPs](#calculating-available-ips)
- [Common CIDR Blocks (Memorize These)](#common-cidr-blocks-memorize-these)
- [Subnet Planning Rules](#subnet-planning-rules)
- [Subnetting Practice](#subnetting-practice)
[Final Compression](#final-compression)

---

## The Core Problem

### The Question

**Scenario:** You're setting up a network for a company.

**Requirements:**
- Web servers (need 50 IPs)
- Application servers (need 100 IPs)
- Databases (need 10 IPs)
- Each group should be isolated for security

**Questions:**
1. How do you divide the network?
2. How many IPs do you need total?
3. How do you prevent IP conflicts?
4. How do you ensure room for growth?

**This is what subnetting solves.**

---

### Why You Can't Just Use One Big Network

**Without subnetting (all devices in 192.168.1.0/24):**

```
Problems:
❌ Can't isolate web servers from databases (security risk)
❌ Can't apply different firewall rules to different groups
❌ Broadcast storms (everyone sees everyone's traffic)
❌ Difficult to manage (254 devices in one flat network)
❌ No logical organization
```

**With subnetting (divided logically):**

```
Benefits:
✅ Web servers:  10.0.1.0/24 (isolated)
✅ App servers:  10.0.2.0/24 (isolated)
✅ Databases:    10.0.3.0/24 (isolated)
✅ Different firewall rules per subnet
✅ Better performance (smaller broadcast domains)
✅ Organized and manageable
```

---

## Why Subnets Exist

### The Historical Context

**You now understand routers** (from File 04).

**Key insight from that file:**
- Routers separate networks
- Each router interface is on a different network
- Devices on different networks need a router to communicate

**Subnets exist BECAUSE routers exist.**

---

### Subnets Create Network Boundaries

**One large network (no subnetting):**

```
Company network: 10.0.0.0/16 (65,534 hosts)
All departments share one network

Problems:
- No isolation
- Single broadcast domain (inefficient)
- Can't apply per-department security rules
```

**Multiple subnets (segmented):**

```
Company network: 10.0.0.0/16

Subnet 1 (Marketing):    10.0.1.0/24  (254 hosts)
Subnet 2 (Engineering):  10.0.2.0/24  (254 hosts)
Subnet 3 (Finance):      10.0.3.0/24  (254 hosts)
Subnet 4 (HR):           10.0.4.0/24  (254 hosts)

Benefits:
- Departments isolated
- Different firewall rules per department
- Better performance
- Easier troubleshooting
```

---

### The Four Reasons Subnets Exist

```
1. Security / Isolation
   Separate sensitive systems from others

2. Organization
   Logical grouping of devices

3. Performance
   Smaller broadcast domains

4. Address Management
   Efficient use of IP space
```

---

## Subnet Masks (The Divider)

### What Is a Subnet Mask?

**Definition:**  
A subnet mask defines which part of an IP address is the network portion and which part is the host portion.

**Purpose:**  
Tells your device: "These IPs are local (same network), everything else is remote (need router)."

---

### How Subnet Masks Work

**Example IP and mask:**

```
IP Address:   192.168.1.45
Subnet Mask:  255.255.255.0
```

**What this means:**

```
IP Address:     192  .  168  .  1    .  45
Subnet Mask:    255  .  255  .  255  .  0
                │       │       │       │
                Network Network Network Host
                portion portion portion portion
```

**Translation:**

```
Network portion: 192.168.1  (first 3 octets)
  This defines the network
  All devices on this network have 192.168.1.X

Host portion: 45  (last octet)
  This identifies the specific device
  Can be 0-255 (actually 1-254 usable)
```

---

### Binary View (How It Really Works)

**IP Address: 192.168.1.45**

```
Decimal:  192      .  168      .  1        .  45
Binary:   11000000 .  10101000 .  00000001 .  00101101
```

**Subnet Mask: 255.255.255.0**

```
Decimal:  255      .  255      .  255      .  0
Binary:   11111111 .  11111111 .  11111111 .  00000000
          │                                   │
          Network bits (1s)                   Host bits (0s)
```

**The rule:**

```
Where mask has 1 → Network portion (fixed for this network)
Where mask has 0 → Host portion (varies per device)
```

---

### Common Subnet Masks

| Subnet Mask | Binary | Network Bits | Host Bits | Total Hosts |
|-------------|--------|--------------|-----------|-------------|
| 255.0.0.0 | 11111111.00000000.00000000.00000000 | 8 | 24 | 16,777,214 |
| 255.255.0.0 | 11111111.11111111.00000000.00000000 | 16 | 16 | 65,534 |
| 255.255.255.0 | 11111111.11111111.11111111.00000000 | 24 | 8 | 254 |
| 255.255.255.128 | 11111111.11111111.11111111.10000000 | 25 | 7 | 126 |
| 255.255.255.192 | 11111111.11111111.11111111.11000000 | 26 | 6 | 62 |

---

### How Devices Use Subnet Masks

**Your laptop's configuration:**

```
IP:   192.168.1.45
Mask: 255.255.255.0
```

**You want to reach 192.168.1.67:**

```
Your network:   192.168.1.0
Target network: 192.168.1.0
Match → SAME NETWORK → Send direct
```

**You want to reach 192.168.2.50:**

```
Your network:   192.168.1.0
Target network: 192.168.2.0
No match → DIFFERENT NETWORK → Send to gateway
```

---

## CIDR Notation (The Shorthand)

### What Is CIDR?

**CIDR = Classless Inter-Domain Routing**

**Purpose:**  
A shorter way to write IP address + subnet mask together.

**Instead of:**

```
Network:      192.168.1.0
Subnet Mask:  255.255.255.0
```

**Write:**

```
192.168.1.0/24
```

---

### What the /Number Means

**The number after the slash = how many network bits**

```
192.168.1.0/24
            └─ 24 bits for network
               32 - 24 = 8 bits for hosts
```

**Conversion:**

```
/24 → 24 network bits → Subnet mask 255.255.255.0

Why 255.255.255.0?
  First 24 bits are 1s: 11111111.11111111.11111111.00000000
  In decimal: 255.255.255.0
```

---

### Common CIDR to Subnet Mask Conversions

| CIDR | Subnet Mask | Network Bits | Host Bits |
|------|-------------|--------------|-----------|
| /8 | 255.0.0.0 | 8 | 24 |
| /16 | 255.255.0.0 | 16 | 16 |
| /24 | 255.255.255.0 | 24 | 8 |
| /25 | 255.255.255.128 | 25 | 7 |
| /26 | 255.255.255.192 | 26 | 6 |
| /27 | 255.255.255.224 | 27 | 5 |
| /28 | 255.255.255.240 | 28 | 4 |
| /30 | 255.255.255.252 | 30 | 2 |
| /32 | 255.255.255.255 | 32 | 0 |

---

### CIDR Block Examples

**Example 1: 10.0.0.0/16**

```
Range:  10.0.0.0 - 10.0.255.255
Total:  2^16 = 65,536 IPs
Usable: 65,534
```

**Example 2: 192.168.1.0/24**

```
Range:  192.168.1.0 - 192.168.1.255
Total:  2^8 = 256 IPs
Usable: 254
```

**Example 3: 172.16.0.0/12**

```
Range:  172.16.0.0 - 172.31.255.255
Total:  2^20 = 1,048,576 IPs
Usable: 1,048,574
```

---

### Why CIDR Is Better Than Old Classes

**Old system (before 1993):**

```
Class A: /8  (16 million IPs per network)
Class B: /16 (65,536 IPs per network)
Class C: /24 (256 IPs per network)

Problem:
  Company needs 500 IPs
  Class C too small (256)
  Class B too big (65,536) — Waste!
```

**CIDR system (modern):**

```
Need 500 IPs? Use /23 (512 IPs)
Need 1000 IPs? Use /22 (1024 IPs)

Flexible! Any size you need.
```

---

## Calculating Available IPs

### The Formula

**Given CIDR notation:**

```
Total IPs = 2^(32 - CIDR)

Usable IPs = Total - 2
  -1 for network address (first IP)
  -1 for broadcast address (last IP)
```

---

### Step-by-Step Calculation

**Example: 192.168.1.0/26**

```
Step 1: Identify host bits
  CIDR: /26
  Host bits: 32 - 26 = 6 bits

Step 2: Calculate total IPs
  Total: 2^6 = 64 IPs

Step 3: Calculate usable IPs
  Usable: 64 - 2 = 62 IPs

Step 4: Determine range
  Network address:   192.168.1.0   (reserved)
  First usable:      192.168.1.1
  Last usable:       192.168.1.62
  Broadcast address: 192.168.1.63  (reserved)
```

---

### Quick Reference Table

| CIDR | Host Bits | Total IPs | Usable IPs | Use Case |
|------|-----------|-----------|------------|----------|
| /32 | 0 | 1 | 1 | Single host (security group rule) |
| /30 | 2 | 4 | 2 | Point-to-point links |
| /29 | 3 | 8 | 6 | Very small subnet |
| /28 | 4 | 16 | 14 | Small subnet |
| /27 | 5 | 32 | 30 | Small subnet |
| /26 | 6 | 64 | 62 | Medium subnet |
| /25 | 7 | 128 | 126 | Medium subnet |
| /24 | 8 | 256 | 254 | Standard subnet |
| /23 | 9 | 512 | 510 | Medium-large subnet |
| /22 | 10 | 1,024 | 1,022 | Large subnet |
| /20 | 12 | 4,096 | 4,094 | Very large subnet |
| /16 | 16 | 65,536 | 65,534 | Large network |
| /8 | 24 | 16,777,216 | 16,777,214 | Massive network |

---

### Reserved Addresses

**In every subnet, two addresses are reserved:**

```
Example: 192.168.1.0/24

Network address:   192.168.1.0    (identifies the subnet)
Broadcast address: 192.168.1.255  (send to all hosts)

Usable range:      192.168.1.1 - 192.168.1.254
```

---

## Common CIDR Blocks (Memorize These)

### The Essential Four

```
/32 = 1 IP (single host)
/24 = 256 IPs (254 usable) — standard subnet
/16 = 65,536 IPs — large network
/8  = 16.7 million IPs — entire private range
```

---

### Mental Shortcuts

**Powers of 2:**

```
/32 = 2^0  = 1
/28 = 2^4  = 16
/26 = 2^6  = 64
/24 = 2^8  = 256      ← Memorize
/22 = 2^10 = 1,024
/20 = 2^12 = 4,096
/16 = 2^16 = 65,536   ← Memorize
/8  = 2^24 = 16,777,216
```

---

## Subnet Planning Rules

### Rule 1: Avoid Overlap

**❌ BAD (subnets overlap):**

```
Subnet A: 10.0.1.0/24  (10.0.1.0 - 10.0.1.255)
Subnet B: 10.0.1.128/25 (10.0.1.128 - 10.0.1.255)
                          ↑
                    Overlap! Conflict!
```

**✅ GOOD (no overlap):**

```
Subnet A: 10.0.1.0/24   (10.0.1.0 - 10.0.1.255)
Subnet B: 10.0.2.0/24   (10.0.2.0 - 10.0.2.255)
```

---

### Rule 2: Plan for Growth

```
Need 50 IPs → Use /24 (254 usable)
  Room for growth: 254 - 50 = 204 IPs available

Rule of thumb: Allocate 2-3x what you need today.
```

---

### Rule 3: Use Consistent Sizing

**✅ Consistent (easy to manage):**

```
Web subnet:  10.0.1.0/24
App subnet:  10.0.2.0/24
DB subnet:   10.0.3.0/24

Same size, predictable, simple
```

---

### Rule 4: Smaller CIDR = Bigger Network

```
/24 = 256 IPs    (bigger subnet)
/26 = 64 IPs     (smaller subnet)
/28 = 16 IPs     (even smaller)

Lower number = MORE IPs
Higher number = FEWER IPs
```

---

### Rule 5: Leave Room Between Subnets

```
VPC: 10.0.0.0/16

Current subnets:
  Web:  10.0.1.0/24
  App:  10.0.2.0/24
  DB:   10.0.3.0/24

Reserved for future:
  10.0.4.0/24 - 10.0.255.0/24 (available)
```

---

## Subnetting Practice

### Exercise 1: Calculate Usable IPs

**Given: 192.168.10.0/27**

```
Step 1: Find host bits
  Host bits = 32 - 27 = 5 bits

Step 2: Calculate total IPs
  Total = 2^5 = 32 IPs

Step 3: Calculate usable
  Usable = 32 - 2 = 30 IPs

Step 4: Determine range
  Network:   192.168.10.0
  First:     192.168.10.1
  Last:      192.168.10.30
  Broadcast: 192.168.10.31
```

---

### Exercise 2: Choose Right CIDR

**Requirement: Need subnet for 100 hosts**

```
Options:
  /25 = 128 IPs (126 usable) ✓ Sufficient
  /26 = 64 IPs (62 usable)   ✗ Too small
  /24 = 256 IPs (254 usable) ✓ Room for growth

Best choice: /24 (room for growth)
```

---

### Exercise 3: Identify Conflicts

**Which subnets overlap?**

```
A: 10.0.1.0/24   (10.0.1.0 - 10.0.1.255)
B: 10.0.2.0/24   (10.0.2.0 - 10.0.2.255)
C: 10.0.1.128/25 (10.0.1.128 - 10.0.1.255)

Answer: A and C overlap
  A covers 10.0.1.0 - 10.0.1.255
  C covers 10.0.1.128 - 10.0.1.255
  Conflict in 10.0.1.128 - 10.0.1.255 range
```

---

> **AWS implementation:** How to apply these CIDR concepts to AWS VPC design — public vs private subnets, multi-AZ patterns, AWS reserved IPs, and a full webstore VPC subnet plan — is covered in the AWS notes.
> → [AWS VPC & Subnets](../../06.%20AWS%20–%20Cloud%20Infrastructure/03-vpc-subnet/README.md)

---

## Final Compression

### Subnet Mask Basics

```
Subnet mask = Defines network boundary

255.255.255.0 means:
  First 3 octets = network (192.168.1)
  Last octet = hosts (0-255)
```

---

### CIDR Notation

```
Format: IP/Number

192.168.1.0/24
            └─ 24 network bits
               8 host bits remain

Formula:
  Total IPs = 2^(32 - CIDR)
  Usable = Total - 2
```

---

### The Essential CIDRs (Memorize)

```
/32 = 1 IP       (single host)
/24 = 256 IPs    (standard subnet)
/16 = 65,536 IPs (large network)
/8  = 16.7M IPs  (entire private range)
```

---

### Subnet Planning Rules

```
1. No overlap (check ranges)
2. Plan for growth (use 2-3x needed)
3. Consistent sizing (all /24 is easier)
4. Smaller CIDR = bigger network (/16 > /24)
5. Leave gaps for future expansion
```

---

### Mental Model

```
Subnetting = Dividing a network into smaller pieces

Why?
  Security (isolate systems)
  Organization (logical groups)
  Performance (smaller domains)

How?
  Subnet mask defines boundary
  CIDR notation is shorthand
```

---

### What You Can Do Now

✅ Calculate IPs from CIDR (/24 = 256 IPs)  
✅ Avoid subnet overlap conflicts  
✅ Choose appropriate subnet sizes  
✅ Understand subnet masks  
✅ Plan for growth and future expansion  

---

---

## What This Means for the Webstore

When you deploy the webstore to a server environment, you decide what subnet it lives in. A single server on a `/24` subnet shares that network with 253 other possible addresses. When you need to separate webstore-api from webstore-db for security — putting the database in a private subnet with no internet route — you need two subnets: one public (`10.0.1.0/24`) for the frontend and API tier, one private (`10.0.2.0/24`) for the database. Postgres lives on `10.0.2.50`. A browser on the internet cannot reach postgres directly — not because of a firewall rule, but because there is no route to that subnet from outside. This is the network design pattern AWS VPC implements, and you will lay it out exactly this way when you get there.

---

## What Breaks

| Symptom | Cause | First command to run |
|---|---|---|
| Two subnets overlap — AWS rejects the configuration | Miscalculated CIDR ranges | `ipcalc CIDR` on both — check if HostMin/HostMax ranges intersect |
| Instance in private subnet cannot reach the internet | No NAT Gateway route in the route table | Check route table — private subnets need `0.0.0.0/0 → NAT Gateway` |
| Instance in public subnet cannot reach the internet | No Internet Gateway route | Check route table — public subnets need `0.0.0.0/0 → IGW` |
| Two instances in different subnets cannot communicate | Missing local VPC route or Security Group blocking | Confirm both are in the same VPC — intra-VPC traffic uses the `local` route automatically |
| Database reachable from internet despite being private | Route table has `0.0.0.0/0 → IGW` — subnet is effectively public | Remove the IGW route from the db subnet's route table |

---

→ **Interview questions for this topic:** [99-interview-prep → Subnets · CIDR · IP Math](../99-interview-prep/README.md#subnets--cidr--ip-math)

→ Ready to practice? [Go to Lab 02](../networking-labs/02-devices-subnets-lab.md)

---
# SOURCE: 03. Networking – Foundations/06-ports-transport/README.md
---

# File 06: Ports & Transport Layer

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

# Ports & Transport Layer

## What this file is about

This file teaches **how applications are identified using port numbers** and **how data is delivered reliably**. If you understand this, you'll know why SSH uses port 22, how TCP guarantees delivery, when to use UDP, and how to configure firewall rules correctly. This is essential for deploying and troubleshooting applications.

<!-- no toc -->
- [The Core Problem](#the-core-problem)
- [What Are Ports?](#what-are-ports)
- [Common Port Numbers (Memorize These)](#common-port-numbers-memorize-these)
- [TCP vs UDP (The Two Protocols)](#tcp-vs-udp-the-two-protocols)
- [TCP: The Reliable Protocol](#tcp-the-reliable-protocol)
- [UDP: The Fast Protocol](#udp-the-fast-protocol)
- [Port Ranges and Categories](#port-ranges-and-categories)
- [The Socket Concept](#the-socket-concept)
- [Real Scenarios](#real-scenarios)  
[Final Compression](#final-compression)

---

## The Core Problem

### Your Original Question

**"Does the device have IP and the application also has IP?"**

**Short answer:** No.

**Correct model:**

```
Device has IP address    (identifies the computer)
Application has PORT     (identifies the application)

Format: IP:Port
Example: 192.168.1.45:80
         └──────────┘ └┘
         Device       Application
```

---

### The Scenario

**Your server has multiple applications running:**

```
Server IP: 192.168.1.100

Running applications:
- Web server (nginx)
- Database (PostgreSQL)
- SSH server
- Redis cache
- API application
```

**Problem:**  
A packet arrives at 192.168.1.100.  
**Which application should receive it?**

**Solution: Port numbers**

```
Web server:    192.168.1.100:80
Database:      192.168.1.100:5432
SSH:           192.168.1.100:22
Redis:         192.168.1.100:6379
API:           192.168.1.100:3000

Same IP, different ports
```

---

### Real-World Analogy

**IP address = Apartment building address**

```
123 Main Street
```

**Port number = Apartment number**

```
123 Main Street, Apartment 5
123 Main Street, Apartment 12
123 Main Street, Apartment 24

Same building (IP)
Different apartments (ports)
```

**Sending mail:**

```
Wrong: "Send to 123 Main Street"
  Which apartment? Unclear!

Right: "Send to 123 Main Street, Apartment 12"
  Specific destination
```

**Sending data:**

```
Wrong: "Send to 192.168.1.100"
  Which application? Unclear!

Right: "Send to 192.168.1.100:80"
  Specific application (web server)
```

---

## What Are Ports?

### Definition

**Port:**  
A 16-bit number (0-65535) that identifies a specific application or service on a device.

**Purpose:**  
Allow multiple applications to run on the same IP address without conflicts.

---

### How Ports Work

**Your laptop connects to a web server:**

```
Your laptop:
  IP: 192.168.1.45
  Source port: 54321 (random)

Web server:
  IP: 203.45.67.89
  Destination port: 80 (HTTP)

Connection format:
  192.168.1.45:54321 → 203.45.67.89:80
  └──────────────┘     └──────────────┘
  Source (you)         Destination (server)
```

---

### Port Number Format

**Range:**

```
0 - 65535 (16-bit number)

Total possible ports: 65,536
```

**In packet headers:**

```
TCP/UDP Header:
  Source Port:      54321
  Destination Port: 80
  ...other fields...
```

---

### Check Your Open Ports

**Linux/Mac:**

```bash
# Show all listening ports
sudo netstat -tlnp

# or
sudo ss -tlnp

Output:
Proto Local Address    State   PID/Program
tcp   0.0.0.0:22       LISTEN  1234/sshd
tcp   0.0.0.0:80       LISTEN  5678/nginx
tcp   127.0.0.1:5432   LISTEN  9012/postgres
```

**Windows:**

```cmd
netstat -ano

Output:
Proto  Local Address      Foreign Address    State       PID
TCP    0.0.0.0:80         0.0.0.0:0          LISTENING   4
TCP    0.0.0.0:443        0.0.0.0:0          LISTENING   4
TCP    127.0.0.1:5432     0.0.0.0:0          LISTENING   2508
```

---

## Common Port Numbers (Memorize These)

### Essential Ports for DevOps

**You MUST know these:**

| Port | Protocol | Service | Usage |
|------|----------|---------|-------|
| **20/21** | FTP | File Transfer Protocol | File uploads (legacy) |
| **22** | SSH | Secure Shell | Remote server access |
| **23** | Telnet | Telnet | Unsecure remote access (don't use) |
| **25** | SMTP | Email sending | Mail servers |
| **53** | DNS | Domain Name System | Name resolution |
| **80** | HTTP | Web traffic (unsecure) | Websites |
| **110** | POP3 | Email retrieval | Email clients |
| **143** | IMAP | Email retrieval | Email clients |
| **443** | HTTPS | Web traffic (secure) | Secure websites |
| **3306** | MySQL | MySQL database | Database connections |
| **5432** | PostgreSQL | PostgreSQL database | Database connections |
| **6379** | Redis | Redis cache | Cache/queue connections |
| **27017** | MongoDB | MongoDB database | NoSQL database |
| **3389** | RDP | Remote Desktop | Windows remote access |
| **8080** | HTTP Alt | Alternative HTTP | Dev servers, proxies |

---

### Application-Specific Ports

**Docker & Containers:**

```
2375 - Docker daemon (unencrypted)
2376 - Docker daemon (TLS)
```

**Kubernetes:**

```
6443 - Kubernetes API server
10250 - Kubelet API
```

**Message Queues:**

```
5672 - RabbitMQ
9092 - Kafka
```

**Monitoring:**

```
9090 - Prometheus
3000 - Grafana
9200 - Elasticsearch
5601 - Kibana
```

---

### Real Examples

**Accessing websites:**

```
http://google.com
  → Implicitly uses port 80
  → Browser connects to google.com:80

https://google.com
  → Implicitly uses port 443
  → Browser connects to google.com:443

http://localhost:3000
  → Explicitly uses port 3000
  → Browser connects to localhost:3000
```

**SSH to server:**

```bash
ssh user@192.168.1.100
  → Implicitly uses port 22
  → Connects to 192.168.1.100:22

ssh -p 2222 user@192.168.1.100
  → Explicitly uses port 2222
  → Connects to 192.168.1.100:2222
```

**Database connections:**

```
PostgreSQL:
  psql -h 192.168.1.100 -p 5432
  Connection string: postgresql://user:pass@192.168.1.100:5432/db

MySQL:
  mysql -h 192.168.1.100 -P 3306
  Connection string: mysql://user:pass@192.168.1.100:3306/db

MongoDB:
  mongo 192.168.1.100:27017
  Connection string: mongodb://192.168.1.100:27017/db
```

---

## TCP vs UDP (The Two Protocols)

### The Transport Layer

**Layer 4 (Transport) has two main protocols:**

```
1. TCP (Transmission Control Protocol)
   - Reliable, ordered, connection-oriented
   - Most common

2. UDP (User Datagram Protocol)
   - Fast, unordered, connectionless
   - Special use cases
```

---

### Side-by-Side Comparison

| Feature | TCP | UDP |
|---------|-----|-----|
| **Reliability** | Guaranteed delivery | No guarantee |
| **Ordering** | Packets arrive in order | May arrive out of order |
| **Connection** | Requires handshake | No connection setup |
| **Speed** | Slower (overhead) | Faster (minimal overhead) |
| **Error checking** | Yes (retransmits lost data) | Minimal |
| **Use cases** | Web, email, file transfer, databases | Video, gaming, DNS, VoIP |
| **Header size** | 20 bytes | 8 bytes |

---

### When to Use Which

**Use TCP when:**

```
✅ Data MUST arrive correctly
✅ Order matters
✅ Loss is unacceptable

Examples:
- Downloading files
- Loading web pages
- Database queries
- Email
- SSH connections
```

**Use UDP when:**

```
✅ Speed is critical
✅ Some data loss is acceptable
✅ Real-time is important

Examples:
- Live video streaming
- Online gaming
- VoIP (phone calls)
- DNS queries
- IoT sensor data
```

---

### Visual Comparison

**TCP (like certified mail):**

```
Sender → Post Office
  ↓
Acknowledgment: "We received it"
  ↓
Delivery to recipient
  ↓
Signature required
  ↓
Confirmation back to sender: "Delivered!"

Guarantees:
✅ Package arrives
✅ In correct order
✅ Recipient confirms receipt
```

**UDP (like shouting across the street):**

```
Sender → Yells message
  ↓
Hope recipient hears it

No guarantees:
❌ May not arrive
❌ May arrive out of order
❌ No confirmation

But: Very fast!
```

---

## TCP: The Reliable Protocol

### TCP Characteristics

```
✅ Connection-oriented (handshake required)
✅ Reliable (guarantees delivery)
✅ Ordered (packets reassembled correctly)
✅ Error-checked (detects corruption)
✅ Flow-controlled (adapts to network speed)
```

---

### TCP 3-Way Handshake

**Before data is sent, TCP establishes a connection:**

```
┌──────────┐                      ┌──────────┐
│  Client  │                      │  Server  │
└────┬─────┘                      └────┬─────┘
     │                                 │
     │  1. SYN (Synchronize)           │
     │  "I want to connect"            │
     ├────────────────────────────────>│
     │                                 │
     │                                 │ Check if port open
     │                                 │ Allocate resources
     │                                 │
     │  2. SYN-ACK (Synchronize-Ack)   │
     │  "OK, I'm ready"                │
     │<────────────────────────────────┤
     │                                 │
     │                                 │
     │  3. ACK (Acknowledge)           │
     │  "Great, let's start"           │
     ├────────────────────────────────>│
     │                                 │
     │  Connection established         │
     │  Data can now flow              │
     │<───────────────────────────────>│
```

---

### Step-by-Step Handshake

**Step 1: Client sends SYN**

```
Client → Server

TCP Header:
  Source Port:    54321
  Dest Port:      80
  Flags:          SYN
  Sequence:       1000
  
Message: "I want to connect to port 80"
```

**Step 2: Server responds with SYN-ACK**

```
Server → Client

TCP Header:
  Source Port:    80
  Dest Port:      54321
  Flags:          SYN, ACK
  Sequence:       5000
  Acknowledgment: 1001
  
Message: "I received your SYN (1000). 
          I'm ready. My sequence starts at 5000."
```

**Step 3: Client sends ACK**

```
Client → Server

TCP Header:
  Source Port:    54321
  Dest Port:      80
  Flags:          ACK
  Sequence:       1001
  Acknowledgment: 5001
  
Message: "I received your SYN-ACK (5000). Let's communicate."

Connection now ESTABLISHED
```

---

### TCP Data Transfer

**After handshake, data flows with acknowledgments:**

```
Client → Server: "Here's 100 bytes (seq 1001-1100)"
Server → Client: "Got it! (ack 1101)"

Client → Server: "Here's 100 bytes (seq 1101-1200)"
Server → Client: "Got it! (ack 1201)"

If packet lost:
Client → Server: "Here's 100 bytes (seq 1201-1300)"
Server: ... (no response)

Client waits for timeout
Client: "No ACK received, resend"
Client → Server: "Here's 100 bytes (seq 1201-1300)" (retry)
Server → Client: "Got it! (ack 1301)"
```

---

### TCP Connection Termination

**4-way termination (graceful close):**

```
┌──────────┐                      ┌──────────┐
│  Client  │                      │  Server  │
└────┬─────┘                      └────┬─────┘
     │                                 │
     │  1. FIN (Finish)                │
     │  "I'm done sending"             │
     ├────────────────────────────────>│
     │                                 │
     │  2. ACK                         │
     │  "OK, got it"                   │
     │<────────────────────────────────┤
     │                                 │
     │  3. FIN                         │
     │  "I'm also done"                │
     │<────────────────────────────────┤
     │                                 │
     │  4. ACK                         │
     │  "OK, closing"                  │
     ├────────────────────────────────>│
     │                                 │
     │  Connection closed              │
```

---

### Why TCP Matters for DevOps

**Debugging connection issues:**

```
Error: "Connection refused"
  Meaning: Server not listening on that port
  TCP reached server, but nothing on port 80

Error: "Connection timeout"
  Meaning: No response to SYN
  Firewall blocking, or server down

Error: "Connection reset"
  Meaning: Server abruptly closed connection
  Application crashed, or limit reached
```

**Check TCP connections:**

```bash
# Show established TCP connections
netstat -tn

# Show listening TCP ports
netstat -tln

# Count connections per port
netstat -tn | grep :80 | wc -l
```

---

## UDP: The Fast Protocol

### UDP Characteristics

```
✅ Connectionless (no handshake)
✅ Fast (minimal overhead)
✅ Low latency
❌ No reliability guarantee
❌ No ordering guarantee
❌ No retransmission
```

---

### How UDP Works

**No handshake, just send:**

```
┌──────────┐                      ┌──────────┐
│  Client  │                      │  Server  │
└────┬─────┘                      └────┬─────┘
     │                                 │
     │  UDP packet                     │
     │  "Here's some data"             │
     ├────────────────────────────────>│
     │                                 │
     │  (no acknowledgment)            │
     │                                 │
     │  Another UDP packet             │
     │  "Here's more data"             │
     ├────────────────────────────────>│
     │                                 │
     │  (no acknowledgment)            │
     │                                 │
     │  No connection state            │
     │  No reliability                 │
     │  Just send and hope             │
```

---

### UDP Packet Structure

**Much simpler than TCP:**

```
UDP Header (8 bytes):
  Source Port:      53
  Destination Port: 54321
  Length:           56 bytes
  Checksum:         0x1A2B

Payload:
  DNS response data
  
That's it! No sequence, no ack, no flags.
```

---

### Why Use UDP?

**DNS queries (perfect UDP use case):**

```
You: "What's google.com's IP?"
  UDP packet to 8.8.8.8:53
  Small query (< 512 bytes)
  
DNS server: "142.250.190.46"
  UDP packet back
  Small response
  
Total time: ~10ms

If UDP packet lost? Send again.
Lost rate: <1%
Speed gain: Significant (no handshake)
```

**Live video streaming:**

```
Video frames sent via UDP
  Frame 1 → (sent)
  Frame 2 → (sent)
  Frame 3 → (lost!) ❌
  Frame 4 → (sent)
  Frame 5 → (sent)

Result: Slight glitch (Frame 3 missing)
Better than: Buffering while waiting for retransmit

User experience: Smooth (acceptable glitch)
```

**Online gaming:**

```
Player position updates:
  Position at T=0ms  → (sent via UDP)
  Position at T=50ms → (sent via UDP)
  Position at T=100ms → (lost!) ❌
  Position at T=150ms → (sent via UDP)

Missing one position update? No problem.
Next update arrives with current position.
Better than TCP delay from retransmit.
```

---

### UDP vs TCP Example

**Downloading a file (use TCP):**

```
TCP:
  100% of file arrives
  Every byte verified
  Correct order
  Download time: 10 seconds
  
UDP:
  98% of file arrives (2% lost)
  File corrupted
  Unusable
  Download time: 8 seconds (but useless!)
```

**VoIP call (use UDP):**

```
UDP:
  2% packets lost
  Slight audio glitch
  Real-time conversation
  Latency: 50ms
  
TCP:
  100% packets arrive
  No glitches
  But: Stuttering from retransmits
  Latency: 200-500ms (unacceptable delay)
```

---

### Common UDP Services

| Port | Service | Why UDP? |
|------|---------|----------|
| **53** | DNS | Small queries, speed critical |
| **67/68** | DHCP | Small broadcast messages |
| **123** | NTP (time sync) | Speed, periodic updates |
| **161/162** | SNMP (monitoring) | Speed, many small queries |
| **514** | Syslog | Fire-and-forget logging |
| **Various** | Video/Audio streaming | Real-time, loss acceptable |
| **Various** | Online gaming | Low latency critical |

---

## Port Ranges and Categories

### The Three Ranges

**0-1023: Well-Known Ports**

```
Assigned by IANA
System/privileged services only
Require root/admin to bind

Examples:
  22  - SSH
  80  - HTTP
  443 - HTTPS
```

**1024-49151: Registered Ports**

```
Registered for specific services
Can be used by regular users
Companies register their software ports

Examples:
  3306  - MySQL
  5432  - PostgreSQL
  27017 - MongoDB
  3000  - Many dev servers
  8080  - Alternative HTTP
```

**49152-65535: Dynamic/Private Ports**

```
Ephemeral ports
Used for client-side connections
Randomly assigned by OS

Example:
  Your browser connects to server:
    Source port: 54321 (random from this range)
    Dest port: 443 (server's HTTPS port)
```

---

### Binding Ports (Server vs Client)

**Server behavior (binds to specific port):**

```
Web server:
  Binds to port 80
  Listens for connections
  Port doesn't change

Code:
  socket.bind(("0.0.0.0", 80))
  socket.listen()
```

**Client behavior (uses random port):**

```
Your browser:
  Connects to google.com:443
  Uses random source port: 54321
  Different for each connection

Next connection:
  Source port: 54322 (different)
```

---

### Check Port Availability

**Linux/Mac:**

```bash
# Check if port 80 is in use
sudo lsof -i :80

# Check if port available
nc -zv localhost 80

# Test TCP connection
telnet localhost 80

# Test UDP connection
nc -u localhost 53
```

**Why ports might be unavailable:**

```
1. Another application using it
   Error: "Address already in use"
   
2. Insufficient privileges
   Error: "Permission denied" (ports < 1024)
   
3. Firewall blocking
   Error: "Connection refused" or timeout
```

---

## The Socket Concept

### What Is a Socket?

**Socket:**  
A combination of IP address + port number + protocol.

**Format:**

```
Protocol://IP:Port

Examples:
  tcp://192.168.1.100:80
  udp://8.8.8.8:53
  tcp://[::1]:443 (IPv6)
```

---

### Socket as Endpoint

**Communication requires two sockets:**

```
Client socket:
  tcp://192.168.1.45:54321

Server socket:
  tcp://192.168.1.100:80

Connection:
  192.168.1.45:54321 ←→ 192.168.1.100:80
```

---

### Multiple Connections to Same Server

**Server can handle many clients on same port:**

```
Server: 192.168.1.100:80

Connection 1:
  Client A (192.168.1.45:54321) → Server (192.168.1.100:80)

Connection 2:
  Client B (192.168.1.67:54322) → Server (192.168.1.100:80)

Connection 3:
  Client C (192.168.1.89:54323) → Server (192.168.1.100:80)

Server distinguishes by:
  Different source IP + source port combinations
```

---

### Socket States (TCP)

**TCP sockets have states:**

```
LISTEN      - Server waiting for connections
SYN_SENT    - Client sent SYN, waiting for SYN-ACK
ESTABLISHED - Connection active
FIN_WAIT    - Closing connection
TIME_WAIT   - Connection closed, waiting for delayed packets
CLOSED      - Socket closed
```

**Check socket states:**

```bash
netstat -tn

Output:
Proto Recv-Q Send-Q Local Address      Foreign Address    State
tcp   0      0      192.168.1.45:54321 142.250.190.46:443 ESTABLISHED
tcp   0      0      192.168.1.45:54322 93.184.216.34:80   TIME_WAIT
tcp   0      0      0.0.0.0:22         0.0.0.0:*          LISTEN
```

---

## Real Scenarios

### Scenario 1: Web Server Configuration

**nginx configuration:**

```nginx
server {
    listen 80;                    # HTTP
    listen [::]:80;               # HTTP (IPv6)
    server_name example.com;
    
    return 301 https://$server_name$request_uri;  # Redirect to HTTPS
}

server {
    listen 443 ssl;               # HTTPS
    listen [::]:443 ssl;          # HTTPS (IPv6)
    server_name example.com;
    
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    
    location / {
        proxy_pass http://localhost:3000;  # Forward to app on port 3000
    }
}
```

**Port usage:**

```
Port 80:  Public-facing HTTP (redirects to 443)
Port 443: Public-facing HTTPS (SSL/TLS)
Port 3000: Internal application server (not exposed)
```

---

### Scenario 2: Docker Port Binding

**Expose container port to host:**

```bash
# Run nginx container
docker run -d -p 8080:80 nginx

# Breakdown:
#   -p 8080:80
#      │    │
#      │    └─ Container port (nginx listens on 80)
#      └────── Host port (accessible at localhost:8080)

# Access:
curl http://localhost:8080
  → Routes to container's port 80
```

**Multiple port mappings:**

```bash
docker run -d \
  -p 80:80 \       # HTTP
  -p 443:443 \     # HTTPS
  -p 3306:3306 \   # MySQL
  nginx
```

---

### Scenario 3: AWS Security Group Rules

**Allow web traffic:**

```
Inbound Rules:

Type     Protocol  Port Range  Source       Description
HTTP     TCP       80          0.0.0.0/0    Allow HTTP from anywhere
HTTPS    TCP       443         0.0.0.0/0    Allow HTTPS from anywhere
SSH      TCP       22          203.0.113.0/24  Allow SSH from office IP only
Custom   TCP       3000        10.0.1.0/24  Allow internal API access
```

**Common mistake:**

```
❌ Wrong: Open all ports
   Port Range: 0-65535
   Risk: Exposes unnecessary services

✅ Right: Only open needed ports
   Ports: 22, 80, 443
   Principle of least privilege
```

---

### Scenario 4: Debugging Connection Issues

**Can't connect to database:**

```bash
# Step 1: Check if database listening
sudo netstat -tlnp | grep 5432

Output:
tcp  0.0.0.0:5432  LISTEN  1234/postgres

✓ Database is listening on port 5432

# Step 2: Try to connect locally
psql -h localhost -p 5432

✓ Works locally

# Step 3: Try from remote
psql -h 192.168.1.100 -p 5432

✗ Connection timeout

# Conclusion: Firewall blocking port 5432
```

**Fix:**

```bash
# Ubuntu/Debian
sudo ufw allow 5432/tcp

# CentOS/RHEL
sudo firewall-cmd --add-port=5432/tcp --permanent
sudo firewall-cmd --reload
```

---

### Scenario 5: Multi-Service Server

**One server running multiple services:**

```
Server IP: 192.168.1.100

Services:
├─ SSH:        Port 22      (secure remote access)
├─ Web:        Port 80      (public HTTP)
├─ Web SSL:    Port 443     (public HTTPS)
├─ PostgreSQL: Port 5432    (internal database)
├─ Redis:      Port 6379    (internal cache)
└─ API:        Port 8000    (internal API)

Firewall rules:
  Port 22:   Allow from 203.0.113.0/24 (office)
  Port 80:   Allow from 0.0.0.0/0 (everyone)
  Port 443:  Allow from 0.0.0.0/0 (everyone)
  Port 5432: Allow from 192.168.1.0/24 (local network)
  Port 6379: Allow from 192.168.1.0/24 (local network)
  Port 8000: Allow from 192.168.1.0/24 (local network)
```

---

## Final Compression

### What Are Ports?

```
Port = 16-bit number (0-65535)
Purpose: Identify applications on a device

Format: IP:Port
  192.168.1.100:80  (web server)
  192.168.1.100:5432 (database)

Same IP, different applications
```

---

### Essential Ports (Memorize)

```
22   - SSH (remote access)
53   - DNS (name resolution)
80   - HTTP (web unsecure)
443  - HTTPS (web secure)
3306 - MySQL
5432 - PostgreSQL
6379 - Redis
27017 - MongoDB
```

---

### TCP vs UDP

**TCP (Reliable):**
```
✅ Guaranteed delivery
✅ Ordered packets
✅ 3-way handshake (SYN, SYN-ACK, ACK)
✅ Use for: Web, email, databases, file transfer
```

**UDP (Fast):**
```
✅ No handshake
✅ Low latency
❌ No guarantee
✅ Use for: DNS, video streaming, gaming, VoIP
```

---

### TCP 3-Way Handshake

```
Client → Server: SYN ("Let's connect")
Server → Client: SYN-ACK ("OK, ready")
Client → Server: ACK ("Great!")

Connection established
```

---

### Port Ranges

```
0-1023:       Well-known (system services)
1024-49151:   Registered (applications)
49152-65535:  Dynamic (client connections)
```

---

### Socket = IP + Port + Protocol

```
tcp://192.168.1.45:54321 → tcp://192.168.1.100:80
└────────────────────┘      └────────────────────┘
Client socket               Server socket
```

---

### Common Errors

```
"Connection refused"
  → Port not listening
  → Check: netstat -tln | grep PORT

"Connection timeout"
  → Firewall blocking or server down
  → Check: firewall rules

"Address already in use"
  → Port taken by another app
  → Check: lsof -i :PORT
```

---

### Mental Model

```
IP address = Apartment building
Port number = Apartment number

One building (192.168.1.100)
Many apartments:
  :22   (SSH)
  :80   (HTTP)
  :443  (HTTPS)
  :5432 (PostgreSQL)

Mail delivery needs both:
  Building address + Apartment number
  IP address + Port number
```

---

### What You Can Do Now

✅ Understand what ports are (application identifiers)  
✅ Know common port numbers (22, 80, 443, 3306, 5432)  
✅ Understand TCP vs UDP differences  
✅ Know TCP 3-way handshake  
✅ Configure firewall rules with correct ports  
✅ Debug port-related connection issues  
✅ Map Docker container ports  

---

---

## What This Means for the Webstore

Three services, one server, three ports. nginx on 80, webstore-api on 8080, postgres on 5432. When a connection arrives at the server's IP, the OS reads the destination port and delivers it to the right process. When you check `ss -tlnp` on the webstore server, you will see `0.0.0.0:80` for nginx (listening on all interfaces), `0.0.0.0:8080` for the API, and `127.0.0.1:5432` for postgres (loopback only). That single difference in binding address tells you everything about what is and is not reachable from outside. Reading `ss` output is how you verify a service is actually listening before you debug anything else.

---

→ **Interview questions for this topic:** [99-interview-prep → TCP vs UDP · Ports · Three-Way Handshake](../99-interview-prep/README.md#tcp-vs-udp--ports--three-way-handshake)

→ Ready to practice? [Go to Lab 03](../networking-labs/03-ports-transport-nat-lab.md)

---
# SOURCE: 03. Networking – Foundations/07-nat/README.md
---

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
┌─────────────────────────────────────┐
│           Your Router               │
│                                     │
│  LAN Side (Internal):               │
│    IP:  192.168.1.1                 │
│    MAC: AA:BB:CC:DD:EE:FF           │
│    Private, not internet-routable   │
│                                     │
│  WAN Side (External):               │
│    IP:  203.45.67.89                │
│    MAC: 11:22:33:44:55:66           │
│    Public, internet-routable        │
│    Assigned by ISP via DHCP         │
│                                     │
└─────────────────────────────────────┘
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
│  ┌─────────────────────┐                                 │
│  │  Router / NAT       │                                 │
│  │                     │                                 │
│  │  LAN: 192.168.1.1   │                                 │
│  │  WAN: 203.45.67.89  │                                 │
│  │                     │                                 │
│  │  NAT Table:         │                                 │
│  │  192.168.1.45:54321 │                                 │
│  │    ↔ 203.45.67.89:54321                               │
│  └─────────────────────┘                                 │
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
192.168.1.67:51234 → 203.45.67.89:49153

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

---

## What This Means for the Webstore

The webstore server has a private IP on the network — `10.0.1.45` or similar. When it receives a request from a browser on the internet, that request arrived at the public IP of the router, which NAT-translated it inbound to `10.0.1.45`. The browser never knew the server's private IP. When the server responds, the router translates the source IP back to public before sending it out. This NAT process is invisible in both directions. When you later configure `docker run -p 8080:80`, Docker is creating a DNAT rule in iptables — the exact same mechanism described in this file, applied at the container level. The concept is identical. The scope is smaller.

---

→ **Interview questions for this topic:** [99-interview-prep → NAT · Port Forwarding · Translation](../99-interview-prep/README.md#nat--port-forwarding--translation)

→ Ready to practice? [Go to Lab 03](../networking-labs/03-ports-transport-nat-lab.md)

---
# SOURCE: 03. Networking – Foundations/08-dns/README.md
---

# File 08: DNS

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

# DNS (Domain Name System)

## What this file is about

This file teaches **how domain names are translated into IP addresses** and **how the DNS system works globally**. If you understand this, you'll know why websites sometimes load slowly, how caching and TTL affect changes, and how to debug DNS issues. How Docker and AWS implement DNS on top of these concepts is covered in their respective notes.

<!-- no toc -->
- [The Core Problem](#the-core-problem)
- [What Is DNS?](#what-is-dns)
- [How DNS Resolution Works](#how-dns-resolution-works)
- [DNS Record Types](#dns-record-types)
- [DNS Caching](#dns-caching)
- [DNS Servers and Hierarchy](#dns-servers-and-hierarchy)
- [Public DNS Servers](#public-dns-servers)
- [DNS Debugging](#dns-debugging)  
[Final Compression](#final-compression)

---

## The Core Problem

### The Human vs Computer Challenge

**Humans prefer names:**

```
google.com
github.com
stackoverflow.com
mycompany.internal
```

**Computers need IP addresses:**

```
142.250.190.46
140.82.121.4
151.101.1.69
10.0.1.50
```

**The problem:** How do we bridge this gap?

---

### Before DNS (The Dark Ages)

**1970s-1980s: hosts.txt file**

```
Every computer had a file: /etc/hosts

Contents:
10.1.1.5    server1
10.1.1.6    server2
10.1.1.7    database

Problem:
  - Manual updates
  - No central authority
  - Didn't scale
  - File grew huge
```

**Stanford Research Institute maintained master hosts.txt — this broke when internet grew beyond a few hundred hosts.**

---

### The DNS Solution (1983)

**Distributed, hierarchical, automated system:**

```
✅ No single file to maintain
✅ Automatic lookups
✅ Scales globally
✅ Distributed authority
✅ Caching for speed
```

---

## What Is DNS?

### Definition

**DNS = Domain Name System**

**Purpose:** Translate human-readable domain names into IP addresses.

**Analogy:** DNS is like a phone book for the internet.

```
Phone book:
  Name: "Pizza Place" → Phone: 555-1234

DNS:
  Domain: google.com → IP: 142.250.190.46
```

---

### DNS Is a Distributed Database

**Not one server, but millions:**

```
Root DNS servers:        13 worldwide
Top-level domain (TLD):  Hundreds (.com, .org, .uk, etc.)
Authoritative servers:   Millions (each domain has one)
Recursive resolvers:     Thousands (ISPs, Google, Cloudflare)
```

---

## How DNS Resolution Works

### The Complete DNS Query Process

**You type `www.google.com` in browser:**

---

### Step 1: Check Local Cache

```
Browser: "Have I looked up www.google.com recently?"

If cached and not expired:
  Use cached IP
  Done! (milliseconds)
```

---

### Step 2: Check OS Cache

```
Operating system cache check

If cached:
  Return IP to browser
  Done!
```

---

### Step 3: Check /etc/hosts File

```
/etc/hosts contains:
  127.0.0.1       localhost
  192.168.1.100   myserver.local

If www.google.com is in this file:
  Use that IP (manual override)
```

---

### Step 4: Query Recursive DNS Resolver

**Your computer asks configured DNS server:**

```
Your DNS server (configured in network settings):
  8.8.8.8 (Google DNS)
  or 1.1.1.1 (Cloudflare)
  or 192.168.1.1 (Router)

Query sent via UDP port 53:
  "What's the IP for www.google.com?"
```

---

### Step 5-8: Root → TLD → Authoritative → Answer

```
Recursive resolver → Root server
  "I don't know, but .com TLD is at 192.5.6.30"

Recursive resolver → .com TLD server
  "I don't know, but google.com's NS is ns1.google.com"

Recursive resolver → ns1.google.com
  "www.google.com = 142.250.190.46" ← Final answer

Resolver caches result (TTL: 300s)
Returns to your browser
```

---

### Visual: Complete DNS Resolution

```
┌──────────────┐
│  Your Browser│
└──────┬───────┘
       │ 1. "What's google.com?"
       ▼
┌──────────────────────────┐
│ Browser Cache → OS Cache │
│ /etc/hosts → All miss    │
└──────┬───────────────────┘
       │ 2. UDP query to DNS server
       ▼
┌─────────────────────────┐
│ Recursive Resolver      │
│ (8.8.8.8) — cache miss  │
└──────┬──────────────────┘
       │ 3. Root servers
       │ 4. .com TLD
       │ 5. google.com NS
       ▼
┌─────────────────────────┐
│ Authoritative Server    │
│ (ns1.google.com)        │
│ "142.250.190.46"        │
└──────┬──────────────────┘
       │ 6. Answer returned + cached
       ▼
┌────────────────┐
│ Your Browser   │
│ Connects to    │
│ 142.250.190.46 │
└────────────────┘
```

---

### Timing Breakdown

```
First query (cache miss):   ~70ms total
Subsequent queries (hit):   <1ms (cached)

This is why first page load feels slower.
```

---

## DNS Record Types

### Common Record Types

---

### A Record (Address)

**Maps domain to IPv4 address:**

```
google.com.        300    IN    A    142.250.190.46
```

**Use case:** Most common, points domain to server IP.

---

### AAAA Record (IPv6 Address)

**Maps domain to IPv6 address:**

```
google.com.    300    IN    AAAA    2607:f8b0:4004:c07::71
```

---

### CNAME Record (Canonical Name)

**Alias one domain to another:**

```
www.example.com.    300    IN    CNAME    example.com.
```

**Use case:** Aliases, subdomains pointing to main domain.

---

### MX Record (Mail Exchange)

**Specifies mail server:**

```
example.com.    300    IN    MX    10 mail.example.com.
```

**Priority:** Lower number = higher priority.

---

### TXT Record (Text)

**Arbitrary text data:**

```
example.com.    300    IN    TXT    "v=spf1 include:_spf.google.com ~all"
```

**Common uses:** SPF, DKIM, domain verification.

---

### NS Record (Name Server)

**Specifies authoritative DNS servers:**

```
google.com.    300    IN    NS    ns1.google.com.
```

---

### PTR Record (Pointer — Reverse DNS)

**Maps IP address to domain:**

```
46.190.250.142.in-addr.arpa.    IN    PTR    google.com.
```

**Use case:** Email servers (anti-spam), verification.

---

### Record Type Summary

| Type | Purpose | Example |
|------|---------|---------|
| **A** | IPv4 address | example.com → 93.184.216.34 |
| **AAAA** | IPv6 address | example.com → 2606:... |
| **CNAME** | Alias | www → example.com |
| **MX** | Mail server | Mail to mail.example.com |
| **TXT** | Text data | SPF, DKIM, verification |
| **NS** | Nameserver | Delegates to ns1.example.com |
| **PTR** | Reverse lookup | IP → domain |

---

## DNS Caching

### Why Caching Exists

**Without caching:**

```
Every page load = DNS query = 70ms overhead
100 queries/second = slow
```

**With caching:**

```
First query: 70ms (full lookup)
Next 299 seconds: <1ms (cached)
```

---

### Caching Layers

```
1. Browser cache          — respects TTL
2. Operating system cache — respects TTL
3. Recursive resolver     — respects TTL (all users benefit)
4. Authoritative server   — source of truth (doesn't cache)
```

---

### TTL (Time To Live)

**TTL = How long to cache the record**

```
example.com.    300    IN    A    93.184.216.34
                └─┘
                TTL (seconds)

300 seconds = 5 minutes
```

**Common TTL values:**

```
60 seconds    - Frequently changing (during migrations)
300 seconds   - Common default (5 minutes)
3600 seconds  - Standard (1 hour)
86400 seconds - Long-term stable (24 hours)
```

---

### TTL Impact

**Short TTL (60 seconds):**

```
✅ Changes propagate quickly
✅ Good for deployments/migrations
❌ More DNS queries
```

**Long TTL (86400 seconds):**

```
✅ Fewer queries, better performance
❌ Changes take 24 hours to propagate
```

**Best practice:**

```
Normal operation:  Long TTL (3600-86400s)
Before changes:    Reduce TTL (60-300s)
After changes:     Restore long TTL
```

---

### DNS Propagation

**"DNS propagation" = cache expiration worldwide**

```
Old record: example.com → 1.2.3.4 (TTL: 3600s)
Change to:  example.com → 5.6.7.8

Propagation time: up to 1 hour (old TTL)

Best practice: Reduce TTL to 60s first, wait for old TTL to expire,
then make the change. Propagates in 60 seconds.
```

---

### Flush DNS Cache

**Windows:**
```cmd
ipconfig /flushdns
```

**Mac:**
```bash
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder
```

**Linux (systemd-resolved):**
```bash
sudo systemd-resolve --flush-caches
```

---

## DNS Servers and Hierarchy

### The DNS Hierarchy

```
                    . (Root)
                    │
        ┌───────────┼───────────┐
        │           │           │
       .com        .org        .net  (TLDs)
        │
    ┌───┴───┐
 google.com  example.com
```

---

### Root DNS Servers

**13 root server clusters (labeled A-M):**

```
a.root-servers.net ... m.root-servers.net

Actually hundreds of servers worldwide
Anycast routing to nearest instance
```

**Root servers know:** All TLD servers. NOT individual domains.

---

### TLD Servers

**Top-Level Domain servers:**

```
Generic TLDs: .com, .org, .net, .info
Country code: .us, .uk, .de, .jp
New TLDs:     .io, .dev, .app, .cloud
```

**TLD servers know:** Authoritative nameservers for domains under that TLD. NOT actual IPs.

---

### Authoritative DNS Servers

**Final authority for a domain:**

```
Google's authoritative servers:
  ns1.google.com, ns2.google.com, ns3.google.com, ns4.google.com

These contain the actual DNS records.
```

---

### Recursive Resolvers

**Do the heavy lifting:**

```
Examples:
  Google Public DNS: 8.8.8.8, 8.8.4.4
  Cloudflare: 1.1.1.1, 1.0.0.1

Job:
  1. Receive query from client
  2. Query root → TLD → authoritative
  3. Cache the result
  4. Return answer to client
```

---

## Public DNS Servers

### Popular Public DNS Providers

**Google Public DNS:**

```
Primary:   8.8.8.8
Secondary: 8.8.4.4

✅ Fast and reliable
❌ Google logs queries
```

**Cloudflare DNS:**

```
Primary:   1.1.1.1
Secondary: 1.0.0.1

✅ Often fastest
✅ Privacy-focused
✅ Malware blocking available (1.1.1.2)
```

**Quad9:**

```
Primary:   9.9.9.9
Secondary: 149.112.112.112

✅ Blocks malicious domains
✅ Privacy-focused
```

---

### Configure DNS Servers

**Linux (systemd-resolved):**

```bash
# Edit /etc/systemd/resolved.conf
[Resolve]
DNS=1.1.1.1 8.8.8.8
FallbackDNS=1.0.0.1 8.8.4.4

sudo systemctl restart systemd-resolved
```

**Linux (old method):**

```bash
# Edit /etc/resolv.conf
nameserver 1.1.1.1
nameserver 8.8.8.8
```

---

### Why Use Public DNS

```
✅ Often faster
✅ More reliable
✅ Better privacy (some providers)
✅ Malware/ad blocking (some providers)
✅ Bypass ISP DNS hijacking
```

---

> **Docker implementation:** Docker runs an embedded DNS server at `127.0.0.11` on every custom network. Containers resolve each other by name automatically — no manual IP management needed. The full DNS setup with verification commands is in the Docker notes.
> → [Docker Networking](../../04.%20Docker%20–%20Containerization/05-docker-networking/README.md)

> **AWS implementation:** AWS Route 53 is a globally distributed DNS service with routing policies (latency, weighted, failover, geolocation), health checks, and tight AWS integration. The full Route 53 setup with Terraform examples is in the AWS notes.
> → [AWS Route 53](../../06.%20AWS%20–%20Cloud%20Infrastructure/13-route53/README.md)

---

## DNS Debugging

### Common DNS Tools

---

### nslookup

**Basic DNS lookup:**

```bash
nslookup google.com

Output:
Server:         8.8.8.8
Address:        8.8.8.8#53

Non-authoritative answer:
Name:   google.com
Address: 142.250.190.46
```

**Query specific DNS server:**

```bash
nslookup google.com 1.1.1.1
```

**Query specific record type:**

```bash
nslookup -type=MX google.com
```

---

### dig (More detailed)

**Basic query:**

```bash
dig google.com

;; ANSWER SECTION:
google.com.    300    IN    A    142.250.190.46

;; Query time: 23 msec
;; SERVER: 8.8.8.8#53
```

**Short format:**

```bash
dig google.com +short
```

**Trace full resolution path:**

```bash
dig +trace google.com
```

**Query specific record type:**

```bash
dig MX google.com
dig AAAA google.com
dig TXT google.com
dig NS google.com
```

---

### Debugging Workflow

**Step 1: Can you resolve the name?**

```bash
nslookup example.com

If fails:
  - DNS server unreachable
  - Domain doesn't exist
  - Network issue
```

**Step 2: What IP did it resolve to?**

```bash
dig example.com +short

If wrong IP:
  - DNS cache stale (flush cache)
  - DNS propagation in progress
  - Wrong DNS record configured
```

**Step 3: Can you reach the IP?**

```bash
ping 93.184.216.34

If fails → Firewall or network issue
If succeeds → DNS is fine, problem is application-level
```

**Step 4: Check from different DNS servers**

```bash
dig @8.8.8.8 example.com
dig @1.1.1.1 example.com

If different results → DNS propagation issue
```

**Step 5: Trace full path**

```bash
dig +trace example.com
```

---

### Common DNS Issues

**Issue 1: NXDOMAIN**
```
Causes: Typo in domain, domain not registered, record not created
Fix: Check spelling, verify domain ownership, create DNS records
```

**Issue 2: Timeout**
```
Causes: DNS server unreachable, firewall blocking port 53
Fix: Try different DNS server, check firewall rules
```

**Issue 3: Wrong IP returned**
```
Causes: Stale cache, wrong DNS record, DNS hijacking
Fix: Flush DNS cache, verify authoritative record, use public DNS
```

**Issue 4: Slow resolution**
```
Causes: Slow DNS server, network latency
Fix: Switch to faster DNS (1.1.1.1)
```

---

## Final Compression

### What Is DNS?

```
DNS = Phone book for the internet

Domain name → IP address
  google.com → 142.250.190.46
```

---

### DNS Resolution Process

```
1. Check browser cache
2. Check OS cache
3. Check /etc/hosts
4. Query recursive resolver (8.8.8.8)
5. Resolver: root → TLD → authoritative
6. Return answer
7. Cache at all levels
```

---

### DNS Record Types (Essential)

```
A      - Domain to IPv4
AAAA   - Domain to IPv6
CNAME  - Alias (www → example.com)
MX     - Mail server
TXT    - Text data (SPF, verification)
NS     - Nameserver delegation
```

---

### TTL (Time To Live)

```
60s     - Short (migrations)
300s    - Common default
3600s   - Standard (1 hour)
86400s  - Long (24 hours)

Lower TTL = Faster changes, more queries
Higher TTL = Slower changes, fewer queries
```

---

### Public DNS Servers

```
Google:     8.8.8.8, 8.8.4.4
Cloudflare: 1.1.1.1, 1.0.0.1
Quad9:      9.9.9.9
```

---

### DNS Debugging

```
nslookup google.com     - Basic lookup
dig google.com          - Detailed lookup
dig +trace google.com   - Full path trace

Flush cache:
  Windows: ipconfig /flushdns
  Mac:     sudo killall -HUP mDNSResponder
  Linux:   sudo systemd-resolve --flush-caches
```

---

### Mental Model

```
DNS = Global distributed database

Your query:
  "What's google.com?"

DNS journey:
  Your computer → Resolver → Root → TLD → Authoritative
  
Answer: "142.250.190.46"
Cached everywhere for speed
Expires after TTL
```

---

### What You Can Do Now

✅ Understand how DNS resolution works  
✅ Know common DNS record types  
✅ Configure public DNS servers  
✅ Debug DNS issues with dig/nslookup  
✅ Understand DNS caching and TTL  
✅ Plan DNS changes with TTL reduction  

---

---

## What This Means for the Webstore

When you register `webstore.example.com` and create an A record pointing to the server's public IP, every browser goes through the full DNS resolution chain before it can connect. The TTL on that A record controls how long DNS caches the answer. If you move the webstore to a new server, old DNS caches will keep sending traffic to the old IP until the TTL expires — this is why DNS changes always require a propagation wait. On the server itself, adding an entry like `10.0.1.50 webstore-db` to `/etc/hosts` lets the API connect to the database by hostname without a real DNS server. The OS resolves it locally, the query never goes to a DNS server, and the connection works.

---

→ **Interview questions for this topic:** [99-interview-prep → DNS · Resolution · Records](../99-interview-prep/README.md#dns--resolution--records)

→ Ready to practice? [Go to Lab 04](../networking-labs/04-dns-firewalls-lab.md)

---
# SOURCE: 03. Networking – Foundations/09-firewalls/README.md
---

# File 09: Firewalls & Security

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

# Firewalls & Security

## What this file is about

This file teaches **how to control network access using firewall rules** and **the critical difference between stateful and stateless firewalls**. If you understand this, you'll be able to reason about any firewall — Linux iptables, AWS Security Groups, AWS NACLs, Docker network rules. The universal concepts are here. How AWS implements stateful and stateless firewalls on top of these concepts is covered in the AWS notes.

<!-- no toc -->
- [The Core Problem](#the-core-problem)
- [What Is a Firewall?](#what-is-a-firewall)
- [Firewall Rules (The Basics)](#firewall-rules-the-basics)
- [Stateful vs Stateless (CRITICAL)](#stateful-vs-stateless-critical)
- [Linux Firewall — iptables](#linux-firewall--iptables)
- [Common Firewall Scenarios](#common-firewall-scenarios)
- [Production Debugging Framework](#production-debugging-framework)  
[Final Compression](#final-compression)

---

## The Core Problem

### Unrestricted Access Is Dangerous

**Scenario: Server with no firewall**

```
Your web server: 203.45.67.89

Open ports:
├─ 22   (SSH)
├─ 80   (HTTP)
├─ 443  (HTTPS)
├─ 3306 (MySQL)
├─ 5432 (PostgreSQL)
└─ 6379 (Redis)

Attacker from 123.45.67.89:
  ✅ Can try SSH brute force (port 22)
  ✅ Can access database directly (port 3306)
  ✅ Can connect to Redis (port 6379)

Result: Security nightmare
```

---

### What You Actually Need

**Principle of least privilege:**

```
✅ Allow HTTP from anyone (port 80)
✅ Allow HTTPS from anyone (port 443)
✅ Allow SSH from office only (port 22 from 203.0.113.0/24)
❌ Block database ports from internet (3306, 5432)
❌ Block Redis from internet (6379)

Only expose what's necessary
Restrict everything else
```

---

## What Is a Firewall?

### Definition

**Firewall:**  
A network security system that monitors and controls incoming and outgoing network traffic based on predetermined security rules.

---

### Firewall Placement

**Network firewall (between networks):**

```
┌──────────────┐         ┌──────────┐         ┌──────────┐
│   Internet   │ ←────→  │ Firewall │ ←────→  │ Internal │
│              │         │          │         │ Network  │
└──────────────┘         └──────────┘         └──────────┘
```

**Host-based firewall (on server):**

```
┌────────────────────────────────┐
│     Server (203.45.67.89)      │
│                                │
│  ┌──────────────────────────┐  │
│  │   Firewall (iptables)    │  │
│  │  Allow 80, 443           │  │
│  │  Allow 22 from office    │  │
│  │  Block everything else   │  │
│  └──────────────────────────┘  │
│               │                │
│       ┌───────┴────────┐       │
│       │   Application  │       │
│       └────────────────┘       │
└────────────────────────────────┘
```

---

### Firewall Types

**Packet filtering (Layer 3-4):**

```
Examines: Source IP, Destination IP, ports, protocol
Decision: Allow or deny
Examples: iptables, AWS Security Groups, NACLs
```

**Stateful inspection (Layer 3-4, connection-aware):**

```
Tracks connection state
Remembers outbound requests
Auto-allows return traffic
Examples: AWS Security Groups, modern firewalls
```

**Application layer (Layer 7):**

```
Inspects application data
Can block based on URLs, HTTP headers, content
Examples: Web Application Firewall (WAF), proxy servers
```

---

## Firewall Rules (The Basics)

### Rule Components

**Every firewall rule specifies:**

```
1. Direction (inbound or outbound)
2. Protocol (TCP, UDP, ICMP, or ALL)
3. Port range (22, 80, 443, or range)
4. Source (where traffic comes FROM)
5. Destination (where traffic goes TO)
6. Action (ALLOW or DENY)
```

---

### Rule Example (Inbound)

```
Rule: Allow SSH from office

Direction:   Inbound
Protocol:    TCP
Port:        22
Source:      203.0.113.0/24 (office network)
Action:      ALLOW
```

---

### Rule Example (Outbound)

```
Rule: Allow HTTPS to internet

Direction:   Outbound
Protocol:    TCP
Port:        443
Destination: 0.0.0.0/0 (anywhere)
Action:      ALLOW
```

---

### Default Policy

**Firewalls have a default action:**

**Default DENY (recommended — whitelist approach):**

```
Default: DENY all traffic

Explicit rules:
  ALLOW port 80 from 0.0.0.0/0
  ALLOW port 443 from 0.0.0.0/0
  ALLOW port 22 from 203.0.113.0/24

Everything else: DENIED

Secure: Only explicitly allowed traffic passes
```

**Default ALLOW (dangerous — blacklist approach):**

```
Default: ALLOW all traffic

This is insecure — easy to forget to block something
```

**Best practice: Default DENY, explicitly ALLOW what's needed.**

---

### Source/Destination Notation

```
Single IP:     203.0.113.45/32
IP range:      203.0.113.0/24
Anywhere:      0.0.0.0/0 (all IPv4)
```

---

## Stateful vs Stateless (CRITICAL)

### The Most Important Concept in This File

**This single concept is responsible for more firewall misconfiguration than anything else.**

---

### What Is State?

**State = Memory of connections**

**Stateful firewall:**

```
✅ Remembers outbound connections
✅ Automatically allows return traffic
✅ Tracks connection state
✅ Smarter, easier to configure
```

**Stateless firewall:**

```
❌ No memory of connections
❌ Evaluates each packet independently
❌ Must explicitly allow BOTH directions
❌ Harder to configure correctly
```

---

### Stateful Example (Easy)

**Stateful firewall:**

```
Inbound rules:
  ALLOW TCP port 80 from 0.0.0.0/0

What happens:
  1. User → Your server (port 80)
     Inbound rule: ALLOW ✅

  2. Your server → User (return traffic)
     Firewall: "This is return traffic from allowed inbound"
     Automatically allowed ✅ (stateful behavior)

Connection works! ✅

You only needed ONE rule (inbound)
Return traffic automatically allowed
```

---

### Stateless Example (Hard)

**Stateless firewall:**

```
Inbound rules:
  ALLOW TCP port 80 from 0.0.0.0/0

Outbound rules:
  (none)

What happens:
  1. User (123.45.67.89:54321) → Your server (port 80)
     Inbound rule: ALLOW ✅

  2. Your server (port 80) → User (123.45.67.89:54321)
     Firewall: "Is there an outbound rule for port 54321?"
     NO rule exists ❌

     Response BLOCKED ❌

Connection FAILS! ❌

You needed TWO rules:
  - Inbound: Allow port 80
  - Outbound: Allow ephemeral ports (1024-65535)
```

---

### The Ephemeral Port Problem

**Why stateless is hard:**

```
User connects to your server on port 80
User's browser picks a random ephemeral port (49152-65535) as source

Your server's response goes back to that ephemeral port
Stateless firewall has no outbound rule for port 54321

Solution:
  Allow outbound TCP ports 1024-65535 (all ephemeral ports)

This is overly permissive but necessary for stateless firewalls.
```

---

### Stateful vs Stateless Summary Table

| Feature | Stateful | Stateless |
|---------|----------|-----------|
| **Remembers connections?** | ✅ Yes | ❌ No |
| **Auto-allows return traffic?** | ✅ Yes | ❌ No |
| **Rules needed** | Fewer (easier) | More (harder) |
| **Configuration complexity** | Low | High |
| **AWS example** | Security Groups | NACLs |

---

> **AWS implementation:** AWS Security Groups are stateful — they remember connections and auto-allow return traffic. AWS NACLs are stateless — you must explicitly allow both directions including ephemeral ports. The full setup, the NACL trap, and best practices are in the AWS VPC notes.
> → [AWS VPC & Subnets](../../06.%20AWS%20–%20Cloud%20Infrastructure/03-vpc-subnet/README.md)

---

## Linux Firewall — iptables

### What Is iptables?

**iptables** is the Linux kernel's built-in packet filtering firewall. AWS Security Groups and Docker networking both use iptables under the hood.

---

### Tables and Chains

**Tables:**
```
filter  - Default. Allow/deny packets.
nat     - Modify source/destination IPs (NAT, port forwarding).
mangle  - Modify packet headers.
```

**Chains (in the filter table):**
```
INPUT   - Packets destined FOR this machine
OUTPUT  - Packets originating FROM this machine
FORWARD - Packets passing THROUGH this machine
```

---

### Basic iptables Commands

**View current rules:**

```bash
# View filter table rules
sudo iptables -L -n -v

# View with line numbers (useful for deletion)
sudo iptables -L --line-numbers -n
```

**Allow inbound HTTP:**

```bash
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
```

**Allow inbound SSH from specific IP only:**

```bash
sudo iptables -A INPUT -p tcp --dport 22 -s 203.0.113.0/24 -j ACCEPT
```

**Block all inbound by default (after allowing needed ports):**

```bash
sudo iptables -P INPUT DROP
```

**Delete a rule by line number:**

```bash
sudo iptables -D INPUT 3
```

**Flush all rules (reset):**

```bash
sudo iptables -F
```

---

### Complete Minimal Server Example

**Allow HTTP, HTTPS, SSH — block everything else:**

```bash
# Start fresh
sudo iptables -F

# Allow established connections (stateful behavior)
sudo iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allow loopback
sudo iptables -A INPUT -i lo -j ACCEPT

# Allow SSH from office
sudo iptables -A INPUT -p tcp --dport 22 -s 203.0.113.0/24 -j ACCEPT

# Allow HTTP and HTTPS from anywhere
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT

# Block everything else inbound
sudo iptables -P INPUT DROP

# Allow all outbound (default)
sudo iptables -P OUTPUT ACCEPT
```

**Key line — stateful behavior:**
```bash
sudo iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
```

This is what makes iptables stateful. Without it, you'd need explicit rules for every return packet.

---

### Verify Rules

```bash
sudo iptables -L INPUT -n -v

Output:
Chain INPUT (policy DROP)
target     prot opt source     destination
ACCEPT     all  --  0.0.0.0/0  0.0.0.0/0   state RELATED,ESTABLISHED
ACCEPT     all  --  0.0.0.0/0  0.0.0.0/0   (loopback)
ACCEPT     tcp  --  203.0.113.0/24  0.0.0.0/0  tcp dpt:22
ACCEPT     tcp  --  0.0.0.0/0  0.0.0.0/0   tcp dpt:80
ACCEPT     tcp  --  0.0.0.0/0  0.0.0.0/0   tcp dpt:443
```

---

### NAT Rules (iptables nat table)

**Docker uses iptables nat rules for port binding:**

```bash
# View NAT rules
sudo iptables -t nat -L -n -v

# See DNAT rules Docker created
sudo iptables -t nat -L DOCKER -n

Output (after docker run -p 8080:80 nginx):
  DNAT tcp dpt:8080 to:172.17.0.2:80
```

This is exactly what happens when you run `docker run -p 8080:80` — Docker writes an iptables DNAT rule.

---

### ufw (Uncomplicated Firewall)

**ufw is a simpler front-end for iptables:**

```bash
# Check status
sudo ufw status verbose

# Allow port 80
sudo ufw allow 80/tcp

# Allow SSH from specific IP
sudo ufw allow from 203.0.113.0/24 to any port 22

# Enable (careful on remote servers — ensure SSH is allowed first!)
sudo ufw enable
```

---

## Common Firewall Scenarios

### Scenario 1: Can't SSH to Server

**Symptom:**

```bash
ssh user@54.123.45.67
# Hangs, then times out
```

**Debug checklist:**

```
☐ 1. Is port 22 open?
     nc -zv 54.123.45.67 22
     # Connection refused = nothing listening or firewall blocking

☐ 2. Check iptables rules
     sudo iptables -L INPUT -n | grep 22

☐ 3. Is your source IP allowed?
     Check if your current IP is in the allowed range

☐ 4. Is sshd running?
     sudo systemctl status sshd
```

---

### Scenario 2: Website Times Out

**Symptom:**

```bash
curl http://54.123.45.67
# Hangs, times out
```

**Debug:**

```
☐ 1. Is port 80 open?
     nc -zv 54.123.45.67 80

☐ 2. Check iptables
     sudo iptables -L INPUT -n | grep 80

☐ 3. Is web server running?
     sudo systemctl status nginx
     sudo netstat -tlnp | grep :80

☐ 4. Listening on correct interface?
     0.0.0.0:80 ✅ (all interfaces)
     127.0.0.1:80 ❌ (localhost only)
```

---

### Scenario 3: Database Connection Refused

**Symptom:**

```
App can't connect to database
Error: Connection refused to 10.0.3.50:5432
```

**Debug:**

```
☐ 1. Is PostgreSQL listening?
     sudo netstat -tlnp | grep :5432

☐ 2. Is PostgreSQL listening on correct interface?
     Check postgresql.conf:
     listen_addresses = '*'  (all interfaces)
     Not: listen_addresses = 'localhost'

☐ 3. Firewall allowing the port?
     sudo iptables -L INPUT -n | grep 5432

☐ 4. App server IP allowed?
     Check pg_hba.conf for client authentication
```

---

## Production Debugging Framework

### Systematic Approach

**When connection fails, debug in this order:**

---

### Step 1: DNS Resolution

```bash
nslookup database.internal
dig api.example.com

If fails: DNS issue
```

---

### Step 2: Network Reachability

```bash
ping 10.0.3.50

# If ICMP blocked, test a port:
nc -zv 10.0.3.50 5432
```

---

### Step 3: Port Accessibility

```bash
telnet 10.0.3.50 5432

Connection refused → Port not listening
Timeout → Firewall blocking
```

---

### Step 4: Firewall Check

```bash
# Local iptables
sudo iptables -L -n -v

# Cloud firewall (see AWS notes for Security Groups / NACLs)
```

---

### Step 5: Application Layer

```bash
sudo systemctl status postgresql
sudo netstat -tlnp | grep :5432
sudo journalctl -u postgresql -n 50
```

---

### Decision Tree

```
Connection fails
    │
    ▼
Can resolve DNS? → No → DNS issue
    │ Yes
    ▼
Can ping/reach IP? → No → Routing or firewall issue
    │ Yes
    ▼
Port accessible? → No → Firewall blocking or service not running
    │ Yes
    ▼
Service running? → No → Start/restart the service
    │ Yes
    ▼
Check application logs → Application-level issue
```

---

### Error Messages Guide

| Error | Meaning | Likely Cause |
|-------|---------|--------------|
| **Connection refused** | Port not listening | Service not running, wrong port |
| **Connection timeout** | No response | Firewall blocking, server down |
| **No route to host** | Routing problem | Network misconfigured |
| **Name or service not known** | DNS failure | DNS misconfigured |
| **Network unreachable** | No network path | Missing default route |

---

## Final Compression

### What Is a Firewall?

```
Firewall = Traffic filter

Allows or denies traffic based on:
  - Source IP
  - Destination IP
  - Port
  - Protocol
  
Purpose: Security
```

---

### Stateful vs Stateless (CRITICAL)

**Stateful:**
```
✅ Remembers connections
✅ Auto-allows return traffic
✅ Easier to configure

One rule needed (inbound only)
```

**Stateless:**
```
❌ No memory
❌ Must explicitly allow both directions
❌ Harder to configure

Two rules needed (inbound + outbound including ephemeral ports)
```

---

### iptables Essentials

```bash
# View rules
sudo iptables -L -n -v

# Allow port 80
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT

# Allow established connections (stateful)
sudo iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Block all inbound (after allowlist)
sudo iptables -P INPUT DROP
```

---

### Production Debugging Order

```
1. DNS working? (nslookup)
2. Network reachable? (ping, nc)
3. Port open? (telnet, nc -zv)
4. Firewall allowing? (iptables)
5. Service running? (systemctl, netstat)
```

---

### Common Scenarios

```
"Connection refused" → Service not running or wrong port
"Connection timeout" → Firewall blocking
"DNS not found"      → DNS misconfigured
"Network unreachable" → Routing issue
```

---

### Best Practices

```
✅ Default DENY policy
✅ Principle of least privilege
✅ Use stateful firewalls (easier and safer)
✅ Document all rules
✅ Test after every change
❌ Don't open all ports (0-65535)
❌ Don't allow SSH from 0.0.0.0/0 in production
```

---

### Mental Model

```
Stateful firewall = Smart bouncer
  Remembers who came in
  Lets them out automatically

Stateless firewall = Strict gate guard
  Checks everyone, both ways
  No memory

Use stateful for most cases.
Use stateless only when you need explicit DENY rules.
```

---

### What You Can Do Now

✅ Understand stateful vs stateless firewalls  
✅ Write iptables rules for common scenarios  
✅ Debug connectivity issues systematically  
✅ Know "connection refused" vs "timeout"  
✅ Apply principle of least privilege  

---

---

## What This Means for the Webstore

The webstore server needs exactly three inbound rules: allow port 80 (nginx), allow port 8080 (API), allow port 22 (SSH). Everything else is dropped by default. Postgres on port 5432 should never be reachable directly from outside — it accepts connections only from `127.0.0.1` or the server's local interface. A missing DROP rule on port 5432 means anyone on the internet can attempt to connect to the webstore database directly. The iptables setup from Linux Lab 05 enforces this: HTTP open to the world, SSH restricted to your IP, postgres not reachable from outside at all. This same logic is what AWS Security Groups enforce at the cloud level — different syntax, identical concept.

---

→ **Interview questions for this topic:** [99-interview-prep → Firewalls · iptables · Security Groups](../99-interview-prep/README.md#firewalls--iptables--security-groups)

→ Ready to practice? [Go to Lab 04](../networking-labs/04-dns-firewalls-lab.md)

---
# SOURCE: 03. Networking – Foundations/10-complete-journey/README.md
---

# File 10: Complete Journey & OSI Deep Dive

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

# Complete Journey & OSI Deep Dive

## What this file is about

This file shows **how all networking concepts work together** in real packet flows. If you understand this, you can trace a packet from your browser to a server anywhere in the world, debug connectivity issues systematically, and understand what's happening at every layer of the network stack.

<!-- no toc -->
- [The Real Question](#the-real-question)
- [The OSI Model — Complete Picture](#the-osi-model--complete-picture)
- [Encapsulation — The Russian Nesting Doll](#encapsulation--the-russian-nesting-doll)
- [Journey 1: You Open google.com](#journey-1-you-open-googlecom)
- [Journey 2: LAN Communication (Same Subnet)](#journey-2-lan-communication-same-subnet)
- [Journey 3: Docker Container to Container](#journey-3-docker-container-to-container)
- [Journey 4: AWS Multi-Tier Application](#journey-4-aws-multi-tier-application)
- [The Troubleshooting Mindset](#the-troubleshooting-mindset)
- [Common Failure Points](#common-failure-points)  
[Final Compression](#final-compression)

---

## The Real Question

After learning about IP addresses, routers, DNS, NAT, and firewalls separately, one question remains:

**"What actually happens when I type google.com in my browser and press Enter?"**

This file answers that question completely — step by step, layer by layer, with nothing hidden.

---

## The OSI Model — Complete Picture

### Why OSI Exists

The OSI (Open Systems Interconnection) model is a framework that breaks networking into 7 layers. Each layer has a specific job. Understanding this model lets you:

- Debug problems systematically (which layer is broken?)
- Understand where different technologies fit (is DNS Layer 7 or Layer 3?)
- Communicate with other engineers (everyone uses this model)

### The 7 Layers

| Layer | Name | What It Does | Examples | Data Unit |
|-------|------|--------------|----------|-----------|
| **7** | Application | User-facing protocols | HTTP, DNS, SSH, FTP | Data/Messages |
| **6** | Presentation | Data formatting, encryption | SSL/TLS, JPEG, ASCII | Data |
| **5** | Session | Maintains connections | NetBIOS, RPC | Data |
| **4** | Transport | End-to-end delivery, reliability | TCP, UDP | Segments |
| **3** | Network | Routing between networks | IP, ICMP | Packets |
| **2** | Data Link | Local delivery, error detection | Ethernet, WiFi, ARP | Frames |
| **1** | Physical | Physical transmission | Cables, radio waves | Bits |

### How to Remember It

**Mnemonic (top to bottom):**
```
All People Seem To Need Data Processing
Application
Presentation
Session
Transport
Network
Data Link
Physical
```

**Or reverse (bottom to top):**
```
Please Do Not Throw Sausage Pizza Away
Physical
Data Link
Network
Transport
Session
Presentation
Application
```

---

### Visual: The Stack

```
┌─────────────────────────────────────────────┐
│  Layer 7: Application                       │
│  What: User-facing protocols                │
│  Example: HTTP, DNS, SSH                    │
│  Your browser lives here                    │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│  Layer 6: Presentation                      │
│  What: Data formatting, encryption          │
│  Example: SSL/TLS, compression              │
│  Makes data readable/secure                 │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│  Layer 5: Session                           │
│  What: Maintains connections                │
│  Example: Session management                │
│  Keeps conversations organized              │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│  Layer 4: Transport                         │
│  What: Ports, reliability                   │
│  Example: TCP (reliable), UDP (fast)        │
│  Creates: Segments                          │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│  Layer 3: Network                           │
│  What: IP addressing, routing               │
│  Example: IP, routers                       │
│  Creates: Packets                           │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│  Layer 2: Data Link                         │
│  What: MAC addressing, switches             │
│  Example: Ethernet, WiFi, ARP               │
│  Creates: Frames                            │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│  Layer 1: Physical                          │
│  What: Physical transmission                │
│  Example: Cables, WiFi radio, fiber         │
│  Transmits: Bits (1s and 0s)                │
└─────────────────────────────────────────────┘
```

---

### DevOps Reality: Which Layers Matter Most

**For cloud/DevOps engineers, you spend 90% of time in:**

- **Layer 7** (Application): HTTP, HTTPS, DNS, SSH
- **Layer 4** (Transport): TCP/UDP, ports
- **Layer 3** (Network): IP addresses, routing, subnets
- **Layer 2** (Data Link): Rarely touch directly (cloud abstracts this)

**Layers 5-6:** Mostly abstracted away (TLS happens automatically)  
**Layer 1:** Never touch (cloud provider handles physical)

---

## Encapsulation — The Russian Nesting Doll

### The Core Concept

**Each layer wraps the previous layer's data.**

When you send data:
1. Application creates data
2. Transport wraps it (adds TCP/UDP header)
3. Network wraps that (adds IP header)
4. Data Link wraps that (adds Ethernet header)
5. Physical transmits the bits

**Visual:**

```
┌──────────────────────────────────────────────────────────────┐
│ Ethernet Frame (Layer 2)                                     │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐  │
│  │ IP Packet (Layer 3)                                    │  │
│  │                                                        │  │
│  │  ┌──────────────────────────────────────────────────┐  │  │
│  │  │ TCP Segment (Layer 4)                            │  │  │
│  │  │                                                  │  │  │
│  │  │  ┌────────────────────────────────────────────┐  │  │  │
│  │  │  │ Application Data (Layer 7)                 │  │  │  │
│  │  │  │                                            │  │  │  │
│  │  │  │ "GET /index.html HTTP/1.1"                 │  │  │  │
│  │  │  │                                            │  │  │  │
│  │  │  └────────────────────────────────────────────┘  │  │  │
│  │  │                                                  │  │  │
│  │  └──────────────────────────────────────────────────┘  │  │
│  │                                                        │  │
│  └────────────────────────────────────────────────────────┘  │
│                                                              │
└──────────────────────────────────────────────────────────────┘

Each layer adds its own header (metadata).
The inner data is payload for the outer layer.
```

---

### What Each Header Contains

**Application Data (Layer 7):**
```
The actual content: "GET /index.html HTTP/1.1"
```

**TCP Header (Layer 4) adds:**
- Source port: 54321 (random)
- Destination port: 443 (HTTPS)
- Sequence numbers (for ordering)
- Flags (SYN, ACK, FIN)

**IP Header (Layer 3) adds:**
- Source IP: 192.168.1.45 (your laptop)
- Destination IP: 142.250.190.46 (Google)
- TTL (time to live)
- Protocol (TCP)

**Ethernet Header (Layer 2) adds:**
- Source MAC: AA:BB:CC:DD:EE:FF (your laptop)
- Destination MAC: 11:22:33:44:55:66 (router)
- EtherType (IPv4)

---

### The Critical Truth About MAC vs IP

**CRITICAL: Every packet contains BOTH MAC and IP headers.**

**They serve different purposes:**

| Header | Purpose | Changes During Journey? |
|--------|---------|------------------------|
| **IP Header** | Final destination | ❌ No — stays same from source to destination |
| **MAC Header** | Next hop | ✅ Yes — rewritten at every router |

**Example journey:**

```
Your laptop → Router → ISP Router → Google

Hop 1 (Laptop → Router):
  MAC src: Laptop MAC
  MAC dst: Router MAC  ← Changes at router
  IP src:  Laptop IP
  IP dst:  Google IP   ← Stays same

Hop 2 (Router → ISP):
  MAC src: Router MAC
  MAC dst: ISP MAC     ← Changed
  IP src:  Laptop IP
  IP dst:  Google IP   ← Still same

Hop N (Last → Google):
  MAC src: Router MAC
  MAC dst: Google MAC  ← Changed again
  IP src:  Laptop IP
  IP dst:  Google IP   ← Still same
```

**This is why:**
- MAC = local (only survives one hop)
- IP = global (survives entire journey)

---

## Journey 1: You Open google.com

**Scenario:** You're on your laptop at home, connected to WiFi. You type `google.com` in your browser.

**Network details:**
- Your laptop: 192.168.1.45 (private IP)
- Your router: 192.168.1.1 (LAN side), 203.45.67.89 (WAN side, public IP from ISP)
- Google server: 142.250.190.46

---

### Step-by-Step Complete Flow

#### Phase 1: DNS Resolution

**Step 1: Browser checks cache**
```
Browser: "Do I know google.com's IP?"
Cache: "No, never visited before"
```

**Step 2: OS DNS query**
```
Your laptop: "What's google.com?"
DNS query sent to: 8.8.8.8 (Google DNS)
Protocol: UDP port 53
```

**Step 3: DNS response**
```
DNS server: "google.com = 142.250.190.46"
Your laptop: Caches this for 5 minutes (TTL)
```

---

#### Phase 2: TCP Connection Establishment

**Step 4: TCP 3-way handshake begins**

```
Your laptop → Google

SYN packet:
  IP src: 192.168.1.45
  IP dst: 142.250.190.46
  TCP src port: 54321 (random)
  TCP dst port: 443 (HTTPS)
  Flags: SYN
```

**Step 5: Routing decision**
```
Your laptop checks:
"Is 142.250.190.46 in my subnet (192.168.1.0/24)?"

Subnet calculation:
142.250.X.X ≠ 192.168.1.X

Decision: Not local → send to default gateway (192.168.1.1)
```

**Step 6: ARP lookup**
```
Your laptop needs: Router's MAC address

ARP request (broadcast):
"Who has 192.168.1.1? Tell 192.168.1.45"

Router responds:
"192.168.1.1 is at MAC AA:BB:CC:DD:EE:FF"

Your laptop caches this.
```

---

#### Phase 3: Packet Creation (Encapsulation)

**Step 7: Build the packet**

```
Layer 7 (Application):
  Data: "SYN" (connection request)

Layer 4 (Transport):
  Wraps with TCP header:
    Src port: 54321
    Dst port: 443
    Flags: SYN
    Sequence: 1000

Layer 3 (Network):
  Wraps with IP header:
    Src IP: 192.168.1.45
    Dst IP: 142.250.190.46
    Protocol: TCP
    TTL: 64

Layer 2 (Data Link):
  Wraps with Ethernet header:
    Src MAC: [Your laptop MAC]
    Dst MAC: [Router MAC]  ← Next hop, not Google!
    Type: IPv4

Layer 1 (Physical):
  Converts to radio waves (WiFi)
  Transmits
```

**Key insight:** Destination MAC = router (next hop), not Google (final destination).

---

#### Phase 4: Router Processing

**Step 8: Router receives packet**

```
Router WiFi interface receives bits
Converts to frame
Checks Ethernet header:
  Dst MAC: [Router MAC] → "This is for me"

Router strips Ethernet header (de-encapsulation)
Reads IP header:
  Dst IP: 142.250.190.46 → "Not for me, forward it"

Router checks routing table:
  142.250.190.46 → Send via WAN interface to ISP
```

**Step 9: NAT translation**

```
Router's NAT table:

Before (LAN side):
  Src IP: 192.168.1.45
  Src port: 54321

After (WAN side):
  Src IP: 203.45.67.89 (router's public IP)
  Src port: 54321 (or remapped)

NAT logs:
"Port 54321 belongs to 192.168.1.45"
```

**Step 10: Router forwards packet**

```
Router creates new Ethernet frame:
  Src MAC: [Router WAN MAC]
  Dst MAC: [ISP Router MAC] ← Different MAC!

IP header (unchanged):
  Src IP: 203.45.67.89 (after NAT)
  Dst IP: 142.250.190.46

Router transmits via cable to ISP
```

---

#### Phase 5: Internet Journey

**Step 11: Multiple router hops**

```
ISP Router 1:
  Receives frame
  Strips Ethernet header
  Reads IP destination: 142.250.190.46
  Checks routing table: Forward to ISP Router 2
  Creates new Ethernet frame (new MACs)
  Forwards

ISP Router 2:
  Same process
  Forwards to ISP Router 3

... (10-20 hops) ...

Last Router:
  Knows Google is directly connected
  Forwards to Google's server
```

**At each hop:**
- ✅ MAC addresses change (new src/dst MACs)
- ❌ IP addresses stay same (src/dst IPs preserved)

---

#### Phase 6: Google Receives

**Step 12: Google's server receives packet**

```
Google server checks:
  Dst MAC: [Google server MAC] → "For me"
  Dst IP: 142.250.190.46 → "For me"

Google de-encapsulates:
  Strips Ethernet header
  Strips IP header
  Reads TCP header:
    Dst port: 443 → "HTTPS service"
    Flags: SYN → "New connection request"

Google's firewall checks:
  Port 443 from internet? → Allowed
```

**Step 13: Google responds (SYN-ACK)**

```
Google creates response:
  TCP flags: SYN-ACK
  Src IP: 142.250.190.46
  Dst IP: 203.45.67.89 (your router's public IP)
  Src port: 443
  Dst port: 54321

Packet travels back through internet
Same routing process in reverse
```

---

#### Phase 7: Return Journey

**Step 14: Router receives response**

```
Router WAN interface receives packet:
  Dst IP: 203.45.67.89 → "This is me"
  Dst port: 54321

Router checks NAT table:
  "Port 54321 = 192.168.1.45"

Router reverse NAT:
  Changes Dst IP: 203.45.67.89 → 192.168.1.45
  
Router forwards to LAN:
  New Ethernet frame:
    Src MAC: [Router LAN MAC]
    Dst MAC: [Your laptop MAC]
```

**Step 15: Your laptop receives**

```
Your laptop WiFi receives:
  Dst MAC: [Laptop MAC] → "For me"
  Dst IP: 192.168.1.45 → "For me"

De-encapsulates:
  TCP sees: SYN-ACK
  Browser: "Connection established!"
```

**Step 16: Final ACK**

```
Your laptop sends ACK to complete handshake
Connection now open
Browser can send HTTP request
```

---

#### Phase 8: HTTP Request

**Step 17: Browser sends request**

```
Application layer data:
GET / HTTP/1.1
Host: google.com

Encapsulated again:
  TCP segment (port 443)
  IP packet (to 142.250.190.46)
  Ethernet frame (to router MAC)

Same journey as before
```

**Step 18: Google responds with HTML**

```
Google sends:
HTTP/1.1 200 OK
Content-Type: text/html
<html>...</html>

Travels back through internet
NAT translation at router
Delivered to browser
```

**Step 19: Browser renders page**

```
Browser receives HTML
Parses it
Makes additional requests (CSS, JS, images)
Each request = new TCP connection or reuses existing
Renders google.com homepage
```

---

### Complete Timeline Summary

| Time | Event | Layer(s) |
|------|-------|----------|
| 0ms | Type google.com | L7 |
| 5ms | DNS query (UDP) | L7, L4, L3 |
| 25ms | DNS response | All layers |
| 30ms | TCP SYN sent | L7, L4, L3, L2, L1 |
| 30ms | ARP lookup (router MAC) | L2 |
| 31ms | Packet reaches router | All layers |
| 31ms | NAT translation | L3, L4 |
| 32ms | Packet forwarded to ISP | All layers |
| 50ms | Packet reaches Google | All layers (many hops) |
| 50ms | Google firewall check | L3, L4 |
| 51ms | SYN-ACK sent back | All layers |
| 70ms | Router receives, reverse NAT | L3, L4 |
| 71ms | Your laptop receives SYN-ACK | All layers |
| 71ms | ACK sent to complete handshake | All layers |
| 90ms | Connection established (TLS happens here) | L5, L6 |
| 100ms | HTTP GET request sent | L7 |
| 120ms | Google responds with HTML | L7 |
| 121ms | Browser renders page | L7 |

**Total time:** ~120ms (0.12 seconds)

---

### What You Just Learned

By tracing this one request, you now understand:

✅ **DNS resolution** (Application layer)  
✅ **TCP 3-way handshake** (Transport layer)  
✅ **Routing decisions** (Network layer)  
✅ **ARP translation** (Data Link layer)  
✅ **NAT operation** (Network/Transport layers)  
✅ **MAC address changes** (every hop)  
✅ **IP address preservation** (end-to-end)  
✅ **Encapsulation/de-encapsulation** (at every device)  
✅ **Firewall checks** (at destination)  

**This is the complete picture of networking.**

---

## Journey 2: LAN Communication (Same Subnet)

**Scenario:** Two computers on same WiFi network, no internet involved.

**Network setup:**
```
Computer A: 192.168.1.10
Computer B: 192.168.1.20
Subnet: 192.168.1.0/24
Gateway: 192.168.1.1 (exists but not used)
Switch/Access Point: Connects both
```

---

### The Flow (Much Simpler)

**Step 1: Computer A wants to send file to Computer B**

```
Application: File transfer app
Destination: 192.168.1.20
```

**Step 2: Routing decision**

```
Computer A checks:
"Is 192.168.1.20 in my subnet?"

Calculation:
My IP:     192.168.1.10
My mask:   255.255.255.0
My subnet: 192.168.1.0/24

Target:    192.168.1.20
Masked:    192.168.1.0/24

Match? YES → Send directly (no router needed)
```

**Step 3: ARP for Computer B's MAC**

```
Computer A broadcasts ARP:
"Who has 192.168.1.20? Tell 192.168.1.10"

Computer B responds:
"192.168.1.20 is at MAC BB:BB:BB:BB:BB:BB"

Computer A caches this
```

**Step 4: Build and send packet**

```
Ethernet Frame:
  Src MAC: [Computer A MAC]
  Dst MAC: [Computer B MAC] ← Direct to destination!

IP Packet:
  Src IP: 192.168.1.10
  Dst IP: 192.168.1.20

TCP Segment:
  Src port: 5000
  Dst port: 5001
  
Data: File contents
```

**Step 5: Switch forwards**

```
Switch receives frame
Checks destination MAC: BB:BB:BB:BB:BB:BB
Checks MAC table: "This MAC is on port 3"
Forwards frame only to port 3 (Computer B)
```

**Step 6: Computer B receives**

```
Computer B:
  Checks MAC → "For me"
  Checks IP → "For me"
  Delivers to file transfer app (port 5001)
```

---

### Key Differences from Internet Journey

| Aspect | Internet (Journey 1) | LAN (Journey 2) |
|--------|---------------------|-----------------|
| **Router used?** | ✅ Yes (multiple) | ❌ No |
| **NAT used?** | ✅ Yes | ❌ No |
| **DNS needed?** | ✅ Yes (domain names) | ❌ No (direct IP) |
| **MAC changes?** | ✅ Yes (every hop) | ❌ No (one hop) |
| **Hops** | 10-20 | 1 |
| **Speed** | ~100ms | <1ms |

---

## Journey 3: Docker Container to Container

**Scenario:** Two containers on same Docker network communicating.

**Setup:**
```bash
docker network create myapp-net --subnet=172.20.0.0/16
docker run -d --name web --network myapp-net nginx
docker run -d --name api --network myapp-net node-app
```

**Container details:**
```
web container: 172.20.0.2
api container: 172.20.0.3
Docker network: 172.20.0.0/16
```

---

### The Flow

**Step 1: Web container wants to call API**

```
Inside web container code:
fetch('http://api:3000/data')
```

**Step 2: Docker DNS resolution**

```
Container queries Docker's internal DNS:
"What's 'api'?"

Docker DNS responds:
"api = 172.20.0.3"
```

**Step 3: Routing decision**

```
Web container checks:
My IP: 172.20.0.2
Subnet: 172.20.0.0/16
Target: 172.20.0.3

In same subnet? YES → Direct communication
```

**Step 4: Packet sent via Docker bridge**

```
Docker bridge network = virtual switch

Ethernet Frame:
  Src MAC: [web container veth MAC]
  Dst MAC: [api container veth MAC]

IP Packet:
  Src IP: 172.20.0.2
  Dst IP: 172.20.0.3

TCP Segment:
  Src port: Random
  Dst port: 3000

HTTP Request:
  GET /data
```

**Step 5: Docker bridge forwards**

```
Docker bridge (like a switch):
  Receives from web container
  Checks destination: 172.20.0.3
  Forwards to api container's virtual interface
```

**Step 6: API container receives**

```
API container:
  Receives packet
  Port 3000 → Node.js app
  Processes request
  Sends response back
```

---

### What's Different in Docker

**Docker-specific concepts:**

- **veth pairs:** Virtual ethernet cables (one end in container, one in bridge)
- **Bridge network:** Virtual switch connecting containers
- **Internal DNS:** Container names automatically resolve to IPs
- **Isolation:** Each container has own network namespace

**No NAT needed** (containers on same bridge)  
**No physical NICs** (all virtual)  
**Same networking principles** (IP, MAC, TCP still apply)

---

## Journey 4: AWS Multi-Tier Application

**Scenario:** User accesses web application hosted on AWS

**Architecture:**
```
Internet User
    ↓
Application Load Balancer (ALB) - Public subnet
    ↓
Web Server (EC2) - Private subnet
    ↓
Database (RDS) - Private subnet
```

**Network details:**
```
VPC: 10.0.0.0/16

Public Subnet: 10.0.1.0/24
├─ ALB: 10.0.1.100 (also has public IP: 54.123.45.67)
└─ Internet Gateway: Attached

Private Subnet (Web): 10.0.2.0/24
├─ Web Server: 10.0.2.50
└─ NAT Gateway: 10.0.1.200 (in public subnet)

Private Subnet (DB): 10.0.3.0/24
└─ RDS: 10.0.3.25
```

---

### Complete Flow

#### Phase 1: User → ALB

**Step 1: DNS resolution**

```
User browser: "What's myapp.example.com?"
Route 53 (AWS DNS): "54.123.45.67"
```

**Step 2: User sends HTTPS request**

```
User laptop (203.45.67.89) → ALB (54.123.45.67)

Internet routing (multiple hops)
Reaches AWS region
AWS Internet Gateway receives
Routes to ALB in public subnet
```

**Step 3: ALB receives request**

```
ALB checks:
  Port 443 (HTTPS) → Allowed
  Security Group: Allow 0.0.0.0/0 on port 443 ✅

ALB terminates TLS (decrypts HTTPS)
Now has HTTP request
```

---

#### Phase 2: ALB → Web Server

**Step 4: ALB health checks**

```
ALB knows about:
  Web Server 1: 10.0.2.50 (healthy)
  Web Server 2: 10.0.2.51 (healthy)

Chooses: Web Server 1 (round-robin)
```

**Step 5: ALB forwards to web server**

```
Internal VPC routing:
  Src IP: 10.0.1.100 (ALB)
  Dst IP: 10.0.2.50 (web server)

Subnet check:
  10.0.1.X ≠ 10.0.2.X → Different subnets

VPC router forwards between subnets
```

**Step 6: Web server receives**

```
Web server security group checks:
  Source: ALB security group → Allowed ✅
  Port 80 (HTTP) → Allowed ✅

EC2 instance receives request
Apache/Nginx processes it
```

---

#### Phase 3: Web Server → Database

**Step 7: Web server queries database**

```
Application code:
  Connection string: 10.0.3.25:5432 (PostgreSQL)

Packet created:
  Src IP: 10.0.2.50
  Dst IP: 10.0.3.25
  Dst port: 5432
```

**Step 8: VPC routing**

```
Different subnets:
  10.0.2.X → 10.0.3.X

VPC route table:
  10.0.0.0/16 → local (VPC router handles)

Packet forwarded to database subnet
```

**Step 9: RDS receives query**

```
RDS security group checks:
  Source: Web server security group → Allowed ✅
  Port 5432 → Allowed ✅

PostgreSQL processes query
Returns data
```

---

#### Phase 4: Response Journey

**Step 10: Database → Web Server**

```
Response packet:
  Src IP: 10.0.3.25
  Dst IP: 10.0.2.50

Routed back through VPC
Web server receives data
```

**Step 11: Web Server → ALB**

```
Web server generates HTML response

Packet:
  Src IP: 10.0.2.50
  Dst IP: 10.0.1.100

ALB receives
Encrypts with TLS (HTTPS)
```

**Step 12: ALB → User**

```
ALB sends HTTPS response:
  Src IP: 54.123.45.67 (ALB public IP)
  Dst IP: 203.45.67.89 (user's public IP)

Internet routing
Reaches user's ISP
User's router (NAT)
User's browser displays page
```

---

### What If Web Server Needs Internet?

**Scenario:** Web server needs to download OS updates

**Step 1: Web server initiates connection**

```
Web server: "I want to reach archive.ubuntu.com"
Dst IP: 91.189.88.142 (Ubuntu server)
```

**Step 2: Route table check**

```
Web server's route table:
  10.0.0.0/16 → local
  0.0.0.0/0 → NAT Gateway (10.0.1.200)

Decision: Send to NAT Gateway
```

**Step 3: NAT Gateway translation**

```
NAT Gateway receives:
  Src IP: 10.0.2.50 (private)

NAT Gateway translates:
  Src IP: 52.10.20.30 (NAT Gateway's Elastic IP)

Forwards to Internet Gateway
```

**Step 4: Internet Gateway**

```
Routes packet to internet
Ubuntu server receives
Responds
```

**Step 5: Return path**

```
Internet → Internet Gateway → NAT Gateway

NAT Gateway reverse translation:
  Dst IP: 52.10.20.30 → 10.0.2.50

Delivers to web server
```

---

### AWS Networking Summary

**Components used:**

| Component | Purpose | Layer |
|-----------|---------|-------|
| **VPC** | Isolated network | L3 |
| **Subnets** | Network segments | L3 |
| **Internet Gateway** | VPC ↔ Internet | L3 |
| **NAT Gateway** | Private ↔ Internet (outbound) | L3, L4 |
| **Route Tables** | Traffic direction | L3 |
| **Security Groups** | Stateful firewall | L3, L4 |
| **NACLs** | Stateless firewall | L3, L4 |
| **ALB** | Load balancer | L7 |

---

## The Troubleshooting Mindset

### The Systematic Approach

When something doesn't work, **debug layer by layer:**

```
┌──────────────────────────────────────┐
│ 7. Application Layer                 │
│    Is the app running?               │
│    Check: ps aux | grep app          │
└──────────────────────────────────────┘
                ↑
┌──────────────────────────────────────┐
│ 4. Transport Layer                   │
│    Is the port open?                 │
│    Check: netstat -tlnp | grep :80   │
└──────────────────────────────────────┘
                ↑
┌──────────────────────────────────────┐
│ 3. Network Layer                     │
│    Can we reach the IP?              │
│    Check: ping 192.168.1.50          │
│          traceroute google.com       │
└──────────────────────────────────────┘
                ↑
┌──────────────────────────────────────┐
│ Firewall (sits between layers)       │
│    Are firewall rules correct?       │
│    Check: Security groups, iptables  │
└──────────────────────────────────────┘
                ↑
┌──────────────────────────────────────┐
│ DNS (Application layer service)      │
│    Does name resolve?                │
│    Check: nslookup google.com        │
│          dig google.com              │
└──────────────────────────────────────┘
```

---

### The 5-Question Debug Framework

**When connection fails, ask in order:**

#### 1. DNS Working?
```bash
nslookup myapp.example.com

If fails: DNS issue
If works: Note the IP, move to step 2
```

#### 2. Network Reachable?
```bash
ping <IP_FROM_STEP_1>

If fails: Routing or firewall issue
If works: Network path exists, move to step 3
```

**Note:** Ping might be blocked (ICMP). If ping fails, try:
```bash
telnet <IP> <PORT>
# or
nc -zv <IP> <PORT>
```

#### 3. Port Open?
```bash
# Test if specific port accessible
telnet <IP> 80

If "Connection refused": Port not open or service not running
If "Connected": Port is open, move to step 4
```

#### 4. Firewall Allowing?
```bash
# Check security groups (AWS)
# Check iptables (Linux)
sudo iptables -L -n -v

Look for rules blocking your traffic
```

#### 5. Application Running?
```bash
# Check if service is running
sudo systemctl status nginx

# Check if listening on expected port
sudo netstat -tlnp | grep :80

# Check application logs
sudo journalctl -u nginx -n 50
```

---

### Common Failure Points

| Symptom | Likely Layer | Debug Step |
|---------|-------------|------------|
| "Unknown host" | DNS (L7) | `nslookup domain.com` |
| "Connection timeout" | Firewall or routing (L3) | Check security groups, ping |
| "Connection refused" | Port closed (L4) | `netstat -tlnp \| grep :PORT` |
| "404 Not Found" | Application (L7) | Check app logs, correct URL |
| "SSL certificate error" | Presentation (L6) | Check cert validity, TLS config |
| Slow but working | All layers | `traceroute`, check bandwidth |

---

## Common Failure Points

### Scenario 1: Can't SSH to EC2

**Symptom:**
```bash
ssh ec2-user@54.123.45.67
# Hangs, then times out
```

**Debug:**

```
Step 1: DNS (skip, using IP)

Step 2: Network reachable?
ping 54.123.45.67
# Timeout (ICMP might be blocked, try port test)

telnet 54.123.45.67 22
# Connection timeout

Step 3: Check security group
AWS Console → EC2 → Security Groups
Inbound rules:
  SSH (22) from 203.45.67.89/32 ← Your office IP

Problem: Your current IP is 198.51.100.45 (different!)

Fix: Update security group or use your actual current IP
```

---

### Scenario 2: Container Can't Reach Database

**Symptom:**
```
App container logs: "Connection refused to db:5432"
```

**Debug:**

```
Step 1: DNS
docker exec app-container ping db
# ping: unknown host db

Problem: Containers not on same network

Fix:
docker network create mynet
docker network connect mynet app-container
docker network connect mynet db-container

Now DNS works
```

---

### Scenario 3: Website Loads Slowly

**Symptom:**
```
Browser: Page takes 30 seconds to load
```

**Debug:**

```
Step 1: DNS resolution time
dig example.com
# Query time: 25000 msec

Problem: DNS server slow or unreachable

Check:
cat /etc/resolv.conf
# nameserver 192.168.1.1

Router's DNS might be slow

Fix: Use faster DNS
# Add to /etc/resolv.conf
nameserver 8.8.8.8
nameserver 1.1.1.1

Test again:
dig example.com
# Query time: 15 msec ← Much better
```

---

### Scenario 4: NAT Not Working

**Symptom:**
```
Private EC2 instance can't reach internet for updates
```

**Debug:**

```
Step 1: Check route table
Private subnet route table:
  10.0.0.0/16 → local
  0.0.0.0/0 → igw-xxxxx  ← WRONG!

Problem: Private subnet pointing to Internet Gateway
Should point to NAT Gateway

Fix:
  0.0.0.0/0 → nat-xxxxx

Now works
```

---

## Final Compression

### The Complete Mental Model

**Networking = Data traveling through layers**

```
Your app creates data
  ↓
TCP wraps it (adds ports, reliability)
  ↓
IP wraps it (adds source/destination IPs)
  ↓
Ethernet wraps it (adds next-hop MACs)
  ↓
Physical layer transmits bits
  ↓
(At each router: strip Ethernet, check IP, add new Ethernet)
  ↓
Destination receives
  ↓
Strips layers in reverse
  ↓
App receives data
```

---

### Critical Truths (Never Forget)

1. **MAC and IP always work together**
   - MAC = next hop (changes every router)
   - IP = final destination (never changes)

2. **Routers connect networks**
   - Check destination IP
   - If not local → use routing table
   - Strip old MAC, add new MAC

3. **NAT hides private IPs**
   - Private IP → Router → Public IP
   - Response → Router → Private IP
   - NAT table tracks connections

4. **Firewalls control access**
   - Stateful = remembers connections
   - Stateless = checks every packet
   - Security groups = stateful (AWS)
   - NACLs = stateless (AWS)

5. **DNS is just a lookup service**
   - Name → IP translation
   - Uses UDP port 53
   - Can be cached
   - Can be slow (debug point)

---

### The Three Questions Every Packet Answers

```
1. Who am I going to ultimately? (Destination IP)
2. Who do I give this to next? (Next-hop MAC)
3. How do I get there? (Routing table)
```

**Answer these three, and you understand networking.**

---

### OSI Layers — Quick Reference

```
7. Application    →  HTTP, DNS, SSH (what users see)
6. Presentation   →  TLS, encryption (data formatting)
5. Session        →  Session management (connections)
4. Transport      →  TCP, UDP, ports (reliability)
3. Network        →  IP, routing (addressing)
2. Data Link      →  MAC, switching (local delivery)
1. Physical       →  Cables, WiFi (transmission)
```

---

### Troubleshooting Checklist

```
□ DNS resolving? (nslookup)
□ IP reachable? (ping or port test)
□ Port open? (netstat)
□ Firewall allowing? (security groups, iptables)
□ App running? (systemctl status, logs)
```

---
# 00-networking-map.md 

## 1. Master Packet Journey

```text
[Computer A] (Opens google.com)
      ↓
   DNS Lookup (File 05)
      ↓
   TCP Handshake (File 07)
      ↓
   Encapsulation: Data→Port→IP→MAC (File 09)
      ↓
[Local Switch] (Layer 2)
      ↓
   ARP Resolution (File 03)
      ↓
[Home Router] (Layer 3)
      ↓
   NAT: Private IP → Public IP (File 04)
      ↓
((( INTERNET )))
      ↓
   Hop-by-Hop Routing (File 09)
   MAC changes every hop
   IP never changes
      ↓
[AWS VPC]
      ↓
   Internet Gateway (File 11)
      ↓
   NACL: Stateless Firewall (File 10)
      ↓
   Load Balancer (File 11)
      ↓
   Security Group: Stateful Firewall (File 10)
      ↓
   ARP Final Hop (File 03)
      ↓
   De-encapsulation: MAC→IP→Port→Data (File 09)
      ↓
   Port Routes to Application (File 08)
      ↓
[Destination Server]
```

---

## 2. Layer Mental Model

| Layer | Tool | Purpose | Scope | Changes During Journey? |
|---|---|---|---|---|
| **Layer 2 (Data Link)** | MAC Address | Local delivery within network | LAN only | Yes (every hop) |
| **Layer 3 (Network)** | IP Address | Global delivery across internet | Worldwide | Destination: No<br>Source: Yes (NAT) |
| **Layer 4 (Transport)** | Port Number | Deliver to correct application | Inside server OS | No |

---

## 3. Packet Lifecycle

### Local Exit (Your Network)
```
DNS    → google.com becomes 142.250.80.46
TCP    → SYN, SYN-ACK, ACK handshake
Wrap   → Data→Port 443→IP→MAC (router)
Switch → Reads MAC, forwards locally
NAT    → 192.168.1.100 becomes 203.0.113.5
```

### Internet Transit
```
Routing → Packet hops router-to-router
MAC     → Rewritten every hop
IP      → Destination never changes
```

### Cloud Entry
```
IGW            → Enters AWS VPC
NACL           → Subnet firewall (stateless)
Load Balancer  → Distributes to server
Security Group → Instance firewall (stateful)
```

### Server Delivery
```
ARP     → Resolve final MAC
Unwrap  → MAC→IP→Port→Data
Port    → 443 routes to web application
```

---

## 4. What Changes vs What Stays

| Component | Changes? | When? | Why? |
|---|---|---|---|
| **Application Data** | Never | - | The payload |
| **Destination IP** | Never | - | Global addressing |
| **Source IP** | Once | At NAT | Private→Public |
| **Port Number** | Never | - | Application identifier |
| **MAC Address** | Every hop | At each router | Local delivery only |

---

## 5. Protocol Map

| Need | Protocol | File | Command Example |
|---|---|---|---|
| Name → IP | DNS | 05 | `nslookup google.com` |
| IP → MAC (local) | ARP | 03 | `arp -a` |
| Reliable delivery | TCP | 07 | 3-way handshake |
| Fast delivery | UDP | 07 | No handshake |
| Global routing | IP | 09 | Hop-by-hop |
| Hide private IPs | NAT | 04 | Router translation |
| Auto IP assignment | DHCP | 02 | Lease process |

---

## 6. Security Layers

| Firewall Type | Scope | Memory? | Return Traffic? | File |
|---|---|---|---|---|
| **NACL** | Subnet (multiple servers) | No (stateless) | Needs explicit rule | 10 |
| **Security Group** | Instance (single server) | Yes (stateful) | Auto-allowed | 10 |

**Rule:**
- Stateless = checks every packet independently, has amnesia
- Stateful = remembers connections, auto-allows replies

---

## 7. Debugging Breakpoints

| Stage | Failure Symptom | Tool | What It Shows | File |
|---|---|---|---|---|
| **DNS** | Name not resolving | `nslookup google.com` | IP address or error | 05 |
| **TCP** | Connection refused | `telnet IP PORT` | Port open/closed | 07 |
| **Routing** | Packet lost | `traceroute google.com` | Where packet dies | 09 |
| **Firewall** | Port blocked | `nc -zv IP PORT` | Port reachable? | 10 |
| **ARP** | Local delivery fails | `arp -a` | MAC table | 03 |
| **NAT** | External access fails | `curl ifconfig.me` | Public IP | 04 |

---

## 8. File Index (Concept → Location)

| Concept | File | Key Question Answered |
|---|---|---|
| **IP Addressing** | 01 | What does 192.168.1.100/24 mean? |
| **DHCP** | 02 | How did my device get an IP? |
| **ARP** | 03 | How does IP become MAC? |
| **NAT** | 04 | Why do I have two IPs (private/public)? |
| **DNS** | 05 | How does google.com become an IP? |
| **Subnetting** | 06 | How do I calculate /24 vs /16? |
| **TCP/UDP** | 07 | Reliable vs fast - when to use which? |
| **Ports** | 08 | What is port 443 vs port 80? |
| **Routing** | 09 | How does a packet cross the internet? |
| **Firewalls** | 10 | Stateful vs stateless - what's the difference? |
| **Cloud Networking** | 11 | How do VPCs, ALBs, and Security Groups work? |

---

## 9. Interview Compression

**"Explain packet flow from browser to cloud server"**

> DNS translates google.com to an IP. TCP handshake establishes connection. Data is encapsulated: application layer → port 443 → destination IP → router MAC. 
>
> Local switch forwards via MAC. Router performs NAT (private IP → public IP). Packet hops across internet—MAC changes every hop, IP stays constant.
>
> Enters AWS via Internet Gateway into VPC. Passes stateless NACL (subnet firewall), then load balancer distributes to server. Stateful Security Group (instance firewall) allows it through.
>
> ARP resolves final MAC. De-encapsulation: strip MAC → IP → port. Port 443 routes to web application. Response follows reverse path.

---

## Webstore DevOps Scenario

**User opens webstore.com**

```
DNS       → webstore.com resolves to 54.123.45.67 (Route53)
TCP       → Handshake to port 443
NAT       → Home router: 192.168.1.50 → 203.45.67.89
Routing   → Hops to AWS us-east-1
IGW       → Enters VPC 10.0.0.0/16
NACL      → Allows port 443 inbound
ALB       → Distributes to 1 of 3 backend servers
SG        → Allows port 443 to EC2 instance
Server    → Nginx serves video stream
Response  → Reverse path to browser
```

**DevOps controls:**
- DNS (Route53 config)
- Load balancer algorithm
- Security Group rules
- NACL subnet restrictions
- VPC architecture

---

## Quick Reference Card

### Addressing
```
MAC:        00:1A:2B:3C:4D:5E  (local, changes)
Private IP: 192.168.1.100      (internal, NAT'd)
Public IP:  203.0.113.5        (internet, constant)
Port:       443                (application, constant)
```

### Common Ports
```
22  → SSH
80  → HTTP
443 → HTTPS
3306 → MySQL
5432 → PostgreSQL
27017 → MongoDB
```

### Encapsulation Order
```
Build (outbound):    Data → Port → IP → MAC
Unwrap (inbound):    MAC → IP → Port → Data
```

---

**This is your network map. Review before interviews. Everything clicks.**

**You now understand networking completely.**

From typing a URL to packets traveling the world, from Docker containers talking to AWS multi-tier applications — it's all the same fundamental concepts:

**Encapsulation → Routing → Delivery → De-encapsulation**

Everything else is just details.

---

## What Breaks

| Symptom | Cause | First command to run |
|---|---|---|
| DNS resolves but browser shows "connection refused" | Service is not listening — DNS and routing are fine but nothing answers on the port | `nc -zv IP PORT` — then `ss -tlnp \| grep PORT` on the server |
| DNS resolves but connection times out | Firewall is dropping the packet before it reaches the service | `nc -zv IP PORT` — timeout means firewall, not the app |
| `dig` returns an IP but the wrong one | Stale DNS cache — old A record still in resolver | `dig @8.8.8.8 DOMAIN` to bypass local cache and compare |
| Service is running and port is open but still unreachable | App bound to `127.0.0.1` not `0.0.0.0` — only reachable locally | `ss -tlnp \| grep PORT` — check the address column |
| Request reaches nginx but API returns 502 Bad Gateway | nginx can't reach upstream — webstore-api is down or on wrong port | `curl http://localhost:8080` from the server directly |
| Everything works locally but fails from outside | Port not exposed or Security Group missing inbound rule | Check `docker ps` ports, iptables rules, and Security Group inbound rules |
| High latency at one traceroute hop | Congestion at that router — not your server | `traceroute -n DESTINATION` — identify which hop introduces the spike |

---

→ **Interview questions for this topic:** [99-interview-prep → The Complete Journey](../99-interview-prep/README.md#the-complete-journey)

→ Ready to practice? [Go to Lab 05](../networking-labs/05-complete-journey-lab.md)

---
# SOURCE: 03. Networking – Foundations/99-interview-prep/README.md
---

[Home](../README.md) |
[Foundation](../01-foundation-and-the-big-picture/README.md) |
[Addressing](../02-addressing-fundamentals/README.md) |
[IP Deep Dive](../03-ip-deep-dive/README.md) |
[Devices](../04-network-devices/README.md) |
[Subnets & CIDR](../05-subnets-cidr/README.md) |
[Ports & Transport](../06-ports-transport/README.md) |
[NAT](../07-nat/README.md) |
[DNS](../08-dns/README.md) |
[Firewalls](../09-firewalls/README.md) |
[Complete Journey](../10-complete-journey/README.md) |
[Interview](../99-interview-prep/README.md)

---

# Networking — Interview Prep

Answers are 30 seconds. No padding. Every question here actually comes up.

---

## OSI Model · Layers · Encapsulation

**What is the OSI model and why does it matter?**

The OSI model breaks networking into 7 layers — Physical, Data Link, Network, Transport, Session, Presentation, Application. Each layer has one job and serves the layer above it. It matters because when something breaks, you debug layer by layer. Connection refused means Layer 4 — the port isn't listening. DNS fails means Layer 7 — name resolution is broken. The model gives you a systematic place to start instead of guessing.

**What are the three layers you spend 90% of your time in?**

Layer 7 Application — HTTP, DNS, SSH — what users interact with. Layer 4 Transport — TCP/UDP, ports — reliability and which service gets the packet. Layer 3 Network — IP addresses, routing — how packets get between networks. Layers 1, 2, 5, and 6 are mostly abstracted in cloud and container environments.

**What is encapsulation?**

Each layer wraps the data from the layer above it with its own header. An HTTP request becomes a TCP segment, which becomes an IP packet, which becomes an Ethernet frame, which becomes bits on a wire. On the receiving end, each layer strips its header and passes the data up. This is why layers are independent — HTTP doesn't know or care about Ethernet.

---

## MAC vs IP · ARP · Addressing

**What is the difference between a MAC address and an IP address?**

A MAC address is a hardware identifier burned into the network interface — it never changes and operates at Layer 2. An IP address is a logical address assigned by software — it can change and operates at Layer 3. MAC addresses handle local delivery on the same network segment. IP addresses handle end-to-end delivery across networks. The critical rule: the destination IP never changes as a packet travels across the internet, but the destination MAC changes at every single router hop.

**What is ARP and when does it run?**

ARP — Address Resolution Protocol — resolves an IP address to a MAC address on a local network. When a device knows the destination IP but needs the MAC to actually send the frame, it broadcasts "who has this IP?" on the local segment. The owner responds with its MAC. The result is cached in the ARP table. ARP only works within a subnet — to reach another subnet, the packet goes to the gateway instead.

**What are private IP ranges?**

`10.0.0.0/8`, `172.16.0.0/12`, and `192.168.0.0/16`. These are not routable on the public internet — routers drop packets with private source IPs. They exist so organizations can use IP addresses internally without consuming public address space. NAT translates private IPs to a public IP when traffic leaves the network.

---

## Subnets · CIDR · IP Math

**What is a subnet?**

A subnet is a subdivision of a network. A `/24` gives you 256 addresses (254 usable — the network address and broadcast are reserved). A `/16` gives you 65,536. Subnetting lets you divide a large address space into smaller logical segments for security, organization, and routing efficiency.

**What does /24 mean in CIDR notation?**

The `/24` means 24 bits are the network portion of the address and the remaining 8 bits identify hosts. A `10.0.1.0/24` subnet covers `10.0.1.0` through `10.0.1.255` — 256 addresses, 254 usable. Smaller number = bigger network: `/16` is larger than `/24`.

**Why does the webstore need two subnets on AWS?**

Security through network isolation. The frontend and API go in a public subnet with an internet route — browsers need to reach them. The database goes in a private subnet with no internet route — nothing from the public internet can reach postgres directly, not because of a firewall rule but because there is no route. This is the standard AWS multi-tier architecture.

---

## TCP vs UDP · Ports · Three-Way Handshake

**What is the difference between TCP and UDP?**

TCP is connection-oriented — it establishes a connection with a three-way handshake, guarantees delivery, retransmits lost packets, and delivers data in order. UDP is connectionless — it fires packets and forgets, no guarantee, no retransmission, no ordering. TCP is for HTTP, SSH, postgres — anything where data integrity matters. UDP is for DNS queries, video streaming, gaming — anything where speed matters more than perfect delivery.

**What is the TCP three-way handshake?**

SYN — the client sends a synchronize packet to initiate the connection. SYN-ACK — the server acknowledges and sends its own synchronize. ACK — the client acknowledges the server's SYN. Connection is established. When you see `Connection refused`, the server received the SYN but nothing was listening on that port. When you see a timeout, the SYN never reached the server — firewall or routing problem.

**What is the difference between `Connection refused` and `Connection timed out`?**

Refused means the packet reached the machine but nothing is listening on that port — the OS sent back a RST. Timed out means the packet never reached the machine — it was dropped by a firewall, the host is down, or there is no route. Refused is a Layer 4 problem. Timed out is a Layer 3 or firewall problem. This distinction tells you exactly where to look.

**What are well-known ports?**

Ports 0–1023 are reserved for system services. 22 is SSH, 80 is HTTP, 443 is HTTPS, 5432 is postgres, 3306 is MySQL, 6443 is the Kubernetes API server. Ports 1024–49151 are registered application ports. Above 49152 are ephemeral ports — assigned dynamically by the OS for outbound connections.

---

## NAT · Port Forwarding · Translation

**What is NAT and why does it exist?**

Network Address Translation replaces the source IP of outgoing packets with a public IP, and reverses the translation for responses. It exists because IPv4 has ~4 billion addresses — not enough for every device. NAT lets thousands of devices share one public IP. Your home router does this. AWS NAT Gateway does this for private subnets. Docker does this for containers.

**What is DNAT and where does it appear in DevOps?**

Destination NAT rewrites the destination IP and port of incoming packets. When you run `docker run -p 8080:80`, Docker creates an iptables DNAT rule — traffic arriving on host port 8080 gets its destination rewritten to the container's private IP on port 80. AWS load balancers do the same thing at cloud scale. `sudo iptables -t nat -L DOCKER -n` shows every DNAT rule Docker has created.

**What is the difference between SNAT and DNAT?**

SNAT modifies the source address — used for outbound traffic, like a private instance reaching the internet through a NAT gateway. DNAT modifies the destination address — used for inbound traffic, like port forwarding or load balancing. Docker port binding is DNAT. AWS NAT Gateway is SNAT.

---

## DNS · Resolution · Records

**What happens when you type `webstore.example.com` in a browser?**

The OS checks its local cache. If not found, it queries the recursive resolver (usually your ISP or `8.8.8.8`). The resolver checks its cache. If not found, it walks the DNS tree — queries the root servers for `.com`, then the `.com` TLD servers for `example.com`, then `example.com`'s authoritative nameserver for `webstore.example.com`. The A record comes back with an IP. The browser connects to that IP on port 80 or 443.

**What is the difference between an A record and a CNAME?**

An A record maps a hostname directly to an IP address. A CNAME maps a hostname to another hostname — an alias. `www.example.com CNAME example.com` means www resolves to whatever example.com resolves to. You cannot use a CNAME at the zone apex (the root domain itself) — that's why some DNS providers offer ALIAS or ANAME records.

**What is the difference between a recursive resolver and an authoritative nameserver?**

A recursive resolver (like `8.8.8.8`) does the work of walking the DNS tree on your behalf and caches results. An authoritative nameserver is the final source of truth for a specific domain — it holds the actual A records, CNAMEs, MX records. When you configure DNS for your domain, you're setting records on the authoritative nameserver. When someone resolves your domain, a recursive resolver fetches from your authoritative nameserver and caches the result for the TTL duration.

**What is TTL in DNS?**

Time To Live — how long a DNS record is cached before resolvers must re-query. A TTL of 300 means caches keep the record for 5 minutes. Low TTL (60s) means faster propagation when you change records but more DNS traffic. High TTL (86400s = 24h) means less traffic but slow propagation. Before changing DNS, lower the TTL first and wait for existing caches to expire.

---

## Firewalls · iptables · Security Groups

**What is the difference between stateful and stateless firewalls?**

A stateless firewall evaluates every packet independently against rules — it doesn't know if a packet is part of an established connection. A stateful firewall tracks connection state — it automatically allows return traffic for established connections without an explicit rule. AWS Security Groups are stateful. Basic iptables without connection tracking is stateless. In practice, stateful is almost always what you want — you should not need to write rules for return traffic.

**What is the difference between a Security Group and a Network ACL in AWS?**

Security Groups are stateful, operate at the instance level, and only have allow rules — anything not explicitly allowed is denied. Network ACLs are stateless, operate at the subnet level, have both allow and deny rules, and evaluate rules in number order. For most use cases, Security Groups are sufficient. NACLs add a subnet-level layer when you need explicit deny rules or want defense in depth.

**What does iptables -t nat -L DOCKER -n show you?**

Every DNAT rule Docker has created for port bindings. Each `-p host:container` flag you used creates one entry — the host port maps to the container's private IP and container port. If `webstore-db` has no `-p` flag, it will have no entry here — confirming it's internal only and unreachable from outside Docker.

---

## The Complete Journey

**Walk me through what happens when a user opens `webstore.example.com`.**

The browser checks its DNS cache. On miss, the OS queries the recursive resolver. The resolver walks the DNS tree and gets the A record — the webstore server's public IP. The browser initiates a TCP three-way handshake to port 80 or 443. The packet leaves the user's machine with their private IP, hits their home router, which NAT-translates the source to a public IP. The packet travels across the internet — routers forward it hop by hop, the destination IP stays constant, but the MAC address changes at every hop. The packet arrives at the webstore server's public IP. If there's a load balancer, it DNAT-translates to a backend instance. The server's firewall checks the inbound rule — port 80 or 443 allowed, packet accepted. The OS reads the destination port and delivers to nginx. nginx processes the request. The response travels back the same path in reverse.

**What is the systematic debugging order when a service is unreachable?**

DNS first — `dig webstore.example.com` — does the name resolve? Reachability second — `ping IP` — does the host respond at all? Port third — `nc -zv IP PORT` — is the port open? Service fourth — `curl -v http://IP:PORT` — is the application responding? Logs fifth — check the service logs for what it received. This order matters because each step rules out an entire layer before moving down.

---

← [Back to Networking README](../README.md)

---
# SOURCE: 03. Networking – Foundations/fix-networking-navbar.sh
---

#!/bin/bash

# macOS-compatible — uses python3
# Run from inside: notes/03. Networking – Foundations/
# bash fix-navbar.sh

FILES=(
  "01-foundation-and-the-big-picture/README.md"
  "02-addressing-fundamentals/README.md"
  "03-ip-deep-dive/README.md"
  "04-network-devices/README.md"
  "05-subnets-cidr/README.md"
  "06-ports-transport/README.md"
  "07-nat/README.md"
  "08-dns/README.md"
  "09-firewalls/README.md"
  "10-complete-journey/README.md"
)

for file in "${FILES[@]}"; do
  if [ -f "$file" ]; then
    python3 - "$file" << 'EOF'
import sys

filepath = sys.argv[1]

with open(filepath, 'r') as f:
    content = f.read()

if '[Interview]' in content:
    print('already done — skipped')
    sys.exit(0)

# Find the last nav link line and append Interview after it
# Networking files end their nav bar with the last link before a blank line + ---
# Strategy: find the first --- after the nav bar and insert before it

lines = content.split('\n')
nav_end_idx = None

for i, line in enumerate(lines):
    if line.strip() == '---' and i > 0:
        # Check that previous non-empty line looks like a nav link
        for j in range(i-1, -1, -1):
            if lines[j].strip():
                if lines[j].strip().endswith(')') or lines[j].strip().endswith('README.md)'):
                    nav_end_idx = j
                break
        break

if nav_end_idx is None:
    print('nav bar end not found — check manually')
    sys.exit(1)

# Append interview link to the last nav line
lines[nav_end_idx] = lines[nav_end_idx] + ' |\n[Interview](../99-interview-prep/README.md)'

with open(filepath, 'w') as f:
    f.write('\n'.join(lines))

print('updated')
EOF
    echo "✅ $file"
  else
    echo "❌ not found: $file"
  fi
done

echo ""
echo "verify with: head -15 01-foundation-and-the-big-picture/README.md"

---
# SOURCE: 03. Networking – Foundations/networking-labs/01-foundation-addressing-ip-lab.md
---

[Home](../README.md) |
[Labs Index](./README.md) |
[Lab 01](./01-foundation-addressing-ip-lab.md) |
[Lab 02](./02-devices-subnets-lab.md) |
[Lab 03](./03-ports-transport-nat-lab.md) |
[Lab 04](./04-dns-firewalls-lab.md) |
[Lab 05](./05-complete-journey-lab.md)

---

# Lab 01 — Foundation, Addressing & IP

## The Situation

The webstore server exists as a machine on a network. It has a network interface. That interface has a MAC address burned into it by the manufacturer. The server has been assigned an IP address — either manually or by DHCP. When nginx starts and listens on port 80, it binds to that IP. When a request arrives, it arrives at that IP.

Before you can understand any of that — before Docker, before AWS, before containers or cloud — you need to see what a real network interface looks like from the terminal. This lab is that foundation. You will inspect your own machine the same way you would inspect a production server on day one.

## What this lab covers

You will inspect your real network interfaces, read MAC and IP addresses, watch ARP work live, identify private vs public IPs, and prove that localhost means different things in different contexts. Everything you see here maps directly to the theory in files 01, 02, and 03.

## Prerequisites

- [Foundation notes](../01-foundation-and-the-big-picture/README.md)
- [Addressing notes](../02-addressing-fundamentals/README.md)
- [IP Deep Dive notes](../03-ip-deep-dive/README.md)
- Linux terminal access

---

## Section 1 — Your Network Interfaces

**Goal:** Find your MAC address, IP address, and understand what each interface is.

1. Show all network interfaces
```bash
ip addr show
```

**What to observe:**
- `lo` — loopback interface (127.0.0.1) — this is localhost
- `eth0` or `ens3` or `wlan0` — your real network interface
- Each interface has a MAC address (`link/ether`) and an IP (`inet`)

2. Show compact view
```bash
ip -brief addr show
```

3. Find just your IP address
```bash
ip addr show | grep 'inet ' | grep -v '127.0.0.1'
```

4. Find just your MAC address
```bash
ip link show | grep 'link/ether'
```

**Write down:**
- Your IP address: _______________
- Your MAC address: _______________
- Your interface name: _______________

---

## Section 2 — Identify Private vs Public IPs

**Goal:** Classify IP addresses as private or public using the three private ranges.

1. Check your current IP
```bash
ip addr show | grep 'inet '
```

**Is your IP in one of these ranges?**
```
10.0.0.0 - 10.255.255.255      → Private
172.16.0.0 - 172.31.255.255    → Private
192.168.0.0 - 192.168.255.255  → Private
```

2. Find your public IP (what the internet sees)
```bash
curl -s ifconfig.me
```

**What to observe:** This is different from your private IP — NAT in action.

3. Compare them
```bash
echo "Private IP:"
ip addr show | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}'
echo "Public IP:"
curl -s ifconfig.me
echo ""
```

**What to observe:** Two completely different IPs. Your router is translating between them using NAT (covered in file 07).

---

## Section 3 — Inspect the ARP Table

**Goal:** Watch ARP work — see IP to MAC mappings on your local network.

1. View your current ARP cache
```bash
arp -a
```

**What to observe:** IP addresses mapped to MAC addresses for devices on your local network. Your router/gateway will almost certainly be in here.

2. Find your default gateway IP
```bash
ip route | grep default
```

3. Check the gateway's MAC in the ARP table
```bash
arp -a | grep $(ip route | grep default | awk '{print $3}')
```

**What to observe:** Your gateway has both an IP (Layer 3) and a MAC (Layer 2). When you send traffic to the internet, your MAC destination is always this gateway — not the final server. The MAC changes at every hop. The IP destination never changes.

4. Ping something to trigger ARP activity
```bash
ping -c 1 8.8.8.8
arp -a
```

**What to observe:** After pinging, new entries may appear in the ARP cache.

5. View ARP in a different format
```bash
ip neigh show
```

---

## Section 4 — Prove Localhost Is Relative

**Goal:** Prove that 127.0.0.1 always means "this machine" — never crosses network boundaries.

1. Ping localhost
```bash
ping -c 3 127.0.0.1
```

**What to observe:** Works instantly — traffic never leaves your machine

2. Ping localhost by name
```bash
ping -c 3 localhost
```

3. Check /etc/hosts — see the localhost entry
```bash
cat /etc/hosts
```

**What to observe:** `127.0.0.1 localhost` is hardcoded here. This is why `localhost` always resolves to 127.0.0.1 — it never touches DNS.

4. Run a quick web server on localhost
```bash
python3 -m http.server 8888 &
sleep 1
curl http://localhost:8888
kill %1
```

**What to observe:** Server starts on localhost, curl reaches it. This traffic never left your machine. This is how the webstore-api connects to webstore-db when both run on the same server.

---

## Section 5 — DHCP in Action

**Goal:** See what DHCP assigned to your machine.

1. View your full network configuration
```bash
ip addr show
ip route show
cat /etc/resolv.conf
```

**What to observe:** DHCP gave you:
- IP address
- Subnet mask (visible in CIDR notation after the IP)
- Default gateway (in `ip route`)
- DNS server (in `/etc/resolv.conf`)

2. Check when your DHCP lease was obtained (if on Ubuntu/Debian)
```bash
cat /var/lib/dhcp/dhclient.leases 2>/dev/null | tail -20
```

3. View your subnet mask from the IP
```bash
ip addr show | grep 'inet ' | grep -v '127.0.0.1'
```

**What to observe:** The `/24` or `/16` after your IP is your subnet mask in CIDR notation. `/24` means `255.255.255.0` — 254 usable addresses in your subnet.

---

## Section 6 — Break It on Purpose

### Break 1 — Ping a non-existent local IP

```bash
ping -c 3 192.168.1.254
```

**What to observe:** Timeout or `Destination Host Unreachable` — ARP sends a broadcast asking who has that IP. Nobody answers. No MAC address found. Packet cannot be delivered.

### Break 2 — Ping an invalid public IP

```bash
ping -c 3 0.0.0.0
```

**What to observe:** Error — `0.0.0.0` is not a valid destination address.

### Break 3 — Confirm private IPs don't route to internet

```bash
traceroute 10.0.0.1
```

**What to observe:** Either reaches a local device or times out quickly — private IPs never route past your gateway to the internet. RFC 1918 addresses are dropped by internet routers.

---

## Checklist

Do not move to Lab 02 until every box is checked.

- [ ] I ran `ip addr show` and identified my MAC address, IP address, and interface name
- [ ] I ran `curl ifconfig.me` and confirmed my public IP is different from my private IP — I understand this is NAT
- [ ] I ran `arp -a` and found my gateway's MAC address — I understand why the gateway has both an IP and a MAC
- [ ] I confirmed my IP is in one of the three private ranges
- [ ] I pinged localhost and confirmed traffic never left my machine
- [ ] I ran a web server on localhost and confirmed it was reachable only via that machine
- [ ] I read `/etc/hosts` and found the localhost entry — I understand it bypasses DNS
- [ ] I identified what DHCP gave me: IP, subnet mask, gateway, DNS server

---
# SOURCE: 03. Networking – Foundations/networking-labs/02-devices-subnets-lab.md
---

[Home](../README.md) |
[Labs Index](./README.md) |
[Lab 01](./01-foundation-addressing-ip-lab.md) |
[Lab 02](./02-devices-subnets-lab.md) |
[Lab 03](./03-ports-transport-nat-lab.md) |
[Lab 04](./04-dns-firewalls-lab.md) |
[Lab 05](./05-complete-journey-lab.md)

---

# Lab 02 — Network Devices & Subnets

## The Situation

A request arrives at the webstore server. It did not teleport there. It was routed — forwarded hop by hop from the browser's machine through a chain of routers until it reached the subnet the server lives in. Each router along the way made one decision: where do I send this next?

The server itself also makes routing decisions. When the webstore-api tries to reach webstore-db, the OS checks its routing table: is that IP in my subnet (send direct) or somewhere else (send to gateway)? When you deploy the webstore to AWS, you will design the subnets that control this — which services are in the same subnet, which are isolated, which can reach the internet.

This lab is where you learn to read routing tables and design subnets before AWS adds its own layer on top.

## What this lab covers

You will read your routing table and understand every line, watch traceroute reveal the router hops between you and a server, calculate CIDR blocks by hand, identify subnet boundaries, and design a basic multi-tier subnet plan. This maps to files 04 and 05.

## Prerequisites

- [Network Devices notes](../04-network-devices/README.md)
- [Subnets & CIDR notes](../05-subnets-cidr/README.md)
- Lab 01 completed

---

## Section 1 — Read Your Routing Table

**Goal:** Understand every line of your actual routing table.

1. View your routing table
```bash
ip route
```

**Example output:**
```
default via 192.168.1.1 dev eth0
192.168.1.0/24 dev eth0 proto kernel scope link src 192.168.1.45
```

**What each line means:**

```
default via 192.168.1.1 dev eth0
  ↑         ↑             ↑
  Default   Gateway IP    Interface to use
  route     (router)

  "For everything not matched by a specific route,
   send to 192.168.1.1 via eth0"

192.168.1.0/24 dev eth0 proto kernel scope link
  ↑              ↑
  Your subnet    "Deliver directly, no router needed"

  "For any IP in 192.168.1.0-255, send directly via eth0"
```

2. View more detailed routing table
```bash
netstat -rn
```

3. Find your default gateway
```bash
ip route | grep default | awk '{print $3}'
```

4. Confirm the gateway is reachable
```bash
ping -c 3 $(ip route | grep default | awk '{print $3}')
```

**What to observe:** Gateway responds — your Layer 3 path to the internet is working.

---

## Section 2 — Watch Routing with Traceroute

**Goal:** See each router hop between you and a remote server.

1. Install traceroute if needed
```bash
sudo apt install traceroute -y 2>/dev/null || sudo yum install traceroute -y 2>/dev/null
```

2. Trace route to Google DNS
```bash
traceroute -n 8.8.8.8
```

**What to observe:**
- First hop = your router (default gateway)
- Each subsequent hop = a router on the internet
- Times show latency at each hop
- `* * *` = router not responding to traceroute probes (firewall)

3. Trace to a closer server
```bash
traceroute -n google.com
```

4. Count the hops
```bash
traceroute -n 8.8.8.8 | wc -l
```

5. Compare hops to different destinations
```bash
echo "=== To 8.8.8.8 ===" && traceroute -n -m 10 8.8.8.8
echo "=== To 1.1.1.1 ===" && traceroute -n -m 10 1.1.1.1
```

**What to observe:** Different paths to different destinations — routers make independent forwarding decisions at every hop.

---

## Section 3 — CIDR Calculation by Hand

**Goal:** Calculate IP ranges from CIDR notation without a tool.

**The formula:** `Total IPs = 2^(32 - CIDR prefix)`

Work through each one manually before checking:

**Exercise 1: 192.168.1.0/24**
```
Host bits = 32 - 24 = 8
Total IPs = 2^8 = ?
Usable IPs = Total - 2 = ?
Range = 192.168.1.0 to 192.168.1.?
```

**Exercise 2: 10.0.0.0/16**
```
Host bits = 32 - 16 = 16
Total IPs = 2^16 = ?
Range = 10.0.0.0 to 10.0.?.?
```

**Exercise 3: 172.16.0.0/28**
```
Host bits = 32 - 28 = 4
Total IPs = 2^4 = ?
Usable IPs = Total - 2 = ?
Range = 172.16.0.0 to 172.16.0.?
```

2. Verify with ipcalc (install if needed)
```bash
sudo apt install ipcalc -y 2>/dev/null
ipcalc 192.168.1.0/24
ipcalc 10.0.0.0/16
ipcalc 172.16.0.0/28
```

**What to observe:** Confirm your calculations. Focus on: Network, Broadcast, HostMin, HostMax, Hosts/Net.

3. Check if two IPs are in the same subnet
```bash
ipcalc 192.168.1.45/24
ipcalc 192.168.1.200/24
```

**What to observe:** Same Network address → same subnet → can communicate directly without a router.

```bash
ipcalc 192.168.1.45/24
ipcalc 192.168.2.50/24
```

**What to observe:** Different Network address → different subnets → need a router.

---

## Section 4 — Identify Your Subnet

**Goal:** Calculate your own subnet boundaries from your actual IP.

1. Get your IP and prefix
```bash
ip addr show | grep 'inet ' | grep -v '127.0.0.1'
```

2. Calculate your subnet range
```bash
MY_IP=$(ip addr show | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}')
ipcalc $MY_IP
```

**What to observe:**
- Network = first IP in your subnet
- Broadcast = last IP in your subnet
- HostMin = first usable IP
- HostMax = last usable IP

3. Confirm your gateway is in your subnet
```bash
GATEWAY=$(ip route | grep default | awk '{print $3}')
echo "Gateway: $GATEWAY"
ipcalc $MY_IP | grep -E 'Network|HostMin|HostMax'
```

**What to observe:** The gateway IP should be within the HostMin-HostMax range — it is a device on your subnet.

---

## Section 5 — Design a Webstore Subnet Plan

**Goal:** Apply CIDR knowledge to plan a real multi-tier network for the webstore.

This is a paper exercise. Answer each question before moving on.

**Scenario:** You are deploying the webstore to a server environment with three tiers.

**Requirements:**
- Network CIDR: `10.0.0.0/16`
- 3 tiers: web/frontend, api, database
- 2 availability zones (AZ-a and AZ-b)
- Web tier: needs ~50 IPs per AZ
- API tier: needs ~100 IPs per AZ
- DB tier: needs ~20 IPs per AZ (postgres must be isolated — no direct internet access)

**Questions to answer:**

```
1. How many total IPs does 10.0.0.0/16 give you?
   Answer: ___

2. Which CIDR would you use for each tier?
   
   Web tier:  needs 50 IPs  → use /__ (gives ___ usable)
   API tier:  needs 100 IPs → use /__ (gives ___ usable)
   DB tier:   needs 20 IPs  → use /__ (gives ___ usable)

3. Assign non-overlapping CIDRs:
   
   web-az-a:  10.0.___.0/___
   web-az-b:  10.0.___.0/___
   api-az-a:  10.0.___.0/___
   api-az-b:  10.0.___.0/___
   db-az-a:   10.0.___.0/___
   db-az-b:   10.0.___.0/___

4. Do any of your subnets overlap? Check by listing ranges.

5. Which subnets should be public (reachable from internet)?
   Which should be private (no direct internet access)?
   Why does the database subnet need to be private?
```

**Reference answer structure (fill in your own values):**
```
Network: 10.0.0.0/16

web-az-a:  10.0.1.0/24   (254 usable) ← public
web-az-b:  10.0.11.0/24               ← public
api-az-a:  10.0.2.0/24               ← public or private
api-az-b:  10.0.12.0/24
db-az-a:   10.0.3.0/24               ← private (no internet route)
db-az-b:   10.0.13.0/24              ← private
```

---

## Section 6 — Break It on Purpose

### Break 1 — Try to ping outside your subnet directly

```bash
# Find an IP that's NOT in your subnet
# If you're on 192.168.1.0/24, try pinging 192.168.2.1
ping -c 3 192.168.2.1
```

**What to observe:** Either times out or succeeds via routing — in either case your machine sent it to the gateway first because it is a different subnet.

Prove it with traceroute:
```bash
traceroute -n 192.168.2.1
```

**What to observe:** First hop is your gateway — even for an address that looks local.

### Break 2 — Remove default route (restores on reconnect)

```bash
# Note your default gateway before proceeding
GATEWAY=$(ip route | grep default | awk '{print $3}')
IFACE=$(ip route | grep default | awk '{print $5}')

# Remove default route temporarily
sudo ip route del default

# Try to reach internet
ping -c 2 8.8.8.8

# Restore immediately
sudo ip route add default via $GATEWAY dev $IFACE

# Confirm restored
ip route
ping -c 2 8.8.8.8
```

**What to observe:** Without default route, internet is unreachable. Packets with no matching route are dropped. The routing table entry is not optional.

---

## Checklist

Do not move to Lab 03 until every box is checked.

- [ ] I read my routing table and explained every line in plain English
- [ ] I identified my default gateway and confirmed it responds to ping
- [ ] I ran traceroute to 8.8.8.8 and identified the first hop as my router
- [ ] I calculated total and usable IPs for /24, /16, and /28 by hand — then verified with ipcalc
- [ ] I confirmed my gateway IP is within my subnet range
- [ ] I designed a 6-subnet webstore plan with non-overlapping CIDRs and identified which subnets should be public vs private
- [ ] I removed the default route temporarily and confirmed internet was unreachable, then restored it

---
# SOURCE: 03. Networking – Foundations/networking-labs/03-ports-transport-nat-lab.md
---

[Home](../README.md) |
[Labs Index](./README.md) |
[Lab 01](./01-foundation-addressing-ip-lab.md) |
[Lab 02](./02-devices-subnets-lab.md) |
[Lab 03](./03-ports-transport-nat-lab.md) |
[Lab 04](./04-dns-firewalls-lab.md) |
[Lab 05](./05-complete-journey-lab.md)

---

# Lab 03 — Ports, Transport & NAT

## The Situation

Three services share one server. nginx on port 80, webstore-api on port 8080, postgres on port 5432. When a packet arrives at the server's IP, the OS reads the destination port number and delivers it to the right process. Without ports, three services on one machine would be impossible — there would be no way to tell which traffic belonged to which application.

The server also sits behind a router. Its IP address is private — `10.0.1.45` or similar. The router translates that private IP to a public one before packets leave for the internet, and translates back when responses arrive. This NAT process is invisible to both the browser and the server. But when it breaks — or when you need to deliberately expose a service — you need to understand the iptables rules that drive it.

## What this lab covers

You will inspect which ports are listening on your machine, watch the TCP 3-way handshake happen in real time, observe NAT in action at the iptables level, and confirm that UDP behaves differently from TCP. This maps to files 06 and 07.

## Prerequisites

- [Ports & Transport notes](../06-ports-transport/README.md)
- [NAT notes](../07-nat/README.md)
- Lab 02 completed

---

## Section 1 — Inspect Listening Ports

**Goal:** See which applications are listening on which ports right now.

1. Show all listening TCP ports
```bash
sudo ss -tlnp
```

**Column meanings:**
```
State   = LISTEN (waiting for connections)
Local   = IP:Port the service is bound to
         0.0.0.0:22 = listening on ALL interfaces
         127.0.0.1:631 = listening on localhost only
Process = which program owns the socket
```

**What to observe:** If nginx is running, you will see `0.0.0.0:80`. If postgres is installed, look for `127.0.0.1:5432` — it is bound to loopback only by default, meaning nothing outside this machine can reach it.

2. Show listening UDP ports too
```bash
sudo ss -ulnp
```

3. Show all established TCP connections
```bash
ss -tnp
```

4. Find what is on a specific port
```bash
sudo ss -tlnp | grep :22
sudo ss -tlnp | grep :80
```

5. Check if a port is in use before running a service
```bash
sudo ss -tlnp | grep :8080
# If empty — port is free
```

---

## Section 2 — Watch the TCP Handshake

**Goal:** See SYN → SYN-ACK → ACK happen in real time.

1. Use curl with verbose output to see connection details
```bash
curl -v http://example.com 2>&1 | head -30
```

**What to observe:**
```
* Connected to example.com (93.184.216.34) port 80
  ↑ TCP handshake complete — connection established
```

2. See the full HTTPS handshake
```bash
curl -v https://example.com 2>&1 | head -40
```

3. Time the connection
```bash
curl -w "DNS: %{time_namelookup}s\nConnect: %{time_connect}s\nTotal: %{time_total}s\n" \
  -o /dev/null -s http://example.com
```

**What to observe:** `time_connect` shows how long the TCP handshake took. If this is high, the delay is in the network — not the application.

4. Watch a connection establish and close using ss
```bash
# Terminal 1 — watch connections in real time
watch -n 0.5 'ss -tn | grep example.com'

# Terminal 2 — make a request
curl http://example.com
```

**What to observe:** Connection appears as ESTABLISHED, then moves to TIME_WAIT, then disappears.

---

## Section 3 — TCP vs UDP in Practice

**Goal:** Prove TCP and UDP behave differently.

1. Test TCP connection
```bash
nc -zv 8.8.8.8 53
```

**What to observe:** `Connection to 8.8.8.8 53 port [tcp/domain] succeeded`

2. Test UDP connection
```bash
nc -zuv 8.8.8.8 53
```

3. DNS uses UDP — make a DNS query and observe
```bash
dig google.com
# Note: "SERVER: 8.8.8.8#53" and "Query time"
```

4. Force DNS over TCP
```bash
dig +tcp google.com
```

**What to observe:** Same result but uses TCP — slightly slower due to handshake overhead.

5. Test a port that is not open
```bash
nc -zv localhost 9999
```

**What to observe:** `Connection refused` — TCP reached the machine but nothing is listening. This is distinct from a timeout, which means the firewall dropped the packet before it reached the machine.

---

## Section 4 — NAT in Action with iptables

**Goal:** See how NAT rules work at the Linux kernel level using iptables.

1. Check what iptables NAT rules currently exist
```bash
sudo iptables -t nat -L -n -v
```

**What to observe:** Existing NAT rules — PREROUTING (DNAT) and POSTROUTING (SNAT) chains.

2. Manually create a port forwarding rule (DNAT) — this is exactly what Docker does when you pass -p
```bash
# Forward host port 9999 to localhost:8080
sudo iptables -t nat -A PREROUTING -p tcp --dport 9999 -j REDIRECT --to-port 8080
```

3. Start a server on port 8080
```bash
python3 -m http.server 8080 &
SERVER_PID=$!
```

4. Access it via the forwarded port
```bash
curl http://localhost:9999
```

**What to observe:** Request to port 9999 is transparently forwarded to 8080 — this is DNAT in action.

5. Verify the iptables rule you created
```bash
sudo iptables -t nat -L PREROUTING -n -v
```

6. Clean up
```bash
sudo iptables -t nat -D PREROUTING -p tcp --dport 9999 -j REDIRECT --to-port 8080
kill $SERVER_PID 2>/dev/null
```

> **Docker NAT walkthrough:** Docker automates all of this — every `-p host:container` flag creates iptables DNAT rules just like you did above. The full Docker-specific walkthrough is in the Docker networking lab.
> → [Docker Lab 02](../../04.%20Docker%20–%20Containerization/docker-labs/02-networking-volumes-lab.md)

---

## Section 5 — Ephemeral Ports

**Goal:** See ephemeral (client-side) ports in action.

1. Make multiple simultaneous connections and watch port numbers
```bash
curl -s http://example.com &
curl -s http://example.com &
curl -s http://example.com &

ss -tn | grep example.com
```

**What to observe:** Each connection uses a different source port (49152-65535 range). This is how PAT tracks which response belongs to which connection.

2. See your local port range
```bash
cat /proc/sys/net/ipv4/ip_local_port_range
```

---

## Section 6 — Break It on Purpose

### Break 1 — Try to bind to a privileged port without sudo

```bash
python3 -m http.server 80
```

**What to observe:** `Permission denied` — ports below 1024 require root. This is why nginx runs as root initially but drops privileges after binding to port 80.

Fix it with a high port:
```bash
python3 -m http.server 8888 &
curl http://localhost:8888
kill %1
```

### Break 2 — Try to bind same port twice

```bash
python3 -m http.server 7777 &
python3 -m http.server 7777
```

**What to observe:** `Address already in use` — only one process can bind to a port at a time. This is why starting nginx when nginx is already running fails.

```bash
kill %1
```

### Break 3 — Connection refused vs timeout

```bash
# Connection refused (port not listening)
nc -zv localhost 9876
# Fast response: "Connection refused"

# Connection timeout (firewall or no route)
nc -zv -w 3 192.0.2.1 80
# Slow response after 3 seconds: "Operation timed out"
```

**What to observe:** Refused = server reachable but nothing listening. Timeout = cannot reach the server at all — firewall dropped the packet or no route exists.

---

## Checklist

Do not move to Lab 04 until every box is checked.

- [ ] I ran `ss -tlnp` and identified at least 3 listening services and their ports — I noted whether each is bound to `0.0.0.0` or `127.0.0.1` and understand the difference
- [ ] I used `curl -v` and saw the TCP connection established message
- [ ] I timed a TCP connection with `curl -w` and noted the connect time vs total time
- [ ] I used `nc -zv` to test both TCP and UDP connections to port 53
- [ ] I manually created a DNAT iptables rule and confirmed port forwarding worked
- [ ] I verified the iptables rule with `iptables -t nat -L PREROUTING -n`
- [ ] I produced "Address already in use", "Connection refused", and "Permission denied" errors on purpose — I can explain what each one means

---
# SOURCE: 03. Networking – Foundations/networking-labs/04-dns-firewalls-lab.md
---

[Home](../README.md) |
[Labs Index](./README.md) |
[Lab 01](./01-foundation-addressing-ip-lab.md) |
[Lab 02](./02-devices-subnets-lab.md) |
[Lab 03](./03-ports-transport-nat-lab.md) |
[Lab 04](./04-dns-firewalls-lab.md) |
[Lab 05](./05-complete-journey-lab.md)

---

# Lab 04 — DNS & Firewalls

## The Situation

Nobody types `10.0.1.45` into a browser. They type `webstore.example.com`. DNS translates that name to an IP before any packet is sent. The TTL on that DNS record controls how long the translation is cached — if you move the server to a new IP, browsers will keep going to the old one until the TTL expires. This is why DNS changes always require a propagation wait.

The firewall is the last gatekeeper before the server. nginx is reachable because iptables has an ACCEPT rule for port 80. postgres is not reachable from outside because port 5432 is either blocked or bound only to localhost. The distinction between stateful and stateless firewalls — auto-allowing return traffic vs requiring explicit rules for both directions — is what separates a working security configuration from a broken one.

## What this lab covers

You will trace a DNS query from your machine all the way to the authoritative server, query different record types, observe TTL caching, write firewall rules that block and allow traffic, and prove the difference between stateful and stateless behavior. This maps to files 08 and 09.

## Prerequisites

- [DNS notes](../08-dns/README.md)
- [Firewalls notes](../09-firewalls/README.md)
- Lab 03 completed

---

## Section 1 — DNS Resolution in Depth

**Goal:** Watch the full DNS resolution chain from your machine to the authoritative server.

1. Basic lookup
```bash
dig google.com
```

**What to observe in the output:**
```
;; ANSWER SECTION:
google.com.    300    IN    A    142.250.190.46
               ↑           ↑    ↑
               TTL         Type IP address

;; Query time: 23 msec
;; SERVER: 8.8.8.8#53
```

2. Short format (just the IP)
```bash
dig google.com +short
```

3. Trace the full resolution chain — root → TLD → authoritative
```bash
dig +trace google.com
```

**What to observe:**
- First queries go to root servers (`.`)
- Root delegates to `.com` TLD
- TLD delegates to google's nameservers
- Google's NS returns the final answer

4. Query a specific DNS server directly
```bash
dig @1.1.1.1 google.com
dig @8.8.8.8 google.com
```

5. Compare response times between DNS servers
```bash
echo "=== Default DNS ===" && dig google.com | grep "Query time"
echo "=== Cloudflare ===" && dig @1.1.1.1 google.com | grep "Query time"
echo "=== Google DNS ===" && dig @8.8.8.8 google.com | grep "Query time"
```

---

## Section 2 — DNS Record Types

**Goal:** Query different record types and understand what each returns.

1. A record (IPv4 address)
```bash
dig A google.com +short
```

2. AAAA record (IPv6 address)
```bash
dig AAAA google.com +short
```

3. MX record (mail servers)
```bash
dig MX google.com +short
```

4. NS record (authoritative nameservers)
```bash
dig NS google.com +short
```

5. TXT record (text data — SPF, verification, etc.)
```bash
dig TXT google.com +short
```

6. CNAME record (alias)
```bash
dig CNAME www.github.com +short
```

**What to observe:** www.github.com is likely a CNAME pointing to github.com — two DNS lookups happen when you visit it.

7. Reverse DNS lookup (IP to domain)
```bash
dig -x 8.8.8.8 +short
```

---

## Section 3 — DNS Caching and TTL

**Goal:** Observe TTL and prove caching works.

1. Look up a domain and note the TTL
```bash
dig google.com | grep -A1 'ANSWER SECTION'
```

Note the TTL value (e.g., `300`).

2. Query it again immediately
```bash
dig google.com | grep -A1 'ANSWER SECTION'
```

**What to observe:** TTL has decreased — your resolver cached the result and is counting down. When TTL reaches zero the cache is invalidated and a fresh lookup happens. This is why DNS changes take time to propagate.

3. Check your local DNS cache
```bash
systemd-resolve --statistics | grep -i cache
```

4. Flush DNS cache and see the difference
```bash
sudo systemd-resolve --flush-caches 2>/dev/null || \
sudo killall -HUP dnsmasq 2>/dev/null || \
echo "Cache flush not available on this system"

time dig google.com +short
```

5. Test /etc/hosts override
```bash
echo "1.2.3.4 webstore.fake" | sudo tee -a /etc/hosts

nslookup webstore.fake
ping -c 1 webstore.fake

sudo sed -i '/webstore.fake/d' /etc/hosts
```

**What to observe:** `/etc/hosts` entries override DNS completely — the OS never queries a DNS server for names found in this file. This is how development environments fake service hostnames without a real DNS server.

---

## Section 4 — Docker DNS

> **This section is covered in the Docker networking lab.**
>
> Docker's embedded DNS server (`127.0.0.11`), container name resolution, and verifying `/etc/resolv.conf` inside containers are all hands-on exercises in the Docker lab.
>
> → [Docker Lab 02 — Networking & Volumes](../../04.%20Docker%20–%20Containerization/docker-labs/02-networking-volumes-lab.md)
>
> Complete that lab after finishing this one.

---

## Section 5 — Firewall Rules with iptables

**Goal:** Write real firewall rules, test them, and understand stateful behavior.

1. Check current firewall rules
```bash
sudo iptables -L -n -v
```

2. Start a simple web server to use as a target
```bash
python3 -m http.server 7777 &
SERVER_PID=$!

curl -s http://localhost:7777 > /dev/null && echo "Server reachable"
```

3. Block port 7777 outbound
```bash
sudo iptables -A OUTPUT -p tcp --dport 7777 -j DROP
```

4. Test it
```bash
curl -m 3 http://localhost:7777
```

**What to observe:** Connection times out — iptables dropped the outbound packets before they reached the server.

5. Remove the rule
```bash
sudo iptables -D OUTPUT -p tcp --dport 7777 -j DROP
curl -m 3 http://localhost:7777 > /dev/null && echo "Reachable again"
```

6. Block by source IP
```bash
sudo iptables -A INPUT -p tcp -s 127.0.0.1 --dport 7777 -j DROP
curl -m 3 http://localhost:7777

sudo iptables -D INPUT -p tcp -s 127.0.0.1 --dport 7777 -j DROP
curl -m 3 http://localhost:7777 > /dev/null && echo "Reachable again"
```

7. Clean up server
```bash
kill $SERVER_PID 2>/dev/null
```

---

## Section 6 — Stateful vs Stateless Demonstration

**Goal:** Prove stateful behavior by blocking return traffic.

1. Start a server
```bash
python3 -m http.server 6666 &
SERVER_PID=$!
```

2. Allow inbound port 6666
```bash
sudo iptables -A INPUT -p tcp --dport 6666 -j ACCEPT
```

3. Test — stateful behavior allows return traffic automatically
```bash
curl -s http://localhost:6666 > /dev/null && echo "Works — stateful allows return traffic automatically"
```

4. Now block established connections (simulate stateless)
```bash
sudo iptables -I INPUT -m state --state ESTABLISHED,RELATED -j DROP
curl -m 3 http://localhost:6666
```

**What to observe:** Fails — we blocked the return traffic, simulating stateless behavior. The request got in but the response could not get back.

5. Restore
```bash
sudo iptables -D INPUT -m state --state ESTABLISHED,RELATED -j DROP
sudo iptables -D INPUT -p tcp --dport 6666 -j ACCEPT
kill $SERVER_PID 2>/dev/null
```

**Key insight:** AWS Security Groups are stateful — inbound rule only needed, return traffic auto-allowed. AWS NACLs are stateless — both inbound AND outbound rules needed including ephemeral ports. This is why NACL misconfiguration is the most common AWS networking mistake.

---

## Section 7 — Break It on Purpose

### Break 1 — Query a non-existent domain

```bash
dig nonexistent-domain-xyz99999.com +short
nslookup nonexistent-domain-xyz99999.com
```

**What to observe:** NXDOMAIN — domain does not exist. If you see this for a real domain, either the domain was deleted, the DNS record was removed, or you are querying the wrong DNS server.

### Break 2 — Query with wrong DNS server

```bash
dig @192.168.99.99 google.com
```

**What to observe:** Timeout — DNS server unreachable. This is what happens when `/etc/resolv.conf` points to a DNS server that is down or wrong.

### Break 3 — Simulate the NACL trap (stateless)

```bash
python3 -m http.server 5555 &
SERVER_PID=$!

# Allow inbound (like NACL inbound rule)
sudo iptables -A INPUT -p tcp --dport 5555 -j ACCEPT

# Block outbound response (like NACL missing ephemeral rule)
sudo iptables -A OUTPUT -p tcp --sport 5555 -j DROP

curl -m 3 http://localhost:5555
```

**What to observe:** Request gets in (inbound allowed) but response is blocked (outbound blocked) — exactly the AWS NACL trap when someone forgets the outbound ephemeral port rule.

```bash
sudo iptables -D OUTPUT -p tcp --sport 5555 -j DROP
sudo iptables -D INPUT -p tcp --dport 5555 -j ACCEPT
kill $SERVER_PID 2>/dev/null
```

---

## Checklist

Do not move to Lab 05 until every box is checked.

- [ ] I ran `dig +trace google.com` and identified root servers, TLD servers, and authoritative servers
- [ ] I queried A, AAAA, MX, NS, TXT, and CNAME record types and know what each one contains
- [ ] I queried the same domain twice and observed the TTL counting down — I understand what this means for DNS changes
- [ ] I added a fake entry to `/etc/hosts` and confirmed it overrode DNS without touching any DNS server
- [ ] I used iptables to block a port and confirmed connection timed out, then unblocked it
- [ ] I demonstrated stateful behavior (return traffic auto-allowed) vs stateless (return traffic blocked)
- [ ] I queried a non-existent domain and got NXDOMAIN
- [ ] I simulated the NACL trap — inbound allowed but response blocked — and understood why it happens
- [ ] I noted that Docker DNS exercises are in Docker Lab 02

---
# SOURCE: 03. Networking – Foundations/networking-labs/05-complete-journey-lab.md
---

[Home](../README.md) |
[Labs Index](./README.md) |
[Lab 01](./01-foundation-addressing-ip-lab.md) |
[Lab 02](./02-devices-subnets-lab.md) |
[Lab 03](./03-ports-transport-nat-lab.md) |
[Lab 04](./04-dns-firewalls-lab.md) |
[Lab 05](./05-complete-journey-lab.md)

---

# Lab 05 — The Complete Journey

## The Situation

A user types `webstore.example.com` into a browser and presses Enter. You are the engineer who built that server. Something is wrong — the page is not loading. You have a terminal.

This is the lab where every concept from the previous four labs converges into one skill: systematic debugging. DNS, routing, ports, NAT, firewalls — you have practiced each one separately. Now you use all of them together, in order, working from the outside in until you find where the chain breaks.

By the end of this lab you can trace a complete request from browser to server, document every layer, and answer the interview question that every DevOps role asks: "Walk me through what happens when a user opens a URL."

## What this lab covers

You will trace a complete request from your machine to a real server using every tool from the previous labs — DNS, routing, ports, NAT, firewalls — and document every layer. Then you will simulate a production debugging scenario and use a systematic approach to find and fix the problem. This maps to file 10.

## Prerequisites

- All previous labs completed
- [Complete Journey notes](../10-complete-journey/README.md)

---

## Section 1 — Full Packet Trace to google.com

**Goal:** Document every step of a real request using the tools you have learned.

Run each command and write down what you observe.

**Step 1: DNS — name to IP**
```bash
dig google.com +short
```
Record: `google.com → _______________`

**Step 2: Routing — how does your machine reach that IP?**
```bash
ip route get $(dig google.com +short | head -1)
```
Record: `Packets go via gateway: _______________`

**Step 3: How many hops to get there?**
```bash
traceroute -n -m 15 $(dig google.com +short | head -1)
```
Record: `Number of hops: ___`

**Step 4: Is the port open?**
```bash
nc -zv google.com 443
```
Record: Port 443 open? ___

**Step 5: What does your machine look like to google.com?**
```bash
curl -s https://ifconfig.me
```
Record: `Google sees you as: _______________` (your public IP — NAT in action)

**Step 6: Make the actual HTTP request and see all layers**
```bash
curl -v https://google.com 2>&1 | head -50
```

**What to observe in the verbose output:**
```
* Trying 142.250.190.46:443...    ← Layer 3/4: IP + port
* Connected to google.com         ← TCP handshake complete
* TLSv1.3 (OUT), TLS handshake   ← Layer 6: TLS
> GET / HTTP/2                    ← Layer 7: HTTP request
< HTTP/2 301                      ← Layer 7: HTTP response
```

**Step 7: Capture actual packets (requires sudo)**
```bash
# In one terminal — capture traffic
sudo tcpdump -i any -n host google.com -c 20 2>/dev/null &
TCPDUMP_PID=$!

# Make a request
curl -s http://google.com > /dev/null

sleep 2
kill $TCPDUMP_PID 2>/dev/null
```

**What to observe:** Real packets with source/destination IPs and ports. Note how your source port is an ephemeral number — a different one for each connection.

---

## Section 2 — Document the Full Journey

**Goal:** Write out every layer for a request to google.com in your own words.

Fill in this template based on what you observed:

```
REQUEST: curl https://google.com

Layer 7 (DNS):
  Resolved: google.com → ___.___.___.___ 

Layer 3-4 (Routing + TCP):
  Your private IP: ___.___.___.___ 
  Your gateway:    ___.___.___.___ 
  TCP handshake to: google.com:___

Layer 2 (Local delivery):
  First hop MAC: ___ (your gateway)

NAT (at your router):
  Private IP ___.___.___.___  → Public IP ___.___.___.___ 

Internet transit:
  Number of hops: ___
  MAC changed at each hop
  IP stayed constant: ___.___.___.___ 

At Google:
  Port 443 → HTTPS application
  Response sent back

Return journey:
  NAT translates public IP back to your private IP
  Response delivered to your browser
```

---

## Section 3 — Docker Webstore Simulation

> **This section is covered in the Docker networking lab.**
>
> Running the webstore stack in Docker and tracing DNS, routing, ports, and NAT within containers are hands-on exercises built into the Docker lab. The Docker lab has the complete webstore setup with all verification commands.
>
> → [Docker Lab 02 — Networking & Volumes](../../04.%20Docker%20–%20Containerization/docker-labs/02-networking-volumes-lab.md)
>
> Complete that lab after finishing the networking labs series.

---

## Section 4 — Production Debugging Simulation

**Goal:** Use the systematic debugging framework to find and fix three broken connections.

**Setup — start a web server:**
```bash
python3 -m http.server 4444 &
SERVER_PID=$!
curl -s http://localhost:4444 > /dev/null && echo "Server working"
```

---

**Break 1 — DNS failure simulation:**
```bash
echo "127.0.0.1 broken-webstore.com" | sudo tee -a /etc/hosts
nslookup working-webstore.com
```

**Debug it:**
```bash
nslookup working-webstore.com
cat /etc/hosts | grep webstore
```

**Fix it:**
```bash
echo "127.0.0.1 working-webstore.com" | sudo tee -a /etc/hosts
nslookup working-webstore.com
curl http://working-webstore.com:4444 -s > /dev/null && echo "Fixed"

sudo sed -i '/webstore.com/d' /etc/hosts
```

---

**Break 2 — Port blocked:**
```bash
sudo iptables -A INPUT -p tcp --dport 4444 -j DROP
curl -m 3 http://localhost:4444
```

**Debug it using the framework:**
```bash
# Step 1: Host reachable?
ping -c 2 localhost

# Step 2: Port open?
nc -zv localhost 4444
# Finding: timeout — firewall blocking, not "connection refused"

# Step 3: Check firewall rules
sudo iptables -L INPUT -n | grep 4444

# Fix
sudo iptables -D INPUT -p tcp --dport 4444 -j DROP

nc -zv localhost 4444
curl http://localhost:4444 -s > /dev/null && echo "Fixed"
```

---

**Break 3 — Service not running:**
```bash
kill $SERVER_PID 2>/dev/null
curl -m 3 http://localhost:4444
```

**Debug it:**
```bash
# Port open?
nc -zv localhost 4444
# Connection refused — nothing listening (different from timeout)

# What's listening?
ss -tlnp | grep 4444
# Nothing — service is down

# Fix
python3 -m http.server 4444 &
SERVER_PID=$!
sleep 1
curl http://localhost:4444 -s > /dev/null && echo "Fixed"

kill $SERVER_PID 2>/dev/null
```

---

## Section 5 — The Interview Answer

**Goal:** Practice explaining the full packet journey out loud.

Open the [networking map](../00-networking-map/README.md) and answer this question as if in an interview:

> "Walk me through exactly what happens when a user opens webstore.com. Start from their browser and end at the server response."

Your answer should cover:
- DNS resolution (what servers are involved)
- TCP handshake
- NAT at the home router
- Internet routing (what changes at each hop and what stays the same)
- How the server's firewall decides to accept or drop the connection
- Server receives and responds
- Return path

Time yourself. Aim for 90 seconds covering all key points without looking at notes.

---

## Final Checklist

- [ ] I traced a complete request to google.com using dig, ip route, traceroute, nc, and curl -v
- [ ] I filled in the complete journey template with my actual observed values
- [ ] I identified my public IP with `curl ifconfig.me` and confirmed it differs from my private IP
- [ ] I noted that the Docker webstore simulation is in Docker Lab 02
- [ ] I debugged all 3 break scenarios using the systematic framework (DNS → reachability → port → service) — I can explain what "connection refused" vs "timeout" each tells you
- [ ] I can explain the full packet journey from browser to server in 90 seconds without notes
- [ ] I reviewed the networking map and understand every row

---
# SOURCE: 03. Networking – Foundations/networking-labs/README.md
---

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

---
# SOURCE: 03. Networking – Foundations/README.md
---

<p align="center">
  <img src="../../assets/networking-banner.svg" alt="networking" width="100%"/>
</p>

[← devops-runbook](../../README.md) |
[Foundation](./01-foundation-and-the-big-picture/README.md) |
[Addressing](./02-addressing-fundamentals/README.md) |
[IP Deep Dive](./03-ip-deep-dive/README.md) |
[Devices](./04-network-devices/README.md) |
[Subnets & CIDR](./05-subnets-cidr/README.md) |
[Ports & Transport](./06-ports-transport/README.md) |
[NAT](./07-nat/README.md) |
[DNS](./08-dns/README.md) |
[Firewalls](./09-firewalls/README.md) |
[Complete Journey](./10-complete-journey/README.md) |
[Interview](./99-interview-prep/README.md)

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
