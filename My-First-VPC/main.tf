# VARIABLES - can use variables below with a .tfvars file but configured an aws credentials file with the access/secret access keys. 
# variable "aws_access_key" {}
# variable "aws_secret_key" {}


# PROVIDER
provider "aws" {
  #access_key = var.aws_access_key
  #secret_key = var.aws_secret_key
  region = "us-east-1"
}

# VPC
resource "aws_vpc" "VPC" {
  cidr_block           = "172.23.0.0/16"
  enable_dns_hostnames = "true"

  tags = {
    "Name" : "Kura_VPC_1"
  }
}
# ELASTIC IP
resource "aws_eip" "NAT_EIP" {
  vpc = true
}
# NAT GATEWAY
resource "aws_nat_gateway" "NAT_GATE" {
  allocation_id = aws_eip.NAT_EIP.id
  subnet_id     = aws_subnet.public_subnet_1.id
}
# SUBNET 1
resource "aws_subnet" "public_subnet_1" {
  cidr_block              = "172.23.0.0/18"
  vpc_id                  = aws_vpc.VPC.id
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[0]
}
# SUBNET 2
resource "aws_subnet" "private_subnet_1" {
  cidr_block              = "172.23.64.0/18"
  vpc_id                  = aws_vpc.VPC.id
  map_public_ip_on_launch = false
  availability_zone       = data.aws_availability_zones.available.names[0]
}
# INTERNET GATEWAY
resource "aws_internet_gateway" "IG" {
  vpc_id = aws_vpc.VPC.id
}
# ROUTE TABLE
resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.VPC.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.NAT_GATE.id
  }
}
resource "aws_route_table_association" "routetable_publicsubnet1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.route_table.id
}
# PRIVATE ROUTE TABLE
resource "aws_route_table" "route_table_private" {
  vpc_id = aws_vpc.VPC.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.NAT_GATE.id
  }
}
resource "aws_route_table_association" "routetable_privatesubnet1" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.route_table_private.id
}

# SEC GROUP
resource "aws_security_group" "SG" {
  name        = "ssh-access"
  description = "open ssh traffic"
  vpc_id      = aws_vpc.VPC.id
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    "Name" : "Kura_VPC_1_SG"
    "Terraform" : "true"
  }
}

# DATA
data "aws_availability_zones" "available" {
  state = "available"
}