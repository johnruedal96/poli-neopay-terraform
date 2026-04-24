resource "aws_cloudwatch_log_group" "producer" {
  name              = "/aws/lambda/neopay-pagos-producer-${var.environment}"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "consumer" {
  name              = "/aws/lambda/neopay-pagos-consumer-${var.environment}"
  retention_in_days = 7
}

resource "aws_cloudwatch_metric_alarm" "producer_errors" {
  alarm_name          = "neopay-producer-errors-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "This metric monitors producer lambda errors"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    FunctionName = var.lambda_producer_name
  }
}

resource "aws_cloudwatch_metric_alarm" "producer_latency_p99" {
  alarm_name          = "neopay-producer-latency-p99-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = 300
  extended_statistic  = "p99"
  threshold           = 2000
  alarm_description   = "This metric monitors producer lambda p99 latency"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    FunctionName = var.lambda_producer_name
  }
}

resource "aws_cloudwatch_metric_alarm" "consumer_errors" {
  alarm_name          = "neopay-consumer-errors-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "This metric monitors consumer lambda errors"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    FunctionName = var.lambda_consumer_name
  }
}

resource "aws_cloudwatch_metric_alarm" "consumer_latency_p99" {
  alarm_name          = "neopay-consumer-latency-p99-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = 300
  extended_statistic  = "p99"
  threshold           = 5000
  alarm_description   = "This metric monitors consumer lambda p99 latency"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    FunctionName = var.lambda_consumer_name
  }
}

resource "aws_cloudwatch_metric_alarm" "sqs_dlq_messages" {
  alarm_name          = "neopay-sqs-dlq-messages-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Alarm when DLQ has messages - indicates processing failures"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    QueueName = "neopay-pagos-dlq-${var.environment}"
  }
}

resource "aws_cloudwatch_metric_alarm" "sqs_queue_age" {
  alarm_name          = "neopay-sqs-oldest-message-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "ApproximateAgeOfOldestMessage"
  namespace           = "AWS/SQS"
  period              = 300
  statistic           = "Maximum"
  threshold           = 300
  alarm_description   = "Alarm when messages are queued for more than 5 minutes"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    QueueName = "neopay-pagos-${var.environment}"
  }
}

resource "aws_cloudwatch_metric_alarm" "lambda_throttle" {
  alarm_name          = "neopay-lambda-throttle-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Throttles"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Alarm when lambda functions are being throttled"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    FunctionName = var.lambda_consumer_name
  }
}

resource "aws_sns_topic" "alerts" {
  name = "neopay-alerts-${var.environment}"
}

resource "aws_sns_topic_subscription" "alerts_email" {
  count     = var.environment == "prod" ? 1 : 0
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

resource "aws_cloudwatch_dashboard" "neopay" {
  dashboard_name = "neopay-${var.environment}"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/Lambda", "Invocations", { stat = "Sum" }],
            [".", "Errors", { stat = "Sum" }],
            [".", "Duration", { stat = "Average" }]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "Lambda Metrics"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/Lambda", "Duration", { stat = "p95" }],
            [".", "Duration", { stat = "p99" }]
          ]
          period = 300
          region = var.aws_region
          title  = "Lambda Latency p95/p99"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/SQS", "ApproximateNumberOfMessagesVisible", { stat = "Maximum" }],
            [".", "ApproximateAgeOfOldestMessage", { stat = "Maximum" }]
          ]
          period = 300
          region = var.aws_region
          title  = "SQS Queue Metrics"
        }
      }
    ]
  })
}