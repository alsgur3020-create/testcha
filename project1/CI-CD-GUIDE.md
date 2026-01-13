# GitHub Actions CI/CD 가이드

## 개요
이 프로젝트는 AWS EKS에 3-tier 애플리케이션을 자동 배포하는 CI/CD 파이프라인을 제공합니다.

## 사전 준비사항

### 1. AWS 리소스
- EKS 클러스터
- ECR 리포지토리 (front, back)
- RDS 데이터베이스 (선택사항)
- ALB Ingress Controller 설치

### 2. GitHub Secrets 설정
리포지토리 Settings > Secrets and variables > Actions에서 다음 값들을 설정하세요:

```
AWS_ACCESS_KEY_ID: AKIA...
AWS_SECRET_ACCESS_KEY: your-secret-key
AWS_REGION: ap-northeast-2
EKS_CLUSTER_NAME: your-cluster-name
```

### 3. ECR 리포지토리 생성
```bash
aws ecr create-repository --repository-name front --region ap-northeast-2
aws ecr create-repository --repository-name back --region ap-northeast-2
```

## CI/CD 파이프라인 구조

### 워크플로우 트리거
- `main` 브랜치에 push: 전체 빌드 및 배포
- `develop` 브랜치에 push: 테스트만 실행
- Pull Request: 테스트만 실행

s### 파이프라인 단계

1. **Test Job**
   - Node.js 환경 설정
   - 의존성 설치
   - 단위 테스트 실행

2. **Build and Deploy Job** (main 브랜치만)
   - AWS 인증
   - ECR 로그인
   - Docker 이미지 빌드 및 푸시
   - EKS 배포
   - 배포 검증

## 프로젝트 구조

```
project1/
├── backend/
│   ├── Dockerfile
│   ├── package.json
│   └── server.js
├── frontend/
│   ├── Dockerfile
│   ├── nginx.conf
│   └── index.html
├── backend-deployment.yaml
├── frontend-deployment.yaml
├── database-config.yaml
└── ingress.yaml
```

## 배포 과정

### 1. 코드 변경 및 커밋
```bash
git add .
git commit -m "feat: 새로운 기능 추가"
git push origin main
```

### 2. 자동 배포 확인
GitHub Actions 탭에서 워크플로우 실행 상태를 확인할 수 있습니다.

### 3. 배포 검증
```bash
# 클러스터 상태 확인
kubectl get pods
kubectl get svc
kubectl get ingress

# 애플리케이션 테스트
curl http://your-alb-url/api/health
curl http://your-alb-url/
```

## 트러블슈팅

### 일반적인 문제들

1. **ECR 권한 오류**
   ```
   Error: denied: User is not authorized to perform: ecr:BatchCheckLayerAvailability
   ```
   - AWS IAM 사용자에게 ECR 권한 추가 필요

2. **EKS 접근 오류**
   ```
   Error: You must be logged in to the server (Unauthorized)
   ```
   - EKS 클러스터의 aws-auth ConfigMap에 사용자 추가 필요

3. **이미지 Pull 오류**
   ```
   Error: ErrImagePull
   ```
   - ECR 리포지토리 존재 여부 확인
   - 이미지 태그 확인

### 로그 확인 방법
```bash
# Pod 로그 확인
kubectl logs -l app=backend
kubectl logs -l app=frontend

# 배포 상태 확인
kubectl describe deployment backend
kubectl describe deployment frontend
```

## 고급 설정

### 환경별 배포
- `develop` 브랜치: 개발 환경
- `staging` 브랜치: 스테이징 환경  
- `main` 브랜치: 프로덕션 환경

### 롤백 방법
```bash
# 이전 버전으로 롤백
kubectl rollout undo deployment/backend
kubectl rollout undo deployment/frontend

# 특정 리비전으로 롤백
kubectl rollout undo deployment/backend --to-revision=2
```

### 모니터링
- CloudWatch Logs로 애플리케이션 로그 수집
- Prometheus + Grafana로 메트릭 모니터링
- AWS Load Balancer Controller로 ALB 메트릭 확인

## 보안 고려사항

1. **최소 권한 원칙**: IAM 사용자에게 필요한 최소 권한만 부여
2. **시크릿 관리**: 민감한 정보는 GitHub Secrets 사용
3. **이미지 스캔**: ECR에서 취약점 스캔 활성화
4. **네트워크 정책**: Kubernetes Network Policy로 트래픽 제한

## 성능 최적화

1. **멀티 스테이지 빌드**: Docker 이미지 크기 최소화
2. **캐싱**: GitHub Actions에서 Docker layer 캐싱 활용
3. **리소스 제한**: Pod에 적절한 CPU/메모리 제한 설정
4. **HPA**: Horizontal Pod Autoscaler로 자동 스케일링