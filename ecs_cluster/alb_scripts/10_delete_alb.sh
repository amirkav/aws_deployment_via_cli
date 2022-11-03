#!/bin/bash
exec > >(tee -a /var/log/elb_init.log) 2>&1
source ${VENV_DIR}/bin/activate

# De-register targets
# http://docs.aws.amazon.com/cli/latest/reference/elbv2/deregister-targets.html

# Delete target group
aws elbv2 delete-target-group --target-group-arn ${tg_arn}

# Delete load balancer
aws elbv2 delete-load-balancer --load-balancer-arn ${alb_arn}

# Delete instances associated with the target group
# (deleting a target group does not impact the targets associated with it)
