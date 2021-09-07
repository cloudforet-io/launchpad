data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

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
    path = "../../outputs/terraform_states/eks.tfstate"
  }

  # required terraform version
  required_version = ">= 0.13.1"
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "aws" {
  region = var.region
}