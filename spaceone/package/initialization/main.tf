resource "local_file" "generate_root" {
  content  =  templatefile("${path.module}/tmpl/root.tpl",
    {
     root_domain_owner          = "${var.root_domain_owner}"
     root_domain_owner_password = "${var.root_domain_owner_password}"
     username                   = "${var.username}"
     password                   = "${var.password}"
    })
  filename = "${path.module}/yaml/root.yaml"
}

resource "local_file" "generate_user" {
  count    =  var.domain_count
  content  =  templatefile("${path.module}/tmpl/user.tpl",
    {
     domain_name                              = "${var.domain_name}-${count.index}"
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
  filename = "${path.module}/yaml/user${count.index}.yaml"
}

resource "helm_release" "spaceone-initializer" {
  name              = "root-domain"
  repository        = "https://spaceone-dev.github.io/charts"
  chart             = "spaceone-initializer"
  namespace         = "spaceone"

  values = [
    local_file.generate_root.content
  ]
}
