# Create a Target Group to forward the request from ALB to backendservices on port 8080

resource "aws_lb_target_group" "catalogue" {
  name     = "${var.project}-${var.environment}-catalogue" #roboshop-dev-catalogue
  port     = 8080
  protocol = "HTTP"
  vpc_id   = local.vpc_id
  deregistration_delay = 120
  health_check {
    healthy_threshold = 2     #2 success it means healthy
    interval = 5              # every 5 secs should check the health of catalogue instance
    matcher = "200-299"       # Succesfull status codes
    path = "/health"          #can check the api succesfull api response dns/health or ip/health
    port = 8080               # checking on port 8080
    timeout = 2               # wait for the response. within 2 secs should return response
    unhealthy_threshold = 3   #If 3 consecutive unhealthy then service is unhealthy
  }
}

# Create Catalogue instance
resource "aws_instance" "catalogue" {
  ami           = local.ami_id
  instance_type = "t3.micro"
  vpc_security_group_ids = [local.catalogue_sg_id]
  subnet_id = local.private_subnet_id
  #iam_instance_profile = "EC2RoleToFetchSSMParams"
  tags = merge(
    local.common_tags,
    {
        Name = "${var.project}-${var.environment}-catalogue"
    }
  )
}

#Provisoning the catalogue service into the instance
resource "terraform_data" "catalogue" {
  triggers_replace = [
    aws_instance.catalogue.id
  ]
  
  provisioner "file" {
    source      = "catalogue.sh"
    destination = "/tmp/catalogue.sh"
  }

  connection {
    type     = "ssh"
    user     = "ec2-user"
    password = "DevOps321"
    host     = aws_instance.catalogue.private_ip
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/catalogue.sh",
      "sudo sh /tmp/catalogue.sh catalogue ${var.environment} "
    ]
  }
}

#Auto Scaling. To do it first stop the instance
resource "aws_ec2_instance_state" "catalogue"{
  instance_id = aws_instance.catalogue.id
  state = "stopped"
  depends_on = [terraform_data.catalogue]  #Once provisoning is done then we need to stop the instance
}

# Get the AMI Id of the instance
resource "aws_ami_from_instance" "catalogue" {
  name               = "${var.project}-${var.environment}-catalogue"
  source_instance_id = aws_instance.catalogue.id
  depends_on = [aws_ec2_instance_state.catalogue]   #Once stopped only then we need to get the AMI ID
  tags = merge(
    local.common_tags,
    {
      Name = "${var.project}-${var.environment}-catalogue"
    }
  )
}

#Delete the instance 
resource "terraform_data" "catalogue_delete" {
  triggers_replace = [
    aws_instance.catalogue.id
  ]
  
  # make sure you have aws CLI configure in your laptop. localexec because instance already stopped and no use
  #ssh cannot be done since it is stopped. safe way is doing it using localexec to delete the instance outside of provider
  provisioner "local-exec" {
    command = "aws ec2 terminate-instances --instance-ids ${aws_instance.catalogue.id}"
  }

  depends_on = [aws_ami_from_instance.catalogue]     #Once ami is feteched ony then delete the instance
}