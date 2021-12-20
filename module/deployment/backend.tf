terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.4.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.7.1"
    }
    aws = {
      source  = "hashicorp/aws"
      version = ">= 2.28.1"
    }
  }
  
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

provider "kubernetes" {
  config_path = "../../data/kubeconfig/config"
}

provider "helm" {
  kubernetes {
    config_path = "../../data/kubeconfig/config"
  }
  repository_config_path = "../../data/helm/config/repositories.yaml"
  repository_cache = "../../data/helm/cache/repository"
}

provider "aws" {
  region = var.region
}