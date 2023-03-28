# モジュールを定義するファイル
# 入力パラメータ：instance_type (EC2のインスタンスタイプ)
# 出力パラメータ：public_dns (EC2のパブリックDNS)

# 入力パラメータの指定
variable "example_instance_type" {}

# locals {
# 	example_instance_type = "t2.micro"
# }

# Amazon Linux 2 の最新AMIを取得
data "aws_ami" "recent_amazon_linux_2" {
	# 最新のAMIを取得
	most_recent = true
	owners = ["amazon"]

	# AMI名の検索条件を指定
	filter {
		name = "name"
		# values = ["amzn2-ami-hvm-2.0.????????-x86_64-gp2"]
		values = ["amzn2-ami-hvm-*-x86_64-gp2"]
	}

	# 使用可能なものを指定
	filter {
		name = "state"
		values = ["available"]
	}
}

resource "aws_security_group" "example_ec2" {
  name = "example_ec2"

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [ "0.0.0.0/0" ]
  }
}

resource "aws_instance" "example" {
	# ami = "ami-0c3fd0f5d33134a76"
	ami = data.aws_ami.recent_amazon_linux_2.image_id

	# instance_type = "t2.micro"
	instance_type = var.example_instance_type
	# instance_type = local.example_instance_type

	# リスト形式で指定
	vpc_security_group_ids = [ aws_security_group.example_ec2.id ]

	tags = {
		Name = "example"
	}

	# user_data = file("./user_data.sh")
	user_data = <<EOF
		#!/bin/bash
		yum install -y httpd
		systemctl start httpd.service
	EOF
}

# output "example_instance_id" {
#   value = aws_instance.example.id
# }

output "example_public_dns" {
	value = aws_instance.example.public_dns
}
