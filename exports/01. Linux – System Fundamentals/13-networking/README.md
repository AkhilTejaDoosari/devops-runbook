[Home](../README.md) |
[Boot](../01-boot-process/README.md) |
[Basics](../02-basics/README.md) |
[Files](../03-working-with-files/README.md) |
[Filters](../04-filter-commands/README.md) |
[sed](../05-sed-stream-editor/README.md) |
[awk](../06-awk/README.md) |
[Editors](../07-text-editor/README.md) |
[Users](../08-user-&-group-management/README.md) |
[Permissions](../09-file-ownership-&-permissions/README.md) |
[Archive](../10-archiving-and-compression/README.md) |
[Packages](../11-package-management/README.md) |
[Services](../12-service-management/README.md) |
[Networking](../13-networking/README.md)

# Linux Networking

When something is wrong with a running service, the problem is often in the network layer. nginx is running but not responding. The API cannot reach the database. A port that should be open is not. A request is arriving but taking 3 seconds to respond and you do not know where the delay is.

These tools are how you answer those questions from the command line. No GUI. No external monitoring tool. Just the terminal and the commands that let you see exactly what is happening on the network right now.

---

## Table of Contents

- [1. ip — Inspect Network Interfaces](#1-ip--inspect-network-interfaces)
- [2. ping — Confirm Reachability](#2-ping--confirm-reachability)
- [3. traceroute — Find Where Delay Lives](#3-traceroute--find-where-delay-lives)
- [4. dig — Query DNS](#4-dig--query-dns)
- [5. curl — Test HTTP Endpoints](#5-curl--test-http-endpoints)
- [6. ss — See What Is Listening](#6-ss--see-what-is-listening)
- [7. nc — Test Port Connectivity](#7-nc--test-port-connectivity)
- [8. tcpdump — Capture Live Traffic](#8-tcpdump--capture-live-traffic)
- [9. nmap — Scan Open Ports](#9-nmap--scan-open-ports)
- [10. iftop — Watch Bandwidth Live](#10-iftop--watch-bandwidth-live)
- [11. The Webstore Debug Workflow](#11-the-webstore-debug-workflow)
- [12. Quick Reference](#12-quick-reference)

---

## 1. ip — Inspect Network Interfaces

`ip` shows and configures network interfaces — the connections your server has to the network. When you SSH into a server for the first time, `ip addr` tells you what IP addresses the machine has and on which interfaces.

```bash
# Show all interfaces and their IP addresses
ip addr show

# Output:
# 1: lo: <LOOPBACK,UP,LOWER_UP>
#     inet 127.0.0.1/8 scope host lo
# 2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP>
#     inet 10.0.1.45/24 brd 10.0.1.255 scope global eth0
```

`lo` is the loopback interface — `127.0.0.1`, the address a service uses to talk to itself on the same machine. `eth0` (or `enp3s0` on newer systems) is the real network interface with the server's actual IP.

```bash
# Show the routing table — how the server decides where to send traffic
ip route show

# Output:
# default via 10.0.1.1 dev eth0        ← default gateway
# 10.0.1.0/24 dev eth0 proto kernel    ← local network route

# Show only a specific interface
ip addr show eth0
```

**When you reach for `ip`:**
Confirming the server's IP after provisioning. Checking which interface is active when you have multiple network cards. Verifying the default gateway when traffic is not routing correctly.

---

## 2. ping — Confirm Reachability

`ping` sends ICMP echo requests to a target and measures whether it responds and how long it takes. It answers the most basic question: can this machine reach that machine?

```bash
# Ping the webstore-api from another container or server
ping webstore-api

# Stop after 4 packets
ping -c 4 webstore-api

# Output:
# PING webstore-api (172.18.0.3): 56 data bytes
# 64 bytes from 172.18.0.3: icmp_seq=0 ttl=64 time=0.312 ms
# 64 bytes from 172.18.0.3: icmp_seq=1 ttl=64 time=0.287 ms
# --- webstore-api ping statistics ---
# 4 packets transmitted, 4 received, 0% packet loss
# round-trip min/avg/max = 0.287/0.299/0.312 ms
```

**Reading ping output:**
`time=0.312 ms` is round-trip latency — how long the packet took to go and come back. On a local network this should be under 1ms. Across the internet, 10–50ms is normal. Packet loss above 0% means something is dropping packets between the two machines.

**When `ping` fails:**
A failed ping does not always mean the host is down. Some servers block ICMP deliberately. If ping fails, follow up with `nc` or `curl` to test a specific port before concluding the host is unreachable.

```bash
# Ping the database to confirm network connectivity
ping -c 3 webstore-db

# Ping localhost to confirm the loopback interface is up
ping -c 2 localhost
```

---

## 3. traceroute — Find Where Delay Lives

`traceroute` maps every router hop between you and a destination, showing the latency at each step. When a request is slow and you do not know where the delay is, `traceroute` tells you exactly which hop is adding the time.

```bash
# Trace the path to the webstore API server
traceroute webstore-api.example.com

# Skip DNS lookups — faster, shows only IPs
traceroute -n webstore-api.example.com

# Output:
#  1  10.0.1.1      0.891 ms  0.823 ms  0.812 ms     ← your gateway
#  2  172.16.0.1    1.234 ms  1.198 ms  1.211 ms     ← ISP router
#  3  54.239.1.1    8.456 ms  8.421 ms  8.433 ms     ← AWS edge
#  4  54.239.2.15  10.123 ms 10.098 ms 10.112 ms     ← destination
```

Each line is one hop. Three time values are three probes sent to that hop. `* * *` means a router is blocking traceroute probes — not necessarily broken, just silent.

**When you reach for `traceroute`:**
API response times jumped from 50ms to 800ms. `traceroute` shows hop 3 suddenly adding 700ms — you know the delay is at the ISP level, not your server.

---

## 4. dig — Query DNS

`dig` queries DNS servers directly and shows the full response. When a hostname is not resolving, or resolving to the wrong IP, `dig` shows you exactly what the DNS server returned and which server answered.

```bash
# Look up the IP for webstore-api
dig webstore-api.example.com

# Short answer only — just the IP
dig +short webstore-api.example.com
# 54.239.28.81

# Query a specific DNS server — bypass your default resolver
dig @8.8.8.8 webstore-api.example.com

# Look up the DNS server responsible for a domain (NS record)
dig webstore-api.example.com NS

# Trace the full DNS resolution path from root servers down
dig +trace webstore-api.example.com

# Check if a domain has an MX record
dig webstore-api.example.com MX
```

**What the `dig` output tells you:**

```
;; ANSWER SECTION:
webstore-api.example.com.  300  IN  A  54.239.28.81
#                          ^^^
#                          TTL — seconds until this record expires from cache
```

TTL (Time to Live) is how long resolvers cache this answer. A TTL of 300 means DNS changes take up to 5 minutes to propagate. If you just updated a DNS record and it is not working yet, check the TTL.

**When you reach for `dig`:**
You deployed to a new server and updated the DNS record but traffic is still hitting the old server. `dig +short` shows the old IP is still being returned — the TTL has not expired yet.

---

## 5. curl — Test HTTP Endpoints

`curl` makes HTTP requests from the terminal. It is how you test whether a service is responding correctly without opening a browser — essential on a server with no GUI.

```bash
# Test the webstore-api is responding
curl http://localhost:8080

# Test with verbose output — see request headers and response headers
curl -v http://localhost:8080/api/products

# Test only the response headers — useful for checking status codes
curl -I http://localhost:8080/api/products
# HTTP/1.1 200 OK
# Content-Type: application/json
# ...

# POST request with a JSON body — testing the orders endpoint
curl -X POST http://localhost:8080/api/orders \
  -H "Content-Type: application/json" \
  -d '{"product_id": 1, "quantity": 2}'

# Follow redirects automatically
curl -L http://webstore.example.com

# Test with a specific Host header — testing virtual host routing
curl -H "Host: webstore.example.com" http://localhost

# Set a timeout — fail if no response in 5 seconds
curl --max-time 5 http://localhost:8080/api/products

# Save response to a file
curl http://localhost:8080/api/products -o products.json
```

**Reading curl -I output:**
The HTTP status code tells you immediately what happened — `200 OK` means success, `301/302` means redirect, `404` means not found, `502 Bad Gateway` means nginx received the request but the upstream API did not respond, `503 Service Unavailable` means nginx could not reach the upstream at all.

**When you reach for `curl`:**
After a deploy, before announcing the service is up. After editing nginx config, to confirm the new routing is working. When a user reports an endpoint is broken — reproduce it from the server with curl to confirm and capture the exact response.

---

## 6. ss — See What Is Listening

`ss` shows socket statistics — every active network connection and every port the server is listening on. It replaced `netstat` on modern Linux systems.

```bash
# Show all listening TCP ports with process names
sudo ss -tlnp

# Output:
# State    Recv-Q  Send-Q  Local Address:Port  Peer Address:Port  Process
# LISTEN   0       511     0.0.0.0:80         0.0.0.0:*          users:(("nginx",pid=1235,fd=6))
# LISTEN   0       128     0.0.0.0:22         0.0.0.0:*          users:(("sshd",pid=845,fd=3))
# LISTEN   0       128     127.0.0.1:5432     0.0.0.0:*          users:(("postgres",pid=987,fd=5))
```

Reading this output: port 80 is nginx listening on all interfaces (`0.0.0.0`) — accessible from outside. Port 5432 is postgres listening only on `127.0.0.1` — only accessible locally, not from outside the server. Port 22 is sshd.

```bash
# Show all TCP and UDP connections with process names — numeric only
sudo ss -tunp

# Show connections to a specific port — who is connected to port 8080
sudo ss -t dst :8080

# Show established connections only
sudo ss -t state established

# Check if nginx is listening on port 80
sudo ss -tlnp | grep :80
```

**When you reach for `ss`:**
You deployed nginx but `curl http://localhost` is not responding. `ss -tlnp` shows nginx is not in the list — it failed to start or is not bound to the expected port. Or you see port 8080 is not in the list — the API service is not running.

---

## 7. nc — Test Port Connectivity

`nc` (netcat) opens a raw TCP or UDP connection to a port. It is the fastest way to test whether a specific port is open and accepting connections — without needing to speak the full protocol of whatever service is running there.

```bash
# Test if port 8080 on the API server is accepting connections
nc -zv webstore-api 8080
# Connection to webstore-api 8080 port [tcp/*] succeeded!

# Test if the database port is reachable
nc -zv webstore-db 5432
# Connection to webstore-db 5432 port [tcp/*] succeeded!

# Test with a timeout — fail after 3 seconds
nc -zv -w 3 webstore-api 8080

# Test if port 80 is open on a remote server
nc -zv webstore.example.com 80
```

`-z` means zero I/O — just test the connection, do not send data. `-v` is verbose — shows whether the connection succeeded or failed.

**When you reach for `nc`:**
The API cannot connect to the database. Before debugging the application, use `nc -zv webstore-db 5432` from the API server. If nc fails, it is a network problem. If nc succeeds, the problem is in the application layer — wrong credentials, wrong database name, wrong connection string.

---

## 8. tcpdump — Capture Live Traffic

`tcpdump` captures raw network packets in real time. It shows you exactly what is going over the wire — every request, every response, every header. It is the deepest debugging tool in this list and the one you reach for when everything else has failed to explain what is happening.

```bash
# Capture all traffic on eth0 — stop with Ctrl+C
sudo tcpdump -i eth0

# Capture only HTTP traffic on port 80
sudo tcpdump -i eth0 port 80

# Capture traffic to or from the webstore-api IP
sudo tcpdump -i eth0 host 10.0.1.45

# Capture with no DNS lookups — shows IPs not hostnames
sudo tcpdump -i eth0 -n port 80

# Capture and show packet contents in ASCII
sudo tcpdump -i eth0 -A port 8080

# Save capture to a file for analysis
sudo tcpdump -i eth0 -w webstore-capture.pcap port 8080

# Read from a saved capture file
sudo tcpdump -r webstore-capture.pcap
```

**When you reach for `tcpdump`:**
`curl` returns a response but it looks wrong. `ss` shows connections are being established. But something in the data is not right. `tcpdump -A port 8080` shows you the raw HTTP request and response — every header, every body. You can see exactly what nginx is sending and what it is receiving.

---

## 9. nmap — Scan Open Ports

`nmap` probes a host or range of hosts and reports which ports are open. On your own servers, it confirms your firewall is configured correctly — that only the ports you intend to expose are exposed.

```bash
# Scan the webstore server — which ports are open?
nmap webstore.example.com

# Scan specific ports only
nmap -p 22,80,443,8080 webstore.example.com

# Scan with service version detection
nmap -sV webstore.example.com

# Fast scan — top 100 most common ports
nmap -F webstore.example.com

# Output:
# PORT     STATE  SERVICE
# 22/tcp   open   ssh
# 80/tcp   open   http
# 8080/tcp open   http-proxy
# 5432/tcp closed postgresql   ← good — DB should not be exposed
```

**When you reach for `nmap`:**
After configuring a firewall, confirm that port 5432 (database) is closed to the outside world and port 80 is open. `nmap` from an external machine gives you the attacker's view of your server — what they can see.

---

## 10. iftop — Watch Bandwidth Live

`iftop` shows a real-time view of network bandwidth usage per connection. When a server is saturating its network link and you need to know which connection is consuming it, `iftop` shows you immediately.

```bash
# Watch all traffic on eth0
sudo iftop -i eth0

# Show IPs only — no DNS lookups
sudo iftop -n -i eth0
```

Press `q` to quit. The display shows source and destination IPs with bandwidth rates — 2s, 10s, and 40s averages.

**When you reach for `iftop`:**
A server's network usage jumped to 90% of capacity. `iftop` shows one IP address consuming almost all of it — a likely sign of a backup job, a runaway log shipper, or a DDoS attempt.

---

## 11. The Webstore Debug Workflow

This is the sequence you follow when something is wrong with the webstore and you need to isolate where the problem is. Work from the outside in — network first, then application.

**Scenario: users report the webstore is not loading**

```bash
# Step 1 — is nginx running and listening on port 80?
sudo ss -tlnp | grep :80
# If nothing appears — nginx is not listening. Check status:
sudo systemctl status nginx
journalctl -u nginx -n 20

# Step 2 — can the server respond to HTTP at all?
curl -I http://localhost
# 200 OK → nginx is up
# Connection refused → nginx is not running or not bound to port 80

# Step 3 — can the API be reached from the frontend server?
nc -zv webstore-api 8080
# succeeded → port is open, network is fine
# failed → check if the API service is running, check firewall

# Step 4 — is the API actually responding correctly?
curl -v http://webstore-api:8080/api/products
# Check status code and response body

# Step 5 — can the API reach the database?
nc -zv webstore-db 5432
# succeeded → database port is reachable
# failed → database is down or firewall is blocking

# Step 6 — is DNS resolving correctly?
dig +short webstore-api.example.com
# Compare to the IP you expect

# Step 7 — if traffic is getting in but responses are wrong, capture it
sudo tcpdump -A -i eth0 port 8080 -c 20
# Read the raw HTTP request and response
```

Work through each step in order. Each command either confirms a layer is working or identifies where the break is.

---

## 12. Quick Reference

| Command | What it does | When you reach for it |
|---|---|---|
| `ip addr show` | Show all interfaces and IP addresses | First thing after SSHing into a new server |
| `ip route show` | Show routing table | Diagnosing routing problems |
| `ping -c 4 <host>` | Test reachability with 4 packets | Confirming two machines can reach each other |
| `traceroute -n <host>` | Trace route, show IPs only | Finding which hop is adding latency |
| `dig +short <host>` | Quick DNS lookup | Confirming a hostname resolves to the right IP |
| `dig +trace <host>` | Full DNS resolution trace | Debugging DNS propagation after a record change |
| `curl -I <url>` | Show HTTP response headers only | Checking status code without full body |
| `curl -v <url>` | Verbose HTTP request and response | Debugging headers, auth, redirects |
| `sudo ss -tlnp` | Show listening TCP ports with process names | Confirming a service is bound to the right port |
| `sudo ss -tunp` | Show all TCP and UDP connections | Full socket inventory |
| `nc -zv <host> <port>` | Test if a port is open | Isolating network vs application problems |
| `sudo tcpdump -i eth0 port <port>` | Capture traffic on a specific port | Deep packet inspection when nothing else explains it |
| `sudo tcpdump -A -i eth0 port <port>` | Capture with ASCII payload | Reading raw HTTP request and response content |
| `nmap -p <ports> <host>` | Scan specific ports | Verifying firewall rules from outside |
| `sudo iftop -n -i eth0` | Watch bandwidth per connection live | Finding which connection is saturating the link |

---

→ Ready to practice? [Go to Lab 05](../linux-labs/05-networking-lab.md)
