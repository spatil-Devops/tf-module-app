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

  ingress {
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = var.prometheus_servers
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "nginx-exporter-port" {
  count             = var.name == "frontend" ? 1 : 0
  type              = "ingress"
  from_port         = 9113
  to_port           = 9113
  protocol          = "tcp"
  cidr_blocks       = var.prometheus_servers
  security_group_id = aws_security_group.allow_all.id
}

resource "aws_security_group_rule" "grok-exporter-port" {
  count             = var.name == "frontend" ? 1 : 0
  type              = "ingress"
  from_port         = 9144
  to_port           = 9144
  protocol          = "tcp"
  cidr_blocks       = var.prometheus_servers
  security_group_id = aws_security_group.allow_all.id
}

resource "aws_instance" "node" {
  ami           = data.aws_ami.ami.image_id
  instance_type = var.instance_type
  vpc_security_group_ids = [aws_security_group.allow_all.id]

  tags = {
    Name = "${var.name}-${var.env}"
    Monitor = "yes"
    Env = var.env
    Component = var.name
  }

  # this is not to recreate machines when run again and again
  lifecycle {
    ignore_changes = [
      "ami"
    ]
  }
}

resource "aws_route53_record" "record" {
  zone_id = var.zone_id
  name    = "${var.name}-${var.env}.sdevopsp25.site"
  type    = "A"
  ttl     = 30
  records = [aws_instance.node.private_ip]
}

resource "null_resource" "provisioner" {
  depends_on = [aws_route53_record.record]

  # Trigger this null resource when the id changes
  triggers = {
    instance_id = aws_instance.node.id
  }
  connection {
    host     = aws_instance.node.private_ip
    type     = "ssh"
    user     = "ec2-user"
    password = var.SSH_PASSWORD
  }
  provisioner "remote-exec" {
    inline= ["sudo labauto ansible",
    "ansible-pull -i localhost, -U https://github.com/spatil-Devops/expense-shell.git -e role_name=${var.name} -e env=${var.env} -e vault_token=${var.vault_token} expense.yml"]
  }
}