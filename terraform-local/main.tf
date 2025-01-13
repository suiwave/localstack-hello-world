############################################################################
## terraformブロック
############################################################################
terraform {
  # Terraformのバージョン指定
  required_version = "~> 1.7.0"

  # Terraformのaws用ライブラリのバージョン指定
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.33.0"
    }
  }
}

############################################################################
## providerブロック
############################################################################
provider "aws" {
  # リージョンを指定
  region = "ap-northeast-1"

  # LocalStackを利用する場合の設定
  # https://docs.localstack.cloud/user-guide/integrations/terraform/
  access_key                  = "test"
  secret_key                  = "test"
  s3_use_path_style           = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    s3             = "http://localhost:4566"
  }
}

locals {
  project = "localstack-terraform"
}

############################################################################
## resourceブロック
############################################################################
# Localstackでしか作れないような汎用的な名前のバケット
resource "aws_s3_bucket" "bucket" {
  bucket = "sample-bucket"
}