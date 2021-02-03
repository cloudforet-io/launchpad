#!/bin/bash

sudo apt update
sudo apt install -y python3
sudo apt install -y python3-pip

pip3 install --no-input ansible
pip3 install --no-input boto3

sudo ansible-galaxy collection install community.mongodb
