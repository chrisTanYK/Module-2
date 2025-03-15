provider "aws" {
  region = "us-east-1"
}

# Create S3 Bucket
resource "aws_s3_bucket" "bucket" {
  bucket = "christanyk-misc-storage"
}

# Create "upload/" folder in S3 bucket
resource "aws_s3_object" "uploads_folder" {
  bucket = aws_s3_bucket.bucket.id
  key    = "uploads/"  # This creates a folder-like prefix
}

# Enable Event Notification on S3
resource "aws_s3_bucket_notification" "s3_event" {
  bucket = aws_s3_bucket.bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.s3_lambda.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "uploads/"
  }
}

# Grant S3 Permission to Invoke Lambda
resource "aws_lambda_permission" "s3_trigger" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_lambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.bucket.arn
}

# Create Local File for Lambda Code
resource "local_file" "lambda_code" {
  filename = "lambda_function.py"
  content  = <<EOF
import json

def lambda_handler(event, context):
    print("event:", event)
    print("context:", context)
    return {
        'statusCode': 200,
        'body': json.dumps('S3 Event Triggered!')
    }
EOF
}

# Auto-create ZIP File using Terraform Archive Provider
resource "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = local_file.lambda_code.filename
  output_path = "lambda_function.zip"
}

# Create Lambda Function (Assumes an existing IAM Role is provided externally)
resource "aws_lambda_function" "s3_lambda" {
  function_name    = "christanyk-process-s3events"
  role             = "arn:aws:iam::255945442255:role/existing_lambda_role"  # Replace with an existing IAM role
  runtime          = "python3.9"
  handler          = "lambda_function.lambda_handler"
  filename         = archive_file.lambda_zip.output_path
  source_code_hash = archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.bucket.id
    }
  }
}

# Auto Cleanup on terraform destroy
resource "null_resource" "cleanup" {
  provisioner "local-exec" {
    when    = destroy
    command = <<EOT
      aws s3 rb s3://christanyk-misc-storage --force
      aws lambda delete-function --function-name christanyk-process-s3events || true
    EOT
  }
}


