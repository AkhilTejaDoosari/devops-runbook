[Home](../README.md) |
[Labs Index](./README.md) |
[Lab 01](./01-foundation-addressing-ip-lab.md) |
[Lab 02](./02-devices-subnets-lab.md) |
[Lab 03](./03-ports-transport-nat-lab.md) |
[Lab 04](./04-dns-firewalls-lab.md) |
[Lab 05](./05-complete-journey-lab.md)

---

# Lab 05 — The Complete Journey

## What this lab is about

You will trace a complete request from your machine to a real server using every tool from the previous labs — DNS, routing, ports, NAT, firewalls — and document every layer. Then you will simulate a production debugging scenario and use a systematic approach to find and fix the problem. This maps to file 10.

## Prerequisites

- All previous labs completed
- [Complete Journey notes](../10-complete-journey/README.md)

---

## Section 1 — Full Packet Trace to google.com

**Goal:** Document every step of a real request using the tools you've learned.

Run each command and write down what you observe.

**Step 1: DNS — name to IP**
```bash
dig google.com +short
```
Record: `google.com → _______________`

**Step 2: Routing — how does your machine reach that IP?**
```bash
ip route get $(dig google.com +short | head -1)
```
Record: `Packets go via gateway: _______________`

**Step 3: How many hops to get there?**
```bash
traceroute -n -m 15 $(dig google.com +short | head -1)
```
Record: `Number of hops: ___`

**Step 4: Is the port open?**
```bash
nc -zv google.com 443
```
Record: Port 443 open? ___

**Step 5: What does your machine look like to google.com?**
```bash
curl -s https://ifconfig.me
```
Record: `Google sees you as: _______________` (your public IP — NAT in action)

**Step 6: Make the actual HTTP request and see all layers**
```bash
curl -v https://google.com 2>&1 | head -50
```

**What to observe in the verbose output:**
```
* Trying 142.250.190.46:443...    ← Layer 3/4: IP + port
* Connected to google.com         ← TCP handshake complete
* TLSv1.3 (OUT), TLS handshake   ← Layer 6: TLS
> GET / HTTP/2                    ← Layer 7: HTTP request
< HTTP/2 301                      ← Layer 7: HTTP response
```

**Step 7: Capture actual packets (requires sudo)**
```bash
# In one terminal — capture traffic
sudo tcpdump -i any -n host google.com -c 20 2>/dev/null &
TCPDUMP_PID=$!

# In another terminal — make a request
curl -s http://google.com > /dev/null

sleep 2
kill $TCPDUMP_PID 2>/dev/null
```

**What to observe:** Real packets with source/destination IPs and ports. Note how your source port is an ephemeral number.

---

## Section 2 — Document the Full Journey

**Goal:** Write out every layer for a request to google.com in your own words.

Fill in this template based on what you observed:

```
REQUEST: curl https://google.com

Layer 7 (DNS):
  Resolved: google.com → ___.___.___.___ 

Layer 3-4 (Routing + TCP):
  Your private IP: ___.___.___.___ 
  Your gateway:    ___.___.___.___ 
  TCP handshake to: google.com:___

Layer 2 (Local delivery):
  First hop MAC: ___ (your gateway)

NAT (at your router):
  Private IP ___.___.___.___  → Public IP ___.___.___.___ 

Internet transit:
  Number of hops: ___
  MAC changed at each hop
  IP stayed constant: ___.___.___.___ 

At Google:
  Port 443 → HTTPS application
  Response sent back

Return journey:
  NAT translates public IP back to your private IP
  Response delivered to your browser
```

---

## Section 3 — Docker Webstore Simulation

> **This section is covered in the Docker networking lab.**
>
> Running the webstore stack in Docker and tracing DNS, routing, ports, and NAT within containers are hands-on exercises built into the Docker lab. The Docker lab has the complete webstore setup with all verification commands.
>
> → [Docker Lab 02 — Networking & Volumes](../../04.%20Docker%20–%20Containerization/docker-labs/02-networking-volumes-lab.md)
>
> Complete that lab after finishing the networking labs series.

---

## Section 4 — Production Debugging Simulation

**Goal:** Use the systematic debugging framework to find and fix a broken connection.

**Setup — start a web server:**
```bash
python3 -m http.server 4444 &
SERVER_PID=$!
curl -s http://localhost:4444 > /dev/null && echo "Server working"
```

**Break 1 — DNS failure simulation:**
```bash
echo "127.0.0.1 broken-webstore.com" | sudo tee -a /etc/hosts

nslookup working-webstore.com
```

**Debug it:**
```bash
nslookup working-webstore.com
cat /etc/hosts | grep webstore
```

**Fix it:**
```bash
echo "127.0.0.1 working-webstore.com" | sudo tee -a /etc/hosts
nslookup working-webstore.com
curl http://working-webstore.com:4444 -s > /dev/null && echo "Fixed"

sudo sed -i '/webstore.com/d' /etc/hosts
```

---

**Break 2 — Port blocked:**
```bash
sudo iptables -A INPUT -p tcp --dport 4444 -j DROP

curl -m 3 http://localhost:4444
```

**Debug it using the framework:**
```bash
# Step 1: Host reachable?
ping -c 2 localhost

# Step 2: Port open?
nc -zv localhost 4444
# Finding: timeout — firewall blocking

# Step 3: Check firewall rules
sudo iptables -L INPUT -n | grep 4444

# Fix
sudo iptables -D INPUT -p tcp --dport 4444 -j DROP

nc -zv localhost 4444
curl http://localhost:4444 -s > /dev/null && echo "Fixed"
```

---

**Break 3 — Service not running:**
```bash
kill $SERVER_PID 2>/dev/null

curl -m 3 http://localhost:4444
```

**Debug it:**
```bash
# Port open?
nc -zv localhost 4444
# Connection refused — nothing listening

# What's listening?
ss -tlnp | grep 4444
# Nothing — service is down

# Fix
python3 -m http.server 4444 &
SERVER_PID=$!
sleep 1
curl http://localhost:4444 -s > /dev/null && echo "Fixed"

kill $SERVER_PID 2>/dev/null
```

---

## Section 5 — The Interview Answer

**Goal:** Practice explaining the full packet journey out loud.

Open the [networking map](../00-networking-map/README.md) and answer this question as if in an interview:

> "Walk me through exactly what happens when a user opens webstore.com. Start from their browser and end at the server response."

Your answer should cover:
- DNS resolution (what servers are involved)
- TCP handshake
- NAT at the home router
- Internet routing (what changes and what stays the same)
- Cloud entry (IGW, NACL, load balancer, security group)
- Server receives and responds
- Return path

Time yourself. Aim for 90 seconds covering all key points.

---

## Final Checklist

- [ ] I traced a complete request to google.com using dig, ip route, traceroute, nc, and curl -v
- [ ] I filled in the complete journey template with my actual observed values
- [ ] I identified my public IP with `curl ifconfig.me` and confirmed it differs from my private IP
- [ ] I noted that the Docker webstore simulation is in Docker Lab 02
- [ ] I debugged all 3 break scenarios using the systematic framework (DNS → reachability → port → service)
- [ ] I can explain the full packet journey from browser to server in 90 seconds without notes
- [ ] I reviewed the networking map and understand every row
