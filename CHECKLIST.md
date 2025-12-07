# Trading Agent - Checklist Deployment

Usa questa checklist per assicurarti di non dimenticare nessun passo durante il deployment.

## 📋 Pre-Deployment

### Account e API Keys
- [ ] Account **Hyperliquid** creato (testnet o mainnet)
- [ ] Wallet Ethereum configurato (private key + address)
- [ ] Fondi nel wallet Hyperliquid (anche su testnet)
- [ ] API Key **OpenAI** ottenuta (con credito)
- [ ] Verificato accesso a modello GPT-5.1
- [ ] API Key **CoinMarketCap** Pro ottenuta
- [ ] Testato Fear & Greed Index API

### Server e Dominio
- [ ] Server VPS/Cloud provisioned (min 2GB RAM)
- [ ] Accesso SSH configurato
- [ ] Dominio registrato
- [ ] DNS configurato (se necessario)
- [ ] Plesk installato (se usi Plesk)

---

## 🔧 Setup Locale (Testing)

### Prima Configurazione
- [ ] Repository clonata localmente
- [ ] Docker Desktop installato e funzionante
- [ ] File `.env` creato da `.env.example`
- [ ] Tutte le variabili in `.env` configurate
- [ ] Password PostgreSQL sicura impostata

### Test Locale
- [ ] `docker compose build` eseguito senza errori
- [ ] `docker compose up -d` eseguito con successo
- [ ] Container postgres **healthy**
- [ ] Container trading_agent **running**
- [ ] Container web_api **running**
- [ ] Health check risponde: `curl http://localhost:8000/health`
- [ ] Database inizializzato correttamente
- [ ] Trading agent esegue ciclo completo senza errori
- [ ] Logs controllati per verificare assenza errori critici

---

## 🚀 Deployment Server Remoto

### Setup Server
- [ ] Connessione SSH al server verificata
- [ ] Docker installato: `docker --version`
- [ ] Docker Compose installato: `docker compose version`
- [ ] Git installato (se usi Git): `git --version`
- [ ] Codice caricato in `/opt/markato-trading-agent` (o percorso scelto)
- [ ] File `.env` copiato e configurato sul server
- [ ] Permessi file corretti: `chmod 600 .env`
- [ ] Script `start.sh` reso eseguibile: `chmod +x start.sh`

### Build e Avvio
- [ ] `docker compose build` completato senza errori
- [ ] `docker compose up -d` eseguito
- [ ] Tutti i container in stato **Up**: `docker compose ps`
- [ ] Health check risponde localmente: `curl http://localhost:8000/health`
- [ ] Logs verificati: `docker compose logs -f`
- [ ] Database popolato con primi dati

### Firewall
- [ ] UFW installato: `apt install ufw`
- [ ] SSH consentito: `ufw allow 22/tcp`
- [ ] Porta API configurata (8000): `ufw allow 8000/tcp`
- [ ] HTTPS consentito (80, 443): `ufw allow 80/tcp && ufw allow 443/tcp`
- [ ] Firewall abilitato: `ufw enable`
- [ ] Regole verificate: `ufw status`

---

## 🌐 Configurazione NGINX/Plesk

### Opzione A: Server con Plesk

- [ ] Dominio aggiunto su Plesk
- [ ] Direttive NGINX aggiunte in **Apache & nginx Settings**
- [ ] Proxy pass configurato verso IP:porta corretti
- [ ] SSL/TLS Let's Encrypt installato
- [ ] Redirect HTTP → HTTPS abilitato
- [ ] Test accesso: `curl https://tuodominio.com/health`

### Opzione B: Server Standalone

- [ ] NGINX installato: `apt install nginx`
- [ ] File configurazione creato: `/etc/nginx/sites-available/trading-agent`
- [ ] Symlink creato: `/etc/nginx/sites-enabled/trading-agent`
- [ ] Configurazione testata: `nginx -t`
- [ ] NGINX riavviato: `systemctl reload nginx`
- [ ] Certbot installato: `apt install certbot python3-certbot-nginx`
- [ ] Certificato SSL ottenuto: `certbot --nginx -d tuodominio.com`
- [ ] Auto-rinnovo configurato: `certbot renew --dry-run`
- [ ] Test accesso HTTPS: `curl https://tuodominio.com/health`

---

## 🔐 DNS Configuration

- [ ] Record **A** configurato: `tuodominio.com → IP-SERVER`
- [ ] Record **A** per www configurato: `www.tuodominio.com → IP-SERVER`
- [ ] TTL impostato (consigliato: 300-3600 secondi)
- [ ] DNS propagato: `nslookup tuodominio.com`
- [ ] Test ping: `ping tuodominio.com`

---

## ✅ Verifica Funzionamento

### API Endpoints
- [ ] `/health` risponde: `curl https://tuodominio.com/health`
- [ ] `/status` risponde: `curl https://tuodominio.com/status`
- [ ] `/operations` risponde: `curl https://tuodominio.com/operations?limit=10`
- [ ] `/performance` risponde: `curl https://tuodominio.com/performance`

### Trading Agent
- [ ] Bot esegue analisi dati (indicators, news, sentiment, forecasts)
- [ ] LLM genera decisioni correttamente
- [ ] Operazioni vengono loggate nel database
- [ ] Ordini su Hyperliquid eseguiti (se configurato per aprire posizioni)
- [ ] Stop loss configurati correttamente
- [ ] Nessun errore critico nei logs

### Database
- [ ] Connessione database funzionante
- [ ] Tabelle create: `\dt` in psql
- [ ] Snapshots account salvati
- [ ] Operazioni registrate
- [ ] Query di performance funzionanti

---

## 📊 Monitoring e Automazione

### Logs
- [ ] Log rotation configurato (Docker daemon.json)
- [ ] Script di monitoring creato (opzionale)
- [ ] Alerting configurato (email/Telegram) (opzionale)

### Backup
- [ ] Script backup database creato
- [ ] Cron job backup configurato
- [ ] Location backup sicura (fuori dal server)
- [ ] Test restore da backup eseguito

### Automazione
- [ ] Systemd service creato (opzionale)
- [ ] Service abilitato all'avvio: `systemctl enable trading-agent`
- [ ] Health check automatico con cron (opzionale)
- [ ] Auto-restart su crash configurato (docker restart policy)

---

## 🔒 Sicurezza

### Server
- [ ] Password SSH disabilitato (solo chiavi)
- [ ] Fail2Ban installato e configurato
- [ ] Porte non necessarie chiuse
- [ ] Solo IP fidati possono accedere a porte sensibili
- [ ] Aggiornamenti automatici configurati (opzionale)

### Applicazione
- [ ] File `.env` non committato su Git
- [ ] `.env` con permessi 600
- [ ] Password database complessa
- [ ] API keys non esposte nei logs
- [ ] HTTPS enforced (no HTTP)

### Hyperliquid
- [ ] Testnet usato per test iniziali
- [ ] Mainnet solo dopo testing completo
- [ ] Leva configurata responsabilmente
- [ ] Stop loss sempre attivi
- [ ] Position size ragionevole

---

## 📈 Post-Deployment

### Primo Giorno
- [ ] Monitoraggio logs ogni ora
- [ ] Verifica metriche performance
- [ ] Controllo posizioni aperte su Hyperliquid
- [ ] Test manuale API endpoints
- [ ] Backup database creato

### Prima Settimana
- [ ] Review logs giornaliera
- [ ] Analisi P&L
- [ ] Verifica accuratezza decisioni LLM
- [ ] Ottimizzazione prompt (se necessario)
- [ ] Tuning parametri risk management

### Manutenzione Continua
- [ ] Update settimanale sistema: `apt update && apt upgrade`
- [ ] Review mensile performance
- [ ] Backup mensile completo
- [ ] Rotazione API keys (ogni 3-6 mesi)
- [ ] Update dipendenze Python (periodico)

---

## 🆘 Troubleshooting Preparato

- [ ] Documentazione letta: `DEPLOYMENT.md`
- [ ] Comandi utili salvati: `COMMANDS.md`
- [ ] Script di deploy testato: `./deploy-remote.sh`
- [ ] Contatti supporto salvati (GitHub Issues, etc.)
- [ ] Piano di rollback preparato

---

## 🎯 Obiettivi di Performance

Definisci e monitora:

- [ ] **Uptime target**: ___% (es: 99.5%)
- [ ] **Max drawdown accettabile**: ___% (es: 15%)
- [ ] **ROI target mensile**: ___% (es: 5-10%)
- [ ] **Numero trade al giorno**: ___ (es: 3-5)
- [ ] **Win rate target**: ___% (es: >55%)

---

## ✨ Opzionale (Nice to Have)

- [ ] Dashboard monitoring (Grafana + Prometheus)
- [ ] Notifiche Telegram per operazioni
- [ ] Webhook Discord per alerts
- [ ] Multi-timeframe analysis
- [ ] Backtesting framework
- [ ] Paper trading mode
- [ ] A/B testing diverse strategie
- [ ] Machine learning per ottimizzazione parametri

---

## 📝 Note Finali

**Data primo deployment**: _______________

**Versione**: v1.0.0

**Configurazione**:
- Testnet: [ ] Sì [ ] No
- Mainnet: [ ] Sì [ ] No
- Leva max: _____x
- Asset tradati: _____________________

**Team/Responsabili**:
- DevOps: _____________________
- Trading Strategy: _____________________
- Monitoring: _____________________

---

**Firma**: _____________________

**Data**: _____________________

---

**Status Deployment**:
- [ ] ✅ Production Ready
- [ ] ⚠️ Testing Phase
- [ ] 🚧 In Development

---

Buon trading! 🚀
