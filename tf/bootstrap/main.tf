terraform {
  required_version = "~> 1.0.10"

  required_providers {
    aws     = "~> 3.63"
    archive = "~> 2.2"
  }
}

provider "aws" {
  region                  = "ca-central-1"
  shared_credentials_file = "$HOME/.aws/credentials"
  profile                 = "serverless-rails-demo"
  skip_region_validation  = true
}

resource "aws_s3_bucket" "terraform-state" {
  bucket = "serverless-rails-demo--tf-state"
  versioning {
    enabled = true
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_dynamodb_table" "terraform-locks" {
  name         = "tf-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
}
