[🏠 Home](../README.md) | 
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

---
# Introduction to AWS & Cloud Computing

Every system we build — from a small web app to a global streaming platform — runs on three invisible pillars: compute, storage, and networking.
AWS brings all three together as building blocks you can rent, combine, and scale instantly.
Instead of buying servers or worrying about power, racks, and backups, you build with ready-made components — like assembling Lego blocks in the cloud.

In this journey, we’ll move from the inside out — starting with the smallest unit of trust and control (IAM), then stepping outward to networks (VPC), storage (EBS, S3), compute (EC2), databases (RDS), and finally into automation, scaling, and infrastructure as code.

By the end, you won’t just “know” AWS services — you’ll think like an architect who sees how they connect and why each piece matters.

## Table of Contents

1. [Why Cloud Computing?](#1-why-cloud-computing)
2. [Why AWS?](#2-why-aws)
3. [Cloud Service Models](#3-cloud-service-models)
4. [Creating an AWS Free Tier Account](#4-creating-an-aws-free-tier-account)
5. [AWS Global Infrastructure (2025 Update)](#5-aws-global-infrastructure-2025-update)

---

<details>
<summary><strong>1. Why Cloud Computing?</strong></summary>

### The Problem Before Cloud

In the pre-cloud era, companies bought **physical servers** and ran their own data centers.
This meant:

* High capital cost for hardware and maintenance.
* Under-utilized resources (servers idling most of the time).
* Slow scaling and complex upgrades.

### The Cloud Revolution

Cloud Computing lets you **rent computing power, storage, and networks over the internet**.
You pay only for what you use and scale instantly without owning hardware.

| Concept             | Description                        | Example                           |
| ------------------- | ---------------------------------- | --------------------------------- |
| **Physical Server** | One machine per application        | HP or IBM server in a data center |
| **Virtualization**  | Many VMs on one server             | 1 physical → 10 virtual machines  |
| **Cloud Computing** | On-demand virtual resources online | Launch an EC2 instance on AWS     |

💡 **Analogy:** Owning a generator vs paying the electric bill — Cloud is on-demand power.

</details>

---

<details>
<summary><strong>2. Why AWS?</strong></summary>

### AWS at a Glance (2025)

* **Launch Year:** 2006 – first public cloud provider.
* **Market Share:** ~60% of cloud jobs worldwide.
* **Global Coverage:** 36 active Regions, 114 Availability Zones (AZs), 400+ Edge Locations.
* **Upcoming Regions:** Mexico, Taiwan, New Zealand, Saudi Arabia.

| Provider         | Core Strength                         | Market Presence |
| ---------------- | ------------------------------------- | --------------- |
| **AWS**          | Largest service portfolio & ecosystem | ⭐⭐⭐⭐⭐           |
| **Azure**        | Enterprise integration with Microsoft | ⭐⭐⭐             |
| **Google Cloud** | AI / ML excellence                    | ⭐⭐              |

### Why Start with AWS

* Standard in DevOps and Cloud roles.
* Skills transfer easily to Azure & GCP.
* Rich documentation and global community.

💡 **Analogy:** Learning AWS is like learning English first — opens every door in tech.

</details>

---

<details>
<summary><strong>3. Cloud Service Models</strong></summary>

### Theory & Notes

* **IaaS (Infrastructure as a Service)**

  * **What it is:** The provider gives you raw infrastructure — virtual machines, storage, and networks — over the internet.
  * **You manage:** Operating systems, applications, runtime, security patches.
  * **Provider manages:** Physical hardware, data centers, and virtualization.
  * **Analogy:** Renting a piece of land — you build your own house but don’t own the land.
  * **Examples:** AWS EC2, Google Compute Engine, Microsoft Azure VMs.

* **PaaS (Platform as a Service)**

  * **What it is:** The provider gives you infrastructure plus platforms/tools (like databases, runtime environments).
  * **You manage:** Only your code and data.
  * **Provider manages:** Infrastructure, OS, runtime, scaling, and security.
  * **Analogy:** Renting a fully furnished apartment — you move in and start using it.
  * **Examples:** AWS Elastic Beanstalk, Google App Engine, Heroku.

* **SaaS (Software as a Service)**

  * **What it is:** Complete software delivered over the internet.
  * **You manage:** Only usage and basic settings.
  * **Provider manages:** Everything else.
  * **Analogy:** Booking a hotel room — you enjoy the service without managing anything.
  * **Examples:** Gmail, Google Drive, Dropbox, Salesforce, Zoom.

---

| Model    | Provider Manages                     | You Manage              | Real Examples           | Best For    |
| -------- | ------------------------------------ | ----------------------- | ----------------------- | ----------- |
| **IaaS** | Hardware, Virtualization, Networking | OS, Runtime, Apps, Data | AWS EC2, Google Compute | Custom apps |
| **PaaS** | Everything above + OS, Runtime       | Apps, Data              | AWS Beanstalk, Heroku   | Developers  |
| **SaaS** | Everything                           | Only usage/config       | Gmail, Salesforce, Zoom | End users   |

---

### Cloud Market Comparison

| Cloud Provider        | Market Position  | Key Strengths                        | Job Market Share |
| --------------------- | ---------------- | ------------------------------------ | ---------------- |
| **AWS (Amazon)**      | #1 Market Leader | First-mover advantage, 200+ services | ~60%             |
| **Azure (Microsoft)** | #2 Strong Second | Deep Windows/Office integration      | ~25%             |
| **GCP (Google)**      | #3 Growing Fast  | Superior AI/ML tools                 | ~10%             |
| **Others**            | Niche Players    | Specialized industry solutions       | ~5%              |

* **High Demand:** AWS professionals are in the highest demand across industries.
* **Better Compensation:** Higher salaries and strong job security.
* **Skill Transferability:** Core AWS concepts work across clouds.
* **Ecosystem Support:** Huge community and documentation base.

<img src="images/service-control.jpg" alt="" width="600" height="375" />

</details>

---

<details>  
<summary><strong>4. Creating an AWS Free Tier Account</strong></summary>

### **Step-by-Step**

1. Visit [aws.amazon.com](https://aws.amazon.com) → click **“Create an AWS Account.”**  
2. Enter a valid email, strong password, and account name.  
3. Add a **credit or debit card** (for identity verification — Free Tier doesn’t charge if you stay within limits).  
4. Complete **SMS verification**.  
5. Choose the **Free Tier plan** when prompted.  
6. Sign in as **Root User** and open the **AWS Management Console**.

🎥 *Visual Guide:* [How to Create an AWS Free Tier Account (YouTube)](https://www.youtube.com/results?search_query=create+aws+free+tier+account)

---

### **Key Terms**

| Term | Meaning | Example |
|------|----------|----------|
| **Root User** | Full-access owner of the AWS account | Used for billing and account-level security |
| **IAM User** | Secure account for daily operations | You’ll create this next |
| **Free Tier** | Limited-usage plan or credit system for new users | 750 hrs/month of EC2 micro (for older accounts) |

---

### **⚙️ Free Tier Rules in 2025**

AWS introduced an updated Free Tier model on **July 15, 2025**.  
The eligibility depends on **when your account was created**:

| Account Created | What You Get | Duration | Notes |
|-----------------|---------------|-----------|--------|
| **Before July 15 2025** | Classic 12-month Free Tier | 12 months | Includes EC2 750 hrs/month, RDS 750 hrs/month, S3 5 GB, CloudWatch/Lambda “Always Free.” |
| **On or After July 15 2025** | New **Credit-based Free Tier** | Variable | You get ≈ $100–$200 credits + “Always Free” services (no fixed 12 months). |

---

### **🧭 2025 Free Tier Highlights (Classic Accounts)**

| Service | Free Limit | Duration |
|----------|-------------|-----------|
| **EC2** | 750 hrs/month (t2.micro or t3.micro) | 12 months |
| **RDS** | 750 hrs/month (MySQL, PostgreSQL, MariaDB, etc.) | 12 months |
| **S3** | 5 GB Standard storage | 12 months |
| **CloudWatch & Lambda** | Always Free within limits | Unlimited |
| **Credits (varies)** | ≈ $100 welcome credit for new accounts | Promo-based |

> 🔸 *If you signed up after July 15 2025, you’ll see a credit balance instead of time-based limits.  
> Always check **Billing → Free Tier Dashboard** to confirm what applies to you.*

---

### **Best Practices**

- Use the **Root User** only for **billing** and **security** tasks.  
- Enable **MFA (Multi-Factor Authentication)** on the Root User.  
- Create an **IAM Admin User** for all daily operations.  
- Regularly monitor usage in **Billing → Free Tier Dashboard** to avoid accidental charges.  

---

<details>
<summary><strong>📘 Note – AWS Free Tier Change (July 2025 Update)</strong></summary>

AWS modified its **Free Tier policy on July 15, 2025**.  
Your benefits depend on **when your account was created**:

| Account Created | Model | What You Get |
|-----------------|--------|---------------|
| **Before July 15 2025** | Classic Free Tier | 12 months of free usage for core services:<br>• EC2 750 hrs/month (t2.micro or t3.micro)<br>• RDS 750 hrs/month (MySQL/PostgreSQL/MariaDB)<br>• S3 5 GB Standard Storage<br>• CloudWatch & Lambda always free within limits |
| **On or After July 15 2025** | Credit-based Free Tier | No fixed 12-month period — instead you receive ≈ $100 to $200 in credits plus ongoing “Always Free” services. |

**Quick Reminder:**  
- The “12-month Free Tier” wording applies **only** to accounts created before July 15 2025.  
- Newer accounts follow the **credit model**, so verify your balance and limits under **Billing → Free Tier Dashboard** in the AWS Console.  
- AWS may adjust credits or service quotas by region or promotion, so always confirm your exact limits.

</details>

</details>

---

<details>
<summary><strong>5. AWS Global Infrastructure (2025 Update)</strong></summary>

### Why It Exists

AWS built a **worldwide network of data centers** so users anywhere can run apps with low latency and high reliability.
If one area goes down, others keep running — this is fault tolerance by design.

---

### Core Building Blocks

| Component                  | 2025 Count                         | Purpose                                  | Example                | Analogy                       |
| -------------------------- | ---------------------------------- | ---------------------------------------- | ---------------------- | ----------------------------- |
| **Region**                 | 36 active + 4 announced            | Geographic cluster of data centers       | `us-east-1` (Virginia) | Country                       |
| **Availability Zone (AZ)** | 114 operational                    | Independent data center within a Region  | `us-east-1a`           | City                          |
| **Edge Location**          | 400+                               | Delivers content fast via CloudFront CDN | Tokyo, Miami           | Courier hub                   |
| **Local Zone**             | 20+                                | Brings compute closer to metro areas     | Los Angeles            | Neighborhood station          |
| **Wavelength Zone**        | Telco partnerships (Verizon, KDDI) | Extends AWS to 5G networks               | AWS on Verizon 5G      | Mobile tower mini-data center |

---

### How They Work Together

* **Regions** are independent geographic areas.
* Each Region has 2–6 **AZs**, each with separate power & networking.
* **Edge Locations** serve cached data close to users for speed.
* **Local Zones** handle low-latency tasks like gaming or streaming.

📘 **Example:** An EC2 instance in `us-east-1` runs inside an AZ (e.g., `us-east-1a`).
You can replicate it to `us-east-1b` for high availability.

---

### Best Practices

| Goal                  | Recommendation                        | Why                                |
| --------------------- | ------------------------------------- | ---------------------------------- |
| **High Availability** | Use multiple AZs in the same Region   | One AZ failure won’t stop your app |
| **Low Latency**       | Choose Region closest to end-users    | Faster responses                   |
| **Data Compliance**   | Store data in legally approved Region | Meets local laws                   |
| **Cost Optimization** | Compare Region pricing                | Rates vary globally                |

---

### Real-World Analogy

Think of AWS like **Netflix’s global distribution system**:

* **Regions** = big production campuses.
* **AZs** = buildings inside those campuses.
* **Edge Locations** = servers in your city’s ISP delivering content instantly.

So when someone in India streams a movie, it’s served from the Mumbai Edge Location within the India Region — not from Virginia.

✅ **Key Takeaway:** AWS’s superpower is its **redundancy + reach** — a web of Regions, AZs, and Edge Locations ensuring speed and reliability everywhere.

</details>

---