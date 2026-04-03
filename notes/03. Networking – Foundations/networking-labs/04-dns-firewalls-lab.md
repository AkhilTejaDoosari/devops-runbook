[Home](../README.md) |
[Labs Index](./README.md) |
[Lab 01](./01-foundation-addressing-ip-lab.md) |
[Lab 02](./02-devices-subnets-lab.md) |
[Lab 03](./03-ports-transport-nat-lab.md) |
[Lab 04](./04-dns-firewalls-lab.md) |
[Lab 05](./05-complete-journey-lab.md)

---

# Lab 04 — DNS & Firewalls

## What this lab is about

You will trace a DNS query from your machine all the way to the authoritative server, query different record types, observe TTL caching, write firewall rules that block and allow traffic, and prove the difference between stateful and stateless behavior. This maps to files 08 and 09.

## Prerequisites

- [DNS notes](../08-dns/README.md)
- [Firewalls notes](../09-firewalls/README.md)
- Lab 03 completed

---

## Section 1 — DNS Resolution in Depth

**Goal:** Watch the full DNS resolution chain from your machine to the authoritative server.

1. Basic lookup
```bash
dig google.com
```

**What to observe in the output:**
```
;; ANSWER SECTION:
google.com.    300    IN    A    142.250.190.46
               ↑           ↑    ↑
               TTL         Type IP address

;; Query time: 23 msec
;; SERVER: 8.8.8.8#53
```

2. Short format (just the IP)
```bash
dig google.com +short
```

3. Trace the full resolution chain — root → TLD → authoritative
```bash
dig +trace google.com
```

**What to observe:**
- First queries go to root servers (`.`)
- Root delegates to `.com` TLD
- TLD delegates to google's nameservers
- Google's NS returns the final answer
- Each step shows the delegation chain

4. Query a specific DNS server directly
```bash
# Query Cloudflare instead of your default DNS
dig @1.1.1.1 google.com

# Query Google DNS
dig @8.8.8.8 google.com
```

5. Compare response times between DNS servers
```bash
echo "=== Default DNS ===" && dig google.com | grep "Query time"
echo "=== Cloudflare ===" && dig @1.1.1.1 google.com | grep "Query time"
echo "=== Google DNS ===" && dig @8.8.8.8 google.com | grep "Query time"
```

---

## Section 2 — DNS Record Types

**Goal:** Query different record types and understand what each returns.

1. A record (IPv4 address)
```bash
dig A google.com +short
```

2. AAAA record (IPv6 address)
```bash
dig AAAA google.com +short
```

3. MX record (mail servers)
```bash
dig MX google.com +short
```

4. NS record (authoritative nameservers)
```bash
dig NS google.com +short
```

5. TXT record (text data — SPF, verification, etc.)
```bash
dig TXT google.com +short
```

6. CNAME record (alias)
```bash
dig CNAME www.github.com +short
```

**What to observe:** www.github.com is likely a CNAME pointing to github.com — two DNS lookups happen when you visit it.

7. Reverse DNS lookup (IP to domain)
```bash
dig -x 8.8.8.8 +short
```

---

## Section 3 — DNS Caching and TTL

**Goal:** Observe TTL and prove caching works.

1. Look up a domain and note the TTL
```bash
dig google.com | grep -A1 'ANSWER SECTION'
```

Note the TTL value (e.g., `300`).

2. Query it again immediately
```bash
dig google.com | grep -A1 'ANSWER SECTION'
```

**What to observe:** TTL has decreased — your resolver cached the result and is counting down.

3. Check your local DNS cache
```bash
# If using systemd-resolved
systemd-resolve --statistics | grep -i cache
```

4. Flush DNS cache and see the difference
```bash
# Flush cache
sudo systemd-resolve --flush-caches 2>/dev/null || \
sudo killall -HUP dnsmasq 2>/dev/null || \
echo "Cache flush not available on this system"

# Query again — should take longer (full lookup)
time dig google.com +short
```

5. Test /etc/hosts override
```bash
# Add a fake entry
echo "1.2.3.4 webstore.fake" | sudo tee -a /etc/hosts

# Resolve it
dig webstore.fake +short
nslookup webstore.fake

# /etc/hosts takes priority over DNS
ping -c 1 webstore.fake

# Clean up
sudo sed -i '/webstore.fake/d' /etc/hosts
```

**What to observe:** `/etc/hosts` entries override DNS completely — this is why Docker containers can resolve each other by name even without a DNS server.

---

## Section 4 — Docker DNS

**Goal:** Prove Docker's built-in DNS works for container name resolution.

1. Create a Docker network and two containers
```bash
docker network create webstore-dns-test

docker run -d --name webstore-frontend \
  --network webstore-dns-test \
  nginx

docker run -d --name webstore-api \
  --network webstore-dns-test \
  nginx
```

2. From inside webstore-api, resolve webstore-frontend by name
```bash
docker exec webstore-api nslookup webstore-frontend
```

**What to observe:** Docker's internal DNS (127.0.0.11) resolves `webstore-frontend` to the container's IP automatically.

3. Confirm the DNS server Docker uses
```bash
docker exec webstore-api cat /etc/resolv.conf
```

**What to observe:** `nameserver 127.0.0.11` — Docker's embedded DNS server.

4. Confirm containers can reach each other by name
```bash
docker exec webstore-api curl -s http://webstore-frontend | head -5
```

5. Clean up
```bash
docker stop webstore-frontend webstore-api
docker rm webstore-frontend webstore-api
docker network rm webstore-dns-test
```

---

## Section 5 — Firewall Rules with ufw

**Goal:** Write real firewall rules, test them, and understand stateful behavior.

1. Check current firewall status
```bash
sudo ufw status verbose
```

2. Start a simple web server to use as a target
```bash
python3 -m http.server 7777 &
SERVER_PID=$!

# Confirm it's reachable
curl -s http://localhost:7777 > /dev/null && echo "Server reachable"
```

3. Enable ufw (if not already enabled — careful on remote servers)
```bash
# Only do this if you have console access or are on a local machine
# sudo ufw enable
# For safety, just view rules without enabling
sudo ufw status
```

4. Test iptables rules directly (works without ufw enabled)

Block port 7777 outbound:
```bash
sudo iptables -A OUTPUT -p tcp --dport 7777 -j DROP
```

Test it:
```bash
curl -m 3 http://localhost:7777
```

**What to observe:** Connection times out — iptables dropped the outbound packets.

Remove the rule:
```bash
sudo iptables -D OUTPUT -p tcp --dport 7777 -j DROP
curl -m 3 http://localhost:7777 > /dev/null && echo "Reachable again"
```

5. Block by source IP
```bash
# Block connections from localhost to port 7777
sudo iptables -A INPUT -p tcp -s 127.0.0.1 --dport 7777 -j DROP

# Test — should fail
curl -m 3 http://localhost:7777

# Remove rule
sudo iptables -D INPUT -p tcp -s 127.0.0.1 --dport 7777 -j DROP

# Test — should work
curl -m 3 http://localhost:7777 > /dev/null && echo "Reachable again"
```

6. Clean up server
```bash
kill $SERVER_PID 2>/dev/null
```

---

## Section 6 — Stateful vs Stateless Demonstration

**Goal:** Understand why stateful firewalls are easier by simulating both scenarios.

**Stateful behavior (iptables conntrack — default Linux behavior):**

1. Start a server
```bash
python3 -m http.server 6666 &
SERVER_PID=$!
```

2. Allow inbound port 6666 (simulating Security Group — stateful)
```bash
sudo iptables -A INPUT -p tcp --dport 6666 -j ACCEPT
```

3. Test it works
```bash
curl -s http://localhost:6666 > /dev/null && echo "Works - stateful allows return traffic automatically"
```

**What to observe:** Works because Linux iptables is stateful by default — return traffic is automatically allowed via connection tracking.

4. Now simulate stateless — block all established connections
```bash
sudo iptables -I INPUT -m state --state ESTABLISHED,RELATED -j DROP
curl -m 3 http://localhost:6666
```

**What to observe:** Fails — we blocked the return traffic, simulating stateless behavior.

5. Restore
```bash
sudo iptables -D INPUT -m state --state ESTABLISHED,RELATED -j DROP
sudo iptables -D INPUT -p tcp --dport 6666 -j ACCEPT
kill $SERVER_PID 2>/dev/null
```

**Key insight:** AWS Security Groups use stateful tracking — you only need inbound rules. AWS NACLs are stateless — you need both inbound AND outbound rules including ephemeral ports.

---

## Section 7 — Break It on Purpose

### Break 1 — Query a non-existent domain

```bash
dig nonexistent-domain-xyz99999.com +short
nslookup nonexistent-domain-xyz99999.com
```

**What to observe:** NXDOMAIN — domain does not exist. This is what happens when DNS misconfiguration causes app failures.

### Break 2 — Query with wrong DNS server

```bash
# Query a non-existent DNS server
dig @192.168.99.99 google.com
```

**What to observe:** Timeout — DNS server unreachable. This is what happens when /etc/resolv.conf has wrong nameserver.

### Break 3 — Forget ephemeral ports (NACL simulation)

```bash
python3 -m http.server 5555 &
SERVER_PID=$!

# Allow inbound (like NACL inbound rule)
sudo iptables -A INPUT -p tcp --dport 5555 -j ACCEPT

# Block outbound on specific port (like NACL missing ephemeral rule)
# Client source port will be in ephemeral range — block a specific one
# This simulates what happens when NACL blocks return traffic
sudo iptables -A OUTPUT -p tcp --sport 5555 -j DROP

curl -m 3 http://localhost:5555
```

**What to observe:** Request gets in (inbound allowed) but response is blocked (outbound blocked) — exactly the NACL trap.

```bash
# Fix it
sudo iptables -D OUTPUT -p tcp --sport 5555 -j DROP
sudo iptables -D INPUT -p tcp --dport 5555 -j ACCEPT
kill $SERVER_PID 2>/dev/null
```

---

## Checklist

Do not move to Lab 05 until every box is checked.

- [ ] I ran `dig +trace google.com` and identified root servers, TLD servers, and authoritative servers in the output
- [ ] I queried A, AAAA, MX, NS, TXT, and CNAME record types and know what each returns
- [ ] I queried the same domain twice and observed the TTL counting down — proving caching works
- [ ] I added a fake entry to `/etc/hosts` and confirmed it overrode DNS
- [ ] I set up Docker containers on a custom network and resolved container names with nslookup
- [ ] I used iptables to block a port and confirmed connection timed out, then unblocked and confirmed it worked again
- [ ] I demonstrated stateful behavior (return traffic allowed automatically) vs stateless (return traffic blocked)
- [ ] I queried a non-existent domain and got NXDOMAIN
- [ ] I simulated the NACL trap — inbound allowed but response blocked
