# リモートステートを参照
data "terraform_remote_state" "network" {
  backend = "s3"

  config = {
    bucket = "tfstate-pragmatic-terraform"
    key = "network/terraform.tfstate"
    region = "ap-northeast-1"
  }
}

# リモートステート経由でリソースの参照
resource "aws_instance" "server" {
  ami = "ami-0c3fd0f5d33134a76"
  instance_type = "t3.micro"
  vpc_security_group_ids = [ aws_security_group.server.id ]
  # リモートステートを参照
  subnet_id = data.terraform_remote_state.network.outputs.subnet_id
}

resource "aws_security_group" "server" {
  # リモートステートを参照
  vpc_id = data.terraform_remote_state.network.outputs.vpc_id
}

# SSMパラメータストアの参照
data "aws_ssm_parameter" "vpc_id" {
  name = "/staging/vpc/id"
}

data "aws_ssm_parameter" "subnet_id" {
  name = "/staging/public/subnet/id"
}

resource "aws_instance" "server_ssm" {
  ami = "ami-0c3fd0f5d33134a76"
  instance_type = "t3.micro"
  vpc_security_group_ids = [ aws_security_group.server_ssm.id ]
  # リモートステートを参照
  subnet_id = data.aws_ssm_parameter.subnet_id.value
}

resource "aws_security_group" "server_ssm" {
  # リモートステートを参照
  vpc_id = data.aws_ssm_parameter.vpc_id.value
}

# タグによるデータソースの定義
data "aws_vpc" "staging" {
  tags = {
    Environment = "Staging"
  }
}

# フィルターによるデータソースの定義
# 特定の条件に合致するリソースを参照
data "aws_subnet" "public_staging" {
  filter {
    name = "vpc-id"
    values = [ data.aws_vpc.staging.id ]
  }

  filter {
    name = "cidr-block"
    values = ["192.168.0.0/24"]
  }
}

# Data-only Modules による参照
module "staging_network" {
  source = "./staging_network"
}

resource "aws_instance" "server_dom" {
  ami = "ami-0c3fd0f5d33134a76"
  instance_type = "t3.micro"
  vpc_security_group_ids = [ aws_security_group.server_dom.id ]
  subnet_id = module.staging_network.public_subnet_id
}

resource "aws_security_group" "server_dom" {
  vpc_id = module.staging_network.vpc_id
}
