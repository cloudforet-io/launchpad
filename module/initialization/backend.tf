terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.4.1"
    }
    aws = {
      source  = "hashicorp/aws"
      version = ">= 2.28.1"
    }
  }

  backend "local" {
    path = "../../data/tfstates/initialization.tfstate"
  }

  required_version = ">= 0.13.1"
}

provider "helm" {
  kubernetes {
    config_path = "../../data/kubeconfig/config"
  }
  repository_config_path = "../../data/helm/config/repositories.yaml"
  repository_cache = "../../data/helm/cache/repository"
}