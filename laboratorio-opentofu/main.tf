# =============================================================================
# PP6 - Práctica Profesional VI
# Infrastructure as Code con OpenTofu
# main.tf — Configuración principal de infraestructura AWS
#
# NOTA: Este archivo es 100% compatible con Terraform.
# La única diferencia está en el comando: "tofu" en lugar de "terraform".
# =============================================================================

# -----------------------------------------------------------------------------
# TERRAFORM/TOFU CONFIG — Versiones y providers requeridos
# -----------------------------------------------------------------------------
terraform {
  required_version = ">= 1.6"   # OpenTofu >= 1.6 soporta todas estas features

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
  # OpenTofu usa el mismo formato de backend que Terraform.
  # El estado (terraform.tfstate) es 100% compatible entre ambas herramientas.

  # ─── BACKEND REMOTO — S3 + DynamoDB (comentado) ───────────────────────────
  # Idéntico al de Terraform. OpenTofu soporta todos los backends de Terraform.
  #
  # backend "s3" {
  #   bucket         = "pp6-terraform-state-<ACCOUNT_ID>"
  #   key            = "laboratorio/opentofu.tfstate"
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

  default_tags {
    tags = {
      Proyecto     = var.project_name
      Ambiente     = var.environment
      Creado_Por   = "OpenTofu"    # Diferencia visible: qué herramienta lo creó
      Laboratorio  = "Infraestructura-como-Codigo"
      Gestionado   = "IaC-PP6"
    }
  }
}

# -----------------------------------------------------------------------------
# NETWORKING — VPC, Subnet, Internet Gateway, Route Table
# -----------------------------------------------------------------------------

resource "aws_vpc" "pp6_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "pp6-vpc-laboratorio"
  }
}

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

resource "aws_internet_gateway" "pp6_igw" {
  vpc_id = aws_vpc.pp6_vpc.id

  tags = {
    Name = "pp6-internet-gateway"
  }
}

resource "aws_route_table" "pp6_public_rt" {
  vpc_id = aws_vpc.pp6_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.pp6_igw.id
  }

  tags = {
    Name = "pp6-tabla-ruteo-publica"
  }
}

resource "aws_route_table_association" "pp6_public_rta" {
  subnet_id      = aws_subnet.pp6_public_subnet.id
  route_table_id = aws_route_table.pp6_public_rt.id
}

# -----------------------------------------------------------------------------
# SECURITY GROUP
# -----------------------------------------------------------------------------
resource "aws_security_group" "pp6_app_sg" {
  name_prefix = "pp6-app-"
  description = "Grupo de seguridad para la aplicacion PP6 IaC"
  vpc_id      = aws_vpc.pp6_vpc.id

  ingress {
    description = "Acceso SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_allowed_cidr]
  }

  ingress {
    description = "Aplicacion Web Python"
    from_port   = var.app_port
    to_port     = var.app_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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

  lifecycle {
    create_before_destroy = true
  }
}

# -----------------------------------------------------------------------------
# SSH KEY PAIR
# -----------------------------------------------------------------------------
resource "tls_private_key" "pp6_key_pair" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "pp6_key" {
  key_name   = "pp6-clave-ssh-${var.environment}"
  public_key = tls_private_key.pp6_key_pair.public_key_openssh

  tags = {
    Name = "pp6-clave-ssh"
  }
}

# -----------------------------------------------------------------------------
# EC2 INSTANCE
# -----------------------------------------------------------------------------
resource "aws_instance" "pp6_app" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.pp6_key.key_name
  vpc_security_group_ids      = [aws_security_group.pp6_app_sg.id]
  subnet_id                   = aws_subnet.pp6_public_subnet.id
  associate_public_ip_address = true

  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -e

    apt-get update -y
    apt-get install -y python3 net-tools curl

    mkdir -p /home/ubuntu/pp6-web
    cd /home/ubuntu/pp6-web

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
        .tofu { color: #FFDA18; }
      </style>
    </head>
    <body>
      <h1>&#x1F680; PP6 - Infrastructure as Code</h1>
      <p class="status">&#x2705; Servidor funcionando correctamente</p>
      <p>Esta instancia fue creada con <strong class="tofu">OpenTofu</strong> como parte del laboratorio de IaC.</p>
      <div>
        <span class="badge">&#x1F331; OpenTofu</span>
        <span class="badge">&#x1F527; Terraform-compatible</span>
        <span class="badge">&#x2601; AWS EC2</span>
        <span class="badge">&#x1F40D; Python3</span>
      </div>
    </body>
    </html>
    HTML

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

    chown -R ubuntu:ubuntu /home/ubuntu/pp6-web

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

    systemctl daemon-reload
    systemctl enable pp6-web.service
    systemctl start pp6-web.service
  EOF
  )

  tags = {
    Name = "pp6-instancia-iac"
    Tipo = "Servidor-Aplicacion"
  }

  provisioner "local-exec" {
    command = "echo 'Instancia creada con OpenTofu: ${self.public_ip}'"
  }
}
