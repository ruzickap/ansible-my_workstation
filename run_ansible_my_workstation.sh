#!/bin/bash

DESTINATION_IP="192.168.122.186"
MYUSER="mirantis"
PASSWORD="mirantis"

ansible-playbook --diff --user="${MYUSER}" --extra-vars "ansible_password=${PASSWORD} ansible_become_password=${PASSWORD}" -i "${DESTINATION_IP}," main.yml
