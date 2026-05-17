provider "aws" {
  region = var.aws_region
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "aws_security_group" "monitoring" {
  name        = "${var.project_name}-sg"
  description = "Monitoring stack access"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.monitoring_allowed_cidr]
  }

  ingress {
    description = "Grafana"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = [var.monitoring_allowed_cidr]
  }

  ingress {
    description = "Prometheus"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = [var.monitoring_allowed_cidr]
  }

  ingress {
    description = "Alertmanager"
    from_port   = 9093
    to_port     = 9093
    protocol    = "tcp"
    cidr_blocks = [var.monitoring_allowed_cidr]
  }

  ingress {
    description = "OTLP HTTP from app server"
    from_port   = 4318
    to_port     = 4318
    protocol    = "tcp"
    cidr_blocks = ["${var.app_server_ip}/32"]
  }

  ingress {
    description = "OTLP gRPC from app server"
    from_port   = 4317
    to_port     = 4317
    protocol    = "tcp"
    cidr_blocks = ["${var.app_server_ip}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-sg"
  }
}

resource "aws_instance" "monitoring" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.monitoring.id]

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  tags = {
    Name    = "${var.project_name}-server"
    Project = var.project_name
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(pathexpand(var.ssh_private_key_path))
    host        = self.public_ip
  }

  provisioner "file" {
    source      = "../config"
    destination = "/tmp/anvila-observability-config"
  }

  provisioner "file" {
    source      = "../scripts/install_monitoring.sh"
    destination = "/tmp/install_monitoring.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/install_monitoring.sh",
      "sudo SLACK_WEBHOOK_URL='${var.slack_webhook_url}' STAGING_URL='${var.staging_url}' PRODUCTION_URL='${var.production_url}' APP_SERVER_IP='${var.app_server_ip}' /tmp/install_monitoring.sh"
    ]
  }
}
