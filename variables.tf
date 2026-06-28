variable "region" {
  description = "AWS region for the lab."
  type        = string
  default     = "us-east-1"
}

variable "owner" {
  description = "Tag value identifying the lab owner."
  type        = string
  default     = "cat"
}

variable "my_ip_cidr" {
  description = <<-EOT
    The single public IP allowed to reach RDS (5432) and the EC2 runner (SSH/22),
    in CIDR form. This is your Pritunl/home egress IP.

    VERIFY before applying: run `curl ifconfig.me` from the Pritunl box.
    A value ending in .0 is usually a NETWORK address, not a host — confirm
    the real egress IP and use /32 for a single host.
  EOT
  type        = string
  default     = "23.23.207.0/32"

  validation {
    condition     = can(cidrhost(var.my_ip_cidr, 0))
    error_message = "my_ip_cidr must be valid CIDR, e.g. 1.2.3.4/32."
  }
}

variable "budget_limit_usd" {
  description = "Monthly budget ceiling in USD. Alerts fire as a fraction of this."
  type        = number
  default     = 240
}

variable "budget_alert_email" {
  description = "Email address that receives budget threshold alerts."
  type        = string
  default     = "kwindus@gmail.com"
}

# --- Per-service toggles -----------------------------------------------------
# These let you apply ONLY what a given session needs and keep everything else
# from existing (and costing). Flip on at session start, off (or `destroy`) at end.

variable "enable_rds" {
  description = "Create the RDS Postgres target. Turn ON only while practicing the Vault database secrets engine. Costs ~$0.017/hr while up."
  type        = bool
  default     = false
}

variable "enable_gha_runner" {
  description = "Create the EC2 self-hosted GitHub Actions runner. Costs ~$0.0104/hr while running; stop (don't destroy) to pause."
  type        = bool
  default     = false
}

variable "enable_lambda" {
  description = "Create the Lambda demo. Effectively free at rest — safe to leave on."
  type        = bool
  default     = true
}

# --- GitHub runner inputs (only used when enable_gha_runner = true) -----------
variable "gha_repo_url" {
  description = "https://github.com/<you>/swift-lab — the repo the runner registers to."
  type        = string
  default     = ""
}

variable "gha_runner_token" {
  description = "Short-lived registration token from the repo's Settings > Actions > Runners. Expires ~1hr; pass at apply time, never commit."
  type        = string
  default     = ""
  sensitive   = true
}

variable "key_pair_name" {
  description = "Existing EC2 key pair name for SSH to the runner (optional)."
  type        = string
  default     = ""
}
