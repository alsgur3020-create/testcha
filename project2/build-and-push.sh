#!/bin/bash

# ECR 설정
AWS_REGION="ap-northeast-2"
AWS_ACCOUNT_ID="101553892293"
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

echo "🔐 ECR 로그인 중..."
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}

echo "🏗️ 백엔드 이미지 빌드 중..."
cd backend
docker build -t back .
docker tag back:latest ${ECR_REGISTRY}/back:latest

echo "📤 백엔드 이미지 푸시 중..."
docker push ${ECR_REGISTRY}/back:latest

echo "🏗️ 프론트엔드 이미지 빌드 중..."
cd ../frontend
docker build -t front .
docker tag front:latest ${ECR_REGISTRY}/front:latest

echo "📤 프론트엔드 이미지 푸시 중..."
docker push ${ECR_REGISTRY}/front:latest

cd ..

echo "✅ 모든 이미지 빌드 및 푸시 완료!"
echo ""
echo "📋 생성된 이미지:"
echo "- ${ECR_REGISTRY}/back:latest"
echo "- ${ECR_REGISTRY}/front:latest"
echo ""
echo "🚀 다음 단계: ./deploy-chat.sh 실행"