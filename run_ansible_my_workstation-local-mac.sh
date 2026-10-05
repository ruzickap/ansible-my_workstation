#!/usr/bin/env bash

MY_PASSWORD=""
# GitHub token for "gh skill install" - agent skills are skipped when it is empty
# (e.g. on a fresh Mac where gh is not installed/authenticated yet)
GH_TOKEN="$(gh auth token 2> /dev/null || true)"
export GH_TOKEN

set -eux
cd ansible || exit

ansible-playbook --skip-tags data --diff --extra-vars "ansible_password=${MY_PASSWORD} ansible_become_password=${MY_PASSWORD}" --connection=local -i "127.0.0.1," main.yml | tee -a /tmp/ansible_my_workstation-local.log
