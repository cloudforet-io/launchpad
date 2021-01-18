variable "environment" {}
variable "region" {}
variable "vpc_id" {}

// Security Group
variable "mongodb_bastion_ingress_rule_admin_access_security_group_id" {}
variable "mongodb_bastion_ingress_rule_admin_access_port" {}
variable "mongodb_app_ingress_rule_mongodb_access_security_group_id" {}

// MongoDB Server Domain
variable "mongodb_parent_zone" {
    description     = "Parent private hosted zone for MongoDB Replication Nodes"
    type =  object({
        name              = string
        vpc_id            = string
        zone_id           = string
    })
}


// MongoDB Bastion
variable "mongodb_ami_id" {}
variable "mongodb_bastion_subnet_id" {}
variable "mongodb_bastion_instance_type" {}
variable "mongodb_bastion_keypair_name" {}


// MongoDB Config Server
variable "mongodb_keypair_name" {}
variable "mongodb_config_instance_type" {}
variable "mongodb_config_server" {
    description     =   "for MongoDB Config servers"
    type = list(object({
        name                =   string
        subnet_id           =   string
        rs_primary          =   bool

        root_device         =   object({
            volume_type     =   string
            volume_size     =   number
        })
    }))
}

// MongoDB Replica Set Members
variable "mongodb_replica_set_members" {
    description             =   "for MongoDB Shard Replica Set member instances"
    type = list(object({
        name                =   string
        instance_type       =   string
        subnet_id           =   string
        replica_set         =   string
        rs_type             =   string
        rs_primary          =   bool

        root_device         =   object({
            volume_type     =   string
            volume_size     =   number
        })
        data_devices        =   list(object({
            device_name     =   string
            volume_type     =   string
            volume_size     =   number
        }))
    }))
}
