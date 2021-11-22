resource "null_resource" "create_k8s_namespace" {
  provisioner "local-exec" {
    command = <<EOT
        kubectl create ns spaceone
        kubectl create ns root-supervisor
    EOT
  }
}

resource "local_file" "generate_frontend" {
  count = var.enterprise ? 1 : 0
  content  =  templatefile("${path.module}/tmpl/frontend.tpl",
    {
      console-api-domain                 = "console-api.${data.terraform_remote_state.certificate.outputs.domain_name}"
      console-domain                     = "*.console.${data.terraform_remote_state.certificate.outputs.domain_name}"
      certificate-arn                    = "${data.terraform_remote_state.certificate.outputs.certificate_arn}"
    })
  filename = "${path.module}/../../data/helm/values/spaceone/frontend.yaml"
}

module "get_secret_key" {
  depends_on = [
    null_resource.create_k8s_namespace
  ]
  source = "matti/outputs/shell"

  command = "base64 --decode ../secret/gpg/secret-key | gpg --pinentry-mode loopback --decrypt --batch --passphrase spaceone"
}

data "aws_region" "current" {}

resource "local_file" "generate_value" {
  count = var.enterprise ? 1 : 0
  content  =  templatefile("${path.module}/tmpl/values.tpl",
    {
      aws_access_key_id          = "${data.terraform_remote_state.secret[0].outputs.access_key_id}"
      aws_secret_access_key      = "${module.get_secret_key.stdout}"
      region_name                = "${data.aws_region.current.name}"
      monitoring_domain          = "monitoring.${data.terraform_remote_state.certificate.outputs.domain_name}"
      monitoring_webhook_domain  = "monitoring-webhook.${data.terraform_remote_state.certificate.outputs.domain_name}"
      certificate-arn            = "${data.terraform_remote_state.certificate.outputs.certificate_arn}"
      smpt_host                  = "${var.notification_smpt_host}" 
      smpt_port                  = "${var.notification_smpt_port}"
      smpt_user                  = "${var.notification_smpt_user}"
      smpt_password              = "${var.notification_smpt_password}"
    })
  filename = "${path.module}/../../data/helm/values/spaceone/values.yaml"
}

resource "local_file" "generate_database" {
 count = var.enterprise ? 1 : 0
 content  =  templatefile("${path.module}/tmpl/database.tpl",
   {
     database_user_name                  = "${data.terraform_remote_state.documentdb[0].outputs.database_user_name}"
     database_user_password              = "${data.terraform_remote_state.documentdb[0].outputs.database_user_password}"
     endpoint                            = "${data.terraform_remote_state.documentdb[0].outputs.endpoint}"
   })
 filename = "${path.module}/../../data/helm/values/spaceone/database.yaml"
}

resource "local_file" "generate_minikube" {
 count = var.development ? 1 : 0
 content  =  templatefile("${path.module}/tmpl/minikube.tpl",
   {
      console-api-domain                 = "console-api.${data.terraform_remote_state.certificate.outputs.domain_name}"
      console-domain                     = "*.console.${data.terraform_remote_state.certificate.outputs.domain_name}"
      monitoring_domain                  = "monitoring.${data.terraform_remote_state.certificate.outputs.domain_name}"
      certificate-arn                    = "${data.terraform_remote_state.certificate.outputs.certificate_arn}"
   })
 filename = "${path.module}/../../data/helm/values/spaceone/minikube.yaml"
}

resource "null_resource" "add_spaceone_repo" {
  depends_on = [
    local_file.generate_database,
    local_file.generate_frontend,
    local_file.generate_value,
    local_file.generate_minikube
  ]
  provisioner "local-exec" {
    command = <<EOT
      helm repo add spaceone https://spaceone-dev.github.io/charts --repository-config ${path.module}/../../data/helm/config/repositories.yaml --repository-cache ${path.module}/../../data/helm/cache/repository
      helm repo update --repository-config ${path.module}/../../data/helm/config/repositories.yaml --repository-cache ${path.module}/../../data/helm/cache/repository
      sleep 5
    EOT
  }
}

resource "null_resource" "kubectl_config_set_context" {
  depends_on = [
    null_resource.add_spaceone_repo,
  ]
  provisioner "local-exec" {
    command = "kubectl config set-context --current --namespace spaceone"
  }
}

resource "null_resource" "install_spaceone_with_helm" {
  depends_on = [
    null_resource.kubectl_config_set_context,
  ]
  count = var.enterprise ? 1 : 0
  provisioner "local-exec" {
    command = <<EOT
      helm install spaceone --repository-config ${path.module}/../../data/helm/config/repositories.yaml --repository-cache ${path.module}/../../data/helm/cache/repository \
        -f ${path.module}/../../data/helm/values/spaceone/frontend.yaml \
        -f ${path.module}/../../data/helm/values/spaceone/values.yaml \
        -f ${path.module}/../../data/helm/values/spaceone/database.yaml \
        spaceone/spaceone
    EOT
  }
}

resource "null_resource" "install_spaceone_with_helm_dev" {
  depends_on = [
    null_resource.kubectl_config_set_context,
  ]
  count = var.development ? 1 : 0
  provisioner "local-exec" {
    command = "kubectl config set-context $(kubectl config current-context) --namespace spaceone"
  }
  provisioner "local-exec" {
    command = <<EOT
      helm install spaceone --repository-config ${path.module}/../../data/helm/config/repositories.yaml --repository-cache ${path.module}/../../data/helm/cache/repository \
        -f ${path.module}/../../data/helm/values/spaceone/minikube.yaml \
        spaceone/spaceone
    EOT
  }
}