locals {
  cluster_prefix = "dscott"
  owner          = "dscott"

  azure_ocp_version = "4.11.26"
  azure_region      = "eastus"

  aws_ocp_version = "4.11.39"
  aws_region      = "us-west-2"
}

variable "token" {
  type      = string
  sensitive = true
}

variable "db_password" {
  type      = string
  sensitive = true
}

module "aro_cluster" {
  source = "git::https://github.com/scottd018-demos/terraform-aro.git?ref=v0.0.0-alpha"

  cluster_name = "${local.cluster_prefix}-1"
  ocp_version  = local.azure_ocp_version
  location     = local.azure_region
  owner        = local.owner
  pull_secret  = file("~/.azure/aro-pull-secret.txt")
}

module "rosa_cluster" {
  source = "git::https://github.com/scottd018-demos/terraform-rosa.git?ref=v0.0.3-alpha"

  providers = {
    aws = aws.us
  }

  cluster_name = "${local.cluster_prefix}-2"
  ocp_version  = local.aws_ocp_version
  region       = local.aws_region
  token        = var.token
}

resource "cockroach_cluster" "demo" {
  name           = local.cluster_prefix
  cloud_provider = "AWS"

  serverless = {}

  regions = [{ name = local.aws_region }]
}

resource "cockroach_sql_user" "demo" {
  name       = local.owner
  password   = var.db_password
  cluster_id = cockroach_cluster.demo.id
}

resource "cockroach_database" "demo" {
  name       = local.cluster_prefix
  cluster_id = cockroach_cluster.demo.id
}
