<p align="center">
  <img src="../../assets/bash-banner.svg" alt="bash" width="100%"/>
</p>

[← devops-runbook](../../README.md)

---

Shell scripting — the glue that connects every tool in this runbook and automates the operational work that no other tool handles.

---

## Why Bash — and Why Not Python

Bash is pre-installed on every Linux server, every CI runner, every Docker container, and every Kubernetes node. When you SSH into a production server at 2am during an incident, Bash is what you have. No package manager needed, no virtual environment, no import statements — just a file with a shebang line.

Python is more powerful for complex scripting. Better string handling, better data structures, better error messages. Both matter in a DevOps career, and you will use both. Bash comes first because it is always available, because the DevOps tools you have been using throughout this runbook are called from the command line, and because reading and writing Bash is an unavoidable part of working with CI pipelines, Dockerfiles, Kubernetes lifecycle hooks, and Ansible tasks.

The scripts in this tool are not academic exercises. They are the scripts that DevOps engineers actually write — deploy scripts, health checks, database backups, log rotation, environment bootstrapping. The focus is on writing scripts that are readable, debuggable, and safe to run in production.

---

## Prerequisites

**Complete first:** [10. Ansible – Configuration Management](../10.%20Ansible%20–%20Configuration%20Management/README.md)

Bash is the last tool in this runbook because it wraps everything else. You write deployment scripts that call `kubectl`. Health check scripts that call `curl` and `aws`. Backup scripts that call `pg_dump` and `aws s3`. Without knowing what those tools do, the scripts have no context. Come here after completing the full stack.

---

## The Running Example

Every script in this tool automates a real webstore operational task.

| Script | What it does |
|---|---|
| `deploy.sh` | Builds the webstore-api image, pushes to ECR, updates the manifest, triggers ArgoCD sync |
| `healthcheck.sh` | Hits the webstore-api `/health` endpoint, checks pod status, reports pass or fail |
| `backup.sh` | Dumps the webstore-db postgres database, compresses it, uploads to S3 with a timestamp |
| `rotate-logs.sh` | Compresses logs older than 7 days, deletes logs older than 30 days |
| `bootstrap.sh` | Sets up a fresh developer machine — installs tools, configures git, sets up kubeconfig |

---

## Where You Take the Webstore

You arrive at Bash with the entire webstore stack built — Linux, Git, Docker, Kubernetes, CI-CD, Observability, AWS, Terraform, Ansible. Each piece is solid but each piece is separate. Manual steps connect them.

You leave with scripts that automate the connections. The deployment pipeline has a fallback script. The database has a scheduled backup. The logs rotate automatically. A new engineer can run one script to set up their development environment. The operational toil is gone.

---

## The Scripting Mindset

A script should do one thing well and fail loudly when it cannot. The worst scripts are the ones that silently succeed when they actually failed — an empty backup file, a deployment that appeared to finish but was never applied, a health check that always returns green regardless of the application state.

Every script in this tool is written with `set -e` (exit on error), `set -u` (error on unset variables), and explicit error messages. A script that fails clearly is infinitely more useful than one that silently does the wrong thing.

---

## Phases

| # | Phase | Topics | Lab |
|---|---|---|---|
| 01 | [Scripting Mindset](./01-scripting-mindset/README.md) | When to write a script, shebang line, making scripts executable, exit codes, `set -e` and `set -u` | No lab |
| 02 | [Variables & Input](./02-variables-input/README.md) | Variables, positional arguments, `$@`, `read`, environment variables, quoting rules | [Lab 01](./bash-labs/01-variables-conditionals-lab.md) |
| 03 | [Conditionals](./03-conditionals/README.md) | `if/elif/else`, test operators (`-f`, `-z`, `-eq`), `case` statements | [Lab 01](./bash-labs/01-variables-conditionals-lab.md) |
| 04 | [Loops](./04-loops/README.md) | `for`, `while`, `until`, `break`, `continue`, looping over files and command output | [Lab 02](./bash-labs/02-loops-functions-lab.md) |
| 05 | [Functions](./05-functions/README.md) | Declaring functions, calling them, return values, local variables, sourcing files | [Lab 02](./bash-labs/02-loops-functions-lab.md) |
| 06 | [Error Handling](./06-error-handling/README.md) | `set -e`, `set -u`, `set -o pipefail`, `trap`, logging patterns, exit codes | [Lab 03](./bash-labs/03-error-handling-lab.md) |
| 07 | [Real-World Scripts](./07-real-world-scripts/README.md) | Deploy script, health check, postgres backup, log rotation, developer bootstrap | [Lab 04](./bash-labs/04-real-world-lab.md) |

---

## Labs

| Lab | Topics Covered | What You Practice |
|---|---|---|
| [Lab 01](./bash-labs/01-variables-conditionals-lab.md) | Variables, Input, Conditionals | Write a script that reads arguments, validates them, and branches on conditions |
| [Lab 02](./bash-labs/02-loops-functions-lab.md) | Loops, Functions | Write a function library and loop over real files and command output |
| [Lab 03](./bash-labs/03-error-handling-lab.md) | Error Handling | Add `set -euo pipefail` and `trap` to a script, produce real failures and read them |
| [Lab 04](./bash-labs/04-real-world-lab.md) | Real-World Scripts | Write the webstore deploy script, healthcheck, and database backup from scratch |

---

## What You Can Do After This

- Write Bash scripts that are safe to run in production
- Use `set -euo pipefail` and explain what each flag does
- Handle errors explicitly with `trap` and meaningful exit codes
- Write functions that make scripts readable and testable
- Accept and validate command-line arguments
- Write a deploy script, a health check, and a backup script from scratch
- Read any Bash script in a real codebase and understand what it does

---

## How to Use This

Read phases in order. Each one builds on the previous.
After each phase do the lab before moving on.
The checklist at the end of every lab is not optional.

---

## You Have Reached the End

This is the last tool in the runbook. You started with a blank Linux server and a project idea. You end with the webstore running in production on AWS EKS, deployed automatically by a CI-CD pipeline, monitored by Prometheus and Grafana, infrastructure defined in Terraform, servers configured by Ansible, and operational tasks automated by Bash scripts.

The runbook is a foundation. The industry moves fast and the tools evolve. But the fundamentals — how containers work, how networks route packets, how infrastructure is provisioned and configured, how systems are observed and debugged — those do not change. Build on them.
