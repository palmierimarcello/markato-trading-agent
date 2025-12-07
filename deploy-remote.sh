#!/bin/bash

# Script per deployment automatico su server remoto
# Usage: ./deploy-remote.sh user@server-ip

set -e

# Colori
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}"
echo "=========================================="
echo "  Trading Agent - Remote Deployment"
echo "=========================================="
echo -e "${NC}"

# Verifica argomenti
if [ -z "$1" ]; then
    echo -e "${RED}Errore: Specificare l'utente e il server${NC}"
    echo "Usage: ./deploy-remote.sh user@server-ip"
    echo "Esempio: ./deploy-remote.sh root@123.456.789.10"
    exit 1
fi

REMOTE_USER_HOST=$1
REMOTE_DIR="/opt/markato-trading-agent"

echo -e "${YELLOW}Server remoto: ${REMOTE_USER_HOST}${NC}"
echo -e "${YELLOW}Directory remota: ${REMOTE_DIR}${NC}"
echo ""

# Funzioni
success() {
    echo -e "${GREEN}✓${NC} $1"
}

error() {
    echo -e "${RED}✗${NC} $1"
    exit 1
}

info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Step 1: Verifica connessione SSH
info "Verifico connessione SSH..."
if ssh -o BatchMode=yes -o ConnectTimeout=5 $REMOTE_USER_HOST exit &>/dev/null; then
    success "Connessione SSH OK"
else
    error "Impossibile connettersi a $REMOTE_USER_HOST. Verifica credenziali SSH."
fi

# Step 2: Verifica file .env locale
info "Verifico file .env locale..."
if [ ! -f .env ]; then
    error "File .env non trovato. Crea il file .env prima di deployare."
fi
success "File .env presente"

# Step 3: Crea directory remota
info "Creo directory remota..."
ssh $REMOTE_USER_HOST "mkdir -p $REMOTE_DIR" || error "Impossibile creare directory remota"
success "Directory remota creata"

# Step 4: Trasferimento file
info "Trasferimento file sul server remoto..."

# Lista file da trasferire
FILES_TO_TRANSFER=(
    "*.py"
    "requirements.txt"
    "Dockerfile"
    "Dockerfile.api"
    "docker-compose.yml"
    ".dockerignore"
    "start.sh"
    "system_prompt.txt"
    ".env"
)

for pattern in "${FILES_TO_TRANSFER[@]}"; do
    scp -q $pattern $REMOTE_USER_HOST:$REMOTE_DIR/ 2>/dev/null || true
done

success "File trasferiti"

# Step 5: Verifica Docker sul server remoto
info "Verifico Docker sul server remoto..."
if ssh $REMOTE_USER_HOST "command -v docker &> /dev/null"; then
    success "Docker installato"
else
    echo -e "${YELLOW}Docker non trovato. Installazione in corso...${NC}"
    ssh $REMOTE_USER_HOST "curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh"
    success "Docker installato"
fi

# Step 6: Build e avvio container
info "Build e avvio container..."
ssh $REMOTE_USER_HOST << 'ENDSSH'
cd /opt/markato-trading-agent

# Stop container esistenti
docker compose down 2>/dev/null || true

# Build
echo "Building Docker images..."
docker compose build --no-cache

# Avvio
echo "Starting containers..."
docker compose up -d

# Attendi
sleep 5

# Verifica
echo "Container status:"
docker compose ps
ENDSSH

success "Container avviati"

# Step 7: Test health check
info "Test health check..."
sleep 3

if ssh $REMOTE_USER_HOST "curl -f http://localhost:8000/health &> /dev/null"; then
    success "Health check OK!"

    # Mostra risposta
    echo ""
    echo -e "${GREEN}Risposta API:${NC}"
    ssh $REMOTE_USER_HOST "curl -s http://localhost:8000/health | python3 -m json.tool 2>/dev/null || curl -s http://localhost:8000/health"
else
    echo -e "${YELLOW}⚠ Health check fallito. Verifica i logs:${NC}"
    echo "ssh $REMOTE_USER_HOST 'cd $REMOTE_DIR && docker compose logs web_api'"
fi

# Step 8: Info finale
echo ""
echo -e "${GREEN}=========================================="
echo "  Deployment completato!"
echo "==========================================${NC}"
echo ""
echo -e "${BLUE}Comandi utili:${NC}"
echo ""
echo "  Visualizza logs:"
echo "    ssh $REMOTE_USER_HOST 'cd $REMOTE_DIR && docker compose logs -f'"
echo ""
echo "  Verifica stato:"
echo "    ssh $REMOTE_USER_HOST 'cd $REMOTE_DIR && docker compose ps'"
echo ""
echo "  Riavvia servizi:"
echo "    ssh $REMOTE_USER_HOST 'cd $REMOTE_DIR && docker compose restart'"
echo ""
echo "  Accedi al server:"
echo "    ssh $REMOTE_USER_HOST"
echo ""
echo -e "${BLUE}Endpoint API:${NC}"
echo "  http://[IP-SERVER]:8000/health"
echo "  http://[IP-SERVER]:8000/status"
echo "  http://[IP-SERVER]:8000/performance"
echo ""
echo -e "${YELLOW}Prossimi passi:${NC}"
echo "  1. Configura il firewall (UFW)"
echo "  2. Configura NGINX reverse proxy (se standalone)"
echo "  3. Configura SSL con Let's Encrypt"
echo "  4. Punta il DNS al server"
echo ""
echo "Vedi: REMOTE-SERVER-SETUP.md per dettagli"
echo ""
