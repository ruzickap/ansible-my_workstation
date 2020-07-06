#!/bin/bash

DESTINATION_IP="192.168.122.197"
MYUSER="pruzicka"
PASSWORD="xxxx"

ansible-playbook --skip-tags printer --diff --user="${MYUSER}" --extra-vars "ansible_password=${PASSWORD} ansible_become_password=${PASSWORD}" -i "${DESTINATION_IP}," main.yml
