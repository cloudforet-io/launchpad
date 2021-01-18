// Register config server record into route53 hosted zone

resource "aws_route53_record" "mongodb_config_domain_name" {
  zone_id                       = aws_route53_zone.mongoDB_hosted_zone.zone_id
  name                          = "${lookup(var.mongodb_config_servers[count.index].tags, "Name")}.${aws_route53_zone.mongoDB_hosted_zone.name}"
  count                         = length(var.mongodb_config_servers)
  type                          = "A"
  ttl                           = 60
  records                       = [var.mongodb_config_servers[count.index].private_ip]
}

resource "aws_route53_record" "mongodb_rs_member_domain_name" {
  zone_id                       = aws_route53_zone.mongoDB_hosted_zone.zone_id
  name                          = "${lookup(var.mongodb_rs_members[count.index].tags, "Name")}.${aws_route53_zone.mongoDB_hosted_zone.name}"
  count                         = length(var.mongodb_rs_members)
  type                          = "A"
  ttl                           = 60
  records                       = [var.mongodb_rs_members[count.index].private_ip]
}

