#!/bin/bash

# 사용법: ./init-ssl.sh your_email@example.com

set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <email>"
    echo "Example: $0 admin@teamedison.xyz"
    exit 1
fi

EMAIL=$1
DOMAINS=("api.teamedison.xyz" "ai.teamedison.xyz")

echo "=== Edison SSL 초기화 ==="
echo "Email: $EMAIL"
echo "Domains: ${DOMAINS[*]}"
echo ""

# 디렉토리 생성
mkdir -p certbot/conf certbot/www

# 임시 자체 서명 인증서 생성
echo ">> 임시 인증서 생성..."
for domain in "${DOMAINS[@]}"; do
    cert_path="./certbot/conf/live/$domain"
    mkdir -p "$cert_path"

    if [ ! -f "$cert_path/fullchain.pem" ]; then
        openssl req -x509 -nodes -newkey rsa:4096 -days 1 \
            -keyout "$cert_path/privkey.pem" \
            -out "$cert_path/fullchain.pem" \
            -subj "/CN=$domain"
        echo "   Created temp cert for $domain"
    fi
done

# Nginx 시작
echo ""
echo ">> Nginx 시작..."
docker compose up -d nginx
sleep 5

# Let's Encrypt 인증서 발급
echo ""
echo ">> Let's Encrypt 인증서 발급..."
for domain in "${DOMAINS[@]}"; do
    echo "   Requesting cert for $domain..."

    rm -rf "./certbot/conf/live/$domain"
    rm -rf "./certbot/conf/archive/$domain"
    rm -rf "./certbot/conf/renewal/$domain.conf"

    docker compose run --rm certbot certonly \
        --webroot \
        --webroot-path=/var/www/certbot \
        --email "$EMAIL" \
        --agree-tos \
        --no-eff-email \
        --force-renewal \
        -d "$domain"
done

# Nginx 재시작
echo ""
echo ">> Nginx 재시작..."
docker compose restart nginx

echo ""
echo "=== SSL 초기화 완료! ==="
echo "docker compose up -d 로 전체 서비스 시작하세요"
