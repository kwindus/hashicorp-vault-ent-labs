data "aws_availability_zones" "available" {
  state = "available"
}

# --- Networking: minimal VPC, public subnets, security groups ----------------
module "network" {
  source     = "./modules/network"
  my_ip_cidr = var.my_ip_cidr
  azs        = slice(data.aws_availability_zones.available.names, 0, 2)
}

# --- Cost control: budget + threshold alerts (always on) ---------------------
module "budget" {
  source       = "./modules/budget"
  limit_usd    = var.budget_limit_usd
  alert_email  = var.budget_alert_email
}

# --- RDS Postgres: Vault database secrets-engine target (toggle) --------------
module "rds_target" {
  source = "./modules/rds-target"
  count  = var.enable_rds ? 1 : 0

  vpc_id            = module.network.vpc_id
  subnet_ids        = module.network.public_subnet_ids
  rds_security_group_id = module.network.rds_sg_id
}

# --- EC2 GitHub Actions self-hosted runner (toggle) --------------------------
module "gha_runner" {
  source = "./modules/gha-runner"
  count  = var.enable_gha_runner ? 1 : 0

  subnet_id         = module.network.public_subnet_ids[0]
  security_group_id = module.network.runner_sg_id
  key_pair_name     = var.key_pair_name
  repo_url          = var.gha_repo_url
  runner_token      = var.gha_runner_token
}

# --- Lambda demo: serverless + credit activity (toggle, default on) ----------
module "lambda_demo" {
  source = "./modules/lambda-demo"
  count  = var.enable_lambda ? 1 : 0
}
