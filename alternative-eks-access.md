# EKS 접근 문제 해결 방법

## 현재 문제
GitHub Actions에서 `the server has asked for the client to provide credentials` 에러가 발생하는 이유:

1. IAM Role이 EKS 클러스터의 aws-auth ConfigMap에 제대로 등록되지 않음
2. Kubernetes RBAC 권한 부족
3. EKS 클러스터 엔드포인트 접근 권한 부족

## 해결 방법

### 방법 1: aws-auth ConfigMap 수동 업데이트 (권장)

```bash
# 1. 현재 aws-auth 확인
kubectl get configmap aws-auth -n kube-system -o yaml

# 2. aws-auth 편집
kubectl edit configmap aws-auth -n kube-system

# 3. 다음 내용을 mapRoles에 추가:
- rolearn: arn:aws:iam::101553892293:role/GitHubActions-ECR-EKS-Role
  groups:
  - system:masters
  username: github-actions
```

### 방법 2: eksctl을 사용한 IAM 매핑

```bash
# GitHub Actions Role을 EKS 클러스터에 매핑
eksctl create iamidentitymapping \
  --cluster my-eks-cluster \
  --region ap-northeast-2 \
  --arn arn:aws:iam::101553892293:role/GitHubActions-ECR-EKS-Role \
  --group system:masters \
  --username github-actions
```

### 방법 3: 서비스 계정 기반 접근

```yaml
# github-actions-sa.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: github-actions
  namespace: default
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::101553892293:role/GitHubActions-ECR-EKS-Role
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: github-actions-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: github-actions
  namespace: default
```

### 방법 4: 임시 해결책 - kubectl 대신 AWS CLI 사용

GitHub Actions에서 kubectl 대신 AWS CLI를 사용하여 배포:

```bash
# ECS 서비스 업데이트 방식으로 변경
aws ecs update-service --cluster my-cluster --service my-service --force-new-deployment
```

## 현재 상황에서 즉시 적용할 수 있는 해결책

### 1단계: 로컬에서 aws-auth 업데이트
```bash
kubectl patch configmap aws-auth -n kube-system --patch '
data:
  mapRoles: |
    - rolearn: arn:aws:iam::101553892293:role/eksctl-my-eks-cluster-nodegroup-ap-NodeInstanceRole-B5kcChClq60O
      groups:
      - system:bootstrappers
      - system:nodes
      username: system:node:{{EC2PrivateDNSName}}
    - rolearn: arn:aws:iam::101553892293:role/GitHubActions-ECR-EKS-Role
      groups:
      - system:masters
      username: github-actions
'
```

### 2단계: IAM 정책 업데이트
```bash
# 스크립트 실행
chmod +x update-iam-policy.sh
./update-iam-policy.sh
```

### 3단계: GitHub Actions 재실행
워크플로우를 다시 실행하여 문제가 해결되었는지 확인

## 검증 방법

### 로컬에서 GitHub Actions Role 테스트
```bash
# 임시로 Role assume (테스트용)
aws sts assume-role \
  --role-arn arn:aws:iam::101553892293:role/GitHubActions-ECR-EKS-Role \
  --role-session-name test-session

# 반환된 자격 증명으로 환경 변수 설정 후
kubectl get nodes
```

### EKS 클러스터 상태 확인
```bash
# 클러스터 엔드포인트 확인
aws eks describe-cluster --name my-eks-cluster --region ap-northeast-2 --query 'cluster.endpoint'

# 클러스터 상태 확인
aws eks describe-cluster --name my-eks-cluster --region ap-northeast-2 --query 'cluster.status'
```