
# AWS SAM
AWS SAM is a wrapper around CloudFormation.
It automates the creation of dependencies for Lambda deployment.

It does that by offering a number of transfomations on the CFN template.
For instance, to add an API Endpoint for our Lambda function,
we simply add the API Endpoint to our Lambda definition.
SAM will automatically transform the CFT to include resources
and settings for the API endpoint to work with the lambda function.


# AWS SAM Local
SAM Local offers a local testing environment for Lambda functions.
Instead of deploying the lambda function on AWS to test it,
we can test our lambda function on our local machine before deploying to cloud.
SAM Local does that by installing a Docker container that
mirrors the AWS Lambda containers on our local machines.



## SAM Local Limitations and Future Dev
We have stopped development on SAM Local templates & scripts until the following two limitations are lifted:
    (a) 'sam local invoke' command to support '--parameter-values' parameter (this limitation was lifted in Oct 2018)
    (b) SAM Local template to support intrinsic functions such as '!Ref', Conditionals, etc.
https://github.com/awslabs/aws-sam-cli/issues/572
https://github.com/awslabs/aws-sam-cli/issues/573

SAM Local is a work in progress, and has some weird behavior.
For instance, setting environmental variables with SAM Local is as follows:
- Define the ENV_VARS inside the SAM Local Template
- Create a env_vars.json file
- Pass the json file reference to the SAM Local Invoke command.
This is in contrast with regular invoke command that simply accepts
env vars as env-vars CLI parameter.


https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/sam-cli-command-reference-sam-deploy.html
https://docs.aws.amazon.com/lambda/latest/dg/deploying-lambda-apps.html
