output "apex_url" {
  description = "The URL of the APEX application."
  value       = "${module.cr_base.service_url}"
}