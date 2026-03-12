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
[Complete Journey](../10-complete-journey/README.md)

---

# Network Segmentation (Subnets & CIDR)

## What this file is about

This file teaches **how to divide networks into smaller segments** and **how to read CIDR notation**. If you understand this, you'll be able to plan AWS VPCs, calculate how many IPs are available, and design networks that don't conflict. This is essential for cloud infrastructure work.

<!-- no toc -->
- [The Core Problem](#the-core-problem)
- [Why Subnets Exist](#why-subnets-exist)
- [Subnet Masks (The Divider)](#subnet-masks-the-divider)
- [CIDR Notation (The Shorthand)](#cidr-notation-the-shorthand)
- [Calculating Available IPs](#calculating-available-ips)
- [Common CIDR Blocks (Memorize These)](#common-cidr-blocks-memorize-these)
- [Subnet Planning Rules](#subnet-planning-rules)
- [Real AWS VPC Planning](#real-aws-vpc-planning)
- [Subnetting Practice](#subnetting-practice)  
[Final Compression](#final-compression)

---

## The Core Problem

### The Question

**Scenario:** You're setting up an AWS VPC for a company.

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
   Example: Database subnet isolated from web subnet

2. Organization
   Logical grouping of devices
   Example: One subnet per office floor

3. Performance
   Smaller broadcast domains
   Less traffic interference

4. Address Management
   Efficient use of IP space
   Can grow subnets independently
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
| 255.255.255.224 | 11111111.11111111.11111111.11100000 | 27 | 5 | 30 |

---

### How Devices Use Subnet Masks

**Your laptop's configuration:**

```
IP:   192.168.1.45
Mask: 255.255.255.0
```

**You want to reach 192.168.1.67:**

```
Step 1: Your laptop does bitwise AND operation
  
Your IP:        192.168.1.45
Mask:           255.255.255.0
AND result:     192.168.1.0    ← Your network

Target IP:      192.168.1.67
Mask:           255.255.255.0
AND result:     192.168.1.0    ← Target network

Step 2: Compare networks
  192.168.1.0 == 192.168.1.0 → SAME NETWORK

Step 3: Decision
  Send directly (use ARP, no router)
```

**You want to reach 192.168.2.50:**

```
Step 1: Bitwise AND

Your network:   192.168.1.0
Target network: 192.168.2.0

Step 2: Compare
  192.168.1.0 != 192.168.2.0 → DIFFERENT NETWORK

Step 3: Decision
  Send to default gateway (router needed)
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
| /29 | 255.255.255.248 | 29 | 3 |
| /30 | 255.255.255.252 | 30 | 2 |
| /32 | 255.255.255.255 | 32 | 0 |

---

### CIDR Block Examples

**Example 1: 10.0.0.0/16**

```
Network: 10.0.0.0
CIDR: /16

Meaning:
  First 16 bits = network (10.0)
  Last 16 bits = hosts (0.0 - 255.255)

Range:
  10.0.0.0 - 10.0.255.255

Total IPs: 2^16 = 65,536
Usable: 65,534 (minus network and broadcast)
```

**Example 2: 192.168.1.0/24**

```
Network: 192.168.1.0
CIDR: /24

Meaning:
  First 24 bits = network (192.168.1)
  Last 8 bits = hosts (0-255)

Range:
  192.168.1.0 - 192.168.1.255

Total IPs: 2^8 = 256
Usable: 254 (minus network and broadcast)
```

**Example 3: 172.16.0.0/12**

```
Network: 172.16.0.0
CIDR: /12

Meaning:
  First 12 bits = network
  Last 20 bits = hosts

Range:
  172.16.0.0 - 172.31.255.255

Total IPs: 2^20 = 1,048,576
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
  Class B too big (65,536) - Waste!
```

**CIDR system (modern):**

```
Need 500 IPs? Use /23 (512 IPs)
Need 1000 IPs? Use /22 (1024 IPs)
Need 2000 IPs? Use /21 (2048 IPs)

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
  Network address:   192.168.1.0   (first IP - reserved)
  First usable:      192.168.1.1
  Last usable:       192.168.1.62
  Broadcast address: 192.168.1.63  (last IP - reserved)
```

---

### Quick Reference Table

| CIDR | Host Bits | Total IPs | Usable IPs | Use Case |
|------|-----------|-----------|------------|----------|
| /32 | 0 | 1 | 1 | Single host (security group rule) |
| /31 | 1 | 2 | 2 | Point-to-point links |
| /30 | 2 | 4 | 2 | Point-to-point links |
| /29 | 3 | 8 | 6 | Very small subnet |
| /28 | 4 | 16 | 14 | Small subnet |
| /27 | 5 | 32 | 30 | Small subnet |
| /26 | 6 | 64 | 62 | Medium subnet |
| /25 | 7 | 128 | 126 | Medium subnet |
| /24 | 8 | 256 | 254 | Standard subnet |
| /23 | 9 | 512 | 510 | Medium-large subnet |
| /22 | 10 | 1,024 | 1,022 | Large subnet |
| /21 | 11 | 2,048 | 2,046 | Large subnet |
| /20 | 12 | 4,096 | 4,094 | Very large subnet |
| /16 | 16 | 65,536 | 65,534 | Large network (AWS VPC typical) |
| /8 | 24 | 16,777,216 | 16,777,214 | Massive network |

---

### Reserved Addresses

**In every subnet, two addresses are reserved:**

```
Example: 192.168.1.0/24

Network address:   192.168.1.0    (identifies the subnet)
  Cannot be assigned to a device
  Used in routing tables

Broadcast address: 192.168.1.255  (all hosts on subnet)
  Cannot be assigned to a device
  Used to send to everyone at once

Usable range:      192.168.1.1 - 192.168.1.254
```

---

### AWS Additional Reservations

**AWS reserves 5 IPs per subnet** (not just 2):

```
Example: 10.0.1.0/24 in AWS

Reserved by AWS:
  10.0.1.0   - Network address
  10.0.1.1   - VPC router
  10.0.1.2   - DNS server
  10.0.1.3   - Reserved for future use
  10.0.1.255 - Broadcast address

Usable by you:
  10.0.1.4 - 10.0.1.254 (251 IPs)
```

**Important:** AWS documentation says 256 - 5 = 251 usable (not 254).

---

## Common CIDR Blocks (Memorize These)

### The Essential Four

**You MUST memorize these for DevOps work:**

```
/32 = 1 IP (single host)
  Example: Security group rule for one specific IP
  "Allow SSH from 203.45.67.89/32"

/24 = 256 IPs (254 usable)
  Example: Standard subnet
  "Web server subnet: 10.0.1.0/24"

/16 = 65,536 IPs (65,534 usable)
  Example: Large VPC or network
  "VPC: 10.0.0.0/16"

/8 = 16.7 million IPs
  Example: Entire private IP range
  "Private range: 10.0.0.0/8"
```

---

### The Practical Ones for AWS

```
/28 = 16 IPs (14 usable, 11 in AWS)
  Use: Very small subnets (test environments)

/26 = 64 IPs (62 usable, 59 in AWS)
  Use: Small subnets

/24 = 256 IPs (254 usable, 251 in AWS)
  Use: Standard subnet (most common)

/23 = 512 IPs (510 usable, 507 in AWS)
  Use: Medium subnet

/22 = 1,024 IPs (1,022 usable, 1,019 in AWS)
  Use: Large subnet

/20 = 4,096 IPs (4,094 usable, 4,091 in AWS)
  Use: Very large subnet

/16 = 65,536 IPs
  Use: VPC CIDR (entire network space)
```

---

### Mental Shortcuts

**Powers of 2:**

```
/32 = 2^0  = 1
/31 = 2^1  = 2
/30 = 2^2  = 4
/29 = 2^3  = 8
/28 = 2^4  = 16
/27 = 2^5  = 32
/26 = 2^6  = 64
/25 = 2^7  = 128
/24 = 2^8  = 256      ← Memorize this
/23 = 2^9  = 512
/22 = 2^10 = 1,024
/21 = 2^11 = 2,048
/20 = 2^12 = 4,096
/16 = 2^16 = 65,536   ← Memorize this
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
                    No overlap ✓
```

---

### Rule 2: Plan for Growth

**Don't do this:**

```
Need 50 IPs → Use /26 (62 usable)
  Problem: If you grow to 70 IPs, you're stuck
```

**Do this instead:**

```
Need 50 IPs → Use /24 (254 usable)
  Room for growth: 254 - 50 = 204 IPs available
```

**Rule of thumb:** Allocate 2-3x what you need today.

---

### Rule 3: Use Consistent Sizing

**❌ Inconsistent (hard to manage):**

```
Web subnet:  10.0.1.0/26  (62 IPs)
App subnet:  10.0.2.0/24  (254 IPs)
DB subnet:   10.0.3.0/28  (14 IPs)
```

**✅ Consistent (easy to manage):**

```
Web subnet:  10.0.1.0/24  (254 IPs)
App subnet:  10.0.2.0/24  (254 IPs)
DB subnet:   10.0.3.0/24  (254 IPs)

Same size, predictable, simple
```

---

### Rule 4: Smaller CIDR = Bigger Network

**This confuses beginners:**

```
/24 = 256 IPs    (bigger subnet)
/26 = 64 IPs     (smaller subnet)
/28 = 16 IPs     (even smaller)

Lower number = MORE IPs
Higher number = FEWER IPs
```

**Why?**

```
/24 = 24 network bits, 8 host bits (2^8 = 256)
/28 = 28 network bits, 4 host bits (2^4 = 16)

More host bits = More IPs
```

---

### Rule 5: Leave Room Between Subnets

**For future expansion:**

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

## Real AWS VPC Planning

### Scenario: E-Commerce Application

**Requirements:**

```
Web servers:       Need 20 now, expect 50 eventually
App servers:       Need 40 now, expect 100 eventually
Databases:         Need 5 now, expect 10 eventually
Future expansion:  Leave room for 5 more tiers
```

---

### Step 1: Choose VPC CIDR

**Options:**

```
10.0.0.0/16   → 65,536 IPs (good)
10.0.0.0/20   → 4,096 IPs (tight)
10.0.0.0/8    → 16.7 million IPs (overkill)
```

**Decision: 10.0.0.0/16**

```
Reasoning:
- Gives 65,536 IPs total
- Room for many subnets
- Standard VPC size
- Easy to subdivide
```

---

### Step 2: Plan Subnet Sizes

**Calculate needs:**

```
Web servers:  50 IPs needed
  Use /24 (254 usable) ✓

App servers:  100 IPs needed
  Use /24 (254 usable) ✓

Databases:    10 IPs needed
  Use /24 (254 usable) ✓ (consistent sizing)
```

---

### Step 3: Assign CIDR Blocks

**Subnet allocation:**

```
VPC: 10.0.0.0/16

Public Subnet (Web):
  10.0.1.0/24
  Range: 10.0.1.0 - 10.0.1.255
  Usable: 10.0.1.4 - 10.0.1.254 (251 in AWS)

Private Subnet (App):
  10.0.2.0/24
  Range: 10.0.2.0 - 10.0.2.255
  Usable: 10.0.2.4 - 10.0.2.254 (251 in AWS)

Private Subnet (DB):
  10.0.3.0/24
  Range: 10.0.3.0 - 10.0.3.255
  Usable: 10.0.3.4 - 10.0.3.254 (251 in AWS)

Reserved for future:
  10.0.4.0/24 - 10.0.255.0/24
```

---

### Step 4: Multi-AZ Design

**For high availability, create subnets in multiple AZs:**

```
VPC: 10.0.0.0/16

Availability Zone A:
  Public:  10.0.1.0/24  (web servers)
  Private: 10.0.2.0/24  (app servers)
  Private: 10.0.3.0/24  (databases)

Availability Zone B:
  Public:  10.0.11.0/24  (web servers)
  Private: 10.0.12.0/24  (app servers)
  Private: 10.0.13.0/24  (databases)

Availability Zone C:
  Public:  10.0.21.0/24  (web servers)
  Private: 10.0.22.0/24  (app servers)
  Private: 10.0.23.0/24  (databases)
```

---

### Step 5: Terraform Example

```hcl
# VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  
  tags = {
    Name = "production-vpc"
  }
}

# Public subnet (web)
resource "aws_subnet" "public_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  
  tags = {
    Name = "public-subnet-a"
    Tier = "web"
  }
}

# Private subnet (app)
resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1a"
  
  tags = {
    Name = "private-subnet-a"
    Tier = "application"
  }
}

# Private subnet (database)
resource "aws_subnet" "database_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1a"
  
  tags = {
    Name = "database-subnet-a"
    Tier = "database"
  }
}
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
Acceptable:  /25 (tight fit)
```

---

### Exercise 3: Design VPC

**Requirement:**

```
Web tier:  20 servers
App tier:  50 servers
DB tier:   10 servers
3 Availability Zones
```

**Solution:**

```
VPC: 10.0.0.0/16

AZ1 (us-east-1a):
  Web:  10.0.1.0/24
  App:  10.0.2.0/24
  DB:   10.0.3.0/24

AZ2 (us-east-1b):
  Web:  10.0.11.0/24
  App:  10.0.12.0/24
  DB:   10.0.13.0/24

AZ3 (us-east-1c):
  Web:  10.0.21.0/24
  App:  10.0.22.0/24
  DB:   10.0.23.0/24

Total used: 9 x 256 = 2,304 IPs
Available:  65,536 - 2,304 = 63,232 IPs remaining
```

---

### Exercise 4: Identify Conflicts

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
/16 = 65,536 IPs (large network/VPC)
/8  = 16.7M IPs  (entire private range)
```

---

### Quick CIDR Reference

| CIDR | Total IPs | Usable IPs | AWS Usable |
|------|-----------|------------|------------|
| /28 | 16 | 14 | 11 |
| /26 | 64 | 62 | 59 |
| /24 | 256 | 254 | 251 |
| /23 | 512 | 510 | 507 |
| /22 | 1,024 | 1,022 | 1,019 |
| /20 | 4,096 | 4,094 | 4,091 |
| /16 | 65,536 | 65,534 | 65,531 |

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

### AWS VPC Pattern

```
VPC: 10.0.0.0/16 (standard)

Subnet pattern:
  10.0.1.0/24  → Public subnet AZ1
  10.0.2.0/24  → Private subnet AZ1
  10.0.11.0/24 → Public subnet AZ2
  10.0.12.0/24 → Private subnet AZ2

Leaves: 10.0.20.0 - 10.0.255.0 for future
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
  
Result:
  Multiple isolated networks
  Better security
  Easier management
```

---

### What You Can Do Now

✅ Calculate IPs from CIDR (/24 = 256 IPs)  
✅ Design AWS VPC with proper subnets  
✅ Avoid subnet overlap conflicts  
✅ Choose appropriate subnet sizes  
✅ Understand subnet masks  
✅ Plan for growth and future expansion  

---