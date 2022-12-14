#######################################################
# IAM roles for AWSLoadBalancerController
#######################################################

resource "aws_iam_policy" "AWSLoadBalancerControllerIAMPolicy" {
  name        = "${data.terraform_remote_state.eks.outputs.cluster_id}-AWSLoadBalancerControllerIAMPolicy"
  policy      = "${file("json/iam-policy.json")}"
}

resource "aws_iam_role" "AWSLoadBalancerController" {
  name        =  "${data.terraform_remote_state.eks.outputs.cluster_id}-AWSLoadBalancerController_iam_role"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Federated": "${data.terraform_remote_state.eks.outputs.oidc_provider_arn}"
        },
        "Action": "sts:AssumeRoleWithWebIdentity",
        "Condition": {
          "StringEquals": {
            "${data.terraform_remote_state.eks.outputs.oidc_provider}:sub": "system:serviceaccount:kube-system:aws-load-balancer-controller",
            "${data.terraform_remote_state.eks.outputs.oidc_provider}:aud": "sts.amazonaws.com"
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
  count = var.minimal ? 0 : 1

  name        = "${data.terraform_remote_state.eks.outputs.cluster_id}-external-dns"
  policy      = "${file("json/external-dns.json")}"
}

resource "aws_iam_role" "external-dns" {
  count = var.minimal ? 0 : 1

  name        =  "${data.terraform_remote_state.eks.outputs.cluster_id}-external-dns_iam_role"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Federated": "${data.terraform_remote_state.eks.outputs.oidc_provider_arn}"
        },
        "Action": "sts:AssumeRoleWithWebIdentity",
        "Condition": {
          "StringEquals": {
            "${data.terraform_remote_state.eks.outputs.oidc_provider}:aud": "sts.amazonaws.com",
            "${data.terraform_remote_state.eks.outputs.oidc_provider}:sub": "system:serviceaccount:kube-system:external-dns"
          }
        }  
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "external-dns" {
  count = var.minimal ? 0 : 1
  role       = aws_iam_role.external-dns[0].name
  policy_arn = aws_iam_policy.external-dns[0].arn
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

// TODO: controller helm install

resource "helm_release" "aws-load-balancer-controller" {
  depends_on = [kubernetes_cluster_role_binding.aws-load-balancer-controller]
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.4.1"
  
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
  count = var.minimal ? 0 : 1
  depends_on = [aws_iam_role.external-dns[0]]

  automount_service_account_token = true
  metadata {
    name = "external-dns"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = "${aws_iam_role.external-dns[0].arn}"
    }   
    labels = {
      "app.kubernetes.io/name"       = "external-dns"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

resource "kubernetes_cluster_role" "external-dns" {
  count = var.minimal ? 0 : 1
  depends_on = [aws_iam_role.external-dns[0]]
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
  count = var.minimal ? 0 : 1
  depends_on = [kubernetes_service_account.external-dns[0],kubernetes_cluster_role.external-dns[0]]

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
    name      = kubernetes_cluster_role.external-dns[0].metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.external-dns[0].metadata[0].name
    namespace = "kube-system"
  }
}

resource "kubernetes_deployment" "external-dns" {
  count = var.minimal ? 0 : 1
  depends_on = [kubernetes_cluster_role_binding.external-dns[0]]

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
          "iam.amazonaws.com/role" = "${aws_iam_policy.external-dns[0].arn}"
        }   
      }

      spec {
        container {
          name  = "external-dns"
          image = "k8s.gcr.io/external-dns/external-dns:v0.7.6"
          args = [
            "--source=service",
            "--source=ingress",
            "--domain-filter=${data.terraform_remote_state.certificate[0].outputs.domain_name}",
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