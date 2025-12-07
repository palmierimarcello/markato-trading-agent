# Trading Agent - Docker Quick Start

Guida rapida per avviare il Trading Agent con Docker in 5 minuti.

## 🚀 Quick Start

### 1. Clona la Repository
```bash
git clone https://github.com/your-username/markato-trading-agent.git
cd markato-trading-agent
```

### 2. Configura le Credenziali
```bash
# Copia il template
cp .env.example .env

# Modifica con le tue API keys
nano .env  # oppure usa vim, code, ecc.
```

Configura almeno questi valori:
- `PRIVATE_KEY` - Chiave privata Ethereum per Hyperliquid
- `WALLET_ADDRESS` - Indirizzo wallet Ethereum
- `OPENAI_API_KEY` - API key OpenAI
- `CMC_PRO_API_KEY` - API key CoinMarketCap
- `POSTGRES_PASSWORD` - Password per il database

### 3. Avvia con lo Script Automatico
```bash
# Rendi lo script eseguibile (solo la prima volta)
chmod +x start.sh

# Avvia tutto
./start.sh
```

### 4. Verifica che Funzioni
```bash
# Test API
curl http://localhost:8000/health

# Visualizza logs
docker compose logs -f
```

---

## 📦 Servizi Inclusi

Il docker-compose avvia automaticamente:

| Servizio | Porta | Descrizione |
|----------|-------|-------------|
| **postgres** | 5432 | Database PostgreSQL per tracking operazioni |
| **trading_agent** | - | Bot che esegue le operazioni di trading |
| **web_api** | 8000 | API REST per monitoring e status |

---

## 🔧 Comandi Docker Utili

### Gestione Container
```bash
# Avvia tutti i servizi
docker compose up -d

# Ferma tutti i servizi
docker compose down

# Riavvia un servizio specifico
docker compose restart trading_agent

# Visualizza stato
docker compose ps
```

### Logs e Debug
```bash
# Tutti i logs
docker compose logs -f

# Solo trading agent
docker compose logs -f trading_agent

# Solo API
docker compose logs -f web_api

# Ultimi 100 log
docker compose logs --tail=100
```

### Database
```bash
# Accedi al database
docker compose exec postgres psql -U trading_user -d trading_db

# Backup database
docker compose exec postgres pg_dump -U trading_user trading_db > backup.sql

# Ripristina backup
cat backup.sql | docker compose exec -T postgres psql -U trading_user trading_db
```

### Rebuild e Update
```bash
# Rebuild dopo modifiche al codice
docker compose build --no-cache

# Pull ultime modifiche e rebuild
git pull
docker compose build
docker compose up -d
```

---

## 🌐 API Endpoints

Una volta avviato, l'API è disponibile su `http://localhost:8000`:

### GET /health
Health check del servizio
```bash
curl http://localhost:8000/health
```

### GET /status
Stato attuale dell'account e posizioni aperte
```bash
curl http://localhost:8000/status
```

### GET /operations?limit=50
Ultime operazioni del bot
```bash
curl http://localhost:8000/operations?limit=10
```

### GET /performance
Metriche di performance (P&L, ROI, etc.)
```bash
curl http://localhost:8000/performance
```

---

## 🔐 Sicurezza

- ✅ Il file `.env` NON deve essere committato su Git
- ✅ Usa password forti per `POSTGRES_PASSWORD`
- ✅ Non esporre la porta 5432 (PostgreSQL) su Internet
- ✅ In produzione, usa HTTPS con reverse proxy (NGINX)

---

## 🐛 Troubleshooting

### Container non si avvia
```bash
# Verifica i logs
docker compose logs

# Verifica la configurazione
docker compose config
```

### Porta già in uso
```bash
# Cambia la porta in docker-compose.yml
# Modifica "8000:8000" in "8001:8000" (per esempio)
```

### Database connection error
```bash
# Aspetta che PostgreSQL sia pronto
docker compose logs postgres

# Ricrea i container
docker compose down -v
docker compose up -d
```

### Reset completo
```bash
# ATTENZIONE: Cancella tutti i dati!
docker compose down -v
docker compose up -d
```

---

## 📊 Monitoring in Produzione

Per il deployment in produzione su Plesk, segui la guida completa:
- [DEPLOYMENT.md](DEPLOYMENT.md) - Guida completa deployment su Plesk

---

## 🆘 Supporto

- Issues: [GitHub Issues](https://github.com/your-username/markato-trading-agent/issues)
- Docs: [DEPLOYMENT.md](DEPLOYMENT.md)
