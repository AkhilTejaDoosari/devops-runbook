# File 10: Complete Journey & OSI Deep Dive

[← devops-runbook](../../README.md) |
[Foundation](../01-foundation-and-the-big-picture/README.md) |
[Addressing](../02-addressing-fundamentals/README.md) |
[IP Deep Dive](../03-ip-deep-dive/README.md) |
[Network Devices](../04-network-devices/README.md) |
[Subnets & CIDR](../05-subnets-cidr/README.md) |
[Ports & Transport](../06-ports-transport/README.md) |
[NAT](../07-nat/README.md) |
[DNS](../08-dns/README.md) |
[Firewalls](../09-firewalls/README.md) |
[Complete Journey](../10-complete-journey/README.md)

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