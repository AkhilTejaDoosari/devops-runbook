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

# AWS S3 (Simple Storage Service)

EBS works great inside one zone, but sometimes data needs to travel — backups, media, global access.
That's where S3 (Simple Storage Service) takes over.
Instead of local disks, it's like a giant warehouse in the cloud — infinite shelves where any app can drop a file and pick it up from anywhere on the planet.

---

## Table of Contents

1. [What Is S3](#1-what-is-s3)
2. [Core Concept — Buckets and Objects](#2-core-concept--buckets-and-objects)
3. [Bucket Naming Rules](#3-bucket-naming-rules)
4. [Static Website Hosting](#4-static-website-hosting)
5. [Versioning](#5-versioning)
6. [Storage Classes and Pricing](#6-storage-classes-and-pricing)
7. [Security, Lifecycle, and Encryption](#7-security-lifecycle-and-encryption)
8. [Real Example — Webstore on S3](#8-real-example--webstore-on-s3)
9. [CLI Reference](#9-cli-reference)

---

## 1. What Is S3

### Why Do We Need S3?

EBS volumes are reliable but tied to one instance in one zone.
They're perfect for operating systems or databases — not for global sharing.

When applications grow, you need a place where:
- Any service can store or fetch data, anytime.
- Capacity expands automatically.
- Costs depend on how much you store.

That's **Amazon S3** — an object-storage service that acts like a limitless data vault.
You can store photos, backups, code, logs, or even full websites — pay only for what you use.

### Analogy — The Infinite Warehouse

Think of S3 as an **endless warehouse** in the cloud.
Each **bucket** is a storage room with its own label.
Every file you drop inside becomes an **object**, tagged with a unique barcode (its URL).

You can walk in, store or retrieve any object from anywhere in the world.
Unlike an EBS disk, this warehouse has no walls, no cables — just infinite shelves that never fill up.

---

## 2. Core Concept — Buckets and Objects

- You create **buckets** to organize data. Each bucket name must be globally unique.
- Inside a bucket, every uploaded **object** is stored with:
  - **Key** → the file name / path
  - **Value** → file data
  - **Metadata** → object info
  - **Version ID** (if versioning is on)

S3 automatically replicates data across devices in the same region for durability (11 nines).

Example URL:
```
https://my-bucket.s3.amazonaws.com/image.png
```

**Architect's Note:**
S3 is a **global service**, but buckets are **region-specific**.
Pick regions closer to your users to reduce latency.

---

## 3. Bucket Naming Rules

| Rule | Description |
|---|---|
| Length | 3 – 63 characters |
| Characters | a-z, 0-9, period (.), hyphen (-) |
| Must start/end with | Letter or number |
| Global uniqueness | No two buckets share the same name |
| Forbidden | Uppercase, underscores, or spaces |

**Tip:** For websites, match your bucket name to your domain (e.g., `webstore-assets.com`).

---

## 4. Static Website Hosting

S3 can host **static websites** — sites made of HTML, CSS, and JS files that look identical for all users.

**Steps:**
1. Create a bucket (often named after your domain).
2. Upload your website files (`index.html`, `error.html`).
3. Enable **Static Website Hosting** under *Properties*.
4. Provide the index and error documents.
5. Make objects publicly readable.
6. Access your site via the generated endpoint URL.

Example endpoint:
`http://webstore-website.s3-website-us-east-1.amazonaws.com`

**Modern tip:** For production, use **AWS Amplify** or **CloudFront** for performance and HTTPS.

---

## 5. Versioning

Think of versioning as an **undo button** for your bucket.
When enabled, every new upload of the same object keeps the previous version rather than replacing it.

- **Default:** Disabled (new file overwrites the old one).
- **Enabled:** S3 preserves all versions.
- **Suspended:** Keeps existing versions but stops new ones.

**Why it matters in DevOps:**
- Recover from accidental deletes or overwrites.
- Track configuration file history or deployment artifacts.
- Combine with Lifecycle policies to expire old versions automatically.

---

## 6. Storage Classes and Pricing

### Storage Classes with Scenarios

Different data deserves different storage costs.
Here's how each S3 storage class fits a real-world use case:

| Storage Class | When to Use | Real Scenario |
|---|---|---|
| **Standard** | Frequently accessed data | Website images, app assets, or user uploads accessed every day. |
| **Intelligent-Tiering** | Unknown or changing access patterns | Logs and reports whose popularity changes — S3 auto-moves them between hot/cold tiers. |
| **Standard-IA (Infrequent Access)** | Accessed once or twice a month | Monthly analytics exports, historical sales reports. |
| **One Zone-IA** | Rarely used and easily reproducible | Cached data or thumbnails that can be recreated anytime. |
| **Glacier Instant Retrieval** | Archives needed quarterly with instant access | Marketing footage or past project files that must be instantly restored. |
| **Glacier Flexible Retrieval** | Long-term archives, retrieved occasionally | Tax filings or compliance documents you access once a year. |
| **Glacier Deep Archive** | Long-term retention, rarely accessed | 7-year legal backups or raw sensor data for audit purposes. |
| **Reduced Redundancy** | Legacy option (not recommended) | Old, non-critical assets; replaced by Standard class today. |

**Architect's rule:** Match **frequency of access** with **cost of storage** — frequent = Standard; rare = Glacier.

---

### How S3 Billing Actually Works

S3 pricing depends on **what you store and how you use it**, not on how many buckets you create.

| Charged For | Example |
|---|---|
| **Storage (GB per month)** | Total size of all objects in all buckets |
| **Requests** | PUT / GET / COPY / DELETE calls made to S3 |
| **Data Transfer Out** | Data leaving S3 to the Internet or another AWS Region |
| **Optional Features** | Replication, Inventory, Analytics, Object Lock, etc. |

You **do not** pay for:
- Number of buckets
- Number of folders
- How many EC2 instances access them

If you store **1 TB** of data — whether it lives in one bucket or ten — the cost is identical.

---

### Multiple Buckets vs One Big Bucket

| Approach | Pros | Notes |
|---|---|---|
| **Single bucket with folders** | Simpler to manage, one policy to maintain | Harder to apply different lifecycle or security rules |
| **Separate buckets per data type** | Clear boundaries for policy and lifecycle; easy cost breakdown | Slightly more management overhead, but no extra charges |

**Example — webstore bucket design:**
- `webstore-assets` → product images (Standard → IA lifecycle)
- `webstore-logs` → app logs (Intelligent-Tiering → Glacier)
- `webstore-backups` → database exports (Deep Archive)
- `webstore-tf-state` → Terraform state files (Standard + versioning)

All together they cost the same as one huge bucket — only the **usage** matters.

---

### EC2 and S3 Interaction Costs

S3 isn't "attached" like EBS; EC2 accesses it via the S3 API (HTTPS).

| Scenario | Cost |
|---|---|
| EC2 ↔ S3 in same region | Free for inbound and most outbound traffic |
| EC2 ↔ S3 cross-region | Inter-region data transfer fees apply |
| EC2 ↔ S3 via Internet (no VPC endpoint) | Charged as Internet egress per GB |

**Architect's Guideline:**
- Use **multiple buckets** if you need different security or retention rules.
- Use **one bucket with folders** for simpler projects.
- Always keep S3 and EC2 in the same region to avoid transfer charges.
- Tag buckets to track cost by project or environment.

---

## 7. Security, Lifecycle, and Encryption

### Security & Access Control

S3 security is multi-layered:

1. **IAM Policies** → Who can access S3 resources.
2. **Bucket Policies** → What specific actions are allowed or denied at bucket level.
3. **ACLs** → Object-level access (legacy, rarely used).
4. **Block Public Access** → Global safeguard against accidental exposure.
5. **Encryption** → Protects data both at rest (AES-256 / KMS) and in transit (HTTPS).

Always use **IAM roles** for EC2 or Lambda to grant temporary, secure access instead of embedding keys.

---

### Lifecycle Management

As data ages, its value often drops.
**Lifecycle rules** let you automate storage transitions and deletions.

Example policy ideas:
- Move logs to **Glacier** after 30 days.
- Delete old object versions after 90 days.
- Permanently remove expired data after 1 year.

This keeps S3 lean, cost-efficient, and self-maintaining.

---

### Encryption & Consistency

- **At Rest:** S3 encrypts objects with AES-256 (SSE-S3) or AWS KMS (SSE-KMS).
- **In Transit:** Uses HTTPS/TLS for secure uploads and downloads.
- **Data Consistency:** Offers strong read-after-write consistency for all PUT and DELETE operations.

These features make S3 safe for both personal data and enterprise-grade workloads.

---

## 8. Real Example — Webstore on S3

In the **webstore app**, product images and static assets sit inside S3 buckets — secure, versioned, and globally accessible.
When a user views a product, the app fetches metadata (title, price, description) from **RDS**, then serves the product image directly from **S3** through a pre-signed URL.

This separation keeps:
- **RDS** focused on lightweight queries
- **S3** handling heavy media storage
- **EC2** running business logic

```
webstore-assets/
  images/product-001.jpg   ← served via pre-signed URL
  images/product-002.jpg
  static/style.css

webstore-backups/
  db-2026-04-01.dump.gz    ← postgres backup uploaded by Bash script

webstore-tf-state/
  terraform.tfstate         ← versioned, never public
```

**Webstore Terraform state backend (S3 + DynamoDB locking):**

```hcl
terraform {
  backend "s3" {
    bucket         = "webstore-tf-state"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "webstore-tf-lock"
    encrypt        = true
  }
}
```

**Pre-signed URL generation (webstore-api serving product images):**

```bash
aws s3 presign s3://webstore-assets/images/product-001.jpg \
  --expires-in 3600
```

---

## 9. CLI Reference

### AWS CLI Examples

```bash
# Upload a file
aws s3 cp product-001.jpg s3://webstore-assets/images/product-001.jpg

# Download a file
aws s3 cp s3://webstore-assets/images/product-001.jpg ./downloads/

# Sync local folder to bucket
aws s3 sync ./media s3://webstore-assets/

# Remove an object
aws s3 rm s3://webstore-assets/images/old-product.jpg
```

### Quick Command Summary

| Command | Description |
|---|---|
| `aws s3 mb s3://bucket` | Make a new bucket |
| `aws s3 ls` | List buckets |
| `aws s3 ls s3://bucket/` | List objects in bucket |
| `aws s3 cp file s3://bucket` | Upload object |
| `aws s3 rm s3://bucket/file` | Delete object |
| `aws s3 sync local/ s3://bucket/` | Sync folders |
| `aws s3 rb s3://bucket --force` | Remove bucket and contents |
| `aws s3 presign s3://bucket/file --expires-in 3600` | Generate pre-signed URL |

---

## What You Can Do After This

- Create and configure S3 buckets with correct access controls
- Design a multi-bucket strategy for the webstore (assets, backups, state)
- Enable versioning and configure lifecycle rules for cost management
- Explain the difference between S3 storage classes and when to use each
- Generate pre-signed URLs so applications serve S3 objects without making buckets public
- Use S3 as a Terraform state backend with DynamoDB locking

---

## What Comes Next

→ [06. EC2](../06-ec2/README.md)

You have networking, IAM, block storage, and object storage. Now you need compute — EC2 (Elastic Compute Cloud) is the virtual machine that ties all of it together into a running server.
