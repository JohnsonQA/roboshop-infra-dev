#Create key pair in local and attach to aws
/* resource "aws_key_pair" "openvpn" {
  key_name   = "openvpn"
  public_key = file("C:\\devops\\daws-84s\\openvpn.pub") # for mac use /
} */

#Create vpn in public subnet
resource "aws_instance" "vpn"{
    ami = local.ami_id
    instance_type = "t3.micro"
    vpc_security_group_ids = [local.vpn_sg_id]
    subnet_id =  local.public_subnet_id
    key_name = "devopsRsa" # make sure this key exist in AWS
    #key_name = aws_key_pair.openvpn.key_name
    user_data = file("openvpn.sh")     #through bash script in headless mode doing steps to connect to vpn
    
    tags = merge(
    local.common_tags,
    {
        Name = "${var.project}-${var.environment}-vpn"
    }
  )
}

#Create R53 for VPN to re-use the host again without updating IP
resource "aws_route53_record" "vpn" {
  zone_id = var.zone_id
  name    = "vpn-${var.environment}.${var.zone_name}"
  type    = "A"
  ttl     = 1
  records = [aws_instance.vpn.public_ip]
  allow_overwrite = true
}