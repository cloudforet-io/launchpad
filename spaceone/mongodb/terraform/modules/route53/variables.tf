variable "mongodb_parent_zone" {
  description     = "Parent hosted zone for MongoDB Replication Nodes"
  type =  object({
    name              = string
    zone_id           = string
    vpc_id            = string
  })
}

variable "mongodb_config_servers" {}
variable "mongodb_rs_members" {}

