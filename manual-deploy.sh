#!/bin/bash

# 수동 EKS 배포 스크립트
# GitHub Actions가 실패할 경우 로컬에서 실행

set -e

# 변수 설정
AWS_REGION="ap-northeast-2"
ECR_REGISTRY="101553892293.dkr.ecr.ap-northeast-2.amazonaws.com"
BACKEND_REPO="back"
FRONTEND_REPO="front"

# 최신 커밋 해시 가져오기
IMAGE_TAG=$(git rev-parse HEAD)

echo "=== 수동 EKS 배포 시작 ==="
echo "이미지 태그: $IMAGE_TAG"
echo "ECR 레지스트리: $ECR_REGISTRY"

# 1. AWS 자격 증명 확인
echo "1. AWS 자격 증명 확인..."
aws sts get-caller-identity

# 2. EKS 클러스터 연결 확인
echo "2. EKS 클러스터 연결 확인..."
kubectl get nodes

# 3. ECR 이미지 존재 확인
echo "3. ECR 이미지 확인..."
aws ecr describe-images --repository-name $BACKEND_REPO --image-ids imageTag=$IMAGE_TAG --region $AWS_REGION || echo "Backend 이미지 없음"
aws ecr describe-images --repository-name $FRONTEND_REPO --image-ids imageTag=$IMAGE_TAG --region $AWS_REGION || echo "Frontend 이미지 없음"

# 4. 배포 파일 준비
echo "4. 배포 파일 준비..."
cp project1/backend-deployment.yaml backend-deployment-temp.yaml
cp project1/frontend-deployment.yaml frontend-deployment-temp.yaml

# 이미지 태그 업데이트
sed -i.bak "s|101553892293.dkr.ecr.ap-northeast-2.amazonaws.com/back:latest|$ECR_REGISTRY/$BACKEND_REPO:$IMAGE_TAG|g" backend-deployment-temp.yaml
sed -i.bak "s|101553892293.dkr.ecr.ap-northeast-2.amazonaws.com/front:latest|$ECR_REGISTRY/$FRONTEND_REPO:$IMAGE_TAG|g" frontend-deployment-temp.yaml

echo "업데이트된 이미지:"
echo "Backend: $(grep 'image:' backend-deployment-temp.yaml | head -1)"
echo "Frontend: $(grep 'image:' frontend-deployment-temp.yaml | head -1)"

# 5. Kubernetes 리소스 배포
echo "5. Kubernetes 리소스 배포..."

echo "  - Database config 배포..."
kubectl apply -f project1/database-config.yaml

echo "  - Backend deployment 배포..."
kubectl apply -f backend-deployment-temp.yaml

echo "  - Frontend deployment 배포..."
kubectl apply -f frontend-deployment-temp.yaml

echo "  - Ingress 배포..."
kubectl apply -f project1/ingress.yaml

# 6. 배포 상태 확인
echo "6. 배포 상태 확인..."
kubectl get deployments
kubectl get pods

# 7. 배포 완료 대기
echo "7. 배포 완료 대기..."
echo "Backend 배포 상태 확인 중..."
kubectl rollout status deployment/backend --timeout=300s

echo "Frontend 배포 상태 확인 중..."
kubectl rollout status deployment/frontend --timeout=300s

# 8. 최종 상태 확인
echo "8. 최종 배포 상태..."
kubectl get pods -l app=backend
kubectl get pods -l app=frontend
kubectl get svc
kubectl get ingress

# 9. 임시 파일 정리
echo "9. 정리..."
rm -f backend-deployment-temp.yaml frontend-deployment-temp.yaml
rm -f backend-deployment-temp.yaml.bak frontend-deployment-temp.yaml.bak

echo ""
echo "✅ 수동 배포 완료!"
echo ""
echo "애플리케이션 접근:"
INGRESS_URL=$(kubectl get ingress app-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "로드밸런서 URL 확인 중...")
echo "URL: http://$INGRESS_URL"
echo ""
echo "Pod 로그 확인:"
echo "kubectl logs -l app=backend"
echo "kubectl logs -l app=frontend"