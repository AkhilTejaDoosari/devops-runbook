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

# Networking Reference Map

A single-page cheat sheet covering the entire series.
Use this before interviews and when debugging production issues.

---

## 1. Master Packet Journey

```
[Your Computer]
      ↓
   DNS Lookup → name becomes IP
      ↓
   TCP Handshake → SYN, SYN-ACK, ACK
      ↓
   Encapsulation → Data → Port → IP → MAC
      ↓
[Local Switch] → reads MAC, forwards locally
      ↓
   ARP Resolution → IP becomes MAC
      ↓
[Home Router]
      ↓
   NAT → Private IP becomes Public IP
      ↓
((( INTERNET )))
      ↓
   Hop-by-Hop Routing
   MAC changes every hop
   IP never changes
      ↓
[AWS VPC]
      ↓
   Internet Gateway → enters VPC
      ↓
   NACL → subnet firewall (stateless)
      ↓
   Load Balancer → distributes to server
      ↓
   Security Group → instance firewall (stateful)
      ↓
   ARP Final Hop → resolve final MAC
      ↓
   De-encapsulation → MAC → IP → Port → Data
      ↓
   Port routes to application
      ↓
[Destination Server]
```

---

## 2. Layer Mental Model

| Layer | Tool | Purpose | Changes During Journey? |
|---|---|---|---|
| **Layer 2 (Data Link)** | MAC Address | Local delivery within network | Yes — every hop |
| **Layer 3 (Network)** | IP Address | Global delivery across internet | Destination: No / Source: Yes (NAT) |
| **Layer 4 (Transport)** | Port Number | Deliver to correct application | No |

---

## 3. What Changes vs What Stays

| Component | Changes? | When | Why |
|---|---|---|---|
| **Application Data** | Never | — | The payload |
| **Destination IP** | Never | — | Global addressing |
| **Source IP** | Once | At NAT | Private → Public |
| **Port Number** | Never | — | Application identifier |
| **MAC Address** | Every hop | At each router | Local delivery only |

---

## 4. Protocol Map

| Need | Protocol | Command |
|---|---|---|
| Name → IP | DNS | `nslookup google.com` |
| IP → MAC (local) | ARP | `arp -a` |
| Reliable delivery | TCP | 3-way handshake |
| Fast delivery | UDP | No handshake |
| Global routing | IP | Hop-by-hop |
| Hide private IPs | NAT | Router translation |
| Auto IP assignment | DHCP | Lease process |

---

## 5. Security Layers

| Firewall Type | Scope | Memory? | Return Traffic? |
|---|---|---|---|
| **NACL** | Subnet | No (stateless) | Needs explicit rule |
| **Security Group** | Instance | Yes (stateful) | Auto-allowed |

**Rule:**
- Stateless = checks every packet independently, has amnesia
- Stateful = remembers connections, auto-allows replies

---

## 6. Debugging Breakpoints

| Stage | Failure Symptom | Tool | What It Shows |
|---|---|---|---|
| **DNS** | Name not resolving | `nslookup google.com` | IP or error |
| **TCP** | Connection refused | `nc -zv IP PORT` | Port open/closed |
| **Routing** | Packet lost | `traceroute google.com` | Where packet dies |
| **Firewall** | Port blocked | `ss -tlnp` | Listening ports |
| **ARP** | Local delivery fails | `arp -a` | MAC table |
| **NAT** | External access fails | `curl ifconfig.me` | Public IP |

---

## 7. Common Ports

```
22    → SSH
53    → DNS
80    → HTTP
443   → HTTPS
3306  → MySQL
5432  → PostgreSQL
6379  → Redis
27017 → MongoDB
```

---

## 8. CIDR Quick Reference

| CIDR | Total IPs | Usable | Use Case |
|---|---|---|---|
| /32 | 1 | 1 | Single host (SG rule) |
| /28 | 16 | 14 | Small subnet |
| /24 | 256 | 254 | Standard subnet |
| /16 | 65,536 | 65,534 | VPC CIDR |

---

## 9. Private IP Ranges

```
10.0.0.0/8         → Large networks (AWS VPC)
172.16.0.0/12      → Medium networks (Docker default)
192.168.0.0/16     → Home/small office
```

---

## 10. Interview Answer: Browser to Server

> DNS translates the domain to an IP. TCP handshake establishes connection. Data is encapsulated: application layer → port → destination IP → router MAC.
>
> Local switch forwards via MAC. Router performs NAT (private IP → public IP). Packet hops across internet — MAC changes every hop, IP stays constant.
>
> Enters AWS via Internet Gateway. Passes stateless NACL (subnet firewall), then load balancer distributes to server. Stateful Security Group allows it through.
>
> De-encapsulation: strip MAC → IP → port. Port routes to web application. Response follows reverse path.

---

## 11. Webstore Scenario

**User opens webstore.com**

```
DNS       → webstore.com resolves to 54.123.45.67 (Route53)
TCP       → Handshake to port 443
NAT       → Home router: 192.168.1.50 → 203.45.67.89
Routing   → Hops to AWS us-east-1
IGW       → Enters VPC 10.0.0.0/16
NACL      → Allows port 443 inbound
ALB       → Distributes to webstore-api instance
SG        → Allows port 443 to EC2
Server    → nginx serves webstore-frontend
Response  → Reverse path to browser
```
