#!/usr/bin/env bash


#######################################
### Get a list of logstream names for the current log group
# https://docs.aws.amazon.com/cli/latest/reference/logs/describe-log-streams.html
desc_log_stream_resp=$(aws logs describe-log-streams \
    --log-group-name ${log_group_name} \
    --log-stream-name-prefix "$(date -u '+%Y/%m/%d')"
    )
log_stream_names=$(echo ${desc_log_stream_resp} | jq ".logStreams[].logStreamName" --raw-output | sed -e 's/"$//' -e 's/^"//')

# sort by last event timestamp using jq.
log_stream_names=$(echo ${desc_log_stream_resp} | jq -s -c 'sort_by(.lastEventTimestamp)' | jq '.logStreams[].logStreamName' --raw-output | sed -e 's/"$//' -e 's/^"//')

# this is very inefficient, because we cannot specify prefix
desc_log_stream_resp=$(aws logs describe-log-streams \
    --log-group-name ${log_group_name} \
    --order-by LastEventTime \
    --descending
    )
log_stream_names=$(echo ${desc_log_stream_resp} | jq ".logStreams[].logStreamName" --raw-output | sed -e 's/"$//' -e 's/^"//')
#######################################

