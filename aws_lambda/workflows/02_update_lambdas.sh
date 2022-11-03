#!/bin/bash
exec > >(tee -a /var/log/deploy_scripts.log) 2>&1

source ${GITS_DIR}/tools/bash_tools/bash_helpers.sh

### USAGE
# $ source ~/gits/lucius/workflows/02_update_lambdas.sh -p meerkat -s 02 -e dev -l ar-scraper-worker:dev:lucius,ar-scraper-orch:dev:lucius -t scraper
# $ source ~/gits/lucius/workflows/02_update_lambdas.sh -p dinosaur -s 03 -e dev -l drive-scraper-users-orch:drive:lucius,drive-scraper-files-orch:drive:lucius,drive-scraper-worker:drive:lucius,master-uploader:all:lucius -t scraper
# $ source ~/gits/lucius/workflows/02_update_lambdas.sh -p dinosaur -s 03 -e dev -l drive-scraper-users-orch:drive:lucius -t scraper
# $ source ~/gits/lucius/workflows/02_update_lambdas.sh -p thoughtlabs -s 02 -e dev -l top-risks:drive:aristo -t reporter
# Format for --lambdas parameter: {base_name}:{application}:{repo},{base_name}:{application}:{repo}
#   Example: drive-scraper-users-orch:drive:lucius
# $ source ~/gits/lucius/workflows/02_update_lambdas.sh -p dinosaur -s 04 -e dev -l drive-scraper-users-orch:drive:lucius,drive-scraper-files-orch:drive:lucius,drive-scraper-worker:drive:lucius,master-uploader:all:lucius -t scraper

#######################################
export suffix=01
export project_name=thoughtlabs
export env=dev
export lambdas=scrapers,reporters
#TODO: codify this
export base_names=master-uploader,ar-scraper-worker,ar-scraper-orch,ar-scraper-orch,\
dir-scraper,dir-scraper-users-orch,dir-scraper-users-worker,\
dir-scraper,dir-scraper-tokens-orch,dir-scraper-tokens-worker,\
drive-scraper-worker,drive-scraper-users-orch,drive-scraper-files-orch,\
file-metrics,top-risks

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
        -l | --lambdas )  shift
            lambdas=$1
            ;;
        -t | --lambda-type )  shift
            lambda_type=$1
            ;;
        -b | --base-names )  shift
            base_names=$1
            ;;
    esac
    shift
done
#######################################

#######################################
updateLambda () {
    source ${GITS_DIR}/lucius/deploy_configs/00_set_env_vars.sh -b $1 -a $2 -s $3 -p $4 -e $5
    source ${GITS_DIR}/lucius/deploy_scripts/cli_update/03_update_lambda_function.sh
    source ${GITS_DIR}/lucius/deploy_scripts/cli_update/05_update_lambda_alias.sh
    source ${GITS_DIR}/lucius/deploy_scripts/cli_create/05_put_function_concurrency.sh -l ${lambda_function_name} -c 20
    #TODO: update event source mapping?? Only if you have changed the name or the alias of the lambda function.
    # source ${GITS_DIR}/lucius/deploy_scripts/cli_update/08_update_event_source_mapping.sh
    # source ${GITS_DIR}/lucius/deploy_scripts/cli_update/07_update_cloudwatch_event_rule.sh
}
#######################################

#######################################
if [ "$lambda_type" = 'scraper' ]; then
    source ${GITS_DIR}/lucius/deploy_scripts/package_code/01_package_lambda_code.sh -r uphrates,nicos,sphaerus -p lucius -b $base_names
fi

if [ "$lambda_type" = 'reporter' ]; then
    source ${GITS_DIR}/lucius/deploy_scripts/package_code/01_package_lambda_code.sh -r sphaerus,aristo -p aristo -b $base_names
fi
#######################################

#######################################
IFS=',' read -r -a lambdas_array <<< "$lambdas"
for lambda in "${lambdas_array[@]}"
do
    echo $lambda
    IFS=':' read -r -a l_app_array <<< "$lambda"
    updateLambda "${l_app_array[0]}" "${l_app_array[1]}" $suffix $project_name $env
done
#######################################
