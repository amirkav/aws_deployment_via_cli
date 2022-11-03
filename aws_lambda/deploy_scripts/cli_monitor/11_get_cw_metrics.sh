#!/bin/bash
exec > >(tee -a /var/log/deploy_scripts.log) 2>&1

#######################################
"""
https://docs.aws.amazon.com/lambda/latest/dg/monitoring-functions-access-metrics.html

## Using AWS CLI
https://docs.aws.amazon.com/cli/latest/reference/cloudwatch/list-metrics.html
https://docs.aws.amazon.com/cli/latest/reference/cloudwatch/get-metric-statistics.html

## Using CloudWatch CLI
https://docs.aws.amazon.com/AmazonCloudWatch/latest/cli/cli-mon-list-metrics.html
https://docs.aws.amazon.com/AmazonCloudWatch/latest/cli/cli-mon-get-stats.html

## List of available metrics
https://docs.aws.amazon.com/lambda/latest/dg/monitoring-functions-metrics.html
https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/lam-metricscollected.html

## Lambda limits:
https://docs.aws.amazon.com/lambda/latest/dg/limits.html
"""
#######################################


#######################################
export lambda_function_name=${project_name}-${env}-lambda-${base_name}-${suffix}
export env=${env}
start_date=$(date -u -v-1d '+%Y-%m-%dT%H:%M:%SZ')
end_date=$(date -u '+%Y-%m-%dT%H:%M:%SZ')

# Override above parameters from the command line, if provided
while [ "$1" != "" ]; do
    case $1 in
        -l | --lambda-function-name )  shift
            lambda_function_name=$1
            ;;
        -e | --env )  shift
            env=$1
            ;;
        -s | --start-time )  shift
            start_time=$1
            ;;
        -n | --end-time )  shift
            end_time=$1
            ;;
    esac
    shift
done
#######################################

#######################################
### Get the list of available metrics
"""
If you dont specify metric-name, it will return all available metrics.
If you want a specific metric (eg, errors), use --metric-name param:
--metric-name 'Errors'

For a list of CloudWatch Metrics:
https://docs.aws.amazon.com/lambda/latest/dg/monitoring-functions-metrics.html
https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/lam-metricscollected.html
"""
list_metrics_resp=$(aws cloudwatch list-metrics \
    --namespace 'AWS/Lambda' \
    --dimensions Name=Resource,Value=${lambda_function_name}:${env}
    )

metric_names=$(echo ${list_metrics_resp} | jq ".Metrics[].MetricName" --raw-output | sed -e 's/"$//' -e 's/^"//')
dimensions_list=$(echo ${list_metrics_resp} | jq ".Metrics[].Dimensions" --raw-output | sed -e 's/"$//' -e 's/^"//')

#######################################
### Get statistics for a metric
"""
The maximum number of data points returned from a single call is 1,440.
If you request more than 1,440 data points, CloudWatch returns an error.
To reduce the number of data points, you can narrow the specified time range
and make multiple requests across adjacent time ranges,
or you can increase the specified period.
Data points are not returned in chronological order.

The time stamp must be in ISO 8601 UTC format (for example, 2016-10-03T23:00:00Z).

--dimensions
Make sure to specify all the dimensions for that metric.
To see all dimensions for a metric, see the result of 'aws clouwatch list-metrics' command above.
https://aws.amazon.com/premiumsupport/knowledge-center/cloudwatch-getmetricstatistics-data/
https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/lam-metricscollected.html

--query
https://stackoverflow.com/questions/40152622/shell-script-sorting-aws-cloudwatch-metrics-json-array-based-on-the-timesta
"""

###################
### Invocations
# Always use "Sum".
# This should correlate with concurrent limit, but will be different from it (because we sum all invocations over a period).
aws cloudwatch get-metric-statistics \
    --namespace 'AWS/Lambda' \
    --metric-name 'Invocations' \
    --dimensions Name=Resource,Value=${lambda_function_name}:${env} Name=FunctionName,Value=${lambda_function_name} \
    --start-time ${start_date} \
    --end-time ${end_date} \
    --period 600 \
    --statistics 'Sum' \
    --unit 'Count' \
    --query 'sort_by(Datapoints,&Timestamp)[*]'


###################
### Errors
# How many invocations resulted in error in the past 24hr
aws cloudwatch get-metric-statistics \
    --namespace 'AWS/Lambda' \
    --metric-name 'Errors' \
    --dimensions Name=Resource,Value=${lambda_function_name}:${env} Name=FunctionName,Value=${lambda_function_name} \
    --start-time ${start_date} \
    --end-time ${end_date} \
    --period 600 \
    --statistics 'Sum' \
    --unit 'Count' \
    --query 'sort_by(Datapoints,&Timestamp)[*]'


###################
### Duration
#TODO: Look for duration of 300000 (time out)
aws cloudwatch get-metric-statistics \
    --namespace 'AWS/Lambda' \
    --metric-name 'Duration' \
    --dimensions Name=Resource,Value=${lambda_function_name}:${env} Name=FunctionName,Value=${lambda_function_name} \
    --start-time ${start_date} \
    --end-time ${end_date} \
    --period 600 \
    --statistics 'Maximum' \
    --unit 'Milliseconds' \
    --query 'sort_by(Datapoints,&Timestamp)[*]'


###################
### Throttles
# It is OK for this to be high. This is the number of 'potential invocations' that were throttled to not exceed concurrent invocations limits.
# https://docs.aws.amazon.com/lambda/latest/dg/concurrent-executions.html#throttling-behavior
aws cloudwatch get-metric-statistics \
    --namespace 'AWS/Lambda' \
    --metric-name 'Throttles' \
    --dimensions Name=Resource,Value=${lambda_function_name}:${env} Name=FunctionName,Value=${lambda_function_name} \
    --start-time ${start_date} \
    --end-time ${end_date} \
    --period 600 \
    --statistics 'Sum' \
    --unit 'Count' \
    --query 'sort_by(Datapoints,&Timestamp)[*]'


###################
# Concurrent executions (entire account)
"""
Emitted as an aggregate metric for all functions in the account,
and for functions that have a custom concurrency limit specified.
Not applicable for versions or aliases.
Measures the sum of concurrent executions
for a given function at a given point in time.

https://docs.aws.amazon.com/lambda/latest/dg/concurrent-executions.html
https://docs.aws.amazon.com/lambda/latest/dg/limits.html
https://docs.aws.amazon.com/lambda/latest/dg/concurrent-executions.html#concurrent-execution-safety-limit
"""
aws cloudwatch get-metric-statistics \
    --namespace 'AWS/Lambda' \
    --metric-name 'ConcurrentExecutions' \
    --start-time ${start_date} \
    --end-time ${end_date} \
    --period 600 \
    --statistics 'Maximum' \
    --unit 'Count' \
    --query 'sort_by(Datapoints,&Timestamp)[*]'


# Concurrent executions for a given lambda (must have maximum concurrency limit configured)
aws cloudwatch get-metric-statistics \
    --namespace 'AWS/Lambda' \
    --metric-name 'ConcurrentExecutions' \
    --dimensions Name=Resource,Value=${lambda_function_name}:${env} Name=FunctionName,Value=${lambda_function_name} \
    --start-time ${start_date} \
    --end-time ${end_date} \
    --period 600 \
    --statistics 'Maximum' \
    --unit 'Count' \
    --query 'sort_by(Datapoints,&Timestamp)[*]'


###################
# UnreservedConcurrentExecutions
"""
Emitted as an aggregate metric for all functions in the account only.
Not applicable for functions, versions, or aliases.
Represents the sum of the concurrency of the functions
that do not have a custom concurrency limit specified.
Must be viewed as an average metric if aggregated across a time period.
"""
aws cloudwatch get-metric-statistics \
    --namespace 'AWS/Lambda' \
    --metric-name 'UnreservedConcurrentExecutions' \
    --start-time ${start_date} \
    --end-time ${end_date} \
    --period 600 \
    --statistics 'Maximum' \
    --unit 'Count' \
    --query 'sort_by(Datapoints,&Timestamp)[*]'


#######################################
### Timeouts (Metric Filter)
#TODO: This does not seem to work for metric filters.
# We can view the metric filter here:
# https://us-west-2.console.aws.amazon.com/cloudwatch/home?region=us-west-2#metricsV2:graph=~(metrics~(~(~'dinosaur~'TooManyConnections~(stat~'Sum)))~view~'timeSeries~stacked~false~region~'us-west-2);namespace=dinosaur;dimensions=
# We can view the test logstream here:
# https://us-west-2.console.aws.amazon.com/cloudwatch/home?region=us-west-2#logEventViewer:group=/aws/lambda/dinosaur-dev-lambda-master-uploader-03;stream=TestLogStream;start=2018-09-22T23:23:50Z
# But we cannot extract metric filter stats using CLI.
start_date=$(date -u -v-1d '+%Y-%m-%dT%H:%M:%SZ')
end_date=$(date -u '+%Y-%m-%dT%H:%M:%SZ')

aws cloudwatch get-metric-statistics \
    --namespace '${project_name}' \
    --metric-name ${metric_name} \
    --start-time ${start_date} \
    --end-time ${end_date} \
    --period 600 \
    --statistics 'Maximum' \
    --unit 'Count' \
    --query 'sort_by(Datapoints,&Timestamp)[*]'
