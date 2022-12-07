# ----------------------------------------------------------------------------------------------
# Lambda Function
# ----------------------------------------------------------------------------------------------
resource "aws_lambda_function" "this" {
  function_name    = "onecloud-auto-register-ec2-public-ip-in-route53"
  source_code_hash = data.archive_file.this.output_base64sha256
  filename         = data.archive_file.this.output_path
  handler          = "index.handler"
  runtime          = "nodejs14.x"
  memory_size      = 128
  role             = aws_iam_role.this.arn
  timeout          = 5

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.this.name
      ZONE_NAME  = var.zone_name
    }
  }
}

# ---------------------------------------------------------------------------------------------
# API Gateway Permission (Lambda) - ECS Task Start
# ---------------------------------------------------------------------------------------------
resource "aws_lambda_permission" "this" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.this.arn
}

# ----------------------------------------------------------------------------------------------
# Lambda Function data - Dummy
# ----------------------------------------------------------------------------------------------
data "archive_file" "this" {
  type        = "zip"
  source_dir  = "../dist"
  output_path = "./dist.zip"
}

# ----------------------------------------------------------------------------------------------
# AWS Lambda Role - ECS Task Status
# ----------------------------------------------------------------------------------------------
resource "aws_iam_role" "this" {
  name               = "OneCloudAutoRegisterEC2InRoute53Role"
  assume_role_policy = data.aws_iam_policy_document.this.json

  lifecycle {
    create_before_destroy = false
  }
}

# ----------------------------------------------------------------------------------------------
# AWS Lambda Role Policy
# ----------------------------------------------------------------------------------------------
data "aws_iam_policy_document" "this" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# ----------------------------------------------------------------------------------------------
# AWS Lambda Role - ECS Policy
# ----------------------------------------------------------------------------------------------
resource "aws_iam_role_policy" "this" {
  name = "Policy"
  role = aws_iam_role.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:describeInstances",
          "dynamodb:*",
          "route53:listHostedZonesByName",
          "route53:changeResourceRecordSets"
        ]
        Resource = "*"
      },
    ]
  })
}
