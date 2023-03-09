terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  required_version = ">= 1.2.0"
}

# AWS provider config
provider "aws" {
  region = var.region
  shared_credentials_files = ["./credentials"]
}

# Create cluster nodes ssh keys
resource "tls_private_key" "cluster_nodes_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create aws key pair
resource "aws_key_pair" "generated_key" {
  key_name   = var.key_name
  public_key = tls_private_key.cluster_nodes_key.public_key_openssh
}

# Copy private key into a file
resource "local_file" "ssh_private_key_file" {
  content  = "${tls_private_key.cluster_nodes_key.private_key_pem}"
  filename = "${path.module}/${var.key_name}.pem"
  file_permission = "0600"
}

# Copy public key into a file
resource "local_file" "ssh_public_key_file" {
  content  = "${tls_private_key.cluster_nodes_key.public_key_openssh}"
  filename = "${path.module}/${var.key_name}.pub"
}

# GET available availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Create Private Subnet for K8s cluster nodes 
resource "aws_subnet" "k8s_cluster_private" {
  vpc_id     = module.vpc.vpc_id
  cidr_block = var.k8s_private_subnet_cidr

  tags = {
    Name = "k8s-subnet-private-1"
  }
}

# Create IGW
resource "aws_internet_gateway" "k8s_cluster_ig" {
  vpc_id = module.vpc.vpc_id

  tags = {
    Name = "K8s VPC Internet Gateway"
  }
}

# Create Route table
resource "aws_route_table" "public_rt" {
  vpc_id = module.vpc.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.k8s_cluster_ig.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.k8s_cluster_ig.id
  }

  tags = {
    Name = "Public Route Table"
  }
}

# Create route table association
resource "aws_route_table_association" "public_1_rt_a" {
  subnet_id      = aws_subnet.k8s_cluster_private.id
  route_table_id = aws_route_table.public_rt.id
}

# Create K8s  cluster VPC
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.19.0"

  name = "k8s-vpc"
  cidr = var.k8s_vpc_cidr
  azs = data.aws_availability_zones.available.names
  enable_dns_hostnames = true
}

# Local variables
locals {
  # AWS security group ingress rules 
  ingress_rules = [
      { 
        from = 22, 
        to = 22, 
        proto = "tcp", 
        cidr = ["0.0.0.0/0"], 
        description = "Incoming ssh rule"
      },
      { 
        from = 6443, 
        to = 6443, 
        proto = "tcp", 
        cidr = [var.k8s_private_subnet_cidr], 
        description = "Incoming custom https rule"
      }
    ]
}

# Create aws security group
resource "aws_security_group" "k8s_cluster_sg" {
  name        = "k8s-cluster-sg"
  description = "Ingress and egress traffic to K8s EC2 Instance"
  vpc_id      = module.vpc.vpc_id
  dynamic "ingress" {
    for_each = local.ingress_rules
    content {
      from_port   = ingress.value["from"]
      to_port     = ingress.value["to"]
      protocol    = ingress.value["proto"]
      cidr_blocks = ingress.value["cidr"]
      description = ingress.value["description"]
    }
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name        = "K8s network acl"
    Environment = terraform.workspace
  }
}

# Get ubuntu ami data
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  # Canonical
  owners = ["099720109477"]
}
