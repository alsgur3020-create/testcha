# WebSocket 채팅 애플리케이션

EKS에서 실행되는 실시간 WebSocket 채팅 애플리케이션입니다.

**⚠️ 중요: 이 프로젝트는 project1의 기존 리소스를 덮어씁니다!**
- 동일한 ECR 리포지토리 사용: `back`, `front`
- 동일한 ALB 사용: `app-ingress`
- 동일한 Kubernetes 리소스명 사용

## 🏗️ 아키텍처

- **Frontend**: Nginx + HTML/JavaScript (Socket.IO 클라이언트)
- **Backend**: Node.js + Express + Socket.IO
- **Redis**: 세션 저장소 및 Socket.IO 어댑터
- **Load Balancer**: AWS ALB (기존 ALB 재사용)
- **Container Registry**: Amazon ECR (기존 ECR 재사용)

## 🚀 주요 기능

- ✅ 실시간 WebSocket 채팅
- ✅ Redis 기반 세션 관리
- ✅ 다중 채팅방 지원
- ✅ 채팅 히스토리 저장
- ✅ 로드밸런싱 및 고가용성
- ✅ Sticky Session 지원

## 📦 배포 방법

### 1. 이미지 빌드 및 푸시 (기존 ECR 덮어쓰기)
```bash
cd project2
./build-and-push.sh
```
이 명령은 기존 `back:latest`, `front:latest` 이미지를 WebSocket 버전으로 덮어씁니다.

### 2. Kubernetes 배포 (기존 리소스 업데이트)
```bash
./deploy-chat.sh
```
이 명령은:
- Redis 추가 배포
- 기존 backend, frontend Deployment 업데이트
- 기존 app-ingress 업데이트 (WebSocket 지원 추가)

### 3. 배포 상태 확인
```bash
kubectl get pods
kubectl get svc
kubectl get ingress app-ingress
```

## 🔧 설정 파일

- `backend-deployment.yaml`: 백엔드 서비스 (Redis 연결 추가)
- `frontend-deployment.yaml`: 프론트엔드 서비스 (WebSocket UI 추가)
- `redis-deployment.yaml`: Redis 클러스터 (신규)
- `ingress.yaml`: ALB Ingress (WebSocket 지원 추가)
- `app-secrets.yaml`: 애플리케이션 시크릿 (신규)

## 🌐 접속 방법

1. 기존 Ingress URL 사용:
   ```bash
   kubectl get ingress app-ingress
   ```

2. 브라우저에서 URL 접속

3. 사용자 이름과 채팅방 ID 입력

4. 실시간 채팅 시작!

## 🔍 로그 확인

```bash
# 백엔드 로그
kubectl logs -f deployment/backend

# Redis 로그
kubectl logs -f deployment/redis

# 프론트엔드 로그
kubectl logs -f deployment/frontend
```

## 🔄 project1으로 롤백

WebSocket 기능이 필요 없다면 project1으로 롤백:

```bash
cd ../project1
kubectl apply -f backend-deployment.yaml
kubectl apply -f frontend-deployment.yaml
kubectl apply -f ingress.yaml
kubectl delete -f ../project2/redis-deployment.yaml
kubectl delete -f ../project2/app-secrets.yaml
```

## 📋 환경 변수

### Backend (추가된 환경 변수)
- `REDIS_HOST`: redis-service
- `REDIS_PASSWORD`: Redis 비밀번호
- `SESSION_SECRET`: 세션 암호화 키
- `FRONTEND_URL`: 프론트엔드 URL (CORS)

### 보안 설정
- Redis 비밀번호 보호
- 세션 암호화
- CORS 설정
- Kubernetes Secrets 사용

## 🔄 스케일링

```bash
# 백엔드 스케일링 (Redis Pub/Sub으로 동기화)
kubectl scale deployment backend --replicas=3

# 프론트엔드 스케일링
kubectl scale deployment frontend --replicas=3
```

## 📊 모니터링

- Health Check 엔드포인트: `/api/health`
- 채팅방 목록 API: `/api/rooms`
- Redis 연결 상태 확인 포함

## ⚠️ 주의사항

1. **기존 리소스 덮어쓰기**: 이 배포는 project1의 리소스를 업데이트합니다
2. **Redis 의존성**: Redis가 없으면 채팅 기능이 작동하지 않습니다
3. **세션 유지**: Redis를 삭제하면 모든 세션과 채팅 히스토리가 사라집니다