output "domain_name" {
    value = var.domain_name
}

output "console_certificate_arn" {
    value = aws_acm_certificate.console.id
}

output "console_api_certificate_arn" {
    value = aws_acm_certificate.console_api.id
}

output "console_domain" {
    value = aws_acm_certificate.console.domain_name
}

output "console_api_domain" {
    value = aws_acm_certificate.console_api.domain_name
}