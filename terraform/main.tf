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
    Name = "demo-rt"
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
# EKS Cluster
# -----------------------------
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.20.0"

  name               = var.cluster_name
  kubernetes_version = "1.29"

  vpc_id     = aws_vpc.demo.id
  subnet_ids = aws_subnet.demo[*].id

  enable_cluster_creator_admin_permissions = true

  eks_managed_node_groups = {
    demo = {
      instance_types = ["t3.micro"]

      min_size     = 1
      max_size     = 1
      desired_size = 1

      ami_type = "AL2023_x86_64_STANDARD"

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
