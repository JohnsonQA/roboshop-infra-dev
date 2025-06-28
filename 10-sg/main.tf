module "frontend" {
    source = "git::https://github.com/JohnsonQA/terraform-aws-sg-module.git?ref=main"
    project = var.project
    environment = var.environment
    sg_name = var.frontend_sg_name
    sg_description = var.frontend_sg_description
    vpc_id = local.vpc_id
}

module "bastion" {
    source = "git::https://github.com/JohnsonQA/terraform-aws-sg-module.git?ref=main"
    project = var.project
    environment = var.environment
    sg_name = var.bastion_sg_name
    sg_description = var.bastion_sg_description
    vpc_id = local.vpc_id
}

#creating sg from backen-alb
module "backend_alb" {
    source = "git::https://github.com/JohnsonQA/terraform-aws-sg-module.git?ref=main"
    project = var.project
    environment = var.environment
    sg_name = "backend-alb"
    sg_description = "created for backend alb"
    vpc_id = local.vpc_id
}

module "vpn" {
    source = "git::https://github.com/JohnsonQA/terraform-aws-sg-module.git?ref=main"
    project = var.project
    environment = var.environment
    sg_name = var.vpn_sg_name
    sg_description = "created for vpn"
    vpc_id = local.vpc_id
}

# bastion accepting connections from my laptop
resource "aws_security_group_rule" "bastion_laptop" {
  type              = "ingress"
  from_port         = 22               #SSH connection to login private IP's/ subnets
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]        # allowing open connection
  security_group_id = module.bastion.sg_id    # It's is destination for which we are adding rule
}

# backend ALB accepting connections from my bastion host on port no 80
resource "aws_security_group_rule" "backend_alb_bastion" {
  type              = "ingress"
  from_port         = 80                    # allwoing htpp to connect private backend applications     
  to_port           = 80
  protocol          = "tcp"
  source_security_group_id = module.bastion.sg_id     #bastion sg id attaching to backend -alb sg. so that if bastion ip changes it won't effect to connect application thru LB
  security_group_id = module.backend_alb.sg_id         #Destination sg id for which we are creating
}

#VPN ports 22, 443, 1194, 943 
resource "aws_security_group_rule" "vpn_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = module.vpn.sg_id
}

resource "aws_security_group_rule" "vpn_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = module.vpn.sg_id
}

resource "aws_security_group_rule" "vpn_1194" {
  type              = "ingress"
  from_port         = 1194
  to_port           = 1194
  protocol          = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = module.vpn.sg_id
}

resource "aws_security_group_rule" "vpn_943" {
  type              = "ingress"
  from_port         = 943
  to_port           = 943
  protocol          = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = module.vpn.sg_id
}

# backend ALB accepting connections from VPN on port no 80
resource "aws_security_group_rule" "backend_alb_vpn" {
  type              = "ingress"
  from_port         = 80                    # allwoing htpp to connect private backend applications     
  to_port           = 80
  protocol          = "tcp"
  source_security_group_id = module.vpn.sg_id     #VPN sg id attaching to backend -alb sg. so that if vpn ip changes it won't effect to connect application thru LB
  security_group_id = module.backend_alb.sg_id         #Allowing port 80 to ALB.This is Destination sg id for which we are allowing port
}