# 入力パラメータの指定
# IAMロールとIAMポリシーの名前
variable "name" { }
# ポリシードキュメント
variable "policy" { }
# IAMロールを関連付けるAWSのサービス識別子
variable "identifier" { }

# IAMロール
resource "aws_iam_role" "default" {
  name = var.name
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

# 信頼ポリシー
data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = [ "sts:AssumeRole" ]

    principals {
      type = "Service"
      identifiers = [ var.identifier ]
    }
  }
}

# IAMポリシー
resource "aws_iam_policy" "default" {
  name = var.name
  policy = var.policy
}

# IAMポリシーのアタッチ
resource "aws_iam_policy_attachment" "default" {
  name = aws_iam_role.default.name
  policy_arn = aws_iam_policy.default.arn
}

# 出力パラメータ
output "iam_role_arn" {
  value = aws_iam_role.default.arn
}

output "iam_role_name" {
  value = aws_iam_role.default.name
}
