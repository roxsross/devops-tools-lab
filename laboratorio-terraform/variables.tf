# =============================================================================
# PP6 - Práctica Profesional VI
# Infrastructure as Code con Terraform
# variables.tf — Definición de variables configurables
# =============================================================================

variable "aws_region" {
  description = "Región de AWS donde se van a crear todos los recursos"
  type        = string
  default     = "us-east-1"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.aws_region))
    error_message = "La región debe tener formato válido, ej: us-east-1, sa-east-1."
  }
}

variable "environment" {
  description = "Ambiente de trabajo (laboratorio, dev, staging, prod)"
  type        = string
  default     = "laboratorio"
}

variable "instance_type" {
  description = "Tipo de instancia EC2 (t2.micro es elegible para Free Tier)"
  type        = string
  default     = "t2.micro"
}

variable "ami_id" {
  description = "ID de la imagen Ubuntu 22.04 LTS en us-east-1"
  type        = string
  default     = "ami-0866a3c8686eaeeba"
  # Para otras regiones buscar: ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*
}

variable "vpc_cidr" {
  description = "Bloque CIDR para la VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "Bloque CIDR para la subnet pública"
  type        = string
  default     = "10.0.1.0/24"
}

variable "app_port" {
  description = "Puerto en el que corre la aplicación web Python"
  type        = number
  default     = 3000
}

variable "ssh_allowed_cidr" {
  description = "CIDR permitido para SSH. ADVERTENCIA: 0.0.0.0/0 permite acceso desde cualquier IP."
  type        = string
  default     = "0.0.0.0/0"
  # Buena práctica en producción: usar tu IP pública, ej: "203.0.113.42/32"
}

variable "project_name" {
  description = "Nombre del proyecto, usado para etiquetar recursos"
  type        = string
  default     = "PP6-IaC"
}
