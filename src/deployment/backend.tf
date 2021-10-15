terraform {
  backend "local" {
    path = "../../outputs/terraform_states/deployment.tfstate"
  }
  required_version = ">= 0.13.1"
}

data "terraform_remote_state" "certificate" {
  backend = "local"
  config = {
    path = "../../outputs/terraform_states/certificate.tfstate"
  }
}

data "terraform_remote_state" "documentdb" {
  count = var.enterprise ? 1 : 0
  backend = "local"
  config = {
    path = "../../outputs/terraform_states/documentdb.tfstate"
  }
}

data "terraform_remote_state" "secret" {
  count = var.enterprise ? 1 : 0
  backend = "local"
  config = {
    path = "../../outputs/terraform_states/secret.tfstate"
  }
}
provider "aws" {
  region = var.region
}