variable "environment" {}
variable "region" {}
variable "mongodb_ami_id" {}
variable "mongodb_bastion_subnet_id" {}
variable "mongodb_bastion_instance_type" {}
variable "mongodb_bastion_keypair_name" {}
variable "mongodb_bastion_security_group_ids" {
    type = list(string)
}