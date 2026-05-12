terraform {

  required_version = ">= 1.3.0"

  required_providers {

    aws = {

      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# -----------------------------
# AWS Provider
# -----------------------------
provider "aws" {

  region = "us-west-2"
}

# -----------------------------
# Availability Zones
# -----------------------------
data "aws_availability_zones" "available" {}

# -----------------------------
# VPC
# -----------------------------
resource "aws_vpc" "demo" {

  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "demo-vpc"
  }
}

# -----------------------------
# Internet Gateway
# -----------------------------
resource "aws_internet_gateway" "demo" {

  vpc_id = aws_vpc.demo.id

  tags = {
    Name = "demo-igw"
  }
}

# -----------------------------
# Public Subnets
# -----------------------------
resource "aws_subnet" "demo" {

  count = length(var.subnet_cidrs)

  vpc_id                  = aws_vpc.demo.id
  cidr_block              = var.subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {

    Name = "demo-subnet-${count.index}"

    "kubernetes.io/role/elb" = "1"

    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

# -----------------------------
# Route Table
# -----------------------------
resource "aws_route_table" "demo" {

  vpc_id = aws_vpc.demo.id

  route {

    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.demo.id
  }

  tags = {
    Name = "demo-route-table"
  }
}

# -----------------------------
# Route Table Association
# -----------------------------
resource "aws_route_table_association" "demo" {

  count = length(aws_subnet.demo)

  subnet_id      = aws_subnet.demo[count.index].id
  route_table_id = aws_route_table.demo.id
}

# -----------------------------
# Security Group
# -----------------------------
resource "aws_security_group" "eks" {

  name        = "eks-security-group"
  description = "Security group for EKS cluster"
  vpc_id      = aws_vpc.demo.id

  ingress {

    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {

    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "eks-security-group"
  }
}

# -----------------------------
# EKS Cluster
# -----------------------------
module "eks" {

  source  = "terraform-aws-modules/eks/aws"
  version = "20.8.5"

  cluster_name    = var.cluster_name
  cluster_version = "1.29"

  vpc_id     = aws_vpc.demo.id
  subnet_ids = aws_subnet.demo[*].id

  enable_irsa = true

  eks_managed_node_groups = {

    demo = {

      instance_types = ["t3.micro"]

      ami_type = "AL2_x86_64"

      capacity_type = "ON_DEMAND"

      min_size     = 1
      max_size     = 1
      desired_size = 1

      disk_size = 20

      subnet_ids = aws_subnet.demo[*].id

      tags = {
        Name = "demo-node-group"
      }
    }
  }

  tags = {

    Environment = "dev"
    Terraform   = "true"
  }
}
