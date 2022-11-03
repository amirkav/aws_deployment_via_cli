#!/bin/bash
exec > >(tee -a /var/log/deploy_scripts.log) 2>&1

#######################################
### Update lambda alias
# After you create a new version for the lambda function,
# update the alias to point to the new version.
# In our 'update-function-code', we create a new version for the lambda by specifying '--publish'.
# So, it is needed that we update the lambda alias to point to the newly-created version.

aws lambda update-alias \
    --region us-west-2 \
    --function-name ${lambda_function_name} \
    --function-version ${lambda_function_version} \
    --name ${env} \
    --profile ${profile_user}

