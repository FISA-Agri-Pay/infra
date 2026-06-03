# Architecture Notes

This project uses a hybrid cloud architecture:

- On-prem Kubernetes: ledger DB, core financial APIs, payment approval APIs
- AWS EKS/MSK: product APIs, event processing, monitoring, Kafka-based messaging
- VESSL AI: H100-based vLLM serving for open-source LLM inference

The MCP server is separate from the vLLM server. MCP exposes safe backend tools to the LLM agent, while vLLM serves the base LLM model.
