# Trading Agent - Plesk Quick Start

Guida rapida per deployare su Plesk usando il PostgreSQL già installato.

---

## 🎯 Setup in 10 Minuti

### 1. Crea Database su Plesk (5 min)

**Via Plesk UI:**
1. Login Plesk → **Databases** → **Add Database**
2. Tipo: **PostgreSQL**
3. Nome: `trading_db`
4. Crea utente: `trading_user` con password sicura
5. Assegna **tutti i privilegi**

**Oppure via SSH:**
```bash
ssh root@your-server.com

sudo -u postgres psql << EOF
CREATE DATABASE trading_db;
CREATE USER trading_user WITH ENCRYPTED PASSWORD 'your_secure_password';
GRANT ALL PRIVILEGES ON DATABASE trading_db TO trading_user;
\q
EOF
```

✅ Salva le credenziali!

---

### 2. Carica Codice sul Server (2 min)

**Opzione A - Git:**
```bash
ssh root@your-server.com
cd /var/www/vhosts/tuodominio.com/
git clone https://github.com/your-username/markato-trading-agent.git
cd markato-trading-agent
```

**Opzione B - SCP:**
```bash
# Dal tuo computer
scp -r /Users/marcello/GitHub-Repo/markato-trading-agent root@your-server.com:/var/www/vhosts/tuodominio.com/
```

---

### 3. Configura Ambiente (2 min)

```bash
# Sul server
cd /var/www/vhosts/tuodominio.com/markato-trading-agent

# Copia template Plesk
cp .env.plesk.example .env

# Modifica con le tue credenziali
nano .env
```

**Configura almeno questi**:
```env
DATABASE_URL=postgresql://trading_user:YOUR_PASSWORD@localhost:5432/trading_db
PRIVATE_KEY=your_ethereum_private_key
WALLET_ADDRESS=0xYourAddress
OPENAI_API_KEY=sk-proj-your_key
CMC_PRO_API_KEY=your_cmc_key
```

Salva con `Ctrl+O`, esci con `Ctrl+X`.

---

### 4. Avvia Container (1 min)

```bash
# Usa lo script automatico per Plesk
chmod +x start-plesk.sh
./start-plesk.sh
```

**Oppure manualmente:**
```bash
docker compose -f docker-compose.plesk.yml build
docker compose -f docker-compose.plesk.yml up -d
```

✅ Verifica:
```bash
curl http://localhost:8000/health
```

---

### 5. Configura Reverse Proxy su Plesk (2 min)

1. **Plesk** → **Websites & Domains** → `tuodominio.com`
2. **Apache & nginx Settings**
3. In **"Additional nginx directives"**:

```nginx
location / {
    proxy_pass http://127.0.0.1:8000;
    proxy_http_version 1.1;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}

location /health {
    proxy_pass http://127.0.0.1:8000/health;
}
```

4. Clicca **OK**

---

### 6. Abilita SSL (1 min)

1. **SSL/TLS Certificates**
2. **Install** → **Let's Encrypt**
3. Abilita **"Redirect HTTP to HTTPS"**

---

### 7. Test Finale

```bash
curl https://tuodominio.com/health
curl https://tuodominio.com/status
```

✅ **Fatto!** Il tuo trading agent è online su `https://tuodominio.com`

---

## 📋 Comandi Utili Plesk

### Gestione Container
```bash
cd /var/www/vhosts/tuodominio.com/markato-trading-agent

# Visualizza logs
docker compose -f docker-compose.plesk.yml logs -f

# Stato container
docker compose -f docker-compose.plesk.yml ps

# Riavvia
docker compose -f docker-compose.plesk.yml restart

# Ferma
docker compose -f docker-compose.plesk.yml down
```

### Database
```bash
# Connettiti al database
sudo -u postgres psql -d trading_db

# Query utili
SELECT COUNT(*) FROM account_snapshots;
SELECT * FROM bot_operations ORDER BY created_at DESC LIMIT 10;

# Backup
sudo -u postgres pg_dump trading_db > backup_$(date +%Y%m%d).sql
```

### Update Codice
```bash
git pull
docker compose -f docker-compose.plesk.yml build --no-cache
docker compose -f docker-compose.plesk.yml up -d
```

---

## 🔍 Differenze Plesk vs Standard

| Aspetto | Standard (docker-compose.yml) | Plesk (docker-compose.plesk.yml) |
|---------|-------------------------------|----------------------------------|
| Database | Container PostgreSQL | PostgreSQL di Plesk |
| Network | Bridge network | Host network |
| Porta DB | Esposta su 5432 | Usa localhost:5432 |
| Volumi DB | Volume Docker | Gestito da Plesk |
| Backup | Script Docker | pg_dump nativo |

---

## ⚠️ Note Importanti

1. **network_mode: host** è essenziale per accedere a PostgreSQL su localhost
2. **Non esporre porta 5432** su internet (firewall)
3. **Backup database** regolari con `pg_dump`
4. **Usa password forti** per `trading_user`

---

## 🆘 Troubleshooting Rapido

### API non risponde
```bash
docker compose -f docker-compose.plesk.yml logs web_api
curl http://localhost:8000/health
```

### Database connection error
```bash
# Verifica connessione
psql -U trading_user -d trading_db -h localhost

# Verifica pg_hba.conf
sudo nano /var/lib/pgsql/data/pg_hba.conf
# Aggiungi: host trading_db trading_user 127.0.0.1/32 md5

sudo systemctl restart postgresql
```

### Container non trova database
```bash
# Verifica DATABASE_URL
cat .env | grep DATABASE_URL

# Test da container
docker compose -f docker-compose.plesk.yml exec trading_agent \
  python -c "import psycopg2; psycopg2.connect('$DATABASE_URL'); print('OK')"
```

---

## 📚 Documentazione Completa

- [PLESK-POSTGRES-SETUP.md](PLESK-POSTGRES-SETUP.md) - Setup dettagliato database
- [DEPLOYMENT.md](DEPLOYMENT.md) - Deployment completo su Plesk
- [COMMANDS.md](COMMANDS.md) - Tutti i comandi disponibili
- [CHECKLIST.md](CHECKLIST.md) - Checklist pre-produzione

---

**Setup completato in 10 minuti!** 🎉

Prossimi passi:
- Monitora logs: `docker compose -f docker-compose.plesk.yml logs -f`
- Configura backup automatici
- Testa le API: `curl https://tuodominio.com/performance`
