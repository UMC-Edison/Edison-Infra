#!/bin/bash

# 사용법: ./deploy.sh [spring|ai|all] [tag]

set -euo pipefail

DEPLOY_DIR="/home/ubuntu/edison-infra"
SERVICE=${1:-all}
TAG=${2:-latest}

cd "$DEPLOY_DIR"

echo "=== Edison 배포 시작 ==="
echo "Service: $SERVICE"
echo "Tag: $TAG"
echo "Time: $(date)"
echo ""

case $SERVICE in
    spring)
        echo ">> Spring 서버 배포..."
        export SPRING_TAG="$TAG"
        docker compose pull spring-app
        docker compose up -d spring-app
        ;;
    ai)
        echo ">> AI 서버 배포..."
        export AI_TAG="$TAG"
        docker compose pull ai-server
        docker compose up -d ai-server
        ;;
    all)
        echo ">> 전체 서비스 재시작..."
        docker compose pull
        docker compose up -d
        ;;
    *)
        echo "Unknown service: $SERVICE"
        echo "Usage: $0 [spring|ai|all] [tag]"
        exit 1
        ;;
esac

echo ""
echo ">> 사용하지 않는 이미지 정리..."
docker image prune -af

echo ""
echo ">> 서비스 상태 확인..."
sleep 5
docker compose ps

echo ""
echo "=== 배포 완료 ==="