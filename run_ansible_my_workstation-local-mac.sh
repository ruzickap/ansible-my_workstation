#!/usr/bin/env bash

MY_PASSWORD=""
# GitHub token from the laptop's gh, used by "gh skill install" on the remote Mac
GH_TOKEN="$(gh auth token)"
export GH_TOKEN

set -eux
cd ansible || exit

ansible-playbook --skip-tags data --diff --extra-vars "ansible_password=${MY_PASSWORD} ansible_become_password=${MY_PASSWORD}" --connection=local -i "127.0.0.1," main.yml | tee -a /tmp/ansible_my_workstation-local.log
