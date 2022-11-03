# AWS Lambda - SQS integration


## Set up queue
Follow these best practices:
https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-best-practices.html

SQS Limits:
https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-limits.html


## Dead-Letter Queue
- When the ReceiveCount for a message exceeds the maxReceiveCount for a queue, Amazon SQS moves the message to a dead-letter queue.
- Remember how SQS polls message: SQS distributes messages across distributed servers. As a result, when we poll the messages, SQS will propagate the receive command across all servers. The receive command may take some time to reach all the servers; therefore, we may see the receive counts increase with time (for a limited time after the initial poll).
Also, SQS stores messages on multiple servers, so as the poll propagates through the servers, we may get more than one receive count for each time we poll.

The idea is to delete the message after receiving it. If we don't delete the message, it means something had gone wrong. DLQ will keep track of those messages so we can fix the problem.
Note: Lambda functions automatically delete the msg after consuming it.

https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-dead-letter-queues.html

- Best Practice: set the retention period of a dead-letter queue to be longer than the retention period of the original queue.


## Visibility Timeout
- For standard queues, the visibility timeout isn't a guarantee against receiving a message twice.
- Set the visibility timeout to the maximum time that it takes your application to process and delete a message from the queue.
- For a SQS queue to trigger a lambda function, its Visibility Timeout must be at least equal or greater than the lambda function timeout.



## Receiving and deleting messages
An Amazon SQS message has three basic states:
1. Sent to a queue by a producer,
2. Received from the queue by a consumer, and
3. Deleted from the queue. A message is considered to be in flight after it is received from a queue by a consumer, but not yet deleted from the queue (that is, between states 2 and 3).

- There is no limit to the number of messages in a queue which are between states 1 and 2. So, a SQS queue can have as many messages as desired.
- For standard queues, there can be a maximum of 120,000 inflight messages (received from a queue by a consumer, but not yet deleted from the queue). If you reach this limit, Amazon SQS returns the OverLimit error message. To avoid reaching the limit, you should delete messages from the queue after they're processed.



## IAM Roles & Policies
Note that we can use either IAM or SQS resource-based policies to control permission to SQS.

~ To configure Lambda function triggers using the console, you must ensure the following:

(a) Your Amazon SQS role must include the following permissions:
lambda:CreateEventSourceMapping
lambda:ListEventSourceMappings
lambda:ListFunctions

~ created: BBS-Dev-SQS-LambdaTrigger-Policy
~ Create an IAM Role for SQS and attach the Policy above to it. Note that SQS uses its own resource-based permission system, which is similar to IAM system but is separately managed.
https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-authentication-and-access-control.html
https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-sqs-policy.html

(b) Your Lambda role must include the following permissions:
sqs:ChangeMessageVisibility
sqs:DeleteMessage
sqs:GetQueueAttributes
sqs:ReceiveMessage
sqs:SendMessage

~ created: BBS-Dev-Lambda-Services-Policy
NOTE: I removed "BBS-Dev-Developer" policy from "BBS-Dev-Lambda-VPC-Execution-Role" and added "BBS-Dev-Lambda-Services-Policy" to it. Test the lambda functions after this change to make sure it does not break them.



Note: in my local development (using my laptop), boto3 uses my credentials (IAM User 'amir') to send a message to the SQS queue. But when the lambda function is running from AWS lambda, it uses Lambda Execution Role. so, don't forget to add the following to Lambda Execution role.
Even when I invoke the lambda function using CLI commands, I use the parameter "--user=amir" which runs the lambda function with my user. But, I need to run it using "BBS-Dev-Lambda-VPC-Execution-Role".

~ Add lambda triggering permissions to "RolesBBS-Dev-Lambda-VPC-Execution-Role".

https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-overview-of-managing-access.html
https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-using-identity-based-policies.html
https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-api-permissions-reference.html



## Use Queue

NOTE:
- Lambda automatically retrieves messages and directs them to target lambda function.
- Lambda automatically deletes the messages after using them.
Note: Do not add graceful failing to your Lambda functions. If your lambda function retrieves a message and fails in handling it, lambda will delete the SQS message even if the message was not properly handled.
#TODO: When using Amazon SQS as an event source, configure a DLQ on the Amazon SQS queue itself and not the Lambda function.
https://docs.aws.amazon.com/lambda/latest/dg/with-sqs.html
