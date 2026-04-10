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

# AWS CloudWatch & SNS — The Eyes and Bell of AWS

CloudWatch observes. SNS alerts.
Together, they form the heartbeat and voice of your AWS ecosystem — detecting change and announcing it instantly.

---

## Table of Contents

1. [What Is CloudWatch and Why Observability Matters](#1-what-is-cloudwatch-and-why-observability-matters)
2. [What Is SNS — Core Concepts](#2-what-is-sns--core-concepts)
3. [Architecture Diagram](#3-architecture-diagram)
4. [Hands-On Workflow](#4-hands-on-workflow)
5. [Best Practices & Use Cases](#5-best-practices--use-cases)
6. [Beyond Alerts — Automation & IaC](#6-beyond-alerts--automation--iac)
7. [Summary, Cost, and Checklist](#7-summary-cost-and-checklist)

---

## 1. What Is CloudWatch and Why Observability Matters

### Why We Need Observability

As infrastructure grows, manual health checks don't scale.
We need **real-time telemetry** — metrics, logs, events — that expose what's happening under the hood.

Without observability:
- Outages go undetected until users report them.
- Bottlenecks stay hidden.
- MTTR (mean time to repair) skyrockets.

**CloudWatch + SNS** close the loop:

> Measure → Detect → Alert → Respond → Recover.

---

### What Is CloudWatch

Amazon CloudWatch provides a **central nervous system** for AWS environments.

It collects and visualizes:
- **Metrics:** quantitative measures (CPU, Memory, I/O).
- **Logs:** textual data from applications & services.
- **Events:** resource state changes (e.g., EC2 stopped).
- **Alarms:** logic that evaluates metrics and triggers actions.

Advanced features:
- **Metric Math:** combine or compute metrics (e.g., `CPUUtilization / NumberOfCores`).
- **Anomaly Detection:** ML-based deviation banding.
- **Composite Alarms:** aggregate multiple alarms → one decision point.
- **Dashboards:** unified visibility across accounts and regions.

---

## 2. What Is SNS — Core Concepts

### What Is SNS

Amazon Simple Notification Service (SNS) is a **fully-managed pub/sub messaging service**.
It decouples **publishers (alarms)** from **subscribers (email, Lambda, SQS, HTTP)**.

```
CloudWatch Alarm ──► SNS Topic ──► Subscribers (Email / SMS / Lambda)
```

Features:
- **Fan-out delivery** to multiple endpoints.
- **Durability** and delivery retries.
- **Message filtering** per subscription.
- **Cross-account topics** for centralized alerting.

---

### Core Concepts

| Concept | CloudWatch Role | SNS Role |
|---|---|---|
| **Metric** | Numeric data point (e.g., CPU %, Requests) | — |
| **Log Group / Stream** | Store application or system logs | — |
| **Alarm** | Evaluates metric vs threshold → state change | Publishes message to topic |
| **Dashboard** | Visualization of metrics | — |
| **Event** | Detects resource changes | May publish notifications through SNS |
| **Topic** | — | Named channel for messages |
| **Subscription** | — | Destination endpoint (Email/SMS/Lambda) |

**Logs vs Metrics vs Events:**

| Data Type | Example Source | Used For |
|---|---|---|
| **Logs** | App stdout / EC2 syslog | Root-cause analysis |
| **Metrics** | CPU %, Memory, Latency | Trend monitoring & threshold alarms |
| **Events** | EC2 stop, Lambda invoke | Automation & reactive flows |

---

## 3. Architecture Diagram

```
                   ┌──────────────────────────────┐
                   │         AWS Resources         │
                   │  (EC2, RDS, Lambda, ECS…)    │
                   └──────────────┬───────────────┘
                                  │  Metrics / Logs
                                  ▼
                        ┌──────────────────┐
                        │   CloudWatch     │
                        │ Metrics + Logs   │
                        └───────┬──────────┘
                                │ Alarm Trigger
                                ▼
                        ┌──────────────────┐
                        │     SNS Topic    │
                        │   (ops-alerts)   │
                        └───────┬──────────┘
              ┌────────────────┼────────────────┐
              │                │                │
       ┌────────────┐  ┌────────────┐  ┌────────────┐
       │   Email     │  │   SMS      │  │  Lambda    │
       │ Subscriber  │  │ Subscriber │  │ Automation │
       └────────────┘  └────────────┘  └────────────┘
```

**Planes of Operation:**

```
Metrics Plane      →  Collect & Store  (CloudWatch)
Alarm Plane        →  Evaluate & Trigger
Notification Plane →  Publish & Deliver (SNS)
Automation Plane   →  Remediate (Lambda/Systems Manager)
```

---

## 4. Hands-On Workflow

### Webstore Monitoring Setup

These are the core alarms for the webstore on AWS.

**Alarm 1 — webstore-api high CPU:**
```bash
aws cloudwatch put-metric-alarm \
  --alarm-name webstore-api-high-cpu \
  --metric-name CPUUtilization \
  --namespace AWS/EC2 \
  --statistic Average \
  --period 300 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold \
  --dimensions Name=AutoScalingGroupName,Value=webstore-api-asg \
  --evaluation-periods 1 \
  --alarm-actions arn:aws:sns:us-east-1:123456789012:webstore-warning
```

**Alarm 2 — webstore ALB 5XX errors:**
```bash
aws cloudwatch put-metric-alarm \
  --alarm-name webstore-alb-5xx \
  --metric-name HTTPCode_ELB_5XX_Count \
  --namespace AWS/ApplicationELB \
  --statistic Sum \
  --period 60 \
  --threshold 10 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 2 \
  --alarm-actions arn:aws:sns:us-east-1:123456789012:webstore-critical
```

---

**Step 1 – Create SNS Topic & Subscription:**

```bash
aws sns create-topic --name ops-alerts

aws sns subscribe \
  --topic-arn arn:aws:sns:us-east-1:111122223333:ops-alerts \
  --protocol email \
  --notification-endpoint admin@example.com
```

Confirm email subscription.

**Step 2 – Create CloudWatch Alarm:**

```bash
aws cloudwatch put-metric-alarm \
  --alarm-name HighCPU \
  --metric-name CPUUtilization --namespace AWS/EC2 \
  --statistic Average --period 300 --threshold 80 \
  --comparison-operator GreaterThanThreshold \
  --dimensions Name=InstanceId,Value=i-0123456789abcdef \
  --evaluation-periods 1 \
  --alarm-actions arn:aws:sns:us-east-1:111122223333:ops-alerts
```

**Step 3 – Trigger Alarm:**

```bash
sudo yum install stress -y
sudo stress --cpu 4 --timeout 60
```

→ Alarm state changes to `ALARM` → SNS emails team.

**Step 4 – View Alarm History:**
Console → CloudWatch → Alarms → History.

---

## 5. Best Practices & Use Cases

### Operational Excellence

- Group metrics per application/environment.
- Apply consistent naming: `<env>-<service>-<metric>-<severity>`.
- Define severity levels → separate SNS topics (`critical`, `warning`, `info`).
- Use **composite alarms** to reduce noise.
- Set **log retention policies**.
- Encrypt SNS topics with KMS.
- Integrate Slack/MS Teams via Lambda webhooks.
- Enable **cross-account dashboards** for central visibility.

### Practical Use Cases

| Category | Example |
|---|---|
| **Performance** | Alert when ALB 5xx > 1%, CPU > 80% |
| **Security** | Root login event → SNS critical topic |
| **Automation** | Low disk space → Lambda expands EBS volume |
| **Cost Control** | Idle instance → SNS → Lambda terminates |
| **DevOps Pipelines** | CI/CD failure → SNS → Slack channel |

---

## 6. Beyond Alerts — Automation & IaC

### Event-Driven Remediation (Example)

```
CloudWatch Alarm → SNS Topic → Lambda → EC2 API (Action)
```

**Scenario:** CPU ≥ 95% for 5 min → auto-scale EC2.

Lambda code (abstract):

```python
import boto3
def handler(event, context):
  asg = boto3.client('autoscaling')
  asg.set_desired_capacity(AutoScalingGroupName='webstore-api-asg', DesiredCapacity=3)
```

SNS publishes → Lambda invoked → Infra self-heals.

---

### Infrastructure-as-Code (CloudFormation Snippet)

```yaml
Resources:
  OpsAlertsTopic:
    Type: AWS::SNS::Topic
    Properties:
      TopicName: ops-alerts

  HighCPUAlarm:
    Type: AWS::CloudWatch::Alarm
    Properties:
      AlarmDescription: High CPU Utilization
      Namespace: AWS/EC2
      MetricName: CPUUtilization
      Statistic: Average
      Period: 300
      Threshold: 80
      ComparisonOperator: GreaterThanThreshold
      EvaluationPeriods: 1
      AlarmActions:
        - !Ref OpsAlertsTopic
```

Version-control your alerts and topics alongside application code.

---

## 7. Summary, Cost, and Checklist

### Cost & Optimization Tips

| Area | Tip |
|---|---|
| **Metrics** | Publish aggregated custom metrics instead of per-instance. |
| **Logs** | Set retention < 30 days unless required. |
| **Dashboards** | Delete unused widgets to cut API calls. |
| **Alarms** | Combine via Composite Alarms to reduce charges. |
| **SNS** | Batch non-urgent notifications or route through SQS to throttle. |

---

### Quick Summary

- **CloudWatch = Observer**, **SNS = Messenger**.
- Together → real-time visibility + automated response.
- Use metric math & anomaly detection for smarter alerts.
- Codify monitoring via CloudFormation/Terraform.
- Maintain alert hygiene (severity, naming, noise control).
- Integrate Lambda for self-healing automation.

---

### Self-Audit Checklist

- [ ] I can explain how CloudWatch and SNS interact.
- [ ] I can create metrics, alarms, and SNS topics via CLI/IaC.
- [ ] I understand metric math and anomaly detection.
- [ ] I can draw the Event → Metric → Alarm → SNS → Lambda flow.
- [ ] I can implement alert severity and retention policies.
- [ ] I can estimate and optimize CloudWatch costs.
- [ ] I have a cross-account dashboard for visibility.

---

## What You Can Do After This

- Create CloudWatch alarms on the metrics that matter for the webstore
- Create SNS topics and subscribe email addresses and Lambda functions
- Build a CloudWatch dashboard that shows webstore health at a glance
- Write CloudFormation to codify alarms and topics alongside infrastructure
- Design an event-driven remediation flow using CloudWatch → SNS → Lambda

---

## What Comes Next

→ [10. Route 53](../10-route53/README.md)

The webstore is running, load-balanced, and monitored. Route 53 is how users actually reach it — DNS resolves `webstore.com` to the ALB's DNS name.
