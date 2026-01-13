#!/bin/bash

# 현재 GitHub Actions에서 사용 중인 IAM Role 확인 스크립트

echo "=== 현재 IAM 설정 확인 ==="

# 1. 현재 AWS 자격 증명 확인
echo "1. 현재 AWS 자격 증명:"
aws sts get-caller-identity

# 2. GitHub Actions에서 사용할 Role ARN 확인
GITHUB_ROLE_ARN="arn:aws:iam::101553892293:role/GitHubActions-ECR-EKS-Role"
echo ""
echo "2. GitHub Actions용 IAM Role 확인:"
echo "Role ARN: $GITHUB_ROLE_ARN"

if aws iam get-role --role-name GitHubActions-ECR-EKS-Role > /dev/null 2>&1; then
    echo "✅ GitHub Actions Role 존재함"
    
    # Role에 연결된 정책 확인
    echo ""
    echo "3. Role에 연결된 정책:"
    aws iam list-attached-role-policies --role-name GitHubActions-ECR-EKS-Role
    
    # Trust Policy 확인
    echo ""
    echo "4. Trust Policy 확인:"
    aws iam get-role --role-name GitHubActions-ECR-EKS-Role --query 'Role.AssumeRolePolicyDocument'
else
    echo "❌ GitHub Actions Role이 존재하지 않습니다."
fi

# 3. EKS 클러스터의 aws-auth ConfigMap 확인
echo ""
echo "5. EKS aws-auth ConfigMap 확인:"
kubectl get configmap aws-auth -n kube-system -o yaml | grep -A 10 -B 5 "GitHubActions-ECR-EKS-Role" || echo "❌ GitHub Actions Role이 aws-auth에 없습니다."

# 4. 현재 사용자의 EKS 접근 권한 확인
echo ""
echo "6. 현재 사용자의 EKS 접근 권한:"
kubectl auth can-i '*' '*' --all-namespaces && echo "✅ 전체 권한 있음" || echo "❌ 권한 제한됨"

echo ""
echo "=== 확인 완료 ==="