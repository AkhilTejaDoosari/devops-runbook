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

# EKS — Elastic Kubernetes Service

## What This File Is About

The webstore has been running on Minikube for all the Kubernetes labs. Minikube is a single-node cluster on your laptop — it is not production. EKS (Elastic Kubernetes Service) is the managed Kubernetes service that runs the same manifests you wrote for Minikube on real AWS infrastructure, inside the VPC you designed, backed by RDS instead of a postgres container, images pulled from ECR instead of Docker Hub.

---

## Table of Contents

1. [What Is EKS](#1-what-is-eks)
2. [Key EKS Components](#2-key-eks-components)
3. [How EKS Fits the Webstore Architecture](#3-how-eks-fits-the-webstore-architecture)
4. [eksctl — Create the Cluster](#4-eksctl--create-the-cluster)
5. [ECR — Push the Webstore Image](#5-ecr--push-the-webstore-image)
6. [Deploy the Webstore to EKS](#6-deploy-the-webstore-to-eks)
7. [AWS Load Balancer Controller](#7-aws-load-balancer-controller)
8. [EBS CSI Driver](#8-ebs-csi-driver)
9. [IAM Roles for Service Accounts (IRSA)](#9-iam-roles-for-service-accounts-irsa)
10. [Horizontal Pod Autoscaler on EKS](#10-horizontal-pod-autoscaler-on-eks)
11. [Cleaning Up](#11-cleaning-up)

---

## 1. What Is EKS

EKS is a **managed Kubernetes control plane**. AWS runs the API server, etcd, controller manager, and scheduler across multiple AZs — the components you inspected in the K8s architecture lab. You do not provision, patch, or operate these components. You interact with the cluster through `kubectl` exactly as you did with Minikube.

You are responsible for the **worker nodes** — the EC2 instances that run your pods. EKS provides managed node groups that automate the lifecycle of these nodes: provisioning, OS patching, Kubernetes version updates, and Auto Scaling integration.

The same Kubernetes manifests you wrote for the webstore on Minikube deploy identically to EKS. The cluster looks the same to `kubectl`. The pods behave the same. The difference is that the infrastructure underneath is AWS-managed, multi-AZ, and production-grade.

---

## 2. Key EKS Components

**Managed Node Groups** — AWS manages the EC2 instances that serve as worker nodes. You choose the instance type, the desired count, and the scaling limits. AWS handles the node AMI, OS patching, and Kubernetes version upgrades. Nodes run in your private subnets inside your VPC.

**ECR (Elastic Container Registry)** — the private container registry that holds your webstore-api image. In Minikube you pulled from Docker Hub. In EKS you push to ECR and pull from there. ECR is in the same AWS account — no public registry, no rate limiting, images always available.

**AWS Load Balancer Controller** — a Kubernetes controller that watches for Ingress objects and creates AWS ALBs automatically. When you apply an Ingress manifest for the webstore, the controller creates an ALB, configures the listeners and target groups, and wires the health checks. You manage the Ingress manifest. AWS manages the ALB.

**EBS CSI Driver** — the Container Storage Interface (CSI) driver for EBS. When you create a PersistentVolumeClaim with the `ebs-sc` StorageClass, the EBS CSI driver provisions a real EBS volume and attaches it to the correct node automatically.

**IRSA (IAM Roles for Service Accounts)** — lets Kubernetes pods assume IAM roles. Instead of putting IAM credentials in a Secret, you annotate a Kubernetes ServiceAccount with an IAM role ARN. Pods using that ServiceAccount automatically get temporary credentials for that role. The webstore-api ServiceAccount gets the role that allows S3 reads and ECR pulls.

**OIDC Provider** — eksctl enables this automatically. It is what makes IRSA work — the cluster's OIDC (OpenID Connect) identity provider is what allows Kubernetes service accounts to be trusted by AWS IAM.

---

## 3. How EKS Fits the Webstore Architecture

```
┌─────────────────────────────── AWS (us-east-1) ──────────────────────────────────┐
│                                                                                  │
│  EKS Control Plane (AWS managed, across multiple AZs)                            │
│  ├── API Server                                                                  │
│  ├── etcd                                                                        │
│  ├── Scheduler                                                                   │
│  └── Controller Manager                                                          │
│                                                                                  │
│  VPC: 10.0.0.0/16                                                                │
│  ├── Public Subnets (us-east-1a, us-east-1b)                                     │
│  │   └── AWS Load Balancer Controller → ALB for Ingress                          │
│  │                                                                               │
│  └── Private Subnets (us-east-1a, us-east-1b)                                   │
│      ├── EKS Node Group (EC2 worker nodes)                                       │
│      │   ├── webstore-frontend pods                                              │
│      │   ├── webstore-api pods                                                   │
│      │   └── System pods (CoreDNS, kube-proxy, aws-node)                        │
│      │                                                                           │
│      └── RDS PostgreSQL (replaces webstore-db pod + PVC)                        │
│                                                                                  │
│  ECR: webstore-api container images                                              │
└──────────────────────────────────────────────────────────────────────────────────┘
```

---

## 4. eksctl — Create the Cluster

`eksctl` is the official CLI for creating and managing EKS clusters.

**Install:**

```bash
brew tap weaveworks/tap
brew install weaveworks/tap/eksctl
```

**Create a cluster:**

```bash
eksctl create cluster \
  --name webstore \
  --region us-east-1 \
  --version 1.29 \
  --nodegroup-name webstore-nodes \
  --node-type t3.medium \
  --nodes 2 \
  --nodes-min 2 \
  --nodes-max 6 \
  --managed \
  --vpc-private-subnets subnet-1a,subnet-1b \
  --vpc-public-subnets subnet-pub-1a,subnet-pub-1b \
  --with-oidc \
  --ssh-access \
  --ssh-public-key webstore-key
```

This takes 15–20 minutes. eksctl creates the EKS control plane, the managed node group, the necessary IAM roles, and updates your kubeconfig so `kubectl` connects to the new cluster.

**Verify:**

```bash
kubectl get nodes
kubectl get pods -A
```

---

## 5. ECR — Push the Webstore Image

```bash
# Create the ECR repository
aws ecr create-repository \
  --repository-name webstore-api \
  --region us-east-1

# Authenticate Docker to ECR
aws ecr get-login-password --region us-east-1 \
  | docker login \
    --username AWS \
    --password-stdin 123456789012.dkr.ecr.us-east-1.amazonaws.com

# Build and tag the image
docker build -t webstore-api:v1.0 .
docker tag webstore-api:v1.0 \
  123456789012.dkr.ecr.us-east-1.amazonaws.com/webstore-api:v1.0

# Push to ECR
docker push 123456789012.dkr.ecr.us-east-1.amazonaws.com/webstore-api:v1.0
```

---

## 6. Deploy the Webstore to EKS

The manifests you wrote for Minikube need two changes for EKS:

1. The webstore-api Deployment image tag changes from the placeholder to the ECR image URL.
2. The webstore-db is removed from Kubernetes — it is now RDS. The `DATABASE_URL` Secret is updated to point to the RDS endpoint.

Everything else — Deployments, Services, ConfigMaps, Secrets, HPA — works identically.

```bash
# Update kubeconfig to point to the EKS cluster
aws eks update-kubeconfig \
  --region us-east-1 \
  --name webstore

# Verify connection
kubectl cluster-info
kubectl get nodes

# Apply all webstore manifests
kubectl apply -f k8s/

# Watch rollout
kubectl rollout status deployment/webstore-api -n webstore
kubectl rollout status deployment/webstore-frontend -n webstore

# Verify pods
kubectl get pods -n webstore
```

---

## 7. AWS Load Balancer Controller

The ALB controller watches for Ingress objects and creates real AWS ALBs. Install via Helm after the cluster is running.

```bash
# Create IAM policy for the controller
aws iam create-policy \
  --policy-name AWSLoadBalancerControllerIAMPolicy \
  --policy-document file://iam-policy.json

# Create IAM service account
eksctl create iamserviceaccount \
  --cluster webstore \
  --namespace kube-system \
  --name aws-load-balancer-controller \
  --attach-policy-arn arn:aws:iam::123456789012:policy/AWSLoadBalancerControllerIAMPolicy \
  --approve

# Install via Helm
helm repo add eks https://aws.github.io/eks-charts
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=webstore \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller
```

**Webstore Ingress manifest:**

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: webstore-ingress
  namespace: webstore
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
spec:
  rules:
  - host: webstore.com
    http:
      paths:
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: webstore-api
            port:
              number: 8080
      - path: /
        pathType: Prefix
        backend:
          service:
            name: webstore-frontend
            port:
              number: 80
```

---

## 8. EBS CSI Driver

```bash
eksctl create iamserviceaccount \
  --cluster webstore \
  --namespace kube-system \
  --name ebs-csi-controller-sa \
  --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
  --approve

eksctl create addon \
  --cluster webstore \
  --name aws-ebs-csi-driver \
  --service-account-role-arn arn:aws:iam::123456789012:role/AmazonEKS_EBS_CSI_DriverRole
```

After installing, PVCs with `storageClassName: ebs-sc` automatically provision real EBS volumes.

---

## 9. IAM Roles for Service Accounts (IRSA)

The webstore-api pods need to access S3 and ECR without hardcoded credentials. IRSA is the solution.

```bash
# Create the IAM role and service account in one command
eksctl create iamserviceaccount \
  --cluster webstore \
  --namespace webstore \
  --name webstore-api-sa \
  --attach-policy-arn arn:aws:iam::123456789012:policy/WebstoreAPIPolicy \
  --approve
```

Update the webstore-api Deployment to use this ServiceAccount:

```yaml
spec:
  template:
    spec:
      serviceAccountName: webstore-api-sa
      containers:
      - name: webstore-api
        image: 123456789012.dkr.ecr.us-east-1.amazonaws.com/webstore-api:v1.0
```

The pods now get temporary IAM credentials automatically. No secrets, no credential rotation to manage.

---

## 10. Horizontal Pod Autoscaler on EKS

HPA works the same on EKS as on Minikube. Install the Metrics Server first:

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

Then apply the HPA for webstore-api:

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: webstore-api-hpa
  namespace: webstore
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: webstore-api
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 60
```

---

## 11. Cleaning Up

EKS clusters cost money when running. Delete the cluster when you are done with labs.

```bash
# Delete all Kubernetes resources first
kubectl delete namespace webstore

# Delete the cluster and all node groups
eksctl delete cluster --name webstore --region us-east-1
```

---

## What You Can Do After This

- Create an EKS cluster with eksctl and connect kubectl to it
- Push a container image to ECR and deploy it to EKS
- Install the AWS Load Balancer Controller and create an Ingress that provisions an ALB
- Install the EBS CSI Driver and provision PersistentVolumeClaims backed by EBS
- Configure IRSA so pods assume IAM roles without credentials in Secrets
- Deploy the full webstore stack to a production EKS cluster

---

## What Comes Next

→ [09. Terraform — IaC Foundations](../../09.%20Terraform%20–%20IaC%20Foundations/README.md)

All the infrastructure you have built manually across these AWS labs — VPC, EKS, RDS, ALB, IAM roles, Route 53 — becomes Terraform code. One `terraform apply` recreates everything from a blank AWS account.
