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
[Complete Journey](../10-complete-journey/README.md)

---

# NAT & Translation

## What this file is about

This file teaches **how devices with private IPs access the internet** and **how your router manages multiple devices with one public IP**. If you understand this, you'll know why your home router can support 50+ devices with one IP, how to expose services running on private networks, and how AWS NAT Gateways work. This is critical for cloud networking.

<!-- no toc -->
- [The Core Problem](#the-core-problem)
- [Why NAT Exists](#why-nat-exists)
- [How NAT Works (Basic)](#how-nat-works-basic)
- [PAT: Port Address Translation](#pat-port-address-translation)
- [The NAT Table](#the-nat-table)
- [Port Forwarding (Inbound NAT)](#port-forwarding-inbound-nat)
- [NAT Types and Variations](#nat-types-and-variations)
- [AWS NAT Gateway](#aws-nat-gateway)
- [Docker Port Binding (NAT in Action)](#docker-port-binding-nat-in-action)
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
│           Your Router                │
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

Problem: How do private devices access the internet?
```

**Without NAT:**

```
Laptop (192.168.1.45) → Google (142.250.190.46)

Packet:
  Source IP: 192.168.1.45 (private)
  Dest IP:   142.250.190.46 (public)

Google receives packet
Google tries to respond:
  Source IP: 142.250.190.46
  Dest IP:   192.168.1.45 ← Private IP!

Internet routers: "192.168.1.45 is not routable"
Packet dropped
Laptop never gets response

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
  
  Source Port:     54321 (unchanged for now)
  Dest IP:         142.250.190.46 (unchanged)
  Dest Port:       443 (unchanged)

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
  New Dest IP:   192.168.1.45 (laptop's private IP)
  
  Dest Port:     54321 (unchanged)
  Source IP:     142.250.190.46 (unchanged)
  Source Port:   443 (unchanged)
```

**Step 6: Router forwards to laptop**

```
Router sends packet to LAN:
  Source IP:   142.250.190.46
  Source Port: 443
  Dest IP:     192.168.1.45 (laptop)
  Dest Port:   54321

Laptop receives response
Communication successful!
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
│  │    ↔ 203.45.67.89:54321                              │
│  └─────────────────────┘                                 │
│        │                                                 │
│        │ 2. Translated request                           │
│        │    Src: 203.45.67.89:54321 ← Changed            │
│        │    Dst: 142.250.190.46:443                      │
│        ▼                                                 │
└──────────────────────────────────────────────────────────┘
         │
         │ Internet
         ▼
┌──────────────────────────────────────────────────────────┐
│  [Google: 142.250.190.46]                                │
│        │                                                 │
│        │ 3. Response                                     │
│        │    Src: 142.250.190.46:443                      │
│        │    Dst: 203.45.67.89:54321 ← Router's IP        │
│        ▼                                                 │
└──────────────────────────────────────────────────────────┘
         │
         │ Internet
         ▼
┌──────────────────────────────────────────────────────────┐
│  ┌─────────────────────┐                                 │
│  │  Router / NAT       │                                 │
│  │                     │                                 │
│  │  Checks NAT table:  │                                 │
│  │  Port 54321 →       │                                 │
│  │    192.168.1.45     │                                 │
│  └─────────────────────┘                                 │
│        │                                                 │
│        │ 4. Reverse translation                          │
│        │    Src: 142.250.190.46:443                      │
│        │    Dst: 192.168.1.45:54321 ← Changed back       │
│        ▼                                                 │
│  [Laptop: 192.168.1.45]                                  │
│        │                                                 │
│        ✓ Receives response                               │
└──────────────────────────────────────────────────────────┘
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
Two devices access same server:

Laptop:  192.168.1.45:54321 → Google:443
Phone:   192.168.1.67:54321 → Google:443

Both happen to use port 54321 (random collision)

With basic NAT:
  Both translate to: 203.45.67.89:54321

Google responds to: 203.45.67.89:54321
  
Router receives response
Problem: Which device should receive it?
  Laptop (192.168.1.45)?
  Phone (192.168.1.67)?
  
❌ Ambiguous! NAT table collision!
```

---

### How PAT Solves This

**PAT changes BOTH IP and port:**

```
Laptop request:
  Original: 192.168.1.45:54321 → Google:443
  After PAT: 203.45.67.89:10001 → Google:443
            └────────────┘└────┘
            Public IP     New port

Phone request:
  Original: 192.168.1.67:54321 → Google:443
  After PAT: 203.45.67.89:10002 → Google:443
            └────────────┘└────┘
            Public IP     Different new port

PAT Table:
  192.168.1.45:54321 ↔ 203.45.67.89:10001
  192.168.1.67:54321 ↔ 203.45.67.89:10002

No collision! Each connection has unique translated port.
```

---

### PAT Step-by-Step

**Outbound (laptop → internet):**

```
1. Laptop sends:
   Src: 192.168.1.45:54321
   Dst: 142.250.190.46:443

2. Router checks PAT table for existing mapping
   Not found → Create new mapping

3. Router allocates unused port: 10001

4. Router creates PAT entry:
   192.168.1.45:54321 ↔ 203.45.67.89:10001

5. Router translates and forwards:
   Src: 203.45.67.89:10001 ← Changed
   Dst: 142.250.190.46:443
```

**Inbound (internet → laptop):**

```
1. Google responds:
   Src: 142.250.190.46:443
   Dst: 203.45.67.89:10001

2. Router receives on WAN interface

3. Router looks up port 10001 in PAT table:
   10001 → 192.168.1.45:54321

4. Router translates:
   Src: 142.250.190.46:443
   Dst: 192.168.1.45:54321 ← Changed back

5. Router forwards to laptop
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
  Connection 3: 203.45.67.89:49154
  ...
  Connection N: 203.45.67.89:65535

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
192.168.1.89:48901 ↔ 203.45.67.89:49155 ↔ 8.8.8.8:53          60s
```

---

### NAT Table Entries

**Each entry contains:**

```
1. Internal endpoint (private IP:port)
2. External endpoint (public IP:port on router)
3. Remote endpoint (destination IP:port)
4. Protocol (TCP/UDP)
5. Timeout (TTL for entry)
6. State (for TCP: ESTABLISHED, etc.)
```

---

### NAT Table Timeout

**Entries expire after inactivity:**

```
TCP connection:
  Active: Entry stays alive
  Idle for 5 minutes: Entry removed
  New packet: New entry created

UDP (connectionless):
  Packet sent: Entry created
  Idle for 30-60 seconds: Entry removed
```

**Why timeout matters:**

```
Long idle connection:
  Client thinks connection is alive
  NAT table entry expired (timed out)
  Client sends data
  Router: "No NAT entry found"
  Packet dropped
  Connection appears broken

Solution: TCP keepalive or reconnect
```

---

### View NAT Table

**On Linux router:**

```bash
# Using iptables
sudo iptables -t nat -L -n -v

# Using conntrack
sudo conntrack -L

Output:
tcp 6 299 ESTABLISHED src=192.168.1.45 dst=142.250.190.46 \
  sport=54321 dport=443 \
  src=142.250.190.46 dst=203.45.67.89 \
  sport=443 dport=49152
```

**On home router:**

```
Most consumer routers show NAT table in web interface:
  Status → Active Sessions
  or
  Advanced → NAT Table
```

---

## Port Forwarding (Inbound NAT)

### The Problem

**NAT blocks inbound connections:**

```
You run web server on laptop: 192.168.1.45:8080

Friend tries to access from internet:
  http://203.45.67.89:8080

Packet arrives at router:
  Dst: 203.45.67.89:8080

Router checks NAT table:
  No entry for port 8080
  (Entry only exists for outbound connections)

Router: "Where should I send this?"
  No mapping found
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

Router configuration:
  "Forward all traffic to 203.45.67.89:8080
   to 192.168.1.45:8080"
```

---

### How Port Forwarding Works

**Inbound request:**

```
Friend → http://203.45.67.89:8080

1. Packet arrives at router:
   Dst: 203.45.67.89:8080

2. Router checks port forwarding rules:
   Port 8080 → 192.168.1.45:8080

3. Router translates:
   Old Dst: 203.45.67.89:8080
   New Dst: 192.168.1.45:8080

4. Router forwards to laptop

5. Laptop's web server receives request

6. Laptop responds

7. Router performs reverse NAT

8. Friend receives response
```

---

### Port Forwarding Configuration

**Home router web interface:**

```
Port Forwarding Rules:

Service Name: Web Server
External Port: 8080
Internal IP:   192.168.1.45
Internal Port: 8080
Protocol:      TCP
Enabled:       Yes

Service Name: Game Server
External Port: 25565
Internal IP:   192.168.1.50
Internal Port: 25565
Protocol:      TCP/UDP
Enabled:       Yes
```

---

### Common Port Forwarding Use Cases

```
✅ Hosting game servers (Minecraft, etc.)
✅ Running web servers at home
✅ Remote desktop access
✅ Security cameras (remote viewing)
✅ BitTorrent (better connectivity)
✅ Home automation systems
```

---

### Port Forwarding vs DMZ

**Port forwarding (recommended):**

```
Forwards specific ports only
Secure - only exposed ports accessible

Example:
  Forward port 8080 → 192.168.1.45
  All other ports protected
```

**DMZ - Demilitarized Zone (not recommended):**

```
Forwards ALL ports to one device
Insecure - entire device exposed

Example:
  DMZ host: 192.168.1.45
  All inbound traffic → 192.168.1.45
  Device fully exposed to internet
  
⚠️ Security risk!
```

---

## NAT Types and Variations

### Source NAT (SNAT)

**What we've been discussing - outbound translation:**

```
Changes source IP when going outbound

Private → Public
  Src: 192.168.1.45 → 203.45.67.89
```

---

### Destination NAT (DNAT)

**Port forwarding - inbound translation:**

```
Changes destination IP when coming inbound

Public → Private
  Dst: 203.45.67.89:8080 → 192.168.1.45:8080
```

---

### Static NAT

**One-to-one mapping (not common in home):**

```
One private IP always maps to one public IP

Example (enterprise):
  192.168.1.100 ↔ 203.45.67.100 (always)
  192.168.1.101 ↔ 203.45.67.101 (always)
  
Used when: Multiple public IPs available
```

---

### Dynamic NAT

**Pool of public IPs (enterprise):**

```
Public IP pool: 203.45.67.100-110

Outbound connection:
  192.168.1.45 gets 203.45.67.100 (from pool)
  192.168.1.67 gets 203.45.67.101 (from pool)
  
Connection closes:
  203.45.67.100 returns to pool
  
New connection:
  192.168.1.89 gets 203.45.67.100 (reused)
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

## AWS NAT Gateway

### Why AWS Needs NAT

**AWS VPC scenario:**

```
VPC: 10.0.0.0/16

Public Subnet: 10.0.1.0/24
  - Has Internet Gateway
  - Instances get public IPs
  - Can access internet directly

Private Subnet: 10.0.2.0/24
  - No Internet Gateway
  - Instances only have private IPs
  - Cannot access internet directly
  
Problem: How do private instances download updates?
```

---

### NAT Gateway Architecture

```
┌────────────────────────────────────────────┐
│  VPC: 10.0.0.0/16                          │
│                                            │
│  ┌──────────────────────────────────────┐  │
│  │ Public Subnet: 10.0.1.0/24           │  │
│  │                                      │  │
│  │  ┌────────────────┐                  │  │
│  │  │  NAT Gateway   │                  │  │
│  │  │  10.0.1.100    │                  │  │
│  │  │  (Has Elastic  │                  │  │
│  │  │   IP)          │                  │  │
│  │  └────────┬───────┘                  │  │
│  │           │                          │  │
│  └───────────┼──────────────────────────┘  │
│              │                             │
│              │ Routes to Internet Gateway  │
│              │                             │
│  ┌───────────┼──────────────────────────┐  │
│  │           │                          │  │
│  │ Private Subnet: 10.0.2.0/24         │  │
│  │                                     │  │
│  │  [EC2: 10.0.2.50]                   │  │
│  │        │                            │  │
│  │        │ Default route:             │  │
│  │        │ 0.0.0.0/0 → 10.0.1.100     │  │
│  │        │ (NAT Gateway)              │  │
│  └────────┼─────────────────────────────┘  │
│           │                                │
└───────────┼────────────────────────────────┘
            │
            ▼
      [Internet Gateway]
            │
            ▼
        [Internet]
```

---

### NAT Gateway Traffic Flow

**Private instance downloads package:**

```
1. EC2 (10.0.2.50) → Ubuntu mirrors (91.189.88.142)
   
2. Packet reaches NAT Gateway (10.0.1.100)

3. NAT Gateway translates:
   Old Src: 10.0.2.50 (private)
   New Src: 52.10.20.30 (NAT Gateway's Elastic IP)

4. Packet routed via Internet Gateway to internet

5. Ubuntu server responds to 52.10.20.30

6. Response returns to NAT Gateway

7. NAT Gateway translates back:
   Old Dst: 52.10.20.30
   New Dst: 10.0.2.50

8. Packet delivered to EC2 instance

9. Package download completes
```

---

### NAT Gateway Characteristics

```
✅ Managed service (AWS maintains)
✅ Highly available (in single AZ)
✅ Scales automatically (up to 45 Gbps)
✅ Supports TCP, UDP, ICMP
✅ Charged per hour + data processed
❌ Outbound only (no inbound connections)
❌ Single AZ (need one per AZ for HA)
```

---

### NAT Gateway vs NAT Instance

| Feature | NAT Gateway | NAT Instance |
|---------|-------------|--------------|
| **Availability** | Highly available in AZ | You manage |
| **Bandwidth** | Up to 45 Gbps | Instance type dependent |
| **Maintenance** | AWS manages | You manage |
| **Cost** | Higher (managed service) | Lower (EC2 costs) |
| **Security groups** | Cannot be applied | Can be applied |
| **Bastion host** | No | Can be used as bastion |
| **Recommendation** | ✅ Recommended | Legacy |

---

### Terraform NAT Gateway Example

```hcl
# Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"
  
  tags = {
    Name = "nat-gateway-eip"
  }
}

# NAT Gateway in public subnet
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id
  
  tags = {
    Name = "main-nat-gateway"
  }
}

# Route table for private subnet
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }
  
  tags = {
    Name = "private-route-table"
  }
}

# Associate route table with private subnet
resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}
```

---

## Docker Port Binding (NAT in Action)

### Docker Default Networking

**Docker creates isolated network:**

```
Host: 192.168.1.100

Docker bridge network: 172.17.0.0/16
  Docker bridge IP: 172.17.0.1
  
Container:
  IP: 172.17.0.2
  Running nginx on port 80
```

**Problem:**

```
Container is isolated
  IP 172.17.0.2 not accessible from host network
  Cannot access container from outside
```

---

### Docker Port Binding = NAT + Port Forwarding

**Bind container port to host port:**

```bash
docker run -d -p 8080:80 nginx
              │  └───┘ └─────┘
              │   │      └─ Container port (nginx listens here)
              │   └──────── Host port (exposed to outside)
              └──────────── Port flag
```

**What Docker does:**

```
1. Creates NAT rule:
   External (host):8080 → Internal (container):80

2. Sets up iptables rules (Linux):
   DNAT rule: host:8080 → 172.17.0.2:80

3. Configures port forwarding
```

---

### Docker Port Binding Traffic Flow

**Request from outside:**

```
1. Client → http://192.168.1.100:8080

2. Packet arrives at host (192.168.1.100:8080)

3. Docker's iptables rule activates:
   DNAT: 192.168.1.100:8080 → 172.17.0.2:80

4. Packet forwarded to container

5. Nginx receives request on port 80

6. Nginx responds

7. Docker reverse NAT:
   172.17.0.2:80 → 192.168.1.100:8080

8. Response sent to client
```

---

### Docker Networking Modes

**Bridge (default - uses NAT):**

```bash
docker run -d -p 8080:80 nginx

Container isolated
Port binding required for external access
```

**Host (no NAT):**

```bash
docker run -d --network host nginx

Container shares host network
Port 80 directly exposed on host
No NAT/translation needed
```

**None (fully isolated):**

```bash
docker run -d --network none nginx

No network access
No NAT
Container completely isolated
```

---

### Multiple Port Bindings

```bash
docker run -d \
  -p 80:80 \      # HTTP
  -p 443:443 \    # HTTPS
  -p 8080:8080 \  # Alt HTTP
  nginx

Creates multiple NAT rules:
  Host:80    → Container:80
  Host:443   → Container:443
  Host:8080  → Container:8080
```

---

## Real Scenarios

### Scenario 1: Home Network NAT

**Setup:**

```
ISP provides: 203.45.67.89 (public IP)
Router WAN: 203.45.67.89
Router LAN: 192.168.1.1

Devices:
├─ Laptop:    192.168.1.45
├─ Phone:     192.168.1.67
└─ Desktop:   192.168.1.89
```

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

### Scenario 2: AWS Multi-Tier Application

**Architecture:**

```
VPC: 10.0.0.0/16

Public Subnet (10.0.1.0/24):
  ├─ Internet Gateway (attached)
  ├─ NAT Gateway (10.0.1.100, Elastic IP: 52.10.20.30)
  └─ Load Balancer (public-facing)

Private Subnet (10.0.2.0/24):
  ├─ Web Servers (no public IP)
  └─ App Servers (no public IP)

Private Subnet (10.0.3.0/24):
  └─ Databases (no public IP)
```

**Traffic patterns:**

```
Inbound (User → Web Server):
  User → Load Balancer (public IP)
  Load Balancer → Web Server (10.0.2.50)
  No NAT (internal VPC routing)

Outbound (Web Server → Internet):
  Web Server (10.0.2.50) → NAT Gateway (10.0.1.100)
  NAT Gateway translates to Elastic IP (52.10.20.30)
  Internet sees: 52.10.20.30
```

---

### Scenario 3: Port Forwarding for Game Server

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

1. Packet arrives at router
2. Router checks port forwarding: 25565 → 192.168.1.100
3. Router translates destination
4. Packet forwarded to game server
5. Game server responds
6. Router performs reverse NAT
7. Friend receives response
8. Connection established
```

---

### Scenario 4: Docker Application Stack

```bash
# Web frontend
docker run -d -p 80:80 --name web nginx

# API backend
docker run -d -p 3000:3000 --name api node-app

# Database (no external exposure)
docker run -d --name db postgres
```

**NAT rules:**

```
Host:80   → web container (172.17.0.2:80)
Host:3000 → api container (172.17.0.3:3000)

Database: 172.17.0.4:5432
  No port binding
  Only accessible from other containers
  Isolated from external access
```

---

## Final Compression

### Why NAT Exists

```
Problem: Not enough public IPv4 addresses
Solution: Many private IPs share one public IP

Your home: 10 devices, 1 public IP
Office: 500 devices, 5 public IPs
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
192.168.1.89:48901 → 203.45.67.89:49154

Same public IP, different ports
```

---

### Port Forwarding (Inbound NAT)

```
Static mapping for inbound connections

Rule: External:8080 → Internal:192.168.1.45:8080

Internet user → Public IP:8080
Router forwards → Private IP:8080

Use cases: Game servers, web hosting, remote access
```

---

### Router's Two IPs

```
Router has TWO network interfaces:

LAN (Internal):
  IP: 192.168.1.1 (private)
  Your devices connect here

WAN (External):
  IP: 203.45.67.89 (public, from ISP)
  Internet connection

One foot in each network
```

---

### AWS NAT Gateway

```
Purpose: Allow private EC2 instances to access internet

Location: Public subnet
Requires: Elastic IP
Direction: Outbound only

Private instance → NAT Gateway → Internet Gateway → Internet
```

---

### Docker Port Binding

```
docker run -p 8080:80 nginx
          └─ └───┘ └─────┘
          │   │      └─ Container port
          │   └──────── Host port
          └──────────── Creates NAT + port forward

Host:8080 → Container (172.17.0.2:80)
```

---

### NAT Limitations

```
❌ Breaks end-to-end connectivity
❌ Inbound connections blocked (unless port forwarding)
❌ Some protocols don't work well (SIP, FTP)
❌ NAT table can fill up (limit on connections)
✅ Works for most common protocols (HTTP, HTTPS, SSH)
```

---

### Mental Model

```
NAT = Translator between two worlds

Private world (home/office):
  Many devices
  Private IPs (192.168.X.X, 10.X.X.X)
  Cannot route on internet

Public world (internet):
  One public IP (from ISP)
  Internet-routable

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
✅ Design AWS VPC with NAT Gateway  
✅ Understand Docker port binding  
✅ Debug NAT-related connectivity issues  
✅ Know router has two IPs (LAN + WAN)  

---