#!/bin/bash

# 사용법: ./init-ssl-dev.sh your_email@example.com

set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <email>"
    exit 1
fi

EMAIL=$1
DOMAIN="dev.teamedison.xyz"  # <--- 여기만 다릅니다!

echo "=== Edison Dev Server SSL 초기화 ==="
echo "Email: $EMAIL"
echo "Domain: $DOMAIN"
echo ""

# 디렉토리 생성
mkdir -p certbot/conf certbot/www

# 임시 자체 서명 인증서 생성
echo ">> 임시 인증서 생성..."
cert_path="./certbot/conf/live/$DOMAIN"
mkdir -p "$cert_path"

if [ ! -f "$cert_path/fullchain.pem" ]; then
    openssl req -x509 -nodes -newkey rsa:4096 -days 1 \
        -keyout "$cert_path/privkey.pem" \
        -out "$cert_path/fullchain.pem" \
        -subj "/CN=$DOMAIN"
    echo "   Created temp cert for $DOMAIN"
fi

# Nginx 시작
echo ""
echo ">> Nginx 시작..."
docker compose -f docker-compose.dev.yml up -d nginx
sleep 5

# Let's Encrypt 인증서 발급
echo ""
echo ">> Let's Encrypt 인증서 발급..."

rm -rf "./certbot/conf/live/$DOMAIN"
rm -rf "./certbot/conf/archive/$DOMAIN"
rm -rf "./certbot/conf/renewal/$DOMAIN.conf"

docker compose -f docker-compose.dev.yml run --rm certbot certonly \
    --webroot \
    --webroot-path=/var/www/certbot \
    --email "$EMAIL" \
    --agree-tos \
    --no-eff-email \
    -d "$DOMAIN"

# Nginx 재시작
echo ""
echo ">> Nginx 재시작..."
docker compose -f docker-compose.dev.yml restart nginx

echo ""
echo "=== Dev SSL 초기화 완료! ==="
