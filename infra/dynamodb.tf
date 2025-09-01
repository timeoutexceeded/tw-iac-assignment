resource "aws_dynamodb_table" "users" {
  name           = "${var.prefix}-users"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "userId"

  attribute {
    name = "userId"
    type = "S"
  }

  tags = {
    Name = "${var.prefix}-users"
  }
}