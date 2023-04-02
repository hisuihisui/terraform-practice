# 入力パラメータ
# セキュリティグループ名
variable "name" { }
# VPCのID
variable "vpc_id" { }
# 通信を許可するポート
variable "port" { }
# CIDR
variable "cidr_block" {
  # 型の指定
  # 指定しない場合は any 型になる
  type = list(string)
}


resource "aws_security_group" "default" {
  name = var.name
  vpc_id = var.vpc_id
}

# インバウンドルール
resource "aws_security_group_rule" "ingress" {
  type = "ingress"
  from_port = var.port
  to_port = var.port
  protocol = "tcp"
  cidr_blocks = var.cidr_block
  security_group_id = aws_security_group.default.id
}

# アウトバウンドルール
resource "aws_security_group_rule" "egress" {
  type = "egress"
  from_port = 0
  to_port = 0
  protocol = "-1"
  cidr_blocks = [ "0.0.0.0/0" ]
  security_group_id = aws_security_group.default.id
}

# 出力
output "security_group_id" {
  value = aws_security_group.default.id
}
