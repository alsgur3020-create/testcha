# GitHub Secrets 설정 완전 가이드

## 현재 상황
GitHub Actions에서 `EKS_CLUSTER_NAME` Secret이 설정되지 않아서 EKS 배포가 실패하고 있습니다.

## 해결 단계

### 1단계: 현재 설정된 Secrets 확인
GitHub 리포지토리 → Settings → Secrets and variables → Actions

**현재 필요한 Secrets:**
- ✅ `AWS_ROLE_ARN` (IAM Role 사용 시)
- ❌ `EKS_CLUSTER_NAME` (누락됨)

### 2단계: EKS 클러스터 확인

#### 로컬에서 EKS 클러스터 확인
```bash
# AWS CLI로 클러스터 목록 확인
aws eks list-clusters --region ap-northeast-2

# 결과 예시:
# {
#     "clusters": [
#         "my-eks-cluster",
#         "production-cluster"
#     ]
# }
```

#### EKS 클러스터가 없는 경우
```bash
# eksctl로 클러스터 생성 (간단한 방법)
eksctl create cluster --name my-3tier-cluster --region ap-northeast-2 --nodes 2

# 또는 AWS Console에서 생성
# AWS Console → EKS → Clusters → Create cluster
```

### 3단계: GitHub Secrets 설정

#### 필수 Secrets 설정
```
Name: AWS_ROLE_ARN
Secret: arn:aws:iam::101553892293:role/GitHubActions-ECR-EKS-Role

Name: EKS_CLUSTER_NAME
Secret: my-3tier-cluster (실제 클러스터 이름으로 변경)
```

### 4단계: 설정 검증

#### GitHub Actions 로그에서 확인할 내용
```
✅ EKS 클러스터를 찾았습니다.
✅ kubeconfig 업데이트 완료
✅ EKS 배포 완료
```

#### 실패 시 확인할 내용
```
❌ EKS 클러스터를 찾을 수 없습니다: [클러스터이름]
⚠️  EKS_CLUSTER_NAME Secret이 설정되지 않았습니다.
```

## 현재 워크플로우 동작

### ECR 이미지 빌드 (항상 실행)
- ✅ 백엔드 Docker 이미지 빌드 및 푸시
- ✅ 프론트엔드 Docker 이미지 빌드 및 푸시

### EKS 배포 (조건부 실행)
- EKS_CLUSTER_NAME이 설정되고 클러스터가 존재하는 경우에만 실행
- 설정되지 않은 경우 건너뜀 (에러 없이)

## 단계별 해결 가이드

### 옵션 1: 기존 EKS 클러스터 사용
```bash
# 1. 클러스터 목록 확인
aws eks list-clusters --region ap-northeast-2

# 2. 클러스터 이름을 GitHub Secrets에 설정
# GitHub → Settings → Secrets → EKS_CLUSTER_NAME
```

### 옵션 2: 새 EKS 클러스터 생성
```bash
# 1. eksctl로 클러스터 생성
eksctl create cluster \
  --name my-3tier-cluster \
  --region ap-northeast-2 \
  --nodes 2 \
  --node-type t3.medium

# 2. 생성 완료 후 GitHub Secrets에 설정
# EKS_CLUSTER_NAME: my-3tier-cluster
```

### 옵션 3: EKS 없이 ECR만 사용
현재 워크플로우는 EKS가 없어도 ECR 이미지 빌드는 정상적으로 완료됩니다.
나중에 EKS 클러스터를 준비한 후 Secret을 설정하면 자동으로 배포가 시작됩니다.

## 트러블슈팅

### 문제 1: "argument --name: expected one argument"
**원인:** EKS_CLUSTER_NAME Secret이 비어있음
**해결:** GitHub Secrets에 올바른 클러스터 이름 설정

### 문제 2: "cluster not found"
**원인:** 설정한 클러스터 이름이 존재하지 않음
**해결:** `aws eks list-clusters`로 실제 클러스터 이름 확인

### 문제 3: "access denied"
**원인:** IAM Role에 EKS 권한 부족
**해결:** IAM Role에 다음 권한 추가
```json
{
  "Effect": "Allow",
  "Action": [
    "eks:DescribeCluster",
    "eks:ListClusters"
  ],
  "Resource": "*"
}
```

## 현재 상태 요약

✅ **작동하는 부분:**
- AWS IAM Role 인증
- ECR 이미지 빌드 및 푸시
- Docker 이미지 생성

⚠️ **설정 필요한 부분:**
- EKS_CLUSTER_NAME Secret 설정
- EKS 클러스터 존재 여부 확인

🎯 **다음 단계:**
1. EKS 클러스터 생성 또는 기존 클러스터 확인
2. GitHub Secrets에 EKS_CLUSTER_NAME 설정
3. 워크플로우 재실행으로 전체 배포 완료