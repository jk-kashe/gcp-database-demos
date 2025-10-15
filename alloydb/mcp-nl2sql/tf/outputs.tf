output "pagila_db_setup_completion" {
  description = "The ID of the null_resource that indicates pagila DB setup is complete."
  value       = null_resource.pagila_db_setup.id
}