# 로컬 개발 환경 설정 가이드

## 1. 환경 변수 설정

### .env 파일 생성
```bash
# 프로젝트 루트에서 실행
cp .env.example .env
```

### .env 파일 편집
```bash
# .env 파일을 열어서 실제 값으로 수정
vim .env
```

## 2. AWS CLI 설정

### AWS CLI 설치
```bash
# macOS
brew install awscli

# Ubuntu/Debian
sudo apt-get install awscli

# Windows
# AWS CLI 공식 사이트에서 다운로드
```

### AWS 자격 증명 설정
```bash
# 방법 1: AWS CLI configure 사용
aws configure
# AWS Access Key ID: AKIA...
# AWS Secret Access Key: ...
# Default region name: ap-northeast-2
# Default output format: json

# 방법 2: 환경 변수 사용 (권장)
export AWS_ACCESS_KEY_ID=your_access_key
export AWS_SECRET_ACCESS_KEY=your_secret_key
export AWS_DEFAULT_REGION=ap-northeast-2
```

## 3. Docker 로컬 테스트

### 백엔드 이미지 빌드 및 실행
```bash
cd project1/backend

# 이미지 빌드
docker build -t local-backend .

# 컨테이너 실행
docker run -p 3000:3000 --env-file ../../.env local-backend
```

### 프론트엔드 이미지 빌드 및 실행
```bash
cd project1/frontend

# 이미지 빌드
docker build -t local-frontend .

# 컨테이너 실행
docker run -p 8080:8080 local-frontend
```

## 4. Kubernetes 로컬 테스트

### kubectl 설정
```bash
# EKS 클러스터 연결
aws eks update-kubeconfig --region ap-northeast-2 --name your-cluster-name

# 연결 확인
kubectl get nodes
```

### 로컬에서 배포 테스트
```bash
# 네임스페이스 생성 (선택사항)
kubectl create namespace dev

# 배포 파일 적용
kubectl apply -f project1/database-config.yaml -n dev
kubectl apply -f project1/backend-deployment.yaml -n dev
kubectl apply -f project1/frontend-deployment.yaml -n dev
kubectl apply -f project1/ingress.yaml -n dev
```

## 5. 보안 주의사항

### 절대 커밋하면 안 되는 파일들
- `.env` (실제 환경 변수)
- `aws-credentials.txt`
- `kubeconfig` 파일
- `*.pem`, `*.key` 파일
- 실제 시크릿이 포함된 YAML 파일

### 안전한 개발 방법
1. `.env.example`만 커밋하고 `.env`는 절대 커밋하지 않기
2. 개발용과 프로덕션용 AWS 계정 분리
3. 최소 권한 원칙 적용
4. 정기적으로 액세스 키 로테이션

## 6. 트러블슈팅

### 권한 오류 시
```bash
# 현재 AWS 사용자 확인
aws sts get-caller-identity

# ECR 로그인 테스트
aws ecr get-login-password --region ap-northeast-2 | docker login --username AWS --password-stdin 101553892293.dkr.ecr.ap-northeast-2.amazonaws.com
```

### 네트워크 오류 시
```bash
# VPC 및 보안 그룹 확인
aws ec2 describe-vpcs
aws ec2 describe-security-groups
```