

# How to handle Lambda Timeout Issue

Look into the following options to resolve this issue:


## Batch Requests
~ Implement batch requests, parallel processing, etc. to reduce run time.


## Instance size
- Use a larger instance. For that, increase the memory size.


## ECS Task (docker)
- Use an EC2 process or ECS task to run the uploader function.
If you use ECS or EC2 instances instead of Lambda,
be sure to make adjustments for the following:
- Use awslogs client to log your code to CloudWatch.
- Use an SNS topic and a separate Lambda function
to stop or delete the cluster after the batch process is done.

https://serifandsemaphore.io/aws-lambda-going-beyond-5-minutes-34e381e71231
https://stackoverflow.com/questions/41225378/how-to-ignore-aws-lambda-timeout-limit-300-seconds-for-long-execution
https://github.com/lambci/docker-lambda
https://github.com/tmaiaroto/node-docker-lambda


## Sharding
Break the process into shards.
Then call a separate Lambda function for each.

I need two Lambda functions: the orchestrator and the worker lambda.
- Orchestrator: get file IDs, shard them into chunks of 200,
and invoke worker lambdas with the list of 200 file IDs.
- Worker: get the list of 200 file IDs, run the uploader on them.

Note that in orchestrator call, we need to set
the parameter InvocationType='Event'
to make sure the invocation is asynchronous.
I.e., the first lambda does not wait for the second lambda to terminate.
In this case, the first function will finish running,
and the callback function will be executed successfully,
while the second function is triggered and can continue execution.

Read:
https://docs.aws.amazon.com/lambda/latest/dg/python-context-object.html
https://docs.aws.amazon.com/sns/latest/dg/sns-lambda.html
http://boto3.readthedocs.io/en/latest/reference/services/lambda.html#Lambda.Client.invoke
https://stackoverflow.com/questions/31714788/can-an-aws-lambda-function-call-another
https://lorenstewart.me/2017/10/02/serverless-framework-lambdas-invoking-lambdas/



## Relaying
Relay the Lambda process to continue the task from where it times out.
AWS Step Functions may be helpful here.

(a) Use boto3 Lambda invoke() function:
http://boto3.readthedocs.io/en/latest/reference/services/lambda.html

(b) Use boto3 SNS to publish an SNS message
with the list of file IDs that are yet to be uploaded,
and have the Lambda function listening on that SNS.

https://stackoverflow.com/questions/31714788/can-an-aws-lambda-function-call-another
https://docs.aws.amazon.com/sns/latest/dg/sns-lambda.html

To know when to kick off the next relay, use Lambda's function: context.getRemainingTimeInMillis()
https://stackoverflow.com/questions/35563949/get-notifications-when-aws-lambda-timesout



## Use Other AWS Services
https://aws.amazon.com/step-functions/
https://aws.amazon.com/batch/


