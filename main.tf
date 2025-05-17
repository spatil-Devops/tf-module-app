resource "aws_security_group" "allow_all" {
  name        = "${var.name}-${var.env}"
  description = "${var.name}-${var.env}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = var.port_no
    to_port     = var.port_no
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "node" {
  ami           = data.aws_ami.ami.image_id
  instance_type = var.instance_type
  vpc_security_group_ids = [aws_security_group.allow_all.id]

  tags = {
    Name = "${var.name}-${var.env}"
  }
}

resource "aws_route53_record" "record" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = "${var.name}-${var.env}.sdevopsp25.site"
  type    = "A"
  ttl     = 30
  records = [aws_instance.node.private_ip]
}

resource "null_resource" "provisioner" {
  depends_on = [aws_route53_record.record]
  provisioner "local-exec" {
    command = "sleep 120; cd /home/ec2-user/expense-shell; ansible-playbook -i ${aws_instance.node.private_ip}, -e ansible_user=ec2-user -e ansible_password=DevOps321 -e role_name=${var.name} -e env=dev expense.yml"
  }
}