terraform {
  required_version = ">= 0.13.1"

  required_providers {
    aws        = ">= 2.28.1"
  }
#  backend "s3" {
#    bucket = "var.bucket_name"
#    key    = "certificate/terraform.tfstate"
#    region = "us-west-1"
#  }
  backend "local" {
    path = "./terraform.tfstate"
  }
}

provider "aws" {
  region  = var.region
}