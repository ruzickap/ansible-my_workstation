#!/bin/bash -eux

ansible-playbook --diff --connection=local -i "127.0.0.1," main.yml | tee /var/tmp/ansible_my_workstation-local.log
