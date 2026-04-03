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
[Complete Journey](../10-complete-journey/README.md)

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
