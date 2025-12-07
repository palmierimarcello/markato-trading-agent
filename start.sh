#!/bin/bash

# Script di avvio per Trading Agent
# Questo script automatizza il processo di build e deployment

set -e  # Exit on error

echo "=========================================="
echo "  Trading Agent - Deployment Script"
echo "=========================================="
echo ""

# Colori per output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Funzione per messaggi di successo
success() {
    echo -e "${GREEN}✓${NC} $1"
}

# Funzione per messaggi di warning
warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Funzione per messaggi di errore
error() {
    echo -e "${RED}✗${NC} $1"
    exit 1
}

# 1. Verifica prerequisiti
echo "1. Verifica prerequisiti..."

if ! command -v docker &> /dev/null; then
    error "Docker non è installato. Installalo prima di continuare."
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
    warning "File .env non trovato. Copiando da .env.example..."
    cp .env.example .env
    warning "IMPORTANTE: Modifica il file .env con le tue credenziali prima di continuare!"
    echo ""
    read -p "Premi INVIO dopo aver configurato .env, oppure CTRL+C per uscire..."
fi
success "File .env presente"

# 3. Verifica variabili critiche
if ! grep -q "your_" .env; then
    success "File .env sembra configurato"
else
    warning "Il file .env contiene ancora valori placeholder. Verificalo!"
    read -p "Vuoi continuare comunque? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        error "Deployment annullato. Configura .env e riprova."
    fi
fi

# 4. Stop container esistenti
echo ""
echo "3. Stop container esistenti (se presenti)..."
docker compose down 2>/dev/null || true
success "Container fermati"

# 5. Build immagini
echo ""
echo "4. Build immagini Docker..."
docker compose build --no-cache || error "Build fallito"
success "Immagini Docker create"

# 6. Avvio servizi
echo ""
echo "5. Avvio servizi..."
docker compose up -d || error "Avvio fallito"
success "Container avviati"

# 7. Attendi che i servizi siano pronti
echo ""
echo "6. Attesa inizializzazione servizi..."
sleep 5

# 8. Verifica stato
echo ""
echo "7. Verifica stato container..."
docker compose ps

# 9. Test health check
echo ""
echo "8. Test health check API..."
sleep 3

if curl -f http://localhost:8000/health &> /dev/null; then
    success "API risponde correttamente!"
    echo ""
    curl http://localhost:8000/health | python3 -m json.tool 2>/dev/null || curl http://localhost:8000/health
else
    warning "API non risponde ancora. Controlla i logs con: docker compose logs web_api"
fi

# 10. Mostra logs
echo ""
echo "=========================================="
echo "  Deployment completato!"
echo "=========================================="
echo ""
echo "Comandi utili:"
echo "  • Visualizza logs:      docker compose logs -f"
echo "  • Stato container:      docker compose ps"
echo "  • Ferma servizi:        docker compose down"
echo "  • Riavvia:              docker compose restart"
echo ""
echo "Endpoint API disponibili su http://localhost:8000"
echo "  • /health              - Health check"
echo "  • /status              - Stato account"
echo "  • /operations          - Operazioni recenti"
echo "  • /performance         - Metriche performance"
echo ""
echo "Per vedere i logs in tempo reale:"
echo "  docker compose logs -f"
echo ""
