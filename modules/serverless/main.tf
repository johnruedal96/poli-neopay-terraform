resource "aws_sqs_queue" "pagos_dlq" {
  name = "neopay-pagos-dlq-${var.environment}"
}

resource "aws_sqs_queue" "pagos" {
  name                       = "neopay-pagos-${var.environment}"
  visibility_timeout_seconds = 180
  receive_wait_time_seconds  = 0

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.pagos_dlq.arn
    maxReceiveCount     = 5
  })
}

resource "aws_iam_role" "producer" {
  name = "neopay-pagos-producer-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "producer_logs" {
  role       = aws_iam_role.producer.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "producer_sqs" {
  name = "neopay-producer-sqs-${var.environment}"
  role = aws_iam_role.producer.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["sqs:SendMessage"]
      Resource = aws_sqs_queue.pagos.arn
    }]
  })
}

resource "aws_iam_role" "consumer" {
  name = "neopay-pagos-consumer-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "consumer_logs" {
  role       = aws_iam_role.consumer.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "consumer_vpc" {
  role       = aws_iam_role.consumer.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy" "consumer_sqs" {
  name = "neopay-consumer-sqs-${var.environment}"
  role = aws_iam_role.consumer.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes"
      ]
      Resource = aws_sqs_queue.pagos.arn
    }]
  })
}

resource "aws_apigatewayv2_api" "pagos" {
  name          = "neopay-pagos-api-${var.environment}"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["POST", "OPTIONS"]
    allow_headers = ["content-type", "authorization"]
  }
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.pagos.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_lambda_permission" "apigw_invoke_producer" {
  count         = var.lambda_producer_arn != "" ? 1 : 0
  statement_id  = "AllowInvokeFromHttpApi"
  action        = "lambda:InvokeFunction"
  function_name = split(":", var.lambda_producer_arn)[6]
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.pagos.execution_arn}/*/*"
}

resource "aws_apigatewayv2_integration" "producer" {
  count                  = var.lambda_producer_arn != "" ? 1 : 0
  api_id                 = aws_apigatewayv2_api.pagos.id
  integration_type       = "AWS_PROXY"
  integration_uri        = var.lambda_producer_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "post_pagos" {
  count     = var.lambda_producer_arn != "" ? 1 : 0
  api_id    = aws_apigatewayv2_api.pagos.id
  route_key = "POST /pagos"
  target    = "integrations/${aws_apigatewayv2_integration.producer.id}"
}

resource "aws_lambda_event_source_mapping" "consumer" {
  count            = var.lambda_consumer_arn != "" ? 1 : 0
  event_source_arn = aws_sqs_queue.pagos.arn
  function_name    = var.lambda_consumer_arn
  batch_size       = 5
}