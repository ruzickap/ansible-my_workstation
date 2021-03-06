#!/usr/bin/env bash

PASSWORD="my_password"

set -eu
ansible-playbook --skip-tags data,test_data,company --diff --extra-vars "ansible_password=${PASSWORD} ansible_become_password=${PASSWORD}" --connection=local -i "127.0.0.1," main.yml
