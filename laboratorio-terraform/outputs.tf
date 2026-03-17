# =============================================================================
# PP6 - Práctica Profesional VI
# Infrastructure as Code con Terraform
# outputs.tf — Valores exportados después del despliegue
# =============================================================================

output "ip_publica_instancia" {
  description = "IP pública de la instancia EC2"
  value       = aws_instance.pp6_app.public_ip
}

output "dns_publico_instancia" {
  description = "DNS público asignado por AWS a la instancia"
  value       = aws_instance.pp6_app.public_dns
}

output "url_aplicacion" {
  description = "URL completa para acceder a la aplicación web"
  value       = "http://${aws_instance.pp6_app.public_ip}:${var.app_port}"
}

output "comando_ssh" {
  description = "Comando listo para conectarse por SSH a la instancia"
  value       = "ssh -i pp6-clave-ssh.pem ubuntu@${aws_instance.pp6_app.public_ip}"
}

output "instancia_id" {
  description = "ID único de la instancia EC2 en AWS"
  value       = aws_instance.pp6_app.id
}

output "vpc_id" {
  description = "ID de la VPC creada"
  value       = aws_vpc.pp6_vpc.id
}

output "subnet_id" {
  description = "ID de la subnet pública"
  value       = aws_subnet.pp6_public_subnet.id
}

output "security_group_id" {
  description = "ID del Security Group de la aplicación"
  value       = aws_security_group.pp6_app_sg.id
}

output "clave_privada_ssh" {
  description = "Clave privada SSH en formato PEM — MANTENER SECRETA, nunca commitear a Git"
  value       = tls_private_key.pp6_key_pair.private_key_pem
  sensitive   = true
  # Para exportar: terraform output -raw clave_privada_ssh > pp6-clave-ssh.pem && chmod 600 pp6-clave-ssh.pem
}

output "resumen_infraestructura" {
  description = "Resumen de todos los recursos desplegados"
  value = {
    region        = var.aws_region
    ambiente      = var.environment
    instancia_id  = aws_instance.pp6_app.id
    tipo_instancia = var.instance_type
    ip_publica    = aws_instance.pp6_app.public_ip
    url_app       = "http://${aws_instance.pp6_app.public_ip}:${var.app_port}"
    vpc_cidr      = var.vpc_cidr
  }
}
