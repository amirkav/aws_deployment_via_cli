#!/bin/bash
exec > >(tee -a /var/log/deploy_scripts.log) 2>&1

#######################################
### Delete existing Lambda function
# If you want to delete the function, including all its versions, and any aliases pointing to the function versions:
aws lambda delete-function --function-name test_scheduled_event


# If you want to delete a specific version:
# You can delete any function version but not the $LATEST ,
# that is, you cannot specify $LATEST as the value of this parameter.
# The $LATEST version can be deleted only when you want to delete all the function versions and aliases.
# You can only specify a function version, not an alias name, using this parameter.
# You cannot delete a function version using its alias.

aws lambda delete-function \
    --function-name ${lambda_function_name} \
    --qualifier ${lambda_function_version}
