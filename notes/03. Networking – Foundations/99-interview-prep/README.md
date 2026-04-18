[Home](../README.md) |
[Foundation](../01-foundation-and-the-big-picture/README.md) |
[Addressing](../02-addressing-fundamentals/README.md) |
[IP Deep Dive](../03-ip-deep-dive/README.md) |
[Devices](../04-network-devices/README.md) |
[Subnets & CIDR](../05-subnets-cidr/README.md) |
[Ports & Transport](../06-ports-transport/README.md) |
[NAT](../07-nat/README.md) |
[DNS](../08-dns/README.md) |
[Firewalls](../09-firewalls/README.md) |
[Complete Journey](../10-complete-journey/README.md) |
[Interview](../99-interview-prep/README.md)

---

# Networking — Interview Prep

Answers are 30 seconds. No padding. Every question here actually comes up.

---

## OSI Model · Layers · Encapsulation

**What is the OSI model and why does it matter?**

The OSI model breaks networking into 7 layers — Physical, Data Link, Network, Transport, Session, Presentation, Application. Each layer has one job and serves the layer above it. It matters because when something breaks, you debug layer by layer. Connection refused means Layer 4 — the port isn't listening. DNS fails means Layer 7 — name resolution is broken. The model gives you a systematic place to start instead of guessing.

**What are the three layers you spend 90% of your time in?**

Layer 7 Application — HTTP, DNS, SSH — what users interact with. Layer 4 Transport — TCP/UDP, ports — reliability and which service gets the packet. Layer 3 Network — IP addresses, routing — how packets get between networks. Layers 1, 2, 5, and 6 are mostly abstracted in cloud and container environments.

**What is encapsulation?**

Each layer wraps the data from the layer above it with its own header. An HTTP request becomes a TCP segment, which becomes an IP packet, which becomes an Ethernet frame, which becomes bits on a wire. On the receiving end, each layer strips its header and passes the data up. This is why layers are independent — HTTP doesn't know or care about Ethernet.

---

## MAC vs IP · ARP · Addressing

**What is the difference between a MAC address and an IP address?**

A MAC address is a hardware identifier burned into the network interface — it never changes and operates at Layer 2. An IP address is a logical address assigned by software — it can change and operates at Layer 3. MAC addresses handle local delivery on the same network segment. IP addresses handle end-to-end delivery across networks. The critical rule: the destination IP never changes as a packet travels across the internet, but the destination MAC changes at every single router hop.

**What is ARP and when does it run?**

ARP — Address Resolution Protocol — resolves an IP address to a MAC address on a local network. When a device knows the destination IP but needs the MAC to actually send the frame, it broadcasts "who has this IP?" on the local segment. The owner responds with its MAC. The result is cached in the ARP table. ARP only works within a subnet — to reach another subnet, the packet goes to the gateway instead.

**What are private IP ranges?**

`10.0.0.0/8`, `172.16.0.0/12`, and `192.168.0.0/16`. These are not routable on the public internet — routers drop packets with private source IPs. They exist so organizations can use IP addresses internally without consuming public address space. NAT translates private IPs to a public IP when traffic leaves the network.

---

## Subnets · CIDR · IP Math

**What is a subnet?**

A subnet is a subdivision of a network. A `/24` gives you 256 addresses (254 usable — the network address and broadcast are reserved). A `/16` gives you 65,536. Subnetting lets you divide a large address space into smaller logical segments for security, organization, and routing efficiency.

**What does /24 mean in CIDR notation?**

The `/24` means 24 bits are the network portion of the address and the remaining 8 bits identify hosts. A `10.0.1.0/24` subnet covers `10.0.1.0` through `10.0.1.255` — 256 addresses, 254 usable. Smaller number = bigger network: `/16` is larger than `/24`.

**Why does the webstore need two subnets on AWS?**

Security through network isolation. The frontend and API go in a public subnet with an internet route — browsers need to reach them. The database goes in a private subnet with no internet route — nothing from the public internet can reach postgres directly, not because of a firewall rule but because there is no route. This is the standard AWS multi-tier architecture.

---

## TCP vs UDP · Ports · Three-Way Handshake

**What is the difference between TCP and UDP?**

TCP is connection-oriented — it establishes a connection with a three-way handshake, guarantees delivery, retransmits lost packets, and delivers data in order. UDP is connectionless — it fires packets and forgets, no guarantee, no retransmission, no ordering. TCP is for HTTP, SSH, postgres — anything where data integrity matters. UDP is for DNS queries, video streaming, gaming — anything where speed matters more than perfect delivery.

**What is the TCP three-way handshake?**

SYN — the client sends a synchronize packet to initiate the connection. SYN-ACK — the server acknowledges and sends its own synchronize. ACK — the client acknowledges the server's SYN. Connection is established. When you see `Connection refused`, the server received the SYN but nothing was listening on that port. When you see a timeout, the SYN never reached the server — firewall or routing problem.

**What is the difference between `Connection refused` and `Connection timed out`?**

Refused means the packet reached the machine but nothing is listening on that port — the OS sent back a RST. Timed out means the packet never reached the machine — it was dropped by a firewall, the host is down, or there is no route. Refused is a Layer 4 problem. Timed out is a Layer 3 or firewall problem. This distinction tells you exactly where to look.

**What are well-known ports?**

Ports 0–1023 are reserved for system services. 22 is SSH, 80 is HTTP, 443 is HTTPS, 5432 is postgres, 3306 is MySQL, 6443 is the Kubernetes API server. Ports 1024–49151 are registered application ports. Above 49152 are ephemeral ports — assigned dynamically by the OS for outbound connections.

---

## NAT · Port Forwarding · Translation

**What is NAT and why does it exist?**

Network Address Translation replaces the source IP of outgoing packets with a public IP, and reverses the translation for responses. It exists because IPv4 has ~4 billion addresses — not enough for every device. NAT lets thousands of devices share one public IP. Your home router does this. AWS NAT Gateway does this for private subnets. Docker does this for containers.

**What is DNAT and where does it appear in DevOps?**

Destination NAT rewrites the destination IP and port of incoming packets. When you run `docker run -p 8080:80`, Docker creates an iptables DNAT rule — traffic arriving on host port 8080 gets its destination rewritten to the container's private IP on port 80. AWS load balancers do the same thing at cloud scale. `sudo iptables -t nat -L DOCKER -n` shows every DNAT rule Docker has created.

**What is the difference between SNAT and DNAT?**

SNAT modifies the source address — used for outbound traffic, like a private instance reaching the internet through a NAT gateway. DNAT modifies the destination address — used for inbound traffic, like port forwarding or load balancing. Docker port binding is DNAT. AWS NAT Gateway is SNAT.

---

## DNS · Resolution · Records

**What happens when you type `webstore.example.com` in a browser?**

The OS checks its local cache. If not found, it queries the recursive resolver (usually your ISP or `8.8.8.8`). The resolver checks its cache. If not found, it walks the DNS tree — queries the root servers for `.com`, then the `.com` TLD servers for `example.com`, then `example.com`'s authoritative nameserver for `webstore.example.com`. The A record comes back with an IP. The browser connects to that IP on port 80 or 443.

**What is the difference between an A record and a CNAME?**

An A record maps a hostname directly to an IP address. A CNAME maps a hostname to another hostname — an alias. `www.example.com CNAME example.com` means www resolves to whatever example.com resolves to. You cannot use a CNAME at the zone apex (the root domain itself) — that's why some DNS providers offer ALIAS or ANAME records.

**What is the difference between a recursive resolver and an authoritative nameserver?**

A recursive resolver (like `8.8.8.8`) does the work of walking the DNS tree on your behalf and caches results. An authoritative nameserver is the final source of truth for a specific domain — it holds the actual A records, CNAMEs, MX records. When you configure DNS for your domain, you're setting records on the authoritative nameserver. When someone resolves your domain, a recursive resolver fetches from your authoritative nameserver and caches the result for the TTL duration.

**What is TTL in DNS?**

Time To Live — how long a DNS record is cached before resolvers must re-query. A TTL of 300 means caches keep the record for 5 minutes. Low TTL (60s) means faster propagation when you change records but more DNS traffic. High TTL (86400s = 24h) means less traffic but slow propagation. Before changing DNS, lower the TTL first and wait for existing caches to expire.

---

## Firewalls · iptables · Security Groups

**What is the difference between stateful and stateless firewalls?**

A stateless firewall evaluates every packet independently against rules — it doesn't know if a packet is part of an established connection. A stateful firewall tracks connection state — it automatically allows return traffic for established connections without an explicit rule. AWS Security Groups are stateful. Basic iptables without connection tracking is stateless. In practice, stateful is almost always what you want — you should not need to write rules for return traffic.

**What is the difference between a Security Group and a Network ACL in AWS?**

Security Groups are stateful, operate at the instance level, and only have allow rules — anything not explicitly allowed is denied. Network ACLs are stateless, operate at the subnet level, have both allow and deny rules, and evaluate rules in number order. For most use cases, Security Groups are sufficient. NACLs add a subnet-level layer when you need explicit deny rules or want defense in depth.

**What does iptables -t nat -L DOCKER -n show you?**

Every DNAT rule Docker has created for port bindings. Each `-p host:container` flag you used creates one entry — the host port maps to the container's private IP and container port. If `webstore-db` has no `-p` flag, it will have no entry here — confirming it's internal only and unreachable from outside Docker.

---

## The Complete Journey

**Walk me through what happens when a user opens `webstore.example.com`.**

The browser checks its DNS cache. On miss, the OS queries the recursive resolver. The resolver walks the DNS tree and gets the A record — the webstore server's public IP. The browser initiates a TCP three-way handshake to port 80 or 443. The packet leaves the user's machine with their private IP, hits their home router, which NAT-translates the source to a public IP. The packet travels across the internet — routers forward it hop by hop, the destination IP stays constant, but the MAC address changes at every hop. The packet arrives at the webstore server's public IP. If there's a load balancer, it DNAT-translates to a backend instance. The server's firewall checks the inbound rule — port 80 or 443 allowed, packet accepted. The OS reads the destination port and delivers to nginx. nginx processes the request. The response travels back the same path in reverse.

**What is the systematic debugging order when a service is unreachable?**

DNS first — `dig webstore.example.com` — does the name resolve? Reachability second — `ping IP` — does the host respond at all? Port third — `nc -zv IP PORT` — is the port open? Service fourth — `curl -v http://IP:PORT` — is the application responding? Logs fifth — check the service logs for what it received. This order matters because each step rules out an entire layer before moving down.

---

← [Back to Networking README](../README.md)
