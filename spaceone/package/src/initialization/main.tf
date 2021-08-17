resource "local_file" "generate_root" {
  content  =  templatefile("${path.module}/tmpl/root.tpl",
    {
     root_domain_owner          = "${var.root_domain_owner}"
     root_domain_owner_password = "${var.root_domain_owner_password}"
     root_domain_username       = "${var.root_domain_username}"
     root_domain_password       = "${var.root_domain_password}"
    })
  filename = "${path.module}/../../outputs/helm/spaceone-initializer/root.yaml"
}

resource "null_resource" "install_spaceone_with_helm" {
  provisioner "local-exec" {
    command = <<EOT
      helm install root-domain \
      -f ${path.module}/../../outputs/helm/spaceone-initializer/root.yaml \
      spaceone/spaceone-initializer
    EOT
  }
}

resource "local_file" "generate_user" {
  content  =  templatefile("${path.module}/tmpl/user.tpl",
    {
     domain_name                              = "${var.domain_name}"
     domain_owner                             = "${var.domain_owner}"
     domain_owner_password                    = "${var.domain_owner_password}"
     oauth_plugin_id                          = "${var.oauth_plugin_id}"
     oauth_plugin_version                     = "${var.oauth_plugin_version}"
     oauth_plugin_domain                      = "${var.oauth_plugin_domain}"
     oauth_plugin_client_id                   = "${var.oauth_plugin_client_id}"
#     project_admin_policy_type                = "${var.project_admin_policy_type}"
#     project_admin_policy_id                  = "${var.project_admin_policy_id}"
#     domain_admin_policy_type                 = "${var.domain_admin_policy_type}"
#     domain_admin_policy_id                   = "${var.domain_admin_policy_id}"
     username                                 = "${var.username}"
     password                                 = "${var.password}"
     aws_cloud_watch_plugin_id                = "${var.aws_cloud_watch_plugin_id}"
     aws_cloud_watch_plugin_version           = "${var.aws_cloud_watch_plugin_version}"
     google_cloud_stackdriver_plugin_id       = "${var.google_cloud_stackdriver_plugin_id}"
     google_cloud_stackdriver_plugin_version  = "${var.google_cloud_stackdriver_plugin_version}"
     azure_monitor_plugin_id                  = "${var.azure_monitor_plugin_id}"
     azure_monitor_plugin_id_plugin_version   = "${var.azure_monitor_plugin_id_plugin_version}"
     aws_hyperbilling_plugin_id               = "${var.aws_hyperbilling_plugin_id}"
     aws_hyperbilling_version                 = "${var.aws_hyperbilling_version}"
    })
  filename = "${path.module}/../../outputs/helm/spaceone-initializer/user.yaml"
}