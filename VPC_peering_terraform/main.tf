provider "aws" {
  region = "us-east-1"
}

# Get the latest Amazon Linux 2 AMI
data "aws_ami" "latest_amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# VPC A
resource "aws_vpc" "christanykA" {
  cidr_block = "10.1.0.0/16"
  tags       = { Name = "christanykA-VPC" }
}

# VPC B
resource "aws_vpc" "christanykB" {
  cidr_block = "10.2.0.0/16"
  tags       = { Name = "christanykB-VPC" }
}

# Internet Gateway for VPC A
resource "aws_internet_gateway" "igwA" {
  vpc_id = aws_vpc.christanykA.id
  tags   = { Name = "christanykA-IGW" }
}

# Internet Gateway for VPC B
resource "aws_internet_gateway" "igwB" {
  vpc_id = aws_vpc.christanykB.id
  tags   = { Name = "christanykB-IGW" }
}

# Subnets
resource "aws_subnet" "subnetA" {
  vpc_id                  = aws_vpc.christanykA.id
  cidr_block              = "10.1.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"
}

resource "aws_subnet" "subnetB" {
  vpc_id                  = aws_vpc.christanykB.id
  cidr_block              = "10.2.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1b"
}

# VPC Peering Connection
resource "aws_vpc_peering_connection" "peer_vpcs" {
  vpc_id      = aws_vpc.christanykA.id
  peer_vpc_id = aws_vpc.christanykB.id
  auto_accept = true
  tags        = { Name = "christanykA-christanykB-Peering" }
}

# Route Tables
resource "aws_route_table" "rtA" {
  vpc_id = aws_vpc.christanykA.id
}

resource "aws_route" "routeA" {
  route_table_id            = aws_route_table.rtA.id
  destination_cidr_block    = "10.2.0.0/16"
  vpc_peering_connection_id = aws_vpc_peering_connection.peer_vpcs.id
}

resource "aws_route_table_association" "rtaA" {
  subnet_id      = aws_subnet.subnetA.id
  route_table_id = aws_route_table.rtA.id
}

resource "aws_route_table" "rtB" {
  vpc_id = aws_vpc.christanykB.id
}

resource "aws_route" "routeB" {
  route_table_id            = aws_route_table.rtB.id
  destination_cidr_block    = "10.1.0.0/16"
  vpc_peering_connection_id = aws_vpc_peering_connection.peer_vpcs.id
}

resource "aws_route_table_association" "rtaB" {
  subnet_id      = aws_subnet.subnetB.id
  route_table_id = aws_route_table.rtB.id
}

# Security Group for HTTP Access
resource "aws_security_group" "web_sg" {
  vpc_id = aws_vpc.christanykA.id
  name   = "allow_http"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 Instances
resource "aws_instance" "ec2_christanykA" {
  ami                    = data.aws_ami.latest_amazon_linux.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.subnetA.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  key_name               = "chrisTanYK_ce9"  # No .pem extension

  user_data = <<-EOF
              #!/bin/bash
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              EOF

  tags = { Name = "christanykA-WebServer" }
}

resource "aws_instance" "ec2_christanykB" {
  ami                    = data.aws_ami.latest_amazon_linux.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.subnetB.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  key_name               = "christanykce9_2"  # No .pem extension

  user_data = <<-EOF
              #!/bin/bash
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              EOF

  tags = { Name = "christanykB-WebServer" }
}

