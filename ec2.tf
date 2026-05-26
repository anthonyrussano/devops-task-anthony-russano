resource "aws_instance" "egress_proxy" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = var.instance_type
  subnet_id                   = values(aws_subnet.public)[0].id
  vpc_security_group_ids      = [aws_security_group.egress_proxy.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.ec2_ssm.name
  key_name                    = var.ssh_key_name
  user_data_replace_on_change = true

  user_data = templatefile("${path.module}/templates/proxy-user-data.sh.tftpl", {
    egress_proxy_port       = var.egress_proxy_port
    allowed_domains         = local.outbound_allowlist_domains
    package_repository_host = var.package_repository_domain
    daily_operation_host    = var.daily_operation_domain
  })

  root_block_device {
    encrypted   = true
    volume_size = var.root_volume_size_gb
    volume_type = "gp3"
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tags = {
    Name = "${var.project_name}-egress-proxy"
    Role = "egress-control"
  }
}

resource "aws_instance" "app" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = var.instance_type
  subnet_id                   = values(aws_subnet.app)[0].id
  vpc_security_group_ids      = [aws_security_group.app.id]
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.ec2_ssm.name
  key_name                    = var.ssh_key_name
  user_data_replace_on_change = true

  user_data = templatefile("${path.module}/templates/app-user-data.sh.tftpl", {
    app_port                = var.app_port
    proxy_private_ip        = aws_instance.egress_proxy.private_ip
    egress_proxy_port       = var.egress_proxy_port
    package_repository_host = var.package_repository_domain
    daily_operation_host    = var.daily_operation_domain
  })

  root_block_device {
    encrypted   = true
    volume_size = var.root_volume_size_gb
    volume_type = "gp3"
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tags = {
    Name = "${var.project_name}-app"
    Role = "application"
  }
}

resource "aws_instance" "mysql" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = var.instance_type
  subnet_id                   = values(aws_subnet.db)[0].id
  vpc_security_group_ids      = [aws_security_group.mysql.id]
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.ec2_ssm.name
  key_name                    = var.ssh_key_name
  user_data_replace_on_change = true

  user_data = templatefile("${path.module}/templates/mysql-user-data.sh.tftpl", {
    mysql_port = var.mysql_port
  })

  root_block_device {
    encrypted   = true
    volume_size = var.root_volume_size_gb
    volume_type = "gp3"
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tags = {
    Name = "${var.project_name}-mysql"
    Role = "database"
  }
}

