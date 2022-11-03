#!/bin/bash

### USAGE
# $ source ${GITS_DIR}/lucius/deploy_scripts/cli_monitor/31_create_cw_dash_body.sh

cat >${GITS_DIR}/lucius/deploy_scripts/cli_monitor/31_cw_dash_body.json <<EOL
{
    "widgets": [
        {
            "type": "metric",
            "x": 0,
            "y": 0,
            "width": 24,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "AWS/RDS", "DatabaseConnections", "DBClusterIdentifier", "${db_cluster_id}", { "stat": "Maximum", "period": 60 } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "us-west-2",
                "period": 300,
                "title": "DB Connections"
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 6,
            "width": 24,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "${project_name}", "TooManyConnectionsCount", { "stat": "Sum", "period": 60 } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "us-west-2",
                "period": 300,
                "title": "TooManyConnectionsCount"
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 12,
            "width": 24,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "AWS/SQS", "ApproximateNumberOfMessagesVisible", "QueueName", "${sqs_q_name_drive_files}", { "stat": "Sum", "period": 60 } ],
                    [ ".", "ApproximateNumberOfMessagesNotVisible", ".", ".", { "stat": "Sum", "period": 60 } ],
                    [ ".", "ApproximateNumberOfMessagesVisible", ".", "${sqs_q_name_drive_users}", { "stat": "Sum", "period": 60 } ],
                    [ ".", "ApproximateNumberOfMessagesNotVisible", ".", ".", { "stat": "Sum", "period": 60 } ],
                    [ ".", "ApproximateNumberOfMessagesVisible", ".", "${sqs_q_name_uploader}", { "stat": "Sum", "period": 60 } ],
                    [ ".", "ApproximateNumberOfMessagesNotVisible", ".", ".", { "stat": "Sum", "period": 60 } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "us-west-2",
                "period": 300,
                "title": "SQS Q Messages Count"
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 18,
            "width": 24,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "AWS/SQS", "ApproximateNumberOfMessagesVisible", "QueueName", "${sqs_dlq_name_drive_files}", { "stat": "Sum", "period": 60 } ],
                    [ ".", "ApproximateNumberOfMessagesNotVisible", ".", ".", { "stat": "Sum", "period": 60 } ],
                    [ ".", "ApproximateNumberOfMessagesVisible", ".", "${sqs_dlq_name_drive_users}", { "stat": "Sum", "period": 60 } ],
                    [ ".", "ApproximateNumberOfMessagesNotVisible", ".", ".", { "stat": "Sum", "period": 60 } ],
                    [ ".", "ApproximateNumberOfMessagesVisible", ".", "${sqs_dlq_name_uploader}", { "stat": "Sum", "period": 60 } ],
                    [ ".", "ApproximateNumberOfMessagesNotVisible", ".", ".", { "stat": "Sum", "period": 60 } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "us-west-2",
                "period": 300,
                "title": "SQS DLQ Messages Count"
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 24,
            "width": 24,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "AWS/SQS", "ApproximateNumberOfMessagesVisible", "QueueName", "${sqs_rbq_name_drive_files}", { "stat": "Sum", "period": 60 } ],
                    [ ".", "ApproximateNumberOfMessagesNotVisible", ".", ".", { "stat": "Sum", "period": 60 } ],
                    [ ".", "ApproximateNumberOfMessagesVisible", ".", "${sqs_rbq_name_drive_users}", { "stat": "Sum", "period": 60 } ],
                    [ ".", "ApproximateNumberOfMessagesNotVisible", ".", ".", { "stat": "Sum", "period": 60 } ],
                    [ ".", "ApproximateNumberOfMessagesVisible", ".", "${sqs_rbq_name_uploader}", { "stat": "Sum", "period": 60 } ],
                    [ ".", "ApproximateNumberOfMessagesNotVisible", ".", ".", { "stat": "Sum", "period": 60 } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "us-west-2",
                "period": 300,
                "title": "SQS RBQ Messages Count"
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 30,
            "width": 24,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "AWS/Lambda", "Invocations", "FunctionName", "${lambda_name_drive_scraper_files_orch}", { "stat": "Sum", "period": 60 } ],
                    [ "...", "${lambda_name_drive_scraper_users_orch}", { "stat": "Sum", "period": 60 } ],
                    [ "...", "${lambda_name_drive_scraper_worker}", { "stat": "Sum", "period": 60 } ],
                    [ "...", "${lambda_name_master_uploader}", { "stat": "Sum", "period": 60 } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "us-west-2",
                "period": 300,
                "title": "LambdaInvocations"
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 36,
            "width": 24,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "AWS/Lambda", "Duration", "FunctionName", "${lambda_name_master_uploader}", { "period": 60 } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "us-west-2",
                "period": 300,
                "title": "UploaderLambdaDuration"
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 42,
            "width": 24,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "AWS/Lambda", "Errors", "FunctionName", "${lambda_name_master_uploader}", { "stat": "Sum", "period": 60 } ],
                    [ ".", "Throttles", ".", ".", { "stat": "Sum", "period": 60 } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "us-west-2",
                "period": 300,
                "title": "LambdaErrorsThrottles"
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 48,
            "width": 24,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "${project_name}", "LambdaTimeOutCount", { "stat": "Sum", "period": 60 } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "us-west-2",
                "period": 300,
                "title": "LambdaTimeoutCount"
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 54,
            "width": 24,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "${project_name}", "ApiRateLimitExceeded", { "stat": "Sum", "period": 60 } ],
                    [ ".", "ApiUserRateLimitExceeded", { "stat": "Sum", "period": 60 } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "us-west-2",
                "period": 300,
                "title": "G Api Throttle Count"
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 60,
            "width": 24,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "${project_name}", "DuplicateRowsCount", { "stat": "Sum", "period": 60 } ],
                    [ ".", "InsertedRowsCount", { "stat": "Sum", "period": 60 } ],
                    [ ".", "UpdatedRowsCount", { "stat": "Sum", "period": 60 } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "us-west-2",
                "period": 300,
                "title": "SQL Insert Stats"
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 66,
            "width": 24,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "AWS/RDS", "SelectLatency", "DBClusterIdentifier", "${db_cluster_id}", { "period": 300 } ],
                    [ ".", "DDLLatency", ".", "." ],
                    [ ".", "UpdateLatency", ".", "." ],
                    [ ".", "InsertLatency", ".", "." ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "us-west-2",
                "period": 300,
                "title": "DB Latency"
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 72,
            "width": 24,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "AWS/RDS", "NetworkThroughput", "DBClusterIdentifier", "${db_cluster_id}", { "period": 60 } ],
                    [ ".", "DMLThroughput", ".", ".", { "period": 60 } ],
                    [ ".", "SelectThroughput", ".", ".", { "period": 60 } ],
                    [ ".", "CommitThroughput", ".", ".", { "period": 60 } ],
                    [ ".", "NetworkReceiveThroughput", ".", ".", { "period": 60 } ],
                    [ ".", "ActiveTransactions", ".", ".", { "period": 60 } ],
                    [ ".", "UpdateThroughput", ".", ".", { "period": 60 } ],
                    [ ".", "InsertThroughput", ".", "." ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "us-west-2",
                "period": 300,
                "title": "DB Throughput"
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 78,
            "width": 24,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "AWS/RDS", "CPUUtilization", "DBClusterIdentifier", "${db_cluster_id}", { "period": 60 } ],
                    [ ".", "Queries", ".", ".", { "period": 60 } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "us-west-2",
                "period": 300,
                "title": "DB Usage"
            }
        }
    ]
}
EOL
