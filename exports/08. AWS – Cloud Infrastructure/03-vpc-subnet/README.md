[Home](../README.md) |
[Intro](../01-intro-aws/README.md) |
[IAM](../02-iam/README.md) |
[VPC](../03-vpc-subnet/README.md) |
[EBS](../04-ebs/README.md) |
[S3](../05-s3/README.md) |
[EC2](../06-ec2/README.md) |
[RDS](../07-rds/README.md) |
[Load Balancing](../08-load-balancing-auto-scaling/README.md) |
[CloudWatch](../09-cloudwatch-sns/README.md) |
[Route 53](../10-route53/README.md) |
[CLI](../11-cli-cloudformation/README.md) |
[EKS](../12-eks/README.md)

---

# AWS VPC & Subnets

## What This File Is About

IAM decided **who** gets access. VPC decides **where** that access works — your private, isolated network inside AWS. This file covers how to design a VPC from scratch, plan subnets correctly, route traffic between tiers, and secure every layer with Security Groups and NACLs. By the end you will be able to design a production-ready multi-tier AWS network and understand exactly what happens at every hop inside it.

**Foundation:** The networking concepts behind everything here — IP addressing, CIDR math, NAT (Network Address Translation), stateful vs stateless firewalls — are covered in depth in the [Networking Fundamentals](../../03.%20Networking%20–%20Foundations/README.md) folder. Specifically:
- Subnets and CIDR: [05 — Subnets & CIDR](../../03.%20Networking%20–%20Foundations/05-subnets-cidr/README.md)
- NAT concept: [07 — NAT & Translation](../../03.%20Networking%20–%20Foundations/07-nat/README.md)
- Stateful vs Stateless firewalls: [09 — Firewalls & Security](../../03.%20Networking%20–%20Foundations/09-firewalls/README.md)

---

## Table of Contents

1. [Why VPC Exists](#1-why-vpc-exists)
2. [What Is a VPC](#2-what-is-a-vpc)
3. [CIDR and IP Address Ranges](#3-cidr-and-ip-address-ranges)
4. [Subnets and Availability Zones](#4-subnets-and-availability-zones)
5. [Routing, IGW and NAT Gateway](#5-routing-igw-and-nat-gateway)
6. [Security Groups vs NACLs](#6-security-groups-vs-nacls)
7. [The NACL Trap — The Most Common Beginner Mistake](#7-the-nacl-trap--the-most-common-beginner-mistake)
8. [IP Concepts — Private, Public, Elastic, ENI](#8-ip-concepts--private-public-elastic-eni)
9. [VPC Subnet Design — Webstore on AWS](#9-vpc-subnet-design--webstore-on-aws)
10. [Architecture Blueprint](#10-architecture-blueprint)

---

## 1. Why VPC Exists

Before the cloud, every company had a physical server room — racks, cables, routers, and switches all wired together manually. Expanding meant buying hardware, finding rack space, and rewiring everything.

AWS virtualizes that entire setup. Instead of physical cables and switches, you define your network in software. That virtual network is your VPC.

Think of AWS as a massive city of skyscrapers — one per account. Your VPC is your private building inside that city. You control everything about it:

- Which floors face the street (public subnets)
- Which floors are internal only (private subnets)
- How the hallways connect floors (route tables)
- Who has keys to each room (security groups)
- Which entrance faces the street (internet gateway)

Without a VPC, every AWS resource would float in the open city with no walls or doors. VPC gives you **boundaries, privacy, and structure**.

```
AWS City (many accounts)
└── Your Account
    └── Your VPC = Your Private Building
        ├── Internet Gateway    = Main entrance to the street
        ├── Public Subnet       = Street-facing floors (web servers)
        ├── Private Subnet      = Internal floors (databases, app servers)
        ├── Route Tables        = Hallways connecting floors
        ├── Security Groups     = Door locks on individual rooms
        └── NACLs               = Security gates at each floor entrance
```

---

## 2. What Is a VPC

A **Virtual Private Cloud (VPC)** is an isolated network you own inside AWS. Every resource you launch — EC2, RDS, Lambda — lives inside a VPC.

**Key components:**

| Component | Purpose | Example |
|---|---|---|
| **VPC** | The network boundary | `10.0.0.0/16` |
| **Subnet** | Sub-division of the VPC | `10.0.1.0/24` |
| **Route Table** | Defines where traffic goes | Route to IGW or NAT |
| **Internet Gateway (IGW)** | Public internet access | Web tier in public subnet |
| **NAT Gateway** | Private → Internet (outbound only) | OS updates from private EC2 |
| **Security Group** | Instance-level stateful firewall | Allow HTTP, SSH |
| **NACL** | Subnet-level stateless firewall | Allow/Deny by CIDR and port |

**Default VPC vs Custom VPC:**

When you create an AWS account, AWS gives you a Default VPC in every region — pre-built with public subnets and an IGW. It works immediately but is not production-safe because everything lands in public subnets by default.

For any real workload you create a **Custom VPC** — every subnet, route, and firewall rule is intentionally designed.

```
┌────────────────────────── AWS Region ──────────────────────────────┐
│                                                                    │
│  ┌─────────────────────── VPC (10.0.0.0/16) ──────────────────┐    │
│  │                                                            │    │
│  │  Public Subnet (10.0.1.0/24)   Private Subnet (10.0.2.0/24)│    │
│  │  ┌──────────────────────┐      ┌──────────────────────┐    │    │
│  │  │  EC2 Web Server      │      │  RDS Database        │    │    │
│  │  │  Route → IGW         │      │  Route → NAT         │    │    │
│  │  └──────────────────────┘      └──────────────────────┘    │    │
│  │                                                            │    │
│  │  IGW ↔ Internet                NAT Gateway (in public)     │    │
│  └────────────────────────────────────────────────────────────┘    │
└────────────────────────────────────────────────────────────────────┘
```

---

## 3. CIDR and IP Address Ranges

Before you build subnets, you choose how much IP space your VPC owns. That range is defined using **CIDR (Classless Inter-Domain Routing)** notation.

A CIDR block like `10.0.0.0/16` means:
- `10.0.0.0` is the starting address
- `/16` means the first 16 bits are the network portion — everything after is yours to assign

**The formula:**
```
Total IPs = 2^(32 - prefix)

10.0.0.0/16  →  2^16 = 65,536 IPs
10.0.1.0/24  →  2^8  =    256 IPs
10.0.3.0/28  →  2^4  =     16 IPs
```

**AWS reserves 5 IPs per subnet** (network address, VPC router, DNS, future use, broadcast). Always subtract 5 from your total.

**Quick reference table:**

| CIDR | Total IPs | Usable in AWS | Common use |
|---|---|---|---|
| **/16** | 65,536 | 65,531 | Entire VPC CIDR |
| **/20** | 4,096 | 4,091 | Large subnet |
| **/24** | 256 | 251 | Standard subnet (most common) |
| **/26** | 64 | 59 | Small subnet |
| **/28** | 16 | 11 | Minimum AWS size |

**The Rule:** AWS only allows VPC CIDRs between `/16` (largest) and `/28` (smallest). Anything outside that range is rejected.

**Private IP ranges** (memorize these — they cannot route on the internet):
```
10.0.0.0/8         → Large networks (standard for AWS VPCs)
172.16.0.0/12      → Medium networks
192.168.0.0/16     → Home/small office
```

Always use private ranges for VPC CIDRs. Public IP ranges in a VPC cause routing conflicts.

**Avoiding overlap:**
If you ever connect two VPCs (VPC Peering) or connect to an on-premises network, their CIDR ranges must not overlap. This is why planning matters upfront.

```
Bad — overlap:
VPC A: 10.0.0.0/16  (10.0.0.0 - 10.0.255.255)
VPC B: 10.0.1.0/24  (10.0.1.0 - 10.0.1.255)  ← inside VPC A's range

Good — no overlap:
VPC A: 10.0.0.0/16  (10.0.0.0 - 10.0.255.255)
VPC B: 10.1.0.0/16  (10.1.0.0 - 10.1.255.255)
```

---

## 4. Subnets and Availability Zones

A **subnet** is a slice of your VPC CIDR assigned to one Availability Zone. Every resource you launch lives in a specific subnet — and therefore in a specific AZ.

**Public vs Private:**

| Type | Has route to IGW? | Has public IP? | Use for |
|---|---|---|---|
| **Public subnet** | Yes | Yes | Web servers, load balancers, bastion hosts |
| **Private subnet** | No | No | Databases, app servers, internal services |

**The HA Rule:** For high availability, always create subnets across multiple AZs. If one AZ fails, your resources in other AZs keep running.

```
VPC: 10.0.0.0/16

AZ us-east-1a:
  Public subnet:   10.0.1.0/24
  Private subnet:  10.0.2.0/24

AZ us-east-1b:
  Public subnet:   10.0.11.0/24
  Private subnet:  10.0.12.0/24
```

**What makes a subnet public?**
A subnet becomes public when its route table has a route pointing `0.0.0.0/0` to an Internet Gateway. Without that route, even if an EC2 instance has a public IP, it cannot reach the internet — the route table is the gate, not the IP.

**What makes a subnet private?**
No route to IGW. Outbound internet access goes through a NAT Gateway instead. Inbound from the internet is impossible — by design.

**Subnet sizing guidance:**
```
Web tier (public):    /24 — room for load balancers, bastion hosts
App tier (private):   /24 — room for multiple app servers
DB tier (private):    /24 — consistent sizing keeps things simple
```

Always size larger than you think you need. You cannot resize a subnet after creation — you would have to create a new one.

---

## 5. Routing, IGW and NAT Gateway

Every subnet is associated with a **route table** — a set of rules that tell AWS where to send traffic based on destination IP.

**How routing decisions work:**
```
Packet destination: 8.8.8.8

Route table lookup (most specific match wins):
  10.0.0.0/16  →  local        (matches? No — 8.8.8.8 not in VPC range)
  0.0.0.0/0    →  igw-xxxxx    (matches everything else → send to IGW)

Decision: Forward to Internet Gateway
```

**Standard route tables:**

Public subnet route table:
```
Destination     Target
10.0.0.0/16     local         ← VPC-internal traffic stays inside
0.0.0.0/0       igw-xxxxx     ← everything else goes to internet
```

Private subnet route table:
```
Destination     Target
10.0.0.0/16     local         ← VPC-internal traffic stays inside
0.0.0.0/0       nat-xxxxx     ← outbound internet via NAT Gateway
```

---

### Internet Gateway (IGW)

An IGW connects your VPC to the internet. It handles both inbound and outbound traffic for public subnets.

| Property | Value |
|---|---|
| Scope | One per VPC |
| Direction | Bidirectional (inbound and outbound) |
| Cost | Free |
| Requirement | Must be attached to VPC and referenced in route table |

Without an IGW attached and routed, no instance in the VPC can reach the internet — regardless of what Security Group rules say.

---

### NAT Gateway

A NAT (Network Address Translation) Gateway lets instances in **private subnets** make outbound internet connections (downloading packages, calling external APIs) while remaining completely unreachable from the internet inbound.

**How it works:**
```
Private EC2 (10.0.2.50) wants to reach apt.ubuntu.com

1. EC2 sends packet — source IP: 10.0.2.50
2. Route table: 0.0.0.0/0 → NAT Gateway
3. NAT Gateway translates:
     Old source: 10.0.2.50 (private)
     New source: 52.10.20.30 (NAT Gateway's Elastic IP)
4. Packet leaves via IGW to internet
5. Response returns to NAT Gateway
6. NAT translates back to 10.0.2.50
7. Private EC2 receives response

The internet only ever saw 52.10.20.30 — never the private IP
```

| Property | Value |
|---|---|
| Location | Must live in a public subnet |
| Direction | Outbound only — no inbound connections possible |
| Cost | Charged per hour + per GB processed |
| HA requirement | Create one NAT Gateway per AZ |
| Requires | An Elastic IP address |

**The HA pattern:**
```
AZ-a: Private subnet → NAT Gateway in Public subnet AZ-a
AZ-b: Private subnet → NAT Gateway in Public subnet AZ-b
```

One NAT Gateway per AZ. If you use a single NAT Gateway and that AZ goes down, all private instances in every AZ lose internet access.

**NAT Gateway vs NAT Instance:**

| Feature | NAT Gateway | NAT Instance (legacy) |
|---|---|---|
| Managed by | AWS | You |
| Availability | Highly available within AZ | You manage failover |
| Bandwidth | Up to 45 Gbps | Limited by instance type |
| Cost | Higher | Lower (EC2 cost only) |
| Recommendation | Always use this | Legacy — avoid |

---

## 6. Security Groups vs NACLs

AWS gives you two layers of network security. Understanding the difference between them is one of the most important concepts in AWS networking.

**The key difference in one line:**
Security Groups are stateful (remember connections). NACLs are stateless (evaluate every packet independently).

---

### Security Groups

A Security Group is a **stateful firewall** attached to an individual EC2 instance, RDS instance, or load balancer.

**Stateful means:** if an inbound rule allows a connection in, the return traffic is automatically allowed out — even with no outbound rule. The Security Group remembers the connection.

| Property | Value |
|---|---|
| Level | Instance (ENI) |
| Statefulness | Stateful — return traffic auto-allowed |
| Rule types | Allow only — cannot create Deny rules |
| Default inbound | Deny all |
| Default outbound | Allow all |
| Changes | Apply immediately |

**Webstore web server Security Group:**

| Direction | Protocol | Port | Source | Purpose |
|---|---|---|---|---|
| Inbound | TCP | 80 | 0.0.0.0/0 | HTTP from internet |
| Inbound | TCP | 443 | 0.0.0.0/0 | HTTPS from internet |
| Inbound | TCP | 22 | 203.0.113.0/24 | SSH from office only |
| Outbound | All | All | 0.0.0.0/0 | Allow all outbound |

**Referencing Security Groups:**
Instead of using IP ranges, you can reference another Security Group as the source. This is the production pattern for multi-tier apps:

```
Database Security Group inbound rule:
  Allow TCP 5432 from [App Server Security Group ID]

This means: only instances wearing the App Server SG badge
can reach the database — regardless of their IP address.
If you scale to 100 app servers, no rule change needed.
```

---

### Network ACLs (NACLs)

A NACL is a **stateless firewall** at the subnet boundary. Every packet — inbound and outbound — is evaluated independently against the rules. No memory of connections.

| Property | Value |
|---|---|
| Level | Subnet |
| Statefulness | Stateless — every packet evaluated independently |
| Rule types | Allow and Deny |
| Rule evaluation | Lowest rule number first — first match wins |
| Default | Allow all inbound and outbound |
| Changes | Apply immediately |

**Public subnet NACL (correct configuration):**

Inbound rules:
| Rule # | Protocol | Port | Source | Action |
|---|---|---|---|---|
| 100 | TCP | 80 | 0.0.0.0/0 | ALLOW |
| 110 | TCP | 443 | 0.0.0.0/0 | ALLOW |
| 120 | TCP | 1024-65535 | 0.0.0.0/0 | ALLOW ← critical |
| * | All | All | 0.0.0.0/0 | DENY |

Outbound rules:
| Rule # | Protocol | Port | Destination | Action |
|---|---|---|---|---|
| 100 | TCP | 80 | 0.0.0.0/0 | ALLOW |
| 110 | TCP | 443 | 0.0.0.0/0 | ALLOW |
| 120 | TCP | 1024-65535 | 0.0.0.0/0 | ALLOW ← critical |
| * | All | All | 0.0.0.0/0 | DENY |

---

### Side-by-Side Comparison

| Feature | Security Group | NACL |
|---|---|---|
| Level | Instance | Subnet |
| Stateful? | Yes | No |
| Allow rules | Yes | Yes |
| Deny rules | No | Yes |
| Default inbound | Deny all | Allow all |
| Rule evaluation | All rules checked | Lowest number first |
| Return traffic | Auto-allowed | Must be explicitly allowed |
| Best for | Primary security control | Subnet-level defense layer |

**The Recommendation:** Use Security Groups for all primary access control — they are stateful and easier to manage. Add NACLs only when you need explicit Deny rules or a subnet-level defense layer.

---

## 7. The NACL Trap — The Most Common Beginner Mistake

This single misconfiguration causes more AWS networking failures than anything else. Read this carefully.

**The Setup:**
You create a custom NACL to secure your public subnet. You add what looks like correct rules:

```
Inbound:
  100  TCP  80   0.0.0.0/0  ALLOW
  110  TCP  443  0.0.0.0/0  ALLOW
  *    All  All  0.0.0.0/0  DENY

Outbound:
  100  TCP  80   0.0.0.0/0  ALLOW
  110  TCP  443  0.0.0.0/0  ALLOW
  *    All  All  0.0.0.0/0  DENY
```

Looks complete. Allows HTTP and HTTPS both ways. But your website does not load.

**What actually happens:**

```
User (123.45.67.89:54321) → Your server (:80)

NACL Inbound check:
  Rule 100: TCP port 80 from anywhere → ALLOW
  Packet enters subnet, reaches EC2

Server processes request

Server (:80) → User (123.45.67.89:54321)
  The response goes to port 54321 — the user's ephemeral port

NACL Outbound check:
  Rule 100: TCP port 80 → not a match (destination port is 54321)
  Rule 110: TCP port 443 → not a match
  Rule *: DENY

Response is dropped. User sees timeout.
```

**Why this happens:**
When a user connects to your server on port 80, their browser picks a random **ephemeral port** (between 1024-65535) as the source port. The server's response goes back to that ephemeral port. Your NACL has no outbound rule allowing traffic to ports 1024-65535 — so the response is silently dropped.

Security Groups never have this problem because they are stateful — they remember the inbound connection and automatically allow the response.

**The Fix:**

```
Outbound rules (add this):
  120  TCP  1024-65535  0.0.0.0/0  ALLOW  ← allows all response traffic

Inbound rules (add this too for outbound-initiated responses):
  120  TCP  1024-65535  0.0.0.0/0  ALLOW  ← allows return traffic for outbound requests
```

**The Rule:** Every NACL that allows inbound traffic on a port must also allow outbound traffic on the ephemeral port range (1024-65535). And vice versa. Both directions. Always.

**Why this confuses people:**
Security Groups teach you to only think about inbound rules — return traffic is automatic. NACLs are the opposite. The mental model that works for Security Groups breaks completely when applied to NACLs.

**Best practice:**
Most teams leave NACLs at the default (allow all) and use Security Groups for all access control. Only add custom NACLs when you specifically need Deny rules — and when you do, always include the ephemeral port range in both directions.

---

## 8. IP Concepts — Private, Public, Elastic, ENI

Every EC2 instance in your VPC gets network addresses. Understanding which type does what prevents a lot of confusion.

---

### Private IP

Assigned automatically when an instance launches. Used for all communication within the VPC — EC2 to EC2, EC2 to RDS, EC2 to internal load balancers.

```
Properties:
  Free
  Stays the same when instance stops and starts
  Released permanently when instance is terminated
  Not reachable from the internet
  Cannot route on the public internet
```

---

### Public IP

Assigned automatically to instances in public subnets (if the subnet is configured to auto-assign). Allows direct communication with the internet via IGW.

```
Properties:
  Automatically assigned — no action needed
  Included in Free Tier (750 hrs/month)
  Changes every time the instance stops and starts
  Lost permanently when instance is terminated
```

This is the problem with Public IPs — they change. If your DNS record points to `3.120.55.23` and the instance restarts, it gets a new IP and your DNS breaks.

---

### Elastic IP

A static public IPv4 address that you allocate to your account. It stays the same forever until you release it.

```
Properties:
  Permanent — survives stop/start/restart
  Can be moved between instances (failover)
  Free while attached to a running instance
  Billed when allocated but not attached (idle charge)
```

**When to use Elastic IP:**
- Production servers that need a consistent public IP
- Failover setups where you move the IP from a failed instance to a healthy one
- When your DNS or firewall rules reference a specific IP

**The idle billing trap:** If you allocate an Elastic IP and then stop the instance or detach the IP, AWS charges you for it. Always release Elastic IPs you are not using.

---

### ENI (Elastic Network Interface)

A virtual network card. Every instance gets one primary ENI automatically. It holds the instance's private IP, public IP, MAC address, and Security Group associations.

You can create additional ENIs and attach them to instances — useful for network separation, management interfaces, or failover.

---

### Comparison

| Type | Persists on restart? | Internet reachable? | Cost |
|---|---|---|---|
| Private IP | Yes | No | Free |
| Public IP | No — changes | Yes | Free (750 hrs/mo) |
| Elastic IP | Yes | Yes | Free if attached, billed if idle |
| ENI | N/A | Depends | Free |

---

## 9. VPC Subnet Design — Webstore on AWS

This is how you translate the webstore requirements into a real VPC design. Work through this before touching the console.

**Requirements:**
```
Application: webstore (frontend + api + database)
Region: us-east-1
Availability Zones: 2 (for high availability)
Tiers: web (public), api (private), database (private)
Expected growth: 3x current size
```

**Step 1 — Choose VPC CIDR**

Use `10.0.0.0/16` — 65,536 IPs. Plenty of room for all subnets across multiple AZs with room for future expansion.

**Step 2 — Calculate subnet sizes**

```
Web tier:      ~20 instances now, ~60 eventually → /24 (251 usable)
API tier:      ~40 instances now, ~120 eventually → /24 (251 usable)
Database tier: ~5 instances now, ~15 eventually   → /24 (251 usable)

Consistent /24 sizing — simple to manage, no mental math needed
```

**Step 3 — Assign non-overlapping CIDRs**

```
VPC: 10.0.0.0/16

AZ us-east-1a:
  webstore-web-1a:  10.0.1.0/24   (public)
  webstore-api-1a:  10.0.2.0/24   (private)
  webstore-db-1a:   10.0.3.0/24   (private)

AZ us-east-1b:
  webstore-web-1b:  10.0.11.0/24  (public)
  webstore-api-1b:  10.0.12.0/24  (private)
  webstore-db-1b:   10.0.13.0/24  (private)

Reserved for future:
  10.0.20.0 - 10.0.255.0  (available)
```

**Step 4 — Define routing**

```
Public subnets (web-1a, web-1b):
  Route table: 0.0.0.0/0 → igw-xxxxx

Private subnets (api, db):
  Route table: 0.0.0.0/0 → nat-xxxxx
  (one NAT Gateway per AZ for HA)
```

**Step 5 — Define Security Groups**

```
webstore-alb-sg:
  Inbound:  443 from 0.0.0.0/0
  Inbound:  80 from 0.0.0.0/0
  Outbound: All

webstore-api-sg:
  Inbound:  8080 from webstore-alb-sg  ← reference SG, not IP
  Outbound: All

webstore-db-sg:
  Inbound:  5432 from webstore-api-sg  ← only api tier can reach db
  Outbound: All
```

**Step 6 — Verify no overlaps**

```
10.0.1.0/24   → 10.0.1.0  - 10.0.1.255
10.0.2.0/24   → 10.0.2.0  - 10.0.2.255
10.0.3.0/24   → 10.0.3.0  - 10.0.3.255
10.0.11.0/24  → 10.0.11.0 - 10.0.11.255
10.0.12.0/24  → 10.0.12.0 - 10.0.12.255
10.0.13.0/24  → 10.0.13.0 - 10.0.13.255

No overlaps.
```

**Terraform snippet:**

```hcl
resource "aws_vpc" "webstore" {
  cidr_block = "10.0.0.0/16"
  tags = { Name = "webstore-vpc" }
}

resource "aws_subnet" "web_1a" {
  vpc_id            = aws_vpc.webstore.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
  tags = { Name = "webstore-web-1a", Tier = "web" }
}

resource "aws_subnet" "api_1a" {
  vpc_id            = aws_vpc.webstore.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1a"
  tags = { Name = "webstore-api-1a", Tier = "api" }
}

resource "aws_subnet" "db_1a" {
  vpc_id            = aws_vpc.webstore.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1a"
  tags = { Name = "webstore-db-1a", Tier = "database" }
}
```

---

## 10. Architecture Blueprint

**Webstore production VPC — full picture:**

```
┌──────────────────────────────── AWS Region (us-east-1) ────────────────────────────────────┐
│                                                                                            │
│  ┌─────────────────────────────── VPC: 10.0.0.0/16 ──────────────────────────────────┐     │
│  │                                                                                   │     │
│  │  AZ: us-east-1a                          AZ: us-east-1b                           │     │
│  │                                                                                   │     │
│  │  ┌─── Public (10.0.1.0/24) ────┐        ┌─── Public (10.0.11.0/24) ───┐           │     │
│  │  │  ALB (webstore-alb-sg)      │        │  ALB (webstore-alb-sg)      │           │     │
│  │  │  NAT Gateway                │        │  NAT Gateway                │           │     │
│  │  │  Route: 0.0.0.0/0 → IGW     │        │  Route: 0.0.0.0/0 → IGW     │           │     │
│  │  └─────────────────────────────┘        └─────────────────────────────┘           │     │
│  │                                                                                   │     │
│  │  ┌─── Private (10.0.2.0/24) ───┐        ┌─── Private (10.0.12.0/24) ──┐           │     │
│  │  │  webstore-api EC2           │        │  webstore-api EC2           │           │     │
│  │  │  SG: allow 8080 from ALB SG │        │  SG: allow 8080 from ALB SG │           │     │
│  │  │  Route: 0.0.0.0/0 → NAT     │        │  Route: 0.0.0.0/0 → NAT     │           │     │
│  │  └─────────────────────────────┘        └─────────────────────────────┘           │     │
│  │                                                                                   │     │
│  │  ┌─── Private (10.0.3.0/24) ───┐        ┌─── Private (10.0.13.0/24) ──┐           │     │
│  │  │  webstore-db (RDS postgres) │        │  webstore-db (RDS standby)  │           │     │
│  │  │  SG: allow 5432 from        │        │  SG: allow 5432 from        │           │     │
│  │  │      api SG only            │        │      api SG only            │           │     │
│  │  │  No public IP               │        │  No public IP               │           │     │
│  │  └─────────────────────────────┘        └─────────────────────────────┘           │     │
│  │                                                                                   │     │
│  │  Internet Gateway                                                                 │     │
│  └───────────────────────────────────────────────────────────────────────────────────┘     │
│                                                                                            │
└────────────────────────────────────────────────────────────────────────────────────────────┘

Traffic flow:
  Internet → IGW → ALB (public subnet) → webstore-api (private) → webstore-db (private)
  Private EC2 → NAT Gateway → IGW → Internet (outbound only)
  webstore-db: zero inbound from internet — only reachable from api SG
```

**Security summary:**

| Layer | Tool | What it protects |
|---|---|---|
| VPC boundary | CIDR + IGW | Only traffic through IGW reaches the VPC |
| Subnet boundary | NACLs | Subnet-level allow/deny (leave at default unless specific need) |
| Instance boundary | Security Groups | Per-resource stateful firewall — primary security control |
| Database isolation | SG referencing | Only api tier SG can reach db — no IP-based rules needed |

---

## What You Can Do After This

- Design a multi-tier VPC from scratch — subnets, routing, security groups, NACLs
- Calculate CIDR blocks and verify no overlaps between subnets
- Explain the difference between IGW and NAT Gateway and when each is used
- Write Security Group rules that reference other Security Groups
- Explain exactly why the NACL ephemeral port trap breaks connections
- Design the webstore production VPC with six subnets across two AZs

---

## What Comes Next

→ [04. EBS](../04-ebs/README.md)

The network is designed. Now your EC2 instances need somewhere to store data — EBS (Elastic Block Store) is the persistent block storage that attaches to instances and survives stop/start cycles.
