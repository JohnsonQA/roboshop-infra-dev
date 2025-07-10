#Using terraform roboshop module we can create the user component

module "component" {
    for_each = var.components
    source = "git::https://github.com/JohnsonQA/terraform-aws-roboshop.git?ref=main"
    component = each.key
    rule_priority = each.value.rule_priority
}