#!/bin/bash

# GitHub Actions IAM 정책 업데이트 스크립트

set -e

POLICY_NAME="GitHubActions-ECR-EKS-Policy"
ROLE_NAME="GitHubActions-ECR-EKS-Role"
AWS_ACCOUNT_ID="101553892293"

echo "=== IAM 정책 업데이트 ==="

# 1. 기존 정책 버전 확인
echo "1. 기존 정책 확인..."
POLICY_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:policy/${POLICY_NAME}"

if aws iam get-policy --policy-arn "$POLICY_ARN" > /dev/null 2>&1; then
    echo "✅ 기존 정책 발견: $POLICY_ARN"
    
    # 새 정책 버전 생성
    echo "2. 새 정책 버전 생성..."
    aws iam create-policy-version \
        --policy-arn "$POLICY_ARN" \
        --policy-document file://eks-iam-policy.json \
        --set-as-default
    
    echo "✅ 정책 업데이트 완료"
else
    echo "❌ 기존 정책을 찾을 수 없습니다. 새로 생성합니다."
    
    # 새 정책 생성
    aws iam create-policy \
        --policy-name "$POLICY_NAME" \
        --policy-document file://eks-iam-policy.json \
        --description "GitHub Actions에서 ECR 및 EKS 접근을 위한 확장된 정책"
    
    # Role에 정책 연결
    aws iam attach-role-policy \
        --role-name "$ROLE_NAME" \
        --policy-arn "$POLICY_ARN"
    
    echo "✅ 새 정책 생성 및 연결 완료"
fi

# 3. 현재 Role에 연결된 정책 확인
echo "3. Role에 연결된 정책 확인..."
aws iam list-attached-role-policies --role-name "$ROLE_NAME"

echo ""
echo "=== 업데이트 완료 ==="
echo "이제 GitHub Actions에서 다음 권한을 사용할 수 있습니다:"
echo "- ECR 이미지 관리"
echo "- EKS 클러스터 접근"
echo "- Kubernetes API 호출"
echo "- IAM Role 정보 조회"