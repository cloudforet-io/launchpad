###################################################################
# Create EKS
# 
# Assume: VPC is already exist
# EKS: https://github.com/terraform-aws-modules/terraform-aws-eks
#
###################################################################
terraform {
  required_version = ">= 0.12.6"
}

provider "aws" {
  version = ">= 2.28.1"
  region  = var.region
}


# Variable for EKS
# EKS Cluster name
locals {
	cluster_name = "spaceone-test-eks"
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
  version                = "~> 1.11"
}

# EKS cluster
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
	cluster_name    = local.cluster_name
  cluster_version = "1.19"
  subnets         = var.private_subnets

	cluster_endpoint_private_access = true
	cluster_endpoint_public_access = true

  tags = {
		Terraform = "true"
		Owner = "IT기획부"
    Environment = "prd"
		Application = "spaceone"
  }

	vpc_id = var.vpc_id

	# Managed Node Group
  node_groups_defaults = {
    ami_type  = "AL2_x86_64"
    disk_size = 50
  }

	node_groups = {
    spaceone_core_node_group = {
      desired_capacity = 3
      max_capacity     = 5
      min_capacity     = 1

      instance_types = ["t3.small"]
      capacity_type  = "SPOT"
      k8s_labels = {
        Environment = "prd"
				Terraform = "true"
				Application = "spaceone"
      }
      additional_tags = {
        ExtraTag = "core"
      }
    }
  }

	map_roles    = var.map_roles
  map_users    = var.map_users
  map_accounts = var.map_accounts
}
