resource "null_resource" "create_k8s_namespace" {
  provisioner "local-exec" {
    command = <<EOT
        kubectl create ns spaceone
        kubectl create ns root-supervisor
    EOT
  }
}

resource "time_sleep" "wait_for_destroy" {
  depends_on = [
  null_resource.create_k8s_namespace
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
    })
  filename = "${path.module}/../../outputs/helm/spaceone/frontend.yaml"
}

resource "local_file" "generate_value" {
  content  =  templatefile("${path.module}/tmpl/values.tpl",
    {
      MARKETPLACE_TOKEN                   = "___CHANGE_INVENTORY_MARKETPLACE_TOKEN___"
    })
  filename = "${path.module}/../../outputs/helm/spaceone/values.yaml"
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

resource "null_resource" "install_spaceone_with_helm" {
  provisioner "local-exec" {
    command = "kubectl config set-context $(kubectl config current-context) --namespace spaceone"
  }
  provisioner "local-exec" {
    command = <<EOT
      helm repo add spaceone https://spaceone-dev.github.io/charts
      helm repo update
      sleep 5
      helm install spaceone \
        -f ${path.module}/../../outputs/helm/spaceone/frontend.yaml \
        -f ${path.module}/../../outputs/helm/spaceone/values.yaml \
        spaceone/spaceone
    EOT
  }
}