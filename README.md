# EKS R&D 프로젝트

AWS EKS 클러스터를 CLI로 구축하기 위한 템플릿 모음입니다.

## 파일 구성

- `cluster.yaml`: EKS 클러스터 구성 파일 (eksctl 사용)
- `deploy.sh`: 클러스터 배포 스크립트
- `cleanup.sh`: 클러스터 삭제 스크립트

## 주요 구성

- **인스턴스 타입**: t3.medium
- **노드 수**: 2개 (최소 1개, 최대 4개)
- **볼륨**: 20GB gp3
- **리전**: ap-northeast-2 (서울)
- **Kubernetes 버전**: 1.28

## 사용 방법

1. AWS CLI 설정
```bash
aws configure
```

2. 클러스터 배포
```bash
chmod +x deploy.sh
./deploy.sh
```

3. 클러스터 삭제
```bash
chmod +x cleanup.sh
./cleanup.sh
```

## 필수 도구

- AWS CLI
- eksctl
- kubectl

배포 스크립트가 자동으로 설치를 진행합니다.
