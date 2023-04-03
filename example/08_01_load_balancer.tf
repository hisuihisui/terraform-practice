# ALB
resource "aws_lb" "example" {
  name = "example"
  # LBのタイプ
  # NLBなら、network と指定
  load_balancer_type = "application"
  # VPC内部向け → true
  # インターネット向け → false
  internal = false
  # タイムアウト
  idle_timeout = 60
  # 削除保護
  # 削除する場合には、falseにして一度 applyしてから削除可能
  enable_deletion_protection = true

  # ALBが所属するサブネット
  # 複数指定して、可用性を高める
  subnets = [
    aws_subnet.public_0.id,
    aws_subnet.public_1.id,
  ]

  # アクセスログ
  access_logs {
    # 出力先
    bucket = aws_s3_bucket.alb_log.id
    enabled = true
  }

  # セキュリティグループ
  security_groups = [
    module.http_sg.security_group_id,
    module.https_sg.security_group_id,
    module.http_redirect_sg.security_group_id,
  ]
}

# セキュリティグループ
module "http_sg" {
  source = "./security_group"
  name = "http-sg"
  vpc_id = aws_vpc.example.id
  port = 80
  cidr_block = [ "0.0.0.0/0" ]
}

module "https_sg" {
  source = "./security_group"
  name = "https-sg"
  vpc_id = aws_vpc.example.id
  port = 443
  cidr_block = [ "0.0.0.0/0" ]
}

module "http_redirect_sg" {
  source = "./security_group"
  name = "http-redirect-sg"
  vpc_id = aws_vpc.example.id
  port = 8080
  cidr_block = [ "0.0.0.0/0" ]
}

# HTTPリスナー
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.example.arn
  # ポート
  port = "80"
  # プロトコル
  # ALBでは、HTTP or HTTPS のみ
  protocol = "HTTP"

  # デフォルトアクション
  default_action {
    # forward:リクエストを別のターゲットグループに転送
    # fixed-response:固定のHTTPレスポンスを応答
    # redirect:別のURLにリダイレクト
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "これは「HTTP」です"
      status_code = "200"
    }
  }
}

# HTTPSリスナー
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.example.arn
  port = "443"
  protocol = "HTTPS"
  # SSL証明書
  certificate_arn = aws_acm_certificate.example.arn
  # セキュリティポリシー
  # AWS推奨のポリシーを指定しておく
  ssl_policy = "ELBSecurityPolicy-2016-08"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "これは「HTTPS」です"
      status_code = "200"
    }
  }
}

# HTTP→HTTPSへのリダイレクト
resource "aws_lb_listener" "redirect_http_to_https" {
  load_balancer_arn = aws_lb.example.arn
  port = "8080"
  protocol = "HTTP"

  default_action {
    # リダイレクト
    type = "redirect"

    redirect {
      port = "443"
      protocol = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# リクエストフォワーディング
# 特定のターゲットにリクエストを流す

# ターゲットグループ
resource "aws_lb_target_group" "example" {
  name = "example"
  # ターゲットタイプ
  # EC2, ip, Lambda関数など
  # Fargate の場合は ip を指定
  target_type = "ip"
  # target_type = "ip" の場合は、vpc_id, port, protocol が必要
  vpc_id = aws_vpc.example.id
  port = 80
  protocol = "HTTP"
  # 登録解除の待機時間
  deregistration_delay = 300

  # ヘルスチェック
  health_check {
    # 使用するパス
    path = "/"
    # 正常と判定する実行回数
    healthy_threshold = 5
    # 以上と判定する実行回数
    unhealthy_threshold = 2
    # タイムアウト時間（秒）
    timeout = 5
    # 実行間隔（秒）
    interval = 30
    # 正常と判断するステータスコード
    matcher = 200
    # ポート
    # traffic-port → 上で指定したポート
    port = "traffic-port"
    # プロトコル
    protocol = "HTTP"
  }

  depends_on = [
    aws_lb.example
  ]
}

# リスナールール
# 複数定義可能
resource "aws_lb_listener_rule" "example" {
  listener_arn = aws_lb_listener.https.arn
  # 優先順位
  # 数字が小さいほど、優先順位が高い
  # デフォルトルールは優先順位が最も低い
  priority = 100

  action {
    type = "forward"
    # ターゲットグループ
    target_group_arn = aws_lb_target_group.example.arn
  }

  # 条件
  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}

output "alb_dns_name" {
  value = aws_lb.example.dns_name
}
