locals {
  nginx_sa = "nginx-deployment-sa"
}

data "aws_ssm_parameter" "nginx_parameter" {
  name = "DOCUMENTDB_HOST"
}

# Namespace
resource "kubernetes_namespace_v1" "nginx" {
  metadata {
    name = "nginx"
  }
}

# Service Account
resource "kubectl_manifest" "nginx_deployment_sa" {
  yaml_body = <<YAML
apiVersion: v1
kind: ServiceAccount
metadata:
  name: "${local.nginx_sa}"
  namespace: ${kubernetes_namespace_v1.nginx.metadata[0].name}
  
YAML
  depends_on = [kubernetes_namespace_v1.nginx]
}

# Trusted entities
data "aws_iam_policy_document" "nginx_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${module.eks.oidc_provider}:sub"
      values   = ["system:serviceaccount:${kubernetes_namespace_v1.nginx.metadata[0].name}:${local.nginx_sa}"]
    }

    condition {
      test     = "StringEquals"
      variable = "${module.eks.oidc_provider}:aud"
      values   = ["sts.amazonaws.com"]
    }

    principals {
      identifiers = [module.eks.oidc_provider_arn]
      type        = "Federated"
    }
  }
}

# Role
resource "aws_iam_role" "nginx_deployment_iamserviceaccount_role" {
  assume_role_policy = data.aws_iam_policy_document.nginx_assume_role_policy.json
  name               = "nginx_assume_role_policy"
}

# Policy
resource "aws_iam_policy" "nginx_parameter_deployment_policy" {
  name = "nginx-parameter-deployment-policy"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"
      Action = [ "ssm:GetParameter", "ssm:GetParameters" ],
      Resource = ["${data.aws_ssm_parameter.nginx_parameter.arn}"]
    }]
  })
}

# Policy Attachment
resource "aws_iam_role_policy_attachment" "nginx_deployment_irsa_role_policy_attachment" {
  policy_arn = aws_iam_policy.nginx_parameter_deployment_policy.arn
  role       = aws_iam_role.nginx_deployment_iamserviceaccount_role.name
}



resource "kubernetes_annotations" "nginx_deployment_sa_annotation" {
  api_version = "v1"
  kind        = "ServiceAccount"
  metadata {
    name = "${local.nginx_sa}"
    namespace = "${kubernetes_namespace_v1.nginx.metadata[0].name}"
  }
  # These annotations will be applied to the ServiceAccount resource itself
  annotations = {
      "eks.amazonaws.com/role-arn" = "${aws_iam_role.nginx_deployment_iamserviceaccount_role.arn}"
  }
}