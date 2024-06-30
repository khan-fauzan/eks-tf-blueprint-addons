data "aws_route53_zone" "sub" {
  name = local.hosted_zone_name
}

module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.16"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  # We want to wait for the Fargate profiles to be deployed first
  #create_delay_dependencies = [for prof in module.eks.fargate_profiles : prof.fargate_profile_arn]

  # Enable Fargate logging
  # enable_fargate_fluentbit = true
  # fargate_fluentbit = {
  #   flb_log_cw = true
  # }

  enable_cert_manager                 = false
  #enable_aws_cloudwatch_metrics       = true
  enable_external_dns                 = true
  #enable_aws_load_balancer_controller = true
  #enable_karpenter                    = false
  #enable_ingress_nginx                = true
  enable_external_secrets             = true
  enable_secrets_store_csi_driver     = true
  enable_secrets_store_csi_driver_provider_aws = true
  secrets_store_csi_driver_provider_aws = {
    set = [{
      name  = "syncSecret.enabled"
      value = "true"
    }]
  }
  
  # aws_load_balancer_controller = {
  #   set = [{
  #     name  = "enableServiceMutatorWebhook"
  #     value = "false"
  #   }]
  # }
  
  
  external_dns = {
    name          = "external-dns"
    namespace     = "external-dns"
    create_namespace = true
  }
  
  external_dns_route53_zone_arns = [data.aws_route53_zone.sub.arn]

  #tags = local.tags
}
