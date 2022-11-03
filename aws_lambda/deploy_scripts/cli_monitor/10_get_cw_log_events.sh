#!/bin/bash
#exec > >(tee -a /var/log/deploy_scripts.log) 2>&1

"""
source ${GITS_DIR}/lucius/deploy_scripts/cli_monitor/10_get_cw_log_events.sh
source ${GITS_DIR}/lucius/deploy_scripts/cli_monitor/10_get_cw_log_events.sh -s "2018-09-27T11:10:00Z" -n "2018-09-27T11:30:00Z"
"""

#######################################
export lambda_function_name=${project_name}-${env}-lambda-${base_name}-${suffix}
export env=${env}
start_time_str=""
end_time_str=""

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
            start_time_str=$1
            ;;
        -n | --end-time )  shift
            end_time_str=$1
            ;;
    esac
    shift
done

log_group_name=/aws/lambda/${lambda_function_name}


if [[ ${start_time_str} = "" ]]; then
    start_time=$(gdate -u +'%s%3N')  # current time in millisecs since epoch
    end_time=$(gdate -u -d @$(( $(gdate -u +'%s') - 24*3600)) +'%s%3N')  # yesterday time in millisecs since epoch
else
    start_time=$(gdate -u -d ${start_time_str} +'%s%3N')
    end_time=$(gdate -u -d ${end_time_str} +'%s%3N')
fi

echo start time: $(gdate -u -d @$(($start_time/1000)) '+%Y-%m-%dT%H:%M:%SZ')
echo end time: $(gdate -u -d @$(($end_time/1000)) '+%Y-%m-%dT%H:%M:%SZ')
#######################################

# https://docs.aws.amazon.com/cli/latest/reference/logs/get-log-events.html
# https://docs.aws.amazon.com/cli/latest/reference/logs/filter-log-events.html

###################
# If we dont have a specific log stream name, and only want to use the log group name:
aws logs filter-log-events \
    --log-group-name ${log_group_name} \
    --start-time ${start_time} \
    --end-time ${end_time}
#
##--log-stream-name-prefix "$(date -u '+%Y/%m/%d')"
#
####################
## If we have a specific log stream name:
#aws logs get-log-events \
#    --log-group-name <value> \
#    --log-stream-name <value> \
#    [--start-time <value>] \
#    [--end-time <value>] \
#    [--next-token <value>] \
#    [--limit <value>]



