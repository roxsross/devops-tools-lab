# PP6 - Laboratorio OpenTofu
## Infrastructure as Code · AWS · Práctica Profesional VI

Demuestra la **compatibilidad total** entre OpenTofu y Terraform usando la misma infraestructura del laboratorio anterior.

---

## Dos formas de usar este laboratorio

### Opción A — Deploy desde cero con OpenTofu

```bash
# 1. Inicializar
tofu init

# 2. Validar
tofu validate

# 3. Planificar
tofu plan

# 4. Aplicar
tofu apply
# → escribir "yes" para confirmar

# 5. Guardar la clave SSH
tofu output -raw clave_privada_ssh > pp6-clave-ssh.pem
chmod 600 pp6-clave-ssh.pem

# 6. Probar la aplicación
curl $(tofu output -raw url_aplicacion)
```

### Opción B — Migrar estado existente desde Terraform (demo de intercambiabilidad)

```bash
# Copiar el estado generado por Terraform
cp ../laboratorio-terraform/terraform.tfstate ./terraform.tfstate

# Inicializar OpenTofu (descarga los mismos providers)
tofu init

# Verificar: OpenTofu reconoce los recursos existentes sin cambios
tofu plan
# → Resultado esperado: "No changes. Your infrastructure matches the configuration."

# Verificar los outputs
tofu output
```

> 💡 El resultado `No changes` demuestra que OpenTofu y Terraform son 100% intercambiables a nivel de estado y configuración.

---

## Diferencias con el laboratorio Terraform

| Aspecto | Terraform | OpenTofu |
|---------|-----------|----------|
| Comando | `terraform` | `tofu` |
| Licencia | BSL 1.1 | MPL 2.0 (open-source) |
| Estado | `terraform.tfstate` | mismo formato |
| Archivos `.tf` | ✅ | ✅ idénticos |
| Providers | hashicorp registry | OpenTofu registry + hashicorp |

---

## Limpieza — IMPORTANTE

```bash
tofu destroy
# → escribir "yes" para confirmar
```

> ⚠️ Si migraste el estado desde Terraform, el `tofu destroy` elimina los recursos reales en AWS.
