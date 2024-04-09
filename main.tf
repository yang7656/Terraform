# The name of the EC2 instances are from input variables "instance1_name" and "instance2_name"
variable "instance1_name" {
    description = "Value of the name tag for EC2 instance"
    type        = string
    default     = "assignment4a"
}

variable "instance2_name" {
    description = "Value of the name tag for EC2 instance"
    type        = string
    default     = "assignment4b"
}

terraform {
    required_providers {
        aws = {
            source   = "hashicorp/aws"
            version  = "~> 4.16"
        }
    }
    
    required_version = ">= 1.2.0"
}

provider "aws" {
    region = "us-east-1"
}


resource "aws_vpc" "main" {
    cidr_block           = "10.0.0.0/16"
    instance_tenancy     = "default"
    enable_dns_hostnames = true
    enable_dns_support   = true

    tags = {
        Name = "main"
    }
}


resource "aws_internet_gateway" "terraform_igw" {
    vpc_id = aws_vpc.main.id

    tags = {
        Name = "main-igw"
    }
}

resource "aws_route_table" "public_route_table" {
    vpc_id = aws_vpc.main.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.terraform_igw.id
    }

    tags = {
        Name = "public-route-table"
    }
}


# one availability zone has one public subnet and one private subnet
resource "aws_subnet" "public1" {
    vpc_id            = aws_vpc.main.id
    cidr_block        = "10.0.1.0/24"
    availability_zone = "us-east-1a"
}

resource "aws_subnet" "public2" {
    vpc_id            = aws_vpc.main.id
    cidr_block        = "10.0.2.0/24"
    availability_zone = "us-east-1b"
}

resource "aws_subnet" "private1" {
    vpc_id            = aws_vpc.main.id
    cidr_block        = "10.0.3.0/24"
    availability_zone = "us-east-1a"
}

resource "aws_subnet" "private2" {
    vpc_id            = aws_vpc.main.id
    cidr_block        = "10.0.4.0/24"
    availability_zone = "us-east-1b"
}


# RDS instance with MySQL engine with all private subnets as its subnet group
resource "aws_db_subnet_group" "terraform_rds" {
    name       = "assignment_rds"
    subnet_ids = [aws_subnet.private1.id, aws_subnet.private2.id]
}


# Web servers' security group opens port 80 from anywhere
resource "aws_security_group" "web_sg" {
    name   = "terraform_instance_sg"
    vpc_id = aws_vpc.main.id
    
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

resource "aws_security_group" "rds_sg" {
    name   = "terraform_rds_sg"
    vpc_id = aws_vpc.main.id
    
    ingress {
        from_port       = 3306
        to_port         = 3306
        protocol        = "tcp"
        security_groups = [aws_security_group.web_sg.id]
    }
}

# RDS instance
resource "aws_db_instance" "assignment_db" {
    username               = "SEIS616"
    password               = "SEIS616Terraform"
    engine                 = "mysql"
    allocated_storage      = 50
    db_subnet_group_name   = aws_db_subnet_group.terraform_rds.name
    instance_class         = "db.t3.micro"
    vpc_security_group_ids = [aws_security_group.rds_sg.id]
    skip_final_snapshot    = true
}


resource "aws_route_table_association" "public1_assoc" {
    subnet_id      = aws_subnet.public1.id
    route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public2_assoc" {
    subnet_id      = aws_subnet.public2.id
    route_table_id = aws_route_table.public_route_table.id
}


# EC2 instances
resource "aws_instance" "instance1" {
    ami                         = "ami-051f8a213df8bc089"
    instance_type               = "t2.micro"
    subnet_id                   = aws_subnet.public1.id
    vpc_security_group_ids      = [aws_security_group.web_sg.id]
    associate_public_ip_address = true
    depends_on = [aws_internet_gateway.terraform_igw]
    
    user_data = <<-EOF
        #!/bin/bash
        yum update -y
        yum install httpd -y
        systemctl start httpd
        systemctl enable httpd
        echo "<html><h1>Terraform Assignment</h1></html>" >> /var/www/html/index.html
    EOF
    
    tags = {
        Name = var.instance1_name
    }
}

resource "aws_instance" "instance2" {
    ami                         = "ami-051f8a213df8bc089"
    instance_type               = "t2.micro"
    subnet_id                   = aws_subnet.public2.id
    vpc_security_group_ids      = [aws_security_group.web_sg.id]
    associate_public_ip_address = true
    depends_on = [aws_internet_gateway.terraform_igw]
    
    user_data = <<-EOF
        #!/bin/bash
        yum update -y
        yum install httpd -y
        systemctl start httpd
        systemctl enable httpd
        echo "<html><h1>Terraform Assignment</h1></html>" >> /var/www/html/index.html
    EOF
    
    tags = {
        Name = var.instance2_name
    }
}