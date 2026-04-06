[Home](../README.md) |
[Intro](../01-intro-aws/README.md) |
[IAM](../02-iam/README.md) |
[VPC](../03-vpc-subnet/README.md) |
[EBS](../04-ebs/README.md) |
[S3](../05-s3/README.md) |
[EC2](../06-ec2/README.md) |
[RDS](../07-rds/README.md) |
[Load Balancing](../08-load-balancing-auto-scaling/README.md) |
[CloudWatch](../09-cloudwatch-sns/README.md) |
[Route 53](../10-route53/README.md) |
[CLI](../11-cli-cloudformation/README.md) |
[EKS](../12-eks/README.md)

---

# AWS Load Balancer & Auto Scaling — Resilience and Scaling in Action

Once our app is up, we hit the next challenge — growth.
More users mean more requests, and one EC2 can't handle them forever.
This is where Load Balancers and Auto Scaling come in: one spreads the traffic, the other adds or removes servers automatically.
Together they make your system stable, fast, and cost-smart.

---

## Table of Contents

1. [Why We Need Load Balancing & Auto Scaling](#1-why-we-need-load-balancing--auto-scaling)
2. [Load Balancer — The Traffic Director](#2-load-balancer--the-traffic-director)
3. [AWS Load Balancer Types](#3-aws-load-balancer-types)
4. [Health Checks Explained](#4-health-checks-explained)
5. [Auto Scaling — The Self-Healing Mechanism](#5-auto-scaling--the-self-healing-mechanism)
6. [Scaling Policies](#6-scaling-policies)
7. [Monitoring with CloudWatch](#7-monitoring-with-cloudwatch)
8. [Recommended Architecture — Webstore](#8-recommended-architecture--webstore)
9. [Cost, Benefits, and Hands-On](#9-cost-benefits-and-hands-on)

---

## 1. Why We Need Load Balancing & Auto Scaling

When an application runs on a single EC2 instance, it's vulnerable — if that instance fails, users face downtime.
As traffic grows, that single instance also becomes a bottleneck.

**Load Balancing** prevents overload by distributing requests across multiple servers.
**Auto Scaling** ensures the number of servers adjusts automatically with demand.

Together, they create systems that are:
- **Highly available** – no single point of failure
- **Scalable** – adapt to load changes
- **Cost-efficient** – run only what's needed

**Analogy:**
Think of a restaurant during lunch hour. The manager (Load Balancer) sends customers evenly to free tables, and when the rush increases, new waiters are called in (Auto Scaling). When it's quiet again, the extra waiters leave — smooth, efficient, and balanced.

---

## 2. Load Balancer — The Traffic Director

### Purpose

A Load Balancer acts as a **single entry point** for all users, forwarding requests to backend EC2 instances that are healthy and available.

### How It Works

1. Users connect to the LB's DNS name.
2. The LB routes each request to a **Target Group** (group of EC2 instances or IPs).
3. Constant **Health Checks** decide which targets are fit to receive traffic.
4. The LB automatically stops sending traffic to unhealthy instances.

### Core Concepts

| Term | Description |
|---|---|
| **Listener** | Defines protocol and port (e.g., HTTP 80 → Target Group A) |
| **Target Group** | Pool of EC2 targets behind the LB |
| **Rule** | Conditions (path/host/header) used for routing |
| **Cross-Zone LB** | Balances traffic across AZs for fault tolerance |
| **Sticky Sessions** | Keeps a client bound to the same target |
| **TLS Termination** | LB handles HTTPS encryption via ACM certificate |
| **Access Logs** | Store detailed connection data to S3 |

### Simple Architecture

```
Internet Users
│
▼
+------------------+
|  Load Balancer   |
+------------------+
│      │      │
▼      ▼      ▼
EC2-A  EC2-B  EC2-C
```

---

## 3. AWS Load Balancer Types

Each LB type works at a specific **OSI layer** and fits different needs.

| Type | OSI Layer | Think of It As | Ideal For | Why It Fits Best |
|---|---|---|---|---|
| **Application LB (ALB)** | Layer 7 | Smart receptionist who understands full sentences | Web apps (HTTP/HTTPS) | Routes by path/host, supports cookies, redirects, WebSockets, and integrates with ACM & WAF. |
| **Network LB (NLB)** | Layer 4 | Bouncer who checks connection tickets | Gaming, IoT, low-latency or fixed-IP workloads | Handles millions of TCP/UDP connections with static IPs and TLS pass-through. |
| **Gateway LB (GWLB)** | Layer 3 | Security checkpoint inspecting every packet | Firewalls, intrusion detection, network inspection | Transparently inserts appliances into traffic flow. |
| **Classic LB (CLB)** | Layer 4/7 | Old front-desk operator | Legacy EC2 stacks | Simple, but lacks advanced routing and metrics — migrate to ALB/NLB. |

---

### Real-World Scenarios

| Scenario | Best LB | Why This Works |
|---|---|---|
| Multi-path web app (`/`, `/api`, `/login`) | **ALB** | Path-based routing, SSL termination, WAF support. |
| Multiplayer gaming needing static IPs | **NLB** | TCP/UDP speed, minimal latency. |
| Deploying network firewalls (FortiGate, Palo Alto) | **GWLB** | Inserts inspection appliances inline transparently. |
| Legacy monolith (pre-2016) | **CLB → ALB recommended** | Backward compatible, but ALB adds performance & logs. |

---

### OSI Layer Quick View

| Layer | Understands | Example Decision |
|---|---|---|
| **L3 (GWLB)** | IP Packets | "Route 10.0.0.0/16 through firewall." |
| **L4 (NLB)** | Ports & Protocols | "If TCP 443 → EC2-A." |
| **L7 (ALB)** | Full HTTP/HTTPS requests | "If path = /api → Target Group 2." |

---

### Choosing Quickly

| Goal | Choose |
|---|---|
| Smart routing (URLs, headers) | **ALB** |
| Ultra-low latency or static IP | **NLB** |
| Security inspection | **GWLB** |
| Legacy support | **CLB** |

---

## 4. Health Checks Explained

Health Checks are what keep your Load Balancer smart — it constantly asks "Are you okay?" to each target before sending traffic.

**Parameters to Configure:**
- **Protocol & Path** → `HTTP:80 /healthz` or `TCP:22`
- **Healthy Threshold** → How many successes before marking healthy
- **Unhealthy Threshold** → Failures before removing instance
- **Interval** → Frequency of checks
- **Timeout** → Wait time before declaring failure

**Goal:** keep traffic flowing only to **healthy** instances automatically.

---

## 5. Auto Scaling — The Self-Healing Mechanism

When traffic rises, add servers; when it drops, remove them.
That's what Auto Scaling does — **scale dynamically without manual control.**

### Core Components

| Component | Description |
|---|---|
| **Launch Template** | Blueprint defining AMI, instance type, SGs, IAM role, User Data |
| **Auto Scaling Group (ASG)** | Logical group controlling instance count (Min/Desired/Max) |
| **Scaling Policies** | Define how and when scaling occurs |
| **Health Checks** | Replace unhealthy instances automatically |
| **Lifecycle Hooks** | Trigger actions before join/after terminate (warm-up, drain, save logs) |

**Analogy:**
Like a supermarket opening more checkout counters when queues form and closing them when the rush ends — smooth, elastic, cost-efficient.

---

## 6. Scaling Policies

| Policy Type | Trigger | Example |
|---|---|---|
| **Target Tracking** | Maintain a steady metric | Keep CPU ≈ 60% |
| **Step Scaling** | Adjust by threshold steps | +1 instance @ 70%, +2 @ 90% |
| **Simple Scaling** | One threshold → one action | Add 1 instance when CPU > 80% |
| **Scheduled Scaling** | Time-based automation | Weekdays 9 AM scale out, 5 PM scale in |

**Behind the Scenes:**
- Scaling uses **CloudWatch Alarms** to detect thresholds.
- ASG then launches or terminates instances based on that metric.

---

## 7. Monitoring with CloudWatch

**CloudWatch** provides full observability:

| Type | Use |
|---|---|
| **Metrics** | CPU, Network, RequestCountPerTarget, TargetResponseTime |
| **Alarms** | Trigger actions or notifications |
| **Logs** | Collect system/app logs |
| **Dashboards** | Unified view of health and scaling metrics |

Combine these with scaling policies for a closed feedback loop:
*Monitor → Decide → Act → Repeat.*

---

## 8. Recommended Architecture — Webstore

**Goal:** High availability + elastic scaling + cost efficiency.

```
                    Internet Users
                          │
                          ▼
             ┌────────────────────────┐
             │   Application LB (ALB) │  ← HTTPS 443 (ACM certs)
             │   HTTP 80 → redirect   │
             └────────────┬───────────┘
                          │
             ┌────────────┴────────────┐
             ▼                         ▼
     ┌──────────────┐         ┌──────────────┐
     │ webstore-api │         │ webstore-api │
     │  EC2 (AZ-a)  │         │  EC2 (AZ-b)  │
     └──────────────┘         └──────────────┘
             ▲                         ▲
             └──────────┬──────────────┘
                        │
               Auto Scaling Group
               Min=2  Desired=2  Max=6
               ↑ scale out when CPU > 70%
               ↓ scale in  when CPU < 30%
```

- Instances spread across multiple AZs
- Health Checks at ALB and EC2 level (`/healthz` → expect 200 OK)
- Scaling based on CPU or RequestCountPerTarget
- Instance Refresh for rolling updates (new AMI/Launch Template)
- Logging + Alerts via CloudWatch

**ALB listeners for webstore:**
```
Listener: HTTPS 443
  Default rule → webstore-api-tg (port 8080)
  Path /static/* → webstore-frontend-tg (port 80)

Listener: HTTP 80
  Redirect → HTTPS 443 (301)
```

---

## 9. Cost, Benefits, and Hands-On

### Cost Awareness

| Component | Cost Basis | Notes |
|---|---|---|
| **ALB** | per hour + per LCU (Load Balancer Capacity Unit) | Pay for time active + processed traffic |
| **NLB** | per hour + per LCU (new connections, data processed) | Slightly higher but faster |
| **ASG** | Free | Pay only for EC2 and CloudWatch usage |
| **CloudWatch** | per metric + alarms + logs | Optimize by filtering important metrics only |

**Tip:** Right-size instance types and schedule down-scaling windows to reduce bills.

---

### Benefits Recap

| Capability | Handled By | Outcome |
|---|---|---|
| Traffic Distribution | Load Balancer | Balanced user experience |
| Fault Tolerance | LB + ASG | Automatic recovery from failures |
| Cost Efficiency | ASG | Scales down when idle |
| Security & Monitoring | WAF + CloudWatch | Visibility and Protection |

Together they build **resilient, self-adjusting AWS architectures.**

---

### Hands-On Pointers

1. Deploy **ALB** in public subnets; register EC2 targets in private subnets.
2. Create **Launch Template** → link to ASG → attach scaling policy.
3. Configure Health Checks (`/healthz`) and grace periods.
4. Use **ACM** (AWS Certificate Manager) for free SSL/TLS certificates.
5. Verify metrics in **CloudWatch Dashboard**.
6. Test scaling by generating load (e.g., Apache Bench or stress tool).

**Further reading:**
- [AWS Elastic Load Balancing Docs](https://docs.aws.amazon.com/elasticloadbalancing/latest/userguide/what-is-load-balancing.html)
- [Amazon EC2 Auto Scaling Docs](https://docs.aws.amazon.com/autoscaling/ec2/userguide/what-is-amazon-ec2-auto-scaling.html)
- [Amazon CloudWatch Docs](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/WhatIsCloudWatch.html)
- [AWS WAF Integration Guide](https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html)
- [AWS Certificate Manager Overview](https://docs.aws.amazon.com/acm/latest/userguide/acm-overview.html)

---

## What You Can Do After This

- Create an ALB with listeners, target groups, and health checks
- Explain the difference between ALB, NLB, GWLB, and CLB
- Configure an Auto Scaling Group with a Launch Template and scaling policy
- Set up health checks that correctly identify unhealthy instances
- Design the webstore load balancer setup with path-based routing

---

## What Comes Next

→ [09. CloudWatch & SNS](../09-cloudwatch-sns/README.md)

The ALB distributes traffic. The ASG maintains capacity. CloudWatch tells you what all of this is doing — and SNS alerts you when something goes wrong.
