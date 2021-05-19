###################################################################
# Create VPC and EKS
#
# VPC: https://github.com/terraform-aws-modules/terraform-aws-vpc
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
	cluster_name = "spaceone-prd-eks"
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


module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.77.0"

	# VPC
	name = "vpc-prd-spaceone"
	cidr = "10.0.0.0/22"

	# AZ
  azs		= ["us-west-1a", "us-west-1c"]
  private_subnets		= ["10.0.0.0/24", "10.0.1.0/24"]
  database_subnets	= ["10.0.2.0/25", "10.0.2.128/25"]

  # NAT (for InfraNet)
  #enable_nat_gateway = false
  #intra_subnets			= ["10.0.3.0/26", "10.0.3.64/26"]
  #
  # NAT(for Internet)
  public_subnets			= ["10.0.3.0/26", "10.0.3.64/26"]
  enable_nat_gateway = true

  # Disable VPN
  enable_vpn_gateway = false

  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Terraform = "true"
    Owner = "IT기획부"
    Environment = "prd"
    Application = "spaceone"
  }
  vpc_tags = {
    Name = "vpc-prd-spaceone"
  }
	public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"             = "1"
  }		
  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
  }
}

# EKS cluster
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
	cluster_name    = local.cluster_name
  cluster_version = "1.19"
  subnets         = module.vpc.private_subnets

	cluster_endpoint_private_access = true
	cluster_endpoint_public_access = true

  tags = {
		Terraform = "true"
		Owner = "IT기획부"
    Environment = "prd"
		Application = "spaceone"
  }

	vpc_id = module.vpc.vpc_id

	# Managed Node Group
  node_groups_defaults = {
    ami_type  = "AL2_x86_64"
    disk_size = 50
  }

	node_groups = {
    spaceone_core_node_group = {
      desired_capacity = 4
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
