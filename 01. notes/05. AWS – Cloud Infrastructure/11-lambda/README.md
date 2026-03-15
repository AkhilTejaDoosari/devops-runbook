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

# ⚡ AWS Lambda — “The Invisible Compute Engine”

> **Run code without servers. Pay only when it runs.**
> **Phase 5 – Automation & Serverless**

---

## Table of Contents

1. [Prerequisites (Read Me First)](#1-prerequisites-read-me-first)
2. [Why Lambda Exists](#2-why-lambda-exists)
3. [What Lambda Is (and Isn’t)](#3-what-lambda-is-and-isnt)
4. [Core Building Blocks](#4-core-building-blocks)
5. [Event Sources & Triggers](#5-event-sources--triggers)
6. [Execution Model & Lifecycle](#6-execution-model--lifecycle)
7. [Permissions, Security & Networking](#7-permissions-security--networking)
8. [Concurrency, Scaling & Cold Starts](#8-concurrency-scaling--cold-starts)
9. [Observability: Logs, Metrics, DLQ & Retries](#9-observability-logs-metrics-dlq--retries)
10. [Packaging, Versions, Aliases, Layers & Container Images](#10-packaging-versions-aliases-layers--container-images)
11. [Hands-On Workflow (Console + CLI)](#11-hands-on-workflow-console--cli)
12. [IaC Snapshot (CloudFormation YAML)](#12-iac-snapshot-cloudformation-yaml)
13. [Architectures & Diagrams](#13-architectures--diagrams)
14. [Best Practices (Prod-Ready)](#14-best-practices-prod-ready)
15. [Pricing & Cost Controls](#15-pricing--cost-controls)
16. [Quick Summary](#16-quick-summary)
17. [Self-Audit Checklist](#17-self-audit-checklist)

---

<details>
<summary><strong>1. Prerequisites (Read Me First)</strong></summary>

* **CloudWatch & SNS** (for logs, alarms, notifications).
* **IAM basics** (roles, policies, least privilege).
* **VPC & subnets** (only if you run Lambda inside a VPC).
* **Optional:** AWS CLI for the hands-on; full CLI deep-dive appears later in your `15. AWS CLI.md`.

> 💡 If CLI isn’t comfortable yet, read conceptually and use the console steps. You’ll master the CLI in Phase 6 and come back to automate.

</details>

---

<details>
<summary><strong>2. Why Lambda Exists</strong></summary>

Traditional servers are wasteful for bursty, short tasks. Lambda removes server management and auto-scales to **events**.
Result: faster delivery, lower ops overhead, and pay-per-use economics.

</details>

---

<details>
<summary><strong>3. What Lambda Is (and Isn’t)</strong></summary>

**Is:** Event-driven, stateless compute that executes your function code on demand.
**Isn’t:** A long-running server, a place to keep connection state, or a fit for heavy, always-on workloads.

Good fits: API backends, file processing, scheduled jobs, lightweight ETL, async workers, event routing, glue code.

</details>

---

<details>
<summary><strong>4. Core Building Blocks</strong></summary>

| Concept            | What it means                                        |
| ------------------ | ---------------------------------------------------- |
| **Function**       | Your code + config.                                  |
| **Handler**        | Entry point Lambda calls (e.g., `app.handler`).      |
| **Runtime**        | Language env (Node, Python, Java, .NET, Go, custom). |
| **Timeout**        | Up to **15 minutes** per invocation.                 |
| **Memory**         | 128 MB – 10 GB (CPU scales with memory).             |
| **Ephemeral /tmp** | Up to 10 GB scratch space inside execution env.      |
| **Env Vars**       | Config injected at runtime (secrets via KMS).        |
| **Execution Role** | IAM role Lambda assumes to access AWS APIs.          |

</details>

---

<details>
<summary><strong>5. Event Sources & Triggers</strong></summary>

Common **synchronous** triggers: **API Gateway**, **ALB**, **Lambda Function URL**.
Common **asynchronous**/stream triggers: **S3**, **SNS**, **EventBridge (CloudWatch Events)**, **SQS**, **Kinesis**, **DynamoDB Streams**, **Step Functions**.

```
Users → API Gateway → Lambda → DynamoDB
S3 PutObject → Lambda (thumbnail)
EventBridge schedule → Lambda (nightly job)
SQS queue → Lambda (async worker)
```

</details>

---

<details>
<summary><strong>6. Execution Model & Lifecycle</strong></summary>

1. **Initialization (Init / Cold Start)**

   * Runtime boot, code load, handler init, extensions init.
2. **Invoke (Warm)**

   * Lambda reuses the environment for subsequent requests if possible.
3. **Freeze / Reuse / Evict**

   * Env frozen between invokes; eventually recycled by the service.

**Statefulness note:** Keep code **stateless**; cache clients (DB, SDK) **outside** the handler to benefit from warm reuse.

</details>

---

<details>
<summary><strong>7. Permissions, Security & Networking</strong></summary>

* **Execution Role (IAM):** Grants access to AWS services (S3 get/put, DynamoDB, etc.).
* **Resource Policies:** Allow external services (e.g., S3, EventBridge) to invoke your function.
* **KMS:** Encrypt env vars & payloads when needed.
* **VPC Config:** If your function needs private resources (RDS/ElastiCache), attach to **private subnets** with **NAT** for outbound Internet.
* **Least privilege:** Narrow policies; separate roles per function.

</details>

---

<details>
<summary><strong>8. Concurrency, Scaling & Cold Starts</strong></summary>

* **Concurrency =** how many executions run in parallel.
* **Burst scaling**: Region-dependent large bursts; then scales linearly.
* **Reserved Concurrency:** Hard cap per function (prevents noisy neighbors).
* **Provisioned Concurrency:** Keeps environments warm to reduce cold starts (extra cost).
* **Cold starts:** Longer on VPC + heavy runtimes; mitigate with provisioned concurrency, lighter runtimes, smaller packages, and connection reuse.

</details>

---

<details>
<summary><strong>9. Observability: Logs, Metrics, DLQ & Retries</strong></summary>

* **Logs** → CloudWatch Logs (one log group per function).
* **Metrics** → Invocations, Duration, Errors, Throttles, IteratorAge (streams).
* **Retries**

  * **Async** (S3/SNS/EventBridge): automatic retries + optional **DLQ** (SQS/SNS).
  * **Streams** (Kinesis/DDB): retries until success; use **on-failure destination** or **bisect** patterns.
  * **Sync** (API Gateway): caller sees error; you retry in client or upstream.
* **Destinations** (async): route **success/failure** events to SNS/SQS/Lambda/EventBridge for auditing.
* **Lambda Insights**: enhanced metrics + profiling.

</details>

---

<details>
<summary><strong>10. Packaging, Versions, Aliases, Layers & Container Images</strong></summary>

* **Zip package** (fastest start for most).
* **Container image** (up to 10 GB) when you need OS deps / custom runtimes.
* **Versions**: Immutable snapshots of code+config.
* **Aliases**: Stable pointers to versions (`dev`, `prod`) → blue/green.
* **Layers**: Share libs across functions; keep function package lean.
* **Extensions**: Observability/partner agents that run alongside.

</details>

---

<details>
<summary><strong>11. Hands-On Workflow (Console + CLI)</strong></summary>

**A) Minimal Python example (zip)**

`app.py`

```python
import json
def handler(event, context):
    return {"statusCode": 200, "body": json.dumps({"ok": True})}
```

Zip & create:

```bash
zip function.zip app.py
aws lambda create-function \
  --function-name hello-lambda \
  --runtime python3.11 \
  --handler app.handler \
  --zip-file fileb://function.zip \
  --role arn:aws:iam::<ACCOUNT_ID>:role/lambda-exec-role
```

Invoke test:

```bash
aws lambda invoke --function-name hello-lambda out.json
cat out.json
```

**B) Add an EventBridge (CloudWatch Events) schedule**

```bash
aws events put-rule --name nightly-job --schedule-expression "rate(1 day)"
aws lambda add-permission \
  --function-name hello-lambda \
  --statement-id ev-perm \
  --action lambda:InvokeFunction \
  --principal events.amazonaws.com \
  --source-arn arn:aws:events:us-east-1:<ACCOUNT_ID>:rule/nightly-job
aws events put-targets \
  --rule nightly-job \
  --targets "Id"="1","Arn"="$(aws lambda get-function --function-name hello-lambda --query 'Configuration.FunctionArn' --output text)"
```

**C) Wire to S3 (object-created)** — console: S3 → Properties → Event notifications → Add → Destination = Lambda.

</details>

---

<details>
<summary><strong>12. IaC Snapshot (CloudFormation YAML)</strong></summary>

```yaml
Resources:
  LambdaExecRole:
    Type: AWS::IAM::Role
    Properties:
      AssumeRolePolicyDocument:
        Version: "2012-10-17"
        Statement:
          - Effect: Allow
            Principal: { Service: lambda.amazonaws.com }
            Action: sts:AssumeRole
      Policies:
        - PolicyName: cw-logs
          PolicyDocument:
            Version: "2012-10-17"
            Statement:
              - Effect: Allow
                Action:
                  - logs:CreateLogGroup
                  - logs:CreateLogStream
                  - logs:PutLogEvents
                Resource: "*"

  HelloLambda:
    Type: AWS::Lambda::Function
    Properties:
      FunctionName: hello-lambda
      Handler: app.handler
      Runtime: python3.11
      Role: !GetAtt LambdaExecRole.Arn
      Code:
        ZipFile: |
          import json
          def handler(event, context):
              return {"statusCode": 200, "body": json.dumps({"ok": True})}

  NightlyRule:
    Type: AWS::Events::Rule
    Properties:
      ScheduleExpression: rate(1 day)
      Targets:
        - Arn: !GetAtt HelloLambda.Arn
          Id: t1

  PermissionForEventsToInvoke:
    Type: AWS::Lambda::Permission
    Properties:
      FunctionName: !Ref HelloLambda
      Action: lambda:InvokeFunction
      Principal: events.amazonaws.com
      SourceArn: !GetAtt NightlyRule.Arn
```

</details>

---

<details>
<summary><strong>13. Architectures & Diagrams</strong></summary>

**A) S3 Thumbnail Pipeline**

```
S3 (upload) ──event──► Lambda (resize) ──► S3 /thumbnails
                            │
                            └─ logs ► CloudWatch Logs
```

**B) Serverless API Backend**

```
Client ► API Gateway (REST/HTTP) ► Lambda ► DynamoDB
                  │
                  └─ logs/metrics ► CloudWatch
```

**C) Scheduled Ops Task**

```
EventBridge (rate/cron) ► Lambda ► (EC2/RDS/Cost Explorer APIs)
```

**D) Async Worker with DLQ**

```
Producer ► SQS Queue ► Lambda (process)
                      ├─ on-failure ► SQS DLQ
                      └─ metrics/logs ► CloudWatch
```

**E) VPC-Attached Lambda**

```
Lambda (ENI in Private Subnet) ► RDS
      │
      └─ NAT Gateway ► Internet (patching, APIs)
```

</details>

---

<details>
<summary><strong>14. Best Practices (Prod-Ready)</strong></summary>

* **Keep it stateless**; reuse SDK clients outside the handler.
* **Least-privilege IAM** per function; separate roles.
* **Timeouts** aligned with upstreams; fail fast + idempotency keys.
* **Retries & DLQ/Destinations** for async invocations.
* **Instrument** with structured logs + metrics; enable **Lambda Insights**.
* **Control concurrency** (Reserved) for backends with limits; consider **Provisioned** for low-latency APIs.
* **Small packages** (or **Layers**) to reduce cold starts.
* **VPC only when needed**; ensure NAT for egress; watch ENI limits.
* **Use Aliases** for safe deploys (blue/green, canary).
* **Test locally** (SAM/LocalStack) and deploy IaC (SAM/CDK/CFN/Terraform).

</details>

---

<details>
<summary><strong>15. Pricing & Cost Controls</strong></summary>

* **Charges:** Requests + GB-seconds (memory × duration) + optional provisioned concurrency + networking.
* **Cut cost:** Right-size memory, trim duration, batch work via SQS, aggregate metrics, avoid unnecessary VPC (ENI init time + potential egress).
* **Monitor:** `Duration`, `BilledDuration`, `Invocations`, `Errors`, `Throttles`, `IteratorAge`.

</details>

---

<details>
<summary><strong>16. Quick Summary</strong></summary>

* Lambda = **event-driven, fully-managed compute**.
* Triggers from **API Gateway, S3, SQS, EventBridge, DynamoDB Streams, SNS**.
* **Stateless**, scales automatically; watch **concurrency** and **cold starts**.
* **CloudWatch** for logs/metrics; **DLQ/Destinations** for robustness.
* **IaC** everything; deploy with **versions/aliases**; keep costs in check.

</details>

---

<details>
<summary><strong>17. Self-Audit Checklist</strong></summary>

* [ ] I can explain Lambda’s execution lifecycle and cold starts.
* [ ] I can choose the right trigger (API vs S3 vs SQS vs EventBridge).
* [ ] I configured IAM **execution role** with least privilege.
* [ ] I know when to use **Reserved** vs **Provisioned** concurrency.
* [ ] I can route async failures to **DLQ/Destinations**.
* [ ] I can deploy via **CloudFormation/SAM/CDK** with **versions** and **aliases**.
* [ ] I understand the **VPC trade-offs** and NAT requirement.
* [ ] I can estimate Lambda **cost** and reduce it.

</details>

Perfect — below is your **ready-to-paste Markdown block** containing **both gold-standard tables** (🏡 Compute Models Analogy + 💰 Cost Comparison) and a **simple ASCII cost-curve diagram** that fits beautifully into your `Lambda.md`.
You can drop it right under your “Quick Summary” section or wherever you introduce cross-compute comparisons.

---

## 🏡 Compute Models Analogy – EC2 vs Beanstalk vs Lambda

> **All three run your code — they just differ in how much of the “house” you manage.**

| Model | Analogy | Responsibility | Ideal For |
|:--|:--|:--|:--|
| **EC2** | 🏠 **Your Own House** — you buy the land, build the structure, choose every detail, and maintain it yourself. | You manage **everything**: operating system, security updates, scaling, backups, patching. | When you need full control: custom environments, legacy apps, or workloads that run 24/7. |
| **Elastic Beanstalk** | 🏢 **Serviced Apartment** — the building, power, and maintenance are handled; you furnish the rooms and live comfortably. | AWS manages servers, load balancers, scaling, and health checks. You manage your **application code and configs**. | Standard web or API apps that need scalability without infra headaches. |
| **Lambda** | 🏨 **Hotel Room on Demand** — you arrive, use it briefly, and leave. You pay only for the nights you stay. | AWS manages **everything** — servers, scaling, runtime, and cleanup. You only bring the code. | Event-driven, short-lived, stateless workloads (file processing, automation, microservices). |

---

### 🧭 One-Line Rule of Thumb

| Question | Choose |
|-----------|---------|
| “Do I need full OS control?” → | **EC2** |
| “Do I just want AWS to host my web app?” → | **Elastic Beanstalk** |
| “Do I only need code to run on events?” → | **Lambda** |

---

### ⚙️ Architectural Insight
All three live on the same AWS compute backbone:

```

EC2  →  Base Infrastructure Layer (IaaS)
│
├─ Elastic Beanstalk → Managed PaaS using EC2, ALB, Auto Scaling under the hood
│
└─ Lambda → Fully Serverless FaaS running on abstracted EC2 fleets

```

> The higher you go, the **less infrastructure you manage** and the **faster you can deliver** — but the **less customization** you have.

---

## 💰 Cost Comparison – EC2 vs Beanstalk vs Lambda  

> **All three can run the same app — but the way AWS bills you changes drastically.**

| Aspect | **EC2 (IaaS)** | **Elastic Beanstalk (PaaS)** | **Lambda (FaaS)** |
|:--|:--|:--|:--|
| **Billing Unit** | **Uptime (hours/seconds)** of running instances. | Same as EC2 + extra resources (ALB, EBS, RDS if attached). | **Per request + execution time (GB-seconds)**. |
| **Idle Cost** | Charged even when idle. | Charged while environment runs (EC2s always on). | $0 when idle – no invocations = no cost. |
| **Startup Overhead** | Instance launch time billed immediately. | Small Beanstalk setup + EC2 runtime. | None – only execution time (100 ms blocks). |
| **Included Resources** | EC2 CPU, RAM, EBS, data transfer. | EC2 instances, ALB, Auto Scaling, EBS. | Memory (128 MB–10 GB), vCPU proportionally, + invocation count. |
| **Scaling Behavior** | Pay for each instance 24×7. | Pay for the EC2 fleet Beanstalk creates. | Pay only for executions – auto-scales instantly. |
| **Free Tier** | 750 hrs t2.micro (12 mo). | Uses EC2 Free Tier if within limits. | 1 M requests + 400 k GB-seconds (always free). |
| **Cost Predictability** | Stable for steady load. | Medium – depends on autoscaling. | Variable – depends on events + duration. |
| **Optimization Levers** | Right-size, Spot, Savings Plans. | Same + turn off idle envs. | Optimize memory/duration, batch events, limit provisioned concurrency. |
| **Example Monthly Cost** | 2 × t3.medium 24×7 ≈ $60–70 | EC2 + ALB ≈ $80+ | 2 M invocations (256 MB, 200 ms) ≈ <$1 |

---

### 🧮 How AWS Bills in Practice
1. **EC2 / Beanstalk = time-based** → pay for infrastructure uptime.  
2. **Lambda = usage-based** → pay only for execution time + requests.  
3. **Crossover Point** → if code runs continuously, EC2 is cheaper; if sporadic, Lambda wins.

---

### 📉 Cost Curve – Abstraction vs Idle Cost vs Request Cost

```

Cost ↑
│        EC2 ────── fixed monthly cost (always on)
│           
│            
│             \       Elastic Beanstalk (auto-scale but still EC2-based)
│              
│               
│                __________ Lambda (pay-per-request only)
│
└──────────────────────────────────────────────► Usage / Requests

```

> The higher the abstraction, the **lower your idle cost** and the **higher your per-use precision** —  
> AWS shifts the billing model from *infrastructure ownership* → *platform usage* → *function execution*.
```