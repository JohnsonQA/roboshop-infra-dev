data "aws_ssm_parameter" "vpc_id"{
    name = "/${var.project}/${var.environment}/vpc_id"    //with the name /roboshop/dev/vpc_id this SSM store has VPC value
}

