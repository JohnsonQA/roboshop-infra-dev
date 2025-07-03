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

module "mongodb" {
    #source = "../../terraform-aws-securitygroup"
    source = "git::https://github.com/daws-84s/terraform-aws-securitygroup.git?ref=main"
    project = var.project
    environment = var.environment
    sg_name = "mongodb"
    sg_description = "for mongodb"
    vpc_id = local.vpc_id
}

module "redis" {
    #source = "../../terraform-aws-securitygroup"
    source = "git::https://github.com/daws-84s/terraform-aws-securitygroup.git?ref=main"
    project = var.project
    environment = var.environment

    sg_name = "redis"
    sg_description = "for redis"
    vpc_id = local.vpc_id
}

module "mysql" {
    #source = "../../terraform-aws-securitygroup"
    source = "git::https://github.com/daws-84s/terraform-aws-securitygroup.git?ref=main"
    project = var.project
    environment = var.environment

    sg_name = "mysql"
    sg_description = "for mysql"
    vpc_id = local.vpc_id
}

module "rabbitmq" {
    #source = "../../terraform-aws-securitygroup"
    source = "git::https://github.com/daws-84s/terraform-aws-securitygroup.git?ref=main"
    project = var.project
    environment = var.environment

    sg_name = "rabbitmq"
    sg_description = "for rabbitmq"
    vpc_id = local.vpc_id
}

module "catalogue" {
    #source = "../../terraform-aws-securitygroup"
    source = "git::https://github.com/daws-84s/terraform-aws-securitygroup.git?ref=main"
    project = var.project
    environment = var.environment

    sg_name = "catalogue"
    sg_description = "for catalogue"
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

#Mongodb accepting connection from VPN on ports 22, 27017
resource "aws_security_group_rule" "mongodb_vpn_ssh" {
  count = length(var.mongodb_ports_vpn)
  type              = "ingress"
  from_port         = var.mongodb_ports_vpn[count.index]
  to_port           = var.mongodb_ports_vpn[count.index]
  protocol          = "tcp"
  source_security_group_id = module.vpn.sg_id        #associating vpn sg id to mongdb
  security_group_id = module.mongodb.sg_id
}

resource "aws_security_group_rule" "redis_vpn_ssh" {
  count = length(var.redis_ports_vpn)
  type              = "ingress"
  from_port         = var.redis_ports_vpn[count.index]
  to_port           = var.redis_ports_vpn[count.index]
  protocol          = "tcp"
  source_security_group_id = module.vpn.sg_id
  security_group_id = module.redis.sg_id
}

resource "aws_security_group_rule" "mysql_vpn_ssh" {
  count = length(var.mysql_ports_vpn)
  type              = "ingress"
  from_port         = var.mysql_ports_vpn[count.index]
  to_port           = var.mysql_ports_vpn[count.index]
  protocol          = "tcp"
  source_security_group_id = module.vpn.sg_id
  security_group_id = module.mysql.sg_id
}

# Rabbitmq accepting connection from VPN on Port 22
resource "aws_security_group_rule" "rabbitmq_vpn_ssh" {
  count = length(var.rabbitmq_ports_vpn)
  type              = "ingress"
  from_port         = var.rabbitmq_ports_vpn[count.index]
  to_port           = var.rabbitmq_ports_vpn[count.index]
  protocol          = "tcp"
  source_security_group_id = module.vpn.sg_id
  security_group_id = module.rabbitmq.sg_id
}

# Catalogue to allow connections from backend alb on port 8080
resource "aws_security_group_rule" "catalogue_backend_alb" {
  type              = "ingress"
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  source_security_group_id = module.backend_alb.sg_id
  security_group_id = module.catalogue.sg_id
}

#It's a direct connect from VPN to access catalogue services
resource "aws_security_group_rule" "catalogue_vpn_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  source_security_group_id = module.vpn.sg_id
  security_group_id = module.catalogue.sg_id
}

# From browser to access catalogues thur VPN on port 8080
resource "aws_security_group_rule" "catalogue_vpn_http" {
  type              = "ingress"
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  source_security_group_id = module.vpn.sg_id
  security_group_id = module.catalogue.sg_id
}

resource "aws_security_group_rule" "catalogue_bastion" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  source_security_group_id = module.bastion.sg_id
  security_group_id = module.catalogue.sg_id
}

#Mongodb to allow connection from catalogues as there is a dependendancy to load products data.
#Check the roboshp documentation or catalogue role for more info
resource "aws_security_group_rule" "mongodb_catalogue" {
  type              = "ingress"
  from_port         = 27017
  to_port           = 27017
  protocol          = "tcp"
  source_security_group_id = module.catalogue.sg_id
  security_group_id = module.mongodb.sg_id
}

