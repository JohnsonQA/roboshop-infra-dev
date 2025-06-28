variable "project" {
    default = "roboshop"
}

variable "environment"{
    default = "dev"
}

variable "frontend_sg_name"{
    default = "frontend"
}

variable "frontend_sg_description"{
    default = "created secuirty group for frontend env"
}

variable "bastion_sg_name"{
    default = "bastion"
}

variable "bastion_sg_description"{
    default = "created secuirty group for bastion env"
}

variable "vpn_sg_name"{
    default = "vpn"
}

variable "vpn_sg_description"{
    default = "created secuirty group for vpn"
}

# ports allowing for mongodb to connect thru VPN
variable "mongodb_ports_vpn" {
    default = [22, 27017]
}

variable "redis_ports_vpn" {
    default = [22, 6379]
}

variable "mysql_ports_vpn" {
    default = [22, 3306]
}

variable "rabbitmq_ports_vpn" {
    default = [22, 5672]
}





