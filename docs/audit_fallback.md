# Five-Day Audit Fallback

If the full Terraform rollout cannot be completed before the external audit, use a short-lived compensating control plan and document the implementation evidence.

## Five-day execution plan

- **Day 1:** Freeze manual network changes, inventory current ALB/security groups/subnets/routes, confirm the finite source IP list with Tomasz, and align the intended compensating control with the QSA.
- **Day 2:** Apply inbound containment: finite ALB source CIDRs, app inbound from ALB SG only, MySQL inbound from app SG only, no SSH/public access to app or DB.
- **Day 3:** Apply outbound containment: remove default app/DB egress, add the temporary proxy/firewall path, and verify only `example.com`, `secureweb.com`, and required OS repos are reachable.
- **Day 4:** Enable evidence collection: ALB access logs, VPC Flow Logs, proxy/firewall logs, screenshots/CLI exports, and a signed change record.
- **Day 5:** Run a dry audit walkthrough: prove allowed inbound, denied inbound, allowed egress, denied egress, and management access through approved channels only.

## Immediate changes

- Restrict the existing ALB security group from `0.0.0.0/0` to the approved finite client CIDR list.
- Remove public IPs and direct inbound rules from the app and MySQL instances.
- Move MySQL to an isolated/private subnet if it is not already isolated.
- Change the app security group to allow inbound HTTP only from the ALB security group.
- Change the MySQL security group to allow TCP 3306 only from the app security group.
- Remove default outbound rules from app and MySQL security groups.
- Add an explicit egress control point for required domains: a forward proxy, AWS Network Firewall domain list, or another firewall already accepted by the QSA.
- Force app startup package installation and daily HTTPS calls through that egress control point.
- Enable ALB access logs, VPC Flow Logs, and proxy/firewall logs for audit evidence.
- Capture screenshots or CLI exports of route tables, security groups, ALB listeners, and logs after changes.

## Evidence to prepare

- Network diagram showing internet traffic terminates only at the public ALB.
- Security group export showing finite ALB source CIDRs and no direct internet ingress to CDE components.
- Route table export showing app and DB subnets do not have direct internet routes.
- Egress control configuration showing only `example.com` and `secureweb.com` are allowed for the app path.
- Test output showing denied internet sources cannot reach the ALB and app/DB instances cannot reach arbitrary external hosts.
- Change ticket or implementation notes mapping each change to PCI-DSS 1.3.1 and 1.3.2.

## Residual risks

- Manual changes are harder to reproduce and may drift before automation is merged.
- If the app depends on unlisted package mirrors, startup may fail until the dependency list is complete.
- The auditor may require additional PCI-DSS Requirement 1 controls beyond 1.3.1 and 1.3.2.
