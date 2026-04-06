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

# Elastic Block Store (EBS)

Our network is now set — roads, gates, and rules are ready.
But a server can't run without storage to hold its data.
That's where EBS (Elastic Block Store) comes in.
Think of it as attaching an SSD to your EC2 instance — local, fast, and always there when you restart the machine.

---

## Table of Contents

1. [What Is EBS and How It Works with EC2](#1-what-is-ebs-and-how-it-works-with-ec2)
2. [EBS Volume Types and Performance](#2-ebs-volume-types-and-performance)
3. [Snapshots & Backup Mechanism](#3-snapshots--backup-mechanism)
4. [Cross-AZ and Cross-Region Copy](#4-cross-az-and-cross-region-copy)
5. [EBS Encryption](#5-ebs-encryption)
6. [Modifying Volumes (Resize, Migrate, Tune)](#6-modifying-volumes-resize-migrate-tune)
7. [Best Practices & Quick Summary](#7-best-practices--quick-summary)

---

## 1. What Is EBS and How It Works with EC2

**Elastic Block Store (EBS)** is a **persistent block storage** service designed for Amazon EC2 instances.
Each EBS volume behaves like a **virtual hard drive** — you can format it, mount it, detach it, and re-attach it to other EC2 instances within the same Availability Zone (AZ).

Even if you stop or restart your instance, **the data remains intact**, making EBS a reliable storage layer for OS files, applications, and databases.

Think of EBS as a **detachable SSD** for your EC2 instance — you can unplug it, carry it to another machine in the same data center (AZ), and plug it back in without losing your data.

**Key properties:**
- **Persistent**: Data survives instance stop/start.
- **Block-level**: You manage it like a raw disk.
- **Flexible**: You can increase size, change performance, or migrate without downtime.
- **AZ-scoped**: Must be in the same Availability Zone as the instance.

---

### How EBS Works with EC2

EBS volumes attach to EC2 instances over the **availability zone network**.
When you launch an EC2 instance, it can have:
- **Root Volume:** Stores OS and boot files.
- **Additional Data Volumes:** For app data, logs, or databases.

**High-level flow:**

```
EBS Volume  <──attached──>  EC2 Instance
│
└── Snapshots stored in S3 (for backup & cloning)
```

- EBS is **replicated automatically within its AZ** to prevent data loss.
- You can attach **multiple EBS volumes** to one EC2, or attach a single EBS volume to multiple EC2s (only for io1/io2 Multi-Attach use cases).

**Use Case Examples:**
- Root volume for Linux/Windows OS.
- Application data storage for web servers.
- Database storage (MySQL, PostgreSQL).
- Persistent log storage or caching layer.

---

### Special Case — EBS Multi-Attach (io1 / io2 Volumes)

Normally, a single EBS volume can be **attached to only one EC2 instance at a time**.
That keeps data consistent, just like plugging a physical SSD into one machine.

However, the **Provisioned IOPS SSD (io1 and io2)** volume types introduce a feature called **Multi-Attach**.
It lets you connect the same volume to **up to 16 EC2 instances** *simultaneously* within the **same Availability Zone**.

**Why this exists:**
Some enterprise or clustered applications (for example, Oracle RAC or shared file systems) need multiple servers to read and write to the same shared disk.
Multi-Attach gives them a common block-level layer while keeping latency extremely low.

**How it behaves:**
- Every attached EC2 gets a unique device name (e.g., `/dev/sdf`, `/dev/sdg` …).
- All instances see the **same data blocks** in real time.
- There's **no built-in locking** — your application must manage concurrent writes safely (through a clustered file system or DB engine).
- If ordinary servers try to write at the same time without coordination, data corruption can occur.

**Architect's Note:**
Use Multi-Attach only when your workload is explicitly designed for shared block access.
For general cases, treat EBS as a **one-to-one disk** between an instance and its volume — simpler, faster, safer.

---

## 2. EBS Volume Types and Performance

| Volume Type | Medium | Description | Best For |
|---|---|---|---|
| **gp3** | SSD | General-purpose SSD with configurable IOPS (up to 16,000) and throughput (up to 1,000 MB/s). | Most workloads – OS, applications, boot volumes |
| **io2/io1** | SSD | Provisioned IOPS SSD with consistent latency and Multi-Attach support. | High-performance databases |
| **st1** | HDD | Throughput-optimized HDD for large sequential workloads. | Big data, logs, streaming workloads |
| **sc1** | HDD | Cold HDD with lowest cost and lowest performance. | Archival and infrequently accessed data |

**Tip:** Use **gp3** by default unless you have a clear reason to optimize for either IOPS (io2/io1) or cost (st1/sc1).

**Durability:** EBS volumes provide **99.999% availability** within an AZ due to internal replication.

---

### Performance Essentials — IOPS & Throughput

**IOPS (Input/Output Operations Per Second)** → speed for small random reads/writes.
**Throughput (MB/s)** → speed for large sequential data transfers.

| Metric | gp3 (max) | io2 (max) | st1/sc1 |
|---|---|---|---|
| IOPS | 16,000 | 256,000 (provisioned) | Low |
| Throughput | 1,000 MB/s | 4,000 MB/s | High sequential only |
| Latency | ~5 ms | <1 ms | High (HDD latency) |

**Tip:** Monitor performance using **CloudWatch metrics** like `VolumeReadOps`, `VolumeWriteOps`, `VolumeThroughputPercentage`, etc.

---

### The Webstore and EBS

The webstore-db postgres container on Kubernetes uses a PersistentVolumeClaim backed by an EBS gp3 volume. When webstore-db migrates to RDS, RDS provisions its own gp3 EBS volume internally — you never touch it directly, but snapshotting, resizing, and encryption all apply.

For webstore-api EC2 instances, each node has:
- **Root volume:** 20 GB gp3 — OS, nginx, application
- **Logs volume (optional):** separate gp3 — keeps root volume from filling

```
webstore-api EC2 (us-east-1a)
├── /dev/xvda  →  gp3 20GB  (root — OS + app)
└── /dev/xvdf  →  gp3 50GB  (data — logs, uploads)

webstore-db RDS
└── gp3 20GB  (managed by RDS, backed by EBS internally)
```

---

## 3. Snapshots & Backup Mechanism

A **snapshot** is a **point-in-time backup** of an EBS volume stored in Amazon S3.
Although stored in S3, snapshots are managed transparently by EBS.

```
EBS Volume → Snapshot → New Volume
```

- **First snapshot** = full copy
- **Subsequent snapshots** = incremental (only changed blocks)
- Snapshots can be **used to create new volumes**, **copied across regions**, or **automated via Lifecycle Manager**.

It's like taking a **photo of your disk's current state**.
If anything breaks later, you can rebuild an exact copy using that snapshot.

---

## 4. Cross-AZ and Cross-Region Copy

You can use snapshots to **clone volumes** across Availability Zones or Regions.

### Cross-AZ (within same region)

1. Create a snapshot of the source volume (e.g., `us-east-1a`).
2. Use that snapshot to create a new volume in another AZ (e.g., `us-east-1b`).
3. Attach it to an EC2 instance there.

### Cross-Region

1. Copy the snapshot to another region.
2. Create a volume from that copy.
3. Attach to EC2 in the destination region.

It's like **replicating your disk** to a different branch office — same setup, new location.

---

## 5. EBS Encryption

EBS provides **encryption at rest and in transit** using **AWS KMS** (Key Management Service).
You can use **AWS-managed keys (aws/ebs)** or **customer-managed CMKs**.

**Key points:**
- Encrypted data stays encrypted during I/O operations.
- Snapshots of encrypted volumes are also encrypted.
- New volumes created from encrypted snapshots remain encrypted.
- Enable **EBS encryption by default** in your account for consistency.

```bash
aws ec2 enable-ebs-encryption-by-default
```

---

## 6. Modifying Volumes (Resize, Migrate, Tune)

You can dynamically **resize** or **change** EBS volume attributes without detaching it.

**Options you can modify:**
- Size (GB)
- IOPS
- Throughput (for gp3)

**After resizing:**
- Extend partition and filesystem inside the OS (`growpart`, `xfs_growfs`).

**Migration approach:**
- Create snapshot → New volume (different type or region) → Attach → Sync data.

```bash
aws ec2 modify-volume --volume-id vol-1234567890abcdef --size 200 --iops 8000 --throughput 600
```

---

## 7. Best Practices & Quick Summary

### Best Practices & Cost Optimization

- Use **gp3** for most workloads (better performance per $).
- Set **volume and snapshot tags** for cost tracking.
- Enable **EBS Lifecycle Manager** to automatically delete old snapshots.
- For large-scale systems, **align IOPS with EC2 bandwidth** to avoid bottlenecks.
- Use **RAID 0** (striping) for high I/O and **RAID 1** (mirroring) for durability if needed.
- Always **unmount before detaching** volumes to avoid data corruption.

---

### Quick Summary — Command Reference

| Task | Command | Description |
|---|---|---|
| Create new gp3 volume | `aws ec2 create-volume --size 50 --availability-zone us-east-1a --volume-type gp3` | Creates 50 GB volume |
| Attach volume | `aws ec2 attach-volume --volume-id <id> --instance-id <id> --device /dev/xvdf` | Mounts volume to instance |
| Create snapshot | `aws ec2 create-snapshot --volume-id <id> --description "backup"` | Point-in-time backup |
| Copy snapshot | `aws ec2 copy-snapshot --source-region us-east-1 --source-snapshot-id <id> --destination-region us-west-2` | Cross-region copy |
| Modify volume | `aws ec2 modify-volume --volume-id <id> --size 200` | Resize volume |
| List volumes | `aws ec2 describe-volumes` | View all attached/detached volumes |
| Enable encryption default | `aws ec2 enable-ebs-encryption-by-default` | Enforces KMS encryption |

**Linux Filesystem Resize Example:**

```bash
lsblk                                # list block devices
sudo growpart /dev/xvdf 1            # extend partition
sudo xfs_growfs /                    # expand filesystem
```

**Output:**

```
data blocks changed from 26214400 to 52428800
Filesystem successfully expanded
```

---

## What You Can Do After This

- Choose the right EBS volume type for a given workload
- Attach an EBS volume to an EC2 instance and extend the filesystem after resizing
- Create and manage snapshots for backup and cross-AZ/cross-Region data movement
- Enable EBS encryption by default at the account level
- Explain how RDS uses EBS underneath and why snapshots and sizing still matter

---

## What Comes Next

→ [05. S3](../05-s3/README.md)

EBS is attached to one instance in one AZ. S3 is different — global, serverless object storage that any service can read from or write to from anywhere.
