enabled: true
image:
    name: pyengine/spacectl
    version: latest
skip_health_check: false
domain: root
main:
  import:
    - /root/spacectl/apply/root_domain.yaml
    - /root/spacectl/apply/domain_role.yaml
    - /root/spacectl/apply/project_role.yaml
    - /root/spacectl/apply/repository.yaml
    - /root/spacectl/apply/schema.yaml
    - /root/spacectl/apply/register_plugins.yaml   
    - /root/spacectl/apply/monitoring.yaml
    - /root/spacectl/apply/statistics.yaml
    - /root/spacectl/apply/plugin_endpoint.yaml
  var:
    domain_name: root
    domain_owner:
      id: ${root_domain_owner}
      password: ${root_domain_owner_password}
    user:
      id: root_api_key
    username: ${username}
    password: ${password}
    consul_server: spaceone-consul-server
    plugin_repo : pyengine
  tasks: []