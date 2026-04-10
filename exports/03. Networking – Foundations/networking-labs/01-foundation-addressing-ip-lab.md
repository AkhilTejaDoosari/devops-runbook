[Home](../README.md) |
[Labs Index](./README.md) |
[Lab 01](./01-foundation-addressing-ip-lab.md) |
[Lab 02](./02-devices-subnets-lab.md) |
[Lab 03](./03-ports-transport-nat-lab.md) |
[Lab 04](./04-dns-firewalls-lab.md) |
[Lab 05](./05-complete-journey-lab.md)

---

# Lab 01 — Foundation, Addressing & IP

## The Situation

The webstore server exists as a machine on a network. It has a network interface. That interface has a MAC address burned into it by the manufacturer. The server has been assigned an IP address — either manually or by DHCP. When nginx starts and listens on port 80, it binds to that IP. When a request arrives, it arrives at that IP.

Before you can understand any of that — before Docker, before AWS, before containers or cloud — you need to see what a real network interface looks like from the terminal. This lab is that foundation. You will inspect your own machine the same way you would inspect a production server on day one.

## What this lab covers

You will inspect your real network interfaces, read MAC and IP addresses, watch ARP work live, identify private vs public IPs, and prove that localhost means different things in different contexts. Everything you see here maps directly to the theory in files 01, 02, and 03.

## Prerequisites

- [Foundation notes](../01-foundation-and-the-big-picture/README.md)
- [Addressing notes](../02-addressing-fundamentals/README.md)
- [IP Deep Dive notes](../03-ip-deep-dive/README.md)
- Linux terminal access

---

## Section 1 — Your Network Interfaces

**Goal:** Find your MAC address, IP address, and understand what each interface is.

1. Show all network interfaces
```bash
ip addr show
```

**What to observe:**
- `lo` — loopback interface (127.0.0.1) — this is localhost
- `eth0` or `ens3` or `wlan0` — your real network interface
- Each interface has a MAC address (`link/ether`) and an IP (`inet`)

2. Show compact view
```bash
ip -brief addr show
```

3. Find just your IP address
```bash
ip addr show | grep 'inet ' | grep -v '127.0.0.1'
```

4. Find just your MAC address
```bash
ip link show | grep 'link/ether'
```

**Write down:**
- Your IP address: _______________
- Your MAC address: _______________
- Your interface name: _______________

---

## Section 2 — Identify Private vs Public IPs

**Goal:** Classify IP addresses as private or public using the three private ranges.

1. Check your current IP
```bash
ip addr show | grep 'inet '
```

**Is your IP in one of these ranges?**
```
10.0.0.0 - 10.255.255.255      → Private
172.16.0.0 - 172.31.255.255    → Private
192.168.0.0 - 192.168.255.255  → Private
```

2. Find your public IP (what the internet sees)
```bash
curl -s ifconfig.me
```

**What to observe:** This is different from your private IP — NAT in action.

3. Compare them
```bash
echo "Private IP:"
ip addr show | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}'
echo "Public IP:"
curl -s ifconfig.me
echo ""
```

**What to observe:** Two completely different IPs. Your router is translating between them using NAT (covered in file 07).

---

## Section 3 — Inspect the ARP Table

**Goal:** Watch ARP work — see IP to MAC mappings on your local network.

1. View your current ARP cache
```bash
arp -a
```

**What to observe:** IP addresses mapped to MAC addresses for devices on your local network. Your router/gateway will almost certainly be in here.

2. Find your default gateway IP
```bash
ip route | grep default
```

3. Check the gateway's MAC in the ARP table
```bash
arp -a | grep $(ip route | grep default | awk '{print $3}')
```

**What to observe:** Your gateway has both an IP (Layer 3) and a MAC (Layer 2). When you send traffic to the internet, your MAC destination is always this gateway — not the final server. The MAC changes at every hop. The IP destination never changes.

4. Ping something to trigger ARP activity
```bash
ping -c 1 8.8.8.8
arp -a
```

**What to observe:** After pinging, new entries may appear in the ARP cache.

5. View ARP in a different format
```bash
ip neigh show
```

---

## Section 4 — Prove Localhost Is Relative

**Goal:** Prove that 127.0.0.1 always means "this machine" — never crosses network boundaries.

1. Ping localhost
```bash
ping -c 3 127.0.0.1
```

**What to observe:** Works instantly — traffic never leaves your machine

2. Ping localhost by name
```bash
ping -c 3 localhost
```

3. Check /etc/hosts — see the localhost entry
```bash
cat /etc/hosts
```

**What to observe:** `127.0.0.1 localhost` is hardcoded here. This is why `localhost` always resolves to 127.0.0.1 — it never touches DNS.

4. Run a quick web server on localhost
```bash
python3 -m http.server 8888 &
sleep 1
curl http://localhost:8888
kill %1
```

**What to observe:** Server starts on localhost, curl reaches it. This traffic never left your machine. This is how the webstore-api connects to webstore-db when both run on the same server.

---

## Section 5 — DHCP in Action

**Goal:** See what DHCP assigned to your machine.

1. View your full network configuration
```bash
ip addr show
ip route show
cat /etc/resolv.conf
```

**What to observe:** DHCP gave you:
- IP address
- Subnet mask (visible in CIDR notation after the IP)
- Default gateway (in `ip route`)
- DNS server (in `/etc/resolv.conf`)

2. Check when your DHCP lease was obtained (if on Ubuntu/Debian)
```bash
cat /var/lib/dhcp/dhclient.leases 2>/dev/null | tail -20
```

3. View your subnet mask from the IP
```bash
ip addr show | grep 'inet ' | grep -v '127.0.0.1'
```

**What to observe:** The `/24` or `/16` after your IP is your subnet mask in CIDR notation. `/24` means `255.255.255.0` — 254 usable addresses in your subnet.

---

## Section 6 — Break It on Purpose

### Break 1 — Ping a non-existent local IP

```bash
ping -c 3 192.168.1.254
```

**What to observe:** Timeout or `Destination Host Unreachable` — ARP sends a broadcast asking who has that IP. Nobody answers. No MAC address found. Packet cannot be delivered.

### Break 2 — Ping an invalid public IP

```bash
ping -c 3 0.0.0.0
```

**What to observe:** Error — `0.0.0.0` is not a valid destination address.

### Break 3 — Confirm private IPs don't route to internet

```bash
traceroute 10.0.0.1
```

**What to observe:** Either reaches a local device or times out quickly — private IPs never route past your gateway to the internet. RFC 1918 addresses are dropped by internet routers.

---

## Checklist

Do not move to Lab 02 until every box is checked.

- [ ] I ran `ip addr show` and identified my MAC address, IP address, and interface name
- [ ] I ran `curl ifconfig.me` and confirmed my public IP is different from my private IP — I understand this is NAT
- [ ] I ran `arp -a` and found my gateway's MAC address — I understand why the gateway has both an IP and a MAC
- [ ] I confirmed my IP is in one of the three private ranges
- [ ] I pinged localhost and confirmed traffic never left my machine
- [ ] I ran a web server on localhost and confirmed it was reachable only via that machine
- [ ] I read `/etc/hosts` and found the localhost entry — I understand it bypasses DNS
- [ ] I identified what DHCP gave me: IP, subnet mask, gateway, DNS server
