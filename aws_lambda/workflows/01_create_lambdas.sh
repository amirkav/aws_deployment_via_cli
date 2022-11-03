#!/bin/bash
exec > >([ -d /tmp/logs ] || mkdir /tmp/logs && tee -a /tmp/logs/lambda-deployer.log) 2>&1
set -ex

### USAGE
# $ source ~/gits/lucius/workflows/01_create_lambdas.sh

source ${GITS_DIR}/tools/bash_tools/bash_helpers.sh

#######################################
export suffix=01
export project_name=thoughtlabs
export env=dev
export base_names=master-uploader,ar-scraper-worker,ar-scraper-orch,ar-scraper-orch,\
dir-scraper,dir-scraper-users-orch,dir-scraper-users-worker,\
dir-scraper,dir-scraper-tokens-orch,dir-scraper-tokens-worker,\
drive-scraper-worker,drive-scraper-users-orch,drive-scraper-files-orch
export repos=uphrates,nicos,sphaerus

# Override above parameters from the command line, if provided
while [ "$1" != "" ]; do
    case $1 in
        -s | --suffix )  shift
            suffix=$1
            ;;
        -p | --project-name )  shift
            project_name=$1
            ;;
        -e | --env )  shift
            env=$1
            ;;
        -b | --base-names )  shift
            base_names=$1
            ;;
    esac
    shift
done
#######################################

#######################################
### PACKAGE CODE AND STORE ON S3
source ${GITS_DIR}/lucius/deploy_scripts/package_code/01_package_lambda_code.sh -r $repos -p lucius -b $base_names

#######################################
## master uploader (triggered by sqs msg)
base_name=master-uploader
source ${GITS_DIR}/lucius/deploy_configs/00_set_env_vars.sh -b $base_name -s $suffix -p $project_name -e $env -t sqs
source ${GITS_DIR}/lucius/deploy_scripts/sam/03_sam_deploy.sh


# Group 1: Event Source Mapping
source ${GITS_DIR}/lucius/deploy_scripts/cli_create/12_create_event_source_mapping.sh -q ${sqs_q_arn_uploader} -l ${lambda_function_name}
source ${GITS_DIR}/lucius/deploy_scripts/cli_create/12_create_event_source_mapping.sh -q ${sqs_rbq_arn_uploader} -l ${lambda_function_name}

# Group 2: Concurrency Management
source ${GITS_DIR}/lucius/deploy_scripts/cli_create/05_put_function_concurrency.sh -l ${lambda_function_name} -c 20

# Group 3: CloudWatch Metrics & Filters
source ${GITS_DIR}/lucius/deploy_scripts/cli_monitor/01_put_cw_metric_filters.sh -l ${lambda_function_name} -m TooManyConnectionsCount-${base_name} -v 1 -f TooManyConnections -p "Too many connections"
source ${GITS_DIR}/lucius/deploy_scripts/cli_monitor/01_put_cw_metric_filters.sh -l ${lambda_function_name} -m LambdaTimeOutCount -v 1 -f TaskTimedOut -p "Task timed out"
source ${GITS_DIR}/lucius/deploy_scripts/cli_monitor/01_put_cw_metric_filters.sh -l ${lambda_function_name} -m DuplicateRowsCount -v "$.duplicate_rows" -f duplicate_rows -p "{ $.duplicate_rows = * }"
source ${GITS_DIR}/lucius/deploy_scripts/cli_monitor/01_put_cw_metric_filters.sh -l ${lambda_function_name} -m InsertedRowsCount -v "$.inserted_rows" -f inserted_rows -p "{ $.inserted_rows = * }"
source ${GITS_DIR}/lucius/deploy_scripts/cli_monitor/01_put_cw_metric_filters.sh -l ${lambda_function_name} -m UpdatedRowsCount -v "$.updated_rows" -f updated_rows -p "{ $.updated_rows = * }"


#######################################
## ar scraper - worker (triggered by sqs msg)
base_name=ar-scraper-worker
source ${GITS_DIR}/lucius/deploy_configs/00_set_env_vars.sh -b $base_name -s $suffix -p $project_name -e $env -t sqs
source ${GITS_DIR}/lucius/deploy_scripts/sam/03_sam_deploy.sh
source ${GITS_DIR}/lucius/deploy_scripts/cli_create/12_create_event_source_mapping.sh -q ${sqs_q_arn_admin_reports} -l ${lambda_function_name}
source ${GITS_DIR}/lucius/deploy_scripts/cli_create/12_create_event_source_mapping.sh -q ${sqs_rbq_arn_admin_reports} -l ${lambda_function_name}
source ${GITS_DIR}/lucius/deploy_scripts/cli_create/05_put_function_concurrency.sh -l ${lambda_function_name} -c 20
source ${GITS_DIR}/lucius/deploy_scripts/cli_monitor/01_put_cw_metric_filters.sh -l ${lambda_function_name} -m ApiUserRateLimitExceeded -f ApiUserThrottle -p "User Rate Limit Exceeded"
source ${GITS_DIR}/lucius/deploy_scripts/cli_monitor/01_put_cw_metric_filters.sh -l ${lambda_function_name} -m ApiRateLimitExceeded -f ApiThrottle -p "Rate Limit Exceeded"

## ar scraper - orchestrator (triggered by CloudWatch Event)
base_name=ar-scraper-orch
source ${GITS_DIR}/lucius/deploy_configs/00_set_env_vars.sh -b $base_name -a drive -s $suffix -p $project_name -e $env -t event
source ${GITS_DIR}/lucius/deploy_scripts/sam/03_sam_deploy.sh
source ${GITS_DIR}/lucius/deploy_scripts/cli_create/05_put_function_concurrency.sh -l ${lambda_function_name} -c 10

# ar token cron event
source ${GITS_DIR}/lucius/deploy_scripts/cli_create/10_create_cloudwatch_event_rule.sh -b ar-scraper-orch -a token  -s $suffix -p $project_name -e $env -l ${lambda_function_name} -c "cron(00 09 * * ? *)"

# ar login cron event
source ${GITS_DIR}/lucius/deploy_scripts/cli_create/10_create_cloudwatch_event_rule.sh -b ar-scraper-orch -a login  -s $suffix -p $project_name -e $env -l ${lambda_function_name} -c "cron(10 09 * * ? *)"

# ar drive cron event
source ${GITS_DIR}/lucius/deploy_scripts/cli_create/10_create_cloudwatch_event_rule.sh -b ar-scraper-orch -a drive -s $suffix -p $project_name -e $env -l ${lambda_function_name} -c "cron(40 09 * * ? *)"


#######################################
## dir scraper (triggered by CloudWatch Event)
base_name=dir-scraper
source ${GITS_DIR}/lucius/deploy_configs/00_set_env_vars.sh -b $base_name -s $suffix -p $project_name -e $env -t event
source ${GITS_DIR}/lucius/deploy_scripts/sam/03_sam_deploy.sh
source ${GITS_DIR}/lucius/deploy_scripts/cli_create/10_create_cloudwatch_event_rule.sh -b $base_name -s $suffix -p $project_name -e $env -a all -l ${lambda_function_name} -c "cron(00 08 * * ? *)"
source ${GITS_DIR}/lucius/deploy_scripts/cli_create/05_put_function_concurrency.sh -l ${lambda_function_name} -c 20
source ${GITS_DIR}/lucius/deploy_scripts/cli_monitor/01_put_cw_metric_filters.sh -l ${lambda_function_name} -m ApiUserRateLimitExceeded -f ApiUserThrottle -p "User Rate Limit Exceeded"
source ${GITS_DIR}/lucius/deploy_scripts/cli_monitor/01_put_cw_metric_filters.sh -l ${lambda_function_name} -m ApiRateLimitExceeded -f ApiThrottle -p "Rate Limit Exceeded"

base_name=dir-scraper-users-worker
source ${GITS_DIR}/lucius/deploy_configs/00_set_env_vars.sh -b $base_name -s $suffix -p $project_name -e $env -t sqs
source ${GITS_DIR}/lucius/deploy_scripts/sam/03_sam_deploy.sh
source ${GITS_DIR}/lucius/deploy_scripts/cli_create/12_create_event_source_mapping.sh -q ${sqs_q_arn_dir_users} -l ${lambda_function_name}
source ${GITS_DIR}/lucius/deploy_scripts/cli_create/12_create_event_source_mapping.sh -q ${sqs_rbq_arn_dir_users} -l ${lambda_function_name}
source ${GITS_DIR}/lucius/deploy_scripts/cli_create/05_put_function_concurrency.sh -l ${lambda_function_name} -c 20
source ${GITS_DIR}/lucius/deploy_scripts/cli_monitor/01_put_cw_metric_filters.sh -l ${lambda_function_name} -m ApiUserRateLimitExceeded -f ApiUserThrottle -p "User Rate Limit Exceeded"
source ${GITS_DIR}/lucius/deploy_scripts/cli_monitor/01_put_cw_metric_filters.sh -l ${lambda_function_name} -m ApiRateLimitExceeded -f ApiThrottle -p "Rate Limit Exceeded"

base_name=dir-scraper-users-orch
source ${GITS_DIR}/lucius/deploy_configs/00_set_env_vars.sh -b $base_name -s $suffix -p $project_name -e $env -t event
source ${GITS_DIR}/lucius/deploy_scripts/sam/03_sam_deploy.sh
source ${GITS_DIR}/lucius/deploy_scripts/cli_create/10_create_cloudwatch_event_rule.sh -b $base_name -s $suffix -p $project_name -e $env -a all -l ${lambda_function_name} -c "cron(20 08 * * ? *)"
source ${GITS_DIR}/lucius/deploy_scripts/cli_create/05_put_function_concurrency.sh -l ${lambda_function_name} -c 10

base_name=dir-scraper-tokens-worker
source ${GITS_DIR}/lucius/deploy_configs/00_set_env_vars.sh -b $base_name -s $suffix -p $project_name -e $env -t sqs
source ${GITS_DIR}/lucius/deploy_scripts/sam/03_sam_deploy.sh
source ${GITS_DIR}/lucius/deploy_scripts/cli_create/12_create_event_source_mapping.sh -q ${sqs_q_arn_dir_tokens} -l ${lambda_function_name}
source ${GITS_DIR}/lucius/deploy_scripts/cli_create/12_create_event_source_mapping.sh -q ${sqs_rbq_arn_dir_tokens} -l ${lambda_function_name}
source ${GITS_DIR}/lucius/deploy_scripts/cli_create/05_put_function_concurrency.sh -l ${lambda_function_name} -c 20
source ${GITS_DIR}/lucius/deploy_scripts/cli_monitor/01_put_cw_metric_filters.sh -l ${lambda_function_name} -m ApiUserRateLimitExceeded -f ApiUserThrottle -p "User Rate Limit Exceeded"
source ${GITS_DIR}/lucius/deploy_scripts/cli_monitor/01_put_cw_metric_filters.sh -l ${lambda_function_name} -m ApiRateLimitExceeded -f ApiThrottle -p "Rate Limit Exceeded"

base_name=dir-scraper-tokens-orch
source ${GITS_DIR}/lucius/deploy_configs/00_set_env_vars.sh -b $base_name -s $suffix -p $project_name -e $env -t event
source ${GITS_DIR}/lucius/deploy_scripts/sam/03_sam_deploy.sh
source ${GITS_DIR}/lucius/deploy_scripts/cli_create/10_create_cloudwatch_event_rule.sh -b $base_name -s $suffix -p $project_name -e $env -a all -l ${lambda_function_name} -c "cron(40 08 * * ? *)"
source ${GITS_DIR}/lucius/deploy_scripts/cli_create/05_put_function_concurrency.sh -l ${lambda_function_name} -c 10


#######################################
## drive scraper - worker (triggered by sqs queue containing list of files)
base_name=drive-scraper-worker
source ${GITS_DIR}/lucius/deploy_configs/00_set_env_vars.sh -b $base_name -s $suffix -p $project_name -e $env -t sqs
source ${GITS_DIR}/lucius/deploy_scripts/sam/03_sam_deploy.sh
source ${GITS_DIR}/lucius/deploy_scripts/cli_create/12_create_event_source_mapping.sh -q ${sqs_q_arn_drive_files} -l ${lambda_function_name}
source ${GITS_DIR}/lucius/deploy_scripts/cli_create/12_create_event_source_mapping.sh -q ${sqs_rbq_arn_drive_files} -l ${lambda_function_name}
source ${GITS_DIR}/lucius/deploy_scripts/cli_create/05_put_function_concurrency.sh -l ${lambda_function_name} -c 20
source ${GITS_DIR}/lucius/deploy_scripts/cli_monitor/01_put_cw_metric_filters.sh -l ${lambda_function_name} -m ApiUserRateLimitExceeded -f ApiUserThrottle -p "User Rate Limit Exceeded"
source ${GITS_DIR}/lucius/deploy_scripts/cli_monitor/01_put_cw_metric_filters.sh -l ${lambda_function_name} -m ApiRateLimitExceeded -f ApiThrottle -p "Rate Limit Exceeded"

## drive scraper - file orchestrator (triggered by sqs queue containing list of users)
base_name=drive-scraper-files-orch
source ${GITS_DIR}/lucius/deploy_configs/00_set_env_vars.sh -b $base_name -s $suffix -p $project_name -e $env -t sqs
source ${GITS_DIR}/lucius/deploy_scripts/sam/03_sam_deploy.sh
source ${GITS_DIR}/lucius/deploy_scripts/cli_create/12_create_event_source_mapping.sh -q ${sqs_q_arn_drive_users} -l ${lambda_function_name}
source ${GITS_DIR}/lucius/deploy_scripts/cli_create/12_create_event_source_mapping.sh -q ${sqs_rbq_arn_drive_users} -l ${lambda_function_name}
source ${GITS_DIR}/lucius/deploy_scripts/cli_create/05_put_function_concurrency.sh -l ${lambda_function_name} -c 10
source ${GITS_DIR}/lucius/deploy_scripts/cli_monitor/01_put_cw_metric_filters.sh -l ${lambda_function_name} -m TooManyConnectionsCount-${base_name} -v 1 -f TooManyConnections -p "Too many connections"

## drive scraper - user orchestrator (triggered by CloudWatch Event)
base_name=drive-scraper-users-orch
source ${GITS_DIR}/lucius/deploy_configs/00_set_env_vars.sh -b $base_name -s $suffix -p $project_name -e $env -t event
source ${GITS_DIR}/lucius/deploy_scripts/sam/03_sam_deploy.sh
source ${GITS_DIR}/lucius/deploy_scripts/cli_create/10_create_cloudwatch_event_rule.sh -b $base_name -s $suffix -p $project_name -e $env -a all -l ${lambda_function_name} -c "cron(00 11 * * ? *)"
source ${GITS_DIR}/lucius/deploy_scripts/cli_create/05_put_function_concurrency.sh -l ${lambda_function_name} -c 10


###
#TODO: Do I need to change this?
set +f
