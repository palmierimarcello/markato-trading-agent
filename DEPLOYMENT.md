# Trading Agent - Guida al Deployment su Plesk con Docker

Questa guida ti accompagna passo per passo nel deployment del Trading Agent su un server Plesk utilizzando Docker.

## Indice
1. [Prerequisiti](#prerequisiti)
2. [Configurazione Plesk](#configurazione-plesk)
3. [Setup Docker](#setup-docker)
4. [Configurazione Dominio e NGINX](#configurazione-dominio-e-nginx)
5. [Avvio e Monitoraggio](#avvio-e-monitoraggio)
6. [Troubleshooting](#troubleshooting)

---

## 1. Prerequisiti

### Requisiti Server
- Plesk Obsidian 18.0.x o superiore
- Docker e Docker Compose installati
- Almeno 2GB RAM libera
- 10GB spazio disco
- Accesso SSH come root o utente con sudo

### Requisiti Account/API Keys
- **Hyperliquid**: Wallet Ethereum con private key
- **OpenAI**: API Key con accesso a GPT-5.1
- **CoinMarketCap**: API Key Pro
- **Dominio**: Dominio già configurato su Plesk

### Verifica Docker su Plesk
```bash
# Connettiti via SSH al server
ssh root@your-server-ip

# Verifica installazione Docker
docker --version
docker compose version

# Se Docker non è installato, installalo:
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
```

---

## 2. Configurazione Plesk

### 2.1 Crea Sottoscrizione/Dominio
1. Accedi a Plesk
2. Vai su **Websites & Domains** → **Add Domain**
3. Inserisci il tuo dominio (es. `trading.tuodominio.com`)
4. Configura SSL/TLS con Let's Encrypt

### 2.2 Abilita Accesso SSH per il Dominio
1. Vai su **Websites & Domains** → `tuodominio.com` → **Web Hosting Access**
2. Abilita **Access to the server over SSH**
3. Annota username e crea/configura password

---

## 3. Setup Docker

### 3.1 Carica il Codice sul Server

**Opzione A: Via Git (Consigliato)**
```bash
# Connettiti via SSH
ssh your-plesk-user@your-server-ip

# Naviga nella home directory
cd ~

# Clona la repository
git clone https://github.com/your-username/markato-trading-agent.git
cd markato-trading-agent
```

**Opzione B: Via FTP/SFTP**
1. Usa FileZilla o WinSCP
2. Connettiti al server
3. Carica tutti i file nella directory `/var/www/vhosts/tuodominio.com/trading-agent/`

### 3.2 Configura le Variabili d'Ambiente

```bash
# Copia il template .env
cp .env.example .env

# Modifica il file .env con le tue credenziali
nano .env
```

Compila tutti i valori:
```bash
# Database
POSTGRES_DB=trading_db
POSTGRES_USER=trading_user
POSTGRES_PASSWORD=YOUR_SECURE_PASSWORD_HERE

DATABASE_URL=postgresql://trading_user:YOUR_SECURE_PASSWORD_HERE@postgres:5432/trading_db

# Hyperliquid
PRIVATE_KEY=your_ethereum_private_key
WALLET_ADDRESS=0xYourEthereumAddress

# OpenAI
OPENAI_API_KEY=sk-proj-your_openai_key

# CoinMarketCap
CMC_PRO_API_KEY=your_cmc_api_key
```

Salva con `Ctrl+O`, esci con `Ctrl+X`.

### 3.3 Build e Avvio dei Container

```bash
# Costruisci le immagini Docker
docker compose build

# Avvia i servizi in background
docker compose up -d

# Verifica che i container siano running
docker compose ps
```

Output atteso:
```
NAME                    STATUS              PORTS
trading_agent_db        Up 10 seconds       0.0.0.0:5432->5432/tcp
trading_agent_app       Up 8 seconds
trading_agent_api       Up 8 seconds        0.0.0.0:8000->8000/tcp
```

### 3.4 Inizializza il Database

Il database viene inizializzato automaticamente all'avvio. Verifica:

```bash
# Controlla i logs dell'API
docker compose logs web_api

# Dovresti vedere: "[API] Database initialized successfully"
```

---

## 4. Configurazione Dominio e NGINX

### 4.1 Configura il Reverse Proxy su Plesk

1. **Vai su Plesk** → `tuodominio.com` → **Apache & nginx Settings**

2. **Nella sezione "Additional nginx directives"**, incolla:

```nginx
location / {
    proxy_pass http://127.0.0.1:8000;
    proxy_http_version 1.1;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_buffering off;
}

location /health {
    proxy_pass http://127.0.0.1:8000/health;
    add_header Cache-Control "no-cache";
}
```

3. Clicca **OK** per salvare

### 4.2 Verifica SSL/TLS

1. Vai su **SSL/TLS Certificates**
2. Se non hai già un certificato, clicca **Install** e scegli **Let's Encrypt**
3. Abilita **Redirect HTTP to HTTPS**

### 4.3 Test del Dominio

```bash
# Da un altro terminale/browser
curl https://tuodominio.com/health

# Output atteso:
# {
#   "status": "healthy",
#   "timestamp": "2025-12-07T10:30:00Z",
#   "service": "Trading Agent API"
# }
```

---

## 5. Avvio e Monitoraggio

### 5.1 Comandi Docker Utili

```bash
# Visualizza i logs in tempo reale
docker compose logs -f

# Visualizza solo i logs del trading agent
docker compose logs -f trading_agent

# Visualizza solo i logs dell'API
docker compose logs -f web_api

# Riavvia tutti i servizi
docker compose restart

# Ferma tutti i servizi
docker compose down

# Ferma e rimuovi anche i volumi (ATTENZIONE: cancella il DB!)
docker compose down -v
```

### 5.2 Endpoint API Disponibili

Dopo il deployment, puoi accedere a:

- **`/`** - Informazioni sull'API
- **`/health`** - Health check
- **`/status`** - Stato account e posizioni correnti
- **`/operations?limit=50`** - Ultime 50 operazioni del bot
- **`/performance`** - Metriche di performance (P&L, ROI, ecc.)

Esempio:
```bash
curl https://tuodominio.com/status
curl https://tuodominio.com/performance
curl https://tuodominio.com/operations?limit=10
```

### 5.3 Configurare Cron Job (Opzionale)

Se vuoi eseguire il bot a intervalli regolari invece che in modalità continua:

1. Modifica `docker-compose.yml` commentando il servizio `trading_agent`

2. Aggiungi un cron job sul server:
```bash
# Apri il crontab
crontab -e

# Esegui il bot ogni 15 minuti
*/15 * * * * cd /var/www/vhosts/tuodominio.com/trading-agent && docker compose run --rm trading_agent python main.py >> /var/log/trading-agent.log 2>&1
```

### 5.4 Monitoraggio Database

```bash
# Connettiti al database PostgreSQL
docker compose exec postgres psql -U trading_user -d trading_db

# Query utili:
# Vedi ultimi snapshots
SELECT created_at, balance_usd FROM account_snapshots ORDER BY created_at DESC LIMIT 10;

# Vedi ultime operazioni
SELECT created_at, operation, symbol, direction FROM bot_operations ORDER BY created_at DESC LIMIT 10;

# Esci
\q
```

---

## 6. Troubleshooting

### Container non si avvia
```bash
# Controlla i logs dettagliati
docker compose logs trading_agent
docker compose logs postgres

# Verifica la configurazione
docker compose config
```

### Errore di connessione al Database
```bash
# Verifica che PostgreSQL sia healthy
docker compose ps

# Prova a ricreare i container
docker compose down
docker compose up -d
```

### API non risponde
```bash
# Verifica che il container API sia running
docker ps | grep trading_agent_api

# Controlla i logs
docker compose logs web_api

# Testa localmente
curl http://localhost:8000/health
```

### Errori di permessi
```bash
# Assicurati che l'utente abbia i permessi corretti
sudo chown -R $USER:$USER /var/www/vhosts/tuodominio.com/trading-agent/

# Verifica permessi file .env
chmod 600 .env
```

### NGINX 502 Bad Gateway
```bash
# Verifica che il container API sia running sulla porta 8000
docker compose ps

# Controlla i logs di NGINX su Plesk
tail -f /var/log/nginx/error.log

# Verifica il firewall
sudo ufw status
sudo ufw allow 8000/tcp
```

### Backup Database
```bash
# Crea un backup del database
docker compose exec postgres pg_dump -U trading_user trading_db > backup_$(date +%Y%m%d).sql

# Ripristina da backup
cat backup_20251207.sql | docker compose exec -T postgres psql -U trading_user trading_db
```

---

## 7. Aggiornamenti e Manutenzione

### Aggiornare il Codice
```bash
# Se usi Git
git pull origin main

# Ricostruisci i container
docker compose build

# Riavvia i servizi
docker compose up -d
```

### Aggiornare le Dipendenze
```bash
# Modifica requirements.txt
nano requirements.txt

# Ricostruisci
docker compose build --no-cache
docker compose up -d
```

### Pulizia Container Vecchi
```bash
# Rimuovi container non utilizzati
docker system prune -a

# Rimuovi volumi non utilizzati
docker volume prune
```

---

## 8. Sicurezza

- ✅ Usa sempre **HTTPS** (Let's Encrypt configurato su Plesk)
- ✅ Non committare mai il file `.env` su Git
- ✅ Usa password forti per PostgreSQL
- ✅ Limita l'accesso SSH solo a IP fidati
- ✅ Monitora regolarmente i logs per attività sospette
- ✅ Fai backup regolari del database

---

## Supporto

Per problemi o domande:
- GitHub Issues: [https://github.com/your-username/markato-trading-agent/issues](https://github.com/your-username/markato-trading-agent/issues)
- Email: your-email@example.com

---

**Buon Trading! 🚀**
