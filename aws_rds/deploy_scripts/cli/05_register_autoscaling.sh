#!/bin/bash
exec > >(tee -a /var/log/db_deploy_scripts.log) 2>&1

# https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Aurora.Integrating.AutoScaling.html#Aurora.Integrating.AutoScaling.AddCode
export asg_policy_name=rds-asg-scaling-policy-cpu-util-45

#######################################
### (Step 1) register your Aurora DB cluster with Application Auto Scaling
# https://docs.aws.amazon.com/cli/latest/reference/application-autoscaling/register-scalable-target.html
aws application-autoscaling register-scalable-target --service-namespace rds \
    --resource-id cluster:${db_cluster_name} \
    --scalable-dimension rds:cluster:ReadReplicaCount \
    --min-capacity 1 \
    --max-capacity 10


#######################################
### (Step 2) Write the autoscaling policy in a separate JSON file
# https://docs.aws.amazon.com/autoscaling/application/APIReference/Welcome.html


#######################################
### (Step 3) apply the asg policy you created in step 2, to the db cluster you registered in step 1
# https://docs.aws.amazon.com/cli/latest/reference/application-autoscaling/put-scaling-policy.html
# Note: scaling policies are attached to their RDS resources; eg, a db cluster or instance.
# As a result, "PolicyName" attribute (--policy-name parameter) is unique per db instance,
# but can be reused across different resources.
# Also, only one policy type (eg, TargetTrackingScaling) for a given metric specification (eg, CPUUtilization) is allowed.
# As a result, it is OK to use a generic policy name value; it will be made unique when combined with resource id.
aws application-autoscaling put-scaling-policy \
    --policy-name ${asg_policy_name} \
    --resource-id cluster:${db_cluster_name} \
    --cli-input-json file://${GITS_DIR}/db_deployer/mysql/deploy_configs/asg_put_scaling_policy.json


#######################################
### Edit an existing ASG policy
# To edit an existing policy, repeat the "put-scaling-policy" using desired property values.


#######################################
### Verify that the asg policy is created
aws application-autoscaling describe-scaling-policies --service-namespace rds


#######################################
### To delete an autoscaling policy
# https://docs.aws.amazon.com/cli/latest/reference/application-autoscaling/delete-scaling-policy.html
# We need to supply both resource id and policy name, because policies are attached to their rds resources.
# As a result, policy name only has to be unique per resource id.
# Ie, a policy cannot be identified using only policy id.
aws application-autoscaling delete-scaling-policy \
    --policy-name ${asg_policy_name} \
    --resource-id cluster:${db_cluster_name} \
    --service-namespace rds \
    --scalable-dimension rds:cluster:ReadReplicaCount
