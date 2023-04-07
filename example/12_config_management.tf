#SSMパラメータストア

# 平文
resource "aws_ssm_parameter" "db_username" {
  name = "/db/username"
  value = "root"
  # 平文のまま保存
  type = "String"
  description = "データベースのユーザー名"
}

# 暗号化
# ダミー値を設定しておき、CLI等で後から値を更新する
resource "aws_ssm_parameter" "db_password" {
  name = "/db/password"
  value = "uninitialized"
  # 暗号化して保存
  type = "SecureString"
  description = "データベースのパスワード"

  lifecycle {
    # 値の更新を無視して、plan時に差分が出ないようにする
    ignore_changes = [
      value
    ]
  }
}

# aws ssm put-parameter --name '/ db/ password' --type SecureString --value "ModifiedStrongPassword!" --overwrite
