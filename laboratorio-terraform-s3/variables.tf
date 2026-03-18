# variables.tf - Define las variables del proyecto.
# Incluye el nombre del bucket S3 y la región de AWS.

variable "bucket_name" {
  description = "Nombre del bucket S3 para el sitio estático"
  type        = string
  default     = "mi-sitio-estatico-roxs-s3"
}

variable "aws_region" {
  description = "Región de AWS donde se despliega el bucket"
  type        = string
  default     = "us-west-2"
}
