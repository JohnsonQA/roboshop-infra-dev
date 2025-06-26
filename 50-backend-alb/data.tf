data "aws_ssm_parameter" "vpc_id"{
    name = "/${var.project}/${var.environment}/vpc_id"    //with the name /roboshop/dev/vpc_id this SSM store has VPC value
}

data "aws_ssm_parameter" "private_subnet_ids" {
  name = "/${var.project}/${var.environment}/private_subnet_ids"
}

data "aws_ssm_parameter" "backend_alb_sg_id" {
  name = "/${var.project}/${var.environment}/backend_alb_sg_id"
}