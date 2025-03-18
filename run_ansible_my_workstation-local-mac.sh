#!/usr/bin/env bash

MY_PASSWORD=""

set -eux
cd ansible || exit

ansible-playbook --skip-tags data --tags mc --diff --extra-vars "ansible_python_interpreter=/usr/bin/python3 ansible_password=${MY_PASSWORD} ansible_become_password=${MY_PASSWORD}" --connection=local -i "127.0.0.1," main.yml | tee -a /tmp/ansible_my_workstation-local.log
