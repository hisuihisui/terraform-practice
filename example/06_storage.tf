# プライベートバケットを定義
resource "aws_s3_bucket" "private" {
  # バケット名
  bucket = "private-pragmatic-terraform-06"

  # バージョニング
  # versioning {
  #   enabled = true
  # }

  # サーバーサイド暗号化
  # オブジェクト保存時に暗号化し、参照時に複合する
  # server_side_encryption_configuration {
  #   rule {
  #     apply_server_side_encryption_by_default {
  #       sse_algorithm = "AES256"
  #     }
  #   }
  # }
}

# バージョニング
resource "aws_s3_bucket_versioning" "private" {
  bucket = aws_s3_bucket.private.id

  versioning_configuration {
    status = "Enabled"
  }
}

# サーバーサイド暗号化
# オブジェクト保存時に暗号化し、参照時に複合する
resource "aws_s3_bucket_server_side_encryption_configuration" "private" {
  bucket = aws_s3_bucket.private.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# ブロックパブリックアクセス
resource "aws_s3_bucket_public_access_block" "private" {
  bucket = aws_s3_bucket.private.id
  block_public_acls = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}

# パブリックバケット
resource "aws_s3_bucket" "public" {
  bucket = "public-pragmatic-terraform-06"
}

# バケットのACL設定
resource "aws_s3_bucket_acl" "public" {
  bucket = aws_s3_bucket.public.id
  # デフォルトは "private"
  acl = "public-read"
}

# CORSルール
resource "aws_s3_bucket_cors_configuration" "public" {
  bucket = aws_s3_bucket.public.id

  cors_rule {
    allowed_origins = [ "https://example.com" ]
    allowed_methods = [ "GET" ]
    allowed_headers = [ "*" ]
    max_age_seconds = 3000
  }
}

# ログバケット
resource "aws_s3_bucket" "alb_log" {
  bucket = "alb-log-pragmatic-terraform-06"
}

# ライフサイクルルール
resource "aws_s3_bucket_lifecycle_configuration" "alb_log" {
  bucket = aws_s3_bucket.alb_log.id

  rule {
    id = "rule-1"
    status = "Enabled"

    expiration {
      # 180日
      days = "180"
    }
  }
}

# バケットポリシー
# S3へのアクセス権を設定
resource "aws_s3_bucket_policy" "alb_log" {
  bucket = aws_s3_bucket.alb_log.id
  policy = data.aws_iam_policy_document.alb_log.json
}

# ポリシードキュメント
data "aws_iam_policy_document" "alb_log" {
  statement {
    effect = "Allow"
    actions = [ "s3:PutObject" ]
    resources = [ "arn:aws:s3:::${aws_s3_bucket.alb_log.id}/*" ]
    principals {
      type = "AWS"
      # ALBのログを書き込むAWSが管理しているアカウント
      # リージョンごとに異なる
      identifiers = [ "582318560864" ]
    }
  }
}

# force_destroy
resource "aws_s3_bucket" "force_destroy" {
  bucket = "force-destroy-pragmatic-terraform-06"
  force_destroy = true
}
