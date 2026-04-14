output "api_invoke_url" {
  description = "URL base del HTTP API (POST /pagos)"
  value       = aws_apigatewayv2_stage.default.invoke_url
}

output "api_id" {
  value = aws_apigatewayv2_api.pagos.id
}

output "sqs_queue_url" {
  value = aws_sqs_queue.pagos.url
}

output "sqs_queue_arn" {
  value = aws_sqs_queue.pagos.arn
}

output "lambda_producer_name" {
  description = "Nombre de lambda producer para deploy desde GitHub Actions"
  value       = var.lambda_producer_name
}

output "lambda_producer_arn" {
  description = "ARN de lambda producer"
  value       = local.producer_arn
}

output "lambda_consumer_name" {
  description = "Nombre de lambda consumer para deploy desde GitHub Actions"
  value       = var.lambda_consumer_name
}

output "lambda_consumer_arn" {
  description = "ARN de lambda consumer"
  value       = local.consumer_arn
}