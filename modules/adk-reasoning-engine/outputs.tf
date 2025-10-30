output "reasoning_engine_resource_name" {
  description = "The resource name of the deployed ADK Reasoning Engine."
  value       = trimspace(data.local_file.reasoning_engine.content)
}