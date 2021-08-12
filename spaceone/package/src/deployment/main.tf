resource "kubernetes_namespace" "spaceone_namespace" {
  metadata {
    name = "spaceone"
  }
}

resource "kubernetes_namespace" "root_supervisor_namespace" {
  metadata {
    name = "root-supervisor"
  }
}

resource "time_sleep" "wait_for_destroy" {
  depends_on = [
  kubernetes_namespace.spaceone_namespace,
  kubernetes_namespace.root_supervisor_namespace
  ]

  destroy_duration = "120s"
}

resource "local_file" "generate_frontend" {
  content  =  templatefile("${path.module}/tmpl/frontend.tpl",
    {
      console-api-domain                 = "${var.console_api_domain}"
      console-api-domain-certificate-arn = "${var.console_api_certificate_arn}"
      console-domain                     = "${var.console_domain}"
      console-domain-certificate-arn     = "${var.console_certificate_arn}"
      spaceone-version                   = "${var.spaceone-version}"
    })
  filename = "${path.module}/../../outputs/helm/frontend.yaml"
}

resource "local_file" "generate_value" {
  content  =  templatefile("${path.module}/tmpl/values.tpl",
    {
      spaceone-version                   = "${var.spaceone-version}"
    })
  filename = "${path.module}/../../outputs/helm/values.yaml"
}

#resource "local_file" "generate_database" {
#  content  =  templatefile("${path.module}/tmpl/database.tpl",
#    {
#      database_user_name                  = "${var.database_user_name}"
#      database_user_password              = "${var.database_user_password}"
#      database_cluster_host_name          = "${var.database_cluster_host_name}"
#    })
#  filename = "${path.module}/yaml/database.yaml"
#}

resource "helm_release" "spaceone" {
  depends_on = [
    kubernetes_namespace.spaceone_namespace,
    kubernetes_namespace.root_supervisor_namespace,
    local_file.generate_frontend,
    local_file.generate_value,
    time_sleep.wait_for_destroy
    ]
  name       = "spaceone"
  repository = "https://spaceone-dev.github.io/charts"
  chart      = "spaceone"
  namespace  = "spaceone"

  values = [
    #local_file.generate_database.content,
    local_file.generate_frontend.content,
    local_file.generate_value.content
  ]
}