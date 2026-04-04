<p align="center">
  <img src="../../assets/bash-banner.svg" alt="bash" width="100%"/>
</p>

[← devops-runbook](../../README.md)

---

Shell scripting, automation, and the glue that connects every DevOps tool together — cron jobs, deployment scripts, log processing, and CI/CD pipelines.

---

## Prerequisites

**Complete first:** [01. Linux – System Fundamentals](../01.%20Linux%20–%20System%20Fundamentals/README.md)

Bash scripting is Linux commands put into files and made repeatable. You need to be comfortable with the Linux command line — file operations, process management, and text processing — before scripting makes sense.

Bash becomes most useful after you have worked with the other tools in this series. It ties everything together — automating Docker builds, running Terraform, processing AWS CLI output, and building deployment pipelines.

---

## The Running Example

Every script in this folder operates on the webstore project — the same app used throughout the entire series. Deployment scripts, backup automation, log analysis, and health checks all target the webstore stack.

---

## Topics

| # | File | What You Learn |
|---|---|---|
| 01 | [Bash Foundations](./01-bash-foundations/README.md) | Shebang, variables, input, conditionals, loops, functions |
| 02 | [Text Processing](./02-text-processing/README.md) | grep, sed, awk in scripts, parsing command output |
| 03 | [Script Structure & Error Handling](./03-script-structure/README.md) | Exit codes, `set -e`, `trap`, logging, defensive scripting |
| 04 | [Automation & Cron](./04-automation-cron/README.md) | crontab, scheduled tasks, log rotation, backup scripts |
| 05 | [DevOps Scripting Patterns](./05-devops-patterns/README.md) | Deployment scripts, health checks, Docker automation, CI/CD hooks |

---

## Labs

| Status | Coverage |
|---|---|
| 🚧 Planned | Labs to be built after notes are complete |

---

## How to Use This

Read topics in order.  
Every script should be written from scratch — not copy-pasted.  
Test every script in a way that produces the failure state before fixing it.

---

## What You Can Do After This

- Write deployment scripts that are safe to run in production
- Automate repetitive tasks with cron and scheduled jobs
- Parse and process log output from any tool
- Build health check scripts for Docker and Kubernetes workloads
- Write CI/CD pipeline scripts that are readable and debuggable
- Handle errors correctly so scripts fail loudly, not silently

---

## This Folder Ties Everything Together

Bash is the last piece. Every tool in this series has a command-line interface. Bash is what connects them:

```
Linux commands → Bash scripts
Git operations → Automated in CI/CD hooks
Docker builds  → Scripted in deployment pipelines
kubectl apply  → Wrapped in deployment scripts
AWS CLI calls  → Automated in maintenance scripts
Terraform runs → Orchestrated in pipeline scripts
```

When you can write a Bash script that builds a Docker image, pushes it to a registry, applies a Kubernetes deployment, and sends a notification if anything fails — you are working like a DevOps engineer.
