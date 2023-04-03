# ホストゾーン
# Route53でドメイン登録した際に自動で作成
# NSレコードとSOAレコードも自動で作成される

# ホストゾーンの参照
# data "aws_route53_zone" "example" {
#   name = "example.com"
# }

# ホストゾーンの作成
resource "aws_route53_zone" "example" {
  name = "example.com"
}

# DNSレコードの定義
resource "aws_route53_record" "example" {
  # ホストゾーン
  zone_id = aws_route53_zone.example.id
  # 設定するドメイン（FQDN）
  name = aws_route53_zone.example.name
  # レコードタイプ
  type = "A"

  # エイリアス
  alias {
    name = aws_lb.example.dns_name
    zone_id = aws_lb.example.zone_id
    evaluate_target_health = true
  }
}

output "domain_name" {
  value = aws_route53_record.example.name
}


# ACM
# 証明書の作成
resource "aws_acm_certificate" "example" {
  # ドメイン名
  # *.example.com というワイルドカードでも指定可能
  domain_name = aws_route53_record.example.name
  # ドメインを追加する場合はリストで指定
  subject_alternative_names = [ ]
  # 検証方法
  # DNS or EMAIL
  # 自動更新したいなら、DNSを選択
  validation_method = "DNS"

  # ライフサイクル
  # Terraform独自の機能
  lifecycle {
    # 新規作成してから、古いリソースを削除する
    create_before_destroy = true
  }
}

# SSL証明書の検証
# 検証用DNSレコード
resource "aws_route53_record" "example_certification" {

  for_each = {
    for dvo in aws_acm_certificate.example.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  name = each.value.name
  type = each.value.type
  # 検証するレコード
  # subject_alternative_names がある場合には複数指定
  records = [ each.value.record ]
  zone_id = aws_route53_zone.example.id
  ttl = 60
}

# 検証の待機
resource "aws_acm_certificate_validation" "example" {
  certificate_arn = aws_acm_certificate.example.arn
  validation_record_fqdns = [ for record in aws_route53_record.example_certification : record.fqdn ]
}
