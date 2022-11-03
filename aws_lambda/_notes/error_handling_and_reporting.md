

# OVERVIEW
There are different ways that a lambda function may break.

**(a) Deployment errors: Problems with lambda deployment**
- Lambda function times out.
- Lambda function does not process input data
These are captured by Lambda itself. Lambda will retry the function
and if all retries are unsuccessful, it will push a notification to DLQ.
We can then have the error handling lambda listen to the DLQ and
troubleshoot the deplyment.

**(b) Programmatic errors: python's codebase errors**
- Codebase errors
These problems are not always straightforward to troubleshoot,
so we cannot simply push them to DLQ and have an error handling
lambda waiting for them.
We need to send push messages to the SNS Topic and have a look at the error message.

**(c) Logical errors: errors with uploading data to db**
- Wrong table name, field name, etc.
These problems are also not always straightforward to troubleshoot.
Again, we send the notification to SNS and have someone take a look at them.


## CloudWatch Alerts and SNS notifications for Lambda jobs
(a) "JOB SUCCEEDED" alert: Write this logic inside the lambda function,
using boto3 to send a message to SNS directly from within Python.
Add some statistics and job summary to the message.

(b) "JOB NOT RUN" alert: Put an alarm on "Invocations"
if invocations count is less than 1 within 1 day (or whatever the job frequency is).
Treat "insufficient data" as "breaching".
This is because Lambda only sends these metrics
to CloudWatch if they have a nonzero value.
admin-directory-lambda-dev-cw-alarm-invoc-02

(c) "JOB FAILED" alert: put an alarm on "Errors"
that sends a notification if count is equal to or greater than 1.
Treat "insufficient data" as "breaching".
Admin-directory-lambda-dev-cw-alarm-error

(d) Dead Letter Queue (DLQ)
When lambda function does not deploy as expected and Lambda retries are also not successful.
We specify a DLQ SNS Topic for the lambda function, and AWS takes care of this.


## ISSUE : Lambda function timeout
Either run it again as is or shard further.

I think a combo of alternatives 1&2 below will work. We need to
Set up a DLQ Topic for the Lambda function to capture Lambda
Deployment and timeout issues. We also need to write logic in
Python to publish to the SNS if the upload was not successful.
If either of these two happens and the Lambda function publishes
To SNS, the lambda function has to run again; or, we can write an
Error handling lambda function that runs the function in safe mode.


### Options for resolution
Our options are explained below.


**####ALTERNATIVE 1: Write an error handling logic for worker lambda python functions**
Add logic to the worker nodes to send notification to SNS with file ids.
Then, add a separate lambda function "error_handler"
that captures the errors, shard them, and send them back to worker nodes.

Dev-BBS-Lambda-SNS-Publish-Policy

Invoking a Lambda function based on SNS notifications:
https://aws.amazon.com/blogs/mobile/invoking-aws-lambda-functions-via-amazon-sns/
https://docs.aws.amazon.com/sns/latest/dg/sns-lambda.html
https://docs.aws.amazon.com/sns/latest/dg/msg-status-topics.html



**ALTERNATIVE 2: Use Dead Letter Queue**
Specify a DLQ for each worker lambda function.
DLQ can be easily linked to a Lambda function that
is called when your function fails.
So, we can attach the worker function to the DLQ,
and pass the file IDs to it.

But, because of the timeout issue,
we still wouldn’t know in which state the function was when it failed.
That is fine because our tables have UNIQUE logic that prevents duplicate data.

You need to explicitly provide receive/delete/sendMessage access
to your DLQ resource as part of the execution role for your Lambda function.
The payload written to the DLQ target ARN is the original event payload with no modifications to the message body.

An error handler can simply parse for the string Task timed out after in the Value attribute, and act accordingly,
such as breaking the request into multiple Lambda invocations, or sending to a different queue
that spins up EC2 instances in an Auto Scaling group for handling larger jobs.


### DLQ & Invocation Type
Note that Lambda retry and DLQ behavior only apply to *asynchronous* execution (invocation-type=Event).
For *synchronous* execution (invocation-type= RequestResponse), the main process
that invoked lambda is responsible for retrying and notification.
https://docs.aws.amazon.com/lambda/latest/dg/dlq.html
https://docs.aws.amazon.com/lambda/latest/dg/invocation-options.html


The console always uses the *RequestResponse* invocation type (synchronous invocation)
when invoking a Lambda function which causes AWS Lambda to return a response immediately.
https://docs.aws.amazon.com/lambda/latest/dg/get-started-create-function.html#get-started-invoke-manually


To manually invoke lambda *asynchronously*, we need to use the CLI, and specify a JSON file as the sample event.
For our applications, where we invoke the lambda function from within our application,
we can create a simple test event. For more complex applications such as an S3 event,
we can use the templates that AWS provides. To see the templates:
- Lambda Console
- from top-right choose "Test"
- choose "create new test event"
- from the "event template" drop-down, choose a template for your test event
- modify the JSON test event.

https://docs.aws.amazon.com/lambda/latest/dg/with-s3-example-upload-deployment-pkg.html#walkthrough-s3-events-adminuser-create-test-function-upload-zip-test-manual-invoke


Reading (DLQ):
https://aws.amazon.com/blogs/compute/robust-serverless-application-design-with-aws-lambda-dlq/
https://medium.com/pageup-tech/lambda-dead-letter-errors-when-you-cant-successfully-fail-ac7cb558188
https://aws.amazon.com/about-aws/whats-new/2016/12/aws-lambda-supports-dead-letter-queues/
https://docs.aws.amazon.com/lambda/latest/dg/dlq.html
https://github.com/aws/aws-lambda-dotnet/issues/123
https://forum.serverless.com/t/dead-letter-queue-and-lambda-how-to-test/4199
https://engineering.opsgenie.com/aws-lambda-performance-series-part-2-an-analysis-on-async-lambda-fail-retry-behaviour-and-dead-b84620af406


**ALTERNATIVE 3: Throw an error, and have Lambda does its retry thing...**
The issue with that is that if it is a timeout,
then there is no way for us to shard it further before retrying.

The other issue is that the Lambda built-in retry
only works for lambda deployment errors;
i.e., errors in deploying the lambda function itself,
not programmatic or logical errors.
A Lambda function can fail for any of the following reasons:
- The function times out while trying to reach an endpoint.
- The function fails to successfully parse input data.
- The function experiences resource constraints, such as out-of-memory errors or other timeouts.

(Reading (retries)
https://stackoverflow.com/questions/30328756/retries-in-aws-lambda
https://medium.com/precogs-tech/precogs-lambda-race-250f349c3641
https://docs.aws.amazon.com/lambda/latest/dg/retries-on-errors.html


## SOLUTION ARCHITECTURE
Use a combination of the above. See the components of the architecture below.


**(a) Internal error handling**
- define an error-handling logic inside the lambda function.
This logic can call other lambda functions using boto3 or throw an error that
lambda can then capture and retry or send the error to DQL.

Boto3 response structure (only applies to orchestrator lambda)
{
  "Payload": "<botocore.response.StreamingBody object at 0x7f291d0a4810>",
  "ResponseMetadata":
    {"RetryAttempts": 0,
    "HTTPStatusCode": 202,
    "RequestId": "78a11692-4d77-11e8-82c6-597c55c700cc",
    "HTTPHeaders": {
      "x-amzn-requestid": "78a11692-4d77-11e8-82c6-597c55c700cc",
      "content-length": "0",
      "x-amzn-trace-id": "root=1-5ae8c29f-71fe93ad792917b9b609a324;sampled=0",
      "x-amzn-remapped-content-length": "0",
      "connection": "keep-alive",
      "date": "Tue, 01 May 2018 19:40:15 GMT"
    }
  },
  "StatusCode": 202
}


See: http://boto3.readthedocs.io/en/latest/reference/services/lambda.html#Lambda.Client.invoke



**(b) Lambda DLQ**
- specify DLQ so that lambda send bad jobs to it.


**(c) Error-handling lambda**
- define an error-handling lambda function that listens to DQL Topic
and is triggered using the payload of the original lambda function
that is sent to DQL using lambda.


**(d) Throw errors**
- when in doubt, throw an error inside the lambda function and let the
lambda function to fail. Lambda will pick up and retry or send to DLQ.



# Testing
**(a) Testing deployment errors**
The issue is that the retry behavior will only kick in
if the lambda function fails at AWS level.
Because we have the lambda function in try...catch block,
the lambda function technically does not fail.
The FAILED alert that we send is sent by program, not by AWS.
So, we need to simulate a deployment failure such as
a Timeout fail, not a programmatic or logical fail.


**(b) Testing programmatic errors**


**(c) Testing logical errors**
