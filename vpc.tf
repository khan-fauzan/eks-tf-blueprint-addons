data "aws_availability_zones" "az" {
  state = "available"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.8.1"
  
  name = var.vpc_name
  cidr = var.vpc_cidr
  secondary_cidr_blocks = var.secondary_cidr_blocks

  azs      = slice(data.aws_availability_zones.az.names, 0, 3)

  private_subnets = concat(
    [for k, v in local.azs : cidrsubnet(element(var.secondary_cidr_blocks, 0), 2, k)]
  )
  
  # 10.0.48.0/24 and 10.0.49.0/24 and 10.0.50.0/24
  public_subnets  = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 8, k + 48)]
  
  # 10.0.52.0/24 and 10.0.53.0/24 and 10.0.54.0/24
  intra_subnets   = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 8, k + 52)]
  
  # 10.0.56.0/24 and 10.0.57.0/24 and 10.0.57.0/24
  #database_subnets   = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 56)]

  public_subnet_suffix  = "SubnetPublic"
  private_subnet_suffix = "SubnetPrivate"
  #database_subnet_suffix = "SubnetDatabase"


  enable_nat_gateway = true
  single_nat_gateway = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
    "kubernetes.io/cluster/${local.cluster_name}" = "owned"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
    # Tags subnets for Karpenter auto-discovery
    "karpenter.sh/discovery" = local.cluster_name
    "kubernetes.io/cluster/${local.cluster_name}" = "owned"
  }

  # Flow Logs
  #enable_flow_log                                 = true
  #flow_log_destination_type                       = "cloud-watch-logs"
  #create_flow_log_cloudwatch_log_group            = true
  #create_flow_log_cloudwatch_iam_role             = true
  #flow_log_cloudwatch_log_group_retention_in_days = 7
  #flow_log_log_format                             = "$${interface-id} $${srcaddr} $${srcport} $${pkt-src-aws-service} $${dstaddr} $${dstport} $${pkt-dst-aws-service} $${protocol} $${flow-direction} $${traffic-path} $${action} $${log-status} $${subnet-id} $${az-id} $${sublocation-type} $${sublocation-id}"
  
  tags = local.tags
}