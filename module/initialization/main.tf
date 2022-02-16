resource "local_file" "generate_root_domain_yaml" {
  content  =  templatefile("${path.module}/tmpl/root.tpl",
    {
     root_domain_owner          = "${var.root_domain_owner}"
     root_domain_owner_password = "${var.root_domain_owner_password}"
    })
  filename = "${path.module}/../../data/helm/values/spaceone-initializer/root.yaml"
}

resource "local_file" "generate_user_main_yaml" {
  content  =  templatefile("${path.module}/tmpl/user.tpl",
    {
     domain_owner                             = "${var.domain_owner}"
     domain_owner_password                    = "${var.domain_owner_password}"
     project_admin_policy_id                  = "${var.project_admin_policy_id}"
     domain_admin_policy_id                   = "${var.domain_admin_policy_id}"
    })
  filename = "${path.module}/../../data/helm/values/spaceone-initializer/user.yaml"
}

resource "helm_release" "create_root_domain" {
  depends_on = [local_file.generate_root_domain_yaml]
  name       = "root-domain"
  chart      = "spaceone/spaceone-initializer"
  namespace  = "spaceone"

  values = [
    local_file.generate_root_domain_yaml.content
  ]
}

resource "null_resource" "delete_root_domain_initializer" {
  depends_on = [helm_release.create_root_domain]
  provisioner "local-exec" {
    interpreter=["/bin/bash", "-c"]
    command = <<EOT
      while true
      do
          status=$(kubectl get pod -n spaceone | grep "initialize-spaceone" | awk '{print $3}')
          if [[ $status =~ Completed ]]; then
              release_name=$(helm list -n spaceone | grep 'spaceone-initializer' | awk '{print $1}')
              if [[ $release_name =~ root-domain ]]; then
                  helm uninstall -n spaceone root-domain
              fi
              break
          else
              echo "Waiting for root domain deletion"
          fi
          sleep 1
      done
    EOT
  }
}

resource "helm_release" "create_user_domain" {
  depends_on = [null_resource.delete_root_domain_initializer]
  name       = "user-domain"
  chart      = "spaceone/spaceone-initializer"
  namespace  = "spaceone"

  values = [
    local_file.generate_user_main_yaml.content
  ]
}

resource "null_resource" "wait_for_user_domain_completed" {
  depends_on = [helm_release.create_user_domain]
  provisioner "local-exec" {
    interpreter=["/bin/bash", "-c"]
    command = <<EOT
      while true
      do
          status=$(kubectl get pod -n spaceone | grep "initialize-spaceone" | awk '{print $3}')
          if [[ $status =~ Completed ]]; then
              release_name=$(helm list -n spaceone | grep 'spaceone-initializer' | awk '{print $1}')
              if [[ $release_name =~ user-domain ]]; then
                  helm uninstall -n spaceone user-domain
              fi
              break
          else
              echo "Waiting for user domain"
          fi
          sleep 1
      done
    EOT
  }
}
