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
→ Ready to practice? [Go to Lab 04](../networking-labs/04-dns-firewalls-lab.md)
