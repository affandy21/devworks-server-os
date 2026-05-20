# Security Policy

## Supported Versions

Devworks Server OS is currently in preview. Security fixes should target the latest preview branch unless a stable release branch is created.

## Reporting Vulnerabilities

Do not open public issues for sensitive security problems.

Report privately to the Devworks maintainer or repository owner with:

- A clear description of the issue.
- Affected files or components.
- Reproduction steps.
- Expected impact.
- Suggested mitigation if available.

## Security Baseline

Production deployments should:

- Change the default password immediately.
- Prefer SSH keys over password login.
- Restrict SSH by firewall or trusted IP range.
- Keep UFW enabled.
- Keep Fail2ban enabled.
- Keep unattended security updates enabled.
- Use valid TLS certificates for public services.
- Avoid exposing local admin tooling publicly.

