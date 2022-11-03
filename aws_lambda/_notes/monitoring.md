
# Monitoring Lambda functions

Netflix uses a combination of the following
- CloudWatch Metrics
- Sentry
- StreamAlert (Airbnb)
- Skunkworks (Netflix)


## CloudWatch
#Q: How to monitor and alert from the DLQ?
#Q: How to pass logs together with the DLQ notification?


### CloudWatch Metric Filters
To get the number of lambda functions that returned error.


TODO: Add Metric Filter for count of lambda functions that Time out.

- How to know how many lambda executions are getting "Too many connections" error?
https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/MonitoringLogData.html

- CloudWatch Logs Filters: use them to create dashboards to monitor data?

TODO: Monitor the "Duration" metric.
- If a function times out, it should generate an error.
- If durations are too close to 5min, it should generate a notification to chunk the work to smaller pieces.
- If durations are too small (less than 1min), then it should generate a notification to increase chunk size.

TODO: Create CloudWatch Metrics & Filters to identify and report metrics on the following:
- scraper-worker: "API Rate Limit Exceeded"
- uploader: "Too many connections"
- orch-user: "ERROR"
- orch-files: "ERROR"
TODO: Add CW Metric Filters for the above to lambda CFT json.



### Throughput Dashboard
Create a dashboard with the following metrics:
- Lambda concurrent executions
- SQS queue message count
- SQS DLQs message count
- RDS connections count
- "Too many connections" error count
- Lambda throttles count (how many lambda functions are getting throttled because max concurrent executions limit is reached)
- Lambda function durations
- Lambda function timeouts (need Metric Filter for this)

https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/rds-metricscollected.html
https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/sqs-metricscollected.html
https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-monitoring-using-cloudwatch.html
https://forums.aws.amazon.com/thread.jspa?threadID=72613


### CloudWatch Logs & Metrics
TODO: write scripts to process CW Metrics results and make reports. E.g., look at Duration and send a report of how many executions timed out.

There is a trick in the console to zoom in on the error invocation in lambda to help filter the cloudwatch logs to the time of the error

CloudWatch Metrics:
https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring//viewing_metrics_with_cloudwatch.html


## Aurora Monitoring
https://aws.amazon.com/premiumsupport/knowledge-center/troubleshoot-connecting-aurora/



## Sentry
#TODO: the number of ENIs needed to connect VPC-based lambdas to Sentry will be an issue.




## StreamAlert (Airbnb)
StreamAlert (tool from AirBnb) utilizes CloudWatch Logs and Filters for metrics and it seems to work pretty well.




## SkunkWorks (Netflix)
Use skunkworks to emit a CW metric every time we make a request.
https://github.com/Netflix-Skunkworks/cloudaux



## AWS X-Ray
https://docs.aws.amazon.com/lambda/latest/dg/lambda-x-ray.html

TODO: Use X-Ray to monitor metrics such as time spent initializing lambda function (latency),
https://docs.aws.amazon.com/lambda/latest/dg/using-x-ray.html

TODO: configure tracing subsegments inside your lambda handler
https://docs.aws.amazon.com/lambda/latest/dg/python-tracing.html
https://docs.aws.amazon.com/xray/latest/devguide/xray-sdk-python.html
https://docs.aws.amazon.com/xray/latest/devguide/scorekeep-lambda.html

TODO: Use X-Ray to trace downstream HTTP calls
TODO: Can we do this for API Gateway calls??
https://docs.aws.amazon.com/xray/latest/devguide/xray-sdk-java-httpclients.html

TODO: I also want to know how many lambdas were getting "API Rate Limit Exceeded" error at any given moment in time.


## CloudTrail
TODO: Should we use CloudTrail with Lambda??
https://docs.aws.amazon.com/lambda/latest/dg/logging-using-cloudtrail.html
If we specify "data events", CloudTrail captures API calls for AWS Lambda as events.
