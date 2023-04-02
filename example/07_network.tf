# ネットワーク

# VPC
resource "aws_vpc" "example" {
  # VPCのIPv4アドレスの範囲を指定
  # こだわりがなければ、/16で指定
  cidr_block = "10.0.0.0/16"

  # 名前解決
  # AWSのDNSサーバーによる名前解決を有効化
  enable_dns_support = true
  # VPC内のリソースにパブリックDNSホスト名を自動で割り当てる
  enable_dns_hostnames = true

  # タグ
  tags = {
    Name = "example"
  }
}


# パブリックネットワーク
# インターネットからアクセス可能
#  →パブリックIPアドレスを持つ

# パブリックサブネット
resource "aws_subnet" "public" {
  # VPCの指定
  vpc_id = aws_vpc.example.id
  # CIDR
  # こだわりがなければ、/24で指定
  cidr_block = "10.0.0.0/24"
  # 起動したインスタンスにパブリックIPアドレスを割り当てる
  map_public_ip_on_launch = true
  # アベイラビリティゾーン
  availability_zone = "ap-northeast-1a"
}

# インターネットゲートウェイ
# VPCをインターネットにアクセスできるようにする
# ルートテーブルも必要
resource "aws_internet_gateway" "example" {
  vpc_id = aws_vpc.example.id
}

# ルートテーブル
# ルーティング情報を管理
# ローカルルート（VPC内の通信を許可）が自動で作成
#  ↑はTerraformから操作できない
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.example.id
}

# ルート
# ルートテーブルの１レコードに該当
resource "aws_route" "public" {
  route_table_id = aws_route_table.public.id
  gateway_id = aws_internet_gateway.example.id
  # 通信先
  # インターネットへの疎通許可
  destination_cidr_block = "0.0.0.0/0"
}

# ルートテーブルとサブネットの関連付け
# 関連付けないとデフォルトルートテーブルが使われる
#  →アンチパターンなので、関連づけを忘れない
resource "aws_route_table_association" "public" {
  subnet_id = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}


# プライベートネットワーク
# インターネットから隔離されたネットワーク

# プライベートサブネット
resource "aws_subnet" "private" {
  vpc_id = aws_vpc.example.id
  cidr_block = "10.0.64.0/24"
  availability_zone = "ap-northeast-1a"
  # パブリックIPアドレス不要なので、false
  map_public_ip_on_launch = false
}

# ルートテーブル
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.example.id
}

# ルートテーブルとプライベートサブネットの関連付け
resource "aws_route_table_association" "private" {
  subnet_id = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

# NATゲートウェイ用EIP
resource "aws_eip" "nat_gateway" {
  vpc = true
  # internet_gateway との依存関係を明示
  # リソースの作成順序に作用
  depends_on = [
    aws_internet_gateway.example
  ]
}

# NATゲートウェイ
resource "aws_nat_gateway" "example" {
  # EIPの指定
  allocation_id = aws_eip.nat_gateway.id
  # サブネット
  # パブリックサブネットを指定すること
  subnet_id = aws_subnet.public.id
  # internet_gateway との依存関係を明示
  # リソースの作成順序に作用
  depends_on = [
    aws_internet_gateway.example
  ]
}

# ルートの設定
# プライベートサブネット → NATゲートウェイへの通信を許可
resource "aws_route" "private" {
  route_table_id = aws_route_table.private.id
  # nat_gateway_idを指定すること
  nat_gateway_id = aws_nat_gateway.example.id
  destination_cidr_block = "0.0.0.0/0"
}


# パブリックネットワークのマルチAZ化

# パブリックサブネット
resource "aws_subnet" "public_0" {
  vpc_id = aws_vpc.example.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-northeast-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "public_1" {
  vpc_id = aws_vpc.example.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "ap-northeast-1c"
  map_public_ip_on_launch = true
}

# ルートテーブルとサブネットの関連づけ
resource "aws_route_table_association" "public_0" {
  subnet_id = aws_subnet.public_0.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_1" {
  subnet_id = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}


# プライベートネットワークのマルチAZ化

# プライベートサブネット
resource "aws_subnet" "private_0" {
  vpc_id = aws_vpc.example.id
  cidr_block = "10.0.65.0/24"
  availability_zone = "ap-northeast-1a"
  map_public_ip_on_launch = false
}

resource "aws_subnet" "private_1" {
  vpc_id = aws_vpc.example.id
  cidr_block = "10.0.66.0/24"
  availability_zone = "ap-northeast-1c"
  map_public_ip_on_launch = false
}

# NATゲートウェイ用EIP
resource "aws_eip" "nat_gateway_0" {
  vpc = true
  depends_on = [
    aws_internet_gateway.example
  ]
}

resource "aws_eip" "nat_gateway_1" {
  vpc = true
  depends_on = [
    aws_internet_gateway.example
  ]
}

# NATゲートウェイ
resource "aws_nat_gateway" "nat_gateway_0" {
  allocation_id = aws_eip.nat_gateway_0.id
  subnet_id = aws_subnet.public_0.id
  depends_on = [
    aws_internet_gateway.example
  ]
}

resource "aws_nat_gateway" "nat_gateway_1" {
  allocation_id = aws_eip.nat_gateway_1.id
  subnet_id = aws_subnet.public_1.id
  depends_on = [
    aws_internet_gateway.example
  ]
}

# ルートテーブル
resource "aws_route_table" "private_0" {
  vpc_id = aws_vpc.example.id
}

resource "aws_route_table" "private_1" {
  vpc_id = aws_vpc.example.id
}

# ルート
resource "aws_route" "private_0" {
  route_table_id = aws_route_table.private_0.id
  nat_gateway_id = aws_nat_gateway.nat_gateway_0.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route" "private_1" {
  route_table_id = aws_route_table.private_1.id
  nat_gateway_id = aws_nat_gateway.nat_gateway_1.id
  destination_cidr_block = "0.0.0.0/0"
}

# ルートテーブルとサブネットの関連づけ
resource "aws_route_table_association" "private_0" {
  subnet_id = aws_subnet.private_0.id
  route_table_id = aws_route_table.private_0.id
}

resource "aws_route_table_association" "private_1" {
  subnet_id = aws_subnet.private_1.id
  route_table_id = aws_route_table.private_1.id
}


# ファイアウォール
# セキュリティグループ
resource "aws_security_group" "example" {
  name = "example"
  vpc_id = aws_vpc.example.id
}

# セキュリティグループルール
resource "aws_security_group_rule" "ingress_example" {
  # インバウンドルール
  type = "ingress"
  from_port = "80"
  to_port = "80"
  protocol = "tcp"
  cidr_blocks = [ "0.0.0.0/0" ]
  security_group_id = aws_security_group.example.id
}

resource "aws_security_group_rule" "egress_example" {
  # アウトバウンドルール
  type = "egress"
  from_port = 0
  to_port = 0
  protocol = "-1"
  cidr_blocks = [ "0.0.0.0/0" ]
  security_group_id = aws_security_group.example.id
}


# モジュールの利用
module "example_sg" {
  source = "./security_group"
  name = "module-sg"
  vpc_id = aws_vpc.example.id
  port = 80
  cidr_block = [ "0.0.0.0/0" ]
}
