#!/bin/bash
exec > >(tee -a /var/log/db_deploy_scripts.log) 2>&1

# https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_Monitoring.html
# https://docs.aws.amazon.com/cli/latest/reference/cloudwatch/put-metric-alarm.html
# https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-cw-alarm.html

cd ${GITS_DIR}/db_deployer/mysql/deploy_scripts


#######################################
### See a list of existing cw alarms
aws cloudwatch describe-alarms


#######################################
### Create a new alarm
aws cloudwatch put-metric-alarm --alarm-name cw-metric-alarm-${db_instance_name} \
    --dimensions "Name=DBInstanceIdentifier,Value=${db_instance_name}" \
    --cli-input-json file://${GITS_DIR}/db_deployer/mysql/deploy_configs/put_cw_metric_alarm.json


#######################################
### Delete an existing alarm
aws cloudwatch delete-alarms --alarm-names micro-db-instance-cpu-usage-2
