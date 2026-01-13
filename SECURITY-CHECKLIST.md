# 보안 체크리스트

## GitHub Secrets 관리

### ✅ 해야 할 것들
- [ ] GitHub Secrets에 민감한 정보 저장
- [ ] `.env.example` 파일로 환경 변수 템플릿 제공
- [ ] `.gitignore`에 민감한 파일 패턴 추가
- [ ] 최소 권한 원칙으로 IAM 정책 설정
- [ ] 정기적인 액세스 키 로테이션 (90일마다)

### ❌ 하지 말아야 할 것들
- [ ] 실제 AWS 키를 코드에 하드코딩
- [ ] `.env` 파일을 Git에 커밋
- [ ] 프로덕션 키를 개발 환경에서 사용
- [ ] 과도한 권한을 가진 IAM 사용자 생성
- [ ] 공개 리포지토리에 민감한 정보 노출

## AWS 보안 설정

### IAM 사용자 설정
```json
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
        "ecr:DescribeRepositories"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "eks:DescribeCluster"
      ],
      "Resource": "arn:aws:eks:ap-northeast-2:*:cluster/your-cluster-name"
    },
    {
      "Effect": "Allow",
      "Action": [
        "sts:GetCallerIdentity"
      ],
      "Resource": "*"
    }
  ]
}
```

### EKS 클러스터 보안
- [ ] 프라이빗 엔드포인트 사용
- [ ] 네트워크 정책 설정
- [ ] RBAC 권한 최소화
- [ ] Pod Security Standards 적용

## 컨테이너 보안

### Dockerfile 보안
- [ ] Non-root 사용자로 실행
- [ ] 최소한의 베이스 이미지 사용 (alpine)
- [ ] 불필요한 패키지 제거
- [ ] 취약점 스캔 실행

### 이미지 보안
- [ ] ECR에서 이미지 스캔 활성화
- [ ] 이미지 태그 고정 (latest 사용 금지)
- [ ] 정기적인 베이스 이미지 업데이트

## 네트워크 보안

### Kubernetes 네트워크
- [ ] Network Policy로 Pod 간 통신 제한
- [ ] Ingress에서 TLS 설정
- [ ] 서비스 메시 사용 고려 (Istio)

### AWS 네트워크
- [ ] VPC 프라이빗 서브넷 사용
- [ ] 보안 그룹 최소 권한 설정
- [ ] NAT Gateway 사용

## 모니터링 및 로깅

### 로그 관리
- [ ] CloudWatch Logs 설정
- [ ] 애플리케이션 로그에서 민감한 정보 제거
- [ ] 감사 로그 활성화

### 모니터링
- [ ] CloudTrail로 API 호출 추적
- [ ] GuardDuty로 위협 탐지
- [ ] Config로 리소스 변경 추적

## 정기 보안 점검

### 월간 점검
- [ ] 사용하지 않는 IAM 사용자/역할 정리
- [ ] 액세스 키 사용 현황 검토
- [ ] 보안 그룹 규칙 검토

### 분기별 점검
- [ ] 액세스 키 로테이션
- [ ] 취약점 스캔 결과 검토
- [ ] 보안 정책 업데이트

### 연간 점검
- [ ] 전체 보안 아키텍처 검토
- [ ] 재해 복구 계획 테스트
- [ ] 보안 교육 실시