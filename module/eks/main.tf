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
  name = var.vpc_name
  cidr = var.vpc_cidr

  # AZ
  azs               = ["${var.region}a", "${var.region}b", "${var.region}c"]
  private_subnets   = var.private_subnets
  database_subnets  = var.database_subnets
  
  # NAT(for Internet)
  public_subnets     = var.public_subnets
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
  version         = "18.21.0"

  cluster_name    = var.cluster_name
  cluster_version = var.eks_cluster_version
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnets
  tags            = var.tags



  # Extend cluster security group rules
  cluster_security_group_additional_rules = {
    egress_nodes_ephemeral_ports_tcp = {
      description                = "To node 1025-65535"
      protocol                   = "tcp"
      from_port                  = 1025
      to_port                    = 65535
      type                       = "egress"
      source_node_security_group = true
    }
  }

  # Extend node-to-node security group rules
  node_security_group_additional_rules = {
    ingress_allow_access_from_control_plane = {
      type                          = "ingress"
      protocol                      = "tcp"
      from_port                     = 9443
      to_port                       = 9443
      source_cluster_security_group = true
      description                   = "Allow access from control plane to webhook port of AWS load balancer controller"
    }
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    egress_all = {
      description      = "Node all egress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  }

  cluster_endpoint_private_access = var.cluster_endpoint_private_access
  cluster_endpoint_public_access  = var.cluster_endpoint_public_access

  # Managed Node Group
  eks_managed_node_group_defaults  = var.node_groups_defaults
  eks_managed_node_groups          = var.node_groups

  aws_auth_roles       = var.map_roles
  aws_auth_users       = var.map_users
  aws_auth_accounts    = var.map_accounts
}

resource "null_resource" "replace_kube_config" {
  depends_on = [module.eks]
  provisioner "local-exec" {
    command = <<EOT
        aws eks update-kubeconfig --region ${var.region} --name ${var.cluster_name} --kubeconfig ../../data/kubeconfig/config
    EOT
  }
}
