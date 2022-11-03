#!/bin/bash
exec > >(tee -a /var/log/deploy_scripts.log) 2>&1

"""
$ source ${GITS_DIR}/lucius/deploy_scripts/cli_monitor/01_put_cw_metric_filters.sh -l ${lambda_function_name} -m TooManyConnectionsCount -v 1 -f TooManyConnections -p "Too many connections"

#NOTE: Metric Filters are identified by their Namespace and Metric Name.
If you assign a new metric filter with the same namespace and metric name
as an existing metric filter, CloudWatch will replace the existing
metric filter with the new specs, without providing any warnings.
So, if you want to capture the same metric for different lambda functions
with different logstreams, make sure to pass different metric names to them.

https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/CountingLogEventsExample.html
https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/MonitoringPolicyExamples.html
"""
#######################################
# Override above parameters from the command line, if provided
metric_value=1

while [ "$1" != "" ]; do
    case $1 in
        -l | --lambda-function-name )  shift
            lambda_function_name=$1
            ;;
        -m | --metric-name )  shift
            metric_name=$1
            ;;
        -v | --metric-value )  shift
            metric_value=$1
            ;;
        -f | --filter-name )  shift
            filter_name=$1
            ;;
        -p | --filter-pattern )  shift
            filter_pattern=$1
            ;;
    esac
    shift
done

log_group_name=/aws/lambda/${lambda_function_name}
#######################################


#######################################
### Put a CW Metric Filter on an existing logstream
# https://docs.aws.amazon.com/cli/latest/reference/logs/put-metric-filter.html
# CW > Metrics > dinosaur > Metrics with no dimension > TooManyConnections

# metric_name='DuplicateRows'
# metric_value="$.duplicate_rows"
# filter_name='DuplicateRowsCount'
# filter_pattern="{ $.duplicate_rows = * }"
aws logs put-metric-filter \
    --filter-name ${filter_name} \
    --log-group-name ${log_group_name} \
    --filter-pattern "${filter_pattern}" \
    --metric-transformations \
        metricName=${metric_name},metricNamespace=${project_name},metricValue=${metric_value},defaultValue=0
#######################################

#######################################
### Verify that the metric filter was created
aws logs describe-metric-filters \
    --log-group-name ${log_group_name}
#######################################


#######################################
#######################################
#######################################
### Test the CW Metric Filter
# To test the event filter, you can post event data to it.
# https://docs.aws.amazon.com/cli/latest/reference/logs/put-log-events.html
# Note: We must include the sequence token obtained from the response of the previous call.

## Get last sequence token
#log_group_name=test
#logstream_name=testls
#desc_log_stream_resp=$(aws logs describe-log-streams \
#    --log-group-name ${log_group_name} \
#    --log-stream-name-prefix "${logstream_name}"
#    )
#seq_token=$(echo ${desc_log_stream_resp} | jq ".logStreams[].uploadSequenceToken" --raw-output | sed -e 's/"$//' -e 's/^"//')


## put a test log on the log stream
#log_group_name=test
#logstream_name=testls
#seq_token=49585348424535440270070270213341612448923292705340162466
#ts=$(gdate -u +'%s%3N')
# Formatting the log string: https://github.com/aws/aws-cli/issues/2392
#msg="{\"inserted_rows\": 0, \"updated_rows\": 0, \"duplicate_rows\": 49, \"success\": 1}"
#put_log_resp=$(aws logs put-log-events \
#    --log-group-name ${log_group_name} \
#    --log-stream-name ${logstream_name} \
#    --sequence-token ${seq_token} \
#    --log-events \
#        timestamp=${ts},message="'${msg}'"
#    )
#seq_token=$(echo ${put_log_resp} | jq ".nextSequenceToken" --raw-output | sed -e 's/"$//' -e 's/^"//')
#######################################


#######################################
#######################################
#######################################
### Delete a metric filter
#aws logs delete-metric-filter \
#    --log-group-name ${log_group_name} \
#    --filter-name ${filter_name}
#######################################
