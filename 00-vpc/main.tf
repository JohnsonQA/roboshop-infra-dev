module "vpc" {
    source = "git::https://github.com/JohnsonQA/terraform-vpc-module.git?ref=main"    //to get the mpodule directly from git
    project = var.project
    environment = var.environment
    public_subnet_cidrs = var.public_subnet_cidrs
    private_subnet_cidrs = var.private_subnet_cidrs
    database_subnet_cidrs = var.database_subnet_cidrs

    is_peering_required = true

}