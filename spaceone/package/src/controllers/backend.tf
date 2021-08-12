terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0.1"
    }
    aws = {
      source  = "hashicorp/aws"
      version = ">= 2.28.1"
    }
  }
  backend "local" {
    path = "../../outputs/terraform_states/controllers.tfstate"
  }
  required_version = ">= 0.13.1"
}

data "terraform_remote_state" "eks" {
  backend = "local"
  config = {
    path = "../../outputs/terraform_states/eks.tfstate"
  }
}

data "terraform_remote_state" "certificate" {
  backend = "local"
  config = {
    path = "../../outputs/terraform_states/certificate.tfstate"
  }
}

provider "aws" {
  region = var.region
}

data "aws_eks_cluster" "cluster" {
  name = var.eks_cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = var.eks_cluster_name
}

provider "kubernetes" {
    config_path          = "../../outputs/eks_config/config"
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    token                  = data.aws_eks_cluster_auth.cluster.token  
}

provider "helm" {
  kubernetes {
    config_path          = "../../outputs/eks_config/config"
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}