# =============================================================================
# PP6 - Práctica Profesional VI
# Infrastructure as Code con Terraform
# main.tf — Configuración principal de infraestructura AWS
# =============================================================================

# -----------------------------------------------------------------------------
# TERRAFORM CONFIG — Versiones y providers requeridos
# -----------------------------------------------------------------------------
terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  # ─── BACKEND LOCAL (por defecto para el laboratorio) ──────────────────────
  # El estado se guarda en terraform.tfstate en este directorio.
  # No requiere configuración adicional.

  # ─── BACKEND REMOTO — S3 + DynamoDB (comentado) ───────────────────────────
  # Descomentar para usar estado remoto en producción o trabajo en equipo.
  # Pasos previos:
  #   1. Crear el bucket S3:  aws s3api create-bucket --bucket pp6-terraform-state-<ACCOUNT_ID> --region us-east-1
  #   2. Crear la tabla DynamoDB: aws dynamodb create-table \
  #        --table-name pp6-terraform-locks \
  #        --attribute-definitions AttributeName=LockID,AttributeType=S \
  #        --key-schema AttributeName=LockID,KeyType=HASH \
  #        --billing-mode PAY_PER_REQUEST
  #
  # backend "s3" {
  #   bucket         = "pp6-terraform-state-<ACCOUNT_ID>"
  #   key            = "laboratorio/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "pp6-terraform-locks"
  #   encrypt        = true
  # }
}

# -----------------------------------------------------------------------------
# PROVIDER AWS
# -----------------------------------------------------------------------------
provider "aws" {
  region = var.aws_region

  # Etiquetas aplicadas automáticamente a TODOS los recursos creados
  default_tags {
    tags = {
      Proyecto     = var.project_name
      Ambiente     = var.environment
      Creado_Por   = "Terraform"
      Laboratorio  = "Infraestructura-como-Codigo"
      Gestionado   = "IaC-PP6"
    }
  }
}

# -----------------------------------------------------------------------------
# NETWORKING — VPC, Subnet, Internet Gateway, Route Table
# -----------------------------------------------------------------------------

# VPC principal del laboratorio
resource "aws_vpc" "pp6_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "pp6-vpc-laboratorio"
  }
}

# Subnet pública — donde vivirá la instancia EC2
resource "aws_subnet" "pp6_public_subnet" {
  vpc_id                  = aws_vpc.pp6_vpc.id
  cidr_block              = var.subnet_cidr
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "pp6-subnet-publica"
    Tipo = "Publica"
  }
}

# Internet Gateway — permite tráfico entre la VPC e Internet
resource "aws_internet_gateway" "pp6_igw" {
  vpc_id = aws_vpc.pp6_vpc.id

  tags = {
    Name = "pp6-internet-gateway"
  }
}

# Route Table — define cómo rutear el tráfico
resource "aws_route_table" "pp6_public_rt" {
  vpc_id = aws_vpc.pp6_vpc.id

  # Ruta default: todo el tráfico (0.0.0.0/0) sale por el IGW
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.pp6_igw.id
  }

  tags = {
    Name = "pp6-tabla-ruteo-publica"
  }
}

# Asociación entre la subnet pública y la route table
resource "aws_route_table_association" "pp6_public_rta" {
  subnet_id      = aws_subnet.pp6_public_subnet.id
  route_table_id = aws_route_table.pp6_public_rt.id
}

# -----------------------------------------------------------------------------
# SECURITY GROUP — Reglas de firewall para la instancia
# -----------------------------------------------------------------------------
resource "aws_security_group" "pp6_app_sg" {
  name_prefix = "pp6-app-"
  description = "Grupo de seguridad para la aplicacion PP6 IaC"
  vpc_id      = aws_vpc.pp6_vpc.id

  # Regla de entrada: SSH (puerto 22)
  ingress {
    description = "Acceso SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_allowed_cidr]
  }

  # Regla de entrada: Aplicación web Python (puerto 3000)
  ingress {
    description = "Aplicacion Web Python"
    from_port   = var.app_port
    to_port     = var.app_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Regla de salida: todo el tráfico saliente permitido
  egress {
    description = "Todo el trafico saliente"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "pp6-grupo-seguridad-app"
  }

  # Evitar conflictos al recrear el security group
  lifecycle {
    create_before_destroy = true
  }
}

# -----------------------------------------------------------------------------
# SSH KEY PAIR — Generado automáticamente por Terraform
# -----------------------------------------------------------------------------

# Genera el par de claves RSA 2048 localmente
resource "tls_private_key" "pp6_key_pair" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Registra la clave pública en AWS
resource "aws_key_pair" "pp6_key" {
  key_name   = "pp6-clave-ssh-${var.environment}"
  public_key = tls_private_key.pp6_key_pair.public_key_openssh

  tags = {
    Name = "pp6-clave-ssh"
  }
}

# -----------------------------------------------------------------------------
# EC2 INSTANCE — Servidor con aplicación web Python
# -----------------------------------------------------------------------------
resource "aws_instance" "pp6_app" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.pp6_key.key_name
  vpc_security_group_ids      = [aws_security_group.pp6_app_sg.id]
  subnet_id                   = aws_subnet.pp6_public_subnet.id
  associate_public_ip_address = true

  # user_data: script que se ejecuta al iniciar la instancia por primera vez
  # Se usa base64encode() para evitar problemas de encoding
  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -e

    # Actualizar sistema e instalar dependencias
    apt-get update -y
    apt-get install -y python3 net-tools curl

    # Crear directorio de la aplicación
    mkdir -p /home/ubuntu/pp6-web
    cd /home/ubuntu/pp6-web

    # Crear página HTML
    cat > index.html << 'HTML'
    <!DOCTYPE html>
    <html lang="es">
    <head>
      <meta charset="UTF-8">
      <title>PP6 - Infrastructure as Code</title>
      <style>
        body { font-family: Arial, sans-serif; max-width: 800px; margin: 50px auto; padding: 20px; background: #0f1923; color: #fff; }
        h1 { color: #00d4aa; }
        .badge { display: inline-block; background: #1a2b3c; border: 1px solid #00d4aa; padding: 8px 16px; border-radius: 4px; margin: 5px; font-size: 14px; }
        .status { color: #10b981; font-weight: bold; }
      </style>
    </head>
    <body>
      <h1>&#x1F680; PP6 - Infrastructure as Code</h1>
      <p class="status">&#x2705; Servidor funcionando correctamente</p>
      <p>Esta instancia fue creada con <strong>Terraform / OpenTofu</strong> como parte del laboratorio de IaC.</p>
      <div>
        <span class="badge">&#x1F527; Terraform</span>
        <span class="badge">&#x1F331; OpenTofu</span>
        <span class="badge">&#x2601; AWS EC2</span>
        <span class="badge">&#x1F40D; Python3</span>
      </div>
    </body>
    </html>
    HTML

    # Crear servidor web Python
    cat > servidor.py << 'PYTHON'
    import http.server
    import socketserver
    import os

    PORT = 3000
    WEB_DIR = "/home/ubuntu/pp6-web"

    os.chdir(WEB_DIR)
    Handler = http.server.SimpleHTTPRequestHandler

    with socketserver.TCPServer(("", PORT), Handler) as httpd:
        print(f"Servidor escuchando en puerto {PORT}")
        httpd.serve_forever()
    PYTHON

    # Asignar permisos correctos
    chown -R ubuntu:ubuntu /home/ubuntu/pp6-web

    # Crear servicio systemd para que el servidor sobreviva reinicios
    cat > /etc/systemd/system/pp6-web.service << 'SERVICE'
    [Unit]
    Description=PP6 Web Server - Infrastructure as Code Lab
    After=network.target

    [Service]
    Type=simple
    User=ubuntu
    WorkingDirectory=/home/ubuntu/pp6-web
    ExecStart=/usr/bin/python3 /home/ubuntu/pp6-web/servidor.py
    Restart=on-failure
    RestartSec=5

    [Install]
    WantedBy=multi-user.target
    SERVICE

    # Habilitar e iniciar el servicio
    systemctl daemon-reload
    systemctl enable pp6-web.service
    systemctl start pp6-web.service
  EOF
  )

  tags = {
    Name = "pp6-instancia-iac"
    Tipo = "Servidor-Aplicacion"
  }

  # Esperar a que la instancia esté lista antes de que Terraform declare éxito
  provisioner "local-exec" {
    command = "echo 'Instancia creada: ${self.public_ip} — Esperar 2-3 min para que user_data finalice'"
  }
}
