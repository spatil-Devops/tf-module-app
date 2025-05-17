data "aws_route53_zone" "zone" {
  name         = "sdevopsp25.site"
  private_zone = false
}

data "aws_security_group" "allow-all" {
  filter {
    name = "group-name"
    values = ["allow-all"]
  }
}

data "aws_ami" "ami" {
  most_recent      = true
  name_regex       = "RHEL-9-DevOps-Practice"
  owners           = ["973714476881"]
}