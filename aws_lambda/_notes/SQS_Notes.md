# SQS

## Use Queue
#TODO: To reduce the chance of db deadlocks, we can stagger the SQS messages that are sent by scraper functions, by a small random number. For instance, we can add a Time to each outgoing message to stagger the message by a random number between 0-5 seconds.
https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-message-timers.html
https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-send-message-with-timer.html
To do that, change the "DelaySeconds" attribute of boto3's send_message() method.
https://boto3.readthedocs.io/en/latest/reference/services/sqs.html#SQS.Client.send_message

https://docs.aws.amazon.com/lambda/latest/dg/with-sqs.html


## Event-driven serverless architecture with SQS and Lambda
Standard queues vs FIFO queues
Standard queues support at-least-once message delivery, and FIFO queues support exactly-once message processing.

As long as our application can handle duplicates, standard queue is the right fit for us.

https://aws.amazon.com/blogs/aws/aws-lambda-adds-amazon-simple-queue-service-to-supported-event-sources/?sc_icampaign=launch_lambda_sqs&sc_ichannel=ha&sc_icontent=awssm-765&sc_iplace=banner&trk=ha_awssm-765
https://aws.amazon.com/about-aws/whats-new/2018/04/aws-lambda-now-supports-amazon-sqs-as-event-source/
https://read.acloud.guru/event-driven-architecture-with-sqs-and-aws-lambda-cf2ebd529ae3
https://docs.aws.amazon.com/lambda/latest/dg/use-cases.html
https://docs.aws.amazon.com/lambda/latest/dg/with-sqs.html


## SQS and VPC Resources
SQS uses HTTP protocol over the internet.
Furthermore, SQS does not have VPC Endpoint.
So, you must access SQS via internet.
This means that the VPC that you call SQS from must have internet access.
This will be an issue if you are running a lambda function
within a VPC that does not have a NAT Gateway and cannot access internet.
https://stackoverflow.com/questions/35432272/aws-lambda-unable-to-access-sqs-queue-from-a-lambda-function-with-vpc-access



## IAM Policies and Roles for SQS-Lambda
https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-creating-custom-policies-access-policy-examples.html
https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies.html
https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-sqs-policy.html#cfn-sqs-queuepolicy-policydoc
https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/quickref-iam.html#scenario-sqs-policy



## Deploying SQS Queues
We can configure multiple queues as event sources for a single Lambda function,
but an SQS queue can be mapped only to a single Lambda function.
So, we will need at least one SQS queue per uploader lambda.


Two ways to deploy SQS queues:
(a) Create the Q using its own CFN template.
    Then connect it to lambda functions by creating an event source mapping.
    The benefit of this method is that we can also
    grab the Q name and pass it to scraper worker functions.

(b) create the Q at the same CFN as the lambda CFN and
    connect them there using event source mapping resource.
    We still need to grab Q name and pass it to scraper worker functions.



# RESOURCES
Developer guide
https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/welcome.html

API Ref
https://docs.aws.amazon.com/AWSSimpleQueueService/latest/APIReference/Welcome.html

CLI Ref
https://docs.aws.amazon.com/cli/latest/reference/sqs/index.html

boto3 Ref
https://boto3.readthedocs.io/en/latest/reference/services/sqs.html

CloudFormation Ref
https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-sqs-queues.html
