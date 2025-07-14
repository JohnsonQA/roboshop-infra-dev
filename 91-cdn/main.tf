#Origin block defines the source where cloudFront fetches content from


resource "aws_cloudfront_distribution" "roboshop" {
  origin {
    domain_name = "cdn.${var.zone_name}"   
    custom_origin_config  {
        http_port              = 80 // Required to be set but not used
        https_port             = 443
        origin_protocol_policy = "https-only"    #It talks to origin via https only
        origin_ssl_protocols   = ["TLSv1.2"]     #CDN communicates with origin with these supported TLS versions
    }
    origin_id                = "cdn.${var.zone_name}"
  }

  enabled             = true    #without this CDN won't deploy

  aliases = ["cdn.roboshop.space"]

  #Fall back rule or routing to default cache behaviour
  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]        #Only cache get requests from these methods
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

  #It limits the edge locations cdn should use _200 = Asia + Middle east, _100 only US, canada, europe
  price_class = "PriceClass_200"

  #It controls who can access your CDN content
  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["US", "CA", "GB", "DE"]  #Allowing from only these countries
    }
  }

  tags = merge(
    local.common_tags,{
        Name = "${var.project}-${var.environment}"
    }
  )

  viewer_certificate {
    acm_certificate_arn = local.acm_certificate_arn
    ssl_support_method = "sni-only"  #Use Server Name Indication (SNI) — allows multiple SSL certs on one IP. It's cheaper than dedicated IP.
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