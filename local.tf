# Define Local Values in Terraform
locals {
  host      = var.owner
  environment = var.environment
  name        = "${var.owner}"
  # name        = "${var.business_division}-${var.environment}"

  common_tags = {
    host      = local.host
    environment = local.environment
  }
}