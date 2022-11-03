#!/bin/bash
exec > >(tee -a /var/log/deploy_scripts.log) 2>&1

#######################################
#TODO: put these into a configs.yml file, and put the rest of the script into a devops-only script (low priority)
export base_name=master-uploader
export suffix=01
export project_name=thoughtlabs
export env=dev
export lambda_job_type=worker
export repo='lucius'
export invocation_type='sqs'

# Override the above parameters from the command line, if provided
while [ "$1" != "" ]; do
    case $1 in
        -b | --base_name )      shift
            base_name=$1
                                ;;
        -s | --suffix )         shift
            suffix=$1
                                ;;
        -p | --project_name )   shift
            project_name=$1
                                ;;
        -e | --env )            shift
            env=$1
                                ;;
        -a | --application )    shift
            application=$1
                                ;;
        -r | --repo )    shift
            repo=$1
                                ;;
        -t | --invocation-type )    shift
            export invocation_type=$1
                                ;;
    esac
    shift
done
#######################################

#TODO: move these scripts to a separate devops-only repo (low priority)
export stack_name=${project_name}-${env}-${base_name}-${suffix}
export lambda_function_name=${project_name}-${env}-lambda-${base_name}-${suffix}
export handler=$(echo ${base_name} | tr "-" "_" )_handler.main_handler

export subnet_ids=$(cat ${CONF_DIR}/config.json | jq ".${project_name}.subnets_private" --raw-output | sed -e 's/"$//' -e 's/^"//')
export subnet_id=$(echo $subnet_ids | cut -d',' -f1)

export sg_ids_publ=$(cat ${CONF_DIR}/config.json | jq ".${project_name}.security_group_public" --raw-output | sed -e 's/"$//' -e 's/^"//')
export sg_ids_priv=$(cat ${CONF_DIR}/config.json | jq ".${project_name}.security_group_private" --raw-output | sed -e 's/"$//' -e 's/^"//')
export sg_ids_wtls=$(cat ${CONF_DIR}/config.json | jq ".${project_name}.security_group_whitelist" --raw-output | sed -e 's/"$//' -e 's/^"//')
export sg_ids=${sg_ids_publ}','${sg_ids_priv}','${sg_ids_wtls}

export sns_topic_name=${project_name}-${env}-sns-${base_name}-${suffix}
export sns_dlq_topic_name=${project_name}-${env}-snsdlq-${base_name}-${suffix}
export notification_endpoint=devops@altitudenetworks.com
export owner_contact=amir@altitudenetworks.com

export lambda_exec_role=arn:aws:iam::474602133305:role/BBS-Dev-Lambda-VPC-Execution-Role
export profile_user=BBS-Dev-Developer-Role

export lambda_path=${GITS_DIR}/lucius/lambdas/$(echo ${base_name} | tr "-" "_" )
export deploy_configs_path=${GITS_DIR}/lucius/deploy_configs

export gdpr_compliant=$(cat ${CONF_DIR}/config.json | jq ".${project_name}.gdpr" --raw-output | sed -e 's/"$//' -e 's/^"//')
export filter_for_sensitive_parents=$(cat ${CONF_DIR}/config.json | jq ".${project_name}.filter_for_sensitive_parents" --raw-output | sed -e 's/"$//' -e 's/^"//')
if [ "${gdpr_compliant}" == "1" ]; then
    echo 'GDPR compliance turned on'
else
    echo 'GDPR compliance turned off'
fi


# get sqs queues url and arn
#TODO: add rbq base names to this
export qtypes=uploader,drive-users,drive-files,admin-reports,dir-users,dir-tokens
IFS=',' read -r -a qtypes_array <<< "$qtypes"
list_qs_response=$(aws sqs list-queues --queue-name-prefix ${project_name}-${env})
for qtype in "${qtypes_array[@]}"
do
    echo $qtype
    # get original q details
    list_qs=$(echo $list_qs_response | jq '.QueueUrls'[] | grep $qtype-q)
    export sqs_q_url=$(echo $list_qs | tr " " "\n" | sort -n | tail -1 | sed -e 's/"$//' -e 's/^"//')
    export sqs_q_url_$(echo ${qtype} | tr "-" "_" )=${sqs_q_url}
    export sqs_q_arn_$(echo ${qtype} | tr "-" "_" )=$(aws sqs get-queue-attributes --queue-url $sqs_q_url --attribute-names QueueArn | jq '.Attributes.QueueArn' | sed -e 's/"$//' -e 's/^"//')
    # get rbq details
    list_qs=$(echo $list_qs_response | jq '.QueueUrls'[] | grep $qtype-rbq)
    export sqs_rbq_url=$(echo $list_qs | tr " " "\n" | sort -n | tail -1 | sed -e 's/"$//' -e 's/^"//')
    export sqs_rbq_url_$(echo ${qtype} | tr "-" "_" )=${sqs_rbq_url}
    export sqs_rbq_arn_$(echo ${qtype} | tr "-" "_" )=$(aws sqs get-queue-attributes --queue-url $sqs_rbq_url --attribute-names QueueArn | jq '.Attributes.QueueArn' | sed -e 's/"$//' -e 's/^"//')
done


#######################################
### Update VPC configs json file for the current project and env
cat >${deploy_configs_path}/vpc_configs.json <<EOL
{
  "SubnetIds": ["$(echo $subnet_ids | cut -d',' -f1)", "$(echo $subnet_ids | cut -d',' -f2)"],
  "SecurityGroupIds": ["${sg_ids_publ}", "${sg_ids_priv}", "${sg_ids_wtls}"]
}
EOL



#######################################
########### SET ENV VARS ##############
#######################################
# NOTE: We have env vars in three places:
# (a) env_vars bash variable (here) which we pass to 'aws lambda create-function'.
#     This is needed for CLI-based deployment (not using CloudFormation).
# (b) env_vars.json file that we pass to 'sam local invoke'.
#     This is used to override the env vars defined in the template.
# (c) Inside the CFT (Resources>LambdaFunction>Properties>Environment>Variables)
#     This is just for SAM Local's use. SAM Local only parses environment variables
#     that are defined in the SAM template. If you want to override these env vars,
#     provide an env_vars.json file. But SAM Local will only override
#     those variables that were already declared in the CFT.
#     This is a known bug and will probably be fixed in future releases of SAM Local.

###################
### (a) env_vars to pass to cli parameters
export env_vars="{VENV_DIR=/tmp/venv,\
DATA_DIR=/tmp/data,\
GITS_DIR=/tmp/gits,\
CONF_DIR=/tmp/.credentials,\
PROJECT_NAME=${project_name},\
ENV=${env}}"

###################
### (b) Create Env Vars JSON file for SAM Local
#TODO: Remove this after SAM Local supports passing on env vars in the invoke command line
cat >${deploy_configs_path}/env_vars.json <<EOL
{
    "VENV_DIR": "/tmp/venv",
    "DATA_DIR": "/tmp/data",
    "GITS_DIR": "/tmp/gits",
    "CONF_DIR": "/tmp/.credentials",
    "ENV": "${env}",
    "PROJECT_NAME": "${project_name}"
}
EOL

###################
### (c) inside CFT
#TODO: See "Resources > LambdaFunction > Environment > Variables"


#######################################
######### CREATE TEST EVENTS ##########
#######################################
#TODO: Move this section to its own script, dedicated to testing.

###################
