# Edison Infrastructure

Docker Compose 기반 Edison 서비스 인프라 구성

## 전체 구조 (3개 레포)

```
┌─────────────────────────────────────────────────────────────────────────┐
│                            GitHub Repositories                           │
├─────────────────────┬─────────────────────┬─────────────────────────────┤
│    Edison-Spring    │     Edison-AI       │       Edison-Infra          │
│    (Java 코드)       │   (Python 코드)     │    (Docker Compose 등)       │
│                     │                     │                             │
│  ├─ src/            │  ├─ main.py         │  ├─ docker-compose.yml      │
│  ├─ build.gradle    │  ├─ requirements.txt│  ├─ nginx/nginx.conf        │
│  ├─ Dockerfile ──┐  │  ├─ Dockerfile ──┐  │  ├─ .env                    │
│  └─ .github/     │  │  └─ .github/     │  │  ├─ deploy.sh              │
│     workflows/   │  │     workflows/   │  │  └─ init-ssl.sh            │
│     deploy.yml   │  │     deploy.yml   │  │                             │
└──────────┬───────┘  └──────────┬───────┘  └──────────────┬──────────────┘
           │                     │                         │
           ▼                     ▼                         │
     ┌───────────┐         ┌───────────┐                   │
     │Docker Hub │         │Docker Hub │                   │
     │edison-    │         │edison-ai  │                   │
     │spring:tag │         │:tag       │                   │
     └─────┬─────┘         └─────┬─────┘                   │
           │                     │                         │
           └──────────┬──────────┘                         │
                      ▼                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                           EC2 Instance                                   │
│   /home/ubuntu/edison-infra/ (git clone)                                │
│                                                                          │
│   ┌─────────┐      ┌─────────────┐     ┌────────────┐                   │
│   │  Nginx  │─────►│   Spring    │     │     AI     │                   │
│   │ :80/443 │      │    :8080    │     │   :8000    │                   │
│   └────┬────┘      └──────┬──────┘     └────────────┘                   │
│        │                  │                    ▲                        │
│        └──────────────────┼────────────────────┘                        │
│                           ▼                                             │
│   ┌─────────┐      ┌─────────────┐                                     │
│   │ Certbot │      │    Redis    │                                     │
│   └─────────┘      │    :6379    │                                     │
│                    └─────────────┘                                     │
└─────────────────────────────────────────────────────────────────────────┘
```

## 배포 흐름

```
1. Spring 레포 push → Docker Hub 빌드 → EC2에서 deploy.sh spring 실행
2. AI 레포 push     → Docker Hub 빌드 → EC2에서 deploy.sh ai 실행  
3. Infra 레포 push  → EC2에서 git pull → nginx reload
```

## 레포지토리 구조

```
edison-infra/
├── .github/
│   └── workflows/
│       └── deploy.yml      # Infra 레포 자체 배포
├── docker-compose.yml      # 메인 컴포즈 파일
├── nginx/
│   └── nginx.conf          # Nginx 설정
├── certbot/                # SSL 인증서 (자동 생성)
│   ├── conf/
│   └── www/
├── .env.example            # 환경변수 템플릿
├── .env                    # 실제 환경변수 (gitignore)
├── init-ssl.sh             # SSL 초기화 스크립트
├── deploy.sh               # 배포 스크립트
└── setup-ec2.sh            # EC2 초기 설정
```

## 초기 설정

### 1. EC2 설정

```bash
# EC2에 SSH 접속 후
curl -fsSL https://raw.githubusercontent.com/your-org/edison-infra/main/setup-ec2.sh | bash

# 로그아웃 후 재로그인 (docker 그룹 적용)
exit
ssh ...

# 인프라 레포 클론
git clone https://github.com/your-org/edison-infra.git /home/ubuntu/edison-infra
cd /home/ubuntu/edison-infra
```

### 2. 환경변수 설정

```bash
cp .env.example .env
nano .env  # 실제 값으로 수정
```

### 3. SSL 인증서 발급

```bash
chmod +x init-ssl.sh
./init-ssl.sh your_email@example.com
```

### 4. 서비스 시작

```bash
docker compose up -d
```

## GitHub Secrets 설정

### 3개 레포 공통 (Spring, AI, Infra 모두 동일하게 등록)

| Secret | 설명 |
|--------|------|
| `EC2_HOST` | EC2 퍼블릭 IP 또는 도메인 |
| `EC2_USERNAME` | EC2 SSH 사용자 (보통 `ubuntu`) |
| `EC2_SSH_KEY` | EC2 SSH 프라이빗 키 |
| `ENV_FILE` | .env 파일 내용 전체 (아래 참고) |

### Spring & AI 레포 추가

| Secret | 설명 |
|--------|------|
| `DOCKERHUB_USERNAME` | Docker Hub 사용자명 |
| `DOCKERHUB_TOKEN` | Docker Hub 액세스 토큰 |

### ENV_FILE 시크릿 값 예시

`.env.example` 내용을 복사해서 실제 값으로 채운 후 통째로 등록:

```
DOCKERHUB_USERNAME=your_dockerhub_username
SPRING_TAG=latest
AI_TAG=latest
RDS_URL=jdbc:mysql://your-rds-endpoint:3306/edison
RDS_USERNAME=your_db_username
RDS_PASSWORD=your_db_password
REDIS_PASSWORD=your_redis_password
JWT_SECRET=your_jwt_secret_key
JWT_ACCESS_EXPIRATION=3600000
JWT_REFRESH_EXPIRATION=604800000
GOOGLE_CLIENT_ID=your_google_client_id
OPENAI_KEY=your_openai_api_key
AWS_ACCESS_KEY=your_aws_access_key
AWS_SECRET_KEY=your_aws_secret_key
AWS_S3_BUCKET=your_s3_bucket_name
```

## 적용 체크리스트

### Phase 1: 레포 준비

- [ ] **Infra 레포 생성**: 이 폴더 전체를 새 레포로 push
- [ ] **Spring 레포**: Dockerfile, .github/workflows/deploy.yml 추가
- [ ] **AI 레포**: Dockerfile, .github/workflows/deploy.yml 추가, /health 엔드포인트 추가

### Phase 2: GitHub Secrets 등록

- [ ] 3개 레포 모두: `EC2_HOST`, `EC2_USERNAME`, `EC2_SSH_KEY`, `ENV_FILE`
- [ ] Spring & AI 레포: `DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN` 추가

### Phase 3: EC2 설정

- [ ] 새 EC2 인스턴스 생성 (또는 기존 것 사용)
- [ ] `setup-ec2.sh` 실행
- [ ] Infra 레포 clone
- [ ] `.env` 파일 설정
- [ ] `init-ssl.sh` 실행
- [ ] `docker compose up -d` 실행

### Phase 4: 검증

- [ ] https://api.teamedison.xyz 접속 확인
- [ ] https://ai.teamedison.xyz 접속 확인
- [ ] Spring 레포 push → 자동 배포 확인
- [ ] AI 레포 push → 자동 배포 확인

## 배포 프로세스

### 자동 배포 (GitHub Actions)

1. **Spring 레포**: `main` 브랜치에 push → Docker Hub 빌드 → EC2 배포
2. **AI 레포**: `main` 브랜치에 push → Docker Hub 빌드 → EC2 배포

### 수동 배포

```bash
# Spring만 배포
./deploy.sh spring <tag>

# AI만 배포
./deploy.sh ai <tag>

# 전체 재시작
./deploy.sh all
```

## 운영 명령어

```bash
# 로그 확인
docker compose logs -f spring-app
docker compose logs -f ai-server
docker compose logs -f nginx

# 서비스 상태
docker compose ps

# 서비스 재시작
docker compose restart spring-app

# 전체 중지
docker compose down

# 볼륨까지 삭제 (주의!)
docker compose down -v
```

## SSL 인증서 갱신

Certbot 컨테이너가 12시간마다 자동으로 갱신을 시도합니다.

수동 갱신:
```bash
docker compose run --rm certbot renew
docker compose restart nginx
```

## 도메인 구성

| 도메인 | 서비스 | 포트 |
|--------|--------|------|
| api.teamedison.xyz | Spring Boot | 8080 |
| ai.teamedison.xyz | FastAPI | 8000 |

## 문제 해결

### 컨테이너가 시작되지 않을 때
```bash
docker compose logs <service-name>
```

### SSL 인증서 문제
```bash
# 인증서 상태 확인
docker compose run --rm certbot certificates

# 인증서 재발급
./init-ssl.sh your_email@example.com
```

### Redis 연결 문제
```bash
# Redis 접속 테스트
docker compose exec redis redis-cli -a <password> ping
```