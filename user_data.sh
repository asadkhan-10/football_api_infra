#!/bin/bash
set -euo pipefail
exec > >(tee -a /var/log/user-data.log) 2>&1
export DEBIAN_FRONTEND=noninteractive

# --- 1. Docker from Docker's official apt repo ---
apt-get update
apt-get install -y ca-certificates curl
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" > /etc/apt/sources.list.d/docker.list
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
usermod -aG docker ubuntu

# --- 2. Cap container log size ---
cat > /etc/docker/daemon.json <<'EOF'
{"log-driver":"json-file","log-opts":{"max-size":"10m","max-file":"3"}}
EOF
systemctl restart docker

# --- 3. Swap (1GB RAM box) ---
if [ ! -f /swapfile ]; then
  fallocate -l 2G /swapfile
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  echo '/swapfile none swap sw 0 0' >> /etc/fstab
fi

# --- 4. Host firewall: allow 80/443 ---
for port in 80 443; do
  iptables -C INPUT -p tcp --dport "$port" -j ACCEPT 2>/dev/null || \
    iptables -I INPUT 1 -p tcp --dport "$port" -m conntrack --ctstate NEW -j ACCEPT
done
netfilter-persistent save || true


# --- 5. App directory ---
APP_DIR=/home/ubuntu/app
mkdir -p "$APP_DIR/certbot/conf" "$APP_DIR/certbot/www"
cd "$APP_DIR"

cat > docker-compose-prod.yml <<'EOF'
services:
  api:
    image: asadkhn10/football-prediction-api:latest
    healthcheck:
      test: ["CMD", "python", "-c", "import urllib.request; urllib.request.urlopen('http://localhost:8000/')"]
      interval: 10s
      timeout: 5s
      retries: 3
      start_period: 10s
    depends_on:
      - postgres
      - redis
    environment:
      - database_hostname=postgres
      - database_port=5432
      - database_password=${database_password}
      - database_name=${database_name}
      - database_username=${database_username}
      - secret_key=${secret_key}
      - algorithm=HS256
      - redis_url=redis://redis:6379/0
      - football_api_key=${football_api_key}
    restart: unless-stopped

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/conf.d/default.conf
      - ./certbot/conf:/etc/letsencrypt
      - ./certbot/www:/var/www/certbot
    depends_on:
      api:
        condition: service_healthy
    restart: unless-stopped

  certbot:
    image: certbot/certbot
    profiles: ["tools"]
    volumes:
      - ./certbot/conf:/etc/letsencrypt
      - ./certbot/www:/var/www/certbot

  postgres:
    image: postgres:15
    environment:
      - POSTGRES_USER=${database_username}
      - POSTGRES_PASSWORD=${database_password}
      - POSTGRES_DB=${database_name}
    volumes:
      - postgres-db:/var/lib/postgresql/data
    restart: unless-stopped

  redis:
    image: redis:7-alpine
    restart: unless-stopped

  celery_worker:
    image: asadkhn10/football-prediction-api:latest
    depends_on:
      - postgres
      - redis
    command: celery -A app.celery_app.celery_app worker --loglevel=info
    environment:
      - database_hostname=postgres
      - database_port=5432
      - database_password=${database_password}
      - database_name=${database_name}
      - database_username=${database_username}
      - secret_key=${secret_key}
      - redis_url=redis://redis:6379/0
      - football_api_key=${football_api_key}
    restart: unless-stopped

  celery_beat:
    image: asadkhn10/football-prediction-api:latest
    depends_on:
      - postgres
      - redis
    command: celery -A app.celery_app.celery_app beat --loglevel=info
    environment:
      - database_hostname=postgres
      - database_port=5432
      - database_password=${database_password}
      - database_name=${database_name}
      - database_username=${database_username}
      - secret_key=${secret_key}
      - redis_url=redis://redis:6379/0
      - football_api_key=${football_api_key}
    restart: unless-stopped

volumes:
  postgres-db:
EOF

cat > nginx.conf <<'EOF'
server {
    listen 80;
    server_name football-api.duckdns.org;

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location / {
        return 301 https://$host$request_uri;
    }
}

server {
    listen 443 ssl;
    server_name football-api.duckdns.org;

    ssl_certificate /etc/letsencrypt/live/football-api.duckdns.org/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/football-api.duckdns.org/privkey.pem;

    location / {
        proxy_pass http://api:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
EOF

# .env: names only, you fill the values by hand after first boot
if [ ! -f .env ]; then
cat > .env <<'EOF'
database_username=
database_password=
database_name=
secret_key=
football_api_key=
EOF
fi
chmod 600 .env
chown -R ubuntu:ubuntu "$APP_DIR"