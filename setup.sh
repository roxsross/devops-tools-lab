#!/bin/bash
# =============================================================================
# PP6 - Práctica Profesional VI
# setup.sh — Instalación automática de todas las herramientas necesarias
#
# Uso: bash setup.sh
# Requiere: Ubuntu 22.04+, acceso a sudo, conexión a internet
# =============================================================================

set -e  # Detener en caso de error

# ─── Colores para output ──────────────────────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

ok()   { echo -e "${GREEN}[✓]${NC} $1"; }
info() { echo -e "${CYAN}[→]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
err()  { echo -e "${RED}[✗]${NC} $1"; exit 1; }

echo ""
echo -e "${CYAN}================================================${NC}"
echo -e "${CYAN}  PP6 - Infrastructure as Code                  ${NC}"
echo -e "${CYAN}  Setup automático de herramientas               ${NC}"
echo -e "${CYAN}================================================${NC}"
echo ""

# ─── 1. Actualizar sistema ────────────────────────────────────────────────────
info "Actualizando sistema..."
sudo apt-get update -y > /dev/null 2>&1
sudo apt-get upgrade -y > /dev/null 2>&1
ok "Sistema actualizado"

# ─── 2. Herramientas base ─────────────────────────────────────────────────────
info "Instalando herramientas base (curl, wget, unzip, git, gnupg)..."
sudo apt-get install -y curl wget unzip git software-properties-common gnupg lsb-release > /dev/null 2>&1
ok "Herramientas base instaladas"

# ─── 3. Terraform ────────────────────────────────────────────────────────────
if command -v terraform &> /dev/null; then
  warn "Terraform ya está instalado: $(terraform version | head -1)"
else
  info "Instalando Terraform desde repo oficial HashiCorp..."
  curl -fsSL https://apt.releases.hashicorp.com/gpg \
    | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg 2>/dev/null
  echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
    https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
    | sudo tee /etc/apt/sources.list.d/hashicorp.list > /dev/null
  sudo apt-get update -y > /dev/null 2>&1
  sudo apt-get install -y terraform > /dev/null 2>&1
  ok "Terraform instalado: $(terraform version | head -1)"
fi

# ─── 4. OpenTofu ─────────────────────────────────────────────────────────────
if command -v tofu &> /dev/null; then
  warn "OpenTofu ya está instalado: $(tofu version | head -1)"
else
  info "Instalando OpenTofu desde instalador oficial..."
  curl --proto '=https' --tlsv1.2 -fsSL \
    https://get.opentofu.org/install-opentofu.sh \
    -o /tmp/install-opentofu.sh
  sudo bash /tmp/install-opentofu.sh --install-method deb > /dev/null 2>&1
  rm -f /tmp/install-opentofu.sh
  ok "OpenTofu instalado: $(tofu version | head -1)"
fi

# ─── 5. AWS CLI v2 ───────────────────────────────────────────────────────────
if command -v aws &> /dev/null; then
  warn "AWS CLI ya está instalado: $(aws --version)"
else
  info "Instalando AWS CLI v2..."
  cd /tmp
  curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  unzip -q awscliv2.zip
  sudo ./aws/install > /dev/null 2>&1
  rm -rf awscliv2.zip aws/
  cd - > /dev/null
  ok "AWS CLI instalado: $(aws --version)"
fi

# ─── 6. Verificación final ───────────────────────────────────────────────────
echo ""
echo -e "${CYAN}================================================${NC}"
echo -e "${CYAN}  Verificación de instalaciones                 ${NC}"
echo -e "${CYAN}================================================${NC}"

check_tool() {
  local name=$1
  local cmd=$2
  if command -v $cmd &> /dev/null; then
    ok "$name: $($cmd version 2>&1 | head -1)"
  else
    err "$name no encontrado en PATH"
  fi
}

check_tool "Terraform" "terraform"
check_tool "OpenTofu"  "tofu"

if command -v aws &> /dev/null; then
  ok "AWS CLI: $(aws --version)"
else
  err "AWS CLI no encontrado"
fi

# ─── 7. Configuración AWS ────────────────────────────────────────────────────
echo ""
echo -e "${YELLOW}================================================${NC}"
echo -e "${YELLOW}  PASO MANUAL REQUERIDO: Configurar AWS CLI     ${NC}"
echo -e "${YELLOW}================================================${NC}"
echo ""
echo "  Ejecutar: aws configure"
echo ""
echo "  Necesitás:"
echo "    - AWS Access Key ID"
echo "    - AWS Secret Access Key"
echo "    - Default region: us-east-1"
echo "    - Default output: json"
echo ""
echo "  Para obtener las credenciales:"
echo "    1. Ir a AWS Console → IAM → Users → tu usuario"
echo "    2. Security credentials → Access keys → Create access key"
echo ""
echo -e "${GREEN}  Después de aws configure, verificar con:${NC}"
echo "    aws sts get-caller-identity"
echo ""

# ─── Preguntar si configurar ahora ───────────────────────────────────────────
read -p "¿Querés configurar AWS CLI ahora? [s/N]: " response
if [[ "$response" =~ ^[sS]$ ]]; then
  aws configure
  echo ""
  info "Verificando credenciales..."
  if aws sts get-caller-identity > /dev/null 2>&1; then
    ok "Credenciales AWS válidas:"
    aws sts get-caller-identity
  else
    warn "Las credenciales no son válidas. Revisar Access Key y Secret."
  fi
fi

echo ""
echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}  ¡Setup completo! Próximos pasos:              ${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""
echo "  1. cd laboratorio-terraform"
echo "  2. terraform init"
echo "  3. terraform plan"
echo "  4. terraform apply"
echo ""
