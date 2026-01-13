#!/bin/bash

# GitHub Actions용 IAM Role 생성 스크립트

set -e

# 변수 설정
ROLE_NAME="GitHubActions-ECR-EKS-Role"
POLICY_NAME="GitHubActions-ECR-EKS-Policy"
AWS_ACCOUNT_ID="101553892293"
AWS_REGION="ap-northeast-2"
GITHUB_REPO="alsgur3020-create/testcha"

echo "=== GitHub Actions IAM Role 생성 ==="

# 1. OIDC Provider 확인/생성
echo "1. OIDC Provider 확인 중..."
OIDC_PROVIDER_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"

if aws iam get-open-id-connect-provider --open-id-connect-provider-arn "$OIDC_PROVIDER_ARN" > /dev/null 2>&1; then
    echo "✅ OIDC Provider가 이미 존재합니다."
else
    echo "📝 OIDC Provider 생성 중..."
    aws iam create-open-id-connect-provider \
        --url https://token.actions.githubusercontent.com \
        --client-id-list sts.amazonaws.com \
        --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
    echo "✅ OIDC Provider 생성 완료"
fi

# 2. Trust Policy 생성
echo ""
echo "2. Trust Policy 생성 중..."
cat > trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:${GITHUB_REPO}:*"
        }
      }
    }
  ]
}
EOF

# 3. IAM Role 생성
echo "3. IAM Role 생성 중..."
if aws iam get-role --role-name "$ROLE_NAME" > /dev/null 2>&1; then
    echo "⚠️  Role이 이미 존재합니다. Trust Policy를 업데이트합니다."
    aws iam update-assume-role-policy \
        --role-name "$ROLE_NAME" \
        --policy-document file://trust-policy.json
else
    aws iam create-role \
        --role-name "$ROLE_NAME" \
        --assume-role-policy-document file://trust-policy.json \
        --description "GitHub Actions role for ECR and EKS access"
    echo "✅ IAM Role 생성 완료"
fi

# 4. Permission Policy 생성
echo ""
echo "4. Permission Policy 생성 중..."
cat > permission-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload",
        "ecr:PutImage",
        "ecr:CreateRepository",
        "ecr:DescribeRepositories",
        "ecr:ListRepositories"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "eks:DescribeCluster",
        "eks:ListClusters",
        "eks:DescribeNodegroup",
        "eks:ListNodegroups",
        "eks:DescribeUpdate",
        "eks:ListUpdates",
        "eks:AccessKubernetesApi"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "sts:GetCallerIdentity",
        "sts:AssumeRole"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "iam:GetRole",
        "iam:ListAttachedRolePolicies"
      ],
      "Resource": "arn:aws:iam::${AWS_ACCOUNT_ID}:role/${ROLE_NAME}"
    }
  ]
}
EOF

# 5. Policy 생성 또는 업데이트
echo "5. Permission Policy 생성/업데이트 중..."
POLICY_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:policy/${POLICY_NAME}"

if aws iam get-policy --policy-arn "$POLICY_ARN" > /dev/null 2>&1; then
    echo "⚠️  Policy가 이미 존재합니다. 새 버전을 생성합니다."
    aws iam create-policy-version \
        --policy-arn "$POLICY_ARN" \
        --policy-document file://permission-policy.json \
        --set-as-default
else
    aws iam create-policy \
        --policy-name "$POLICY_NAME" \
        --policy-document file://permission-policy.json \
        --description "GitHub Actions policy for ECR and EKS access"
    echo "✅ Policy 생성 완료"
fi

# 6. Policy를 Role에 연결
echo ""
echo "6. Policy를 Role에 연결 중..."
aws iam attach-role-policy \
    --role-name "$ROLE_NAME" \
    --policy-arn "$POLICY_ARN"
echo "✅ Policy 연결 완료"

# 7. 결과 확인
echo ""
echo "=== 생성 결과 ==="
echo "✅ IAM Role: arn:aws:iam::${AWS_ACCOUNT_ID}:role/${ROLE_NAME}"
echo "✅ IAM Policy: arn:aws:iam::${AWS_ACCOUNT_ID}:policy/${POLICY_NAME}"
echo ""
echo "GitHub Secrets 설정:"
echo "AWS_ROLE_ARN: arn:aws:iam::${AWS_ACCOUNT_ID}:role/${ROLE_NAME}"
echo "EKS_CLUSTER_NAME: my-eks-cluster"
echo ""
echo "Trust Policy에서 허용하는 리포지토리: ${GITHUB_REPO}"

# 8. 임시 파일 정리
rm -f trust-policy.json permission-policy.json

echo ""
echo "✅ GitHub Actions IAM Role 설정 완료!"
echo ""
echo "다음 단계:"
echo "1. GitHub Secrets에 AWS_ROLE_ARN 설정"
echo "2. GitHub Actions 워크플로우 재실행"
echo "3. EKS 자동 배포 확인"