# Trading Agent - Comandi Utili

Raccolta di comandi utili per gestire il Trading Agent.

## 🚀 Deployment Locale

### Prima Configurazione
```bash
# 1. Copia e configura .env
cp .env.example .env
nano .env

# 2. Avvia con script automatico
./start.sh

# 3. Oppure manualmente
docker compose up -d
```

### Gestione Servizi
```bash
# Avvia tutti i servizi
docker compose up -d

# Ferma tutti i servizi
docker compose down

# Riavvia tutti i servizi
docker compose restart

# Riavvia un servizio specifico
docker compose restart trading_agent
docker compose restart web_api
docker compose restart postgres

# Ferma e rimuove tutto (inclusi volumi - ATTENZIONE!)
docker compose down -v
```

## 📦 Deployment Remoto

### Deploy su Server VPS
```bash
# Deploy completo con un comando
./deploy-remote.sh root@123.456.789.10

# Oppure deploy manuale via SCP
scp -r . root@123.456.789.10:/opt/markato-trading-agent/
ssh root@123.456.789.10
cd /opt/markato-trading-agent
docker compose up -d
```

## 📊 Monitoring e Logs

### Visualizzare Logs
```bash
# Tutti i servizi (live)
docker compose logs -f

# Solo trading agent
docker compose logs -f trading_agent

# Solo API
docker compose logs -f web_api

# Solo database
docker compose logs -f postgres

# Ultimi 100 log
docker compose logs --tail=100

# Log di un servizio specifico
docker compose logs --tail=50 -f trading_agent
```

### Stato Container
```bash
# Stato di tutti i container
docker compose ps

# Dettagli risorsa utilizzate
docker stats

# Lista tutti i container (anche fermati)
docker ps -a
```

## 🗄️ Database

### Accesso al Database
```bash
# Connettiti al database PostgreSQL
docker compose exec postgres psql -U trading_user -d trading_db

# Una volta dentro:
\dt                           # Lista tabelle
\d table_name                 # Descrive una tabella
SELECT * FROM account_snapshots LIMIT 10;
\q                           # Esci
```

### Query Utili
```sql
-- Ultimo snapshot account
SELECT created_at, balance_usd
FROM account_snapshots
ORDER BY created_at DESC LIMIT 1;

-- Ultime 10 operazioni
SELECT created_at, operation, symbol, direction, leverage
FROM bot_operations
ORDER BY created_at DESC LIMIT 10;

-- Posizioni aperte attuali
SELECT s.created_at, p.symbol, p.side, p.size, p.pnl_usd
FROM open_positions p
JOIN account_snapshots s ON p.snapshot_id = s.id
ORDER BY s.created_at DESC LIMIT 20;

-- Performance totale
SELECT
    MIN(balance_usd) as min_balance,
    MAX(balance_usd) as max_balance,
    (MAX(balance_usd) - MIN(balance_usd)) as total_profit
FROM account_snapshots;

-- Conteggio operazioni per tipo
SELECT operation, COUNT(*)
FROM bot_operations
GROUP BY operation;
```

### Backup e Restore
```bash
# Backup database
docker compose exec postgres pg_dump -U trading_user trading_db > backup_$(date +%Y%m%d_%H%M%S).sql

# Restore da backup
cat backup_20251207_153000.sql | docker compose exec -T postgres psql -U trading_user trading_db

# Backup automatico con compressione
docker compose exec postgres pg_dump -U trading_user trading_db | gzip > backup_$(date +%Y%m%d).sql.gz

# Restore da backup compresso
gunzip < backup_20251207.sql.gz | docker compose exec -T postgres psql -U trading_user trading_db
```

## 🌐 API Testing

### Health Check
```bash
# Locale
curl http://localhost:8000/health

# Remoto
curl https://tuodominio.com/health

# Con formattazione JSON
curl http://localhost:8000/health | jq
```

### Status Account
```bash
curl http://localhost:8000/status | jq

# Solo balance
curl -s http://localhost:8000/status | jq '.data.balance_usd'
```

### Operazioni Recenti
```bash
# Ultime 10 operazioni
curl http://localhost:8000/operations?limit=10 | jq

# Conta operazioni
curl -s http://localhost:8000/operations?limit=100 | jq '.count'
```

### Performance Metrics
```bash
curl http://localhost:8000/performance | jq

# Solo ROI
curl -s http://localhost:8000/performance | jq '.data.total_return_percent'
```

## 🔧 Manutenzione

### Update Codice
```bash
# Se usi Git
git pull origin main

# Rebuild container
docker compose build --no-cache

# Riavvia
docker compose up -d
```

### Pulizia Sistema
```bash
# Rimuovi container fermati
docker container prune -f

# Rimuovi immagini inutilizzate
docker image prune -a -f

# Rimuovi volumi non usati (ATTENZIONE!)
docker volume prune -f

# Pulizia completa
docker system prune -a -f --volumes
```

### Reset Completo
```bash
# ATTENZIONE: Cancella TUTTI i dati!
docker compose down -v
rm -rf postgres_data/
docker compose up -d
```

## 🔍 Debug

### Esegui Comandi nei Container
```bash
# Shell nel container trading_agent
docker compose exec trading_agent bash

# Shell nel container postgres
docker compose exec postgres bash

# Esegui script Python
docker compose exec trading_agent python -c "import db_utils; db_utils.init_db()"
```

### Verifica Environment Variables
```bash
# Mostra variabili d'ambiente del container
docker compose exec trading_agent env | grep -E 'OPENAI|HYPERLIQUID|POSTGRES'
```

### Rebuild Forzato
```bash
# Ferma tutto
docker compose down

# Rimuovi immagini
docker compose rm -f

# Build senza cache
docker compose build --no-cache --pull

# Avvia
docker compose up -d
```

### Test Connessioni
```bash
# Test connessione database
docker compose exec trading_agent python -c "import psycopg2; conn = psycopg2.connect('postgresql://trading_user:password@postgres:5432/trading_db'); print('DB OK')"

# Test import moduli
docker compose exec trading_agent python -c "import hyperliquid; import openai; print('Imports OK')"
```

## 🔐 Sicurezza

### Verifica Permessi File
```bash
# .env deve essere 600
chmod 600 .env
ls -la .env

# Script devono essere eseguibili
chmod +x start.sh deploy-remote.sh
```

### Rotazione Log
```bash
# Pulisci log Docker
docker compose logs --tail=0 -f

# Configura logrotate per Docker
sudo nano /etc/docker/daemon.json
```
Aggiungi:
```json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
```
```bash
sudo systemctl restart docker
```

## 📡 Networking

### Verifica Porte
```bash
# Verifica porte aperte
netstat -tulpn | grep -E '8000|5432'

# Oppure con ss
ss -tulpn | grep -E '8000|5432'

# Test porta API
nc -zv localhost 8000
```

### Firewall (UFW)
```bash
# Status firewall
sudo ufw status

# Consenti porta API
sudo ufw allow 8000/tcp

# Consenti solo da IP specifico
sudo ufw allow from 123.456.789.10 to any port 8000 proto tcp

# Rimuovi regola
sudo ufw delete allow 8000/tcp
```

## 🔄 Cron Jobs

### Esecuzione Schedulata
```bash
# Apri crontab
crontab -e

# Esegui bot ogni 15 minuti
*/15 * * * * cd /opt/markato-trading-agent && docker compose run --rm trading_agent python main.py >> /var/log/trading-agent.log 2>&1

# Backup database ogni giorno alle 3 AM
0 3 * * * cd /opt/markato-trading-agent && docker compose exec -T postgres pg_dump -U trading_user trading_db | gzip > /backups/trading_db_$(date +\%Y\%m\%d).sql.gz
```

## 📈 Performance Monitoring

### Risorse Container
```bash
# Uso CPU/RAM in tempo reale
docker stats

# Solo trading_agent
docker stats trading_agent_app

# Disk usage
docker system df
```

### Log Size
```bash
# Dimensione log per container
docker inspect trading_agent_app --format='{{.LogPath}}' | xargs ls -lh
```

## 🆘 Troubleshooting

### Container non si avvia
```bash
# Verifica errori
docker compose logs trading_agent

# Verifica configurazione
docker compose config

# Forza ricreazione
docker compose up -d --force-recreate
```

### Porta già in uso
```bash
# Trova processo sulla porta 8000
lsof -i :8000

# Oppure
netstat -tulpn | grep 8000

# Termina processo
kill -9 <PID>
```

### Database connection refused
```bash
# Verifica che postgres sia healthy
docker compose ps postgres

# Attendi che sia pronto
docker compose exec postgres pg_isready -U trading_user

# Ricrea solo postgres
docker compose up -d --force-recreate postgres
```

---

## 📚 Reference

- Docker Compose: https://docs.docker.com/compose/
- PostgreSQL: https://www.postgresql.org/docs/
- Flask API: https://flask.palletsprojects.com/
- Hyperliquid: https://hyperliquid.gitbook.io/

---

**Tip**: Salva i comandi più usati in uno script personale per velocizzare il workflow!
