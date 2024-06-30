output "r53_hostedzone_arn" {
  description = "The arn of the route 53 hosted zone"
  value       = data.aws_route53_zone.sub.arn
}

output "oidc_provider" {
  description = "OIDC Provider"
  value = module.eks.oidc_provider
}

output "oidc_provider_arn" {
  description = "OIDC Provider arn"
  value = module.eks.oidc_provider_arn
}

# output "nginx_parameter_arn" {
#   value = data.aws_ssm_parameter.nginx_parameter.arn
# }