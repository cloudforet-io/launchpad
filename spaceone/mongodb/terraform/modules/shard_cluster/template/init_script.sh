#! /bin/bash

sudo mkdir -p /etc/ansible/facts.d
sudo cat > /etc/ansible/facts.d/custom.fact << EOF
[mongodb]
internal_fqdn = ${internal_fqdn}
rs_primary = ${rs_primary}
is_set = false
EOF
