module "backend_alb"{
    source = "terraform-aws-modules/alb/aws"
    version = "9.16.0"
    internal = true                            #creates alb to private services/network
    name = "${var.project}-${var.environment}-backend-alb"
    vpc_id = local.vpc_id
    subnets = local.private_subnet_ids           #creating alb for backend services so using private subnets. Since its already a list we don't need to wrap in list
    create_security_group = false                # we are creating our own SG. so false
    security_groups = [local.backend_alb_sg_id]  # It give  a string id so we need to wrap in a list  
    enable_deletion_protection = false
    tags = merge(
    local.common_tags,
    {
        Name = "${var.project}-${var.environment}-backend-alb"
    }
  )
}

# Create listener allow port 80 as we are using for private instances
resource "aws_lb_listener" "backend_alb" {
  load_balancer_arn = module.backend_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/html"
      message_body = "<h1>Hello, I am from Backend ALB</h1>"
      status_code  = "200"
    }
  }
}