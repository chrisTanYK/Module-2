provider "aws" {
  region = "us-east-1" # Change to your preferred region
}

# VPC
resource "aws_vpc" "christanyk_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "christanyk-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "christanyk_igw" {
  vpc_id = aws_vpc.christanyk_vpc.id

  tags = {
    Name = "christanyk-igw"
  }
}

# Public Subnet
resource "aws_subnet" "christanyk_subnet" {
  vpc_id                  = aws_vpc.christanyk_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "christanyk-public-subnet"
  }
}

# Route Table for Public Subnet
resource "aws_route_table" "christanyk_rt" {
  vpc_id = aws_vpc.christanyk_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.christanyk_igw.id
  }

  tags = {
    Name = "christanyk-rt"
  }
}

# Associate Route Table with Public Subnet
resource "aws_route_table_association" "christanyk_assoc" {
  subnet_id      = aws_subnet.christanyk_subnet.id
  route_table_id = aws_route_table.christanyk_rt.id
}

# Fetch the latest Amazon Linux 2 AMI
data "aws_ami" "latest_amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Security Group allowing SSH
resource "aws_security_group" "christanyk_sg" {
  vpc_id = aws_vpc.christanyk_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Modify for security
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "christanyk-sg"
  }
}

# EC2 Instance
resource "aws_instance" "christanyk_instance" {
  ami                    = data.aws_ami.latest_amazon_linux.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.christanyk_subnet.id
  availability_zone      = aws_subnet.christanyk_subnet.availability_zone
  vpc_security_group_ids = [aws_security_group.christanyk_sg.id]

  tags = {
    Name = "christanyk-instance"
  }
}

# EBS Volume (1GB)
resource "aws_ebs_volume" "christanyk_volume" {
  availability_zone = aws_instance.christanyk_instance.availability_zone
  size              = 1

  tags = {
    Name = "christanyk-ebs"
  }
}

# Attach EBS Volume to EC2
resource "aws_volume_attachment" "christanyk_ebs_attach" {
  device_name = "/dev/xvdf"
  volume_id   = aws_ebs_volume.christanyk_volume.id
  instance_id = aws_instance.christanyk_instance.id
}

# Get available availability zones
data "aws_availability_zones" "available" {}

