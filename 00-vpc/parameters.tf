resource "aws_ssm_parameter" "vpc_id"{
    name = "/${var.project}/${var.environment}/vpc_id"
    type = "string"
    value = module.vpc.vpc_id
}