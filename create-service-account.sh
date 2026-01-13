#!/bin/bash

# GitHub Actions용 Kubernetes Service Account 생성

set -e

echo "=== GitHub Actions용 Service Account 생성 ==="

# 1. Service Account 생성
echo "1. Service Account 생성 중..."
cat > github-actions-sa.yaml << EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: github-actions
  namespace: default
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::101553892293:role/GitHubActions-ECR-EKS-Role
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: github-actions-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: github-actions
  namespace: default
---
apiVersion: v1
kind: Secret
metadata:
  name: github-actions-token
  namespace: default
  annotations:
    kubernetes.io/service-account.name: github-actions
type: kubernetes.io/service-account-token
EOF

# 2. Service Account 적용
kubectl apply -f github-actions-sa.yaml
echo "✅ Service Account 생성 완료"

# 3. Service Account 토큰 확인
echo ""
echo "2. Service Account 토큰 확인 중..."
sleep 5  # 토큰 생성 대기

if kubectl get secret github-actions-token -n default > /dev/null 2>&1; then
    echo "✅ Service Account 토큰 생성됨"
    
    # 토큰 정보 확인 (민감한 정보는 제외)
    echo "토큰 정보:"
    kubectl describe secret github-actions-token -n default | grep -E "Name:|Type:|Data"
else
    echo "⚠️  Service Account 토큰이 아직 생성되지 않았습니다."
fi

# 4. Service Account 권한 테스트
echo ""
echo "3. Service Account 권한 테스트..."
kubectl auth can-i '*' '*' --as=system:serviceaccount:default:github-actions && echo "✅ 전체 권한 있음" || echo "❌ 권한 제한됨"

# 5. 정리
rm -f github-actions-sa.yaml

echo ""
echo "✅ Service Account 설정 완료!"
echo ""
echo "이제 GitHub Actions에서 다음 방법으로 접근할 수 있습니다:"
echo "1. Service Account 토큰 사용"
echo "2. IAM Role for Service Account (IRSA) 사용"