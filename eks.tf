module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.14.0"


  cluster_name                    = local.cluster_name
  cluster_version                 = var.eks_version
  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true
  cluster_enabled_log_types       = ["api", "audit", "authenticator", "controllerManager", "scheduler"] # Backwards compat

  enable_cluster_creator_admin_permissions = true
  authentication_mode = "API_AND_CONFIG_MAP" # this mode is default
  
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.intra_subnets

  # Fargate profiles use the cluster primary security group so these are not utilized
  create_cluster_security_group = false
  create_node_security_group    = false
  
  enable_irsa = true


  # Fargate Profiles
  # fargate_profiles = {
  #   kube_system = {
  #     name = "kube-system"
  #     selectors = [
  #       { namespace = "kube-system" }
  #     ]
  #   }
  
  #   external_dns = {
  #     name = "external-dns"
  #     selectors = [
  #       { namespace = "external-dns" }
  #     ]
  #   }
    
  #   external_secrets = {
  #     name = "external-secrets"
  #     selectors = [
  #       { namespace = "external-secrets" }
  #     ]
  #   }
    
  #   ingress_nginx = {
  #     name = "ingress-nginx"
  #     selectors = [
  #       { namespace = "ingress-nginx" }
  #     ]
  #   }
    
  #   karpenter = {
  #     name = "karpenter"
  #     selectors = [
  #       { namespace = "karpenter" }
  #     ]
  #   }
    
  #}

  # fargate_profile_defaults = {
  #   iam_role_additional_policies = {
  #     additional = module.eks_blueprints_addons.fargate_fluentbit.iam_policy[0].arn
  #   }
  # }
  

  eks_managed_node_groups = {
    default_node_group = {
      name = "managed-ondemand-t3"

      # Starting on 1.30, AL2023 is the default AMI type for EKS managed node groups
      instance_types = ["t3.medium"]
      min_size     = 3
      max_size     = 3
      desired_size = 3
      subnet_ids   = module.vpc.private_subnets
      iam_role_additional_policies = {
        AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
        AmazonEKSWorkerNodePolicy = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy" 
        AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
        AmazonEBSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
        CloudWatchAgentServerPolicy = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
        AmazonInspector2ManagedCispolicy = "arn:aws:iam::aws:policy/AmazonInspector2ManagedCisPolicy"
      }      
    }
  }
  
  # Create Access Entry for SSO Console Access
  access_entries = {
    # One access entry with a policy associated
    SSO_Console_Access = {
      kubernetes_groups = []
      principal_arn     = "arn:aws:iam::${var.account_id}:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_AdministratorAccess"
      user_name         = "admin"
      type              = "STANDARD"
      
      policy_associations = {
        eksadmin_policy = {
          policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"
          access_scope = {
            type       = "cluster"
          }
        }
        
        clusteradmin_policy = {
          policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type       = "cluster"
          }
        }
      }
    }
  }

  cluster_addons = {
  
    coredns = {
      most_recent=true
    }
    
    kube-proxy = {
      most_recent=true
    }
    
    eks-pod-identity-agent = {
      most_recent=true
    }
    
    vpc-cni    = {
      most_recent              = true
      before_compute           = true
      configuration_values = jsonencode({
        env = {
          ENABLE_POD_ENI                    = "true"
          ENABLE_PREFIX_DELEGATION          = "true"
          POD_SECURITY_GROUP_ENFORCING_MODE = "standard"
        }
        enableNetworkPolicy = "true"
      })      
    }
  }
  
  tags = local.tags
}
