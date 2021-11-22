terraform {
  backend "local" {
    path = "../../data/tfstates/deployment.tfstate"
  }
  required_version = ">= 0.13.1"
}

data "terraform_remote_state" "certificate" {
  backend = "local"
  config = {
    path = "../../data/tfstates/certificate.tfstate"
  }
}

data "terraform_remote_state" "documentdb" {
  count = var.enterprise ? 1 : 0
  backend = "local"
  config = {
    path = "../../data/tfstates/documentdb.tfstate"
  }
}

data "terraform_remote_state" "secret" {
  count = var.enterprise ? 1 : 0
  backend = "local"
  config = {
    path = "../../data/tfstates/secret.tfstate"
  }
}
provider "aws" {
  region = var.region
}