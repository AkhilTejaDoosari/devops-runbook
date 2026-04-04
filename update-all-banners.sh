#!/bin/bash
# Run from repo root
# Updates all banners to say X of 09

ASSETS="assets"

cat > "$ASSETS/banner.svg" << 'SVG'
<svg width="100%" viewBox="0 0 680 160" xmlns="http://www.w3.org/2000/svg">
  <rect x="0" y="0" width="680" height="160" rx="8" fill="#1a1a1a"/>
  <text x="40" y="58" font-family="monospace" font-size="11" fill="#666666">$ cat runbook.md</text>
  <text x="40" y="95" font-family="monospace" font-size="28" fill="#ffffff" font-weight="500">devops-runbook</text>
  <text x="40" y="124" font-family="monospace" font-size="12" fill="#999999">Linux · Git · Networking · Docker · Kubernetes · AWS · Terraform · Ansible · Bash</text>
  <rect x="40" y="138" width="60" height="2" rx="1" fill="#666666" opacity="0.4"/>
  <text x="110" y="147" font-family="monospace" font-size="10" fill="#666666">fundamentals first. production ready.</text>
</svg>
SVG

cat > "$ASSETS/linux-banner.svg" << 'SVG'
<svg width="100%" viewBox="0 0 680 160" xmlns="http://www.w3.org/2000/svg">
  <rect x="0" y="0" width="680" height="160" rx="8" fill="#1a1a1a"/>
  <text x="40" y="48" font-family="monospace" font-size="11" fill="#666666">$ man linux</text>
  <text x="40" y="90" font-family="monospace" font-size="28" fill="#ffffff" font-weight="500">linux</text>
  <text x="40" y="119" font-family="monospace" font-size="12" fill="#999999">system fundamentals · servers · files · processes · networking</text>
  <rect x="40" y="133" width="40" height="2" rx="1" fill="#666666" opacity="0.5"/>
  <text x="90" y="142" font-family="monospace" font-size="10" fill="#666666">01 of 09 · no prerequisites</text>
</svg>
SVG

cat > "$ASSETS/git-banner.svg" << 'SVG'
<svg width="100%" viewBox="0 0 680 160" xmlns="http://www.w3.org/2000/svg">
  <rect x="0" y="0" width="680" height="160" rx="8" fill="#1a1a1a"/>
  <text x="40" y="48" font-family="monospace" font-size="11" fill="#666666">$ git log --oneline</text>
  <text x="40" y="90" font-family="monospace" font-size="28" fill="#ffffff" font-weight="500">git &amp; github</text>
  <text x="40" y="119" font-family="monospace" font-size="12" fill="#999999">version control · branching · collaboration · recovery</text>
  <rect x="40" y="133" width="40" height="2" rx="1" fill="#666666" opacity="0.5"/>
  <text x="90" y="142" font-family="monospace" font-size="10" fill="#666666">02 of 09 · requires: linux</text>
</svg>
SVG

cat > "$ASSETS/networking-banner.svg" << 'SVG'
<svg width="100%" viewBox="0 0 680 160" xmlns="http://www.w3.org/2000/svg">
  <rect x="0" y="0" width="680" height="160" rx="8" fill="#1a1a1a"/>
  <text x="40" y="48" font-family="monospace" font-size="11" fill="#666666">$ traceroute google.com</text>
  <text x="40" y="90" font-family="monospace" font-size="28" fill="#ffffff" font-weight="500">networking</text>
  <text x="40" y="119" font-family="monospace" font-size="12" fill="#999999">ip · dns · nat · tcp · firewalls · the foundation for everything</text>
  <rect x="40" y="133" width="40" height="2" rx="1" fill="#666666" opacity="0.5"/>
  <text x="90" y="142" font-family="monospace" font-size="10" fill="#666666">03 of 09 · requires: git</text>
</svg>
SVG

cat > "$ASSETS/docker-banner.svg" << 'SVG'
<svg width="100%" viewBox="0 0 680 160" xmlns="http://www.w3.org/2000/svg">
  <rect x="0" y="0" width="680" height="160" rx="8" fill="#1a1a1a"/>
  <text x="40" y="48" font-family="monospace" font-size="11" fill="#666666">$ docker ps</text>
  <text x="40" y="90" font-family="monospace" font-size="28" fill="#ffffff" font-weight="500">docker</text>
  <text x="40" y="119" font-family="monospace" font-size="12" fill="#999999">containers · networking · volumes · dockerfile · compose</text>
  <rect x="40" y="133" width="40" height="2" rx="1" fill="#666666" opacity="0.5"/>
  <text x="90" y="142" font-family="monospace" font-size="10" fill="#666666">04 of 09 · requires: networking</text>
</svg>
SVG

cat > "$ASSETS/kubernetes-banner.svg" << 'SVG'
<svg width="100%" viewBox="0 0 680 160" xmlns="http://www.w3.org/2000/svg">
  <rect x="0" y="0" width="680" height="160" rx="8" fill="#1a1a1a"/>
  <text x="40" y="48" font-family="monospace" font-size="11" fill="#666666">$ kubectl get pods</text>
  <text x="40" y="90" font-family="monospace" font-size="28" fill="#ffffff" font-weight="500">kubernetes</text>
  <text x="40" y="119" font-family="monospace" font-size="12" fill="#999999">pods · deployments · services · scaling · eks</text>
  <rect x="40" y="133" width="40" height="2" rx="1" fill="#666666" opacity="0.5"/>
  <text x="90" y="142" font-family="monospace" font-size="10" fill="#666666">05 of 09 · requires: docker</text>
</svg>
SVG

cat > "$ASSETS/aws-banner.svg" << 'SVG'
<svg width="100%" viewBox="0 0 680 160" xmlns="http://www.w3.org/2000/svg">
  <rect x="0" y="0" width="680" height="160" rx="8" fill="#1a1a1a"/>
  <text x="40" y="48" font-family="monospace" font-size="11" fill="#666666">$ aws ec2 describe-instances</text>
  <text x="40" y="90" font-family="monospace" font-size="28" fill="#ffffff" font-weight="500">aws</text>
  <text x="40" y="119" font-family="monospace" font-size="12" fill="#999999">vpc · ec2 · s3 · rds · iam · lambda · cloudformation</text>
  <rect x="40" y="133" width="40" height="2" rx="1" fill="#666666" opacity="0.5"/>
  <text x="90" y="142" font-family="monospace" font-size="10" fill="#666666">06 of 09 · requires: networking</text>
</svg>
SVG

cat > "$ASSETS/terraform-banner.svg" << 'SVG'
<svg width="100%" viewBox="0 0 680 160" xmlns="http://www.w3.org/2000/svg">
  <rect x="0" y="0" width="680" height="160" rx="8" fill="#1a1a1a"/>
  <text x="40" y="48" font-family="monospace" font-size="11" fill="#666666">$ terraform apply</text>
  <text x="40" y="90" font-family="monospace" font-size="28" fill="#ffffff" font-weight="500">terraform</text>
  <text x="40" y="119" font-family="monospace" font-size="12" fill="#999999">infrastructure as code · providers · state · modules</text>
  <rect x="40" y="133" width="40" height="2" rx="1" fill="#666666" opacity="0.5"/>
  <text x="90" y="142" font-family="monospace" font-size="10" fill="#666666">07 of 09 · requires: aws</text>
</svg>
SVG

cat > "$ASSETS/ansible-banner.svg" << 'SVG'
<svg width="100%" viewBox="0 0 680 160" xmlns="http://www.w3.org/2000/svg">
  <rect x="0" y="0" width="680" height="160" rx="8" fill="#1a1a1a"/>
  <text x="40" y="48" font-family="monospace" font-size="11" fill="#666666">$ ansible-playbook deploy.yml</text>
  <text x="40" y="90" font-family="monospace" font-size="28" fill="#ffffff" font-weight="500">ansible</text>
  <text x="40" y="119" font-family="monospace" font-size="12" fill="#999999">configuration management · playbooks · roles · idempotency</text>
  <rect x="40" y="133" width="40" height="2" rx="1" fill="#666666" opacity="0.5"/>
  <text x="90" y="142" font-family="monospace" font-size="10" fill="#666666">08 of 09 · requires: terraform</text>
</svg>
SVG

cat > "$ASSETS/bash-banner.svg" << 'SVG'
<svg width="100%" viewBox="0 0 680 160" xmlns="http://www.w3.org/2000/svg">
  <rect x="0" y="0" width="680" height="160" rx="8" fill="#1a1a1a"/>
  <text x="40" y="48" font-family="monospace" font-size="11" fill="#666666">$ chmod +x deploy.sh &amp;&amp; ./deploy.sh</text>
  <text x="40" y="90" font-family="monospace" font-size="28" fill="#ffffff" font-weight="500">bash</text>
  <text x="40" y="119" font-family="monospace" font-size="12" fill="#999999">scripting · automation · cron · pipelines · glue for everything</text>
  <rect x="40" y="133" width="40" height="2" rx="1" fill="#666666" opacity="0.5"/>
  <text x="90" y="142" font-family="monospace" font-size="10" fill="#666666">09 of 09 · requires: linux</text>
</svg>
SVG

echo "All 9 banners written to assets/"
