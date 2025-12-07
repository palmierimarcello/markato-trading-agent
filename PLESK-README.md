# Trading Agent su Plesk - Guida Completa

> Setup professionale del Trading Agent su server Plesk usando il PostgreSQL già installato invece dei container Docker.

---

## 🎯 Perché Questa Configurazione?

Se hai **Plesk con PostgreSQL già installato**, è meglio usare quel database invece di creare un altro container PostgreSQL. Vantaggi:

✅ **Performance migliori** - Database nativo invece che containerizzato
✅ **Backup più semplici** - Usa gli strumenti di backup Plesk
✅ **Meno risorse** - Un servizio in meno in Docker
✅ **Integrazione Plesk** - Gestione database dal pannello Plesk
✅ **Stabilità** - PostgreSQL gestito da systemd

---

## 📦 File Specifici per Plesk

Questi file sono creati appositamente per Plesk:

| File | Scopo |
|------|-------|
| **docker-compose.plesk.yml** | Docker Compose senza servizio postgres |
| **.env.plesk.example** | Template environment con DATABASE_URL |
| **start-plesk.sh** | Script di avvio automatico per Plesk |
| **PLESK-QUICKSTART.md** | Setup rapido in 10 minuti |
| **PLESK-POSTGRES-SETUP.md** | Configurazione dettagliata database |

---

## 🚀 Setup Rapido (10 Minuti)

### Prerequisiti
- Server con Plesk installato
- PostgreSQL installato su Plesk
- Accesso SSH come root
- Docker e Docker Compose installati

### Passi

#### 1. Crea Database (UI Plesk)
```
Plesk → Databases → Add Database
- Tipo: PostgreSQL
- Nome: trading_db
- Utente: trading_user
- Password: [genera password sicura]
- Privilegi: ALL
```

#### 2. Carica Codice
```bash
ssh root@your-plesk-server.com
cd /var/www/vhosts/tuodominio.com/
git clone https://github.com/your-username/markato-trading-agent.git
cd markato-trading-agent
```

#### 3. Configura Environment
```bash
cp .env.plesk.example .env
nano .env
```

Modifica:
```env
DATABASE_URL=postgresql://trading_user:YOUR_PASSWORD@localhost:5432/trading_db
PRIVATE_KEY=your_ethereum_key
WALLET_ADDRESS=0xYourAddress
OPENAI_API_KEY=sk-proj-your_key
CMC_PRO_API_KEY=your_cmc_key
```

#### 4. Avvia
```bash
chmod +x start-plesk.sh
./start-plesk.sh
```

#### 5. Configura Proxy Plesk
```
Plesk → Websites & Domains → tuodominio.com
→ Apache & nginx Settings
→ Additional nginx directives:

location / {
    proxy_pass http://127.0.0.1:8000;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}
```

#### 6. Abilita SSL
```
SSL/TLS Certificates → Install → Let's Encrypt
✅ Redirect HTTP to HTTPS
```

✅ **Fatto!** Accedi a `https://tuodominio.com/health`

---

## 🔧 Architettura Plesk

```
Internet
  ↓
HTTPS (Let's Encrypt)
  ↓
NGINX (Plesk) - Reverse Proxy
  ↓
Docker Container (API Flask) - Port 8000
  ↓                          ↓
Docker Container (Bot)     PostgreSQL (Host)
  ↓                          ↓
Hyperliquid, OpenAI, CMC   Database (Plesk-managed)
```

**Nota chiave**: I container usano `network_mode: host` per accedere a PostgreSQL su localhost.

---

## 📋 Comandi Quotidiani

### Gestione Container
```bash
cd /var/www/vhosts/tuodominio.com/markato-trading-agent

# Visualizza logs
docker compose -f docker-compose.plesk.yml logs -f

# Stato
docker compose -f docker-compose.plesk.yml ps

# Riavvia
docker compose -f docker-compose.plesk.yml restart

# Ferma
docker compose -f docker-compose.plesk.yml down

# Rebuild dopo modifiche
docker compose -f docker-compose.plesk.yml build --no-cache
docker compose -f docker-compose.plesk.yml up -d
```

### Database
```bash
# Connessione
sudo -u postgres psql -d trading_db

# Query stato
SELECT COUNT(*) FROM account_snapshots;
SELECT * FROM bot_operations ORDER BY created_at DESC LIMIT 10;

# Backup
sudo -u postgres pg_dump trading_db > backup_$(date +%Y%m%d).sql

# Restore
sudo -u postgres psql trading_db < backup_20251207.sql
```

### API Test
```bash
curl https://tuodominio.com/health
curl https://tuodominio.com/status | jq
curl https://tuodominio.com/performance | jq
```

---

## 🔐 Configurazione PostgreSQL

### File Importanti

**pg_hba.conf** - Permessi connessione
```bash
sudo nano /var/lib/pgsql/data/pg_hba.conf
```

Aggiungi:
```conf
# Trading Agent
host    trading_db    trading_user    127.0.0.1/32    md5
```

**postgresql.conf** - Configurazione server
```bash
sudo nano /etc/postgresql/*/main/postgresql.conf
```

Verifica:
```conf
listen_addresses = 'localhost'
```

Riavvia:
```bash
sudo systemctl restart postgresql
```

---

## 📊 Monitoring

### Logs
```bash
# Logs applicazione
docker compose -f docker-compose.plesk.yml logs -f trading_agent

# Logs API
docker compose -f docker-compose.plesk.yml logs -f web_api

# Logs PostgreSQL
sudo tail -f /var/log/postgresql/postgresql-*.log
```

### Database Stats
```sql
-- Connettiti
sudo -u postgres psql -d trading_db

-- Dimensione database
SELECT pg_size_pretty(pg_database_size('trading_db'));

-- Tabelle e dimensioni
SELECT
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- Ultime operazioni
SELECT created_at, operation, symbol, direction
FROM bot_operations
ORDER BY created_at DESC
LIMIT 10;
```

### Performance Metrics
```bash
# Via API
curl -s https://tuodominio.com/performance | jq '.data'

# Output esempio:
{
  "initial_balance": 1000.00,
  "current_balance": 1056.32,
  "total_return_percent": 5.63,
  "total_snapshots": 245,
  "operations_by_type": {
    "open": 45,
    "close": 38,
    "hold": 162
  }
}
```

---

## 🔄 Backup e Recovery

### Backup Automatico

Crea script:
```bash
sudo nano /usr/local/bin/backup-trading-db.sh
```

```bash
#!/bin/bash
BACKUP_DIR="/var/backups/trading-agent"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

sudo -u postgres pg_dump trading_db | gzip > $BACKUP_DIR/trading_db_$DATE.sql.gz

# Mantieni solo ultimi 30 giorni
find $BACKUP_DIR -name "trading_db_*.sql.gz" -mtime +30 -delete

echo "[$(date)] Backup completato: $BACKUP_DIR/trading_db_$DATE.sql.gz"
```

Rendi eseguibile e aggiungi a cron:
```bash
sudo chmod +x /usr/local/bin/backup-trading-db.sh

sudo crontab -e
# Aggiungi: backup ogni giorno alle 3 AM
0 3 * * * /usr/local/bin/backup-trading-db.sh >> /var/log/trading-db-backup.log 2>&1
```

### Recovery
```bash
# Lista backup
ls -lh /var/backups/trading-agent/

# Restore
gunzip < /var/backups/trading-agent/trading_db_20251207_030001.sql.gz | sudo -u postgres psql trading_db
```

---

## 🆘 Troubleshooting

### Problema: Container non connette al database

**Verifica connessione:**
```bash
# Test da host
psql -U trading_user -d trading_db -h localhost

# Test da container
docker compose -f docker-compose.plesk.yml exec trading_agent \
  python -c "import psycopg2; psycopg2.connect('$DATABASE_URL'); print('OK')"
```

**Soluzione:**
1. Verifica `pg_hba.conf` ha entry per 127.0.0.1
2. Verifica password in `.env` corretta
3. Verifica PostgreSQL in ascolto su localhost

### Problema: API non risponde

```bash
# Verifica container running
docker compose -f docker-compose.plesk.yml ps

# Verifica porta 8000 libera
netstat -tulpn | grep 8000

# Logs API
docker compose -f docker-compose.plesk.yml logs web_api
```

### Problema: NGINX 502 Bad Gateway

```bash
# Verifica API risponde
curl http://localhost:8000/health

# Se sì, problema è configurazione NGINX
# Verifica direttive nginx su Plesk

# Logs nginx
tail -f /var/log/nginx/error.log
```

---

## 📈 Update e Manutenzione

### Update Codice
```bash
cd /var/www/vhosts/tuodominio.com/markato-trading-agent

git pull origin main

docker compose -f docker-compose.plesk.yml build --no-cache
docker compose -f docker-compose.plesk.yml up -d
```

### Update Dipendenze
```bash
# Modifica requirements.txt
nano requirements.txt

# Rebuild
docker compose -f docker-compose.plesk.yml build --no-cache
docker compose -f docker-compose.plesk.yml up -d
```

### Pulizia
```bash
# Rimuovi container vecchi
docker system prune -a

# Rimuovi log vecchi
find ./logs -name "*.log" -mtime +30 -delete
```

---

## ✅ Checklist Pre-Produzione

- [ ] Database PostgreSQL creato su Plesk
- [ ] Utente `trading_user` con privilegi completi
- [ ] `pg_hba.conf` configurato per localhost
- [ ] `.env` configurato con DATABASE_URL corretto
- [ ] `docker-compose.plesk.yml` usato (NON docker-compose.yml)
- [ ] Container in running state
- [ ] Health check API funzionante
- [ ] NGINX reverse proxy configurato
- [ ] SSL/TLS Let's Encrypt attivo
- [ ] Backup automatici configurati
- [ ] Firewall configurato (solo 80, 443, 22)
- [ ] Test trading completato su testnet
- [ ] Monitoring configurato

---

## 📞 Supporto

- **Quick Start**: [PLESK-QUICKSTART.md](PLESK-QUICKSTART.md)
- **Setup DB**: [PLESK-POSTGRES-SETUP.md](PLESK-POSTGRES-SETUP.md)
- **Comandi**: [COMMANDS.md](COMMANDS.md)
- **Issues**: [GitHub Issues](https://github.com/your-username/markato-trading-agent/issues)

---

**Il tuo Trading Agent è pronto su Plesk!** 🚀

API disponibile su: `https://tuodominio.com`
Dashboard: `https://tuodominio.com/performance`
Health: `https://tuodominio.com/health`
