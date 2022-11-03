#!/bin/bash
exec > >(tee -a /var/log/deploy_scripts.log) 2>&1

### USAGE
## admin directory
# $ source ~/gits/lucius/workflows/03_invoke_lambdas.sh -p dinosaur -s 06 -e dev -g 0 -l dir-scraper:dir:lucius,dir-scraper-users-orch:dir:lucius,dir-scraper-token-orch:dir:lucius
## admin reports
# $ source ~/gits/lucius/workflows/03_invoke_lambdas.sh -p dinosaur -s 06 -e dev -g 0 -l ar-scraper-orch:drive:lucius,ar-scraper-orch:login:lucius,ar-scraper-orch:token:lucius
## drive
# $ source ~/gits/lucius/workflows/03_invoke_lambdas.sh -p dinosaur -s 08 -e dev -g 0 -l drive-scraper-users-orch:drive:lucius
# $ source ~/gits/lucius/workflows/03_invoke_lambdas.sh -p meerkat -s 04 -e dev -g 0 -l drive-scraper-users-orch:drive:lucius

source ${GITS_DIR}/tools/bash_tools/bash_helpers.sh

#######################################
export suffix=01
export project_name=dinosaur
export env=dev
export lambdas=scrapers,reporters

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
    esac
    shift
done
#######################################

#######################################
#TODO: pass 'max concurrent invocations' as a parameter to this function.
#TODO: If you use stop_lambdas script before running this, concurrent execution limits for all lambdas of a process is set to 20. But, when we run invoke_lambda, we only change the concurrent execition limit of one lamnda to 20. Fix this issue.
invokeLambda () {
    source ${GITS_DIR}/lucius/deploy_configs/00_set_env_vars.sh -b $1 -a $2 -s $3 -p $4 -e $5 -r $6
    source ${GITS_DIR}/lucius/deploy_scripts/cli_create/05_put_function_concurrency.sh -l ${lambda_function_name} -c 20
    source ${GITS_DIR}/lucius/deploy_scripts/cli_invoke/20_invoke_lambda.sh
    echo https://us-west-2.console.aws.amazon.com/cloudwatch/home?region=us-west-2#logs:prefix=/aws/lambda/$3
}
#######################################

#######################################
IFS=',' read -r -a lambdas_array <<< "$lambdas"
for lambda in "${lambdas_array[@]}"
do
    IFS=':' read -r -a l_app_array <<< "$lambda"
    invokeLambda "${l_app_array[0]}" "${l_app_array[1]}" $suffix $project_name $env "${l_app_array[2]}"
done
#######################################
