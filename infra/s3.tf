resource "aws_s3_bucket" "html_bucket" {
  bucket = "${var.prefix}-bucket"
  force_destroy = true

  tags = {
    Name = "${var.prefix}-bucket"
  }
}

resource "aws_s3_object" "index_html" {
  bucket = aws_s3_bucket.html_bucket.id
  key    = "index.html"
  source = "${path.module}/../src/assets/index.html"
  etag   = filemd5("${path.module}/../src/assets/index.html")
  content_type = "text/html"
}

resource "aws_s3_object" "error_html" {
  bucket = aws_s3_bucket.html_bucket.id
  key    = "error.html"
  source = "${path.module}/../src/assets/error.html"
  etag   = filemd5("${path.module}/../src/assets/error.html")
  content_type = "text/html"
}
