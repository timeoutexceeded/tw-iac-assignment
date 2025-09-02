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

resource "aws_iam_role_policy_attachment" "lambda_dynamodb_s3" {
     role       = aws_iam_role.lambda_exec.name
     policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

resource "aws_iam_role_policy_attachment" "lambda_s3_read" {
     role       = aws_iam_role.lambda_exec.name
     policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_lambda_function" "hello_world" {
     function_name = "${var.prefix}-hello-world"
     runtime       = "nodejs18.x"
     role          = aws_iam_role.lambda_exec.arn
     handler       = "hello-world.handler"
     filename      = data.archive_file.hello_world_lambda_zip.output_path
}

resource "aws_lambda_function" "register_user" {
     function_name = "${var.prefix}-register-user"
     runtime       = "nodejs18.x"
     role          = aws_iam_role.lambda_exec.arn
     handler       = "register-user.handler"
     filename      = data.archive_file.register_lambda_zip.output_path

     environment {
          variables = {
               DYNAMO_TABLE = aws_dynamodb_table.users.name
               HTML_BUCKET  = aws_s3_bucket.html_bucket.bucket
          }
     }
}

resource "aws_lambda_function" "verify_user" {
     function_name = "${var.prefix}-verify-user"
     runtime       = "nodejs18.x"
     role          = aws_iam_role.lambda_exec.arn
     handler       = "verify-user.handler"
     filename      = data.archive_file.verify_lambda_zip.output_path

     environment {
          variables = {
               DYNAMO_TABLE = aws_dynamodb_table.users.name
               HTML_BUCKET  = aws_s3_bucket.html_bucket.bucket
          }
     }
}

data "archive_file" "hello_world_lambda_zip" {
     type        = "zip"
     source_dir  = "${path.module}/../src/lambda/hello-world"
     output_path = "${path.module}/build/hello-world.zip"
}

data "archive_file" "register_lambda_zip" {
     type        = "zip"
     source_dir  = "${path.module}/../src/lambda/register-user"
     output_path = "${path.module}/build/register-user.zip"
}

data "archive_file" "verify_lambda_zip" {
     type        = "zip"
     source_dir  = "${path.module}/../src/lambda/verify-user"
     output_path = "${path.module}/build/verify-user.zip"
}

resource "local_file" "env_file" {
     content  = "API_URL=${aws_apigatewayv2_api.http_api.api_endpoint}"
     filename = "${path.module}/.env"
}

resource "aws_apigatewayv2_api" "http_api" {
     name          = "${var.prefix}-api"
     protocol_type = "HTTP"

     cors_configuration {
          allow_headers = ["*"]
          allow_methods = ["*"]
          allow_origins = ["*"]
     }
}

resource "aws_apigatewayv2_integration" "hello_world_lambda" {
     api_id                  = aws_apigatewayv2_api.http_api.id
     integration_type        = "AWS_PROXY"
     integration_uri         = aws_lambda_function.hello_world.arn
     payload_format_version  = "2.0"
}

resource "aws_apigatewayv2_integration" "register_user_lambda" {
     api_id             = aws_apigatewayv2_api.http_api.id
     integration_type   = "AWS_PROXY"
     integration_uri    = aws_lambda_function.register_user.arn
     payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "verify_user_lambda" {
     api_id             = aws_apigatewayv2_api.http_api.id
     integration_type   = "AWS_PROXY"
     integration_uri    = aws_lambda_function.verify_user.arn
     payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "default" {
     api_id    = aws_apigatewayv2_api.http_api.id
     route_key = "GET /"
     target    = "integrations/${aws_apigatewayv2_integration.hello_world_lambda.id}"
}

resource "aws_apigatewayv2_route" "register" {
     api_id    = aws_apigatewayv2_api.http_api.id
     route_key = "POST /register"
     target    = "integrations/${aws_apigatewayv2_integration.register_user_lambda.id}"
}

resource "aws_apigatewayv2_route" "verify" {
     api_id    = aws_apigatewayv2_api.http_api.id
     route_key = "GET /verify"
     target    = "integrations/${aws_apigatewayv2_integration.verify_user_lambda.id}"
}

resource "aws_apigatewayv2_stage" "default" {
     api_id      = aws_apigatewayv2_api.http_api.id
     name        = "$default"
     auto_deploy = true
}

resource "aws_lambda_permission" "allow_apigw_hello_world" {
     statement_id  = "AllowAPIGatewayInvoke"
     action        = "lambda:InvokeFunction"
     function_name = aws_lambda_function.hello_world.function_name
     principal     = "apigateway.amazonaws.com"
     source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "allow_apigw_register" {
     statement_id  = "AllowAPIGatewayInvokeRegister"
     action        = "lambda:InvokeFunction"
     function_name = aws_lambda_function.register_user.function_name
     principal     = "apigateway.amazonaws.com"
     source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "allow_apigw_verify" {
     statement_id  = "AllowAPIGatewayInvokeVerify"
     action        = "lambda:InvokeFunction"
     function_name = aws_lambda_function.verify_user.function_name
     principal     = "apigateway.amazonaws.com"
     source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}
