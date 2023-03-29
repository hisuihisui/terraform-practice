# ポリシーの定義
data "aws_iam_policy_document" "allow_describe_regions" {
  statement {
    effect = "Allow"
    actions = [ "ec2:DescribeRegions" ]  # リージョン一覧を取得
    resources = [ "*" ]
  }
}

# 信頼ポリシー
# なんのサービスに関連付けられるかを定義
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = [ "sts:AssumeRole" ]

    principals {
      type = "Service"
      # EC2にのみ関連づけられる
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# IAMポリシー
resource "aws_iam_policy" "example" {
  name = "example"
  policy = data.aws_iam_policy_document.allow_describe_regions.json
}

# IAMロール
resource "aws_iam_role" "example" {
  name = "example"
  # 信頼ポリシーの設定
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

# IAMロールにIAMポリシーをアタッチする
resource "aws_iam_role_policy_attachment" "example" {
  role = aws_iam_role.example.name
  policy_arn = aws_iam_policy.example.arn
}

# モジュールの利用
module "describe_regions_for_ec2" {
  source = "./iam_role"
  name = "describe-regions-for-ec2"
  identifier = "ec2.amazomaws.com"
  policy = data.aws_iam_policy_document.allow_describe_regions.json
}
