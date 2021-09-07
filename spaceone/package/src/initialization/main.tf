resource "local_file" "generate_root" {
  content  =  templatefile("${path.module}/tmpl/root.tpl",
    {
     root_domain_owner          = "${var.root_domain_owner}"
     root_domain_owner_password = "${var.root_domain_owner_password}"
    })
  filename = "${path.module}/../../outputs/helm/spaceone-initializer/root.yaml"
}

resource "null_resource" "initialize_root_domain" {
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
     project_admin_policy_id                  = "${var.project_admin_policy_id}"
     domain_admin_policy_id                   = "${var.domain_admin_policy_id}"
    })
  filename = "${path.module}/../../outputs/helm/spaceone-initializer/user.yaml"
}


resource "null_resource" "initialize_user_domain" {
  provisioner "local-exec" {
    interpreter=["/bin/bash", "-c"]
    command = <<EOT
      while true
      do
          status=$(kubectl get pod -n spaceone | grep "initialize-spaceone" | awk '{print $3}')
          domain_type=$(helm list | grep '\-domain' | awk '{print $1}')
          if [[ $domain_type =~ root-domain ]] && [[ $status =~ Completed ]]; then
              helm uninstall -n spaceone root-domain
              helm install user-domain \
              -f ${path.module}/../../outputs/helm/spaceone-initializer/user.yaml \
              spaceone/spaceone-initializer
          elif [[ $domain_type =~ user-domain ]] && [[ $status =~ Completed ]]; then
              break
          elif [[ $status =~ Failed|Error ]] ; then
              echo "$(date "+%Y-%m-%d %H:%M:%S") [ERROR] Unable to process user domain creation.\nThe state of the initialization container of the previous user domain is "$status
              exit 1
          fi
          echo "Wait for domain creation to complete...."
          sleep 1
      done
    EOT
  }
}


