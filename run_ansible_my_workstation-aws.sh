#!/usr/bin/env bash

DESTINATION_IP="34.207.86.68"
MY_USER="${USERNAME:-${USER}}"
MY_PASSWORD="$(terraform -chdir=terraform output -raw user_password)"
# GitHub token from the laptop's gh, used by "gh skill install" on the remote Mac
GH_TOKEN="$(gh auth token)"
export GH_TOKEN

cd ansible || exit
ansible-playbook --diff --skip-tags data --user="${MY_USER}" --extra-vars "ansible_password=${MY_PASSWORD} ansible_become_password=${MY_PASSWORD}" -i "${DESTINATION_IP}," main.yml
