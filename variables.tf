variable "region" {
  description = "AWS region"
  type        = string
}

variable "account_id" {
  description = "AWS region"
  type        = string
}

variable "vpc_name" {
  type        = string
  description = "VPC Name"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR"
}

variable "azs" {
  type        = list(string)
  description = "Availability Zones"
}

# variable "public_subnets" {
#   type        = list(string)
#   description = "Public Subnet CIDR values"
# }

# variable "private_subnets" {
#   type        = list(string)
#   description = "Private Subnet CIDR values"
# }

# variable "intra_subnets" {
#   type        = list(string)
#   description = "Intra Subnet CIDR values"
# }

variable "secondary_cidr_blocks" {
  type        = list(string)
  description = "Secondary CIDR Blocks"
}

variable "eks_version" {
  type        = string
  description = "kubernetes version"
}

# variable "eks_cluster_name" {
#   type        = string
#   description = "kubernetes cluster name"
# }

variable "project_name" {
  type = string
  description = "EKS Project Name"
}

variable "environment" {
  type = string
  description = "Environment dev/production/QA"
}
