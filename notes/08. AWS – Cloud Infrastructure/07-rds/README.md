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

# AWS RDS — Relational Database Service

## What This File Is About

EC2 gives us compute power, but most real-world apps also need a structured place to store and query data — not just flat files. RDS (Relational Database Service) fills that role. This file covers what RDS is, how it manages databases, the migration path from the webstore-db postgres container to RDS, and exactly how backups and recovery work under the hood.

---

## Table of Contents

1. [Why Managed Databases](#1-why-managed-databases)
2. [What Is Amazon RDS?](#2-what-is-amazon-rds)
3. [Core Components](#3-core-components)
4. [Key Features](#4-key-features)
5. [How Backups Actually Work (Behind the Scenes)](#5-how-backups-actually-work-behind-the-scenes)
6. [Migrating Webstore-DB from Container to RDS](#6-migrating-webstore-db-from-container-to-rds)

---

## 1. Why Managed Databases

Every application — whether it's a food delivery app or a webstore — needs a place to **store and recall information safely**. That's what a database does: it holds your data even after your system restarts.

### The Problem Before Cloud

Before cloud services existed, companies had to host databases on **physical servers**.
That sounds fine until you realize what it really meant:

- You had to **buy and maintain hardware**.
- You were responsible for **installing, patching, and updating** the database software.
- **Scaling** was a nightmare — if your app suddenly went viral, you couldn't just "add capacity" overnight.
- **Backups and failovers** had to be handled manually.
- And if a server crashed — well, good luck restoring it quickly.

So instead of building your product, you'd be stuck doing IT housekeeping.

### The Restaurant Analogy

Let's imagine your application is a restaurant.

- The **chef** is your **database engine** (MySQL, PostgreSQL, Oracle, etc.) — cooking up the data and serving results.
- The **manager** is **AWS RDS** — taking care of the kitchen, groceries, cleaning, and overall maintenance.
- And you — the **owner (application)** — just focus on serving customers and taking new orders.

You don't worry about whether the gas is filled or the ingredients are fresh — that's RDS's job.

| Role | Real-World Task | AWS Equivalent |
|---|---|---|
| You (Owner/App) | Take customer orders | Application sending queries |
| Chef (DB Engine) | Cook food | Process and store data |
| Manager (RDS) | Keep kitchen running, handle maintenance | Manage infrastructure, backups, and scaling |

---

## 2. What Is Amazon RDS?

RDS is a **fully managed service** that handles all the heavy lifting — setup, maintenance, scaling, patching, and backups — while you focus on using the database, not running it.

You just choose:
- which **engine** you want (MySQL, PostgreSQL, Oracle, SQL Server, or MariaDB)
- how big your instance should be
- and AWS does the rest

So you focus on your app, and RDS quietly takes care of the kitchen.

**Quick Architecture View:**

```
Application (EC2 / EKS Pod)
↓
Security Group (Port 5432 for PostgreSQL)
↓
RDS Instance
↓
Automated Backups + Multi-AZ Replicas
```

In short — your app connects to RDS, and AWS makes sure your data stays available, secure, and recoverable.

---

## 3. Core Components

When you launch an RDS instance, AWS silently builds several moving parts underneath.

### DB Instance
The actual **compute environment** where your database runs — like a virtual machine with CPU, RAM, and storage.
You can scale it vertically (change instance type) or horizontally (add read replicas).

### DB Engine
This defines which database technology is powering your instance.
Options include MySQL, PostgreSQL, Oracle, SQL Server, and MariaDB.
Each has its own pricing and features, but RDS handles all of them in a similar way.

### Endpoint
Every RDS instance gets a **unique DNS endpoint**.
That's your connection string — your app uses it instead of an IP.

```
webstore-db.xxxxx.us-east-1.rds.amazonaws.com
```

Even during a failover or maintenance, the endpoint always points to the correct active instance.

### Storage Type
RDS storage comes from **EBS (Elastic Block Store)**.
You can pick:
- **gp3 (General Purpose SSD)** – cost-effective and balanced performance.
- **io2 (Provisioned IOPS SSD)** – high-speed, low-latency storage for heavy workloads.

You can increase storage size anytime — no downtime required.

### Security Group
Acts as a **firewall** controlling who can access your database.

| Engine | Port |
|---|---|
| MySQL | 3306 |
| PostgreSQL | 5432 |

Always restrict access to specific Security Groups — never open the DB port to `0.0.0.0/0`.

**Summary:**

| Component | Description |
|---|---|
| **DB Instance** | The environment where the database runs |
| **DB Engine** | MySQL, PostgreSQL, Oracle, SQL Server, etc. |
| **Endpoint** | DNS name used by apps to connect |
| **Storage Type** | SSD-backed storage (gp3 / io2) |
| **Security Group** | Firewall controlling inbound and outbound traffic |

---

## 4. Key Features

### 1. Automated Backups
RDS automatically takes **daily snapshots** and transaction log backups.
You can roll back to **any specific second** within your backup retention window.
Perfect for accidental deletions or human errors.

### 2. Multi-AZ Deployment
RDS creates a **standby replica** in another Availability Zone.
If the primary database fails, RDS automatically switches over to the standby.
This means zero manual recovery and almost no downtime.

```
AZ us-east-1a                    AZ us-east-1b
┌─────────────────┐              ┌─────────────────┐
│  RDS Primary    │ ──sync──────►│  RDS Standby    │
│  postgres:15    │              │  postgres:15    │
│  webstore-db    │              │  (auto-promote  │
│  (reads/writes) │              │   on failure)   │
└─────────────────┘              └─────────────────┘
```

### 3. Read Replicas
For apps with lots of read requests (like dashboards or analytics), you can create **read-only copies**.
They help distribute the load and improve performance.

### 4. Monitoring with CloudWatch
You can monitor CPU, memory, connections, and IOPS in real time.
Set alarms or automation to scale when performance metrics go high.

### 5. Fully Managed by AWS
AWS takes care of everything — patching, scaling, failovers, and security updates.
You only pay for what you use.

| Feature | What It Does |
|---|---|
| **Automated Backups** | Daily snapshots + point-in-time restore |
| **Multi-AZ Deployment** | Creates standby DB in another AZ for failover |
| **Read Replicas** | Distribute read traffic and improve performance |
| **CloudWatch Monitoring** | Tracks performance metrics |
| **Fully Managed** | AWS handles all the maintenance tasks |

---

## 5. How Backups Actually Work (Behind the Scenes)

Let's say you create a **PostgreSQL RDS instance** named `webstore-db` in the **us-east-1** region.

### 1. Primary Storage (EBS)

When you launch the database:

- AWS automatically attaches **EBS (Elastic Block Store)** volumes behind the scenes to store your DB files.
- These volumes hold your actual data — tables, indexes, logs, configurations.
- You don't see or manage them; RDS abstracts them away.

**Service involved:** Amazon EBS (RDS uses it internally for database storage)

---

### 2. Automated Backups Start

When you enable automated backups (default setting):

- RDS quietly takes **EBS snapshots** of your database storage volume once every 24 hours.
- These are **incremental snapshots** — meaning only the changed data blocks are stored after the first backup.

**Service involved:** Amazon EBS + Amazon S3
Snapshots are EBS-level backups **stored inside Amazon S3** (you don't see them directly in S3 console, but they live there).

---

### 3. Transaction Logs (Point-in-Time Recovery)

Throughout the day, RDS continuously uploads **transaction logs** (the history of every write or change) to S3.
These logs allow **point-in-time recovery**, meaning you can restore your DB to *any exact second* before failure.

**Service involved:** Amazon S3 (stores binary logs securely and redundantly)

---

### 4. Restore from Backup

Imagine something goes wrong — your app accidentally drops a table.
You go to: **AWS Console → RDS → Databases → Restore to Point in Time.**

You choose a timestamp, like:

```
12th Oct, 2025 – 14:22:05
```

AWS then:

1. Fetches the relevant **EBS snapshot** from S3.
2. Replays all **transaction logs** up to that exact second.
3. Creates a **new RDS instance** (`webstore-db-restore`) with recovered data.

Your original DB stays untouched.

**Services involved:**
- **Amazon RDS** → Orchestrates the recovery process.
- **Amazon S3** → Provides the stored backups and logs.
- **Amazon EBS** → Creates new volumes for the restored DB.

---

### 5. Monitoring and Logging

Once your backups and restores are running, AWS gives you two watchers that keep an eye on everything — one for **performance**, and one for **activity history**.

#### a) CloudWatch — Performance Monitor
Think of this as a health meter for your database.
It constantly measures things like:
- CPU usage
- Storage space used
- Number of connections
- Backup duration and progress

You can open **CloudWatch → Metrics → RDS** in the console and see live graphs.
If something goes wrong (for example, CPU > 90% for 5 minutes), you can set an **alarm** so AWS notifies you or even runs an action.

**Purpose:** lets you know if your database or backups are slowing down, filling up, or overloading — before it becomes a problem.

#### b) CloudTrail — Activity History
This keeps a diary of what actions were taken and by whom.
Example: if someone runs:
- `CreateSnapshot`
- `DeleteDBInstance`
- `RestoreDBInstanceFromBackup`

You'll see exactly when and who did it.

It's mainly for **security and auditing** — so you can trace changes if something unexpected happens.

**Purpose:** proves accountability and helps investigate any wrong action or failure later.

---

### 6. Cross-Region Backups (Optional, for Extra Safety)

If you enable it, AWS can make **a copy of your snapshots** and send them to another region — say your main DB is in `us-east-1`, the copy could go to `us-west-2`.

Why this matters:
- If an entire region faces an outage or disaster, your data is still safe elsewhere.
- You can even launch an RDS instance from that copy in the other region and keep your app running.

You can set this up once — RDS automates the rest.

---

### 7. The Big Picture (Tie Everything Together)

Here's what's happening overall:

1. **Your RDS instance** stores live data on **EBS volumes**.
2. **Automated backups** take **EBS snapshots** daily and save them in **S3**.
3. **Transaction logs** continuously flow into **S3** so you can rewind to any second.
4. **When you restore**, RDS combines the latest snapshot + those logs to rebuild your data on new EBS volumes.
5. **CloudWatch** keeps you informed about performance and backup health.
6. **CloudTrail** keeps an action log for auditing.
7. Optionally, **S3** replicates your snapshots to another region for disaster recovery.

Visually:

```
RDS Instance (EBS)
│
├──► Daily Snapshots ──► Amazon S3
├──► Transaction Logs ──► Amazon S3
│
├──► Monitoring ────────► CloudWatch
├──► Activity Logs ─────► CloudTrail
└──► Optional Copies ───► S3 (Other Region)
```

**In Short:**
- **EBS** = live database storage.
- **S3** = safe long-term backup vault.
- **CloudWatch** = performance dashboard.
- **CloudTrail** = security history log.

Together, these services make RDS backups automatic, trackable, and easy to recover.

### Realistic Example

Your production webstore uses RDS for orders and products.

Scenario:
- At 3:15 PM, a wrong SQL command deletes the `products` table.
- You open RDS → click "Restore to point in time" → select 3:14:59 PM.
- AWS automatically restores from your latest backup snapshot + replays logs → **new DB instance appears with all data intact**.
- You reconnect your app to the new endpoint, and everything resumes normally.

In short:
- RDS uses **EBS** for live data
- **S3** for backups and logs
- **CloudWatch** for monitoring
- **CloudTrail** for auditing
- all of it is managed by **RDS itself** — no manual coordination needed

---

## 6. Migrating Webstore-DB from Container to RDS

The webstore-db runs as a `postgres:15` container with a PersistentVolumeClaim on Kubernetes. Here is the migration path to RDS.

### Step 1 — Dump the data from the container

```bash
# From inside the Kubernetes cluster
kubectl exec -it webstore-db-0 -- pg_dump \
  -U postgres \
  -d webstore \
  -F c \
  -f /tmp/webstore-backup.dump

# Copy the dump out of the pod
kubectl cp webstore-db-0:/tmp/webstore-backup.dump ./webstore-backup.dump
```

### Step 2 — Create the RDS instance

```bash
aws rds create-db-instance \
  --db-instance-identifier webstore-db \
  --db-instance-class db.t3.medium \
  --engine postgres \
  --engine-version 15 \
  --master-username webstore_admin \
  --master-user-password <secure-password> \
  --allocated-storage 20 \
  --storage-type gp3 \
  --vpc-security-group-ids sg-webstore-db \
  --db-subnet-group-name webstore-db-subnet-group \
  --multi-az \
  --backup-retention-period 7 \
  --no-publicly-accessible
```

### Step 3 — Restore the dump to RDS

```bash
# Create the database on RDS
psql -h webstore-db.xxxxx.us-east-1.rds.amazonaws.com \
  -U webstore_admin \
  -c "CREATE DATABASE webstore;"

# Restore the dump
pg_restore \
  -h webstore-db.xxxxx.us-east-1.rds.amazonaws.com \
  -U webstore_admin \
  -d webstore \
  -F c \
  ./webstore-backup.dump
```

### Step 4 — Update the application connection string

Change the `DATABASE_URL` in the webstore-api Kubernetes Secret from the container endpoint to the RDS endpoint. Apply the updated Secret. Roll out the Deployment to pick up the new connection string.

### Step 5 — Verify and decommission the container

Run smoke tests against the application. Verify data integrity. Once confirmed, delete the webstore-db Deployment and PVC.

---

### RDS in a DevOps Workflow

In a DevOps workflow, RDS acts as your **database backbone** — reliable, monitored, and automated.

- **Infrastructure as Code (IaC):** Create and manage RDS using Terraform or CloudFormation.
- **Automation:** Integrate snapshots and restore operations into CI/CD pipelines.
- **Monitoring:** Push CloudWatch metrics into Grafana or custom dashboards.
- **Security:** Use IAM roles, KMS encryption, and TLS connections.
- **Reliability:** Multi-AZ and PITR protect against failures and human mistakes.

In short — RDS gives your application the confidence to scale, fail, recover, and still stay online.

---

## What You Can Do After This

- Create an RDS PostgreSQL instance with Multi-AZ and automated backups
- Explain exactly how RDS backups work — EBS snapshots, transaction logs, S3, CloudWatch, CloudTrail
- Perform a point-in-time restore of a database
- Migrate a postgres database from a Kubernetes container to RDS
- Update an application to connect to RDS instead of a local container
- Explain the difference between automated backups and manual snapshots

---

## What Comes Next

→ [08. Load Balancing & Auto Scaling](../08-load-balancing-auto-scaling/README.md)

The webstore-api runs on two EC2 instances across two AZs. Traffic needs to reach both of them and route away from any instance that becomes unhealthy. That is what the Application Load Balancer (ALB) does.
