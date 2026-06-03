# VESSL AI

VESSL AI deployment configuration for GPU-based LLM serving.

The vLLM server is deployed separately from the MCP server. The MCP server calls the vLLM OpenAI-compatible API and exposes backend tools to the LLM agent.
