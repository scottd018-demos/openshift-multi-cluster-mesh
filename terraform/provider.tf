terraform {
  required_providers {
    cockroach = {
      source = "cockroachdb/cockroach"
    }
  }
}

# NOTE: export COCKROACH_API_KEY with the cockroach cloud API Key
provider "cockroach" {}

provider "aws" {
  alias  = "us"
  region = "us-west-2"
}
