# --- KMS ---
data "aws_caller_identity" "current" {}

resource "aws_kms_key" "data" {
  description         = "Cle pour le bucket data"
  enable_key_rotation = true
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AdminCompte"
      Effect    = "Allow"
      Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
      Action    = "kms:*"
      Resource  = "*"
    }]
  })
}

# --- S3 ---
resource "aws_s3_bucket" "data" {
  #checkov:skip=CKV_AWS_18:Lab local, pas de bucket de logs dedie
  #checkov:skip=CKV_AWS_144:Lab local, pas de replication cross-region
  #checkov:skip=CKV2_AWS_61:Lab local, pas de lifecycle
  #checkov:skip=CKV2_AWS_62:Lab local, pas de notifications d'evenements
  bucket = "ons-lab-data"
}

resource "aws_s3_bucket_versioning" "data" {
  bucket = aws_s3_bucket.data.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "data" {
  bucket = aws_s3_bucket.data.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.data.arn
    }
  }
}

resource "aws_s3_bucket_public_access_block" "data" {
  bucket                  = aws_s3_bucket.data.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# --- IAM ---
data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_role" {
  name               = "lambda-demo-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

resource "aws_iam_role_policy" "lambda_s3" {
  name = "lambda-s3-read"
  role = aws_iam_role.lambda_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:GetObject"]
      Resource = "${aws_s3_bucket.data.arn}/*"
    }]
  })
}

# --- Lambda ---
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/handler.py"
  output_path = "${path.module}/lambda/handler.zip"
}

resource "aws_lambda_function" "demo" {
  #checkov:skip=CKV_AWS_117:Lab local, pas de VPC
  #checkov:skip=CKV_AWS_116:Lab local, pas de dead letter queue
  #checkov:skip=CKV_AWS_173:Pas de variables d'environnement sensibles
  #checkov:skip=CKV_AWS_272:Lab local, pas de code signing
  function_name                  = "demo-fn"
  role                           = aws_iam_role.lambda_role.arn
  handler                        = "handler.handler"
  runtime                        = "python3.12"
  filename                       = data.archive_file.lambda_zip.output_path
  source_code_hash               = data.archive_file.lambda_zip.output_base64sha256
  reserved_concurrent_executions = 5

  tracing_config {
    mode = "Active"
  }
}
