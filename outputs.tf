output "football_api_public_ip" {
  value       = oci_core_instance.web.public_ip
  description = "Public IP of the football_api OCI instance"
}