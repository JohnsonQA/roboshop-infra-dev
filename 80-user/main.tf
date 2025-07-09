#Using terraform roboshop module we can create the user component

module "user" {
    source = "../../terraform-aws-roboshop"
    component = "user"
    rule_priority = 20
}