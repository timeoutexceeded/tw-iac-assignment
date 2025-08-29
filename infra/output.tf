output "api_url" {
  value = aws_apigatewayv2_stage.default.invoke_url
}

output "hello_world_function_name" {
  value = aws_lambda_function.hello_world.function_name
}