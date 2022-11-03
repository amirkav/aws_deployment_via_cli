
# Serverless deployment with SAM


## Develop

**Write lambda function python modules**
Step 1: install our dependencies into build folder
#TODO: we dont want to do that, because it will make our Git repo unnecessarily large.
$ pip install -r ${function_path}/deploy_configs/requirements.txt \
    -t ${function_path}/lambda_package/build/

Step 2: copy our application into build folder
$ cp $function_path/lambda_package/*.py ${function_path}/lambda_package/build/


**Write SAM template for lambda function**

https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/transform-aws-serverless.html
https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-lambda-function.html



## Deploy

### Package the lambda function
The "sam package" command is a wrapper for "aws cloudformation package" command.
It packages the code and uploads it to a S3 bucket for us.
This will save us our legacy script '01_put_lambda_package_on_s3.sh'.
Instead of specifying remote code location in our lambda template,
we just need to specify local path for our lambda package.

#TODO: How to change the name of the package file on S3?
The package command returns an AWS SAM template,
in this case packaged.yaml that contains the CodeUri
that points to the deployment zip in the Amazon S3 bucket
that you specified. This template represents your
serverless application. You are now ready to deploy it.
Read:
https://docs.aws.amazon.com/cli/latest/reference/cloudformation/package.html

$ sam package \
    --template-file ${function_path}/deploy_configs/template.yaml \
    --output-template-file $function_path/deploy_configs/template_packaged.yaml \
    --s3-bucket ${s3_bucket} \
    --s3-prefix ${function_name}


### Deploy the lambda function
#TODO: User 'parameter-overrides' to pass on other parameters to this function,
so we can share one template file across all lambda functions.

https://docs.aws.amazon.com/cli/latest/reference/cloudformation/deploy/index.html

$ sam deploy \
    --template-file $function_path/deploy_configs/template_packaged.yaml \
    --stack-name ${stack_name} \
    --s3-prefix ${function_name} \
    --parameter-overrides ParameterKey1=ParameterValue1 ParameterKey2=ParameterValue2 \
    --role-arn ${iam_role_arn} \
    --notification-arns ${notification_arn} \
    --tags TagKey1=TagValue1 TagKey2=TagValue2 \
    --capabilities CAPABILITY_IAM



### Get stack info and API Gateway endpoint
$ aws cloudformation describe-stacks \
    --stack-name ${stack_name} \
    --query 'Stacks[].Outputs'


## Test

### Run unit tests
$ python -m pytest tests/ -v


### Validate SAM template file syntax
Validates the SAM template against SAM Model Specification:
https://github.com/awslabs/serverless-application-model/blob/master/versions/2016-10-31.md
$ sam validate


### Test the API locally
Invoke function locally through local API Gateway
$ sam local start-api -t ${template_path}

Browse to the following address to test the api
http://localhost:3000/hello

If you have set up your lambda function event to the API endpoint,
visiting that API endpoint may start your lambda function locally.

Start local API Gateway in debug mode on port 5858
$ sam local start-api -d 5858

Python requires you to enable remote debugging in your Lambda function code.
If you enable debugging (using the --debug-port or -d options mentioned above)
for a function that uses one of the Python runtimes (2.7 or 3.6),
SAM CLI maps through that port from your host machine to the Lambda container.
To enable remote debugging, use a Python package such as remote-pdb.
https://pypi.org/project/remote-pdb/
When configuring the host, the debugger listens in on your code,
so make sure to use 0.0.0.0 and not 127.0.0.1.


### Generate mock events (payload) for local lambda testing
Generate sample function payloads (for example, an Amazon S3 event).
$ sam local generate-event s3 \
    --bucket bucket-name
    --key key-name \
    > event_file.json

$ sam local generate-event s3
$ sam local generate-event sns
$ sam local generate-event kinesis
$ sam local generate-event dynamodb
$ sam local generate-event api
$ sam local generate-event schedule


### Invoke lambda function locally
Invoking function with event file
$ sam local invoke ${function_name} \
    -e event_file.json  \
    -t ${template_path}

Invoking function with event via stdin
$ echo '{"message": "Hey, are you there?" }' | sam local invoke ${function_name}  -t ${template_path}


To run SAM CLI with debugging support enabled,
specify --debug-port or -d on the command line.
Invoke a function locally in debug mode on port 5858
$ sam local invoke -d 5858 ${function_name}



