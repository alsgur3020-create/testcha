#!/bin/bash

echo "🚀 WebSocket 채팅 애플리케이션 배포 시작..."

# Redis 배포
echo "📦 Redis 클러스터 배포 중..."
kubectl apply -f redis-deployment.yaml

# 애플리케이션 시크릿 배포
echo "🔐 애플리케이션 시크릿 배포 중..."
kubectl apply -f app-secrets.yaml

# 백엔드 재배포 (Redis 연결 포함)
echo "🔧 백엔드 서비스 업데이트 중..."
kubectl apply -f backend-deployment.yaml

# 프론트엔드 재배포
echo "🎨 프론트엔드 서비스 업데이트 중..."
kubectl apply -f frontend-deployment.yaml

# Ingress 업데이트 (WebSocket 지원)
echo "🌐 Ingress 설정 업데이트 중..."
kubectl apply -f ingress.yaml

echo "⏳ 배포 상태 확인 중..."
kubectl rollout status deployment/redis
kubectl rollout status deployment/backend
kubectl rollout status deployment/frontend

echo "📊 서비스 상태 확인..."
kubectl get pods -l app=redis
kubectl get pods -l app=backend
kubectl get pods -l app=frontend

echo "🔗 서비스 엔드포인트 확인..."
kubectl get svc

echo "🌐 Ingress 정보 확인..."
kubectl get ingress app-ingress

echo "✅ WebSocket 채팅 애플리케이션 배포 완료!"
echo ""
echo "📝 사용 방법:"
echo "1. Ingress URL로 접속"
echo "2. 사용자 이름과 채팅방 ID 입력"
echo "3. '채팅 참여' 버튼 클릭"
echo "4. 실시간 채팅 시작!"
echo ""
echo "🔍 로그 확인:"
echo "kubectl logs -f deployment/backend"
echo "kubectl logs -f deployment/redis"
echo ""
echo "🧹 정리 명령어:"
echo "kubectl delete -f ."