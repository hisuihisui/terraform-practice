variable "ingress_rules" {
  # オブジェクトとして、ポートとcidrのペアを受け取る
  type = map (
    object (
      {
        port = number
        cidr_blocks = list(string)
      }
    )
  )
}

resource "aws_security_group" "default" {
  name = "complex-sg"

  # Dynamic blocks
  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      from_port = ingress.value.port
      to_port = ingress.value.port
      cidr_blocks = ingress.value.cidr_blocks
      protocol = "tcp"
      description = "Allow ${ingress.key}"
    }
  }
}
