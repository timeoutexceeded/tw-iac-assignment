resource "aws_iam_role" "lambda_exec" {
     name = "${var.prefix}-hello-world-role"

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

resource "aws_iam_role_policy_attachment" "lambda_logs" {
     role       = aws_iam_role.lambda_exec.name
     policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "archive_file" "lambda_zip" {
     type        = "zip"
     source_dir  = "${path.module}/../src/lambda/"
     output_path = "${path.module}/build/hello-world.zip"
}

resource "aws_lambda_function" "hello_world" {
     function_name = "${var.prefix}-hello-world"
     runtime       = "nodejs18.x"
     role          = aws_iam_role.lambda_exec.arn
     handler       = "hello-world.handler"
     filename      = data.archive_file.lambda_zip.output_path
}

resource "local_file" "env_file" {
  content  = "API_URL=${aws_apigatewayv2_api.http_api.api_endpoint}"
  filename = "${path.module}/.env"
}

resource "aws_apigatewayv2_api" "http_api" {
     name          = "${var.prefix}-hello-world-api"
     protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
     api_id                  = aws_apigatewayv2_api.http_api.id
     integration_type        = "AWS_PROXY"
     integration_uri         = aws_lambda_function.hello_world.arn
     payload_format_version  = "2.0"
}

resource "aws_apigatewayv2_route" "default" {
     api_id    = aws_apigatewayv2_api.http_api.id
     route_key = "GET /"
     target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_stage" "default" {
     api_id      = aws_apigatewayv2_api.http_api.id
     name        = "$default"
     auto_deploy = true
}

resource "aws_lambda_permission" "allow_apigw" {
     statement_id  = "AllowAPIGatewayInvoke"
     action        = "lambda:InvokeFunction"
     function_name = aws_lambda_function.hello_world.function_name
     principal     = "apigateway.amazonaws.com"
     source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}
