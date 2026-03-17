# PP6 - Infrastructure as Code
## Terraform + OpenTofu + AWS · Práctica Profesional VI

Proyecto completo de laboratorio que demuestra Infrastructure as Code usando Terraform y OpenTofu para desplegar infraestructura en AWS.

---

## Estructura del proyecto

```
pp6-iac/
├── setup.sh                        ← Instalación automática de herramientas
├── README.md                       ← Este archivo
│
├── laboratorio-terraform/          ← Proyecto Terraform
│   ├── main.tf                     ← VPC, subnet, EC2, SG, key pair
│   ├── variables.tf                ← Variables configurables
│   ├── outputs.tf                  ← Valores exportados post-deploy
│   ├── terraform.tfvars            ← Valores del laboratorio
│   ├── backend-remoto.tf.ejemplo   ← Guía para S3 + DynamoDB (opcional)
│   ├── .gitignore
│   └── README.md
│
└── laboratorio-opentofu/           ← Proyecto OpenTofu (idéntico en .tf)
    ├── main.tf                     ← Mismo que Terraform, comando: tofu
    ├── variables.tf
    ├── outputs.tf
    ├── terraform.tfvars
    ├── .gitignore
    └── README.md
```

---

## Inicio rápido

### Paso 1: Instalar herramientas

```bash
bash setup.sh
```

Instala automáticamente: Terraform, OpenTofu, AWS CLI v2.

### Paso 2: Configurar credenciales AWS

```bash
aws configure
# Access Key ID: <tu key>
# Secret Access Key: <tu secret>
# Default region: us-east-1
# Output format: json

# Verificar
aws sts get-caller-identity
```

### Paso 3: Deploy con Terraform

```bash
cd laboratorio-terraform

terraform init
terraform validate
terraform plan
terraform apply        # escribir "yes"

# Guardar clave SSH
terraform output -raw clave_privada_ssh > pp6-clave-ssh.pem
chmod 600 pp6-clave-ssh.pem

# Probar (esperar 2-3 min después del apply)
curl $(terraform output -raw url_aplicacion)
```

### Paso 4: Migrar a OpenTofu (demo de intercambiabilidad)

```bash
cd ../laboratorio-opentofu

# Copiar el estado generado por Terraform
cp ../laboratorio-terraform/terraform.tfstate ./terraform.tfstate

tofu init

# Resultado esperado: "No changes. Your infrastructure matches the configuration."
tofu plan
```

### Paso 5: Limpieza

```bash
# Desde cualquiera de los dos directorios
tofu destroy    # o terraform destroy
# escribir "yes"
```

---

## Infraestructura desplegada

```
Internet
    │
    ▼
Internet Gateway
    │
    ▼
VPC (10.0.0.0/16)
    └── Subnet Pública (10.0.1.0/24)
            └── Security Group (SSH:22, HTTP:3000)
                    └── EC2 t2.micro (Ubuntu 22.04)
                            └── Python3 HTTP Server :3000
```

---

## Comandos de referencia

| Acción | Terraform | OpenTofu |
|--------|-----------|----------|
| Inicializar | `terraform init` | `tofu init` |
| Validar | `terraform validate` | `tofu validate` |
| Planificar | `terraform plan` | `tofu plan` |
| Aplicar | `terraform apply` | `tofu apply` |
| Ver outputs | `terraform output` | `tofu output` |
| Destruir | `terraform destroy` | `tofu destroy` |
| Ver estado | `terraform state list` | `tofu state list` |
| Formatear | `terraform fmt` | `tofu fmt` |

---

## Recursos AWS creados

| # | Recurso | Tipo |
|---|---------|------|
| 1 | pp6-vpc-laboratorio | aws_vpc |
| 2 | pp6-subnet-publica | aws_subnet |
| 3 | pp6-internet-gateway | aws_internet_gateway |
| 4 | pp6-tabla-ruteo-publica | aws_route_table |
| 5 | (asociación) | aws_route_table_association |
| 6 | pp6-grupo-seguridad-app | aws_security_group |
| 7 | (clave RSA local) | tls_private_key |
| 8 | pp6-clave-ssh | aws_key_pair |
| 9 | pp6-instancia-iac | aws_instance |

> ⚠️ **Free Tier:** t2.micro es elegible. Los otros recursos (VPC, IGW, etc.) no generan costo mientras no haya tráfico. Siempre hacer `destroy` al terminar.

---

## Troubleshooting

**`Connection refused` al hacer curl:**
- La app tarda 2-5 min en levantar (user_data se ejecuta al boot)
- Conectarse por SSH y verificar: `sudo systemctl status pp6-web.service`

**`Connection timeout`:**
- Verificar que el Security Group tiene el puerto 3000 abierto
- Verificar que la Route Table tiene ruta a Internet Gateway

**`Error: No valid credential sources found`:**
- Ejecutar `aws configure` y verificar con `aws sts get-caller-identity`

**`Error: InvalidAMIID.NotFound`:**
- La AMI `ami-0866a3c8686eaeeba` es válida en `us-east-1`
- Para otra región: buscar Ubuntu 22.04 LTS en EC2 → AMI Catalog
