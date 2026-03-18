# outputs.tf - Muestra el endpoint del sitio web estático del bucket S3.

output "website_endpoint" {
  description = "URL del sitio web estático en S3"
  value       = aws_s3_bucket_website_configuration.sitio.website_endpoint
}
