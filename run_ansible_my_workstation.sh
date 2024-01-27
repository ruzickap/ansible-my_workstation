#!/usr/bin/env bash

DESTINATION_IP="172.19.84.75"
MY_USER="pruzicka"
MY_PASSWORD=""

cd ansible || exit
ansible-playbook --diff --user="${MY_USER}" --extra-vars "ansible_password=${MY_PASSWORD} ansible_become_password=${MY_PASSWORD}" -i "${DESTINATION_IP}," main.yml # DevSkim: ignore DS162092
