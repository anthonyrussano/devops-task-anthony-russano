output "alb_dns_name" {
  description = "Public DNS name of the application load balancer."
  value       = aws_lb.app.dns_name
}

output "allowed_ingress_cidrs" {
  description = "Finite CIDRs allowed to reach the public ALB."
  value       = var.allowed_ingress_cidrs
}

output "app_has_direct_internet_route" {
  description = "The app route table intentionally has no 0.0.0.0/0 route."
  value       = false
}

output "egress_allowlist_domains" {
  description = "Domains allowed by the forward proxy for app startup and daily operation."
  value       = local.outbound_allowlist_domains
}

