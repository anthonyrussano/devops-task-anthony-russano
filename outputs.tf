output "alb_dns_name" {
  description = "Public DNS name of the internet-facing application load balancer."
  value       = aws_lb.app.dns_name
}

output "allowed_ingress_cidrs" {
  description = "Finite CIDRs permitted to reach the public ALB (PCI 1.3.1)."
  value       = var.allowed_ingress_cidrs
}

output "app_has_direct_internet_route" {
  description = "The app route table intentionally has no 0.0.0.0/0 route (PCI 1.3.2)."
  value       = false
}

output "egress_allowlist_domains" {
  description = "Domains allowed by the forward proxy for app/DB startup and daily operation."
  value       = local.outbound_allowlist_domains
}

output "vpc_flow_logs_log_group" {
  description = "CloudWatch Logs group for VPC Flow Logs (PCI audit evidence)."
  value       = aws_cloudwatch_log_group.vpc_flow_logs.name
}

output "alb_access_logs_bucket" {
  description = "S3 bucket storing ALB access logs (PCI audit evidence)."
  value       = aws_s3_bucket.alb_logs.bucket
}

output "ssm_vpc_endpoints" {
  description = "VPC interface endpoint IDs for SSM (allows private instance management without internet access)."
  value       = { for k, v in aws_vpc_endpoint.ssm_services : k => v.id }
}
