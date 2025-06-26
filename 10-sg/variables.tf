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







