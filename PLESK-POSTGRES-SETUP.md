# Trading Agent - Setup PostgreSQL su Plesk

Guida per configurare il database PostgreSQL usando l'installazione già presente su Plesk invece del container Docker.

---

## 📋 Prerequisiti

- Plesk con PostgreSQL già installato
- Accesso come amministratore Plesk
- Accesso SSH al server

---

## 🗄️ Opzione 1: Creazione Database via Plesk UI

### Step 1: Accedi a Plesk Database Manager

1. **Login su Plesk** con le tue credenziali
2. Vai su **Databases** dal menu principale
3. Clicca su **Add Database**

### Step 2: Crea il Database

Compila i campi:

```
Database type: PostgreSQL
Database name: trading_db
Database server: localhost (default)
```

Clicca **OK**

### Step 3: Crea Utente Database

1. Nella pagina del database appena creato
2. Clicca su **User Management**
3. Clicca **Add Database User**

Compila:
```
Username: trading_user
Password: [genera password sicura, salvala!]
Access hosts: localhost
```

### Step 4: Assegna Permessi

1. Torna alla pagina del database
2. Nella sezione **Users**, seleziona `trading_user`
3. Assegna tutti i privilegi:
   - ✅ SELECT
   - ✅ INSERT
   - ✅ UPDATE
   - ✅ DELETE
   - ✅ CREATE
   - ✅ DROP
   - ✅ INDEX
   - ✅ ALTER
   - ✅ CREATE TEMPORARY TABLES
   - ✅ LOCK TABLES

Clicca **OK**

### Step 5: Annota le Credenziali

```
Host: localhost
Port: 5432 (default PostgreSQL)
Database: trading_db
Username: trading_user
Password: [la password che hai creato]
```

---

## 🗄️ Opzione 2: Creazione Database via SSH (Manuale)

Se preferisci creare il database da terminale:

### Step 1: Connettiti via SSH

```bash
ssh root@your-plesk-server.com
```

### Step 2: Accedi a PostgreSQL come Superuser

```bash
# Diventa utente postgres
sudo -u postgres psql
```

Vedrai il prompt: `postgres=#`

### Step 3: Crea Database e Utente

```sql
-- Crea il database
CREATE DATABASE trading_db;

-- Crea l'utente con password
CREATE USER trading_user WITH ENCRYPTED PASSWORD 'your_secure_password_here';

-- Assegna tutti i privilegi sul database
GRANT ALL PRIVILEGES ON DATABASE trading_db TO trading_user;

-- Esci
\q
```

### Step 4: Verifica Connessione

```bash
# Testa la connessione con il nuovo utente
psql -U trading_user -d trading_db -h localhost

# Dovresti vedere il prompt: trading_db=>
# Esci con \q
```

---

## 🔧 Configurazione Trading Agent

### Step 1: Modifica docker-compose.yml

Ora che usi PostgreSQL esterno, devi **rimuovere il servizio postgres** dal docker-compose.yml.

Apri il file:
```bash
nano docker-compose.yml
```

**Prima** (rimuovi questa sezione):
```yaml
  # Database PostgreSQL
  postgres:
    image: postgres:15-alpine
    container_name: trading_agent_db
    restart: unless-stopped
    environment:
      POSTGRES_DB: ${POSTGRES_DB:-trading_db}
      POSTGRES_USER: ${POSTGRES_USER:-trading_user}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-change_this_password}
      PGDATA: /var/lib/postgresql/data/pgdata
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER:-trading_user} -d ${POSTGRES_DB:-trading_db}"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - trading_network
```

E anche rimuovi dai servizi `trading_agent` e `web_api` la dipendenza da postgres:

**Rimuovi queste righe**:
```yaml
    depends_on:
      postgres:
        condition: service_healthy
```

**Dopo** (versione semplificata):

Il file completo aggiornato è disponibile in fondo a questa guida.

### Step 2: Configura .env con Database Esterno

```bash
nano .env
```

Modifica la stringa di connessione:

```env
# PostgreSQL su Plesk (NON Docker)
DATABASE_URL=postgresql://trading_user:your_secure_password@localhost:5432/trading_db

# NON servono più queste (commentale o rimuovile):
# POSTGRES_DB=trading_db
# POSTGRES_USER=trading_user
# POSTGRES_PASSWORD=...
```

**IMPORTANTE**:
- Usa `localhost` come host (il container accederà al DB del server host)
- Usa la porta `5432` (default PostgreSQL)
- Inserisci la password corretta

### Step 3: Permetti Connessione dal Container

Devi configurare PostgreSQL per accettare connessioni dal container Docker.

#### 3a. Modifica pg_hba.conf

```bash
# Trova il file di configurazione
sudo -u postgres psql -c "SHOW hba_file"

# Output tipico: /var/lib/pgsql/data/pg_hba.conf
# Oppure: /etc/postgresql/13/main/pg_hba.conf (varia per versione)

# Modifica il file
sudo nano /var/lib/pgsql/data/pg_hba.conf
```

Aggiungi questa riga **prima** delle altre regole:

```conf
# Permetti connessione da Docker containers
host    trading_db      trading_user    172.16.0.0/12    md5
host    trading_db      trading_user    127.0.0.1/32     md5
```

#### 3b. Verifica postgresql.conf

```bash
# Trova postgresql.conf
sudo -u postgres psql -c "SHOW config_file"

# Modifica
sudo nano /etc/postgresql/13/main/postgresql.conf
```

Verifica che `listen_addresses` includa localhost:

```conf
listen_addresses = 'localhost,127.0.0.1'
```

#### 3c. Riavvia PostgreSQL

```bash
# Su CentOS/RHEL
sudo systemctl restart postgresql

# Su Ubuntu/Debian
sudo systemctl restart postgresql
```

### Step 4: Usa network_mode: host per Docker

Per permettere ai container di accedere a PostgreSQL su localhost, modifica `docker-compose.yml`:

```yaml
services:
  trading_agent:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: trading_agent_app
    restart: unless-stopped
    network_mode: "host"  # <-- AGGIUNGI QUESTA RIGA
    environment:
      DATABASE_URL: ${DATABASE_URL}
      PRIVATE_KEY: ${PRIVATE_KEY}
      WALLET_ADDRESS: ${WALLET_ADDRESS}
      OPENAI_API_KEY: ${OPENAI_API_KEY}
      CMC_PRO_API_KEY: ${CMC_PRO_API_KEY}
    volumes:
      - ./logs:/app/logs

  web_api:
    build:
      context: .
      dockerfile: Dockerfile.api
    container_name: trading_agent_api
    restart: unless-stopped
    network_mode: "host"  # <-- AGGIUNGI QUESTA RIGA
    environment:
      DATABASE_URL: ${DATABASE_URL}
    # RIMUOVI la sezione ports: perché con host mode non serve
```

---

## 🧪 Test Connessione Database

### Test 1: Da Host

```bash
# Testa connessione diretta
psql -U trading_user -d trading_db -h localhost

# Se chiede password, inseriscila
# Dovresti vedere: trading_db=>

# Esci
\q
```

### Test 2: Da Container Docker

```bash
# Avvia i container
docker compose up -d

# Entra nel container
docker compose exec trading_agent bash

# Testa connessione Python
python3 << EOF
import psycopg2
try:
    conn = psycopg2.connect(
        dbname='trading_db',
        user='trading_user',
        password='your_password',
        host='localhost',
        port='5432'
    )
    print("✅ Connessione OK!")
    conn.close()
except Exception as e:
    print(f"❌ Errore: {e}")
EOF

# Esci dal container
exit
```

### Test 3: Inizializza Schema

```bash
# Crea le tabelle nel database
docker compose exec trading_agent python3 -c "import db_utils; db_utils.init_db(); print('Database initialized!')"
```

Se vedi **"Database initialized!"**, tutto funziona! ✅

---

## 📄 docker-compose.yml Completo (Versione Plesk)

Salva questo come tuo `docker-compose.yml`:

```yaml
version: '3.8'

services:
  # Trading Agent Application
  trading_agent:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: trading_agent_app
    restart: unless-stopped
    network_mode: "host"
    environment:
      # Database esterno Plesk
      DATABASE_URL: ${DATABASE_URL}

      # Hyperliquid
      PRIVATE_KEY: ${PRIVATE_KEY}
      WALLET_ADDRESS: ${WALLET_ADDRESS}

      # OpenAI
      OPENAI_API_KEY: ${OPENAI_API_KEY}

      # CoinMarketCap
      CMC_PRO_API_KEY: ${CMC_PRO_API_KEY}

      # Python
      PYTHONUNBUFFERED: 1
    volumes:
      - ./logs:/app/logs
      - ./account_status_old.json:/app/account_status_old.json

  # API Web
  web_api:
    build:
      context: .
      dockerfile: Dockerfile.api
    container_name: trading_agent_api
    restart: unless-stopped
    network_mode: "host"
    environment:
      DATABASE_URL: ${DATABASE_URL}
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3

# Non servono più volumi per postgres
# Non serve più network personalizzato (usiamo host)
```

---

## 🔐 Sicurezza Database

### Backup Manuale

```bash
# Backup completo
sudo -u postgres pg_dump trading_db > backup_$(date +%Y%m%d).sql

# Backup compresso
sudo -u postgres pg_dump trading_db | gzip > backup_$(date +%Y%m%d).sql.gz
```

### Backup Automatico con Cron

```bash
# Crea script di backup
sudo nano /usr/local/bin/backup-trading-db.sh
```

Contenuto:
```bash
#!/bin/bash
BACKUP_DIR="/var/backups/trading-agent"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

sudo -u postgres pg_dump trading_db | gzip > $BACKUP_DIR/trading_db_$DATE.sql.gz

# Mantieni solo backup ultimi 7 giorni
find $BACKUP_DIR -name "trading_db_*.sql.gz" -mtime +7 -delete

echo "Backup completato: $BACKUP_DIR/trading_db_$DATE.sql.gz"
```

```bash
# Rendi eseguibile
sudo chmod +x /usr/local/bin/backup-trading-db.sh

# Aggiungi a cron (ogni giorno alle 3 AM)
sudo crontab -e

# Aggiungi:
0 3 * * * /usr/local/bin/backup-trading-db.sh >> /var/log/trading-db-backup.log 2>&1
```

### Restore da Backup

```bash
# Decomprimi
gunzip backup_20251207.sql.gz

# Restore
sudo -u postgres psql trading_db < backup_20251207.sql
```

---

## 📊 Monitoring Database

### Verifica Tabelle Create

```bash
sudo -u postgres psql -d trading_db -c "\dt"
```

Output atteso:
```
                  List of relations
 Schema |         Name          | Type  |    Owner
--------+-----------------------+-------+--------------
 public | account_snapshots     | table | trading_user
 public | ai_contexts           | table | trading_user
 public | bot_operations        | table | trading_user
 public | errors                | table | trading_user
 public | forecasts_contexts    | table | trading_user
 public | indicators_contexts   | table | trading_user
 public | news_contexts         | table | trading_user
 public | open_positions        | table | trading_user
 public | sentiment_contexts    | table | trading_user
```

### Query Utili

```bash
# Conta record per tabella
sudo -u postgres psql -d trading_db << EOF
SELECT 'account_snapshots' as table_name, COUNT(*) FROM account_snapshots
UNION ALL
SELECT 'bot_operations', COUNT(*) FROM bot_operations
UNION ALL
SELECT 'open_positions', COUNT(*) FROM open_positions;
EOF
```

### Dimensione Database

```bash
sudo -u postgres psql -d trading_db -c "SELECT pg_size_pretty(pg_database_size('trading_db'))"
```

---

## ✅ Checklist Setup Completo

- [ ] Database `trading_db` creato su PostgreSQL Plesk
- [ ] Utente `trading_user` creato con privilegi
- [ ] Password sicura generata e salvata
- [ ] `pg_hba.conf` configurato per connessioni localhost
- [ ] PostgreSQL riavviato
- [ ] `docker-compose.yml` aggiornato (rimosso servizio postgres)
- [ ] `.env` configurato con `DATABASE_URL` corretto
- [ ] `network_mode: host` aggiunto ai servizi Docker
- [ ] Test connessione da host funzionante
- [ ] Test connessione da container funzionante
- [ ] Schema database inizializzato (`db_utils.init_db()`)
- [ ] Tabelle create verificate
- [ ] Script backup configurato
- [ ] Cron job backup attivo

---

## 🆘 Troubleshooting

### Errore: "password authentication failed"

```bash
# Verifica password
sudo -u postgres psql -c "\du trading_user"

# Resetta password se necessario
sudo -u postgres psql -c "ALTER USER trading_user WITH PASSWORD 'new_password';"
```

### Errore: "connection refused"

```bash
# Verifica che PostgreSQL sia in ascolto
sudo netstat -plnt | grep 5432

# Verifica configurazione
sudo -u postgres psql -c "SHOW listen_addresses;"

# Deve essere: localhost o *
```

### Errore: "no pg_hba.conf entry"

```bash
# Aggiungi entry in pg_hba.conf
sudo nano /var/lib/pgsql/data/pg_hba.conf

# Aggiungi:
host    trading_db    trading_user    127.0.0.1/32    md5

# Riavvia
sudo systemctl restart postgresql
```

### Container non riesce a connettersi

```bash
# Verifica network_mode
docker compose config | grep network_mode

# Deve essere "host"

# Verifica DATABASE_URL
docker compose exec trading_agent env | grep DATABASE_URL
```

---

## 📞 Supporto

Se hai problemi con questa configurazione:
1. Verifica i logs: `docker compose logs -f`
2. Testa connessione manuale: `psql -U trading_user -d trading_db`
3. Verifica pg_hba.conf e postgresql.conf
4. Consulta [COMMANDS.md](COMMANDS.md) per altri comandi utili

---

**Configurazione completata!** Il tuo Trading Agent ora usa PostgreSQL di Plesk invece del container Docker. 🎉
