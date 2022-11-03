#!/bin/bash
exec > >(tee -a /var/log/db_deploy_scripts.log) 2>&1


#######################################
export base_name=create_users
export suffix=01

