enabled: true
image:
    name: pyengine/spacectl
    version: latest
skip_health_check: false
domain: user
main:
  import:
    - /root/spacectl/apply/local_domain_with_policy.yaml
    - /root/spacectl/apply/monitoring.yaml
    - /root/spacectl/apply/oauth_domain.yaml
    - /root/spacectl/apply/statistics.yaml

  var:
    domain_name: ${domain_name}
    domain_owner: ${domain_owner}
    domain_owner_password: ${domain_owner_password}
    oauth_plugin_id: ${oauth_plugin_id}
    oauth_plugin_version: "${oauth_plugin_version}"
    oauth_plugin_domain: ${oauth_plugin_domain}
    oauth_plugin_client_id: ${oauth_plugin_client_id}
    username: ${username}
    password: ${password}
    aws_cloud_watch_plugin_id: ${aws_cloud_watch_plugin_id}
    aws_cloud_watch_plugin_version: "${aws_cloud_watch_plugin_version}"
    google_cloud_stackdriver_plugin_id: ${google_cloud_stackdriver_plugin_id}
    google_cloud_stackdriver_plugin_version: "${google_cloud_stackdriver_plugin_version}"
    azure_monitor_plugin_id: ${azure_monitor_plugin_id}
    azure_monitor_plugin_id_plugin_version: "${azure_monitor_plugin_id_plugin_version}"
    aws_hyperbilling_plugin_id: ${aws_hyperbilling_plugin_id}
    aws_hyperbilling_version: "${aws_hyperbilling_version}"

  tasks: []
