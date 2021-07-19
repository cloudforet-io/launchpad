#######################################################
# OIDC
#######################################################

data "tls_certificate" "thumbprint" {
  url             = data.terraform_remote_state.eks.outputs.cluster_oidc_issuer_url
}

resource "aws_iam_openid_connect_provider" "associate_iam_oidc_provide" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.thumbprint.certificates[0].sha1_fingerprint]
  url             = data.terraform_remote_state.eks.outputs.cluster_oidc_issuer_url
}

#######################################################
# IAM roles for AWSLoadBalancerController
#######################################################

resource "random_string" "random" {
  length  = 5
  special = false
}

resource "aws_iam_policy" "AWSLoadBalancerControllerIAMPolicy" {
  depends_on  = [aws_iam_openid_connect_provider.associate_iam_oidc_provide]

  name        = "AWSLoadBalancerControllerIAMPolicy-${random_string.random.result}"
  policy      = "${file("json/iam-policy.json")}"
}

resource "aws_iam_role" "AWSLoadBalancerController" {
  depends_on  = [aws_iam_openid_connect_provider.associate_iam_oidc_provide]
  
  name        =  "AWSLoadBalancerController_iam_role-${random_string.random.result}"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Federated": "${aws_iam_openid_connect_provider.associate_iam_oidc_provide.arn}"
        },
        "Action": "sts:AssumeRoleWithWebIdentity",
        "Condition": {
          "StringEquals": {
            "${aws_iam_openid_connect_provider.associate_iam_oidc_provide.url}:sub": "system:serviceaccount:kube-system:aws-load-balancer-controller",
            "${aws_iam_openid_connect_provider.associate_iam_oidc_provide.url}:aud": "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "AWSLoadBalancerController" {
    role       = aws_iam_role.AWSLoadBalancerController.name
    policy_arn = aws_iam_policy.AWSLoadBalancerControllerIAMPolicy.arn
}

#######################################################
# IAM roles for external-dns
#######################################################

resource "aws_iam_policy" "external-dns" {
  depends_on  = [aws_iam_openid_connect_provider.associate_iam_oidc_provide]

  name        = "external-dns-${random_string.random.result}"
  policy      = "${file("json/external-dns.json")}"
}

resource "aws_iam_role" "external-dns" {
  depends_on  = [aws_iam_openid_connect_provider.associate_iam_oidc_provide]

  name        =  "external-dns_iam_role-${random_string.random.result}"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Federated": "${aws_iam_openid_connect_provider.associate_iam_oidc_provide.arn}"
        },
        "Action": "sts:AssumeRoleWithWebIdentity",
        "Condition": {
          "StringEquals": {
            "${aws_iam_openid_connect_provider.associate_iam_oidc_provide.url}:aud": "sts.amazonaws.com",
            "${aws_iam_openid_connect_provider.associate_iam_oidc_provide.url}:sub": "system:serviceaccount:kube-system:external-dns"
          }
        }  
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "external-dns" {
    role       = aws_iam_role.external-dns.name
    policy_arn = aws_iam_policy.external-dns.arn
}

#######################################################
# Create AWSLoadBalancerController 
#######################################################

resource "kubernetes_service_account" "aws-load-balancer-controller" {
  depends_on = [aws_iam_role.AWSLoadBalancerController]

  automount_service_account_token = true
  metadata {
    name = "aws-load-balancer-controller"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = "${aws_iam_role.AWSLoadBalancerController.arn}"
    }
    labels = {
      "app.kubernetes.io/name"       = "aws-load-balancer-controller"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

resource "kubernetes_cluster_role" "aws-load-balancer-controller" {
  depends_on = [aws_iam_role.AWSLoadBalancerController]

  metadata {
    name   = "aws-load-balancer-controller"
    labels = {
      "app.kubernetes.io/name"        = "aws-load-balancer-controller"
      "app.kubernetes.io/managed-by"  = "terraform"
    }
  }

   rule {
    api_groups = [
      "",
      "extensions",
    ]

    resources = [
      "configmaps",
      "endpoints",
      "events",
      "ingresses",
      "ingresses/status",
      "services",
    ]

    verbs = [
      "create",
      "get",
      "list",
      "update",
      "watch",
      "patch",
    ]
  }

  rule {
    api_groups = [
      "",
      "extensions",
    ]

    resources = [
      "nodes",
      "pods",
      "secrets",
      "services",
      "namespaces",
    ]

    verbs = [
      "get",
      "list",
      "watch",
    ]
  }
}

resource "kubernetes_cluster_role_binding" "aws-load-balancer-controller" {
  depends_on = [kubernetes_service_account.aws-load-balancer-controller, kubernetes_cluster_role.aws-load-balancer-controller]

  metadata {
    name = "aws-load-balancer-controller"

    labels = {
      "app.kubernetes.io/name"       = "aws-load-balancer-controller"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.aws-load-balancer-controller.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.aws-load-balancer-controller.metadata[0].name
    namespace = "kube-system"
  }
}

resource "helm_release" "aws-load-balancer-controller" {
  depends_on = [kubernetes_cluster_role_binding.aws-load-balancer-controller]
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  
  set {
      name   = "clusterName"
      value  = data.terraform_remote_state.eks.outputs.cluster_id
  }

  set {
      name   = "serviceAccount.create"
      value  = "false"
  }

  set {
      name   = "serviceAccount.name"
      value  = kubernetes_service_account.aws-load-balancer-controller.metadata[0].name
  }
}

#######################################################
# Create external-dns 
#######################################################

resource "kubernetes_service_account" "external-dns" {
  depends_on = [aws_iam_role.external-dns]

  automount_service_account_token = true
  metadata {
    name = "external-dns"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = "${aws_iam_role.external-dns.arn}"
    }   
    labels = {
      "app.kubernetes.io/name"       = "external-dns"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

resource "kubernetes_cluster_role" "external-dns" {
  depends_on = [aws_iam_role.external-dns]
  metadata {
    name = "external-dns"
    labels = {
      "app.kubernetes.io/name"        = "external-dns"
      "app.kubernetes.io/managed-by"  = "terraform"
    }
  }

  rule {
    api_groups = [
      "",
    ]
    resources = [
      "pods",
      "endpoints",
      "services",
    ]
    verbs = [
      "get",
      "list",
      "watch",
    ]
  }

  rule {
    api_groups = [
      "networking.k8s.io",
      "extensions",
    ]
    resources = [
      "ingresses",
    ]
    verbs = [
      "get",
      "list",
      "watch",
    ]
  }

  rule {
    api_groups = [
      "",
    ]
    resources = [
      "nodes",
    ]
    verbs = [
      "list",
      "watch",
    ]
  }
}

resource "kubernetes_cluster_role_binding" "external-dns" {
  depends_on = [kubernetes_service_account.external-dns,kubernetes_cluster_role.external-dns]

  metadata {
    name = "external-dns"

    labels = {
      "app.kubernetes.io/name"       = "external-dns"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.external-dns.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.external-dns.metadata[0].name
    namespace = "kube-system"
  }
}

resource "kubernetes_deployment" "external-dns" {
  depends_on = [kubernetes_cluster_role_binding.external-dns]

  metadata {
    name      = "external-dns"
    namespace = "kube-system"
  }

  spec {
    strategy {
      type = "Recreate"
    }

    selector {
      match_labels = {
        "app.kubernetes.io/name" = "external-dns"
      }
    }

    template {
      metadata {
        labels = {
          "app.kubernetes.io/name" = "external-dns"
        }
        annotations = {
          "iam.amazonaws.com/role" = "${aws_iam_policy.external-dns.arn}"
        }   
      }

      spec {
        container {
          name  = "external-dns"
          image = "k8s.gcr.io/external-dns/external-dns:v0.7.6"
          args = [
            "--source=service",
            "--source=ingress",
            "--domain-filter=${data.terraform_remote_state.certificate.outputs.root_domain} ",
            "--provider=aws",
            "--policy=upsert-only",
            "--aws-zone-type=public",
            "--registry=txt",
            "--txt-owner-id=my-hostedzone-identifier",
          ]
        }
        security_context {
          fs_group = 65534
        }
        service_account_name  = "external-dns"
      }
    }
  }
}