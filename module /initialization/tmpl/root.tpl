enabled: true
image:
    name: spaceone/spacectl
    version: 1.8.4
skip_health_check: false
domain: root
main:
  import:
    - /root/spacectl/apply/root_domain.yaml 
    - /root/spacectl/apply/marketplace.yaml
  var:
    domain_name: root
    domain_owner:
      id: ${root_domain_owner}
      password: ${root_domain_owner_password}
    user:
      id: root_api_key
    consul_server: spaceone-consul-server
    marketplace_endpoint: grpc://repository.portal.spaceone.dev:50051
  tasks: []