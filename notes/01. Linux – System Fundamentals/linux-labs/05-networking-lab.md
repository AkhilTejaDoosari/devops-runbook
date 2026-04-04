[← devops-runbook](../../README.md) |
[Labs Index](./README.md) |
[Lab 01](./01-boot-basics-files-lab.md) |
[Lab 02](./02-filters-sed-awk-lab.md) |
[Lab 03](./03-vim-users-permissions-lab.md) |
[Lab 04](./04-archive-packages-services-lab.md) |
[Lab 05](./05-networking-lab.md)

---

# Lab 05 — Networking

## What this lab is about

You will check your machine's network interfaces and IP addresses, test connectivity with ping and traceroute, resolve DNS with dig, fetch the webstore-frontend with curl, inspect open ports and active connections, and capture live traffic with tcpdump. These are the exact tools you use when debugging a service that is not reachable. Every command is typed from scratch.

## Prerequisites

- [Networking notes](../13-networking/README.md)
- Lab 04 completed — nginx must be installed and running

---

## Section 1 — Network Interfaces and IP Addresses

**Goal:** find your machine's IP address and understand your network interfaces.

1. Show all network interfaces and IP addresses
```bash
ip addr show
```

**What to observe:** at least two interfaces — `lo` (loopback, 127.0.0.1) and one real interface (eth0, ens3, or similar)

2. Show only the interface names and IPs in a compact view
```bash
ip -brief addr show
```

3. Note your machine's IP address — you will use it in later steps
```bash
ip addr show | grep 'inet ' | grep -v '127.0.0.1'
```

---

## Section 2 — Connectivity Testing

**Goal:** verify your machine can reach the outside world and trace the path.

1. Ping Google DNS — stop after 4 packets
```bash
ping -c 4 8.8.8.8
```

**What to observe:** round-trip times and 0% packet loss

2. Ping by hostname — confirms DNS is working
```bash
ping -c 3 google.com
```

**What to observe:** hostname resolves to an IP before pinging

3. Ping localhost — confirms loopback is working
```bash
ping -c 2 localhost
```

4. Trace the route to google.com
```bash
traceroute -n google.com
```

**What to observe:** each hop in the network path from your machine to Google, with response times

5. If traceroute is not installed:
```bash
sudo apt install traceroute -y
```

---

## Section 3 — DNS Resolution

**Goal:** query DNS directly and understand what is happening under the hood.

1. Look up the IP for google.com
```bash
dig google.com
```

**What to observe:** the ANSWER SECTION contains the IP addresses

2. Get just the IP (short output)
```bash
dig +short google.com
```

3. Look up a specific record type (MX = mail server)
```bash
dig MX google.com +short
```

4. Query a specific DNS server directly
```bash
dig @8.8.8.8 google.com +short
```

5. Reverse lookup — find the hostname for an IP
```bash
dig -x 8.8.8.8 +short
```

---

## Section 4 — curl: Talk to the webstore-frontend

**Goal:** use curl to interact with your nginx service the way CI systems and monitoring tools do.

1. Make sure nginx is running
```bash
sudo systemctl status nginx
sudo systemctl start nginx
```

2. Fetch the webstore-frontend page
```bash
curl http://localhost
```

**What to observe:** `<h1>webstore-frontend is live</h1>`

3. Show only the response headers (not the body)
```bash
curl -I http://localhost
```

**What to observe:** `HTTP/1.1 200 OK`, `Server: nginx`, `Content-Type`

4. Follow redirects automatically
```bash
curl -L http://localhost
```

5. Save the response to a file
```bash
curl http://localhost -o /tmp/frontend-response.html
cat /tmp/frontend-response.html
```

6. Time the request
```bash
curl -w "\nTime: %{time_total}s\n" -o /dev/null -s http://localhost
```

7. Test a path that does not exist — observe the 404
```bash
curl -I http://localhost/nonexistent
```

**What to observe:** `404 Not Found`

---

## Section 5 — Open Ports and Active Connections

**Goal:** see which ports your machine is listening on and which connections are active.

1. Show all listening TCP ports
```bash
ss -tlnp
```

**What to observe:** port 80 should appear — nginx is listening

2. Show all listening ports (TCP and UDP)
```bash
ss -tunlp
```

3. Show active established connections
```bash
ss -tnp
```

4. Make a curl request in the background and watch the connection appear
```bash
# In one terminal — run a slow curl
curl http://localhost --limit-rate 1k -o /dev/null &

# In another terminal — watch connections
ss -tnp
```

5. Check which process is listening on port 80
```bash
sudo ss -tlnp | grep :80
```

---

## Section 6 — tcpdump: Capture Live Traffic

**Goal:** capture real packets hitting your nginx service.

1. List available network interfaces
```bash
sudo tcpdump -D
```

2. Capture 5 packets on the loopback interface
```bash
sudo tcpdump -i lo -c 5 -nn
```

3. In one terminal — start capturing HTTP traffic on port 80
```bash
sudo tcpdump -i lo -nn port 80 -c 10
```

4. In another terminal — make a curl request while capture is running
```bash
curl http://localhost
```

**What to observe:** the tcpdump terminal shows the TCP handshake (SYN, SYN-ACK, ACK) and the HTTP request/response packets

5. Save a capture to a file
```bash
sudo tcpdump -i lo -nn port 80 -c 20 -w /tmp/webstore-capture.pcap
```

6. Read the saved capture
```bash
sudo tcpdump -r /tmp/webstore-capture.pcap
```

---

## Section 7 — Break It on Purpose

### Break 1 — curl a port nothing is listening on

1. Stop nginx
```bash
sudo systemctl stop nginx
```

2. Try to curl it
```bash
curl http://localhost
```

**What to observe:** `Connection refused` — no process is listening on port 80

3. Start nginx again
```bash
sudo systemctl start nginx
```

### Break 2 — ping an unreachable host

```bash
ping -c 3 192.168.99.99
```

**What to observe:** `Destination Host Unreachable` or 100% packet loss — the IP is not on your network

### Break 3 — dig a non-existent domain

```bash
dig nonexistent-domain-xyz123.com +short
```

**What to observe:** empty response or NXDOMAIN — the domain does not exist in DNS

### Break 4 — curl with wrong port

```bash
curl http://localhost:9999
```

**What to observe:** `Connection refused` — nothing is listening on port 9999

---

## Checklist

- [ ] I ran `ip addr show` and identified my loopback and real network interfaces
- [ ] I pinged `8.8.8.8` by IP and `google.com` by hostname — and understood why the hostname test also confirms DNS
- [ ] I ran `traceroute -n google.com` and identified the number of hops to reach Google
- [ ] I used `dig +short google.com` and got an IP address back
- [ ] I used `curl http://localhost` and got the webstore-frontend page
- [ ] I used `curl -I` to check response headers and found the HTTP status code and server name
- [ ] I used `ss -tlnp` and confirmed nginx is listening on port 80
- [ ] I captured live HTTP traffic with `tcpdump` while making a curl request and saw the packets appear
- [ ] I stopped nginx and confirmed `curl http://localhost` returns `Connection refused`
- [ ] I ran `dig` on a non-existent domain and understood the NXDOMAIN response
