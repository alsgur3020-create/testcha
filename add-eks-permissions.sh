#!/bin/bash

# GitHub Actions IAM Role에 추가 EKS 권한 부여

set -e

ROLE_NAME="GitHubActions-ECR-EKS-Role"
POLICY_NAME="GitHubActions-EKS-Additional-Policy"
AWS_ACCOUNT_ID="101553892293"

echo "=== EKS 추가 권한 설정 ==="

# 1. 추가 EKS 권한 정책 생성
echo "1. 추가 EKS 권한 정책 생성 중..."
cat > eks-additional-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "eks:*"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "iam:PassRole"
      ],
      "Resource": "arn:aws:iam::${AWS_ACCOUNT_ID}:role/eksctl-*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeInstances",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeSubnets",
        "ec2:DescribeVpcs"
      ],
      "Resource": "*"
    }
  ]
}
EOF

# 2. 정책 생성
POLICY_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:policy/${POLICY_NAME}"

if aws iam get-policy --policy-arn "$POLICY_ARN" > /dev/null 2>&1; then
    echo "⚠️  정책이 이미 존재합니다. 새 버전을 생성합니다."
    aws iam create-policy-version \
        --policy-arn "$POLICY_ARN" \
        --policy-document file://eks-additional-policy.json \
        --set-as-default
else
    aws iam create-policy \
        --policy-name "$POLICY_NAME" \
        --policy-document file://eks-additional-policy.json \
        --description "Additional EKS permissions for GitHub Actions"
    echo "✅ 추가 정책 생성 완료"
fi

# 3. 정책을 Role에 연결
echo "2. 추가 정책을 Role에 연결 중..."
aws iam attach-role-policy \
    --role-name "$ROLE_NAME" \
    --policy-arn "$POLICY_ARN"
echo "✅ 추가 정책 연결 완료"

# 4. 현재 Role에 연결된 모든 정책 확인
echo ""
echo "3. 현재 Role에 연결된 정책 목록:"
aws iam list-attached-role-policies --role-name "$ROLE_NAME"

# 5. 임시 파일 정리
rm -f eks-additional-policy.json

echo ""
echo "✅ EKS 추가 권한 설정 완료!"