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

This file teaches **how domain names are translated into IP addresses** and **how the DNS system works globally**. If you understand this, you'll know why websites sometimes load slowly, how to configure DNS for your applications, and how to debug DNS issues. This is essential for deploying web applications and troubleshooting connectivity.

<!-- no toc -->
- [The Core Problem](#the-core-problem)
- [What Is DNS?](#what-is-dns)
- [How DNS Resolution Works](#how-dns-resolution-works)
- [DNS Record Types](#dns-record-types)
- [DNS Caching](#dns-caching)
- [DNS Servers and Hierarchy](#dns-servers-and-hierarchy)
- [Public DNS Servers](#public-dns-servers)
- [AWS Route 53](#aws-route-53)
- [Docker DNS](#docker-dns)
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

Easy to remember
Meaningful
Pronounceable
```

**Computers need IP addresses:**

```
142.250.190.46
140.82.121.4
151.101.1.69
10.0.1.50

Hard to remember
No meaning to humans
Error-prone
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

**Stanford Research Institute maintained master hosts.txt:**

```
Process:
1. Administrator emails update request
2. SRI manually edits master file
3. Admins download new file periodically
4. Manually deploy to all computers

This broke when internet grew beyond a few hundred hosts.
```

---

### The DNS Solution (1983)

**Distributed, hierarchical, automated system:**

```
✅ No single file to maintain
✅ Automatic lookups
✅ Scales globally
✅ Distributed authority
✅ Caching for speed

Result: Internet could scale to billions of devices
```

---

## What Is DNS?

### Definition

**DNS = Domain Name System**

**Purpose:**  
Translate human-readable domain names into IP addresses that computers use for communication.

**Analogy:**  
DNS is like a phone book for the internet.

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

**No single point of failure:**

```
If one server fails, others continue
Queries distributed globally
Highly redundant
```

---

### DNS Query Flow (Simple View)

```
You type: google.com

1. Your browser: "What's google.com's IP?"
   
2. DNS system: "Let me find out..."
   [Multiple DNS servers queried]
   
3. DNS system: "It's 142.250.190.46"

4. Your browser connects to 142.250.190.46

5. Google's website loads
```

---

## How DNS Resolution Works

### The Complete DNS Query Process

**You type `www.google.com` in browser:**

---

### Step 1: Check Local Cache

```
Browser cache:
  "Have I looked up www.google.com recently?"
  
If cached and not expired:
  Use cached IP (142.250.190.46)
  Done! (milliseconds)
  
If not cached or expired:
  Continue to Step 2
```

---

### Step 2: Check OS Cache

```
Operating system cache:
  "Do I have www.google.com cached?"
  
If cached:
  Return IP to browser
  Done!
  
If not cached:
  Continue to Step 3
```

---

### Step 3: Check /etc/hosts File (Linux/Mac) or C:\Windows\System32\drivers\etc\hosts (Windows)

```
Local hosts file:
  /etc/hosts contains:
  
  127.0.0.1       localhost
  192.168.1.100   myserver.local
  10.0.1.50       database.internal
  
If www.google.com is in this file:
  Use that IP (manual override)
  
Usually not there:
  Continue to Step 4
```

---

### Step 4: Query Recursive DNS Resolver

**Your computer asks configured DNS server:**

```
Your DNS server (configured in network settings):
  8.8.8.8 (Google DNS)
  or
  1.1.1.1 (Cloudflare)
  or
  192.168.1.1 (Router, which forwards to ISP DNS)

Query sent via UDP port 53:
  "What's the IP for www.google.com?"
```

---

### Step 5: Recursive Resolver Checks Its Cache

```
DNS resolver (8.8.8.8):
  "Do I have www.google.com cached?"
  
If cached and not expired:
  Return IP immediately
  Done! (~10-20ms)
  
If not cached:
  Resolver must perform full lookup
  Continue to Step 6
```

---

### Step 6: Root Server Query

**Resolver asks root DNS server:**

```
Recursive resolver → Root server

Query: "Where can I find www.google.com?"

Root server: "I don't know the IP,
              but I know who handles .com domains"
              
Response: "Ask the .com TLD server at 192.5.6.30"

Root server does NOT return IP
Root server returns referral to next level
```

---

### Step 7: TLD Server Query

**Resolver asks .com TLD server:**

```
Recursive resolver → .com TLD server

Query: "Where can I find www.google.com?"

.com server: "I don't know the IP,
              but I know who is authoritative for google.com"
              
Response: "Ask google.com's nameserver at ns1.google.com (216.239.32.10)"
```

---

### Step 8: Authoritative Server Query

**Resolver asks Google's authoritative nameserver:**

```
Recursive resolver → ns1.google.com

Query: "What's the IP for www.google.com?"

Google's nameserver: "Here's the answer!"

Response: "www.google.com = 142.250.190.46"
          "TTL: 300 seconds (5 minutes)"
```

---

### Step 9: Response Chain Back

```
Google's nameserver → Recursive resolver
  "www.google.com = 142.250.190.46"

Recursive resolver caches the answer
  Cache entry: www.google.com → 142.250.190.46 (TTL: 300s)

Recursive resolver → Your computer
  "www.google.com = 142.250.190.46"

Your OS caches the answer
Your browser caches the answer
Your browser connects to 142.250.190.46
```

---

### Visual: Complete DNS Resolution

```
┌──────────────┐
│  Your Browser│
└──────┬───────┘
       │ 1. "What's google.com?"
       ▼
┌──────────────┐
│ Browser Cache│
│ (Not found)  │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│   OS Cache   │
│ (Not found)  │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ /etc/hosts   │
│ (Not found)  │
└──────┬───────┘
       │ 2. UDP query to DNS server
       ▼
┌─────────────────────────┐
│ Recursive Resolver      │
│ (8.8.8.8)               │
│ Check cache: Not found  │
└──────┬──────────────────┘
       │ 3. "Who handles .com?"
       ▼
┌─────────────────────────┐
│ Root DNS Server         │
│ (.)                     │
│ "Ask .com TLD server"   │
└──────┬──────────────────┘
       │ 4. Referral to .com
       ▼
┌─────────────────────────┐
│ TLD Server              │
│ (.com)                  │
│ "Ask google.com's NS"   │
└──────┬──────────────────┘
       │ 5. Referral to google.com
       ▼
┌─────────────────────────┐
│ Authoritative Server    │
│ (ns1.google.com)        │
│ "142.250.190.46"        │
└──────┬──────────────────┘
       │ 6. Answer!
       ▼
┌─────────────────────────┐
│ Recursive Resolver      │
│ Caches answer (5 min)   │
└──────┬──────────────────┘
       │ 7. Return to client
       ▼
┌────────────────┐
│ Your Browser   │
│ Caches answer  │
│ Connects to    │
│ 142.250.190.46 │
└────────────────┘
```

---

### Timing Breakdown

```
First query (cache miss):
  Browser cache:        0ms (miss)
  OS cache:             0ms (miss)
  Recursive resolver:   5ms (query sent)
  Root server:          20ms (referral)
  TLD server:           20ms (referral)
  Authoritative:        25ms (answer)
  Total:                ~70ms

Subsequent queries (cache hit):
  Browser cache:        0ms (hit!)
  Total:                <1ms

This is why first page load feels slower
```

---

## DNS Record Types

### Common Record Types

**DNS stores different types of records:**

---

### A Record (Address)

**Maps domain to IPv4 address:**

```
example.com.        300    IN    A    93.184.216.34

Domain              TTL    Type  Value
```

**Example:**

```
google.com → 142.250.190.46
github.com → 140.82.121.4
```

**Use case:** Most common, points domain to server IP.

---

### AAAA Record (IPv6 Address)

**Maps domain to IPv6 address:**

```
example.com.        300    IN    AAAA    2606:2800:220:1:248:1893:25c8:1946

Domain              TTL    Type    Value (IPv6)
```

**Example:**

```
google.com → 2607:f8b0:4004:c07::71
```

**Use case:** IPv6 addresses (like A record but for IPv6).

---

### CNAME Record (Canonical Name)

**Alias one domain to another:**

```
www.example.com.    300    IN    CNAME    example.com.

Alias               TTL    Type     Target
```

**Example:**

```
www.github.com → github.com
blog.company.com → company.com
```

**How it works:**

```
User looks up: www.example.com
DNS: "www.example.com is a CNAME to example.com"
DNS: "Let me look up example.com"
DNS: "example.com = 93.184.216.34"
User gets: 93.184.216.34

Two lookups required
```

**Use case:** Aliases, subdomains pointing to main domain.

---

### MX Record (Mail Exchange)

**Specifies mail server:**

```
example.com.    300    IN    MX    10 mail.example.com.

Domain          TTL    Type  Priority  Mail server
```

**Example:**

```
gmail.com → MX 5 gmail-smtp-in.l.google.com
```

**Priority (lower = higher priority):**

```
example.com    MX    10    mail1.example.com
example.com    MX    20    mail2.example.com
example.com    MX    30    backup.example.com

Try mail1 first (priority 10)
If unavailable, try mail2 (priority 20)
If unavailable, try backup (priority 30)
```

**Use case:** Email delivery.

---

### TXT Record (Text)

**Arbitrary text data:**

```
example.com.    300    IN    TXT    "v=spf1 include:_spf.google.com ~all"

Domain          TTL    Type   Value (text)
```

**Common uses:**

```
SPF (email security):
  "v=spf1 include:_spf.google.com ~all"

DKIM (email signing):
  "v=DKIM1; k=rsa; p=MIGfMA0GCS..."

Domain verification:
  "google-site-verification=abc123..."

General info:
  "My custom text data"
```

---

### NS Record (Name Server)

**Specifies authoritative DNS servers:**

```
example.com.    300    IN    NS    ns1.example.com.
example.com.    300    IN    NS    ns2.example.com.

Domain          TTL    Type  Nameserver
```

**Example:**

```
google.com → ns1.google.com, ns2.google.com, ns3.google.com
```

**Use case:** Delegates domain to specific DNS servers.

---

### PTR Record (Pointer - Reverse DNS)

**Maps IP address to domain (reverse lookup):**

```
46.190.250.142.in-addr.arpa.    IN    PTR    google.com.

IP (reversed)                   Type   Domain
```

**Example:**

```
Normal (forward):  google.com → 142.250.190.46
Reverse (PTR):     142.250.190.46 → google.com
```

**Use case:** Email servers (anti-spam), verification.

---

### Record Type Summary

| Type | Purpose | Example |
|------|---------|---------|
| **A** | IPv4 address | example.com → 93.184.216.34 |
| **AAAA** | IPv6 address | example.com → 2606:2800:220:... |
| **CNAME** | Alias to another domain | www → example.com |
| **MX** | Mail server | Mail to mail.example.com |
| **TXT** | Text data | SPF, DKIM, verification |
| **NS** | Nameserver | Delegates to ns1.example.com |
| **PTR** | Reverse lookup | IP → domain |

---

## DNS Caching

### Why Caching Exists

**Problem without caching:**

```
Every page load = DNS query
Every image = DNS query  
Every CSS file = DNS query
Every API call = DNS query

100 queries/second × 70ms each = Slow!
```

**Solution: Cache results**

```
First query: 70ms (full lookup)
Next 299 seconds: <1ms (cached)

Massive speed improvement
Reduces DNS server load
```

---

### Caching Layers

**Multiple levels of caching:**

```
1. Browser cache
   Duration: Varies (usually respects TTL)
   Scope: That browser only

2. Operating system cache
   Duration: Varies by OS
   Scope: All applications on that computer

3. Recursive resolver cache (ISP, Google, Cloudflare)
   Duration: TTL specified in DNS record
   Scope: All users of that resolver

4. Authoritative server (doesn't cache queries)
   Source of truth
```

---

### TTL (Time To Live)

**TTL = How long to cache the record**

**Format:**

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
❌ Higher DNS server load
```

**Long TTL (86400 seconds):**

```
✅ Fewer DNS queries
✅ Lower DNS server load
✅ Better performance
❌ Changes take 24 hours to propagate
❌ Bad for migrations
```

**Best practice:**

```
Normal operation: Long TTL (3600-86400s)
Before changes:   Reduce TTL (60-300s)
After changes:    Restore long TTL
```

---

### DNS Propagation

**"DNS propagation" = cache expiration worldwide**

**Scenario: Change IP address**

```
Old record:
  example.com → 1.2.3.4 (TTL: 3600s)

Change DNS:
  example.com → 5.6.7.8

Propagation time:
  0-3600 seconds (up to 1 hour)
  
Some users see old IP (cached)
Some users see new IP (cache expired, queried again)

After TTL expires everywhere:
  All users see new IP
```

**This is why:**

```
Reduce TTL before changes:
  example.com → 1.2.3.4 (TTL: 60s)

Wait for old TTL to expire:
  Wait 1 hour (old 3600s TTL)

Make change:
  example.com → 5.6.7.8 (TTL: 60s)

Propagates in 60 seconds
  Much faster!

After change complete:
  example.com → 5.6.7.8 (TTL: 3600s)
```

---

### Flush DNS Cache

**Clear cached DNS entries:**

**Windows:**

```cmd
ipconfig /flushdns

Output:
Successfully flushed the DNS Resolver Cache.
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

**Linux (nscd):**

```bash
sudo /etc/init.d/nscd restart
```

**Why flush cache:**

```
✅ Testing DNS changes
✅ Debugging DNS issues
✅ Forcing fresh DNS lookup
✅ Resolving stale cache problems
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
        │           │           │
    ┌───┴───┐       │       ┌───┴───┐
 google.com │  wikipedia    │ github
            │     .org      │  .net
        example             │
         .com          cloudflare
                         .net
```

---

### Root DNS Servers

**13 root server clusters (labeled A-M):**

```
a.root-servers.net
b.root-servers.net
c.root-servers.net
...
m.root-servers.net

Note: "13" is logical, not physical
Actually hundreds of servers worldwide
Anycast routing to nearest instance
```

**Root servers know:**

```
✅ All TLD servers (.com, .org, .net, .uk, etc.)
❌ NOT individual domains (google.com, etc.)

Job: Delegate to TLD servers
```

---

### TLD Servers

**Top-Level Domain servers:**

```
Generic TLDs (gTLD):
  .com, .org, .net, .info, .biz, etc.

Country code TLDs (ccTLD):
  .us, .uk, .de, .jp, .au, etc.

New TLDs:
  .io, .dev, .app, .cloud, .tech, etc.
```

**TLD servers know:**

```
✅ All authoritative nameservers for domains under that TLD
   (e.g., .com server knows google.com's nameservers)
❌ NOT actual IP addresses

Job: Delegate to authoritative servers
```

---

### Authoritative DNS Servers

**Final authority for a domain:**

```
Google's authoritative servers:
  ns1.google.com
  ns2.google.com
  ns3.google.com
  ns4.google.com

These servers contain:
  ✅ Actual DNS records (A, AAAA, CNAME, etc.)
  ✅ Authoritative answers
  
Job: Provide final answers
```

---

### Recursive Resolvers

**Do the heavy lifting:**

```
Examples:
  Google Public DNS: 8.8.8.8, 8.8.4.4
  Cloudflare: 1.1.1.1, 1.0.0.1
  Quad9: 9.9.9.9
  ISP DNS: Varies

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

IPv6:
Primary:   2001:4860:4860::8888
Secondary: 2001:4860:4860::8844

Features:
✅ Fast
✅ Reliable
✅ No filtering
❌ Google logs queries
```

**Cloudflare DNS:**

```
Primary:   1.1.1.1
Secondary: 1.0.0.1

IPv6:
Primary:   2606:4700:4700::1111
Secondary: 2606:4700:4700::1001

Features:
✅ Very fast (often fastest)
✅ Privacy-focused (claims not to log)
✅ No filtering by default
✅ Malware blocking available (1.1.1.2)
```

**Quad9:**

```
Primary:   9.9.9.9
Secondary: 149.112.112.112

Features:
✅ Blocks malicious domains
✅ Privacy-focused
✅ Threat intelligence
```

**OpenDNS (Cisco):**

```
Primary:   208.67.222.222
Secondary: 208.67.220.220

Features:
✅ Content filtering
✅ Malware blocking
✅ Customizable
```

---

### Configure DNS Servers

**Linux (systemd-resolved):**

```bash
# Edit /etc/systemd/resolved.conf
[Resolve]
DNS=1.1.1.1 8.8.8.8
FallbackDNS=1.0.0.1 8.8.4.4

# Restart
sudo systemctl restart systemd-resolved
```

**Linux (old method):**

```bash
# Edit /etc/resolv.conf
nameserver 1.1.1.1
nameserver 8.8.8.8
```

**Mac:**

```
System Preferences → Network
Select connection → Advanced
DNS tab → Add DNS servers
  1.1.1.1
  8.8.8.8
```

**Windows:**

```
Control Panel → Network Connections
Right-click adapter → Properties
Internet Protocol Version 4 → Properties
Use the following DNS server addresses:
  Preferred:  1.1.1.1
  Alternate:  8.8.8.8
```

---

### Why Use Public DNS

**Reasons to switch from ISP DNS:**

```
✅ Often faster
✅ More reliable
✅ Better privacy (some providers)
✅ Malware/ad blocking (some providers)
✅ Bypass ISP DNS hijacking
✅ Access blocked content (sometimes)
```

---

## AWS Route 53

### What Is Route 53?

**Amazon's DNS service:**

```
Features:
✅ Authoritative DNS hosting
✅ Domain registration
✅ Health checks & failover
✅ Traffic routing policies
✅ Integration with AWS services
✅ 100% uptime SLA

Name: "Route 53"
  Why 53? DNS uses port 53
```

---

### Route 53 Use Cases

**Hosted zones:**

```
Create hosted zone for: example.com

Add records:
  example.com        A      93.184.216.34
  www.example.com    CNAME  example.com
  api.example.com    A      54.123.45.67
  *.example.com      A      93.184.216.34 (wildcard)
```

**Point domain to AWS resources:**

```
example.com → CloudFront distribution
  Uses alias record (AWS-specific)

api.example.com → Application Load Balancer
  Uses alias record

db.example.com → RDS instance endpoint
  Uses CNAME
```

---

### Route 53 Routing Policies

**Simple routing:**

```
example.com → 93.184.216.34

One record, one IP
Standard DNS
```

**Weighted routing:**

```
example.com → 93.184.216.34 (70% weight)
example.com → 54.123.45.67  (30% weight)

70% of traffic → Server 1
30% of traffic → Server 2

Use case: A/B testing, gradual migrations
```

**Latency-based routing:**

```
example.com → 93.184.216.34 (US East)
example.com → 54.123.45.67  (EU West)
example.com → 203.45.67.89  (Asia Pacific)

Users routed to lowest-latency endpoint
Use case: Global applications
```

**Failover routing:**

```
Primary:   93.184.216.34 (health checked)
Secondary: 54.123.45.67  (backup)

If primary fails health check:
  Route to secondary

Use case: High availability
```

**Geolocation routing:**

```
US users → 93.184.216.34 (US server)
EU users → 54.123.45.67  (EU server)
Default  → 203.45.67.89  (global server)

Based on user's geographic location
Use case: Content localization, compliance
```

---

### Route 53 Terraform Example

```hcl
# Create hosted zone
resource "aws_route53_zone" "main" {
  name = "example.com"
  
  tags = {
    Environment = "production"
  }
}

# A record (domain to IP)
resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "www.example.com"
  type    = "A"
  ttl     = 300
  records = ["93.184.216.34"]
}

# Alias record (domain to ALB)
resource "aws_route53_record" "api" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "api.example.com"
  type    = "A"
  
  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}

# MX record (email)
resource "aws_route53_record" "mx" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "example.com"
  type    = "MX"
  ttl     = 300
  records = [
    "10 mail1.example.com",
    "20 mail2.example.com"
  ]
}
```

---

## Docker DNS

### Docker's Built-in DNS

**Docker provides automatic DNS:**

```
Containers on same network can reach each other by name

No manual IP management needed
```

---

### How Docker DNS Works

**Create network and containers:**

```bash
# Create network
docker network create myapp

# Run containers
docker run -d --name web --network myapp nginx
docker run -d --name api --network myapp node-app
docker run -d --name db --network myapp postgres
```

**Container DNS resolution:**

```
Inside 'web' container:

ping api
  → Resolves to api container's IP (172.20.0.3)

ping db
  → Resolves to db container's IP (172.20.0.4)

curl http://api:3000
  → Connects to api container

psql -h db -U postgres
  → Connects to db container
```

---

### Docker DNS Server

**Docker runs embedded DNS server:**

```
Default Docker DNS: 127.0.0.11
Port: 53

Check inside container:
  cat /etc/resolv.conf
  
  Output:
  nameserver 127.0.0.11
  options ndots:0
```

**DNS resolution order:**

```
1. Check if name is container name on same network
   → If yes, return container's IP

2. If not container name, forward to host DNS
   → Use host's DNS servers (8.8.8.8, etc.)
```

---

### Docker DNS Examples

**Application configuration:**

```yaml
# docker-compose.yml
version: '3'

services:
  web:
    image: nginx
    networks:
      - frontend
      
  api:
    image: node-app
    networks:
      - frontend
      - backend
    environment:
      DB_HOST: db        # Uses DNS name
      DB_PORT: 5432
      
  db:
    image: postgres
    networks:
      - backend

networks:
  frontend:
  backend:
```

**Inside 'api' container:**

```javascript
// Connect to database using DNS name
const dbConfig = {
  host: 'db',           // DNS resolves to postgres container
  port: 5432,
  user: 'postgres',
  password: 'password',
  database: 'myapp'
};

// HTTP request to another service
fetch('http://web/health')
  .then(res => res.json());
```

---

### Docker DNS Limitations

**DNS only works within networks:**

```
❌ Containers on different networks cannot resolve by name
✅ Containers on same network can resolve by name

Solution: Connect container to multiple networks if needed
```

**Example:**

```bash
# web and api on 'frontend' network
# api and db on 'backend' network

web can resolve: api ✅
web cannot resolve: db ❌ (different network)

api can resolve: web ✅ (same network: frontend)
api can resolve: db ✅ (same network: backend)
```

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

Uses 1.1.1.1 instead of default DNS server
```

**Query specific record type:**

```bash
nslookup -type=MX google.com

Output:
google.com      mail exchanger = 10 smtp.google.com.
```

---

### dig (More detailed)

**Basic query:**

```bash
dig google.com

Output:
; <<>> DiG 9.10.6 <<>> google.com
;; ANSWER SECTION:
google.com.             300     IN      A       142.250.190.46

;; Query time: 23 msec
;; SERVER: 8.8.8.8#53(8.8.8.8)
;; WHEN: Tue Mar 10 12:00:00 PST 2026
;; MSG SIZE  rcvd: 55
```

**Short format:**

```bash
dig google.com +short

Output:
142.250.190.46
```

**Query specific DNS server:**

```bash
dig @1.1.1.1 google.com

Uses Cloudflare DNS
```

**Trace full resolution path:**

```bash
dig +trace google.com

Shows:
  Root servers
  .com TLD servers
  google.com authoritative servers
  Final answer

Great for debugging DNS delegation
```

**Query specific record type:**

```bash
dig MX google.com
dig AAAA google.com
dig TXT google.com
dig NS google.com
```

---

### host

**Simple lookup:**

```bash
host google.com

Output:
google.com has address 142.250.190.46
google.com has IPv6 address 2607:f8b0:4004:c07::71
google.com mail is handled by 10 smtp.google.com.
```

**Reverse lookup:**

```bash
host 142.250.190.46

Output:
46.190.250.142.in-addr.arpa domain name pointer lga34s32-in-f14.1e100.net.
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

Compare to expected IP
If wrong IP:
  - DNS cache stale (flush cache)
  - DNS propagation in progress
  - Wrong DNS record configured
```

**Step 3: Can you reach the IP?**

```bash
ping 93.184.216.34

If fails:
  - Firewall blocking
  - Server down
  - Network routing issue
  
If succeeds:
  - DNS working
  - Problem is application-level
```

**Step 4: Check from different DNS servers**

```bash
dig @8.8.8.8 example.com
dig @1.1.1.1 example.com
dig @9.9.9.9 example.com

If different results:
  - DNS propagation issue
  - Different cache states
```

**Step 5: Trace full path**

```bash
dig +trace example.com

Shows entire resolution path
Helps identify where delegation breaks
```

---

### Common DNS Issues

**Issue 1: NXDOMAIN (Domain doesn't exist)**

```
Error: NXDOMAIN

Causes:
  - Typo in domain name
  - Domain not registered
  - DNS record not created
  
Fix:
  - Check spelling
  - Verify domain ownership
  - Create DNS records
```

**Issue 2: Timeout**

```
Error: Query timeout

Causes:
  - DNS server unreachable
  - Firewall blocking port 53
  - Network connectivity issue
  
Fix:
  - Try different DNS server
  - Check firewall rules
  - Verify network connectivity
```

**Issue 3: Wrong IP returned**

```
Expected: 93.184.216.34
Got:      1.2.3.4

Causes:
  - Stale cache
  - Wrong DNS record
  - DNS hijacking (ISP)
  
Fix:
  - Flush DNS cache
  - Verify authoritative record
  - Use public DNS (8.8.8.8)
```

**Issue 4: Slow resolution**

```
Query time: 5000 msec (5 seconds!)

Causes:
  - Slow DNS server
  - Network latency
  - DNS server overloaded
  
Fix:
  - Switch to faster DNS (1.1.1.1)
  - Check network latency
  - Investigate DNS server health
```

---

## Real Scenarios

### Scenario 1: Website Migration

**Moving from old server to new:**

```
Current:
  example.com → 1.2.3.4 (old server)
  TTL: 3600s (1 hour)

Goal:
  example.com → 5.6.7.8 (new server)

Process:
  Day -1: Reduce TTL
    example.com → 1.2.3.4 (TTL: 60s)
    Wait 1 hour for old TTL to expire
    
  Day 0: Make change
    example.com → 5.6.7.8 (TTL: 60s)
    Propagates in 60 seconds
    Monitor both servers
    
  Day +1: Restore TTL
    example.com → 5.6.7.8 (TTL: 3600s)
    Migration complete
```

---

### Scenario 2: Multi-Region Application

**AWS Route 53 latency routing:**

```
example.com configured with latency-based routing:

Record 1:
  IP: 54.123.45.67
  Region: us-east-1
  
Record 2:
  IP: 52.10.20.30
  Region: eu-west-1
  
Record 3:
  IP: 13.45.67.89
  Region: ap-southeast-1

User in New York:
  DNS returns 54.123.45.67 (us-east-1, lowest latency)
  
User in London:
  DNS returns 52.10.20.30 (eu-west-1, lowest latency)
  
User in Singapore:
  DNS returns 13.45.67.89 (ap-southeast-1, lowest latency)
```

---

### Scenario 3: Docker Microservices

```yaml
# docker-compose.yml
services:
  frontend:
    image: react-app
    environment:
      API_URL: http://api:3000    # DNS name

  api:
    image: node-api
    environment:
      DB_HOST: database            # DNS name
      CACHE_HOST: redis            # DNS name
      
  database:
    image: postgres
    
  redis:
    image: redis
```

**DNS resolution:**

```
frontend container:
  Requests http://api:3000
  Docker DNS: api → 172.20.0.3
  Connection succeeds

api container:
  Connects to database:5432
  Docker DNS: database → 172.20.0.4
  Connection succeeds
  
  Connects to redis:6379
  Docker DNS: redis → 172.20.0.5
  Connection succeeds

All service discovery automatic via DNS
```

---

## Final Compression

### What Is DNS?

```
DNS = Phone book for the internet

Domain name → IP address
  google.com → 142.250.190.46

Why it exists:
  Humans remember names
  Computers need IPs
```

---

### DNS Resolution Process

```
1. Check browser cache
2. Check OS cache
3. Check /etc/hosts
4. Query recursive resolver (8.8.8.8)
5. Resolver checks its cache
6. If not cached:
   - Query root server
   - Query TLD server (.com)
   - Query authoritative server
7. Return answer
8. Cache at all levels
```

---

### DNS Record Types (Essential)

```
A      - Domain to IPv4 (google.com → 142.250.190.46)
AAAA   - Domain to IPv6
CNAME  - Alias (www → example.com)
MX     - Mail server
TXT    - Text data (SPF, verification)
NS     - Nameserver delegation
```

---

### TTL (Time To Live)

```
How long to cache the record

60s     - Short (migrations)
300s    - Common default
3600s   - Standard (1 hour)
86400s  - Long (24 hours)

Lower TTL = Faster changes, more queries
Higher TTL = Slower changes, fewer queries
```

---

### DNS Hierarchy

```
Root (.)
  └─ TLD (.com, .org, .net)
      └─ Domain (google.com)
          └─ Subdomain (www.google.com)

Root knows TLD servers
TLD knows authoritative servers
Authoritative has actual records
```

---

### Public DNS Servers

```
Google:     8.8.8.8, 8.8.4.4
Cloudflare: 1.1.1.1, 1.0.0.1
Quad9:      9.9.9.9

Use instead of ISP DNS for:
  - Speed
  - Reliability
  - Privacy
```

---

### Docker DNS

```
Containers on same network:
  Can resolve each other by name
  
Example:
  web container → api container
  Uses name: http://api:3000
  Docker DNS resolves automatically
```

---

### DNS Debugging

```
nslookup google.com     - Basic lookup
dig google.com          - Detailed lookup
dig +trace google.com   - Full path trace
host google.com         - Simple lookup

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
  
Answer:
  "142.250.190.46"
  
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
✅ Use Docker DNS for service discovery  
✅ Configure AWS Route 53  
✅ Plan DNS changes with TTL reduction  

---