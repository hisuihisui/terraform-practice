# null_resource：何もしないリソース
resource "null_resource" "overwrite" {}
resource "null_resource" "bar" {}

# resource "aws_instance" "remove" {
#   ami = "ami-0c3fd0f5d33134a76"
#   instance_type = "t2.micro"
# }

# resource "null_resource" "before" {}
resource "null_resource" "after" {}

# module "before" {
#   source = "./rename"
# }

module "after" {
  source = "./rename"
}
