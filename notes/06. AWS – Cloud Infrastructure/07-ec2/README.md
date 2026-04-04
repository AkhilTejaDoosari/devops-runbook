[← devops-runbook](../../README.md) | 
[Intro to AWS](../01-intro-aws/README.md) | 
[IAM](../02-iam/README.md) | 
[VPC & Subnet](../03-vpc-subnet/README.md) | 
[EBS](../04-ebs/README.md) | 
[EFS](../05-efs/README.md) | 
[S3](../06-s3/README.md) | 
[EC2](../07-ec2/README.md) | 
[RDS](../08-rds/README.md) | 
[Load Balancing & Auto Scaling](../09-Load-balancing-auto-scaling/README.md) | 
[CloudWatch & SNS](../10-cloudwatch-sns/README.md) | 
[Lambda](../11-lambda/README.md) | 
[Elastic Beanstalk](../12-elastic-beanstalk/README.md) | 
[Route 53](../13-route53/README.md) | 
[CLI + CloudFormation](../14-cli-cloudformation/README.md)

# AWS EC2 – Elastic Compute Cloud

We now understand storage — both local (EBS) and global (S3).
But storage by itself doesn’t process anything.
We need the engine that runs our code and powers our apps.
That engine is EC2 (Elastic Compute Cloud) — the virtual machine that ties IAM, VPC, and storage into one working system.

## Table of Contents

1. [EC2 Overview & Purpose](#1-ec2-overview--purpose)  
2. [Billing & Pricing Models](#2-billing--pricing-models)  
3. [AMI & Instance Types](#3-ami--instance-types)  
4. [EC2 Lifecycle & States](#4-ec2-lifecycle--states)  
5. [Key Pairs & Security Groups](#5-key-pairs--security-groups)  
6. [Understanding VPC & Subnets](#6-understanding-vpc--subnets)  
7. [IP Concepts (Private, Public, Elastic, ENI)](#7-ip-concepts-private-public-elastic-eni)  
8. [Storage (EBS, Snapshots, FSR, Archive, Cross-AZ/Region Patterns)](#8-storage-ebs-snapshots-fsr-archive-cross-azregion-patterns)  
9. [Web Hosting (httpd) & User Data](#9-web-hosting-httpd--user-data)  
10. [Instance Metadata & Identity (IMDSv2, Signed Docs, Role Creds)](#10-instance-metadata--identity-imdsv2-signed-docs-role-creds)  
11. [Networking Foundations](#11-networking-foundations)  
12. [Load Balancer (with Health Checks)](#12-load-balancer-with-health-checks)  
13. [Auto Scaling & Monitoring](#13-auto-scaling--monitoring)

---

<details>
<summary><strong>1. EC2 Overview & Purpose</strong></summary>

### What is EC2?

EC2 stands for **Elastic Compute Cloud**, AWS’s service for creating virtual machines in the cloud.
“Elastic” means you can increase or decrease compute capacity on demand — like stretching or shrinking a rubber band depending on workload.   
It allows you to rent compute capacity from AWS instead of owning physical servers.  
You decide how much **CPU**, **memory**, and **storage** you need — and can scale up or down anytime.

**Use Cases:**
- Hosting websites and APIs  
- Running databases or backend servers  
- Testing and development environments  
- Machine learning workloads  

**Analogy:**  
Think of AWS as a massive data center. EC2 lets you rent one computer inside it — and you can turn it on, off, or resize it anytime.

📸 **Image:** [AWS EC2 Concepts](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/concepts.html)

</details>

---

<details>
<summary><strong>2. Billing & Pricing Models</strong></summary>

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
|-------|--------------|-------------|
| **On-Demand** | Pay by second/hour. No commitment. | Testing, short workloads |
| **Reserved Instances (RI)** | 1–3 year commitment for up to 72% discount. | Long-running production workloads |
| **Spot Instances** | Use spare AWS capacity, up to 90% cheaper. | Fault-tolerant workloads |
| **Savings Plans** | Commit to $/hour usage, flexible across services. | Predictable workloads |
| **Dedicated Hosts** | Physical server reserved just for you. | Compliance or licensing needs |

> 💡 **Note:**  
> - **Linux instances** are billed **per-second** (minimum 60 s).  
> - **Windows instances** are billed **per hour**.  
> - **Public IPv4 addresses** are now **billable** outside the Free Tier.  
>   The Free Tier covers **750 hours / month** of one public IPv4; additional or idle ones incur charges.  
> - **Elastic IP (EIP)** addresses are **free while attached** to a running instance, but **billed when idle** (allocated but unused).

📸 **Image:** [AWS EC2 Pricing](https://aws.amazon.com/ec2/pricing/)

</details>

---

<details>
<summary><strong>3. AMI & Instance Types</strong></summary>

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
|---------|----------------|----------|-----------|
| **General Purpose** | Balanced CPU/RAM | `t3.micro` | Web servers |
| **Compute Optimized** | High CPU | `c5.large` | Batch processing |
| **Memory Optimized** | High RAM | `r5.large` | Databases |
| **Storage Optimized** | High I/O | `i3.large` | Data warehousing |
| **Accelerated (GPU)** | Graphics / ML | `p3.2xlarge` | AI/ML workloads |

**Analogy:**  
Each instance type is like a car built for a purpose — a sports car for speed, a truck for heavy loads, etc.

📸 **Image:** [AWS Instance Types](https://aws.amazon.com/ec2/instance-types/)

</details>

---

<details>
<summary><strong>4. EC2 Lifecycle & States</strong></summary>

### Lifecycle Stages

| State | Description |
|--------|--------------|
| **Pending** | Preparing resources and booting |
| **Running** | Fully operational and billable |
| **Stopping** | OS shutting down gracefully |
| **Stopped** | Not running, storage billed but compute stops |
| **Terminated** | Deleted permanently |

**Analogy:**  
Think of EC2 like a laptop:  
- Booting → Pending  
- Working → Running  
- Sleep → Stopped  
- Factory reset → Terminated  

📸 **Image:**  
<img src="images/EC2_instance_lifecycle.png" alt="EC2 Lifecycle" width="550"/>

</details>

---

<details>
<summary><strong>5. Key Pairs & Security Groups</strong></summary>

### Key Pair Authentication

When you create an EC2 instance, AWS uses **public-key cryptography** to ensure secure access — just like how every home has its own unique lock and key.

**Analogy:**  
If your **EC2 instance is your home**:
- The **public key** is the **lock** installed on the home’s door (AWS automatically adds it to your instance).  
- The **private key file** (`.pem` or `.ppk`) that **you download** is the **key** that fits that lock.  

You need this private key every time you want to enter (connect via SSH or RDP).  
If the key doesn’t match the lock → you can’t get inside.

---

#### Example: Connecting to EC2 (Linux/macOS)

```bash
# Step 1: Secure your private key
chmod 400 mykey.pem

# Step 2: Connect to your EC2 instance using SSH
ssh -i mykey.pem ec2-user@<Public-IP>
````

If the **private key** matches the **public key lock** on the instance:
✅ Access granted — you’ve entered your EC2 “home.”

If not:
❌ Permission denied — wrong or missing key.

📸 **Image:** [AWS EC2 Key Pairs](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html)

---

### Security Groups (SG)

A Security Group acts as a **virtual firewall**.

* **Inbound rules** → what traffic can enter
* **Outbound rules** → what traffic can exit
* **Stateful** → return traffic automatically allowed

| Protocol | Port | Use Case           |
| -------- | ---- | ------------------ |
| SSH      | 22   | Remote login       |
| HTTP     | 80   | Web traffic        |
| HTTPS    | 443  | Secure web traffic |

📸 **Image:** [VPC Security Groups](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_SecurityGroups.html)

</details>

---

<details>
<summary><strong>6. Understanding VPC & Subnets</strong></summary>

---

## 🌍 AWS as a Planet – The Big Picture

Before learning about IPs, it’s important to understand **where** everything in AWS lives.

Think of **AWS** as a **digital planet** made up of continents (Regions) and cities (Availability Zones).  
On this planet, every user can carve out their own **private island**, completely isolated from others — that island is your **VPC (Virtual Private Cloud)**.

---

### 🏝️ 1. What is a VPC?

A **VPC (Virtual Private Cloud)** is your **own private island** on the AWS planet.  
It’s a completely secure and customizable environment where you host your AWS resources such as EC2 instances, databases, and load balancers.

Inside this island, you control:
- **Borders:** IP address range (e.g., `10.0.0.0/16`)  
- **Security:** Who can enter or leave (Security Groups, NACLs, Route Tables)  
- **Connectivity:** Whether to open your island to the ocean (Internet) or stay isolated  

**Analogy:**  
> Think of a VPC as your **private country or island** in the AWS world.  
> You make the rules, build the infrastructure, and decide who can visit or communicate.

---

### 🧱 2. What is a Subnet?

A **Subnet** is a smaller **district or region** inside your private island (VPC).  
You divide your island into multiple subnets to separate workloads based on their accessibility.

Each subnet exists within one **Availability Zone (AZ)** — meaning if you have 3 AZs in your AWS Region, your island can have 3 major districts (subnets) across them.

| Subnet Type | Analogy | Connectivity | Common Use |
|--------------|----------|--------------|-------------|
| **Public Subnet** | Coastal city with open ports | Connected to the **Internet Gateway (IGW)** | Web servers, Bastion hosts |
| **Private Subnet** | Inland city with guarded roads | No direct internet connection (internal only) | Databases, Application servers |

---

### 🧩 3. How They Work Together

1. The **VPC** provides your island (the overall network boundary).  
2. You divide it into **Subnets** — each district serving a purpose (public or private).  
3. You connect a **Public Subnet** to the **Internet Gateway** — allowing outside traffic to visit.  
4. You keep **Private Subnets** isolated — only accessible through internal connections.

---

### 💡 Planet Analogy Summary

| AWS Concept | Real-World Analogy | Description |
|--------------|--------------------|--------------|
| **AWS Cloud** | The entire planet | Global infrastructure shared by all AWS users |
| **Region** | Continent | Large geographic area (e.g., North America, Asia) |
| **Availability Zone (AZ)** | City on a continent | Data center cluster within a region |
| **VPC** | Private island or country | Your own isolated network on the AWS planet |
| **Subnet** | District or region on your island | Divides your island into zones for specific use |
| **Public Subnet** | Coastal city with ports | Internet-facing zone for public services |
| **Private Subnet** | Inland city or lab | Internal-only zone for secure data storage |

---

### 🖼️ Visual Diagram

```
                🌍 AWS Planet
                       │
          ┌────────────┴────────────┐
          │                         │
  (Other Users’ Islands)     🏝️ Your VPC (Private Island)
                                     │
          ┌──────────────────────────┴──────────────────────────┐
          │                                                     │
 🌊 Public Subnet (Coastal City)                     🏞️ Private Subnet (Inland City)
  - Connected to Internet Gateway                    - No direct internet access
  - Hosts Web Servers                                - Hosts Databases & Internal Apps
  - Has Public & Private IPs                         - Has only Private IPs
```

---

### 🧠 One-Line Takeaway

> **AWS is the Planet 🌍**  
> **VPC is your Private Island 🏝️**  
> **Subnets are the Districts or Zones on that Island 🧱**  
> **Public Subnets face the sea (Internet Gateway), while Private Subnets stay inland (internal communication).**

📸 **Reference:**  
[AWS VPC Overview – Official Documentation](https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html)

---

</details>

---

<details>
<summary><strong>7. IP Concepts (Private, Public, Elastic, ENI)</strong></summary>

## 🌐 IP Concepts – Addresses on Your Island

Every EC2 instance inside your **VPC (Private Island)** needs a way to communicate — both **within the island** and **with the outside world**.  
That’s where **IP addresses** come in.  

Each EC2 instance can have:
- **Private IP** → used within your island (local communication)
- **Public IP** → used to connect with the outside ocean (internet)
- **Elastic IP** → a permanent public address (reserved port)
- **ENI (Elastic Network Interface)** → the network card that holds these addresses

---

### 🧩 1. Private IP – The House Address Inside the Island

Whenever you build a house (launch an EC2 instance) on your island, AWS automatically assigns it a **Private IP address**.  

This address is used for **internal communication** —  
for example, your bakery (web server) talking to your storage warehouse (database) — all within your fenced island.  

A Private IP **stays the same** even if you restart the house’s power (stop/start the instance),  
but it is **released permanently** if you demolish the house (terminate the instance).  

Private IPs are **free of cost** and **not visible from the ocean (internet)** — they work only within your island’s local boundaries.

📘 **Example**
```

Instance A → Private IP: 10.0.0.5
Instance B → Private IP: 10.0.0.8

```

Both houses can exchange letters (data) freely because they live inside the same fenced island (VPC).

💡 **Analogy:**  
A **Private IP** is your **house address inside the island** — neighbors can visit you,  
but no ship sailing on the ocean can see or reach you.

📸 **Image:** [Private IP Addressing in EC2](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-ip-addressing.html)

---

### 🌊 2. Public IP – The Dock Facing the Ocean

When you build something on your island that the world should reach — like a tourist information center or a shop — you place it on the **coastline** (Public Subnet).  
AWS then assigns it a **Public IP address** connected to an **Internet Gateway (IGW)**.

This Public IP allows visitors (users on the internet) to find and access your service.

However, this dock address is **temporary (dynamic)** —  
if you close the port and reopen it (stop/start your instance), the city assigns a **new dock number** next time.  
If you shut down the port completely (terminate the instance), the old number is gone forever.

Public IPs are billed under AWS’s **Public IPv4** pricing, but the **Free Tier** covers 750 hours per month.

📘 **Example**
```

Private IP: 10.0.0.12
Public IP: 3.120.55.23

````

Connect using SSH:
```bash
ssh -i mykey.pem ec2-user@3.120.55.23
````

After restarting, AWS might give you a new address, like `13.210.40.50`.

💡 **Analogy:**
A **Public IP** is your **temporary dock number** — ships (internet users) can reach you through it,
but if you rebuild or move your dock, the number changes.

📸 **Image:** [Public IPv4 Addressing in EC2](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-ip-addressing.html)

---

### ⚓ 3. Elastic IP – The Permanent Trade Port

Sometimes, you don’t want your dock number (Public IP) to change — especially if you run a permanent business on your island, like a trading company (production server).
That’s where an **Elastic IP (EIP)** comes in.

An Elastic IP is a **static (permanent) public IPv4 address** that you reserve manually.
It stays the same even if your instance stops, restarts, or moves.
You can **detach it** from one instance and **reassign it** to another anytime.

Elastic IPs are **free while attached**, but **billed if idle** (when allocated but unused).

📘 **Example**

```
Elastic IP: 18.220.45.90
Associated Instance: EC2-Web-Server
```

Even after restart:

```
Elastic IP: 18.220.45.90 ✅ (Permanent)
```

💡 **Analogy:**
An **Elastic IP** is your **island’s registered trade port** —
a permanent harbor number used for global trade.
Even if you rebuild your warehouse or relocate offices, ships (clients) always find you through the same port number.

📸 **Image:** [Elastic IP in EC2](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-ip-addressing.html)

---

### 🛰️ 4. ENI (Elastic Network Interface) – The Island’s Communication Hub

An **ENI** is like the **communication control center** of each building on your island.
It’s a **virtual network card** that stores your Private IP, Public IP (if any), and connection rules (Security Groups).

You can **attach or detach** ENIs between instances, like swapping communication panels between buildings.
They’re essential for fault-tolerant or multi-network designs.

💡 **Analogy:**
An **ENI** is the **telecom hub** in your building —
it manages all your phone lines, radios, and ports, connecting you to other buildings or even other islands.

📸 **Image:** [Elastic Network Interface (ENI)](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-eni.html)

---

### 🧭 Comparison Summary

| IP Type        | Role on the Island      | Persistence         | Cost                             | Analogy                           |
| -------------- | ----------------------- | ------------------- | -------------------------------- | --------------------------------- |
| **Private IP** | Internal communication  | Persists on restart | Free                             | House address inside the island   |
| **Public IP**  | Internet-facing access  | Changes on restart  | Free (within 750 hrs/mo)         | Temporary dock number             |
| **Elastic IP** | Permanent global access | Fixed and reusable  | Free if attached; billed if idle | Registered trade port             |
| **ENI**        | Network connector       | N/A                 | Free                             | Communication hub in the building |

---

### 🖼️ Visual Diagram

```
🌍 AWS Planet
│
└── 🏝️ Your VPC (Private Island)
     │
     ├── 🌊 Public Subnet (Coastal City)
     │     ├── EC2 Instance with Public IP (Dock Access)
     │     └── EC2 Instance with Elastic IP (Permanent Port)
     │
     └── 🏞️ Private Subnet (Inland City)
           ├── EC2 Instance with Private IP (Internal Roads)
           └── ENI (Communication Hub connecting everything)
```


                    ┌────────────────────────────┐
                    │       Internet User        │
                    │ (e.g., You on a Laptop)    │
                    └──────────────┬─────────────┘
                                   │
                     Uses Public IP or Elastic IP
                                   │
                      (Example: 3.120.55.23 or 18.220.45.90)
                                   │
                     ┌─────────────▼──────────────┐
                     │   Internet Gateway (IGW)   │
                     │  Bridges Internet <-> VPC  │
                     └─────────────┬──────────────┘
                                   │
                           Public Subnet
                                   │
                  ┌────────────────┴────────────────┐
                  │                                 │
          ┌───────▼───────┐                 ┌───────▼───────┐
          │  EC2 Instance │                 │  EC2 Instance │
          │   Web Server  │                 │   Database    │
          │               │                 │               │
          │ Public IP: 3.120.55.23          │ No Public IP  │
          │ Elastic IP: 18.220.45.90 (opt)  │ Private Only  │
          │ Private IP: 10.0.0.12           │ Private IP: 10.0.0.8 │
          └──────────────────────────────────────────────────────┘
                                   │
                      Communicate privately via VPC
                                   │
                         (10.0.0.12 ↔ 10.0.0.8)

📸 **Reference:**
[AWS EC2 Networking – IP Addressing](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-ip-addressing.html)

</details>

---

<details>
<summary><strong>8. Storage (EBS, Snapshots, Cross-AZ/Region Copy)</strong></summary>

---

## Elastic Block Store (EBS)

EBS is the **hard disk** of your EC2 instance.  
Even if you stop or restart the machine, the data stays safe — that’s what makes it **persistent**.

Each EBS volume acts like one **virtual drive** attached to your instance.  
You can remove it, re-attach it, or copy it to another zone.

| Type        | Description        | Best For |
|-------------|--------------------|----------|
| **gp3**     | Balanced SSD       | General workloads |
| **io2/io1** | High IOPS SSD      | Databases, latency-sensitive apps |
| **st1**     | Throughput HDD     | Big sequential data like logs, analytics |
| **sc1**     | Cold HDD           | Rarely accessed, archive data |

💡 **Analogy:**  
Think of EBS as a **warehouse of shelves** on your island.  
Each shelf (volume) holds your goods (data).  
You can move shelves between shops (instances) — but only inside the **same district (Availability Zone)**.

📸 **Reference:** [Amazon EBS Volumes](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebs-volumes.html)

---

## Snapshots

A **snapshot** is a photograph of your shelf at a certain moment.  
AWS stores it in S3 internally, so you can rebuild the same shelf whenever needed.

```
EBS Volume → Snapshot → New Volume
```

- First snapshot = full copy  
- Next ones = only changed blocks (incremental)  
- You can restore, copy, or automate them with **Lifecycle Manager**

💡 **Analogy:**  
Take a **photo of your warehouse shelf** today.  
If something breaks tomorrow, you can rebuild an identical shelf using that photo.

📸 **Reference:** [EBS Snapshots](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/EBSSnapshots.html)

---

## Cross-AZ or Cross-Region Copy

**Within same Region (Cross-AZ):**

1. Take a snapshot of volume in `us-east-1a`  
2. Create a new volume from it in `us-east-1b`  
3. Attach it to an instance there  

**Between Regions:**

1. Copy snapshot to another region  
2. Create volume from that copy  
3. Attach it to an instance in that region  

💡 **Analogy:**  
You take the photo of your shelf, fly it to another **city (AZ)** or even another **continent (Region)**,  
and rebuild the same shelf there.

📸 **Reference:** [Copy Snapshots](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebs-copy-snapshot.html)

</details>

---

<details>
<summary><strong>9. Web Hosting (httpd) & User Data</strong></summary>

---

## Hosting a Simple Website on EC2

You can turn your EC2 into a small web server using **Apache HTTPD**.

**Step 1 – Install Apache**

```bash
sudo yum install -y httpd
````

**Step 2 – Start the service**

```bash
sudo systemctl start httpd
sudo systemctl enable httpd
```

**Step 3 – Allow Traffic**

In your Security Group, open:

* **HTTP (80)**
* **HTTPS (443)**

**Step 4 – Create a Web Page**

```bash
cd /var/www/html
sudo bash -c 'echo "<h1>Webstore DevOps Learning</h1>" > index.html'
```

Now visit `http://<Public-IP>` in your browser.

💡 **Analogy:**
Your EC2 is a **café**, and Apache is the **waiter** serving pages to visitors who walk in through the **front door (port 80/443)**.

📸 **Reference:** [Install LAMP on EC2](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/install-LAMP.html)

---

## User Data – Automation on First Boot

**User Data scripts** run only once when a new instance starts.
They’re used for quick setup — installing software or creating files automatically.

```bash
#!/bin/bash
yum install -y httpd
echo "<h1>Webstore App – 1</h1>" > /var/www/html/index.html
systemctl enable httpd
systemctl start httpd
```

💡 **Analogy:**
This is like your **“opening-day checklist”** pinned to the café door —
each new branch runs it automatically before serving customers.

📸 **Reference:** [EC2 User Data](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html)

</details>

---

<details>
<summary><strong>10. Instance Metadata & Identity Document</strong></summary>

---

## Instance Metadata – Facts About Your Instance

This is a local HTTP endpoint inside every EC2 that gives information about itself.
It’s only reachable **from within** the instance.

```bash
curl http://169.254.169.254/latest/meta-data/
```

Examples:

* `public-ipv4`
* `instance-id`
* `security-groups`
* `ami-id`

💡 **Analogy:**
Inside your house, there’s a **cabinet with blueprints** — it shows everything about the house,
but no outsider can open it.

---

## IMDSv2 (Security Upgrade)

Newer version of metadata service uses **session tokens** for safety.
AWS recommends **enforcing IMDSv2 only**.

```bash
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

curl -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/
```

---

## Instance Identity Document

Signed JSON document that proves which instance you are.

```bash
curl http://169.254.169.254/latest/dynamic/instance-identity/document
```

Shows:

* Region
* Instance ID
* AMI ID
* Account ID

💡 **Analogy:**
It’s your **government-issued house deed** — official proof of who you are on the island.

📸 **Reference:** [Instance Metadata Docs](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instancedata-data-retrieval.html)

</details>

---

<details>
<summary><strong>11. Networking Foundations</strong></summary>

Networking concepts — DNS, TCP/UDP, the 3-way handshake, OSI layers, stateful vs stateless firewalls — are covered in full in the Networking notes before this series.

→ [Networking Fundamentals](../../03.%20Networking%20–%20Foundations/README.md)

Key concepts used in EC2:
- Security Groups = stateful firewall → [Firewalls & Security](../../03.%20Networking%20–%20Foundations/09-firewalls/README.md)
- Subnets and CIDR → [Subnets & CIDR](../../03.%20Networking%20–%20Foundations/05-subnets-cidr/README.md)
- NAT Gateway → [NAT & Translation](../../03.%20Networking%20–%20Foundations/07-nat/README.md)
- DNS and Route 53 → [DNS](../../03.%20Networking%20–%20Foundations/08-dns/README.md)

</details>

---

<details>
<summary><strong>12. Load Balancer (with Health Checks)</strong></summary>

---

## Why do we need a Load Balancer?

One server works until traffic grows. Then it slows, crashes, or becomes a single point of failure.  
A **Load Balancer (LB)** sits in front and **spreads requests** across many servers.

**Analogy:** A traffic police officer at a busy junction, sending cars into free lanes so no lane jams.

---

## How it works (simple view)

1. Users hit the **LB** (one public endpoint).
2. LB forwards each request to **healthy** EC2 instances.
3. **Health checks** run constantly. If an instance fails, LB stops sending traffic there.

**Common algorithm:**  
- **Round Robin** = 1st request → Server A, 2nd → Server B, 3rd → Server C, then back to A…

```

```
     Internet Users
            │
            ▼
     +---------------+
     | Load Balancer |
     +---------------+
        │     │     │
        ▼     ▼     ▼
     EC2 A  EC2 B  EC2 C
```

```

---

## Health checks (must-have)

- Path/port the LB probes, e.g., `HTTP:80 /healthz` → expect **200 OK**  
- Thresholds: how many passes/fails before “healthy/unhealthy”  
- Purpose: remove bad instances automatically

---

## Types of AWS Load Balancers

| Type | OSI Layer | Best For | Highlights |
|-----|-----------|----------|------------|
| **Application (ALB)** | Layer 7 | HTTP/HTTPS web apps | Path/host routing, headers, cookies, WebSockets, TLS termination with ACM |
| **Network (NLB)** | Layer 4 | Extreme performance TCP/UDP | Very low latency, static IP/EIP per AZ, TLS pass-through/termination |
| **Gateway (GWLB)** | Layer 3 | Firewalls / inspection | Transparent appliance insertion |
| **Classic (CLB)** | 4/7 | Legacy only | Old gen—prefer ALB/NLB for new apps |

**Good defaults for web apps (ALB):**
- Redirect **HTTP → HTTPS**
- **TLS** termination at ALB (managed certs via **ACM**)
- Health check on `/healthz`
- Consider **AWS WAF** and **access logs**

📸 **Reference:**  
[AWS Elastic Load Balancing](https://docs.aws.amazon.com/elasticloadbalancing/latest/userguide/what-is-load-balancing.html)

</details>

---

<details>
<summary><strong>13. Auto Scaling & Monitoring</strong></summary>

---

## Why Auto Scaling?

Traffic changes all day.  
- If you size for peak all the time → **waste money**.  
- If you size small → **downtime** during spikes.

**Auto Scaling** grows and shrinks capacity automatically.

**Analogy:** Open extra billing counters when the line gets long; close them when the store is empty.

---

## Core building blocks

1. **Launch Template**  
   - The “recipe” for new instances (AMI, type, SGs, User Data, IAM role)
2. **Auto Scaling Group (ASG)**  
   - Controls **Min / Desired / Max** instance counts
3. **Scaling Policies**  
   - **Target tracking**: keep a metric steady (e.g., CPU ~ 60%)  
   - **Step scaling**: thresholds add/remove in steps  
   - **Scheduled**: time-based (e.g., weekdays 9 AM scale up)
4. **Health checks**  
   - Replace unhealthy instances (EC2/ELB health)
5. **Lifecycle hooks** (optional)  
   - Run scripts before instance joins/leaves (warm-up, drain, save logs)

```

```
        Internet Users
              │
              ▼
       [ Load Balancer ]
              │
  ┌───────────┴───────────┐
  ▼                       ▼
```

[ EC2 ]                 [ EC2 ]
▲                       ▲
└──────────┬────────────┘
│
Auto Scaling Group
Min=2  Desired=2  Max=6
↑ Add when metric rises (scale out)
↓ Remove when metric falls (scale in)

```

---

## Monitoring (keep an eye)

- **CloudWatch Metrics**: CPU, Network, ELB TargetResponseTime, RequestCountPerTarget, custom app metrics  
- **CloudWatch Alarms**: trigger scaling or alerts  
- **CloudWatch Logs**: ship system/app logs  
- **Dashboards**: single pane of health

---

## A simple, safe starting pattern

- Put instances in **multiple AZs** behind an **ALB**  
- ASG: **Min=2**, Desired starts at 2, **Max** sized for spikes  
- **Target tracking** on CPU (e.g., 50–60%) or ALB metrics (RequestCountPerTarget)  
- Health check grace period during warm-up  
- Use **Instance Refresh** for rolling updates (new AMI/LT)

📸 **References:**  
[Amazon EC2 Auto Scaling](https://docs.aws.amazon.com/autoscaling/ec2/userguide/what-is-amazon-ec2-auto-scaling.html)  
[Amazon CloudWatch](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/WhatIsCloudWatch.html)

</details>