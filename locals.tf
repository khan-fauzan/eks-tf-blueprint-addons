locals {
  # create a name like 'atlas-eks-dev-1-27'
  cluster_name = "${var.project_name}-${var.environment}-${replace(var.eks_version, ".", "-")}"
  azs = slice(data.aws_availability_zones.az.names, 0, 3)

  hosted_zone_name = "kloudessentials.com"
  
  tags = {
    name    = local.cluster_name
    project = var.project_name
    env     = var.environment
  }
}