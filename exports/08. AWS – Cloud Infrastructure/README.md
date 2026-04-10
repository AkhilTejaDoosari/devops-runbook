<p align="center">
  <img src="../../assets/aws-banner.svg" alt="aws" width="100%"/>
</p>

[← devops-runbook](../../README.md)

---

Cloud infrastructure — taking the webstore from a local Kubernetes cluster to production on AWS.

---

## Why AWS — and Why Not GCP or Azure

AWS has roughly 32% of the global cloud market. More DevOps job postings reference AWS than any other provider. EKS, RDS, EC2, and IAM appear in job descriptions as assumed knowledge. Learning AWS first is not a preference — it is the highest-return choice for a DevOps career path.

GCP is excellent for data and machine learning workloads and is growing, but its DevOps job market is a fraction of AWS. Azure dominates in Microsoft enterprise environments. Neither is wrong — but AWS is where the entry-level DevOps interviews happen.

The concepts transfer. VPC is the same mental model as every other cloud network. IAM roles and policies map to GCP service accounts and Azure managed identities. EKS is GKE is AKS. Once you understand how AWS structures its services, reading GCP or Azure documentation is a translation exercise, not a re-education.

---

## Prerequisites

**Complete first:** [07. Observability – Monitoring & Logs](../07.%20Observability%20–%20Monitoring%20%26%20Logs/README.md)

You arrive at AWS knowing how to build, deploy, and observe a containerised application on a local cluster. AWS is where you take that knowledge and apply it to managed, production-grade infrastructure. Without the foundation, the AWS services are just a list of acronyms.

---

## The Running Example

Every file and every lab operates on the same webstore app.

| Service | Local (Minikube) | AWS equivalent |
|---|---|---|
| webstore-frontend | nginx:1.24 pod | EC2 or EKS pod behind ALB |
| webstore-api | nginx:1.24 pod | EKS pod, image from ECR |
| webstore-db | postgres:15 pod + PVC | RDS PostgreSQL |
| Cluster | Minikube | EKS |
| Container registry | Docker Hub | ECR |
| Load balancer | NodePort | Application Load Balancer (ALB) |
| Monitoring | kube-prometheus-stack | CloudWatch |

---

## Where You Take the Webstore

You arrive at AWS with the webstore running on a local cluster, deployed by ArgoCD, monitored by Prometheus and Grafana. Everything works — on your laptop.

You leave with the webstore running on EKS in AWS, database on RDS PostgreSQL, a load balancer in front, images stored in ECR, and CloudWatch collecting logs and metrics. The same manifests you wrote for Minikube deploy to EKS. The infrastructure is reproducible, scalable, and production-grade.

---

## Phases

| # | Phase | Topics | Lab |
|---|---|---|---|
| 01 | [Intro to AWS](./01-intro-aws/README.md) | Why cloud, regions, AZs, IaaS/PaaS/SaaS, free tier | No lab |
| 02 | [IAM](./02-iam/README.md) | Users, groups, roles, policies, MFA, least privilege | [Lab 01](./aws-labs/01-iam-lab.md) |
| 03 | [VPC & Subnets](./03-vpc-subnet/README.md) | VPC, subnets, routing, IGW, NAT, Security Groups, NACLs | [Lab 02](./aws-labs/02-vpc-lab.md) |
| 04 | [EBS](./04-ebs/README.md) | Block storage, volume types, snapshots, encryption, resize | [Lab 03](./aws-labs/03-storage-lab.md) |
| 05 | [S3](./05-s3/README.md) | Object storage, buckets, versioning, lifecycle, security | [Lab 03](./aws-labs/03-storage-lab.md) |
| 06 | [EC2](./06-ec2/README.md) | Instances, AMIs, key pairs, security groups, user data, metadata | [Lab 04](./aws-labs/04-ec2-lab.md) |
| 07 | [RDS](./07-rds/README.md) | Managed PostgreSQL, Multi-AZ, backups, migrate from container | [Lab 05](./aws-labs/05-rds-lab.md) |
| 08 | [Load Balancing & Auto Scaling](./08-load-balancing-auto-scaling/README.md) | ALB, target groups, health checks, ASG, scaling policies | [Lab 06](./aws-labs/06-alb-asg-lab.md) |
| 09 | [CloudWatch & SNS](./09-cloudwatch-sns/README.md) | Metrics, logs, alarms, dashboards, SNS notifications | [Lab 07](./aws-labs/07-cloudwatch-lab.md) |
| 10 | [Route 53](./10-route53/README.md) | DNS, hosted zones, record types, routing policies | [Lab 08](./aws-labs/08-route53-lab.md) |
| 11 | [CLI & CloudFormation](./11-cli-cloudformation/README.md) | AWS CLI setup, daily commands, CloudFormation templates | [Lab 09](./aws-labs/09-cli-lab.md) |
| 12 | [EKS](./12-eks/README.md) | eksctl, ECR, ALB controller, EBS CSI, IRSA, HPA | [Lab 10](./aws-labs/10-eks-lab.md) |

**Extras** → [EFS](./extras/01-efs/README.md) · [Elastic Beanstalk](./extras/02-elastic-beanstalk/README.md) · [Lambda](./extras/03-lambda/README.md) — read when a project needs them.

---

## Labs

| Lab | Topics Covered | What You Practice |
|---|---|---|
| [Lab 01](./aws-labs/01-iam-lab.md) | IAM | Create admin user, DevOps group, attach policies, enable MFA, test least privilege |
| [Lab 02](./aws-labs/02-vpc-lab.md) | VPC & Subnets | Build the webstore VPC — public subnets for ALB, private subnets for API and DB |
| [Lab 03](./aws-labs/03-storage-lab.md) | EBS, S3 | Attach a volume, resize it, create snapshots, create S3 buckets with lifecycle rules |
| [Lab 04](./aws-labs/04-ec2-lab.md) | EC2 | Launch webstore-api server with IAM role, user data bootstrap, security groups |
| [Lab 05](./aws-labs/05-rds-lab.md) | RDS | Create RDS PostgreSQL, dump webstore-db from container, restore to RDS |
| [Lab 06](./aws-labs/06-alb-asg-lab.md) | Load Balancing & Auto Scaling | Create ALB, target group, health checks, ASG with target tracking policy |
| [Lab 07](./aws-labs/07-cloudwatch-lab.md) | CloudWatch & SNS | Create dashboard, set CPU and 5XX alarms, wire to SNS email notification |
| [Lab 08](./aws-labs/08-route53-lab.md) | Route 53 | Create hosted zone, Alias A record pointing webstore.com to ALB |
| [Lab 09](./aws-labs/09-cli-lab.md) | CLI & CloudFormation | Configure CLI, run daily commands, deploy and tear down a CloudFormation stack |
| [Lab 10](./aws-labs/10-eks-lab.md) | EKS | Create EKS cluster, push image to ECR, deploy webstore, configure Ingress and HPA |

---

## What You Can Do After This

- Design and build a production-grade VPC with multi-tier subnets and security groups
- Launch EC2 instances with correct IAM roles, user data, and security groups
- Run a managed PostgreSQL database on RDS with automated backups and Multi-AZ
- Put applications behind an ALB with health checks and Auto Scaling
- Monitor infrastructure with CloudWatch alarms and SNS notifications
- Set up Route 53 DNS for a real domain pointing to an ALB
- Deploy a full Kubernetes workload to EKS and expose it through an ALB Ingress
- Use the AWS CLI to manage infrastructure from the terminal

---

## How to Use This

Read phases in order. Each one builds on the previous.
After each phase do the lab before moving on.
The checklist at the end of every lab is not optional.

---

## What Comes Next

→ [09. Terraform – IaC Foundations](../09.%20Terraform%20–%20IaC%20Foundations/README.md)

You just built AWS infrastructure manually — clicking in the console and running CLI commands. Terraform lets you define all of that as code. The same VPC, EKS cluster, RDS instance, and IAM roles become a set of `.tf` files that can be version controlled, reviewed in a PR, and applied in one command.
