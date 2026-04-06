<p align="center">
  <img src="../../assets/terraform-banner.svg" alt="terraform" width="100%"/>
</p>

[← devops-runbook](../../README.md)

---

Infrastructure as code — define, version, and manage cloud resources across any provider with a single consistent workflow.

---

## Prerequisites

**Complete first:** [06. AWS – Cloud Infrastructure](../06.%20AWS%20–%20Cloud%20Infrastructure/README.md)

Terraform manages cloud resources. You need to understand what those resources are — VPCs, EC2 instances, S3 buckets, IAM roles — before writing code to automate them. Terraform without AWS knowledge means writing code you don't understand.

---

## The Running Example

Every topic uses the same webstore infrastructure as the practical example — building the VPC, EC2 instances, RDS, load balancer, and all supporting resources as Terraform code.

---

## Topics

| # | File | What You Learn |
|---|---|---|
| 01 | [Foundations & Installation](./01-terraform-foundations/README.md) | What Terraform is, declarative vs imperative, IaC philosophy, installation |
| 02 | [Terraform State & Core Engine](./02-terraform-state/README.md) | How state works, `terraform plan`, `apply`, `destroy`, the state file |
| 03 | [Providers, Resources & Data Sources](./03-providers-resources/README.md) | AWS provider, resource blocks, data sources, HCL syntax |
| 04 | [Variables, Outputs & Locals](./04-variables-outputs/README.md) | Input variables, output values, local values, variable types |
| 05 | [Loops & Conditionals](./05-loops-conditionals/README.md) | `count`, `for_each`, `dynamic` blocks, conditional expressions |
| 06 | [Modules](./06-modules/README.md) | Root module, child modules, registry modules, reusability |
| 07 | [Workspaces & Environments](./07-workspaces/README.md) | Dev, staging, production environments, workspace management |
| 08 | [Remote State & Backends](./08-remote-state/README.md) | S3 backend, DynamoDB state locking, team collaboration |
| 09 | [Advanced Patterns & Lifecycle](./09-advanced-patterns/README.md) | `lifecycle` rules, `depends_on`, `ignore_changes`, `create_before_destroy` |
| 10 | [Security, Validation & Best Practices](./10-security-best-practices/README.md) | Sensitive variables, validation rules, `tfsec`, production patterns |
| 11 | [Real-World Projects](./11-real-world-projects/README.md) | Full webstore infrastructure from scratch in Terraform |

---

## Labs

| Status | Coverage |
|---|---|
| 🚧 Planned | Labs to be built after notes are complete |

---

## How to Use This

Read topics in order — each one builds directly on the previous.  
Do not skip state (file 02) — everything Terraform does depends on understanding the state file.  
Do not skip modules (file 06) — production Terraform without modules is unmaintainable.

---

## What You Can Do After This

- Write Terraform code to provision any AWS resource
- Manage state correctly across a team using remote backends
- Structure code with modules for reuse across environments
- Use variables to manage dev, staging, and production from one codebase
- Import existing infrastructure into Terraform state
- Safely plan and apply changes with zero-downtime patterns
- Apply security best practices and validation to your code

---

## What Comes Next

→ [08. Bash – Shell Scripting Essentials](../08.%20Bash%20–%20Shell%20Scripting%20Essentials/README.md)

Terraform handles infrastructure. Bash handles everything in between — deployment scripts, cron jobs, log processing, and the glue that connects tools together in CI/CD pipelines.
