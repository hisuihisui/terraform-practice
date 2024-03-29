variable "ports" {
  # リストで受け取る
  type = list(number)
}

resource "aws_security_group" "default" {
  name = "simple-sg"

  # Dynamic blocks
  dynamic "ingress" {
    for_each = var.ports
    content {
      from_port = ingress.value
      to_port = ingress.value
      cidr_blocks = [ "0.0.0.0/0" ]
      protocol = "tcp"
    }
  }
}
