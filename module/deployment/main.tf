module "get_aws_secret_key" {
  source = "matti/outputs/shell"

  command = "base64 --decode ../secret/gpg/secret-key | gpg --pinentry-mode loopback --decrypt --batch --passphrase spaceone"
}

resource "kubernetes_namespace" "spaceone" {
  metadata {
    name = "spaceone"
  }
}

resource "kubernetes_namespace" "root_supervisor" {
  metadata {
    name = "root-supervisor"
  }
}

resource "null_resource" "add_spaceone_repo" {
  provisioner "local-exec" {
    command = <<EOT
      helm repo add spaceone https://spaceone-dev.github.io/charts --repository-config ${path.module}/../../data/helm/config/repositories.yaml --repository-cache ${path.module}/../../data/helm/cache/repository
      helm repo update --repository-config ${path.module}/../../data/helm/config/repositories.yaml --repository-cache ${path.module}/../../data/helm/cache/repository
      sleep 5
    EOT
  }
}

resource "local_file" "generate_frontend_yaml" {
  depends_on = [
    kubernetes_namespace.spaceone,
    kubernetes_namespace.root_supervisor
  ]
  count = var.standard ? 1 : 0
  content  =  templatefile("${path.module}/tmpl/frontend.tpl",
    {
      console-api-domain                 = "console-api.${data.terraform_remote_state.certificate[0].outputs.domain_name}"
      console-domain                     = "*.console.${data.terraform_remote_state.certificate[0].outputs.domain_name}"
      certificate-arn                    = "${data.terraform_remote_state.certificate[0].outputs.certificate_arn}"
    })
  filename = "${path.module}/../../data/helm/values/spaceone/frontend.yaml"
}

data "aws_region" "current" {}

resource "local_file" "generate_value_yaml" {
  depends_on = [
    kubernetes_namespace.spaceone,
    kubernetes_namespace.root_supervisor
  ]
  count = var.standard ? 1 : 0
  content  =  templatefile("${path.module}/tmpl/values.tpl",
    {
      aws_access_key_id          = "${data.terraform_remote_state.secret[0].outputs.access_key_id}"
      aws_secret_access_key      = "${module.get_aws_secret_key.stdout}"
      region_name                = "${data.aws_region.current.name}"
      monitoring_domain          = "monitoring.${data.terraform_remote_state.certificate[0].outputs.domain_name}"
      monitoring_webhook_domain  = "monitoring-webhook.${data.terraform_remote_state.certificate[0].outputs.domain_name}"
      certificate-arn            = "${data.terraform_remote_state.certificate[0].outputs.certificate_arn}"
      smpt_host                  = "${var.notification_smpt_host}" 
      smpt_port                  = "${var.notification_smpt_port}"
      smpt_user                  = "${var.notification_smpt_user}"
      smpt_password              = "${var.notification_smpt_password}"
    })
  filename = "${path.module}/../../data/helm/values/spaceone/values.yaml"
}

resource "local_file" "generate_database_yaml" {
  depends_on = [
    kubernetes_namespace.spaceone,
    kubernetes_namespace.root_supervisor
  ]
 count = var.standard ? 1 : 0
 content  =  templatefile("${path.module}/tmpl/database.tpl",
   {
     database_user_name                  = "${data.terraform_remote_state.documentdb[0].outputs.database_user_name}"
     database_user_password              = "${data.terraform_remote_state.documentdb[0].outputs.database_user_password}"
     endpoint                            = "${data.terraform_remote_state.documentdb[0].outputs.endpoint}"
   })
 filename = "${path.module}/../../data/helm/values/spaceone/database.yaml"
}

resource "local_file" "generate_minimal_yaml" {
  depends_on = [
    kubernetes_namespace.spaceone,
    kubernetes_namespace.root_supervisor
  ]
 count = var.minimal ? 1 : 0
 content  =  templatefile("${path.module}/tmpl/minimal.tpl",
  {
      smpt_host                  = "${var.notification_smpt_host}" 
      smpt_port                  = "${var.notification_smpt_port}"
      smpt_user                  = "${var.notification_smpt_user}"
      smpt_password              = "${var.notification_smpt_password}"
  })
 filename = "${path.module}/../../data/helm/values/spaceone/minimal.yaml"
}

resource "helm_release" "install_spaceone" {
  count      = var.standard ? 1 : 0
  depends_on = [
    local_file.generate_frontend_yaml[0],
    local_file.generate_value_yaml[0],
    local_file.generate_database_yaml[0]
  ]
  name       = "spaceone"
  chart      = "spaceone/spaceone"
  namespace  = "spaceone"
  wait       = false // need to modify monitoring scheduler
  
  values = [
    local_file.generate_frontend_yaml[0].content,
    local_file.generate_value_yaml[0].content,
    local_file.generate_database_yaml[0].content
  ]
}

resource "helm_release" "install_spaceone_dev" {
  count      = var.minimal ? 1 : 0
  depends_on = [local_file.generate_minimal_yaml[0]]
  name       = "spaceone"
  chart      = "spaceone/spaceone"
  namespace  = "spaceone"
  
  values = [
    local_file.generate_minimal_yaml[0].content
  ]
}
