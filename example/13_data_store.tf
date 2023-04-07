# RDS
# DBパラメータグループ
resource "aws_db_parameter_group" "example" {
  name = "example"
  # エンジン名とバージョンを合わせたもの
  family = "mysql5.7"

  # パラメータ
  parameter {
    name = "character_set_database"
    value = "utf8mb4"
  }

  parameter {
    name = "character_set_server"
    value = "utf8mb4"
  }
}

# DBオプショングループ
# オプション機能を追加
resource "aws_db_option_group" "example" {
  name = "example"
  engine_name = "mysql"
  major_engine_version = "5.7"

  # オプション
  # MariaDB監査プラグイン
  # ユーザーのログオンや実行したクエリなどのアクティビティを記録
  option {
    option_name = "MARIADB_AUDIT_PLUGIN"
  }
}

# DBサブネットグループ
resource "aws_db_subnet_group" "example" {
  name = "example"
  # サブネットの指定
  # 異なるAZのサブネットを指定して可用性を高める
  subnet_ids = [
    aws_subnet.private_0.id,
    aws_subnet.private_1.id,
  ]
}

# DBインスタンス
resource "aws_db_instance" "example" {
  # 識別子
  identifier = "example"
  # エンジン
  engine = "mysql"
  # バージョン
  engine_version = "5.7.25"
  # インスタンスクラス
  instance_class = "db.t3.small"
  # ストレージ容量
  allocated_storage = 20
  # このストレージ容量まで自動でスケールする
  max_allocated_storage = 100
  # gps：汎用SSD
  storage_type = "gp2"
  # ディスク暗号化
  storage_encrypted = true
  # このKMSの鍵でディスク暗号化してくれる
  # デフォルトAWS KMS暗号化鍵を使用するとアカウントをまたいだスナップショットの共有不可
  kms_key_id = aws_kms_key.example.arn
  # マスターユーザー
  username = "admin"
  # パスワード
  # インスタンス作成後、CLI（下記コマンド）によって変更する
  # aws rds modify-db-instance --db-instance-identifier "example" --master-user-password "NewMasterPassword!"
  password = "VeryStrongPassword!"
  # マルチAZにするか
  multi_az = true
  # VPC外からのアクセスを許可するか
  publicly_accessible = false
  # バックアップを行うタイミング
  # UTCであることに注意
  # メンテナンスウィンドウの前に設定しておくとよい
  backup_window = "09:10-09:40"
  # バックアップ保持期間
  # 最大35日間
  backup_retention_period = 30
  # メンテナンス(= OSやデータベースエンジンの更新)を行うタイミング
  # UTCであることに注意
  maintenance_window = "mon:10:10-mon:10:40"
  # 自動マイナーバージョンアップ
  auto_minor_version_upgrade = false
  # RDSの削除
  # deletion_protection = false
  # skip_final_snapshot = true
  # にしてapplyするとdestroyコマンドで削除できるようになる
  # 削除保護
  deletion_protection = true
  # インスタンス削除時のスナップショット作成要否
  skip_final_snapshot = false
  # ポート番号
  port = 3306
  # 設定変更のタイミング
  # true: 即時変更
  # false: メンテナンスにて
  apply_immediately = false
  vpc_security_group_ids = [ module.mysql_sg.security_group_id ]
  parameter_group_name = aws_db_parameter_group.example.name
  option_group_name = aws_db_option_group.example.name
  db_subnet_group_name = aws_db_subnet_group.example.name

  lifecycle {
    ignore_changes = [
      password
    ]
  }
}

# DBインスタンス用SG
module "mysql_sg" {
  source = "./security_group"
  name = "mysql-sg"
  vpc_id = aws_vpc.example.id
  port = 3306
  cidr_block = [ aws_vpc.example.cidr_block ]
}


# ElastiCache
# パラメータグループ
resource "aws_elasticache_parameter_group" "example" {
  name = "example"
  family = "redis5.0"

  parameter {
    # クラスタモードの無効
    name = "cluster-enabled"
    value = "no"
  }
}

# サブネットグループ
resource "aws_elasticache_subnet_group" "example" {
  name = "example"
  # マルチAZのため、複数サブネット指定
  subnet_ids = [
    aws_subnet.private_0.id,
    aws_subnet.private_1.id
  ]
}

# レプリケーショングループの作成
# Redisサーバーの作成
resource "aws_elasticache_replication_group" "example" {
  # 識別子
  replication_group_id = "example"
  # 説明
  description = "Cluster Disabled"
  # エンジン
  # memcached or redis
  engine = "redis"
  # バージョン
  engine_version = "5.0.4"
  # ノード数
  num_cache_clusters = 3
  # ノードタイプ
  node_type = "cache.m3.medium"
  # スナップショット取得時間帯
  # UTC
  snapshot_window = "09:10-10:10"
  # スナップショットの保持期間
  snapshot_retention_limit = 7
  # メンテナンスウィンドウ
  # UTC
  maintenance_window = "mon:10:40-mon:11:40"
  # 自動フェイルオーバー
  # マルチAZ化が前提
  automatic_failover_enabled = true
  # ポート
  port = 6379
  # 設定変更タイミング
  # true: 即時変更
  # false: メンテナンスにて
  apply_immediately = false
  security_group_ids = [
    module.redis_sg.security_group_id
  ]
  parameter_group_name = aws_elasticache_parameter_group.example.name
  subnet_group_name = aws_elasticache_subnet_group.example.name
}

module "redis_sg" {
  source = "./security_group"
  name = "redis-sg"
  vpc_id = aws_vpc.example.id
  port = 6379
  cidr_block = [ aws_vpc.example.cidr_block ]
}
