# File 08: DNS

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

# DNS (Domain Name System)

## What this file is about

This file teaches **how domain names are translated into IP addresses** and **how the DNS system works globally**. If you understand this, you'll know why websites sometimes load slowly, how caching and TTL affect changes, and how to debug DNS issues. How Docker and AWS implement DNS on top of these concepts is covered in their respective notes.

<!-- no toc -->
- [The Core Problem](#the-core-problem)
- [What Is DNS?](#what-is-dns)
- [How DNS Resolution Works](#how-dns-resolution-works)
- [DNS Record Types](#dns-record-types)
- [DNS Caching](#dns-caching)
- [DNS Servers and Hierarchy](#dns-servers-and-hierarchy)
- [Public DNS Servers](#public-dns-servers)
- [DNS Debugging](#dns-debugging)  
[Final Compression](#final-compression)

---

## The Core Problem

### The Human vs Computer Challenge

**Humans prefer names:**

```
google.com
github.com
stackoverflow.com
mycompany.internal
```

**Computers need IP addresses:**

```
142.250.190.46
140.82.121.4
151.101.1.69
10.0.1.50
```

**The problem:** How do we bridge this gap?

---

### Before DNS (The Dark Ages)

**1970s-1980s: hosts.txt file**

```
Every computer had a file: /etc/hosts

Contents:
10.1.1.5    server1
10.1.1.6    server2
10.1.1.7    database

Problem:
  - Manual updates
  - No central authority
  - Didn't scale
  - File grew huge
```

**Stanford Research Institute maintained master hosts.txt — this broke when internet grew beyond a few hundred hosts.**

---

### The DNS Solution (1983)

**Distributed, hierarchical, automated system:**

```
✅ No single file to maintain
✅ Automatic lookups
✅ Scales globally
✅ Distributed authority
✅ Caching for speed
```

---

## What Is DNS?

### Definition

**DNS = Domain Name System**

**Purpose:** Translate human-readable domain names into IP addresses.

**Analogy:** DNS is like a phone book for the internet.

```
Phone book:
  Name: "Pizza Place" → Phone: 555-1234

DNS:
  Domain: google.com → IP: 142.250.190.46
```

---

### DNS Is a Distributed Database

**Not one server, but millions:**

```
Root DNS servers:        13 worldwide
Top-level domain (TLD):  Hundreds (.com, .org, .uk, etc.)
Authoritative servers:   Millions (each domain has one)
Recursive resolvers:     Thousands (ISPs, Google, Cloudflare)
```

---

## How DNS Resolution Works

### The Complete DNS Query Process

**You type `www.google.com` in browser:**

---

### Step 1: Check Local Cache

```
Browser: "Have I looked up www.google.com recently?"

If cached and not expired:
  Use cached IP
  Done! (milliseconds)
```

---

### Step 2: Check OS Cache

```
Operating system cache check

If cached:
  Return IP to browser
  Done!
```

---

### Step 3: Check /etc/hosts File

```
/etc/hosts contains:
  127.0.0.1       localhost
  192.168.1.100   myserver.local

If www.google.com is in this file:
  Use that IP (manual override)
```

---

### Step 4: Query Recursive DNS Resolver

**Your computer asks configured DNS server:**

```
Your DNS server (configured in network settings):
  8.8.8.8 (Google DNS)
  or 1.1.1.1 (Cloudflare)
  or 192.168.1.1 (Router)

Query sent via UDP port 53:
  "What's the IP for www.google.com?"
```

---

### Step 5-8: Root → TLD → Authoritative → Answer

```
Recursive resolver → Root server
  "I don't know, but .com TLD is at 192.5.6.30"

Recursive resolver → .com TLD server
  "I don't know, but google.com's NS is ns1.google.com"

Recursive resolver → ns1.google.com
  "www.google.com = 142.250.190.46" ← Final answer

Resolver caches result (TTL: 300s)
Returns to your browser
```

---

### Visual: Complete DNS Resolution

```
┌──────────────┐
│  Your Browser│
└──────┬───────┘
       │ 1. "What's google.com?"
       ▼
┌──────────────────────────┐
│ Browser Cache → OS Cache │
│ /etc/hosts → All miss    │
└──────┬───────────────────┘
       │ 2. UDP query to DNS server
       ▼
┌─────────────────────────┐
│ Recursive Resolver      │
│ (8.8.8.8) — cache miss  │
└──────┬──────────────────┘
       │ 3. Root servers
       │ 4. .com TLD
       │ 5. google.com NS
       ▼
┌─────────────────────────┐
│ Authoritative Server    │
│ (ns1.google.com)        │
│ "142.250.190.46"        │
└──────┬──────────────────┘
       │ 6. Answer returned + cached
       ▼
┌────────────────┐
│ Your Browser   │
│ Connects to    │
│ 142.250.190.46 │
└────────────────┘
```

---

### Timing Breakdown

```
First query (cache miss):   ~70ms total
Subsequent queries (hit):   <1ms (cached)

This is why first page load feels slower.
```

---

## DNS Record Types

### Common Record Types

---

### A Record (Address)

**Maps domain to IPv4 address:**

```
google.com.        300    IN    A    142.250.190.46
```

**Use case:** Most common, points domain to server IP.

---

### AAAA Record (IPv6 Address)

**Maps domain to IPv6 address:**

```
google.com.    300    IN    AAAA    2607:f8b0:4004:c07::71
```

---

### CNAME Record (Canonical Name)

**Alias one domain to another:**

```
www.example.com.    300    IN    CNAME    example.com.
```

**Use case:** Aliases, subdomains pointing to main domain.

---

### MX Record (Mail Exchange)

**Specifies mail server:**

```
example.com.    300    IN    MX    10 mail.example.com.
```

**Priority:** Lower number = higher priority.

---

### TXT Record (Text)

**Arbitrary text data:**

```
example.com.    300    IN    TXT    "v=spf1 include:_spf.google.com ~all"
```

**Common uses:** SPF, DKIM, domain verification.

---

### NS Record (Name Server)

**Specifies authoritative DNS servers:**

```
google.com.    300    IN    NS    ns1.google.com.
```

---

### PTR Record (Pointer — Reverse DNS)

**Maps IP address to domain:**

```
46.190.250.142.in-addr.arpa.    IN    PTR    google.com.
```

**Use case:** Email servers (anti-spam), verification.

---

### Record Type Summary

| Type | Purpose | Example |
|------|---------|---------|
| **A** | IPv4 address | example.com → 93.184.216.34 |
| **AAAA** | IPv6 address | example.com → 2606:... |
| **CNAME** | Alias | www → example.com |
| **MX** | Mail server | Mail to mail.example.com |
| **TXT** | Text data | SPF, DKIM, verification |
| **NS** | Nameserver | Delegates to ns1.example.com |
| **PTR** | Reverse lookup | IP → domain |

---

## DNS Caching

### Why Caching Exists

**Without caching:**

```
Every page load = DNS query = 70ms overhead
100 queries/second = slow
```

**With caching:**

```
First query: 70ms (full lookup)
Next 299 seconds: <1ms (cached)
```

---

### Caching Layers

```
1. Browser cache          — respects TTL
2. Operating system cache — respects TTL
3. Recursive resolver     — respects TTL (all users benefit)
4. Authoritative server   — source of truth (doesn't cache)
```

---

### TTL (Time To Live)

**TTL = How long to cache the record**

```
example.com.    300    IN    A    93.184.216.34
                └─┘
                TTL (seconds)

300 seconds = 5 minutes
```

**Common TTL values:**

```
60 seconds    - Frequently changing (during migrations)
300 seconds   - Common default (5 minutes)
3600 seconds  - Standard (1 hour)
86400 seconds - Long-term stable (24 hours)
```

---

### TTL Impact

**Short TTL (60 seconds):**

```
✅ Changes propagate quickly
✅ Good for deployments/migrations
❌ More DNS queries
```

**Long TTL (86400 seconds):**

```
✅ Fewer queries, better performance
❌ Changes take 24 hours to propagate
```

**Best practice:**

```
Normal operation:  Long TTL (3600-86400s)
Before changes:    Reduce TTL (60-300s)
After changes:     Restore long TTL
```

---

### DNS Propagation

**"DNS propagation" = cache expiration worldwide**

```
Old record: example.com → 1.2.3.4 (TTL: 3600s)
Change to:  example.com → 5.6.7.8

Propagation time: up to 1 hour (old TTL)

Best practice: Reduce TTL to 60s first, wait for old TTL to expire,
then make the change. Propagates in 60 seconds.
```

---

### Flush DNS Cache

**Windows:**
```cmd
ipconfig /flushdns
```

**Mac:**
```bash
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder
```

**Linux (systemd-resolved):**
```bash
sudo systemd-resolve --flush-caches
```

---

## DNS Servers and Hierarchy

### The DNS Hierarchy

```
                    . (Root)
                    │
        ┌───────────┼───────────┐
        │           │           │
       .com        .org        .net  (TLDs)
        │
    ┌───┴───┐
 google.com  example.com
```

---

### Root DNS Servers

**13 root server clusters (labeled A-M):**

```
a.root-servers.net ... m.root-servers.net

Actually hundreds of servers worldwide
Anycast routing to nearest instance
```

**Root servers know:** All TLD servers. NOT individual domains.

---

### TLD Servers

**Top-Level Domain servers:**

```
Generic TLDs: .com, .org, .net, .info
Country code: .us, .uk, .de, .jp
New TLDs:     .io, .dev, .app, .cloud
```

**TLD servers know:** Authoritative nameservers for domains under that TLD. NOT actual IPs.

---

### Authoritative DNS Servers

**Final authority for a domain:**

```
Google's authoritative servers:
  ns1.google.com, ns2.google.com, ns3.google.com, ns4.google.com

These contain the actual DNS records.
```

---

### Recursive Resolvers

**Do the heavy lifting:**

```
Examples:
  Google Public DNS: 8.8.8.8, 8.8.4.4
  Cloudflare: 1.1.1.1, 1.0.0.1

Job:
  1. Receive query from client
  2. Query root → TLD → authoritative
  3. Cache the result
  4. Return answer to client
```

---

## Public DNS Servers

### Popular Public DNS Providers

**Google Public DNS:**

```
Primary:   8.8.8.8
Secondary: 8.8.4.4

✅ Fast and reliable
❌ Google logs queries
```

**Cloudflare DNS:**

```
Primary:   1.1.1.1
Secondary: 1.0.0.1

✅ Often fastest
✅ Privacy-focused
✅ Malware blocking available (1.1.1.2)
```

**Quad9:**

```
Primary:   9.9.9.9
Secondary: 149.112.112.112

✅ Blocks malicious domains
✅ Privacy-focused
```

---

### Configure DNS Servers

**Linux (systemd-resolved):**

```bash
# Edit /etc/systemd/resolved.conf
[Resolve]
DNS=1.1.1.1 8.8.8.8
FallbackDNS=1.0.0.1 8.8.4.4

sudo systemctl restart systemd-resolved
```

**Linux (old method):**

```bash
# Edit /etc/resolv.conf
nameserver 1.1.1.1
nameserver 8.8.8.8
```

---

### Why Use Public DNS

```
✅ Often faster
✅ More reliable
✅ Better privacy (some providers)
✅ Malware/ad blocking (some providers)
✅ Bypass ISP DNS hijacking
```

---

> **Docker implementation:** Docker runs an embedded DNS server at `127.0.0.11` on every custom network. Containers resolve each other by name automatically — no manual IP management needed. The full DNS setup with verification commands is in the Docker notes.
> → [Docker Networking](../../04.%20Docker%20–%20Containerization/05-docker-networking/README.md)

> **AWS implementation:** AWS Route 53 is a globally distributed DNS service with routing policies (latency, weighted, failover, geolocation), health checks, and tight AWS integration. The full Route 53 setup with Terraform examples is in the AWS notes.
> → [AWS Route 53](../../06.%20AWS%20–%20Cloud%20Infrastructure/13-route53/README.md)

---

## DNS Debugging

### Common DNS Tools

---

### nslookup

**Basic DNS lookup:**

```bash
nslookup google.com

Output:
Server:         8.8.8.8
Address:        8.8.8.8#53

Non-authoritative answer:
Name:   google.com
Address: 142.250.190.46
```

**Query specific DNS server:**

```bash
nslookup google.com 1.1.1.1
```

**Query specific record type:**

```bash
nslookup -type=MX google.com
```

---

### dig (More detailed)

**Basic query:**

```bash
dig google.com

;; ANSWER SECTION:
google.com.    300    IN    A    142.250.190.46

;; Query time: 23 msec
;; SERVER: 8.8.8.8#53
```

**Short format:**

```bash
dig google.com +short
```

**Trace full resolution path:**

```bash
dig +trace google.com
```

**Query specific record type:**

```bash
dig MX google.com
dig AAAA google.com
dig TXT google.com
dig NS google.com
```

---

### Debugging Workflow

**Step 1: Can you resolve the name?**

```bash
nslookup example.com

If fails:
  - DNS server unreachable
  - Domain doesn't exist
  - Network issue
```

**Step 2: What IP did it resolve to?**

```bash
dig example.com +short

If wrong IP:
  - DNS cache stale (flush cache)
  - DNS propagation in progress
  - Wrong DNS record configured
```

**Step 3: Can you reach the IP?**

```bash
ping 93.184.216.34

If fails → Firewall or network issue
If succeeds → DNS is fine, problem is application-level
```

**Step 4: Check from different DNS servers**

```bash
dig @8.8.8.8 example.com
dig @1.1.1.1 example.com

If different results → DNS propagation issue
```

**Step 5: Trace full path**

```bash
dig +trace example.com
```

---

### Common DNS Issues

**Issue 1: NXDOMAIN**
```
Causes: Typo in domain, domain not registered, record not created
Fix: Check spelling, verify domain ownership, create DNS records
```

**Issue 2: Timeout**
```
Causes: DNS server unreachable, firewall blocking port 53
Fix: Try different DNS server, check firewall rules
```

**Issue 3: Wrong IP returned**
```
Causes: Stale cache, wrong DNS record, DNS hijacking
Fix: Flush DNS cache, verify authoritative record, use public DNS
```

**Issue 4: Slow resolution**
```
Causes: Slow DNS server, network latency
Fix: Switch to faster DNS (1.1.1.1)
```

---

## Final Compression

### What Is DNS?

```
DNS = Phone book for the internet

Domain name → IP address
  google.com → 142.250.190.46
```

---

### DNS Resolution Process

```
1. Check browser cache
2. Check OS cache
3. Check /etc/hosts
4. Query recursive resolver (8.8.8.8)
5. Resolver: root → TLD → authoritative
6. Return answer
7. Cache at all levels
```

---

### DNS Record Types (Essential)

```
A      - Domain to IPv4
AAAA   - Domain to IPv6
CNAME  - Alias (www → example.com)
MX     - Mail server
TXT    - Text data (SPF, verification)
NS     - Nameserver delegation
```

---

### TTL (Time To Live)

```
60s     - Short (migrations)
300s    - Common default
3600s   - Standard (1 hour)
86400s  - Long (24 hours)

Lower TTL = Faster changes, more queries
Higher TTL = Slower changes, fewer queries
```

---

### Public DNS Servers

```
Google:     8.8.8.8, 8.8.4.4
Cloudflare: 1.1.1.1, 1.0.0.1
Quad9:      9.9.9.9
```

---

### DNS Debugging

```
nslookup google.com     - Basic lookup
dig google.com          - Detailed lookup
dig +trace google.com   - Full path trace

Flush cache:
  Windows: ipconfig /flushdns
  Mac:     sudo killall -HUP mDNSResponder
  Linux:   sudo systemd-resolve --flush-caches
```

---

### Mental Model

```
DNS = Global distributed database

Your query:
  "What's google.com?"

DNS journey:
  Your computer → Resolver → Root → TLD → Authoritative
  
Answer: "142.250.190.46"
Cached everywhere for speed
Expires after TTL
```

---

### What You Can Do Now

✅ Understand how DNS resolution works  
✅ Know common DNS record types  
✅ Configure public DNS servers  
✅ Debug DNS issues with dig/nslookup  
✅ Understand DNS caching and TTL  
✅ Plan DNS changes with TTL reduction  

---
