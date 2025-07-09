module "frontend_alb"{
    source = "terraform-aws-modules/alb/aws"
    version = "9.16.0"
    internal = false                            #creates alb to public services/network
    name = "${var.project}-${var.environment}-frontend-alb"
    vpc_id = local.vpc_id
    subnets = local.public_subnet_ids           #creating alb for fronetnd services so using public subnets. Since its already a list we don't need to wrap in list
    create_security_group = false                # we are creating our own SG. so false
    security_groups = [local.frontend_alb_sg_id]  # It give  a string id so we need to wrap in a list  
    enable_deletion_protection = false
    tags = merge(
    local.common_tags,
    {
        Name = "${var.project}-${var.environment}-frontend-alb"
    }
  )
}

# Create listener allow port 443 as we are using for public frontend instances
resource "aws_lb_listener" "frontend_alb" {
  load_balancer_arn = module.frontend_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"  #Security Policy
  certificate_arn   = local.acm_certificate_arn   # Attaching cert that we created for HTTPS

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/html"
      message_body = "<h1>Hello, I am from Frontend ALB using HTTPS</h1>"
      status_code  = "200"
    }
  }
}

#Creating R53 record and attaching the alb DNS 
resource "aws_route53_record" "frontend_alb" {
  zone_id = var.zone_id
  name    = "*.${var.zone_name}"   #*.roboshop.space
  type    = "A"

  alias {
    name                   = module.frontend_alb.dns_name
    zone_id                = module.frontend_alb.zone_id # This is the ZONE ID of ALB
    evaluate_target_health = true
  }
}