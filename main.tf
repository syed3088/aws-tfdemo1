provider "aws" {
  region = var.aws_region
}

# VPC
resource "aws_vpc" "main_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "MainVPC"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id
  tags = {
    Name = "MainIGW"
  }
}

# Public Subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = var.public_subnet_cidr
  map_public_ip_on_launch = true
  availability_zone       = var.availability_zone
  tags = {
    Name = "PublicSubnet"
  }
}

# Route Table
resource "aws_route_table" "main_rt" {
  vpc_id = aws_vpc.main_vpc.id
  tags = {
    Name = "MainRouteTable"
  }
}

# Route Table Association
resource "aws_route" "internet_access" {
  route_table_id         = aws_route_table.main_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main_igw.id
}

resource "aws_route_table_association" "public_subnet_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.main_rt.id
}

# Security Group
resource "aws_security_group" "main_sg" {
  vpc_id = aws_vpc.main_vpc.id
  description = "Allow HTTP and SSH access"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidrs
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_http_cidrs
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "MainSG"
  }
}

# EC2 Instance
resource "aws_instance" "main_instance" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.main_sg.id]

  tags = {
    Name = "MainInstance"
  }
}
