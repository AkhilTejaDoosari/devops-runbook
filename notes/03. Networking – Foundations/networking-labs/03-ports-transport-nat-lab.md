[← devops-runbook](../../README.md) |
[Labs Index](./README.md) |
[Lab 01](./01-foundation-addressing-ip-lab.md) |
[Lab 02](./02-devices-subnets-lab.md) |
[Lab 03](./03-ports-transport-nat-lab.md) |
[Lab 04](./04-dns-firewalls-lab.md) |
[Lab 05](./05-complete-journey-lab.md)

---

# Lab 03 — Ports, Transport & NAT

## What this lab is about

You will inspect which ports are listening on your machine, watch the TCP 3-way handshake happen in real time, observe NAT in action at the iptables level, and confirm that UDP behaves differently from TCP. This maps to files 06 and 07.

## Prerequisites

- [Ports & Transport notes](../06-ports-transport/README.md)
- [NAT notes](../07-nat/README.md)
- Lab 02 completed

---

## Section 1 — Inspect Listening Ports

**Goal:** See which applications are listening on which ports right now.

1. Show all listening TCP ports
```bash
sudo ss -tlnp
```

**Column meanings:**
```
State   = LISTEN (waiting for connections)
Local   = IP:Port the service is bound to
         0.0.0.0:22 = listening on ALL interfaces
         127.0.0.1:631 = listening on localhost only
Process = which program owns the socket
```

2. Show listening UDP ports too
```bash
sudo ss -ulnp
```

3. Show all established TCP connections
```bash
ss -tnp
```

4. Find what's on a specific port
```bash
sudo ss -tlnp | grep :22
sudo ss -tlnp | grep :80
```

5. Check if a port is in use before running a service
```bash
sudo ss -tlnp | grep :8080
# If empty — port is free
```

---

## Section 2 — Watch the TCP Handshake

**Goal:** See SYN → SYN-ACK → ACK happen in real time.

1. Use curl with verbose output to see connection details
```bash
curl -v http://example.com 2>&1 | head -30
```

**What to observe:**
```
* Connected to example.com (93.184.216.34) port 80
  ↑ TCP handshake complete — connection established
```

2. See the full HTTPS handshake
```bash
curl -v https://example.com 2>&1 | head -40
```

3. Time the connection
```bash
curl -w "DNS: %{time_namelookup}s\nConnect: %{time_connect}s\nTotal: %{time_total}s\n" \
  -o /dev/null -s http://example.com
```

**What to observe:** `time_connect` shows how long TCP handshake took.

4. Watch a connection establish and close using ss
```bash
# Terminal 1 — watch connections in real time
watch -n 0.5 'ss -tn | grep example.com'

# Terminal 2 — make a request
curl http://example.com
```

**What to observe:** Connection appears as ESTABLISHED, then moves to TIME_WAIT, then disappears.

---

## Section 3 — TCP vs UDP in Practice

**Goal:** Prove TCP and UDP behave differently.

1. Test TCP connection
```bash
nc -zv 8.8.8.8 53
```

**What to observe:** `Connection to 8.8.8.8 53 port [tcp/domain] succeeded`

2. Test UDP connection
```bash
nc -zuv 8.8.8.8 53
```

3. DNS uses UDP — make a DNS query and observe
```bash
dig google.com
# Note: "SERVER: 8.8.8.8#53" and "Query time"
```

4. Force DNS over TCP
```bash
dig +tcp google.com
```

**What to observe:** Same result but uses TCP — slightly slower due to handshake overhead.

5. Test a port that's not open
```bash
nc -zv localhost 9999
```

**What to observe:** `Connection refused` — TCP reached the machine but nothing listening.

---

## Section 4 — NAT in Action with iptables

**Goal:** See how NAT rules work at the Linux kernel level using iptables.

1. Check what iptables NAT rules currently exist
```bash
sudo iptables -t nat -L -n -v
```

**What to observe:** Existing NAT rules — PREROUTING (DNAT) and POSTROUTING (SNAT) chains.

2. Manually create a port forwarding rule (DNAT) — this is exactly what Docker does
```bash
# Forward host port 9999 to localhost:8080
sudo iptables -t nat -A PREROUTING -p tcp --dport 9999 -j REDIRECT --to-port 8080
```

3. Start a server on port 8080
```bash
python3 -m http.server 8080 &
SERVER_PID=$!
```

4. Access it via the forwarded port
```bash
curl http://localhost:9999
```

**What to observe:** Request to port 9999 is transparently forwarded to 8080 — this is DNAT in action.

5. Verify the iptables rule you created
```bash
sudo iptables -t nat -L PREROUTING -n -v
```

6. Clean up
```bash
sudo iptables -t nat -D PREROUTING -p tcp --dport 9999 -j REDIRECT --to-port 8080
kill $SERVER_PID 2>/dev/null
```

> **Docker NAT walkthrough:** Docker automates all of this — every `-p host:container` flag creates iptables DNAT rules just like you did above. The full Docker-specific walkthrough (docker network inspect, verifying DNAT rules created by Docker, container-to-container vs host access) is in the Docker networking lab.
> → [Docker Lab 02](../../04.%20Docker%20–%20Containerization/docker-labs/02-networking-volumes-lab.md)

---

## Section 5 — Ephemeral Ports

**Goal:** See ephemeral (client-side) ports in action.

1. Make multiple simultaneous connections and watch port numbers
```bash
curl -s http://example.com &
curl -s http://example.com &
curl -s http://example.com &

ss -tn | grep example.com
```

**What to observe:** Each connection uses a different source port (49152-65535 range).

2. See your local port range
```bash
cat /proc/sys/net/ipv4/ip_local_port_range
```

---

## Section 6 — Break It on Purpose

### Break 1 — Try to bind to a privileged port without sudo

```bash
python3 -m http.server 80
```

**What to observe:** `Permission denied` — ports below 1024 require root.

Fix it with a high port:
```bash
python3 -m http.server 8888 &
curl http://localhost:8888
kill %1
```

### Break 2 — Try to bind same port twice

```bash
python3 -m http.server 7777 &
python3 -m http.server 7777
```

**What to observe:** `Address already in use` — only one process can bind to a port at a time.

```bash
kill %1
```

### Break 3 — Connection refused vs timeout

```bash
# Connection refused (port not listening)
nc -zv localhost 9876
# Fast response: "Connection refused"

# Connection timeout (firewall or no route)
nc -zv -w 3 192.0.2.1 80
# Slow response after 3 seconds: "Operation timed out"
```

**What to observe:** Refused = server reachable but nothing listening. Timeout = can't reach the server at all.

---

## Checklist

Do not move to Lab 04 until every box is checked.

- [ ] I ran `ss -tlnp` and identified at least 3 listening services and their ports
- [ ] I used `curl -v` and saw the TCP connection established message
- [ ] I timed a TCP connection with `curl -w` and noted the connect time
- [ ] I used `nc -zv` to test both TCP and UDP connections to port 53
- [ ] I manually created a DNAT iptables rule and confirmed port forwarding worked
- [ ] I verified the iptables rule with `iptables -t nat -L PREROUTING -n`
- [ ] I produced "Address already in use", "Connection refused", and "Permission denied" errors on purpose
