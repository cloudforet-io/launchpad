###################################################################
# Common
###################################################################
region          = "us-west-1"
cluster_name    = "user"     # EKS cluster name
service_env     = "present"  # ex) prod/stg/dev/qa
tags  = {
    Managed_by  = "terraform"
}

###################################################################
# VPC
###################################################################
vpc_cidr        = "10.0.0.0/22" 
subnet_AZs      = [
    "us-west-1b",
    "us-west-1c"
]
private_subnets  = [
    "10.0.0.0/24", 
    "10.0.1.0/24"
]
database_subnets = [
    "10.0.2.0/25", 
    "10.0.2.128/25"
]
public_subnets   = [
    "10.0.3.0/26", 
    "10.0.3.64/26"
]
vpc_tags         = {
    Managed_by   = "terraform"
    Name         = "vpc-spaceone"
}

###################################################################
# EKS Cluster
###################################################################
eks_cluster_version             = "1.20"
cluster_endpoint_private_access = true
cluster_endpoint_public_access  = true

###################################################################
# EKS Node Group
###################################################################
node_groups_defaults            = {
    ami_type  = "AL2_x86_64",
    disk_size = 50
}
node_groups_desired_capacity    = 4
node_groups_max_capacity        = 5
node_groups_min_capacity        = 1
node_groups_instance_types      = ["t3.small"]
node_groups_capacity_type       = "SPOT"
node_groups_k8s_labels          = {
    Managed_by  = "terraform"
    Application = "spaceone"
}
node_groups_additional_tags     = {
    ExtraTag    = "core"
}