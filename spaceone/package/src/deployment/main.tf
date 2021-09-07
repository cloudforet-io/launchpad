resource "null_resource" "create_k8s_namespace" {
  provisioner "local-exec" {
    command = <<EOT
        kubectl create ns spaceone
        kubectl create ns root-supervisor
    EOT
  }
}

resource "local_file" "generate_frontend" {
  depends_on = [
    null_resource.create_k8s_namespace
  ]
  count = var.enterprise ? 1 : 0
  content  =  templatefile("${path.module}/tmpl/frontend.tpl",
    {
      console-api-domain                 = "console-api.${data.terraform_remote_state.certificate.outputs.domain_name}"
      console-domain                     = "*.console.${data.terraform_remote_state.certificate.outputs.domain_name}"
      certificate-arn                    = "${data.terraform_remote_state.certificate.outputs.certificate_arn}"
    })
  filename = "${path.module}/../../outputs/helm/spaceone/frontend.yaml"
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
  filename = "${path.module}/../../outputs/helm/spaceone/values.yaml"
}

resource "local_file" "generate_database" {
 count = var.enterprise ? 1 : 0
 content  =  templatefile("${path.module}/tmpl/database.tpl",
   {
     database_user_name                  = "${data.terraform_remote_state.documentdb[0].outputs.database_user_name}"
     database_user_password              = "${data.terraform_remote_state.documentdb[0].outputs.database_user_password}"
     endpoint                            = "${data.terraform_remote_state.documentdb[0].outputs.endpoint}"
   })
 filename = "${path.module}/../../outputs/helm/spaceone/database.yaml"
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
 filename = "${path.module}/../../outputs/helm/spaceone/minikube.yaml"
}

resource "null_resource" "install_spaceone_with_helm" {
  depends_on = [
    null_resource.create_k8s_namespace
  ]
  provisioner "local-exec" {
    command = "kubectl config set-context $(kubectl config current-context) --namespace spaceone"
  }
  provisioner "local-exec" {
    command = <<EOT
      helm repo add spaceone https://spaceone-dev.github.io/charts
      helm repo update
      sleep 5

      if [ $TF_VAR_enterprise = true ]; then
        helm install spaceone \
          -f ${path.module}/../../outputs/helm/spaceone/frontend.yaml \
          -f ${path.module}/../../outputs/helm/spaceone/values.yaml \
          -f ${path.module}/../../outputs/helm/spaceone/database.yaml \
          spaceone/spaceone
      elif [ $TF_VAR_development = true ]; then
        helm install spaceone \
          -f ${path.module}/../../outputs/helm/spaceone/minikube.yaml \
          spaceone/spaceone
      fi
    EOT
  }
}