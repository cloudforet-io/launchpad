enabled: true
image:
    name: spaceone/spacectl
    version: 1.9.1
skip_health_check: false
domain: root
main:
  import:
    - /root/spacectl/apply/root_domain.yaml 
    - /root/spacectl/apply/marketplace.yaml
    - /root/spacectl/apply/role.yaml
  var:
    domain_name: root
    default_language: ko
    default_timezone: Asia/Seoul
    domain_owner:
      id: ${root_domain_owner}
      password: ${root_domain_owner_password}
    user:
      id: root_api_key
    consul_server: spaceone-consul-server
    marketplace_endpoint: grpc://repository.portal.spaceone.dev:50051
    project_admin_policy_type: MANAGED
    project_admin_policy_id: policy-managed-project-admin
    project_viewer_policy_type: MANAGED
    project_viewer_policy_id: policy-managed-project-viewer
    domain_admin_policy_type: MANAGED
    domain_admin_policy_id: policy-managed-domain-admin
    domain_viewer_policy_type: MANAGED
    domain_viewer_policy_id: policy-managed-domain-viewer
  tasks: []