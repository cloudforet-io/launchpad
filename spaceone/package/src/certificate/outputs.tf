output "domain_name" {
    value = var.domain_name
}

output "certificate_arn" {
    value = aws_acm_certificate.this.id
}