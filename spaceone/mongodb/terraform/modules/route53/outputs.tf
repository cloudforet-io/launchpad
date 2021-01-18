output "mongodb_zone_id" {
  value = aws_route53_zone.mongoDB_hosted_zone.zone_id
}

output "mongodb_domain_name" {
  value = aws_route53_zone.mongoDB_hosted_zone.name
}

