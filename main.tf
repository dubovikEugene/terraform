terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region     = "eu-north-1"
  access_key = ""
  secret_key = ""
}

resource "aws_vpc" "ubuntu_vpc" {
  cidr_block           = "10.0.0.0/16"
  instance_tenancy     = "default"
  enable_dns_hostnames = "true"

  tags = {
    Name = "ubuntu_vpc"
  }
}

resource "aws_subnet" "ubuntu_pablic_subnet" {
  vpc_id                  = aws_vpc.ubuntu_vpc.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "eu-north-1a"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "subnet"
  }
}

resource "aws_internet_gateway" "ubuntu_vpc_IGW" {
  vpc_id = aws_vpc.ubuntu_vpc.id

  tags = {
    Name = "ubuntu_vpc_IGW"
  }
}

resource "aws_route_table" "ubuntu_public_route_table" {
  vpc_id = aws_vpc.ubuntu_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ubuntu_vpc_IGW.id
  }
  tags = {
    Name = "ubuntu_public_route_table"
  }
}

resource "aws_route_table_association" "ubuntu_route_table_assotiation" {
  subnet_id      = aws_subnet.ubuntu_pablic_subnet.id
  route_table_id = aws_route_table.ubuntu_public_route_table.id
}


resource "aws_security_group" "ubuntu_sg" {
  name        = "ubuntu_sg"
  description = "This firewall allows SSH, HTTP "
  vpc_id      = aws_vpc.ubuntu_vpc.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "ICMP"
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ubuntu_sg"
  }
}


# Create AWS EC2 Instance
resource "aws_instance" "ubuntu_instance" {
  ami                         = "ami-08eb150f611ca277f"
  associate_public_ip_address = true
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.ubuntu_pablic_subnet.id
  key_name                    = "YauheniTestKeyPair"
  security_groups             = [aws_security_group.ubuntu_sg.id]
  user_data              = file("nginx.tpl")
  root_block_device {
    delete_on_termination = true
    volume_size           = 10
    volume_type           = "gp3"
  }

  tags = {
    Name = "ubuntu_instance"
  }
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.ubuntu_instance.public_ip
}

# Create AWS EC2 Instance
resource "aws_instance" "amazon_linux_instance" {
  ami           = "ami-02db68a01488594c5"
  associate_public_ip_address = false
    subnet_id                   = aws_default_subnet.default_az1.id
  instance_type = "t3.micro"
  key_name = "YauheniTestKeyPair"
  security_groups = [aws_security_group.amazon_linux_sg.id]
 root_block_device {
    delete_on_termination = true
    volume_size           = 10
    volume_type           = "gp3"
  }
  tags = {
    Name = "amazon_linux_instance"
  }
}

resource "aws_default_subnet" "default_az1" {
  availability_zone = "eu-north-1a"

  tags = {
    Name = "Default subnet for us-west-2a"
  }
}

resource "aws_default_vpc" "default" {
   tags = {
    Name = "Default VPC"
  }
}

resource "aws_security_group" "amazon_linux_sg" {
  name        = "amazon_linux_sg"
  vpc_id      = aws_default_vpc.default.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${aws_instance.ubuntu_instance.private_ip}/32"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["${aws_instance.ubuntu_instance.private_ip}/32"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "amazon_linux_sg"
  }
}

