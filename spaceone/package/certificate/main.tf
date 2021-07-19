
locals {
  console_domain     = "*.console.${var.root_domain}"
  console_api_domain = "console-api.${var.root_domain}"
} 

resource "aws_acm_certificate" "console" {
  domain_name       = local.console_domain
  validation_method = "DNS"

  tags = {
    Managed_by = "terraform"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate" "console_api" {
  domain_name       = local.console_api_domain
  validation_method = "DNS"

  tags = {
    Managed_by = "terraform"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "console" {
  for_each = {
    for dvo in aws_acm_certificate.console.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.zone_id
}

resource "aws_route53_record" "console_api" {
  for_each = {
    for dvo in aws_acm_certificate.console_api.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.zone_id
}

resource "aws_acm_certificate_validation" "console" {
  certificate_arn         = aws_acm_certificate.console.arn
  validation_record_fqdns = [for record in aws_route53_record.console : record.fqdn]
}

resource "aws_acm_certificate_validation" "console_api" {
  certificate_arn         = aws_acm_certificate.console_api.arn
  validation_record_fqdns = [for record in aws_route53_record.console_api : record.fqdn]
}