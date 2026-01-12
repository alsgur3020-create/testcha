#!/bin/bash

echo "=== EKS 3-Tier 애플리케이션 배포 스크립트 ==="

# 1. EKS 클러스터 생성 (이미 생성되어 있다면 스킵)
echo "1. EKS 클러스터 확인 중..."
if ! kubectl get nodes &> /dev/null; then
    echo "EKS 클러스터를 먼저 생성합니다..."
    eksctl create cluster -f cluster.yaml
    echo "클러스터 생성 완료!"
else
    echo "EKS 클러스터가 이미 실행 중입니다."
fi

# 2. AWS Load Balancer Controller 설치
echo "2. AWS Load Balancer Controller 설치 중..."
curl -o iam_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.4.4/docs/install/iam_policy.json

aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam_policy.json

CLUSTER_NAME=$(kubectl config current-context | cut -d'/' -f2)
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

eksctl create iamserviceaccount \
  --cluster=$CLUSTER_NAME \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --role-name "AmazonEKSLoadBalancerControllerRole" \
  --attach-policy-arn=arn:aws:iam::$ACCOUNT_ID:policy/AWSLoadBalancerControllerIAMPolicy \
  --approve

helm repo add eks https://aws.github.io/eks-charts
helm repo update

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=$CLUSTER_NAME \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller

# 3. RDS 인스턴스 생성 (선택사항)
echo "3. RDS 설정 안내..."
echo "RDS 인스턴스를 수동으로 생성하거나 기존 인스턴스를 사용하세요."
echo "database-config.yaml의 Secret 값을 실제 RDS 정보로 업데이트하세요."

# 4. 애플리케이션 배포
echo "4. 애플리케이션 배포 중..."

# 데이터베이스 설정 적용
kubectl apply -f database-config.yaml

# 백엔드 배포
kubectl apply -f backend-deployment.yaml

# 프론트엔드 배포
kubectl apply -f frontend-deployment.yaml

# Ingress 배포
kubectl apply -f ingress.yaml

# 5. 배포 상태 확인
echo "5. 배포 상태 확인 중..."
kubectl get pods
kubectl get services
kubectl get ingress

echo "=== 배포 완료! ==="
echo "다음 명령어로 상태를 확인하세요:"
echo "kubectl get pods -w"
echo "kubectl logs -f deployment/backend"
echo "kubectl logs -f deployment/frontend"
