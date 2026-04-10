[Home](../README.md) |
[Labs Index](./README.md) |
[Lab 01](./01-boot-basics-files-lab.md) |
[Lab 02](./02-filters-sed-awk-lab.md) |
[Lab 03](./03-vim-users-permissions-lab.md) |
[Lab 04](./04-archive-packages-services-lab.md) |
[Lab 05](./05-networking-lab.md)

---

# Lab 05 — Networking

## The Situation

Users are reporting that the webstore is slow and sometimes not loading at all. You have no monitoring dashboard. No Datadog. No Grafana. You have a terminal and the networking tools you are about to practice.

Your job is to work from the outside in — confirm reachability first, then DNS, then HTTP, then ports, then the raw packets. Each layer either rules itself out or identifies itself as the problem. By the time you finish this investigation you will know exactly where the issue is.

This is the final Linux lab. By the end of it the webstore has a confirmed working network stack — you have traced every layer from the outside and verified each one. That is the state you hand to Docker in the next tool: a project that works on bare metal, ready to be containerized.

## What this lab covers

You will check your machine's network interfaces and IP addresses, test connectivity with ping and traceroute, resolve DNS with dig, fetch the webstore-frontend with curl, test port connectivity with nc, inspect open ports with ss, and capture live traffic with tcpdump. These are the exact tools you use when debugging a service that is not reachable. Every command is typed from scratch.

## Prerequisites

- [Networking notes](../13-networking/README.md)
- Lab 04 completed — nginx must be installed and running

---

## Section 1 — Network Interfaces and IP Addresses

**Goal:** orient yourself on the server's network — what interfaces exist and what IPs they have.

1. Show all network interfaces and IP addresses
```bash
ip addr show
```

**What to observe:** at least two interfaces — `lo` (loopback, 127.0.0.1) and one real interface (eth0, ens3, or similar). The loopback address is how a service talks to itself on the same machine.

2. Show in compact view
```bash
ip -brief addr show
```

3. Note your machine's actual IP address
```bash
ip addr show | grep 'inet ' | grep -v '127.0.0.1'
```

Record this IP — you will use it in later steps.

4. Show the routing table — how the server decides where to send traffic
```bash
ip route show
```

**What to observe:** `default via X.X.X.X` is your gateway — all traffic not on the local network goes through here.

---

## Section 2 — Connectivity Testing

**Goal:** verify your machine can reach the outside world and trace the path.

1. Ping Google DNS by IP — confirms basic network connectivity without DNS
```bash
ping -c 4 8.8.8.8
```

**What to observe:** round-trip times and 0% packet loss. If this fails, the problem is at the network level — not DNS, not the application.

2. Ping by hostname — confirms DNS is also working
```bash
ping -c 3 google.com
```

**What to observe:** the hostname is resolved to an IP before pinging. If this works but step 1 did not, DNS is the problem.

3. Ping localhost — confirms the loopback interface is up
```bash
ping -c 2 localhost
```

4. Trace the route to google.com — find where latency lives
```bash
traceroute -n google.com
```

**What to observe:** each numbered line is one hop. The times are round-trip latency to that hop. A sudden jump in latency at one hop tells you where the delay is introduced.

5. If traceroute is not installed
```bash
sudo apt install traceroute -y
```

---

## Section 3 — DNS Resolution

**Goal:** query DNS directly and verify hostnames resolve correctly.

1. Look up the IP for google.com
```bash
dig google.com
```

**What to observe:** the ANSWER SECTION contains the IP. The number before `IN A` is the TTL — seconds until this record expires from cache.

2. Get just the IP — short output
```bash
dig +short google.com
```

3. Look up a specific record type
```bash
dig MX google.com +short
```

4. Query a specific DNS server directly — bypass your default resolver
```bash
dig @8.8.8.8 google.com +short
```

5. Reverse lookup — find the hostname for an IP
```bash
dig -x 8.8.8.8 +short
```

6. Trace the full DNS resolution path from root servers down
```bash
dig +trace google.com
```

**What to observe:** the full chain — root servers → TLD servers → authoritative servers. This is how DNS resolution actually works for every hostname lookup.

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

3. Show only the response headers
```bash
curl -I http://localhost
```

**What to observe:** `HTTP/1.1 200 OK`, `Server: nginx/X.X.X`, `Content-Type: text/html`. The status code tells you everything at a glance.

4. Full verbose output — see request headers too
```bash
curl -v http://localhost
```

**What to observe:** lines starting with `>` are the request headers you sent. Lines starting with `<` are the response headers nginx returned.

5. Time the request
```bash
curl -w "\nTime total: %{time_total}s\nTime connect: %{time_connect}s\n" -o /dev/null -s http://localhost
```

**What to observe:** `time_connect` is the TCP handshake time. `time_total` is the full request time. If `time_total` is much larger than `time_connect`, the delay is in the application, not the network.

6. Test a path that does not exist — observe the 404
```bash
curl -I http://localhost/nonexistent
```

**What to observe:** `404 Not Found` — nginx is running and responding, just the resource does not exist.

7. Save the response to a file
```bash
curl http://localhost -o /tmp/frontend-response.html
cat /tmp/frontend-response.html
```

---

## Section 5 — nc: Test Port Connectivity

**Goal:** verify specific ports are open and accepting connections — isolate network from application problems.

1. Test if nginx's port 80 is accepting connections
```bash
nc -zv localhost 80
```

**What to observe:** `Connection to localhost 80 port [tcp/http] succeeded!` — the port is open.

2. Test a port that nothing is listening on
```bash
nc -zv localhost 9999
```

**What to observe:** `Connection refused` — nothing is listening on port 9999.

3. Test with a timeout — fail fast if unreachable
```bash
nc -zv -w 3 localhost 80
```

4. Stop nginx and test again — see the difference
```bash
sudo systemctl stop nginx
nc -zv localhost 80
```

**What to observe:** `Connection refused` — as soon as nginx stops, the port becomes unreachable. This is how you isolate whether a problem is the service or the network.

5. Start nginx again
```bash
sudo systemctl start nginx
nc -zv localhost 80
```

**Why nc matters:** when an application cannot connect to a database or API, you first use `nc -zv host port` to test raw connectivity. If nc fails, it is a network/firewall problem. If nc succeeds, the problem is in the application layer — wrong credentials, wrong protocol, wrong database name.

---

## Section 6 — ss: See What Is Listening

**Goal:** see which ports your machine is listening on and which connections are active.

1. Show all listening TCP ports with process names
```bash
sudo ss -tlnp
```

**What to observe:** port 80 should appear with nginx as the process. Note whether it is bound to `0.0.0.0` (all interfaces) or `127.0.0.1` (local only).

2. Show all listening ports — TCP and UDP
```bash
sudo ss -tunlp
```

3. Show active established connections
```bash
sudo ss -tnp state established
```

4. Make a curl request in the background and watch the connection appear
```bash
curl http://localhost --limit-rate 1k -o /dev/null &
ss -tnp
```

5. Check specifically which process owns port 80
```bash
sudo ss -tlnp | grep :80
```

---

## Section 7 — tcpdump: Capture Live Traffic

**Goal:** capture real packets hitting your nginx service and see the TCP handshake.

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

**What to observe:** the TCP three-way handshake — SYN, SYN-ACK, ACK — then the HTTP request and response packets. This is the full connection lifecycle visible at the packet level.

5. Capture with ASCII payload — see the actual HTTP content
```bash
sudo tcpdump -i lo -A port 80 -c 10
```

Then in another terminal:
```bash
curl http://localhost
```

**What to observe:** the raw HTTP request (`GET / HTTP/1.1`) and response (`HTTP/1.1 200 OK`) visible in the capture.

6. Save a capture to a file
```bash
sudo tcpdump -i lo -nn port 80 -c 20 -w /tmp/webstore-capture.pcap
```

7. Read the saved capture
```bash
sudo tcpdump -r /tmp/webstore-capture.pcap
```

---

## Section 8 — The Full Debug Workflow

**Goal:** run the complete outside-in diagnosis sequence the way you would in a real incident.

Simulate the incident — stop nginx to create the failure:
```bash
sudo systemctl stop nginx
```

Now work through each layer:

```bash
# Step 1 — is nginx running?
sudo systemctl status nginx
# Result: inactive (dead) — found the problem immediately

# Step 2 — is anything listening on port 80?
sudo ss -tlnp | grep :80
# Result: nothing — confirms nginx is not running

# Step 3 — confirm port is unreachable
nc -zv localhost 80
# Result: Connection refused

# Step 4 — confirm curl fails the way users are seeing
curl http://localhost
# Result: Connection refused

# Step 5 — check the logs for why nginx stopped
journalctl -u nginx -n 20
```

Fix it:
```bash
sudo systemctl start nginx
```

Verify each layer is restored:
```bash
sudo ss -tlnp | grep :80         # port is listening
nc -zv localhost 80               # port accepts connections
curl -I http://localhost          # HTTP 200 OK
```

---

## Section 9 — Break It on Purpose

### Break 1 — curl a port nothing is listening on

```bash
sudo systemctl stop nginx
curl http://localhost
```

**What to observe:** `Connection refused` — no process is listening on port 80.

```bash
sudo systemctl start nginx
```

### Break 2 — ping an unreachable host

```bash
ping -c 3 192.168.99.99
```

**What to observe:** `Destination Host Unreachable` or 100% packet loss — the IP is not on your network.

### Break 3 — dig a non-existent domain

```bash
dig nonexistent-domain-xyz123.com +short
```

**What to observe:** empty response — no DNS record exists for this domain. In a real scenario this means either the domain was never created, the DNS record was deleted, or you are querying the wrong DNS server.

### Break 4 — curl with wrong port

```bash
curl http://localhost:9999
```

**What to observe:** `Connection refused` — nothing is listening on port 9999. This is the exact error a misconfigured application sees when it tries to connect to the wrong port.

---

## Checklist

Do not move to Git until every box is checked.

- [ ] I ran `ip addr show` and identified my loopback and real network interfaces — I know what each one is for
- [ ] I pinged `8.8.8.8` by IP and `google.com` by hostname — I understand why testing both confirms different things
- [ ] I ran `traceroute -n google.com` and identified the hops and their latencies
- [ ] I used `dig +short google.com` and got an IP back — I know what TTL means in the output
- [ ] I used `dig +trace` and traced the full DNS resolution chain from root servers down
- [ ] I used `curl -v http://localhost` and identified which lines are request headers and which are response headers
- [ ] I used `curl -w` to measure connection time vs total time
- [ ] I used `nc -zv localhost 80` to confirm port connectivity and `nc -zv localhost 9999` to confirm refusal
- [ ] I stopped nginx and confirmed `nc -zv localhost 80` returns `Connection refused` — then started it and confirmed it succeeds
- [ ] I used `sudo ss -tlnp` and confirmed nginx is listening on port 80
- [ ] I captured live HTTP traffic with `tcpdump -A` while making a curl request and saw the raw HTTP request and response in the output
- [ ] I ran the full outside-in debug workflow in Section 8 and restored nginx at the end
- [ ] I can explain what each tool in this lab tells you that the others do not
