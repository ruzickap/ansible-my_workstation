#!/usr/bin/env bash

DESTINATION_IP="$(tofu -chdir=terraform output -raw public_ip)"
MY_USER="${USERNAME:-${USER}}"
MY_PASSWORD="$(tofu -chdir=terraform output -raw user_password)"
# GitHub token from the laptop's gh, used by "gh skill install" on the remote Mac
GITHUB_TOKEN="$(gh auth token)"
export GITHUB_TOKEN

cd ansible || exit
ansible-playbook --diff --skip-tags data --user="${MY_USER}" --extra-vars "ansible_password=${MY_PASSWORD} ansible_become_password=${MY_PASSWORD}" -i "${DESTINATION_IP}," main.yml
