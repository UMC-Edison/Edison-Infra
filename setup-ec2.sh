#!/bin/bash

# EC2 초기 설정 스크립트 (Ubuntu 22.04/24.04)

set -euo pipefail

echo "=== Edison EC2 초기 설정 ==="

# 시스템 업데이트
echo ">> 시스템 업데이트..."
sudo apt update && sudo apt upgrade -y

# Docker 설치
echo ">> Docker 설치..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com | sudo sh
    sudo usermod -aG docker $USER
    echo "⚠️  Docker 설치 완료. 로그아웃 후 다시 로그인하세요!"
else
    echo "Docker 이미 설치됨"
fi

# Docker Compose 설치
echo ">> Docker Compose 설치..."
if ! docker compose version &> /dev/null; then
    sudo apt install -y docker-compose-plugin
fi

# 필수 도구
echo ">> 필수 도구 설치..."
sudo apt install -y git curl htop

# Docker 서비스 시작
sudo systemctl enable docker
sudo systemctl start docker

# 방화벽 설정
echo ">> 방화벽 설정..."
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw --force enable

echo ""
echo "=== 초기 설정 완료! ==="
echo ""
echo "다음 단계:"
echo "1. exit 후 다시 SSH 접속 (docker 그룹 적용)"
echo "2. git clone <infra-repo> /home/ubuntu/edison-infra"
echo "3. cd /home/ubuntu/edison-infra"
echo "4. chmod +x deploy.sh init-ssl.sh"
echo "5. ./init-ssl.sh your@email.com"
echo "6. docker compose up -d"