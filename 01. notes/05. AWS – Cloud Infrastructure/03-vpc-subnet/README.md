[🏠 Home](../README.md) | 
[Intro to AWS](../01-intro-aws/README.md) | 
[IAM](../02-iam/README.md) | 
[VPC & Subnet](../03-vpc-subnet/README.md) | 
[EBS](../04-ebs/README.md) | 
[EFS](../05-efs/README.md) | 
[S3](../06-s3/README.md) | 
[EC2](../07-ec2/README.md) | 
[RDS](../08-rds/README.md) | 
[Load Balancing & Auto Scaling](../09-Load-balancing-auto-scaling/README.md) | 
[CloudWatch & SNS](../10-cloudwatch-sns/README.md) | 
[Lambda](../11-lambda/README.md) | 
[Elastic Beanstalk](../12-elastic-beanstalk/README.md) | 
[Route 53](../13-route53/README.md) | 
[CLI + CloudFormation](../14-cli-cloudformation/README.md)

# AWS VPC & Subnets 

> IAM decides **who** gets the keys — defining users, roles, and permissions.  
> **VPC decides _where_ those keys work** — your private building inside the vast AWS city.  
>  
> In this city, every customer owns their own high-security building (VPC).  
> You design its layout: the rooms (subnets), doors (gateways), guards (security groups), and pathways (route tables).  
> It’s your isolated environment — fully customizable, secure, and connected only where you allow it.


## Table of Contents
1. [Why We Need a Network Layer](#1-why-we-need-a-network-layer)  
2. [What Is a VPC?](#2-what-is-a-vpc)  
3. [CIDR and IP Address Ranges](#3-cidr-and-ip-address-ranges)  
4. [Subnets and Availability Zones](#4-subnets-and-availability-zones)  
5. [Routing, IGW & NAT Gateway](#5-routing-igw--nat-gateway)  
6. [Security Groups vs NACLs](#6-security-groups-vs-nacls)  
7. [IP Concepts – Private, Public, Elastic, ENI](#7-ip-concepts--private-public-elastic-eni)  
8. [Networking Foundations (DNS, TCP, OSI)](#8-networking-foundations-dns-tcp-osi)  
9. [Architecture Blueprint (End-to-End VPC Design)](#9-architecture-blueprint-end-to-end-vpc-design)  

---

<details>
<summary><strong>1. Why We Need a Network Layer</strong></summary>

Before the cloud, every company had its own physical space — a **server room full of blinking racks**, **tangled cables**, and **heavy routers** stacked like Lego blocks.  
Each application lived there, connected through actual wires. Expanding meant buying new machines, finding space, and rewiring everything.

Then came **AWS**, offering the same setup — but without the metal and cables.  
Now you build that whole network **virtually**.  
No electricians, no switches, no walls — just diagrams and clicks.  
That virtual space you design is your **VPC (Virtual Private Cloud)**.

Think of AWS as a huge city filled with skyscrapers (accounts).  
Inside that city, **your VPC is a private building** — fully yours.  
You decide:
- Who gets the keys to the building (**security**).
- Which rooms face the street (**public subnets**).
- Which stay locked inside (**private subnets**).
- How the hallways connect rooms (**route tables**).

Without a VPC, every AWS resource would just float around the city with no walls or doors — anyone could walk anywhere.  
**VPC gives you boundaries, privacy, and structure** — your own secure floor plan inside the AWS city.

```
AWS City (many accounts)
└── Your Account (one skyscraper among many)
    └── Your VPC = Your Private Building
        ├── Security = Keys & Guards at doors (IAM/Security Groups/NACLs)
        ├── Route Tables = Hallways deciding which room reaches which
        ├── Internet Gateway = Main entrance to the street (Internet)
        ├── Public Subnet = Street-facing rooms (web/bastion)
        │     └─ EC2/Web Server (has public + private IP)
        └── Private Subnet = Internal rooms (DB/app)
              └─ RDS/EC2 App (private IP only; no direct street access)
```

Traffic flow examples:
Internet User → Main Entrance (IGW) → Lobby → Public Room (Web)
Public Room (Web) → Hallway (Route) → Private Room (DB)  [internal only]

```
┌────────────────────────────────────┐
│             AWS  city              │
│   ┌────────────────────────────┐   │
│   │  Your Private skyscrapers  │   │
│   │     (VPC 10.0.0.0/16)      │   │
│   └────────────────────────────┘   │
└────────────────────────────────────┘
```
</details>

---

<details>
<summary><strong>2. What Is a VPC</strong></summary>

---

A **Virtual Private Cloud (VPC)** is your **private building inside the AWS city** — an isolated network space where you decide how things are connected, protected, and accessed.  

Within this building, every floor, door, and hallway is something you control:
- **Subnets** → logical rooms or floors where specific workloads live.  
- **Route Tables** → pathways that decide how traffic moves between rooms.  
- **Internet Gateway (IGW)** → the main door to the public Internet.  
- **NAT Gateway** → a controlled backdoor for private systems to go out safely.  
- **Security Groups & NACLs** → firewalls at different levels — instance and subnet.  

When you first create an AWS account, you get a **Default VPC** (like a pre-built office).  
But professionals usually build **Custom VPCs** — so every range, subnet, and firewall rule is cleanly designed, traceable, and secure.

---

| Component | Purpose | Example |
|------------|----------|----------|
| **VPC** | Network boundary | `10.0.0.0/16` |
| **Subnet** | Sub-division of VPC | `10.0.1.0/24` |
| **Route Table** | Defines traffic paths | Route to IGW / NAT |
| **Internet Gateway (IGW)** | Public Internet access | Web tier in public subnet |
| **NAT Gateway** | Private → Internet (egress) | OS updates from private EC2 |
| **Security Group (SG)** | Instance-level firewall (stateful) | Allow HTTP / SSH |
| **NACL** | Subnet-level firewall (stateless) | Allow / Deny by CIDR / port |

---

### Putting it all together

Now that you know each piece, imagine walking through your AWS building:

- The **VPC** is the building itself — walls define your limits.  
- **Subnets** divide floors by purpose (e.g., web on one, database on another).  
- **Route Tables** define how people and packets move between floors.  
- **IGW** is your public entrance.  
- **NAT Gateway** is your safe exit for internal teams.  
- **Security Groups** protect each server, while **NACLs** secure entire floors.  

---

### 📘 Architecture Overview (Diagram)

```

┌─────────────────────────── AWS Region ────────────────────────────────────────┐
│                                                                               │
│  ┌───────────────────────── VPC (10.0.0.0/16) ─────────────────────────────┐  │
│  │                                                                         │  │
│  │  ┌──────────────────── Public Subnet (10.0.1.0/24) ──────────────────┐  │  │
│  │  │  ↳ NACL: Subnet-level firewall (stateless)                        │  │  │
│  │  │      • Inbound: Allow 80,443,22                                   │  │  │
│  │  │      • Outbound: Allow 1024–65535                                 │  │  │
│  │  │                                                                   │  │  │
│  │  │   ┌──────────── EC2: Web Server (Public) ───────────┐             │  │  │
│  │  │   │  ↳ Security Group (SG): Instance-level firewall │             │  │  │
│  │  │   │     • Inbound: 80,443 from 0.0.0.0/0            │             │  │  │
│  │  │   │     • Outbound: All (stateful auto-return)      │             │  │  │
│  │  │   └─────────────────────────────────────────────────┘             │  │  │
│  │  │                                                                   │  │  │
│  │  │   NAT Gateway (for Private Subnet outbound Internet)              │  │  │
│  │  │   Route Table: 0.0.0.0/0 → IGW                                    │  │  │
│  │  └───────────────────────────────────────────────────────────────────┘  │  │
│  │                                                                         │  │
│  │  ┌──────────────────── Private Subnet (10.0.2.0/24) ─────────────────┐  │  │
│  │  │  ↳ NACL: Subnet-level firewall (stateless)                        │  │  │
│  │  │      • Inbound: Allow 3306 (MySQL) from Public Subnet             │  │  │
│  │  │      • Outbound: Allow 80,443 → NAT                               │  │  │
│  │  │                                                                   │  │  │
│  │  │   ┌──────────── EC2: App Server ───────────┐                      │  │  │
│  │  │   │  ↳ SG: Allow 3306 inbound from Web SG  │                      │  │  │
│  │  │   │  ↳ Outbound: All                       │                      │  │  │
│  │  │   └────────────────────────────────────────┘                      │  │  │
│  │  │                                                                   │  │  │
│  │  │   RDS Database (same subnet or isolated subnet)                   │  │  │
│  │  │   ↳ SG: Allow inbound 3306 only from App SG                       │  │  │
│  │  │   Route Table: 0.0.0.0/0 → NAT                                    │  │  │
│  │  └───────────────────────────────────────────────────────────────────┘  │  │
│  │                                                                         │  │
│  └────────────────────────────│         │──────────────────────────────────┘  │
│          IGW ↔ Internet Gate Way                                              │
└───────────────────────────────────────────────────────────────────────────────┘

```
 **User-Oriented Flow Summary**

1. **User (Browser/SSH Client)**  
   → sends a request to access the EC2 instance (for example, to open a website or start an SSH session).

2. **Internet → Internet Gateway (IGW)**  
   → The request first passes through the **Internet Gateway**, which connects the AWS VPC to the Internet.

3. **Public Subnet (protected by Network Access Control List – NACL)**  
   → The packet enters the public subnet where firewall rules at the subnet level (NACL) allow or deny the request.

4. **EC2 Instance (secured by Security Group – SG)**  
   → The instance’s **Security Group** checks whether traffic on ports 22 (SSH) or 80/443 (HTTP/HTTPS) is allowed.  
   If allowed, the user reaches the EC2 instance running an Apache/Nginx server or terminal environment.

5. **Public EC2 Instance → Private EC2 Instance / Relational Database Service (RDS)**  
   → Internal traffic moves over the **local route** within the VPC (no Internet involvement).  
   The web server can fetch content, connect to a database, or run learning material (e.g., Bash/Git examples from W3Schools).

6. **Private EC2 Instance → Network Address Translation Gateway (NAT Gateway)**  
   → When the private instance needs to download updates, learning scripts, or Git repositories,  
   it uses the **NAT Gateway** in the public subnet to access the Internet securely (outbound only).

7. **Return Path**  
   → Responses from the instance (webpage, terminal output, or Git clone result) follow the same route in reverse,  
   returning through the IGW to the user’s browser or SSH client. 

</details>

---
<details>
<summary><strong>3. CIDR and IP Address Ranges</strong></summary>

---

Before you design rooms or hallways inside your private AWS building, you first decide **how much land the building covers** and **how many rooms can fit inside**.  
That boundary is defined by **CIDR (Classless Inter-Domain Routing)** — it decides the total number of IP addresses your VPC owns.

---

### 3.1 The idea behind CIDR

A CIDR block looks like `10.0.0.0/16`.  
The first part (`10.0.0.0`) is the **starting address**, and the number after the slash (`/16`) tells AWS how much of that address range belongs to you.

The **smaller the number after the slash**, the **larger** your space.  
Each increase in the slash makes your range smaller — fewer addresses to hand out.

```
10.0.0.0/16  →  65,536 total addresses
10.0.1.0/24  →     256 total addresses
10.0.3.0/28  →      16 total addresses
```
Each block size comes from the same simple rule:

> **Total IPs = 2^(32 – Subnet Mask)**

AWS keeps things practical — it only allows CIDRs between **/16** (largest) and **/28** (smallest),
and automatically holds back **5 IPs per subnet** for its own internal use.

---

### 3.2 A local picture — Florida & Delray Beach

Imagine your **entire office building (VPC)** spans a large property — say `10.0.0.0/16`.  
Each **floor (Subnet)** represents a smaller section like `10.0.1.0/24`,  
and each **office room (EC2 instance)** inside that floor gets its own private address such as `10.0.1.5`.  

No floor can extend beyond the total land your building occupies,  
ensuring each department (subnet) stays organized and isolated within the same property.

```
VPC (10.0.0.0/16) → Entire building
Subnet (10.0.1.0/24) → One floor
EC2 (10.0.1.5) → One office room
```

---

<details>
<summary><strong> Math & Sizing (How many IPs fit?)</strong></summary>

---
### 3.3 Math & Sizing (How many IPs fit?)

You size your space with one rule:

**Total IPs = 2^(32 − Subnet Mask)**  
AWS lets you build between **/16** (largest) and **/28** (smallest).  
Inside every subnet, AWS reserves 5 IPs (router, DNS, network ID, future use, broadcast).  
So: **Usable = Total − 5**

| CIDR | Total IPs | Usable IPs (Total − 5) | When to use it |
|------|-----------|------------------------|----------------|
| **/16** | 65,536 | 65,531 | Whole VPC range for large environments |
| **/17** | 32,768 | 32,763 | Big multi-AZ footprints |
| **/18** | 16,384 | 16,379 | Growing environments with many subnets |
| **/19** | 8,192 | 8,187 | Medium scale deployments |
| **/20** | 4,096 | 4,091 | Common “large subnet” size |
| **/21** | 2,048 | 2,043 | App tiers with room to grow |
| **/22** | 1,024 | 1,019 | Busy service subnets |
| **/23** | 512 | 507 | Moderate traffic tiers |
| **/24** | 256 | 251 | Standard subnet size (very common) |
| **/25** | 128 | 123 | Smaller tiers / labs |
| **/26** | 64 | 59 | Tight tiers, NAT or ALB subnets |
| **/27** | 32 | 27 | Tiny control planes |
| **/28** | 16 | 11 | Minimum AWS size (test or jump box) |

> Anything below /28 (i.e., /29 to /32) is not supported for AWS subnets.

---

### 3.4 Quick examples

* `10.0.0.0/16` → 2^(32−16) = 2^16 = 65,536 total → 65,531 usable  
* `10.0.1.0/24` → 2^(32−24) = 2^8 = 256 total → 251 usable  
* `172.31.0.0/20` → 2^(32−20) = 2^12 = 4,096 total → 4,091 usable  
* `10.0.3.0/28` → 2^(32−28) = 2^4 = 16 total → 11 usable  

</details>

</details>

---

<details>
<summary><strong>4. Subnets and Availability Zones</strong></summary>

---

Once your VPC’s boundaries are defined, the next step is to **divide that space** into smaller, functional zones — called **Subnets**.  
A subnet is a logical segment of your VPC that lives entirely inside **one Availability Zone (AZ)**.  
Each subnet is built for a specific purpose: some are open to the Internet, others stay private and isolated.

---

### 4.1 Public vs Private Subnets

| Subnet Type | Connectivity | Common Use |
|--------------|--------------|------------|
| **Public Subnet** | Connected to the Internet Gateway (IGW) | Web servers, bastion hosts |
| **Private Subnet** | Connected to a NAT Gateway (outbound only) | Databases, backend applications |

✅ **Design Principle:**  
For fault tolerance and high availability, create **one public and one private subnet per AZ**.  
Each pair belongs to a different Availability Zone — so if one AZ fails, the other continues operating normally.

---

### 4.2 How subnets fit into your AWS building

Imagine your **VPC as the building**, and each **subnet as a floor**.  
Some floors are **public-facing** — they host reception or web servers that interact with visitors.  
Other floors are **restricted zones** — accessible only to staff and internal systems like databases or application servers.  

Each subnet connects to the rest of the building using **route tables**,  
and the presence (or absence) of an **Internet Gateway** decides whether that subnet is publicly reachable.

---

### 4.3 Example Layout

```

VPC (10.0.0.0/16)
├─ Public Subnet A (10.0.1.0/24)
├─ Private Subnet A (10.0.2.0/24)
├─ Public Subnet B (10.0.3.0/24)
└─ Private Subnet B (10.0.4.0/24)

```

Here, each pair (Public A + Private A, Public B + Private B) sits in different **Availability Zones**,  
creating redundancy across the region.

---

### 4.4 Architecture Snapshot

```

┌───────────────────────────── AWS Region ──────────────────────────────┐
│                                                                       │
│ ┌────────────────────────── VPC (10.0.0.0/16) ──────────────────────┐ │
│ │                                                                   │ │
│ │    Availability Zone A      Availability Zone B                   │ │
│ │ ┌───────────────────────┐ ┌───────────────────────┐               │ │
│ │ │ Public Subnet A       │ │ Public Subnet B       │               │ │
│ │ │ (10.0.1.0/24)         │ │ (10.0.3.0/24)         │               │ │
│ │ │ → Internet Gateway    │ │ → Internet Gateway    │               │ │
│ │ └───────────────────────┘ └───────────────────────┘               │ │
│ │ ┌───────────────────────┐ ┌───────────────────────┐               │ │
│ │ │ Private Subnet A      │ │ Private Subnet B      │               │ │
│ │ │ (10.0.2.0/24)         │ │ (10.0.4.0/24)         │               │ │
│ │ │ → NAT Gateway (out)   │ │ → NAT Gateway (out)   │               │ │
│ │ └───────────────────────┘ └───────────────────────┘               │ │
│ │                                                                   │ │
│ └───────────────────────────────────────────────────────────────────┘ │
│                                                                       │
└───────────────────────────────────────────────────────────────────────┘

```

Each subnet connects to the Internet or other subnets **only through defined routes**,  
ensuring clear separation between public-facing workloads and internal systems.

</details>

---

<details>
<summary><strong>5. Routing, Internet Gateway (IGW) & NAT Gateway</strong></summary>

---

Every subnet inside your VPC needs a **Route Table** — a set of rules that decide **where network traffic should go**.  
These routes determine how instances inside your VPC communicate with each other and with the outside world.

---

### 5.1 How Routing Works

Each subnet in your VPC is associated with exactly **one route table**.  
When an instance sends a packet, AWS checks the route table of that subnet and decides the next hop based on the destination IP address.

| Destination | Target | Purpose |
|--------------|---------|----------|
| `10.0.0.0/16` | `local` | Internal communication within the VPC |
| `0.0.0.0/0` | `igw-xxxx` | Outbound access to the Internet |
| `0.0.0.0/0` | `nat-xxxx` | Private subnet outbound Internet via NAT Gateway |

---

### 5.2 Internet Gateway (IGW)

An **Internet Gateway** connects your VPC to the Internet.  
It allows traffic to flow in and out for public subnets.  
Any instance with a public or Elastic IP and a route to the IGW can communicate directly with external networks.

| Feature | Description |
|----------|-------------|
| **Scope** | One per VPC |
| **Direction** | Two-way (inbound and outbound) |
| **Attachment** | Must be explicitly attached to the VPC |
| **Cost** | Free of charge |

If a subnet’s route table points `0.0.0.0/0 → IGW`, that subnet becomes **public**.

---

### 5.3 NAT Gateway (Network Address Translation)

A **NAT Gateway** allows private instances (without public IPs) to **initiate outbound connections** to the Internet, such as downloading patches or updates — while blocking all inbound traffic.  

This keeps your internal systems secure while still enabling them to access online resources.

| Feature | Description |
|----------|-------------|
| **Scope** | One per Availability Zone |
| **Direction** | Outbound only (no inbound) |
| **Connectivity** | Uses Elastic IP + resides in a public subnet |
| **Cost** | Charged hourly + per-GB processed |

If a private subnet’s route table points `0.0.0.0/0 → NAT Gateway`, instances inside it can reach the Internet **outbound only**.

---

### 5.4 Example Flow

1. A user accesses your application via the Internet.  
2. The request enters the VPC through the **Internet Gateway** and reaches the **public subnet** (web tier).  
3. The web tier communicates internally with the **private subnet** (app/database tier) via local routing.  
4. Private instances connect to the Internet (for updates or external APIs) through the **NAT Gateway**.  
5. The NAT Gateway forwards responses back, maintaining the private subnet’s isolation.

---

### 5.5 Architecture Snapshot

```

┌────────────────────────────────────────── AWS Region ────────────────────────────────────────┐
│                                                                                              │
│       ┌───────────────────────────── VPC (10.0.0.0/16) ───────────────────────────────┐      │
│       │                                                                               │      │
│       │  Public Subnet (10.0.1.0/24)           Private Subnet (10.0.2.0/24)           │      │
│       │  ┌────────────────────────────┐        ┌────────────────────────────┐         │      │
│       │  │  EC2: Web Server (Public)  │        │ EC2: App/DB (Private)      │         │      │
│       │  │  Route: 0.0.0.0/0 → IGW    │        │ Route: 0.0.0.0/0 → NAT     │         │      │
│       │  └────────────────────────────┘        └────────────────────────────┘         │      │
│       │                                                                               │      │
│       │  IGW ↔ Internet                                                               │      │
│       │  NAT Gateway (in public subnet) → Outbound for private subnet                 │      │
│       │                                                                               │      │
│       └───────────────────────────────────────────────────────────────────────────────┘      │
│                                                                                              │
└──────────────────────────────────────────────────────────────────────────────────────────────┘

```

Traffic Summary:  
- **Inbound Internet → IGW → Public Subnet → EC2 (Web/App)**  
- **Internal traffic → Route Table (local)**  
- **Private outbound → NAT Gateway → IGW → Internet**

</details>

---

<details>
<summary><strong>6. Security Groups vs Network ACLs (NACLs)</strong></summary>

---

Once your network layout is built, the next question is **who gets access** and **at what level**.  
AWS gives you two primary layers of control:

1. **Security Groups (SG)** – act at the **instance level**.  
2. **Network ACLs (NACLs)** – act at the **subnet level**.

Together, they form your building’s **security framework** — door locks for individual rooms (SGs) and entry gates for entire floors (NACLs).

---

### 6.1 Security Groups (SG)

A **Security Group** is a **stateful firewall** attached to individual EC2 instances, load balancers, or other resources.  
Stateful means that if an inbound rule allows traffic in, the corresponding outbound traffic is automatically allowed — even if there’s no explicit outbound rule.

| Feature | Description |
|----------|-------------|
| **Level** | Instance (EC2, ENI, ALB, etc.) |
| **Behavior** | Stateful – return traffic automatically allowed |
| **Rules** | Only “Allow” rules (no Deny) |
| **Default Behavior** | Deny all inbound, allow all outbound |
| **Typical Use** | Web servers, application servers |

**Example – Web Server SG**
┌────────────────────────────────────────────────────────────────────────┐
| Direction  | Protocol  | Port            | Source   | Purpose          |
|------------|-----------|-----------------|----------|------------------|
| Inbound    | TCP       | 22 | 0.0.0.0/0  | SSH      | for admin access |
| Inbound    | TCP       | 80 | 0.0.0.0/0  | HTTP     | web traffic      |
| Inbound    | TCP       | 443 | 0.0.0.0/0 | HTTPS    | secure traffic   |
| Outbound   | All | All | 0.0.0.0/0       | Allow    | return responses |
└────────────────────────────────────────────────────────────────────────┘
---

### 6.2 Network ACLs (NACLs)

A **Network Access Control List (NACL)** is a **stateless firewall** that operates at the **subnet level**.  
Stateless means that inbound and outbound rules are evaluated **separately** — both directions must be explicitly allowed.

| Feature | Description |
|----------|-------------|
| **Level** | Subnet |
| **Behavior** | Stateless – inbound and outbound checked separately |
| **Rules** | Can Allow or Deny |
| **Rule Order** | Evaluated in numeric order (lowest first) |
| **Default Behavior** | Allow all inbound and outbound |
| **Typical Use** | Additional subnet boundary protection |

**Example – Public Subnet NACL**
| Rule # | Direction | Action | Protocol | Port Range | Source | Purpose |
|---------|------------|---------|-----------|-------------|---------|----------|
| 100 | Inbound | ALLOW | TCP | 80,443,22 | 0.0.0.0/0 | Allow web + SSH |
| 110 | Outbound | ALLOW | TCP | 1024–65535 | 0.0.0.0/0 | Allow return traffic |
| * | * | DENY | All | All | All | Default deny catch-all |

---

### 6.3 Comparison Summary

| Feature | **Security Group (SG)** | **Network ACL (NACL)** |
|----------|-------------------------|--------------------------|
| **Level** | Instance (ENI) | Subnet |
| **Statefulness** | ✅ Stateful | ❌ Stateless |
| **Default Behavior** | Inbound Deny / Outbound Allow | Allow All |
| **Supports Deny Rules** | ❌ No | ✅ Yes |
| **Evaluation Order** | All rules apply | Lowest number first |
| **Typical Usage** | Fine-grained access control | Broad subnet boundaries |
| **Recommended Practice** | Use SGs for most cases; NACLs for extra subnet protection | Combined use for layered security |

---

### 6.4 Architecture Snapshot
```
┌──────────────────── VPC (10.0.0.0/16) ─────────────────────┐
│                                                            │
│ ┌──────────────────── Public Subnet ─────────────────────┐ │
│ │ ↳ NACL: Subnet-level filter                            │ │
│ │ • Allows ports 80, 443, 22                             │ │
│ │                                                        │ │
│ │ ┌───────────── EC2 Instance ──────────────┐            │ │
│ │ │ ↳ Security Group: Instance firewall     │            │ │
│ │ │ • Allows 80, 443 inbound                │            │ │
│ │ │ • Outbound auto-allowed                 │            │ │
│ │ └─────────────────────────────────────────┘            │ │
│ └────────────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────────┘
```
---

**Quick takeaway:**  
Use **Security Groups** for everyday access control — they’re simple, reliable, and stateful.  
Add **NACLs** only when you need an additional layer of subnet-level defense.

</details>

---

<details>
<summary><strong>7. IP Concepts – Private, Public, Elastic, ENI</strong></summary>

## IP Concepts – Addresses Inside Your Building

Every EC2 instance inside your **VPC (your private building inside the AWS city)** needs an address to communicate — both **internally** and **externally**.  
These addresses define how your resources talk to one another and how they reach the outside Internet.  

Each EC2 instance can have four types of network identifiers:

- **Private IP** → for internal communication within your building (VPC).  
- **Public IP** → for temporary Internet access through the main entrance (Internet Gateway).  
- **Elastic IP** → a permanent, reusable public address for consistent external access.  
- **ENI (Elastic Network Interface)** → the virtual network panel that stores these addresses and connects instances to the network.

---

### 7.1 Private IP – The Room Address Inside Your Building

Whenever you launch an EC2 instance inside your VPC, AWS automatically assigns it a **Private IP address**.  

This address is used for **internal communication** —  
for example, your web server on one floor talking to your database room on another, all within the same secured building.  

A Private IP **remains the same** even if you restart the instance,  
but it is **released permanently** when you remove the instance (terminate it).  

Private IPs are **free of cost** and **invisible from outside the building (the Internet)** — they function only within your internal network boundaries.

**Example**
Instance A → Private IP: 10.0.0.5
Instance B → Private IP: 10.0.0.8

Both rooms can communicate freely because they exist inside the same building (VPC).

**Analogy:**  
A **Private IP** is your **room number inside the building** —  
employees within the same premises can reach you directly,  
but outsiders from the city cannot see or contact you.

---

### 7.2 Public IP – Internet-Facing Address

When an EC2 instance is launched in a **public subnet**, AWS assigns it a **Public IP address**.  
This allows the instance to communicate directly with the Internet through an **Internet Gateway (IGW)**.

A Public IP is **temporary**.  
If you stop or terminate the instance, the address is released and a new one is assigned when it starts again.  
Public IPs are included under the AWS Free Tier for up to 750 hours per month.

**Example**
```

Private IP: 10.0.0.12
Public IP: 3.120.55.23

```

You can connect to the instance using SSH:
```
ssh -i mykey.pem ec2-user@3.120.55.23
```

If the instance restarts, the Public IP might change to a new value such as `13.210.40.50`.

---

### 7.3 Elastic IP – Static Public Address

An **Elastic IP (EIP)** is a **static public IPv4 address** that you allocate to your AWS account.  
Unlike a regular Public IP, an Elastic IP address remains the same even when an instance is stopped, restarted, or replaced.  

You can attach an Elastic IP to any instance in a public subnet, detach it when not needed, and reassign it to another instance at any time.  
Elastic IPs are **free while attached** to a running instance, but AWS charges for **idle addresses** that are allocated but unused.

**Example**

```
Elastic IP: 18.220.45.90
Associated Instance: EC2-Web-Server
```

Even after restart:

```
Elastic IP: 18.220.45.90 (Permanent)
```
---

### 7.4 ENI (Elastic Network Interface)

An **Elastic Network Interface (ENI)** is a **virtual network card** that connects an EC2 instance to the VPC network.  
Each ENI contains one or more **Private IPs**, optional **Public or Elastic IPs**, and associated **Security Groups**.

ENIs can be created independently and attached or detached from instances as needed.  
They are commonly used for **high availability**, **multi-homed network setups**, or **failover configurations**.

| Attribute | Description |
|------------|--------------|
| **Primary ENI** | Created automatically when an instance is launched |
| **Secondary ENI** | Can be attached manually for redundancy or network segregation |
| **Contains** | Private IPs, Public/Elastic IPs, MAC address, Security Groups |
| **Use Case** | Load balancing, failover, or separate management networks |

**Example**
ENI ID: eni-0a12b3c4d567890ef
Attached Instance: EC2-App-Server
Private IP: 10.0.0.8
Public IP: 3.90.55.21
Security Group: sg-0f12a3b4c567890de

---

Here’s that entire **Comparison + Diagram section** rewritten in your new, clean technical format — no analogies, no emojis, just structured AWS clarity.
It fits perfectly after your Elastic IP and ENI sections.

---

### 5. Comparison Summary

| IP Type | Purpose | Persistence | Cost | Notes |
|----------|----------|-------------|------|--------|
| **Private IP** | Internal communication within the VPC | Persists on restart | Free | Used for traffic between instances inside the same VPC |
| **Public IP** | Direct Internet access via IGW | Changes on restart | Free (up to 750 hrs/mo) | Automatically assigned to instances in public subnets |
| **Elastic IP** | Static public IPv4 address | Fixed and reusable | Free if attached; billed if idle | Manually allocated and can be reattached to any instance |
| **ENI** | Network interface for EC2 | N/A | Free | Holds IPs, MAC address, and Security Group associations |

---

### 6. Architecture Overview

```
┌─────────────────────────────── AWS Environment ────────────────────────────────────┐
│                                                                                    │
│   ┌─────────────────────────────── VPC (10.0.0.0/16)───────────────────────────┐   │
│   │                                                                            │   │
│   │  ┌──────────────────── Public Subnet (10.0.1.0/24) ──────────────────┐     │   │
│   │  │  EC2 Instance: Web Server                                         │     │   │
│   │  │  Private IP: 10.0.0.12                                            │     │   │
│   │  │  Public IP: 3.120.55.23                                           │     │   │
│   │  │  Elastic IP (optional): 18.220.45.90                              │     │   │
│   │  │  Route: 0.0.0.0/0 → Internet Gateway (IGW)                        │     │   │
│   │  └───────────────────────────────────────────────────────────────────┘     │   │
│   │                                                                            │   │
│   │  ┌──────────────────── Private Subnet (10.0.2.0/24) ─────────────────┐     │   │
│   │  │  EC2 Instance: Application / Database Server                      │     │   │
│   │  │  Private IP: 10.0.0.8                                             │     │   │
│   │  │  Route: 0.0.0.0/0 → NAT Gateway                                   │     │   │
│   │  │  No Public IP (internal access only)                              │     │   │
│   │  └───────────────────────────────────────────────────────────────────┘     │   │
│   │                                                                            │   │
│   │  IGW ↔ Internet                                                            │   │
│   │  NAT Gateway → Outbound Internet for Private Subnet                        │   │
│   │                                                                            │   │
│   └────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                    │
└────────────────────────────────────────────────────────────────────────────────────┘
```
Traffic Flow Summary:
- Public instance ↔ Internet through **Internet Gateway (IGW)**.  
- Private instance ↔ Internet (outbound only) through **NAT Gateway**.  
- Internal communication via **Private IPs** within the same VPC.  
- **ENI** stores and manages each instance’s IP configuration and Security Groups.

</details>

---

<details>
<summary><strong>8. Networking Foundations (DNS, TCP, OSI)</strong></summary>

## Why do we need prerequisites before OSI?

Before the OSI model starts wrapping and sending data, two things usually happen first:  
1. We find the server’s **IP address**.  
2. We make sure there’s a **reliable connection**.



---

## A) Domain Name System (DNS)

DNS translates a **domain name** (like `google.com`) into its **corresponding IP address**.  
It acts as the Internet’s address book, enabling users to reach servers without memorizing IPs.

**Steps:**
1. Browser checks its local cache.  
2. If not found → asks the **router** → then your **ISP’s DNS**.  
3. ISP may ask **Root** → **TLD** (like `.com`) → **Authoritative** DNS server.  
4. The authoritative server replies with the correct **IP address** (e.g., `142.250.xx.xx`).

> Without DNS, we’d have to memorize IPs instead of names — like remembering every restaurant’s GPS coordinates.

---

## B) Transmission Control Protocol (TCP) – 3-Way Handshake

*Analogy:* Starting a phone call:  
- You: “Hello, can you hear me?”  
- Server: “Yes, I can.”  
- You: “Great, let’s talk.”

**Steps:**
1. **SYN (Synchronize)** → Client: “I want to connect.”  
2. **SYN-ACK (Synchronize + Acknowledge)** → Server: “I hear you; I’m ready.”  
3. **ACK (Acknowledge)** → Client: “Confirmed, let’s begin.”

Now the connection is reliable.  
(When using **HTTPS**, a **TLS handshake** happens right after this to secure the communication.)

---

## C) OSI 7 Layers (Top → Bottom)

---

### Layer 7 — Application

This is where the **user interacts** directly.  
Example: You type `https://www.google.com` → your browser sends an **HTTP/HTTPS request** because **you asked for it**.

Common protocols:  
- **HTTP/HTTPS** – web traffic  
- **FTP** – file transfers  
- **SMTP/IMAP** – emails

---

### Layer 6 — Presentation

Handles **formatting, encryption, and compression** so the data looks correct and secure.  
Example: HTTPS encrypts your message before sending.

---

### Layer 5 — Session

Creates and maintains **sessions** between two systems.  
Example: You log in to **Instagram**, and for the next few minutes you don’t need to log in again — the session is active.  
If you log out or it expires, the session closes.

---

### Layer 4 — Transport

Breaks big data into **segments**, numbers them, and ensures everything arrives correctly.  
Two key protocols live here:

- **TCP** → Reliable, ordered, connection-based (used by HTTPS).  
- **UDP** → Faster, connectionless, no guarantee (used by video calls, games, DNS queries).

Example: Sending a **10 GB wedding video** — it’s split into small numbered pieces that are reassembled on the other side.

---

### Layer 3 — Network

Adds **IP addresses** and decides how to reach the destination.  
Routers pick the **best path** to get data from your computer to the target server.

Example: Going from **Delhi → Mumbai**, there are many roads; the router picks the fastest route.

---

### Layer 2 — Data Link

Works inside your **local network (LAN, Wi-Fi, Ethernet)**.  
It converts **packets → frames** and adds **MAC addresses** for local delivery.

Example: Your router knows which device to send data to — your phone or your laptop — using their unique MAC IDs.

---

### Layer 1 — Physical

Turns everything into **bits (0s and 1s)** and sends them as signals over **wires or air**.  
Examples: Fiber optics, copper cables, Wi-Fi signals.

---

## D) Encapsulation & Decapsulation

When you send data, it moves **down** through all layers (7 → 1).  
When the receiver gets it, it moves **up** (1 → 7).

```

Sender:   L7 → L6 → L5 → L4 → L3 → L2 → L1  (wrap the data)
Network:  --- bits travel through wires/Wi-Fi ---
Receiver: L1 → L2 → L3 → L4 → L5 → L6 → L7  (unwrap the data)

```
---

**Key Takeaways:**
1. **DNS** finds where to send data.  
2. **TCP handshake** makes the connection reliable.  
3. **OSI layers** define how the message is wrapped, sent, and understood.  
4. Each layer adds its own “box” to keep communication smooth and universal.

</details>

---

<details>
<summary><strong>9. Architecture Blueprint – End-to-End VPC Design</strong></summary>

---

### 9.1 Example: Two-Tier Web Application

**Region:** us-east-1  
**VPC:** 10.0.0.0/16  

```

├─ Public Subnet-A (10.0.1.0/24) → EC2 Web Server + Internet Gateway
└─ Private Subnet-A (10.0.2.0/24) → RDS Database + NAT Gateway

```

**Traffic Flow**
1. Internet user sends a request to the web server’s public IP or Elastic IP.  
2. The request passes through the **Internet Gateway (IGW)** into the **Public Subnet**.  
3. The **EC2 Web Server** handles the request and queries the **RDS Database** inside the **Private Subnet** through the VPC’s local route.  
4. The database responds through the same internal route—never exposed to the Internet.  
5. When the private subnet needs outbound access (for patching or API calls), traffic goes through the **NAT Gateway** in the public subnet.  

---

### 9.2 Security Controls
| Layer | Component | Function |
|--------|------------|-----------|
| **Per Instance** | Security Groups | Control inbound/outbound traffic to specific EC2 or RDS resources |
| **Per Subnet** | Network ACLs | Define allowed or denied CIDR ranges at the subnet level |
| **Edge** | Internet / NAT Gateway | Manage inbound and outbound Internet connectivity |

---

### 9.3 Architecture Snapshot

```

┌──────────────────────────────────────── AWS Region ────────────────────────────────────────┐
│                                                                                            │
│        ┌────────────────────────── VPC (10.0.0.0/16) ────────────────────────────┐         │
│        │                                                                         │         │
│        │   ┌──────────────────── Public Subnet (10.0.1.0/24) ────────────────┐   │         │
│        │   │ EC2 Web Server                                                  │   │         │
│        │   │  - Public IP / Elastic IP                                       │   │         │
│        │   │  - Security Group: allow HTTP/HTTPS, SSH                        │   │         │
│        │   │ Route: 0.0.0.0/0 → Internet Gateway                             │   │         │
│        │   │ NAT Gateway → Outbound Internet for Private Subnet              │   │         │
│        │   └─────────────────────────────────────────────────────────────────┘   │         │
│        │                                                                         │         │
│        │   ┌──────────────────── Private Subnet (10.0.2.0/24) ───────────────┐   │         │
│        │   │ RDS Database / Application Server                               │   │         │
│        │   │  - Private IP only                                              │   │         │
│        │   │  - Security Group: allow MySQL (3306) from Web SG               │   │         │
│        │   │ Route: 0.0.0.0/0 → NAT Gateway (outbound only)                  │   │         │
│        │   └─────────────────────────────────────────────────────────────────┘   │         │
│        │                                                                         │         │
│        │  IGW ↔ Internet                                                         │         │
│        └─────────────────────────────────────────────────────────────────────────┘         │
│                                                                                            │
└────────────────────────────────────────────────────────────────────────────────────────────┘

```

---

### 9.4 Summary

- **VPC** provides isolation and IP range control.  
- **Public Subnet** hosts resources that require Internet access.  
- **Private Subnet** keeps internal services secure.  
- **IGW** handles inbound/outbound public traffic.  
- **NAT Gateway** enables private resources to reach the Internet safely.  
- **Security Groups and NACLs** enforce least-privilege access across all tiers.

</details>