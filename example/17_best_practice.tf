# Terraformベストプラクティス

# Terraformのバージョンを固定
terraform {
  required_version = "1.4.2"
}

# プロバイダバージョンを固定
# 定義や変更したときは terraform init を実行する
provider "aws" {
  version = "4.60.0"
  region = "ap-northeast-1"
}
