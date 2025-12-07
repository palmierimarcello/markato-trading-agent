# Trading Agent - Docker Deployment Guide

> Trasforma il tuo Trading Agent in un servizio Docker production-ready, deployabile su qualsiasi server con dominio personalizzato.

---

## 📚 Documentazione Completa

Questa repository include guide dettagliate per ogni scenario di deployment:

| Documento | Descrizione | Quando usarlo |
|-----------|-------------|---------------|
| **[DOCKER-QUICKSTART.md](DOCKER-QUICKSTART.md)** | Avvio rapido in 5 minuti | Test locale, primo approccio |
| **[PLESK-QUICKSTART.md](PLESK-QUICKSTART.md)** | ⭐ Plesk setup rapido (10 min) | **Plesk con PostgreSQL esistente** |
| **[PLESK-POSTGRES-SETUP.md](PLESK-POSTGRES-SETUP.md)** | Setup database su Plesk | Configurazione DB Plesk dettagliata |
| **[DEPLOYMENT.md](DEPLOYMENT.md)** | Deployment completo su Plesk | Server con Plesk (con container DB) |
| **[REMOTE-SERVER-SETUP.md](REMOTE-SERVER-SETUP.md)** | Setup su VPS/Cloud remoto | Server standalone o VPS esterno |
| **[COMMANDS.md](COMMANDS.md)** | Cheat sheet comandi utili | Reference quotidiano |
| **[CHECKLIST.md](CHECKLIST.md)** | Checklist deployment completa | Prima di andare in produzione |

---

## 🚀 Quick Start (3 Passi)

### 1. Configura Credenziali
```bash
cp .env.example .env
nano .env  # Compila tutte le API keys
```

### 2. Avvia Localmente
```bash
./start.sh
```

### 3. Deploy su Server Remoto
```bash
./deploy-remote.sh root@your-server-ip
```

**Fatto!** Il tuo trading agent è online.

---

## 🏗️ Architettura

```
┌─────────────────────────────────────────────────────────────┐
│                        INTERNET                              │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
         ┌───────────────────────┐
         │   tuodominio.com      │
         │   (SSL/TLS - HTTPS)   │
         └───────────┬───────────┘
                     │
                     ▼
         ┌───────────────────────┐
         │  NGINX Reverse Proxy  │
         │   (Plesk o Standalone)│
         └───────────┬───────────┘
                     │
                     ▼
    ┌────────────────────────────────────────┐
    │        Docker Compose Stack            │
    │                                        │
    │  ┌──────────────┐  ┌──────────────┐  │
    │  │ Trading Bot  │  │   Web API    │  │
    │  │  (Python)    │  │   (Flask)    │  │
    │  └──────┬───────┘  └──────┬───────┘  │
    │         │                  │          │
    │         └─────────┬────────┘          │
    │                   ▼                   │
    │         ┌──────────────────┐          │
    │         │   PostgreSQL     │          │
    │         │   (Database)     │          │
    │         └──────────────────┘          │
    └────────────────────────────────────────┘
                     │
                     ▼
         ┌───────────────────────┐
         │  External Services:   │
         │  • Hyperliquid        │
         │  • OpenAI GPT-5.1     │
         │  • CoinMarketCap      │
         │  • News Feed          │
         └───────────────────────┘
```

---

## 📦 Componenti Docker

### Container 1: `trading_agent`
- **Immagine**: Python 3.11
- **Funzione**: Esegue il bot di trading
- **Dipendenze**: PostgreSQL, Hyperliquid SDK, OpenAI
- **Riavvio**: Automatico on failure

### Container 2: `web_api`
- **Immagine**: Python 3.11 + Flask
- **Funzione**: API REST per monitoring
- **Porta**: 8000
- **Endpoints**: `/health`, `/status`, `/operations`, `/performance`

### Container 3: `postgres`
- **Immagine**: PostgreSQL 15
- **Funzione**: Database relazionale
- **Volume**: Persistente
- **Backup**: Automatico con pg_dump

---

## 🔑 Variabili d'Ambiente Richieste

```env
# Database
POSTGRES_DB=trading_db
POSTGRES_USER=trading_user
POSTGRES_PASSWORD=your_password
DATABASE_URL=postgresql://...

# Hyperliquid
PRIVATE_KEY=ethereum_private_key
WALLET_ADDRESS=0xYourAddress

# OpenAI
OPENAI_API_KEY=sk-proj-...

# CoinMarketCap
CMC_PRO_API_KEY=your_cmc_key
```

Vedi [.env.example](.env.example) per template completo.

---

## 🌐 Deployment Scenarios

### Scenario 1: Local Development
**Setup**: Docker Desktop sul tuo Mac/PC
**Guida**: [DOCKER-QUICKSTART.md](DOCKER-QUICKSTART.md)
**Comando**: `./start.sh`

### Scenario 2: Server con Plesk
**Setup**: VPS con Plesk pre-installato
**Guida**: [DEPLOYMENT.md](DEPLOYMENT.md)
**Risultato**: `https://tuodominio.com`

### Scenario 3: VPS Remoto + Dominio Plesk
**Setup**: Bot su VPS separato, Plesk fa reverse proxy
**Guida**: [REMOTE-SERVER-SETUP.md](REMOTE-SERVER-SETUP.md) - Opzione 1
**Architettura**: Plesk → VPS (Docker)

### Scenario 4: VPS Standalone
**Setup**: Tutto su VPS senza Plesk
**Guida**: [REMOTE-SERVER-SETUP.md](REMOTE-SERVER-SETUP.md) - Opzione 2
**Richiede**: NGINX + Let's Encrypt manuale

---

## 🛠️ Script Automatici

### `start.sh`
Avvia tutto localmente con verifiche automatiche
```bash
./start.sh
```

### `deploy-remote.sh`
Deploy completo su server remoto via SSH
```bash
./deploy-remote.sh root@123.456.789.10
```

### `docker-compose.yml`
Orchestrazione multi-container
```bash
docker compose up -d
```

---

## 📊 API Endpoints

Una volta deployato, accedi a:

| Endpoint | Descrizione | Esempio |
|----------|-------------|---------|
| `GET /` | Info API | `curl https://domain.com/` |
| `GET /health` | Health check | `curl https://domain.com/health` |
| `GET /status` | Account status | `curl https://domain.com/status` |
| `GET /operations?limit=N` | Ultime N operazioni | `curl https://domain.com/operations?limit=10` |
| `GET /performance` | Metriche P&L | `curl https://domain.com/performance` |

---

## 🔐 Sicurezza

✅ **Implementato**:
- HTTPS con Let's Encrypt
- Firewall UFW configurato
- Database password protetto
- API keys in .env (non committato)
- Container isolation
- Read-only filesystem per security

⚠️ **Raccomandazioni**:
- [ ] Disabilita password SSH, usa solo chiavi
- [ ] Configura Fail2Ban
- [ ] Limita accesso API solo a IP fidati
- [ ] Backup database cifrati offsite
- [ ] Rotazione API keys ogni 3-6 mesi

---

## 📈 Monitoring

### Logs in Tempo Reale
```bash
docker compose logs -f
```

### Metriche Performance
```bash
curl https://tuodominio.com/performance | jq
```

### Database Queries
```bash
docker compose exec postgres psql -U trading_user -d trading_db
```

### Risorse Sistema
```bash
docker stats
```

---

## 🔄 Manutenzione

### Update Codice
```bash
git pull
docker compose build --no-cache
docker compose up -d
```

### Backup Database
```bash
docker compose exec postgres pg_dump -U trading_user trading_db > backup.sql
```

### Restart Servizi
```bash
docker compose restart
```

---

## 🆘 Troubleshooting

### Container non si avvia
```bash
docker compose logs <service_name>
docker compose config  # Verifica configurazione
```

### API non risponde
```bash
curl http://localhost:8000/health  # Test locale
docker compose ps                   # Verifica stato
```

### Database connection error
```bash
docker compose exec postgres pg_isready -U trading_user
docker compose restart postgres
```

Vedi [COMMANDS.md](COMMANDS.md) per troubleshooting completo.

---

## 📞 Supporto

- **Issues**: [GitHub Issues](https://github.com/your-username/markato-trading-agent/issues)
- **Docs**: Leggi tutte le guide in questa repo
- **Community**: [Discord/Telegram link]

---

## 📄 File Struttura

```
markato-trading-agent/
├── 📄 Dockerfile                    # Container bot principale
├── 📄 Dockerfile.api                # Container API web
├── 📄 docker-compose.yml            # Orchestrazione servizi
├── 📄 .dockerignore                 # File esclusi da build
├── 📄 .env.example                  # Template variabili
├── 📄 requirements.txt              # Dipendenze Python
├── 📄 api.py                        # API Flask
├── 📄 main.py                       # Entry point bot
├── 📄 db_utils.py                   # Gestione database
├── 📄 hyperliquid_trader.py         # Hyperliquid integration
├── 📄 trading_agent.py              # LLM decision engine
├── 📄 sentiment.py                  # Fear & Greed Index
├── 📄 news_feed.py                  # News scraping
├── 📄 forecaster.py                 # Price forecasting
├── 📄 indicators.py                 # Technical indicators
├── 🚀 start.sh                      # Script avvio locale
├── 🚀 deploy-remote.sh              # Script deploy remoto
├── 📚 README-DOCKER.md              # Questo file
├── 📚 DOCKER-QUICKSTART.md          # Quick start
├── 📚 DEPLOYMENT.md                 # Guida Plesk
├── 📚 REMOTE-SERVER-SETUP.md        # Guida VPS remoto
├── 📚 COMMANDS.md                   # Cheat sheet comandi
├── 📚 CHECKLIST.md                  # Checklist deployment
└── 📚 nginx.conf                    # Config NGINX (reference)
```

---

## 🎯 Roadmap

- [x] Docker containerization
- [x] API REST per monitoring
- [x] Deployment automation scripts
- [x] PostgreSQL integration
- [x] Comprehensive documentation
- [ ] Grafana dashboard
- [ ] Telegram notifications
- [ ] Backtesting framework
- [ ] Multi-strategy support
- [ ] Advanced risk management

---

## ⚖️ Licenza

MIT License - Vedi [LICENSE](LICENSE)

---

## 🙏 Credits

Progetto sviluppato da **Rizzo AI Academy**
Ispirato da [Alpha Arena](https://nof1.ai/)

---

**Happy Trading!** 🚀📈

Per iniziare: `./start.sh`
Per deployare: `./deploy-remote.sh user@server-ip`
Per domande: [GitHub Issues](https://github.com/your-username/markato-trading-agent/issues)
