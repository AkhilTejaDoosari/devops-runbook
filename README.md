<p align="center">
  <img src="./assets/banner.svg" alt="devops-runbook" width="100%"/>
</p>

<p align="center">
  <a href="./LICENSE"><img src="https://img.shields.io/badge/License-MIT-green.svg" alt="MIT License"/></a>
  <a href="https://paypal.me/AkhilTejaDoosari"><img src="https://img.shields.io/badge/PayPal-Support%20this%20work-00457C?logo=paypal&logoColor=white" alt="PayPal"/></a>
</p>

A personal DevOps runbook — structured notes and labs built from fundamentals up, using one consistent application across every tool.

---

## Why This Exists

Most DevOps content teaches tools in isolation. Commands work but nothing connects.  
This runbook takes the opposite approach — every tool is learned in context, every concept links back to its foundation, and the same application runs through every layer.

The goal is the kind of understanding that holds up under production pressure — not just knowing the command, but knowing what happens when you run it.

---

## The Webstore App

Every notes file and lab uses the same 3-tier application as the running example:

| Service | Image | Port |
|---|---|---|
| webstore-frontend | nginx:1.24 | 80 |
| webstore-api | nginx:1.24 | 8080 |
| webstore-db | mongo | 27017 |

Using one consistent app across all tools means concepts connect — you are always building on something already familiar.

---

## Learning Order

```
Linux → Git → Networking → Docker → Kubernetes → AWS → Terraform → Ansible → Bash
```

Networking before Docker — so Docker bridge, DNS, and NAT are not magic.  
Networking before AWS — so VPC, Security Groups, and NAT Gateway are not magic.  
Docker before Kubernetes — so Pods, Services, and networking are not magic.  
Terraform before Ansible — so you configure infrastructure you understand how to build.  
Ansible before Bash — so Bash scripts connect tools you already know how to use.

---

## Structure

```
devops-runbook/
├── assets/          ← banners and images
├── notes/           ← lab instructions and reference material
├── lab-work/        ← personal progress logs (grows as you work)
├── LICENSE
└── README.md
```

| # | Topic | Notes | Labs |
|---|---|---|---|
| 01 | [Linux – System Fundamentals](./notes/01.%20Linux%20–%20System%20Fundamentals/README.md) | ✅ Complete | ✅ Complete |
| 02 | [Git & GitHub – Version Control](./notes/02.%20Git%20%26%20GitHub%20–%20Version%20Control/README.md) | ✅ Complete | ✅ Complete |
| 03 | [Networking – Foundations](./notes/03.%20Networking%20–%20Foundations/README.md) | ✅ Complete | ✅ Complete |
| 04 | [Docker – Containerization](./notes/04.%20Docker%20–%20Containerization/README.md) | ✅ Complete | ✅ Complete |
| 05 | [Kubernetes – Orchestration](./notes/05.%20Kubernetes%20–%20Orchestration/README.md) | ✅ Phases 00–03 | ✅ Phases 00–03 |
| 06 | [AWS – Cloud Infrastructure](./notes/06.%20AWS%20–%20Cloud%20Infrastructure/README.md) | ✅ Complete | 🚧 In progress |
| 07 | [Terraform – IaC Foundations](./notes/07.%20Terraform%20–%20IaC%20Foundations/README.md) | 🚧 In progress | 🚧 Planned |
| 08 | [Ansible – Configuration Management](./notes/08.%20Ansible%20–%20Configuration%20Management/README.md) | 🚧 Planned | 🚧 Planned |
| 09 | [Bash – Shell Scripting Essentials](./notes/09.%20Bash%20–%20Shell%20Scripting%20Essentials/README.md) | 🚧 Planned | 🚧 Planned |

---

## How to Use This Runbook

This repo has two separate folders with two separate purposes:

```
notes/       ← lab instructions and reference material — never edit these
lab-work/    ← your personal progress logs — grows as you work
```

---

**Step 1 — Go in order**  
The learning order is not random. Each folder builds directly on the previous one. Skipping networking before Docker means Docker networking will feel like magic — and magic breaks in production without warning.

**Step 2 — Read the notes before opening a terminal**  
Every notes file starts with the mental model. Read it fully before touching a command. Understanding why something works is what lets you debug it when it breaks.

**Step 3 — Do the labs from scratch**  
Every lab says "write from scratch." This means it. Do not copy-paste commands. Typing them yourself forces your brain to process each flag and each decision. Speed comes later — understanding comes first.

**Step 4 — Break things on purpose**  
Every lab has a "Break It on Purpose" section. Do not skip it. These are the failure states you will actually hit in production. Reading about them is not the same as producing the error yourself and reading the output.

**Step 5 — Log your progress in lab-work/**  
After each lab, open your progress file and add a dated entry:

```
lab-work/
└── 04-docker/
    └── lab-02-networking.md
```

Each entry follows this format:

```markdown
## Session — DD Month YYYY

### What I did
- paste actual terminal output here
- note what commands you ran and what you observed

### What broke
- what error you hit and how you fixed it

### Checklist
- [x] item one
- [x] item two
```

When you revisit a lab later, add a new dated entry at the top of the same file. Your log grows over time and your commit history shows continuous active work.

**Step 6 — Commit after every lab**

```bash
git add lab-work/
git commit -m "lab: complete docker lab 02 — networking and volumes"
git push
```

**Step 7 — When stuck, read the error first**  
Before searching anything, read the full error message. Most errors tell you exactly what is wrong. The habit of reading errors carefully is more valuable than any specific command.

**Step 8 — Use the networking folder as a reference**  
The networking notes are the foundation for Docker, Kubernetes, and AWS. Any time something feels abstract in those tools, go back to the networking folder — the concept is explained there without tool-specific noise.

---

## Sources

Notes in this repository are synthesized from multiple resources — YouTube channels, Udemy courses, private courses, and official documentation. No single source is followed exclusively. Where one explanation fell short, a better one was found elsewhere and the best version was kept.

Credits to the DevOps and cloud community at large.

---

## License

This repository is licensed under the [MIT License](./LICENSE).  
You are free to use, adapt, and share the content — just keep the copyright notice.

---

## Support

If this runbook saved you time or helped something click, you can support it here.

[![PayPal](https://img.shields.io/badge/PayPal-Support%20this%20work-00457C?style=for-the-badge&logo=paypal&logoColor=white)](https://paypal.me/AkhilTejaDoosari)

---

## Contact

- Email: doosariakhilteja@gmail.com
- LinkedIn: https://linkedin.com/in/akhiltejadoosari2001
- GitHub: https://github.com/AkhilTejaDoosari
