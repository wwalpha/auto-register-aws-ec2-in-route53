# ----------------------------------------------------------------------------------------------
# AWS Route53
# ----------------------------------------------------------------------------------------------
data "aws_route53_zone" "this" {
  name = var.zone_name
}
