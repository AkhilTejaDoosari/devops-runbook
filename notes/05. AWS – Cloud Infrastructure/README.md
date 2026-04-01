# ☁️ AWS & Cloud Computing — Learning Series

> **"From zero to cloud-fluent — one service at a time."**
>
> This series builds your AWS knowledge from the ground up, moving inside-out:
> starting with identity and trust (IAM), stepping outward into networking (VPC),
> storage (EBS, EFS, S3), compute (EC2), databases (RDS), and finally into
> automation, scaling, and infrastructure as code.
>
> By the end, you won't just *know* AWS services — you'll think like an architect
> who sees how they connect and why each piece matters.

---

## 📚 Series Index

| # | Module | What You'll Learn |
|---|--------|-------------------|
| 01 | [Intro to AWS](./01-intro-aws/README.md) | Cloud computing fundamentals, why AWS, service models (IaaS / PaaS / SaaS), global infrastructure (Regions, AZs, Edge Locations), Free Tier setup |
| 02 | [IAM](./02-iam/README.md) | Users, Groups, Policies, Roles, MFA — who gets the keys and what doors they can open |
| 03 | [VPC & Subnet](./03-vpc-subnet/README.md) | Virtual Private Cloud, subnets, route tables, internet gateways, security groups, NACLs |
| 04 | [EBS](./04-ebs/README.md) | Elastic Block Store — persistent block storage for EC2, volume types, snapshots, encryption |
| 05 | [EFS](./05-efs/README.md) | Elastic File System — shared file storage across multiple EC2 instances |
| 06 | [S3](./06-s3/README.md) | Simple Storage Service — object storage, buckets, versioning, storage classes, lifecycle policies |
| 07 | [EC2](./07-ec2/README.md) | Elastic Compute Cloud — launching and managing virtual machines on AWS |
| 08 | [RDS](./08-rds/README.md) | Relational Database Service — managed databases, Multi-AZ, backups, read replicas |
| 09 | [Load Balancing & Auto Scaling](./09-Load-balancing-auto-scaling/README.md) | ALB / NLB / GWLB, health checks, Auto Scaling Groups, scaling policies |
| 10 | [CloudWatch & SNS](./10-cloudwatch-sns/README.md) | Metrics, alarms, logs, pub/sub alerting — the eyes and bell of AWS |
| 11 | [Lambda](./11-lambda/README.md) | Serverless compute — event-driven functions with no infrastructure to manage |
| 12 | [Elastic Beanstalk](./12-elastic-beanstalk/README.md) | PaaS deployment — upload code, AWS handles EC2, ALB, ASG, and monitoring |
| 13 | [Route 53](./13-route53/README.md) | Global DNS — domain registration, hosted zones, routing policies, health checks |
| 14 | [CLI + CloudFormation](./14-cli-cloudformation/README.md) | AWS CLI commands and Infrastructure as Code using CloudFormation templates |

---

## 🗺️ Learning Path

The series is designed to be followed in order — each module builds on the last.

```
IAM → VPC → EBS → EFS → S3 → EC2 → RDS
           ↓
  Load Balancing + Auto Scaling
           ↓
   CloudWatch + SNS → Lambda
           ↓
 Elastic Beanstalk → Route 53 → CLI + CloudFormation
```

---

## 🧱 What This Series Covers

**Phase 1 — Identity & Trust**
IAM lays the security foundation before anything else is built. Every user, service, and automation in AWS traces back to an IAM identity.

**Phase 2 — Networking**
VPC creates the private cloud environment — the roads, gates, and rules everything else runs inside.

**Phase 3 — Storage**
EBS (local disk), EFS (shared filesystem), and S3 (object warehouse) cover every storage shape an application needs.

**Phase 4 — Compute & Databases**
EC2 runs your applications; RDS stores and manages your structured data reliably.

**Phase 5 — Resilience & Scale**
Load Balancing + Auto Scaling + CloudWatch + SNS keep systems stable, observable, and self-healing under real-world load.

**Phase 6 — Automation & Delivery**
Lambda, Elastic Beanstalk, Route 53, and CloudFormation take you from manually managing resources to deploying and scaling infrastructure as code.

---

## 🎯 Who This Is For

- Engineers building toward an **entry-level Cloud / DevOps role**
- Anyone who wants to understand AWS services at the *why* level, not just the *how*
- Learners who prefer **hands-on examples, analogies, and decision tables** over pure reference docs

---

## 🔧 Practical Example — ChillSpot

Throughout this series, a fictional containerized streaming platform called **ChillSpot** serves as the running practical example. Each module shows how a real-world application uses that AWS service — from storing media in S3, querying metadata from RDS, running compute on EC2, to routing global traffic through Route 53.

---

## 📎 Quick Reference

| Topic | Key Service | Core Idea |
|-------|-------------|-----------|
| Identity | IAM | Who can do what, on which resource |
| Networking | VPC | Private network inside AWS |
| Block Storage | EBS | Persistent disk for one EC2 |
| File Storage | EFS | Shared filesystem across EC2s |
| Object Storage | S3 | Unlimited flat file storage |
| Compute | EC2 | Rent a virtual machine |
| Database | RDS | Managed SQL database |
| Traffic | ALB / NLB | Distribute requests across servers |
| Scale | Auto Scaling | Add / remove EC2 automatically |
| Observe | CloudWatch | Metrics, logs, alarms |
| Alert | SNS | Pub/sub notifications |
| Serverless | Lambda | Run code without a server |
| PaaS Deploy | Beanstalk | Upload code, AWS runs the rest |
| DNS | Route 53 | Domain → IP, with routing logic |
| IaC | CloudFormation | Infrastructure defined as templates |

---

*Start with [01 — Intro to AWS](./01-intro-aws/README.md) →*