#!/bin/bash

# EKS 클러스터 배포 스크립트

echo "EKS 클러스터 배포를 시작합니다..."

# 필수 도구 확인
if ! command -v eksctl &> /dev/null; then
    echo "eksctl이 설치되지 않았습니다. 설치를 진행합니다..."
    curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
    sudo mv /tmp/eksctl /usr/local/bin
fi

if ! command -v kubectl &> /dev/null; then
    echo "kubectl이 설치되지 않았습니다. 설치를 진행합니다..."
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/darwin/amd64/kubectl"
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/
fi

# AWS CLI 설정 확인
if ! aws sts get-caller-identity &> /dev/null; then
    echo "AWS CLI가 설정되지 않았습니다. 'aws configure'를 실행해주세요."
    exit 1
fi

# EKS 클러스터 생성
echo "EKS 클러스터를 생성합니다..."
if eksctl create cluster -f cluster.yaml; then
    echo "클러스터 생성이 완료되었습니다."
    
    # kubeconfig 업데이트
    echo "kubeconfig를 업데이트합니다..."
    aws eks update-kubeconfig --region ap-northeast-2 --name my-eks-cluster
    
    # 클러스터 상태 확인
    echo "클러스터 상태를 확인합니다..."
    kubectl get nodes
    
    echo "EKS 클러스터 배포가 완료되었습니다!"
else
    echo "클러스터 생성에 실패했습니다."
    exit 1
fi
