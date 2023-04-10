terraform {
  backend "s3" {
    bucket = "tfstate-pragmatic-terraform"
    # tfstateファイルごとに異なる値を設定する
    key = "network/terraform.tfstate"
    region = "ap-northeast-1"
  }
}

resource "aws_vpc" "staging" {
  cidr_block = "192.168.0.0/16"

  tags = {
    Environment = "Staging"
  }
}

resource "aws_subnet" "public_staging" {
  vpc_id = aws_vpc.staging.id
  cidr_block = "192.168.0.0/24"

  tags = {
    Environment = "Staging"
    Accessibility = "Public"
  }
}

output "vpc_id" {
  value = aws_vpc.staging.id
}

output "subnet_id" {
  value = aws_subnet.public_staging.id
}

# SSMパラメータストアへ値を格納
resource "aws_ssm_parameter" "vpc_id" {
  name = "/staging/vpc/id"
  value = aws_vpc.staging.id
  type = "String"
}

resource "aws_ssm_parameter" "subnet_id" {
  name = "/staging/public/subnet/id"
  value = aws_subnet.public_staging.id
  type = "String"
}
