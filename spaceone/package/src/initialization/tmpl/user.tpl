enabled: true
image:
    name: spaceone/spacectl
    version: 1.8.4
skip_health_check: false
domain: user
main:
  import:
    - /root/spacectl/apply/local_domain.yaml
    - /root/spacectl/apply/statistics.yaml

  var:
    domain_name: ${domain_name}
    domain_owner: ${domain_owner}
    domain_owner_password: ${domain_owner_password}
    project_admin_policy_type: MANAGED
    project_admin_policy_id: ${project_admin_policy_id}
    domain_admin_policy_type: MANAGED
    domain_admin_policy_id: ${domain_admin_policy_id}

  tasks: []
