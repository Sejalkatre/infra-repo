variable "aws_region" {

  description = "AWS region"

  type = string

  default = "us-west-2"
}

variable "cluster_name" {

  description = "EKS Cluster Name"

  type = string

  default = "devops-cluster"
}

variable "vpc_cidr" {

  description = "VPC CIDR"

  type = string

  default = "10.0.0.0/16"
}

variable "subnet_cidrs" {

  description = "Subnet CIDRs"

  type = list(string)

  default = [
    "10.0.1.0/24",
    "10.0.2.0/24"
  ]
}
