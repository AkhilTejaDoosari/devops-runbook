[Home](../README.md) |
[Labs Index](./README.md) |
[Lab 01](./01-foundation-addressing-ip-lab.md) |
[Lab 02](./02-devices-subnets-lab.md) |
[Lab 03](./03-ports-transport-nat-lab.md) |
[Lab 04](./04-dns-firewalls-lab.md) |
[Lab 05](./05-complete-journey-lab.md)

---

# Lab 03 — Ports, Transport & NAT

## What this lab is about

You will inspect which ports are listening on your machine, watch the TCP 3-way handshake happen in real time, observe NAT in action through Docker port binding, and confirm that UDP behaves differently from TCP. This maps to files 06 and 07.

## Prerequisites

- [Ports & Transport notes](../06-ports-transport/README.md)
- [NAT notes](../07-nat/README.md)
- Lab 02 completed
- Docker installed

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

**What to observe:**
```
* Connected to example.com port 443
* TLSv1.3 (IN), TLS handshake
  ↑ TCP handshake + TLS on top
```

3. Time the connection (shows TCP establishment speed)
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

1. Test TCP connection (nc = netcat)
```bash
# Test TCP connection to Google DNS port 53
nc -zv 8.8.8.8 53
```

**What to observe:** `Connection to 8.8.8.8 53 port [tcp/domain] succeeded` — TCP handshake completed.

2. Test UDP connection
```bash
# Test UDP connection to Google DNS
nc -zuv 8.8.8.8 53
```

**What to observe:** `Connection to 8.8.8.8 53 port [udp/domain] succeeded` — but UDP has no real handshake, nc just confirms the port is reachable.

3. DNS uses UDP — make a DNS query and watch
```bash
# DNS query goes over UDP
dig google.com

# Check the query section at the bottom
# "SERVER: 8.8.8.8#53(8.8.8.8)"
# ";; Query time: X msec"
```

4. Force DNS over TCP
```bash
dig +tcp google.com
```

**What to observe:** Same result but uses TCP instead of UDP — slightly slower due to handshake overhead.

5. Test a port that's not open
```bash
nc -zv localhost 9999
```

**What to observe:** `Connection refused` — TCP reached the machine but nothing is listening on that port.

---

## Section 4 — NAT in Action with Docker

**Goal:** Prove Docker port binding is NAT — your host translates between public port and container port.

1. Run nginx with port binding
```bash
docker run -d --name nat-test -p 8080:80 nginx
```

2. Confirm port 8080 is now listening on the host
```bash
sudo ss -tlnp | grep 8080
```

**What to observe:** Port 8080 is now listening — Docker created this mapping.

3. Access it from the host
```bash
curl http://localhost:8080
```

**What to observe:** nginx responds — request hit host port 8080, Docker translated to container port 80.

4. See the NAT rule Docker created (iptables)
```bash
sudo iptables -t nat -L DOCKER --line-numbers -n
```

**What to observe:** A DNAT rule exists mapping host port 8080 to the container's IP:80.

5. Check what IP the container has
```bash
docker inspect nat-test | grep IPAddress
```

6. Access the container directly on its IP (bypasses NAT)
```bash
CONTAINER_IP=$(docker inspect nat-test | grep '"IPAddress"' | tail -1 | awk -F'"' '{print $4}')
curl http://$CONTAINER_IP:80
```

**What to observe:** Direct container access on port 80 works — no NAT needed when on the same Docker network.

7. Clean up
```bash
docker stop nat-test && docker rm nat-test
```

---

## Section 5 — Ephemeral Ports

**Goal:** See ephemeral (client-side) ports in action.

1. Make multiple simultaneous connections and watch port numbers
```bash
# Make connections in background
curl -s http://example.com &
curl -s http://example.com &
curl -s http://example.com &

# Quickly check connections
ss -tn | grep example.com
```

**What to observe:** Each connection uses a different source port (49152-65535 range) — ephemeral ports assigned by the OS.

2. See your local port range
```bash
cat /proc/sys/net/ipv4/ip_local_port_range
```

**What to observe:** The range of ports your OS uses for client connections.

---

## Section 6 — Break It on Purpose

### Break 1 — Try to bind to a privileged port without sudo

```bash
python3 -m http.server 80
```

**What to observe:** `Permission denied` — ports below 1024 require root. This is why web servers run as root or use capabilities.

Fix it with a high port:
```bash
python3 -m http.server 8888 &
curl http://localhost:8888
kill %1
```

### Break 2 — Try to bind same port twice

```bash
# Start first server
python3 -m http.server 7777 &

# Try to start second on same port
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
- [ ] I ran Docker with `-p 8080:80` and confirmed port 8080 appeared in `ss -tlnp`
- [ ] I found the Docker DNAT rule in iptables
- [ ] I accessed the Docker container directly by its IP without port binding
- [ ] I produced "Address already in use", "Connection refused", and "Permission denied" errors on purpose
