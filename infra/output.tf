output "api_url" {
  value = aws_apigatewayv2_stage.default.invoke_url
}

output "hello_world_function_name" {
  value = aws_lambda_function.hello_world.function_name
}

output "s3_bucket_arn" {
  value = aws_s3_bucket.html_bucket.arn
}

output "s3_bucket_name" {
  value = aws_s3_bucket.html_bucket.id
}
