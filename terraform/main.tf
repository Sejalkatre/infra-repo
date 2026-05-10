data "aws_availability_zones" "available" {}

resource "aws_vpc" "demo" {
  cidr_block = var.vpc_cidr
}

resource "aws_subnet" "demo" {
  count             = length(var.subnet_cidrs)
  vpc_id            = aws_vpc.demo.id
  cidr_block        = var.subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]
}

module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = var.cluster_name
  cluster_version = "1.29"
  subnets         = aws_subnet.demo[*].id
  vpc_id          = aws_vpc.demo.id

  node_groups = {
    demo = {
      desired_capacity = 1
      max_capacity     = 2
      min_capacity     = 1
      instance_types   = ["t3.micro"]
    }
  }
}
