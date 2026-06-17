# Public Release Checklist

Use this checklist before changing this repository to public visibility.

## Required before publishing

- Rotate any credentials that were ever committed to the repository history.
- Do not publish the existing git history until it has been scanned and cleaned.
- Prefer creating a fresh public repository from the sanitized working tree if history cleanup is not required.
- Run a history-aware secret scanner such as `gitleaks` or `trufflehog` before publishing.
- Review Terraform variables, Infracost config, dashboards, and operational scripts for environment-specific identifiers.

## Values that must stay out of the public repository

- Database passwords and replication passwords.
- Cloud credentials, kubeconfigs, private keys, certificates, and Terraform state.
- Real AWS account IDs, ARNs, VPC IDs, subnet IDs, security group IDs, and load balancer DNS names.
- Real internal IP addresses, VPN ranges, hostnames, and topology-specific dashboard variables.
- Production domain names unless they are intentionally public.

## Current repository convention

- Public examples use placeholder account ID `000000000000`.
- Public examples use `example.com` for domains.
- Public examples use documentation IP ranges such as `192.0.2.0/24`, `198.51.100.0/24`, and `203.0.113.0/24`.
- Runtime secrets should be provided through environment variables or a secret manager, not committed files.
