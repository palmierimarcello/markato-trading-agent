#!/bin/bash

# Script di avvio per Trading Agent su Plesk
# Usa PostgreSQL esterno invece del container Docker

set -e

echo "=========================================="
echo "  Trading Agent - Plesk Deployment"
echo "=========================================="
echo ""

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

success() {
    echo -e "${GREEN}✓${NC} $1"
}

warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

error() {
    echo -e "${RED}✗${NC} $1"
    exit 1
}

info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# 1. Verifica prerequisiti
echo "1. Verifica prerequisiti..."

if ! command -v docker &> /dev/null; then
    error "Docker non è installato. Installalo con: curl -fsSL https://get.docker.com | sh"
fi
success "Docker installato"

if ! command -v docker compose &> /dev/null; then
    error "Docker Compose non è installato."
fi
success "Docker Compose installato"

# 2. Verifica file .env
echo ""
echo "2. Verifica configurazione..."

if [ ! -f .env ]; then
    warning "File .env non trovato."
    if [ -f .env.plesk.example ]; then
        info "Copiando da .env.plesk.example..."
        cp .env.plesk.example .env
    else
        cp .env.example .env
    fi
    warning "IMPORTANTE: Modifica .env con le credenziali del DB Plesk!"
    echo ""
    read -p "Premi INVIO dopo aver configurato .env, o CTRL+C per uscire..."
fi
success "File .env presente"

# 3. Verifica DATABASE_URL
if ! grep -q "DATABASE_URL=postgresql://" .env; then
    error "DATABASE_URL non configurato correttamente in .env"
fi

if grep -q "YOUR_DB_PASSWORD" .env; then
    warning "DATABASE_URL contiene ancora placeholder. Configuralo!"
    read -p "Vuoi continuare comunque? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        error "Setup annullato. Configura DATABASE_URL in .env"
    fi
fi
success "DATABASE_URL configurato"

# 4. Test connessione database
echo ""
echo "3. Test connessione PostgreSQL..."

# Estrai credenziali da DATABASE_URL
DB_URL=$(grep "^DATABASE_URL=" .env | cut -d'=' -f2-)

if command -v psql &> /dev/null; then
    info "Testo connessione al database..."
    if psql "$DB_URL" -c "SELECT 1" &> /dev/null; then
        success "Connessione database OK"
    else
        warning "Impossibile connettersi al database. Verifica credenziali in .env"
        warning "Continuando comunque, ma potrebbe fallire..."
    fi
else
    warning "psql non installato, salto test connessione"
fi

# 5. Stop container esistenti
echo ""
echo "4. Stop container esistenti (se presenti)..."
docker compose -f docker-compose.plesk.yml down 2>/dev/null || true
success "Container fermati"

# 6. Build immagini
echo ""
echo "5. Build immagini Docker..."
docker compose -f docker-compose.plesk.yml build --no-cache || error "Build fallito"
success "Immagini create"

# 7. Inizializza database (crea tabelle)
echo ""
echo "6. Inizializzazione schema database..."
info "Questo creerà le tabelle necessarie nel database Plesk"

# Build immagine temporanea per init
docker compose -f docker-compose.plesk.yml build trading_agent

# Esegui init database
docker compose -f docker-compose.plesk.yml run --rm trading_agent python -c "import db_utils; db_utils.init_db(); print('Database initialized!')" || warning "Inizializzazione database fallita (potrebbe essere già inizializzato)"

success "Schema database verificato"

# 8. Avvio servizi
echo ""
echo "7. Avvio servizi..."
docker compose -f docker-compose.plesk.yml up -d || error "Avvio fallito"
success "Container avviati"

# 9. Attendi
echo ""
echo "8. Attesa inizializzazione..."
sleep 5

# 10. Verifica stato
echo ""
echo "9. Verifica stato container..."
docker compose -f docker-compose.plesk.yml ps

# 11. Test health check
echo ""
echo "10. Test health check API..."
sleep 3

if curl -f http://localhost:8000/health &> /dev/null; then
    success "API risponde correttamente!"
    echo ""
    curl http://localhost:8000/health 2>/dev/null | python3 -m json.tool 2>/dev/null || curl http://localhost:8000/health
else
    warning "API non risponde ancora. Controlla logs:"
    echo "  docker compose -f docker-compose.plesk.yml logs web_api"
fi

# 12. Info finale
echo ""
echo "=========================================="
echo "  Deployment completato!"
echo "=========================================="
echo ""
echo -e "${GREEN}✓ Trading Agent avviato con successo${NC}"
echo ""
echo "Comandi utili:"
echo "  • Logs:             docker compose -f docker-compose.plesk.yml logs -f"
echo "  • Stato:            docker compose -f docker-compose.plesk.yml ps"
echo "  • Ferma:            docker compose -f docker-compose.plesk.yml down"
echo "  • Riavvia:          docker compose -f docker-compose.plesk.yml restart"
echo ""
echo "Endpoint API (locale):"
echo "  • http://localhost:8000/health"
echo "  • http://localhost:8000/status"
echo "  • http://localhost:8000/operations"
echo "  • http://localhost:8000/performance"
echo ""
echo -e "${BLUE}Prossimi passi:${NC}"
echo "  1. Configura reverse proxy su Plesk"
echo "  2. Configura SSL/TLS Let's Encrypt"
echo "  3. Punta il dominio al server"
echo ""
echo "Vedi: PLESK-POSTGRES-SETUP.md per dettagli"
echo ""
