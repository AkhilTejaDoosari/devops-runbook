[Foundation](01-foundation-and-the-big-picture/README.md) |
[Addressing](02-addressing-fundamentals/README.md) |
[IP Deep Dive](03-ip-deep-dive/README.md) |
[Network Devices](04-network-devices/README.md) |
[Subnets & CIDR](05-subnets-cidr/README.md) |
[Ports & Transport](06-ports-transport/README.md) |
[NAT](07-nat/README.md) |
[DNS](08-dns/README.md) |
[Firewalls](09-firewalls/README.md) |
[Complete Journey](10-complete-journey/README.md)

# Networking Fundamentals for DevOps Engineers

A comprehensive, no-BS networking guide built for cloud support, DevOps, and cloud engineering roles. Learn networking through practical examples and real-world scenarios.

## Why This Series Exists

Most networking tutorials either:
- Start with OSI theory (boring, abstract)
- Focus on CCNA certification (irrelevant for DevOps)
- Assume you already know networking (unhelpful)

This series teaches networking **the way DevOps engineers actually use it**: Docker containers, AWS VPCs, debugging production issues, and building infrastructure.

## What Makes This Different

**Zero to production-ready in 10 files:**
- Starts with physical reality (cables, packets, encapsulation)
- Builds concepts in dependency order (can't learn subnets before routers)
- Uses real scenarios (AWS, Docker, actual debugging)
- Explains WHY things exist, not just definitions
- No certification fluff, only practical knowledge

## The Series

### Core Foundation
**[01. Foundation & The Big Picture](01-foundation-and-the-big-picture/README.md)**  
What networking actually is. History (ARPANET), physical infrastructure, packets, encapsulation concept, OSI overview. The "aha moment" diagram that makes everything click.

**[02. Addressing Fundamentals](02-addressing-fundamentals/README.md)**  
MAC vs IP addresses, why both exist, how they work together, ARP (IP→MAC translation), private vs public IPs. The critical truth: MAC and IP are ALWAYS used together.

**[03. IP Deep Dive & Assignment](03-ip-deep-dive/README.md)**  
How devices get IPs, DHCP process (DORA), why your IP keeps changing, static vs dynamic, DHCP reservations, localhost (127.0.0.1).

### Network Architecture
**[04. Network Devices](04-network-devices/README.md)**  
Switch (Layer 2, MAC-based) vs Router (Layer 3, IP-based), default gateway (the exit door), routing tables, when direct communication works vs when routing is needed.

**[05. Network Segmentation (Subnets & CIDR)](05-subnets-cidr/README.md)**  
Subnet masks, CIDR notation, calculating IPs (2^(32-CIDR)), common blocks to memorize (/32, /24, /16, /8), AWS VPC planning, avoiding overlaps.

### Application Layer
**[06. Ports & Transport Layer](06-ports-transport/README.md)**  
What ports are (devices have IPs, apps have ports), TCP vs UDP, 3-way handshake (SYN→SYN-ACK→ACK), common ports (22, 80, 443, 3306, 5432), socket concept.

**[07. NAT & Translation](07-nat/README.md)**  
How private IPs access internet, PAT (port address translation), router's two IPs (LAN + WAN), port forwarding, AWS NAT Gateway, Docker port binding (-p flag).

**[08. DNS](08-dns/README.md)**  
Domain→IP translation, DNS resolution process (browser→OS→recursive resolver→root→TLD→authoritative), caching & TTL, record types (A, CNAME, MX), AWS Route 53, Docker DNS.

### Security & Integration
**[09. Firewalls & Security](09-firewalls/README.md)**  
Firewall rules, **stateful vs stateless (CRITICAL)**, AWS Security Groups (stateful, easy), AWS NACLs (stateless, hard), the NACL trap (ephemeral ports), debugging framework.

**[10. Complete Journey & OSI Deep Dive](10-complete-journey/README.md)**  
Everything integrated. Complete packet flows: browser→Google, LAN communication, Docker containers, AWS multi-tier. OSI deep dive, encapsulation in detail, troubleshooting mindset.

## Critical Concepts You'll Master

**The Big Three:**
1. **MAC vs IP** - MAC changes at every hop (next hop), IP never changes (final destination)
2. **Stateful vs Stateless** - Security Groups auto-allow return traffic, NACLs don't (biggest AWS trap)
3. **Encapsulation** - Each layer wraps the previous (Frame→Packet→Segment→Data)

**DevOps Essentials:**
- Why your home router can support 50 devices with one public IP (NAT/PAT)
- How Docker containers find each other by name (built-in DNS)
- Why "connection refused" ≠ "connection timeout" (different problems)
- How to plan AWS VPC subnets without conflicts
- When to use /24 vs /16 vs /32 CIDR blocks

## Learning Path

**Absolute beginner?** Read in order (01→10). Each file builds on previous concepts.

**Have some networking knowledge?** Jump to specific files, but read File 09 (firewalls) even if you think you know it—the stateful/stateless trap breaks most AWS beginners.

**Debugging production issue?** Go directly to File 10 debugging framework, backtrack to specific files as needed.

## Prerequisites

**Required:** None. Designed for complete beginners.

**Helpful but not required:**
- Used Linux command line before
- Seen AWS console
- Run Docker containers

## What You'll Be Able to Do

After completing this series:

✅ Design AWS VPCs with proper subnetting  
✅ Debug "can't connect" issues systematically  
✅ Configure Docker networks correctly  
✅ Understand what happens when you type a URL  
✅ Set up firewalls without breaking applications  
✅ Calculate CIDR blocks in your head  
✅ Explain networking concepts to junior engineers  
✅ Not get trapped by AWS NACLs  

## How to Use This Series

**Each file contains:**
- Clear explanations (why, not just what)
- Step-by-step tables for processes
- Real scenarios (AWS, Docker, home networks)
- Mental models (analogies that stick)
- "Final Compression" (memorize this)

**Read actively:**
- Don't just read, think through examples
- Try commands on your system
- Draw diagrams as you learn
- Test your understanding by explaining to someone

## Philosophy

**This series believes:**
- Practical > Theoretical
- Understanding > Memorization  
- Real scenarios > Abstract examples
- Why it exists > What it's called
- One clear explanation > Ten definitions

**This series avoids:**
- CCNA certification fluff
- Binary math deep dives (unless necessary)
- Protocols you'll never use (BGP, OSPF for beginners)
- Memorization lists without context
- Corporate training speak

## Navigation

Each file has navigation links at the top. Click to jump between files. All files are in order—later files reference concepts from earlier ones.

## Architecture

This series structure was reviewed by multiple AI models (ChatGPT, Gemini, specialized architecture reviewer) and rated 9.3-9.7/10 for:
- Conceptual flow (dependencies satisfied)
- Beginner clarity (zero-knowledge start)
- DevOps relevance (production-focused)
- Pedagogical soundness (builds proper mental models)

## Start Learning

**Ready?** Begin with [01. Foundation & The Big Picture](01-foundation-and-the-big-picture/README.md)

**Questions or feedback?** This is a living document. Improvements welcome.

---

**Built for:** Cloud support engineers, DevOps engineers, SREs, cloud engineers  
**Focus:** AWS, Docker, production environments  
**Level:** Beginner to intermediate  
**Goal:** Turn networking confusion into confident understanding

| Abbreviation | Full Form |
| :--- | :--- |
| **ALB** | Application Load Balancer |
| **ARP** | Address Resolution Protocol |
| **ARPA** | Advanced Research Projects Agency |
| **ARPANET** | Advanced Research Projects Agency Network |
| **CAN** | Campus Area Network / Corporate Area Network |
| **CIDR** | Classless Inter-Domain Routing |
| **DHCP** | Dynamic Host Configuration Protocol |
| **DMZ** | Demilitarized Zone |
| **DNAT** | Destination NAT |
| **DNS** | Domain Name System |
| **FTP** | File Transfer Protocol |
| **HTTP** | Hypertext Transfer Protocol |
| **HTTPS** | Hypertext Transfer Protocol Secure (Secure HTTP) |
| **ICANN** | Internet Corporation for Assigned Names and Numbers |
| **IETF** | Internet Engineering Task Force |
| **IMAP** | Internet Message Access Protocol |
| **IP** | Internet Protocol |
| **IPv4** | Internet Protocol version 4 |
| **IPv6** | Internet Protocol version 6 |
| **ISP** | Internet Service Provider |
| **LAN** | Local Area Network |
| **MAC** | Media Access Control |
| **MAN** | Metropolitan Area Network |
| **NACL** | Network Access Control List |
| **NAT** | Network Address Translation / Network Access Translator |
| **NIC** | Network Interface Card |
| **NS** | Name Server |
| **NTP** | Network Time Protocol |
| **OSI** | Open Systems Interconnection |
| **P2P** | Peer-to-Peer |
| **PAT** | Port Address Translation |
| **POP / POP3** | Post Office Protocol (version 3) |
| **PTR** | Pointer (Reverse DNS) |
| **RDP** | Remote Desktop |
| **RDS** | Relational Database Service |
| **RFC** | Request for Comments |
| **SAN** | Storage Area Network |
| **SG** | Security Groups |
| **SMTP** | Simple Mail Transfer Protocol |
| **SNAT** | Source NAT |
| **SNMP** | Simple Network Management Protocol |
| **SONET** | Synchronous Optical Networking |
| **SSH** | Secure Shell |
| **TCP** | Transmission Control Protocol |
| **TLD** | Top-Level Domain |
| **TTL** | Time To Live |
| **UDP** | User Datagram Protocol |
| **URL** | Uniform Resource Locator |
| **VNC** | Virtual Network Computing |
| **VoIP** | Voice over IP |
| **VPC** | Virtual Private Cloud |
| **WAN** | Wide Area Network |
| **WLAN** | Wireless Local Area Network |
| **WWW** | World Wide Web |