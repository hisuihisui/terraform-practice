# ステートバケットの指定
# 有効にならないようにコメントアウトしておく
# terraform {
#   backend "s3" {
#     bucket = "tfstate-pragmatic-terraform"
#     # tfstateファイルごとに異なる値を設定する
#     key = "example/terraform.tfstate"
#     region = "ap-northeast-1"
#   }
# }
