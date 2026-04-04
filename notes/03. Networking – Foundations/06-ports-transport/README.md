# File 06: Ports & Transport Layer

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

# Ports & Transport Layer

## What this file is about

This file teaches **how applications are identified using port numbers** and **how data is delivered reliably**. If you understand this, you'll know why SSH uses port 22, how TCP guarantees delivery, when to use UDP, and how to configure firewall rules correctly. This is essential for deploying and troubleshooting applications.

<!-- no toc -->
- [The Core Problem](#the-core-problem)
- [What Are Ports?](#what-are-ports)
- [Common Port Numbers (Memorize These)](#common-port-numbers-memorize-these)
- [TCP vs UDP (The Two Protocols)](#tcp-vs-udp-the-two-protocols)
- [TCP: The Reliable Protocol](#tcp-the-reliable-protocol)
- [UDP: The Fast Protocol](#udp-the-fast-protocol)
- [Port Ranges and Categories](#port-ranges-and-categories)
- [The Socket Concept](#the-socket-concept)
- [Real Scenarios](#real-scenarios)  
[Final Compression](#final-compression)

---

## The Core Problem

### Your Original Question

**"Does the device have IP and the application also has IP?"**

**Short answer:** No.

**Correct model:**

```
Device has IP address    (identifies the computer)
Application has PORT     (identifies the application)

Format: IP:Port
Example: 192.168.1.45:80
         └──────────┘ └┘
         Device       Application
```

---

### The Scenario

**Your server has multiple applications running:**

```
Server IP: 192.168.1.100

Running applications:
- Web server (nginx)
- Database (PostgreSQL)
- SSH server
- Redis cache
- API application
```

**Problem:**  
A packet arrives at 192.168.1.100.  
**Which application should receive it?**

**Solution: Port numbers**

```
Web server:    192.168.1.100:80
Database:      192.168.1.100:5432
SSH:           192.168.1.100:22
Redis:         192.168.1.100:6379
API:           192.168.1.100:3000

Same IP, different ports
```

---

### Real-World Analogy

**IP address = Apartment building address**

```
123 Main Street
```

**Port number = Apartment number**

```
123 Main Street, Apartment 5
123 Main Street, Apartment 12
123 Main Street, Apartment 24

Same building (IP)
Different apartments (ports)
```

**Sending mail:**

```
Wrong: "Send to 123 Main Street"
  Which apartment? Unclear!

Right: "Send to 123 Main Street, Apartment 12"
  Specific destination
```

**Sending data:**

```
Wrong: "Send to 192.168.1.100"
  Which application? Unclear!

Right: "Send to 192.168.1.100:80"
  Specific application (web server)
```

---

## What Are Ports?

### Definition

**Port:**  
A 16-bit number (0-65535) that identifies a specific application or service on a device.

**Purpose:**  
Allow multiple applications to run on the same IP address without conflicts.

---

### How Ports Work

**Your laptop connects to a web server:**

```
Your laptop:
  IP: 192.168.1.45
  Source port: 54321 (random)

Web server:
  IP: 203.45.67.89
  Destination port: 80 (HTTP)

Connection format:
  192.168.1.45:54321 → 203.45.67.89:80
  └──────────────┘     └──────────────┘
  Source (you)         Destination (server)
```

---

### Port Number Format

**Range:**

```
0 - 65535 (16-bit number)

Total possible ports: 65,536
```

**In packet headers:**

```
TCP/UDP Header:
  Source Port:      54321
  Destination Port: 80
  ...other fields...
```

---

### Check Your Open Ports

**Linux/Mac:**

```bash
# Show all listening ports
sudo netstat -tlnp

# or
sudo ss -tlnp

Output:
Proto Local Address    State   PID/Program
tcp   0.0.0.0:22       LISTEN  1234/sshd
tcp   0.0.0.0:80       LISTEN  5678/nginx
tcp   127.0.0.1:5432   LISTEN  9012/postgres
```

**Windows:**

```cmd
netstat -ano

Output:
Proto  Local Address      Foreign Address    State       PID
TCP    0.0.0.0:80         0.0.0.0:0          LISTENING   4
TCP    0.0.0.0:443        0.0.0.0:0          LISTENING   4
TCP    127.0.0.1:5432     0.0.0.0:0          LISTENING   2508
```

---

## Common Port Numbers (Memorize These)

### Essential Ports for DevOps

**You MUST know these:**

| Port | Protocol | Service | Usage |
|------|----------|---------|-------|
| **20/21** | FTP | File Transfer Protocol | File uploads (legacy) |
| **22** | SSH | Secure Shell | Remote server access |
| **23** | Telnet | Telnet | Unsecure remote access (don't use) |
| **25** | SMTP | Email sending | Mail servers |
| **53** | DNS | Domain Name System | Name resolution |
| **80** | HTTP | Web traffic (unsecure) | Websites |
| **110** | POP3 | Email retrieval | Email clients |
| **143** | IMAP | Email retrieval | Email clients |
| **443** | HTTPS | Web traffic (secure) | Secure websites |
| **3306** | MySQL | MySQL database | Database connections |
| **5432** | PostgreSQL | PostgreSQL database | Database connections |
| **6379** | Redis | Redis cache | Cache/queue connections |
| **27017** | MongoDB | MongoDB database | NoSQL database |
| **3389** | RDP | Remote Desktop | Windows remote access |
| **8080** | HTTP Alt | Alternative HTTP | Dev servers, proxies |

---

### Application-Specific Ports

**Docker & Containers:**

```
2375 - Docker daemon (unencrypted)
2376 - Docker daemon (TLS)
```

**Kubernetes:**

```
6443 - Kubernetes API server
10250 - Kubelet API
```

**Message Queues:**

```
5672 - RabbitMQ
9092 - Kafka
```

**Monitoring:**

```
9090 - Prometheus
3000 - Grafana
9200 - Elasticsearch
5601 - Kibana
```

---

### Real Examples

**Accessing websites:**

```
http://google.com
  → Implicitly uses port 80
  → Browser connects to google.com:80

https://google.com
  → Implicitly uses port 443
  → Browser connects to google.com:443

http://localhost:3000
  → Explicitly uses port 3000
  → Browser connects to localhost:3000
```

**SSH to server:**

```bash
ssh user@192.168.1.100
  → Implicitly uses port 22
  → Connects to 192.168.1.100:22

ssh -p 2222 user@192.168.1.100
  → Explicitly uses port 2222
  → Connects to 192.168.1.100:2222
```

**Database connections:**

```
PostgreSQL:
  psql -h 192.168.1.100 -p 5432
  Connection string: postgresql://user:pass@192.168.1.100:5432/db

MySQL:
  mysql -h 192.168.1.100 -P 3306
  Connection string: mysql://user:pass@192.168.1.100:3306/db

MongoDB:
  mongo 192.168.1.100:27017
  Connection string: mongodb://192.168.1.100:27017/db
```

---

## TCP vs UDP (The Two Protocols)

### The Transport Layer

**Layer 4 (Transport) has two main protocols:**

```
1. TCP (Transmission Control Protocol)
   - Reliable, ordered, connection-oriented
   - Most common

2. UDP (User Datagram Protocol)
   - Fast, unordered, connectionless
   - Special use cases
```

---

### Side-by-Side Comparison

| Feature | TCP | UDP |
|---------|-----|-----|
| **Reliability** | Guaranteed delivery | No guarantee |
| **Ordering** | Packets arrive in order | May arrive out of order |
| **Connection** | Requires handshake | No connection setup |
| **Speed** | Slower (overhead) | Faster (minimal overhead) |
| **Error checking** | Yes (retransmits lost data) | Minimal |
| **Use cases** | Web, email, file transfer, databases | Video, gaming, DNS, VoIP |
| **Header size** | 20 bytes | 8 bytes |

---

### When to Use Which

**Use TCP when:**

```
✅ Data MUST arrive correctly
✅ Order matters
✅ Loss is unacceptable

Examples:
- Downloading files
- Loading web pages
- Database queries
- Email
- SSH connections
```

**Use UDP when:**

```
✅ Speed is critical
✅ Some data loss is acceptable
✅ Real-time is important

Examples:
- Live video streaming
- Online gaming
- VoIP (phone calls)
- DNS queries
- IoT sensor data
```

---

### Visual Comparison

**TCP (like certified mail):**

```
Sender → Post Office
  ↓
Acknowledgment: "We received it"
  ↓
Delivery to recipient
  ↓
Signature required
  ↓
Confirmation back to sender: "Delivered!"

Guarantees:
✅ Package arrives
✅ In correct order
✅ Recipient confirms receipt
```

**UDP (like shouting across the street):**

```
Sender → Yells message
  ↓
Hope recipient hears it

No guarantees:
❌ May not arrive
❌ May arrive out of order
❌ No confirmation

But: Very fast!
```

---

## TCP: The Reliable Protocol

### TCP Characteristics

```
✅ Connection-oriented (handshake required)
✅ Reliable (guarantees delivery)
✅ Ordered (packets reassembled correctly)
✅ Error-checked (detects corruption)
✅ Flow-controlled (adapts to network speed)
```

---

### TCP 3-Way Handshake

**Before data is sent, TCP establishes a connection:**

```
┌──────────┐                      ┌──────────┐
│  Client  │                      │  Server  │
└────┬─────┘                      └────┬─────┘
     │                                 │
     │  1. SYN (Synchronize)           │
     │  "I want to connect"            │
     ├────────────────────────────────>│
     │                                 │
     │                                 │ Check if port open
     │                                 │ Allocate resources
     │                                 │
     │  2. SYN-ACK (Synchronize-Ack)   │
     │  "OK, I'm ready"                │
     │<────────────────────────────────┤
     │                                 │
     │                                 │
     │  3. ACK (Acknowledge)           │
     │  "Great, let's start"           │
     ├────────────────────────────────>│
     │                                 │
     │  Connection established         │
     │  Data can now flow              │
     │<───────────────────────────────>│
```

---

### Step-by-Step Handshake

**Step 1: Client sends SYN**

```
Client → Server

TCP Header:
  Source Port:    54321
  Dest Port:      80
  Flags:          SYN
  Sequence:       1000
  
Message: "I want to connect to port 80"
```

**Step 2: Server responds with SYN-ACK**

```
Server → Client

TCP Header:
  Source Port:    80
  Dest Port:      54321
  Flags:          SYN, ACK
  Sequence:       5000
  Acknowledgment: 1001
  
Message: "I received your SYN (1000). 
          I'm ready. My sequence starts at 5000."
```

**Step 3: Client sends ACK**

```
Client → Server

TCP Header:
  Source Port:    54321
  Dest Port:      80
  Flags:          ACK
  Sequence:       1001
  Acknowledgment: 5001
  
Message: "I received your SYN-ACK (5000). Let's communicate."

Connection now ESTABLISHED
```

---

### TCP Data Transfer

**After handshake, data flows with acknowledgments:**

```
Client → Server: "Here's 100 bytes (seq 1001-1100)"
Server → Client: "Got it! (ack 1101)"

Client → Server: "Here's 100 bytes (seq 1101-1200)"
Server → Client: "Got it! (ack 1201)"

If packet lost:
Client → Server: "Here's 100 bytes (seq 1201-1300)"
Server: ... (no response)

Client waits for timeout
Client: "No ACK received, resend"
Client → Server: "Here's 100 bytes (seq 1201-1300)" (retry)
Server → Client: "Got it! (ack 1301)"
```

---

### TCP Connection Termination

**4-way termination (graceful close):**

```
┌──────────┐                      ┌──────────┐
│  Client  │                      │  Server  │
└────┬─────┘                      └────┬─────┘
     │                                 │
     │  1. FIN (Finish)                │
     │  "I'm done sending"             │
     ├────────────────────────────────>│
     │                                 │
     │  2. ACK                         │
     │  "OK, got it"                   │
     │<────────────────────────────────┤
     │                                 │
     │  3. FIN                         │
     │  "I'm also done"                │
     │<────────────────────────────────┤
     │                                 │
     │  4. ACK                         │
     │  "OK, closing"                  │
     ├────────────────────────────────>│
     │                                 │
     │  Connection closed              │
```

---

### Why TCP Matters for DevOps

**Debugging connection issues:**

```
Error: "Connection refused"
  Meaning: Server not listening on that port
  TCP reached server, but nothing on port 80

Error: "Connection timeout"
  Meaning: No response to SYN
  Firewall blocking, or server down

Error: "Connection reset"
  Meaning: Server abruptly closed connection
  Application crashed, or limit reached
```

**Check TCP connections:**

```bash
# Show established TCP connections
netstat -tn

# Show listening TCP ports
netstat -tln

# Count connections per port
netstat -tn | grep :80 | wc -l
```

---

## UDP: The Fast Protocol

### UDP Characteristics

```
✅ Connectionless (no handshake)
✅ Fast (minimal overhead)
✅ Low latency
❌ No reliability guarantee
❌ No ordering guarantee
❌ No retransmission
```

---

### How UDP Works

**No handshake, just send:**

```
┌──────────┐                      ┌──────────┐
│  Client  │                      │  Server  │
└────┬─────┘                      └────┬─────┘
     │                                 │
     │  UDP packet                     │
     │  "Here's some data"             │
     ├────────────────────────────────>│
     │                                 │
     │  (no acknowledgment)            │
     │                                 │
     │  Another UDP packet             │
     │  "Here's more data"             │
     ├────────────────────────────────>│
     │                                 │
     │  (no acknowledgment)            │
     │                                 │
     │  No connection state            │
     │  No reliability                 │
     │  Just send and hope             │
```

---

### UDP Packet Structure

**Much simpler than TCP:**

```
UDP Header (8 bytes):
  Source Port:      53
  Destination Port: 54321
  Length:           56 bytes
  Checksum:         0x1A2B

Payload:
  DNS response data
  
That's it! No sequence, no ack, no flags.
```

---

### Why Use UDP?

**DNS queries (perfect UDP use case):**

```
You: "What's google.com's IP?"
  UDP packet to 8.8.8.8:53
  Small query (< 512 bytes)
  
DNS server: "142.250.190.46"
  UDP packet back
  Small response
  
Total time: ~10ms

If UDP packet lost? Send again.
Lost rate: <1%
Speed gain: Significant (no handshake)
```

**Live video streaming:**

```
Video frames sent via UDP
  Frame 1 → (sent)
  Frame 2 → (sent)
  Frame 3 → (lost!) ❌
  Frame 4 → (sent)
  Frame 5 → (sent)

Result: Slight glitch (Frame 3 missing)
Better than: Buffering while waiting for retransmit

User experience: Smooth (acceptable glitch)
```

**Online gaming:**

```
Player position updates:
  Position at T=0ms  → (sent via UDP)
  Position at T=50ms → (sent via UDP)
  Position at T=100ms → (lost!) ❌
  Position at T=150ms → (sent via UDP)

Missing one position update? No problem.
Next update arrives with current position.
Better than TCP delay from retransmit.
```

---

### UDP vs TCP Example

**Downloading a file (use TCP):**

```
TCP:
  100% of file arrives
  Every byte verified
  Correct order
  Download time: 10 seconds
  
UDP:
  98% of file arrives (2% lost)
  File corrupted
  Unusable
  Download time: 8 seconds (but useless!)
```

**VoIP call (use UDP):**

```
UDP:
  2% packets lost
  Slight audio glitch
  Real-time conversation
  Latency: 50ms
  
TCP:
  100% packets arrive
  No glitches
  But: Stuttering from retransmits
  Latency: 200-500ms (unacceptable delay)
```

---

### Common UDP Services

| Port | Service | Why UDP? |
|------|---------|----------|
| **53** | DNS | Small queries, speed critical |
| **67/68** | DHCP | Small broadcast messages |
| **123** | NTP (time sync) | Speed, periodic updates |
| **161/162** | SNMP (monitoring) | Speed, many small queries |
| **514** | Syslog | Fire-and-forget logging |
| **Various** | Video/Audio streaming | Real-time, loss acceptable |
| **Various** | Online gaming | Low latency critical |

---

## Port Ranges and Categories

### The Three Ranges

**0-1023: Well-Known Ports**

```
Assigned by IANA
System/privileged services only
Require root/admin to bind

Examples:
  22  - SSH
  80  - HTTP
  443 - HTTPS
```

**1024-49151: Registered Ports**

```
Registered for specific services
Can be used by regular users
Companies register their software ports

Examples:
  3306  - MySQL
  5432  - PostgreSQL
  27017 - MongoDB
  3000  - Many dev servers
  8080  - Alternative HTTP
```

**49152-65535: Dynamic/Private Ports**

```
Ephemeral ports
Used for client-side connections
Randomly assigned by OS

Example:
  Your browser connects to server:
    Source port: 54321 (random from this range)
    Dest port: 443 (server's HTTPS port)
```

---

### Binding Ports (Server vs Client)

**Server behavior (binds to specific port):**

```
Web server:
  Binds to port 80
  Listens for connections
  Port doesn't change

Code:
  socket.bind(("0.0.0.0", 80))
  socket.listen()
```

**Client behavior (uses random port):**

```
Your browser:
  Connects to google.com:443
  Uses random source port: 54321
  Different for each connection

Next connection:
  Source port: 54322 (different)
```

---

### Check Port Availability

**Linux/Mac:**

```bash
# Check if port 80 is in use
sudo lsof -i :80

# Check if port available
nc -zv localhost 80

# Test TCP connection
telnet localhost 80

# Test UDP connection
nc -u localhost 53
```

**Why ports might be unavailable:**

```
1. Another application using it
   Error: "Address already in use"
   
2. Insufficient privileges
   Error: "Permission denied" (ports < 1024)
   
3. Firewall blocking
   Error: "Connection refused" or timeout
```

---

## The Socket Concept

### What Is a Socket?

**Socket:**  
A combination of IP address + port number + protocol.

**Format:**

```
Protocol://IP:Port

Examples:
  tcp://192.168.1.100:80
  udp://8.8.8.8:53
  tcp://[::1]:443 (IPv6)
```

---

### Socket as Endpoint

**Communication requires two sockets:**

```
Client socket:
  tcp://192.168.1.45:54321

Server socket:
  tcp://192.168.1.100:80

Connection:
  192.168.1.45:54321 ←→ 192.168.1.100:80
```

---

### Multiple Connections to Same Server

**Server can handle many clients on same port:**

```
Server: 192.168.1.100:80

Connection 1:
  Client A (192.168.1.45:54321) → Server (192.168.1.100:80)

Connection 2:
  Client B (192.168.1.67:54322) → Server (192.168.1.100:80)

Connection 3:
  Client C (192.168.1.89:54323) → Server (192.168.1.100:80)

Server distinguishes by:
  Different source IP + source port combinations
```

---

### Socket States (TCP)

**TCP sockets have states:**

```
LISTEN      - Server waiting for connections
SYN_SENT    - Client sent SYN, waiting for SYN-ACK
ESTABLISHED - Connection active
FIN_WAIT    - Closing connection
TIME_WAIT   - Connection closed, waiting for delayed packets
CLOSED      - Socket closed
```

**Check socket states:**

```bash
netstat -tn

Output:
Proto Recv-Q Send-Q Local Address      Foreign Address    State
tcp   0      0      192.168.1.45:54321 142.250.190.46:443 ESTABLISHED
tcp   0      0      192.168.1.45:54322 93.184.216.34:80   TIME_WAIT
tcp   0      0      0.0.0.0:22         0.0.0.0:*          LISTEN
```

---

## Real Scenarios

### Scenario 1: Web Server Configuration

**nginx configuration:**

```nginx
server {
    listen 80;                    # HTTP
    listen [::]:80;               # HTTP (IPv6)
    server_name example.com;
    
    return 301 https://$server_name$request_uri;  # Redirect to HTTPS
}

server {
    listen 443 ssl;               # HTTPS
    listen [::]:443 ssl;          # HTTPS (IPv6)
    server_name example.com;
    
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    
    location / {
        proxy_pass http://localhost:3000;  # Forward to app on port 3000
    }
}
```

**Port usage:**

```
Port 80:  Public-facing HTTP (redirects to 443)
Port 443: Public-facing HTTPS (SSL/TLS)
Port 3000: Internal application server (not exposed)
```

---

### Scenario 2: Docker Port Binding

**Expose container port to host:**

```bash
# Run nginx container
docker run -d -p 8080:80 nginx

# Breakdown:
#   -p 8080:80
#      │    │
#      │    └─ Container port (nginx listens on 80)
#      └────── Host port (accessible at localhost:8080)

# Access:
curl http://localhost:8080
  → Routes to container's port 80
```

**Multiple port mappings:**

```bash
docker run -d \
  -p 80:80 \       # HTTP
  -p 443:443 \     # HTTPS
  -p 3306:3306 \   # MySQL
  nginx
```

---

### Scenario 3: AWS Security Group Rules

**Allow web traffic:**

```
Inbound Rules:

Type     Protocol  Port Range  Source       Description
HTTP     TCP       80          0.0.0.0/0    Allow HTTP from anywhere
HTTPS    TCP       443         0.0.0.0/0    Allow HTTPS from anywhere
SSH      TCP       22          203.0.113.0/24  Allow SSH from office IP only
Custom   TCP       3000        10.0.1.0/24  Allow internal API access
```

**Common mistake:**

```
❌ Wrong: Open all ports
   Port Range: 0-65535
   Risk: Exposes unnecessary services

✅ Right: Only open needed ports
   Ports: 22, 80, 443
   Principle of least privilege
```

---

### Scenario 4: Debugging Connection Issues

**Can't connect to database:**

```bash
# Step 1: Check if database listening
sudo netstat -tlnp | grep 5432

Output:
tcp  0.0.0.0:5432  LISTEN  1234/postgres

✓ Database is listening on port 5432

# Step 2: Try to connect locally
psql -h localhost -p 5432

✓ Works locally

# Step 3: Try from remote
psql -h 192.168.1.100 -p 5432

✗ Connection timeout

# Conclusion: Firewall blocking port 5432
```

**Fix:**

```bash
# Ubuntu/Debian
sudo ufw allow 5432/tcp

# CentOS/RHEL
sudo firewall-cmd --add-port=5432/tcp --permanent
sudo firewall-cmd --reload
```

---

### Scenario 5: Multi-Service Server

**One server running multiple services:**

```
Server IP: 192.168.1.100

Services:
├─ SSH:        Port 22      (secure remote access)
├─ Web:        Port 80      (public HTTP)
├─ Web SSL:    Port 443     (public HTTPS)
├─ PostgreSQL: Port 5432    (internal database)
├─ Redis:      Port 6379    (internal cache)
└─ API:        Port 8000    (internal API)

Firewall rules:
  Port 22:   Allow from 203.0.113.0/24 (office)
  Port 80:   Allow from 0.0.0.0/0 (everyone)
  Port 443:  Allow from 0.0.0.0/0 (everyone)
  Port 5432: Allow from 192.168.1.0/24 (local network)
  Port 6379: Allow from 192.168.1.0/24 (local network)
  Port 8000: Allow from 192.168.1.0/24 (local network)
```

---

## Final Compression

### What Are Ports?

```
Port = 16-bit number (0-65535)
Purpose: Identify applications on a device

Format: IP:Port
  192.168.1.100:80  (web server)
  192.168.1.100:5432 (database)

Same IP, different applications
```

---

### Essential Ports (Memorize)

```
22   - SSH (remote access)
53   - DNS (name resolution)
80   - HTTP (web unsecure)
443  - HTTPS (web secure)
3306 - MySQL
5432 - PostgreSQL
6379 - Redis
27017 - MongoDB
```

---

### TCP vs UDP

**TCP (Reliable):**
```
✅ Guaranteed delivery
✅ Ordered packets
✅ 3-way handshake (SYN, SYN-ACK, ACK)
✅ Use for: Web, email, databases, file transfer
```

**UDP (Fast):**
```
✅ No handshake
✅ Low latency
❌ No guarantee
✅ Use for: DNS, video streaming, gaming, VoIP
```

---

### TCP 3-Way Handshake

```
Client → Server: SYN ("Let's connect")
Server → Client: SYN-ACK ("OK, ready")
Client → Server: ACK ("Great!")

Connection established
```

---

### Port Ranges

```
0-1023:       Well-known (system services)
1024-49151:   Registered (applications)
49152-65535:  Dynamic (client connections)
```

---

### Socket = IP + Port + Protocol

```
tcp://192.168.1.45:54321 → tcp://192.168.1.100:80
└────────────────────┘      └────────────────────┘
Client socket               Server socket
```

---

### Common Errors

```
"Connection refused"
  → Port not listening
  → Check: netstat -tln | grep PORT

"Connection timeout"
  → Firewall blocking or server down
  → Check: firewall rules

"Address already in use"
  → Port taken by another app
  → Check: lsof -i :PORT
```

---

### Mental Model

```
IP address = Apartment building
Port number = Apartment number

One building (192.168.1.100)
Many apartments:
  :22   (SSH)
  :80   (HTTP)
  :443  (HTTPS)
  :5432 (PostgreSQL)

Mail delivery needs both:
  Building address + Apartment number
  IP address + Port number
```

---

### What You Can Do Now

✅ Understand what ports are (application identifiers)  
✅ Know common port numbers (22, 80, 443, 3306, 5432)  
✅ Understand TCP vs UDP differences  
✅ Know TCP 3-way handshake  
✅ Configure firewall rules with correct ports  
✅ Debug port-related connection issues  
✅ Map Docker container ports  

---