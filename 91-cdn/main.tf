resource "aws_cloudfront_distribution" "roboshop" {
  origin {
    domain_name = "cdn.${var.zone_name}"
    custom_origin_config  {
        http_port              = 80 // Required to be set but not used
        https_port             = 443
        origin_protocol_policy = "https-only"
        origin_ssl_protocols   = ["TLSv1.2"]
    }
    origin_id                = "cdn.${var.zone_name}"
  }

  enabled             = true

  aliases = ["cdn.roboshop.space"]

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "cdn.${var.zone_name}"

    viewer_protocol_policy = "https-only"
    cache_policy_id  = data.aws_cloudfront_cache_policy.cacheDisable.id
  }

  # Cache behavior with precedence 0
  ordered_cache_behavior {
    path_pattern     = "/media/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = "cdn.${var.zone_name}"

    viewer_protocol_policy = "https-only"
    cache_policy_id  = data.aws_cloudfront_cache_policy.cacheEnable.id
  }


  price_class = "PriceClass_200"

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["US", "CA", "GB", "DE"]
    }
  }

  tags = merge(
    local.common_tags,{
        Name = "${var.project}-${var.environment}"
    }
  )

  viewer_certificate {
    acm_certificate_arn = local.acm_certificate_arn
    ssl_support_method = "sni-only"
  }
}

resource "aws_route53_record" "cdn" {
  zone_id = var.zone_id
  name    = "cdn.${var.zone_name}" #cdn.roboshop.space
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.roboshop.domain_name
    zone_id                = aws_cloudfront_distribution.roboshop.hosted_zone_id
    evaluate_target_health = true
  }
}