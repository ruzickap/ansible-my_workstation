#!/usr/bin/env bash

MY_PASSWORD=""

set -eux
cd ansible || exit

# ansible-playbook --skip-tags data,company --diff --extra-vars "ansible_python_interpreter=/usr/bin/python3 ansible_password=${MY_PASSWORD}" --connection=local -i "127.0.0.1," main.yml
ansible-playbook --step --start-at-task="Create directory for mc inside ~/.config" --skip-tags data,company --diff --extra-vars "ansible_python_interpreter=/usr/bin/python3 ansible_password=${MY_PASSWORD}" --connection=local -i "127.0.0.1," main.yml
