#!/usr/bin/env bash

PASSWORD="my_password"

set -eu
cd ansible || exit
ansible-playbook --skip-tags data,company --diff --extra-vars "ansible_python_interpreter=/usr/bin/python3 ansible_password=${PASSWORD}" --connection=local -i "127.0.0.1," main.yml
