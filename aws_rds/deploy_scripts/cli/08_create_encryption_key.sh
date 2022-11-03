#!/bin/bash
exec > >(tee -a /var/log/db_deploy_scripts.log) 2>&1

# https://docs.aws.amazon.com/cli/latest/reference/kms/create-key.html
# https://docs.aws.amazon.com/cli/latest/reference/kms/create-alias.html
# https://docs.aws.amazon.com/kms/latest/developerguide/create-keys.html
# https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-kms-key.html#w2ab2c21c10d834c11
# https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-kms-alias.html

#TODO: We also need to add permissions to use and to administer the key.

kms_response=$(aws kms create-key \
    --description="Encryption key for project ${project_name}")

key_id=$(echo $kms_response | jq '.KeyMetadata .KeyId' | sed -e 's/"$//' -e 's/^"//')

aws kms create-alias \
    --alias-name alias/${project_name}_${env}_encryptionkey_${suffix} \
    --target-key-id ${key_id}
