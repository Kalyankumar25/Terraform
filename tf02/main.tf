terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}  

provider "aws" {
  region  = "us-east-1"
}
resource "aws_vpc" "vpc" {
cidr_block = "${var.vpc-cidr}"
instance_tenancy        = "default"
enable_dns_hostnames    = true
tags      = {
Name    = "MY_VPC01"
}
}
resource "aws_internet_gateway" "internet-gateway" {
vpc_id    = aws_vpc.vpc.id
tags = {
Name    = "igw-01"
}
}
resource "aws_eip" "nat-gateway" {
  vpc = true
}
resource "aws_subnet" "public-subnet-1" {
vpc_id                  = aws_vpc.vpc.id
cidr_block              = "${var.Public_Subnet_1}"
availability_zone       = "us-east-1a"
map_public_ip_on_launch = true
tags      = {
Name    = "public-subnet-1a"
}
}
resource "aws_subnet" "public-subnet-2" {
vpc_id                  = aws_vpc.vpc.id
cidr_block              = "${var.Public_Subnet_2}"
availability_zone       = "us-east-1d"
map_public_ip_on_launch = true
tags      = {
Name    = "public-subnet-1d"
}
}
resource "aws_subnet" "private-subnet-1" {
vpc_id                   = aws_vpc.vpc.id
cidr_block               = "${var.Private_Subnet_1}"
availability_zone        = "us-east-1a"
map_public_ip_on_launch  = false
tags      = {
Name    = "private-subnet-1"
}
}
resource "aws_subnet" "private-subnet-2" {
vpc_id                   = aws_vpc.vpc.id
cidr_block               = "${var.Private_Subnet_2}"
availability_zone        = "us-east-1d"
map_public_ip_on_launch  = false
tags      = {
Name    = "private-subnet-1d"
}
}
resource "aws_nat_gateway" "nat-gateway" {
allocation_id = aws_eip.nat-gateway.id
subnet_id = aws_subnet.public-subnet-1.id
tags = {
Name    = "natgw-01"
}
depends_on = [aws_internet_gateway.internet-gateway]
}
resource "aws_route_table" "public-route-table" {
vpc_id       = aws_vpc.vpc.id
route {
cidr_block = "0.0.0.0/0"
gateway_id = aws_internet_gateway.internet-gateway.id
}
tags       = {
Name     = "Public Route Table"
}
}
resource "aws_route_table_association" "public-subnet-route-table-association1" {
subnet_id           = aws_subnet.public-subnet-1.id
route_table_id      = aws_route_table.public-route-table.id
}
resource "aws_route_table_association" "public-subnet-route-table-association2" {
subnet_id           = aws_subnet.public-subnet-2.id
route_table_id      = aws_route_table.public-route-table.id
}
resource "aws_route_table" "private-route-table" {
vpc_id       = aws_vpc.vpc.id
route {
cidr_block = "0.0.0.0/0"
gateway_id = aws_nat_gateway.nat-gateway.id
}
tags       = {
Name     = "Private Route Table"
}
}
resource "aws_route_table_association" "private-subnet-route-table-association1" {
subnet_id           = aws_subnet.private-subnet-1.id
route_table_id      = aws_route_table.private-route-table.id
}
resource "aws_route_table_association" "private-subnet-route-table-association2" {
subnet_id           = aws_subnet.private-subnet-2.id
route_table_id      = aws_route_table.public-route-table.id
}
resource "aws_security_group" "ssh-security-group" {
name        = "SSH Security Group"
description = "Enable SSH access on Port 22"
vpc_id      = aws_vpc.vpc.id
ingress {
description      = "SSH Access"
from_port        = 22
to_port          = 22
protocol         = "tcp"
cidr_blocks      = ["${var.ssh-location}"]

}
egress {
from_port        = 0
to_port          = 0
protocol         = "-1"
cidr_blocks      = ["0.0.0.0/0"]
}
tags   = {
Name = "PUBLIC Security Group"
}
}
resource "aws_security_group" "private-ssh-security-group" {
name        = "Private SSH Security Group"
description = "Enable SSH access on Port 22"
vpc_id      = aws_vpc.vpc.id
ingress {
description      = "SSH Access"
from_port        = 22
to_port          = 22
protocol         = "tcp"
cidr_blocks      = ["${var.vpc-cidr}"]
}
ingress{
description      = "ICMP"
from_port        = 0
to_port          = 0
protocol         = "ICMP"
cidr_blocks      = ["${var.vpc-cidr}"]
}
ingress{
description      = "HTTP"
from_port        = 80
to_port          = 80
protocol         = "tcp"
cidr_blocks      = ["${var.vpc-cidr}"]
}
egress {
from_port        = 0
to_port          = 0
protocol         = "-1"
cidr_blocks      = ["0.0.0.0/0"]
}
tags   = {
Name = "Private Security Group"
}
}
resource "aws_security_group" "webserver-security-group" {
name        = "Web Server Security Group"
description = "Enable HTTP/HTTPS access on Port 80/443 via ALB and SSH access on Port 22 via SSH SG"
vpc_id      = aws_vpc.vpc.id
ingress {
description      = "SSH Access"
from_port        = 22
to_port          = 22
protocol         = "tcp"
security_groups  = ["${aws_security_group.ssh-security-group.id}"]
}
egress {
from_port        = 0
to_port          = 0
protocol         = "-1"
cidr_blocks      = ["0.0.0.0/0"]
}
tags   = {
Name = "Web Server Security Group"
}
}

resource "tls_private_key" "key" {
algorithm = "RSA"
}
resource "local_file" "private_key" {
filename          = "key01.pem"
sensitive_content = tls_private_key.key.private_key_pem
file_permission   = "0400"
}
resource "aws_key_pair" "key_pair" {
key_name   = "key01"
public_key = tls_private_key.key.public_key_openssh
}


resource "aws_instance" "ec2_public1" {
ami                    = "ami-0583d8c7a9c35822c"
instance_type               = "${var.instance_type}"
key_name                    = "${var.key_name}"
security_groups             = ["${aws_security_group.ssh-security-group.id}","${aws_security_group.webserver-security-group.id}"]
subnet_id                   = "${aws_subnet.public-subnet-1.id}"
associate_public_ip_address = true

tags = {
"Name" = "webserver-1a"
}
user_data = "${file("web_userdata.sh")}"
}
resource "aws_instance" "ec2_public2" {
ami                    = "ami-0583d8c7a9c35822c"
instance_type               = "${var.instance_type}"
key_name                    = "${var.key_name}"
security_groups             = ["${aws_security_group.ssh-security-group.id}","${aws_security_group.webserver-security-group.id}"]
subnet_id                   = "${aws_subnet.public-subnet-2.id}"
associate_public_ip_address = true

tags = {
"Name" = "webserver-1d"
}
user_data = "${file("web_userdata.sh")}"
}
resource "aws_instance" "ec2_private1" {
ami                    = "ami-0583d8c7a9c35822c"
instance_type               = "${var.instance_type}"
key_name                    = "${var.key_name}"
security_groups             = ["${aws_security_group.private-ssh-security-group.id}"]
subnet_id                   = "${aws_subnet.private-subnet-1.id}"
associate_public_ip_address = false

tags = {
"Name" = "Docker-Server"
}
user_data = "${file("docker.sh")}"
}
resource "aws_instance" "ec2_private2" {
ami                    = "ami-0583d8c7a9c35822c"
instance_type               = "${var.instance_type}"
key_name                    = "${var.key_name}"
security_groups             = ["${aws_security_group.private-ssh-security-group.id}"]
subnet_id                   = "${aws_subnet.private-subnet-2.id}"
associate_public_ip_address = false

tags = {
"Name" = "Kubernetes-Server"
}
user_data = "${file("userdata.sh")}"
}
resource "aws_instance" "app_server" {
ami                    = "ami-0583d8c7a9c35822c"
instance_type               = "${var.instance_type}"
key_name                    = "${var.key_name}"
security_groups             = ["${aws_security_group.ssh-security-group.id}","${aws_security_group.webserver-security-group.id}"]
subnet_id                   = "${aws_subnet.public-subnet-1.id}"
associate_public_ip_address = true

tags = {
"Name" = "App Server"
}
user_data = "${file("userdata.sh")}"
}
resource "aws_instance" "db_server" {
ami                    = "ami-0583d8c7a9c35822c"
instance_type               = "${var.instance_type}"
key_name                    = "${var.key_name}"
security_groups             = ["${aws_security_group.private-ssh-security-group.id}"]
subnet_id                   = "${aws_subnet.private-subnet-2.id}"
associate_public_ip_address = false

tags = {
"Name" = "db_server"
}
user_data = "${file("userdata.sh")}"
}
resource "aws_instance" "Jenkins_server" {
ami                    = "ami-04a81a99f5ec58529"
instance_type               = "${var.instance_type}"
key_name                    = "${var.key_name}"
security_groups             = ["${aws_security_group.private-ssh-security-group.id}"]
subnet_id                   = "${aws_subnet.private-subnet-2.id}"
associate_public_ip_address = false

tags = {
"Name" = "Jenkins-Server"
}
user_data = "${file("ubuntu_ud.sh")}"
}
/*
provisioner "file" {
source      = "./${var.key_name}.pem"
destination = "/root/${var.key_name}.pem" 
connection {
type        = "ssh"
user        = "ec2-user"
private_key = file("${var.key_name}.pem")
host        = self.public_ip
}
}
provisioner "remote-exec" {
inline = ["chmod 400 /root/${var.key_name}.pem"]
connection {
type        = "ssh"
user        = "ec2-user"
private_key = file("${var.key_name}.pem")
host        = self.public_ip
}
}

*/