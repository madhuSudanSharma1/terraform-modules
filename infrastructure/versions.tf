terraform {
  required_version = ">=1.12.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>6.2"
    }
  }
  backend "s3" {
    bucket       = "madhu-terraform-state-bucket"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
    key          = "modular-terraform/terraform.tfstate"
  }
}
