# Infra

Hybrid cloud infrastructure repository for the BNPL LLM agent project.

This repository keeps infrastructure, deployment, and operations configuration separate from application code.

## Repository Structure

```text
infra/
├─ aws/
│  ├─ eks/
│  ├─ msk/
│  ├─ networking/
│  ├─ monitoring/
│  ├─ data/
│  ├─ dns/
│  ├─ edge-security/
│  ├─ web-edge/
│  ├─ storage/
│  ├─ ecr/
│  ├─ messaging/
│  ├─ alerting/
│  └─ bastion/
├─ vessl-ai/
│  └─ vllm/
├─ on-prem/
│  ├─ kubernetes/
│  └─ vpn/
└─ docs/
```

## Scope

- AWS EKS, MSK, networking, and monitoring configuration
- VESSL AI vLLM deployment manifests
- On-prem Kubernetes and site-to-site VPN notes
- Architecture and operations documentation

## Safety Rules

- Do not commit secrets, API keys, access tokens, kubeconfigs, or cloud credentials.
- Document cost impact for GPU, MSK, EKS, and persistent storage changes.
- Prefer dry-run, validation, or plan output before applying infrastructure changes.
