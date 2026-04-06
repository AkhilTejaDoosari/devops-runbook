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

# AWS EC2 — Elastic Compute Cloud

## What This File Is About

We now understand storage — both local (EBS) and global (S3). But storage by itself doesn't process anything. We need the engine that runs our code and powers our apps. That engine is EC2 (Elastic Compute Cloud) — the virtual machine that ties IAM, VPC, and storage into one working system.

---

## Table of Contents

1. [EC2 Overview & Purpose](#1-ec2-overview--purpose)
2. [Billing & Pricing Models](#2-billing--pricing-models)
3. [AMI & Instance Types](#3-ami--instance-types)
4. [EC2 Lifecycle & States](#4-ec2-lifecycle--states)
5. [Key Pairs & Security Groups](#5-key-pairs--security-groups)
6. [Web Hosting & User Data](#6-web-hosting--user-data)
7. [Instance Metadata & Identity](#7-instance-metadata--identity)
8. [The Webstore-API on EC2](#8-the-webstore-api-on-ec2)

> **Cross-references:** VPC, subnets, and IP concepts are covered in full in [03. VPC & Subnets](../03-vpc-subnet/README.md). EBS storage, snapshots, and cross-AZ copy are in [04. EBS](../04-ebs/README.md). Load balancing and Auto Scaling are in [08. Load Balancing & Auto Scaling](../08-load-balancing-auto-scaling/README.md). Networking foundations (DNS, TCP, OSI layers) are in [03. Networking — Foundations](../../03.%20Networking%20–%20Foundations/README.md).

---

## 1. EC2 Overview & Purpose

### What is EC2?

EC2 stands for **Elastic Compute Cloud**, AWS's service for creating virtual machines in the cloud.
"Elastic" means you can increase or decrease compute capacity on demand — like stretching or shrinking a rubber band depending on workload.
It allows you to rent compute capacity from AWS instead of owning physical servers.
You decide how much **CPU**, **memory**, and **storage** you need — and can scale up or down anytime.

**Use Cases:**
- Hosting websites and APIs
- Running databases or backend servers
- Testing and development environments
- Machine learning workloads

---

## 2. Billing & Pricing Models

### EC2 Billing Basics

You pay for the **time your instance is running**:
- **Linux:** billed **per second** (minimum 60 seconds)
- **Windows:** billed **per hour**

**Example:**
Run a Linux instance for 2 minutes 15 seconds → billed for **135 seconds**.
Windows instances → billed for the full **hour** even if used for 5 minutes.

---

### Free Tier

AWS Free Tier gives:
- **750 hours/month for 12 months**
- Enough to run one small instance continuously

**Instance types:**
- `t2.micro` (older, available in Asia regions)
- `t3.micro` (newer, available in US/EU regions)

---

### Pricing Models

| Model | Description | When to Use |
|---|---|---|
| **On-Demand** | Pay by second/hour. No commitment. | Testing, short workloads |
| **Reserved Instances (RI)** | 1–3 year commitment for up to 72% discount. | Long-running production workloads |
| **Spot Instances** | Use spare AWS capacity, up to 90% cheaper. | Fault-tolerant workloads |
| **Savings Plans** | Commit to $/hour usage, flexible across services. | Predictable workloads |
| **Dedicated Hosts** | Physical server reserved just for you. | Compliance or licensing needs |

**Notes:**
- Linux instances are billed **per-second** (minimum 60 s).
- Windows instances are billed **per hour**.
- Public IPv4 addresses are **billable** outside the Free Tier. The Free Tier covers **750 hours/month** of one public IPv4; additional or idle ones incur charges.
- Elastic IP (EIP) addresses are **free while attached** to a running instance, but **billed when idle** (allocated but unused).

---

## 3. AMI & Instance Types

### Amazon Machine Image (AMI)

An AMI is a **template** used to launch EC2 instances.
It includes:
- Operating System (Linux, Windows, Ubuntu, etc.)
- Preinstalled software (optional)
- Configurations and permissions

**Examples:**
- Ubuntu Server AMI → ready-to-use Linux machine
- Windows Server AMI → preconfigured Windows environment

---

### Instance Types

| Family | Optimized For | Example | Use Case |
|---|---|---|---|
| **General Purpose** | Balanced CPU/RAM | `t3.micro` | Web servers |
| **Compute Optimized** | High CPU | `c5.large` | Batch processing |
| **Memory Optimized** | High RAM | `r5.large` | Databases |
| **Storage Optimized** | High I/O | `i3.large` | Data warehousing |
| **Accelerated (GPU)** | Graphics / ML | `p3.2xlarge` | AI/ML workloads |

---

## 4. EC2 Lifecycle & States

### Lifecycle Stages

| State | Description |
|---|---|
| **Pending** | Preparing resources and booting |
| **Running** | Fully operational and billable |
| **Stopping** | OS shutting down gracefully |
| **Stopped** | Not running, storage billed but compute stops |
| **Terminated** | Deleted permanently |

```
EC2 Instance Lifecycle:

  [Pending] ──► [Running] ──► [Stopping] ──► [Stopped]
                    │                              │
                    │                         [Starting]
                    │                              │
                    └──────────────────────────────┘
                    │
                    ▼
              [Terminated] (permanent, cannot undo)
```

---

## 5. Key Pairs & Security Groups

### Key Pair Authentication

When you create an EC2 instance, AWS uses **public-key cryptography** to ensure secure access.

- The **public key** is the **lock** installed on the instance door (AWS automatically adds it).
- The **private key file** (`.pem` or `.ppk`) that **you download** is the key that fits that lock.

You need this private key every time you want to connect via SSH.
If the key doesn't match the lock → you can't get inside.

**Example: Connecting to EC2 (Linux/macOS)**

```bash
# Step 1: Secure your private key
chmod 400 mykey.pem

# Step 2: Connect to your EC2 instance using SSH
ssh -i mykey.pem ec2-user@<Public-IP>
```

---

### Security Groups (SG)

A **Security Group** acts as a **virtual firewall** controlling inbound and outbound traffic at the instance level.

**Key Rules:**
- **Inbound:** what traffic can reach your instance
- **Outbound:** what traffic your instance can send
- **Stateful:** if you allow inbound, the return traffic is automatically allowed

**Example Security Group for webstore-api:**

| Direction | Protocol | Port | Source | Purpose |
|---|---|---|---|---|
| Inbound | TCP | 8080 | webstore-alb-sg | Traffic from ALB only |
| Inbound | TCP | 22 | Your IP | SSH access |
| Outbound | All | All | 0.0.0.0/0 | All outbound allowed |

**Security Group Chaining (multi-tier pattern):**

```
[Internet]
    │
    ▼
[ALB — webstore-alb-sg]  ← open to 0.0.0.0/0 on 80/443
    │
    ▼
[webstore-api — webstore-api-sg]  ← only allows from webstore-alb-sg
    │
    ▼
[webstore-db — webstore-db-sg]   ← only allows from webstore-api-sg
```

Each layer only accepts traffic from the layer directly above it. The database is unreachable from the internet — not because of NAT (Network Address Translation) or complex routing, but because no SG rule allows it.

---

## 6. Web Hosting & User Data

### Hosting a Simple Website on EC2

You can turn your EC2 into a small web server using **Apache HTTPD**.

**Step 1 – Install Apache**

```bash
sudo yum install -y httpd
```

**Step 2 – Start the service**

```bash
sudo systemctl start httpd
sudo systemctl enable httpd
```

**Step 3 – Allow Traffic**

In your Security Group, open:
- HTTP (80)
- HTTPS (443)

**Step 4 – Create a Web Page**

```bash
cd /var/www/html
sudo bash -c 'echo "<h1>Webstore DevOps Learning</h1>" > index.html'
```

Now visit `http://<Public-IP>` in your browser.

---

### User Data — Automation on First Boot

**User Data scripts** run only once when a new instance starts.
They're used for quick setup — installing software or creating files automatically.

```bash
#!/bin/bash
yum install -y httpd
echo "<h1>Webstore App – 1</h1>" > /var/www/html/index.html
systemctl enable httpd
systemctl start httpd
```

This is like your **"opening-day checklist"** pinned to the door — each new instance runs it automatically before serving traffic.

**User Data notes:**
- Runs as root
- Runs only once — at first launch
- If you stop and start the instance, User Data does not run again
- To run commands on every boot, use `/etc/rc.local` or a systemd service

---

## 7. Instance Metadata & Identity

### Instance Metadata — Facts About Your Instance

This is a local HTTP endpoint inside every EC2 that gives information about itself.
It's only reachable **from within** the instance.

```bash
curl http://169.254.169.254/latest/meta-data/
```

Examples:
- `public-ipv4`
- `instance-id`
- `security-groups`
- `ami-id`

---

### IMDSv2 (Security Upgrade)

Newer version of the metadata service uses **session tokens** for safety.
AWS recommends **enforcing IMDSv2 only**.

```bash
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

curl -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/
```

---

### Instance Identity Document

Signed JSON document that proves which instance you are.

```bash
curl http://169.254.169.254/latest/dynamic/instance-identity/document
```

Shows:
- Region
- Instance ID
- AMI ID
- Account ID

This document is used by tools and services to verify the identity of the instance without relying on credentials.

---

## 8. The Webstore-API on EC2

Before moving to Kubernetes and EKS, the webstore-api tier runs on EC2. Here is what the full deployment looks like:

```
Internet
  │
  ▼
Application Load Balancer (ALB)
  Public subnets — us-east-1a and us-east-1b
  Listener: HTTPS 443 → webstore-api-tg
  Listener: HTTP  80  → redirect to 443
  │
  ├── webstore-api EC2 (us-east-1a, private subnet 10.0.2.0/24)
  │     AMI:            Ubuntu 22.04
  │     Instance type:  t3.medium
  │     IAM role:       webstore-api-role
  │                     (s3:GetObject on webstore-assets/*)
  │                     (ecr:GetAuthorizationToken, ecr:BatchGetImage)
  │     EBS root vol:   20GB gp3
  │     Security group: webstore-api-sg
  │                     (inbound 8080 from webstore-alb-sg only)
  │     User Data:      installs nginx, starts webstore-api service
  │
  └── webstore-api EC2 (us-east-1b, private subnet 10.0.12.0/24)
        Same configuration — second AZ for HA
  │
  ▼
RDS PostgreSQL (private subnets, webstore-db-sg)
  Inbound: 5432 from webstore-api-sg only
```

**What the IAM role provides:**
The `webstore-api-role` attached to each instance gives it permission to:
- Pull product images from S3 (`s3:GetObject` on `webstore-assets/*`)
- Pull container images from ECR

No credentials are hardcoded anywhere. The instance retrieves temporary credentials from the metadata service at `169.254.169.254/latest/meta-data/iam/security-credentials/webstore-api-role`. The SDK picks these up automatically.

**What the User Data does:**
```bash
#!/bin/bash
apt-get update -y
apt-get install -y nginx

# Write nginx config for the API
cat > /etc/nginx/sites-available/webstore-api <<EOF
server {
    listen 8080;
    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host \$host;
    }
}
EOF

ln -s /etc/nginx/sites-available/webstore-api /etc/nginx/sites-enabled/
systemctl enable nginx
systemctl start nginx
```

---

## What You Can Do After This

- Launch an EC2 instance with the correct AMI, instance type, IAM role, and security group
- Write a User Data script that bootstraps an application on first boot
- SSH into an EC2 instance using a key pair
- Explain the difference between Stop and Terminate and what happens to EBS in each case
- Understand what the instance metadata service provides and why it matters for IAM roles
- Design a multi-tier EC2 deployment with ALB and RDS using Security Group chaining

---

## What Comes Next

→ [07. RDS](../07-rds/README.md)

The webstore-db runs as a postgres container in Kubernetes. RDS is what it becomes in production — a managed, multi-AZ PostgreSQL database that AWS operates so you do not have to.
