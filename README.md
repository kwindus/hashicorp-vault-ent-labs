# swift-lab-aws

Terraform for the **AWS half** of the SWIFT Vault study lab. No Vault clusters
live here — those run on Parallels. This stack provisions only the things Vault
*talks to* (an RDS Postgres target), the CI integration (a GitHub Actions
runner), a credit-earning Lambda, and the **cost-control scaffolding** (budget,
tags, one-command teardown).

## The cost philosophy

Everything billable is **off by default**. The baseline that's always up — VPC,
security groups, budget, Lambda — costs effectively nothing. You flip a service
*on* at the start of a session and *off* at the end. Idle infrastructure is both
cost and attack surface; "off by default, on when needed" is the operating
principle, and it's worth being able to articulate in the interview.

Per-service cost summary:

| Service | Cost while up | Posture |
|---------|--------------|---------|
| VPC / SGs / budget | ~$0 | always on |
| Lambda demo | ~$0 at rest | always on |
| RDS db.t3.micro | ~$0.017/hr (~$12–15/mo) | **apply at session start, destroy at end** |
| EC2 t3.micro runner | ~$0.0104/hr | stop to pause, destroy to remove |

With discipline you'll spend ~$30–60 of real charges across four weeks and keep
most of the $240 credits as buffer. The budget alerts are your safety net.

## First-time setup

```bash
# 1. (Optional but recommended) create the remote state backend
cd bootstrap && terraform init && terraform apply
#    note the printed bucket name, put it in ../backend.tf, uncomment that block
cd .. && terraform init -migrate-state

# 2. Configure your inputs
cp terraform.tfvars.example terraform.tfvars
#    EDIT my_ip_cidr — verify your real Pritunl egress IP first:
#    (on the Pritunl box)  curl ifconfig.me

# 3. Stand up the free baseline
make init
make baseline
```

## Daily workflow

```bash
make rds-up        # start a DB-secrets-engine session
# ... do the lab; Vault on Parallels connects to the RDS endpoint output ...
make rds-down      # end it — RDS gone, credits safe

make down          # end-of-day: kill everything billable, keep baseline
make nuke          # end-of-study: destroy the whole stack
make cost          # remind yourself what's currently costing money
```

## ⚠️ The one rule that protects your credits

**Never leave RDS running overnight.** It bills whether or not Vault is querying
it. `make rds-down` (or `make down`) at the end of every session. The budget
alert at 50% is there to catch the night you forget.

## Security notes

- RDS (5432) and the runner (SSH/22) are reachable **only** from `my_ip_cidr`.
- RDS is `publicly_accessible = true` — lab-only, justified because your Vault
  runs off-AWS and must reach it; the SG is what keeps it safe. Never do this in
  production.
- `terraform.tfvars` and all state are gitignored. The runner registration
  token is short-lived; pass it with `-var` at apply time, never commit it.

## Module map

- `modules/network`     — VPC, public subnets, the two IP-locked security groups
- `modules/budget`      — monthly budget + threshold alerts (credit activity #3)
- `modules/rds-target`  — Postgres for Vault's database secrets engine (#5)
- `modules/gha-runner`  — EC2 self-hosted GitHub Actions runner (#1)
- `modules/lambda-demo` — serverless demo + function URL (#4)

Each module has its own README with specific spin-up / spin-down guidance.
