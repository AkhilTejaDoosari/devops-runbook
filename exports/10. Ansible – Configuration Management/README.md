<p align="center">
  <img src="../../assets/ansible-banner.svg" alt="ansible" width="100%"/>
</p>

[← devops-runbook](../../README.md)

---

Configuration management — automating the setup of every server that runs the webstore without touching them manually.

---

## Why Ansible — and Why Not Chef or Puppet

Terraform provisions infrastructure. It does not configure what runs on it. You have an EC2 instance — now what? Something needs to install nginx, write the config file, create the service account, set the correct permissions, and start the process. Without a configuration management tool, that something is you, SSH-ing into each server and running commands by hand.

Ansible automates that. You write a playbook — a YAML file describing the desired state of a server — and Ansible connects over SSH and makes it so. No agent software on the target servers. No daemon to maintain. Just SSH, Python, and YAML.

Chef and Puppet are the predecessors. Both require an agent installed on every managed server, a separate server to coordinate them, and a learning curve that involves Ruby DSLs and certificates. They solve the same problem Ansible solves, but at significantly more operational cost. Ansible is agentless — it needs nothing on the target server except SSH and Python, both of which come preinstalled on every Linux server. SaltStack is also agentless and fast, but its community and job market presence is a fraction of Ansible's.

The other reason Ansible fits this runbook is familiarity. Ansible playbooks are YAML. You have been writing YAML since Kubernetes. The structure is different but the format is the same, and the mental model — describe desired state, let the tool enforce it — is identical.

---

## Prerequisites

**Complete first:** [09. Terraform – IaC Foundations](../09.%20Terraform%20–%20IaC%20Foundations/README.md)

Ansible configures servers that already exist. Terraform is what creates them. You need running EC2 instances with SSH access before Ansible has anything to connect to. The webstore infrastructure from the Terraform real-world project is what the Ansible labs configure.

---

## The Running Example

Every playbook and every lab configures the webstore application servers.

| What gets configured | Ansible handles |
|---|---|
| webstore-frontend server | nginx install, config file, service enabled and started |
| webstore-api server | runtime install, app deploy, env vars, service managed |
| webstore-db server | postgres install, postgres user, database created, config pushed |
| All servers | common packages, security hardening, log rotation, SSH keys |

---

## Where You Take the Webstore

You arrive at Ansible with the webstore running on AWS infrastructure provisioned by Terraform. The EC2 instances exist, the networking is in place, the security groups are correct. But the servers are blank Ubuntu instances — no nginx, no application, no configuration.

You leave with every webstore server fully configured by Ansible playbooks. A new server can be provisioned by Terraform and configured by Ansible without a single manual SSH session. The server state is defined in version-controlled YAML files, applied idempotently on every run.

---

## What Idempotent Means

Running an Ansible playbook once and running it ten times produces the same result. If nginx is already installed, Ansible does not reinstall it. If the config file is already correct, Ansible does not touch it. If the service is already running, Ansible does not restart it. This is idempotency — the foundation of reliable configuration management.

---

## Phases

| # | Phase | Topics | Lab |
|---|---|---|---|
| 01 | [What is Ansible](./01-what-is-ansible/README.md) | Agentless model, SSH-based, inventory, control node vs managed node | No lab |
| 02 | [Playbooks](./02-playbooks/README.md) | Plays, tasks, modules, handlers, YAML structure, running a playbook | [Lab 01](./ansible-labs/01-playbooks-lab.md) |
| 03 | [Variables & Templates](./03-variables-templates/README.md) | Variables, facts, `vars_files`, Jinja2 templates, `when` conditionals | [Lab 02](./ansible-labs/02-variables-templates-lab.md) |
| 04 | [Roles](./04-roles/README.md) | Role directory structure, `tasks`, `handlers`, `templates`, `defaults`, Ansible Galaxy | [Lab 03](./ansible-labs/03-roles-lab.md) |
| 05 | [Real-World Project](./05-real-world/README.md) | Configure the full webstore server fleet — nginx, api, postgres — with roles | [Lab 04](./ansible-labs/04-webstore-config-lab.md) |

---

## Labs

| Lab | Topics Covered | What You Practice |
|---|---|---|
| [Lab 01](./ansible-labs/01-playbooks-lab.md) | Playbooks | Write an inventory file, write your first playbook, run it against an EC2 instance |
| [Lab 02](./ansible-labs/02-variables-templates-lab.md) | Variables & Templates | Use variables and Jinja2 to write the webstore nginx config template |
| [Lab 03](./ansible-labs/03-roles-lab.md) | Roles | Extract the nginx playbook into a reusable role, apply it across multiple servers |
| [Lab 04](./ansible-labs/04-webstore-config-lab.md) | Real-World Project | Configure all three webstore servers end to end — no SSH, no manual steps |

---

## What You Can Do After This

- Write an Ansible inventory file for a fleet of EC2 servers
- Write playbooks that install packages, manage services, and push config files
- Use variables and Jinja2 templates to make playbooks reusable across environments
- Understand and rely on idempotency — run a playbook ten times, same result every time
- Structure reusable roles and organise them the way the community does
- Configure a complete multi-server application without a single manual SSH command

---

## How to Use This

Read phases in order. Each one builds on the previous.
After each phase do the lab before moving on.
The checklist at the end of every lab is not optional.

---

## What Comes Next

→ [11. Bash – Shell Scripting Essentials](../11.%20Bash%20–%20Shell%20Scripting%20Essentials/README.md)

Ansible automates server configuration. Bash scripts automate everything else — deployment steps, health checks, log rotation, backups, environment setup. Every DevOps tool in this runbook is called from the command line. Bash is the glue that connects them.
