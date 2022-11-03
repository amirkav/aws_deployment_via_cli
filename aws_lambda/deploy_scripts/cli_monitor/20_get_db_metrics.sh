#!/bin/bash
exec > >(tee -a /var/log/deploy_scripts.log) 2>&1

