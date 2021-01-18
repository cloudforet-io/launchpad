// Creating child hosted zone

resource "aws_route53_zone" "mongoDB_hosted_zone" {
  comment   = "MongoDB Shard Cluster. Managed by Terraform"
  name      = "db.${var.mongodb_parent_zone.name}"

  vpc {
    vpc_id      = var.mongodb_parent_zone.vpc_id
  }
}

// In VPC private zone, all nameservers are same. don`t need to add ns records to parent domain.



