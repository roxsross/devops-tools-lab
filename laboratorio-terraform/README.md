# PP6 - Laboratorio Terraform
## Infrastructure as Code · AWS · Práctica Profesional VI

Despliega una instancia EC2 con servidor web Python en una VPC dedicada usando **Terraform**.

---

## Recursos que crea

| Recurso | Nombre | Descripción |
|---------|--------|-------------|
| `aws_vpc` | pp6-vpc-laboratorio | VPC con CIDR 10.0.0.0/16 |
| `aws_subnet` | pp6-subnet-publica | Subnet pública en us-east-1a |
| `aws_internet_gateway` | pp6-internet-gateway | Salida a Internet |
| `aws_route_table` | pp6-tabla-ruteo-publica | Ruta default → IGW |
| `aws_security_group` | pp6-app-sg | Puertos 22 (SSH) y 3000 (web) |
| `tls_private_key` | pp6-key-pair | Clave RSA 2048 generada localmente |
| `aws_key_pair` | pp6-clave-ssh | Clave pública registrada en AWS |
| `aws_instance` | pp6-instancia-iac | Ubuntu 22.04 t2.micro con servidor web |

---

## Prerrequisitos

- Ubuntu 22.04+ con `sudo`
- Terraform >= 1.0 instalado
- AWS CLI configurado (`aws configure`)
- Credenciales con permisos: EC2, VPC, IAM (key pairs)

---

## Uso rápido

```bash
# 1. Inicializar (descarga providers)
terraform init

# 2. Validar sintaxis
terraform validate

# 3. Ver qué va a crear (sin ejecutar nada)
terraform plan

# 4. Crear la infraestructura
terraform apply
# → escribir "yes" para confirmar

# 5. Guardar la clave SSH
terraform output -raw clave_privada_ssh > pp6-clave-ssh.pem
chmod 600 pp6-clave-ssh.pem

# 6. Probar la aplicación (esperar 2-3 min después del apply)
curl $(terraform output -raw url_aplicacion)

# 7. Conectarse por SSH
ssh -i pp6-clave-ssh.pem ubuntu@$(terraform output -raw ip_publica_instancia)
```

---

## Verificación dentro de la instancia

```bash
# Ver si el servidor está corriendo
sudo systemctl status pp6-web.service

# Ver logs del servidor
sudo journalctl -u pp6-web.service -f

# Verificar puerto
ss -tlnp | grep 3000

# Probar localmente
curl http://localhost:3000
```

---

## Backend remoto (opcional)

Ver `backend-remoto.tf.ejemplo` para configurar estado en **S3 + DynamoDB**.

---

## Limpieza — IMPORTANTE

```bash
# Destruir TODOS los recursos para evitar costos en AWS
terraform destroy
# → escribir "yes" para confirmar
```

> ⚠️ Siempre ejecutar `destroy` al terminar el laboratorio.
