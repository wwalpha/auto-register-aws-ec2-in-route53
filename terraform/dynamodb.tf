resource "aws_dynamodb_table" "this" {
  name         = "onecloud-domain-mapping"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "Id"

  ttl {
    attribute_name = "ExpireDate"
    enabled        = true
  }

  attribute {
    name = "Id"
    type = "S"
  }
}
