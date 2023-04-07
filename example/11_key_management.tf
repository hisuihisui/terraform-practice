# KMS
# カスタマーマスターキー
resource "aws_kms_key" "example" {
  description = "Example Customer Key"
  # 自動ローテーション機能
  # 年に1度
  enable_key_rotation = true
  # カスタマーマスターキーの有効化/無効化
  is_enabled = true
  # 削除待機期間
  # カスタマーマスターキーの削除は非推奨
  deletion_window_in_days = 30
}

# エイリアス
resource "aws_kms_alias" "example" {
  # 設定する名前
  # "alias/"というプレフィックスが必要
  name = "alias/example"
  target_key_id = aws_kms_key.example.key_id
}
