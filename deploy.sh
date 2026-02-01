#!/bin/bash

# 사용법: ./deploy.sh [spring|ai|all] [tag] [dev|prod]

set -euo pipefail

DEPLOY_DIR="/home/ubuntu/edison-infra"
SERVICE=${1:-all}
TAG=${2:-latest}
ENV=${3:-prod}

cd "$DEPLOY_DIR"

echo "=== Edison 배포 시작 ==="
echo "Environment: $ENV"
echo "Service: $SERVICE"
echo "Tag: $TAG"
echo "Time: $(date)"
echo ""

# 환경별 docker-compose 파일 선택
if [ "$ENV" = "dev" ]; then
    COMPOSE_FILE="docker-compose.dev.yml"
    echo ">> 🔧 DEV 환경 (로컬 PostgreSQL)"
else
    COMPOSE_FILE="docker-compose.yml"
    echo ">> 🚀 PROD 환경 (RDS PostgreSQL)"
fi

case $SERVICE in
    spring)
        echo ">> Spring 서버 배포..."
        export SPRING_TAG="$TAG"
        docker compose -f $COMPOSE_FILE pull spring-app
        docker compose -f $COMPOSE_FILE up -d spring-app
        ;;
    ai)
        echo ">> AI 서버 배포..."
        export AI_TAG="$TAG"
        docker compose -f $COMPOSE_FILE pull ai-server
        docker compose -f $COMPOSE_FILE up -d ai-server
        ;;
    all)
        echo ">> 전체 서비스 재시작..."
        docker compose -f $COMPOSE_FILE pull
        docker compose -f $COMPOSE_FILE up -d
        ;;
    *)
        echo "Unknown service: $SERVICE"
        echo "Usage: $0 [spring|ai|all] [tag] [dev|prod]"
        echo ""
        echo "Examples:"
        echo "  $0 spring latest dev    # DEV 환경"
        echo "  $0 spring abc123 prod   # PROD 환경"
        echo "  $0 spring latest        # PROD (기본값)"
        exit 1
        ;;
esac

echo ""
echo ">> 사용하지 않는 이미지 정리..."
docker image prune -af

echo ""
echo ">> 서비스 상태 확인..."
sleep 5
docker compose -f $COMPOSE_FILE ps

echo ""
echo "=== 배포 완료 ==="
