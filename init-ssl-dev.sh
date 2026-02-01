cat << 'EOF' > init-ssl-dev.sh
#!/bin/bash

# 에러 발생 시 즉시 중단
set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <email>"
    exit 1
fi

EMAIL=$1
DOMAIN="dev.teamedison.xyz"

echo "=== Edison Dev Server SSL 초기화 (Final) ==="
echo "Email: $EMAIL"
echo "Domain: $DOMAIN"

# 1. 디렉토리 정리
mkdir -p certbot/conf certbot/www

# 2. 임시 인증서 생성
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

# 3. Nginx 시작 (서비스명: edison-nginx)
echo ">> Nginx 시작..."
docker compose -f docker-compose.dev.yml up -d edison-nginx
sleep 5

# 4. 기존 잘못된 설정 삭제
rm -rf ./certbot/conf/live/$DOMAIN*
rm -rf ./certbot/conf/archive/$DOMAIN*
rm -rf ./certbot/conf/renewal/$DOMAIN*

# 5. Let's Encrypt 정식 발급 (Entrypoint 수정 적용)
echo ">> Let's Encrypt 정식 발급..."
docker compose -f docker-compose.dev.yml run --rm --entrypoint "certbot" certbot certonly \
    --webroot \
    --webroot-path=/var/www/certbot \
    --email "$EMAIL" \
    --agree-tos \
    --no-eff-email \
    --force-renewal \
    -d "$DOMAIN"

# 6. Nginx 재시작
echo ">> Nginx 재시작..."
docker compose -f docker-compose.dev.yml restart edison-nginx

echo "=== Dev SSL 초기화 완료! ==="
EOF
