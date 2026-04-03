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
[Complete Journey](../10-complete-journey/README.md)

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

**Common Docker mistake:**

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

### Scenario 3: Docker Network

**Bridge network:**

```bash
docker network create --subnet=172.20.0.0/16 myapp

docker run -d --name web --network myapp nginx
docker run -d --name api --network myapp nodeapp
docker run -d --name db --network myapp postgres
```

**IPs assigned:**

```
Docker bridge:  172.20.0.1
web container:  172.20.0.2 (auto-assigned)
api container:  172.20.0.3 (auto-assigned)
db container:   172.20.0.4 (auto-assigned)
```

**How assignment works:**

```
Docker's internal DHCP-like system
First container gets .2
Second gets .3
And so on

Can also specify static:
docker run --ip 172.20.0.100 --name web ...
```

---

### Scenario 4: Office Network

**Large office:**

```
Network: 10.0.0.0/16

VLANs (separate networks):
├─ VLAN 10 (Management): 10.0.10.0/24
│  └─ Servers, switches (static IPs)
│
├─ VLAN 20 (Employee): 10.0.20.0/24
│  └─ Employee laptops (DHCP)
│
├─ VLAN 30 (Guest): 10.0.30.0/24
│  └─ Guest WiFi (DHCP, short lease)
│
└─ VLAN 40 (Printers): 10.0.40.0/24
   └─ Printers (DHCP reservation)
```

**DHCP configuration:**

```
VLAN 20 (Employee):
  Pool: 10.0.20.100 - 10.0.20.200
  Lease: 8 hours (work day)

VLAN 30 (Guest):
  Pool: 10.0.30.50 - 10.0.30.250
  Lease: 1 hour (high turnover)
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