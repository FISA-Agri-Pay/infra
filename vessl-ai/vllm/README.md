# vLLM on VESSL AI

This directory stores deployment manifests for running open-source LLMs with vLLM on VESSL AI H100.

## Model Candidates

- Development: `Qwen/Qwen3-14B`
- Demo: `Qwen/Qwen3-32B`

## Scheduling Scope

For a single H100 setup, scheduling means LLM inference request scheduling inside and around vLLM. It is not Kubernetes GPU node selection scheduling.

Use queue priority, max tokens, chunking, timeout, retry, and backpressure policies to control real-time and batch workloads.
