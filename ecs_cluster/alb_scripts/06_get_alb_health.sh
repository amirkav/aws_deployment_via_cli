#!/bin/bash
exec > >(tee -a /var/log/elb_init.log) 2>&1
source ${VENV_DIR}/bin/activate

# Check the health of the target group
aws elbv2 describe-target-health --target-group-arn ${tg_arn}


# ALB troubleshooting:
# https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-troubleshooting.html
