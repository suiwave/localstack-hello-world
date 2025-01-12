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
}

locals {
  project = "lambda-localstack"
}

############################################################################
## resourceブロック
############################################################################
resource "aws_iam_role" "lambda_execution_role" {
    name = "${local.project}-execution-role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Action = "sts:AssumeRole"
                Effect = "Allow"
                Principal = {
                    Service = "lambda.amazonaws.com"
                }
            }
        ]
    })
}

resource "aws_iam_policy" "lambda_cloudwatch_policy" {
    name        = "${local.project}-cloudwatch-policy"
    description = "Policy for Lambda to write logs to CloudWatch"
    policy      = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Action = [
                    "logs:CreateLogGroup",
                    "logs:CreateLogStream",
                    "logs:PutLogEvents"
                ]
                Effect   = "Allow"
                Resource = "arn:aws:logs:*:*:*"
            }
        ]
    })
}

resource "aws_iam_role_policy_attachment" "lambda_cloudwatch_policy_attachment" {
    role       = aws_iam_role.lambda_execution_role.name
    policy_arn = aws_iam_policy.lambda_cloudwatch_policy.arn
}

resource "aws_iam_policy" "lambda_s3_policy" {
    name        = "${local.project}-s3-policy"
    description = "Policy for Lambda to access S3"
    policy      = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Action = [
                    "s3:ListBucket",
                    "s3:ListBucketVersions",
                    "s3:ListAllMyBuckets"
                ]
                Effect   = "Allow"
                Resource = "*"
            },
            {
                Action = [
                    "s3:ListObjects",
                    "s3:ListObjectsV2",
                    "s3:GetObject"
                ]
                Effect   = "Allow"
                Resource = "*"
            }
        ]
    })
}

resource "aws_iam_role_policy_attachment" "lambda_s3_policy_attachment" {
    role       = aws_iam_role.lambda_execution_role.name
    policy_arn = aws_iam_policy.lambda_s3_policy.arn
}

resource "aws_lambda_function" "example" {
    function_name = "${local.project}-function"
    role          = aws_iam_role.lambda_execution_role.arn
    handler       = "index.handler"
    runtime       = "nodejs18.x"
    filename      = "lambda_function_payload.zip"
    architectures = ["arm64"]

    environment {
        variables = {
            ENV = "prod"
        }
    }

    source_code_hash = filebase64sha256("lambda_function_payload.zip")
}