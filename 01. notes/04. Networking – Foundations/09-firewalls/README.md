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
[Complete Journey](../10-complete-journey/README.md)

---

# Firewalls & Security

## What this file is about

This file teaches **how to control network access using firewall rules** and **the critical difference between stateful and stateless firewalls**. If you understand this, you'll know how to secure AWS infrastructure, debug "connection refused" errors, and avoid the common NACL trap that breaks beginners. This is essential for production deployments.

<!-- no toc -->
- [The Core Problem](#the-core-problem)
- [What Is a Firewall?](#what-is-a-firewall)
- [Firewall Rules (The Basics)](#firewall-rules-the-basics)
- [Stateful vs Stateless (CRITICAL)](#stateful-vs-stateless-critical)
- [AWS Security Groups (Stateful)](#aws-security-groups-stateful)
- [AWS NACLs (Stateless)](#aws-nacls-stateless)
- [The NACL Trap (Common Mistake)](#the-nacl-trap-common-mistake)
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

Problem:
  Anyone on the internet can connect to ANY port
  
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

**Purpose:**  
Act as a barrier between trusted internal network and untrusted external network (internet).

---

### Firewall Placement

**Network firewall (between networks):**

```
┌──────────────┐         ┌──────────┐         ┌──────────┐
│   Internet   │ ←────→  │ Firewall │ ←────→  │ Internal │
│              │         │          │         │ Network  │
└──────────────┘         └──────────┘         └──────────┘

Inspects all traffic crossing boundary
```

**Host-based firewall (on server):**

```
┌────────────────────────────────┐
│     Server (203.45.67.89)      │
│                                │
│  ┌──────────────────────────┐  │
│  │   Firewall (iptables)    │  │
│  │                          │  │
│  │  Rules:                  │  │
│  │  - Allow 80, 443         │  │
│  │  - Allow 22 from office  │  │
│  │  - Block everything else │  │
│  └──────────────────────────┘  │
│               │                │
│       ┌───────┴────────┐       │
│       │   Application  │       │
│       │   (nginx, etc) │       │
│       └────────────────┘       │
└────────────────────────────────┘
```

---

### Firewall Types

**Packet filtering (Layer 3-4):**

```
Examines:
  - Source IP
  - Destination IP
  - Source port
  - Destination port
  - Protocol (TCP/UDP)

Decision: Allow or deny

Examples: iptables, AWS Security Groups, NACLs
```

**Stateful inspection (Layer 3-4, connection-aware):**

```
Tracks connection state
Remembers outbound requests
Automatically allows related return traffic

Examples: AWS Security Groups, modern firewalls
```

**Application layer (Layer 7):**

```
Inspects application data
Can block based on:
  - URLs
  - HTTP headers
  - Content patterns
  
Examples: Web Application Firewall (WAF), proxy servers
```

**For DevOps basics: Focus on packet filtering (stateful vs stateless)**

---

## Firewall Rules (The Basics)

### Rule Components

**Every firewall rule specifies:**

```
1. Direction (inbound or outbound)
2. Protocol (TCP, UDP, ICMP, or ALL)
3. Port range (22, 80, 443, or range like 1024-65535)
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
Destination: This server
Action:      ALLOW

Meaning:
  Traffic TO this server
  Using TCP protocol
  On port 22 (SSH)
  FROM office IP range
  = ALLOWED
```

---

### Rule Example (Outbound)

```
Rule: Allow HTTPS to internet

Direction:   Outbound
Protocol:    TCP
Port:        443
Source:      This server
Destination: 0.0.0.0/0 (anywhere)
Action:      ALLOW

Meaning:
  Traffic FROM this server
  Using TCP protocol
  On port 443 (HTTPS)
  TO anywhere
  = ALLOWED
```

---

### Default Policy

**Firewalls have a default action:**

**Default DENY (recommended, whitelist approach):**

```
Default: DENY all traffic

Explicit rules:
  ALLOW port 80 from 0.0.0.0/0
  ALLOW port 443 from 0.0.0.0/0
  ALLOW port 22 from 203.0.113.0/24

Everything else: DENIED

Secure: Only explicitly allowed traffic passes
```

**Default ALLOW (dangerous, blacklist approach):**

```
Default: ALLOW all traffic

Explicit rules:
  DENY port 3306 from 0.0.0.0/0
  DENY port 5432 from 0.0.0.0/0

Everything else: ALLOWED

Insecure: Easy to forget to block something
```

**Best practice: Default DENY, explicitly ALLOW what's needed**

---

### Source/Destination Notation

**IP addresses:**

```
Single IP:
  203.0.113.45/32

IP range (CIDR):
  203.0.113.0/24 (203.0.113.0 - 203.0.113.255)
  10.0.0.0/16 (10.0.0.0 - 10.0.255.255)

Anywhere (internet):
  0.0.0.0/0 (all IPv4 addresses)
```

**AWS-specific:**

```
Security group ID:
  sg-1234567890abcdef (reference another security group)
  
This server:
  Implied (when configuring inbound rules)
```

---

## Stateful vs Stateless (CRITICAL)

### The Most Important Concept in This File

**This single concept causes more AWS beginners to fail than anything else.**

**Understanding this is MANDATORY for working with AWS networking.**

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

**AWS Security Group (stateful):**

```
Inbound rules:
  ALLOW TCP port 80 from 0.0.0.0/0

Outbound rules:
  ALLOW ALL (default)

What happens:
  1. User (123.45.67.89) → Your server (port 80)
     Inbound rule: ALLOW ✅
     
  2. Your server → User (return traffic)
     Security group: "This is return traffic from allowed inbound"
     Automatically allowed ✅ (stateful behavior)
     
Connection works! ✅

You only needed ONE rule (inbound)
Return traffic automatically allowed
```

---

### Stateless Example (Hard)

**AWS NACL (stateless):**

```
Inbound rules:
  ALLOW TCP port 80 from 0.0.0.0/0

Outbound rules:
  (none)

What happens:
  1. User (123.45.67.89:54321) → Your server (port 80)
     Inbound rule: ALLOW ✅
     Request reaches server
     
  2. Your server (port 80) → User (123.45.67.89:54321)
     NACL: "Is there an outbound rule allowing TCP to 123.45.67.89:54321?"
     NO rule exists ❌
     
     Response BLOCKED ❌
     
Connection FAILS! ❌

You needed TWO rules:
  - Inbound: Allow port 80
  - Outbound: Allow ephemeral ports (1024-65535)
```

---

### Visual: Stateful vs Stateless

**Stateful (Security Group):**

```
┌─────────────┐                    ┌─────────────┐
│   Client    │                    │   Server    │
│ 123.45.67.89│                    │203.45.67.89 │
└──────┬──────┘                    └──────┬──────┘
       │                                  │
       │ 1. Request (TCP SYN)             │
       │    Src: 123.45.67.89:54321       │
       │    Dst: 203.45.67.89:80          │
       ├─────────────────────────────────>│
       │                                  │
       │  Security Group (Inbound):       │
       │  "Allow TCP port 80 from 0.0.0.0/0" ✅
       │  Packet allowed                  │
       │                                  │
       │ 2. Response (TCP SYN-ACK)        │
       │    Src: 203.45.67.89:80          │
       │    Dst: 123.45.67.89:54321       │
       │<─────────────────────────────────┤
       │                                  │
       │  Security Group (Outbound):      │
       │  "This is RETURN TRAFFIC"        │
       │  AUTOMATICALLY allowed ✅         │
       │  (stateful - remembers connection)│
       │                                  │
       ✅ Connection successful           │
```

**Stateless (NACL):**

```
┌─────────────┐                    ┌─────────────┐
│   Client    │                    │   Server    │
│ 123.45.67.89│                    │203.45.67.89 │
└──────┬──────┘                    └──────┬──────┘
       │                                  │
       │ 1. Request                       │
       │    Src: 123.45.67.89:54321       │
       │    Dst: 203.45.67.89:80          │
       ├─────────────────────────────────>│
       │                                  │
       │  NACL (Inbound):                 │
       │  "Allow TCP port 80" ✅           │
       │  Packet allowed                  │
       │                                  │
       │ 2. Response                      │
       │    Src: 203.45.67.89:80          │
       │    Dst: 123.45.67.89:54321       │
       │<─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┤
       │         BLOCKED! ❌               │
       │                                  │
       │  NACL (Outbound):                │
       │  NO RULE for port 54321 ❌        │
       │  Packet DROPPED                  │
       │  (stateless - no memory)         │
       │                                  │
       ❌ Connection FAILS                │
```

---

### The Ephemeral Port Problem

**Why stateless is hard:**

**Outbound request (easy):**

```
Your server initiates connection to google.com:443

Outbound:
  Src: Your server:54321 (random ephemeral port)
  Dst: Google:443
  
Rule needed: Allow outbound TCP port 443

Inbound (response):
  Src: Google:443
  Dst: Your server:54321 (ephemeral port)
  
Rule needed: Allow inbound TCP port 54321
  
But wait... you don't know which ephemeral port will be used!
```

**Solution for stateless:**

```
Allow inbound TCP ports 1024-65535 (all ephemeral ports)

This is overly permissive but necessary
This is why stateless firewalls are hard
```

---

### Stateful vs Stateless Summary Table

| Feature | Stateful | Stateless |
|---------|----------|-----------|
| **Remembers connections?** | ✅ Yes | ❌ No |
| **Auto-allows return traffic?** | ✅ Yes | ❌ No |
| **Rules needed** | Fewer (easier) | More (harder) |
| **Configuration complexity** | Low | High |
| **Example** | AWS Security Groups | AWS NACLs |
| **Best for** | Instance-level security | Subnet-level security |

---

## AWS Security Groups (Stateful)

### What Are Security Groups?

**Security Group:**  
Virtual firewall for EC2 instances (and other AWS resources).

**Characteristics:**

```
✅ Stateful (return traffic automatically allowed)
✅ Instance-level (applies to specific instances)
✅ Default DENY (only explicit ALLOW rules)
✅ Can reference other security groups
✅ Changes apply immediately
❌ Cannot create DENY rules (only ALLOW)
```

---

### Security Group Rules

**Inbound rules (traffic TO instance):**

```
Type      Protocol  Port Range  Source
HTTP      TCP       80          0.0.0.0/0
HTTPS     TCP       443         0.0.0.0/0
SSH       TCP       22          203.0.113.0/24
MySQL     TCP       3306        sg-1234abcd (another SG)
```

**Outbound rules (traffic FROM instance):**

```
Type      Protocol  Port Range  Destination
All       All       All         0.0.0.0/0

(Usually left as "allow all" due to stateful behavior)
```

---

### Security Group Example

**Web server security group:**

```
Inbound:
  HTTP (80)    from 0.0.0.0/0 (internet)
  HTTPS (443)  from 0.0.0.0/0 (internet)
  SSH (22)     from 203.0.113.0/24 (office)

Outbound:
  All traffic  to 0.0.0.0/0

How it works:
  1. User accesses https://yourserver.com
  2. Request to port 443 ✅ (allowed inbound)
  3. Server responds ✅ (stateful - auto-allowed)
  
  4. You SSH from office (203.0.113.45)
  5. SSH to port 22 ✅ (allowed inbound from office)
  6. SSH responses ✅ (stateful - auto-allowed)
  
  7. Attacker tries SSH from 123.45.67.89
  8. SSH to port 22 ❌ (not from office network)
  9. Connection refused
```

---

### Referencing Security Groups

**Common pattern: Multi-tier application**

```
Web Server Security Group (sg-web):
  Inbound:
    HTTP/HTTPS from 0.0.0.0/0
  Outbound:
    All to 0.0.0.0/0

App Server Security Group (sg-app):
  Inbound:
    Port 3000 from sg-web (only from web servers!)
  Outbound:
    All to 0.0.0.0/0

Database Security Group (sg-db):
  Inbound:
    Port 5432 from sg-app (only from app servers!)
  Outbound:
    All to 0.0.0.0/0

Security:
  ✅ Database only accessible from app servers
  ✅ App servers only accessible from web servers
  ✅ Web servers only accessible from internet on 80/443
```

---

### Terraform Security Group Example

```hcl
# Web server security group
resource "aws_security_group" "web" {
  name        = "web-server-sg"
  description = "Security group for web servers"
  vpc_id      = aws_vpc.main.id

  # Inbound HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP from internet"
  }

  # Inbound HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS from internet"
  }

  # Inbound SSH (office only)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["203.0.113.0/24"]
    description = "Allow SSH from office"
  }

  # Outbound all (default)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = {
    Name = "web-server-sg"
  }
}

# Database security group
resource "aws_security_group" "database" {
  name        = "database-sg"
  description = "Security group for database"
  vpc_id      = aws_vpc.main.id

  # Inbound PostgreSQL (from app servers only)
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
    description     = "Allow PostgreSQL from app servers"
  }

  # Outbound all
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "database-sg"
  }
}
```

---

## AWS NACLs (Stateless)

### What Are NACLs?

**NACL = Network Access Control List**

**Characteristics:**

```
❌ Stateless (must explicitly allow both directions)
🔒 Subnet-level (applies to entire subnet)
✅ Can create ALLOW and DENY rules
📊 Rule numbers determine evaluation order
⚡ Changes apply immediately
🎯 Last line of defense (after Security Groups)
```

---

### NACL Rule Structure

**Rules have numbers (evaluated in order):**

```
Rule #  Type      Protocol  Port    Source/Dest  Allow/Deny
100     HTTP      TCP       80      0.0.0.0/0    ALLOW
200     HTTPS     TCP       443     0.0.0.0/0    ALLOW
300     SSH       TCP       22      203.0.113.0/24  ALLOW
*       All       All       All     0.0.0.0/0    DENY

Rules evaluated in order (100, 200, 300, *)
First match wins
* = default rule (catch-all)
```

---

### NACL Example (Correct Configuration)

**Allow HTTP/HTTPS traffic:**

**Inbound rules:**

```
Rule #  Type      Protocol  Port Range    Source       Allow/Deny
100     HTTP      TCP       80            0.0.0.0/0    ALLOW
110     HTTPS     TCP       443           0.0.0.0/0    ALLOW
120     Custom    TCP       1024-65535    0.0.0.0/0    ALLOW (ephemeral)
*       All       All       All           0.0.0.0/0    DENY
```

**Outbound rules:**

```
Rule #  Type      Protocol  Port Range    Destination  Allow/Deny
100     HTTP      TCP       80            0.0.0.0/0    ALLOW
110     HTTPS     TCP       443           0.0.0.0/0    ALLOW
120     Custom    TCP       1024-65535    0.0.0.0/0    ALLOW (ephemeral)
*       All       All       All           0.0.0.0/0    DENY
```

**Why both ephemeral port ranges?**

```
Inbound ephemeral (1024-65535):
  For RETURN traffic when instance makes outbound request
  Instance:54321 → Google:443
  Google:443 → Instance:54321 (needs inbound rule for 54321)

Outbound ephemeral (1024-65535):
  For RETURN traffic when user makes inbound request
  User:54321 → Instance:80
  Instance:80 → User:54321 (needs outbound rule for 54321)

Stateless = Must allow BOTH directions explicitly
```

---

## The NACL Trap (Common Mistake)

### The Scenario That Breaks Beginners

**Setup:**

```
VPC with default NACL (allow all)
Working fine

DevOps engineer: "Let's add security!"
Creates custom NACL
```

**Beginner's NACL configuration:**

```
Inbound:
  100  TCP  80   0.0.0.0/0  ALLOW  (HTTP)
  110  TCP  443  0.0.0.0/0  ALLOW  (HTTPS)
  *    All  All  0.0.0.0/0  DENY

Outbound:
  100  TCP  80   0.0.0.0/0  ALLOW
  110  TCP  443  0.0.0.0/0  ALLOW
  *    All  All  0.0.0.0/0  DENY

Looks good! All HTTP/HTTPS allowed both ways!
```

---

### What Actually Happens

**User tries to access website:**

```
1. User (123.45.67.89:54321) → Server (YourIP:80)
   
   NACL Inbound check:
   Rule 100: TCP port 80 from 0.0.0.0/0 ✅
   Packet allowed into subnet
   
2. Security Group allows traffic ✅

3. Server processes request

4. Server (YourIP:80) → User (123.45.67.89:54321)
   
   NACL Outbound check:
   Rule 100: TCP port 80 to 0.0.0.0/0
   Destination port is 54321, not 80 ❌
   Rule 110: TCP port 443 to 0.0.0.0/0
   Destination port is 54321, not 443 ❌
   Rule *: DENY ❌
   
   PACKET DROPPED! ❌

Website doesn't load
User sees timeout
Engineer: "But Security Group allows it!"
```

---

### The Fix

**Add ephemeral port rules:**

```
Inbound:
  100  TCP  80          0.0.0.0/0  ALLOW
  110  TCP  443         0.0.0.0/0  ALLOW
  120  TCP  1024-65535  0.0.0.0/0  ALLOW  ← FIX!
  *    All  All         0.0.0.0/0  DENY

Outbound:
  100  TCP  80          0.0.0.0/0  ALLOW
  110  TCP  443         0.0.0.0/0  ALLOW
  120  TCP  1024-65535  0.0.0.0/0  ALLOW  ← FIX!
  *    All  All         0.0.0.0/0  DENY

Now return traffic can use ephemeral ports
Website works ✅
```

---

### Why This Is Confusing

**Security Groups (stateful) taught you:**

```
"Just allow inbound port 80, return traffic is automatic"

This works! ✅
```

**NACLs (stateless) require:**

```
"Allow inbound port 80 AND outbound ephemeral ports"

Completely different mental model
Easy to forget
Causes production outages
```

---

### NACL Best Practice

**Most teams:**

```
✅ Use Security Groups for security
❌ Leave NACLs at default (allow all)

Reason:
  Security Groups are easier
  Security Groups are stateful
  Security Groups are sufficient for most cases
  
Use NACLs only when you need:
  - Explicit DENY rules (Security Groups can't deny)
  - Subnet-level controls
  - Additional defense layer
```

---

## Common Firewall Scenarios

### Scenario 1: Can't SSH to EC2

**Symptom:**

```bash
ssh user@54.123.45.67
# Hangs, then times out
```

**Debug checklist:**

```
☐ 1. Security Group allows port 22?
     Check inbound rules for TCP port 22
     
☐ 2. Source IP correct?
     Your current IP might have changed
     Rule allows 203.0.113.0/24 but you're 198.51.100.45
     
☐ 3. NACL allows port 22?
     Check subnet's NACL inbound rules
     
☐ 4. NACL allows ephemeral outbound?
     Check NACL outbound for ports 1024-65535
     
☐ 5. Instance actually listening?
     sshd running?
     Correct port?
```

**Common fix:**

```
Security Group inbound:
  SSH (22) from 0.0.0.0/0 (temporary)
  
Test if it works
If yes: Security Group source IP was wrong
Update to your actual IP
```

---

### Scenario 2: Website Times Out

**Symptom:**

```
curl http://54.123.45.67
# Hangs, times out
```

**Debug:**

```
☐ 1. Security Group allows port 80?
     
☐ 2. NACL allows port 80 inbound?
     
☐ 3. NACL allows ephemeral outbound?
     Rule for TCP 1024-65535 outbound
     
☐ 4. Web server running?
     sudo netstat -tlnp | grep :80
     
☐ 5. Web server listening on correct interface?
     0.0.0.0:80 ✅ (all interfaces)
     127.0.0.1:80 ❌ (localhost only)
```

---

### Scenario 3: Database Connection Refused

**Symptom:**

```
App server can't connect to database

Error: Connection refused to 10.0.3.50:5432
```

**Debug:**

```
☐ 1. Database security group allows app server?
     Inbound rule: Port 5432 from sg-app
     
☐ 2. App server has correct security group?
     Instance must be in sg-app
     
☐ 3. Database actually listening?
     On database server:
     sudo netstat -tlnp | grep :5432
     
☐ 4. PostgreSQL listening on correct IP?
     Edit postgresql.conf:
     listen_addresses = '*'  (all interfaces)
     Not: listen_addresses = 'localhost'
```

---

### Scenario 4: Outbound HTTPS Blocked

**Symptom:**

```
Instance can't download packages

curl: (7) Failed to connect to archive.ubuntu.com
```

**Debug:**

```
☐ 1. Security Group allows outbound?
     Usually defaults to allow all
     
☐ 2. NACL allows outbound port 443?
     
☐ 3. NACL allows inbound ephemeral?
     Return traffic needs inbound 1024-65535
     
☐ 4. Route to internet exists?
     Private subnet needs NAT Gateway
     Route table: 0.0.0.0/0 → nat-xxxxx
     
☐ 5. DNS working?
     nslookup archive.ubuntu.com
```

---

## Production Debugging Framework

### Systematic Approach

**When connection fails, debug in this order:**

---

### Step 1: DNS Resolution

```bash
# Can you resolve the domain?
nslookup database.internal
dig api.example.com

If fails:
  - DNS server misconfigured
  - Domain doesn't exist
  - /etc/resolv.conf wrong
```

---

### Step 2: Network Reachability

```bash
# Can you reach the IP?
ping 10.0.3.50

# Note: ICMP might be blocked
# Better test:
telnet 10.0.3.50 5432
nc -zv 10.0.3.50 5432

If fails:
  - Routing issue
  - Firewall blocking
  - Server down
```

---

### Step 3: Port Accessibility

```bash
# Is the port open?
telnet 10.0.3.50 5432

If "Connection refused":
  - Port not listening
  - Service not running
  - Listening on wrong interface

If timeout:
  - Firewall blocking
  - Network issue
```

---

### Step 4: Security Group Check

```bash
# AWS CLI
aws ec2 describe-security-groups \
  --group-ids sg-1234567890abcdef

Check:
  ✅ Inbound rule exists for your port
  ✅ Source allows your IP or security group
  ✅ Protocol matches (TCP vs UDP)
```

---

### Step 5: NACL Check

```bash
# AWS CLI
aws ec2 describe-network-acls \
  --filters "Name=association.subnet-id,Values=subnet-12345"

Check:
  ✅ Inbound allows your port
  ✅ Outbound allows ephemeral ports (1024-65535)
  ✅ Rules in correct order (lower numbers first)
```

---

### Step 6: Application Layer

```bash
# Is service running?
sudo systemctl status postgresql
sudo systemctl status nginx

# Is it listening?
sudo netstat -tlnp | grep :5432

# Check logs
sudo journalctl -u postgresql -n 50
sudo tail -f /var/log/nginx/error.log
```

---

### Decision Tree

```
Connection fails
    │
    ▼
┌─────────────────┐
│ Can resolve DNS?│
└────┬────────────┘
     │
  ┌──┴──┐
 No    Yes
  │     │
  │     ▼
  │  ┌─────────────────┐
  │  │ Can ping/reach? │
  │  └────┬────────────┘
  │       │
  │    ┌──┴──┐
  │   No    Yes
  │    │     │
  │    │     ▼
  │    │  ┌──────────────────┐
  │    │  │ Port accessible? │
  │    │  └────┬─────────────┘
  │    │       │
  │    │    ┌──┴──┐
  │    │   No    Yes
  │    │    │     │
  │    │    │     ▼
  │    │    │  ┌────────────────┐
  │    │    │  │ Service running?│
  │    │    │  └─────────────────┘
  │    │    │
  │    │    └──► Security Group
  │    │         or NACL issue
  │    │
  │    └──► Routing or
  │         firewall issue
  │
  └──► DNS issue
```

---

### Error Messages Guide

| Error | Meaning | Likely Cause |
|-------|---------|--------------|
| **Connection refused** | Port not listening | Service not running, wrong port |
| **Connection timeout** | No response | Firewall blocking, server down |
| **No route to host** | Routing problem | Network misconfigured |
| **Name or service not known** | DNS failure | DNS misconfigured, domain doesn't exist |
| **Network unreachable** | No network path | Routing table missing default route |

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

**Stateful (AWS Security Groups):**
```
✅ Remembers connections
✅ Auto-allows return traffic
✅ Easier to configure

Example:
  Allow inbound port 80
  Return traffic automatically allowed

One rule needed
```

**Stateless (AWS NACLs):**
```
❌ No memory
❌ Must explicitly allow both directions
❌ Harder to configure

Example:
  Allow inbound port 80
  Allow outbound ports 1024-65535 (ephemeral)
  
Two rules needed (both directions)
```

---

### AWS Security Groups

```
Characteristics:
  ✅ Stateful
  ✅ Instance-level
  ✅ Default DENY
  ✅ Only ALLOW rules
  ✅ Can reference other SGs

Use for: Primary instance security
```

---

### AWS NACLs

```
Characteristics:
  ❌ Stateless
  ✅ Subnet-level
  ✅ ALLOW and DENY rules
  ✅ Numbered rules (order matters)

Requirement:
  Must allow ephemeral ports (1024-65535)
  Both inbound AND outbound

Use for: Subnet-level defense (rare)
```

---

### The NACL Trap

```
Common mistake:
  Allow inbound port 80
  Allow outbound port 80
  Forget ephemeral ports

Result:
  Inbound request works
  Response BLOCKED (port 54321 not allowed outbound)
  
Fix:
  Add outbound 1024-65535
  Add inbound 1024-65535
```

---

### Production Debugging Order

```
1. DNS working? (nslookup)
2. Network reachable? (ping, nc)
3. Port open? (telnet, nc -zv)
4. Security Group allows? (AWS console/CLI)
5. NACL allows? (Check ephemeral ports!)
6. Service running? (systemctl, netstat)
```

---

### Common Scenarios

```
"Connection refused" → Service not running
"Connection timeout" → Firewall blocking
"DNS not found" → DNS misconfigured
"Network unreachable" → Routing issue
```

---

### Best Practices

```
✅ Default DENY policy
✅ Principle of least privilege
✅ Use Security Groups (stateful, easier)
✅ Leave NACLs at default (unless specific need)
✅ Document firewall rules
✅ Test after changes
❌ Don't open all ports (0-65535)
❌ Don't use 0.0.0.0/0 for SSH (restrict to office)
```

---

### Mental Model

```
Security Group = Bouncer at door
  Remembers who came in
  Lets them out automatically
  Stateful, smart

NACL = Gate guard
  Checks everyone, both ways
  No memory
  Stateless, strict

Use Security Groups for most security
Use NACLs only when you need DENY rules
```

---

### What You Can Do Now

✅ Understand stateful vs stateless firewalls  
✅ Configure AWS Security Groups correctly  
✅ Avoid the NACL trap (ephemeral ports)  
✅ Debug connectivity issues systematically  
✅ Secure multi-tier applications  
✅ Understand "connection refused" vs "timeout"  
✅ Know when to use Security Groups vs NACLs  

---