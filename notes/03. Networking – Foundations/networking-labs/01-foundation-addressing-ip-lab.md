[Home](../README.md) |
[Labs Index](./README.md) |
[Lab 01](./01-foundation-addressing-ip-lab.md) |
[Lab 02](./02-devices-subnets-lab.md) |
[Lab 03](./03-ports-transport-nat-lab.md) |
[Lab 04](./04-dns-firewalls-lab.md) |
[Lab 05](./05-complete-journey-lab.md)

---

# Lab 01 — Foundation, Addressing & IP

## What this lab is about

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

**What to observe:** Your gateway has both an IP (Layer 3) and a MAC (Layer 2). When you send traffic to the internet, your MAC destination is always this gateway — not the final server.

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

**What to observe:** `127.0.0.1 localhost` is hardcoded here. This is why `localhost` always resolves to 127.0.0.1.

4. Run a quick web server on localhost
```bash
python3 -m http.server 8888 &
sleep 1
curl http://localhost:8888
kill %1
```

**What to observe:** Server starts on localhost, curl reaches it. This traffic never left your machine.

5. Now run a Docker container and prove container localhost ≠ host localhost
```bash
docker run --rm -d --name test-localhost -p 9999:80 nginx
# Access from host — works (port binding)
curl http://localhost:9999
# Access from inside container — localhost means the container
docker exec test-localhost curl http://localhost:80
# Try to access host's port 9999 from inside container
docker exec test-localhost curl http://localhost:9999
docker stop test-localhost
```

**What to observe:**
- From host: `localhost:9999` works (Docker port binding)
- From inside container: `localhost:80` works (nginx inside container)
- From inside container: `localhost:9999` fails — that port is on the host, not the container

This is the Docker localhost trap that breaks real applications.

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

**What to observe:** The `/24` or `/16` after your IP is your subnet mask in CIDR notation. `/24` means `255.255.255.0`.

---

## Section 6 — Break It on Purpose

### Break 1 — Ping a non-existent local IP

```bash
ping -c 3 192.168.1.254
```

**What to observe:** Timeout or `Destination Host Unreachable` — ARP sends broadcast, no one responds

### Break 2 — Ping an invalid public IP

```bash
ping -c 3 0.0.0.0
```

**What to observe:** Error — `0.0.0.0` is not a valid destination

### Break 3 — Confirm private IPs don't route to internet

```bash
traceroute 10.0.0.1
```

**What to observe:** Either reaches a local device or times out quickly — private IPs never route past your gateway to the internet

---

## Checklist

Do not move to Lab 02 until every box is checked.

- [ ] I ran `ip addr show` and identified my MAC address, IP address, and interface name
- [ ] I ran `curl ifconfig.me` and confirmed my public IP is different from my private IP — I understand this is NAT
- [ ] I ran `arp -a` and found my gateway's MAC address — I understand why the gateway has both an IP and a MAC
- [ ] I confirmed my IP is in one of the three private ranges
- [ ] I pinged localhost and confirmed traffic never left my machine
- [ ] I ran a Docker container and proved that container localhost ≠ host localhost
- [ ] I read `/etc/hosts` and found the localhost entry
- [ ] I identified what DHCP gave me: IP, subnet mask, gateway, DNS server
