#!/bin/bash
exec > >(tee -a /var/log/deploy_scripts.log) 2>&1

# https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_Monitoring.html
# https://docs.aws.amazon.com/cli/latest/reference/cloudwatch/put-metric-alarm.html
# https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-cw-alarm.html
# https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/cloudwatch_concepts.html
# https://docs.aws.amazon.com/AmazonCloudWatch/latest/APIReference/API_MetricDatum.html
# https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/lam-metricscollected.html

###################
### JOB NOT RUN Alarm
#TODO: The config json file referenced below is outdated. Write a script to create the config json file dynamically.
aws cloudwatch put-metric-alarm \
    --alarm-name ${lambda_function_name}-CWAlarm-NotRun-${suffix} \
    --cli-input-json file://${GITS_DIR}/lucius/deploy_scripts/cli_create/20_cw_metric_alarm_job_not_run_config.json


### See a list of existing cw alarms to ensure the alarm was created
aws cloudwatch describe-alarms


###################
### Delete an existing alarm
"""
aws cloudwatch delete-alarms --alarm-names ${lambda_function_name}-${env}-cw-alarm-${suffix}
"""

