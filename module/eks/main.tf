###################################################################
# Create VPC and EKS
#
# VPC: https://github.com/terraform-aws-modules/terraform-aws-vpc
# EKS: https://github.com/terraform-aws-modules/terraform-aws-eks
#
###################################################################

# Variable for EKS Cluster name

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.77.0"  # Source Verion

	# VPC
	name = "vpc-${var.cluster_name}"
	cidr = var.vpc_cidr

	# AZ
  azs		            = ["${var.region}a", "${var.region}b", "${var.region}c"]
  private_subnets		= var.private_subnets
  database_subnets	= var.database_subnets
  
  # NAT(for Internet)
  public_subnets		 = var.public_subnets
  enable_nat_gateway = true

  # Disable VPN
  enable_vpn_gateway = false

  # DNS 
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags     = var.tags
  vpc_tags = var.vpc_tags
	public_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
  }		
  private_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = "1"
  }
}

# EKS cluster
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "17.11.0"
	cluster_name    = var.cluster_name
  cluster_version = var.eks_cluster_version
  vpc_id          = module.vpc.vpc_id
  subnets         = module.vpc.private_subnets
  tags            = var.tags

	cluster_endpoint_private_access = var.cluster_endpoint_private_access
	cluster_endpoint_public_access  = var.cluster_endpoint_public_access

	# Managed Node Group
  node_groups_defaults = var.node_groups_defaults

	node_groups = {
    core = {
      desired_capacity  = var.node_groups_desired_capacity
      max_capacity      = var.node_groups_max_capacity
      min_capacity      = var.node_groups_min_capacity

      instance_types    = var.node_groups_instance_types
      capacity_type     = var.node_groups_capacity_type
      k8s_labels        = var.node_groups_k8s_labels
      additional_tags   = var.node_groups_additional_tags
    }
  }

	map_roles    = var.map_roles
  map_users    = var.map_users
  map_accounts = var.map_accounts
}

resource "null_resource" "replace_kube_config" {
  depends_on = [module.eks]
  provisioner "local-exec" {
    command = <<EOT
        cp ./kubeconfig_${var.cluster_name} ../../data/kubeconfig/config
    EOT
  }
}
