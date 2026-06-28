# module: rds-target  (the hero — handle with care)

A single `db.t3.micro` PostgreSQL 16 instance. This is the target for Vault's
**database secrets engine**: your Parallels Vault connects here as the admin
user and mints short-lived, auto-expiring Postgres credentials on demand. The
green "hero" arrow on the architecture diagram. Also **credit activity #5**.

## Cost — THIS IS THE ONE TO WATCH
**~$0.017/hr while up (~$12–15/month if left running).** It bills continuously
whether or not Vault is querying it.

### Spin DOWN at the end of every session:
```bash
make rds-down       # or: terraform apply -var enable_rds=false
```
### Spin UP only when you're actively doing the DB secrets engine:
```bash
make rds-up         # or: terraform apply -var enable_rds=true
```

`skip_final_snapshot = true` and `deletion_protection = false` are set so
teardown is instant and clean — you lose the data on destroy, which is fine
because the dynamic-secrets demo recreates everything from Vault each session.

## Connecting Vault to it
After `make rds-up`, grab the endpoint:
```bash
terraform output rds_endpoint
terraform output -raw rds_admin_username
# password is sensitive: terraform output -raw, via the module, or read state
```
Then in Vault (on Parallels):
```bash
vault secrets enable database
vault write database/config/swift-lab \
  plugin_name=postgresql-database-plugin \
  connection_url="postgresql://{{username}}:{{password}}@<endpoint>/vaultdemo?sslmode=require" \
  allowed_roles="app" username="vaultadmin" password="<admin-password>"
vault write database/roles/app \
  db_name=swift-lab \
  creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';" \
  default_ttl="1h" max_ttl="24h"
vault read database/creds/app     # <- watch a real, expiring DB user appear in RDS
```

## ⚠️ Reminder
If you do nothing else right, do this: **`make rds-down` before you close the
laptop.** A forgotten RDS instance is the single most likely way to waste
credits in this whole lab.
