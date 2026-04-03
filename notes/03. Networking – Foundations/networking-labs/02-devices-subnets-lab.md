[Home](../README.md) |
[Labs Index](./README.md) |
[Lab 01](./01-foundation-addressing-ip-lab.md) |
[Lab 02](./02-devices-subnets-lab.md) |
[Lab 03](./03-ports-transport-nat-lab.md) |
[Lab 04](./04-dns-firewalls-lab.md) |
[Lab 05](./05-complete-journey-lab.md)

---

# Lab 02 — Network Devices & Subnets

## What this lab is about

You will read your routing table and understand every line, watch traceroute reveal the router hops between you and a server, calculate CIDR blocks by hand, identify subnet boundaries, and design a basic VPC subnet plan. This maps to files 04 and 05.

## Prerequisites

- [Network Devices notes](../04-network-devices/README.md)
- [Subnets & CIDR notes](../05-subnets-cidr/README.md)
- Lab 01 completed

---

## Section 1 — Read Your Routing Table

**Goal:** Understand every line of your actual routing table.

1. View your routing table
```bash
ip route
```

**Example output:**
```
default via 192.168.1.1 dev eth0
192.168.1.0/24 dev eth0 proto kernel scope link src 192.168.1.45
```

**What each line means:**

```
default via 192.168.1.1 dev eth0
  ↑         ↑             ↑
  Default   Gateway IP    Interface to use
  route     (router)

  "For everything not matched by a specific route,
   send to 192.168.1.1 via eth0"

192.168.1.0/24 dev eth0 proto kernel scope link
  ↑              ↑
  Your subnet    "Deliver directly, no router needed"

  "For any IP in 192.168.1.0-255, send directly via eth0"
```

2. View more detailed routing table
```bash
netstat -rn
```

3. Find your default gateway
```bash
ip route | grep default | awk '{print $3}'
```

4. Confirm the gateway is reachable
```bash
ping -c 3 $(ip route | grep default | awk '{print $3}')
```

**What to observe:** Gateway responds — your Layer 3 path to the internet is working.

---

## Section 2 — Watch Routing with Traceroute

**Goal:** See each router hop between you and a remote server.

1. Install traceroute if needed
```bash
sudo apt install traceroute -y 2>/dev/null || sudo yum install traceroute -y 2>/dev/null
```

2. Trace route to Google DNS
```bash
traceroute -n 8.8.8.8
```

**What to observe:**
- First hop = your router (default gateway)
- Each subsequent hop = a router on the internet
- Times show latency at each hop
- `* * *` = router not responding to traceroute probes (firewall)

3. Trace to a closer server
```bash
traceroute -n google.com
```

4. Count the hops
```bash
traceroute -n 8.8.8.8 | wc -l
```

5. Compare hops to different destinations
```bash
echo "=== To 8.8.8.8 ===" && traceroute -n -m 10 8.8.8.8
echo "=== To 1.1.1.1 ===" && traceroute -n -m 10 1.1.1.1
```

**What to observe:** Different paths to different destinations — routers make independent forwarding decisions.

---

## Section 3 — CIDR Calculation by Hand

**Goal:** Calculate IP ranges from CIDR notation without a tool.

**The formula:** `Total IPs = 2^(32 - CIDR prefix)`

Work through each one manually before checking:

**Exercise 1: 192.168.1.0/24**
```
Host bits = 32 - 24 = 8
Total IPs = 2^8 = ?
Usable IPs = Total - 2 = ?
Range = 192.168.1.0 to 192.168.1.?
```

**Exercise 2: 10.0.0.0/16**
```
Host bits = 32 - 16 = 16
Total IPs = 2^16 = ?
Range = 10.0.0.0 to 10.0.?.?
```

**Exercise 3: 172.16.0.0/28**
```
Host bits = 32 - 28 = 4
Total IPs = 2^4 = ?
Usable IPs = Total - 2 = ?
Range = 172.16.0.0 to 172.16.0.?
```

2. Verify with ipcalc (install if needed)
```bash
sudo apt install ipcalc -y 2>/dev/null
ipcalc 192.168.1.0/24
ipcalc 10.0.0.0/16
ipcalc 172.16.0.0/28
```

**What to observe:** Confirm your calculations. Focus on: Network, Broadcast, HostMin, HostMax, Hosts/Net.

3. Check if two IPs are in the same subnet
```bash
ipcalc 192.168.1.45/24
ipcalc 192.168.1.200/24
```

**What to observe:** Same Network address → same subnet → can communicate directly without a router.

```bash
ipcalc 192.168.1.45/24
ipcalc 192.168.2.50/24
```

**What to observe:** Different Network address → different subnets → need a router.

---

## Section 4 — Identify Your Subnet

**Goal:** Calculate your own subnet boundaries from your actual IP.

1. Get your IP and prefix
```bash
ip addr show | grep 'inet ' | grep -v '127.0.0.1'
```

2. Calculate your subnet range
```bash
MY_IP=$(ip addr show | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}')
ipcalc $MY_IP
```

**What to observe:**
- Network = first IP in your subnet
- Broadcast = last IP in your subnet
- HostMin = first usable IP
- HostMax = last usable IP

3. Confirm your gateway is in your subnet
```bash
GATEWAY=$(ip route | grep default | awk '{print $3}')
echo "Gateway: $GATEWAY"
ipcalc $MY_IP | grep -E 'Network|HostMin|HostMax'
```

**What to observe:** The gateway IP should be within the HostMin-HostMax range — it's a device on your subnet.

---

## Section 5 — Design a VPC Subnet Plan

**Goal:** Apply CIDR knowledge to plan a real AWS VPC.

This is a paper exercise. Answer each question before moving on.

**Scenario:** You're building the webstore infrastructure on AWS.

**Requirements:**
- VPC CIDR: `10.0.0.0/16`
- 3 tiers: web, api, database
- 2 availability zones (AZ-a and AZ-b)
- Web tier: needs ~50 IPs per AZ
- API tier: needs ~100 IPs per AZ
- DB tier: needs ~20 IPs per AZ

**Questions to answer:**

```
1. How many total IPs does 10.0.0.0/16 give you?
   Answer: ___

2. Which CIDR would you use for each subnet?
   (Remember: AWS reserves 5 IPs per subnet)
   
   Web tier:  needs 50 IPs → use /__ (gives ___ usable)
   API tier:  needs 100 IPs → use /__ (gives ___ usable)
   DB tier:   needs 20 IPs → use /__ (gives ___ usable)

3. Assign non-overlapping CIDRs:
   
   web-az-a:  10.0.___.0/___
   web-az-b:  10.0.___.0/___
   api-az-a:  10.0.___.0/___
   api-az-b:  10.0.___.0/___
   db-az-a:   10.0.___.0/___
   db-az-b:   10.0.___.0/___

4. Do any of your subnets overlap? Check by listing ranges:
   web-az-a: 10.0.___.0 - 10.0.___.___
   web-az-b: 10.0.___.0 - 10.0.___.___
   (and so on)
```

**Reference answer structure (fill in your own values):**
```
VPC: 10.0.0.0/16

web-az-a:  10.0.1.0/24   (254 usable, 251 in AWS)
web-az-b:  10.0.11.0/24
api-az-a:  10.0.2.0/24
api-az-b:  10.0.12.0/24
db-az-a:   10.0.3.0/24
db-az-b:   10.0.13.0/24
```

---

## Section 6 — Break It on Purpose

### Break 1 — Try to ping outside your subnet directly

```bash
# Find an IP that's NOT in your subnet
# If you're on 192.168.1.0/24, try pinging 192.168.2.1
ping -c 3 192.168.2.1
```

**What to observe:** Either times out (no device there) or succeeds via routing — in either case, your machine sent it to the gateway first because it's a different subnet.

Prove it with traceroute:
```bash
traceroute -n 192.168.2.1
```

**What to observe:** First hop is your gateway — even for an address that "looks local."

### Break 2 — Remove default route (careful — restores itself on reconnect)

```bash
# View current routes
ip route

# Note your default gateway IP before proceeding
GATEWAY=$(ip route | grep default | awk '{print $3}')
IFACE=$(ip route | grep default | awk '{print $5}')

# Remove default route temporarily
sudo ip route del default

# Try to reach internet
ping -c 2 8.8.8.8

# Restore immediately
sudo ip route add default via $GATEWAY dev $IFACE

# Confirm restored
ip route
ping -c 2 8.8.8.8
```

**What to observe:** Without default route, internet is unreachable. The routing table entry is not optional.

---

## Checklist

Do not move to Lab 03 until every box is checked.

- [ ] I read my routing table and explained every line in plain English
- [ ] I identified my default gateway and confirmed it responds to ping
- [ ] I ran traceroute to 8.8.8.8 and identified the first hop as my router
- [ ] I calculated total and usable IPs for /24, /16, and /28 by hand — then verified with ipcalc
- [ ] I confirmed my gateway IP is within my subnet range
- [ ] I designed a 6-subnet VPC plan with no overlapping CIDRs
- [ ] I removed the default route temporarily and confirmed internet was unreachable, then restored it
