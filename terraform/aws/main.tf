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
  region = var.region
  shared_credentials_files = ["./credentials"]
}

resource "tls_private_key" "cluster_nodes_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = var.key_name
  public_key = tls_private_key.cluster_nodes_key.public_key_openssh
  provisioner "local-exec" {
    command = "echo '${tls_private_key.cluster_nodes_key.private_key_pem}' > ./${var.key_name}.pem"
  }
  provisioner "local-exec" {
    command = "echo '${tls_private_key.cluster_nodes_key.public_key_openssh}' > ./${var.key_name}.pub"
  }
}

# GET availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Create Public Subnet for K8s cluster nodes 
resource "aws_subnet" "k8s_cluster_public" {
  vpc_id     = module.vpc.vpc_id
  cidr_block = "172.16.1.0/24"

  tags = {
    Name        = "k8s-subnet-public-1"
  }
}

# Create Public Subnet for K8s cluster nodes 
resource "aws_subnet" "k8s_cluster_private" {
  vpc_id     = module.vpc.vpc_id
  cidr_block = "172.16.2.0/24"

  tags = {
    Name        = "k8s-subnet-private-1"
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
  subnet_id      = aws_subnet.k8s_cluster_public.id
  route_table_id = aws_route_table.public_rt.id
}

# K8s VPC creation
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.19.0"

  name = "k8s-vpc"
  cidr = "172.16.0.0/16"
  azs = data.aws_availability_zones.available.names
  # private_subnets = ["172.16.1.0/24", "172.16.2.0/24", "172.16.3.0/24"]
  # public_subnets = ["172.16.4.0/24", "172.16.5.0/24", "172.16.6.0/24"]
  # enable_nat_gateway = true
  # single_nat_gateway = true
  enable_dns_hostnames = true
}

# Create aws security group
resource "aws_security_group" "k8s_cluster_sg" {
  name        = "k8s-cluster-sg"
  description = "Ingress and egress traffic to K8s EC2 Instance"
  vpc_id      = module.vpc.vpc_id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Incoming SSH rule"
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
