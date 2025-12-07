# Trading Agent - Setup su Server Remoto

Guida completa per deployare il Trading Agent su un server remoto (VPS, Dedicated Server, Cloud) e collegarlo a Plesk con dominio.

## 📋 Scenario

Hai due opzioni:
1. **Server Remoto + Dominio su Plesk** - Il bot gira su un VPS separato, Plesk fa solo da reverse proxy
2. **Server Remoto Standalone** - Tutto su un server senza Plesk

---

## 🎯 Opzione 1: Server Remoto + Dominio su Plesk

### Architettura
```
Internet → Plesk (tuodominio.com) → Reverse Proxy → Server Remoto (VPS con Docker)
```

### Step 1: Setup Server Remoto (VPS)

#### 1.1 Connettiti al Server
```bash
# Sostituisci con il tuo IP
ssh root@123.456.789.10

# Se hai una chiave SSH
ssh -i ~/.ssh/your_key.pem root@123.456.789.10
```

#### 1.2 Installa Docker
```bash
# Update sistema
apt update && apt upgrade -y

# Installa Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Verifica installazione
docker --version
docker compose version

# Abilita Docker all'avvio
systemctl enable docker
systemctl start docker
```

#### 1.3 Installa Git
```bash
apt install git -y
```

#### 1.4 Carica il Codice

**Opzione A: Clone da GitHub**
```bash
cd /opt
git clone https://github.com/your-username/markato-trading-agent.git
cd markato-trading-agent
```

**Opzione B: Trasferimento Manuale via SCP**
```bash
# Dal tuo computer locale
scp -r /Users/marcello/GitHub-Repo/markato-trading-agent root@123.456.789.10:/opt/
```

#### 1.5 Configura Environment
```bash
cd /opt/markato-trading-agent

# Crea .env
cp .env.example .env

# Modifica con nano o vim
nano .env
```

Configura tutte le variabili:
```env
POSTGRES_DB=trading_db
POSTGRES_USER=trading_user
POSTGRES_PASSWORD=strong_password_here

DATABASE_URL=postgresql://trading_user:strong_password_here@postgres:5432/trading_db

PRIVATE_KEY=your_ethereum_private_key
WALLET_ADDRESS=0xYourAddress

OPENAI_API_KEY=sk-proj-your_key
CMC_PRO_API_KEY=your_cmc_key
```

#### 1.6 Avvia i Container
```bash
# Usa lo script automatico
chmod +x start.sh
./start.sh

# Oppure manualmente
docker compose up -d

# Verifica stato
docker compose ps
```

#### 1.7 Configura Firewall
```bash
# Installa UFW se non presente
apt install ufw -y

# Consenti SSH (IMPORTANTE: fallo prima di abilitare UFW!)
ufw allow 22/tcp

# Consenti porta API (solo da IP Plesk per sicurezza)
# Sostituisci 111.222.333.444 con l'IP del server Plesk
ufw allow from 111.222.333.444 to any port 8000 proto tcp

# Abilita firewall
ufw enable

# Verifica regole
ufw status
```

#### 1.8 Test Locale
```bash
# Test API
curl http://localhost:8000/health

# Dovresti vedere:
# {"status":"healthy","timestamp":"...","service":"Trading Agent API"}
```

### Step 2: Configurazione Plesk (Reverse Proxy)

#### 2.1 Configura Dominio su Plesk

1. Accedi a **Plesk**
2. Vai su **Websites & Domains** → `tuodominio.com`
3. Clicca su **Apache & nginx Settings**

#### 2.2 Aggiungi Direttive NGINX

Nella sezione **"Additional nginx directives"**:

```nginx
location / {
    # Sostituisci 123.456.789.10 con l'IP del tuo VPS
    proxy_pass http://123.456.789.10:8000;

    proxy_http_version 1.1;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;

    # Timeouts
    proxy_connect_timeout 60s;
    proxy_send_timeout 60s;
    proxy_read_timeout 60s;

    # Buffering
    proxy_buffering off;
    proxy_request_buffering off;
}

location /health {
    proxy_pass http://123.456.789.10:8000/health;
    add_header Cache-Control "no-cache";
}
```

#### 2.3 Abilita SSL
1. Vai su **SSL/TLS Certificates**
2. Clicca **Install** → **Let's Encrypt**
3. Abilita **"Redirect HTTP to HTTPS"**

#### 2.4 Test Finale
```bash
# Dal tuo computer locale
curl https://tuodominio.com/health

# Dovresti vedere la risposta del bot!
```

---

## 🎯 Opzione 2: Server Remoto Standalone (Senza Plesk)

Se non hai Plesk e vuoi gestire tutto sul VPS.

### Step 1: Setup VPS Completo

Segui gli Step 1.1-1.8 dell'Opzione 1.

### Step 2: Installa NGINX sul VPS

```bash
# Installa NGINX
apt install nginx -y

# Abilita all'avvio
systemctl enable nginx
systemctl start nginx
```

### Step 3: Configura NGINX come Reverse Proxy

```bash
# Crea configurazione per il sito
nano /etc/nginx/sites-available/trading-agent
```

Incolla questa configurazione:

```nginx
server {
    listen 80;
    server_name tuodominio.com www.tuodominio.com;

    # Redirect HTTP -> HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name tuodominio.com www.tuodominio.com;

    # SSL certificates (configureremo con Certbot)
    ssl_certificate /etc/letsencrypt/live/tuodominio.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/tuodominio.com/privkey.pem;

    # SSL settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    # Logs
    access_log /var/log/nginx/trading_agent_access.log;
    error_log /var/log/nginx/trading_agent_error.log;

    # Reverse proxy
    location / {
        proxy_pass http://localhost:8000;
        proxy_http_version 1.1;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    location /health {
        proxy_pass http://localhost:8000/health;
        add_header Cache-Control "no-cache";
    }
}
```

### Step 4: Configura SSL con Let's Encrypt

```bash
# Installa Certbot
apt install certbot python3-certbot-nginx -y

# Prima abilita il sito (senza SSL)
ln -s /etc/nginx/sites-available/trading-agent /etc/nginx/sites-enabled/
nginx -t
systemctl reload nginx

# Configura firewall per HTTPS
ufw allow 80/tcp
ufw allow 443/tcp

# Ottieni certificato SSL
certbot --nginx -d tuodominio.com -d www.tuodominio.com

# Il certificato si rinnova automaticamente
# Test rinnovo automatico:
certbot renew --dry-run
```

### Step 5: DNS Configuration

Nel tuo provider DNS (Cloudflare, GoDaddy, etc.):

```
Type    Name                Value               TTL
A       tuodominio.com      123.456.789.10      Auto
A       www                 123.456.789.10      Auto
```

### Step 6: Test Finale

```bash
# Test da locale
curl https://tuodominio.com/health
curl https://tuodominio.com/status
```

---

## 🔄 Automazione e Maintenance

### Systemd Service (Opzionale)

Per avviare Docker Compose automaticamente:

```bash
# Crea service file
nano /etc/systemd/system/trading-agent.service
```

Contenuto:
```ini
[Unit]
Description=Trading Agent Docker Compose
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/markato-trading-agent
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
```

```bash
# Abilita e avvia
systemctl daemon-reload
systemctl enable trading-agent.service
systemctl start trading-agent.service

# Verifica stato
systemctl status trading-agent.service
```

### Monitoring con Script

```bash
# Crea script di health check
nano /opt/check-trading-agent.sh
```

```bash
#!/bin/bash

HEALTH_URL="http://localhost:8000/health"
LOG_FILE="/var/log/trading-agent-monitor.log"

response=$(curl -s -o /dev/null -w "%{http_code}" $HEALTH_URL)

if [ $response -eq 200 ]; then
    echo "$(date): API is healthy" >> $LOG_FILE
else
    echo "$(date): API is DOWN - Response: $response" >> $LOG_FILE
    # Riavvia i container
    cd /opt/markato-trading-agent
    docker compose restart
fi
```

```bash
# Rendi eseguibile
chmod +x /opt/check-trading-agent.sh

# Aggiungi a cron (ogni 5 minuti)
crontab -e
```

Aggiungi:
```
*/5 * * * * /opt/check-trading-agent.sh
```

---

## 📊 Monitoring e Logs

### Visualizzare Logs
```bash
# Tutti i servizi
docker compose logs -f

# Solo trading agent
docker compose logs -f trading_agent

# Ultimi 100
docker compose logs --tail=100

# Logs NGINX
tail -f /var/log/nginx/trading_agent_access.log
tail -f /var/log/nginx/trading_agent_error.log
```

### Monitoring Database
```bash
# Connettiti al DB
docker compose exec postgres psql -U trading_user -d trading_db

# Query utili
SELECT COUNT(*) FROM account_snapshots;
SELECT COUNT(*) FROM bot_operations;
SELECT * FROM bot_operations ORDER BY created_at DESC LIMIT 10;
```

---

## 🔐 Sicurezza Best Practices

### 1. Configura Fail2Ban
```bash
apt install fail2ban -y
systemctl enable fail2ban
systemctl start fail2ban
```

### 2. Disabilita Password SSH (usa solo chiavi)
```bash
nano /etc/ssh/sshd_config
```
Modifica:
```
PasswordAuthentication no
PubkeyAuthentication yes
```
```bash
systemctl restart sshd
```

### 3. Aggiorna Regolarmente
```bash
# Crea script di update
nano /opt/update-system.sh
```
```bash
#!/bin/bash
apt update
apt upgrade -y
apt autoremove -y
docker system prune -f
```
```bash
chmod +x /opt/update-system.sh

# Cron settimanale
crontab -e
0 3 * * 0 /opt/update-system.sh
```

---

## 🆘 Troubleshooting

### Container si ferma
```bash
# Verifica i logs
docker compose logs trading_agent

# Riavvia
docker compose restart trading_agent
```

### Dominio non raggiungibile
```bash
# Verifica DNS
nslookup tuodominio.com

# Verifica NGINX
nginx -t
systemctl status nginx

# Verifica firewall
ufw status
```

### Database corrotto
```bash
# Backup
docker compose exec postgres pg_dump -U trading_user trading_db > backup.sql

# Ricrea
docker compose down -v
docker compose up -d
```

---

## 📞 Checklist Deployment

- [ ] Server remoto con Docker installato
- [ ] Codice caricato su `/opt/markato-trading-agent`
- [ ] File `.env` configurato con credenziali
- [ ] Container avviati e running (`docker compose ps`)
- [ ] Firewall configurato (UFW)
- [ ] NGINX configurato (se standalone)
- [ ] SSL/TLS attivo (Let's Encrypt)
- [ ] DNS puntato al server
- [ ] Health check funzionante (`curl https://tuodominio.com/health`)
- [ ] Monitoring attivo (cron job)
- [ ] Backup database configurato

---

Buon deployment! 🚀
