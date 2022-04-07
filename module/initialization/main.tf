resource "local_file" "generate_domain_yaml" {
  content  =  templatefile("${path.module}/tmpl/domain.tpl",
    {
     domain_owner          = "${var.domain_owner}"
     domain_owner_password = "${var.domain_owner_password}"
    })
  filename = "${path.module}/../../data/helm/values/spaceone-initializer/domain.yaml"
}

resource "helm_release" "create_domain" {
  depends_on = [local_file.generate_domain_yaml]
  name       = "domain"
  chart      = "spaceone/spaceone-initializer"
  namespace  = "spaceone"

  values = [
    local_file.generate_domain_yaml.content
  ]
}

resource "null_resource" "delete_domain_initializer" {
  depends_on = [helm_release.create_domain]
  provisioner "local-exec" {
    interpreter=["/bin/bash", "-c"]
    command = <<EOT
      while true
      do
          status=$(kubectl get pod -n spaceone | grep "initialize-spaceone" | awk '{print $3}')
          if [[ $status =~ Completed ]]; then
              helm uninstall -n spaceone domain
          else
              echo "Waiting...."
          fi
          sleep 1
      done
    EOT
  }
}