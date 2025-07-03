#!/bin/bash

#using ansible -pull based because no need additional step of ansible control server creation and connecting to node instances.
# Thats why installing ansible and using ansible-pull automatically fetch the code from github and execute ansible roles
dnf install ansible -y
ansible-pull -U https://github.com/JohnsonQA/ansible-roboshop-roles-tf.git -e component=$1 -e env=$2 main.yaml