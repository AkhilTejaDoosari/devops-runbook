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

# AWS CLI + CloudFormation — From Manual Commands to Code-Driven Infrastructure

---

## Table of Contents

1. [Why CLI and CloudFormation](#1-why-cli-and-cloudformation)
2. [AWS CLI — Your Command-Line Bridge](#2-aws-cli--your-command-line-bridge)
3. [CloudFormation — Your Infrastructure Engine](#3-cloudformation--your-infrastructure-engine)
4. [Architecture Blueprint — Automation Flow](#4-architecture-blueprint--automation-flow)
5. [Template Deep Dive — Webstore EC2 Stack](#5-template-deep-dive--webstore-ec2-stack)
6. [Real-World Use Cases & Best Practices](#6-real-world-use-cases--best-practices)
7. [Quick Summary & Self-Audit](#7-quick-summary--self-audit)

---

## 1. Why CLI and CloudFormation

### Why Automation Matters

Manual provisioning through the console is fine for exploration — but it doesn't scale.
When every instance, bucket, or network must be created consistently across environments, **automation becomes survival**.

Automation:
- Removes human error
- Enforces repeatability
- Enables disaster recovery
- Saves time in testing, labs, and CI/CD

In AWS, **CLI** gives command-level control; **CloudFormation** codifies entire infrastructures.
They're two sides of the same efficiency coin.

### Analogy — Driver & Autopilot

| Tool | Analogy | Role |
|---|---|---|
| **AWS Console** | Manual driving | Visual, one-at-a-time actions |
| **AWS CLI** | Steering wheel | Command-based control over services |
| **CloudFormation** | Autopilot | Reads a flight plan (YAML/JSON) and provisions automatically |

You first learn to **drive manually** (CLI) — steering each service yourself —
then you let **autopilot (CloudFormation)** fly the same route flawlessly every time.

### The Problem Without Automation

Imagine decorating a house without writing anything down.
A few months later, you move rooms around — but you forget which switch turns on which light.
That's what happens when you **manage AWS by hand** using only the Console.

Without CLI or CloudFormation:
- You forget what settings you used before.
- Two teammates set up things differently.
- Fixing or recreating something takes hours.
- A simple mistake (like wrong region or subnet) breaks everything.

Automation is your **blueprint and memory**.
It ensures every server, bucket, and network can be rebuilt exactly the same way — anywhere, anytime, by anyone.

> "Manual setup is like cooking without a recipe.
> Automation is the cookbook that guarantees the same flavor every time."

---

## 2. AWS CLI — Your Command-Line Bridge

### Installing AWS CLI (Mac, Windows, Linux)

**For Mac (recommended):**

```bash
brew install awscli
```

or use the official pkg:

```bash
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
sudo installer -pkg AWSCLIV2.pkg -target /
```

**For Windows:**
Download → [AWSCLIV2.msi](https://awscli.amazonaws.com/AWSCLIV2.msi)

**For Linux:**

```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

**Verify installation:**

```bash
aws --version
```

---

### Configure Once

```bash
aws configure
```

You'll be asked for:
- Access Key ID
- Secret Key
- Default region (e.g., `us-east-1`)
- Output format (`json`, `table`, `text`)

After setup, your credentials are stored safely under `~/.aws/credentials`.

---

### Grand Table — Everyday AWS CLI Commands for DevOps Engineers

| Service | Task | Command | What It Does |
|---|---|---|---|
| **General** | Show current profile & region | `aws configure list` | Confirms which account/region you're using |
| | Switch region temporarily | `aws ec2 describe-instances --region us-west-2` | Overrides default |
| **S3 (Storage)** | List buckets | `aws s3 ls` | Shows all buckets |
| | Create bucket | `aws s3 mb s3://webstore-demo` | Makes a new S3 bucket |
| | Upload file | `aws s3 cp index.html s3://webstore-demo/` | Uploads a file |
| | Sync folders | `aws s3 sync ./website s3://webstore-demo` | Mirrors local → S3 |
| | Delete bucket | `aws s3 rb s3://webstore-demo --force` | Removes everything inside |
| **EC2 (Compute)** | List instances | `aws ec2 describe-instances` | View running/stopped servers |
| | Start instance | `aws ec2 start-instances --instance-ids i-1234abcd` | Boot up |
| | Stop instance | `aws ec2 stop-instances --instance-ids i-1234abcd` | Shut down |
| | Reboot instance | `aws ec2 reboot-instances --instance-ids i-1234abcd` | Restart |
| | Create key pair | `aws ec2 create-key-pair --key-name myKey > myKey.pem` | New SSH key |
| **IAM (Access)** | List users | `aws iam list-users` | Show all users |
| | Create user | `aws iam create-user --user-name devuser` | Adds IAM user |
| | Attach policy | `aws iam attach-user-policy --user-name devuser --policy-arn arn:aws:iam::aws:policy/AdministratorAccess` | Grants access |
| **CloudWatch (Monitoring)** | List metrics | `aws cloudwatch list-metrics` | Shows what's being tracked |
| | Get CPU stats | `aws cloudwatch get-metric-statistics --metric-name CPUUtilization --namespace AWS/EC2 --start-time 2025-11-10T00:00:00Z --end-time 2025-11-11T00:00:00Z --period 3600 --statistics Average` | View CPU usage |
| **Lambda (Serverless)** | List functions | `aws lambda list-functions` | Show deployed functions |
| | Invoke function | `aws lambda invoke --function-name myFunction out.json` | Run function manually |
| **CloudFormation (IaC)** | List stacks | `aws cloudformation list-stacks` | View deployed stacks |
| | Validate template | `aws cloudformation validate-template --template-body file://template.yml` | Check YAML before deploying |
| | Create stack | `aws cloudformation create-stack --stack-name MyStack --template-body file://template.yml` | Deploy infra |
| | Delete stack | `aws cloudformation delete-stack --stack-name MyStack` | Tear down infra |
| **Misc Tools** | Get caller identity | `aws sts get-caller-identity` | Confirms which user/account is active |
| | Get service help | `aws s3 help` | Shows CLI options for that service |

**Tip:** Bookmark this table — it's a "cloud survival sheet" for everyday DevOps work.

---

### When & Why to Use AWS CLI

Think of the **AWS CLI** as your **Swiss Army knife** for cloud work — small, fast, and available everywhere.

You use it when:
- You need to **check the health** of servers.
- You want to **move files** to or from S3 quickly.
- You must **start, stop, or reboot** EC2 instances.
- You're writing small **scripts or cron jobs** that talk to AWS automatically.
- You want to **verify** what CloudFormation deployed.

> The Console shows you *what exists*.
> The CLI lets you *command it directly.*

---

## 3. CloudFormation — Your Infrastructure Engine

### What It Does

CloudFormation turns human-readable templates (YAML/JSON) into live AWS resources — EC2, S3, VPC, IAM roles, everything.

You write **what you want**, AWS figures out **how to build it**.

---

### Core Concepts

| Term | Meaning |
|---|---|
| **Template** | Blueprint file describing resources |
| **Stack** | Deployed instance of a template |
| **Change Set** | Preview before applying changes |
| **Parameters** | Input values to reuse templates |
| **Outputs** | Key data exported to other stacks |

---

### Workflow

1. **Write Template**
2. **Upload** (local or S3)
3. **Create Stack**

```bash
aws cloudformation create-stack --stack-name WebstoreEC2Stack \
    --template-body file://webstore-ec2.yml
```

4. **Monitor** progress in Events tab
5. **Verify** resources in EC2 console
6. **Delete** cleanly:

```bash
aws cloudformation delete-stack --stack-name WebstoreEC2Stack
```

---

### Why Architects Love It

- Reproducible environments
- Version-controlled IaC
- Automatic dependency ordering
- Rollback on failure
- Integrates with GitHub Actions / Terraform / CI-CD

---

## 4. Architecture Blueprint — Automation Flow

```
Developer / Engineer
        │
        ▼
 ┌──────────────────────┐
 │ AWS CLI              │  ← Manual provisioning / testing
 └──────────┬───────────┘
            │
            ▼
 ┌──────────────────────┐
 │ AWS CloudFormation   │  ← IaC autopilot (templates)
 └──────────┬───────────┘
            │
            ▼
 ┌──────────────────────────────┐
 │ AWS Resources                │
 │  (EC2 | S3 | RDS | VPC | EKS)│
 └──────────────────────────────┘
            │
            ▼
   Consistent Infrastructure Ready
```

CLI = hands-on control
CloudFormation = repeatable automation
Together = full-spectrum DevOps efficiency.

---

## 5. Template Deep Dive — Webstore EC2 Stack

Below is a production-ready CloudFormation template that creates a secure EC2 instance with nginx serving the webstore frontend.

```yaml
AWSTemplateFormatVersion: '2010-09-09'
Description: >
  Webstore EC2 Linux VM Stack – creates a secure EC2 instance with SSH access.

Parameters:
  KeyPairName:
    Type: AWS::EC2::KeyPair::KeyName
    Description: Name of an existing EC2 KeyPair to SSH into the instance

Resources:
  WebstoreSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: Allow SSH and HTTP access
      VpcId: !Ref AWS::NoValue        # auto-picks default VPC
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 22
          ToPort: 22
          CidrIp: 0.0.0.0/0
        - IpProtocol: tcp
          FromPort: 80
          ToPort: 80
          CidrIp: 0.0.0.0/0

  WebstoreEC2Instance:
    Type: AWS::EC2::Instance
    Properties:
      ImageId: ami-0c02fb55956c7d316      # Amazon Linux 2 (us-east-1)
      InstanceType: t2.micro
      KeyName: !Ref KeyPairName
      SecurityGroupIds:
        - !Ref WebstoreSecurityGroup
      Tags:
        - Key: Name
          Value: Webstore-EC2-Instance
      UserData:
        Fn::Base64: |
          #!/bin/bash
          yum update -y
          amazon-linux-extras install nginx1 -y
          systemctl enable nginx
          systemctl start nginx
          echo "<h1>Welcome to Webstore EC2!</h1>" > /usr/share/nginx/html/index.html

Outputs:
  PublicIP:
    Description: Public IP address of the instance
    Value: !GetAtt WebstoreEC2Instance.PublicIp
  WebURL:
    Description: URL of the deployed web server
    Value: !Sub "http://${WebstoreEC2Instance.PublicDnsName}"
```

**Explanation Highlights:**
- **Security Group** → allows SSH + HTTP from anywhere.
- **EC2 Instance** → launches Amazon Linux 2 + auto-installs Nginx.
- **UserData** → boots with a welcome page.
- **Outputs** → instantly give you the Public IP and URL.

Deploy with:

```bash
aws cloudformation create-stack \
  --stack-name WebstoreEC2Stack \
  --template-body file://webstore-ec2.yml \
  --parameters ParameterKey=KeyPairName,ParameterValue=your-keypair
```

---

## 6. Real-World Use Cases & Best Practices

Instead of big jargon, let's make it real.

| Situation | Tool to Use | Example Scenario |
|---|---|---|
| **Morning Check** | AWS CLI | You start your day by checking which EC2 servers are running — `aws ec2 describe-instances`. |
| **Quick File Upload** | AWS CLI | You push today's build logs to S3 — `aws s3 cp logs.zip s3://webstore-logs/`. |
| **Recreate Environment** | CloudFormation | Need a test VPC + EC2 for a new feature? Run your template once and everything appears. |
| **Clean Up Resources** | AWS CLI | Before weekend, run `aws s3 rb s3://temp-bucket --force` to clear unused data. |
| **Disaster Recovery** | CloudFormation | Prod broke? Redeploy your saved template and get the same architecture back instantly. |
| **Learning / Testing** | Both | Try new configs using CLI, then document successful setup as a CloudFormation YAML. |

**Best Practices:**
- Keep all templates in version control (GitHub).
- Validate every template before running it.
- Use tags (`--tags Key=Owner,Value=Akhil`) for tracking cost.
- Practice deleting stacks often — it teaches clean teardown.

> "CLI gives you agility; CloudFormation gives you immortality."
> Both make sure your cloud doesn't depend on memory — only on mastery.

---

## 7. Quick Summary & Self-Audit

| Area | Key Checks |
|---|---|
| **AWS CLI** | Installed + configured correctly |
| **Access Keys** | Stored securely in credentials file |
| **Common Commands** | S3 list, EC2 describe, IAM users |
| **CloudFormation** | Understands Stacks, Parameters, Outputs |
| **Template Validation** | `validate-template` passes cleanly |
| **Stack Lifecycle** | Create → Update → Delete works error-free |
| **Reproducibility** | Same infra works across regions |

**I can:**
- Create and delete S3 buckets from CLI.
- Deploy the Webstore EC2 Stack via CloudFormation.
- Explain IaC benefits to a teammate in plain English.

**Automation turns good engineers into architects.**
Use **AWS CLI** to understand how AWS thinks, then let **CloudFormation** express that understanding in code.
When you can rebuild an entire environment with one file or one command — you've crossed from *manual operator* to *infrastructure designer.*

---

## What You Can Do After This

- Install and configure the AWS CLI
- Run daily EC2, S3, IAM, RDS, and CloudWatch commands confidently
- Write a CloudFormation template that creates infrastructure from scratch
- Deploy, update, and delete CloudFormation stacks
- Explain when to use CLI vs CloudFormation vs Terraform

---

## What Comes Next

→ [12. EKS](../12-eks/README.md)

All the infrastructure built manually across these labs — VPC, EC2, RDS, ALB, Route 53 — comes together in EKS, where the Kubernetes cluster from your laptop moves into AWS.
