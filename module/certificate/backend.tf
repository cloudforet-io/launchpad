terraform {
  required_version = ">= 0.13.1"

  required_providers {
    aws        = ">= 2.28.1"
  }
  backend "local" {
    path = "../../data/tfstates/certificate.tfstate"
  }
}

provider "aws" {
  region = var.region
}