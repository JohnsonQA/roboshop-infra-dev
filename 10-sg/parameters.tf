#zThis will create ssm store for sg id of frontend instance in SSM parameter store
resource "aws_ssm_parameter" "frontend_sg_id"{
    name = "/${var.project}/${var.environment}/frontend_sg_id"
    type = "String"
    value = module.frontend.sg_id
}