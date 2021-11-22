terraform {
  required_providers {
    aws = {
        source  = "hashicorp/aws"
        version = ">= 2.28.1"
    }
    kubernetes = {
      source    = "hashicorp/kubernetes"
      version   = ">= 1.13.3"
    }
  }
  backend "local" {
    path = "../../data/tfstates/documentdb.tfstate"
  }

  # required terraform version
  required_version = ">= 0.13.1"
}

data "terraform_remote_state" "eks" {
  backend = "local"
  config = {
    path = "../../data/tfstates/eks.tfstate"
  }
}

provider "aws" {
  region = var.region
}