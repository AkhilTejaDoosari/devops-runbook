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
[Complete Journey](../10-complete-journey/README.md)

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
