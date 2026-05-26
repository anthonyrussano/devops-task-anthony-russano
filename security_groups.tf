resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "Public DMZ entry point. Inbound is restricted to approved source CIDRs."
  vpc_id      = aws_vpc.this.id

  tags = {
    Name = "${var.project_name}-alb-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  for_each = toset(var.allowed_ingress_cidrs)

  security_group_id = aws_security_group.alb.id
  description       = "Approved client CIDR to ALB HTTPS"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_ingress_rule" "alb_http_redirect" {
  for_each = toset(var.allowed_ingress_cidrs)

  security_group_id = aws_security_group.alb.id
  description       = "Approved client CIDR to ALB HTTP redirect"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_egress_rule" "alb_to_app" {
  security_group_id            = aws_security_group.alb.id
  description                  = "ALB forwards only to the private app instance"
  ip_protocol                  = "tcp"
  from_port                    = var.app_port
  to_port                      = var.app_port
  referenced_security_group_id = aws_security_group.app.id
}

resource "aws_security_group" "app" {
  name        = "${var.project_name}-app-sg"
  description = "Private app instance. No direct internet route or default outbound rule."
  vpc_id      = aws_vpc.this.id

  tags = {
    Name = "${var.project_name}-app-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "app_from_alb" {
  security_group_id            = aws_security_group.app.id
  description                  = "Application traffic from ALB only"
  ip_protocol                  = "tcp"
  from_port                    = var.app_port
  to_port                      = var.app_port
  referenced_security_group_id = aws_security_group.alb.id
}

resource "aws_vpc_security_group_egress_rule" "app_to_mysql" {
  security_group_id            = aws_security_group.app.id
  description                  = "Application database access"
  ip_protocol                  = "tcp"
  from_port                    = var.mysql_port
  to_port                      = var.mysql_port
  referenced_security_group_id = aws_security_group.mysql.id
}

resource "aws_vpc_security_group_egress_rule" "app_to_proxy" {
  security_group_id            = aws_security_group.app.id
  description                  = "Only outbound internet path is via explicit egress proxy"
  ip_protocol                  = "tcp"
  from_port                    = var.egress_proxy_port
  to_port                      = var.egress_proxy_port
  referenced_security_group_id = aws_security_group.egress_proxy.id
}

resource "aws_vpc_security_group_egress_rule" "app_to_vpc_endpoints" {
  security_group_id            = aws_security_group.app.id
  description                  = "SSM Session Manager via VPC interface endpoints (no internet path)"
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  referenced_security_group_id = aws_security_group.vpc_endpoints.id
}

resource "aws_vpc_security_group_egress_rule" "app_to_s3_endpoint" {
  security_group_id = aws_security_group.app.id
  description       = "S3 gateway endpoint for SSM artifacts and approved AWS package access"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  prefix_list_id    = aws_vpc_endpoint.s3.prefix_list_id
}

resource "aws_security_group" "mysql" {
  name        = "${var.project_name}-mysql-sg"
  description = "MySQL instance in isolated subnet."
  vpc_id      = aws_vpc.this.id

  tags = {
    Name = "${var.project_name}-mysql-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "mysql_from_app" {
  security_group_id            = aws_security_group.mysql.id
  description                  = "MySQL from app instance only"
  ip_protocol                  = "tcp"
  from_port                    = var.mysql_port
  to_port                      = var.mysql_port
  referenced_security_group_id = aws_security_group.app.id
}

resource "aws_vpc_security_group_egress_rule" "mysql_to_proxy" {
  security_group_id            = aws_security_group.mysql.id
  description                  = "Startup package install through egress proxy (production: pre-built AMI)"
  ip_protocol                  = "tcp"
  from_port                    = var.egress_proxy_port
  to_port                      = var.egress_proxy_port
  referenced_security_group_id = aws_security_group.egress_proxy.id
}

resource "aws_vpc_security_group_egress_rule" "mysql_to_vpc_endpoints" {
  security_group_id            = aws_security_group.mysql.id
  description                  = "SSM Session Manager via VPC interface endpoints (no internet path)"
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  referenced_security_group_id = aws_security_group.vpc_endpoints.id
}

resource "aws_vpc_security_group_egress_rule" "mysql_to_s3_endpoint" {
  security_group_id = aws_security_group.mysql.id
  description       = "S3 gateway endpoint for SSM artifacts and approved AWS package access"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  prefix_list_id    = aws_vpc_endpoint.s3.prefix_list_id
}

resource "aws_security_group" "egress_proxy" {
  name        = "${var.project_name}-egress-proxy-sg"
  description = "Controlled egress proxy for app startup and daily HTTPS dependencies."
  vpc_id      = aws_vpc.this.id

  tags = {
    Name = "${var.project_name}-egress-proxy-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "proxy_from_app" {
  security_group_id            = aws_security_group.egress_proxy.id
  description                  = "Forward proxy access from app instance"
  ip_protocol                  = "tcp"
  from_port                    = var.egress_proxy_port
  to_port                      = var.egress_proxy_port
  referenced_security_group_id = aws_security_group.app.id
}

resource "aws_vpc_security_group_ingress_rule" "proxy_from_mysql" {
  security_group_id            = aws_security_group.egress_proxy.id
  description                  = "Forward proxy access from MySQL instance (startup package install only)"
  ip_protocol                  = "tcp"
  from_port                    = var.egress_proxy_port
  to_port                      = var.egress_proxy_port
  referenced_security_group_id = aws_security_group.mysql.id
}

resource "aws_vpc_security_group_egress_rule" "proxy_http" {
  security_group_id = aws_security_group.egress_proxy.id
  description       = "Proxy can fetch HTTP package metadata for allowlisted domains"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "proxy_https" {
  security_group_id = aws_security_group.egress_proxy.id
  description       = "Proxy can connect to HTTPS for allowlisted domains"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}
