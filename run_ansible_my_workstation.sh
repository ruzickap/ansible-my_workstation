#!/usr/bin/env bash

DESTINATION_IP="172.19.84.75"
MYUSER="pruzicka"
PASSWORD="xxxx"

ansible-playbook --diff --user="${MYUSER}" --extra-vars "ansible_password=${PASSWORD} ansible_become_password=${PASSWORD}" -i "${DESTINATION_IP}," main.yml
