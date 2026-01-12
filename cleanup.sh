#!/bin/bash

# EKS 클러스터 삭제 스크립트

echo "EKS 클러스터 삭제를 시작합니다..."

# 클러스터 삭제
eksctl delete cluster -f cluster.yaml

echo "EKS 클러스터가 삭제되었습니다!"
