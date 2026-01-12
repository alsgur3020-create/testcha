# EKS 3-Tier 애플리케이션 배포 가이드

React Frontend + Node.js Backend + RDS Database를 EKS에 배포하는 완전한 가이드입니다.

## 아키텍처

```
Internet → ALB Ingress → Frontend Pod (React)
                    ↓
                Backend Pod (Node.js)
                    ↓
                RDS Database
```

## 파일 구성

- `cluster.yaml`: EKS 클러스터 설정
- `frontend-deployment.yaml`: React 프론트엔드 배포
- `backend-deployment.yaml`: Node.js 백엔드 배포
- `database-config.yaml`: RDS 연결 설정
- `ingress.yaml`: ALB Ingress 라우팅
- `deploy-app.sh`: 전체 배포 스크립트

## 배포 단계

### 1. 사전 준비

```bash
# 필수 도구 설치 확인
kubectl version
eksctl version
helm version
aws --version
```

### 2. RDS 인스턴스 생성

```bash
# RDS MySQL 인스턴스 생성
aws rds create-db-instance \
  --db-instance-identifier myapp-db \
  --db-instance-class db.t3.micro \
  --engine mysql \
  --master-username admin \
  --master-user-password password123 \
  --allocated-storage 20 \
  --vpc-security-group-ids sg-xxxxxxxxx \
  --db-subnet-group-name default
```

### 3. 데이터베이스 설정 업데이트

`database-config.yaml`에서 실제 RDS 정보로 업데이트:

```bash
# Base64 인코딩
echo -n "your-rds-endpoint" | base64
echo -n "your-username" | base64
echo -n "your-password" | base64
```

### 4. 애플리케이션 배포

```bash
# 실행 권한 부여
chmod +x deploy-app.sh

# 전체 배포 실행
./deploy-app.sh
```

### 5. 수동 배포 (단계별)

```bash
# EKS 클러스터 생성
eksctl create cluster -f cluster.yaml

# 데이터베이스 설정
kubectl apply -f database-config.yaml

# 백엔드 배포
kubectl apply -f backend-deployment.yaml

# 프론트엔드 배포
kubectl apply -f frontend-deployment.yaml

# Ingress 배포
kubectl apply -f ingress.yaml
```

## 확인 및 테스트

### 배포 상태 확인

```bash
# Pod 상태 확인
kubectl get pods

# 서비스 확인
kubectl get services

# Ingress 확인
kubectl get ingress
```

### 로그 확인

```bash
# 백엔드 로그
kubectl logs -f deployment/backend

# 프론트엔드 로그
kubectl logs -f deployment/frontend
```

### API 테스트

```bash
# 백엔드 헬스체크
kubectl port-forward service/backend-service 3000:3000
curl http://localhost:3000/api/health

# 프론트엔드 접근
kubectl port-forward service/frontend-service 8080:80
```

## 커스터마이징

### 실제 React 앱 배포

1. React 앱을 빌드하여 Docker 이미지 생성
2. ECR에 이미지 푸시
3. `frontend-deployment.yaml`의 이미지 경로 수정

### 실제 Node.js 앱 배포

1. Node.js 앱을 Docker 이미지로 빌드
2. ECR에 이미지 푸시
3. `backend-deployment.yaml`의 이미지 경로 수정

### 환경별 설정

```bash
# 개발환경
kubectl apply -f . -n development

# 운영환경
kubectl apply -f . -n production
```

## 트러블슈팅

### Pod가 시작되지 않는 경우

```bash
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

### Ingress가 작동하지 않는 경우

```bash
kubectl describe ingress app-ingress
kubectl logs -n kube-system deployment/aws-load-balancer-controller
```

### RDS 연결 문제

```bash
# 보안 그룹 확인
# VPC 서브넷 확인
# 데이터베이스 엔드포인트 확인
```

## 정리

```bash
# 애플리케이션 삭제
kubectl delete -f .

# 클러스터 삭제
eksctl delete cluster -f cluster.yaml
```
