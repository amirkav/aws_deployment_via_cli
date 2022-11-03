#!/bin/bash
exec > >(tee -a /var/log/deploy_scripts.log) 2>&1

source ${GITS_DIR}/tools/bash_tools/bash_helpers.sh

###################
export s3_bucket=bbs-lambda-packages
export s3_key=lambda_compiled_package.zip
export repo='lucius'

# Override the above parameters from the command line, if provided
while [ "$1" != "" ]; do
    case $1 in
        -r | --repos )  shift
            repos=$1
            ;;
        -b | --base-names )  shift
            base_names=$1
            ;;
        -p | --repo )    shift
            repo=$1
            ;;
    esac
    shift
done
IFS=',' read -r -a repos_array <<< "$repos"
###################


###################
export python_dep_dir=/tmp/lambda_python_dependencies
rm /tmp/${s3_key}
rm -rf ${python_dep_dir}
rm -rf ${python_dep_dir}.zip


###################
### install python libraries in the dependency folder
#TODO: To avoid breaking your code, add specific version number to these installs
pip install pytz --upgrade -t ${python_dep_dir}
pip install google_api_python_client --upgrade -t ${python_dep_dir}
pip install oauth2client --upgrade -t ${python_dep_dir}
pip install pymysql --upgrade -t ${python_dep_dir}


###################
### copy Altitude codebase to dependency folder
cp -r ${GITS_DIR}/tools/tools ${python_dep_dir}
cp -r ${GITS_DIR}/diogo/diogo ${python_dep_dir}

# only install repos that were passed by the command line argument and are stored in $repos_array
if elementIn "sphaerus" "${repos_array[@]}" ; then
    cp -r ${GITS_DIR}/sphaerus/sphaerus ${python_dep_dir};
fi;

if elementIn "uphrates" "${repos_array[@]}" ; then
    cp -r ${GITS_DIR}/uphrates/uphrates ${python_dep_dir};
fi;

if elementIn "nicos" "${repos_array[@]}" ; then
    cp -r ${GITS_DIR}/nicos/nicos ${python_dep_dir};
fi;

if elementIn "aristo" "${repos_array[@]}" ; then
    cp -r ${GITS_DIR}/aristo ${python_dep_dir};
fi;


###################
### add python package dependencies to lambda zip package
cd ${python_dep_dir}
zip -ur /tmp/${s3_key} .


###################
### add lambda handler modules to lambda zip package
# https://superuser.com/questions/119649/avoid-unwanted-path-in-zip-file
# zip -urj /tmp/${s3_key} ${GITS_DIR}/lucius/dir_master_scraper/lambda_pkg/*
IFS=',' read -r -a bnames_array <<< "$base_names"
for base_name in "${bnames_array[@]}"
do
    lpath=${GITS_DIR}/${repo}/lambdas/$(echo ${base_name} | tr "-" "_" )
    cd ${lpath}
    zip -ur /tmp/${s3_key} .
done


###################
# Verify the zip folder
zipinfo /tmp/${s3_key}


###################
### upload to s3
aws s3 cp /tmp/${s3_key} s3://${s3_bucket}/${s3_key} --sse "AES256"
