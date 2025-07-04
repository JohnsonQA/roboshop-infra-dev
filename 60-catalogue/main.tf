# Create a Target Group to forward the request from ALB to backendservices on port 8080

resource "aws_lb_target_group" "catalogue" {
  name     = "${var.project}-${var.environment}-catalogue" #roboshop-dev-catalogue
  port     = 8080                                       #Catalogue listens on port 8080. so is TG
  protocol = "HTTP"
  vpc_id   = local.vpc_id
  deregistration_delay = 120                # Before deleting/de-register the instances from TG, it will wait for 120 sec
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

# Launch Template
resource "aws_launch_template" "catalogue" {
  name = "${var.project}-${var.environment}-catalogue"
  image_id = aws_ami_from_instance.catalogue.id          #AMI ID of catalogue
  instance_initiated_shutdown_behavior = "terminate"     #It should be terminated once get the AMI ID 
  instance_type = "t3.micro"
  vpc_security_group_ids = [local.catalogue_sg_id]        # SG id of catalogue
  update_default_version = true # each time you update, new version will become default
  tag_specifications {
    resource_type = "instance"
    # EC2 tags created by ASG
    tags = merge(
      local.common_tags,
      {
        Name = "${var.project}-${var.environment}-catalogue"
      }
    )
  }

  # volume tags created by ASG
  tag_specifications {
    resource_type = "volume"

    tags = merge(
      local.common_tags,
      {
        Name = "${var.project}-${var.environment}-catalogue"
      }
    )
  }

  # launch template tags
  tags = merge(
      local.common_tags,
      {
        Name = "${var.project}-${var.environment}-catalogue"
      }
  )

}

#Auto Sacling Creation
resource "aws_autoscaling_group" "catalogue" {
  name                 = "${var.project}-${var.environment}-catalogue"
  desired_capacity   = 1                                      #How many instances we want to launch
  max_size           = 10                                     #Max instances to scale up and scale down
  min_size           = 1                                      #Min instance
  target_group_arns = [aws_lb_target_group.catalogue.arn]     #To which target group we need to attach
  vpc_zone_identifier  = local.private_subnet_ids             #In how many zones we should have instances. 
  health_check_grace_period = 90                             #within how many secs health check should start
  health_check_type         = "ELB"                          #Should be done by ALB

  launch_template {
    id      = aws_launch_template.catalogue.id              #Launch Temp ID
    version = aws_launch_template.catalogue.latest_version   #Latest Version as everytime AMI ID changes 
  }

  dynamic "tag" {
    for_each = merge(
      local.common_tags,
      {
        Name = "${var.project}-${var.environment}-catalogue"
      }
    )
    content{
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
    
  }

  #When any changes done in AMI or ASG launch template, instances would be auto refreshed based on rolling strategy it means it replaces gradually not all at once. 
  #Means one or more instances will be terminated and replaced at a time
  instance_refresh {
    strategy = "Rolling" 
    preferences {
      min_healthy_percentage = 50     #During Refresh atleast 50% of instances must be healthy
    }
    triggers = ["launch_template"]     #Based on launch template updates or changes instance trigger the instance refresh
  }

  timeouts{
    delete = "15m"                     #It deletes the instance within 15mins 
  }
}

#Auto Scaling Policy
resource "aws_autoscaling_policy" "catalogue" {
  name                   = "${var.project}-${var.environment}-catalogue"
  autoscaling_group_name = aws_autoscaling_group.catalogue.name
  policy_type            = "TargetTrackingScaling"
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 75.0
  }
}

#ALB Listener Rule for Catalogue Service
resource "aws_lb_listener_rule" "catalogue" {
  listener_arn = local.backend_alb_listener_arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.catalogue.arn  # Forwarsd to Catalogue TG
  }

  condition {
    host_header {
      values = ["catalogue.backend-${var.environment}.${var.zone_name}"]    #When hits tis url then proceed it to TG
    }
  }
}