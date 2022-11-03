#!/bin/bash
exec > >(tee -a /var/log/alb_init.log) 2>&1
source ${VENV_DIR}/bin/activate


###################
### Create a listener for the load balancer with a default rule that forwards requests to your target group.
listener_response=$(aws elbv2 create-listener --load-balancer-arn ${alb_arn} --protocol HTTP --port 80  --default-actions Type=forward,TargetGroupArn=${tg_arn})
listener_arn=$(echo $listener_response | jq '.Listeners[0].ListenerArn' | sed -e 's/"$//' -e 's/^"//')

