[Home](../README.md) | 
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

# 🛰️ AWS CloudWatch & SNS — “The Eyes and Bell of AWS”

> **CloudWatch observes. SNS alerts.**
> Together, they form the heartbeat and voice of your AWS ecosystem — detecting change and announcing it instantly.
> **Phase 5 – Automation & Monitoring**

---

## Table of Contents

1. [Why We Need Observability](#1-why-we-need-observability)
2. [What Is CloudWatch](#2-what-is-cloudwatch)
3. [What Is SNS](#3-what-is-sns)
4. [Core Concepts](#4-core-concepts)
5. [Architecture Diagram](#5-architecture-diagram)
6. [Hands-On Workflow](#6-hands-on-workflow)
7. [Best Practices & Use Cases](#7-best-practices--use-cases)
8. [Beyond Alerts – Automation & IaC](#8-beyond-alerts--automation--iac)
9. [Cost & Optimization Tips](#9-cost--optimization-tips)
10. [Quick Summary](#10-quick-summary)
11. [Self-Audit Checklist](#11-self-audit-checklist)

---

<details>
<summary><strong>1. Why We Need Observability</strong></summary>

As infrastructure grows, manual health checks don’t scale.
We need **real-time telemetry** — metrics, logs, events — that expose what’s happening under the hood.

Without observability:

* Outages go undetected until users report them.
* Bottlenecks stay hidden.
* MTTR (mean time to repair) skyrockets.

**CloudWatch + SNS** close the loop:

> Measure → Detect → Alert → Respond → Recover.

</details>

---

<details>
<summary><strong>2. What Is CloudWatch</strong></summary>

Amazon CloudWatch provides a **central nervous system** for AWS environments.

It collects and visualizes:

* **Metrics:** quantitative measures (CPU, Memory, I/O).
* **Logs:** textual data from applications & services.
* **Events:** resource state changes (e.g., EC2 stopped).
* **Alarms:** logic that evaluates metrics and triggers actions.

Advanced features:

* **Metric Math:** combine or compute metrics (e.g., `CPUUtilization / NumberOfCores`).
* **Anomaly Detection:** ML-based deviation banding.
* **Composite Alarms:** aggregate multiple alarms → one decision point.
* **Dashboards:** unified visibility across accounts and regions.

Reference: [AWS Docs – CloudWatch](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/WhatIsCloudWatch.html)

</details>

---

<details>
<summary><strong>3. What Is SNS</strong></summary>

Amazon Simple Notification Service (SNS) is a **fully-managed pub/sub messaging service**.
It decouples **publishers (alarms)** from **subscribers (email, Lambda, SQS, HTTP)**.

```
CloudWatch Alarm ──► SNS Topic ──► Subscribers (Email / SMS / Lambda)
```

Features:

* **Fan-out delivery** to multiple endpoints.
* **Durability** and delivery retries.
* **Message filtering** per subscription.
* **Cross-account topics** for centralized alerting.

Reference: [AWS Docs – SNS](https://docs.aws.amazon.com/sns/latest/dg/welcome.html)

</details>

---

<details>
<summary><strong>4. Core Concepts</strong></summary>

| Concept                | CloudWatch Role                              | SNS Role                                |
| ---------------------- | -------------------------------------------- | --------------------------------------- |
| **Metric**             | Numeric data point (e.g., CPU %, Requests)   | —                                       |
| **Log Group / Stream** | Store application or system logs             | —                                       |
| **Alarm**              | Evaluates metric vs threshold → state change | Publishes message to topic              |
| **Dashboard**          | Visualization of metrics                     | —                                       |
| **Event**              | Detects resource changes                     | May publish notifications through SNS   |
| **Topic**              | —                                            | Named channel for messages              |
| **Subscription**       | —                                            | Destination endpoint (Email/SMS/Lambda) |

**Logs vs Metrics vs Events**

| Data Type   | Example Source          | Used For                            |
| ----------- | ----------------------- | ----------------------------------- |
| **Logs**    | App stdout / EC2 syslog | Root-cause analysis                 |
| **Metrics** | CPU %, Memory, Latency  | Trend monitoring & threshold alarms |
| **Events**  | EC2 stop, Lambda invoke | Automation & reactive flows         |

</details>

---

<details>
<summary><strong>5. Architecture Diagram</strong></summary>

```
                   ┌──────────────────────────────┐
                   │         AWS Resources         │
                   │  (EC2, RDS, Lambda, ECS…)   │
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

**Planes of Operation**

```
Metrics Plane   →  Collect & Store  (CloudWatch)
Alarm Plane     →  Evaluate & Trigger
Notification Plane →  Publish & Deliver (SNS)
Automation Plane  →  Remediate (Lambda/Systems Manager)
```

</details>

---

<details>
<summary><strong>6. Hands-On Workflow</strong></summary>

**Step 1 – Create SNS Topic & Subscription**

```bash
aws sns create-topic --name ops-alerts
aws sns subscribe \
  --topic-arn arn:aws:sns:us-east-1:111122223333:ops-alerts \
  --protocol email --notification-endpoint admin@example.com
```

Confirm email subscription.

**Step 2 – Create CloudWatch Alarm**

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

**Step 3 – Trigger Alarm**

```bash
sudo yum install stress -y
sudo stress --cpu 4 --timeout 60
```

→ Alarm state changes to `ALARM` → SNS emails team.

**Step 4 – View Alarm History**
Console → CloudWatch → Alarms → History.

</details>

---

<details>
<summary><strong>7. Best Practices & Use Cases</strong></summary>

### Operational Excellence

* Group metrics per application/environment.
* Apply consistent naming: `<env>-<service>-<metric>-<severity>`.
* Define severity levels → separate SNS topics (`critical`, `warning`, `info`).
* Use **composite alarms** to reduce noise.
* Set **log retention policies**.
* Encrypt SNS topics with KMS.
* Integrate Slack/MS Teams via Lambda webhooks.
* Enable **cross-account dashboards** for central visibility.

### Practical Use Cases

| Category             | Example                                    |
| -------------------- | ------------------------------------------ |
| **Performance**      | Alert when ALB 5xx > 1 %, CPU > 80 %       |
| **Security**         | Root login event → SNS critical topic      |
| **Automation**       | Low disk space → Lambda expands EBS volume |
| **Cost Control**     | Idle instance → SNS → Lambda terminates    |
| **DevOps Pipelines** | CI/CD failure → SNS → Slack channel        |

</details>

---

<details>
<summary><strong>8. Beyond Alerts – Automation & IaC</strong></summary>

### 8.1 Event-Driven Remediation (Example)

```
CloudWatch Alarm → SNS Topic → Lambda → EC2 API (Action)
```

**Scenario:** CPU ≥ 95 % for 5 min → auto-scale EC2.

Lambda code (abstract):

```python
import boto3
def handler(event, context):
  asg = boto3.client('autoscaling')
  asg.set_desired_capacity(AutoScalingGroupName='web-tier', DesiredCapacity=3)
```

SNS publishes → Lambda invoked → Infra self-heals.

### 8.2 Infrastructure-as-Code (CloudFormation Snippet)

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

</details>

---

<details>
<summary><strong>9. Cost & Optimization Tips</strong></summary>

| Area           | Tip                                                              |
| -------------- | ---------------------------------------------------------------- |
| **Metrics**    | Publish aggregated custom metrics instead of per-instance.       |
| **Logs**       | Set retention < 30 days unless required.                         |
| **Dashboards** | Delete unused widgets to cut API calls.                          |
| **Alarms**     | Combine via Composite Alarms to reduce charges.                  |
| **SNS**        | Batch non-urgent notifications or route through SQS to throttle. |

</details>

---

<details>
<summary><strong>10. Quick Summary</strong></summary>

* **CloudWatch = Observer**, **SNS = Messenger**.
* Together → real-time visibility + automated response.
* Use metric math & anomaly detection for smarter alerts.
* Codify monitoring via CloudFormation/Terraform.
* Maintain alert hygiene (severity, naming, noise control).
* Integrate Lambda for self-healing automation.

</details>

---

<details>
<summary><strong>11. Self-Audit Checklist</strong></summary>

* [ ] I can explain how CloudWatch and SNS interact.
* [ ] I can create metrics, alarms, and SNS topics via CLI/IaC.
* [ ] I understand metric math and anomaly detection.
* [ ] I can draw the Event → Metric → Alarm → SNS → Lambda flow.
* [ ] I can implement alert severity and retention policies.
* [ ] I can estimate and optimize CloudWatch costs.
* [ ] I have a cross-account dashboard for visibility.

</details>

---