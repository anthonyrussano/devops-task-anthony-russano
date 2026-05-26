# POC Discussion Notes

## What the POC demonstrates

- A dedicated VPC replaces the flat default-VPC pattern.
- Public internet traffic terminates only at the internet-facing ALB in public DMZ subnets.
- ALB inbound is restricted to a finite list of approved source CIDRs (PCI 1.3.1).
- App and MySQL instances have no public IPs and accept no direct internet inbound traffic.
- App-to-DB traffic is restricted to MySQL TCP 3306 from the app security group only.
- The app and DB subnet route tables have no default internet route (PCI 1.3.2).
- Required outbound calls (`example.com`, `secureweb.com`) are forced through a Squid proxy with a hostname allowlist; all other outbound is blocked at the security group.
- EC2 management uses SSM Session Manager via VPC interface endpoints — no SSH, no bastion, no internet path for control-plane traffic.
- VPC Flow Logs (all traffic) are shipped to CloudWatch Logs for audit evidence.
- ALB access logs are written to a dedicated S3 bucket for audit evidence.
- EBS volumes on all instances are encrypted at rest.
- IMDSv2 is enforced (hop-limit 1) on all instances to prevent SSRF credential theft.

## Instance connectivity matrix

| Source        | Destination     | Port | Path                        |
|---------------|-----------------|------|-----------------------------|
| Approved CIDRs | ALB            | 443  | Internet → ALB SG           |
| Approved CIDRs | ALB            | 80   | Redirected to 443           |
| ALB           | App EC2         | 80   | ALB SG → App SG             |
| App EC2       | MySQL EC2       | 3306 | App SG → MySQL SG           |
| App EC2       | Egress proxy    | 3128 | App SG → Proxy SG           |
| MySQL EC2     | Egress proxy    | 3128 | MySQL SG → Proxy SG (startup only) |
| App/MySQL EC2 | SSM endpoints   | 443  | App/MySQL SG → Endpoint SG  |
| Proxy         | Internet        | 80/443 | Public subnet via IGW (allowlisted domains only) |

## VPC endpoint design

SSM Session Manager requires the agent to call three AWS APIs:
`ssm`, `ssmmessages`, and `ec2messages`. Without VPC interface endpoints,
those calls would traverse the internet — unavailable to private instances
with no internet route. The POC provisions interface endpoints in the private
app subnets so both the app and MySQL instances reach SSM via the AWS
backbone, never touching the internet.

An S3 gateway endpoint (free) is also added to the app and DB route tables.
This keeps S3-backed SSM artefacts, CloudWatch agent payloads, and Amazon
Linux package S3 downloads off the internet path.

## Why Squid for egress control

Squid is the simplest demonstration of the principle: all outbound from CDE
components is funnelled through a single controlled point with an explicit
hostname allowlist. In production the preferred replacement is **AWS Network
Firewall** with FQDN-based stateful rules — managed, highly available,
integrated with CloudWatch, and auditor-familiar. The security group and route
table structure in this POC would remain identical; only the proxy EC2 would
be replaced.

## POC guardrails and limitations

- `allowed_ingress_cidrs` validates that at least one IPv4 CIDR is supplied and rejects `0.0.0.0/0`.
- App and DB security groups have no default egress; every outbound path is represented as a named Terraform rule.
- ALB access logging is created with an explicit bucket policy dependency so AWS log-delivery validation does not race the policy attachment.
- The Squid proxy is intentionally single-instance for the POC. It proves the control objective but is not the final HA design.
- The app startup package from `example.com` is represented as a placeholder artifact fetch because the real package name, signature, and repository path were not provided.
- No `terraform plan/apply` was run locally because deployment needs real AWS credentials, an ACM certificate ARN, and the approved ingress source list.

## Production improvements

- Replace single EC2 app instance with an Auto Scaling Group across private subnets.
- Replace MySQL EC2 with Amazon RDS Multi-AZ (removes DB patch/OS burden, adds automated backups).
- Replace the Squid proxy with AWS Network Firewall (HA, centrally managed, CloudWatch metrics).
- Use a private package mirror or pre-hardened golden AMI so DB instances require no internet egress at all during startup.
- Add VPC endpoints for CloudWatch Logs, Secrets Manager, and KMS so log shipping and secret retrieval also stay within the AWS network.
- Add AWS WAF on the ALB for L7 protections (managed rule groups, rate limiting).
- Add GuardDuty, AWS Config rules, and Security Hub for continuous compliance posture.
- Use remote Terraform state (S3 + DynamoDB locking) with pull-request review gates before any infrastructure change.
- Add CloudWatch Logs metric filters and alarms on Flow Logs rejected traffic for real-time alerting.

## Questions for Tomasz

- Which exact source IP ranges should be in `allowed_ingress_cidrs` for the audit?
- Should port 80 remain open on the ALB for the HTTP→HTTPS redirect, or enforce HTTPS-only at the DNS/CDN layer?
- Is `example.com` accessed over HTTPS, HTTP, or both? Are there additional CDN or mirror hostnames behind it?
- Does `secureweb.com` resolve to stable IPs, or do we need subdomain/wildcard allowlisting?
- Is a Squid proxy acceptable to the QSA for the POC, or is AWS Network Firewall required from the start?
- Is the MySQL EC2 a hard requirement, or can the final recommendation use RDS?
- Are there additional AWS service APIs the app calls (Secrets Manager, SQS, etc.) that would need VPC endpoints?
