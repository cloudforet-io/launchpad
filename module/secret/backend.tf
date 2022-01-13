terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 2.28.1"
    }
  }

  backend "local" {
    path = "../../data/tfstates/secret.tfstate"
  }

  required_version = ">= 0.13.1"
}

provider "aws" {
  region = var.region
}