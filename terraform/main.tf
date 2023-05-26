locals {
  cluster_prefix = "dscott"
  owner          = "dscott"

  # NOTE: we split up the versions into different minor versions because the azure versions
  #       as noted via the command az aro get-versions, lists a limited version set compared
  #       to what ROSA offers.  using the same version in ROSA also leads to a unstable install
  #       process.
  ocp_version_azure = "4.11.26"
  ocp_version_aws   = "4.11.39"
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
  ocp_version  = local.ocp_version_azure
  location     = "eastus"
  owner        = "dscott"
  pull_secret  = file("~/.azure/aro-pull-secret.txt")
}

module "rosa_cluster" {
  source = "git::https://github.com/scottd018-demos/terraform-rosa.git?ref=v0.0.3-alpha"

  providers = {
    aws = aws.us
  }

  cluster_name = "${local.cluster_prefix}-2"
  ocp_version  = local.ocp_version_aws
  region       = "us-west-2"
  token        = var.token
}
