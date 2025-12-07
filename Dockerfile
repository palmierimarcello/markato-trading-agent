# Usa Python 3.11 come base image
FROM python:3.11-slim

# Metadata
LABEL maintainer="Trading Agent"
LABEL description="Automated Trading Agent with AI-driven decisions"

# Imposta variabili d'ambiente
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Crea directory di lavoro
WORKDIR /app

# Installa dipendenze di sistema necessarie per psycopg2 e altre librerie
RUN apt-get update && apt-get install -y \
    gcc \
    postgresql-client \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Copia requirements e installa dipendenze Python
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copia tutto il codice dell'applicazione
COPY . .

# Crea directory per logs se necessaria
RUN mkdir -p /app/logs

# Esponi porta per health check (opzionale, se aggiungi API)
EXPOSE 8000

# Script di avvio che inizializza il DB e avvia il bot
CMD ["python", "main.py"]
