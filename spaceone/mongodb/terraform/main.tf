terraform {
  backend "s3" {}
}

provider "template" {}

provider "aws"{
  region              = var.region
}

// Security Group for MongoDB
module "mongodb_security_group" {
  source      = "./modules/security_group"

  environment = var.environment
  vpc_id      = var.vpc_id

  mongodb_bastion_ingress_rule_admin_access_security_group_id = var.mongodb_bastion_ingress_rule_admin_access_security_group_id
  mongodb_bastion_ingress_rule_admin_access_port              = var.mongodb_bastion_ingress_rule_admin_access_port
  mongodb_app_ingress_rule_mongodb_access_security_group_id   = var.mongodb_app_ingress_rule_mongodb_access_security_group_id
}

// MongoDB Bastion
module "bastion" {
  source                              =   "./modules/bastion"

  environment                         =   var.environment
  region                              =   var.region

  mongodb_ami_id                      =   var.mongodb_ami_id
  mongodb_bastion_subnet_id           =   var.mongodb_bastion_subnet_id
  mongodb_bastion_instance_type       =   var.mongodb_bastion_instance_type
  mongodb_bastion_keypair_name        =   var.mongodb_bastion_keypair_name
  mongodb_bastion_security_group_ids =    [module.mongodb_security_group.mongodb_bastion_sg_id]

  depends_on                          =   [module.mongodb_security_group]
}

// MongoDB Shard Cluster
module "shard_cluster" {
  source                              =   "./modules/shard_cluster"

  environment                         =   var.environment
  mongodb_host_zone_name              =   var.mongodb_parent_zone.name

  // MongoDB Bastion
  mongodb_ami_id                      =   var.mongodb_ami_id

  // MongoDB Config Server
  mongodb_keypair_name                =   var.mongodb_keypair_name
  mongodb_config_instance_type        =   var.mongodb_config_instance_type
  mongodb_config_server               =   var.mongodb_config_server

  // MongoDB Replica Set Members
  mongodb_replica_set_members         =   var.mongodb_replica_set_members

  // Security Group
  mongodb_security_group_ids          =   [module.mongodb_security_group.mongodb_internal_sg_id, module.mongodb_security_group.mongodb_app_sg_id]

  depends_on                          =   [module.mongodb_security_group]
}

// MongoDB Route53 Records
module "route53_record" {
  source                              =   "./modules/route53"

  // Route 53 parents domain
  mongodb_parent_zone                 =   var.mongodb_parent_zone

  // MongoDB Config Server
  mongodb_config_servers              =   module.shard_cluster.mongodb_config_servers

  // MongoDB Replica Set Members
  mongodb_rs_members                  =   module.shard_cluster.mongodb_rs_members
}