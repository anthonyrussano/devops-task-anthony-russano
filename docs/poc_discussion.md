# POC Discussion Notes

## What the POC demonstrates

- A dedicated VPC replaces the flat default VPC pattern.
- Public internet traffic is limited to the public ALB in DMZ subnets.
- ALB inbound traffic is restricted to a finite list of approved source CIDRs.
- App and MySQL instances are not public and do not accept direct internet inbound traffic.
- App-to-DB traffic is restricted to MySQL from the app security group.
- The app subnet has no default route to the internet.
- App outbound internet access is forced through a controlled proxy that allowlists `example.com` and `secureweb.com`.
- EC2 access uses SSM Session Manager instead of opening SSH.

## Production improvements

- Replace single EC2 instances with Auto Scaling Groups across private subnets.
- Replace the MySQL EC2 instance with Amazon RDS or Aurora if acceptable for the assignment and compliance scope.
- Replace the simple proxy with AWS Network Firewall, a managed egress firewall, or an existing enterprise proxy with central policy and logging.
- Use a private package mirror or golden AMI so app startup does not depend on public package repositories.
- Add AWS WAF on the ALB for L7 protections and managed IP sets.
- Add VPC endpoints for SSM, CloudWatch Logs, Secrets Manager, and other AWS APIs required by operations.
- Add centralized logging, alerting, GuardDuty, AWS Config rules, and CI/CD policy checks.
- Use remote Terraform state with locking and pull-request review before infrastructure changes.

## Questions for Tomasz

- Which exact source IP ranges should be allowed to reach the ALB during the audit?
- Is the ALB required to keep port 80 open for redirect, or should HTTPS-only be enforced?
- Is `example.com` accessed over HTTPS, HTTP, or both?
- Are there additional package mirror hostnames behind `example.com` that must be allowlisted?
- Does `secureweb.com` resolve to stable endpoints or require wildcard/subdomain allowlisting?
- Is a forward proxy acceptable for the POC, or is AWS Network Firewall preferred for the final design?
- Is the MySQL EC2 instance a hard requirement, or can the final recommendation use RDS?

