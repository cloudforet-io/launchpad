variable "region" {
  type        = string
  description = "AWS Region for EKS"
}

variable "vpc_name" {
  type        = string
  description = "vpc cluster name"
  default     = ""
}

variable "cluster_name" {
  type        = string
  description = "EKS cluster name"
  default     = ""
}

variable "tags" {
  type        = map
  description = "Tags"
  default     = {}
}

variable "vpc_cidr" {
  type        = string
  description = "VPC for EKS Cluster"
  default     = "" 
}

variable "subnet_AZs" {
  type        = list
  description = "Availability Zones of Subnet"
  default     = []
}

variable "private_subnets" {
  type        = list
  description = "CIDR list for Private Subnets"
  default     = []
}

variable "database_subnets" {
  type        = list
  description = "CIDR list for Database Subnets"
  default     = []
}

variable "public_subnets" {
  type        = list
  description = "CIDR list for Public Subnets"
  default     = []
}

variable "vpc_tags" {
  type        = map
  description = "vpc tags"
  default     = {}
}

variable "eks_cluster_version" {
  type        = string
  description = "EKS Cluster Version"
  default     = ""
}

variable "cluster_endpoint_private_access" {
  type        = bool
  description = "boolean cluster_endpoint_private_access"
  default     = true
}

variable "cluster_endpoint_public_access" {  
  type        = bool
  description = "boolean cluster_endpoint_public_access"
  default     = true
}

variable "node_groups_defaults" {}

variable "node_groups" {}

variable "map_accounts" {
  description = "Additional AWS account numbers to add to the aws-auth configmap."
  type        = list(string)
  default     = []
}

variable "map_roles" {
  description = "Additional IAM roles to add to the aws-auth configmap."
  type = list(object({
    rolearn  = string
    username = string
    groups   = list(string)
  }))

  default = [
  ]
}

variable "map_users" {
  description = "Additional IAM users to add to the aws-auth configmap."
  type = list(object({
    userarn  = string
    username = string
    groups   = list(string)
  }))

  default = [
		{
      userarn  = "arn:aws:iam::111111111111:user/username"
      username = "your_name"
      groups   = ["system:masters"]
    }
  ]
}
