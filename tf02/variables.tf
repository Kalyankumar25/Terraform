variable "vpc-cidr" {
default = "192.168.10.0/24"
description = "VPC CIDR BLOCK"
type = string
}
variable "Public_Subnet_1" {
default = "192.168.10.0/26"
description = "Public_Subnet_1"
type = string
}
variable "Public_Subnet_2" {
default = "192.168.10.128/26"
description = "Public_Subnet_1"
type = string
}
variable "Private_Subnet_1" {
default = "192.168.10.64/27"
description = "Private_Subnet_1"
type = string
}
variable "Private_Subnet_2" {
default = "192.168.10.96/27"
description = "Private_Subnet_2"
type = string
}
variable "ssh-location" {
default = "0.0.0.0/0"
description = "SSH variable for bastion host"
type = string
}
variable "instance_type" {
type        = string
default     = "t2.micro"
}
variable key_name {
default     = "key01"
type = string
}