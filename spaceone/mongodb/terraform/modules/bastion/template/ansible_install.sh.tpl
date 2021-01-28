#! /bin/bash
sudo yum update
sudo yum install -y python3 git
sudo pip3 install ansible
sudo pip3 install boto3
sudo mkdir -p /opt/ansible/inventory
sudo mkdir -p /opt/ansible/inventory/group_vars

sudo cat > /opt/ansible/inventory/aws_ec2.yaml << EOF
---
plugin: aws_ec2
regions:
  - ${region}
keyed_groups:
  - key: tags
    prefix: tag
EOF

sudo cat > /opt/ansible/inventory/group_vars/tag_server_type_mongodb << EOF
ansible_ssh_user: ubuntu
ansible_ssh_private_key_file: /root/key/mongodb.pem
EOF

sudo cat > /opt/ansible/inventory/group_vars/tag_server_type_mongodb_bastion << EOF
ansible_ssh_user: ubuntu
ansible_ssh_private_key_file: /root/key/mongodb.pem
EOF

sudo cat > /opt/ansible/inventory/group_vars/tag_rs_type_mongos << EOF
ansible_ssh_user: ubuntu
ansible_ssh_private_key_file: /root/key/mongodb.pem
EOF


sudo mkdir -p /etc/ansible
sudo cat > /etc/ansible/ansible.cfg << EOF
[defaults]
inventory = /opt/ansible/inventory/aws_ec2.yaml
host_key_checking = False
interpreter_python = /usr/bin/python3

[privilege_escalation]
become = true

[inventory]
enable_plugins = aws_ec2
EOF

sudo mkdir -p /root/key
sudo cat > /root/key/mongodb.pem << EOF
${mongodb_ssh_pem}
EOF
sudo chmod 0400 /root/key/mongodb.pem

sudo ansible-galaxy collection install community.mongodb
