# Create/Request ACM Certificate. AWS Certificatie Manager for the Domain roboshop.space
# Expose the cert in SSM store so that can be used for frontend https service

resource "aws_acm_certificate" "roboshop" {
  domain_name       = "*.${var.zone_name}"    #*.roboshop.space
  validation_method = "DNS"                    #Should be validate with DNS

  tags = merge(
    local.common_tags,
    {
        Name = "${var.project}-${var.environment}"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Create R53 records for the TLS certificate that we created
resource "aws_route53_record" "roboshop" {
  for_each = {
    for dvo in aws_acm_certificate.roboshop.domain_validation_options : dvo.domain_name => {
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

# Cert validation with DNS
resource "aws_acm_certificate_validation" "roboshop" {
  certificate_arn         = aws_acm_certificate.roboshop.arn
  validation_record_fqdns = [for record in aws_route53_record.roboshop : record.fqdn]
}
