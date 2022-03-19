# ----------------------------------------------------------------------------------------------
# AWS CloudWatch Event Rule
# ----------------------------------------------------------------------------------------------
resource "aws_cloudwatch_event_rule" "this" {
  name        = "register-ec2-public-ip-in-route53"
  description = "Register public ip in route53"

  event_pattern = <<EOF
{
  "source": ["aws.ec2"],
  "detail-type": ["EC2 Instance State-change Notification"],
  "detail": {
    "state": ["running"],
    "instance-id": ["${var.instance_id}"]
  }
}
EOF
}

# ----------------------------------------------------------------------------------------------
# AWS CloudWatch Event Rule Target
# ----------------------------------------------------------------------------------------------
resource "aws_cloudwatch_event_target" "this" {
  rule      = aws_cloudwatch_event_rule.this.name
  target_id = "SendToLambda"
  arn       = aws_lambda_function.this.arn

  input_transformer {
    input_paths = {
      "instance-id" = "$.detail.instance-id"
      "state"       = "$.detail.state"
    }
    input_template = <<EOF
{
  "instance": "<instance-id>",
  "state": "<state>",
  "instanceAlias": "${var.instance_alias}.${var.zone_name}",
  "zoneName": "${var.zone_name}"
}
EOF
  }
}
