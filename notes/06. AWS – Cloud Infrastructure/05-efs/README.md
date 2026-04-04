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

# Day 10 – Elastic File System (EFS)

## Table of Contents

1. [Why We Need EFS](#1-why-we-need-efs)
2. [What Is Amazon EFS](#2-what-is-amazon-efs)
3. [EBS vs EFS vs S3 Comparison](#3-ebs-vs-efs-vs-s3-comparison)
4. [Simplified Real-World Scenarios](#4-simplified-real-world-scenarios)
5. [How EFS Works Internally](#5-how-efs-works-internally)
6. [Lab Task – Mounting EFS on EC2](#6-lab-task--mounting-efs-on-ec2)
7. [Architecture Diagrams](#7-architecture-diagrams)
8. [Performance & Throughput Modes](#8-performance--throughput-modes)
9. [Pricing & Best Practices](#10-pricing--best-practices)

---

<details>
<summary><strong>1. Why We Need EFS</strong></summary>

When you start with one EC2, its **EBS volume** (local SSD) works fine.
But once you add more servers—**EC2-A**, **EC2-B**, **EC2-C**—each has its own EBS disk.
Uploads on one server never appear on the others, creating inconsistent data.

You can’t attach one EBS to many EC2s, and syncing files manually is painful.
What you really need is a **shared drive** that all EC2s can mount and see the same files instantly.
That’s what **Amazon EFS** provides.

---

### 💡 Quick Analogy

| Storage | Real-World Equivalent  | Use                        |
| ------- | ---------------------- | -------------------------- |
| **EBS** | Laptop SSD             | Private, local, fast       |
| **EFS** | Office network drive   | Shared, live, auto-scaling |
| **S3**  | Google Drive / Dropbox | Cloud archive and delivery |

EFS is that shared folder in the office everyone opens together.

---

### What EFS Fixes

| Need                  | Why EBS Fails            | How EFS Solves It           |
| --------------------- | ------------------------ | --------------------------- |
| Multi-instance access | EBS = 1 EC2 only         | EFS mountable by many EC2s  |
| Elastic capacity      | EBS size is fixed        | EFS auto-grows/shrinks      |
| High availability     | EBS in 1 AZ              | EFS replicates across AZs   |
| POSIX file system     | S3 = objects, no folders | EFS = real Linux filesystem |

---

### Visual Flow

```
Without EFS:
EC2-A → EBS-A   ❌ Files not visible to EC2-B
EC2-B → EBS-B   ❌ Different copies everywhere

With EFS:
EC2-A, EC2-B, EC2-C  →  mount /efsdir →  Amazon EFS
✓ All see and edit the same files in real time
```

---

### ✅ When to Use EFS

* Web apps on multiple EC2s (WordPress, Drupal)
* Shared datasets or ML pipelines
* Developer workspaces and user home dirs
* Any situation needing simultaneous read/write access

### ❌ Not for

* Databases → use **EBS**
* Backups or global media hosting → use **S3**

</details>

---

<details>
<summary><strong>2. What Is Amazon EFS</strong></summary>

**Amazon EFS (Elastic File System)** is a fully managed, shared file system that your EC2 instances can mount and use together.
It behaves like a normal Linux directory but the files actually live in AWS’s storage layer, not inside any one EC2.

**Key Points**

* **Elastic:** Storage automatically expands or shrinks with your data.
* **Shared:** Many EC2s can mount the same path at once.
* **POSIX-compliant:** Standard Linux permissions, folders, and file locks work normally.
* **Highly Available:** Data is replicated across multiple AZs for durability.
* **Fully Managed:** No disks or capacity planning—AWS handles scaling and health.

```
EC2-A, EC2-B, EC2-C  ──►  /efsdir  ──►  Amazon EFS (Shared Storage)
```

💡 **Think of it:** one central folder in the cloud that all your servers can open at the same time.

</details>

---

<details>
<summary><strong>3. EBS vs EFS vs S3 – Storage Comparison</strong></summary>

AWS gives three main storage options, each solving a different need.

| Feature         | **EBS**                | **EFS**                    | **S3**                   |
| --------------- | ---------------------- | -------------------------- | ------------------------ |
| **Type**        | Block Storage          | File Storage               | Object Storage           |
| **Access**      | One EC2 at a time      | Many EC2s at once          | Via HTTP/API             |
| **Scalability** | Fixed size (manual)    | Auto-scales (elastic)      | Infinite                 |
| **Speed**       | Very fast (local disk) | Network fast               | Slower (API calls)       |
| **Use Case**    | OS disk, DB storage    | Shared app files / uploads | Backups, media, archives |
| **Scope**       | Single AZ              | Multi-AZ (Regional)        | Regional/Global          |
| **Analogy**     | Laptop SSD             | Office shared drive        | Google Drive / Dropbox   |

💡 **In short:**

* **EBS** → local, private, single-server speed.
* **EFS** → shared, elastic workspace for multiple servers.
* **S3** → global storage for large, static, or archived data.

</details>

---

<details>
<summary><strong>4. Simplified Real-World Scenarios</strong></summary>

| Example                    | Storage Type | Real-World Analogy             | Key Idea                 |
| -------------------------- | ------------ | ------------------------------ | ------------------------ |
| **Personal Laptop**        | EBS          | Your own SSD – only you use it | Local, fast, private     |
| **Office Shared Folder**   | EFS          | Team drive on company network  | Shared live access       |
| **Google Drive / Dropbox** | S3           | Cloud backup for everything    | Accessible from anywhere |

🎬 **Movie Studio Analogy**

| Task                      | Best AWS Storage | Why                               |
| ------------------------- | ---------------- | --------------------------------- |
| Editing raw footage       | EBS              | Local speed needed                |
| Sharing project files     | EFS              | Multiple editors collaborate live |
| Archiving finished movies | S3               | Cheap & limitless storage         |
| Streaming worldwide       | S3 + CloudFront  | Global delivery                   |

</details>

---

<details>
<summary><strong>5. How EFS Works Internally</strong></summary>

EFS isn’t a physical disk; it’s a **network file system** managed by AWS.
Your EC2s connect to it over **NFS (Network File System)** — just like mapping a shared drive in an office network.

### Step-by-Step Flow

1️⃣ **Create EFS File System** → AWS sets up an elastic backend across multiple AZs.
2️⃣ **Mount Targets in Subnets** → Each AZ gets an endpoint that EC2s use to connect.
3️⃣ **Mount from EC2** → You make a folder (`/efsdir`) and mount the EFS through NFS:

```bash
sudo mount -t efs -o tls <EFS_ID>:/ efsdir
```

4️⃣ **Shared Access** → Any EC2 mounting that same path sees identical files instantly.
5️⃣ **Elastic Scaling & Durability** → EFS automatically grows, shrinks, and replicates data across AZs.

---

### Visual Snapshot

```
┌──────────────────────── AWS Region ─────────────────────────┐
│                                                             │
│  EC2-A (AZ-A)  ─┐                                           │
│                 │   NFS Mount (tcp 2049)                    │
│  EC2-B (AZ-B)  ─┼──►  Amazon EFS File System                │
│  EC2-C (AZ-C)  ─┘      • Multi-AZ replication               │
│                       • Auto-scale storage                  │
│                       • Shared POSIX filesystem             │
└─────────────────────────────────────────────────────────────┘
```

💡 **In short:**
Your EC2s keep their own EBS disks for local speed but share one EFS folder for collaboration — all while AWS handles the scaling, replication, and reliability behind the scenes.  
📘 EFS is separate from EBS.  
Mounting EFS simply adds **another drive** to your machine (shared via network).
</details>

---

<details>
<summary><strong>6. Lab Task – Mounting EFS on EC2</strong></summary>

**Goal:** Share the same storage between two EC2 instances.
###  **EFS Mount Lab (Quick Commands)**

```bash
# 1️⃣ Launch two EC2 instances in the same VPC (different subnets for HA)

# 2️⃣ Create an EFS file system in the AWS Console
#    → Add mount targets in both subnets

# 3️⃣ Connect to the first EC2
ssh -i mykey.pem ec2-user@<EC2-PUBLIC-IP>

# 4️⃣ Install the EFS client
sudo yum install -y amazon-efs-utils

# 5️⃣ Create a directory to mount EFS
mkdir /efsdir

# 6️⃣ Mount the EFS file system
sudo mount -t efs -o tls <EFS-ID>:/ /efsdir

# 7️⃣ Test shared access
echo "Hello from EC2-A" > /efsdir/test.txt
```

### ✅ **On EC2-B**

```bash
sudo yum install -y amazon-efs-utils
mkdir /efsdir
sudo mount -t efs -o tls <EFS-ID>:/ /efsdir
cat /efsdir/test.txt
```

If you see

```
Hello from EC2-A
```

EFS is successfully shared between both EC2 instances.

✅ If both instances see the same file, EFS is working.
```
EC2-A (AZ-A) ─┐
               ├──►  Amazon EFS (File System)
EC2-B (AZ-B) ─┘
     ↳ Both read / write to /efsdir (same files, live sync)
```
</details>

---

<details>
<summary><strong>7. Architecture Diagrams</strong></summary>

### A) Mount Flow (what your EC2 actually sees)

```
EC2 Instance
├─ /           → EBS (OS, app, local files)
└─ /efsdir     → EFS (shared network filesystem via NFS)
                 ↑
                 └─ mount -t efs <EFS-ID>:/ /efsdir
```

---

### B) Multi-AZ EFS with Mount Targets (HA)

```
┌───────────────────── AWS Region ───────────────────┐
│  VPC                                               │
│                                                    │
│  AZ-A                         AZ-B                 │
│  ┌───────────────┐           ┌───────────────┐     │
│  │  EC2-A        │           │  EC2-B        │     │
│  │  (has EBS)    │           │  (has EBS)    │     │
│  │ mount /efsdir ├──┐     ┌──┤ mount /efsdir │     │
│  └───────────────┘  │     │  └───────────────┘     │
│                     ▼     ▼                        │
│          ┌─────────────┴─────────────┐             │
│          │  Amazon EFS (Regional)    │             │
│          │  • Multi-AZ replication   │             │
│          │  • Elastic capacity       │             │
│          └─────────────┬─────────────┘             │
│                  ▲     │     ▲                     │
│     Mount Target (AZ-A)│  Mount Target (AZ-B)      │
│        (one per subnet) (TCP 2049/NFS)             │
│                                                    │
│ Security Group tip:                                │
│ allow NFS (TCP 2049) EC2 ↔ EFS (both directions)   │
└────────────────────────────────────────────────────┘
```

---

### C) EFS in the App Tier (behind an ALB, optional context)

```
Internet
   │
[ ALB ]  ← (optional) balances traffic to web/app EC2s
   │
   ├── EC2-Web-1 (EBS) ┐
   ├── EC2-Web-2 (EBS) ┼── mount /efsdir → Amazon EFS (shared content)
   └── EC2-Web-3 (EBS) ┘
```

---

### Final All-in-One (EBS + EFS + S3)

```
                ┌───────────────────────────┐
                │         Amazon S3         │
                │  (Backups / Hosting / CDN)│
                └─────────────┬─────────────┘
                              │  (HTTP/API)
┌────────────────────────────────────────────────────────────────┐
│                            AWS VPC                             │
│                                                                │
│   ┌───────────────┐        NFS (TCP 2049)       ┌────────────┐ │
│   │  EC2-A        │ ──────────────────────────► │            │ │
│   │  (EBS: OS/app)│                             │            │ │
│   │  /efsdir ─────┼───────────────────────────► │  Amazon    │ │
│   └───────────────┘                             │    EFS     │ │
│                                                 │ (Regional  │ │
│   ┌───────────────┐                             │  shared FS)│ │
│   │  EC2-B        │ ──────────────────────────► │            │ │
│   │  (EBS: OS/app)│                             │            │ │
│   │  /efsdir      │                             └────────────┘ │
│   └───────────────┘                                            │     
│                                                                │
│  Flow:                                                         │
│   • EBS = local per-instance disk (fast, private)              │
│   • EFS = shared live files across EC2s                        │
│   • S3  = publish/archive/fan delivery (global)                │
└────────────────────────────────────────────────────────────────┘
```

</details>

---

<details>
<summary><strong>8. Performance & Throughput Modes</strong></summary>

| Category        | Mode            | Description                      | Use Case                   |
| --------------- | --------------- | -------------------------------- | -------------------------- |
| **Performance** | General Purpose | Low latency (default)            | Web apps, CMS, dev/test    |
|                 | Max IO          | High throughput (bigger latency) | Big data, media processing |
| **Throughput**  | Bursting        | Scales with usage                | Variable workloads         |
|                 | Provisioned     | Fixed MB/s                       | Predictable heavy loads    |

</details>

---

<details>
<summary><strong>9. Pricing & Best Practices</strong></summary>

💰 **Pricing**

* Pay per GB of data stored per month.
* Lifecycle policy to move cold data to **EFS Infrequent Access (IA)**.
* No charge for data transfer within same Region.

✅ **Best Practices**

* Allow TCP 2049 (NFS) in Security Groups.
* Enable encryption at rest and in transit.
* Create mount targets in each AZ for HA.
* Monitor EFS metrics via CloudWatch.
* Use lifecycle policies for cost optimization.

---

### 🏁 Final Summary

| **Concept** | **Acts Like** | **Main Use** |
|--------------|---------------|--------------|
| **EBS** | Laptop SSD (internal storage) | Fast, local storage for a single EC2 |
| **EFS** | Office network drive (shared external storage) | Shared, elastic multi-EC2 storage |
| **S3** | Google Drive / Dropbox | Global, limitless object storage for backups and hosting |

💡 **In one line:**  
> **EBS** is *personal and local*, **EFS** is *shared and elastic*, and **S3** is *global and endless*.

</details>
---