
# Lambda Scaling & Retry Behavior

## Asynchronous, non-stream events (boto3 invocation)
Asynchronous events are queued before being used
to invoke the Lambda function.
If AWS Lambda is unable to fully process the event,
it will automatically retry the invocation twice,
with delays between retries.
If you have specified a Dead Letter Queue for your function,
then the failed event is sent to the specified
Amazon SQS queue or Amazon SNS topic.
If you don't specify a Dead Letter Queue (DLQ),
which is not required and is the default setting,
then the event will be discarded.

It is recommended to use the Lambda DLQ only in asynchronous invocation.
If you are using Amazon SQS as an event source,
we recommend configuring a DLQ on the Amazon SQS queue itself
and not the Lambda function.
https://docs.aws.amazon.com/lambda/latest/dg/dlq.html


## Synchronous, non-steam event sources (API GW)
The invoking application receives a 429 error and is responsible for retries.


## Poll-based non-stream event sources (SQS Queue)
If you configure an Amazon SQS queue as an event source,
Lambda will poll a batch of records in the queue and
invoke your Lambda function.

If the invocation fails or times out,
every message in the batch will be returned to the queue,
and each will be available for processing once
the Visibility Timeout period expires.
(Visibility timeouts are a period of time
during which SQS prevents other consumers
from receiving and processing the message).

Once an invocation successfully processes a batch,
each message in that batch will be removed from the queue.
When a message is not successfully processed,
it is either discarded or if you have configured
an Amazon SQS Dead Letter Queue,
the failure information will be directed there for you to analyze.

The number of times that Lambda will retry processing a SQS message
depends on the 'maxReceiveCount' parameter of the SQS queue.
Once lambda retrieves the message for retrying after that maxReceiveCount,
the message is sent to DLQ.

Note that the advantage of SQS is that Lambda
will continue to process new messages,
regardless of a failed invocation of a previous message.
In other words, processing of new messages will not be blocked.


### Scaling Behavior
For Lambda functions that process Amazon SQS queues,
Lambda will poll a batch of records in the queue and
invoke your Lambda function.
Therefore, each message batch is considered a single concurrent unit.

AWS Lambda will automatically scale the polling on the queue
until the maximum concurrency level is reached.
The maximum concurrency level can be specified by
'ReservedConcurrentExecutions' parameter in Lambda definition.
The default value for concurrency is 1000.

When an Amazon SQS event source mapping is initially enabled,
Lambda begins long-polling the Amazon SQS queue.
Long polling helps reduce the cost of polling
by reducing the number of empty responses,
while providing optimal processing latency when messages arrive.
As the influx of messages to a queue increases,
AWS Lambda automatically scales up polling activity
until the number of concurrent function executions
reaches max concurrency limit.

SQS supports an initial burst of 5 concurrent function invocations
and increases concurrency by 60 concurrent invocations per minute.


If the default 'Immediate Concurrency Increase' value
is not sufficient to accommodate the traffic surge,
AWS Lambda will continue to increase
the number of concurrent function executions
by 500 per minute until your account safety limit
has been reached or the number of concurrently executing functions
is sufficient to successfully process the increased load.

Because Lambda depends on EC2 to provide Elastic Network Interfaces (ENI)
for VPC-enabled Lambda functions, these functions are also
subject to EC2's rate limits as they scale.
If your EC2 rate limits prevent VPC-enabled functions
from adding 500 concurrent invocations per minute,
request a limit increase to AWS Support.



### Poll-based stream event sources (an ordered queue such as DynamoDB, Kinesis)
When a Lambda function invocation fails,
AWS Lambda attempts to process the erring batch of records
until the time the data expires, which can be up to seven days.

The exception is treated as blocking,
and AWS Lambda will not read any new records
from the shard until the failed batch of records
either expires or is processed successfully.
This ensures that AWS Lambda processes the stream events in order.


### Scaling Behavior
For Lambda functions that process Kinesis or DynamoDB streams,
Lambda processes each shard’s events in sequence.
So, there is no concurrency 'within' a single shard,
but there is concurrency 'across' multiple shards.

Therefore, the number of shards is the unit of concurrency.
If your stream has 100 active shards,
there will be at most 100 Lambda function invocations running concurrently.

**Source**
========
https://docs.aws.amazon.com/lambda/latest/dg/retries-on-errors.html
https://docs.aws.amazon.com/lambda/latest/dg/scaling.html


