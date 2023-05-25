locals {
  cluster_prefix = "dscott"
  ocp_version    = "4.11.26"
  owner          = "dscott"
}

variable "token" {
  type = string
}

provider "aws" {
  alias  = "us"
  region = "us-west-2"
}

module "aro_cluster" {
  source = "git::https://github.com/scottd018-demos/terraform-aro.git?ref=v0.0.0-alpha"

  cluster_name = "${local.cluster_prefix}-1"
  ocp_version  = local.ocp_version
  location     = "eastus"
  owner        = "dscott"
  pull_secret  = file("~/.azure/aro-pull-secret.txt")
}

module "rosa_cluster" {
  source = "git::https://github.com/scottd018-demos/terraform-rosa.git?ref=v0.0.1-alpha"

  providers = {
    aws = aws.us
  }

  cluster_name = "${local.cluster_prefix}-2"
  ocp_version  = local.ocp_version
  region       = "us-west-2"
  token        = var.token
}
