# Convenience wrappers around the per-service toggles.
# The whole point: ending a session is one command, so idle cost is near zero.

.PHONY: help init plan baseline rds-up rds-down runner-up runner-down down nuke cost

help:
	@echo "make baseline    - apply free baseline (network, budget, lambda)"
	@echo "make rds-up       - add the RDS Postgres target (Vault DB engine)"
	@echo "make rds-down     - destroy ONLY the RDS target"
	@echo "make runner-up    - add the GitHub Actions runner (needs token vars)"
	@echo "make runner-down  - destroy ONLY the runner"
	@echo "make down         - destroy all billable resources, keep baseline"
	@echo "make nuke         - destroy EVERYTHING in this stack"
	@echo "make cost         - quick reminder of what's currently billable"

init:
	terraform init

baseline:
	terraform apply -var enable_rds=false -var enable_gha_runner=false -var enable_lambda=true

rds-up:
	terraform apply -var enable_rds=true

rds-down:
	terraform apply -var enable_rds=false

runner-up:
	terraform apply -var enable_gha_runner=true

runner-down:
	terraform apply -var enable_gha_runner=false

# Turn off everything that costs money; keep the free baseline in place.
down:
	terraform apply -var enable_rds=false -var enable_gha_runner=false -var enable_lambda=true

# Full teardown — use at the very end of the study period.
nuke:
	terraform destroy

cost:
	@echo "Billable while up:"
	@echo "  RDS db.t3.micro   ~\$$0.017/hr  (~\$$12-15/mo if left up)  <- destroy at session end"
	@echo "  EC2 t3.micro      ~\$$0.0104/hr (stop to pause, destroy to remove)"
	@echo "  Lambda + Budget   ~free at rest (safe to leave on)"
