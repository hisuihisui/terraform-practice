# 三項演算子
variable "env" {}

resource "aws_instance" "example" {
  ami = "ami-0c3fd0f5d33134a76"
  # env の値によって切り替える
  instance_type = var.env == "prod" ? "m5.large" : "t3.micro"
}

# terraform plan -var "env=prod"

# 複数リソース作成
# countを使用して複数のリソースを簡単に作成可能
resource "aws_vpc" "examples" {
  # 3個作成
  count = 3
  cidr_block = "10.${count.index}.0.0/16"
}

# リソース作成制御
# count と三項演算子の組み合わせ
# たとえば
# count = var.allow_ssh ? 1 : 0

# 主要なデータソース
# AWSアカウントID
data "aws_caller_identity" "current" {}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

# リージョン
data "aws_region" "current" {}

output "region_name" {
  value = data.aws_region.current.name
}

# アベイラビリティゾーン
data "aws_availability_zones" "available" {
  state = "available"
}

output "availability_zones" {
  value = data.aws_availability_zones.available.names
}

# サービスアカウント
data "aws_elb_service_account" "current" {}

output "alb_service_account_id" {
  value = data.aws_elb_service_account.current.id
}


# ランダム文字列
# Randomプロバイダのrandom_stringリソースを使用
provider "random" {}

resource "random_string" "password" {
  length = 32
  # 特殊文字を使用するか
  # DBインスタンスでは使用不可のため、今回はfalseにしておく
  special = false
}

resource "aws_db_instance" "ecample" {
  engine = "mysql"
  instance_class = "db.t3.small"
  allocated_storage = 20
  skip_final_snapshot = true
  username = "admin"
  password = random_string.password.result
}


# Multipleプロバイダ
# 複数のリージョンを使用してリソースを作成
# 特定のリソースだけ別リージョンに作りたいとか
# aliasを使用して、プロバイダに名前をつける
provider "aws" {
  # こっちを使いたい場合は provider = aws.virginia をつける
  # alias が未定義のプロバイダはデフォルトプロバイダとなる
  alias = "virginia"
  region = "us-east-1"
}

resource "aws_vpc" "virginia" {
  provider = aws.virginia
  cidr_block = "192.168.0.0/16"
}

resource "aws_vpc" "tokyo" {
  cidr_block = "192.168.0.0/16"
}

output "virginia_vpc" {
  value = aws_vpc.virginia.arn
}

output "tokyo_vpc" {
  value = aws_vpc.tokyo.arn
}

# モジュールのマルチリージョン定義
module "virginia" {
  source = "./vpc"

  providers = {
    aws = aws.virginia
  }
}

module "tokyo" {
  source = "./vpc"
}

output "module_virginia_vpc" {
  value = module.virginia.vpc_arn
}

output "module_tokyo_vpc" {
  value = module.tokyo.vpc_arn
}


# Dynamic blocks
# 動的にブロック要素を生成できる
module "simple_sg" {
  source = "./simple_security_group"
  ports = [80, 443, 8080]
}

module "complex_sg" {
  source = "./complex_security_group"
  ingress_rules = {
    http = {
      port = 80
      cidr_blocks = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
    }
    https = {
      port = 443
      cidr_blocks = ["0.0.0.0/0"]
    }
    redirect_http_to_https = {
      port = 8080
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}
