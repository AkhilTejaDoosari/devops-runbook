<p align="center">
  <img src="../../assets/aws-banner.svg" alt="aws" width="100%"/>
</p>

[← devops-runbook](../../README.md)

---

Cloud infrastructure — taking the webstore from a local Kubernetes cluster to production on AWS.

---

## Why AWS — and Why Not GCP or Azure

AWS has roughly 32% of the global cloud market. More DevOps job postings reference AWS than any other cloud provider. EKS, RDS, EC2, and IAM appear in job descriptions as assumed knowledge. Learning AWS first is not a preference — it is the highest-return choice for a DevOps career path.

GCP is excellent for data and machine learning workloads and is growing, but its DevOps job market is a fraction of AWS. Azure dominates in Microsoft enterprise environments, but those shops tend to hire Windows and .NET experience alongside the cloud skills. Neither is wrong — but AWS is where the entry-level DevOps interviews happen.

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
| Load balancer | NodePort | Application Load Balancer |
| Monitoring | kube-prometheus-stack | CloudWatch + managed Prometheus |

---

## Where You Take the Webstore

You arrive at AWS with the webstore running on a local cluster, deployed by ArgoCD, monitored by Prometheus and Grafana. Everything works — on your laptop.

You leave with the webstore running on EKS in AWS, with the database on RDS PostgreSQL, a load balancer in front, images stored in ECR, and CloudWatch collecting logs and metrics. The same manifests you wrote for Minikube deploy to EKS. The infrastructure is reproducible, scalable, and production-grade.

---

## Phases

| # | Phase | Topics | Lab |
|---|---|---|---|
| 01 | [Intro to AWS](./01-intro-aws/README.md) | Why cloud, AWS global infrastructure, regions and availability zones, free tier | No lab |
| 02 | [IAM](./02-iam/README.md) | Users, groups, roles, policies, least privilege, MFA, the root account rule | [Lab 01](./aws-labs/01-iam-lab.md) |
| 03 | [VPC & Subnets](./03-vpc-subnet/README.md) | VPC, public and private subnets, route tables, internet gateway, NAT gateway | [Lab 02](./aws-labs/02-vpc-lab.md) |
| 04 | [EBS](./04-ebs/README.md) | Block storage, volumes, snapshots, attaching to EC2 | [Lab 03](./aws-labs/03-compute-storage-lab.md) |
| 05 | [EFS](./05-efs/README.md) | Shared file storage, mount targets, use cases vs EBS | [Lab 03](./aws-labs/03-compute-storage-lab.md) |
| 06 | [S3](./06-s3/README.md) | Object storage, buckets, policies, versioning, static site hosting | [Lab 03](./aws-labs/03-compute-storage-lab.md) |
| 07 | [EC2](./07-ec2/README.md) | Instance types, AMIs, key pairs, security groups, user data, lifecycle | [Lab 04](./aws-labs/04-ec2-lab.md) |
| 08 | [RDS](./08-rds/README.md) | Managed databases, PostgreSQL on RDS, multi-AZ, snapshots, migrating from postgres container | [Lab 05](./aws-labs/05-rds-lab.md) |
| 09 | [Load Balancing & Auto Scaling](./09-Load-balancing-auto-scaling/README.md) | ALB, target groups, health checks, Auto Scaling Groups, launch templates | [Lab 06](./aws-labs/06-alb-asg-lab.md) |
| 10 | [CloudWatch & SNS](./10-cloudwatch-sns/README.md) | Metrics, logs, dashboards, alarms, SNS notifications | [Lab 07](./aws-labs/07-cloudwatch-lab.md) |
| 11 | [Lambda](./11-lambda/README.md) | Serverless functions, triggers, execution role, use cases in DevOps pipelines | [Lab 08](./aws-labs/08-lambda-lab.md) |
| 12 | [Elastic Beanstalk](./12-elastic-beanstalk/README.md) | Platform as a Service, deploy without managing infrastructure, when to use it | No lab |
| 13 | [Route 53](./13-route53/README.md) | DNS, hosted zones, record types, routing policies, domain registration | [Lab 09](./aws-labs/09-route53-lab.md) |
| 14 | [CLI & CloudFormation](./14-cli-cloudformation/README.md) | AWS CLI setup, key commands, CloudFormation basics, why Terraform replaces it | [Lab 10](./aws-labs/10-cli-lab.md) |

---

## Labs

| Lab | Topics Covered | What You Practice |
|---|---|---|
| [Lab 01](./aws-labs/01-iam-lab.md) | IAM | Create IAM user, group, and policy — never use root for daily work |
| [Lab 02](./aws-labs/02-vpc-lab.md) | VPC & Subnets | Build the webstore VPC — public subnet for api, private subnet for database |
| [Lab 03](./aws-labs/03-compute-storage-lab.md) | EBS, EFS, S3 | Create and attach a volume, mount EFS, create an S3 bucket for webstore assets |
| [Lab 04](./aws-labs/04-ec2-lab.md) | EC2 | Launch a webstore-api server, SSH in, install nginx, manage lifecycle |
| [Lab 05](./aws-labs/05-rds-lab.md) | RDS | Create RDS PostgreSQL, connect from EC2, migrate webstore-db data |
| [Lab 06](./aws-labs/06-alb-asg-lab.md) | ALB & Auto Scaling | Put webstore-frontend behind an ALB, create an ASG for the api tier |
| [Lab 07](./aws-labs/07-cloudwatch-lab.md) | CloudWatch | Create a dashboard, set an alarm, send an SNS notification on breach |
| [Lab 08](./aws-labs/08-lambda-lab.md) | Lambda | Write a Lambda function triggered by an S3 upload, test and monitor it |
| [Lab 09](./aws-labs/09-route53-lab.md) | Route 53 | Register a hosted zone, create an A record pointing to the ALB |
| [Lab 10](./aws-labs/10-cli-lab.md) | AWS CLI | Configure CLI, run key commands for EC2, S3, and IAM from the terminal |

---

## What You Can Do After This

- Navigate the AWS console and CLI confidently
- Set up IAM with least-privilege access and MFA
- Design a multi-tier VPC with public and private subnets
- Launch EC2 instances, attach storage, and manage lifecycle
- Run a managed PostgreSQL database on RDS
- Put applications behind an Application Load Balancer
- Monitor infrastructure with CloudWatch alarms and dashboards
- Use S3 for static assets and object storage
- Set up Route 53 DNS for a real domain

---

## How to Use This

Read phases in order. Each one builds on the previous.
After each phase do the lab before moving on.
The checklist at the end of every lab is not optional.

---

## What Comes Next

→ [09. Terraform – IaC Foundations](../09.%20Terraform%20–%20IaC%20Foundations/README.md)

You just built AWS infrastructure manually — clicking in the console and running CLI commands. Terraform lets you define all of that as code. The same VPC, EKS cluster, RDS instance, and IAM roles become a set of `.tf` files that can be version controlled, reviewed in a PR, and applied in one command.
